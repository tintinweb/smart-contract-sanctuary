/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract MyToken
{
    string public constant name = "WhiteToken"; // name
    string public constant symbol = "WTK"; // symbol
    uint8 public constant decimals = 5; // nimber of 0s
    uint public totalSupply = 0; // tokens in use now
    uint constant allTokens = 100000000000; // max num of tokens
    
    mapping(address => uint) balances; // num of tokens on the account
    mapping(address => mapping(address => uint)) allowed; // chechs if user is allowed to make transactions
    
    address immutable owner;
    
    event Transfer(address indexed _myAddress, address indexed _anotherUserAddress, uint _numOfTokens);
    event Approval(address indexed _myAddress, address indexed _anotherUserAddress, uint _numOfTokens);
    
    
    modifier checkAllTokens(uint _numOfTokens)
    {
        require(totalSupply + _numOfTokens <= allTokens);
        _;
    }
    
    modifier checkUser()
    {
        require(owner == msg.sender);
        _;
    }
    
    constructor()
    {
        owner = msg.sender;
    }
    
    function mint(address _userAddress, uint _numOfTokens) checkUser checkAllTokens(_numOfTokens) public payable // making new tokens
    {
        totalSupply += _numOfTokens;
        balances[_userAddress] += _numOfTokens;
    }
    
    function balanceOf(address _userAddress) public view returns(uint)
    {
        return balances[_userAddress];
    }
    
    function transfer(address _myAddress, address _anotherUserAddress, uint _numOfTokens) checkAllTokens(_numOfTokens) public payable
    {
        _myAddress = msg.sender;
        require(balances[_myAddress] >= _numOfTokens && balances[_anotherUserAddress] + _numOfTokens >= balances[_anotherUserAddress]);
        balances[_myAddress] -= _numOfTokens;
        balances[_anotherUserAddress] += _numOfTokens;
        emit Transfer(_myAddress, _anotherUserAddress, _numOfTokens);
    }
    
    function transferFrom(address _oneUserAddress, address _anotherUserAddress, uint _numOfTokens) checkAllTokens(_numOfTokens) public payable
    {
        require(balances[_oneUserAddress] >= _numOfTokens && balances[_anotherUserAddress] + _numOfTokens >= balances[_anotherUserAddress]);
        balances[_oneUserAddress] -= _numOfTokens;
        balances[_anotherUserAddress] += _numOfTokens;
        allowed[msg.sender][_anotherUserAddress] -= _numOfTokens;
        emit Transfer(_oneUserAddress, _anotherUserAddress, _numOfTokens);
        emit Approval(msg.sender, _anotherUserAddress, allowed[msg.sender][_anotherUserAddress]);
    }
    
    function approve(address _anotherUserAddress, uint _numOfTokens) public payable
    {
        allowed[msg.sender][_anotherUserAddress] = _numOfTokens;
        emit Approval(msg.sender, _anotherUserAddress, _numOfTokens);
    }
    
    function allowance(address _oneUserAddress, address _anotherUserAddress) public view returns(uint)
    {
        return allowed[_oneUserAddress][_anotherUserAddress];
    }
}