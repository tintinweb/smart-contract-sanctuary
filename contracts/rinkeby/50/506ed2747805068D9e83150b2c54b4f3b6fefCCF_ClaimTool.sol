// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IClaimable.sol";

contract ClaimTool is Ownable {

    IClaimable public lottery;
    IClaimable public swapMining;
    IClaimable public tradeMining;


    constructor(
        address _lottery,
        address _swapMining,
        address _tradeMining
    ) public {
        lottery = IClaimable(_lottery);
        swapMining = IClaimable(_swapMining);
        tradeMining = IClaimable(_tradeMining);
        
    }


    function setLottery(address _newAddress) public onlyOwner {
        lottery = IClaimable(_newAddress);
    }


    function setSwapMining(address _newAddress) public onlyOwner {
        swapMining = IClaimable(_newAddress);
    }


    function setTradeMining(address _newAddress) public onlyOwner {
        tradeMining = IClaimable(_newAddress);
    }

    function _pending(IClaimable claimable, address user, uint256 startCycle, uint256 endCycle) internal view returns (uint256) {
        uint amount = 0;
        for (uint256 cycleNum = startCycle; cycleNum <= endCycle; cycleNum ++) {
            amount += claimable.pending(user, cycleNum);
        }
        return amount;
    }

    function pendingLottery(address user, uint256 startCycle, uint256 endCycle) external view returns (uint256) {
        if (address(lottery) != address(0)) {
            return _pending(lottery, user, startCycle, endCycle);
        }
        return 0; 
    }

    function pendingSwapMining(address user, uint256 startCycle, uint256 endCycle) external view returns (uint256) {
        if (address(swapMining) != address(0)) {
            return _pending(swapMining, user, startCycle, endCycle);
        }
        return 0; 
    }

    function pendingTradeMining(address user, uint256 startCycle, uint256 endCycle) external view returns (uint256) {
        if (address(tradeMining) != address(0)) {
            return _pending(tradeMining, user, startCycle, endCycle);
        }
        return 0; 
    }

    function claimAll(address user, uint256 startCycle, uint256 endCycle) external {
        if (address(lottery) != address(0)) {
            lottery.claim(user, startCycle, endCycle);
        }
        if (address(swapMining) != address(0)) {
            swapMining.claim(user, startCycle, endCycle);
        }

        if (address(tradeMining) != address(0)) {
            tradeMining.claim(user, startCycle, endCycle);
        }
    }
}

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
pragma solidity ^0.6.12;

interface IClaimable {
      function claim(address user, uint256 startCycle, uint256 endCycle) external;
      function pending(address user, uint256 cycleNum) external view returns (uint256);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}