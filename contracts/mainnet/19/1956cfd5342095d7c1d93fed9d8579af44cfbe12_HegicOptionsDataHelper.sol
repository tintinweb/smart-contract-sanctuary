/**
 *Submitted for verification at Etherscan.io on 2020-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

enum State {Inactive, Active, Exercised, Expired}
enum OptionType {Invalid, Put, Call}

struct Option {
    State state;
    address payable holder;
    uint256 strike;
    uint256 amount;
    uint256 lockedAmount;
    uint256 premium;
    uint256 expiration;
    OptionType optionType;
}

interface IHegicPool {
    function totalBalance() external view returns (uint256 amount);

    function availableBalance() external view returns (uint256 amount);
}

interface IHegicOptions {

    function pool() external view returns (address poolAddress);

    function unlockAll(uint256[] calldata optionsIDs) external;

    function options(uint256) external view returns (Option memory);

}

interface IHegicPoolKeep3r {
  function ethOptions (  ) external view returns ( address );
  function wbtcOptions (  ) external view returns ( address );
}

contract HegicOptionsDataHelper {

    IHegicPoolKeep3r iJob = IHegicPoolKeep3r(0xB1aCE96072654e3A2564A90D64Be99Dd3Ac195F4);
    
    function getUnlockableOptionsCount(address optionpoolAddr,uint256 start,uint256 limit) public view returns (uint256 count) {
        count = 0;
        for(uint i=start;i<limit;i++) {
            if(unlockable(optionpoolAddr,limit))
               ++count;
        }
    }
    
    function GetUnlockableOptions(uint256 poolindex , uint256 start,uint256 limit) public view returns (uint256[] memory unlockableIDS) {
        address optionpool = poolindex == 0 ? iJob.ethOptions() : iJob.wbtcOptions();
        unlockableIDS = new uint256[](getUnlockableOptionsCount(optionpool,start,limit));
        uint256 index = 0;
        for(uint i=start;i<limit;i++){
            if(unlockable(optionpool,limit)){
                unlockableIDS[index] = i;
                index++;
            }
        }
    }
    
    function unlockable(address hegic, uint256 optionID) public view returns (bool) {
        Option memory option = IHegicOptions(hegic).options(optionID);
        // if one of the options is not active or not expired, do not continue
        if (option.state != State.Active || option.expiration >= block.timestamp) {
                return false;
        }
        return true;
    }

}