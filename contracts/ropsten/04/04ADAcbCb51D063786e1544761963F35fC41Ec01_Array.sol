/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

pragma solidity ^0.8.11;

contract Array {
    uint[] public dynamicArray;
    uint[] public dynamicArray2 = [3,2,1,2,3,4];
    uint[5] public fixArray;
    uint[5] public fixArray2 = [5,5,5,5,5];
    uint[][] public tddArray;
    uint[5][5] public tdfArray;
    
    function setDynamicArray(uint[] memory _dynamicArray) public {
        dynamicArray = _dynamicArray;
    }

    function setStaticArray(uint[5] memory _fixArray) public {
    }

    function setTwoDecArray(uint[][] memory _tddArray) public {
        tddArray = _tddArray;
    }

    function setTwoDecFixArray(uint[5][5] memory _tdfArray) public {
        tdfArray = _tdfArray;
    }

    function changeInArray(uint _index, uint value) public {
        require(_index < dynamicArray.length, "index out of length array");
        dynamicArray[_index] = value;
    }
    
    function removeFromArray(uint _index) public {
        require(_index < fixArray.length, "index out of length array");
        delete fixArray[_index];
    }

    function removeByShift(uint _index) public {
        require(_index < dynamicArray.length, "index out of length array");
        for (uint i = _index; i < dynamicArray.length - 1; i++) {
            dynamicArray[i] = dynamicArray[i + 1];
        }
        dynamicArray.pop();
    }
    
    function addInArray(uint _value) public {
        dynamicArray.push(_value);
    }

    function removeTwoDecArray(uint _i, uint _j) public {
        delete tddArray[_i][_j];
    }

    function deleteAll() public {
        delete dynamicArray;
    }

    function getDynamicArray() public view returns (uint[] memory) {
        return dynamicArray;
    }

    function getStaticArray() public view returns (uint[5] memory) {
        return fixArray;
    }

    function getTwoDecArray() public view returns (uint[][] memory) {
        return tddArray;
    }

    function getTwoDecFixArray() public view returns (uint[5][5] memory) {
        return tdfArray;
    }

    function sumResult() public view returns (uint _sum) {
        for (uint i = 0; i < dynamicArray.length; i++) {
            _sum += dynamicArray[i];
        }
        return _sum;
    }

    function high() public view returns (uint _high) {
        // _high = 0;
        for (uint i = 0; i < dynamicArray.length; i++) {
            if (dynamicArray[i] > _high) {
                _high = dynamicArray[i];
            }
        }
        return _high;
    }
}