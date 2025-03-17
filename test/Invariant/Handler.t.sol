//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Exchange} from "../../src/Exchange.sol";
import {Token} from "../../src/Token.sol";

contract Handler is Test {

    Exchange exchange;
    Token token;
    uint256 constant maxAmount = 10 * 10e18;
    uint256 constant funds = 10 * 10 ** 18;

    constructor(Exchange _exchange, Token _token) {
        exchange = _exchange;
        token = _token;
    }

    function addLiquidity(uint256 amount) public {
        amount = bound(amount, 1, maxAmount);
        token.approve(address(exchange), funds);
        exchange.addLiquidity{value: funds}(amount);
    }

    function removeLiquidity(uint256 lpToken) public {
        lpToken = bound(lpToken, 0, exchange.balanceOf(msg.sender));
        if (lpToken == 0) {
            return;
        }
        exchange.removeLiquidity(lpToken);
    }

    function swapTokenToEth(uint256 tokenAmount, uint256 minAmount) public {
        tokenAmount = bound(tokenAmount, 1, 1e18);
        minAmount = bound(minAmount, 1, tokenAmount/2);
        exchange.tokenToEth(tokenAmount, minAmount);
    }

    function swapEthToToken(uint256 minAmount) public {
        minAmount = bound(minAmount, 1, 1e18);
        exchange.ethToToken(minAmount);
    }
}