// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MagicScrolls+.sol";
import "./IMagicScrolls+.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract MagicShopPlus is MagicScrollsPlus, ERC165Storage {
    constructor()
        MagicScrollsPlus(
            "Mona's Magic Shop",
            "MMS",
            "https://us-central1-deguild-2021.cloudfunctions.net/app/readMagicScroll/",
            address(0x4312D992940D0b110525f553160c9984b77D1EF4)
        )
    {
        _registerInterface(type(IMagicScrollsPlus).interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/SkillCertificates/V2/ISkillCertificate+.sol";
import "./IMagicScrolls+.sol";
import "contracts/Utils/EIP-55.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract MagicScrollsPlus is Context, Ownable, IMagicScrollsPlus {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;
    using ChecksumLib for address;
    using ERC165Checker for address;

    /**
     * @dev Classic ERC721 mapping, tracking down the scrolls existed
     * We need to know exactly what happened to the scroll
     * so we keep track of those scrolls here.
     */
    mapping(uint256 => address) private _owners;

    /**
     * @dev This mapping store all scrolls.
     */
    mapping(uint256 => MagicScroll) private _scrollCreated;

    /**
     * @dev This mapping store just scroll types.
     */
    mapping(uint256 => MagicScroll) private _scrollTypes;

    /**
     * @dev Classic ERC1155 mapping, tracking down the balances of each address
     * Given a scroll type and an address, we know the quantity!
     */
    mapping(uint256 => mapping(address => uint256)) private _balances;

    /**
     * @dev This mapping handles permission to use burn().
     */
    mapping(address => bool) private _certificateManagers;

    /**
     * @dev Store the address of Deguild Token
     */
    address private _addressDGT;
    string private _name;
    string private _symbol;
    string private _baseURIscroll;

    /**
     * @dev Store the ID of scrolls and types
     */
    Counters.Counter private tracker = Counters.Counter(0);
    Counters.Counter private variations = Counters.Counter(0);

    /**
     * @dev Store the interface of Deguild Token
     */
    IERC20 private _DGT;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address addressDGT_
    ) {
        _name = name_;
        _symbol = symbol_;
        _addressDGT = addressDGT_;
        _baseURIscroll = baseURI_;
        _DGT = IERC20(addressDGT_);
    }

    /**
     * @dev See {IMagicScrolls-name}.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IMagicScrolls-symbol}.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IMagicScrolls-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 tokenType = _scrollCreated[tokenId].scrollID;
        return tokenTypeURI(tokenType);
    }

    /**
     * @dev See {IMagicScrolls-tokenURI}.
     */
    function tokenTypeURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _existsType(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        abi.encodePacked(baseURI, address(this).getChecksum()),
                        abi.encodePacked("/", tokenId.toString())
                    )
                )
                : "";
    }

    /**
     * @dev See {IMagicScrolls-numberOfScrollTypes}.
     */
    function numberOfScrollTypes()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return variations.current();
    }

    /**
     * @dev See {IMagicScrolls-deguildCoin}.
     */
    function deguildCoin() external view virtual override returns (address) {
        return _addressDGT;
    }

    /**
     * @dev See {IMagicScrolls-ownerOf}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOf(uint256 id)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[id];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IMagicScrolls-balanceOfOne}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOfOne(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IMagicScrolls-balanceOfAll}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOfAll(address account)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](variations.current());

        for (uint256 i = 0; i < variations.current(); ++i) {
            batchBalances[i] = balanceOfOne(account, i);
        }

        return batchBalances;
    }

    /**
     * @dev See {IMagicScrolls-balanceUserOwned}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceUserOwned(address account)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256 balances = 0;

        for (uint256 i = 0; i < tracker.current(); i++) {
            if (_owners[i] == account) {
                balances++;
            }
        }

        uint256[] memory ownedBalances = new uint256[](balances);

        for (uint256 i = tracker.current() - 1; i > 0; i--) {
            if (_owners[i] == account) {
                ownedBalances[--balances] = i;
            }
        }
        return ownedBalances;
    }

    /**
     * @dev See {IMagicScrolls-isCertificateManager}.
     */
    function isCertificateManager(address manager)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _certificateManagers[manager];
    }

    /**
     * @dev See {IMagicScrolls-isPurchasableScroll}.
     */
    function isPurchasableScroll(uint256 scrollType, address buyer)
        public
        view
        virtual
        override
        returns (bool)
    {
        require(_existsType(scrollType), "Scroll does not exist.");
        require(
            _scrollTypes[scrollType].available,
            "This scroll type is no longer purchasable"
        );

        if (!_scrollTypes[scrollType].hasPrerequisite) {
            return true;
        } else {
            require(
                _scrollTypes[scrollType].prerequisite.supportsInterface(
                    type(ISkillCertificatePlus).interfaceId
                ),
                "Address is not supported"
            );
            return
                ISkillCertificatePlus(_scrollTypes[scrollType].prerequisite)
                    .verify(buyer, _scrollTypes[scrollType].certificateId);
        }
    }

    /**
     * @dev See {IMagicScrolls-scrollTypes}.
     */
    function scrollTypes()
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory types;
        uint256 count = 0;

        for (uint256 i = 0; i < variations.current(); i++) {
            if (_scrollTypes[i].available) {
                count++;
            }
        }

        types = new uint256[](count);
        for (uint256 i = 0; i < variations.current(); i++) {
            if (_scrollTypes[i].available) {
                types[--count] = i;
            }
        }
        return types;
    }

    /**
     * @dev See {IMagicScrolls-scrollTypeInfo}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollTypeInfo(uint256 typeId)
        public
        view
        virtual
        override
        returns (
            uint256,
            uint256,
            address,
            bool,
            bool,
            bool
        )
    {
        require(_existsType(typeId), "This scroll type does not exist");
        MagicScroll memory scroll = _scrollTypes[typeId];
        return (
            typeId,
            scroll.price,
            scroll.prerequisite,
            scroll.lessonIncluded,
            scroll.hasPrerequisite,
            scroll.available
        );
    }

    /**
     * @dev See {IMagicScrolls-scrollInfo}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollInfo(uint256 tokenId)
        public
        view
        virtual
        override
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool
        )
    {
        require(_exists(tokenId), "This scroll does not exist");
        MagicScroll memory scroll = _scrollCreated[tokenId];
        return (
            tokenId,
            scroll.scrollID,
            scroll.price,
            scroll.prerequisite,
            scroll.lessonIncluded,
            scroll.hasPrerequisite
        );
    }

    /**
     * @dev See {IMagicScrolls-forceCancel}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function forceCancel(uint256 id) external virtual override returns (bool) {
        _forceCancel(id);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-consume}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function consume(uint256 id) external virtual override returns (bool) {
        _consume(id);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-burn}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function burn(uint256 id) external virtual override returns (bool) {
        _burn(id);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-buyScroll}.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be able to transfer DGT properly and succesfully.
     */
    function buyScroll(uint256 scrollType)
        external
        virtual
        override
        returns (bool)
    {
        _buyScroll(scrollType);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-addScroll}.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be the owner of the shop.
     */
    function addScroll(
        uint256 certificateId,
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) external virtual override onlyOwner returns (bool) {
        _addScroll(
            certificateId,
            prerequisite,
            lessonIncluded,
            hasPrerequisite,
            price
        );
        return true;
    }

    /**
     * @dev See {IMagicScrolls-setCertificateManager}.
     *
     * Requirements:
     *
     * - The caller must be the owner of the shop.
     */
    function setCertificateManager(address manager, bool status)
        external
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _certificateManagers[manager] = status;
        emit ApprovalForCM(manager, status);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-sealScroll}.
     *
     * Requirements:
     *
     * - `scroll` type must exist.
     * - The caller must be the owner of the shop.
     */
    function sealScroll(uint256 scrollType)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _sealScroll(scrollType);
        return true;
    }

    function _addScroll(
        uint256 certificateId,
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) private {
        _scrollTypes[variations.current()] = MagicScroll({
            scrollID: variations.current(),
            price: price,
            certificateId: certificateId,
            prerequisite: prerequisite, //certification required
            state: 1,
            lessonIncluded: lessonIncluded,
            hasPrerequisite: hasPrerequisite,
            available: true
        });
        emit ScrollAdded(
            variations.current(),
            price,
            prerequisite,
            lessonIncluded,
            hasPrerequisite,
            true
        );
        variations.increment();
    }

    function _sealScroll(uint256 scrollType) private onlyOwner returns (bool) {
        require(_existsType(scrollType), "This scroll type does not exist");

        _scrollTypes[scrollType].available = false;
        emit ScrollAdded(
            _scrollTypes[scrollType].scrollID,
            _scrollTypes[scrollType].price,
            _scrollTypes[scrollType].prerequisite,
            _scrollTypes[scrollType].lessonIncluded,
            _scrollTypes[scrollType].hasPrerequisite,
            _scrollTypes[scrollType].available
        );
        return true;
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _existsType(uint256 tokenId) private view returns (bool) {
        require(
            variations.current() > tokenId,
            "There are not that many types of scroll"
        );
        return _scrollTypes[tokenId].available;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() private view returns (string memory) {
        return _baseURIscroll;
    }

    function _buyScroll(uint256 scrollType) private {
        // check for validity to buy from interface for certificate
        require(
            isPurchasableScroll(scrollType, _msgSender()),
            "This scroll is not purchasable."
        );
        require(
            _DGT.transferFrom(
                _msgSender(),
                owner(),
                _scrollTypes[scrollType].price
            ),
            "Cannot transfer DGC, approve the contract or buy more DGC!"
        );
        _scrollCreated[tracker.current()] = _scrollTypes[scrollType];
        _owners[tracker.current()] = _msgSender();
        _balances[scrollType][_msgSender()]++;

        emit ScrollBought(tracker.current(), scrollType);
        tracker.increment();
    }

    function _burn(uint256 id) private {
        require(_exists(id), "Nonexistent token");
        require(
            _msgSender().supportsInterface(
                type(ISkillCertificatePlus).interfaceId
            ),
            "Address is not supported"
        );
        require(
            isCertificateManager(_msgSender()),
            "You are not the certificate manager, burning is reserved for the claiming certificate only."
        );
        require(
            _scrollCreated[id].state == 1 || _scrollCreated[id].state == 2,
            "This scroll is no longer burnable."
        );
        _balances[_scrollCreated[id].scrollID][ownerOf(id)]--;
        _scrollCreated[id].state = 0; //consumed state id
        _owners[id] = address(0);

        emit StateChanged(id, _scrollCreated[id].state);
    }

    function _forceCancel(uint256 id) private onlyOwner {
        require(_exists(id), "Nonexistent token");
        _scrollCreated[id].state = 99; //Cancelled state id
        emit StateChanged(id, _scrollCreated[id].state);
    }

    function _consume(uint256 id) internal virtual {
        uint256 scrollType = _scrollCreated[id].scrollID;

        require(_exists(id), "Nonexistent token");
        require(
            isCertificateManager(_msgSender()),
            "You are not the certificate manager, consuming is reserved for the claiming exam key only."
        );
        require(
            _msgSender().supportsInterface(
                type(ISkillCertificatePlus).interfaceId
            ),
            "Address is not supported"
        );
        require(
            ISkillCertificatePlus(_msgSender()).typeAccepted(scrollType) ==
                scrollType,
            "Wrong type of scroll to be consumed."
        );
        require(
            _scrollCreated[id].state == 1,
            "This scroll is no longer consumable."
        );
        _scrollCreated[id].state = 2; //consumed state id
        emit StateChanged(id, _scrollCreated[id].state);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * NFT style interface, but it does not allow transfer like other ERC721 and ERC1155
 * It requires DGT & SkillCertificate to work around with. Basically, we try to make a shop out of it!
 * As the first version, here are the list of functions, events, and structs we used.
 */
interface IMagicScrollsPlus {
    /**
     * @dev This data type is used to store the data of a magic scroll.
     * scrollID         (uint256) is the unique type of that scroll.
     * price            (uint256) is the price of that scroll.
     * prerequisite     (address) is the address of the certificate manager (any address is fine, if it has no prerequisite).
     * state            (uint8)   is the state of the scroll (Consumed or cancelled or fresh).
     * lessonIncluded   (bool)    is the state telling that this scroll can be used for unlocking learning materials off-chain.
     * hasPrerequisite  (bool)    is the state telling that this scroll requires a certificate from the certificate manager given.
     * available        (bool)    is the state telling that this scroll is no longer purchasable
     *                            (only used to check the availability to mint various magic scroll types)
     */
    struct MagicScroll {
        uint256 scrollID;
        uint256 price;
        uint256 certificateId;
        address prerequisite;
        uint8 state;
        bool lessonIncluded;
        bool hasPrerequisite;
        bool available;
    }

    /**
     * @dev Emitted when `scrollId` make changes to its state, changing to `scrollState`.
     */
    event StateChanged(uint256 scrollId, uint8 scrollState);

    /**
     * @dev Emitted when `scrollId` is minted based from scroll of type `scrollType`.
     */
    event ScrollBought(uint256 scrollId, uint256 scrollType);

    /**
     * @dev Emitted when a new scroll is added, giving that scroll of type `scrollId` is ready to be minted.
     */
    event ScrollAdded(
        uint256 scrollID,
        uint256 price,
        address indexed prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        bool available
    );

    /**
     * @dev Emitted when `account` gained or lost permission to be a certificate manager.
     */
    event ApprovalForCM(address indexed account, bool status);

    /**
     * @dev Returns the shop name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the shop symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` cannot be non-existence token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token type.
     *
     * Requirements:
     *
     * - `tokenId` cannot be non-existence token.
     */
    function tokenTypeURI(uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @dev Returns the number of scroll types available to be bought
     */
    function numberOfScrollTypes() external view returns (uint256);

    /**
     * @dev Returns the acceptable token address.
     */
    function deguildCoin() external view returns (address);

    /**
     * @dev Returns the owner of the `id` token.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOf(uint256 id) external view returns (address);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOfOne(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the balance that `account` owned, according to types.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOfAll(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the balance that `account` owned, according to ownership of
     * minted scrolls.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceUserOwned(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns true if `manager` is approved to burn tokens.
     */
    function isCertificateManager(address manager) external view returns (bool);

    /**
     * @dev Returns true if `scrollType` is purchasable for `buyer`.
     *      Each scroll has its own conditions to purchase.
     */
    function isPurchasableScroll(uint256 scrollType, address buyer)
        external
        view
        returns (bool);

    /**
     * @dev Returns the array of scroll types' ids that are available to be purchase.
     */
    function scrollTypes() external view returns (uint256[] memory);

    /**
     * @dev Returns the information of the token type of `typeId`.
     * [0] (uint256)    typeId
     * [1] (uint256)    price of this `typeId` type
     * [2] (address)    prerequisite of this `typeId` type
     * [3] (bool)       lessonIncluded of this `typeId` type
     * [4] (bool)       hasPrerequisite of this `typeId` type
     * [5] (bool)       available of this `typeId` type
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollTypeInfo(uint256 typeId)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            bool,
            bool,
            bool
        );

    /**
     * @dev Returns the information of the token type of `tokenId`.
     * [0] (uint256)    tokenId
     * [1] (uint256)    scrollID of this `tokenId`.
     * [2] (uint256)    price of this `tokenId`.
     * [3] (address)    prerequisite of this `tokenId`.
     * [4] (bool)       lessonIncluded of this `tokenId`.
     * [5] (bool)       hasPrerequisite of this `tokenId`.
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollInfo(uint256 tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool
        );

    /**
     * @dev Change `id` token state to 99 (Cancelled).
     *
     * Usage : Neutralize the scroll if something fishy occurred with the owner.
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function forceCancel(uint256 id) external returns (bool);

    /**
     * @dev Change `id` token state to 2 (Consumed).
     *
     * Usage : Unlock a key from certificate manager to take examination
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function consume(uint256 id) external returns (bool);

    /**
     * @dev Change `id` token state to 0 (Burned) and transfer ownership to address(0).
     *
     * Usage : Burn the token
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function burn(uint256 id) external returns (bool);

    /**
     * @dev Mint a scroll of type `scroll`.
     *
     * Usage : Buy a magic scroll
     * Emits a {ScrollBought} event.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be able to transfer DGT properly and succesfully.
     */
    function buyScroll(uint256 scroll) external returns (bool);

    /**
     * @dev Mint a type scroll.
     *
     * Usage : Add a magic scroll
     * Emits a {ScrollAdded} event.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be the owner of the shop.
     */
    function addScroll(
        uint256 certificateId,
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) external returns (bool);

    /**
     * @dev Set `manager` to be a CertificateManager or not.
     *
     * Emits a {ApprovalForCM} event.
     *
     * Requirements:
     *
     * - The caller must be the owner of the shop.
     */
    function setCertificateManager(address manager, bool status)
        external
        returns (bool);

    /**
     * @dev When owner want to seal a scroll, it will check for existence and seal them forever (not mintable anymore and cannot be used later on).
     *
     * Requirements:
     *
     * - `scroll` type must exist.
     * - The caller must be the owner of the shop.
     */
    function sealScroll(uint256 scrollType) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * NFT style interface, but it does not simple transfer like other ERC1155
 * It requires MagicScrolls to work around with. Basically, we try to make a certificate out of it!
 */
interface ISkillCertificatePlus {
    /**
     * @dev Emitted when `scrollId` certificate is minted for `student`.
     */
    event CertificateMinted(address student, uint256 scrollId);

    /**
     * @dev Emitted when `scrollId` certificate is burned for `student`.
     */
    event CertificateBurned(address student, uint256 scrollId);

    /**
     * @dev Returns the certificate name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the certificate symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the associated shop address.
     */
    function shop() external view returns (address);

    function typesExisted() external view returns (uint256);

    /**
     * @dev Returns the type of scroll accepted from associated shop address.
     */
    function typeAccepted(uint256 typeId) external view returns (uint256);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 typeId) external view returns (string memory);

    /**
     * @dev Returns the owner of the `id` token.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOfType(uint256 tokenId, uint256 typeId)
        external
        view
        returns (address);

    /**
     * @dev Change `id` token state to 99 (Cancelled).
     *
     * Usage : Neutralize the scroll if something fishy occurred with the owner.
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function verify(address student, uint256 typeId)
        external
        view
        returns (bool);

    function addCertificate(uint256 scrollTypeId)
        external
        returns (bool);

    /**
     * @dev Burn `id` token to address(0) (Also, void the certification).
     *
     * Usage : Burn the certificate.
     * Emits a {CertificateBurned} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function forceBurn(uint256 id, uint256 typeId) external returns (bool);

    /**
     * @dev Mind a token to `to` (Also, give the certification and burn `scrollOwnedID` in the shop).
     *
     * Usage : Mint the certificate.
     * Emits a {CertificateMinted} event.
     *
     * Requirements:
     *
     * - `to` must the owner of `scrollOwnedID`.
     * - `scrollOwnedID` must be burned.
     */
    function mint(
        address to,
        uint256 scrollOwnedID,
        uint256 typeId
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ChecksumLib {

    /*
     * @dev Get a checksummed string hex representation of an account address.
     * @param account address The account to get the checksum for.
     * @return The checksummed account string in ASCII format.
     */
    function getChecksum(address account)
        public
        pure
        returns (string memory accountChecksum)
    {
        // call internal function for converting an account to a checksummed string.
        return string(abi.encodePacked("0x", _toChecksumString(account)));
    }

    /*
     * @dev Get a fixed-size array of whether or not each character in an account
     * will be capitalized in the checksum.
     * @param account address The account to get the checksum capitalization
     * information for.
     * @return A fixed-size array of booleans that signify if each character or
     * "nibble" of the hex encoding of the address will be capitalized by the
     * checksum.
     */
    function getChecksumCapitalizedCharacters(address account)
        public
        pure
        returns (bool[40] memory characterCapitalized)
    {
        // call internal function for computing characters capitalized in checksum.
        return _toChecksumCapsFlags(account);
    }

    function _toChecksumString(address account)
        private
        pure
        returns (string memory asciiString)
    {
        // convert the account argument from address to bytes.
        bytes20 data = bytes20(account);

        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        bool leftCaps;
        bool rightCaps;
        uint8 asciiOffset;

        // get the capitalized characters in the actual checksum.
        bool[40] memory caps = _toChecksumCapsFlags(account);

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // locate and extract each capitalization status.
            leftCaps = caps[2 * i];
            rightCaps = caps[2 * i + 1];

            // get the offset from nibble value to ascii character for left nibble.
            asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);

            // get the offset from nibble value to ascii character for right nibble.
            asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
        }

        return string(asciiBytes);
    }

    function _toChecksumCapsFlags(address account)
        private
        pure
        returns (bool[40] memory characterCapitalized)
    {
        // convert the address to bytes.
        bytes20 a = bytes20(account);

        // hash the address (used to calculate checksum).
        bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

        // declare variable types.
        uint8 leftNibbleAddress;
        uint8 rightNibbleAddress;
        uint8 leftNibbleHash;
        uint8 rightNibbleHash;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i; i < a.length; i++) {
            // locate the byte and extract each nibble for the address and the hash.
            rightNibbleAddress = uint8(a[i]) % 16;
            leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
            rightNibbleHash = uint8(b[i]) % 16;
            leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

            characterCapitalized[2 * i] = (leftNibbleAddress > 9 &&
                leftNibbleHash > 7);
            characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 &&
                rightNibbleHash > 7);
        }
    }

    /*
     * @dev Determine whether a string hex representation of an account address
     * matches the ERC-55 checksum of that address.
     * @param accountChecksum string The checksummed account string in ASCII
     * format. Note that a leading "0x" MUST NOT be included.
     * @return A boolean signifying whether or not the checksum is valid.
     */
    function _isChecksumValid(string memory provided)
        private
        pure
        returns (bool ok)
    {
        // convert the provided string into account type.
        address account = _toAddress(provided);

        // return false in the event the account conversion returned null address.
        if (account == address(0)) {
            // ensure that provided address is not also the null address first.
            bytes memory b = bytes(provided);
            for (uint256 i; i < b.length; i++) {
                if (b[i] != hex"30") {
                    return false;
                }
            }
        }

        // get the capitalized characters in the actual checksum.
        string memory actual = _toChecksumString(account);

        // compare provided string to actual checksum string to test for validity.
        return (keccak256(abi.encodePacked(actual)) ==
            keccak256(abi.encodePacked(provided)));
    }

    function _getAsciiOffset(uint8 nibble, bool caps)
        private
        pure
        returns (uint8 offset)
    {
        // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
        if (nibble < 10) {
            offset = 48;
        } else if (caps) {
            offset = 55;
        } else {
            offset = 87;
        }
    }

    function _toAddress(string memory account)
        private
        pure
        returns (address accountAddress)
    {
        // convert the account argument from address to bytes.
        bytes memory accountBytes = bytes(account);

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        // only proceed if the provided string has a length of 40.
        if (accountBytes.length == 40) {
            for (uint256 i; i < 40; i++) {
                // get the byte in question.
                b = uint8(accountBytes[i]);

                // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
                if (b < 48) return address(0);
                if (57 < b && b < 65) return address(0);
                if (70 < b && b < 97) return address(0);
                if (102 < b) return address(0); //bytes(hex"");

                // find the offset from ascii encoding to the nibble representation.
                if (b < 65) {
                    // 0-9
                    asciiOffset = 48;
                } else if (70 < b) {
                    // a-f
                    asciiOffset = 87;
                } else {
                    // A-F
                    asciiOffset = 55;
                }

                // store left nibble on even iterations, then store byte on odd ones.
                if (i % 2 == 0) {
                    nibble = b - asciiOffset;
                } else {
                    accountAddressBytes[(i - 1) / 2] = (
                        bytes1(16 * nibble + (b - asciiOffset))
                    );
                }
            }

            // pack up the fixed-size byte array and cast it to accountAddress.
            bytes memory packed = abi.encodePacked(accountAddressBytes);
            assembly {
                accountAddress := mload(add(packed, 20))
            }
        }
    }

    // based on https://ethereum.stackexchange.com/a/56499/48410
    function _toAsciiString(bytes20 data)
        private
        pure
        returns (string memory asciiString)
    {
        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
            asciiBytes[2 * i] = bytes1(
                leftNibble + (leftNibble < 10 ? 48 : 87)
            );
            asciiBytes[2 * i + 1] = bytes1(
                rightNibble + (rightNibble < 10 ? 48 : 87)
            );
        }

        return string(asciiBytes);
    }
}

// SPDX-License-Identifier: MIT

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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
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

// SPDX-License-Identifier: MIT

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