pragma solidity ^0.4.25;

contract blockchainBubbleSort {
    
    // Written by Ciar&#225;n &#211; hAol&#225;in, 2018, as a really bad joke
    function getAuthor() public pure returns (string author) {
        return ("Ciaran &#211; hAol&#225;in 2018");
    }
    
    uint256[] storedArray;
    
    event SomeStuffGotSorted(uint256[] sortedArray);
    
    function bubbleSort(uint256[] array) public pure returns (uint256[] sortedArray)  {
        bool editFlag = true;
        while (editFlag) {
            editFlag = false;
            for (uint256 i = 0; i<array.length-1; i++) {
                if (array[i]>array[i+1]) {
                    uint256 temp = array[i];
                    array[i]=array[i+1];
                    array[i+1]=temp;
                    editFlag=true;
                }
            }
        }
        return array;
    }
    
    function storeBubbleSort(uint256[] array) public returns (uint256[] sortedArray) {
        storedArray = bubbleSort(array);
        emit SomeStuffGotSorted(storedArray);
        return storedArray;
    }
    
}