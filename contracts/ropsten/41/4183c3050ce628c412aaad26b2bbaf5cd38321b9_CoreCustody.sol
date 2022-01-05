/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

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

contract CoreCustody{
   
    address public owner;
    uint public totalDeposit;
    uint public totalHolders;
    address [] public holdersList;

    // accepted tokens 
    mapping (address => bool) public Tokens;
    address [] public TokensList ;
    // storing users token balances

    mapping (address => mapping (address => uint256)) public UserTokens;

    // events
    event DepositTokenEvent(address token,address indexed from, address indexed to, uint256 value);
    event WithdrawTokenEvent(address token,address indexed from, address indexed to, uint256 value);

    
    constructor(address _token){
        owner = msg.sender;
        Tokens[_token] = true;
        TokensList.push(_token);

    }

    modifier onlyOwner(){
        require(msg.sender == owner,'You dont have permission to excute this function.');
        _;
    }

    modifier AllowedTokenCheck(IERC20 _token){
        require(Tokens[address(_token)],'This Token is not allowed to deposit and withdraw.');
        _;
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
    require(UserTokens[msg.sender][address(_token)]>0,'Your are not deposit any token');
    require(UserTokens[msg.sender][address(_token)] >= _amount,'Your withdraw token is exeeds your token deposit');
    _token.transfer(msg.sender, _amount);
    totalDeposit -= _amount;

    UserTokens[msg.sender][address(_token)] -= _amount;

    emit WithdrawTokenEvent(address(_token),msg.sender,address(this), _amount);

    }
    
}