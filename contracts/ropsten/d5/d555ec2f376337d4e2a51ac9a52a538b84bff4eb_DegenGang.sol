// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/**
 * @title DegenGang Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract DegenGang is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    mapping (address => bool) public userWhiteList;

    uint256 public constant totalSaleElement = 7000; // 7K
    uint256 public constant mintPrice = 6 * 10 ** 16; // 0.06 ETH
    uint256 public constant maxPrivateSaleMintQuantity = 3; // 3 DEGGNs
    uint256 public constant maxPublicSaleMintQuantity = 30; // 30 DEGGNs

    address public clientAddress;
    address public devAddress;
    address public teamMemberA;
    address public teamMemberB;
    address public giveawayAddress;

    bool public publicSaleIsActive;
    bool public privateSaleIsActive;

    event CreateDeggn(
        address indexed minter,
        uint256 indexed id
    );

    modifier checkPrivateSaleIsActive {
        require (
            privateSaleIsActive == true,
            "Private Sale is not active"
        );
        _;
    }

    modifier checkPublicSaleIsActive {
        require (
            publicSaleIsActive == true,
            "Public Sale is not active"
        );
        _;
    }

    modifier onlyWhiteList {
        require (
            userWhiteList[msg.sender] == true,
            "You're not in white list"
        );
        _;
    }

    constructor(
        address client,
        address dev,
        address memberA,
        address memberB,
        address giveaway
    ) ERC721("Degen Gang", "DEGGN") {
        publicSaleIsActive = false;
        privateSaleIsActive = false;

        clientAddress = client;
        devAddress = dev;
        teamMemberA = memberA;
        teamMemberB = memberB;
        giveawayAddress = giveaway;
    }

    /**
     * Set Private Sale Status, only Owner call it
     */
    function setPrivateSaleStatus(bool saleStatus) external onlyOwner {
        privateSaleIsActive = saleStatus;
    }

    /**
     * Set Public Sale Status, only Owner call it
     */
    function setPublicSaleStatus(bool saleStatus) external onlyOwner {
        publicSaleIsActive = saleStatus;
    }

    /**
     * Set Base URI, only Owner call it
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * Get Total Supply
     */
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    /**
     * Get Total Mint
     */
    function totalMint() public view returns (uint) {
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
    function getTokensOfOwner(address _owner) public view returns (uint256 [] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIdList = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIdList[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIdList;
    }

    /**
     * Update White List, only Owner call it
     */
    function updateWhiteList(address[] memory addressList) external onlyOwner {
        for (uint256 i = 0; i < addressList.length; i += 1) {
            userWhiteList[addressList[i]] = true;
        }
    }

    /**
     * Mint An Element, Internal Function
     */
    function _mintAnElement(address _to) internal {
        uint256 id = _totalSupply();

        _tokenIdTracker.increment();
        _safeMint(_to, id);

        emit CreateDeggn(_to, id);   
    }

    /**
     * Mint DEGGN By User in Private
     */
    function privateMintByUser(uint256 mintQuantity)
        public
        payable
        checkPrivateSaleIsActive
        onlyWhiteList
    {
        uint256 totalSupply = _totalSupply();
        uint256 balance = balanceOf(_msgSender());

        require(mintQuantity > 0, "Mint Quantity should be more than zero");
        require(totalSupply <= totalSaleElement, "Presale End");
        require(totalSupply + mintQuantity <= totalSaleElement, "Max Limit To Total Sale");
        require(mintQuantity <= maxPrivateSaleMintQuantity, "Exceeds Private Sale Amount");
        require(balance + mintQuantity <= maxPrivateSaleMintQuantity, "Max Limit To Presale");
        require(mintPrice.mul(mintQuantity) <= msg.value, "Low Price To Mint");

        for (uint256 i = 0; i < mintQuantity; i += 1) {
            _mintAnElement(_msgSender());
        }
    }

    /**
     * Mint DEGGN By User in Public
     */
    function publicMintByUser(uint256 mintQuantity)
        public
        payable
        checkPublicSaleIsActive
    {
        uint256 totalSupply = _totalSupply();

        require(mintQuantity > 0, "Mint Quantity should be more than zero");
        require(totalSupply <= totalSaleElement, "Presale End");
        require(totalSupply + mintQuantity <= totalSaleElement, "Max Limit To Total Sale");
        require(mintQuantity <= maxPublicSaleMintQuantity, "Exceeds Public Sale Amount");
        require(mintPrice.mul(mintQuantity) <= msg.value, "Low Price To Mint");

        for (uint256 i = 0; i < mintQuantity; i += 1) {
            _mintAnElement(_msgSender());
        }
    }

    /**
     * Mint DEGGN By Owner
     */
    function mintByOwner(address _to, uint256 _amount) external onlyOwner {
        uint256 totalSupply = _totalSupply();

        require(totalSupply <= totalSaleElement, "Presale End");
        require(totalSupply + _amount <= totalSaleElement, "Max Limit To Presale");

        for (uint256 i = 0; i < _amount; i += 1) {
            _mintAnElement(_to);
        }
    }

    /**
     * Withdraw the Treasury from Presale&Sale, only Owner call it
     */
    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 restAmount = totalBalance;

        uint256 clientAmount = totalBalance.mul(5500).div(10000); // 55%
        restAmount = restAmount.sub(clientAmount);

        uint256 devAmount = totalBalance.mul(2500).div(10000); // 25%
        restAmount = restAmount.sub(devAmount);

        uint256 memberAAmount = totalBalance.mul(500).div(10000); // 5%
        restAmount = restAmount.sub(memberAAmount);

        uint256 memberBAmount = totalBalance.mul(1000).div(10000); // 10%
        restAmount = restAmount.sub(memberBAmount);

        uint256 giveawayAmount = restAmount;    // 5%

        // Withdraw To Client
        (bool withdrawClient, ) = clientAddress.call{value: clientAmount}("");
        require(withdrawClient, "Withdraw Failed To Client.");

        // Withdraw To Dev
        (bool withdrawDev, ) = devAddress.call{value: devAmount}("");
        require(withdrawDev, "Withdraw Failed To Dev");

        // Withdraw To MemberA
        (bool withdrawMemberA, ) = teamMemberA.call{value: memberAAmount}("");
        require(withdrawMemberA, "Withdraw Failed To Member A");

        // Withdraw To MemberB
        (bool withdrawMemberB, ) = teamMemberB.call{value: memberBAmount}("");
        require(withdrawMemberB, "Withdraw Failed To Member B");

        // Withdraw To Giveaway
        (bool withdrawGiveaway, ) = giveawayAddress.call{value: giveawayAmount}("");
        require(withdrawGiveaway, "Withdraw Failed To Giveaway");
    }
}