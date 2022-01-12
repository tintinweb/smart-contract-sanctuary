// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./provableAPI_0.6.sol";
contract RandomExample is usingProvable
{
    bytes public result;
    bytes32 public queryId;
    constructor() public
    {
        provable_setProof(proofType_Ledger);
    }

    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) override public
    {
        require(msg.sender == provable_cbAddress());
        if (provable_randomDS_proofVerify__returnCode(_queryId,_result,_proof)== 0)
            result = bytes(_result);
        else
            result = "Error";
    }

    function GetRandom(uint8 nrbytes) public payable
    {
            queryId=provable_newRandomDSQuery(
                0,
                nrbytes,
                200000
            );
    }
}