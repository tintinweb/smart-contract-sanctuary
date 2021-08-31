pragma solidity ^0.6.2;
import "./provableAPI.sol";

contract useProvableApi is usingProvable{
	event logString(bytes32);

    function searchIPFS(string memory _cid)public virtual returns (bytes32){
        bytes32 queryId =provable_query("IPFS", _cid);  //oraclize解析json数据   
		emit logString(queryId);
		return queryId;
    }
}