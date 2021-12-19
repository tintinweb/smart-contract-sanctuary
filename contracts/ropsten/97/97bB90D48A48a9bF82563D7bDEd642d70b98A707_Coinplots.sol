/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

pragma solidity ^0.8.10;

contract Coinplots {
    string[] public plots;
    // 625 = 25 x 25

    function getplots() public view returns (string[] memory) {
        //for i in plots{}
        return plots;
    }

    function viewPlots() public view returns (string memory){
        string memory tempString = "temp";

        return tempString;

    }

    function setPlot(uint pNum, string memory newValue) public {
        plots[pNum] = (newValue);
    }

    function getplotsNum(uint pplots) public view returns (string memory) {
        return plots[pplots];
    }

    function pushToplots(string memory newValue) public {
        plots.push(newValue);
    }
}