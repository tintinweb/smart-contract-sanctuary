/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity 0.8.1;

contract erc20{
    mapping(address => uint) public balance;
    mapping(address => bool) public isLocked;
    uint public totalSupply_;
    uint public decimals = 0;
    string public name = "2 Test Token";
    string public symbol = "2TT";
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor() {
        owner = msg.sender;
        totalSupply_ = 1000000; //Put an initial supply of 1,000,000 tokens
        balance[msg.sender] = totalSupply_;
        emit Transfer(address(0), owner, totalSupply_);
    }
    
    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint){
        return balance[tokenOwner];
    }
    
    function transfer(address recipient, uint amount) public returns(bool){
        require(balance[msg.sender] >= amount, 'Insufficient balance');
        require(!isLocked[msg.sender], 'Your account is locked');
        balance[recipient] += amount;
        balance[msg.sender] -= amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    //Owner functions
    modifier onlyOwner(){
      require(msg.sender == owner, 'This is an owner function');
      _;
    }
    
    function mint(uint amount) public onlyOwner{
        balance[owner] += amount;
        totalSupply_ += amount;
        emit Transfer(address(0), owner, amount);
    }
    
    function lock(address add) public onlyOwner{
        isLocked[add] = true;
    }
    
    function unlock(address add) public onlyOwner{
        isLocked[add] = false;
    }
    
    function burn(uint amount) public onlyOwner{
        require(balance[msg.sender] >= amount, 'Insufficient balance');
        balance[msg.sender] -= amount;
        totalSupply_ -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}