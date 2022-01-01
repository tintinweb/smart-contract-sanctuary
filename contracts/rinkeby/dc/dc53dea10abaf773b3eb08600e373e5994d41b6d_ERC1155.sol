/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC1155 is ERC165 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
interface ERC1155TokenReceiver {
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC1155 is IERC1155
{
    using SafeMath for uint256;
    using Address for address;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
         return interfaceId == 0x01ffc9a7 || interfaceId == 0xd9b67a26;
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {

        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {

        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array length must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to]   = value.add(balances[id][_to]);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        return balances[_id][_owner];
    }


    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }


    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {

        require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == 0xf23a6e61, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {
        require(ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == 0xbc197c81, "contract returned an unknown value from onERC1155BatchReceived");
    }



    mapping (uint256 => address) public creators;
    uint256[] private enable_anonymous_mint;

    uint256 public nonce;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

    modifier anonymousMint(uint256 _id) {
        require(creators[_id] == msg.sender || _get_bool_from_pack(_id));
        _;
    }

    function getBoolean(uint256 _packed, uint256 _index) internal pure returns(bool)
    {
        uint256 flag = (_packed >> _index) & uint256(1);
        return (flag == 1 ? true : false);
    }

    function setBoolean(uint256 _packed, uint256 _index, bool _value) internal pure returns(uint256) {
        if (_value)
            return _packed | uint256(1) << _index;
        else
            return _packed & ~(uint256(1) << _index);
    }

    function _get_bool_from_pack(uint256 _id) internal view returns(bool){
        uint256 _packed = _id/256;
        uint256 _index = _id%256;
        return getBoolean(enable_anonymous_mint[_packed],_index);
    }

    function _set_bool_to_pack(uint256 _id,bool _value) internal {
        uint256 _packednum = _id/256;
        uint256 _index = _id%256;
        if(enable_anonymous_mint.length == _packednum){
            enable_anonymous_mint.push(0);
        }
        enable_anonymous_mint[_packednum] = setBoolean(enable_anonymous_mint[_packednum],_index,_value);
    }


    function create(uint256 _initialSupply, string calldata _uri,bool _enable_anonymous_mint) external returns(uint256 _id) {

        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;
        _set_bool_to_pack(_id,_enable_anonymous_mint);
        //emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);
    }

    function setEnableAnonymousMint(uint256 _id,bool _enable_anonymous_mint) external creatorOnly(_id) {
        _set_bool_to_pack(_id,_enable_anonymous_mint);
    }
    function getEnableAnonymousMint(uint256 _id) external view{
        _get_bool_from_pack(_id);
    }
    function mint(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external anonymousMint(_id) {

        for (uint256 i = 0; i < _to.length; ++i) {

            address to = _to[i];
            uint256 quantity = _quantities[i];

            balances[_id][to] = quantity + balances[_id][to];

            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, _id, quantity, '');
            }
        }
    }

    function setURI(string calldata _uri, uint256 _id) external creatorOnly(_id) {
        emit URI(_uri, _id);
    }
}