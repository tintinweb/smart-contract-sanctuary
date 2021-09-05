/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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
    constructor() {
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
}


contract yakuSwap is Ownable {

  // Uninitialized - Default status (if swaps[index] doesn't exist, status will get this value)
  // Created - the swap was created, but the mone is still in the contract
  // Completed - the money has been sent to 'toAddress' (swap successful)
  // Cancelled - the money has been sent to 'fromAddress' (maxBlockHeight was reached)
  enum SwapStatus { Uninitialized, Created, Completed, Cancelled }

  struct Swap {
    SwapStatus status;
    uint startBlock;
    uint amount;
    bytes32 secretHash;
    address fromAddress;
    address toAddress;
    uint16 maxBlockHeight;
  }

  mapping (bytes32 => Swap) public swaps;
  uint public totalFees = 0;

  event SwapCompleted(bytes32 indexed _swapId, string _secret);

  function getSwapId(bytes32 secretHash, address fromAddress) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      secretHash,
      fromAddress
    ));
  }

  function createSwap(bytes32 _secretHash, address _toAddress, uint16 _maxBlockHeight) payable public {
    require(msg.value >= 1000);
    require(_maxBlockHeight > 10);
    require(_toAddress != address(0) && msg.sender != address(0));

    bytes32 swapId = getSwapId(_secretHash, msg.sender);
    require(swaps[swapId].status == SwapStatus.Uninitialized);
    
    uint swapAmount = msg.value / 1000 * 993;
    Swap memory newSwap = Swap(
      SwapStatus.Created,
      block.number,
      swapAmount,
      _secretHash,
      msg.sender,
      _toAddress,
      _maxBlockHeight
    );

    swaps[swapId] = newSwap;
    totalFees += msg.value - newSwap.amount;
  }

  function completeSwap(bytes32 _swapId, string memory _secret) public {
    Swap storage swap = swaps[_swapId];

    require(swap.status == SwapStatus.Created);
    require(block.number < swap.startBlock + swap.maxBlockHeight);
    require(swap.secretHash == sha256(abi.encodePacked(_secret)));

    swap.status = SwapStatus.Completed;
    emit SwapCompleted(_swapId, _secret);
    (bool success,) = swap.toAddress.call{value: swap.amount}("");

    require(success);
  }

  function cancelSwap(bytes32 _swapId) public {
    Swap storage swap = swaps[_swapId];

    require(swap.status == SwapStatus.Created);
    require(block.number >= swap.startBlock + swap.maxBlockHeight);

    swap.status = SwapStatus.Cancelled;
    (bool success,) = swap.fromAddress.call{value: swap.amount}("");

    require(success);
  }

  function getFees() public onlyOwner {
    totalFees = 0;
    (bool success,) = owner().call{value: totalFees}("");
    
    require(success);
  }
}