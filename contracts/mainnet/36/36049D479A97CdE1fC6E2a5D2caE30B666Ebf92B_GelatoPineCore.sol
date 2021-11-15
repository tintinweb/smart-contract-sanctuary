// SPDX-License-Identifier: GPL-3.0

//
// Original work by Pine.Finance
//  - https://github.com/pine-finance
//
// Authors:
//  - Ignacio Mazzara <@nachomazzara>
//  - Agustin Aguilar <@agusx1211>

// solhint-disable-next-line
pragma solidity 0.6.12;

import {PineCore, IModule, IERC20} from "./PineCore.sol";

contract GelatoPineCore is PineCore {
    modifier onlyGelato {
        require(
            address(0x3CACa7b48D0573D793d3b0279b5F0029180E83b6) == msg.sender,
            "GelatoPineCore: onlyGelato"
        );
        _;
    }

    function executeOrder(
        IModule _module,
        IERC20 _inputToken,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _signature,
        bytes calldata _auxData
    ) public override onlyGelato {
        super.executeOrder(
            _module,
            _inputToken,
            _owner,
            _data,
            _signature,
            _auxData
        );
    }
}

/**
 *Submitted for verification at Etherscan.io on 2020-08-30
 */

/**
 *Submitted for verification at Etherscan.io on 2020-08-30
 */

// SPDX-License-Identifier: GPL-3.0
//
// Original work by Pine.Finance
//  - https://github.com/pine-finance
//
// Authors:
//  - Ignacio Mazzara <@nachomazzara>
//  - Agustin Aguilar <@agusx1211>

