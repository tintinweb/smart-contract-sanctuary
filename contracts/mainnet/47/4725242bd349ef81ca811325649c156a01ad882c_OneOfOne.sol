// SPDX-License-Identifier: MIT
// Francisco Giordano (2022-01-01)

pragma solidity 0.8.11;

contract OneOfOne {
    address internal owner;
    mapping (uint => string) public uri;
    mapping (address => mapping (address => bool)) public isApprovedForAll;

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint _id, uint _value);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint indexed _id);

    constructor(address _owner, string memory _uri) { initialize(_owner, _uri); }

    function initialize(address _owner, string memory _uri) public {
        require(owner == address(0) && _owner != address(0));
        emit TransferSingle(msg.sender, address(0), _owner, 1, 1);
        emit URI(_uri, 1);
        uri[1] = _uri;
        owner = _owner;
    }

    function contractURI() public view returns (string memory) { return uri[1]; }

    function supportsInterface(bytes4 _id) public pure returns (bool) { return _id == 0x01ffc9a7 || _id == 0xd9b67a26 || _id == 0x0e89341c; }

    function balanceOf(address _owner, uint _id) public view returns (uint) { return _owner == owner && _id == 1 ? 1 : 0; }

    function balanceOfBatch(address[] calldata _owners, uint[] calldata _ids) public view returns (uint[] memory res) {
        require(_owners.length == _ids.length);
        res = new uint[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) res[i] = balanceOf(_owners[i], _ids[i]);
    }

    function safeTransferFrom(address _from, address _to, uint _id, uint _value, bytes calldata _data) public {
        require(_id == 1 && _value <= 1 && _from == owner && _to != address(0));
        require(_from == msg.sender || isApprovedForAll[_from][msg.sender]);
        emit TransferSingle(msg.sender, _from, _to, _id, _value);
        if (_value == 1) owner = _to;
        if (_to.code.length > 0) {
            (bool ok, bytes memory retdata) = _to.call(abi.encodeWithSelector(0xf23a6e61, msg.sender, _from, _id, _value, _data));
            require(ok && abi.decode(retdata, (bytes4)) == 0xf23a6e61);
        }
    }

    function safeBatchTransferFrom(address _from, address _to, uint[] calldata _ids, uint[] calldata _values, bytes calldata _data) public {
        require(_ids.length == _values.length);
        for (uint i = 0; i < _ids.length; i++) safeTransferFrom(_from, _to, _ids[i], _values[i], _data);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
}