// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "SwapperSimpleBase.sol";
import "SwapPriceCalculatorInterface.sol";

contract Swapper
{
    using SafeMath for uint256;
    
    address private admin;
    IERC20 private token;
    ISwapPriceCalculator private priceCalculator;
    
    uint256 private ethReserve;
    uint256 private ethReserveTaken;
    uint256 private ethFee;
    uint256 private ethFeeTaken;
    uint256 private tokensSold;
    
    string private constant ERR_MSG_SENDER = "ERR_MSG_SENDER";
    string private constant ERR_AMOUNT = "ERR_AMOUNT";
    string private constant ERR_ZERO_ETH = "ERR_ZERO_ETH";
    
    event Swap(uint256 receivedEth,
               uint256 expectedTokens,
               uint16 slippage,
               uint256 ethFeeAdd,
               uint256 actualTokens,
               uint256 tokensSold);
    
    // constructor:
    //--------------------------------------------------------------------------------------------------------------------------
    constructor(address _admin, address _token, address _priceCalculator) public
    {
        admin = _admin;
        token = IERC20(_token);
        priceCalculator = ISwapPriceCalculator(_priceCalculator);
    }
    
    function getAdmin() external view returns (address)
    {
        return admin;
    }
    
    function getToken() external view returns (address)
    {
        return address(token);
    }
    //--------------------------------------------------------------------------------------------------------------------------
    
    // ETH balance methods:
    //--------------------------------------------------------------------------------------------------------------------------
    function getTotalEthBalance() external view returns (uint256)
    {
        return address(this).balance;
    }
    
    function sendEth(address payable _to) external returns (uint256 ethReserveTaken_, uint256 ethFeeTaken_)
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        _to.transfer(address(this).balance);
        
        ethReserveTaken_ = ethReserve - ethReserveTaken;
        ethFeeTaken_ = ethFee - ethFeeTaken;
        
        ethReserveTaken = ethReserve;
        ethFeeTaken = ethFee;
    }
    //--------------------------------------------------------------------------------------------------------------------------
    
    // Tokens balance methods:
    //--------------------------------------------------------------------------------------------------------------------------
    function getTotalTokensBalance() external view returns (uint256)
    {
        return token.balanceOf(address(this));
    }
    
    function sendTokens(address _to, uint256 _amount) external
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        if(_amount == 0)
        {
            token.transfer(_to, token.balanceOf(address(this)));
        }
        else
        {
            token.transfer(_to, _amount);
        }
    }
    //--------------------------------------------------------------------------------------------------------------------------
    
    // Price calculator:
    //--------------------------------------------------------------------------------------------------------------------------
    function getPriceCalculator() external view returns (address)
    {
        return address(priceCalculator);
    }
    
    function setPriceCalculator(address _priceCalculator) external
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        priceCalculator = ISwapPriceCalculator(_priceCalculator);
    }
    
    function calcPrice(uint256 _ethAmount, bool _excludeFee) external view returns (uint256, uint256, uint256)
    {
        require(_ethAmount > 0, ERR_ZERO_ETH);
        
        return priceCalculator.calc(_ethAmount, 0, 0, ethReserve, tokensSold, _excludeFee);
    }
    //--------------------------------------------------------------------------------------------------------------------------
    
    // Current state:
    //--------------------------------------------------------------------------------------------------------------------------
    function getState() external view returns (uint256 ethReserve_,
                                               uint256 ethReserveTaken_,
                                               uint256 ethFee_,
                                               uint256 ethFeeTaken_,
                                               uint256 tokensSold_)
    {
        ethReserve_ = ethReserve;
        ethReserveTaken_ = ethReserveTaken;
        ethFee_ = ethFee;
        ethFeeTaken_ = ethFeeTaken;
        tokensSold_ = tokensSold;
    }
    //--------------------------------------------------------------------------------------------------------------------------
    
    // Swap logic methods:
    //--------------------------------------------------------------------------------------------------------------------------
    function swap(uint256 _expectedTokensAmount, uint16 _slippage, bool _excludeFee) external payable
    {
        require(msg.value > 0, ERR_ZERO_ETH);
        require(_expectedTokensAmount > 0, "ERR_ZERO_EXP_AMOUNT");
        require(_slippage <= 500, "ERR_SLIPPAGE_TOO_BIG");
        
        (uint256 actualTokensAmount, uint256 ethFeeAdd, uint256 actualEthAmount)
            = priceCalculator.calc(msg.value, _expectedTokensAmount, _slippage, ethReserve, tokensSold, _excludeFee);
            
        require(actualTokensAmount > 0, "ERR_ZERO_ACTUAL_TOKENS");
        require(msg.value == actualEthAmount, "ERR_WRONG_ETH_AMOUNT");
        
        ethFee = ethFee.add(ethFeeAdd);
        ethReserve = ethReserve.add(msg.value.sub(ethFeeAdd));
        tokensSold = tokensSold.add(actualTokensAmount);
        
        token.transfer(msg.sender, actualTokensAmount);
     
        emit Swap(msg.value, _expectedTokensAmount, _slippage, ethFeeAdd, actualTokensAmount, tokensSold);
    }
    //--------------------------------------------------------------------------------------------------------------------------
}