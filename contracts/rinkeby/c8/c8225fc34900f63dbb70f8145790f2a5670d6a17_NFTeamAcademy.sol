// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract NFTeamAcademy is ERC1155Supply, Ownable  {

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    bool saleIsActive = false;

    uint constant SILVER_TOKEN_ID = 1;
    uint constant GOLDEN_TOKEN_ID = 2;
    uint constant PLATINUM_TOKEN_ID = 3;

    uint constant MAX_PASSES_PER_PURCHASE = 5;

    uint constant MAX_SILVER_PASSES = 7000;
    uint constant SILVER_PASS_PRICE = 0.03 ether;

    uint constant MAX_GOLDEN_PASSES = 2500;
    uint constant GOLDEN_PASS_PRICE = 0.25 ether;

    uint constant MAX_PLATINUM_PASSES = 500;
    uint constant PLATINUM_PASS_PRICE = 1 ether;

    uint constant MAX_TOKENS = 10000;

    address ownerAddress = 0x7Fe031913A59D3396cF49970B99D24a5Cf0E7159;

    constructor(
        string memory uri,
        string memory _symbol,
        string memory _name
    ) ERC1155(
        uri
    ) { 
        name = _name;
        symbol = _symbol;
    }

    function reserve(uint tokenId, uint qty) external onlyOwner {
       _mint(msg.sender, tokenId, qty, "");
    }

    function burn(address from, uint id, uint qty) external onlyOwner {
       _burn(from, id, qty);
    }

    function setSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function buyPass(uint numberOfTokens, string memory passType) external payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MAX_PASSES_PER_PURCHASE, "Exceeded max token purchase");

        if (compareStrings(passType, "silver")) {
            require(totalSupply(SILVER_TOKEN_ID) + numberOfTokens <= MAX_SILVER_PASSES, "Purchase would exceed max supply of tokens");
            require(SILVER_PASS_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
            _mint(msg.sender, SILVER_TOKEN_ID, numberOfTokens, "");
        } else if (compareStrings(passType, "golden")) {
            require(totalSupply(GOLDEN_TOKEN_ID) + numberOfTokens <= MAX_GOLDEN_PASSES, "Purchase would exceed max supply of tokens");
            require(GOLDEN_PASS_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
            _mint(msg.sender, GOLDEN_TOKEN_ID, numberOfTokens, "");
        } else if (compareStrings(passType, "platinum")) {
            require(totalSupply(PLATINUM_TOKEN_ID) + numberOfTokens <= MAX_PLATINUM_PASSES, "Purchase would exceed max supply of tokens");
            require(PLATINUM_PASS_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
            _mint(msg.sender, PLATINUM_TOKEN_ID, numberOfTokens, "");
        }
    }

    function setUri(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
    }

    function withdraw() external onlyOwner {
        _withdraw(ownerAddress, address(this).balance);
    }

    function _withdraw(address addr, uint256 amount) private {
        (bool success, ) = addr.call{value: amount}("");
        require(success, "TRANSFER_FAIL");
    }
}