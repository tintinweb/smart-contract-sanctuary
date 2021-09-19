/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

pragma solidity 0.7.6;

contract Tamplate {
    uint public n;
    address public sender;

    function T1( uint _n ) public returns ( bool ) {
        n = _n;
        sender = msg.sender;
        return true;
    }
}

contract Factory {

    Tamplate Tn;
    
    function createNew ( ) public returns ( address ){
        Tamplate T1 = new Tamplate();
        return address( T1 );
    }
}