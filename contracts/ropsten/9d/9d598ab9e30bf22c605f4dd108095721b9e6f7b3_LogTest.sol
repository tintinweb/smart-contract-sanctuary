pragma solidity ^0.4.24;

contract LogTest {
    address private owner;
    uint private idx;
    mapping(address => uint) id;
    mapping(uint => address) ply;
    
    event LogTransferIn(address indexed _addr, uint indexed _value, uint indexed _id);
    event LogTransferOut(address indexed _addr, uint indexed _value, uint indexed _id);
    
    constructor() public {
        owner = msg.sender;
        idx = 0;
    }
    
    function () public payable {
        require(msg.value >= 0.1 ether);
        idx += 1;
        id[msg.sender] = idx;
        ply[idx] = msg.sender;
        
        emit LogTransferIn(msg.sender, msg.value, idx);
    }
    
    function get() public payable {
        require(id[msg.sender] != 0);
        msg.sender.transfer(0.05 ether);
        emit LogTransferOut(msg.sender, 0.05 ether, id[msg.sender]);
    }
    
    function withdraw() public payable {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
    
}