/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract test {
    mapping(address => mapping(uint => uint)) public mymap;
    uint contador=0;
    mapping(address => uint) contadorArr;

    function add(address _address, uint256 tokenId) internal {
        mymap[_address][contador]=tokenId;
        contadorArr[_address]=contadorArr[_address];
    }

    function dele(address _address, uint256 tokenId) internal {
        for (uint i=0; i<contadorArr[_address]; i++) {
            if (mymap[_address][i]==tokenId) {
                delete mymap[_address][i];
            }
        }
    }

    function search(address _address) public view returns(uint256[] memory) {
        uint256[] memory ret = new uint256[](contadorArr[_address]);
        for (uint i=0; i<contadorArr[_address]; i++) {
            ret[i]=mymap[_address][i];
        }
        return ret;
    }
}