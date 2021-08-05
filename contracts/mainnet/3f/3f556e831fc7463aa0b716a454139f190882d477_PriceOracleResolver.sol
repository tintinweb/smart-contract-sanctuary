// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import {Ownable} from "../../vendor/Ownable.sol";
import {GelatoBytes} from "../../lib/GelatoBytes.sol";

/// @title PriceOracleResolver
/// @notice Contract with convenience methods to retrieve oracle addresses or to mock test.
/// @dev Can be used to:
///  - Query oracle address for Gelato Condition payloads on frontend
///  - Test Conditions by using `getMockPrice(address _test)` as `oraclePayload`
contract PriceOracleResolver is Ownable {
    using GelatoBytes for bytes;

    mapping(string => address) public oracle;
    mapping(string => bytes) public oraclePayload;
    mapping(address => uint256) public mockPrice;

    /// @notice Adds a new Oracle address
    /// @dev Only owner can call this, but existing oracle entries are immutable
    /// @param _oracle The descriptor of the oracle e.g. ETH/USD-Maker-v1
    /// @param _oracleAddress The address of the oracle contract
    /// @param _oraclePayload The payload with function selector for the oracle request.
    function addOracle(
        string memory _oracle,
        address _oracleAddress,
        bytes calldata _oraclePayload
    ) external onlyOwner {
        require(
            oracle[_oracle] == address(0),
            "PriceOracleResolver.addOracle: set"
        );
        oracle[_oracle] = _oracleAddress;
        oraclePayload[_oracle] = _oraclePayload;
    }

    /// @notice Function that allows easy oracle data testing in production.
    /// @dev Your mock prices cannot be overriden by someone else.
    /// @param _mockPrice The mock data you want to test against.
    function setMockPrice(uint256 _mockPrice) public {
        mockPrice[msg.sender] = _mockPrice;
    }

    /// @notice Use with setMockPrice for easy testing in production.
    /// @dev Encode oracle=PriceOracleResolver and oraclePayload=getMockPrice(tester)
    ///  to test your Conditions or Actions that make dynamic calls to price oracles.
    /// @param _tester The msg.sender during setMockPrice.
    /// @return The tester's mockPrice.
    function getMockPrice(address _tester) external view returns (uint256) {
        return mockPrice[_tester];
    }

    /// @notice A generelized getter for a price supplied by an oracle contract.
    /// @dev The oracle returndata must be formatted as a single uint256.
    /// @param _oracle The descriptor of our oracle e.g. ETH/USD-Maker-v1
    /// @return The uint256 oracle price
    function getPrice(string memory _oracle) external view returns (uint256) {
        address oracleAddr = oracle[_oracle];
        if (oracleAddr == address(0))
            revert("PriceOracleResolver.getPrice: no oracle");
        (bool success, bytes memory returndata) = oracleAddr.staticcall(
            oraclePayload[_oracle]
        );
        if (!success)
            returndata.revertWithError("PriceOracleResolver.getPrice:");
        return abi.decode(returndata, (uint256));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.7.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}