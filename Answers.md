
# Advanced NFT Assignment - Answers

## 1. Should you use Pausable or NonReentrant in your NFT?

- **Pausable**: Yes, use it to stop minting or transfers temporarily in case of bugs or exploits.
- **NonReentrant**: Yes, to protect against reentrancy attacks, especially during fund withdrawals.

## 2. What trick does OpenZeppelin use to save gas on the NonReentrant modifier?

- OpenZeppelin uses a simple state variable to track if the function is being executed, preventing reentrant calls without complex checks, saving gas.
