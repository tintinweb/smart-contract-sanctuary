// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


import "./interfaces/KeeperCompatibleInterface.sol";
import "./interfaces/PeriodicPrizeStrategyInterface.sol";
import "./interfaces/PrizePoolRegistryInterface.sol";
import "./interfaces/PrizePoolInterface.sol";
import "./utils/SafeAwardable.sol";


///@notice Contract implements Chainlink's Upkeep system interface, automating the upkeep of PrizePools in the associated registry. 
contract PrizeStrategyUpkeep is KeeperCompatibleInterface {

    using SafeAwardable for address;

    address public prizePoolRegistry;

    uint public upkeepBatchSize;
    
    constructor(address _prizePoolRegistry, uint256 _upkeepBatchSize) public {
        prizePoolRegistry = _prizePoolRegistry;
        upkeepBatchSize = _upkeepBatchSize;
    }

    /// @notice Checks if PrizePools require upkeep. Call in a static manner every block by the Chainlink Upkeep network.
    /// @param checkData Not used in this implementation.
    /// @return upkeepNeeded as true if performUpkeep() needs to be called, false otherwise. performData returned empty. 
    function checkUpkeep(bytes calldata checkData) view override external returns (bool upkeepNeeded, bytes memory performData){ // check view

        address[] memory prizePools = PrizePoolRegistryInterface(prizePoolRegistry).getPrizePools();

        // check if canStartAward()
        for(uint256 pool = 0; pool < prizePools.length; pool++){
            address prizeStrategy = PrizePoolInterface(prizePools[pool]).prizeStrategy();
            if(prizeStrategy.canStartAward()){
                return (true, performData);
            } 
        }
        // check if canCompleteAward()
        for(uint256 pool = 0; pool < prizePools.length; pool++){
            address prizeStrategy = PrizePoolInterface(prizePools[pool]).prizeStrategy();
            if(prizeStrategy.canCompleteAward()){
                return (true, performData);
            } 
        }
        return (false, performData);
    }
   /// @notice Performs upkeep on the prize pools. 
    /// @param performData Not used in this implementation.
    function performUpkeep(bytes calldata performData) override external{

        address[] memory prizePools = PrizePoolRegistryInterface(prizePoolRegistry).getPrizePools();
     
        uint256 batchCounter = upkeepBatchSize; //counter for batch
        uint256 poolIndex = 0;
        
        while(batchCounter > 0 && poolIndex < prizePools.length){
            
            address prizeStrategy = PrizePoolInterface(prizePools[poolIndex]).prizeStrategy();
            
            if(prizeStrategy.canStartAward()){
                PeriodicPrizeStrategyInterface(prizeStrategy).startAward();
                batchCounter--;
            }
            else if(prizeStrategy.canCompleteAward()){
                PeriodicPrizeStrategyInterface(prizeStrategy).completeAward();
                batchCounter--;
            }
            poolIndex++;            
        }
  
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface KeeperCompatibleInterface {

  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );
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
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface PeriodicPrizeStrategyInterface {
  function startAward() external;
  function completeAward() external;
  function canStartAward() external view returns (bool);
  function canCompleteAward() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface PrizePoolInterface {
    function prizeStrategy() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface PrizePoolRegistryInterface {
    function getPrizePools() external view returns(address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/PeriodicPrizeStrategyInterface.sol";


///@notice Wrapper library for address that checks that the address supports canStartAward() and canCompleteAward() before calling
library SafeAwardable{

    ///@return canCompleteAward returns true if the function is supported AND can be completed 
    function canCompleteAward(address self) internal view returns (bool canCompleteAward){
        if(supportsFunction(self, PeriodicPrizeStrategyInterface.canCompleteAward.selector)){
            return PeriodicPrizeStrategyInterface(self).canCompleteAward();      
        }
        return false;
    }

    ///@return canStartAward returns true if the function is supported AND can be started, false otherwise
    function canStartAward(address self) internal view returns (bool canStartAward){
        if(supportsFunction(self, PeriodicPrizeStrategyInterface.canStartAward.selector)){
            return PeriodicPrizeStrategyInterface(self).canStartAward();
        }
        return false;
    }
    
    ///@param selector is the function selector to check against
    ///@return success returns true if function is implemented, false otherwise
    function supportsFunction(address self, bytes4 selector) internal view returns (bool success){
        bytes memory encodedParams = abi.encodeWithSelector(selector);
        (bool success, bytes memory result) = self.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32){
            return (false);
        }
        if(!success && result.length > 0){
            revert(string(result));
        }
        return (success);
    }
}

