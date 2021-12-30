/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC1155 {
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

interface IERC1155TokenReceiver {
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);      
}

interface IERC1155Metadata_URI {
    function uri(uint256 _id) external view returns (string memory);
}

contract MyERC1155 is IERC165,IERC1155,IERC1155TokenReceiver,IERC1155Metadata_URI{

    mapping (address => mapping(uint256 => uint256)) internal balances;
    mapping (address => mapping(address => bool)) internal operators;
    address private _contractOwner;

    string private _baseURI;
    string public name;
    bool public initialized;
    bool public DisabledMint;
    uint private _currentId;

    function init(address sender,string calldata init_name,string calldata init_baseURI) external{
        require(!initialized,"already initialized");
        _contractOwner = sender;
        name = init_name;
        _baseURI = init_baseURI;
        initialized = true;
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external{
	    require((msg.sender == _from) || _isApprovedForAll(_from, msg.sender), "INVALID_OPERATOR");
        require(_to != address(0),"INVALID_RECIPIENT");

        _safeTransferFrom(_from, _to, _id, _value);
        _callonERC1155Received(_from, _to, _id, _value, gasleft(), _data);
    }

	function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) internal
    {
        balances[_from][_id] = balances[_from][_id] - _value;
        balances[_to][_id] = balances[_to][_id] + _value;
        emit TransferSingle(msg.sender, _from, _to, _id, _value);
    }

	 function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data) internal
    {
        if (isContract(_to)) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
            require(retval == 0xf23a6e61, "INVALID_ON_RECEIVE_MESSAGE");
        }
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external{
        require((msg.sender == _from) || _isApprovedForAll(_from, msg.sender), "INVALID_OPERATOR");
        require(_to != address(0), "INVALID_RECIPIENT");

        _safeBatchTransferFrom(_from, _to, _ids, _values);
        _callonERC1155BatchReceived(_from, _to, _ids, _values, gasleft(), _data);
    }

    function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts) internal
    {
        require(_ids.length == _amounts.length, "INVALID_ARRAYS_LENGTH");
        uint256 nTransfer = _ids.length;
        for (uint256 i = 0; i < nTransfer; i++) {
            balances[_from][_ids[i]] = balances[_from][_ids[i]] - _amounts[i];
            balances[_to][_ids[i]] = balances[_to][_ids[i]] + _amounts[i];
        }
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data) internal
    {
        if (isContract(_to)) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
            require(retval == 0xbc197c81, "INVALID_ON_RECEIVE_MESSAGE");
        }
    }   

    function balanceOf(address _owner, uint256 _id) external view returns (uint256){
	    return balances[_owner][_id];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory){
        require(_owners.length == _ids.length, "INVALID_ARRAY_LENGTH");

        // Variables
        uint256[] memory batchBalances = new uint256[](_owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < _owners.length; i++) {
        batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }

    function setApprovalForAll(address _operator, bool _approved) external{
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
	    return _isApprovedForAll(_owner, _operator);
    }
     function _isApprovedForAll(address _owner, address _operator) internal view returns (bool){
	    return operators[_owner][_operator];
    }   

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4){
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4){

    }

    function uri(uint256 _id) external view returns (string memory){
        return string(abi.encodePacked(_baseURI,toString(_id)));
        
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return  interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0; 
    }

     function mint() external {
        require(!DisabledMint || msg.sender == _contractOwner,"mint disabled");
        _mint(msg.sender);
    }

    function _mint(address sender) internal {

        _currentId += 1;
        balances[sender][_currentId] += 1;

        emit TransferSingle(sender, address(0), sender, _currentId, 1);
    }
   

	function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    } 
}