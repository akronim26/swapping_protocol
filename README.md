# Swapping Protocol

## Overview

Swapping Protocol is a decentralized exchange (DEX) implemented in Solidity that allows users to swap between ETH (native token) and a custom ERC20 "exchange token" using the constant product rule (x * y = k), a model popularized by Uniswap. The protocol enables users to:

- Swap ETH ↔️ ERC20 tokens with a 1% fee on swaps.
- Provide liquidity to the pool and receive LP tokens representing their share.
- Withdraw provided liquidity proportionally at any time.

The design ensures that even after swaps, liquidity providers can always withdraw their correct share thanks to the constant product invariance.

## Key Features

- **Constant Product Market Maker**: Maintains the product of ETH and exchange token reserves, ensuring fair swaps.
- **Liquidity Pools**: Users can add/remove liquidity, earning LP tokens that track their share.
- **Fee Mechanism**: 1% swap fee incentivizes liquidity providers.
- **No Impermanent Loss Protection**: Follows standard DEX risks.
- **Non-reentrant & Secure**: Utilizes OpenZeppelin's ReentrancyGuard for security.

## Components

- `Exchange.sol`: The core contract for swapping and liquidity management.
- `Token.sol`: ERC20 implementation for the custom exchange token.
- Scripts and tests for deployment and invariant checking.

## Usage

### Build

```sh
forge build
```

### Test

```sh
forge test
```

### Format

```sh
forge fmt
```

### Local Node

```sh
anvil
```

### Deploy

```sh
forge script script/DeployExchange.s.sol:DeployExchange --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Interact

```sh
cast <subcommand>
```

## Example

- Add liquidity: Call `addLiquidity(tokenAmount)` with ETH and approved tokens.
- Swap ETH for tokens: Call `ethToToken(minAmount)` with ETH.
- Swap tokens for ETH: Call `tokenToEth(tokenAmount, minAmount)` after approving tokens.
- Remove liquidity: Call `removeLiquidity(lpTokenAmount)`.

## Security

- Always audit before using in production.
- This is an educational implementation and not audited for mainnet use.

---

# License

MIT
