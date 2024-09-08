import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// Define a list of addresses with their respective minting indices (in your case index should relate to the bitmap tracking)
const values = [
  ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0"],  // Address 1 with index 0
  ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "1"],  // Address 2 with index 1
  // Add more addresses as necessary
];

// Create the Merkle Tree
const tree = StandardMerkleTree.of(values, ["address", "uint256"]);

// Output the Merkle root, you'll use this in the contract constructor
console.log('Merkle Root:', tree.root);

// Save the Merkle tree to a file for later use
fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));

// Example: Obtain Merkle proofs for all addresses in the tree
for (const [i, v] of tree.entries()) {
  const address = v[0]; // Extract the address
  const proof = tree.getProof(i); // Get the proof for the current entry
  console.log(`Merkle Proof for address ${address}:`, proof); // Log the proof
}

const proof=[
  '0x94b29c01ed483e694a7ecf386d384987d4d3e9d4e6c476f5b97302b23ff871c9'
]
const verified = StandardMerkleTree.verify(tree.root, ["address", "uint256"], ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0"], proof);
console.log('Is valid:', verified);  // Should return true if the proof is valid
