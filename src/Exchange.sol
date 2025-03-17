//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title A swapping protocol
/// @author Abhivansh Saini
/// @notice  This is a swapping protocol in which the user can swap between ETH (a native token, not an ERC20 token) and a exchange token (an ERC20 token) using the constant product rule of decentralised finance in which the product of the two tokens which are supposed to be swapped (here ETH and exchange token) remains approximately constant before and after swap. There is also the concept of liquidity pools in which if someone liquidity provider provides the liquidity, gets liquidity tokens for every exchange token they provide. Later they can get their provided liquidity back in the ratio of their liquidity tokens. The protocol also charges 1% fee for swapping which gets distributed to the liquidity providers on basis of ratio of their provided liquidity. This acts as their incentive to provide liquidity into the protocol.
/// @dev I have imported IERC20 for the functioning of the exchange token and ERC20 for the functioning of liquidity tokens.

/// @dev This contract creates the exchange between the ETH and the exchange token. It provides functions like addLiquidity, removeLiquidity for Liquidity Providers. It also provide functions to get token and ETH amount the user will get on swapping and also provide to function to swap for users.

contract Exchange is ERC20, ReentrancyGuard {
    address tokenAddress;

    error Exchange_TokenAddressZero();
    error Exchange_InvalidTokenAmount();
    error Exchange_ReservesAreEmpty();
    error Exchange_AmountIsZero();
    error Exchange_AmountLessThanMinAmount();

    event Exchange_LiquidityAdded(address indexed user);
    event Exchange_LiquidityRemoved(address indexed user);
    event Exchange_TokenToEthSwapped(address indexed user, uint256 tokenAmount, uint256 ethReceived);
    event Exchange_EthToTokenSwapped(address indexed user, uint256 ethAmount, uint256 tokenReceived);

    mapping(address user => uint256 amount) userToLPTokenBalance;

    /// @dev The argument in the constructor is for the exchange token and the arguments in the ERC20 are for the liquidity tokens we are providing to the liquidity providers.

    constructor(address _token) ERC20("Liquidity", "LP") {
        if (_token == address(0)) {
            revert Exchange_TokenAddressZero();
        }
        tokenAddress = _token;
    }

    ///////////////////////////////////////////////
    ////// FUNCTIONS FOR LIQUIDITY PROVIDERS //////
    ///////////////////////////////////////////////

    /// @dev This function deals with adding liquidity to the protocol which is used by liquidty providers. This handles both the cases when the liquidity is added for the first time and when the liquidity has already been added. This also mints liquidity providers with liquidity tokens. The provider gets 1 liquidity token in return of every exchange token they added to the liquidity.
    /// @param tokenAmount - It is the amount of exchange token the user is willing to add in the liquidity pool.

    function addLiquidity(uint256 tokenAmount) public payable nonReentrant {
        require(tokenAmount > 0, Exchange_AmountIsZero());
        if (getReserve() == 0) {
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                tokenAmount
            );
            uint256 liquidityTokens = tokenAmount;
            userToLPTokenBalance[msg.sender] += liquidityTokens;
            _mint(msg.sender, liquidityTokens);
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAllowed = (tokenReserve * msg.value) / ethReserve;
            if (tokenAmount < tokenAllowed) {
                revert Exchange_InvalidTokenAmount();
            }
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                tokenAllowed
            );
            uint256 liquidityTokens = tokenAllowed;
            userToLPTokenBalance[msg.sender] += liquidityTokens;
            _mint(msg.sender, liquidityTokens);
        }
        emit Exchange_LiquidityAdded(msg.sender);
    }

    /// @dev This function is used to remove the liquidity provided by the liquidity providers. The liquidity provider can burn the liquidity tokens and get exchange token and ETH proportional to their share in liquidity pool in return.
    /// @param liquidityTokens - It is the amount of liquidity tokens the liquidity provider got in exchange of providing liquidity.

    function removeLiquidity(uint256 liquidityTokens) public nonReentrant {
        require(liquidityTokens > 0, Exchange_AmountIsZero());
        uint256 tokenAmount = liquidityTokens;
        uint256 ethAmount = (address(this).balance * tokenAmount) /
            getReserve();
        _burn(msg.sender, liquidityTokens);
        userToLPTokenBalance[msg.sender] -= liquidityTokens;
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        emit Exchange_LiquidityRemoved(msg.sender);
    }

    /////////////////////////////////
    ////// FUNCTIONS FOR USERS //////
    /////////////////////////////////

    /// @dev This function calculates the amount of the ETH or exchange token they will get on swapping them with a certain amount of exchange token or ETH respectively after charging 1% fee for swapping.
    /// @param inputAmount - It is the amount in exchange of which the user wants the other token (can be ETH or exchange token).
    /// @param inputReserve - It is the reserve of the inputAmount token.
    /// @param outputReserve - It is the reserve of the token that the user will get in exchange of inputAmount.

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) internal pure returns (uint256) {
        require(inputAmount > 0, Exchange_AmountIsZero());
        require(
            inputReserve > 0 && outputReserve > 0,
            Exchange_ReservesAreEmpty()
        );
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }

    /// @dev  This function is used to swap the ETH amount on basis of the exchange token amount. This calculation is done by using getAmount function.
    /// @param tokenAmount - It is the amount of exchange tokens against which the user wants to get the ETH.
    /// @param minAmount - It is used because sometimes when many people are using the protocol, the amount of ETH or exchange token can change drastically, so hence the user can get less amount of ETH than he was supposed to get at the start of the transaction. So to prevent user from this condition, the minAmount is used.

    function tokenToEth(uint256 tokenAmount, uint256 minAmount) public nonReentrant {
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = getReserve();
        uint256 ethAmountReceived = getAmount(
            tokenAmount,
            tokenReserve,
            ethReserve
        );
        if (ethAmountReceived < minAmount) {
            revert Exchange_AmountLessThanMinAmount();
        }
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
        payable(msg.sender).transfer(ethAmountReceived);
        emit Exchange_TokenToEthSwapped(msg.sender, tokenAmount, ethAmountReceived);
    }

    /// @dev This function is used to swap the exchange token amount on basis of the ETH amount. This calculation is done by using getAmount function.
    /// @param minAmount - It is used because sometimes when many people are using the protocol, the amount of ETH or exchange token can change drastically, so hence the user can get less amount of exchange token than he was supposed to get at the start of the transaction. So to prevent user from this condition, the minAmount is used.

    function ethToToken(uint256 minAmount) public payable nonReentrant {
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = getReserve();
        uint256 tokenAmountReceived = getAmount(
            msg.value,
            ethReserve,
            tokenReserve
        );
        if (tokenAmountReceived < minAmount) {
            revert Exchange_AmountLessThanMinAmount();
        }
        IERC20(tokenAddress).transfer(msg.sender, tokenAmountReceived);
        emit Exchange_EthToTokenSwapped(msg.sender, msg.value, tokenAmountReceived);
    }

    //////////////////////////////
    ////// GETTER FUNCTIONS //////
    //////////////////////////////

    /// @dev This function gives the total amount of exchange tokens this address (this exchange) holds.

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /// @dev This function gives the total Liquidity token a user holds.

    function getLPTokenBalance(address user) public view returns (uint256) {
        return userToLPTokenBalance[user];
    }
}
