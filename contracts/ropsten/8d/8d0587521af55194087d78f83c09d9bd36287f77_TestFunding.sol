/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

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

contract TestFunding{
    mapping(address => uint) public users;
    address [] public users_list;
    address public owner;
    uint public totalDeposit;
    uint public noOfUsers;
    address allowed_token_address;

    event DepositTokenEvent(address indexed from, address indexed to, uint256 value);
    event WithdrawTokenEvent(address indexed from, address indexed to, uint256 value);

    
    constructor(address _token){
        owner = msg.sender;
        allowed_token_address = _token;

    }

    modifier onlyOwner(){
        require(msg.sender == owner,'You dont have permission to excute this function.');
        _;
    }

    modifier AllowedTokenCheck(IERC20 _token){
        require(IERC20(allowed_token_address) == _token,'This Token is not allowed to deposit and withdraw.');
        _;
    }

    function resetTokens() private{

        for (uint i=0; i< users_list.length ; i++){
        users[users_list[i]] = 0;
    }
    totalDeposit = 0 ;


    }

    function updateAllowedToken(address _token) public onlyOwner{
        allowed_token_address = _token;
        resetTokens();
    }

    function getAllowedToken() public view returns (address){
        return allowed_token_address;
    }

    function checkTokenAllowances(IERC20 _token) public view returns(uint256){
        uint256 allowance = _token.allowance(msg.sender, address(this));
        return allowance;
    }
    
    function depositToken(IERC20 _token,uint _amount) public AllowedTokenCheck(_token){
        require(_amount > 0, "You need to deposit at least some tokens");
        
        uint256 allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");

        if(users[msg.sender] == 0){
            noOfUsers++;
            users_list.push(msg.sender);
        }
        _token.transferFrom(msg.sender,address(this), _amount);
        users[msg.sender]+=_amount;
        totalDeposit  += _amount;
        emit DepositTokenEvent(msg.sender,address(this), _amount);
    }
    
    
    function getUserTokenBalance() public view returns(uint)
    {
     return users[msg.sender];   
    }
    
    function getCurrentUser() public view returns(address)
    {
     return msg.sender;   
    }
    
    function withdrawToken(IERC20 _token,uint _amount) public AllowedTokenCheck(_token)
    {
    require(_amount > 0, "You need to withdraw at least some tokens");
    require(users[msg.sender]>0,'Your are not deposit any token');
    require(users[msg.sender] >= _amount,'Your withdraw token is exeeds your token deposit');
    _token.transfer(msg.sender, _amount);
    totalDeposit -= _amount;
    users[msg.sender] -= _amount;
    emit WithdrawTokenEvent(msg.sender,address(this), _amount);

    }
    
}