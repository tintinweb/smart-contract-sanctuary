//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MelonMarketplace.sol";

import {MelonLibrary} from "./libraries/MelonLibrary.sol";

contract MelonNFT is ERC721Upgradeable, AccessControlUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    // IERC20 private melonToken;
    // NFTEnglishAuction public englishAuction;

    using ECDSA for bytes32;
    using Strings for uint256;
    using SafeMath for uint256;

    // mapping(uint256 => MelonLibrary.NFT_MODEL) public tokens;

    string private _baseURIextended;

    address payable private platformAddress;

    address private marketplaceAddress;
    MelonMarketplace private MarketplaceContract;
    // address private dutchAuctionAddress;
    // address private englishAuctionAddress;

    modifier platformOnly() {
        require(msg.sender == platformAddress, "you're not a super-admin!");
        _;
    }

    // modifier adminOnly(uint256 tokenID) {
    //     require(hasRole(ADMIN_ROLE, msg.sender), "caller is not an admin!");
    //     _;
    // }

    // modifier adminOrOwner(uint256 tokenID) {
    //     require(hasRole(ADMIN_ROLE, msg.sender) || ownerOf(tokenID) == msg.sender || msg.sender == marketplaceAddress);
    //     _;
    // }

    // modifier adminOrOwnerMultiple(uint256[] calldata tokensIDs) {
    //     for (uint256 index = 0; index < tokensIDs.length; index++) {
    //         require(
    //             hasRole(ADMIN_ROLE, msg.sender) || msg.sender == tokens[tokensIDs[index]].owner || msg.sender == englishAuctionAddress,
    //             "caller is not an admin or owner for at least one token!"
    //         );
    //     }
    //     _;
    // }

    // event TokensMinted(
    //     uint256[] ids,
    //     uint256[] price,
    //     uint256[] symbol,
    //     SaleStatuses saleStatus,
    //     address creator,
    //     address payable[] referralAddress,
    //     uint256 referralFee,
    //     uint256 timestamp
    // );

    event TokenBought(uint256 tokenID, address buyer, uint256 timestamp);

    event SaleStatusChanged(uint256 tokenID, MelonLibrary.SaleStatuses saleStatus, uint256 symbol, uint256 value, uint256 timestamp);

    event SaleStatusChangedMultiple(uint256[] tokensIDs, MelonLibrary.SaleStatuses saleStatus, uint256 symbol, uint256 value, uint256 timestamp);

    event ReferralFeeChanged(uint256 tokenID, uint256 referralFee, address payable[] referralAddress, uint256 timestamp);

    function initialize(
        string memory baseURI,
        // address _tokenAddress,
        // address _englishAuctionAddress,
        address _marketplaceAddress,
        address payable _platformAddress
    ) public initializer {
        __ERC721_init("Melon Marketplace", "MMRKT");
        __AccessControl_init();
        // melonToken = IERC20(_tokenAddress);
        platformAddress = _platformAddress;
        _baseURIextended = baseURI;
        marketplaceAddress = _marketplaceAddress;
        MarketplaceContract = MelonMarketplace(_marketplaceAddress);
        // englishAuction = NFTEnglishAuction(_englishAuctionAddress);
        // englishAuctionAddress = _englishAuctionAddress;
        __Ownable_init_unchained();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory)  {
        require(_exists(tokenID), "URI set of nonexistent token");
        return string(abi.encodePacked(_baseURIextended, tokenID.toString()));
    }

    function contractURI() public view returns (string memory) {
      return "ipfs://QmdYm3mp4cvgXbDRsBfTgF1rHPXnS8iWM98NSAf3oyExkn";
    }

    function mint(address creator, uint256 id) public {
        require(!_exists(id), "Token already exists");
        require(msg.sender == marketplaceAddress, "Only marketplace can mint");
        _safeMint(creator, id);
    }

    function burn(uint256 tokenID) public {
        require(msg.sender == marketplaceAddress || msg.sender == ownerOf(tokenID), "Only marketplace or owner can burn");
        require(_exists(tokenID), "Token already exists");
        _burn(tokenID);
    }

    // function mintToken(
    //     MelonLibrary.NFT_MODEL memory nftModel,
    //     uint256[] memory ids,
    //     bytes calldata signIds,
    //     bytes calldata signFee
    // ) public nonReentrant {
    //     for (uint256 index = 0; index < ids.length; index++) require(bytes(abi.encodePacked(tokens[ids[index]].owner)).length > 0, "at least one token already exists");
    //     require(_verifyMint(ids, signIds), "NFT params are not valid");
    //     if (bytes(abi.encodePacked(signFee)).length > 0) {
    //         require(nftModel.referralFee >= 0 && nftModel.referralFee <= 90, "fee must be above 0 and below 90%!");
    //         require(bytes(abi.encodePacked(nftModel.referralAddress)).length > 0, "sign is fine, but address is empty!");
    //         require(_verifyFee(nftModel.referralFee, nftModel.referralAddress, signFee), "fee sign is not valid!");
    //     } else {
    //         require(nftModel.referralAddress.length == 0, "sign is empty, but address is there!");
    //         require(nftModel.referralFee == 0, "sign is empty, but fee is not null!");
    //     }
    //     if (nftModel.saleStatus == MelonLibrary.SaleStatuses.FIX_PRICE)
    //         require(
    //             nftModel.price.length > 0 && nftModel.symbol.length > 0 && (nftModel.symbol[0] == MelonLibrary.MATIC || nftModel.symbol[0] == MelonLibrary.MELON),
    //             "item can not be for sale without a price"
    //         );

    //     if (!hasRole(ADMIN_ROLE, msg.sender)) require(msg.sender == nftModel.owner && msg.sender == nftModel.creator, "you're not owner nor creator!");

    //     uint256[] memory localSymbol = new uint256[](1);
    //     uint256[] memory localPrice = new uint256[](1);

    //     if (nftModel.saleStatus == MelonLibrary.SaleStatuses.FIX_PRICE) {
    //         localSymbol = nftModel.symbol;
    //         localPrice = nftModel.price;
    //     }

    //     for (uint256 index = 0; index < ids.length; index++) {
    //         uint256 currentId = ids[index];
    //         MelonLibrary.NFT_MODEL memory token =
    //             MelonLibrary.NFT_MODEL({
    //                 symbol: localSymbol,
    //                 price: localPrice,
    //                 owner: payable(nftModel.creator),
    //                 creator: payable(nftModel.creator),
    //                 isFirstSale: true,
    //                 referralFee: nftModel.referralFee,
    //                 referralAddress: nftModel.referralAddress,
    //                 saleStatus: nftModel.saleStatus
    //             });
    //         tokens[currentId] = token;
    //         _safeMint(nftModel.creator, ids[index]);
    //     }

        // emit TokensMinted(ids, nftModel.price, nftModel.symbol, nftModel.saleStatus, nftModel.creator, nftModel.referralAddress, nftModel.referralFee, block.timestamp);
    // }

    // function mintWithEnglishAuction(
    //     NFT_MODEL memory nftModel,
    //     uint256[] calldata tokenIDs,
    //     uint256 symbol,
    //     uint256 minBid,
    //     uint256 reservePrice,
    //     uint256 auctionDuration,
    //     bytes calldata signIds,
    //     bytes calldata signFee
    // ) external {
    //     require(nftModel.saleStatus == SaleStatuses.NOT_ON_SALE, "token must not be on sale!");
    //     require(nftModel.price.length == 0, "token price should not be set!");

    //     mintToken(nftModel, tokenIDs, signIds, signFee);
    //     approveMultiple(tokenIDs, englishAuctionAddress);
    //     englishAuction.createAuction(tokenIDs, symbol, minBid, reservePrice, auctionDuration);
    //     for (uint256 index = 0; index < tokenIDs.length; index++) tokens[tokenIDs[index]].saleStatus = SaleStatuses.ENGLISH_AUCTION;
    // }

    // function _verifyMint(uint256[] memory ids, bytes calldata sign) internal view returns (bool) {
    //     bytes32 b = keccak256(abi.encode(ids));
    //     return b.toEthSignedMessageHash().recover(sign) == platformAddress;
    // }

    // function _verifyFee(
    //     uint256 fee,
    //     address payable[] memory referralAddress,
    //     bytes calldata sign
    // ) internal view returns (bool) {
    //     bytes32 b = keccak256(abi.encode(fee, referralAddress[0]));
    //     return b.toEthSignedMessageHash().recover(sign) == platformAddress;
    // }

    // function buyWithMelon(uint256 tokenID) external {
    //     require(tokens[tokenID].saleStatus == SaleStatuses.FIX_PRICE, "this token is not for sale!");
    //     require(tokens[tokenID].price.length > 0, "price for the NFT has not been set!");
    //     require(tokens[tokenID].symbol.length > 0, "the symbol for the NFT has not been specified!");
    //     require(tokens[tokenID].symbol[0] == MelonLibrary.MELON, "wrong currency selected!");
    //     require(tokens[tokenID].owner != address(0), "you're trying to sell to zero-address");

    //     uint256 referralFeeTotal = 0;

    //     if (tokens[tokenID].isFirstSale && bytes(abi.encodePacked(tokens[tokenID].referralAddress)).length > 0) {
    //         referralFeeTotal = tokens[tokenID].price[0].mul(tokens[tokenID].referralFee).div(100);
    //         melonToken.transferFrom(msg.sender, tokens[tokenID].referralAddress[0], referralFeeTotal);
    //         tokens[tokenID].isFirstSale = false;
    //     }

    //     melonToken.transferFrom(msg.sender, tokens[tokenID].owner, tokens[tokenID].price[0].sub(referralFeeTotal));
    //     _transfer(tokens[tokenID].owner, msg.sender, tokenID);
    //     tokens[tokenID].owner = payable(msg.sender);
    //     tokens[tokenID].saleStatus = SaleStatuses.NOT_ON_SALE;
    //     emit TokenBought(tokenID, msg.sender, block.timestamp);
    // }

    // function buy(uint256 tokenID) external payable {
    //     require(tokens[tokenID].saleStatus == SaleStatuses.FIX_PRICE, "this token is not for sale!");
    //     require(tokens[tokenID].price.length > 0, "price for the NFT has not been set!");
    //     require(tokens[tokenID].symbol.length > 0, "the symbol for the NFT has not been specified!");
    //     require(tokens[tokenID].symbol[0] == MelonLibrary.MATIC, "wrong currency selected!");
    //     require(tokens[tokenID].owner != address(0), "you're trying to sell to zero-address");
    //     require(msg.value >= tokens[tokenID].price[0], "insufficient funds!");

    //     uint256 comissionValue = tokens[tokenID].price[0].mul(25).div(1000);
    //     uint256 referralFeeTotal = 0;
    //     feesAddress.transfer(comissionValue);

    //     if (tokens[tokenID].isFirstSale && bytes(abi.encodePacked(tokens[tokenID].referralAddress)).length > 0) {
    //         referralFeeTotal = tokens[tokenID].price[0].mul(tokens[tokenID].referralFee).div(100);
    //         tokens[tokenID].referralAddress[0].transfer(referralFeeTotal);
    //         tokens[tokenID].isFirstSale = false;
    //     }
    //     tokens[tokenID].owner.transfer(tokens[tokenID].price[0].sub(comissionValue + referralFeeTotal));
    //     _transfer(tokens[tokenID].owner, msg.sender, tokenID);
    //     tokens[tokenID].owner = payable(msg.sender);
    //     tokens[tokenID].saleStatus = SaleStatuses.NOT_ON_SALE;

    //     emit TokenBought(tokenID, msg.sender, block.timestamp);
    // }

    // function setForSale(
    //     uint256 price,
    //     uint256 symbol,
    //     uint256 tokenID
    // ) external adminOrOwner(tokenID) {
    //     require(tokens[tokenID].saleStatus == SaleStatuses.NOT_ON_SALE, "this token is on sale");
    //     require(price > 0, "you didn't pass on the price!");
    //     require(symbol == MelonLibrary.MATIC || symbol == MelonLibrary.MELON, "the symbol for the NFT has not been specified!");
    //     tokens[tokenID].saleStatus = SaleStatuses.FIX_PRICE;
    //     tokens[tokenID].price = [price];
    //     tokens[tokenID].symbol = [symbol];

    //     emit SaleStatusChanged(tokenID, SaleStatuses.FIX_PRICE, symbol, price, block.timestamp);
    // }

    // function setForSaleMultiple(
    //     uint256 price,
    //     uint256 symbol,
    //     uint256[] calldata tokensIDs
    // ) external adminOrOwnerMultiple(tokensIDs) {
    //     for (uint256 index = 0; index < tokensIDs.length; index++) {
    //         require(_exists(tokensIDs[index]), "URI set of nonexistent token");
    //         require(tokens[tokensIDs[index]].saleStatus == SaleStatuses.NOT_ON_SALE, "this token is on sale");
    //         require(price > 0, "you didn't pass on the price!");
    //         require(symbol == MelonLibrary.MATIC || symbol == MelonLibrary.MELON, "the symbol for the NFT has not been specified!");
    //         tokens[tokensIDs[index]].saleStatus = SaleStatuses.FIX_PRICE;
    //         tokens[tokensIDs[index]].price = [price];
    //         tokens[tokensIDs[index]].symbol = [symbol];
    //     }
    //     emit SaleStatusChangedMultiple(tokensIDs, SaleStatuses.FIX_PRICE, symbol, price, block.timestamp);
    // }

    // function withdrawFromSale(uint256 tokenID) external adminOrOwner(tokenID) {
    //     require(tokens[tokenID].saleStatus == SaleStatuses.FIX_PRICE, "this token is not on sale");

    //     tokens[tokenID].saleStatus = SaleStatuses.NOT_ON_SALE;

    //     emit SaleStatusChanged(tokenID, SaleStatuses.NOT_ON_SALE, tokens[tokenID].symbol[0], tokens[tokenID].price[0], block.timestamp);
    // }

    // function setPrice(uint256 price, uint256 tokenID) external adminOrOwner(tokenID) {
    //     require(price > 0, "you didn't pass on the price!");
    //     require(tokens[tokenID].saleStatus == SaleStatuses.FIX_PRICE, "token must be on sale!");

    //     tokens[tokenID].price = [price];
    //     emit SaleStatusChanged(tokenID, tokens[tokenID].saleStatus, tokens[tokenID].symbol[0], price, block.timestamp);
    // }

    // function setReferralFee(
    //     address payable[] memory referralAddress,
    //     uint256 fee,
    //     uint256 tokenID,
    //     bytes calldata signFee
    // ) external adminOnly(tokenID) {
    //     require(tokens[tokenID].isFirstSale, "this token was already on sale!");
    //     if (bytes(abi.encodePacked(signFee)).length > 0) {
    //         require(bytes(abi.encodePacked(referralAddress)).length > 0, "sign is fine, but address is empty!");
    //         require(fee >= 0, "fee must be above 0!");
    //         require(fee <= 90, "fee must be below 90%!");
    //         require(_verifyFee(fee, referralAddress, signFee), "fee sign is not valid!");
    //     } else {
    //         require(referralAddress.length == 0, "sign is empty, but address is there!");
    //         require(fee == 0, "sign is empty, but fee is not null!");
    //     }

    //     require(bytes(abi.encodePacked(tokens[tokenID].referralFee)).length > 0, "fee for this token does not exists");
    //     tokens[tokenID].referralFee = fee;
    //     tokens[tokenID].referralAddress = referralAddress;

    //     emit ReferralFeeChanged(tokenID, fee, referralAddress, block.timestamp);
    // }

    // function markTokenAsSold(uint256 tokenID, address payable newOwner) external {
    //     require(_exists(tokenID), "URI set of nonexistent token");
    //     require(msg.sender == dutchAuctionAddress || msg.sender == englishAuctionAddress, "Access denied");
    //     tokens[tokenID].isFirstSale = false;
    //     tokens[tokenID].owner = newOwner;
    // }

    function approveMultiple(uint256[] calldata tokenIds, address contractAddress) public {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            approve(contractAddress, tokenIds[index]);
        }
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()) || MarketplaceContract.viewAdminRole(msg.sender),
            "ERC721: approve caller is not owner nor admin nor approved for all"
        );

        _approve(to, tokenId);
    }

    function exists(uint256 id) public view returns(bool) {
        return _exists(id);
    }

    function transferToken(
        address from,
        address to,
        uint256 tokenID
    ) external nonReentrant {
        require(msg.sender == marketplaceAddress, "You don't have permission to call this");
        _transfer(from, to, tokenID);
    }

    function tokenExists(uint256 tokenID) external view returns (bool) {
        return _exists(tokenID);
    }

    function setMarketplaceAddress(address _marketplaceAddress) public platformOnly {
        marketplaceAddress = _marketplaceAddress;
        MarketplaceContract = MelonMarketplace(_marketplaceAddress);
    }

    // function changeTokenAddress(address _tokenAddress) external platformOnly {
    //     melonToken = IERC20(_tokenAddress);
    // }

    // function setEnglishAuction(address newAddress) external platformOnly {
    //     englishAuction = NFTEnglishAuction(newAddress);
    //     englishAuctionAddress = newAddress;
    // }

    // function setTokenOnAuction(uint256[] calldata tokenIDs, uint256 status) external {
    //     require(msg.sender == dutchAuctionAddress || msg.sender == englishAuctionAddress, "Access denied");
    //     for (uint256 index = 0; index < tokenIDs.length; index++) {
    //         require(_exists(tokenIDs[index]), "the token does not exist!");
    //         tokens[tokenIDs[index]].saleStatus = SaleStatuses(status);
    //     }
    // }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MelonNFT.sol";