//
//
//                                                /
//                                                @,
//                                               /&&
//                                              &&%%&/
//                                            &%%%%&%%,..
//                                         */%&,*&&&&&&%%&*
//                                           /&%%%%%%%#.
//                                    ./%&%%%&#/%%%%&#&%%%&#(*.
//                                         .%%%%%%%&&%&/ ..,...
//                                       .*,%%%%%%%%%&&%%%%(
//                                     ,&&%%%&&*%%%%%%%%.*(#%&/
//                                  ./,(*,*,#%%%%%%%%%%%%%%%(,
//                                 ,(%%%%%%%%%%%%&%%%%%%%%%#&&%%%#/(*
//                                     *#%%%%%%%&%%%&%%#%%%%%%(
//                              .(####%%&%&#*&%%##%%%%%%%%%%%#.,,
//                                      ,&%%%%%###%%%%%%%%%%%%#&&.
//                             ..,(&%%%%%%%%%%%%%%%%%%&&%%%%#%&&%&%%%%&&#,
//                           ,##//%((#*/#%%%%%%%%%%%%%%%%%%%%%&(.
//                                  (%%%%%%%%%%%%%%%%%%%#%%%%%%%%%&&&&#(*,
//                                   ./%%%%&%%%%#%&%%%%%%##%%&&&&%%(*,
//                                #%%%%%%&&%%%#%%%%%%%%%%%%%%%&#,*&&#.
//                            /%##%(%&/ #%%%%%%%%%%%%%%%%%%%%%%%%%&%%%.
//                                 *&%%%%&%%%%%%%%#%%%%%%%%%%%%%%%%%&%%%#%#%%,
//                        .*(#&%%%%%%%%&&%%%%%%%%%%#%%%%%%%%%%%%%%%(,
//                    ./#%%%%%%%%%%%%%%%%%%%%%%%#%&%#%%%%%%%%%%%%%%%%%%%%&%%%#####(.
//                          .,,*#%%%%%%%%%%%%%##%%&&%#%%%%%%%%&&%%%%%%(&*#&**/(*
//                        .,(&%%%%%#((%%%%%%#%%%%%%%%%#%%%%%%%&&&&&%%%%&%*
//                         ,,,,,..*&%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%#/*.
//                           ,#&%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%%%%%%%%/,
//           .     .,*(#%%%%%%%%%&&&&%%%%%%&&&%%%%%%%%%&&%##%%%%%#,(%%%%%%%%%%%(((*
//             ,/((%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#%%%%%%%&#  . . ...
//                      .,.,,**(%%%%%%%%&%##%%%%%%%%%%%%%%%%%%###%%%%%%%%%&*
//                       ,%&%%%%%&&%%%%%%%#%%%%%%%%%%%%%%%%%%&%%%%##%%%%%%%%%%%%%%%%&&#.
//              .(&&&%%%%%%&#&&%&%%%%%%%##%%%%&&%%%#%%%%%%&%%%%%%&&%%%%&&&/*(,(#(,,.
//                         ..&%%%%%%#%#%%%%%%%%%%%##%%%%%%%&%%%%%%%%%%%%%%%%&&(.
//                      ,%%%%%%%%%##%%%&%%%%%%%%&%%#%%&&%%%%&%%%%%%&%%%%%&(#%%%#,
//              ./%&%%%%%%%%%%%%%%%%%%%%%%%%%&&&%%%##%%%%%%%%%%%%%&&&%%%%%%%%&#.//*/,..
//      ,#%%%%%%%%%%%%%%%%%%&&%%%%%&&&&%%%%%&&&%%%%%#%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%&&(,..
//            ,#* ,&&&%,.,*(%%%%%%%%%&%%%%&&&%%%%%&%%%%#%%%%##%%%%%%%&&%%%%%%%%%%%#%%%%%%%%&%(*.
//          .,,/((#%&%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&%#%%%%%%%%%%%%%%%%%#%%%%%%%((*
// *,//**,...,/#%%%%%%%%%%%&&&&%%%%%%%%%%%%%#%%%%%%&&&%%%%&&&&%%%#%%#%%%%%%%%%%%%%%%#*.       .,(#%&@*
//  .*%%(*(%%%%%%%%%%&&&&&&&&%%%%%%%&&%%%%%%%%%%%%%&&&%%%%%%%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%/..
//      .,/%&%%%%%%@#(&%&%%%%%%%%%#&&%%##%#%%%#%%%%&&&%%%%%%%%###%%%%%&&&%%%%%%%%%%%%%%%%&(//%%/
//          ,..     .(%%%%##%%%#%%%%%%#%%%%%##%%%%%&&&&%%%%%%%#&%#%%%%%%&&&%%%%%##//  ,,.
//            .,(%#%%##%%%#%%%#%%%#%%*,.*%%%%%%%%%&.,/&%%%%%%% #&%%#%%%%%&%(&%((%&&&(*
//                        ,/#/(%%,    ,&%%#%/.//         %*&(%#    .(,(%%%.

pragma solidity 0.6.12;

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

// File: contracts/libs/ECDSA.sol

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// File: contracts/interfaces/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/libs/Fabric.sol

/**
 * @title Fabric
 * @dev Create deterministics vaults.
 *
 * Original work by Pine.Finance
 * - https://github.com/pine-finance
 *
 * Authors:
 * - Agustin Aguilar <agusx1211>
 * - Ignacio Mazzara <nachomazzara>
 */
