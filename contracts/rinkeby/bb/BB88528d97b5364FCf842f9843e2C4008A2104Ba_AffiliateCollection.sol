// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "../modules/Affiliable.sol";
import "../interface/ICollectionStruct.sol";

/**
 * @title Affiliate Collection
 * @dev   end contract that is made up of building blocks and is ready to be used that extends the affiliate functionality.
 */
contract AffiliateCollection is Affiliable, ICollectionStruct {
    bool public isValid;

    /**
     * @dev setup presale and base collection details including whitelist
     * @param _baseCollection struct with params to setup base collection
     * @param _presaleable struct with params to setup presale
     * @param _paymentSplitter struct with params to setup payment splitting
     * @param _revealable struct with params to setup reveal details
     */
    function setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        RevealableStruct memory _revealable
    ) external {
        _setup(_baseCollection, _presaleable, _paymentSplitter, _revealable);
    }

    function setupWithAffiliate(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        RevealableStruct memory _revealable,
        IAffiliateRegistry _registry,
        bytes32 _projectId
    ) external {
        _setup(_baseCollection, _presaleable, _paymentSplitter, _revealable);
        _setAffiliateModule(_registry, _projectId);
    }

    function _setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        RevealableStruct memory _revealable
    ) private {
        require(!isValid, "C:001");
        isValid = true;
        setupBaseCollection(
            _baseCollection.name,
            _baseCollection.symbol,
            _baseCollection.admin,
            _baseCollection.maximumTokens,
            _baseCollection.maxPurchase,
            _baseCollection.maxHolding,
            _baseCollection.price,
            _baseCollection.publicSaleStartTime,
            _baseCollection.loadingURI
        );
        setupPresale(
            _presaleable.presaleReservedTokens,
            _presaleable.presalePrice,
            _presaleable.presaleStartTime,
            _presaleable.presaleMaxHolding,
            _presaleable.presaleWhitelist
        );
        setupPaymentSplitter(
            _paymentSplitter.simplr,
            _paymentSplitter.simplrShares,
            _paymentSplitter.payees,
            _paymentSplitter.shares
        );
        setRevealableDetails(
            _revealable.projectURIProvenance,
            _revealable.revealAfterTimestamp
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "./Royalties.sol";
import "../affiliate/Affiliate.sol";

/**
 * @title Affiliable
 * @dev   Module that adds functionality of affiliate.
 */
contract Affiliable is Royalties, Affiliate {
    /**
     * @dev public buy tokens in quantity
     */
    function affiliateBuy(
        uint256 _quantity,
        bytes memory _signature,
        address _affiliate
    ) external payable virtual {
        _buy(msg.sender, _quantity);
        _transferAffiliateShare(_signature, _affiliate, msg.value);
    }

    /**
     * @dev buy tokens in quantity during presale
     * @param _quantity number of tokens to buy
     */
    function affiliatePresaleBuy(
        uint256 _quantity,
        bytes memory _signature,
        address _affiliate
    ) external payable virtual {
        _presaleBuy(msg.sender, _quantity);
        _transferAffiliateShare(_signature, _affiliate, msg.value);
    }

    /**
     * @dev returns bool, based on if the module is initialised or not
     */
    function isAffiliateModuleInitialised() external view returns (bool) {
        return _isAffiliateModuleInitialised();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

/**
 * @title Collection Struct Interface
 * @dev   interface to for all the struct required for setup parameters.
 */
interface ICollectionStruct {
    struct BaseCollectionStruct {
        string name;
        string symbol;
        address admin;
        uint256 maximumTokens;
        uint16 maxPurchase;
        uint16 maxHolding;
        uint256 price;
        uint256 publicSaleStartTime;
        string loadingURI;
    }

    struct PresaleableStruct {
        uint256 presaleReservedTokens;
        uint256 presalePrice;
        uint256 presaleStartTime;
        uint256 presaleMaxHolding;
        address[] presaleWhitelist;
    }

    struct PaymentSplitterStruct {
        address simplr;
        uint256 simplrShares;
        address[] payees;
        uint256[] shares;
    }

    struct RevealableStruct {
        bytes32 projectURIProvenance;
        uint256 revealAfterTimestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity ^0.8.9;

import "./Reservable.sol";
import "../../@rarible/royalties/contracts/LibPart.sol";
import "../../@rarible/royalties/contracts/LibRoyaltiesV2.sol";

/**
 * @title Royalties
 * @dev   Module that adds functionality of royalties as required by rarible and EIP-2981.
 */
contract Royalties is Reserveable {
    /**
     * @notice struct made up of two properties
     * account: address of royalty receiver
     * value: royalty percentage, where 10000 = 100% and 100 = 1%
     */
    LibPart.Part internal royalties;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev set royalties, only one address can receive the royalties
     * @param _royalties new royalty struct to be set
     */
    function setRoyalties(LibPart.Part memory _royalties) public onlyOwner {
        require(_royalties.account != address(0x0), "RT:001");
        require(_royalties.value >= 0 && _royalties.value < 10000, "RT:002");
        royalties = _royalties;
    }

    /**
     * @dev see {EIP-2981}
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "RT:003");
        LibPart.Part storage _royalties = royalties;
        if (_royalties.account != address(0) && _royalties.value != 0) {
            return (
                _royalties.account,
                (_salePrice * _royalties.value) / 10000
            );
        }
        return (address(0), 0);
    }

    // for rarible
    /**
     * @dev returns royalties details, implemented for Rarible
     * @param id token id
     * @return array of royalty struct
     */
    function getRaribleV2Royalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory)
    {
        require(_exists(id), "RT:003");
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        LibPart.Part storage _royaltiesRef = royalties;
        _royalties[0].account = _royaltiesRef.account;
        _royalties[0].value = _royaltiesRef.value;
        return _royalties;
    }

    /**
     * @dev see {EIP-165}
     * @param interfaceId interface id of implementation
     * @return true, if implements the interface else false
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES ||
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "./IAffiliateRegistry.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

contract Affiliate {
    IAffiliateRegistry private _affiliateRegistry;
    bytes32 private _projectId;

    event AffiliateShareTransferred(
        address indexed affiliate,
        bytes32 indexed project,
        uint256 value
    );

    function getAffiliateRegistry() public view returns (IAffiliateRegistry) {
        return _affiliateRegistry;
    }

    function getProjectId() public view returns (bytes32) {
        return _projectId;
    }

    function _setAffiliateModule(
        IAffiliateRegistry newRegistry,
        bytes32 projectId
    ) internal {
        require(
            address(newRegistry) != address(0),
            "Affiliate: Registry cannot be null address"
        );
        require(projectId != bytes32(0), "Affiliate: zero project id");
        _affiliateRegistry = newRegistry;
        _projectId = projectId;
    }

    function _setProjectId(bytes32 projectId) internal {
        require(projectId != bytes32(0), "Affiliate: zero project id");
        _projectId = projectId;
    }

    function _transferAffiliateShare(
        bytes memory signature,
        address affiliate,
        uint256 value
    ) internal {
        require(_isAffiliateModuleInitialised(), "Affiliate: not initialised");
        bool isAffiliate;
        uint256 shareValue;
        (isAffiliate, shareValue) = _affiliateRegistry.getAffiliateShareValue(
            signature,
            affiliate,
            _projectId,
            value
        );
        if (isAffiliate) {
            Address.sendValue(payable(affiliate), shareValue);
            emit AffiliateShareTransferred(affiliate, _projectId, shareValue);
        }
    }

    function _isAffiliateModuleInitialised() internal view returns (bool) {
        return
            _projectId != bytes32(0) &&
            address(_affiliateRegistry) != address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "./Revealable.sol";

/**
 * @title Reserveable
 * @dev   Module that adds functionality of reserving tokens from sale. Reserved tokens cannot be bought.
 */
contract Reserveable is Revealable {
    uint256 public reservedTokens; // amount of tokens reserved, that is tokens that won't be sold
    uint256 public reserveTokenCounter; // counter for tokens that have been transfered

    /**
     * @dev set tokens that needs to be reserved, it sets new value, does not add value to previous value
     * @param _reserveTokens new number of tokens to be reserved
     */
    function reserveTokens(uint256 _reserveTokens) external onlyOwner {
        require(tokensCount == 0, "RS:001");
        require(
            _reserveTokens + presaleReservedTokens < maximumTokens,
            "RS:002"
        );
        reservedTokens = _reserveTokens;
        startingTokenIndex = _reserveTokens;
    }

    /**
     * @dev transfer the one reserve tokens to a receiver
     * @param _receiver receiver address of reserved token
     */
    function transferReservedToken(address _receiver) external onlyOwner {
        uint256 currentTokenId = reserveTokenCounter;
        require(currentTokenId < reservedTokens, "RS:001");
        reserveTokenCounter++;
        _safeMint(_receiver, currentTokenId + 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH =
        keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 public constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "./Presaleable.sol";

/**
 * @title Revealable
 * @dev   Module that adds functionality of revealing tokens.
 */
contract Revealable is Presaleable {
    using Strings for uint256;
    bool public isRevealable; // is the collection revealable
    bytes32 public projectURIProvenance; // hash to make sure that Project URI dosen't change
    uint256 public revealAfterTimestamp; // timestamp when the original art needs to be revealed

    /**
     * @dev set revealable details of the collection
     * @param _projectURIProvenance provenance of the collection
     * @param _revealAfterTimestamp reveal timestamp of the collection
     */
    function setRevealableDetails(
        bytes32 _projectURIProvenance,
        uint256 _revealAfterTimestamp
    ) internal {
        require(_revealAfterTimestamp >= block.timestamp, "R:001");
        if (
            _projectURIProvenance != keccak256(abi.encode(loadingURI)) &&
            _revealAfterTimestamp > 0
        ) {
            isRevealable = true;
            projectURIProvenance = _projectURIProvenance;
            _setRevealAfterTimestamp(_revealAfterTimestamp);
        } else {
            projectURI = loadingURI;
        }
    }

    /**
     * @dev set new reveal timestamp
     * @param _revealAfterTimestamp new reveal timestamp of the collection
     */
    function setRevealAfterTimestamp(uint256 _revealAfterTimestamp)
        external
        onlyOwner
    {
        require(isRevealable, "R:002");
        require(_revealAfterTimestamp >= block.timestamp, "R:003");
        _setRevealAfterTimestamp(_revealAfterTimestamp);
    }

    /**
     * @dev set new project URI
     * @param _projectURI new project URI
     */
    function setProjectURI(string memory _projectURI) external onlyOwner {
        projectURI = _projectURI;
    }

    /**
     * @dev view method to return URI of a collection
     * @param tokenId token id
     * @return token URI for the supplied token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "R:004");
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : loadingURI;
    }

    /**
     * @dev private method to set reveal timestamp
     * @param _revealAfterTimestamp new reveal timestamp of the collection
     */
    function _setRevealAfterTimestamp(uint256 _revealAfterTimestamp) private {
        revealAfterTimestamp = _revealAfterTimestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "./PaymentSplitable.sol";

/**
 * @title Presaleable
 * @dev   Module that adds functionality of presale with an optional whitelist presale.
 */
contract Presaleable is PaymentSplitable {
    // presale state
    address public constant SENTINEL_ADDRESS = address(0x1); // last address for linked list

    mapping(address => address) public presaleWhitelist; // addresses that are whitelisted for presale
    uint256 public whitelistCount; // total whitelist addresses
    uint256 public presaleReservedTokens; // number of tokens reserved for presale
    uint256 public presaleMaxHolding; // number of tokens a collector can hold during presale
    uint256 public presalePrice; // price of token during presale
    uint256 public presaleStartTime; // presale start timestamp

    event WhitelistAdded(address indexed addedAddress); // emitted when new address is added to whitelist
    event WhitelistRemoved(address indexed removedAddress); // emitted when a address is remove from whitelist

    modifier presaleAllowed() {
        require(isPresaleAllowed(), "PR:001");
        _;
    }

    /**
     * @dev setup presale details including whitelist
     * @param _presaleReservedTokens number of NFTs reserved for presale
     * @param _presalePrice price per NFT token during presale
     * @param _presaleStartTime presale start timestamp
     * @param _presaleWhitelist array of addresses that are whitelisted for presale
     */
    function setupPresale(
        uint256 _presaleReservedTokens,
        uint256 _presalePrice,
        uint256 _presaleStartTime,
        uint256 _presaleMaxHolding,
        address[] memory _presaleWhitelist
    ) internal {
        if (_presaleStartTime != 0) {
            require(_presaleReservedTokens != 0, "PR:002");
            require(_presaleStartTime > block.timestamp, "PR:003");
            require(_presaleMaxHolding != 0, "PR:004");
            presaleReservedTokens = _presaleReservedTokens;
            presalePrice = _presalePrice;
            presaleStartTime = _presaleStartTime;
            presaleMaxHolding = _presaleMaxHolding;
            if (!(_presaleWhitelist.length == 0)) {
                _presaleWhitelistBatch(_presaleWhitelist);
            }
        }
    }

    /**
     * @dev add whitelist for presale in batch
     * @param _whitelists array of address that needs to be added to presale whitelist
     */
    function presaleWhitelistBatch(address[] memory _whitelists)
        public
        onlyOwner
        presaleAllowed
    {
        _presaleWhitelistBatch(_whitelists);
    }

    /**
     * @dev add an address to presale whitelist
     * @param _whitelistAddress address that needs to be whitelisted for presale
     */
    function addWhitelist(address _whitelistAddress)
        external
        onlyOwner
        presaleAllowed
    {
        address sentinel_address = SENTINEL_ADDRESS;
        if (whitelistCount == 0) {
            presaleWhitelist[sentinel_address] = sentinel_address;
        }
        whitelistCount++;
        require(
            _whitelistAddress != address(0) &&
                _whitelistAddress != sentinel_address &&
                _whitelistAddress != address(this),
            "PR:005"
        );
        require(presaleWhitelist[_whitelistAddress] == address(0), "PR:006");
        presaleWhitelist[_whitelistAddress] = presaleWhitelist[
            sentinel_address
        ];
        presaleWhitelist[sentinel_address] = _whitelistAddress;
        emit WhitelistAdded(_whitelistAddress);
    }

    /**
     * @dev remove an address from presale whitelist
     * @param _prevWhitelistAddress whitelist address that pointed to the address to be removed in the linked list
     * @param _removeWhitelistAddress address to be removed from whitelist
     */
    function removeWhitelist(
        address _prevWhitelistAddress,
        address _removeWhitelistAddress
    ) external onlyOwner presaleAllowed {
        require(
            _removeWhitelistAddress != address(0) &&
                _removeWhitelistAddress != SENTINEL_ADDRESS,
            "PR:005"
        );
        require(
            presaleWhitelist[_prevWhitelistAddress] == _removeWhitelistAddress,
            "PR:007"
        );
        whitelistCount--;
        presaleWhitelist[_prevWhitelistAddress] = presaleWhitelist[
            _removeWhitelistAddress
        ];
        presaleWhitelist[_removeWhitelistAddress] = address(0);
        emit WhitelistRemoved(_removeWhitelistAddress);
    }

    /**
     * @dev setup presale start time
     * @param _newPresaleStartTime new presale start time
     */
    function setPresaleStartTime(uint256 _newPresaleStartTime)
        external
        onlyOwner
    {
        require(
            _newPresaleStartTime > block.timestamp &&
                _newPresaleStartTime != presaleStartTime,
            "PR:008"
        );
        presaleStartTime = _newPresaleStartTime;
    }

    /**
     * @dev buy token during presale
     */
    function presaleBuy()
        external
        payable
        virtual
        whenNotPaused
        presaleAllowed
    {
        require(isPresaleActive(), "PR:009");
        require(msg.value == presalePrice, "PR:010");
        require(
            isPresaleWhitelisted() ? isWhitelisted(msg.sender) : true,
            "PR:011"
        );
        require(balanceOf(msg.sender) + 1 <= presaleMaxHolding, "PR:012");
        _manufacture(msg.sender);
    }

    /**
     * @dev buy tokens in quantity during presale
     * @param _quantity number of tokens to buy
     */
    function presaleBuy(uint256 _quantity) external payable {
        _presaleBuy(msg.sender, _quantity);
    }

    function _presaleBuy(address _buyer, uint256 _quantity)
        internal
        whenNotPaused
        presaleAllowed
    {
        require(isPresaleActive(), "PR:009");
        require(
            isPresaleWhitelisted() ? isWhitelisted(_buyer) : true,
            "PR:011"
        );
        require(tokensCount + _quantity <= presaleReservedTokens, "PR:013");
        require(msg.value == (presalePrice * _quantity), "PR:010");
        require(_quantity <= maxPurchase, "PR:014");
        require(balanceOf(_buyer) + _quantity <= presaleMaxHolding, "PR:012");
        _manufacture(_buyer, _quantity);
    }

    /**
     * @dev get all the whitelistsed address for whitelist
     * @return _array array of addresses that re whitelisted for presale
     */
    function getPresaleWhitelists()
        external
        view
        presaleAllowed
        returns (address[] memory)
    {
        address[] memory _array = new address[](whitelistCount);
        address currentWhitelist = presaleWhitelist[SENTINEL_ADDRESS];
        uint256 index;
        while (currentWhitelist != SENTINEL_ADDRESS) {
            _array[index] = currentWhitelist;
            currentWhitelist = presaleWhitelist[currentWhitelist];
            index++;
        }
        return _array;
    }

    /**
     * @dev check if an address is whitelist or not
     * @param _address address that needs to be checked if whitelisted for presale or not
     * @return a boolean value, if true, address is whitelisted for presale
     */
    function isWhitelisted(address _address) public view returns (bool) {
        return
            _address != SENTINEL_ADDRESS &&
            presaleWhitelist[_address] != address(0);
    }

    /**
     * @dev check if presale is allowed
     * @return a bool, if true, presale is allowed and exists
     */
    function isPresaleAllowed() public view returns (bool) {
        return presaleReservedTokens > 0;
    }

    /**
     * @dev check if presale is whitelisted or not
     * @return a bool, if true, presale is whitelisted
     */
    function isPresaleWhitelisted() public view returns (bool) {
        return isPresaleAllowed() && whitelistCount != 0;
    }

    /**
     * @dev check if presale is active or not
     * @return a bool, if true, presale is active
     */
    function isPresaleActive() public view returns (bool) {
        return
            block.timestamp > presaleStartTime &&
            tokensCount < presaleReservedTokens &&
            block.timestamp < publicSaleStartTime;
    }

    /**
     * @dev private method to add whitelist in batch
     * @param _whitelists array of addresses
     */
    function _presaleWhitelistBatch(address[] memory _whitelists) private {
        address currentWhitelistAddress = SENTINEL_ADDRESS;
        if (whitelistCount == 0) {
            presaleWhitelist[currentWhitelistAddress] = currentWhitelistAddress;
        }
        whitelistCount += _whitelists.length;
        for (uint256 i; i < _whitelists.length; i++) {
            address whitelistAddress = _whitelists[i];
            require(
                whitelistAddress != address(0) &&
                    whitelistAddress != currentWhitelistAddress &&
                    whitelistAddress != address(this) &&
                    whitelistAddress != SENTINEL_ADDRESS,
                "PR:005"
            );
            require(presaleWhitelist[whitelistAddress] == address(0), "PR:006");
            presaleWhitelist[whitelistAddress] = presaleWhitelist[
                currentWhitelistAddress
            ];
            presaleWhitelist[currentWhitelistAddress] = whitelistAddress;
            currentWhitelistAddress = whitelistAddress;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "../base/BaseCollection.sol";

/**
 * @title Payment Splitable
 * @dev   Module that adds functionality of payment splitting.
 */
contract PaymentSplitable is BaseCollection {
    uint256 public constant TOTAL_SHARES = 1e18; // 100% // to avoid rounding errors
    uint256 public constant MAX_PAYEES = 6; // maximum number payees that can be added
    uint256 public SIMPLR_SHARES; // share of Simplr
    address public SIMPLR_RECEIVER_ADDRESS; // address of SIMPLR to receive shares

    struct Payee {
        uint256 shares;
        uint256 amountReleased;
    }

    uint256 public totalReleased; // total amount of payment release

    // Payee State
    mapping(address => Payee) public payees; // mapping of address of payee to Payee struct
    mapping(uint256 => address) public payeeAddress; // mapping of payeeId to payee address
    uint256 public totalPayees; // total number of payees

    /**
     * @dev setup payment splitting details for collection
     * @param _simplr address of simplr beneficicary address
     * @param _simplrShares percentage share of simplr, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
     * @param _payees array of payee address
     * @param _shares array of payee shares, index for both arrays should match for a payee
     */
    function setupPaymentSplitter(
        address _simplr,
        uint256 _simplrShares,
        address[] memory _payees,
        uint256[] memory _shares
    ) internal {
        require(_simplr != address(0), "PS:001");
        SIMPLR_RECEIVER_ADDRESS = _simplr;
        SIMPLR_SHARES = _simplrShares;
        _setPayees(_payees, _shares);
    }

    /**
     * @dev set new payees before releasing any payment
     * @param _payees array of payee address
     * @param _shares array of payee shares, index for both arrays should match for a payee
     */
    function setPayees(address[] memory _payees, uint256[] memory _shares)
        external
        onlyOwner
    {
        require(totalReleased == 0, "PS:002");
        _setPayees(_payees, _shares);
    }

    /**
     * @dev private method to set new payees before releasing any payment
     * @param _payees array of payee address
     * @param _shares array of payee shares, index for both arrays should match for a payee
     */
    function _setPayees(address[] memory _payees, uint256[] memory _shares)
        private
    {
        require(_payees.length == _shares.length, "PS:003");
        uint256 totalSharesAdded;
        if (totalPayees > _payees.length) {
            for (uint256 i = _payees.length; i < totalPayees; i++) {
                delete payees[payeeAddress[i]];
                delete payeeAddress[i];
            }
        }
        for (uint256 i; i < _payees.length; i++) {
            payeeAddress[i] = _payees[i];
            payees[_payees[i]] = Payee(_shares[i], 0);
            totalSharesAdded += _shares[i];
        }
        payeeAddress[_payees.length] = SIMPLR_RECEIVER_ADDRESS;
        payees[SIMPLR_RECEIVER_ADDRESS] = Payee(SIMPLR_SHARES, 0);
        totalPayees = _payees.length + 1;
        require(totalSharesAdded + SIMPLR_SHARES == TOTAL_SHARES, "PS:004");
    }

    /**
     * @dev release payment to a payee
     * @param _amount amount that is to be released
     */
    function release(uint256 _amount) external {
        address _payee = msg.sender;
        require(payees[_payee].shares > 0, "PS:005");
        uint256 payment = pendingPayment(_payee);
        require(payment != 0 && payment >= _amount, "PS:006");
        payees[_payee].amountReleased += _amount;
        totalReleased += _amount;
        Address.sendValue(payable(_payee), _amount);
    }

    /**
     * @dev view method to get the pending amount of a payee
     * @param account payee address
     * @return pending amount
     */
    function pendingPayment(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased;
        return
            (totalReceived * payees[account].shares) /
            TOTAL_SHARES -
            payees[account].amountReleased;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";

/**
 * @title Base Collection
 * @dev   Contract that adds the base functionality of a collection.
 */
contract BaseCollection is Ownable, Pausable, ERC721Enumerable {
    string public constant VERSION = "0.1.0"; // contract version

    //constants
    uint256 public maximumTokens; // total number of tokens.
    uint16 public maxPurchase; // maximum tokens a user can buy per transaction
    uint16 public maxHolding; // maximum tokens a user can hold
    string private _name; // overriden ERC721 _name property, name of collection
    string private _symbol; // overriden ERC721 _symbol property, symbol of collection

    uint256 public tokensCount; // token IDs counter
    uint256 public startingTokenIndex; // starting index of token ID, this si settled to support reserving tokens

    // public sale state
    uint256 public price; // price per token
    uint256 public publicSaleStartTime; // public sale start time, if zero, public sale starts right after presale.
    string public projectURI; // Base URI for project assets
    string public loadingURI; // Base URI for loading URI
    string public metadata; // ipfs hash that stores metadata of the project

    constructor() ERC721("", "") {}

    /**
     * @dev setup sale and other details
     * @param name_ name of the collection
     * @param symbol_ symbol of the collection
     * @param _admin address of admin of the project
     * @param _maximumTokens maximum number of NFTs
     * @param _maxPurchase maximum number of NFTs that can be bought in once transaction
     * @param _maxHolding maximum number of NFTs a user can hold
     * @param _price price per NFT token during public sale.
     * @param _publicSaleStartTime public sale start timestamp
     * @param _loadingURI URI for project media and assets
     */
    function setupBaseCollection(
        string memory name_,
        string memory symbol_,
        address _admin,
        uint256 _maximumTokens,
        uint16 _maxPurchase,
        uint16 _maxHolding,
        uint256 _price,
        uint256 _publicSaleStartTime,
        string memory _loadingURI
    ) internal {
        require(_admin != address(0), "BC:001");
        require(_maximumTokens != 0, "BC:002");
        require(
            _maximumTokens >= _maxHolding && _maxHolding >= _maxPurchase,
            "BC:003"
        );
        _name = name_;
        _symbol = symbol_;
        _transferOwnership(_admin);
        maximumTokens = _maximumTokens;
        maxPurchase = _maxPurchase;
        maxHolding = _maxHolding;
        price = _price;
        publicSaleStartTime = _publicSaleStartTime;
        loadingURI = _loadingURI;
    }

    /**
     * @dev set metadata of the project
     * @param _metadata ipfs hash or CID of the metadata
     */
    function setMetadata(string memory _metadata) external {
        // can only be invoked before setup or by owner after setup
        require(!isSetupComplete() || msg.sender == owner(), "BC:004");
        require(bytes(_metadata).length != 0, "BC:005");
        metadata = _metadata;
    }

    /**
     * @dev set new public sale start time
     * @param _newPublicSaleStartTime new timestamp of public sale start time
     */
    function setPublicSaleStartTime(uint256 _newPublicSaleStartTime)
        external
        onlyOwner
    {
        require(
            _newPublicSaleStartTime > block.timestamp &&
                _newPublicSaleStartTime != publicSaleStartTime,
            "BC:006"
        );
        publicSaleStartTime = _newPublicSaleStartTime;
    }

    /**
     * @dev pause the collection, using OpenZeppelin's Pausable.sol
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev unpause the collection, using OpenZeppelin's Pausable.sol
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev public buy a single token
     */
    function buy() external payable virtual whenNotPaused {
        require(isSaleActive(), "BC:007");
        require(msg.value == price, "BC:008");
        require(balanceOf(msg.sender) + 1 <= maxHolding, "BC:009");
        _manufacture(msg.sender);
    }

    /**
     * @dev public buy tokens in quantity
     * @param _quantity number of tokens to buy
     */
    function buy(uint256 _quantity) external payable virtual {
        _buy(msg.sender, _quantity);
    }

    function _buy(address _buyer, uint256 _quantity) internal whenNotPaused {
        require(isSaleActive(), "BC:010");
        require(msg.value == (price * _quantity), "BC:011");
        require(_quantity <= maxPurchase, "BC:012");
        require(balanceOf(_buyer) + _quantity <= maxHolding, "BC:013");
        _manufacture(_buyer, _quantity);
    }

    /**
     * @dev checks if public sale is active or not
     * @return boolean
     */
    function isSaleActive() public view returns (bool) {
        return
            block.timestamp >= publicSaleStartTime &&
            tokensCount + startingTokenIndex != maximumTokens;
    }

    /**
     * @dev override, to return base uri based
     * @return base uri string
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return projectURI;
    }

    /**
     * @dev override, to return name of collection
     * @return name of collection
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev override, to return symbol of collection
     * @return symbol of collection
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev internal method to manage the minting of tokens
     * @param _buyer address of receiver of minted token
     */
    function _manufacture(address _buyer) internal {
        uint256 currentTokenId = tokensCount + startingTokenIndex;
        tokensCount++;
        _safeMint(_buyer, currentTokenId + 1);
    }

    /**
     * @dev internal method to manage the minting of tokens in quantity
     * @param _buyer address of receiver of minted token
     * @param _quantity number of tokens to mint
     */
    function _manufacture(address _buyer, uint256 _quantity) internal {
        uint256 currentTokenId = tokensCount + startingTokenIndex;
        require(currentTokenId + _quantity <= maximumTokens, "BC:014");
        uint256 newTokensCount = currentTokenId + _quantity;
        tokensCount += _quantity;
        for (
            currentTokenId;
            currentTokenId < newTokensCount;
            currentTokenId++
        ) {
            _safeMint(_buyer, currentTokenId + 1);
        }
    }

    /**
     * @dev checks if setup is complete
     * @return boolean
     */
    function isSetupComplete() public view virtual returns (bool) {
        return maximumTokens != 0 && publicSaleStartTime != 0;
    }

    /**
     * @dev get array of tokens that are bought or holded by a user
     * @return array of token IDs
     */
    function getAllTokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);
        if (balance == 0) {
            return new uint256[](balance);
        } else {
            uint256[] memory tokenList = new uint256[](balance);
            for (uint256 i; i < balance; i++) {
                tokenList[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokenList;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165 {
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

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

interface IAffiliateRegistry {
    function setAffiliateShares(uint256 _affiliateShares, bytes32 _projectId)
        external;

    function registerProject(string memory projectName, uint256 affiliateShares)
        external
        returns (bytes32 projectId);

    function getProjectId(string memory _projectName, address _projectOwner)
        external
        view
        returns (bytes32 projectId);

    function getAffiliateShareValue(
        bytes memory signature,
        address affiliate,
        bytes32 projectId,
        uint256 value
    ) external view returns (bool _isAffiliate, uint256 _shareValue);
}