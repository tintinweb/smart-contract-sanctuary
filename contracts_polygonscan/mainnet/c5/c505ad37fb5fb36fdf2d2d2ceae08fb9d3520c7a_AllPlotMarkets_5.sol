/**
 *Submitted for verification at polygonscan.com on 2021-09-30
*/

// File: contracts/external/openzeppelin-solidity/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeMath128 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
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
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint128 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;

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
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint128 c = a * b;
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
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint128 c = a / b;
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
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeMath64 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
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
    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint64 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint64 a, uint64 b, string memory errorMessage) internal pure returns (uint64) {
        require(b <= a, errorMessage);
        uint64 c = a - b;

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
    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint64 c = a * b;
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
    function div(uint64 a, uint64 b) internal pure returns (uint64) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint64 c = a / b;
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
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeMath32 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
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
    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint32 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        uint32 c = a - b;

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
    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
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
    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint32 c = a / b;
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
    function mod(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/external/proxy/Proxy.sol

pragma solidity 0.5.7;


/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () external payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
            }
    }

    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function implementation() public view returns (address);
}

// File: contracts/external/proxy/UpgradeabilityProxy.sol

pragma solidity 0.5.7;



/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param implementation representing the address of the upgraded implementation
    */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant IMPLEMENTATION_POSITION = keccak256("org.govblocks.proxy.implementation");

    /**
    * @dev Constructor function
    */
    constructor() public {}

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address impl) {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            impl := sload(position)
        }
    }

    /**
    * @dev Sets the address of the current implementation
    * @param _newImplementation address representing the new implementation to be set
    */
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
        sstore(position, _newImplementation)
        }
    }

    /**
    * @dev Upgrades the implementation address
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}

// File: contracts/external/proxy/OwnedUpgradeabilityProxy.sol

pragma solidity 0.5.7;



/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    // Storage position of the owner of the contract
    bytes32 private constant PROXY_OWNER_POSITION = keccak256("org.govblocks.proxy.owner");

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor(address _implementation) public {
        _setUpgradeabilityOwner(msg.sender);
        _upgradeTo(_implementation);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
    }

    /**
    * @dev Allows the proxy owner to upgrade the current version of the proxy.
    * @param _implementation representing the address of the new implementation to be set.
    */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}

// File: contracts/external/EIP712/Initializable.sol

pragma solidity 0.5.7;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// File: contracts/external/EIP712/EIP712Base.sol

pragma solidity 0.5.7;


contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := 137
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// File: contracts/external/NativeMetaTransaction.sol

pragma solidity 0.5.7;



contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }

    function _msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/interfaces/IToken.sol

pragma solidity 0.5.7;

contract IToken {

    function decimals() external view returns(uint8);

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external view returns (uint256);

    /**
    * @dev Gets the balance of the specified address.
    * @param account The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address account) external view returns (uint256);

    /**
    * @dev Transfer token for a specified address
    * @param recipient The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
    * @dev function that mints an amount of the token and assigns it to
    * an account.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function mint(address account, uint256 amount) external returns (bool);
    
     /**
    * @dev burns an amount of the tokens of the message sender
    * account.
    * @param amount The amount that will be burnt.
    */
    function burn(uint256 amount) external;

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
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
    * @dev Transfer tokens from one address to another
    * @param sender address The address which you want to send tokens from
    * @param recipient address The address which you want to transfer to
    * @param amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function lockForGovernanceVote(address _of, uint256 _period) public;

    function isLockedForGV(address _of) public view returns (bool);

    function changeOperator(address _newOperator) public returns (bool);
}

// File: contracts/interfaces/IbPLOTToken.sol

pragma solidity 0.5.7;

contract IbPLOTToken {
    function convertToPLOT(address _of, address _to, uint256 amount) public;
    function transfer(address recipient, uint256 amount) public returns (bool);
    function renounceMinter() public;
}

// File: contracts/interfaces/IAuth.sol

