// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./HashSale.sol";

contract HashNFT is ERC721Enumerable, Ownable {
    string public baseURI = "https://api.rocket.hashbon.com/nft/";
    uint public minIdForMinting;
    uint public tokensForMinting;
    uint public totalTokens;
    uint public minTokensPurchased = 3000 * (10 ** 18);
    mapping(address => bool) public gotFreeToken;
    HashSale crowdSaleContract;

    event TokenMint(address to, uint indexed startId, uint indexed finishId);

    constructor(
        uint _minIdForMinting,
        uint _tokensForMinting,
        uint _totalTokens,
        address _crowdSaleAddress
    ) ERC721("Hashmonauts", "HSMN") {
        minIdForMinting = _minIdForMinting;
        tokensForMinting = _tokensForMinting;
        totalTokens = _totalTokens;
        crowdSaleContract = HashSale(_crowdSaleAddress);
    }

    function mintFreeToken() external {
        require(!gotFreeToken[msg.sender], "You have already got your token");
        require(_checkCrowdsaleParticipation(msg.sender), "You must buy at least 3000 HASH tokens on the crowdsale to get your NFT");
        bool tokenFound = false;
        uint id = minIdForMinting;
        while (id < minIdForMinting + tokensForMinting) {
            if (!_exists(id)) {
                tokenFound = true;
                break;
            }
            id++;
        }
        require(tokenFound == true, "All tokens are already minted");
        _safeMint(msg.sender, id);
        emit TokenMint(msg.sender, id, id);
    }

    function mintTokens(address _to, uint _startId, uint _finishId) external onlyOwner {
        require(_to != address(0), "Incorrect address");
        for (uint id = _startId; id <= _finishId; id++) {
            require(!_exists(id), "The token is already minted");
            _safeMint(msg.sender, id);
        }
        emit TokenMint(msg.sender, _startId, _finishId);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _checkCrowdsaleParticipation(address _customerAddress) internal view returns (bool) {
        uint i = 0;
        uint tokensPurchased = 0;
        while (true) {
            (
                address customerAddress,
                uint payAmount,
                uint tokenAmount,
                bytes memory agreementSignature,
                uint16 referral,
                bool tokensWithdrawn
            ) = crowdSaleContract.sales(i);
            if (customerAddress == _customerAddress) {
                tokensPurchased += tokenAmount;
            }
            if (customerAddress == address(0)) {
                break;
            }
        }
        return tokensPurchased >= minTokensPurchased;
    }
}