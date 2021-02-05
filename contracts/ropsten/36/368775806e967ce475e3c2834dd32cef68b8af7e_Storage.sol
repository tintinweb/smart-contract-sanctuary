/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

pragma solidity  >=0.4.0 <0.6.0;

contract Storage {

struct Certificate {
    string doc_hash;
    bool valid;
    uint valid_until;
}

mapping(uint => Certificate) documents;


function storeDocument(uint _id, string _docHash, bool _valid, uint _valid_until)  public returns(bool success)
{
    documents[_id].doc_hash = _docHash;
    documents[_id].valid = _valid;
    documents[_id].valid_until = _valid_until;
    return true;
}

function getDocument(uint _id) public view returns (string, bool, uint){
    return (documents[_id].doc_hash, documents[_id].valid, documents[_id].valid_until);
}


}