import "./MelonEnglishAuction.sol";

import {MelonLibrary} from "./libraries/MelonLibrary.sol";

  contract MelonMarketplace is AccessControlUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    IERC20 private melonToken;
    NFTEnglishAuction public englishAuction;
    MelonNFT public NFTContract;

    address payable platformAddress;
    address payable feesAddress;

    using ECDSA for bytes32;
    using Strings for uint256;
    using SafeMath for uint256;

    mapping(uint256 => MelonLibrary.NFT_MODEL) public tokens;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public englishAuctionAddress;

    modifier platformOnly() {
        require(msg.sender == platformAddress, "you're not a super-admin!");
        _;
    }

    modifier adminOnly(uint256 tokenID) {
        require(hasRole(ADMIN_ROLE, msg.sender), "caller is not an admin!");
        _;
    }

    modifier adminOrOwner(uint256 tokenID) {
        require(hasRole(ADMIN_ROLE, msg.sender) || msg.sender == tokens[tokenID].owner || msg.sender == englishAuctionAddress, "caller is not an admin or owner!");
        _;
    }

    modifier adminOrOwnerMultiple(uint256[] calldata tokensIDs) {
        for (uint256 index = 0; index < tokensIDs.length; index++) {
            require(
                hasRole(ADMIN_ROLE, msg.sender) || msg.sender == tokens[tokensIDs[index]].owner || msg.sender == englishAuctionAddress,
                "caller is not an admin or owner for at least one token!"
            );
        }
        _;
    }

    event TokensMinted(
        uint256[] ids,
        uint256[] price,
        uint256[] symbol,
        MelonLibrary.SaleStatuses saleStatus,
        address creator,
        address payable[] referralAddress,
        uint256 referralFee,
        uint256 timestamp
    );

    event TokenBought(uint256 tokenID, address buyer, uint256 timestamp);

    event SaleStatusChanged(uint256 tokenID, MelonLibrary.SaleStatuses saleStatus, uint256 symbol, uint256 value, uint256 timestamp);

    event SaleStatusChangedMultiple(uint256[] tokensIDs, MelonLibrary.SaleStatuses saleStatus, uint256 symbol, uint256 value, uint256 timestamp);

    event ReferralFeeChanged(uint256 tokenID, uint256 referralFee, address payable[] referralAddress, uint256 timestamp);

    event TokenBurned(uint256 tokenID, uint256 timestamp);

    function initialize(
        address _NFTAddress,
        address _tokenAddress,
        address _englishAuctionAddress,
        address _platformAddress,
        address _feesAddress
    ) public initializer {
        __AccessControl_init();
        melonToken = IERC20(_tokenAddress);
        platformAddress = payable(_platformAddress);
        NFTContract = MelonNFT(_NFTAddress);
        feesAddress = payable(_feesAddress);
        englishAuction = NFTEnglishAuction(_englishAuctionAddress);
        englishAuctionAddress = _englishAuctionAddress;
        _setupRole(ADMIN_ROLE, _platformAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _platformAddress);
        __Ownable_init_unchained();
    }

    // function grantDefaultAdminRole(address payable admin) external platformOnly {
    //     platformAddress = admin;
    //     _setupRole(DEFAULT_ADMIN_ROLE, admin);
    // }

    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }

    // function tokenURI(uint256 tokenID) public view override returns (string memory)  {
    //     require(_exists(tokenID), "URI set of nonexistent token");
    //     return string(abi.encodePacked(_baseURIextended, tokenID.toString()));
    // }

    // function contractURI() public view returns (string memory) {
    //   return "ipfs://QmdYm3mp4cvgXbDRsBfTgF1rHPXnS8iWM98NSAf3oyExkn";
    // }

    function mintToken(
        MelonLibrary.NFT_MODEL memory nftModel,
        uint256[] memory ids,
        bytes calldata signIds,
        bytes calldata signFee
    ) public nonReentrant {
        for (uint256 index = 0; index < ids.length; index++) require(bytes(abi.encodePacked(tokens[ids[index]].owner)).length > 0, "at least one token already exists");
        require(_verifyMint(ids, signIds), "NFT params are not valid");
        if (bytes(abi.encodePacked(signFee)).length > 0) {
            require(nftModel.referralFee >= 0 && nftModel.referralFee <= 90, "fee must be above 0 and below 90%!");
            require(bytes(abi.encodePacked(nftModel.referralAddress)).length > 0, "sign is fine, but address is empty!");
            require(_verifyFee(nftModel.referralFee, nftModel.referralAddress, signFee), "fee sign is not valid!");
        } else {
            require(nftModel.referralAddress.length == 0, "sign is empty, but address is there!");
            require(nftModel.referralFee == 0, "sign is empty, but fee is not null!");
        }
        if (nftModel.saleStatus == MelonLibrary.SaleStatuses.FIX_PRICE)
            require(
                nftModel.price.length > 0 && nftModel.symbol.length > 0 && (nftModel.symbol[0] == MelonLibrary.MATIC || nftModel.symbol[0] == MelonLibrary.MELON),
                "item can not be for sale without a price"
            );

        if (!hasRole(ADMIN_ROLE, msg.sender)) require(msg.sender == nftModel.owner && msg.sender == nftModel.creator, "you're not owner nor creator!");

        uint256[] memory localSymbol = new uint256[](1);
        uint256[] memory localPrice = new uint256[](1);

        if (nftModel.saleStatus == MelonLibrary.SaleStatuses.FIX_PRICE) {
            localSymbol = nftModel.symbol;
            localPrice = nftModel.price;
        }

        for (uint256 index = 0; index < ids.length; index++) {
            uint256 currentId = ids[index];
            MelonLibrary.NFT_MODEL memory token =
                MelonLibrary.NFT_MODEL({
                    symbol: localSymbol,
                    price: localPrice,
                    owner: payable(nftModel.creator),
                    creator: payable(nftModel.creator),
                    isFirstSale: true,
                    referralFee: nftModel.referralFee,
                    referralAddress: nftModel.referralAddress,
                    saleStatus: nftModel.saleStatus
                });
            tokens[currentId] = token;
            NFTContract.mint(nftModel.creator, ids[index]);
        }

        emit TokensMinted(ids, nftModel.price, nftModel.symbol, nftModel.saleStatus, nftModel.creator, nftModel.referralAddress, nftModel.referralFee, block.timestamp);
    }

    function _verifyMint(uint256[] memory ids, bytes calldata sign) internal view returns (bool) {
        bytes32 b = keccak256(abi.encode(ids));
        return b.toEthSignedMessageHash().recover(sign) == platformAddress;
    }

    function mintWithEnglishAuction(
        MelonLibrary.NFT_MODEL memory nftModel,
        uint256[] calldata tokenIDs,
        uint256 symbol,
        uint256 minBid,
        uint256 reservePrice,
        uint256 auctionDuration,
        bytes calldata signIds,
        bytes calldata signFee
    ) external nonReentrant {
        require(nftModel.saleStatus == MelonLibrary.SaleStatuses.NOT_ON_SALE, "token must not be on sale!");
        require(nftModel.price.length == 0, "token price should not be set!");

        mintToken(nftModel, tokenIDs, signIds, signFee);
        NFTContract.approveMultiple(tokenIDs, englishAuctionAddress);
        englishAuction.createAuction(tokenIDs, symbol, minBid, reservePrice, auctionDuration);
        for (uint256 index = 0; index < tokenIDs.length; index++) tokens[tokenIDs[index]].saleStatus = MelonLibrary.SaleStatuses.ENGLISH_AUCTION;
    }

    // function _verifyMint(uint256[] memory ids, bytes calldata sign) internal view returns (bool) {
    //     bytes32 b = keccak256(abi.encode(ids));
    //     return b.toEthSignedMessageHash().recover(sign) == platformAddress;
    // }

    // function _verifyFee(
    //     uint256 fee,
    //     address payable[] memory referralAddress,
    //     bytes calldata sign
    // ) internal view returns (bool) {
    //     bytes32 b = keccak256(abi.encode(fee, referralAddress[0]));
    //     return b.toEthSignedMessageHash().recover(sign) == platformAddress;
    // }

    function getTokenByID(uint256 tokenID) public view returns (MelonLibrary.NFT_MODEL memory token) {
        require(NFTContract.exists(tokenID), "this token does not exist!");
        return tokens[tokenID];
    }

    function buyWithMelon(uint256 tokenID) external nonReentrant {
        require(tokens[tokenID].saleStatus == MelonLibrary.SaleStatuses.FIX_PRICE, "this token is not for sale!");
        require(tokens[tokenID].price.length > 0, "price for the NFT has not been set!");
        require(tokens[tokenID].symbol.length > 0, "the symbol for the NFT has not been specified!");
        require(tokens[tokenID].symbol[0] == MelonLibrary.MELON, "wrong currency selected!");
        require(tokens[tokenID].owner != address(0), "you're trying to sell to zero-address");

        uint256 referralFeeTotal = 0;

        if (tokens[tokenID].isFirstSale && bytes(abi.encodePacked(tokens[tokenID].referralAddress)).length > 0) {
            referralFeeTotal = tokens[tokenID].price[0].mul(tokens[tokenID].referralFee).div(100);
            melonToken.transferFrom(msg.sender, tokens[tokenID].referralAddress[0], referralFeeTotal);
            tokens[tokenID].isFirstSale = false;
        }

        melonToken.transferFrom(msg.sender, tokens[tokenID].owner, tokens[tokenID].price[0].sub(referralFeeTotal));
        // NFTContract._transfer(tokens[tokenID].owner, msg.sender, tokenID);
        NFTContract.transferToken(getTokenByID(tokenID).owner, msg.sender, tokenID);
        tokens[tokenID].owner = payable(msg.sender);
        tokens[tokenID].saleStatus = MelonLibrary.SaleStatuses.NOT_ON_SALE;
        emit TokenBought(tokenID, msg.sender, block.timestamp);
    }

    function buy(uint256 tokenID) external payable nonReentrant {
        require(tokens[tokenID].saleStatus == MelonLibrary.SaleStatuses.FIX_PRICE, "this token is not for sale!");
        require(tokens[tokenID].price.length > 0, "price for the NFT has not been set!");
        require(tokens[tokenID].symbol.length > 0, "the symbol for the NFT has not been specified!");
        require(tokens[tokenID].symbol[0] == MelonLibrary.MATIC, "wrong currency selected!");
        require(tokens[tokenID].owner != address(0), "you're trying to sell to zero-address");
        require(msg.value >= tokens[tokenID].price[0], "insufficient funds!");

        uint256 comissionValue = tokens[tokenID].price[0].mul(25).div(1000);
        uint256 referralFeeTotal = 0;
        feesAddress.transfer(comissionValue);

        if (tokens[tokenID].isFirstSale && bytes(abi.encodePacked(tokens[tokenID].referralAddress)).length > 0) {
            referralFeeTotal = tokens[tokenID].price[0].mul(tokens[tokenID].referralFee).div(100);
            tokens[tokenID].referralAddress[0].transfer(referralFeeTotal);
            tokens[tokenID].isFirstSale = false;
        }
        tokens[tokenID].owner.transfer(tokens[tokenID].price[0].sub(comissionValue + referralFeeTotal));
        // NFTContract._transfer(tokens[tokenID].owner, msg.sender, tokenID);
        NFTContract.transferToken(getTokenByID(tokenID).owner, msg.sender, tokenID);
        tokens[tokenID].owner = payable(msg.sender);
        tokens[tokenID].saleStatus = MelonLibrary.SaleStatuses.NOT_ON_SALE;

        emit TokenBought(tokenID, msg.sender, block.timestamp);
    }

    function setForSale(
        uint256 price,
        uint256 symbol,
        uint256 tokenID
    ) external adminOrOwner(tokenID) {
        require(tokens[tokenID].saleStatus == MelonLibrary.SaleStatuses.NOT_ON_SALE, "this token is on sale");
        require(price > 0, "you didn't pass on the price!");
        require(symbol == MelonLibrary.MATIC || symbol == MelonLibrary.MELON, "the symbol for the NFT has not been specified!");
        tokens[tokenID].saleStatus = MelonLibrary.SaleStatuses.FIX_PRICE;
        tokens[tokenID].price = [price];
        tokens[tokenID].symbol = [symbol];

        emit SaleStatusChanged(tokenID, MelonLibrary.SaleStatuses.FIX_PRICE, symbol, price, block.timestamp);
    }

    function setForSaleMultiple(
        uint256 price,
        uint256 symbol,
        uint256[] calldata tokensIDs
    ) external adminOrOwnerMultiple(tokensIDs) {
        for (uint256 index = 0; index < tokensIDs.length; index++) {
            require(NFTContract.tokenExists(tokensIDs[index]), "URI set of nonexistent token");
            require(tokens[tokensIDs[index]].saleStatus == MelonLibrary.SaleStatuses.NOT_ON_SALE, "this token is on sale");
            require(price > 0, "you didn't pass on the price!");
            require(symbol == MelonLibrary.MATIC || symbol == MelonLibrary.MELON, "the symbol for the NFT has not been specified!");
            tokens[tokensIDs[index]].saleStatus = MelonLibrary.SaleStatuses.FIX_PRICE;
            tokens[tokensIDs[index]].price = [price];
            tokens[tokensIDs[index]].symbol = [symbol];
        }
        emit SaleStatusChangedMultiple(tokensIDs, MelonLibrary.SaleStatuses.FIX_PRICE, symbol, price, block.timestamp);
    }

    function withdrawFromSale(uint256 tokenID) external adminOrOwner(tokenID) {
        require(tokens[tokenID].saleStatus == MelonLibrary.SaleStatuses.FIX_PRICE, "this token is not on sale");

        tokens[tokenID].saleStatus = MelonLibrary.SaleStatuses.NOT_ON_SALE;

        emit SaleStatusChanged(tokenID, MelonLibrary.SaleStatuses.NOT_ON_SALE, tokens[tokenID].symbol[0], tokens[tokenID].price[0], block.timestamp);
    }

    function setPrice(uint256 price, uint256 tokenID) external adminOrOwner(tokenID) {
        require(price > 0, "you didn't pass on the price!");
        require(tokens[tokenID].saleStatus == MelonLibrary.SaleStatuses.FIX_PRICE, "token must be on sale!");

        tokens[tokenID].price = [price];
        emit SaleStatusChanged(tokenID, tokens[tokenID].saleStatus, tokens[tokenID].symbol[0], price, block.timestamp);
    }

    function _verifyFee(
        uint256 fee,
        address payable[] memory referralAddress,
        bytes calldata sign
    ) internal view returns (bool) {
        bytes32 b = keccak256(abi.encode(fee, referralAddress[0]));
        return b.toEthSignedMessageHash().recover(sign) == platformAddress;
    }

    function setReferralFee(
        address payable[] memory referralAddress,
        uint256 fee,
        uint256 tokenID,
        bytes calldata signFee
    ) external adminOnly(tokenID) {
        require(tokens[tokenID].isFirstSale, "this token was already on sale!");
        if (bytes(abi.encodePacked(signFee)).length > 0) {
            require(bytes(abi.encodePacked(referralAddress)).length > 0, "sign is fine, but address is empty!");
            require(fee >= 0, "fee must be above 0!");
            require(fee <= 90, "fee must be below 90%!");
            require(_verifyFee(fee, referralAddress, signFee), "fee sign is not valid!");
        } else {
            require(referralAddress.length == 0, "sign is empty, but address is there!");
            require(fee == 0, "sign is empty, but fee is not null!");
        }

        require(bytes(abi.encodePacked(tokens[tokenID].referralFee)).length > 0, "fee for this token does not exists");
        tokens[tokenID].referralFee = fee;
        tokens[tokenID].referralAddress = referralAddress;

        emit ReferralFeeChanged(tokenID, fee, referralAddress, block.timestamp);
    }

    // function grantAdminRole(address account) external platformOnly {
    //     grantRole(ADMIN_ROLE, account);
    // }

    // function viewAdminRole(address user) external view returns (bool) {
    //     return hasRole(ADMIN_ROLE, user);
    // }

    function markTokenAsSold(uint256 tokenID, address payable newOwner) external {
        require(NFTContract.tokenExists(tokenID), "URI set of nonexistent token");
        require(msg.sender == englishAuctionAddress, "Access denied");
        tokens[tokenID].isFirstSale = false;
        tokens[tokenID].owner = newOwner;
    }

    // function approveMultiple(uint256[] calldata tokenIds, address contractAddress) public {
    //     for (uint256 index = 0; index < tokenIds.length; index++) {
    //         approve(contractAddress, tokenIds[index]);
    //     }
    // }

    // function approve(address to, uint256 tokenId) public virtual override {
    //     address owner = ERC721Upgradeable.ownerOf(tokenId);
    //     require(to != owner, "ERC721: approval to current owner");

    //     require(
    //         _msgSender() == owner || isApprovedForAll(owner, _msgSender()) || hasRole(ADMIN_ROLE, msg.sender),
    //         "ERC721: approve caller is not owner nor admin nor approved for all"
    //     );

    //     _approve(to, tokenId);
    // }

    function isTokenOnSale(uint256[] calldata tokenIds) public view returns (bool) {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            if (tokens[tokenIds[index]].saleStatus == MelonLibrary.SaleStatuses.FIX_PRICE) {
                return true;
            }
        }

        return false;
    }

    function grantAdminRole(address account) external platformOnly {
        grantRole(ADMIN_ROLE, account);
    }

    function viewAdminRole(address user) public view returns (bool) {
        return hasRole(ADMIN_ROLE, user);
    }

    function grantDefaultAdminRole(address payable admin) external platformOnly {
        platformAddress = admin;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function changeFeesAddress(address payable newAddress) external platformOnly {
        feesAddress = newAddress;
    }

    function burn(uint256 tokenID) external adminOrOwner(tokenID) {
      require(NFTContract.exists(tokenID), "Token already exists");
      NFTContract.burn(tokenID);
      emit TokenBurned(tokenID, block.timestamp);
    }

    // function changeTokenAddress(address _tokenAddress) external platformOnly {
    //     melonToken = IERC20(_tokenAddress);
    // }

    function setEnglishAuction(address newAddress) external platformOnly {
        englishAuction = NFTEnglishAuction(newAddress);
        englishAuctionAddress = newAddress;
    }

    function setTokenOnAuction(uint256[] calldata tokenIDs, uint256 status) external {
        require(msg.sender == englishAuctionAddress, "Access denied");
        for (uint256 index = 0; index < tokenIDs.length; index++) {
            require(NFTContract.tokenExists(tokenIDs[index]), "the token does not exist!");
            tokens[tokenIDs[index]].saleStatus = MelonLibrary.SaleStatuses(status);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./MelonNFT.sol";
import "./MelonMarketplace.sol";

contract NFTEnglishAuction is IERC721Receiver, ERC721HolderUpgradeable {
    using SafeMath for uint256;

    IERC20 private melonToken;
    address payable platformAddress;
    address private nftAddress;
    address payable feesAddress;

    struct Auction {
        uint256 tokenID;
        address tokenOwner;
        uint256 symbol;
        uint256 minBid;
        uint256 reservePrice;
        uint256 endTime;
        uint256 startTime;
        address highestBidder;
        uint256 highestBid;
        uint256 totalBids;
        bool isFinished;
        mapping(uint256 => Offer) offers;
        uint256[] offerIdArray;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenID;
        uint256 offerSymbol;
        uint256 offerValue;
        address offerCreator;
        bool isExist;
    }

    mapping(uint256 => Auction) tokenIDToAuction;

    MelonNFT public NFTContract;
    MelonMarketplace public MarketplaceContract;

    modifier platformOnly() {
        require(msg.sender == platformAddress, "you're not a super-admin!");
        _;
    }

    event BidPosted(uint256 tokenID, uint256 bidAmount, uint256 symbol, address bidder, uint256 timestamp);
    event AuctionCreated(uint256[] tokenIDs, uint256 symbol, uint256 minBid, uint256 reservePrice, uint256 startDate, uint256 endDate, uint256 timestamp);
    event AuctionFinished(uint256 tokenID, address newOwner, uint256 timestamp);
    event AuctionWithdrawed(uint256 tokenID, uint256 timestamp);
    event OfferPlaced(uint256 tokenID, uint256 offerId, uint256 offerValue, uint256 offerSymbol, address offerCreator, uint256 timestamp);
    event OfferDenied(uint256 offerId, uint256 tokenID, uint256 timestamp);
    event OfferApproved(uint256 tokenID, uint256 offerId, uint256 timestamp);

    function initialize(
        address _NFTAddress,
        address _NFTMarketplaceAddress,
        address tokenAddress,
        address payable _platformAddress,
        address payable _feesAddress
    ) external initializer {
        NFTContract = MelonNFT(_NFTAddress);
        MarketplaceContract = MelonMarketplace(_NFTMarketplaceAddress);
        nftAddress = _NFTAddress;
        melonToken = IERC20(tokenAddress);
        platformAddress = _platformAddress;
        feesAddress = _feesAddress;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override(ERC721HolderUpgradeable, IERC721Receiver) returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getAuctionData(uint256 tokenID)
        public
        view
        returns (
            uint256 currentPrice,
            uint256 currency,
            uint256 minBid,
            uint256 startDate,
            uint256 endDate,
            uint256 reservePrice,
            bool isFinished
        )
    {
        Auction storage auction = tokenIDToAuction[tokenID];

        currency = auction.symbol;
        minBid = auction.minBid;
        startDate = auction.startTime;
        reservePrice = auction.reservePrice;
        isFinished = auction.isFinished;

        bool withinTime =
            (block.timestamp >= auction.startTime && block.timestamp <= auction.endTime) || (auction.highestBid >= auction.reservePrice && block.timestamp > auction.endTime);

        if (withinTime) {
            currentPrice = auction.highestBid;
            endDate = auction.endTime;
        } else {
            currentPrice = auction.reservePrice;
            endDate = 0;
        }
    }

    function createAuction(
        uint256[] calldata tokenIDs,
        uint256 symbol,
        uint256 minBid,
        uint256 reservePrice,
        uint256 auctionDuration
    ) public {
        require(reservePrice >= minBid, "Invalid reserve price");

        for (uint256 index = 0; index < tokenIDs.length; index++) {
            require(tokenIDToAuction[tokenIDs[index]].tokenOwner == address(0x0), "MelonEnglishAuction: auction for one of the tokens already exists!");
        }
        require(minBid >= 1000000000000, "MelonEnglishAuction: your minimal bid must be bigger than 0.000001!");
        require(auctionDuration >= 1 days, "MelonEnglishAuction: duration must be more than 1 day!");
        require(auctionDuration <= 4 weeks, "MelonEnglishAuction: duration must be less than 4 weeks!");
        require(symbol == 1 || symbol == 0, "MelonEnglishAuction: this token is not in MATIC or MELON!");

        require(!MarketplaceContract.isTokenOnSale(tokenIDs), "Already on sale");

        for (uint256 index = 0; index < tokenIDs.length; index++) {
            require(NFTContract.ownerOf(tokenIDs[index]) == msg.sender || MarketplaceContract.viewAdminRole(msg.sender) || nftAddress == msg.sender, "Invalid caller");
        }

        for (uint256 index = 0; index < tokenIDs.length; index++) {
            address owner = MarketplaceContract.getTokenByID(tokenIDs[index]).owner;

            NFTContract.safeTransferFrom(owner, address(this), tokenIDs[index]);

            Auction storage auction = tokenIDToAuction[tokenIDs[index]];

            auction.tokenOwner = owner;
            auction.minBid = minBid;
            auction.symbol = symbol;
            auction.reservePrice = reservePrice;
            auction.tokenID = tokenIDs[index];
            auction.endTime = block.timestamp + auctionDuration;
            auction.startTime = block.timestamp;
            auction.highestBid = 0;
            auction.highestBidder = address(0x0);
            auction.totalBids = 0;
            auction.isFinished = false;
        }
        MarketplaceContract.setTokenOnAuction(tokenIDs, 3); // didn't find how to expose enum from MelonNFT properly
        emit AuctionCreated(tokenIDs, symbol, minBid, reservePrice, block.timestamp, block.timestamp + auctionDuration, block.timestamp);
    }

    function bidWithMATIC(uint256 tokenID) public payable {
        Auction storage auction = tokenIDToAuction[tokenID];

        require(isBidValid(tokenID, msg.value), "Issue on validation");
        require(auction.symbol == 0, "symbol is wrong, must be MATIC!");

        uint256 lastHighestBid = auction.highestBid;
        address lastHighestBidder = auction.highestBidder;
        uint256 totalBids = auction.totalBids;
        uint256 endTime = auction.endTime;

        bool withinTime = block.timestamp >= auction.startTime && block.timestamp <= auction.endTime;

        if (withinTime) {
            if (endTime - block.timestamp < 300 && msg.value >= auction.reservePrice) {
                tokenIDToAuction[tokenID].endTime = endTime + 300;
            }
        } else {
            require(auction.highestBid < auction.reservePrice, "Auction already finished");
            require(msg.value >= auction.reservePrice, "Issue on validation");

            if (msg.value >= auction.reservePrice) {
                tokenIDToAuction[tokenID].endTime = block.timestamp + 86400;
            }
        }

        tokenIDToAuction[tokenID].highestBid = msg.value;
        tokenIDToAuction[tokenID].highestBidder = msg.sender;
        tokenIDToAuction[tokenID].totalBids = totalBids + 1;

        emit BidPosted(tokenID, msg.value, tokenIDToAuction[tokenID].symbol, msg.sender, block.timestamp);

        if (lastHighestBidder != address(0)) {
            payable(lastHighestBidder).transfer(lastHighestBid);
        }
    }

    function bidWithMelon(uint256 tokenID, uint256 bidPrice) public {
        Auction storage auction = tokenIDToAuction[tokenID];

        require(isBidValid(tokenID, bidPrice), "issue on validation");
        require(auction.symbol == 1, "symbol is wrong, must be Melon!");

        uint256 lastHighestBid = auction.highestBid;
        address lastHighestBidder = auction.highestBidder;
        uint256 totalBids = auction.totalBids;
        uint256 endTime = auction.endTime;

        bool withinTime = block.timestamp >= auction.startTime && block.timestamp <= auction.endTime;

        if (withinTime) {
            if (endTime - block.timestamp < 300 && bidPrice >= auction.reservePrice) {
                tokenIDToAuction[tokenID].endTime = endTime + 300;
            }
        } else {
            require(auction.highestBid < auction.reservePrice, "Auction already finished");
            require(bidPrice >= auction.reservePrice, "Issue on validation");

            if (bidPrice >= auction.reservePrice) {
                tokenIDToAuction[tokenID].endTime = block.timestamp + 86400;
            }
        }

        melonToken.transferFrom(msg.sender, address(this), bidPrice);

        tokenIDToAuction[tokenID].highestBid = bidPrice;
        tokenIDToAuction[tokenID].highestBidder = msg.sender;
        tokenIDToAuction[tokenID].totalBids = totalBids + 1;

        emit BidPosted(tokenID, bidPrice, tokenIDToAuction[tokenID].symbol, msg.sender, block.timestamp);

        if (lastHighestBidder != address(0)) {
            melonToken.approve(address(this), lastHighestBid);
            melonToken.transferFrom(address(this), lastHighestBidder, lastHighestBid);
        }
    }

    function isBidValid(uint256 tokenID, uint256 bidAmount) internal view returns (bool) {
        require(tokenIDToAuction[tokenID].tokenOwner != address(0x0), "Auction doesn't exist");
        Auction storage auction = tokenIDToAuction[tokenID];

        address tokenOwner = auction.tokenOwner;
        uint256 minBid = auction.minBid;
        uint256 highestBid = auction.highestBid;

        bool bidAmountValid = bidAmount >= minBid + highestBid;
        bool sellerValid = tokenOwner != address(0);
        return bidAmountValid && sellerValid && !auction.isFinished;
    }

    function finalize(uint256 tokenID) public {
        require(tokenIDToAuction[tokenID].tokenOwner != address(0x0), "Auction doesn't exist");
        Auction storage auction = tokenIDToAuction[tokenID];

        require(msg.sender == auction.tokenOwner || msg.sender == auction.highestBidder || MarketplaceContract.viewAdminRole(msg.sender), "Invalid caller");
        require((block.timestamp >= auction.startTime && block.timestamp <= auction.endTime) || auction.highestBid >= auction.reservePrice, "Auction can't be ended");
        require(!auction.isFinished, "Auction already finished");

        require(auction.totalBids > 0, "Auction has no bids");

        uint256 comissionValue = auction.highestBid.mul(25).div(1000);
        uint256 referralFeeTotal = 0;

        if (auction.symbol == 0) {
            feesAddress.transfer(comissionValue);
            if (MarketplaceContract.getTokenByID(tokenID).referralAddress.length > 0) {
                referralFeeTotal = auction.highestBid.mul(MarketplaceContract.getTokenByID(tokenID).referralFee).div(100);
                MarketplaceContract.getTokenByID(tokenID).referralAddress[0].transfer(referralFeeTotal);
            }
            payable(auction.tokenOwner).transfer(auction.highestBid.sub(comissionValue + referralFeeTotal));
        } else if (auction.symbol == 1) {
            melonToken.approve(address(this), auction.highestBid);
            if (MarketplaceContract.getTokenByID(tokenID).referralAddress.length > 0) {
                referralFeeTotal = auction.highestBid.mul(MarketplaceContract.getTokenByID(tokenID).referralFee).div(100);
                melonToken.transferFrom(address(this), MarketplaceContract.getTokenByID(tokenID).referralAddress[0], referralFeeTotal);
            }
            melonToken.transferFrom(address(this), auction.tokenOwner, auction.highestBid.sub(referralFeeTotal));
        }

        NFTContract.safeTransferFrom(address(this), auction.highestBidder, auction.tokenID);

        tokenIDToAuction[tokenID].isFinished = true;
        MarketplaceContract.markTokenAsSold(tokenID, payable(auction.highestBidder));

        emit AuctionFinished(tokenID, auction.highestBidder, block.timestamp);

        withdrawPendingOffers(auction);
        delete tokenIDToAuction[tokenID];
    }

    function withdraw(uint256 tokenID) public {
        require(tokenIDToAuction[tokenID].tokenOwner != address(0x0), "The auction doesn't exist");
        Auction storage auction = tokenIDToAuction[tokenID];

        require(auction.tokenOwner == msg.sender || MarketplaceContract.viewAdminRole(msg.sender) || nftAddress == msg.sender, "Invalid caller");
        require(!auction.isFinished, "Auction already finished");

        uint256 lastHighestBid = auction.highestBid;
        address lastHighestBidder = auction.highestBidder;

        if (auction.symbol == 0 && lastHighestBidder != address(0x0)) {
            payable(lastHighestBidder).transfer(lastHighestBid);
        } else if (auction.symbol == 1 && lastHighestBidder != address(0x0)) {
            melonToken.approve(address(this), lastHighestBid);
            melonToken.transferFrom(address(this), lastHighestBidder, lastHighestBid);
        }

        tokenIDToAuction[tokenID].isFinished = true;

        NFTContract.safeTransferFrom(address(this), auction.tokenOwner, auction.tokenID);

        uint256[] memory tokenIDs = new uint256[](1);
        tokenIDs[0] = tokenID;
        MarketplaceContract.setTokenOnAuction(tokenIDs, 0);
        withdrawPendingOffers(auction);

        delete tokenIDToAuction[tokenID];

        emit AuctionWithdrawed(tokenID, block.timestamp);
    }

    function placeOfferMATIC(uint256 tokenID) public payable {
        validateOffer(tokenID, msg.value, msg.sender, 0);
        createOffer(tokenID, msg.value, msg.sender);
    }

    function placeOfferMelon(uint256 tokenID, uint256 value) public {
        validateOffer(tokenID, value, msg.sender, 1);
        melonToken.transferFrom(msg.sender, address(this), value);
        createOffer(tokenID, value, msg.sender);
    }

    function createOffer(
        uint256 tokenID,
        uint256 value,
        address offerCreator
    ) private {
        Offer memory offer =
            Offer({offerId: getNewOfferID(), tokenID: tokenID, offerValue: value, offerSymbol: tokenIDToAuction[tokenID].symbol, offerCreator: offerCreator, isExist: true});

        Auction storage auction = tokenIDToAuction[offer.tokenID];

        auction.offers[offer.offerId] = offer;
        auction.offerIdArray.push(offer.offerId);

        emit OfferPlaced(tokenID, offer.offerId, value, offer.offerSymbol, offerCreator, block.timestamp);
    }

    function hasOffers(uint256 tokenID, address offerCreator) private view returns (bool) {
        for (uint256 index = 0; index < tokenIDToAuction[tokenID].offerIdArray.length; index++) {
            if (tokenIDToAuction[tokenID].offers[tokenIDToAuction[tokenID].offerIdArray[index]].offerCreator == offerCreator) return true;
        }

        return false;
    }

    function validateOffer(
        uint256 tokenID,
        uint256 value,
        address offerCreator,
        uint256 symbol
    ) private view {
        require(tokenIDToAuction[tokenID].tokenOwner != address(0x0), "The auction doesn't exist");
        require(tokenIDToAuction[tokenID].symbol == symbol, "Wrong currency");
        require(!hasOffers(tokenID, offerCreator), "One offer per user is allowed");
        require(tokenIDToAuction[tokenID].startTime < block.timestamp, "MelonEnglishAuction: auction has not started yet!");
        require(tokenIDToAuction[tokenID].endTime > block.timestamp, "MelonEnglishAuction: auction has been ended!");
        require(value >= tokenIDToAuction[tokenID].reservePrice, "MelonEnglishAuction: value must be bigger than reserve price!");
    }

    function approveOffer(uint256 tokenID, uint256 offerId) public {

        Auction storage auction = tokenIDToAuction[tokenID];

        require(auction.tokenOwner != address(0x0), "the auction does not exist");

        Offer memory offer = auction.offers[offerId];

        require(auction.offers[offerId].offerCreator != address(0x0), "the offer does not exist");

        require(auction.tokenOwner == msg.sender || MarketplaceContract.viewAdminRole(msg.sender) || nftAddress == msg.sender, "Invalid caller");
        require(!auction.isFinished, "Auction already finished");

        uint256 comissionValue = offer.offerValue.mul(25).div(1000);
        uint256 referralFeeTotal = 0;

        if (auction.symbol == 0) {
            feesAddress.transfer(comissionValue);
            if (MarketplaceContract.getTokenByID(tokenID).referralAddress.length > 0) {
                referralFeeTotal = offer.offerValue.mul(MarketplaceContract.getTokenByID(tokenID).referralFee).div(100);
                MarketplaceContract.getTokenByID(tokenID).referralAddress[0].transfer(referralFeeTotal);
            }
            payable(auction.tokenOwner).transfer(offer.offerValue.sub(comissionValue + referralFeeTotal));
        } else if (auction.symbol == 1) {
            melonToken.approve(address(this), offer.offerValue);
            if (MarketplaceContract.getTokenByID(tokenID).referralAddress.length > 0) {
                referralFeeTotal = offer.offerValue.mul(MarketplaceContract.getTokenByID(tokenID).referralFee).div(100);
                melonToken.transferFrom(address(this), MarketplaceContract.getTokenByID(tokenID).referralAddress[0], referralFeeTotal);
            }
            melonToken.transferFrom(address(this), auction.tokenOwner, offer.offerValue.sub(referralFeeTotal));
        }

        NFTContract.safeTransferFrom(address(this), offer.offerCreator, auction.tokenID);

        tokenIDToAuction[tokenID].isFinished = true;
        MarketplaceContract.markTokenAsSold(tokenID, payable(offer.offerCreator));

        emit OfferApproved(offer.tokenID, offer.offerId, block.timestamp);

        uint256 lastHighestBid = auction.highestBid;
        address lastHighestBidder = auction.highestBidder;

        if (auction.symbol == 0 && lastHighestBidder != address(0x0)) {
            payable(lastHighestBidder).transfer(lastHighestBid);
        } else if (auction.symbol == 1 && lastHighestBidder != address(0x0)) {
            melonToken.approve(address(this), lastHighestBid);
            melonToken.transferFrom(address(this), lastHighestBidder, lastHighestBid);
        }

        for (uint256 index = 0; index < auction.offerIdArray.length; index++) {
            uint256 currentId = auction.offerIdArray[index];

            if (currentId != offerId && auction.offers[currentId].isExist) {
                if (offer.offerSymbol == 0) {
                    payable(auction.offers[currentId].offerCreator).transfer(auction.offers[currentId].offerValue);
                } else if (offer.offerSymbol == 1) {
                    melonToken.approve(address(this), auction.offers[currentId].offerValue);
                    melonToken.transferFrom(address(this), auction.offers[currentId].offerCreator, auction.offers[currentId].offerValue);
                }
            }
        }
        delete tokenIDToAuction[tokenID];
    }

    function denyOffer(uint256 tokenID, uint256 offerId) public {
        Auction storage auction = tokenIDToAuction[tokenID];

        require(auction.tokenOwner != address(0x0), "the auction does not exist");

        Offer memory offer = auction.offers[offerId];

        require(offer.offerCreator != address(0x0), "the offer does not exist");

        require(msg.sender == offer.offerCreator, "Invalid caller");
        require(!auction.isFinished, "Auction already finished");

        if (auction.symbol == 0) {
            payable(offer.offerCreator).transfer(offer.offerValue);
        } else if (auction.symbol == 1) {
            melonToken.approve(address(this), auction.offers[offer.offerId].offerValue);
            melonToken.transferFrom(address(this), auction.offers[offer.offerId].offerCreator, auction.offers[offer.offerId].offerValue);
        }

        emit OfferDenied(offerId, tokenID, block.timestamp);
        delete auction.offers[offerId];
    }

    function withdrawPendingOffers(Auction storage auction) private {
        for (uint256 index = 0; index < auction.offerIdArray.length; index++) {
            uint256 currentId = auction.offerIdArray[index];

            if (auction.offers[currentId].isExist) {
                if (auction.symbol == 0) {
                    payable(auction.offers[currentId].offerCreator).transfer(auction.offers[currentId].offerValue);
                } else if (auction.symbol == 1) {
                    melonToken.approve(address(this), auction.offers[currentId].offerValue);
                    melonToken.transferFrom(address(this), auction.offers[currentId].offerCreator, auction.offers[currentId].offerValue);
                }
            }
        }
    }

    uint256 offerIdCounter;

    // Return new offer id
    function getNewOfferID() private returns (uint256) {
        return ++offerIdCounter;
    }

    function changeTokenAddress(address _tokenAddress) external platformOnly {
        melonToken = IERC20(_tokenAddress);
    }

    function changeProxyAddress(address newAddress) external platformOnly {
        NFTContract = MelonNFT(newAddress);
        nftAddress = newAddress;
    }

    function changeFeesAddress(address payable newAddress) external platformOnly {
        feesAddress = newAddress;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library MelonLibrary {

    enum SaleStatuses {NOT_ON_SALE, FIX_PRICE, DUTCH_AUCTION, ENGLISH_AUCTION}

    struct NFT_MODEL {
        uint256[] symbol;
        uint256[] price;
        address payable owner;
        address payable creator;
        uint256 referralFee;
        address payable[] referralAddress;
        SaleStatuses saleStatus;
        bool isFirstSale;
    }

    struct Auction {
        uint256 tokenID;
        address tokenOwner;
        uint256 symbol;
        uint256 minBid;
        uint256 reservePrice;
        uint256 endTime;
        uint256 startTime;
        address highestBidder;
        uint256 highestBid;
        uint256 totalBids;
        bool isFinished;
        mapping(uint256 => Offer) offers;
        uint256[] offerIdArray;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenID;
        uint256 offerSymbol;
        uint256 offerValue;
        address offerCreator;
        bool isExist;
    }

    uint256 public constant MATIC = 0;
    uint256 public constant MELON = 1;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

