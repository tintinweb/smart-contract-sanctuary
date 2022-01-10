/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
        
}



contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _previousOwner = _owner ;
        _owner = newOwner;
    }

    function previousOwner() public view returns (address) {
        return _previousOwner;
    }
}

contract CoreCustody is Context,Ownable{
   
    using SafeMath for uint256;


    // address public owner;
    uint public totalDeposit;
    uint public totalHolders;
    address [] public holdersList;

    // accepted tokens 
    mapping (address => bool) public Tokens;
    address [] public TokensList ;

    // storing users token balances
    mapping (address => mapping (address => uint256)) public UserTokens;
    
    mapping(address => bool) private _isBlacklisted;

    bool public _withdrawFlag ;
    bool public _depositFlag ;
    


    // events
    event DepositTokenEvent(address token,address indexed from, address indexed to, uint256 value);
    event WithdrawTokenEvent(address token,address indexed from, address indexed to, uint256 value);

    
    constructor(address _token){
        Tokens[_token] = true;
        TokensList.push(_token);
        _withdrawFlag = true;
        _depositFlag = true;

    }


    modifier AllowedTokenCheck(IERC20 _token){
        require(Tokens[address(_token)],'This Token is not allowed to deposit and withdraw.');
        _;
    }

    function setWithdrawalFlag(bool _bool) external onlyOwner {
        _withdrawFlag = _bool;
    }

    function setDepositFlag(bool _bool) external onlyOwner {
        _depositFlag = _bool;
    }

    function setAddressIsBlackListed(address _address, bool _bool) external onlyOwner {
        _isBlacklisted[_address] = _bool;
    }

    function viewIsBlackListed(address _address) public view returns(bool) {
        return _isBlacklisted[_address];
    }

// this function is for adding new token or modifed exist one 
    function allowedTokens(address _token,bool _flag) public onlyOwner{
        Tokens[_token] = _flag;
        TokensList.push(_token);
    }

   
    function checkTokenAllowances(IERC20 _token) public view returns(uint256){
        uint256 allowance = _token.allowance(msg.sender, address(this));
        return allowance;
    }
    
    function depositToken(IERC20 _token,uint _amount) public AllowedTokenCheck(_token){
        require(_amount > 0, "You need to deposit at least some tokens");
        
        require(_isBlacklisted[msg.sender],"Your Address is blacklisted");
        
        require(_depositFlag,"Deposit is not allowed");


        uint256 allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");

        if(UserTokens[msg.sender][address(_token)] == 0){
            totalHolders++;
            holdersList.push(msg.sender);
        }
        _token.transferFrom(msg.sender,address(this), _amount);
        totalDeposit  += _amount;

        UserTokens[msg.sender][address(_token)] += _amount;

        emit DepositTokenEvent(address(_token),msg.sender,address(this), _amount);
    }
    
    
    function getUserTokenBalance(address _token) public view returns(uint256)
    {
        return UserTokens[msg.sender][address(_token)];   
    }
    
    function getCurrentUser() public view returns(address)
    {
        return msg.sender;   
    }
    
    function withdrawToken(IERC20 _token,uint _amount) public AllowedTokenCheck(_token)
    {
        require(_amount > 0, "You need to withdraw at least some tokens");
        require(_isBlacklisted[msg.sender],"Your Address is blacklisted");
        require(_withdrawFlag,"Withdraw is not allowed");


        require(UserTokens[msg.sender][address(_token)]>0,'Your are not any token Balance');
        require(UserTokens[msg.sender][address(_token)] >= _amount,'Your withdraw token is exeeds your token deposit');
        _token.transfer(msg.sender, _amount);
        totalDeposit -= _amount;

        UserTokens[msg.sender][address(_token)] -= _amount;

        emit WithdrawTokenEvent(address(_token),msg.sender,address(this), _amount);

    }
    
}