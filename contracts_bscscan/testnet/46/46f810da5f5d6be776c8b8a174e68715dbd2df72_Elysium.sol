/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

pragma solidity ^0.5.17;

contract Elysium {

    string public name; // token name
    string public symbol; // token symbol
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    uint256 public maxSupply;
    uint8 devFeePercentage;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address=> uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 value);
    event EcoBurn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor() public {
        decimals = 8;
        totalSupply = 100000000000000*10**uint256(decimals);
        maxSupply = 100000000000000*10**uint256(decimals);
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        name = "Elysium";
        symbol = "EMC";
        // devFee = _value/100*5; // for 5% dev fee
        devFeePercentage = 49; // for 49% dev fee
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        require(_value % 100 == 0);
        uint256 devFeeAmount = _value/100*devFeePercentage;
        
        // uint previousBalances = balanceOf[_from] + balanceOf[_to];
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += (_value-devFeeAmount);
        balanceOf[owner] += devFeeAmount;
        
        emit Transfer(_from, _to, _value);
        
        // assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    // spend 3rd party's approved token amount
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value);
        
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        
        return true;
    }
    
    // approve 3rd party to spend/ecoburn your tokens
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    // disappear from blockchain supply forever
    function ecoburn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        
        emit EcoBurn(msg.sender, _value);
        
        return true;
    }
    
    // eco burn tokens of 3rd party
    function ecoburnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        
        emit EcoBurn(_from, _value);
        
        return true;
    }
    
    // generate new tokens (only owner can do it)
    function mint(uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        require(totalSupply + _value <= maxSupply);
        
        balanceOf[owner] += _value;
        totalSupply += _value;
        
        emit Mint(owner, _value);
        
        return true;
    }
    
    // generate new tokens to 3rd party (only owner can do it)
    function mintTo(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        require(_to != address(0));
        require(totalSupply + _value <= maxSupply);
        
        balanceOf[_to] += _value;
        totalSupply += _value;
        
        emit Mint(_to, _value);
        
        return true;
    }
    
    // owner assigns new owner
    function transferOwnership(address newOwner) public returns (bool success) {
        require(newOwner != address(0));
        require(newOwner != owner);
        require(msg.sender == owner);
        
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        
        return success;
    }
    
    // get dev Fee Percentage
    function getTaxPercentage() public returns (uint256){
        return devFeePercentage;
    }
    
    // set dev Fee Percentage
    function setTaxPercentage(uint8 newDevFeePercentage) public returns (bool success){
        require(msg.sender == owner);
        
        devFeePercentage = newDevFeePercentage;
        
        return success;
    }
}