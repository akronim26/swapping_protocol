//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../../src/Exchange.sol";
import {Token} from "../../src/Token.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is Test {

    Token token;
    Exchange exchange;
    address user = makeAddr("user");
    uint256 constant initialSupply = 100 * 10 ** 18;
    uint256 constant funds = 10 * 10 ** 18;
    uint256 constant AMOUNT = 10 * 10 ** 18;
    Handler handler;

    function setUp() external {
        token = new Token(initialSupply);
        exchange = new Exchange(address(token));
        handler = new Handler(exchange, token);
        token.transfer(address(handler), initialSupply);
        vm.deal(address(handler), AMOUNT);
        targetContract(address(handler));
    }

    function invariant_lpTokenSupply() public view {
        uint256 totalLPSupply = exchange.totalSupply();
        if (totalLPSupply > 0) {
            assert(exchange.getReserve() > 0);
            assert(address(exchange).balance > 0);
        }
    }

    function invariant_GetterFunctionsShouldNotRevert() public view {
        exchange.getLPTokenBalance(msg.sender);
        exchange.getTotalLPTokens();
        exchange.getReserve();
    }

}