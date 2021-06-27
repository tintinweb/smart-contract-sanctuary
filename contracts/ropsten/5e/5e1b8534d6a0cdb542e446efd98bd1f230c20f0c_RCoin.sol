/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract RCoin 
{
    string public constant name = "RCoin";              // Name of Token
    string public constant symbol = "RC";               // Symbol of Token
    uint8 public constant decimals = 4;                 // how many zeros in token. 1 RCoin = 10000 mini-RCoin
    uint public totalSupply = 0;                        // How many coins are present in the network
    mapping(address => uint) balances;                  // Map of balances. balances[Address of your wallet] = Value in mini-RCoin`s
    mapping(address => mapping(address => uint)) allowed;// Map of permissions. allowed[Address from which you can transfer][Address that can transfer] = How many coins
    address payable owner;
    
    event Transfer(address _adr_send, address _adr_get, uint _coins);
    event Approval(address _adr_for_access, address _adr_access, uint _allowed_coins);
    event AccessCoinsChange(uint _access_coins, uint _access_coins_after);
    
    modifier OwnerOnly
    {
        require(msg.sender == owner);
        _;
    }
    modifier CheckPermission(address _adr_for_access, address _adr_access)
    {
        require(allowed[_adr_for_access][_adr_access] > 0);
        _;
    }
    constructor()
    
    {
        owner = payable(msg.sender);
    }
    
    
    function mint(address _Adr, uint _coins) public OwnerOnly payable 
    {
        require(_coins + totalSupply >= totalSupply && balances[_Adr] <= balances[_Adr] + _coins);
        balances[_Adr] += _coins;
        totalSupply += _coins;
    }
    function balanceOf(address _Adr) public view returns(uint)
    {
        return balances[_Adr];
    }
    function balanceOf() public view returns(uint)
    {
        return(balances[msg.sender]);
    }
    function transfer(address _adr_get, uint _coins) public payable
    {
        require(balances[msg.sender] >= _coins && balances[_adr_get] < balances[_adr_get] + _coins);
        balances[msg.sender] -= _coins;
        balances[_adr_get] += _coins;
        emit Transfer(msg.sender, _adr_get, _coins);
    }
    function transferSenderToGetter(address _adr_send, address _adr_get, uint _coins) CheckPermission(msg.sender, _adr_send) public payable
    {
        require(balances[_adr_send] >= _coins && balances[_adr_get] < balances[_adr_get] + _coins);
        balances[_adr_send] -= _coins;
        balances[_adr_get] += _coins;
        allowed[msg.sender][_adr_send] -= _coins;
        emit Transfer(_adr_send, _adr_get, _coins);
        emit AccessCoinsChange(allowed[msg.sender][_adr_send],allowed[msg.sender][_adr_send] - _coins);
    }
    
    function approve(address _adr_access, address _adr_for_access, uint _access_coins) public OwnerOnly payable //Идея такова, что сам создатель токена решает кто имеет право пересылать коины с других кошельков
    {
        allowed[_adr_for_access][_adr_access] = _access_coins;
        emit Approval(_adr_for_access, _adr_access, _access_coins);
    }
    function allowance(address _adr_for_access, address _adr_access) public view returns(uint)
    {
        return allowed[_adr_for_access][_adr_access];
    }
    function convert() public payable // Функция конвертации ETH в Rcoin`s. 1 wei = 20 mini-RCoin
    {
        owner.transfer(msg.value);
        balances[msg.sender] += msg.value  * 20;
        totalSupply += msg.value * 20;
    }
    
}