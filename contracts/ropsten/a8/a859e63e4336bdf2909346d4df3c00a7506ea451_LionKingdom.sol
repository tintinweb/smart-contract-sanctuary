// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

/**
 * @title LionKingdom Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract LionKingdom is ERC721, Ownable {
    using SafeMath for uint256;

    mapping (address => bool) public userWhiteList;

    uint256 public currentIdTracker;
    uint256 public totalSaleElement; // 10K
    uint256 public constant mintPrice = 7 * 10 ** 16; // 0.07 ETH
    uint256 public constant maxPrivateSaleMintQuantity = 5; // 3 LOKs
    uint256 public constant maxPublicSaleMintQuantity = 30; // 30 LOKs

    address public wallet1;
    address public wallet2;
    address public wallet3;

    bool public publicSaleIsActive;
    bool public privateSaleIsActive;

    event CreateLOKNFT(
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
        address wa1,
        address wa2,
        address wa3
    ) ERC721("Lion Kingdom", "LOKNFT") {
        publicSaleIsActive = false;
        privateSaleIsActive = false;

        wallet1 = wa1;
        wallet2 = wa2;
        wallet3 = wa3;

        totalSaleElement = 10000;
        currentIdTracker = 0;
    }

    /**
     * Set Total Sale Elements, only Owner call it
     */
    function setTotalSaleElement(uint256 newTotalSaleElement) external onlyOwner {
        totalSaleElement = newTotalSaleElement;
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
        return currentIdTracker;
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
        currentIdTracker = currentIdTracker.add(1);
        
        _safeMint(_to, id);

        emit CreateLOKNFT(_to, id);
    }

    /**
     * Mint LOK By User in Private
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
     * Mint LOK By User in Public
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
     * Mint LOK By Owner
     */
    function mintByOwner(address _to, uint256 mintQuantity) public onlyOwner {
        uint256 totalSupply = _totalSupply();

        require(totalSupply <= totalSaleElement, "Presale End");
        require(totalSupply + mintQuantity <= totalSaleElement, "Max Limit To Presale");

        for (uint256 i = 0; i < mintQuantity; i += 1) {
            _mintAnElement(_to);
        }
    }

    /**
     * Batch Mint LOK By Owner
     */
    function batchMintByOwner(
        address[] memory mintAddressList,
        uint256[] memory quantityList
    ) external onlyOwner {
        require (mintAddressList.length == quantityList.length, "The length should be same");

        for (uint256 i = 0; i < mintAddressList.length; i += 1) {
            mintByOwner(mintAddressList[i], quantityList[i]);
        }
    }

    /**
     * Withdraw
     */
    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 restAmount = totalBalance;

        uint256 amount1 = totalBalance.mul(6000).div(10000); // 70%
        restAmount = restAmount.sub(amount1);

        uint256 amount2 = totalBalance.mul(3000).div(10000); // 20%
        restAmount = restAmount.sub(amount2);

        uint256 amount3 = restAmount;                        // 10%

        // Withdraw To Wallet1
        (bool withdrawWallet1, ) = wallet1.call{value: amount1}("");
        require(withdrawWallet1, "Withdraw Failed To Wallet1.");

        // Withdraw To Wallet2
        (bool withdrawWallet2, ) = wallet2.call{value: amount2}("");
        require(withdrawWallet2, "Withdraw Failed To Wallet2");

        // Withdraw To Wallet3
        (bool withdrawWallet3, ) = wallet3.call{value: amount3}("");
        require(withdrawWallet3, "Withdraw Failed To Wallet3");
    }
}