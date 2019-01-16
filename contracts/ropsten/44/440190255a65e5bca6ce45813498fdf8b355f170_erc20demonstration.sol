pragma solidity ^0.5;
// Smart Contract MOOC

contract erc20demonstration {

    mapping (address => uint) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint tokens);

    constructor() payable public {
        balanceOf[msg.sender] = msg.value + 0.5 ether; // Creator starts off with some
    }
    
    function transfer(address _to, uint256 _value) public 
    returns (bool success) {
        require( balanceOf[msg.sender] >= _value );
        balanceOf[msg.sender] -= _value;
        balanceOf[_to]        += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }
    
    function name() public pure returns (string memory) { return "SC-MOOC-19 test token"; }
    function symbol() public pure returns (string memory) { return "scmooc-19"; }
    function decimals() public pure returns (uint8) { return 18; }
    
    // Custom
    
    // take deposits
    function () external payable {
        balanceOf[msg.sender] += msg.value;
    }
    
    // convenience balance check (just a view)
    function checkMyBalance() public view returns(uint) {
        return balanceOf[msg.sender];
    }
    
    // withdraw to eth
    function withdrawETH(uint256 value) public returns (bool) {
        require( balanceOf[msg.sender] >= value );
        balanceOf[msg.sender] -= value;
        msg.sender.transfer(value);
        return true;
    }
}