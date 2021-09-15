/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

contract CowllectorManager {
    address public cowllector;
    
    constructor(address _cowllector) public {
        cowllector = _cowllector;
    }
    
    // verifies that the caller is the cowllector.
    modifier onlyCowllector() {
        require(msg.sender == cowllector, "!cowllector");
        _;
    }
    
    function setCowllector (address _cowllector) external onlyCowllector {
        cowllector = _cowllector;
    }
}

pragma solidity >=0.6.0;

interface IStrategy {
    function cowllectorHarvest() external;
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

abstract contract MultiHarvest is CowllectorManager {
    
    struct Result {
        address strategy;
        bool success;
    }

    function harvest(address[] memory strategies) public onlyCowllector returns (Result[] memory returnData) {
        returnData = new Result[](strategies.length);
        bool success;
        for(uint256 i = 0; i < strategies.length; i++) {
            try IStrategy(strategies[i]).cowllectorHarvest() {
                success = true;
            } catch {
                success = false;
            }
            returnData[i] = Result(strategies[i], success);
        }
        return returnData;
    }

}