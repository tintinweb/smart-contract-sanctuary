// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../interfaces/IPocoEquiment.sol";

contract StakingPocoTicket is Initializable , OwnableUpgradeable{
    
    constructor() initializer {}

    uint256 public stakePeriod;
    uint256 public ticketSize;
    address public STAKE_TOKEN;
    uint256 public totalClaimedTicket;
    uint256 public totalUsedTicket;

    struct StakingInfo {
        uint256 amount;
        uint256 stakingAt;
        uint256 remainingTicket;
    } 

    mapping(address => bool) public whiteListPool;
    mapping(address => uint256) public userTicket;
    mapping(address => StakingInfo) public userStake;
    uint256 public emissionRate;
    address public TREASURY_ADDRESS;
    address public REWARD_TOKEN;

    function initialize() initializer public {
        __Ownable_init();
    }

    modifier onlyNonContract {
        require(tx.origin == msg.sender, "Only non-contract call");
        _;
    }

    // Update config
    function updateConfig(uint256 _stakePeriod, address _stakeToken, uint256 _ticketSize, uint256 _emissionRate, address _TREASURY_ADDRESS, address _REWARD_TOKEN) public onlyOwner{
        stakePeriod = _stakePeriod;
        STAKE_TOKEN = _stakeToken; 
        ticketSize = _ticketSize;
        emissionRate = _emissionRate;
        TREASURY_ADDRESS = _TREASURY_ADDRESS;
        REWARD_TOKEN = _REWARD_TOKEN;
    }

    // Update pool which using ticket
    function updateWhitelistPool(address _pool, bool _status) public onlyOwner{
        whiteListPool[_pool] = _status;
    }

    // Fix wrong ticket
    function updateAddressTicket(address[] memory _address, uint256[] memory _number) public onlyOwner{
        for (uint256 i = 0; i < _address.length; i++) {
            userTicket[_address[i]] += _number[i];
        }
        
    }

    function getReward(
        address _address
    ) public view returns (uint256) {
        uint256 yearReward = userStake[_address].amount * emissionRate / 100;
        uint256 amountReward =  yearReward * (block.timestamp - userStake[_address].stakingAt) / 31536000;
        return (amountReward);
    }

    function useTicket(uint256 _amount, address _add) public {
        require(_amount > 0, "Invalid amount");
        require(whiteListPool[msg.sender], "Invalid pool");
        require(_amount <= userTicket[_add], "Not enouhg ticket.");
        userTicket[_add] -= _amount;
        totalUsedTicket += _amount;
    }

    // Get claimable ticket
    function claimableTicket(address _add) public view returns (uint256) {
        uint256 stakeDay = (block.timestamp - userStake[_add].stakingAt) * 1e6 / stakePeriod;
        return ((userStake[_add].amount * 1e4 / ticketSize) * stakeDay) + userStake[_add].remainingTicket;
    }

    // Claim ticket
    function claimTicket(address _add) public {
        // Return reward if user is staking
        if (userStake[_add].amount > 0) {
            uint256 reward = getReward(_add);
            if (reward > 0) {
                IERC20Upgradeable(REWARD_TOKEN).transferFrom(TREASURY_ADDRESS,_add, reward);
            }
        }
        uint256 ticket = claimableTicket(_add) / 1e10;
        userStake[_add].remainingTicket = claimableTicket(_add) - ticket * 1e10;
        userStake[_add].stakingAt = block.timestamp;
        userTicket[_add] += ticket;
        totalClaimedTicket += ticket;
        
    }

    function staking(uint256 _amount) public {
        // Return reward if user is staking
        if (userStake[msg.sender].amount > 0) {
            uint256 reward = getReward(msg.sender);
            if (reward > 0) {
                IERC20Upgradeable(REWARD_TOKEN).transferFrom(TREASURY_ADDRESS ,msg.sender, reward);
            }
        }
        // Claim ticket if have
        uint256 ticket = claimableTicket(msg.sender) / 1e10;
        userTicket[msg.sender] += ticket;
        userStake[msg.sender].remainingTicket = claimableTicket(msg.sender) - ticket * 1e10;
        userStake[msg.sender].stakingAt = block.timestamp;
        userStake[msg.sender].amount += _amount;
        IERC20Upgradeable(STAKE_TOKEN).transferFrom(msg.sender, address(this), _amount);
        totalClaimedTicket += ticket;

    }

    function unstaking(uint256 _amount) public {
        require(_amount <= userStake[msg.sender].amount, "Invalid amount.");
        // Return reward if user is staking
        if (userStake[msg.sender].amount > 0) {
            uint256 reward = getReward(msg.sender);
            if (reward > 0) {
                IERC20Upgradeable(REWARD_TOKEN).transferFrom(TREASURY_ADDRESS ,msg.sender, reward);
            }
        }
        // Claim ticket if have
        uint256 ticket = claimableTicket(msg.sender) / 1e10;
        userTicket[msg.sender] += ticket;
        userStake[msg.sender].remainingTicket = claimableTicket(msg.sender) - ticket * 1e10;
        userStake[msg.sender].stakingAt = block.timestamp;
        totalClaimedTicket += ticket;
        if (_amount > 0) {
            userStake[msg.sender].amount -= _amount;
            IERC20Upgradeable(STAKE_TOKEN).transfer(msg.sender, _amount);
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