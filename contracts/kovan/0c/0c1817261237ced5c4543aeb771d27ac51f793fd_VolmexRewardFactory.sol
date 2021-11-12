// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ITreasuryVester.sol";
import "./interfaces/IVolmexToken.sol";

/**
 * @title Factory Contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexRewardFactory is OwnableUpgradeable {
    // mapping of indexCount with user wallet address to cloned contract address
    mapping(uint256 => mapping(address => address)) private vestingContracts;
    // mapping of user wallet address to array of owned indexes
    mapping(address => uint256[]) private clonedTreasuryIndexes;
    // TreasuryVester contract implementation
    address public treasuryImplementation;
    // volmex ERC20 token
    address public volmexToken;
    // unique index
    uint256 public indexCount;
    // address of new treasury contract
    address newTreasuryContract;
    /* ========== EVENTS ========== */
    event ClonedTreasureVester(
        address receiver,
        address treasuryContract,
        uint256 quantity,
        uint256 index
    );
    /**
     * @notice Get the address of implementation contracts instance.
     * @param _implementation address of factory contract
     * @param _volmexToken address of volmex ERC20 token
     */
    function initialize(address _implementation, address _volmexToken)
        external
        initializer
    {
        __Ownable_init();
        treasuryImplementation = _implementation;
        volmexToken = _volmexToken;
    }
    /**
     * @notice update the TreasuryVester contract address
     * @param _implementation address of factory contract
     */
    function updateImplementationAddress(address _implementation)
        external
        onlyOwner
    {
        treasuryImplementation = _implementation;
    }
    /**
     * @notice get the array of instance of treasure vesting contract
     * @param _user is address of cloned contract holder
     */
    function getVestingContractIndexes(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return clonedTreasuryIndexes[_user];
    }
    /**
     * @notice get the instance of treasure vesting contract
     * @param _user is address of cloned contract holder
     * @param _clonedIndex is index of cloned treasure vesting contract
     */
    function getVestingContract(address _user, uint256 _clonedIndex)
        external
        view
        returns (address)
    {
        return vestingContracts[_clonedIndex][_user];
    }
    /**
     * @notice Get the expected address of treasury vester contract
     * @param _recipient is the address of receiver
     * @param _index is a integer value
     */
    function determineTreasuryVesterAddress(address _recipient, uint256 _index)
        external
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(_recipient, _index));
        return
            Clones.predictDeterministicAddress(
                treasuryImplementation,
                salt,
                address(this)
            );
    }
    /**
     * @notice cloned the treasury vester contract for array of addresses
     * @param _recipients is the array of addresses of receivers
     * @param _quantities is a array of amounts which is claimable by users
     */
    function cloneTreasuryVesterContract(
        address[] calldata _recipients,
        uint256[] calldata _quantities,
        uint256 _vestingBegin,
        uint256 _vestingEnd,
        uint256 _vestingCliff
    ) external onlyOwner {
        require(
            _recipients.length == _quantities.length,
            "VolmexRewardFactory: length of arrays are not equal"
        );
        uint256 _indexCount = indexCount;
        for (uint256 i = 0; i < _recipients.length; i++) {
            _indexCount += 1;
            bytes32 salt = keccak256(
                abi.encodePacked(_recipients[i], _indexCount)
            );
            newTreasuryContract = Clones.cloneDeterministic(
                treasuryImplementation,
                salt
            );
            ITreasuryVester(newTreasuryContract).initialize(
                volmexToken,
                _vestingBegin,
                _vestingEnd,
                _vestingCliff,
                _recipients[i],
                _quantities[i]
            );
            IVolmexToken(volmexToken).transferFrom(
                msg.sender,
                newTreasuryContract,
                _quantities[i]
            );
            vestingContracts[_indexCount][_recipients[i]] = newTreasuryContract;
            clonedTreasuryIndexes[_recipients[i]].push(_indexCount);
            emit ClonedTreasureVester(
                _recipients[i],
                newTreasuryContract,
                _quantities[i],
                _indexCount
            );
        }
        indexCount = _indexCount;
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
library Clones {
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

// SPDX-License-Identifier: BUSL 1.1

pragma solidity 0.8.0;

interface ITreasuryVester {
    function initialize(
        address _volmexToken,
        uint256 _vestingBegin,
        uint256 _vestingEnd,
        uint256 _vestingCliff,
        address _recipient,
        uint256 _vestingAmount
    ) external;

    function claim() external;

    function owner() external view returns (address);

    function volmexToken() external view returns (address);

    function recipient() external view returns (address);

    function vestingBegin() external view returns (uint256);

    function vestingEnd() external view returns (uint256);

    function vestingcliff() external view returns (uint256);

    function lastUpdate() external view returns (uint256);

    function vestingAmount() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL 1.1

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IVolmexToken {
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