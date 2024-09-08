// SPDX-License-Identifier: MIT
// commit-reveal can only be used public sale.
// mintwithbitmap and mintwithmapping can only be used during pre-sale

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AdvancedNFT is ERC721, Ownable(msg.sender), ReentrancyGuard {
    using BitMaps for BitMaps.BitMap;

    // Merkle tree root
    bytes32 public merkleRoot;

    // Mapping and Bitmap to track minted addresses
    mapping(address => bool) public hasMintedMapping;
    BitMaps.BitMap private hasMintedBitmap;

    // Commit-Reveal Structure
    struct Commit {
        bytes32 commitHash;
        uint256 blockNumber;
    }
    mapping(address => Commit) public commits;
    uint256 public revealDelay = 10;

    // State machine
    enum SaleState {
        Paused,
        Presale,
        PublicSale,
        SoldOut
    }
    SaleState public saleState;

    // Multicall functionality
    uint256 public totalMinted;
    uint256 public maxSupply;

    // Balances for contributors (for pull pattern)
    mapping(address => uint256) public balances;
    // Whitelist of allowed function selectors

    mapping(bytes4 => bool) public allowedFunctions;

    constructor(bytes32 _merkleRoot, uint256 _maxSupply)
        ERC721("Advanced NFT", "ANFT")
    {
        merkleRoot = _merkleRoot;
        maxSupply = _maxSupply;
        saleState = SaleState.Paused;
        allowedFunctions[IERC721.transferFrom.selector] = true;
    }

    // === State Machine for Minting Phases ===
    modifier validState(SaleState requiredState) {
        require(saleState == requiredState, "Invalid state for this action");
        _;
    }

    function setSaleState(SaleState _newState) external onlyOwner {
        saleState = _newState;
    }

    function mintWithMapping(bytes32[] calldata _merkleProof, uint256 index)
        public
        nonReentrant
        validState(SaleState.Presale)
    {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, index)))
        );
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        require(totalMinted < maxSupply, "Max supply reached");
        require(!hasMintedMapping[msg.sender], "Already minted");

        hasMintedMapping[msg.sender] = true;
        _mintInternal();
    }

    function mintWithBitmap(bytes32[] calldata _merkleProof, uint256 index)
        public
        nonReentrant
        validState(SaleState.Presale)
    {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, index)))
        );
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        require(totalMinted < maxSupply, "Max supply reached");
        require(!hasMintedBitmap.get(index), "Already minted");

        hasMintedBitmap.set(index);
        _mintInternal();
    }

    function _mintInternal() private {
        _safeMint(msg.sender, totalMinted);
        totalMinted++;
        if (totalMinted == maxSupply) {
            saleState = SaleState.SoldOut;
        }
    }

    // === Commit-Reveal for Random NFT ID Allocation ===
    function commit(bytes32 _commitHash)
        external
        validState(SaleState.PublicSale)
    {
        commits[msg.sender] = Commit(_commitHash, block.number);
    }

    function reveal(uint256 _nftId, uint256 _secret)
        external
        nonReentrant
        validState(SaleState.PublicSale)
    {
        Commit memory userCommit = commits[msg.sender];
        require(
            block.number > userCommit.blockNumber + revealDelay,
            "Reveal too soon"
        );
        require(
            keccak256(abi.encodePacked(_nftId, _secret)) ==
                userCommit.commitHash,
            "Invalid reveal"
        );

        _safeMint(msg.sender, _nftId);
        totalMinted++;
        require(totalMinted <= maxSupply, "Exceeds supply");
    }

    // === Multicall for Transferring NFTs ===
    function multiApprove(address[] calldata to, uint256[] calldata tokenIds)
        external
    {
        require(to.length == tokenIds.length, "Arrays length mismatch");
        for (uint256 i = 0; i < to.length; i++) {
            approve(to[i], tokenIds[i]);
        }
    }

    function multicall(bytes[] calldata data)
        external
        nonReentrant
        validState(SaleState.PublicSale)
    {
        for (uint256 i = 0; i < data.length; i++) {
            require(data[i].length >= 4, "Invalid call data");
            bytes4 selector = bytes4(data[i][:4]);
            require(allowedFunctions[selector], "Function not allowed");

            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Transaction failed");
        }
    }

    // === Pull Pattern for Fund Withdrawals ===
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Receive function to accept funds (for pull payments)
    function recievefunds() external payable {
        balances[msg.sender] += msg.value;
    }
}
