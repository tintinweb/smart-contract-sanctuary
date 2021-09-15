pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../../contracts/external/IMedianizer.sol";

/// @title A mock implementation of a medianizer price oracle.
/// @dev This is used in the Keep testnets only. Mainnet uses the MakerDAO medianizer.
contract MockMedianizer is Ownable, IMedianizer {
    uint256 private value;

    constructor() public {
    // solium-disable-previous-line no-empty-blocks
    }

    function read() external view returns (uint256) {
        return value;
    }

    function peek() external view returns (uint256, bool) {
        return (value, value > 0);
    }

    function setValue(uint256 _value) external onlyOwner{
        value = _value;
    }
}

contract ETHBTCPriceFeedMock is MockMedianizer {
    // solium-disable-previous-line no-empty-blocks
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.5.17;

/// @notice A medianizer price feed.
/// @dev Based off the MakerDAO medianizer (https://github.com/makerdao/median)
interface IMedianizer {
    /// @notice Get the current price.
    /// @dev May revert if caller not whitelisted.
    /// @return Designated price with 18 decimal places.
    function read() external view returns (uint256);

    /// @notice Get the current price and check if the price feed is active
    /// @dev May revert if caller not whitelisted.
    /// @return Designated price with 18 decimal places.
    /// @return true if price is > 0, else returns false
    function peek() external view returns (uint256, bool);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
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