/**
 *Submitted for verification at polygonscan.com on 2021-08-05
*/

pragma solidity 0.5.7;

interface IMarket {
    function marketCreationPreBuffer(uint _marketType) external view returns(uint _bufferTime);
}

contract GetPreBufferTimes {
    function getPreBufferTimes(uint[] memory _marketTypes, address _cyclicMarketAddress) public view
    returns(uint[] memory _bufferTimes) {
        _bufferTimes = new uint[](_marketTypes.length);
        for(uint64 i = 0; i< _marketTypes.length; i++) {
            _bufferTimes[i] = IMarket(_cyclicMarketAddress).marketCreationPreBuffer(_marketTypes[i]);
        }
    }
}