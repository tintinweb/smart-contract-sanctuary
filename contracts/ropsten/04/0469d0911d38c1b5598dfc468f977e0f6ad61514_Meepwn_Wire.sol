pragma solidity ^0.4.18;

contract Meepwn_Wire
{
    address public entrant;
    
    constructor()
    {
        entrant = msg.sender;
    }
    
    function isAccountAddress(address addr) private returns(bool)
    {
        uint x;
        assembly { x := extcodesize(caller) }
        return x == 0;
    }
    
    function exploitMe(bytes8 _key)
    {
        require(msg.sender != tx.origin);
        require(isAccountAddress(msg.sender));
        require(msg.gas % 1337 == 0);
        require(uint64(_key) ^ uint64(sha3(msg.sender)) ^ uint64(sha3(address(this))) == 0x13371337);
        
        entrant = tx.origin;
    }
}