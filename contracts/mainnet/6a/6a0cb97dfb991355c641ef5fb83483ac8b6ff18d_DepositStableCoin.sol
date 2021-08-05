// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "SafeMath.sol";
import "IERC20.sol";

interface IStableToken
{
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
}

contract DepositStableCoin
{
    using SafeMath for uint256;
    
    address public admin;
    IStableToken public stableToken;
    IERC20 public depositToken;
    
    uint256 public stableTokenReserve;
    uint256 public stableTokenFee;
    uint256 public price;
    uint256 public depositTokensSold;
    
    string private constant ERR_MSG_SENDER = "ERR_MSG_SENDER";
    string private constant ERR_AMOUNT = "ERR_AMOUNT";
    string private constant ERR_ZERO_PAYMENT = "ERR_ZERO_PAYMENT";
    
    event Deposit(uint256 fromAmount,
                  uint256 fromFeeAdd,
                  uint256 actualToAmount,
                  uint256 tokensSold);
    
    constructor(address _admin, address _stableToken, address _depositToken) public
    {
        admin = _admin;
        stableToken = IStableToken(_stableToken);
        depositToken = IERC20(_depositToken);
    }
    
    function changeToken(address _newDepositToken) external
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        depositToken.transfer(admin, depositToken.balanceOf(address(this)));
        
        depositToken = IERC20(_newDepositToken);
    }
    
    function sendStableToken(address _to) external returns (uint256 stableTokenReserveTaken_, uint256 stableTokenFeeTaken_)
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        stableToken.transfer(_to, stableToken.balanceOf(address(this)));
        
        stableTokenReserveTaken_ = stableTokenReserve;
        stableTokenFeeTaken_ = stableTokenFee;
        
        stableTokenReserve = 0;
        stableTokenFee = 0;
    }
    
    function sendDepositTokens(address _to, uint256 _amount) external
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        if(_amount == 0)
        {
            depositToken.transfer(_to, depositToken.balanceOf(address(this)));
        }
        else
        {
            depositToken.transfer(_to, _amount);
        }
    }
    
    function deposit(bool _excludeFee) external
    {
        uint256 stableTokenAmount = stableToken.allowance(msg.sender, address(this));
        require(stableTokenAmount > 0, ERR_ZERO_PAYMENT);
        
        uint256 actualToAmount = stableTokenAmount;
        uint256 stableTokenFeeAdd;
        
        if(!_excludeFee)
        {
            stableTokenFeeAdd = stableTokenAmount.mul(3).div(1000);
            actualToAmount = stableTokenAmount.sub(stableTokenFeeAdd);
        }
            
        require(actualToAmount > 0, "ERR_ZERO_ACTUAL_TO_AMOUNT");
        
        stableToken.transferFrom(msg.sender, address(this), stableTokenAmount);
        
        stableTokenFee = stableTokenFee.add(stableTokenFeeAdd);
        stableTokenReserve = stableTokenReserve.add(stableTokenAmount.sub(stableTokenFeeAdd));
        depositTokensSold = depositTokensSold.add(actualToAmount);
        
        depositToken.transfer(msg.sender, actualToAmount);
     
        emit Deposit(stableTokenAmount, stableTokenFeeAdd, actualToAmount, depositTokensSold);
    }
}