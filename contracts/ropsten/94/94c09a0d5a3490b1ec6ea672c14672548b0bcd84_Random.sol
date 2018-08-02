pragma solidity ^0.4.24;

contract Random{
    event generateRandom(uint256 randomNumber);

    /**team 5% when someone win*/
    function core() public payable{
        uint random = uint256(keccak256(abi.encodePacked(block.timestamp)));
        emit generateRandom(random);
    }
}