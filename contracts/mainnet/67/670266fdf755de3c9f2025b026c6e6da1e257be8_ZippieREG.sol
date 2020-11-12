pragma solidity >=0.4.22 <0.6.0;
contract ZippieREG {
    /// Delegate your vote to the voter $(to).
    function publish(uint256 stream, bytes memory cid) public {
        emit NewEvent(msg.sender, stream, cid);
    }

    event NewEvent(address indexed publisher, uint256 indexed stream, bytes cid);
}