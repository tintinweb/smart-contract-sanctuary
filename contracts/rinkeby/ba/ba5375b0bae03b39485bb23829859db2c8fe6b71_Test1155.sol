// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract Test1155 is ERC1155Supply, Ownable  {
    uint constant MAX_TOKENS_PER_PURCHASE = 5;
    uint constant MAX_TOKENS = 10;
    uint constant TOKEN_PRICE = 0.01 ether;
    uint NUM_RESERVED_TOKENS = 2;

    bool public saleIsActive = false;

    uint mintIndex = 0;

    constructor(
        string memory uri
    ) ERC1155(
        uri
    ) { }

    function totalSupply() public view virtual returns (uint256) {
        return mintIndex;
    }

    function reserve(address _to, uint _numberOfTokens) public onlyOwner {
        require(mintIndex <= MAX_TOKENS, "Exceed supply");
        require(_numberOfTokens < NUM_RESERVED_TOKENS, "Exceeded reserved");

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _mint(_to, mintIndex + 1, 1, "");
            mintIndex++;
            NUM_RESERVED_TOKENS--;
        }
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setUri(string memory _newUri) public onlyOwner {
        _setURI(_newUri);
    }
    
    function mint(uint _numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(_numberOfTokens <= MAX_TOKENS_PER_PURCHASE, "Exceeded max token purchase");
        require(TOKEN_PRICE * _numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(mintIndex <= MAX_TOKENS, "Exceed supply");

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _mint(msg.sender, mintIndex + 1, 1, "");
            mintIndex++;
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}