/* Copyright (C) 2021 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;

contract IAuth {

    address public authorized;

    /// @dev modifier that allows only the authorized addresses to execute the function
    modifier onlyAuthorized() {
        require(authorized == msg.sender, "Not authorized");
        _;
    }

    /// @dev checks if an address is authorized to govern
    function isAuthorized(address _toCheck) public view returns(bool) {
        return (authorized == _toCheck);
    }

    function changeAuthorizedAddress(address _newAuth) external onlyAuthorized {
        authorized = _newAuth;
    }

}

// File: contracts/interfaces/IOracle.sol

/* Copyright (C) 2020 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;

contract IOracle {
  
  function getSettlementPrice(uint256 _marketSettleTime, uint80 _roundId) external view returns(uint256 _value, uint256 _roundIdUsed);

  function getLatestPrice() external view returns(uint256 _value);
}

// File: contracts/interfaces/IMarket.sol

pragma solidity 0.5.7;

contract IMarket {
  function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64);
  function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value);
  function handleFee(uint _marketId, uint64 _cummulativeFee, address _msgSenderAddress, address _relayer) external;
  function calculatePredictionPointsAndMultiplier(address _user, uint256 _marketId, uint256 _prediction, uint64 _stake) external returns(uint64 predictionPoints);
  function setRewardPoolShareForCreator(uint _marketId, uint _amount) external;
}

// File: contracts/AllPlotMarkets.sol

/* Copyright (C) 2020 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;









contract IMaster {
    function dAppToken() public view returns(address);
    function getLatestAddress(bytes2 _module) public view returns(address);
}

contract AllPlotMarkets is IAuth, NativeMetaTransaction {
    using SafeMath32 for uint32;
    using SafeMath64 for uint64;
    using SafeMath128 for uint128;
    using SafeMath for uint;

    enum PredictionStatus {
      Live,
      InSettlement,
      Cooling,
      InDispute,
      Settled
    }

    event Deposited(address indexed user, uint256 amount, uint256 timeStamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timeStamp);
    event MarketQuestion(uint256 indexed marketIndex, uint256 startTime, uint256 predictionTime, uint256 coolDownTime, uint256 setlementTime, uint64[] optionRanges, address marketCreatorContract);
    event MarketResult(uint256 indexed marketIndex, uint256 totalReward, uint256 winningOption, uint256 closeValue);
    event MarketSettled(uint256 indexed marketIndex);
    // event MarketResult(uint256 indexed marketIndex, uint256 totalReward, uint256 winningOption, uint256 closeValue, uint256 roundId, uint256 daoFee, uint256 marketCreatorFee);
    event ReturnClaimed(address indexed user, uint256 amount);
    event PlacePrediction(address indexed user,uint256 value, uint256 predictionPoints, address predictionAsset,uint256 prediction,uint256 indexed marketIndex);

    struct PredictionData {
      uint64 predictionPoints;
      uint64 amountStaked;
    }
    
    struct UserMarketData {
      bool predictedWithBlot;
      mapping(uint => PredictionData) predictionData;
    }

    struct UserData {
      uint128 totalStaked;
      uint128 lastClaimedIndex;
      uint[] marketsParticipated;
      uint unusedBalance;
      mapping(uint => UserMarketData) userMarketData;
    }

    struct MarketBasicData {
      uint32 startTime;
      uint32 predictionTime;
      uint32 settlementTime;
      uint32 cooldownTime;
    }

    struct MarketDataExtended {
      uint64[] optionRanges;
      uint32 WinningOption;
      uint32 settleTime;
      address marketCreatorContract;
      uint incentiveToDistribute;
      uint rewardToDistribute;
      uint totalStaked;
      PredictionStatus predictionStatus;
    }

    // mapping(address => uint256) public conversionRate;
    
    address internal masterAddress;
    address internal plotToken;
    address internal disputeResolution;

    address internal predictionToken;

    IbPLOTToken internal bPLOTInstance;

    uint internal predictionDecimalMultiplier;
    uint internal defaultMaxRecords;
    bool public marketCreationPaused;

    MarketBasicData[] internal marketBasicData;

    mapping(address => bool) public authorizedMarketCreator;
    mapping(uint256 => MarketDataExtended) internal marketDataExtended;
    mapping(address => UserData) internal userData;

    mapping(uint =>mapping(uint=>PredictionData)) internal marketOptionsAvailable;

    mapping(uint => bool) internal marketSettleEventEmitted;

    /**
     * @dev Changes the master address and update it's instance
     * @param _authorizedMultiSig Authorized address to execute critical functions in the protocol.
     * @param _defaultAuthorizedAddress Authorized address to trigger initial functions by passing required external values.
     */
    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner());
      IMaster ms = IMaster(msg.sender);
      masterAddress = msg.sender;
      address _plotToken = ms.dAppToken();
      plotToken = _plotToken;
      predictionToken = _plotToken;
      authorized = _authorizedMultiSig;
      marketBasicData.push(MarketBasicData(0,0,0,0));
      _initializeEIP712("AM");
      predictionDecimalMultiplier = 10;
      defaultMaxRecords = 20;
    }

    /**
    * @dev Function to initialize the dependancies
    */
    function initializeDependencies() external {
      IMaster ms = IMaster(masterAddress);
      disputeResolution = ms.getLatestAddress("DR");
      bPLOTInstance = IbPLOTToken(ms.getLatestAddress("BL"));
    }

    /**
    * @dev Whitelist an address to create market.
    * @param _authorized Address to whitelist.
    */
    function addAuthorizedMarketCreator(address _authorized) external onlyAuthorized {
      require(_authorized != address(0));
      authorizedMarketCreator[_authorized] = true;
    }

    /**
    * @dev de-whitelist an address to create market.
    * @param _authorized Address to whitelist.
    */
    function removeAuthorizedMarketCreator(address _authorized) external onlyAuthorized {
      authorizedMarketCreator[_authorized] = false;
    }

    /**
    * @dev Create the market.
    * @param _marketTimes Array of params as mentioned below
    * _marketTimes => [0] _startTime, [1] _predictionTIme, [2] _settlementTime, [3] _cooldownTime
    * @param _optionRanges Array of params as mentioned below
    * _optionRanges => For 3 options, the array will be with two values [a,b], First option will be the value less than zeroth index of this array, the next option will be the value less than first index of the array and the last option will be the value greater than the first index of array
    * @param _marketCreator Address of the user who initiated the market creation
    * @param _initialLiquidity Amount of tokens to be provided as initial liquidity to the market, to be split equally between all options. Can also be zero
    */
    function createMarket(uint32[] memory _marketTimes, uint64[] memory _optionRanges, address _marketCreator, uint64 _initialLiquidity) 
    public 
    returns(uint64 _marketIndex)
    {
      require(_marketCreator != address(0));
      require(authorizedMarketCreator[msg.sender]);
      require(!marketCreationPaused);
      _checkForValidMarketTimes(_marketTimes);
      _checkForValidOptionRanges(_optionRanges);
      _marketIndex = uint64(marketBasicData.length);
      marketBasicData.push(MarketBasicData(_marketTimes[0], _marketTimes[1], _marketTimes[2], _marketTimes[3]));
      marketDataExtended[_marketIndex].optionRanges = _optionRanges;
      marketDataExtended[_marketIndex].marketCreatorContract = msg.sender;
      emit MarketQuestion(_marketIndex, _marketTimes[0], _marketTimes[1], _marketTimes[3], _marketTimes[2], _optionRanges, msg.sender);
      if(_initialLiquidity > 0) {
        _placeInitialPrediction(_marketIndex, _marketCreator, _initialLiquidity, uint64(_optionRanges.length + 1));
      }
      return _marketIndex;
    }

    /**
    * @dev Internal function to check for valid given market times.
    */
    function _checkForValidMarketTimes(uint32[] memory _marketTimes) internal pure {
      for(uint i=0;i<_marketTimes.length;i++) {
        require(_marketTimes[i] != 0);
      }
      require(_marketTimes[2] > _marketTimes[1]); // Settlement time should be greater than prediction time
    }

    /**
    * @dev Internal function to check for valid given option ranges.
    */
    function _checkForValidOptionRanges(uint64[] memory _optionRanges) internal pure {
      for(uint i=0;i<_optionRanges.length;i++) {
        require(_optionRanges[i] != 0);
        if( i > 0) {
          require(_optionRanges[i] > _optionRanges[i - 1]);
        }
      }
    }
    
    /**
     * @dev Internal function to place initial prediction of the market creator
     * @param _marketId Index of the market to place prediction
     * @param _msgSenderAddress Address of the user who is placing the prediction
     */
    function _placeInitialPrediction(uint64 _marketId, address _msgSenderAddress, uint64 _initialLiquidity, uint64 _totalOptions) internal {
      uint256 _defaultAmount = (10**predictionDecimalMultiplier).mul(_initialLiquidity);
      (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress);
      uint _balanceAvailable = _tokenLeft.add(_tokenReward);
      if(_balanceAvailable < _defaultAmount) {
        _deposit(_defaultAmount.sub(_balanceAvailable), _msgSenderAddress);
      }
      address _predictionToken = predictionToken;
      uint64 _predictionAmount = _initialLiquidity/ _totalOptions;
      for(uint i = 1;i < _totalOptions; i++) {
        _placePrediction(_marketId, _msgSenderAddress, _predictionToken, _predictionAmount, i);
        _initialLiquidity = _initialLiquidity.sub(_predictionAmount);
      }
      _placePrediction(_marketId, _msgSenderAddress, _predictionToken, _initialLiquidity, _totalOptions);
    }

    /**
    * @dev Transfer the _asset to specified address.
    * @param _recipient The address to transfer the asset of
    * @param _amount The amount which is transfer.
    */
    function _transferAsset(address _asset, address _recipient, uint256 _amount) internal {
      if(_amount > 0) { 
          require(IToken(_asset).transfer(_recipient, _amount));
      }
    }

    /**
    * @dev Get market settle time
    * @param _marketId Index of the market
    * @return the time at which the market result will be declared
    */
    function marketSettleTime(uint256 _marketId) public view returns(uint32) {
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      if(_marketDataExtended.settleTime > 0) {
        return _marketDataExtended.settleTime;
      }
      return _marketBasicData.startTime + (_marketBasicData.settlementTime);
    }

    /**
    * @dev Gets the status of market.
    * @param _marketId Index of the market
    * @return PredictionStatus representing the status of market.
    */
    function marketStatus(uint256 _marketId) public view returns(PredictionStatus){
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      if(_marketDataExtended.predictionStatus == PredictionStatus.Live && now >= marketExpireTime(_marketId)) {
        return PredictionStatus.InSettlement;
      } else if(_marketDataExtended.predictionStatus == PredictionStatus.Settled && now <= marketCoolDownTime(_marketId)) {
        return PredictionStatus.Cooling;
      }
      return _marketDataExtended.predictionStatus;
    }

    /**
    * @dev Get market cooldown time
    * @param _marketId Index of the market
    * @return the time upto which user can raise the dispute after the market is settled
    */
    function marketCoolDownTime(uint256 _marketId) public view returns(uint256) {
      return (marketSettleTime(_marketId) + marketBasicData[_marketId].cooldownTime);
    }

    /**
    * @dev Updates Flag to pause creation of market.
    */
    function pauseMarketCreation() external onlyAuthorized {
      require(!marketCreationPaused);
      marketCreationPaused = true;
    }

    /**
    * @dev Updates Flag to resume creation of market.
    */
    function resumeMarketCreation() external onlyAuthorized {
      require(marketCreationPaused);
      marketCreationPaused = false;
    }

    /**
    * @dev Function to deposit prediction token for participation in markets
    * @param _amount Amount of prediction token to deposit
    */
    function _deposit(uint _amount, address _msgSenderAddress) internal {
      _transferTokenFrom(predictionToken, _msgSenderAddress, address(this), _amount);
      UserData storage _userData = userData[_msgSenderAddress];
      _userData.unusedBalance = _userData.unusedBalance.add(_amount);
      emit Deposited(_msgSenderAddress, _amount, now);
    }

    /**
    * @dev Withdraw provided amount of deposited and available prediction token
    * @param _token Amount of prediction token to withdraw
    * @param _maxRecords Maximum number of records to check
    */
    function withdraw(uint _token, uint _maxRecords) public {
      address payable _msgSenderAddress = _msgSender();
      (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress);
      _tokenLeft = _tokenLeft.add(_tokenReward);
      _withdraw(_token, _maxRecords, _tokenLeft, _msgSenderAddress);
    }

    /**
    * @dev Internal function to withdraw deposited and available assets
    * @param _token Amount of prediction token to withdraw
    * @param _maxRecords Maximum number of records to check
    * @param _tokenLeft Amount of prediction token left unused for user
    */
    function _withdraw(uint _token, uint _maxRecords, uint _tokenLeft, address _msgSenderAddress) internal {
      _withdrawReward(_maxRecords, _msgSenderAddress);
      userData[_msgSenderAddress].unusedBalance = _tokenLeft.sub(_token);
      require(_token > 0);
      _transferAsset(predictionToken, _msgSenderAddress, _token);
      emit Withdrawn(_msgSenderAddress, _token, now);
    }

    /**
    * @dev Get market expire time
    * @return the time upto which user can place predictions in market
    */
    function marketExpireTime(uint _marketId) internal view returns(uint256) {
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      return _marketBasicData.startTime + (_marketBasicData.predictionTime);
    }

    /**
    * @dev Deposit and Place prediction on the available options of the market with both PLOT and BPLOT.
    * @param _marketId Index of the market
    * @param _tokenDeposit prediction token amount to deposit
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _prediction The option on which user placed prediction.
    * @param _plotPredictionAmount The PLOT amount staked by user at the time of prediction.
    * @param _bPLOTPredictionAmount The BPLOT amount staked by user at the time of prediction.
    * _tokenDeposit should be passed with 18 decimals
    * _plotPredictionAmount and _bPLOTPredictionAmount should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function depositAndPredictWithBoth(uint _tokenDeposit, uint _marketId, address _asset, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount) external {
      address payable _msgSenderAddress = _msgSender();
      UserData storage _userData = userData[_msgSenderAddress];
      uint64 _predictionStake = _plotPredictionAmount.add(_bPLOTPredictionAmount);
      //Can deposit only if prediction stake amount contains plot
      if(_plotPredictionAmount > 0 && _tokenDeposit > 0) {
        _deposit(_tokenDeposit, _msgSenderAddress);
      }
      if(_bPLOTPredictionAmount > 0) {
        require(!_userData.userMarketData[_marketId].predictedWithBlot);
        _userData.userMarketData[_marketId].predictedWithBlot = true;
        uint256 _amount = (10**predictionDecimalMultiplier).mul(_bPLOTPredictionAmount);
        bPLOTInstance.convertToPLOT(_msgSenderAddress, address(this), _amount);
        _userData.unusedBalance = _userData.unusedBalance.add(_amount);
      }
      require(_asset == plotToken);
      _placePrediction(_marketId, _msgSenderAddress, _asset, _predictionStake, _prediction);
    }

    /**
    * @dev Deposit and Place prediction on the available options of the market.
    * @param _marketId Index of the market
    * @param _tokenDeposit prediction token amount to deposit
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param _prediction The option on which user placed prediction.
    * _tokenDeposit should be passed with 18 decimals
    * _predictioStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function depositAndPlacePrediction(uint _tokenDeposit, uint _marketId, address _asset, uint64 _predictionStake, uint256 _prediction) external {
      address payable _msgSenderAddress = _msgSender();
      if(_tokenDeposit > 0) {
        _deposit(_tokenDeposit, _msgSenderAddress);
      }
      _placePrediction(_marketId, _msgSenderAddress, _asset, _predictionStake, _prediction);
    }

    /**
    * @dev Place prediction on the available options of the market.
    * @param _marketId Index of the market
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param _prediction The option on which user placed prediction.
    * _predictionStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function _placePrediction(uint _marketId, address _msgSenderAddress, address _asset, uint64 _predictionStake, uint256 _prediction) internal {
      require(!marketCreationPaused && _prediction <= (marketDataExtended[_marketId].optionRanges.length +1) && _prediction >0);
      require(now >= marketBasicData[_marketId].startTime && now <= marketExpireTime(_marketId));
      uint64 _predictionStakePostDeduction = _predictionStake;
      uint decimalMultiplier = 10**predictionDecimalMultiplier;
      UserData storage _userData = userData[_msgSenderAddress];
      if(_asset == predictionToken) {
        uint256 unusedBalance = _userData.unusedBalance;
        unusedBalance = unusedBalance.div(decimalMultiplier);
        if(_predictionStake > unusedBalance)
        {
          _withdrawReward(defaultMaxRecords, _msgSenderAddress);
          unusedBalance = _userData.unusedBalance;
          unusedBalance = unusedBalance.div(decimalMultiplier);
        }
        require(_predictionStake <= unusedBalance);
        _userData.unusedBalance = (unusedBalance.sub(_predictionStake)).mul(decimalMultiplier);
      } else {
        require(_asset == address(bPLOTInstance));
        require(!_userData.userMarketData[_marketId].predictedWithBlot);
        _userData.userMarketData[_marketId].predictedWithBlot = true;
        bPLOTInstance.convertToPLOT(_msgSenderAddress, address(this), (decimalMultiplier).mul(_predictionStake));
        _asset = plotToken;
      }
      _predictionStakePostDeduction = _deductFee(_marketId, _predictionStake, _msgSenderAddress);
      
      uint64 predictionPoints = IMarket(marketDataExtended[_marketId].marketCreatorContract).calculatePredictionPointsAndMultiplier(_msgSenderAddress, _marketId, _prediction, _predictionStakePostDeduction);
      require(predictionPoints > 0);

      _storePredictionData(_marketId, _prediction, _msgSenderAddress, _predictionStakePostDeduction, predictionPoints);
      emit PlacePrediction(_msgSenderAddress, _predictionStake, predictionPoints, _asset, _prediction, _marketId);
    }

    /**
     * @dev Internal function to deduct fee from the prediction amount
     * @param _marketId Index of the market
     * @param _amount Total preidction amount of the user
     * @param _msgSenderAddress User address
     */
    function _deductFee(uint _marketId, uint64 _amount, address _msgSenderAddress) internal returns(uint64 _amountPostFee){
      uint64 _fee;
      address _relayer;
      if(_msgSenderAddress != tx.origin) {
        _relayer = tx.origin;
      } else {
        _relayer = _msgSenderAddress;
      }
      (, uint _cummulativeFeePercent)= IMarket(marketDataExtended[_marketId].marketCreatorContract).getUintParameters("CMFP");
      _fee = _calculateAmulBdivC(uint64(_cummulativeFeePercent), _amount, 10000);
      _transferAsset(plotToken, marketDataExtended[_marketId].marketCreatorContract, (10**predictionDecimalMultiplier).mul(_fee));
      IMarket(marketDataExtended[_marketId].marketCreatorContract).handleFee(_marketId, _fee, _msgSenderAddress, _relayer);
      _amountPostFee = _amount.sub(_fee);
    }

    /**
    * @dev Settle the market, setting the winning option
    * @param _marketId Index of market
    */
    function settleMarket(uint256 _marketId, uint256 _value) external {
      require(marketDataExtended[_marketId].marketCreatorContract == msg.sender);
      if(marketStatus(_marketId) == PredictionStatus.InSettlement) {
        _postResult(_value, _marketId);
      }
    }

    /**
    * @dev Function to settle the market when a dispute is raised
    * @param _marketId Index of market
    * @param _marketSettleValue The current price of market currency.
    */
    function postMarketResult(uint256 _marketId, uint256 _marketSettleValue) external {
      require(marketStatus(_marketId) == PredictionStatus.InDispute);
      require(msg.sender == disputeResolution);
      _postResult(_marketSettleValue, _marketId);
    }

    /**
    * @dev Function to emit MarketSettled event of given market.
    * @param _marketId Index of market
    */
    function emitMarketSettledEvent(uint256 _marketId) external {
      require(!marketSettleEventEmitted[_marketId]);
      require(marketStatus(_marketId) == PredictionStatus.Settled);
      marketSettleEventEmitted[_marketId] = true;
      emit MarketSettled(_marketId);
    }

    // function TEMP_emitMarketSettledEvent(uint256 _fromMarketId, uint256 _toMarketId) external {
    //   for(uint i = _fromMarketId; i<= _toMarketId; i++) {
    //     require(!marketSettleEventEmitted[i]);
    //     require(marketStatus(i) == PredictionStatus.Settled);
    //     marketSettleEventEmitted[i] = true;
    //     emit MarketSettled(i);
    //   }
    // }

    /**
    * @dev Calculate the result of market.
    * @param _value The current price of market currency.
    * @param _marketId Index of market
    */
    function _postResult(uint256 _value, uint256 _marketId) internal {
      require(now >= marketSettleTime(_marketId));
      require(_value > 0);
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      if(_marketDataExtended.predictionStatus != PredictionStatus.InDispute) {
        _marketDataExtended.settleTime = uint32(now);
      } else {
        delete _marketDataExtended.settleTime;
      }
      _marketDataExtended.predictionStatus = PredictionStatus.Settled;
      uint32 _winningOption;
      for(uint32 i = 0; i< _marketDataExtended.optionRanges.length;i++) {
        if(_value < _marketDataExtended.optionRanges[i]) {
          _winningOption = i+1;
          break;
        }
      }
      if(_winningOption == 0) {
        _winningOption = uint32(_marketDataExtended.optionRanges.length + 1);
      }
      _marketDataExtended.WinningOption = _winningOption;
      uint64 totalReward = _calculateRewardTally(_marketId, _winningOption);
      _marketDataExtended.rewardToDistribute = totalReward;
      emit MarketResult(_marketId, _marketDataExtended.rewardToDistribute, _winningOption, _value);
    }

    /**
    * @dev Internal function to calculate the reward.
    * @param _marketId Index of market
    * @param _winningOption WinningOption of market
    */
    function _calculateRewardTally(uint256 _marketId, uint256 _winningOption) internal view returns(uint64 totalReward){
      for(uint i=1; i <= marketDataExtended[_marketId].optionRanges.length +1; i++){
        uint64 _tokenStakedOnOption = marketOptionsAvailable[_marketId][i].amountStaked;
        if(i != _winningOption) {
          totalReward = totalReward.add(_tokenStakedOnOption);
        }
      }
    }

    /**
    * @dev Claim the pending return of the market.
    * @param maxRecords Maximum number of records to claim reward for
    */
    function _withdrawReward(uint256 maxRecords, address _msgSenderAddress) internal {
      // address payable _msgSenderAddress = _msgSender();
      uint256 i;
      UserData storage _userData = userData[_msgSenderAddress];
      uint len = _userData.marketsParticipated.length;
      uint lastClaimed = len;
      uint count;
      uint tokenReward =0;
      require(!marketCreationPaused);
      for(i = _userData.lastClaimedIndex; i < len && count < maxRecords; i++) {
        (uint claimed, uint tempTokenReward) = claimReturn(_msgSenderAddress, _userData.marketsParticipated[i]);
        if(claimed > 0) {
          delete _userData.marketsParticipated[i];
          tokenReward = tokenReward.add(tempTokenReward);
          count++;
        } else {
          if(lastClaimed == len) {
            lastClaimed = i;
          }
        }
      }
      if(lastClaimed == len) {
        lastClaimed = i;
      }
      emit ReturnClaimed(_msgSenderAddress, tokenReward);
      _userData.unusedBalance = _userData.unusedBalance.add(tokenReward.mul(10**predictionDecimalMultiplier));
      _userData.lastClaimedIndex = uint128(lastClaimed);
    }

    /**
    * @dev FUnction to return users unused deposited balance including the return earned in markets
    * @param _user Address of user
    * return prediction token Unused in deposit
    * return prediction token Return from market
    */
    function getUserUnusedBalance(address _user) public view returns(uint256, uint256){
      uint tokenReward;
      uint decimalMultiplier = 10**predictionDecimalMultiplier;
      UserData storage _userData = userData[_user];
      uint len = _userData.marketsParticipated.length;
      for(uint i = _userData.lastClaimedIndex; i < len; i++) {
        tokenReward = tokenReward.add(getReturn(_user, _userData.marketsParticipated[i]));
      }
      return (_userData.unusedBalance, tokenReward.mul(decimalMultiplier));
    }

    /**
    * @dev Gets number of positions user got in prediction
    * @param _user Address of user
    * @param _marketId Index of market
    * @param _option Option Id
    * return Number of positions user got in prediction
    */
    function getUserPredictionPoints(address _user, uint256 _marketId, uint256 _option) external view returns(uint64) {
      return userData[_user].userMarketData[_marketId].predictionData[_option].predictionPoints;
    }

    /**
    * @dev Gets the market data.
    * @return _optionRanges Maximum values of all the options
    * @return _tokenStaked uint[] memory representing the prediction token staked on each option ranges of the market.
    * @return _predictionTime uint representing the type of market.
    * @return _expireTime uint representing the time at which market closes for prediction
    * @return _predictionStatus uint representing the status of the market.
    */
    function getMarketData(uint256 _marketId) external view returns
       (uint64[] memory _optionRanges, uint[] memory _tokenStaked,uint _predictionTime,uint _expireTime, PredictionStatus _predictionStatus){
        MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
        _predictionTime = _marketBasicData.predictionTime;
        
        _expireTime = marketExpireTime(_marketId);
        _predictionStatus = marketStatus(_marketId);
        _optionRanges = marketDataExtended[_marketId].optionRanges;
 
        _tokenStaked = new uint[](marketDataExtended[_marketId].optionRanges.length +1);
        for (uint i = 0; i < marketDataExtended[_marketId].optionRanges.length +1; i++) {
          _tokenStaked[i] = marketOptionsAvailable[_marketId][i+1].amountStaked;
       }
    }

    /**
    * @dev Get total options available in the given market id.
    * @param _marketId Index of the market.
    * @return Total number of options.
    */
    function getTotalOptions(uint256 _marketId) external view returns(uint) {
      return marketDataExtended[_marketId].optionRanges.length + 1;
    }

    /**
    * @dev Claim the return amount of the specified address.
    * @param _user User address
    * @param _marketId Index of market
    * @return Flag, if 0:cannot claim, 1: Already Claimed, 2: Claimed; Return in prediction token
    */
    function claimReturn(address _user, uint _marketId) internal view returns(uint256, uint256) {

      if(marketStatus(_marketId) != PredictionStatus.Settled) {
        return (0, 0);
      }
      return (2, getReturn(_user, _marketId));
    }

    /** 
    * @dev Gets the return amount of the specified address.
    * @param _user The address to specify the return of
    * @param _marketId Index of market
    * @return returnAmount uint[] memory representing the return amount.
    * @return incentive uint[] memory representing the amount incentive.
    * @return _incentiveTokens address[] memory representing the incentive tokens.
    */
    function getReturn(address _user, uint _marketId) public view returns (uint returnAmount){
      if(marketStatus(_marketId) != PredictionStatus.Settled || getTotalPredictionPoints(_marketId) == 0) {
       return (returnAmount);
      }
      uint256 _winningOption = marketDataExtended[_marketId].WinningOption;
      UserData storage _userData = userData[_user];
      returnAmount = _userData.userMarketData[_marketId].predictionData[_winningOption].amountStaked;
      uint256 userPredictionPointsOnWinngOption = _userData.userMarketData[_marketId].predictionData[_winningOption].predictionPoints;
      if(userPredictionPointsOnWinngOption > 0) {
        returnAmount = _addUserReward(_marketId, returnAmount, _winningOption, userPredictionPointsOnWinngOption);
      }
      return returnAmount;
    }

    /**
    * @dev Adds the reward in the total return of the specified address.
    * @param returnAmount The return amount.
    * @return uint[] memory representing the return amount after adding reward.
    */
    function _addUserReward(uint256 _marketId, uint returnAmount, uint256 _winningOption, uint256 _userPredictionPointsOnWinngOption) internal view returns(uint){
        return returnAmount.add(
            _userPredictionPointsOnWinngOption.mul(marketDataExtended[_marketId].rewardToDistribute).div(marketOptionsAvailable[_marketId][_winningOption].predictionPoints)
          );
    }

    /**
    * @dev Basic function to perform mathematical operation of (`_a` * `_b` / `_c`)
    * @param _a value of variable a
    * @param _b value of variable b
    * @param _c value of variable c
    */
    function _calculateAmulBdivC(uint64 _a, uint64 _b, uint64 _c) internal pure returns(uint64) {
      return _a.mul(_b).div(_c);
    }

    /**
    * @dev Returns total assets staked in market in PLOT value
    * @param _marketId Index of market
    * @return tokenStaked Total prediction token staked on market value in PLOT
    */
    function getTotalStakedWorthInPLOT(uint256 _marketId) public view returns(uint256 _tokenStakedWorth) {
      return (marketDataExtended[_marketId].totalStaked).mul(10**predictionDecimalMultiplier);
      // return (marketDataExtended[_marketId].totalStaked).mul(conversionRate[plotToken]).mul(10**predictionDecimalMultiplier);
    }

    /**
    * @dev Returns total prediction points allocated to users
    * @param _marketId Index of market
    * @return predictionPoints total prediction points allocated to users
    */
    function getTotalPredictionPoints(uint _marketId) public view returns(uint64 predictionPoints) {
      for(uint256 i = 1; i<= marketDataExtended[_marketId].optionRanges.length +1;i++) {
        predictionPoints = predictionPoints.add(marketOptionsAvailable[_marketId][i].predictionPoints);
      }
    }

    /**
    * @dev Stores the prediction data.
    * @param _prediction The option on which user place prediction.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param predictionPoints The positions user got during prediction.
    */
    function _storePredictionData(uint _marketId, uint _prediction, address _msgSenderAddress, uint64 _predictionStake, uint64 predictionPoints) internal {
      UserData storage _userData = userData[_msgSenderAddress];
      PredictionData storage _predictionData = marketOptionsAvailable[_marketId][_prediction];
      if(!_hasUserParticipated(_marketId, _msgSenderAddress)) {
        _userData.marketsParticipated.push(_marketId);
      }
      _userData.userMarketData[_marketId].predictionData[_prediction].predictionPoints = _userData.userMarketData[_marketId].predictionData[_prediction].predictionPoints.add(predictionPoints);
      _predictionData.predictionPoints = _predictionData.predictionPoints.add(predictionPoints);
      
      _userData.userMarketData[_marketId].predictionData[_prediction].amountStaked = _userData.userMarketData[_marketId].predictionData[_prediction].amountStaked.add(_predictionStake);
      _predictionData.amountStaked = _predictionData.amountStaked.add(_predictionStake);
      _userData.totalStaked = _userData.totalStaked.add(_predictionStake);
      marketDataExtended[_marketId].totalStaked = marketDataExtended[_marketId].totalStaked.add(_predictionStake);
      
    }

    /**
    * @dev Function to check if user had participated in given market
    * @param _marketId Index of market
    * @param _user Address of user
    */
    function _hasUserParticipated(uint256 _marketId, address _user) internal view returns(bool _hasParticipated) {
      for(uint i = 1;i <= marketDataExtended[_marketId].optionRanges.length +1; i++) {
        if(userData[_user].userMarketData[_marketId].predictionData[i].predictionPoints > 0) {
          _hasParticipated = true;
          break;
        }
      }
    }

    /**
    * @dev Internal function to call transferFrom function of a given token
    * @param _token Address of the ERC20 token
    * @param _from Address from which the tokens are to be received
    * @param _to Address to which the tokens are to be transferred
    * @param _amount Amount of tokens to transfer. In Wei
    */
    function _transferTokenFrom(address _token, address _from, address _to, uint256 _amount) internal {
      IToken(_token).transferFrom(_from, _to, _amount);
    }

    /**
    * @dev Get flags set for user
    * @param _marketId Index of market.
    * @param _user User address
    * @return Flag defining if user had predicted with bPLOT
    * @return Flag defining if user had availed multiplier
    */
    function getUserFlags(uint256 _marketId, address _user) external view returns(bool) {
      return (
              userData[_user].userMarketData[_marketId].predictedWithBlot
      );
    }

    /**
    * @dev Gets the result of the market.
    * @param _marketId Index of market.
    * @return uint256 representing the winning option of the market.
    * @return uint256 Value of market currently at the time closing market.
    * @return uint256 representing the positions of the winning option.
    * @return uint[] memory representing the reward to be distributed.
    * @return uint256 representing the prediction token staked on winning option.
    */
    function getMarketResults(uint256 _marketId) external view returns(uint256 _winningOption, uint256, uint256, uint256) {
      _winningOption = marketDataExtended[_marketId].WinningOption;
      return (_winningOption, marketOptionsAvailable[_marketId][_winningOption].predictionPoints, marketDataExtended[_marketId].rewardToDistribute, marketOptionsAvailable[_marketId][_winningOption].amountStaked);
    }

    /**
    * @dev Internal function set market status
    * @param _marketId Index of market
    * @param _status Status of market to set
    */
    function setMarketStatus(uint256 _marketId, PredictionStatus _status) public {
      require(msg.sender == disputeResolution);
      marketDataExtended[_marketId].predictionStatus = _status;
    }

    /**
    * @dev Gets the Option pricing params for market.
    * @param _marketId Index of market.
    * @param _option predicting option.
    * @return uint[] Array consist of pricing param.
    * @return uint32 start time of market.
    * @return address feed address for market.
    */
    function getMarketOptionPricingParams(uint _marketId, uint _option) external view returns(uint[] memory, uint32) {

      // [0] -> amount staked in `_option`
      // [1] -> Total amount staked in market
      uint[] memory _optionPricingParams = new uint256[](2);
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      _optionPricingParams[0] = marketOptionsAvailable[_marketId][_option].amountStaked;
      _optionPricingParams[1] = marketDataExtended[_marketId].totalStaked;
      return (_optionPricingParams,_marketBasicData.startTime);
    }

    /**
    * @dev Get total number of markets created till now.
    */
    function getTotalMarketsLength() external view returns(uint64) {
      return uint64(marketBasicData.length);
    }

    /**
    * @dev Get total amount staked by the user in markets.
    */
    function getTotalStakedByUser(address _user) external view returns(uint) {
      return userData[_user].totalStaked;
    }
}

