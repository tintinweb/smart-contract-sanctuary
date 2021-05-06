/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity 0.6.6;

contract TestContract {

    string data;
    
    event DataChanged(string oldData, string newData);

    constructor() public {
        data = "data";
    }

    function setData(string calldata _data) external {
        string memory oldData = data;
        data = _data;
        emit DataChanged(oldData, _data);
    } 
    
    function getData() external view returns(string memory) {
        return data;
    }
}