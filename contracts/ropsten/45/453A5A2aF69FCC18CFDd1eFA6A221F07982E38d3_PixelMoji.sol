// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/**
 * @title PixelMoji Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract PixelMoji is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public totalSaleElement;
    uint256 public mintPrice;
    uint256 public maxByMint;
    address public clientAddress;
    address public devAddress;
    bool public saleIsActive;

    event CreatePixelMoji(address indexed minter, uint256 indexed id);

    modifier checkSaleIsActive() {
        require(saleIsActive == true, "Sale is not active");
        _;
    }

    constructor(address wallet1, address wallet2)
        ERC721("PixelMoji", "PixelMoji")
    {
        totalSaleElement = 10000; // 10K
        mintPrice = 6 * 10**16; // 0.06 ETH
        saleIsActive = false;
        maxByMint = 30;

        clientAddress = wallet1;
        devAddress = wallet2;
    }

    /**
     * Set Mint Price
     */
    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    /**
     * Set Max By Mint
     */
    function setMaxByMint(uint256 newMaxByMint) external onlyOwner {
        maxByMint = newMaxByMint;
    }

    /**
     * Set Sale Status
     */
    function setSaleStatus(bool saleStatus) external onlyOwner {
        saleIsActive = saleStatus;
    }

    /**
     * Set Base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * Get Total Supply
     */
    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * Get Total Mint
     */
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Get Tokens Of Owner
     */
    function getTokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIdList = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIdList[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIdList;
    }

    /**
     * Mint An Element
     */
    function _mintAnElement(address _to) internal {
        uint256 id = _totalSupply();

        _tokenIdTracker.increment();
        _safeMint(_to, id);

        emit CreatePixelMoji(_to, id);
    }

    /**
     * Mint PixelMoji By User
     */
    function mintByUser(address _to, uint256 _amount)
        public
        payable
        checkSaleIsActive
    {
        uint256 totalSupply = _totalSupply();

        require(totalSupply <= totalSaleElement, "Presale End");
        require(
            totalSupply + _amount <= totalSaleElement,
            "Max Limit To Presale"
        );
        require(_amount <= maxByMint, "Exceeds Amount");
        require(mintPrice.mul(_amount) <= msg.value, "Low Price To Mint");

        for (uint256 i = 0; i < _amount; i += 1) {
            _mintAnElement(_to);
        }
    }

    /**
     * Withdraw
     */
    function withdrawAll() public onlyOwner {
        uint256 totalBalance = address(this).balance;

        uint256 devAmount = totalBalance.mul(1200).div(10000);
        uint256 clientAmount = totalBalance.sub(devAmount);

        (bool withdrawDev, ) = devAddress.call{value: devAmount}("");
        require(withdrawDev, "Withdraw Failed To Dev");
        (bool withdrawClient, ) = clientAddress.call{value: clientAmount}("");
        require(withdrawClient, "Withdraw Failed To Client.");
    }
}