library Fabric {
    /*Vault bytecode

        def _fallback() payable:
            call cd[56] with:
                funct call.data[0 len 4]
                gas cd[56] wei
                args call.data[4 len 64]
            selfdestruct(tx.origin)

        // Constructor bytecode
        0x6012600081600A8239f3

        0x60 12 - PUSH1 12           // Size of the contract to return
        0x60 00 - PUSH1 00           // Memory offset to return stored code
        0x81    - DUP2  12           // Size of code to copy
        0x60 0a - PUSH1 0A           // Start of the code to copy
        0x82    - DUP3  00           // Dest memory for code copy
        0x39    - CODECOPY 00 0A 12  // Code copy to memory
        0xf3    - RETURN 00 12       // Return code to store

        // Deployed contract bytecode
        0x60008060448082803781806038355AF132FF

        0x60 00 - PUSH1 00                    // Size for the call output
        0x80    - DUP1  00                    // Offset for the call output
        0x60 44 - PUSH1 44                    // Size for the call input
        0x80    - DUP1  44                    // Size for copying calldata to memory
        0x82    - DUP3  00                    // Offset for calldata copy
        0x80    - DUP1  00                    // Offset for destination of calldata copy
        0x37    - CALLDATACOPY 00 00 44       // Execute calldata copy, is going to be used for next call
        0x81    - DUP2  00                    // Offset for call input
        0x80    - DUP1  00                    // Amount of ETH to send during call
        0x60 38 - PUSH1 38                    // calldata pointer to load value into stack
        0x35    - CALLDATALOAD 38 (A)         // Load value (A), address to call
        0x5a    - GAS                         // Remaining gas
        0xf1    - CALL (A) (A) 00 00 44 00 00 // Execute call to address (A) with calldata mem[0:64]
        0x32    - ORIGIN (B)                  // Dest funds for selfdestruct
        0xff    - SELFDESTRUCT (B)            // selfdestruct contract, end of execution
    */
    bytes public constant code =
        hex"6012600081600A8239F360008060448082803781806038355AF132FF";
    bytes32 public constant vaultCodeHash =
        bytes32(
            0xfa3da1081bc86587310fce8f3a5309785fc567b9b20875900cb289302d6bfa97
        );

    /**
     * @dev Get a deterministics vault.
     */
    function getVault(bytes32 _key) internal view returns (address) {
        return
            address(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            _key,
                            vaultCodeHash
                        )
                    )
                )
            );
    }

    /**
     * @dev Create deterministic vault.
     */
    function executeVault(
        bytes32 _key,
        IERC20 _token,
        address _to
    ) internal returns (uint256 value) {
        address addr;
        bytes memory slotcode = code;

        /* solium-disable-next-line */
        assembly {
            // Create the contract arguments for the constructor
            addr := create2(0, add(slotcode, 0x20), mload(slotcode), _key)
        }

        value = _token.balanceOf(addr);
        /* solium-disable-next-line */
        (bool success, ) =
            addr.call(
                abi.encodePacked(
                    abi.encodeWithSelector(
                        _token.transfer.selector,
                        _to,
                        value
                    ),
                    address(_token)
                )
            );

        require(success, "Error pulling tokens");
    }
}

// File: contracts/interfaces/IModule.sol

/**
 * Original work by Pine.Finance
 * - https://github.com/pine-finance
 *
 * Authors:
 * - Ignacio Mazzara <nachomazzara>
 * - Agustin Aguilar <agusx1211>
 */
interface IModule {
    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Executes an order
     * @param _inputToken - Address of the input token
     * @param _inputAmount - uint256 of the input token amount (order amount)
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bought - amount of output token bought
     */
    function execute(
        IERC20 _inputToken,
        uint256 _inputAmount,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _auxData
    ) external returns (uint256 bought);

    /**
     * @notice Check whether an order can be executed or not
     * @param _inputToken - Address of the input token
     * @param _inputAmount - uint256 of the input token amount (order amount)
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bool - whether the order can be executed or not
     */
    function canExecute(
        IERC20 _inputToken,
        uint256 _inputAmount,
        bytes calldata _data,
        bytes calldata _auxData
    ) external view returns (bool);
}

// File: contracts/commons/Order.sol

contract Order {
    address public constant ETH_ADDRESS =
        address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
}

// File: contracts/PineCore.sol

/**
 * Original work by Pine.Finance
 * - https://github.com/pine-finance
 *
 * Authors:
 * - Ignacio Mazzara <nachomazzara>
 * - Agustin Aguilar <agusx1211>
 */
