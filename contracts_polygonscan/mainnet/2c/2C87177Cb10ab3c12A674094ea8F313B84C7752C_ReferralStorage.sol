//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IMintableToken.sol";
import "./interfaces/ITypedNFT.sol";

contract ReferralStorage is OwnableUpgradeable {

    mapping(address => bool) public programEnabled;

    mapping(address => address) public referrers;

    mapping(address => address) public referredProgram;

    mapping(address => address[]) public invitees;

    // Not used in V2
    mapping(address => bool) public rewardClaimed;

    // Not used in V2
    uint256 public rewardInvitees;

    enum TokenType {
        ERC20,
        ERC721
    }

    struct Reward {
        TokenType tokenType;
        address token;
        uint256 typeId;
        uint256 amount;
    }

    Reward[] public rewards;

    uint256[] public levelInvitees;

    mapping(address => mapping(uint256 => bool)) public levelClaimed;

    // EVENTS

    event Reference(address indexed inviteee, address indexed referrer, address indexed program);

    event RewardClaimed(address indexed claimer, uint256 indexed level);

    // CONSTRUCTOR

    function initialize(Reward[] memory rewards_, uint256[] memory levelInvitees_) external initializer {
        __Ownable_init();

        require(rewards_.length == levelInvitees_.length, "Length mismatch");
        for (uint256 i = 0; i < rewards_.length; i++) {
            rewards.push(rewards_[i]);
        }
        for (uint256 i = 0; i < levelInvitees_.length; i++) {
            levelInvitees.push(levelInvitees_[i]);
        }
    }

    // PUBLIC FUNCTIONS

    function refer(address invitee, address referrer) external {
        require(programEnabled[msg.sender], "This referral program is not enabled");

        if (referrers[invitee] == address(0)) {
            referrers[invitee] = referrer;
            referredProgram[invitee] = msg.sender;
            invitees[referrer].push(invitee);
            emit Reference(invitee, referrer, msg.sender);
        }
    }

    function claimReward(uint256 level) external {
        require(invitees[msg.sender].length >= levelInvitees[level], "Not enough invitees for reward");
        require(!levelClaimed[msg.sender][level], "Already claimed");

        levelClaimed[msg.sender][level] = true;
        if (rewards[level].tokenType == TokenType.ERC20) {
            IMintableToken(rewards[level].token).mint(msg.sender, rewards[level].amount);
        } else {
            ITypedNFT(rewards[level].token).mint(msg.sender, rewards[level].typeId, rewards[level].amount);
        }

        emit RewardClaimed(msg.sender, level);
    }

    // CONFIGURATION

    function setProgram(address program, bool enabled) external onlyOwner {
        programEnabled[program] = enabled;
    }

    function setLevels(Reward[] memory rewards_, uint256[] memory levelInvitees_) external onlyOwner {
        require(rewards_.length == levelInvitees_.length, "Length mismatch");

        for (uint256 i = 0; i < rewards_.length; i++) {
            if (i < rewards.length) {
                rewards[i] = rewards_[i];
                levelInvitees[i] = levelInvitees_[i];
            } else {
                rewards.push(rewards_[i]);
                levelInvitees.push(levelInvitees_[i]);
            }
        }
        while (rewards.length > rewards_.length) {
            rewards.pop();
            levelInvitees.pop();
        }
    }

    // VIEW FUNCTIONS

    function getInviteesCount(address referrer) external view returns (uint256) {
        return invitees[referrer].length;
    }

    function getInvitees(address referrer) external view returns (address[] memory) {
        return invitees[referrer];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMintableToken {
    function mint(address to, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITypedNFT {
    function mint(address _to, uint256 _type, uint256 _amount) external returns (uint256);
    function getTypeInfo(uint256 _typeId) external view returns (
        uint256 nominalPrice,
        uint256 capSupply,
        uint256 maxSupply,
        string memory info,
        address minterOnly,
        string memory uri
    );
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function burn(uint256 tokenId) external;
    function getTokenType(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 * /// @custom:oz-upgrades-unsafe-allow constructor
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