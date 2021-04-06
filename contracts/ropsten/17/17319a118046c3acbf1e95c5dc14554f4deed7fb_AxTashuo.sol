/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract AxTashuo is Ownable {
    struct TashuoArray { 
        string orderid;
        string userid;
        string transtext;
        string voicefilehash;
    }
    
    TashuoArray[] public ts;
    //event OnAddTsData(string orderid, string userid, string transtext, string voicefilehash);
    function addtsdata(string orderid, string userid, string transtext, string voicefilehash) onlyOwner() public {
        ts.push(TashuoArray(orderid, userid, transtext, voicefilehash));
        //emit OnAddTsData(orderid, userid, transtext, voicefilehash);
    }
}