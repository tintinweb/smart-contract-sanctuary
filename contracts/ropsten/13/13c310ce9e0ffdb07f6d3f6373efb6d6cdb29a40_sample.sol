pragma solidity 0.4.23;
contract sample{
    uint c;
    function get() public view returns(uint ){
        return c;
    }
    function set(uint a,uint b ) public {
        c=a+b;
    }
    
}