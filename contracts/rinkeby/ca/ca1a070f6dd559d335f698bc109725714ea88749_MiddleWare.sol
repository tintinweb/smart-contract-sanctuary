/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface LandInterface{
    function decodeTokenId(uint value) external view returns (int, int);
}

interface EstateInterface{
    function getEstateSize(uint256 estateId) external view returns (uint256);
    function estateLandIds(uint256 tokenId, uint256 index) external view returns (uint256);
}

contract MiddleWare{

    address public land;

    address public estate;

    constructor(address _land, address _estate){
        land = _land;
        estate = _estate;
    }

    function getLandData(uint256 estId, uint256 _pageNumber, uint256 pageSize) public view returns(int[] memory x, int[] memory y, uint256[] memory landIds, uint256 pageNumber){
        LandInterface landInterface = LandInterface(land);
        EstateInterface estateInterface = EstateInterface(estate);
        uint256 estateSize = estateInterface.getEstateSize(estId);
        uint256 start = _pageNumber * pageSize;
        uint256 end = ( _pageNumber + 1) * pageSize;
        if(end < estateSize){
            pageNumber = _pageNumber + 1;
        }else{
            end = estateSize;
            pageNumber = 0;
        }
        landIds = new uint256[](end - start);
        x = new int[](end - start);
        y = new int[](end - start);
        uint256 count;
        for(uint256 i=start; i<end; i++){
            landIds[count] = estateInterface.estateLandIds(estId, i);
            (int _x, int _y) = landInterface.decodeTokenId(landIds[count]);
            x[count] = _x;
            y[count] = _y;

            count++;
        }
    }
}