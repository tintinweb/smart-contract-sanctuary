/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// Peek a book contract used for zkopru private-exchange project.
// Copied from mhchia/peek-a-book

pragma solidity ^0.8.0;

contract PeekABook {
    event Advertise(
        uint adID,
        string indexed pairIndex,
        string pair,
        bool indexed buyOrSell,
        uint amount,
        string peerID,
        address indexed advertiser
    );
    event Invalidate(uint adID);

    uint public maxID;

    mapping (uint => address) public advertisers;

    function advertise(string memory pair, bool buyOrSell, uint amount, string memory peerID) public returns(uint) {
        uint adID = maxID;
        advertisers[adID] = msg.sender;
        emit Advertise(adID, pair, pair, buyOrSell, amount, peerID, msg.sender);
        maxID += 1;
        return adID;
    }

    function invalidate(uint adID) public {
        require(adID < maxID, "advertisement not found");
        address advertiser = advertisers[adID];
        require(advertiser == msg.sender, "advertisement can only be invalidated by its advertiser");
        emit Invalidate(adID);
    }
}