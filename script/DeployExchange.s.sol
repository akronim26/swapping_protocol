//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Exchange} from "../src/Exchange.sol";

contract DeployExchange is Script {

    /// @dev Used the contract address of token contract after deployment.

    address tokenAddress = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;

    function run() external returns(Exchange) {
        Exchange exchange;
        vm.startBroadcast();
        exchange = new Exchange(tokenAddress);
        vm.stopBroadcast();
        return exchange;
    }
}