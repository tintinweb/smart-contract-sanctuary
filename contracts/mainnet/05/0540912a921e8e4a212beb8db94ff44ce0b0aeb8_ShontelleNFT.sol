/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

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

contract CommonConstants {
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

interface ERC1155TokenReceiver {
     function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);
     function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}

interface IERC165 {
      function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
   
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

   function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

  
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

  
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, ERC165, CommonConstants {
    using SafeMath for uint256;
    using Address for address;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    constructor() {
        _registerInterface(INTERFACE_SIGNATURE_ERC1155);
    }

/////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external override{

        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }
    
    function balanceOf(address _owner, uint256 _id) external view override returns (uint256) {
        return balances[_id][_owner];
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return operatorApproval[_owner][_operator];
    }
   
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override {
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array lenght must match.");
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
    
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view override returns (uint256[] memory) {

        require(_owners.length == _ids.length);
        uint256[] memory balances_ = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }
    
    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {
       require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {
        require(ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == ERC1155_BATCH_ACCEPTED, "contract returned an unknown value from onERC1155BatchReceived");
    }
}

library StringLibrary {

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }
}

contract HasContractURI is ERC165 {

    string public contractURI;

    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    constructor(string memory _contractURI)  {
        contractURI = _contractURI;
        _registerInterface(_INTERFACE_ID_CONTRACT_URI);
    }

    function _setContractURI(string memory _contractURI) internal {
        contractURI = _contractURI;
    }
}

contract HasTokenURI {
    using StringLibrary for string;

    string public tokenURIPrefix;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _tokenURIPrefix)  {
        tokenURIPrefix = _tokenURIPrefix;
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return tokenURIPrefix.append(_tokenURIs[tokenId]);
    }
    function _setTokenURI(uint256 tokenId, string memory _uri) internal virtual {
        _tokenURIs[tokenId] = _uri;
    }
    function _setTokenURIPrefix(string memory _tokenURIPrefix) internal {
        tokenURIPrefix = _tokenURIPrefix;
    }

    function _clearTokenURI(uint256 tokenId) internal {
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    
     function uri(uint256 _id) external view returns (string memory) {
        return _tokenURI(_id);
    }
}

contract Context {
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC1155Base is Ownable, HasTokenURI, HasContractURI, ERC1155 {

    using SafeMath for uint256;
    mapping (uint256 => address) public creators;
    mapping (uint256 => string) public images;

    constructor(string memory contractURI, string memory tokenURIPrefix) HasContractURI(contractURI) HasTokenURI(tokenURIPrefix) {
    }

    function _mint(uint256 _id, uint256 _supply, string memory _uri, string memory image) internal {
        require(creators[_id] == address(0x0), "Token is already minted");
        require(_supply != 0, "Supply should be positive");
        require(bytes(_uri).length > 0, "uri should be set");

        creators[_id] = msg.sender;
        images[_id] = image;
        balances[_id][msg.sender] = _supply;
        _setTokenURI(_id, _uri);

        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _supply);
        emit URI(_uri, _id);
    }

    function burn(address _owner, uint256 _id, uint256 _value) external {

        require(_owner == msg.sender || operatorApproval[_owner][msg.sender] == true, "Need operator approval for 3rd party burns.");
        balances[_id][_owner] = balances[_id][_owner].sub(_value);

        emit TransferSingle(msg.sender, _owner, address(0x0), _id, _value);
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal override {
        require(creators[tokenId] != address(0x0), "_setTokenURI: Token should exist");
        super._setTokenURI(tokenId, uri);
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }
}

contract ShontelleNFT is Ownable, ERC1155Base {
    event CreateERC1155_v1(address indexed creator, string name, string symbol);
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol, string memory contractURI, string memory tokenURIPrefix) ERC1155Base(contractURI, tokenURIPrefix)  {
        name = _name;
        symbol = _symbol;

        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
        emit CreateERC1155_v1(msg.sender, name, symbol);
    }
   
    function mint(uint256 id, uint256 supply, string memory uri, string memory image) onlyOwner public {
        _mint(id, supply, uri, image);
    }
    
    function batchMint(uint256[] memory _ids, uint256[] memory _quantities, string[] memory uri, string[] memory image) onlyOwner public {
        for (uint256 i = 0; i < _ids.length; i++) {
            _mint(_ids[i], _quantities[i], uri[i], image[i]);
        }
    }
}