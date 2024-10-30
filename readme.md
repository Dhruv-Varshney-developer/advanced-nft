# Advanced NFT

## Description

This project implements an **advanced NFT contract** with cutting-edge features such as **Merkle Tree-based airdrops**, **bitmap optimizations**, **commit-reveal random allocation**, **multicall for efficient transfers**, and a **state machine to control minting phases**. The project is designed for scalability, security, and gas efficiency, leveraging OpenZeppelin libraries.

## Features

### 1\. **Merkle Tree Airdrop**

- Addresses in the Merkle Tree are allowed to mint NFTs during the presale.
- The contract supports two tracking mechanisms:

  - **Mapping**: A traditional approach using a mapping to track addresses.
  - **Bitmap**: A gas-optimized method using OpenZeppelin’s BitMaps.

### 2\. **Commit-Reveal Mechanism**

- Ensures randomness during the NFT allocation process.
- Users commit a hash (NFT ID + secret) and reveal it after a delay of 10 blocks.
- Inspired by Cool Cats NFT but implemented without Chainlink.

### 3\. **Multicall**

- Enables batch processing of NFT transfers in a single transaction.
- Prevents abuse by ensuring only allowed functions can be multicalled.

### 4\. **State Machine**

- The contract operates in distinct phases:

  - **Paused**: No minting allowed.
  - **Presale**: Merkle Tree-based minting using mapping or bitmap.
  - **Public Sale**: Commit-reveal minting and multicall allowed.
  - **Sold Out**: Minting disabled.

- Each phase is enforced using require statements.

### 5\. **Pull-Pattern Fund Withdrawal**

- Contributors can withdraw funds individually using the **pull pattern**, improving security.
- Allows withdrawals to multiple contributors.

### 6\. **Gas Optimizations**

- Utilizes bitmap tracking for airdrop eligibility to reduce storage costs.
- Leverages OpenZeppelin’s nonReentrant modifier to prevent reentrancy attacks.

## File Structure

```bash

AdvancedNFT/
├── contracts/
│   └── advancednft.sol         # Main NFT contract implementation
├── merkletree/
│   ├── merkleproof.mjs         # Script to generate Merkle Tree and proofs
│   ├── tree.json               # Serialized Merkle Tree data
│   ├── package.json            # Dependencies for the Merkle Tree scripts
│   └── .gitignore              # Ignore unnecessary files
├── answers.md                  # Answers to important questions
├── README.md                   # Documentation for the project

```

## Installation

### Prerequisites

- **Node.js**: To run the Merkle Tree scripts.
- **Solidity Compiler**: For compiling the contract.

### Steps

1.  Clone the repo:

```bash
clone https://github.com/username/AdvancedNFT.git
cd AdvancedNFT
```

2.  Generate merkletree and proof or use existing ones.:

```bash
cd merkletree
npm install
```

3.  Deploy the contract using **Hardhat** or **Remix**.

## Usage

### 1\. **Generating Merkle Proofs**

Run the `merkleproof.mjs` script to generate the Merkle Root and proofs:

```bash
node merkletree/merkleproof.mjs
```

Use the generated root and proofs in the contract.

### 2\. **Minting During Presale**

Use `mintWithMapping` or `mintWithBitmap` with a valid Merkle Proof.

### 3\. **Commit-Reveal in Public Sale**

- Get commit hash:
  Use the following command in the console to generate the commit hash:

  ```javascript
  web3.utils.keccak256(
    web3.eth.abi.encodeParameters(
      ["uint256", "uint256"],
      [replace_with_nftId, replace_with_secret]
    )
  );
  ```

- Commit:

```solidity
commit(hash);
```

- Reveal (after 10 blocks):

```solidity
reveal(nftId, secret);
```

### 4\. **Batch Transfers**

Prepare calldata using generateTransferFromData and call multicall with the encoded data.

### 5\. **Withdrawing Funds**

Contributors can call withdraw() to claim their funds securely.

## Tools and Libraries

- **OpenZeppelin Contracts**: Security and gas-efficient libraries.
- **Hardhat**: Testing and deployment.
- **Merkle Tree Utilities**: For secure airdrops.
- **Solidity 0.8.x**: Latest features with built-in overflow checks.

## Contributing

1.  Fork the repository.
2.  `git checkout -b feature-name`
3.  Submit a pull request.

## License

This project is licensed under the MIT License.
