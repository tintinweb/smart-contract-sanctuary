// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ECDSA.sol";

contract NFTeamAcademy is ERC1155Supply, Ownable  {

    using ECDSA for bytes32;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    bool public saleIsActive = false;
    bool public presaleIsActive = false;

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
    address signerAddress = 0xf972Ea810BdD84DAc591946a1f508b1D1de7AB36;

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

    function setPresaleState() external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function setSignerAddress(address signer) public onlyOwner {
        signerAddress = signer;
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function matchAddresSigner(bytes32 hash, bytes memory signature) public view returns(bool) {
        return signerAddress == hash.recover(signature);
    }

    function buyPass(uint numberOfTokens, string memory passType, bytes memory signature, bytes32 hash) external payable {
        require(saleIsActive && !presaleIsActive, "SALE_CLOSED");
        require(numberOfTokens <= MAX_PASSES_PER_PURCHASE, "EXCEED_PASS_PER_MINT");
        require(matchAddresSigner(hash, signature), "NO_DIRECT_MINT");

        if (compareStrings(passType, "silver")) {
            require(totalSupply(SILVER_TOKEN_ID) + numberOfTokens <= MAX_SILVER_PASSES, "EXCEED_MAX_SALE_SUPPLY");
            require(SILVER_PASS_PRICE * numberOfTokens <= msg.value, "INCORRECT_ETH");
            _mint(msg.sender, SILVER_TOKEN_ID, numberOfTokens, "");
        } else if (compareStrings(passType, "golden")) {
            require(totalSupply(GOLDEN_TOKEN_ID) + numberOfTokens <= MAX_GOLDEN_PASSES, "EXCEED_MAX_SALE_SUPPLY");
            require(GOLDEN_PASS_PRICE * numberOfTokens <= msg.value, "INCORRECT_ETH");
            _mint(msg.sender, GOLDEN_TOKEN_ID, numberOfTokens, "");
        } else if (compareStrings(passType, "platinum")) {
            require(totalSupply(PLATINUM_TOKEN_ID) + numberOfTokens <= MAX_PLATINUM_PASSES, "EXCEED_MAX_SALE_SUPPLY");
            require(PLATINUM_PASS_PRICE * numberOfTokens <= msg.value, "INCORRECT_ETH");
            _mint(msg.sender, PLATINUM_TOKEN_ID, numberOfTokens, "");
        }
    }

    function presaleBuyPass(uint numberOfTokens, string memory passType, bytes memory signature, bytes32 hash) external payable {
        require(!saleIsActive && presaleIsActive, "PRESALE_CLOSED");
        require(numberOfTokens <= MAX_PASSES_PER_PURCHASE, "EXCEED_PASS_PER_MINT");
        require(matchAddresSigner(hash, signature), "NO_DIRECT_MINT");

        if (compareStrings(passType, "silver")) {
            require(totalSupply(SILVER_TOKEN_ID) + numberOfTokens <= MAX_SILVER_PASSES, "EXCEED_MAX_SALE_SUPPLY");
            require(SILVER_PASS_PRICE * numberOfTokens <= msg.value, "INCORRECT_ETH");
            _mint(msg.sender, SILVER_TOKEN_ID, numberOfTokens, "");
        } else if (compareStrings(passType, "golden")) {
            require(totalSupply(GOLDEN_TOKEN_ID) + numberOfTokens <= MAX_GOLDEN_PASSES, "EXCEED_MAX_SALE_SUPPLY");
            require(GOLDEN_PASS_PRICE * numberOfTokens <= msg.value, "INCORRECT_ETH");
            _mint(msg.sender, GOLDEN_TOKEN_ID, numberOfTokens, "");
        } else if (compareStrings(passType, "platinum")) {
            require(totalSupply(PLATINUM_TOKEN_ID) + numberOfTokens <= MAX_PLATINUM_PASSES, "EXCEED_MAX_SALE_SUPPLY");
            require(PLATINUM_PASS_PRICE * numberOfTokens <= msg.value, "INCORRECT_ETH");
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