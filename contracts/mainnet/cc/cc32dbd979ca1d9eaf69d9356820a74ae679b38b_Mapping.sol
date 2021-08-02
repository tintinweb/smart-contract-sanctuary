/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: MIT

// THIRM PROTOCOL MAP

pragma solidity ^0.8.3;

interface ENS {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mint(address to, uint256 amount) external;
}


contract Mapping {

    uint256 public lastTimeExecuted = block.timestamp;

    mapping(string => address) private addressMap;

    function nftOwner() public view returns (address) {
        return ENS(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85).ownerOf(77518759032194629606678436102314512673279501256913318464318261388698786067419);
    }
    
     function toMint() public view returns (uint256) {
        uint256 toMintint = block.timestamp - lastTimeExecuted;
        return toMintint * 120000000000000;
    }

    function getAddressMap(string memory _coinAddress) public view returns (address) {
        return addressMap[_coinAddress];
    }

    function setAddressMap(string memory _coinaddress) external {
        require(addressMap[_coinaddress] == address(0), "Address already mapped");
        addressMap[_coinaddress] = msg.sender;
    }

    function run(address _token) external {
        ENS(_token).mint(nftOwner(), toMint());
        lastTimeExecuted = block.timestamp;
    }
}