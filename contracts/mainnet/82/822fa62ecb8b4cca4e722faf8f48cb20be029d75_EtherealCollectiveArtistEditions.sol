// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract EtherealCollectiveArtistEditions is ERC1155Supply, Ownable  {

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    address ownerAddress = 0x817A17FD73e3e3509FA3D534dBdAFD810b875c4c;

    constructor(
        string memory uri,
        string memory _symbol,
        string memory _name
    ) ERC1155(
        uri
    ) { 
        name = _name;
        symbol = _symbol;
       _mint(ownerAddress, 1, 100, "");
       _mint(ownerAddress, 2, 100, "");
       _mint(ownerAddress, 3, 100, "");
       _mint(ownerAddress, 4, 100, "");
       _mint(ownerAddress, 5, 100, "");
       _mint(ownerAddress, 6, 100, "");
    }

    function setUri(string memory _newUri) public onlyOwner {
        _setURI(_newUri);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}