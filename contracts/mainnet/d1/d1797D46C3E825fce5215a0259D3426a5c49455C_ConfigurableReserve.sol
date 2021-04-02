// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IConfigurableReserve.sol";
import "./IPrizePool.sol";

/// @title Implementation of IConfigurable reserve
/// @notice Provides an Ownable configurable reserve for prize pools. This includes an opt-out default rate for prize pools. 
/// For flexibility this includes a specified withdraw Strategist address which can be set by the owner.
/// The prize pool Reserve can withdrawn by the owner or the reserve strategist. 
contract ConfigurableReserve is IConfigurableReserve, Ownable {
    
    /// @notice Storage of Reserve Rate Mantissa associated with a Prize Pool
    mapping(address => ReserveRate) public prizePoolMantissas;

    /// @notice Storage of the address of a withdrawal strategist 
    address public withdrawStrategist;

    /// @notice Storage of the default rate mantissa
    uint224 public defaultReserveRateMantissa;

    constructor() Ownable(){

    }

    /// @notice Returns the reserve rate for a particular source
    /// @param source The source for which the reserve rate should be return.  These are normally prize pools.
    /// @return The reserve rate as a fixed point 18 number, like Ether.  A rate of 0.05 = 50000000000000000
    function reserveRateMantissa(address source) external override view returns (uint256){
        if(!prizePoolMantissas[source].useCustom){
            return uint256(defaultReserveRateMantissa);
        }
        // else return the custom rate
        return prizePoolMantissas[source].rateMantissa;
    }

    /// @notice Allows the owner of the contract to set the reserve rates for a given set of sources.
    /// @dev Length must match sources param.
    /// @param sources The sources for which to set the reserve rates.
    /// @param _reserveRates The respective ReserveRates for the sources.  
    function setReserveRateMantissa(address[] calldata sources,  uint224[] calldata _reserveRates, bool[] calldata useCustom) external override onlyOwner{
        for(uint256 i = 0; i <  sources.length; i++){
            prizePoolMantissas[sources[i]].rateMantissa = _reserveRates[i];
            prizePoolMantissas[sources[i]].useCustom = useCustom[i];
            emit ReserveRateMantissaSet(sources[i], _reserveRates[i], useCustom[i]);
        }
    }

    /// @notice Allows the owner of the contract to set the withdrawal strategy address
    /// @param _strategist The new withdrawal strategist address
    function setWithdrawStrategist(address _strategist) external override onlyOwner{
        withdrawStrategist = _strategist;
        emit ReserveWithdrawStrategistChanged(_strategist);
    }

    /// @notice Calls withdrawReserve on the Prize Pool
    /// @param prizePool The Prize Pool to withdraw reserve
    /// @param to The reserve transfer destination address
    /// @return The amount of reserve withdrawn from the prize pool
    function withdrawReserve(address prizePool, address to) external override onlyOwnerOrWithdrawStrategist returns (uint256){
        return PrizePoolInterface(prizePool).withdrawReserve(to);
    }

    /// @notice Sets the default ReserveRate mantissa
    /// @param _reserveRateMantissa The new default reserve rate mantissa
    function setDefaultReserveRateMantissa(uint224 _reserveRateMantissa) external override onlyOwner{
        defaultReserveRateMantissa = _reserveRateMantissa;
        emit DefaultReserveRateMantissaSet(_reserveRateMantissa);
    }

    /// @notice Only allows the owner or current strategist to call a function
    modifier onlyOwnerOrWithdrawStrategist(){
        require(msg.sender == owner() || msg.sender == withdrawStrategist, "!onlyOwnerOrWithdrawStrategist");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface IConfigurableReserve {
  
  ///@notice struct to store the reserve rate mantissa for an address and a flag to indicate to use the default reserve rate
  struct ReserveRate{
      uint224 rateMantissa;
      bool useCustom;
  }

  /// @notice Returns the reserve rate for a particular source
  /// @param source The source for which the reserve rate should be return.  These are normally prize pools.
  /// @return The reserve rate as a fixed point 18 number, like Ether.  A rate of 0.05 = 50000000000000000
  function reserveRateMantissa(address source) external view returns (uint256);

  /// @notice Allows the owner of the contract to set the reserve rates for a given set of sources.
  /// @dev Length must match sources param.
  /// @param sources The sources for which to set the reserve rates.
  /// @param _reserveRates The respective ReserveRates for the sources.  
  function setReserveRateMantissa(address[] calldata sources,  uint224[] calldata _reserveRates, bool[] calldata useCustom) external;

  /// @notice Allows the owner of the contract to set the withdrawal strategy address
  /// @param strategist The new withdrawal strategist address
  function setWithdrawStrategist(address strategist) external;

  /// @notice Calls withdrawReserve on the Prize Pool
  /// @param prizePool The Prize Pool to withdraw reserve
  /// @param to The reserve transfer destination address
  function withdrawReserve(address prizePool, address to) external returns (uint256);

  /// @notice Sets the default ReserveRate mantissa
  /// @param _reserveRateMantissa The new default reserve rate mantissa
  function setDefaultReserveRateMantissa(uint224 _reserveRateMantissa) external;
  
  /// @notice Emitted when the reserve rate mantissa was updated for a prize pool
  /// @param prizePool The prize pool address for which the rate was set
  /// @param reserveRateMantissa The respective reserve rate for the prizepool.
  /// @param useCustom Whether to use the custom reserve rate (true) or the default (false)
  event ReserveRateMantissaSet(address indexed prizePool, uint256 reserveRateMantissa, bool useCustom);

  /// @notice Emitted when the withdraw strategist is changed
  /// @param strategist The updated strategist address
  event ReserveWithdrawStrategistChanged(address indexed strategist);

  /// @notice Emitted when the default reserve rate mantissa was updated
  /// @param rate The new updated default mantissa rate
  event DefaultReserveRateMantissaSet(uint256 rate);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

/// @title Escrows assets and deposits them into a yield source.  Exposes interest to Prize Strategy.  Users deposit and withdraw from this contract to participate in Prize Pool.
/// @notice Accounting is managed using Controlled Tokens, whose mint and burn functions can only be called by this contract.
/// @dev Must be inherited to provide specific yield-bearing asset control, such as Compound cTokens
interface PrizePoolInterface {
    function withdrawReserve(address to) external returns (uint256);
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