//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title A swapping protocol
/// @author Abhivansh Saini
/// @notice  This is a swapping protocol in which the user can swap between ETH (a native token, not an ERC20 token) and a exchange token (an ERC20 token) using the constant product rule of decentralised finance in which the product of the two tokens which are supposed to be swapped (here ETH and exchange token) remains approximately constant before and after swap. There is also the concept of liquidity pools in which if someone liquidity provider provides the liquidity, gets liquidity tokens for every exchange token they provide. Later they can get their provided liquidity back in the ratio of their liquidity tokens. The protocol also charges 1% fee for swapping which gets distributed to the liquidity providers on basis of ratio of their provided liquidity. This acts as their incentive to provide liquidity into the protocol.


/// @dev This contract creates the exchange token which is an ERC20.

contract Token is ERC20 {

    uint256 constant INITIAL_SUPPLY = 100 * 10 ** 18;
    constructor(uint256 initialSupply) ERC20("Swappy", "SWY") {
        initialSupply = INITIAL_SUPPLY;
        _mint(msg.sender, initialSupply);
    }
}