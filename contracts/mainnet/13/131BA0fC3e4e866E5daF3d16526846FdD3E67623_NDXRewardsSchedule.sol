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
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRewardsSchedule.sol";


/**
 * @dev Rewards schedule that distributes 1,500,000 tokens over two years using a linear
 * decay that distributes roughly 1.7 tokens in the first block for every 0.3 tokens in the
 * last block.
 *
 * A value of 13.2 seconds was selected as the average block time to set 4778182 as the number
 * of blocks in 2 years. This has been a stable block time for roughly a year at the time of
 * writing.
 */
contract NDXRewardsSchedule is Ownable, IRewardsSchedule {
  uint256 public immutable override startBlock;
  uint256 public override endBlock;

  constructor(uint256 startBlock_) public Ownable() {
    startBlock = startBlock_;
    endBlock = startBlock_ + 4778181;
  }

  /**
   * @dev Set an early end block for rewards.
   * Note: This can only be called once.
   */
  function setEarlyEndBlock(uint256 earlyEndBlock) external override onlyOwner {
    uint256 endBlock_ = endBlock;
    require(endBlock_ == startBlock + 4778181, "Early end block already set");
    require(earlyEndBlock > block.number && earlyEndBlock > startBlock, "End block too early");
    require(earlyEndBlock < endBlock_, "End block too late");
    endBlock = earlyEndBlock;
    emit EarlyEndBlockSet(earlyEndBlock);
  }

  function getRewardsForBlockRange(uint256 from, uint256 to) external view override returns (uint256) {
    require(to >= from, "Bad block range");
    uint256 endBlock_ = endBlock;
    // If queried range is entirely outside of reward blocks, return 0
    if (from >= endBlock_ || to <= startBlock) return 0;

    // Use start/end values where from/to are OOB
    if (to > endBlock_) to = endBlock_;
    if (from < startBlock) from = startBlock;

    uint256 x = from - startBlock;
    uint256 y = to - startBlock;

    // This formula is the definite integral of the following function:
    // rewards(b) = 0.5336757788 - 0.00000009198010879*b; b >= 0; b < 4778182
    // where b is the block number offset from {startBlock} and the output is multiplied by 1e18.
    return (45990054395 * x**2)
      + (5336757788e8 * (y - x))
      - (45990054395 * y**2);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IRewardsSchedule {
  event EarlyEndBlockSet(uint256 earlyEndBlock);

  function startBlock() external view returns (uint256);
  function endBlock() external view returns (uint256);
  function getRewardsForBlockRange(uint256 from, uint256 to) external view returns (uint256);
  function setEarlyEndBlock(uint256 earlyEndBlock) external;
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
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