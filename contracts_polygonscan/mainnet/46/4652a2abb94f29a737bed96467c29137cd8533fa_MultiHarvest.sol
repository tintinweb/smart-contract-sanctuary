/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IStrategy {
    function harvest() external;
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

contract MultiHarvest {

    struct Result {
        address strategy;
        bool success;
    }
    
    // verifies that the caller is not a contract.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }
    
    function harvest(address[] memory strategies) public onlyEOA returns (Result[] memory returnData) {
        returnData = new Result[](strategies.length);
        bool success;
        for(uint256 i = 0; i < strategies.length; i++) {
            try IStrategy(strategies[i]).harvest() {
                success = true;
            } catch {
                success = false;
            }
            returnData[i] = Result(strategies[i], success);
        }
        return returnData;
    }

}