# Arcin Locker 🔒

**Arcin Locker** is the foundational smart contract module for **Arcin**, an upcoming fully on-chain Private Swap DEX dedicated to stablecoins. 

While the ultimate vision of Arcin is to provide uncompromising privacy for stablecoin swaps, this repository contains the first building block: a highly gas-optimized, secure token locking mechanism built for the Arc network.

---

## 🌐 Live DApp & Verification
- **DApp Interface:** [locker.arcin.xyz](https://locker.arcin.xyz)
- **Verified Smart Contract:** [View on Arcscan](https://testnet.arcscan.app/address/0x2Cc605B0daCD2b0Cc1A5Be606D694A11cA4e5F90)

---

## ⚡ Core Features
- **Gas-Optimized Storage:** Uses mapping-based tracking instead of expensive unbounded arrays to minimize gas costs during state updates.
- **Strict CEI Pattern:** Fully adheres to the Checks-Effects-Interactions pattern to prevent Re-entrancy attacks.
- **Native & ERC20 Support:** Seamless handling of both Native network tokens and ERC20 stablecoins.
- **Double-Count & Underflow Protection:** Built-in safeguards against array underflows and double-counting vulnerabilities.
- **Emergency Recovery:** Admin fallback mechanism to rescue stranded tokens if necessary.

---

## 🛠 Tech Stack
- **Language:** Solidity `^0.8.20`
- **Frontend Integration:** Ethers.js,js, HTML/CSS (Glassmorphism UI)
- **Network:** Arc Testnet

---

## 📜 Smart Contract Architecture
The contract is deliberately kept single-file for this iteration to ensure straightforward verification and auditing. 

**Key mappings:**
- `mapping(address => mapping(address => bool)) private isDeposited;`
- Ensures O(1) complexity when checking user token existence without looping through state arrays.
