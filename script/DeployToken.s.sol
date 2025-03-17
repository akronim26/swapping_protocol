//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

contract DeployToken is Script {

    uint256 constant INITIAL_SUPPLY = 100 * 10 ** 18;

    function run() external returns(Token) {
        Token token;
        vm.startBroadcast();
        token = new Token(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return (token);
    }
}