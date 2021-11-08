// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/**
 * @title LionKingdom Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract LionKingdom is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    mapping (address => bool) public userWhiteList;
    mapping (address => uint256) public userPrivateTicketList;
    mapping (address => uint256) public userTicketList;

    uint256 public constant totalSaleElement = 10000; // 10K
    uint256 public constant mintPrice = 7 * 10 ** 16; // 0.07 ETH
    uint256 public constant maxPrivateSaleMintQuantity = 5; // 5 LOKs
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

        emit CreateLOKNFT(_to, id);
    }

    /**
     * Mint LOKNFT By User in Pre Sale Ticket
     */
    function preSaleTicket(uint256 mintQuantity)
        public
        payable
        checkPrivateSaleIsActive
        onlyWhiteList
    {
        uint256 userTicketBalance = userTicketList[_msgSender()];

        require(mintQuantity > 0, "Mint Quantity should be more than zero");
        require(mintQuantity <= maxPrivateSaleMintQuantity, "Exceeds Private Sale Amount");
        require(userTicketBalance.add(mintQuantity) <= maxPrivateSaleMintQuantity, "Max Limit To Presale");
        require(userPrivateTicketList[_msgSender()].add(mintQuantity) <= maxPrivateSaleMintQuantity, "Already over Private Sale Amount");
        require(mintPrice.mul(mintQuantity) <= msg.value, "Low Price To Mint");

        userTicketList[_msgSender()] = userTicketList[_msgSender()].add(mintQuantity);
        userPrivateTicketList[_msgSender()] = userTicketList[_msgSender()];
    }

    /**
     * Mint LOKNFT By User in Public
     */
    function publicSaleTicket(uint256 mintQuantity)
        public
        payable
        checkPublicSaleIsActive
    {
        uint256 totalSupply = _totalSupply();
        uint256 userTicketBalance = userTicketList[_msgSender()];

        require(mintQuantity > 0, "Mint Quantity should be more than zero");
        require(totalSupply <= totalSaleElement, "Sale End");
        require(totalSupply.add(mintQuantity) <= totalSaleElement, "Max Limit To Total Sale");
        require(mintQuantity <= maxPublicSaleMintQuantity, "Exceeds Public Sale Amount");
        require(userTicketBalance.add(mintQuantity) <= maxPublicSaleMintQuantity, "Max Public Sale Amount");
        require(mintPrice.mul(mintQuantity) <= msg.value, "Low Price To Mint");

        userTicketList[_msgSender()] = userTicketList[_msgSender()].add(mintQuantity);
    }

    /**
     * Claim LOK NFT
     */
    function claimLOKNFT() external {
        uint256 userTicketBalance = userTicketList[_msgSender()];

        require(userTicketBalance > 0, "User Ticket Balance should be more than zero");
        userTicketList[_msgSender()] = 0;

        for (uint256 i = 0; i < userTicketBalance; i += 1) {
            _mintAnElement(_msgSender());
        }        
    }


    /**
     * Reserve LOKNFT
     */
    function reserve(address _to, uint256 mintQuantity) public onlyOwner {
        uint256 totalSupply = _totalSupply();

        require(totalSupply <= totalSaleElement, "Sale End");
        require(totalSupply + mintQuantity <= totalSaleElement, "Max Limit To Sale");

        for (uint256 i = 0; i < mintQuantity; i += 1) {
            _mintAnElement(_to);
        }
    }

    /**
     * Batch Reserve LOKNFT
     */
    function batchReserve(
        address[] memory mintAddressList,
        uint256[] memory quantityList
    ) external onlyOwner {
        require (mintAddressList.length == quantityList.length, "The length should be same");

        for (uint256 i = 0; i < mintAddressList.length; i += 1) {
            reserve(mintAddressList[i], quantityList[i]);
        }
    }

    /**
     * Withdraw
     */
    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 restAmount = totalBalance;

        uint256 amount1 = totalBalance.mul(7000).div(10000); // 70%
        restAmount = restAmount.sub(amount1);

        uint256 amount2 = totalBalance.mul(2000).div(10000); // 20%
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