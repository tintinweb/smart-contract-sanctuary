pragma solidity =0.6.10;

import {OtokenSpawner} from "./OtokenSpawner.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {OtokenInterface} from "../interfaces/OtokenInterface.sol";
import {WhitelistInterface} from "../interfaces/WhitelistInterface.sol";

/**
 * SPDX-License-Identifier: UNLICENSED
 * @title A factory to create Opyn oTokens
 * @author Opyn Team
 * @notice Create new oTokens and keep track of all created tokens
 * @dev Calculate contract address before each creation with CREATE2
 * and deploy eip-1167 minimal proxies for oToken logic contract
 */
contract OtokenFactory is OtokenSpawner {
    using SafeMath for uint256;
    /// @notice Opyn AddressBook contract that records the address of the Whitelist module and the Otoken impl address. */
    address public addressBook;

    /// @notice array of all created otokens */
    address[] public otokens;

    /// @dev mapping from parameters hash to its deployed address
    mapping(bytes32 => address) private idToAddress;

    /// @dev max expiry that BokkyPooBahsDateTimeLibrary can handle. (2345/12/31)
    uint256 private constant MAX_EXPIRY = 11865398400;

    constructor(address _addressBook) public {
        addressBook = _addressBook;
    }

    /// @notice emitted when the factory creates a new Option
    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );

    /**
     * @notice create new oTokens
     * @dev deploy an eip-1167 minimal proxy with CREATE2 and register it to the whitelist module
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return newOtoken address of the newly created option
     */
    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address) {
        require(_expiry > now, "OtokenFactory: Can't create expired option");
        require(_expiry < MAX_EXPIRY, "OtokenFactory: Can't create option with expiry > 2345/12/31");
        // 8 hours = 3600 * 8 = 28800 seconds
        require(_expiry.sub(28800).mod(86400) == 0, "OtokenFactory: Option has to expire 08:00 UTC");
        bytes32 id = _getOptionId(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        require(idToAddress[id] == address(0), "OtokenFactory: Option already created");

        address whitelist = AddressBookInterface(addressBook).getWhitelist();
        require(
            WhitelistInterface(whitelist).isWhitelistedProduct(
                _underlyingAsset,
                _strikeAsset,
                _collateralAsset,
                _isPut
            ),
            "OtokenFactory: Unsupported Product"
        );

        require(!_isPut || _strikePrice > 0, "OtokenFactory: Can't create a $0 strike put option");

        address otokenImpl = AddressBookInterface(addressBook).getOtokenImpl();

        bytes memory initializationCalldata = abi.encodeWithSelector(
            OtokenInterface(otokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );

        address newOtoken = _spawn(otokenImpl, initializationCalldata);

        idToAddress[id] = newOtoken;
        otokens.push(newOtoken);
        WhitelistInterface(whitelist).whitelistOtoken(newOtoken);

        emit OtokenCreated(
            newOtoken,
            msg.sender,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );

        return newOtoken;
    }

    /**
     * @notice get the total oTokens created by the factory
     * @return length of the oTokens array
     */
    function getOtokensLength() external view returns (uint256) {
        return otokens.length;
    }

    /**
     * @notice get the oToken address for an already created oToken, if no oToken has been created with these parameters, it will return address(0)
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return the address of target otoken.
     */
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        bytes32 id = _getOptionId(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        return idToAddress[id];
    }

    /**
     * @notice get the address at which a new oToken with these parameters would be deployed
     * @dev return the exact address that will be deployed at with _computeAddress
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return targetAddress the address this oToken would be deployed at
     */
    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        address otokenImpl = AddressBookInterface(addressBook).getOtokenImpl();

        bytes memory initializationCalldata = abi.encodeWithSelector(
            OtokenInterface(otokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );
        return _computeAddress(otokenImpl, initializationCalldata);
    }

    /**
     * @dev hash oToken parameters and return a unique option id
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return id the unique id of an oToken
     */
    function _getOptionId(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut)
            );
    }
}

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity =0.6.10;

import {Spawn} from "../packages/Spawn.sol";
import {Create2} from "../packages/oz/Create2.sol";

