// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "SafeMath.sol";
import "IERC20.sol";

interface IUSDT
{
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
}

contract JasmyDepositSwapper
{
    using SafeMath for uint256;
    
    address public owner;
    
    IUSDT public usdtToken;
    IERC20 public depositToken3; // deposit for 3 months
    IERC20 public depositToken6; // deposit for 6 months
    
    uint256 public ethFee;
    uint256 public usdtFee;
    
    uint256 public depositToken3Reserve;
    uint256 public depositToken6Reserve;
    
    uint256 public ethPrice; // ETH price (18 decimails) for one deposit token (18 decimals)
    uint256 public usdtPrice; // USDT price (6 decimals) for one deposit token (18 decimals)
    
    uint256 private constant DECIMALS = 10**18;
    
    string private constant ERR_MSG_SENDER = "ERR_MSG_SENDER";
    
    event Swap(uint256 fromAmount,
               bool isFromEth, // ETH or USDT
               bool isToToken3, // 3 or 6
               uint256 expectedToTokensAmount,
               uint16 slippage,
               uint256 fromFeeAdd,
               uint256 actualToTokensAmount);
    
    // constructor:
    //--------------------------------------------------------------------------------------------------------------------------------------
    constructor(address _owner,
                address _usdtToken,
                address _depositToken3,
                address _depositToken6,
                uint256 _ethPrice,
                uint256 _usdtPrice,
                uint256 _depositToken3Reserve,
                uint256 _depositToken6Reserve) public
    {
        owner = _owner;
        
        usdtToken = IUSDT(_usdtToken);
        depositToken3 = IERC20(_depositToken3);
        depositToken6 = IERC20(_depositToken6);
        
        ethPrice = _ethPrice;
        usdtPrice = _usdtPrice;
        
        // preset deposit token reserves before mint/transfer:
        
        if(_depositToken3Reserve > 0)
        {
            depositToken3Reserve = _depositToken3Reserve;
        }
        
        if(_depositToken6Reserve > 0)
        {
            depositToken6Reserve = _depositToken6Reserve;
        }
    }
    //--------------------------------------------------------------------------------------------------------------------------------------
    
    // Earnings:
    //--------------------------------------------------------------------------------------------------------------------------------------
    function sendEarnings(address payable _to) external returns (uint256 ethReserveTaken_,
                                                                 uint256 ethFeeTaken_,
                                                                 uint256 usdtReserveTaken_,
                                                                 uint256 usdtFeeTaken_)
    {
        require(msg.sender == owner, ERR_MSG_SENDER);
        
        uint256 ethBalance = address(this).balance;
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        
        if(ethBalance > 0)
        {
            _to.transfer(ethBalance);
        }
        
        if(usdtBalance > 0)
        {
            usdtToken.transfer(_to, usdtBalance);
        }
        
        ethReserveTaken_ = ethBalance - ethFee;
        ethFeeTaken_ = ethFee;
        usdtReserveTaken_ = usdtBalance - usdtFee;
        usdtFeeTaken_ = usdtFee;
        
        ethFee = 0;
        usdtFee = 0;
    }
    //--------------------------------------------------------------------------------------------------------------------------------------
    
    // Reserves:
    //--------------------------------------------------------------------------------------------------------------------------------------
    function setReserves(uint256 _depositToken3Reserve, uint256 _depositToken6Reserve) external
    {
        require(msg.sender == owner, ERR_MSG_SENDER);
        require(_depositToken3Reserve <= depositToken3.balanceOf(address(this))
                && _depositToken6Reserve <= depositToken6.balanceOf(address(this)), "ERR_INVALID_SET_RESERVE_VALUE");
        
        depositToken3Reserve = _depositToken3Reserve;
        depositToken6Reserve = _depositToken6Reserve;
    }
    
    function sendReserves(address _to) external
    {
        require(msg.sender == owner, ERR_MSG_SENDER);
        
        depositToken3Reserve = 0;
        depositToken6Reserve = 0;
        
        depositToken3.transfer(_to, depositToken3.balanceOf(address(this)));
        depositToken6.transfer(_to, depositToken6.balanceOf(address(this)));
    }
    //--------------------------------------------------------------------------------------------------------------------------------------
    
    // Prices:
    //--------------------------------------------------------------------------------------------------------------------------------------
    function setPrices(uint256 _ethPrice, uint256 _usdtPrice) external
    {
        require(msg.sender == owner, ERR_MSG_SENDER);
        
        if(_ethPrice > 0)
        {
            ethPrice = _ethPrice;
        }
        
        if(_usdtPrice > 0)
        {
            usdtPrice = _usdtPrice;
        }
    }
    //--------------------------------------------------------------------------------------------------------------------------------------
    
    // Calculator:
    //--------------------------------------------------------------------------------------------------------------------------------------
    function calcSwap(uint256 _fromAmount, bool _isFromEth, bool _isToToken3) public view returns (uint256 actualToTokensAmount_,
                                                                                                   uint256 fromFeeAdd_,
                                                                                                   uint256 actualFromAmount_)
    {
        require(_fromAmount > 0, "ERR_ZERO_PAYMENT");
        
        actualFromAmount_ = _fromAmount;
        
        fromFeeAdd_ = _fromAmount.mul(3).div(1000);
        _fromAmount = _fromAmount.sub(fromFeeAdd_);
        
        actualToTokensAmount_ = _fromAmount.mul(DECIMALS).div(_isFromEth ? ethPrice : usdtPrice);
        
        uint256 toTokensReserve = _isToToken3 ? depositToken3Reserve : depositToken6Reserve;
        if(actualToTokensAmount_ > toTokensReserve)
        {
            actualToTokensAmount_ = toTokensReserve;
            actualFromAmount_ = toTokensReserve.mul(_isFromEth ? ethPrice : usdtPrice).div(DECIMALS);
            
            fromFeeAdd_ = actualFromAmount_.mul(3).div(1000);
            actualFromAmount_ = actualFromAmount_.add(fromFeeAdd_);
        }
    }
    //--------------------------------------------------------------------------------------------------------------------------------------
    
    // Swap:
    //--------------------------------------------------------------------------------------------------------------------------------------
    function swapEthToDepositToken(bool _isToToken3, uint256 _expectedToTokensAmount, uint16 _slippage) external payable
    {
        ethFee = ethFee.add(swap(msg.value, true, _isToToken3, _expectedToTokensAmount, _slippage));
    }
    
    function swapUsdtToDepositToken(bool _isToToken3, uint256 _expectedToTokensAmount, uint16 _slippage) external
    {
        uint256 usdtAmount = usdtToken.allowance(msg.sender, address(this));
        usdtToken.transferFrom(msg.sender, address(this), usdtAmount);
        
        usdtFee = usdtFee.add(swap(usdtAmount, false, _isToToken3, _expectedToTokensAmount, _slippage));
    }
    
    function swap(uint256 _fromAmount,
                  bool _isFromEth, // ETH or USDT
                  bool _isToToken3, // 3 or 6
                  uint256 _expectedToTokensAmount,
                  uint16 _slippage) private returns (uint256 fromFeeAdd_)
    {
        //require(_fromAmount > 0, "ERR_ZERO_PAYMENT"); // will be checked in calcSwap
        require(_expectedToTokensAmount > 0, "ERR_ZERO_EXPECTED_AMOUNT");
        require(_slippage <= 500, "ERR_SLIPPAGE_TOO_BIG");
        
        (uint256 actualToTokensAmount, uint256 fromFeeAdd, uint256 actualFromAmount)
            = calcSwap(_fromAmount, _isFromEth, _isToToken3);
            
        require(actualToTokensAmount > 0, "ERR_ZERO_ACTUAL_TOKENS");
        require(_fromAmount == actualFromAmount, "ERR_WRONG_PAYMENT_AMOUNT");
        
        require((actualToTokensAmount >= _expectedToTokensAmount)
                || (uint256(1000).mul(_expectedToTokensAmount.sub(actualToTokensAmount)) <= _expectedToTokensAmount.mul(_slippage)),
                "ERR_SLIPPAGE");
                
        if(_isToToken3)
        {
            depositToken3Reserve = depositToken3Reserve.sub(actualToTokensAmount);
            depositToken3.transfer(msg.sender, actualToTokensAmount);
        }
        else
        {
            depositToken6Reserve = depositToken6Reserve.sub(actualToTokensAmount);
            depositToken6.transfer(msg.sender, actualToTokensAmount);
        }
        
        fromFeeAdd_ = fromFeeAdd;
        
        emit Swap(_fromAmount, _isFromEth, _isToToken3, _expectedToTokensAmount, _slippage, fromFeeAdd_, actualToTokensAmount);
    }
    //--------------------------------------------------------------------------------------------------------------------------------------
}