// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AdvancedNFT is ERC721Enumerable, Ownable(msg.sender), ReentrancyGuard, Pausable {
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
    enum SaleState { Paused, Presale, PublicSale, SoldOut }
    SaleState public saleState;

    // Multicall functionality
    uint256 public totalMinted;
    uint256 public maxSupply;

    // Balances for contributors (for pull pattern)
    mapping(address => uint256) public balances;

    constructor(bytes32 _merkleRoot, uint256 _maxSupply) ERC721("Advanced NFT", "ANFT") {
        merkleRoot = _merkleRoot;
        maxSupply = _maxSupply;
    }

    function mintWithMapping(bytes32[] calldata _merkleProof, uint256 index) public nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, index));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");
        require(totalMinted < maxSupply, "Max supply reached");
        require(!hasMintedMapping[msg.sender], "Already minted");

        hasMintedMapping[msg.sender] = true;
        _safeMint(msg.sender, totalMinted);
        totalMinted++;
    }

    function mintWithBitmap(bytes32[] calldata _merkleProof, uint256 index) public nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, index));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");
        require(totalMinted < maxSupply, "Max supply reached");
        require(!hasMintedBitmap.get(index), "Already minted");

        hasMintedBitmap.set(index);
        _safeMint(msg.sender, totalMinted);
        totalMinted++;
    }

    // === Commit-Reveal for Random NFT ID Allocation ===
    function commit(bytes32 _commitHash) external whenNotPaused {
        commits[msg.sender] = Commit(_commitHash, block.number);
    }

    function reveal(uint256 _nftId, uint256 _secret) external whenNotPaused nonReentrant {
        Commit memory userCommit = commits[msg.sender];
        require(block.number > userCommit.blockNumber + revealDelay, "Reveal too soon");
        require(keccak256(abi.encodePacked(_nftId, _secret)) == userCommit.commitHash, "Invalid reveal");

        _safeMint(msg.sender, _nftId);
        totalMinted++;
        require(totalMinted <= maxSupply, "Exceeds supply");
    }

    // === Multicall for Transferring NFTs ===
    function multicall(bytes[] calldata data) external whenNotPaused nonReentrant {
        for (uint256 i = 0; i < data.length; i++) {
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Transaction failed");
        }
    }

    // === State Machine for Minting Phases ===
    function setSaleState(SaleState _newState) external onlyOwner {
        saleState = _newState;
    }

    

    // === Pull Pattern for Fund Withdrawals ===
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // === Pausable Functions ===
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Receive function to accept funds (for pull payments)
    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}
