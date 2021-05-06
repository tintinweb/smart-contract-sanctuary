/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity 0.6.6;

contract TestContract {

    string data;

    constructor() public {
        data = "data";
    }

    function setData(string calldata _data) external {
        data = _data;
    } 
    
    function getData() external view returns(string memory) {
        return data;
    }
}