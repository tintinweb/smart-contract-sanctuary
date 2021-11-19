// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPOSDAORandom {
    function collectRoundLength() external view returns(uint256);
    function currentSeed() external view returns(uint256);
    function isCommitPhase() external view returns(bool);
}

contract RandomMock is IPOSDAORandom {
    uint256 private _collectRoundLength;

    constructor(uint256 _roundLength) {
        setCollectRoundLength(_roundLength);
    }

    function collectRoundLength() external override view returns(uint256) {
        return _collectRoundLength;
    }

    function currentSeed() external override view returns(uint256) {
        // solhint-disable-next-line not-rely-on-time
        return uint256(keccak256(abi.encodePacked(block.timestamp)));
    }

    function isCommitPhase() external override view returns(bool) {
        if (_collectRoundLength == 0) {
            return true;
        }
        return (block.number % _collectRoundLength) < (_collectRoundLength / 2);
    }

    function setCollectRoundLength(uint256 _roundLength) public {
        _collectRoundLength = _roundLength;
    }
}