/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract SamToken{

    constructor() {
        myName = "Sam_Token";
        mySymbol = "STZ";
        myDecimals = 0;
        myTotalSupply = 1000;
        balances[msg.sender] = myTotalSupply;   // deployer
        admin = msg.sender;
    }
    address admin;  // deployer
    string myName;
    function name() public view returns (string memory){
        return myName;
    }
    string mySymbol;
    function symbol() public view returns (string memory) {
        return mySymbol;
    }
    uint8 myDecimals;
    function decimals() public view returns (uint8) {
        return myDecimals;
    }
    uint256 myTotalSupply;
    function totalSupply() public view returns (uint256) {
        return myTotalSupply;
    }
    mapping(address => uint256) balances;
    function balanceOf(address _user) public view returns (uint256 balance){
        return balances[_user];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf(msg.sender) >= _value, "Insufficient balance");
   //  require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;

    }
    // run by spender;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>= _value, "Insufficient owner balance");
        require( allowed[_from][msg.sender]>= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from , _to, _value);
        return true;
    }
    // Owner -  0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // spender - 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // _to      - 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping(address => mapping (address => uint256)) allowed;
    // Run by Owner.
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    // increaseAllowance
    // decreaseAllowance

    // mint - To incrase total supply.
    function mint(uint256 _qty) public returns (bool){
        myTotalSupply += _qty;
        // To my wallet.
        balances[msg.sender]+= _qty;

        // To deployer wallet
       // balances[admin] += _qty;
        // to _to wallet.
       // balances[_to] += _qty;
        return true;
    }
    // burn - To decrease total supply.

    function burn(uint256 _qty) public returns (bool) {
         require(balanceOf(msg.sender) >= _qty, "Insufficient balance");
        myTotalSupply -= _qty; 
        balances[msg.sender]-= _qty; 
        return true; 
    
        // burn

    }



}