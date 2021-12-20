/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity ^0.7.0;

contract test {

    event Array(uint[] array);


    uint[] public initArray;
    uint[] public oldArray;
    uint[] public s_newIndexes=[1,2,3,4,5];

    constructor(){
        for (uint i = 0; i < 6; i++) {
            initArray.push(i+1);
        }
    }

    function remove(uint index)  external returns(uint[] memory) {
        oldArray=initArray;
        if (index >= oldArray.length) return oldArray;
        for (uint i = index; i < oldArray.length - 1; i++) {
            oldArray[i] = oldArray[i + 1];
        }
        oldArray.pop();
        emit Array(oldArray);
        return oldArray;
    }

    function getinitArray() external view returns(uint[] memory) {
        return initArray;
    }

    function getoldArray() external view returns(uint[] memory) {
        return oldArray;
    }

    function tes() external returns(bool) {
        uint8 a=1;
        require(isInIndexes(a), "the a is not in s_newIndexes");
        return isInIndexes(a);
    }

    function isInIndexes(uint index) public returns(bool){
        bool isIn=false;
        for (uint8 i = 0; i < s_newIndexes.length; i++) {
            if(index==s_newIndexes[i]){
                isIn=true;
                break;
            }
        }
        return isIn;
    }

}