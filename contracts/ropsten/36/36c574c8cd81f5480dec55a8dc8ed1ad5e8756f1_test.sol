pragma solidity ^0.4.24;

/**
 * @dev test for below:
 * @dev 200/199 ?
 * @dev int[] a; initial a; delete a[3], what will happen
 * @dev memory storage function pramater
 */

contract test {

    uint256 public a = uint256(200) / uint256(199);

    uint256 public b = uint256(200) / uint256(101);



    uint256[] public arr;
    function getLength() view public returns (uint256) {
        return arr.length;        
    }

    function pushElement(uint256 _element) public {
        arr.push(_element);
    }
    
    function deleteElement() public {
        delete arr[arr.length - 1];
    }

    function getElement(uint256 _index) view public returns (uint256) {
        return arr[_index];
    }

    uint256[] public x = [1,2,3,4,5,6,7,8];
    uint256[] public y = [9,8,3,5,0,200,122,66];
    mapping (uint256 => bool) public temp;

    function testMemory(uint256[] memory _x, uint256[] memory  _y) public returns (uint256) {
        uint256 counter = 0;

        for(uint256 i = 0; i < _x.length; i++) {
            temp[_x[i]] = true;
        }
        for(i = 0; i < _y.length; i++) {
            if (temp[_y[i]] == true) 
                counter++;
        }

        return counter;
    }

    function testStorage(uint256[] _x, uint256[]  _y) public returns (uint256) {
        uint256 counter = 0;

        for(uint256 i = 0; i < _x.length; i++) {
            temp[_x[i]] = true;
        }
        for(i = 0; i < _y.length; i++) {
            if (temp[_y[i]] == true) 
                counter++;
        }

        return counter;
    }
    
    function testTemp1() public returns (uint256) {
        testStorage(x,y);
    }
    
    function testTemp2() public returns (uint256) {
        uint256[] memory c = x;
        uint256[] memory d = y;
        testMemory(c,d);
    }
    
    function testTemp3() public returns (uint256) {
        testMemory(x,y);
    }
    
    function testTemp4() public returns (uint256) {
        uint256[] memory c = x;
        uint256[] memory d = y;
        testStorage(c,d);
    }
}