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

contract HegicOptionsDataHelper {
    
    function getUnlockableOptionsCount(address optionpool,uint256 limit) public view returns (uint256 count) {
        count = 0;
        for(uint i=0;i<limit;i++) {
            if(_totalUnlock(optionpool,limit))
               ++count;
        }
    }

    function GetUnlockableOptions(address optionpool,uint256 limit) public view returns (uint256[] memory unlockableIDS) {
        unlockableIDS = new uint256[](getUnlockableOptionsCount(optionpool,limit));
        uint256 index = 0;
        for(uint i=0;i<limit;i++){
            if(_totalUnlock(optionpool,limit))
               unlockableIDS[index] = i;
               index++;
        }
    }
    
    function _totalUnlock(address hegic, uint256 optionID) internal view returns (bool) {
        Option memory option = IHegicOptions(hegic).options(optionID);
        // if one of the options is not active or not expired, do not continue
        if (option.state != State.Active || option.expiration >= block.timestamp) {
                return false;
        }
        return true;
    }

}