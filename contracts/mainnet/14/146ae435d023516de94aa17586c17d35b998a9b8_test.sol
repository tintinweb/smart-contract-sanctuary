pragma solidity^0.4.24;


contract test{
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function kill() public onlyOwner {
        uint b = address(this).balance;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         selfdestruct(owner);
    } 
}