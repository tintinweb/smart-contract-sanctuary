pragma solidity ^0.4.23;

contract CryptoPrize {
    uint256 public pings;

    event Ping(uint256 pings);

    // start with 0 budget and 0 Yum for the prize
    constructor() public {
        pings = 0;
    }

    function ping() public {
        pings++;
        emit Ping(pings);
    }
}