// File: contracts/AllPlotMarkets_2.sol

/* Copyright (C) 2021 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract AllPlotMarkets_2 is AllPlotMarkets {

    mapping(address => bool) public authToProxyPrediction;

    /**
    * @dev Function to add an authorized address to place proxy predictions
    * @param _proxyAddress Address to whitelist
    */
    function addAuthorizedProxyPreditictor(address _proxyAddress) external onlyAuthorized {
      require(_proxyAddress != address(0));
      authToProxyPrediction[_proxyAddress] = true;
    }

    /**
    * @dev Function to deposit prediction token for participation in markets
    * @param _amount Amount of prediction token to deposit
    */
    function _depositFor(uint _amount, address _msgSenderAddress, address _depositForAddress) internal {
      _transferTokenFrom(predictionToken, _msgSenderAddress, address(this), _amount);
      UserData storage _userData = userData[_depositForAddress];
      _userData.unusedBalance = _userData.unusedBalance.add(_amount);
      emit Deposited(_depositForAddress, _amount, now);
    }

    /**
    * @dev Deposit and Place prediction on behalf of another address
    * @param _predictFor Address of user, to place prediction for
    * @param _marketId Index of the market
    * @param _tokenDeposit prediction token amount to deposit
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _prediction The option on which user placed prediction.
    * @param _plotPredictionAmount The PLOT amount staked by user at the time of prediction.
    * @param _bPLOTPredictionAmount The BPLOT amount staked by user at the time of prediction.
    * _tokenDeposit should be passed with 18 decimals
    * _plotPredictionAmount and _bPLOTPredictionAmount should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function depositAndPredictFor(address _predictFor, uint _tokenDeposit, uint _marketId, address _asset, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount) external {
      require(_predictFor != address(0));
      address payable _msgSenderAddress = _msgSender();
      require(authToProxyPrediction[_msgSenderAddress]);
      uint64 _predictionStake = _plotPredictionAmount.add(_bPLOTPredictionAmount);
      //Can deposit only if prediction stake amount contains plot
      if(_plotPredictionAmount > 0 && _tokenDeposit > 0) {
        _depositFor(_tokenDeposit, _msgSenderAddress, _predictFor);
      }
      if(_bPLOTPredictionAmount > 0) {
        UserData storage _userData = userData[_predictFor];
        require(!_userData.userMarketData[_marketId].predictedWithBlot);
        _userData.userMarketData[_marketId].predictedWithBlot = true;
        uint256 _amount = (10**predictionDecimalMultiplier).mul(_bPLOTPredictionAmount);
        bPLOTInstance.convertToPLOT(_predictFor, address(this), _amount);
        _userData.unusedBalance = _userData.unusedBalance.add(_amount);
      }
      require(_asset == plotToken);
      _placePrediction(_marketId, _predictFor, _asset, _predictionStake, _prediction);
    }

}

// File: contracts/AllPlotMarkets_3.sol

/* Copyright (C) 2021 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract AllPlotMarkets_3 is AllPlotMarkets_2 {

    mapping(uint => uint) internal creatorRewardFromRewardPool;
    uint internal constant maxPendingClaims = 100;

    /**
    * @dev Place prediction on the available options of the market.
    * @param _marketId Index of the market
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param _prediction The option on which user placed prediction.
    * _predictionStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function _placePrediction(uint _marketId, address _msgSenderAddress, address _asset, uint64 _predictionStake, uint256 _prediction) internal {
      if(userData[_msgSenderAddress].marketsParticipated.length > maxPendingClaims) {
        _withdrawReward(defaultMaxRecords, _msgSenderAddress);
      }
      super._placePrediction(_marketId, _msgSenderAddress, _asset, _predictionStake, _prediction);
    }


    /**
    * @dev Claim the return amount of the specified address.
    * @param _user User address
    * @param _marketId Index of market
    * @return Flag, if 0:cannot claim, 2: Claimed; Return in prediction token
    */
    function claimReturn(address _user, uint _marketId) internal view returns(uint256, uint256) {

      if(!marketSettleEventEmitted[_marketId]) {
        return (0, 0);
      }
      return (2, getReturn(_user, _marketId));
    }

    /** 
    * @dev Gets the return amount of the specified address.
    * @param _user The address to specify the return of
    * @param _marketId Index of market
    * @return returnAmount uint[] memory representing the return amount.
    * @return incentive uint[] memory representing the amount incentive.
    * @return _incentiveTokens address[] memory representing the incentive tokens.
    */
    function getReturn(address _user, uint _marketId) public view returns (uint returnAmount){
      if(!marketSettleEventEmitted[_marketId] || getTotalPredictionPoints(_marketId) == 0) {
       return (returnAmount);
      }
      uint256 _winningOption = marketDataExtended[_marketId].WinningOption;
      UserData storage _userData = userData[_user];
      returnAmount = _userData.userMarketData[_marketId].predictionData[_winningOption].amountStaked;
      uint256 userPredictionPointsOnWinngOption = _userData.userMarketData[_marketId].predictionData[_winningOption].predictionPoints;
      if(userPredictionPointsOnWinngOption > 0) {
        returnAmount = _addUserReward(_marketId, returnAmount, _winningOption, userPredictionPointsOnWinngOption);
      }
      return returnAmount;
    }

    /**
    * @dev Calculate the result of market.
    * @param _value The current price of market currency.
    * @param _marketId Index of market
    */
    function _postResult(uint256 _value, uint256 _marketId) internal {
      require(now >= marketSettleTime(_marketId));
      require(_value > 0);
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      if(_marketDataExtended.predictionStatus != PredictionStatus.InDispute) {
        _marketDataExtended.settleTime = uint32(now);
      } else {
        delete _marketDataExtended.settleTime;
      }
      _marketDataExtended.predictionStatus = PredictionStatus.Settled;
      uint32 _winningOption;
      for(uint32 i = 0; i< _marketDataExtended.optionRanges.length;i++) {
        if(_value < _marketDataExtended.optionRanges[i]) {
          _winningOption = i+1;
          break;
        }
      }
      if(_winningOption == 0) {
        _winningOption = uint32(_marketDataExtended.optionRanges.length + 1);
      }
      _marketDataExtended.WinningOption = _winningOption;
      uint64 totalReward = _calculateRewardTally(_marketId, _winningOption);
      (,uint RPS) = IMarket(_marketDataExtended.marketCreatorContract).getUintParameters("RPS");
      uint64 rewardForCreator = 0;
      if(RPS>0)
      {
        rewardForCreator = uint64(RPS).mul(totalReward).div(100);
        creatorRewardFromRewardPool[_marketId] = rewardForCreator;
      }
      _marketDataExtended.rewardToDistribute = totalReward.sub(rewardForCreator);
      emit MarketResult(_marketId, _marketDataExtended.rewardToDistribute, _winningOption, _value);
    }

    /**
    * @dev Emit MarketSettled event of given market and transfer if any reward pool share exists
    * @param _marketId Index of market
    */
    function emitMarketSettledEvent(uint256 _marketId) external {
      require(marketStatus(_marketId) == PredictionStatus.Settled);
      require(!marketSettleEventEmitted[_marketId]);
      marketSettleEventEmitted[_marketId] = true;
      uint creatorReward = creatorRewardFromRewardPool[_marketId].mul(10**predictionDecimalMultiplier);
      if(creatorReward>0)
      {
        delete creatorRewardFromRewardPool[_marketId];
        MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
        _transferAsset(plotToken,_marketDataExtended.marketCreatorContract,creatorReward);
        IMarket(_marketDataExtended.marketCreatorContract).setRewardPoolShareForCreator(_marketId, creatorReward);
      }

      emit MarketSettled(_marketId);
    }

    /**
    * @dev Withdraw provided amount of deposited and available prediction token
    * @param _token Amount of prediction token to withdraw
    * @param _maxRecords Maximum number of records to check
    */
    function withdraw(uint _token, uint _maxRecords) public {
      address payable _msgSenderAddress = _msgSender();
      // (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress);
      // _tokenLeft = _tokenLeft.add(_tokenReward);
      _withdraw(_token, _maxRecords, 0, _msgSenderAddress);
    }

    /**
    * @dev Internal function to withdraw deposited and available assets
    * @param _token Amount of prediction token to withdraw
    * @param _maxRecords Maximum number of records to check
    * @param _tokenLeft Amount of prediction token left unused for user
    */
    function _withdraw(uint _token, uint _maxRecords, uint _tokenLeft, address _msgSenderAddress) internal {
      _withdrawReward(_maxRecords, _msgSenderAddress);
      userData[_msgSenderAddress].unusedBalance = userData[_msgSenderAddress].unusedBalance.sub(_token);
      require(_token > 0);
      _transferAsset(predictionToken, _msgSenderAddress, _token);
      emit Withdrawn(_msgSenderAddress, _token, now);
    }

    /**
    * @dev Claim the pending return of the market.
    * @param maxRecords Maximum number of records to claim reward for
    */
    function _withdrawReward(uint256 maxRecords, address _msgSenderAddress) internal {
      uint256 i;
      UserData storage _userData = userData[_msgSenderAddress];
      uint[] memory _marketsParticipated = _userData.marketsParticipated;
      uint len = _marketsParticipated.length;
      uint tokenReward =0;
      uint lastClaimedIndex = _userData.lastClaimedIndex;
      require(!marketCreationPaused);

      uint tempArrayCount;
      if(lastClaimedIndex == 0) {
        tempArrayCount = len;
      } else {
        tempArrayCount = len.sub(lastClaimedIndex);
      }
      // uint tempArrayLength = len < tempArrayCount? len: tempArrayCount;
      uint[] memory unsettledMarkets =  new uint[](tempArrayCount);
      //tempArrayCount will now act as a counter for temporary array i.e: unsettledMarkets;
      tempArrayCount = 0;
      for(i = lastClaimedIndex; i < len; i++) {
        (uint claimed, uint tempTokenReward) = claimReturn(_msgSenderAddress, _marketsParticipated[i]);
        if(claimed > 0) {
          tokenReward = tokenReward.add(tempTokenReward);
        } else {
          if(_marketsParticipated[i] > 0) {
            unsettledMarkets[tempArrayCount] = _marketsParticipated[i];
            tempArrayCount++;
          }
        }
      }
      delete _userData.marketsParticipated;
      delete _userData.lastClaimedIndex;
      _userData.marketsParticipated = unsettledMarkets;
      if(unsettledMarkets.length != tempArrayCount) {
        _userData.marketsParticipated.length = tempArrayCount;
      }
      emit ReturnClaimed(_msgSenderAddress, tokenReward);
      _userData.unusedBalance = _userData.unusedBalance.add(tokenReward.mul(10**predictionDecimalMultiplier));
    }

}

