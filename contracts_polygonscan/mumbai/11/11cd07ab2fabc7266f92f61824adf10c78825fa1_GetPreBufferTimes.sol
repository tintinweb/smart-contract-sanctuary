/**
 *Submitted for verification at polygonscan.com on 2021-08-06
*/

pragma solidity 0.5.7;

interface IMarket {
    function createMarket(uint32 _currencyTypeIndex, uint32 _marketTypeIndex, uint80 _roundId) external;
}

contract GetPreBufferTimes {
    function getPreBufferTimes(uint32[] memory _currencyIndexes, uint32[] memory _marketTypes, address _marketCreatorContract) public{
        require(_currencyIndexes.length == _marketTypes.length);
        for(uint64 i = 0; i< _marketTypes.length; i++) {
            IMarket(_marketCreatorContract).createMarket(_currencyIndexes[i], _marketTypes[i], 0);
        }
    }
}