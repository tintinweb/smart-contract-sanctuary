pragma solidity ^0.4.24;

contract SampleContract
{
    int public y = 100;
    int public x = 200;
    
    function adjustValue() public
    {
        if( x > y )
            x = x - y;
        else
            x = x + y;
    }
}