/**
 * @title OtokenSpawner
 * @author Opyn Team
 * @notice This contract spawns and initializes eip-1167 minimal proxies that
 * point to existing logic contracts.
 * @notice This contract was modified from Spawner.sol
 * https://github.com/0age/Spawner/blob/master/contracts/Spawner.sol to fit into OtokenFactory
 */
contract OtokenSpawner {
    // fixed salt value because we will only deploy an oToken with the same init value once
    bytes32 private constant SALT = bytes32(0);

    /**
     * @notice internal function for spawning an eip-1167 minimal proxy using `CREATE2`
     * @param logicContract address of the logic contract
     * @param initializationCalldata calldata that will be supplied to the `DELEGATECALL`
     * from the spawned contract to the logic contract during contract creation
     * @return spawnedContract the address of the newly-spawned contract
     */
    function _spawn(address logicContract, bytes memory initializationCalldata) internal returns (address) {
        // place the creation code and constructor args of the contract to spawn in memory
        bytes memory initCode = abi.encodePacked(
            type(Spawn).creationCode,
            abi.encode(logicContract, initializationCalldata)
        );

        // spawn the contract using `CREATE2`
        return Create2.deploy(0, SALT, initCode);
    }

    /**
     * @notice internal view function for finding the address of the standard
     * eip-1167 minimal proxy created using `CREATE2` with a given logic contract
     * and initialization calldata payload
     * @param logicContract address of the logic contract
     * @param initializationCalldata calldata that will be supplied to the `DELEGATECALL`
     * from the spawned contract to the logic contract during contract creation
     * @return target address of the next spawned minimal proxy contract with the
     * given parameters.
     */
    function _computeAddress(address logicContract, bytes memory initializationCalldata)
        internal
        view
        returns (address target)
    {
        // place the creation code and constructor args of the contract to spawn in memory
        bytes memory initCode = abi.encodePacked(
            type(Spawn).creationCode,
            abi.encode(logicContract, initializationCalldata)
        );
        // get target address using the constructed initialization code
        bytes32 initCodeHash = keccak256(initCode);

        target = Create2.computeAddress(SALT, initCodeHash);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface AddressBookInterface {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setOtokenImpl(address _otokenImpl) external;

    function setOtokenFactory(address _factory) external;

    function setOracleImpl(address _otokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setLiquidationManager(address _liquidationManager) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OtokenInterface {
    function addressBook() external view returns (address);

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface WhitelistInterface {
    /* View functions */

    function addressBook() external view returns (address);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool);

    function isWhitelistedCollateral(address _collateral) external view returns (bool);

    function isWhitelistedOtoken(address _otoken) external view returns (bool);

    function isWhitelistedCallee(address _callee) external view returns (bool);

    /* Admin / factory only functions */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function whitelistCollateral(address _collateral) external;

    function blacklistCollateral(address _collateral) external;

    function whitelistOtoken(address _otoken) external;

    function blacklistOtoken(address _otoken) external;

    function whitelistCallee(address _callee) external;

    function blacklistCallee(address _callee) external;
}

/* solhint-disable avoid-low-level-calls, indent, no-inline-assembly */
/* This contract is copied from Spawner package: https://github.com/0age/Spawner */
pragma solidity =0.6.10;

/**
 * @title Spawn
 * @author 0age
 * @notice This contract provides creation code that is used by Spawner in order
 * to initialize and deploy eip-1167 minimal proxies for a given logic contract.
 * SPDX-License-Identifier: MIT
 */
// version: https://github.com/0age/Spawner/blob/1b342afda0c1ec47e6a2d65828a6ca50f0a442fe/contracts/Spawner.sol
contract Spawn {
    constructor(address logicContract, bytes memory initializationCalldata) public payable {
        // delegatecall into the logic contract to perform initialization.
        (bool ok, ) = logicContract.delegatecall(initializationCalldata);
        if (!ok) {
            // pass along failure message from delegatecall and revert.
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // place eip-1167 runtime code in memory.
        bytes memory runtimeCode = abi.encodePacked(
            bytes10(0x363d3d373d3d3d363d73),
            logicContract,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );

        // return eip-1167 code to write it to spawned contract runtime.
        assembly {
            return(add(0x20, runtimeCode), 45) // eip-1167 runtime code, length
        }
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0
/* solhint-disable */

pragma solidity =0.6.10;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint256(_data));
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

/* solhint-disable */
pragma solidity ^0.6.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}