pragma solidity ^0.6.2;
import "./provableAPI.sol";

contract useProvableApi2 is usingProvable{
	event logString(bytes32);

    function searchIPFS(string memory _cid)public virtual returns (bytes32){
        bytes32 queryId =provable_query("IPFS", _cid);  //oraclize解析json数据   
		emit logString(queryId);
		return queryId;
    }

    function searchURL(string memory _url)public virtual returns (bytes32){
        bytes32 queryId =provable_query("URL", strConcat("json(",_url,").image"));  //oraclize解析json数据   
		emit logString(queryId);
		return queryId;
    }
}