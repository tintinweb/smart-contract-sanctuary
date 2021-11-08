/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity  >=0.6.0 <0.8.0;

contract ArrayTest {
    uint randomNumber; //or call VRF contract if this is another contract
    mapping (address => uint) public groupNumByAddr;
    
     function assignGroupNumbers(address[] memory addressArr, uint numGroups) public virtual {
        require(numGroups > 0 && addressArr.length > numGroups-1,"revert");
        uint minGroupNumber = addressArr.length/numGroups;
        uint remainder = addressArr.length % numGroups;
        uint counter = 1;
        uint currIndex = 0;
        uint[] memory numInGroupArr = new uint[](numGroups);
        uint target;
        bool notUpdate;
        while (currIndex < addressArr.length){
            notUpdate = true;
            while(notUpdate){
                target = (uint256(keccak256(abi.encode(randomNumber, counter))) % numGroups);
                if(target< remainder && numInGroupArr[target] < minGroupNumber + 1){
                    numInGroupArr[target]++;
                    groupNumByAddr[addressArr[currIndex]] = target;//(you can add 1 if you want group to start at 1)
                    currIndex++;
                    notUpdate = false;
                    counter++;
                }
                else if(target >= remainder && numInGroupArr[target] < minGroupNumber){
                    numInGroupArr[target]++;
                    groupNumByAddr[addressArr[currIndex]] = target;//(you can add 1 if you want group to start at 1)
                    currIndex++;
                    counter++;
                    notUpdate = false;
                }
                else{
                    counter++;
                }
                
            }
        }        
    }
    
    function setRandomNumber(uint _amount) public {
        randomNumber = _amount;
    }
}