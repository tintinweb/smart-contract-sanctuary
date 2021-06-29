/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
library SafeMath
{
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }
    function sub(uint256 a,uint256 b) internal pure returns (uint256)
    {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }
}
interface ERC1155 {
    function balanceOf(address _owner, uint256 _id) external view returns(uint256);
    function balanceOfBatch(address[] calldata _owners,uint256[] calldata _ids) external view returns(uint256[] memory);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function setApprovalForAll(address _operator, bool approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns(bool);
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
}
contract ERC_1155 is ERC1155 {
    using SafeMath for uint256;
    mapping(uint256 => mapping(address => uint256)) public balance;
    mapping(address => mapping(address => bool)) public operatorAddress;
    string public _uri;
    constructor(string memory uri_) public{
             _setURI(uri_);
    }
     function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
     function uri(uint256) public view virtual returns (string memory) {
        return _uri;
    }
    function balanceOf(address _owner, uint256 _id) public override view returns(uint256) {
        require(_owner!=address(0),"Owner address can't be zero");
        return balance[_id][_owner];
    }
    function balanceOfBatch(address[] calldata _owners,uint256[] calldata _ids) public override view returns(uint256[] memory) {
       require(_owners.length==_ids.length,"Length must be same");
       uint256[] memory batchBalances=new uint256[](_owners.length);
       for(uint256 i=0;i<_owners.length;i++) {
           require(_owners[i]!=address(0),"Owner address cannot be zero");
           batchBalances[i]=balanceOf(_owners[i],_ids[i]);
       }
       return batchBalances;
    }
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) public override {
        require(msg.sender==_from || isApprovedForAll(_from,msg.sender),"Calling address is not owner nor approved");
        require(balance[_id][_from] >=_value,"Not Enough Balance for Transfer");
        require(_to!=address(0),"Receiver address cannot be zero");
        balance[_id][_from]=balance[_id][_from].sub(_value);
        balance[_id][_to]=balance[_id][_to].add(_value);
        emit TransferSingle(msg.sender,_from,_to,_id,_value);
    }
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) public override {
        require(msg.sender==_from || isApprovedForAll(_from,msg.sender),"Calling address is not owner nor approved");
        require(_to!=address(0),"Receiver address cannot be zero");
        require(_ids.length==_values.length,"Length must be same");
        for(uint256 i=0;i<_ids.length;i++) {
            require(balance[_ids[i]][_from]>=_values[i],"NOt Enough Balance for Transfer");
            balance[_ids[i]][_from]=balance[_ids[i]][_from].sub(_values[i]);
            balance[_ids[i]][_to]=balance[_ids[i]][_to].add(_values[i]);
        }
        emit TransferBatch(msg.sender,_from,_to,_ids,_values);
    }
    function setApprovalForAll(address _operator, bool approved) public override {
        require(msg.sender!=_operator,"Approval for self");
        operatorAddress[msg.sender][_operator]=approved;
        emit ApprovalForAll(msg.sender,_operator,approved);
    }
    function isApprovedForAll(address _owner, address _operator) public override view returns(bool) {
        return operatorAddress[_owner][_operator];
    }
    function mint(address _owner, uint256 _id, uint256 _value, bytes memory _data) public {
        require(_owner!=address(0),"Mint to the zero address");
        balance[_id][_owner]=balance[_id][_owner].add(_value);
        emit TransferSingle(msg.sender,address(0),_owner,_id,_value);
    }
    function mintBatch(address _owner,uint256[] calldata _ids, uint256[] calldata _values, bytes memory data) public {
        require(_owner!=address(0),"Mint to the zero address");
        require(_ids.length==_values.length,"Length must be same");
        for(uint256 i=0;i<_ids.length;i++) {
            balance[_ids[i]][_owner]=balance[_ids[i]][_owner].add(_values[i]);
        }
        emit TransferBatch(msg.sender,address(0),_owner,_ids,_values);
    }
    function burn(address _owner, uint256 _id, uint256 _value) public {
        require(_owner!=address(0),"Burn from the zero address");
        require(balance[_id][_owner]>=_value,"Not Enough Balance for Burn");
        balance[_id][_owner]=balance[_id][_owner].sub(_value);
        emit TransferSingle(msg.sender,_owner,address(0),_id,_value);
    }
    function burnBatch(address _owner,uint256[] calldata _ids, uint256[] calldata _values) public {
        require(_owner!=address(0),"Burn from the zero address");
        require(_ids.length==_values.length,"Length must be same");
        for(uint256 i=0;i<_ids.length;i++) {
            require(balance[_ids[i]][_owner]>=_values[i],"Not Enough Balance for Burn");
            balance[_ids[i]][_owner]=balance[_ids[i]][_owner].sub(_values[i]);
        }
    }
}