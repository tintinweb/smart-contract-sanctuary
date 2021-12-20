/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: Keeper.sol


pragma solidity ^0.8.0;

// Farmageddon Lottery Keeper Automation 

// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol



interface Token{
    function updateFee(uint256 _txFee,uint256 _burnFee,uint256 _charityFee)  external;
	function transferOwnership(address newOwner) external;	 
    function excludeAccount(address account) external;
    function includeAccount(address account) external;
	}



contract FGKeeper is KeeperCompatibleInterface, Ownable {
    // Setup Variables
        
        uint256 public step;
        uint256 public upKeepTime;

    // assign token    
    Token public TokenAddress;

    function ExcludeAccount(address _Account) external onlyOwner {
        TokenAddress.excludeAccount(_Account);
    }

    function IncludeAccount(address _Account) external onlyOwner {
        TokenAddress.includeAccount(_Account);
    }

    function SetTokenAddress(address _lotteryAddress) external onlyOwner {
        TokenAddress = Token(_lotteryAddress);
    }

    function _setTimeToStartAndStart(uint256 _TimeToStart) external onlyOwner {
        require(step == 0, "Already Started");
        upKeepTime = _TimeToStart;
        step = 1;
    }

    function _pauseKeeperAndPutTaxesToNormal() external onlyOwner {
        step = 0;
    }
 
    function _changeOwnershipOfTokenAndStopKeeper(address _NewOwner) external onlyOwner {
        TokenAddress.transferOwnership(_NewOwner);
        step = 0;
    }

    
    function checkUpkeep(bytes calldata) view external override returns (bool upkeepNeeded, bytes memory) {
        // perform upkeep when timestamp is equal or more than upkeepTime
        upkeepNeeded = block.timestamp >= upKeepTime && step > 0;
    }

    // Perform Tax changes
    function performUpkeep(bytes calldata /* performData */) external override {
        if (step == 1) {
             // tax free day
            TokenAddress.updateFee(0, 0, 0);
            step = 2;
            upKeepTime += 86400;
            
        }
       
        else if (step == 2) {
             // Appreciation day
            TokenAddress.updateFee(3, 0, 0);
            step = 3;
            upKeepTime += 86400;
        }

        else if (step == 3) {
            // Burn day
            TokenAddress.updateFee(0, 3, 0);
            step = 4;
            upKeepTime += 86400;
        }  

        else if (step == 4) {
            // Burn day
            TokenAddress.updateFee(1, 1, 1);
            step = 1;
            upKeepTime += 345600;
        }  

    }

    // Function to manually change taxes
    function manualUpkeep() external onlyOwner {
         if (step == 1) {
             // tax free day
            TokenAddress.updateFee(0, 0, 0);
            step = 2;
            upKeepTime += 86400;
            
        }
       
        else if (step == 2) {
             // Appreciation day
            TokenAddress.updateFee(3, 0, 0);
            step = 3;
            upKeepTime += 86400;
        }

        else if (step == 3) {
            // Burn day
            TokenAddress.updateFee(0, 3, 0);
            step = 4;
            upKeepTime += 86400;
        }  

        else if (step == 4) {
            // Burn day
            TokenAddress.updateFee(1, 1, 1);
            step = 1;
            upKeepTime += 345600;
        }  

    }
}