abstract contract PineCore is Order {
    using SafeMath for uint256;
    using Fabric for bytes32;

    // ETH orders
    mapping(bytes32 => uint256) public ethDeposits;

    // Events
    event DepositETH(
        bytes32 indexed _key,
        address indexed _caller,
        uint256 _amount,
        bytes _data
    );

    event OrderExecuted(
        bytes32 indexed _key,
        address _inputToken,
        address _owner,
        address _witness,
        bytes _data,
        bytes _auxData,
        uint256 _amount,
        uint256 _bought
    );

    event OrderCancelled(
        bytes32 indexed _key,
        address _inputToken,
        address _owner,
        address _witness,
        bytes _data,
        uint256 _amount
    );

    /**
     * @dev Prevent users to send Ether directly to this contract
     */
    receive() external payable {
        require(
            msg.sender != tx.origin,
            "PineCore#receive: NO_SEND_ETH_PLEASE"
        );
    }

    /**
     * @notice Create an ETH to token order
     * @param _data - Bytes of an ETH to token order. See `encodeEthOrder` for more info
     */
    function depositEth(bytes calldata _data) external payable {
        require(msg.value > 0, "PineCore#depositEth: VALUE_IS_0");

        (
            address module,
            address inputToken,
            address payable owner,
            address witness,
            bytes memory data,

        ) = decodeOrder(_data);

        require(
            inputToken == ETH_ADDRESS,
            "PineCore#depositEth: WRONG_INPUT_TOKEN"
        );

        bytes32 key =
            keyOf(
                IModule(uint160(module)),
                IERC20(inputToken),
                owner,
                witness,
                data
            );

        ethDeposits[key] = ethDeposits[key].add(msg.value);
        emit DepositETH(key, msg.sender, msg.value, _data);
    }

    /**
     * @notice Cancel order
     * @dev The params should be the same used for the order creation
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     */
    function cancelOrder(
        IModule _module,
        IERC20 _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external {
        require(msg.sender == _owner, "PineCore#cancelOrder: INVALID_OWNER");
        bytes32 key = keyOf(_module, _inputToken, _owner, _witness, _data);

        uint256 amount = _pullOrder(_inputToken, key, msg.sender);

        emit OrderCancelled(
            key,
            address(_inputToken),
            _owner,
            _witness,
            _data,
            amount
        );
    }

    /**
     * @notice Get the calldata needed to create a token to token/ETH order
     * @dev Returns the input data that the user needs to use to create the order
     * The _secret is used to prevent a front-running at the order execution
     * The _amount is used as the param `_value` for the ERC20 `transfer` function
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @param _secret - Private key of the _witness
     * @param _amount - uint256 of the order amount
     * @return bytes - input data to send the transaction
     */
    function encodeTokenOrder(
        IModule _module,
        IERC20 _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data,
        bytes32 _secret,
        uint256 _amount
    ) external view returns (bytes memory) {
        return
            abi.encodeWithSelector(
                _inputToken.transfer.selector,
                vaultOfOrder(_module, _inputToken, _owner, _witness, _data),
                _amount,
                abi.encode(
                    _module,
                    _inputToken,
                    _owner,
                    _witness,
                    _data,
                    _secret
                )
            );
    }

    /**
     * @notice Get the calldata needed to create a ETH to token order
     * @dev Returns the input data that the user needs to use to create the order
     * The _secret is used to prevent a front-running at the order execution
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @param _secret -  Private key of the _witness
     * @return bytes - input data to send the transaction
     */
    function encodeEthOrder(
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data,
        bytes32 _secret
    ) external pure returns (bytes memory) {
        return
            abi.encode(_module, _inputToken, _owner, _witness, _data, _secret);
    }

    /**
     * @notice Get order's properties
     * @param _data - Bytes of the order
     * @return module - Address of the module to use for the order execution
     * @return inputToken - Address of the input token
     * @return owner - Address of the order's owner
     * @return witness - Address of the witness
     * @return data - Bytes of the order's data
     * @return secret -  Private key of the _witness
     */
    function decodeOrder(bytes memory _data)
        public
        pure
        returns (
            address module,
            address inputToken,
            address payable owner,
            address witness,
            bytes memory data,
            bytes32 secret
        )
    {
        (module, inputToken, owner, witness, data, secret) = abi.decode(
            _data,
            (address, address, address, address, bytes, bytes32)
        );
    }

    /**
     * @notice Get the vault's address of a token to token/ETH order
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @return address - The address of the vault
     */
    function vaultOfOrder(
        IModule _module,
        IERC20 _inputToken,
        address payable _owner,
        address _witness,
        bytes memory _data
    ) public view returns (address) {
        return keyOf(_module, _inputToken, _owner, _witness, _data).getVault();
    }

    /**
     * @notice Executes an order
     * @dev The sender should use the _secret to sign its own address
     * to prevent front-runnings
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @param _signature - Signature to calculate the witness
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     */
    function executeOrder(
        IModule _module,
        IERC20 _inputToken,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _signature,
        bytes calldata _auxData
    ) public virtual {
        // Calculate witness using signature
        address witness =
            ECDSA.recover(keccak256(abi.encodePacked(msg.sender)), _signature);

        bytes32 key = keyOf(_module, _inputToken, _owner, witness, _data);

        // Pull amount
        uint256 amount = _pullOrder(_inputToken, key, address(_module));
        require(amount > 0, "PineCore#executeOrder: INVALID_ORDER");

        uint256 bought =
            _module.execute(_inputToken, amount, _owner, _data, _auxData);

        emit OrderExecuted(
            key,
            address(_inputToken),
            _owner,
            witness,
            _data,
            _auxData,
            amount,
            bought
        );
    }

    /**
     * @notice Check whether an order exists or not
     * @dev Check the balance of the order
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @return bool - whether the order exists or not
     */
    function existOrder(
        IModule _module,
        IERC20 _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external view returns (bool) {
        bytes32 key = keyOf(_module, _inputToken, _owner, _witness, _data);

        if (address(_inputToken) == ETH_ADDRESS) {
            return ethDeposits[key] != 0;
        } else {
            return _inputToken.balanceOf(key.getVault()) != 0;
        }
    }

    /**
     * @notice Check whether an order can be executed or not
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bool - whether the order can be executed or not
     */
    function canExecuteOrder(
        IModule _module,
        IERC20 _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data,
        bytes calldata _auxData
    ) external view returns (bool) {
        bytes32 key = keyOf(_module, _inputToken, _owner, _witness, _data);

        // Pull amount
        uint256 amount;
        if (address(_inputToken) == ETH_ADDRESS) {
            amount = ethDeposits[key];
        } else {
            amount = _inputToken.balanceOf(key.getVault());
        }

        return _module.canExecute(_inputToken, amount, _data, _auxData);
    }

    /**
     * @notice Transfer the order amount to a recipient.
     * @dev For an ETH order, the ETH will be transferred from this contract
     * For a token order, its vault will be executed transferring the amount of tokens to
     * the recipient
     * @param _inputToken - Address of the input token
     * @param _key - Order's key
     * @param _to - Address of the recipient
     * @return amount - amount transferred
     */
    function _pullOrder(
        IERC20 _inputToken,
        bytes32 _key,
        address payable _to
    ) private returns (uint256 amount) {
        if (address(_inputToken) == ETH_ADDRESS) {
            amount = ethDeposits[_key];
            ethDeposits[_key] = 0;
            (bool success, ) = _to.call{value: amount}("");
            require(success, "PineCore#_pullOrder: PULL_ETHER_FAILED");
        } else {
            amount = _key.executeVault(_inputToken, _to);
        }
    }

    /**
     * @notice Get the order's key
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @return bytes32 - order's key
     */
    function keyOf(
        IModule _module,
        IERC20 _inputToken,
        address payable _owner,
        address _witness,
        bytes memory _data
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(_module, _inputToken, _owner, _witness, _data)
            );
    }
}

