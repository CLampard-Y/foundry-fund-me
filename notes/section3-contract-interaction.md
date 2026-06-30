# Contract Interaction Notes
## 1. ABI
Why Frontend, cast, script all need to know the functions included in contract?
> ABI is the interface specification of a smart contract. The frontend, cast, and scripts rely on ABI or function signatures to convert human-readable calls like fund() into calldata that the EVM contract can understand and process.
## 2. Contract Address
Why only ABI alone is not enough to interact with contract?
> A contract address is the location of a deployed contract instance on a specific blockchain network. The same ABI can match many deployed contracts, so both ABI and contract address are needed to interact with a specific contract.
## 3. Browser Wallet / window.ethereum
Why can a website interacts with Metamask?
> MetaMask or other browser wallets inject a global object called `window.ethereum` into the browser. A website can use `window.ethereum` to check whether a wallet exists, request account authorization, and send read or transaction requests through the wallet.
## 4. Provider vs Signer
Why does `getBalance()` not need a signer, while `fund()` does?
> A provider is used to access blockchain state through RPC. A signer represents the signing ability of the connected wallet account.
> `getBalance()` is read-only, so it only needs a provider. `fund()` sends ETH and changes contract state, so it requires a signer and wallet confirmation.
## 5. Frontend vs `cast` vs Foundry script
Are frontend, cast and script are different logics?
> frontend, cast and script all call the same contract address on chain,  they are different interaction methods for the same deployed contract. Frontend interacts with wallet by `ethers.js`, cast interacts by CLI RPC, script interacts by solidity scripts broadcast, in the end they all rely on contract address, ABI, RPC/network and signing account. 
## 6. Transaction Data / Function Selector / Calldata
What is the Hex data in Metamask?
> Hex data is encoded calldata of transaction. The first four bytes are function selector (the first 4 bytes of the keccak256 hash of the function signature), the rest are encoded arguments.
## 7. README and Deployment Evidence
Why wrting "run the project" purely in README is not enough?
> README needs to specify network, contract address, deployment evidence, interaction steps, etc. Because contract interaction didn't happen in an abstract context. Callers need to know which chain they are on, which contract address they are calling, which ABI or function signature is used, and how to interact with the contract, etc.
## 8. What I Do Not Need to Learn Deeply Now
> I do not need to deeply learn React, Svelte, HTML/CSS, UI styling, frontend polishing, or complete full-stack dApp development for now.
> My current goal is to understand the contract interaction model, not to become a frontend developer.