/**
 *Submitted for verification at polygonscan.com on 2021-07-26
*/

pragma solidity 0.8.4;

contract storageTestCF {

  struct transactionObj {
    string txType;
    string details;
    string IDs;
    string refNumber;
    string prevRefNumber;
  }

  mapping (string => transactionObj) private _map;
  
  event newTransaction(string _id, string _type, string _details, string _refNumber, string _prevRefNumber);
  
  function readTransaction(string memory _id) external view returns (transactionObj memory) {
    return _map[_id];
  }

  function storeTransaction(string memory _id, string memory _type, string memory _details, string memory _refNumber, string memory _prevRefNumber) public {
    transactionObj storage _tx = _map[_id];
    _tx.txType = _type;
    _tx.details = _details;
    _tx.refNumber = _refNumber;
    _tx.prevRefNumber = _prevRefNumber;
    emit newTransaction(_id, _type, _details, _refNumber, _prevRefNumber);
  }

}