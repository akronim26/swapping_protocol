//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";
import {Token} from "../src/Token.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ExchangeTest is Test {

    Token token;
    Exchange exchange;
    address user = makeAddr("user");
    uint256 constant initialSupply = 100 * 10 ** 18;
    uint256 constant funds = 10 * 10 ** 18;
    uint256 constant AMOUNT = 10 * 10 ** 18;

    modifier liquidityAdded {
        vm.startPrank(user);
        token.approve(address(exchange), funds);
        exchange.addLiquidity{value: funds}(funds);
        vm.stopPrank();
        _;
    }

    function setUp() external {
        token = new Token(initialSupply);
        exchange = new Exchange(address(token));
        token.transfer(user, AMOUNT);
        vm.deal(user, 100 ether);
    }

    function testFuzzAddLiquidity(uint256 tokenAmount) public {
        vm.prank(user);
        tokenAmount = bound(tokenAmount, 1, token.balanceOf(user));
        uint256 initialTokenReserve = exchange.getReserve();
        uint256 initialEthReserve = address(exchange).balance;
        vm.startPrank(user);
        token.approve(address(exchange), funds);
        exchange.addLiquidity{value: funds}(funds);
        vm.stopPrank();
        uint256 finalTokenReserve = exchange.getReserve();
        uint256 finalEthReserve = address(exchange).balance;
        assertEq(finalEthReserve, initialEthReserve + funds);
        assertEq(finalTokenReserve, initialTokenReserve + funds);
    }

    function testFuzzRemoveLiquidity(uint256 lpTokens) public liquidityAdded {
        vm.prank(user);
        lpTokens = bound(lpTokens, 1, exchange.getLPTokenBalance(user));
        uint256 initialTokenReserve = exchange.getReserve();
        uint256 initialEthReserve = address(exchange).balance;
        uint256 totalSupply = exchange.totalSupply();
        uint256 expectedEthAmount = (lpTokens * initialEthReserve) / totalSupply;
        uint256 expectedTokenAmount = (lpTokens * initialTokenReserve) / totalSupply;
        vm.startPrank(user);
        exchange.removeLiquidity(lpTokens);
        vm.stopPrank();
        uint256 finalTokenReserve = exchange.getReserve();
        uint256 finalEthReserve = address(exchange).balance;
        assertEq(finalEthReserve, initialEthReserve - expectedEthAmount);
        assertEq(finalTokenReserve, initialTokenReserve - expectedTokenAmount);
    }

    function testEthToTokenSwap() public liquidityAdded {
        uint256 initialTokenReserve = exchange.getReserve();
        uint256 initialEthReserve = address(exchange).balance;
        vm.startPrank(user);
        exchange.ethToToken{value: 1 ether}(0);
        vm.stopPrank();
        uint256 finalTokenReserve = exchange.getReserve();
        uint256 finalEthReserve = address(exchange).balance;
        console.log(finalTokenReserve, initialTokenReserve);
        console.log(finalEthReserve, initialEthReserve);
        assert(finalEthReserve > initialEthReserve);
        assert(finalTokenReserve < initialTokenReserve);
    }

    function testTokenToEthSwap() public liquidityAdded {
        token.transfer(user, AMOUNT);
        uint256 initialTokenReserve = exchange.getReserve();
        uint256 initialEthReserve = address(exchange).balance;
        uint256 tokenAmount = 1 ether;
        vm.startPrank(user);
        token.approve(address(exchange), tokenAmount);
        exchange.tokenToEth(tokenAmount, 0);
        vm.stopPrank();
        uint256 finalTokenReserve = exchange.getReserve();
        uint256 finalEthReserve = address(exchange).balance;
        assert(finalEthReserve < initialEthReserve);
        assert(finalTokenReserve > initialTokenReserve);
    }
}