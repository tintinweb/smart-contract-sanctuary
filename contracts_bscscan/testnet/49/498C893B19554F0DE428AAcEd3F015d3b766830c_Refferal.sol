// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Refferal is PausableUpgradeable, OwnableUpgradeable {
    uint public newUserBonusAmount;
    uint public minClaimReferBonusAmount;
    IERC20 public erc20Bonus;
    address public signer;
    address[] public users;
    struct TopRefer {
        address user;
        uint n;
    }

    mapping(address => bool) public isReferrer;
    mapping(address => uint) public referBonusAmount;
    mapping(address => address[]) public referreds;
    mapping(uint => TopRefer) public topRefers;

    struct Reward {
        address user;
        uint amount;
    }
    mapping(string => Reward) public claimRewards; // claimReward ID => info

    event ClaimReferBonusAmount(address _clamer, uint _amount);
    event ClaimReward(address _clamer, uint _amount, string claimId);
    function initialize(address _signer, uint _newUserBonusAmount, IERC20 _erc20Bonus, uint _minClaimReferBonusAmount) external initializer {
        signer = _signer;
        newUserBonusAmount = _newUserBonusAmount;
        erc20Bonus = _erc20Bonus;
        minClaimReferBonusAmount = _minClaimReferBonusAmount;
        __Ownable_init();
    }

    function getMessageHashForClaimReward(address _user, uint _amount, string memory _claimId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _amount, _claimId));
    }

    function getMessageHash(address _user, address _refferrer, uint _top) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _refferrer, _top));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function permitForClaimReward(address _user, uint _amount, string memory _claimId, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        return ecrecover(getEthSignedMessageHash(getMessageHashForClaimReward(_user, _amount, _claimId)), v, r, s) == signer;
    }
    function permit(address _user, address _refferrer, uint _top, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        return ecrecover(getEthSignedMessageHash(getMessageHash(_user, _refferrer, _top)), v, r, s) == signer;
    }
    function getUsers() external view returns(address[] memory) {
        return users;
    }
    function claimReferBonusAmount() public {
        require(referBonusAmount[_msgSender()] >= minClaimReferBonusAmount, "Refferal: Not meet condition yet");
        erc20Bonus.transfer(_msgSender(), referBonusAmount[_msgSender()]);
        emit ClaimReferBonusAmount(_msgSender(), referBonusAmount[_msgSender()]);
        referBonusAmount[_msgSender()] = 0;
    }

    function claimReward(uint _amount, string memory _claimId, uint8 v, bytes32 r, bytes32 s) public {
        require(permitForClaimReward(_msgSender(), _amount, _claimId, v, r, s), "Refferal: Invalid signature");
        require(claimRewards[_claimId].user == address(0), "Refferal: claimed");
        erc20Bonus.transfer(_msgSender(), _amount);
        claimRewards[_claimId] = Reward(_msgSender(), _amount);
        emit ClaimReward(_msgSender(), _amount, _claimId);
    }
    function claimRewardAndReferBonus(uint _amount, string memory _claimId, uint8 v, bytes32 r, bytes32 s) external {
        claimReferBonusAmount();
        claimReward(_amount, _claimId, v, r, s);
    }
    function register(address _refferrer, uint _top, uint8 v, bytes32 r, bytes32 s) external {
        require(permit(_msgSender(), _refferrer, _top, v, r, s), "Refferal: Invalid signature");
        if(_refferrer != address(0)) {
            require(isReferrer[_refferrer], "Refferal: Invalid Refferrer");
            referBonusAmount[_refferrer] += newUserBonusAmount;
            referreds[_refferrer].push(_msgSender());
            if(_top != 0 && _top <= 3) topRefers[_top] = TopRefer(_refferrer, _top);
        }
        users.push(_msgSender());
        isReferrer[_msgSender()] = true;
        erc20Bonus.transfer(_msgSender(), newUserBonusAmount);
    }
    function setminClaimReferBonusAmount(uint _minClaimReferBonusAmount) external onlyOwner {
        minClaimReferBonusAmount = _minClaimReferBonusAmount;
    }
    function setErc20Bonus(IERC20 _erc20Bonus) external onlyOwner {
        erc20Bonus = _erc20Bonus;
    }
    function setNewUserBonusAmount(uint _newUserBonusAmount) external onlyOwner {
        newUserBonusAmount = _newUserBonusAmount;
    }
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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