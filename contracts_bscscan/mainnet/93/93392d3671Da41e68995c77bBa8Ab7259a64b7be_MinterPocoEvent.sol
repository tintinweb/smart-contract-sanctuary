// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../interfaces/IPocoEquiment.sol";
import "../interfaces/IPocoCharacter.sol";
import "../interfaces/IStaskingPocoTicket.sol";
import "../utils/PocoRandom.sol";

contract MinterPocoEvent is Initializable , OwnableUpgradeable{
    
    constructor() initializer {}

    uint256 public mintedCounter;
    address public pocoEquiment;
    address public pocoCharacter;
    address public treasury;
    address public stakingTicket;
    address private pocoRandom;

    // Event noel config
    uint256 public limitTicket;
    uint256 public limitCharacter;
    uint256 public limitItem;
    uint256 public mintedItem;
    uint256 public mintedCharacter;
    uint256 public spinedTicket;


    // resultType : 1 - Unlucky , 2 - Get Character, 3 - Get Item
    event SpinTicketNoelResult(uint256 indexed resultType, address indexed minter, uint256 indexed nftId, uint256 randomValue);

    function initialize() initializer public {
        __Ownable_init();
    }

    modifier onlyNonContract {
        require(tx.origin == msg.sender, "Only non-contract call");
        _;
    }

    // Update config
    function updateConfig(address _treasury, address _pocoRandom, address _pocoCharacter, address _pocoEquiment, address _stakingTicket) public onlyOwner{
        treasury = _treasury;
        pocoCharacter  = _pocoCharacter;
        pocoEquiment = _pocoEquiment;
        pocoRandom  = _pocoRandom;
        stakingTicket = _stakingTicket;
    }

    // Config Noel Event
    function updateNoelEvent(uint256 _limitTicket, uint256 _limitCharacter, uint256 _limitItem) public onlyOwner{
        limitItem = _limitItem;
        limitCharacter  = _limitCharacter;
        limitTicket  = _limitTicket;
    }

    // Get random number
    function spinTicketNoelEvent() public onlyNonContract {
        require(spinedTicket < limitTicket, "exceed limit ticket of Noel event." );
        spinedTicket += 1;
        IStaskingPocoTicket(stakingTicket).useTicket(1, msg.sender);
        uint256 randomValue = PocoRandom(pocoRandom).getPocoRandom(10000);
        if (randomValue < 1125) {
            // Get character
            uint256 skin;
            uint256 skill;
            uint256 element; // 1 - dark, 2 - fire, 3 - light, 4- water, 5- wind
            uint256 randomChar = PocoRandom(pocoRandom).getPocoRandom(10);
            // Skin order: 11-wing(1-2)-face_skin(49-58)-face(1-2)-earn(11-12)-body_skin(42)-body(7-8) 
            if (mintedCharacter < limitCharacter) {
                if (randomChar == 1) {
                    skin = 11 * 1e12 + 1 * 1e10  + 49 * 1e8 + 1 * 1e6 + 11 * 1e4 + 42 * 1e2 + 7;
                    skill = 11 * 1e4 + 7 * 1e2 + 4;
                    element = 1; 
                }
                else if (randomChar == 2) {
                    skin = 11 * 1e12 + 2 * 1e10  + 50 * 1e8 + 2 * 1e6 + 12 * 1e4 + 42 * 1e2 + 8;
                    skill = 11 * 1e4 + 10 * 1e2 + 5;
                    element = 1; 
                }
                else if (randomChar == 3) {
                    skin = 11 * 1e12 + 1 * 1e10  + 51 * 1e8 + 1 * 1e6 + 11 * 1e4 + 42 * 1e2 + 7;
                    skill = 11 * 1e4 + 7 * 1e2 + 4;
                    element = 2; 
                }
                else if (randomChar == 4) {
                    skin = 11 * 1e12 + 2 * 1e10  + 52 * 1e8 + 2 * 1e6 + 12 * 1e4 + 42 * 1e2 + 8;
                    skill = 11 * 1e4 + 10 * 1e2 + 5;
                    element = 2; 
                }
                else if (randomChar == 5) {
                    skin = 11 * 1e12 + 1 * 1e10  + 53 * 1e8 + 1 * 1e6 + 11 * 1e4 + 42 * 1e2 + 7;
                    skill = 11 * 1e4 + 7 * 1e2 + 4;
                    element = 3; 
                }
                else if (randomChar == 6) {
                    skin = 11 * 1e12 + 2 * 1e10  + 54 * 1e8 + 2 * 1e6 + 12 * 1e4 + 42 * 1e2 + 8;
                    skill = 11 * 1e4 + 10 * 1e2 + 5;
                    element = 3; 
                }
                else if (randomChar == 7) {
                    skin = 11 * 1e12 + 1 * 1e10  + 55 * 1e8 + 1 * 1e6 + 11 * 1e4 + 42 * 1e2 + 7;
                    skill = 11 * 1e4 + 7 * 1e2 + 4;
                    element = 4; 
                }
                else if (randomChar == 8) {
                    skin = 11 * 1e12 + 2 * 1e10  + 56 * 1e8 + 2 * 1e6 + 12 * 1e4 + 42 * 1e2 + 8;
                    skill = 11 * 1e4 + 10 * 1e2 + 5;
                    element = 4; 
                }
                else if (randomChar == 9) {
                    skin = 11 * 1e12 + 1 * 1e10  + 57 * 1e8 + 1 * 1e6 + 11 * 1e4 + 42 * 1e2 + 7;
                    skill = 11 * 1e4 + 7 * 1e2 + 4;
                    element = 5; 
                }
                else if (randomChar == 10) {
                    skin = 11 * 1e12 + 2 * 1e10  + 58 * 1e8 + 2 * 1e6 + 12 * 1e4 + 42 * 1e2 + 8;
                    skill = 11 * 1e4 + 10 * 1e2 + 5;
                    element = 5; 
                }
                // Source = 3: Event Noel
                IPocoCharacter(pocoCharacter).safeMintbyEvent(msg.sender, skill, skin, element, 3); 
                // 2 is spin ticket got character 
                emit SpinTicketNoelResult(2, msg.sender, IPocoCharacter(pocoCharacter).currentTokenIDCounter() - 1, randomValue);
                mintedCharacter += 1;
            }
        }
        else if ( randomValue > 7360) {
            if (mintedItem < limitItem) {
                    
                // Source = 3: Event Noel
                uint256 itemTypeID = PocoRandom(pocoRandom).getPocoRandom(5);
                uint256 additionValue;
                if (itemTypeID ==  5) {
                    additionValue = PocoRandom(pocoRandom).getPocoRandom(7) + 3;
                } else if (itemTypeID == 4) {
                    additionValue = PocoRandom(pocoRandom).getPocoRandom(9) + 11;
                }
                else if (itemTypeID == 3) {
                    additionValue = PocoRandom(pocoRandom).getPocoRandom(4) + 4;
                }
                else if (itemTypeID == 2) {
                    additionValue = PocoRandom(pocoRandom).getPocoRandom(41) + 79;
                }
                else {
                    additionValue = PocoRandom(pocoRandom).getPocoRandom(9) + 11; 
                }
                IPocoEquiment(pocoEquiment).safeMintEvent(msg.sender, itemTypeID, 11, additionValue); 
                // 3 is spin ticket got character 
                emit SpinTicketNoelResult(3, msg.sender, IPocoEquiment(pocoEquiment).currentTokenIDCounter() - 1, randomValue);
                mintedItem += 1;
            }
        }
        else {
            // 1 is spin ticket got nothing. Unlucky 
            emit SpinTicketNoelResult(1, msg.sender, 0, randomValue);
        }

    }

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * constructor() initializer {}
 * ```
 * ====
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../dependencies/open-zeppelin/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IPocoEquiment is IERC165Upgradeable {
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

    function safeMint(address to, uint256 number) external;
    function safeMintEvent(address to, uint256 _itemTypeID, uint256 _itemID, uint256 _additionValue) external;
    function currentTokenIDCounter() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../dependencies/open-zeppelin/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IPocoCharacter is IERC165Upgradeable {
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

    function safeMintbyPocoX(address to, uint256 number) external;
    function safeMintbyBUSD(address to, uint256 number) external;
    function currentTokenIDCounter() external view returns (uint256);
    function safeMintbyEvent(address to, uint256 _skill, uint256 _skin, uint256 _element, uint256 _source) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an StaskingPocoTicket compliant contract.
 */
interface IStaskingPocoTicket {
    function userTicket(address _add) external;
    function useTicket(uint256 _amount, address _add) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../dependencies/open-zeppelin/utils/StringsUpgradeable.sol";

contract PocoRandom is Initializable , OwnableUpgradeable{
    
    constructor() initializer {}

    uint256 randomCounter;
    mapping(address => bool) public whitelistRandom;  

    function initialize() initializer public {
        __Ownable_init();
    }

    modifier onlyWhitelistRandom() {
        require(whitelistRandom[msg.sender], 'Only whitelist');
        _;
    }

    function getRandomSeed() internal view returns (uint256) {
        return uint256(sha256(abi.encodePacked(block.coinbase, randomCounter, blockhash(block.number -1), block.difficulty, block.gaslimit, block.timestamp, gasleft(), msg.sender)));
    }

    function setWhiteList(address _whitelist, bool status) public onlyOwner {
        whitelistRandom[_whitelist] = status;
    }

    // Get random number
    function updateCounter(uint256 addedCounter) public onlyWhitelistRandom{
        unchecked { randomCounter += addedCounter; }
    }

    // Get random number
    function getPocoRandom(uint256 _rate) public view onlyWhitelistRandom returns (uint256) {
        return (getRandomSeed() % _rate)  + 1;
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