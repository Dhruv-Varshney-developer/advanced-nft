
# Advanced NFT Assignment - Answers

## 1. Should you use Pausable or NonReentrant in your NFT?

- **Pausable**: No, since important function can be paused using state machine.
- **NonReentrant**: Yes, to protect against reentrancy attacks, especially during fund withdrawals.

## 2. What trick does OpenZeppelin use to save gas on the NonReentrant modifier?

OpenZeppelin's `NonReentrant` modifier saves gas by using a single storage slot with two states (entered/not entered) to track function reentrancy, minimizing costly storage operations. 
This simple status flag approach efficiently prevents reentrancy attacks with minimal gas overhead.
