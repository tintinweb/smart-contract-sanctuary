// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/**
 * @title Battle Of Ages Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract BOA is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string public PROVENANCE = "";

    uint256 public totalSaleElement;
    uint256 public mintPrice;
    uint256 public maxByMint;

    bool public saleIsActive;

    address private weth;
    address public clientAddress;
    address public devAddress;

    event CreateBOA(address indexed minter, uint256 indexed id);

    modifier checkSaleIsActive() {
        require(saleIsActive == true, "Sale is not active");
        _;
    }

    constructor() ERC721("Battle Of Ages", "BOA") {
        totalSaleElement = 10000;
        mintPrice = 7 * 10**16; // 0.05 WETH
        maxByMint = 30;

        saleIsActive = false;

        weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; // WETH
        clientAddress = _msgSender();
        devAddress = _msgSender();
    }

    /**
     * Set Sale Status
     */
    function setSaleStatus(bool saleStatus) external onlyOwner {
        saleIsActive = saleStatus;
    }

    /**
     * Set WEH
     */
    function setWEHAddress(address _weth) external onlyOwner {
        weth = _weth;
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
     * Set Mint Price
     */
    function setTotalSupply(uint256 totalSupply) external onlyOwner {
        totalSaleElement = totalSupply;
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

        emit CreateBOA(_to, id);
    }

    /**
     * Mint BOA By User
     */
    function mintByUser(
        address _to,
        uint256 _amount,
        uint256 _wethAmount
    ) public payable checkSaleIsActive {
        uint256 totalSupply = _totalSupply();

        require(totalSupply <= totalSaleElement, "Presale End");
        require(
            totalSupply + _amount <= totalSaleElement,
            "Max Limit To Presale"
        );
        require(_amount <= maxByMint, "Exceeds Amount");
        require(_wethAmount == mintPrice.mul(_amount), "Not correct Price");
        require(
            IERC20(weth).allowance(msg.sender, address(this)) >= _wethAmount,
            "Low Price To Mint"
        );

        IERC20(weth).transferFrom(_to, address(this), _wethAmount);

        for (uint256 i = 0; i < _amount; i += 1) {
            _mintAnElement(_to);
        }
    }

    /**
     * Mint BOA By Owner
     */
    function mintByOwner(address _to, uint256 _amount) external onlyOwner {
        uint256 totalSupply = _totalSupply();

        require(totalSupply <= totalSaleElement, "Presale End");
        require(
            totalSupply + _amount <= totalSaleElement,
            "Max Limit To Presale"
        );

        for (uint256 i = 0; i < _amount; i += 1) {
            _mintAnElement(_to);
        }
    }

    /**
     * Withdraw
     */
    function withdrawAll() public onlyOwner {
        uint256 totalBalance = IERC20(weth).balanceOf(address(this));

        uint256 devAmount = totalBalance.mul(20).div(100);
        uint256 clientAmount = totalBalance.sub(devAmount);

        IERC20(weth).transfer(devAddress, devAmount);
        IERC20(weth).transfer(clientAddress, clientAmount);
    }
}