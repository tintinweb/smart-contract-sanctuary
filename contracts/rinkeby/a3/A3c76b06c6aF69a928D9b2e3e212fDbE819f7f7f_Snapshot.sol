// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Snapshot {

    function snapshot(address _contract, uint256 _start, uint256 _end) public view returns(address[] memory){
        ERC721Interface ERC721 = ERC721Interface(_contract);
        address[] memory result = new address[](_end - _start);
        for(uint256 i = 0; i < _end - _start; i++){
            result[i] = ERC721.ownerOf(i);
        }
        return result;
    }

}

contract ERC721Interface{
    function ownerOf(uint256) public view returns(address){}
}