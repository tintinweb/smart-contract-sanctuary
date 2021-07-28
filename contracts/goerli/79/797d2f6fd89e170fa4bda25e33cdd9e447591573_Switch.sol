/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

pragma solidity >=0.5.16;

contract Switch{
    struct data{
        string name;
        string documentHash;
    }
    uint256 id = 0;
    data[] public lookUp;
    
    event addedData(string name, string documentHash);
    
    function addData(string calldata _name, string calldata _documentHash) external returns(bool){
        data memory d;
        d.name = _name;
        d.documentHash = _documentHash;
        lookUp.push(d);
        id++;
        
        emit addedData(_name, _documentHash);
        return true;
    }
}