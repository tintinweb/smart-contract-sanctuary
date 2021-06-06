/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity 0.4.22;

contract agree_contract{
    
    address owner;
    string data;
    
    event logData(string dataToLog);
    
    modifier onlyOwner(){
        require(msg.sender == owner,"not owner");
        _;
    }
    
    function getData() public view returns(string returnData){
        return data;
    }
    
    function setData(string newData) public {
        emit logData(newData);
        data = newData;
    }

}