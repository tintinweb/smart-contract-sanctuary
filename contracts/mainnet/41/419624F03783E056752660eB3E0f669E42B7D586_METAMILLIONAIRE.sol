// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/**
 * @title METAMILLIONAIRE Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract METAMILLIONAIRE is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string public PROVENANCE = "";

    uint256 public totalSaleElement;
    uint256 public mintPrice;
    uint256 public maxByMint;

    address public clientAddress;
    address public devAddress;
    bool public saleIsActive;

    event CreateMETAMILLIONAIRE(address indexed minter, uint256 indexed id);

    modifier checkSaleIsActive() {
        require(saleIsActive == true, "Sale is not active");
        _;
    }

    constructor() ERC721("METAMILLIONAIRE", "METAMILLIONAIRE") {
        totalSaleElement = 12000; // 12K
        mintPrice = 7 * 10**16; // 0.07 ETH
        maxByMint = 30;

        saleIsActive = false;

        clientAddress = _msgSender();
        devAddress = 0xE1bF6046BC0F602F8c31E5dd4e090bd959F9B7a4;
    }

    /**
     * Set Sale Status
     */
    function setSaleStatus(bool saleStatus) external onlyOwner {
        saleIsActive = saleStatus;
    }

    function setWithdrawAddress(address _client) external onlyOwner {
        clientAddress = _client;
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
     * Set Base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * Set Base PROVENANCE
     */
    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
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

        emit CreateMETAMILLIONAIRE(_to, id);
    }

    /**
     * Mint METAMILLIONAIRE By User
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
        uint256 devAmount = totalBalance.mul(7).div(100);
        uint256 clientAmount = totalBalance.sub(devAmount);

        (bool withdrawDev, ) = devAddress.call{value: devAmount}("");
        require(withdrawDev, "Withdraw Failed To Dev");
        (bool withdrawClient, ) = clientAddress.call{value: clientAmount}("");
        require(withdrawClient, "Withdraw Failed To Client.");
    }
}