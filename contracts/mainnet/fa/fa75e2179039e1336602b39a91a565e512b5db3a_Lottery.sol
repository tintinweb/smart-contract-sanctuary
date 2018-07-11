pragma solidity ^0.4.21;

/// @title BlockchainCuties lottery
/// @author https://BlockChainArchitect.io
contract Lottery
{
    event Bid(address sender);

    function bid() public
    {
        emit Bid(msg.sender);
    }
}