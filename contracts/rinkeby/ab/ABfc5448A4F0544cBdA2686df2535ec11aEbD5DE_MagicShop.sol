// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MagicScrolls.sol";

contract MagicShop is MagicScrolls {
    constructor()
        MagicScrolls(
            "Mona's Magic Shop",
            "MMS",
            "https://atlas-content1-cdn.pixelsquid.com/assets_v2/",
            address(0x4312D992940D0b110525f553160c9984b77D1EF4)
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SkillCertificates/ISkillCertificate.sol";
import "./IMagicScrolls.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MagicScrolls is Context, Ownable, IMagicScrolls {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;

    struct MagicScroll {
        uint256 scrollID;
        uint256 price;
        address prerequisite; //certification required, check for existence and validity
        uint8 state;
        bool lessonIncluded;
        bool hasPrerequisite;
        bool available;
    }

    /**
     * @dev Classic ERC721 mapping, tracking down the scrolls existed
     * We need to know exactly what happened to the scroll
     * so we keep track of those scrolls here.
     */
    mapping(uint256 => address) private _owners;
    mapping(uint256 => MagicScroll) private _scrollCreated;

    mapping(uint256 => MagicScroll) private _scrollTypes;

    /**
     * @dev Classic ERC1155 mapping, tracking down the balances of each address
     * Given a scroll type and an address, we know the quantity!
     */
    mapping(uint256 => mapping(address => uint256)) private _balances;

    address private _addressDGC;
    string private _name;
    string private _symbol;
    string private _baseURIscroll;
    Counters.Counter private tracker = Counters.Counter(0);
    Counters.Counter private variations = Counters.Counter(0);
    IERC20 private _DGC;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address addressDGC_
    ) {
        _name = name_;
        _symbol = symbol_;
        _addressDGC = addressDGC_;
        _baseURIscroll = baseURI_;
        _DGC = IERC20(addressDGC_);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
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
     * @dev See {IERC721-ownerOf}.
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
     * @dev Telling what this address own
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
     * @dev Check every type of scroll in one account
     *
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
     * @dev Check every type of scroll in one account, check the struct to decode it properly
     *
     */
    function scrollTypes() public view virtual returns (MagicScroll[] memory) {
        MagicScroll[] memory batchBalances = new MagicScroll[](
            variations.current()
        );

        for (uint256 i = 0; i < variations.current(); ++i) {
            batchBalances[i] = _scrollTypes[i];
        }
        return batchBalances;
    }

    /**
     * @dev Check every type of scroll in one account
     *
     */
    function scrollTypeInfo(uint256 typeId)
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
            bool,
            bool
        )
    {
        require(_existsType(typeId), "This scroll type does not exist");
        MagicScroll memory scroll = _scrollTypes[typeId];
        return (
            typeId,
            scroll.scrollID,
            scroll.price,
            scroll.prerequisite,
            scroll.lessonIncluded,
            scroll.hasPrerequisite,
            scroll.available
        );
    }

    /**
     * @dev Check every type of scroll in one account
     *
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
            scroll.hasPrerequisite,
            scroll.available
        );
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the acceptable token name.
     */
    function deguildCoin() external view virtual override returns (address) {
        return _addressDGC;
    }

    /**
     * @dev Returns the token collection name.
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
     * @dev Returns the token collection symbol.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
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

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function forceCancel(uint256 id) external virtual override returns (bool) {
        _forceCancel(id);
        return true;
    }

    function consume(uint256 id) external virtual override returns (bool) {
        _consume(id);
        return true;
    }

    function burn(uint256 id) external virtual override returns (bool) {
        _burn(id);
        return true;
    }

    //This function suppose to be a view function
    function isPurchasableScroll(uint256 scrollType)
        public
        view
        virtual
        returns (bool)
    {
        require(_existsType(scrollType), "Scroll does not exist.");
        if (!_scrollTypes[scrollType].hasPrerequisite) return true;
        require(
            ISkillCertificate(_scrollTypes[scrollType].prerequisite).verify(
                _msgSender()
            ) && _scrollTypes[scrollType].available,
            "You are not verified or this scroll type is no longer purchasable."
        );
        return true;
    }

    function buyScroll(uint256 scrollType)
        external
        virtual
        override
        returns (bool)
    {
        // check for validity to buy from interface for certificate
        require(
            isPurchasableScroll(scrollType),
            "This scroll is not purchasable."
        );
        require(
            _DGC.transferFrom(
                _msgSender(),
                owner(),
                _scrollTypes[scrollType].price
            ),
            "Cannot transfer DGC, approve the contract or buy more DGC!"
        );
        return _buyScroll(scrollType);
    }

    function addScroll(
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) external virtual override onlyOwner returns (bool) {
        _addScroll(prerequisite, lessonIncluded, hasPrerequisite, price);
        return true;
    }

    function sealScroll(uint256 scrollType)
        external
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _sealScroll(scrollType);
        return true;
    }

    function _addScroll(
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) internal virtual onlyOwner {
        _scrollTypes[variations.current()] = MagicScroll({
            scrollID: variations.current(),
            price: price,
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

    function _sealScroll(uint256 scrollType)
        internal
        virtual
        onlyOwner
        returns (bool)
    {
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

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _existsType(uint256 tokenId) internal view virtual returns (bool) {
        return variations.current() > tokenId;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseURIscroll;
    }

    function _buyScroll(uint256 scrollType) internal virtual returns (bool) {
        _scrollCreated[tracker.current()] = _scrollTypes[scrollType];
        _owners[tracker.current()] = _msgSender();
        _balances[scrollType][_msgSender()]++;

        emit ScrollBought(tracker.current(), scrollType);
        tracker.increment();
        return true;
    }

    function _burn(uint256 id) internal virtual {
        require(_exists(id), "Nonexistent token");
        require(
            _msgSender() == _scrollCreated[id].prerequisite ||
                _msgSender() == owner(),
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

    function _forceCancel(uint256 id) internal virtual {
        require(_exists(id), "Nonexistent token");
        require(
            _msgSender() == _owners[id] || _msgSender() == owner(),
            "You are not the owner of this item"
        );
        _scrollCreated[id].state = 99; //Cancelled state id
        emit StateChanged(id, _scrollCreated[id].state);
    }

    function _consume(uint256 id) internal virtual {
        require(_exists(id), "Nonexistent token");

        require(
            _msgSender() == _owners[id] || _msgSender() == owner(),
            "You are not the owner of this item"
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

interface ISkillCertificate {
    /**
     * NFT style interface, but it does not simple transfer like other ERC721 and ERC1155
     * It requires MagicScrolls to work around with. Basically, we try to make a certificate out of it!
     */

    event CertificateMinted(uint256 scrollId);

    /**
     * @dev Returns the owner of the `id` token.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOf(uint256 id) external view returns (address);

    /**
     * @dev Returns the shop name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the shop symbol.
     */
    function symbol() external view returns (string memory);

    function shop() external view returns (address);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev When there is a problem, cancel this item.
     */
    function forceBurn(uint256 id) external;
    

    /**
     * @dev When user want to get a certificate, mint this item and burn a scroll.
     */
    function mint(address to, uint256 scrollOwnedID) external returns (bool);

    /**
     * @dev returns the validity of the certificate of student.
     */
    function verify(address student)
        external view
        returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * NFT style interface, but it does not simple transfer like other ERC721 and ERC1155
 * It requires DGC & SkillCertificate to work around with. Basically, we try to make a shop out of it!
 */
interface IMagicScrolls {
    /**
     * @dev From logging, we show that the minted scroll has changed its state
     */
    event StateChanged(uint256 scrollId, uint8 scrollState);

    /**
     * @dev From logging, we show that the a scroll of one type has been minted
     */
    event ScrollBought(uint256 scrollId, uint256 scrollType);

    /**
     * @dev From logging, we show that the a type of scroll has been added to the list
     */
    event ScrollAdded(
        uint256 scrollID,
        uint256 price,
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        bool available
    );

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function balanceOfOne(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the owner of the `id` token.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOf(uint256 id) external view returns (address);

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
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Returns the number of scroll types available to be bought
     */
    function numberOfScrollTypes() external view returns (uint256);

    /**
     * @dev Returns the balance that this account owned, according to type
     */
    function balanceOfAll(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the balance that this account owned, according to ownership of minted scrolls
     */
    function balanceUserOwned(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev When there is a problem, cancel this item.
     */
    function forceCancel(uint256 id) external returns (bool);

    /**
     * @dev When user wants to take a test, consume this item.
     */
    function consume(uint256 id) external returns (bool);

    /**
     * @dev When user want to get a certificate, burn this item.
     */
    function burn(uint256 id) external returns (bool);

    /**
     * @dev When user want to get a scroll, transfer DGC to owner of the shop, returns the newest minted id.
     */
    function buyScroll(uint256 scroll) external returns (bool);

    /**
     * @dev When owner want to add a scroll, returns the newest scroll type id.
     */
    function addScroll(
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) external returns (bool);

    /**
     * @dev When owner want to seal a scroll, it will check for existence and seal them forever (not mintable anymore and cannot be used later on).
     */
    function sealScroll(uint256 scrollType) external returns (bool);

    /**
     * @dev Returns the acceptable token name.
     */
    function deguildCoin() external view returns (address);

    function scrollTypeInfo(uint256 typeId)
        external
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool,
            bool
        );

    function scrollInfo(uint256 tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool,
            bool
        );
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

