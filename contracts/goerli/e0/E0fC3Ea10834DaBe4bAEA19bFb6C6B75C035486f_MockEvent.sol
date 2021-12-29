pragma solidity =0.7.5;


contract MockEvent {

    event ChessInfo(uint tokenId, uint x, uint y, address user, uint level);

    function sendEvent(uint tokenId, uint x, uint y, address user, uint level) public {
        emit ChessInfo(tokenId, x, y, user, level);
    }

}