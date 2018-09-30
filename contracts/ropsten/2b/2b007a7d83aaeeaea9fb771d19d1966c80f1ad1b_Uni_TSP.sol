pragma solidity ^0.4.24;

contract Uni_TSP {
    uint256[1000][1000] array;
    bool isSetup;
    constructor () public {
        isSetup = false;
    }
    function setup(uint256[] input) public {
        require(!isSetup);
        uint256 counter = 0;
        for (uint256 i = 0; i<1000; i++) {
            for (uint256 j = 0; j<=i; j++) {
                array[i][j]=input[counter];
            }
        }
        isSetup = true;
    }
    function getAuthor() public pure returns (string authorName) {
        return("Ciar&#225;n &#211; hAol&#225;in, Maynooth University, 2018");
    }
    function submitDistance(uint256[] submittedPath) public returns (uint256) {
        return 0;
    }
    function checkDistance(uint256 i, uint256 j) public view returns (uint256) {
        return array[i][j];
    }
    function set(uint256 i, uint256 j, uint256 i1, uint256 j1) public {
        array[i][j]=array[i1][j1];
    }
    function setn(uint256 i, uint256 j, uint256 val) public {
        array[i][j]=val;
    }
}