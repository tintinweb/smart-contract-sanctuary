// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "./MyStack.sol";

contract MinerContract{

    uint public createTime;

    /* The token against which this chequebook writes cheques */
    MyStake public myStake;

    address public issuer;
    /* indicates wether a cheque bounced in the past */

    struct ClientInfo{
        uint status;
        string result;
    }

    ClientInfo[] private clientInfos;

    constructor(address _issuer, address _pool, uint _createTime) {
        issuer = _issuer;
        myStake = MyStake(_pool);
        createTime = _createTime;
    }

    function uploadInfo(uint status,string memory result) public {
        ClientInfo memory clientInfo;
        clientInfo.status = status;
        clientInfo.result = result;
        clientInfos.push(clientInfo);
        myStake.uploadInfo(status,result);
    }
}