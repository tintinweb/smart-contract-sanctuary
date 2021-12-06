/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-06
*/

pragma solidity 0.5.0;

contract pop{
    uint8[] __randomVariable = [150, 175, 200, 225, 250];
    uint8[] __remainingRandomVariable = [150, 175, 200, 225, 250];
    uint8[] tempRemainingRandomVariable;
    mapping (uint256 => uint256) occuranceOfRandonNumber;

    function randomVariablePicker() internal view returns (uint256) {
        uint256 getRandomNumber = __remainingRandomVariable[
        uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender))) % __remainingRandomVariable.length];
        return getRandomNumber;
    }

    function popRandomVariable() public  returns(uint256, uint8[] memory, uint256){
        uint256 randomNumber = randomVariablePicker();
        if(occuranceOfRandonNumber[randomNumber]>=24){
            //remove variable
            uint256 _index;
            for(uint256 index=0;index<=__remainingRandomVariable.length;index++){
                if(__remainingRandomVariable[index]==randomNumber){
                    _index = index;
                    break;
                }
            }
            delete __remainingRandomVariable[_index];
            __remainingRandomVariable[_index] = __remainingRandomVariable[__remainingRandomVariable.length-1];
            for(uint256 index=0;index<__remainingRandomVariable.length-1;index++){
                tempRemainingRandomVariable[index]= __remainingRandomVariable[index];
            }
          __remainingRandomVariable = tempRemainingRandomVariable;
         }
         if(occuranceOfRandonNumber[randomNumber]<24){
            occuranceOfRandonNumber[randomNumber] = occuranceOfRandonNumber[randomNumber]+1;
         }
        return(randomNumber, __remainingRandomVariable, occuranceOfRandonNumber[randomNumber]);
    }
}