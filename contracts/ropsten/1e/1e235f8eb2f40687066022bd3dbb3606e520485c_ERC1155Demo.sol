/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ERC1155{
     event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
     event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
     event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
     function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value/*, bytes calldata _data*/) external;
     function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values/*, bytes calldata _data*/) external;
     function balanceOf(address _owner, uint256 _id) external view returns (uint256);
     function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
     function setApprovalForAll(address _operator, bool _approved) external;
     function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


contract ERC1155Demo is ERC1155 {
     mapping (uint256 => mapping(address => uint256)) private Balances;
    mapping (address => mapping(address => bool)) private AdminApprovals;

    string tokenUri;

 
    constructor (string memory uri) {
        setURI(uri);
    }
    
    function setURI(string memory _uri)internal{
       tokenUri= _uri ;
    }
    
    function getUri()external view returns(string memory){
        return tokenUri;
    }
    
  
    
     function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value/*, bytes calldata _data*/) external override{
         require(msg.sender == _from || isApprovedForAll(_from,msg.sender),"Only Owner or Approved user can perform transfer");
         require(_to != address(0), "Invalid resepient address");
          uint256 fromBalance = Balances[_id][_from];
        require(fromBalance >= _value, "Insufficient balance for transfer");
        Balances[_id][_from] = fromBalance - _value;
        Balances[_id][_to] += _value;

        emit TransferSingle(msg.sender, _from, _to, _id, _value);
     }
     
     function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values/*, bytes calldata _data*/) external override{
           require(msg.sender == _from || isApprovedForAll(_from,msg.sender),"Only Owner or Approved user can perform transfer");
            require(_to != address(0), "Invalid resepient address");
               for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 amount = _values[i];

            uint256 fromBalance = Balances[id][_from];
            require(fromBalance >= amount, "Insufficient balance for transfer");
            Balances[id][_from] = fromBalance - amount;
            Balances[id][_to] += amount;
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
     }
     
     function balanceOf(address _owner, uint256 _id) public override view returns (uint256){
          require(_owner != address(0), "Invalid Owner Address");
        return Balances[_id][_owner];
     }
     
     function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external override view returns (uint256[] memory){
         require(_owners.length == _ids.length,"Owner and ids legth does not match." );
         uint256 [] memory batchBalance = new uint256[](_ids.length);
           for (uint i = 0; i < _owners.length; i++) {
            batchBalance[i] = balanceOf(_owners[i], _ids[i]);
        }

        return batchBalance;
     }
     
     function setApprovalForAll(address _operator, bool _approved) external override{
         require(msg.sender != _operator,"Invalid Operator Address");
         AdminApprovals[msg.sender][_operator]= _approved;
         emit ApprovalForAll(msg.sender,_operator,_approved);
    
     }
     
     function isApprovedForAll(address _owner, address _operator) public override view returns (bool){
         return AdminApprovals[_owner][_operator];
     }
     
     function mintToken(address _address,uint256 _id, uint256 _amount/*, bytes memory _data*/) external{
         require(_address != address(0), "Invalid address");
         Balances[_id][_address] += _amount;
          emit TransferSingle(msg.sender, address(0), _address, _id, _amount);
     }
     
     
     function mintBatchToken(address _to,uint256[] calldata _ids, uint256[] calldata _values/*, bytes memory data*/) external{
         require(_to != address(0), "Invalid address");
         require(_ids.length == _values.length, "Ids and Values size mismatch.");
         for (uint i = 0; i < _ids.length; i++) {
            Balances[_ids[i]][_to] += _values[i];
        }

        emit TransferBatch(msg.sender, address(0), _to, _ids, _values);
         
     }
}