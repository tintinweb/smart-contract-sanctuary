pragma solidity 0.8.3;

import "./ERC721.sol";

// SPDX-License-Identifier: MIT

contract Exponential is ERC721 {
    
    uint public exponentsMinted;
    address contractCreator;
    string baseURI;
    
    constructor() ERC721("Exponential", "EXP") {
        contractCreator = msg.sender;
        baseURI = "ipfs://QmbuZUpMQGmbyjGH6XstCMcsynxUN4QN7TEzkNHAGDCqnk/";
    }
    
    
    modifier isContractCreator() {
        require(msg.sender == contractCreator);
        _;
    }

    function mint() external payable returns (uint256) {
        require(msg.value == 2 ** exponentsMinted);
        uint id = exponentsMinted++;

        _safeMint(msg.sender, id);
        return id;
    }
    
    
    function _baseURI() internal override view virtual returns (string memory) {
        return baseURI;
    }
    
    function updateBaseURI(string memory uri) external isContractCreator {
        baseURI = uri;
    }
    
    function updateOwner(address newOwner) external isContractCreator {
        contractCreator = newOwner;
    }
    
    function withdrawEarnings() external isContractCreator {
        payable(msg.sender).transfer(address(this).balance);
    }
}