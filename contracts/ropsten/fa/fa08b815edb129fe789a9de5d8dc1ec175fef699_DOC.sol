pragma solidity ^0.4.8;

contract DOC {
    address owner;
    uint public bua_position = 0;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    event new_bua_position (
        uint bua_position
    );
    
    constructor() public {
        owner = msg.sender;
    }
    
    function withdraw() public onlyOwner {
         owner.transfer(address(this).balance);
    }
    
    function select_bua_position(uint _bua_position) public payable {
        require(msg.value > 0 ether);
        bua_position = _bua_position;
        emit new_bua_position(_bua_position);
    }
}