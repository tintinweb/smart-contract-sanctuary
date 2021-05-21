/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: UoSM
pragma solidity >=0.4.22 <0.8.4;
//pragma experimental ABIEncoderV2;

contract Lora{

    struct Node{
        uint nodeId;
        bytes[] cid; 
    }
    
    mapping (uint => Node) private nodes;
    
    function setInput (uint _nodeId, bytes memory _cid) public{
        nodes[_nodeId].nodeId = _nodeId;
        nodes[_nodeId].cid.push(_cid);
    }
}