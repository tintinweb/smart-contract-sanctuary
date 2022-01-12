/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract owned{
    
    address public owner;
    
    constructor()  {
        owner = msg.sender; 
    }
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) internal onlyOwner {
        owner = newOwner;
    }
    
    
}

contract BasicToken is owned {
    
    uint public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    address[] public trustedMinters;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed _from, address indexed _to, uint tokens);
    event Approval(address indexed _tokenOwner, address indexed _spender, uint tokens);
    event Burn(address indexed _tokenOwner, uint tokens);
    
    constructor(string memory tokenName, string memory tokenSymbol, uint initialSupply) {
        totalSupply = initialSupply*10**uint256(decimals);
        balanceOf[msg.sender] = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    function _transfer(address _from, address _to, uint256 _value) public  {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) public  returns(bool success){
        _transfer(msg.sender,_to, _value);
        return true;
    } 
    
    function transerFrom(address _from, address _to, uint256 _value) public returns(bool success){
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    } 
    
    function approve(address _spender, uint256 _value) public returns(bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function mintToken(address _target, uint256 _mintedAmount)public  {
        require(exists(msg.sender), 'The sender address is not registered as a Minter');
        balanceOf[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        emit Transfer(address(0), owner, _mintedAmount);
        emit Transfer(owner, _target, _mintedAmount);
    }
    
    function burn(address _target, uint256 _value) public returns(bool success){
        require(exists(msg.sender), 'The sender address is not registered as a Minter');
        require(balanceOf[_target] >= _value);
        balanceOf[_target] -= _value;
        totalSupply -= _value;
        emit Burn(_target, _value);
        return true;
    } 

    function addMinter(address _minter) public onlyOwner {
        if(!exists(_minter)){
            trustedMinters.push(_minter);
        }
    }

    function removeMinter(address _minter) public onlyOwner returns (bool) {
        for (uint i = 0; i < trustedMinters.length; i++) {
            if (trustedMinters[i] == _minter) {
                trustedMinters[i] = trustedMinters[trustedMinters.length - 1];
                trustedMinters.pop();
                return true;
            }
        }
        return false;
    }

    function exists(address element) internal view returns (bool) {
        for (uint i = 0; i < trustedMinters.length; i++) {
            if (trustedMinters[i] == element) {
                return true;
            }
        }
        return false;
    }
}