// File: contracts/AllPlotMarkets_4.sol

/* Copyright (C) 2021 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract AllPlotMarkets_4 is AllPlotMarkets_3 {

    /**
     * @dev Internal function to place initial prediction of the market creator
     * @param _marketId Index of the market to place prediction
     * @param _msgSenderAddress Address of the user who is placing the prediction
     */
    function _placeInitialPrediction(uint64 _marketId, address _msgSenderAddress, uint64 _initialLiquidity, uint64 _totalOptions) internal {
      uint256 _defaultAmount = (10**predictionDecimalMultiplier).mul(_initialLiquidity);
      if(userData[_msgSenderAddress].marketsParticipated.length > maxPendingClaims) {
        _withdrawReward(defaultMaxRecords, _msgSenderAddress);
      }

      (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress);
      uint _balanceAvailable = _tokenLeft.add(_tokenReward);
      if(_balanceAvailable < _defaultAmount) {
        _deposit(_defaultAmount.sub(_balanceAvailable), _msgSenderAddress);
      }
      address _predictionToken = predictionToken;
      uint64 _predictionAmount = _initialLiquidity/ _totalOptions;
      for(uint i = 1;i < _totalOptions; i++) {
        _provideLiquidity(_marketId, _msgSenderAddress, _predictionToken, _predictionAmount, i);
        _initialLiquidity = _initialLiquidity.sub(_predictionAmount);
      }
      _provideLiquidity(_marketId, _msgSenderAddress, _predictionToken, _initialLiquidity, _totalOptions);
    }

    /**
    * @dev Add liquidity on given option (Simplified version of _placePrediction, removed checks)
    * @param _marketId Index of the market
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param _prediction The option on which user placed prediction.
    * _predictionStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function _provideLiquidity(uint _marketId, address _msgSenderAddress, address _asset, uint64 _predictionStake, uint256 _prediction) internal {
      uint decimalMultiplier = 10**predictionDecimalMultiplier;
      UserData storage _userData = userData[_msgSenderAddress];
      
      uint256 unusedBalance = _userData.unusedBalance;
      unusedBalance = unusedBalance.div(decimalMultiplier);
      if(_predictionStake > unusedBalance)
      {
        _withdrawReward(defaultMaxRecords, _msgSenderAddress);
        unusedBalance = _userData.unusedBalance;
        unusedBalance = unusedBalance.div(decimalMultiplier);
      }
      _userData.unusedBalance = (unusedBalance.sub(_predictionStake)).mul(decimalMultiplier);
   
      uint64 predictionPoints = IMarket(marketDataExtended[_marketId].marketCreatorContract).calculatePredictionPointsAndMultiplier(_msgSenderAddress, _marketId, _prediction, _predictionStake);
      require(predictionPoints > 0);

      _storePredictionData(_marketId, _prediction, _msgSenderAddress, _predictionStake, predictionPoints);
      emit PlacePrediction(_msgSenderAddress, _predictionStake, predictionPoints, _asset, _prediction, _marketId);
    }
}

// File: contracts/AllPlotMarkets_5.sol

/* Copyright (C) 2021 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract AllPlotMarkets_5 is AllPlotMarkets_4 {

    /**
    * @dev Create the market.
    * @param _marketTimes Array of params as mentioned below
    * _marketTimes => [0] _startTime, [1] _predictionTIme, [2] _settlementTime, [3] _cooldownTime
    * @param _optionRanges Array of params as mentioned below
    * _optionRanges => For 3 options, the array will be with two values [a,b], First option will be the value less than zeroth index of this array, the next option will be the value less than first index of the array and the last option will be the value greater than the first index of array
    * @param _marketCreator Address of the user who initiated the market creation
    * @param _initialLiquidities Amount of tokens to be provided as initial liquidity to the market, to be split equally between all options. Can also be zero
    */
    function createMarketWithVariableLiquidity(uint32[] memory _marketTimes, uint64[] memory _optionRanges, address _marketCreator, uint64[] memory _initialLiquidities) 
    public 
    returns(uint64 _marketIndex)
    {
      require(_marketCreator != address(0));
      require(authorizedMarketCreator[msg.sender]);
      require(!marketCreationPaused);
      _checkForValidMarketTimes(_marketTimes);
      _checkForValidOptionRanges(_optionRanges);
      _marketIndex = uint64(marketBasicData.length);
      marketBasicData.push(MarketBasicData(_marketTimes[0], _marketTimes[1], _marketTimes[2], _marketTimes[3]));
      marketDataExtended[_marketIndex].optionRanges = _optionRanges;
      marketDataExtended[_marketIndex].marketCreatorContract = msg.sender;
      emit MarketQuestion(_marketIndex, _marketTimes[0], _marketTimes[1], _marketTimes[3], _marketTimes[2], _optionRanges, msg.sender);
    //   if(_initialLiquidity > 0) {
        _initialPredictionWithVariableLiquidity(_marketIndex, _marketCreator, _initialLiquidities, uint64(_optionRanges.length + 1));
    //   }
      return _marketIndex;
    }

    /**
     * @dev Internal function to place initial prediction of the market creator
     * @param _marketId Index of the market to place prediction
     * @param _msgSenderAddress Address of the user who is placing the prediction
     */
    function _initialPredictionWithVariableLiquidity(uint64 _marketId, address _msgSenderAddress, uint64[] memory _initialLiquidities, uint64 _totalOptions) internal {
      uint64 _initialLiquidity;
      for(uint i = 0;i < _initialLiquidities.length; i++) {
        _initialLiquidity = _initialLiquidity.add(_initialLiquidities[i]);
      }
      uint256 _defaultAmount = (10**predictionDecimalMultiplier).mul(_initialLiquidity);
      if(userData[_msgSenderAddress].marketsParticipated.length > maxPendingClaims) {
        _withdrawReward(defaultMaxRecords, _msgSenderAddress);
      }

      (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress);
      uint _balanceAvailable = _tokenLeft.add(_tokenReward);
      if(_balanceAvailable < _defaultAmount) {
        _deposit(_defaultAmount.sub(_balanceAvailable), _msgSenderAddress);
      }
      require(_totalOptions == _initialLiquidities.length);
      address _predictionToken = predictionToken;
      for(uint i = 1;i <= _totalOptions; i++) {
        if(_initialLiquidities[i-1] > 0) {
          _provideLiquidity(_marketId, _msgSenderAddress, _predictionToken, _initialLiquidities[i-1], i);
        }
      }
    }

}