// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./Sync.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

contract SyncFactory is Initializable, OwnableUpgradeable {
    event SyncCreated(address _syncClone, address _dao);

    address public syncUnderlying;
    address payable public bot;
    address public wxDai;
    address payable public plazaDao;
    address payable public daoHausDao;
    uint256 public plazaSplit;
    uint256 public feePercent;

    function initialize(
        address _syncUnderlying,
        address payable _bot,
        address _wxDai,
        address payable _plazaDao,
        address payable _daoHausDao,
        uint256 _plazaSplit,
        uint256 _feePercent
    ) external initializer {
        __Ownable_init();
        syncUnderlying = _syncUnderlying;
        wxDai = _wxDai;
        plazaDao = _plazaDao;
        bot = _bot;
        daoHausDao = _daoHausDao;
        plazaSplit = _plazaSplit;
        feePercent = _feePercent;
        // TODO transfer ownership to plaza dao
    }

    function createSync(address _dao) external returns (address _syncClone) {
        _syncClone = ClonesUpgradeable.clone(syncUnderlying);
        Sync(payable(_syncClone)).initialize(
            bot,
            wxDai,
            _dao,
            msg.sender,
            plazaDao,
            daoHausDao,
            plazaSplit,
            feePercent
        );
        emit SyncCreated(_syncClone, msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./interfaces/IMoloch.sol";
import "./interfaces/IWXDAI.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Sync is Initializable, OwnableUpgradeable {
    event WithdrawFromDAO(uint256 _amount);
    event CollectedFunds(uint256 _balance, uint256 _fee, uint256 _gasFunds, uint256 _plazaFee, uint256 _daoHausFee);
    event Synced();
    event RequestedFunds();
    event DeletedBot(uint256 _sharesToBurn, uint256 _lootToBurn, uint256 _balance);

    address payable public bot;
    address public wxDai;
    address public dao;
    address public minion;
    address public plazaDao;
    address payable public daoHausDao;
    uint256 public plazaSplit;
    uint256 public feePercent;

    uint256 private constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant DIVISOR = 1000;

    struct Member {
        address delegateKey; // the key responsible for submitting proposals and voting - defaults to member address unless updated
        uint256 shares; // the # of voting shares assigned to this member
        uint256 loot; // the loot amount available to this member (combined with shares on ragequit)
        bool exists; // always true once a member has been created
        uint256 highestIndexYesVote; // highest proposal index # on which the member voted YES
        uint256 jailed; // set to proposalIndex of a passing guild kick proposal for this member, prevents voting on and sponsoring proposals
    }

    function initialize(
        address payable _bot,
        address _wxDai,
        address _dao,
        address _minion,
        address payable _plazaDao,
        address payable _daoHausDao,
        uint256 _plazaSplit,
        uint256 _feePercent
    ) external initializer {
        __Ownable_init();
        transferOwnership(_minion);
        bot = _bot;
        wxDai = _wxDai;
        dao = _dao;
        minion = _minion;
        plazaDao = _plazaDao;
        daoHausDao = _daoHausDao;
        plazaSplit = _plazaSplit;
        feePercent = _feePercent;
    }

    receive() external payable {}

    function withdrawFromDAO() public returns (uint256 _amount) {
        _amount = IMoloch(dao).getUserTokenBalance(address(this), wxDai);
        if (_amount > 0) {
            IMoloch(dao).withdrawBalance(wxDai, _amount);
            emit WithdrawFromDAO(_amount);
        }
    }

    function collectFunds() public {
        withdrawFromDAO();
        IWXDAI _token = IWXDAI(wxDai);
        uint256 _balance = _token.balanceOf(address(this));
        if (_balance > 0) {
            // FIXME there could be a issue when _balance*feePercent is < 1000. Total fee will be 0.
            uint256 _fee = (_balance * feePercent) / DIVISOR;
            uint256 _gasFunds = _balance - _fee;
            // FIXME there could be a issue when _fee*plazaSplit is < 1000. Plaza fee will be 0;
            uint256 _plazaFee = (_fee * plazaSplit) / DIVISOR;
            uint256 _daoHausFee = _balance - _plazaFee;
            _token.transfer(plazaDao, _plazaFee);
            _token.transfer(daoHausDao, _daoHausFee);
            _token.withdraw(_gasFunds);
            bot.transfer(_gasFunds); // FIXME bot must be an EOA
            // TODO maybe reduce params emitted
            emit CollectedFunds(_balance, _fee, _gasFunds, _plazaFee, _daoHausFee);
        }
    }

    function collectTokens() external {
        // NOTE this contract must have a share. Not adding a require to save gas.
        IMoloch(dao).collectTokens(wxDai);
        emit Synced();
    }

    function requestFunds() external {
        require(msg.sender == bot, "Sync::!bot");
        IMoloch(dao).submitProposal(
            address(this),
            0,
            0,
            0,
            wxDai,
            10 * (10**IWXDAI(wxDai).decimals()),
            wxDai,
            // solhint-disable quotes
            '{"title": "Plaza Sync Bot: Request for payment","description": "Top-off 10 WXDAI for gas requirements","link": "https://plaza.tech/","proposalType": "Funding Proposal"}'
        );
        emit RequestedFunds();
    }

    function deleteBot() external {
        collectFunds(); // FIXME this will transfer funds to bot, plaza & daoHaus. Do we rather want to send this to the dao?
        IMoloch _moloch = IMoloch(dao);
        (, uint256 _sharesToBurn, uint256 _lootToBurn, , , ) = _moloch.members(address(this));
        require(_sharesToBurn > 0 || _lootToBurn > 0, "Sync::no loot|share");
        _moloch.ragequit(_sharesToBurn, _lootToBurn);
        uint256 _balance = _moloch.getUserTokenBalance(address(this), wxDai);
        if (_balance > 0) {
            IWXDAI(wxDai).transfer(dao, _balance);
        }
        emit DeletedBot(_sharesToBurn, _lootToBurn, _balance);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IMoloch {
    // brief interface for moloch dao v2

    function cancelProposal(uint256 proposalId) external;

    function depositToken() external view returns (address);

    function getProposalFlags(uint256 proposalId) external view returns (bool[6] memory);

    function getTotalLoot() external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    function getUserTokenBalance(address user, address token) external view returns (uint256);

    function members(address user)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        );

    function ragequit(uint256 sharesToBurn, uint256 lootToBurn) external;

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);

    function tokenWhitelist(address token) external view returns (bool);

    function updateDelegateKey(address newDelegateKey) external;

    function userTokenBalances(address user, address token) external view returns (uint256);

    function withdrawBalance(address token, uint256 amount) external;

    function collectTokens(address token) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWXDAI is IERC20Upgradeable {
    function decimals() external returns (uint8);

    function deposit() external payable;

    function withdraw(uint256) external;
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