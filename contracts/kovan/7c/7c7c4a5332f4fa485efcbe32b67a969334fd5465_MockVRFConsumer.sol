/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IVRFProvider {
    function requestRandomData(string calldata seed, uint64 time) external payable;
}

interface IVRFConsumer {
    function consume(string calldata seed, uint64 time, bytes32 result) external;
}

abstract contract VRFConsumerBase is IVRFConsumer {
    IVRFProvider public provider;

    function consume(
        string calldata seed,
        uint64 time,
        bytes32 result
    ) external override {
        require(msg.sender == address(provider), "Caller is not the provider");
        _consume(seed, time, result);
    }

    function _consume(
        string calldata seed,
        uint64 time,
        bytes32 result
    ) internal virtual {
        revert("Unimplemented");
    }
}


contract MockVRFConsumer is VRFConsumerBase {
    string public latestSeed;
    uint64 public latestTime;
    bytes32 public latestResult;

    event RandomDataRequested(
        address provider,
        string seed,
        uint64 time,
        uint256 bounty
    );
    event Consume(string seed, uint64 time, bytes32 result);

    constructor(IVRFProvider _provider) public {
        provider = _provider;
    }

    function requestRandomDataFromProvider(string calldata seed, uint64 time)
        external
        payable
    {
        provider.requestRandomData{value: msg.value}(seed, time);

        emit RandomDataRequested(address(provider), seed, time, msg.value);
    }

    function _consume(
        string calldata seed,
        uint64 time,
        bytes32 result
    ) internal override {
        latestSeed = seed;
        latestTime = time;
        latestResult = result;

        emit Consume(seed, time, result);
    }
}