pragma solidity ^0.4.23;

contract thisIsATest {
    uint256 public aVar_;
    anothertest lalala = anothertest(0x554e38F5c998DF8750ba9Bb64333709A27C3b32c);
    
    function getAvar()
        public
    {
        aVar_ = lalala.giveITup();
    }
}

contract anothertest {
    
    function giveITup()
        public
        pure
        returns(uint256)
    {
        return(42);
    }
}