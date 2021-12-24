// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// @title: StickDix.sol
//
//   _____ _____ _____ _____  _   _______ _______   __
//  /  ___|_   _|_   _/  __ \| | / /  _  \_   _\ \ / /
//  \  `--. | |   | | | /  \/| |/ /| | | | | |  \ V / 
//   `--. \ | |   | | | |    |    \| | | | | |  /   \ 
//  /\__/ / | |  _| |_| \__/\| |\  \ |/ / _| |_/ /^\ \
//  \____/  \_/  \___/ \____/\_| \_/___/  \___/\/   \/
//
 
import "./Ownable.sol";
import "./ERC721.sol";
 
contract StickDix is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 6969;
    // 20 for the team, 76 for those that minted early.
    uint256 private constant TOKENS_RESERVED = 96;
    uint256 public constant TOKEN_COST = 0.06969 ether;
    uint256 public constant MAX_MINT_PER_TX = 4;

    bool public isSaleActive;
    uint256 public totalSupply;
    mapping(address => uint256) private mintedPerWallet;

    string public baseUri;

    constructor() ERC721("StickDix", "DIX") {
        // Base IPFS URI of the unrevealed StickDix
        baseUri = "ipfs://QmfRw96NGLU23nhd4nnWGWNvLffopYG3jT8e9SB8TkdQkF/";
        for (uint256 i = 1; i <= TOKENS_RESERVED; ++i) {
            _safeMint(msg.sender, i);
        }
        totalSupply = TOKENS_RESERVED;
    }

    // PUBLIC FUNCTIONS
    function mintDix(uint256 _numTokens) external payable {
        require(isSaleActive, "Sale is not active.");
        require(_numTokens <= MAX_MINT_PER_TX, "May only mint 4 StickDix per TX.");
        require(mintedPerWallet[msg.sender] + _numTokens <= 12, "May only mint 12 per wallet.");
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + _numTokens <= MAX_TOKENS, "Exceeds `MAX_TOKENS`");
        require(_numTokens * TOKEN_COST <= msg.value, "Insufficient ETH funds.");

        for (uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }
        mintedPerWallet[msg.sender] += _numTokens;
        totalSupply += _numTokens;
    }

    // OWNER ONLY FUNCTIONS
    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = balance * 69 / 100;
        uint256 balanceTwo = balance * 19 / 100;
        uint256 balanceThree = balance * 9 / 100;
        uint256 balanceFour = balance - balanceOne - balanceTwo - balanceThree;
        (bool transferOne, ) = payable(0xb091FbBA63C444946E3Cd9a0d546810702511D05).call{value: balanceOne}("");
        (bool transferTwo, ) = payable(0x996D22d34b5D985936526B3901C412A81a4292f6).call{value: balanceTwo}("");
        (bool transferThree, ) = payable(0xDeF5D0c29eb7f754954198DD30b8B2248D8D93Be).call{value: balanceThree}("");
        (bool transferFour, ) = payable(0x1f6a2990121b0c0e278899eCe0824E8068cC1D37).call{value: balanceFour}("");
        require(transferOne && transferTwo && transferThree && transferFour, "Transfer failed.");
    }

    // INTERNAL FUNCTIONS
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}