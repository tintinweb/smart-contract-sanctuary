/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/CloneLib.sol

pragma solidity 0.6.6;
//solhint-disable avoid-low-level-calls
//solhint-disable no-inline-assembly

library CloneLib {
    /**
     * Returns bytecode of a new contract that clones template
     * Adapted from https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-sdk/master/packages/lib/contracts/upgradeability/ProxyFactory.sol
     * Which in turn adapted it from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
     */
    function cloneBytecode(address template) internal pure returns (bytes memory code) {
        bytes20 targetBytes = bytes20(template);
        assembly {
            code := mload(0x40)
            mstore(0x40, add(code, 0x57)) // code length is 0x37 plus 0x20 for bytes length field. update free memory pointer
            mstore(code, 0x37) // store length in first 32 bytes

            // store clone source address after first 32 bytes
            mstore(add(code, 0x20), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(code, 0x34), targetBytes)
            mstore(add(code, 0x48), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
    }

    /**
     * Predict the CREATE2 address.
     * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1014.md for calculation details
     */
    function predictCloneAddressCreate2(
        address template,
        address deployer,
        bytes32 salt
    ) internal pure returns (address proxy) {
        bytes32 codehash = keccak256(cloneBytecode(template));
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            codehash
        )))));
    }

    /**
     * Deploy given bytecode using CREATE2, address can be known in advance, get it from predictCloneAddressCreate2
     * Optional 2-step deployment first runs the constructor, then supplies an initialization function call.
     * @param code EVM bytecode that would be used in a contract deploy transaction (to=null)
     * @param initData if non-zero, send an initialization function call in the same tx with given tx input data (e.g. encoded Solidity function call)
     */
    function deployCodeAndInitUsingCreate2(
        bytes memory code,
        bytes memory initData,
        bytes32 salt
    ) internal returns (address payable proxy) {
        uint256 len = code.length;
        assembly {
            proxy := create2(0, add(code, 0x20), len, salt)
        }
        require(proxy != address(0), "error_alreadyCreated");
        if (initData.length != 0) {
            (bool success, ) = proxy.call(initData);
            require(success, "error_initialization");
        }
    }

    /**
     * Deploy given bytecode using old-style CREATE, address is hash(sender, nonce)
     * Optional 2-step deployment first runs the constructor, then supplies an initialization function call.
     * @param code EVM bytecode that would be used in a contract deploy transaction (to=null)
     * @param initData if non-zero, send an initialization function call in the same tx with given tx input data (e.g. encoded Solidity function call)
     */
    function deployCodeAndInitUsingCreate(
        bytes memory code,
        bytes memory initData
    ) internal returns (address payable proxy) {
        uint256 len = code.length;
        assembly {
            proxy := create(0, add(code, 0x20), len)
        }
        require(proxy != address(0), "error_create");
        if (initData.length != 0) {
            (bool success, ) = proxy.call(initData);
            require(success, "error_initialization");
        }
    }
}

// File: contracts/IAMB.sol

pragma solidity 0.6.6;

// Tokenbridge Arbitrary Message Bridge
interface IAMB {

    //only on mainnet AMB:
    function executeSignatures(bytes calldata _data, bytes calldata _signatures) external;

    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function requiredSignatures() external view returns (uint256);
    function numMessagesSigned(bytes32 _message) external view returns (uint256);
    function signature(bytes32 _hash, uint256 _index) external view returns (bytes memory);
    function message(bytes32 _hash) external view returns (bytes memory);
    function failedMessageDataHash(bytes32 _messageId)
        external
        view
        returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId)
        external
        view
        returns (address);

    function failedMessageSender(bytes32 _messageId)
        external
        view
        returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);
}

// File: contracts/ITokenMediator.sol

pragma solidity 0.6.6;

interface ITokenMediator {
    function bridgeContract() external view returns (address);

    //returns:
    //Multi-token mediator: 0xb1516c26 == bytes4(keccak256(abi.encodePacked("multi-erc-to-erc-amb")))
    //Single-token mediator: 0x76595b56 ==  bytes4(keccak256(abi.encodePacked("erc-to-erc-amb")))
    function getBridgeMode() external pure returns (bytes4 _data);

    function relayTokensAndCall(address token, address _receiver, uint256 _value, bytes calldata _data) external;
}

// File: contracts/FactoryConfig.sol

pragma solidity 0.6.6;

interface FactoryConfig {
    function currentToken() external view returns (address);
    function currentMediator() external view returns (address);
}

// File: contracts/DataUnionFactoryMainnet.sol

pragma solidity 0.6.6;







interface IDataUnionMainnet {
    function sidechainAddress() external view returns (address proxy);
}

contract DataUnionFactoryMainnet {
    event MainnetDUCreated(address indexed mainnet, address indexed sidechain, address indexed owner, address template);

    address public dataUnionMainnetTemplate;

    // needed to calculate address of sidechain contract
    address public dataUnionSidechainTemplate;
    address public dataUnionSidechainFactory;
    uint256 public sidechainMaxGas;
    FactoryConfig public migrationManager;

    constructor(address _migrationManager,
                address _dataUnionMainnetTemplate,
                address _dataUnionSidechainTemplate,
                address _dataUnionSidechainFactory,
                uint256 _sidechainMaxGas)
        public
    {
        migrationManager = FactoryConfig(_migrationManager);
        dataUnionMainnetTemplate = _dataUnionMainnetTemplate;
        dataUnionSidechainTemplate = _dataUnionSidechainTemplate;
        dataUnionSidechainFactory = _dataUnionSidechainFactory;
        sidechainMaxGas = _sidechainMaxGas;
    }

    function amb() public view returns (IAMB) {
        return IAMB(ITokenMediator(migrationManager.currentMediator()).bridgeContract());
    }
 
    function token() public view returns (address) {
        return migrationManager.currentToken();
    }


    function sidechainAddress(address mainetAddress)
        public view
        returns (address)
    {
        return CloneLib.predictCloneAddressCreate2(
            dataUnionSidechainTemplate,
            dataUnionSidechainFactory,
            bytes32(uint256(mainetAddress))
        );
    }
    /*

    */
    function mainnetAddress(address deployer, string memory name)
        public view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encode(bytes(name), deployer));
        return CloneLib.predictCloneAddressCreate2(
            dataUnionMainnetTemplate,
            address(this),
            salt
        );
    }


/*
    function initialize(
        address _token,
        address _tokenMediator,
        address _sidechainDataUnionFactory,
        uint256 _sidechainMaxgas,
        address _sidechainTemplateDataUnion,
        address _owner,
        uint256 adminFeeFraction,
        address[] memory agents
    )  public {
    users can only deploy with salt = their key.
*/
    function deployNewDataUnion(address owner, uint256 adminFeeFraction, address[] memory agents, string memory name)
        public
        returns (address)
    {
        bytes32 salt = keccak256(abi.encode(bytes(name), msg.sender));
        bytes memory data = abi.encodeWithSignature("initialize(address,address,uint256,address,address,uint256,address[])",
            migrationManager,
            dataUnionSidechainFactory,
            sidechainMaxGas,
            dataUnionSidechainTemplate,
            owner,
            adminFeeFraction,
            agents
        );
        address du = CloneLib.deployCodeAndInitUsingCreate2(CloneLib.cloneBytecode(dataUnionMainnetTemplate), data, salt);
        emit MainnetDUCreated(du, sidechainAddress(du), owner, dataUnionMainnetTemplate);
        return du;
    }
}