// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ISystemParameters.sol";

import "./libraries/PureParameters.sol";

import "./common/Globals.sol";

contract SystemParameters is Ownable, ISystemParameters {
    using PureParameters for PureParameters.Param;

    address private _registryAddr;

    bytes32 public constant LIQUIDATION_BOUNDARY_KEY = keccak256("LIQUIDATION_BOUNDARY");

    mapping(bytes32 => PureParameters.Param) private _parameters;

    constructor(address registryAddr_) Ownable() {
        _registryAddr = registryAddr_;
    }

    function getLiquidationBoundaryParam() external view override returns (uint256) {
        return _getParam(LIQUIDATION_BOUNDARY_KEY).getUintFromParam();
    }

    function setupLiquidationBoundary(uint256 _newValue) external onlyOwner {
        require(
            _newValue >= ONE_PERCENT * 50 && _newValue <= ONE_PERCENT * 80,
            "SystemParameters: The new value of the liquidation boundary is invalid."
        );

        _parameters[LIQUIDATION_BOUNDARY_KEY] = PureParameters.makeUintParam(_newValue);

        emit UintParamUpdated(LIQUIDATION_BOUNDARY_KEY, _newValue);
    }

    function _getParam(bytes32 _paramKey) internal view returns (PureParameters.Param memory) {
        require(
            PureParameters.paramExists(_parameters[_paramKey]),
            "SystemParameters: Param for this key doesn't exist."
        );

        return _parameters[_paramKey];
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

uint256 constant ONE_PERCENT = 10**25;
uint256 constant DECIMAL = ONE_PERCENT * 100;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint8 constant PRICE_DECIMALS = 8;

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ISystemParameters {
    event UintParamUpdated(bytes32 _paramKey, uint256 _newValue);

    /**
     * @notice Getter for parameter by key LIQUIDATION_BOUNDARY_KEY
     * @return current liquidation boundary parameter value
     */
    function getLiquidationBoundaryParam() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

library PureParameters {
    enum Types {NOT_EXIST, UINT, ADDRESS, BYTES32, BOOL}

    struct Param {
        uint256 uintParam;
        address addressParam;
        bytes32 bytes32Param;
        bool boolParam;
        Types currentType;
    }

    function makeUintParam(uint256 _num) internal pure returns (Param memory) {
        return
            Param({
                uintParam: _num,
                currentType: Types.UINT,
                addressParam: address(0),
                bytes32Param: bytes32(0),
                boolParam: false
            });
    }

    function getUintFromParam(Param memory _param) internal pure returns (uint256) {
        require(_param.currentType == Types.UINT, "PureParameters: Parameter not contain uint.");

        return _param.uintParam;
    }

    function makeAdrressParam(address _address) internal pure returns (Param memory) {
        return
            Param({
                addressParam: _address,
                currentType: Types.ADDRESS,
                uintParam: uint256(0),
                bytes32Param: bytes32(0),
                boolParam: false
            });
    }

    function getAdrressFromParam(Param memory _param) internal pure returns (address) {
        require(
            _param.currentType == Types.ADDRESS,
            "PureParameters: Parameter not contain address."
        );

        return _param.addressParam;
    }

    function makeBytes32Param(bytes32 _hash) internal pure returns (Param memory) {
        return
            Param({
                bytes32Param: _hash,
                currentType: Types.BYTES32,
                addressParam: address(0),
                uintParam: uint256(0),
                boolParam: false
            });
    }

    function getBytes32FromParam(Param memory _param) internal pure returns (bytes32) {
        require(
            _param.currentType == Types.BYTES32,
            "PureParameters: Parameter not contain bytes32."
        );

        return _param.bytes32Param;
    }

    function makeBoolParam(bool _bool) internal pure returns (Param memory) {
        return
            Param({
                boolParam: _bool,
                currentType: Types.BOOL,
                addressParam: address(0),
                uintParam: uint256(0),
                bytes32Param: bytes32(0)
            });
    }

    function getBoolFromParam(Param memory _param) internal pure returns (bool) {
        require(_param.currentType == Types.BOOL, "PureParameters: Parameter not contain bool.");

        return _param.boolParam;
    }

    function paramExists(Param memory _param) internal pure returns (bool) {
        return (_param.currentType != Types.NOT_EXIST);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "evmVersion": "istanbul",
  "libraries": {},
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