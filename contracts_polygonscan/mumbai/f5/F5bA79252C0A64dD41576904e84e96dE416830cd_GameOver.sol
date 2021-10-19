// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC1155.sol";
import "Ownable.sol";

contract GameOver is ERC1155, Ownable {
    constructor() ERC1155("http://3.65.36.158/api/token/{id}") {}

    string public name = 'GameOver';
    
    string _contractURI = 'http://3.65.36.158/api/metadata';

    function setContractURI(string memory newuri) public onlyOwner {
        _contractURI = newuri;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}