// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../utilities/AdminUpgradeable.sol";
import "../utilities/AddressCache.sol";
import "./IStaking.sol";
import "../token/IRelationToken.sol";
import "../utilities/SystemConfig.sol";
import "../utilities/Constants.sol";
import "./IDelegate.sol";
import "../indexers/IIndexer.sol";
import "../utilities/TokenUtils.sol";

contract Delegating is AdminUpgradeable, PausableUpgradeable, AddressCache, IDelegate, Constants {
    using SafeMath for uint256;

    //inflationary rnt
    IRelationToken rnt;
    IConfig config;
    IIndexer indexer;

    // indexer => Bank
    mapping(address => Bank) public banks;

    ///Admin can Pause unStake
    modifier notDelegatePaused(address _indexer) {
        require(indexer.isRegistered(_indexer), "!indexer");
        require(banks[_indexer].canDelegate, "can not delegate");
        _;
    }

    ///Admin can Pause unStake
    modifier notUnDelegatePaused(address _indexer) {
        require(indexer.isRegistered(_indexer), "!indexer");
        require(banks[_indexer].canUnDelegate, "can not unDelegate");
        _;
    }

    event Delegated(
        address _indexer,
        uint256 _amount,
        uint256 addShareAmount,
        uint256 selfTotalShareVal,
        uint256 totalShareVal,
        uint256 totalStakeVal
    );

    event UnDelegated(
        address _indexer,
        uint256 withdrawShareAmount,
        uint256 withdrawRNTAmount,
        uint256 selfTotalShareVal,
        uint256 totalShareVal,
        uint256 totalStakeVal
    );

    function initialize(address admin) public initializer {
        AdminUpgradeable.__AdminUpgradeable_init(admin);
    }

    function updateAddressCache(IAddressStorage _addressStorage) public override onlyAdmin {
        config = IConfig(_addressStorage.getAddressWithRequire(CONFIG_KEY, ""));
        rnt = IRelationToken(_addressStorage.getAddressWithRequire(RELATION_TOKEN_KEY, ""));
        indexer = IIndexer(_addressStorage.getAddressWithRequire(INDEXER_KEY, ""));

        emit CachedAddressUpdated(CONFIG_KEY, address(config));
        emit CachedAddressUpdated(RELATION_TOKEN_KEY, address(rnt));
        emit CachedAddressUpdated(INDEXER_KEY, address(indexer));
    }

    function getDelegateShare(address _indexer, address _delegator) external view override returns (uint256) {
        Bank storage bank = banks[_indexer];
        return bank.stakeSharePool[_delegator];
    }

    function getTotalVal(address _indexer) external view override returns (uint256) {
        return banks[_indexer].totalVal;
    }

    function getTotalShareVal(address _indexer) external view override returns (uint256) {
        return banks[_indexer].totalShareVal;
    }

    function delegate(address _indexer, uint256 _amount) external override whenNotPaused notDelegatePaused(_indexer) {
        require(_amount > 0, "stake amount <= 0");

        Bank storage bank = banks[_indexer];
        calInterest(_indexer);

        //record stake infos
        TokenUtils.pullTokens(rnt, msg.sender, _amount);
        bank.totalVal = bank.totalVal.add(_amount);

        //calc share token amount
        uint256 total = bank.totalVal.sub(_amount);
        uint256 totalShareVal = bank.totalShareVal;
        uint256 addShareAmount = (total == 0 || totalShareVal == 0) ? _amount : _amount.mul(totalShareVal).div(total);
        bank.stakeSharePool[msg.sender] = bank.stakeSharePool[msg.sender].add(addShareAmount);
        bank.totalShareVal = bank.totalShareVal.add(addShareAmount);

        emit Delegated(
            _indexer,
            _amount,
            addShareAmount,
            bank.stakeSharePool[msg.sender],
            bank.totalShareVal,
            bank.totalVal
        );
    }

    function unDelegate(address _indexer, uint256 _withdrawShareAmount)
        external
        override
        whenNotPaused
        notUnDelegatePaused(_indexer)
    {
        require(_withdrawShareAmount > 0, "share amount <= 0");
        Bank storage bank = banks[_indexer];
        calInterest(_indexer);

        require(bank.totalShareVal > 0, "totalShareVal <= 0");

        //withdraw amount
        uint256 withdrawRNTAmount = _withdrawShareAmount.mul(bank.totalVal).div(bank.totalShareVal);
        bank.totalVal = bank.totalVal.sub(withdrawRNTAmount);
        TokenUtils.pushTokens(rnt, msg.sender, withdrawRNTAmount);

        //burn share
        bank.totalShareVal = bank.totalShareVal.sub(_withdrawShareAmount);
        bank.stakeSharePool[msg.sender] = bank.stakeSharePool[msg.sender].sub(_withdrawShareAmount);
        emit UnDelegated(
            _indexer,
            _withdrawShareAmount,
            withdrawRNTAmount,
            bank.stakeSharePool[msg.sender],
            bank.totalShareVal,
            bank.totalVal
        );
    }

    function setDelegatePaused(address _indexer, bool paused) external override {
        Bank storage bank = banks[_indexer];
        bank.canDelegate = !paused;
    }

    function setUnDelegatePaused(address _indexer, bool paused) external override {
        Bank storage bank = banks[_indexer];
        bank.canUnDelegate = !paused;
    }

    function calInterest(address _indexer) public {
        Bank storage bank = banks[_indexer];
        if (block.timestamp > bank.lastInterestTime) {
            uint256 timePast = block.timestamp.sub(bank.lastInterestTime);
            uint256 ratePerSec = config.getUint(DELEGATOR_INTEREST_RATE_KEY);
            uint256 interest = ratePerSec.mul(timePast).mul(bank.totalVal).div(1e18);
            // mint interest, increase totalSupply of RNT
            rnt.mint(address(this), interest);
            bank.totalVal = bank.totalVal.add(interest);
            bank.lastInterestTime = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title AdminUpgradeable
 *
 * @dev This is an upgradeable version of `Admin` by replacing the constructor with
 * an initializer and reserving storage slots.
 */
contract AdminUpgradeable is Initializable {
    event CandidateChanged(address oldCandidate, address newCandidate);
    event AdminChanged(address oldAdmin, address newAdmin);

    address public admin;
    address public candidate;

    function __AdminUpgradeable_init(address _admin) public virtual initializer {
        require(_admin != address(0), "AdminUpgradeable: zero address");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    function setCandidate(address _candidate) external onlyAdmin {
        address old = candidate;
        candidate = _candidate;
        emit CandidateChanged(old, candidate);
    }

    function becomeAdmin() external {
        require(msg.sender == candidate, "AdminUpgradeable: only candidate can become admin");
        address old = admin;
        admin = candidate;
        emit AdminChanged(old, admin);
    }

    modifier onlyAdmin {
        require((msg.sender == admin), "AdminUpgradeable: only the contract admin can perform this action");
        _;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces/IAddressStorage.sol";

abstract contract AddressCache {
    function updateAddressCache(IAddressStorage _addressStorage) external virtual;
    event CachedAddressUpdated(string name, address addr);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

interface IStaking {
    /// Stake tokens
    /// @dev stake to msg.sender
    /// @param _tokens token amount
    function stake(uint256 _tokens) external;

    /// Unstake tokens
    /// @param _tokens token amount
    function unStake(uint256 _tokens) external;

    /// Punish Indexer for misbehavior. Rewards will also be given to the dispute raiser.
    /// @param _indexer _indexer address
    /// @param _tokens punish amount
    /// @param _reward reward amount
    /// @param _reward reward amount
    /// @param _reward beneficiary address
    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external;

    /// check if a indexer, stake first and become an indexer
    /// @param _indexer an address
    /// @return if an indexer return true
    function hasStaked(address _indexer) external view returns (bool);

    /**
     * @dev Get the total amount of tokens staked by the indexer.
     * @param _indexer Address of the indexer
     * @return Amount of tokens staked by the indexer
     */
    function getIndexerStakedTokens(address _indexer) external view returns (uint256);

    /// forbid stake
    /// @param paused set paused true or false
    function setStakePaused(bool paused) external;

    /// forbid unStake
    /// @param paused set paused true or false
    function setUnStakePaused(bool paused) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



/**
 * @title RNT TOKEN contract
 * @dev This is the implementation of the ERC20 RNT Token.
 * The implementation exposes a Permit() function to allow for a spender to send a signed message
 * and approve funds to a spender following EIP2612 to make integration with other contracts easier.
 *
 * The token is initially owned by the deployer address that can mint tokens to create the initial
 * distribution. For convenience, an initial supply can be passed in the constructor that will be
 * assigned to the deployer.
 *
 * The admin can add the RewardsManager contract to mint indexing rewards.
 *
 */
interface IRelationToken is IERC20 {
    // -- Mint and Burn --

    function burn(uint256 amount) external;

    function mint(address _to, uint256 _amount) external;

    // -- Mint Admin --

    function addMinter(address _account) external;

    function removeMinter(address _account) external;

    function renounceMinter() external;

    function isMinter(address _account) external view returns (bool);

    // -- Permit --

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IConfig.sol";
import "./Constants.sol";

contract SystemConfig is OwnableUpgradeable, IConfig, Constants {
    mapping(string => uint256) internal mUintConfig;
    event SetUintConfig(string key, uint256 value);

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    function getUint(string calldata key) external view override returns (uint256) {
        return mUintConfig[key];
    }

    function setUint(string calldata key, uint256 value) external override onlyOwner {
        mUintConfig[key] = value;
        emit SetUintConfig(key, value);
    }

    function deleteUint(string calldata key) external onlyOwner {
        delete mUintConfig[key];
        emit SetUintConfig(key, 0);
    }

    function batchSet(string[] calldata names, uint256[] calldata values) external onlyOwner {
        require(names.length == values.length, "Input lengths must match");

        for (uint256 i = 0; i < names.length; i++) {
            mUintConfig[names[i]] = values[i];
            emit SetUintConfig(names[i], values[i]);
        }
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Constants {
    //Address Cache
    string public constant CONFIG_KEY = "CONFIG_KEY";
    string public constant RELATION_TOKEN_KEY = "RELATION_TOKEN_KEY";
    string public constant STAKING_KEY = "STAKING_KEY";
    string public constant DELEGATING_KEY = "DELEGATING_KEY";
    string public constant INDEXER_KEY = "INDEXER_KEY";
    string public constant ACCESS_CONTROL_KEY = "ACCESS_CONTROL";

    //Config Unit
    string public constant INDEXER_INTEREST_RATE_KEY = "INDEXER_INTEREST_RATE_KEY";
    string public constant DELEGATOR_INTEREST_RATE_KEY = "DELEGATOR_INTEREST_RATE_KEY";
    string public constant SLASHING_PERCENTAGE_KEY = "SLASHING_PERCENTAGE_KEY";
    string public constant FISHERMAN_REWARD_PERCENTAGE_KEY = "FISHERMAN_REWARD_PERCENTAGE_KEY";
    string public constant MINIMUM_FISHMEN_DEPOSIT_KEY = "MINIMUM_FISHMEN_DEPOSIT_KEY";

    constructor() public {}
}

// SPDX-License-Identifier: GPL-2.0-or-later


pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IDelegate {


    struct Bank {
        // Pool : delegator => StakeShareAmount
        mapping(address => uint256) stakeSharePool;
        bool canDelegate;
        bool canUnDelegate;
        // Total tokens (staked by the delegator)
        uint256 totalVal;
        // Total shares
        uint256 totalShareVal;
        uint256 lastInterestTime;
    }


    /**
     * @dev Delegate tokens to an indexer.
     * @param _indexer Address of the indexer to delegate tokens to
     * @param _tokens Amount of tokens to delegate
     */
    function delegate(address _indexer, uint256 _tokens) external;

    /**
     * @dev Undelegate tokens from an indexer.
     * @param _indexer Address of the indexer where tokens had been delegated
     * @param _shares Amount of shares to return and undelegate tokens
     */
    function unDelegate(address _indexer, uint256 _shares) external;

    /// forbid delegate
    /// @param _indexer Address of the indexer where tokens had been delegated
    /// @param paused set paused true or false
    function setDelegatePaused(address _indexer, bool paused) external;

    /// forbid unDelegate
    /// @param _indexer Address of the indexer where tokens had been delegated
    /// @param paused set paused true or false
    function setUnDelegatePaused(address _indexer, bool paused) external;


    /// get delegate share
    /// @param _indexer Address of the indexer
    /// @param _delegator Address of the delegator
    /// @return share of delegator
    function getDelegateShare(address _indexer, address _delegator) external view returns (uint256);


    function getTotalVal(address _indexer) external view returns (uint256);

    function getTotalShareVal(address _indexer) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.6.12;

interface IIndexer {
    struct IndexerService {
        string url;
        string geo;
        uint256 price;
        uint256 feeSplitRatio;
    }

    /**
     * @dev Register an indexer service, you should register first and stake later
     * @param _url URL of the indexer service
     * @param _geo geo of the indexer service location
     * @param _price fee price
     */
    function register(
        string calldata _url,
        string calldata _geo,
        uint256 _price,
        uint256 _feeSplitRatio
    ) external;

    /**
     * @dev Unregister an indexer service
     */
    function unregister() external;

    /**
     * @dev Return the registration status of an indexer service
     * @return True if the indexer service is registered
     */
    function isRegistered(address _indexer) external view returns (bool);

    /**
     * @dev get fee price, how much per seconds
     * @param _indexer Address of the indexer
     * @return fee price
     */
    function getFeePrice(address _indexer) external returns (uint256);

    /**
     * @dev get fee split ratio of Indexer
     * @param _indexer Address of the indexer
     * @return fee split ratio
     */
    function getFeeSplitRatio(address _indexer) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.6.12;

import "../token/IRelationToken.sol";

library TokenUtils {
    /**
     * @dev Pull tokens from an address to this contract.
     * @param _relationToken Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        IRelationToken _relationToken,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_relationToken.transferFrom(_from, address(this), _amount), "!transfer");
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _relationToken Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        IRelationToken _relationToken,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_relationToken.transfer(_to, _amount), "!transfer");
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _relationToken Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burnTokens(IRelationToken _relationToken, uint256 _amount) internal {
        if (_amount > 0) {
            _relationToken.burn(_amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IAddressStorage {
    function updateAll(string[] calldata names, address[] calldata destinations) external;

    function update(string calldata name, address dest) external;

    function getAddress(string calldata name) external view returns (address);

    function getAddressWithRequire(string calldata name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IConfig {
    function getUint(string calldata key) external view returns (uint256);

    function setUint(string calldata key, uint256 value) external;
}