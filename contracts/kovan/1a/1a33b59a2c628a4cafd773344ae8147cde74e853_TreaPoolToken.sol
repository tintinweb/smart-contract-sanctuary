/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract ReentrancyGuard {
    bool private _notEntered;
    constructor () internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//-------------------------------------------------NFT-------------------------------------------------------//
interface IERC777Sender {

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}


interface IERC1820Registry {
    function setManager(address account, address newManager) external;
    function getManager(address account) external view returns (address);
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);
    function updateERC165Cache(address account, bytes4 interfaceId) external;
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);
    event ManagerChanged(address indexed account, address indexed newManager);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC165 {
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

interface IERC1155TokenReceiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


interface IERC1155 {
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event URI(string _amount, uint256 indexed _id);
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


abstract contract ERC1155 is IERC165, IERC1155 {
    using SafeMath for uint256;
    using Address for address;
    
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;
    mapping (address => mapping(uint256 => uint256)) internal balances;
    mapping (address => mapping(address => bool)) internal operators;

    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
    {
        balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
        balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
    {
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
            require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
        }
    }


  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");
    uint256 nTransfer = _ids.length;
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }
emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }


  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  function setApprovalForAll(address _operator, bool _approved) 
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  
  function isApprovedForAll(address _owner, address _operator) 
    public override virtual view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  function balanceOf(address _owner, uint256 _id) 
    public override view returns (uint256)
  {
    return balances[_owner][_id];
  }

  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) 
    public override view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
  bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
    if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
        _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
      return true;
    }
    return false;
  }
}


contract ERC1155Metadata {
  // URI's default URI prefix
  string internal baseMetadataURI;
  event URI(string _uri, uint256 indexed _id);


  function uri(uint256 _id) public virtual view  returns (string memory) {
    return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
  }


  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseMetadataURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }


  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }


  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint256 j = _i;
    uint256 ii = _i;
    uint256 len;

    // Get number of bytes
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;

    // Get each individual ASCII
    while (ii != 0) {
      bstr[k--] = byte(uint8(48 + ii % 10));
      ii /= 10;
    }

    // Convert to string
    return string(bstr);
  }
}


abstract contract ERC1155MintBurn is ERC1155 {
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }


  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }


  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}



library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}


pragma experimental ABIEncoderV2;


contract CRCN is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable {
    using Strings for string;
    uint256 private _currentTokenID = 0;
    mapping (uint256 => address) public creators;
    mapping (uint256 => uint256) public tokenSupply;
    mapping (uint256 => uint256) public caps;
    mapping (uint256 => string) public uris;

    struct Uint256Set {
        uint256[] _values;
        mapping (uint256 => uint256) _indexes;
    }

    struct AddressSet {
        address[] _values;
        mapping (address => uint256) _indexes;
    }
    mapping (address => Uint256Set) private holderTokens;
    mapping (uint256 => AddressSet) private owners;
    string public name;
    string public symbol;

    /**
    * @dev Require msg.sender to be the creator of the token id
    */
    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender, "CRCN: ONLY_CREATOR_ALLOWED");
        _;
    }

    /**
    * @dev Require msg.sender to own more than 0 of the token id
    */
    modifier ownersOnly(uint256 _id) {
        require(isTokenOwner(msg.sender, _id), "CRCN: ONLY_OWNERS_ALLOWED");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) public {
        name = _name;
        symbol = _symbol;
    }

    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function tokensOf(address owner) public view returns (uint256[] memory) {
        return holderTokens[owner]._values;
    }

    function getNextTokenID() public view returns (uint256) {
        return _currentTokenID.add(1);
    }

    /**
    * @dev Will update the base URL of token's URI
    * @param _newBaseMetadataURI New base URL of token's URI
    */
    function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyOwner {
        _setBaseMetadataURI(_newBaseMetadataURI);
    }

    function create(
        address _initialOwner,
        uint256 _initialSupply,
        uint256 _cap,
        string memory _uri,
        bytes memory _data
    ) public onlyOwner returns (uint256) {
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;
        setAdd(_initialOwner, _id);

        if (bytes(_uri).length > 0) {
            uris[_id] = _uri;
            emit URI(_uri, _id);
        }

        _mint(_initialOwner, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        caps[_id] = _cap;

        return _id;
    }

 
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) public override {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
        require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
        
        _safeTransferFrom(_from, _to, _id, _amount);
        _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);

        if (balanceOf(_from, _id) == 0) {
            setRemove(_from, _id);
        }

        setAdd(_to, _id);
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
         public override
    {
        // Requirements
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
        require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);

        for (uint256 i = 0; i < _ids.length; i++) {
            if (balanceOf(_from, _ids[i]) == 0) {
                setRemove(_from, _ids[i]);
            }

            setAdd(_to, _ids[i]);
        }
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public creatorOnly(_id) {
        if (caps[_id] != 0) {
            require(tokenSupply[_id].add(_quantity) <= caps[_id], "CRCN: OVER_THE_CAP");
        }
        _mint(_to, _id, _quantity, _data);
        setAdd(_to, _id);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _quantity = _quantities[i];

            if (caps[_id] != 0) {
                require(tokenSupply[_id].add(_quantity) <= caps[_id], "CRCN: OVER_THE_CAP");
            }
            require(creators[_id] == msg.sender, "CRCN: ONLY_CREATOR_ALLOWED");

            setAdd(_to, _id);
            tokenSupply[_id] = tokenSupply[_id].add(_quantity);
        }
        _batchMint(_to, _ids, _quantities, _data);
    }

    function setCreator(
        address _to,
        uint256[] memory _ids
    ) public {
        require(_to != address(0), "CRCN: INVALID_ADDRESS.");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            _setCreator(_to, id);
        }
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    )  public override view returns (bool isOperator) {

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function isTokenOwner(
        address _owner,
        uint256 _id
    ) public view returns (bool) {
        if(balances[_owner][_id] > 0) {
            return true;
        }
        return false;
    }

    function ownerOf(uint256 _id) public view returns (address[] memory) {
        return owners[_id]._values;
    }

    function _getUri(uint256 _id) internal view returns (string memory) {
        require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id), uris[_id]);
    }

    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
    {
        creators[_id] = _to;
    }

    function _exists(
        uint256 _id
    ) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    function _incrementTokenTypeId() private  {
        _currentTokenID++;
    }

    function setAdd(address owner, uint256 value) internal returns (bool) {
        if (!setContains(owner, value)) {
            holderTokens[owner]._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            holderTokens[owner]._indexes[value] = holderTokens[owner]._values.length;

            owners[value]._values.push(owner);
            owners[value]._indexes[owner] = owners[value]._values.length;

            return true;
        } else {
            return false;
        }
    }

  
    function setRemove(address owner, uint256 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = holderTokens[owner]._indexes[value];
        uint256 ownerIndex = owners[value]._indexes[owner];

        if (valueIndex != 0) {
          
            uint256 toDeleteValueIndex = valueIndex - 1;
            uint256 lastIndex = holderTokens[owner]._values.length - 1;
            uint256 lastValue = holderTokens[owner]._values[lastIndex];
            holderTokens[owner]._values[toDeleteValueIndex] = lastValue;
            holderTokens[owner]._indexes[lastValue] = toDeleteValueIndex + 1; // All indexes are 1-based
            holderTokens[owner]._values.pop();
            delete holderTokens[owner]._indexes[value];

            uint256 toDeleteOwnerIndex = ownerIndex - 1;
            lastIndex = owners[value]._values.length - 1;
            address lastAddress = owners[value]._values[lastIndex];
            owners[value]._values[toDeleteOwnerIndex] = lastAddress;
            owners[value]._indexes[lastAddress] = toDeleteOwnerIndex + 1; // All indexes are 1-based
            owners[value]._values.pop();
            delete owners[value]._indexes[owner];

            return true;
        } else {
            return false;
        }
    }


    function setContains(address owner, uint256 value) public view returns (bool) {
        return holderTokens[owner]._indexes[value] != 0;
    }

    function at(address owner, uint256 index) public view returns (uint256) {
        Uint256Set memory set = holderTokens[owner];
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
}

contract SponsorWhitelistControl {
    function getSponsorForGas(address contractAddr) public view returns (address) {}
    function getSponsoredBalanceForGas(address contractAddr) public view returns (uint) {}
    function getSponsoredGasFeeUpperBound(address contractAddr) public view returns (uint) {}
    function getSponsorForCollateral(address contractAddr) public view returns (address) {}
    function getSponsoredBalanceForCollateral(address contractAddr) public view returns (uint) {}
    function isWhitelisted(address contractAddr, address user) public view returns (bool) {}
    function isAllWhitelisted(address contractAddr) public view returns (bool) {}
    function addPrivilegeByAdmin(address contractAddr, address[] memory addresses) public {}
    function removePrivilegeByAdmin(address contractAddr, address[] memory addresses) public {}
    function setSponsorForGas(address contractAddr, uint upperBound) public payable {}
    function setSponsorForCollateral(address contractAddr) public payable {}
    function addPrivilege(address[] memory) public {}
    function removePrivilege(address[] memory) public {}
}


contract Genesis is CRCN, IERC777Sender, ReentrancyGuard {
    event Opened(address indexed account, uint256 id, uint256 categoryId);
    event Forged(address indexed account, uint256[] ids, uint256 bounty);
    address public devAddr;
    constructor( address _devAddr, string memory _baseMetadataURI)
        CRCN("MoonswapHero", "GENESIS")
    public {
        devAddr = _devAddr;
        _setBaseMetadataURI(_baseMetadataURI);
        address[] memory users = new address[](1);
        users[0] = address(0);
       
    }

    // IERC777Sender
    function tokensToSend(
        address,
        address from,
        address,
        uint256,
        bytes memory,
        bytes memory
    ) public override
    {
        require(from == address(this), "Genesis: deposit not authorized");
    }

    function setDevAddr(address _devAddr) public onlyOwner {
        devAddr = _devAddr;
    }

    function uri(uint256 _id) public override view returns (string memory) {
        return _getUri(_id);
    }

    function batchCreateNFT(
        address[] calldata _initialOwners,
        string[] calldata _uris,
        bytes calldata _data
    ) external onlyOwner nonReentrant returns (uint256[] memory tokenIds) {
        require(_initialOwners.length == _uris.length, "Genesis: uri length mismatch");

        tokenIds = new uint256[](_initialOwners.length);
        for (uint i = 0; i < _initialOwners.length; i++) {
            tokenIds[i] = createNFT(_initialOwners[i], _uris[i], _data);
        }
    }

    function createNFT(
        address _initialOwner,
        string memory _uri,
        bytes memory _data
    ) public onlyOwner returns (uint256 tokenId) {
        tokenId = create(_initialOwner, 1, 1, _uri, _data);
    }
}


//-------------------------------------------------STAKE-------------------------------------------------------//
contract Wrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public investToken;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        address _from = msg.sender;
        address _to = address(this);
        uint256 _nftId = 4;
        uint256 _value = amount;
        bytes memory _bytes = "0x01";
        (bool success, bytes memory returndata) = address(investToken).call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", _from, _to, _nftId, _value, _bytes));
        if (!success)
            revert();
       
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        address _from = address(this);
        address _to = msg.sender;
        uint256 _nftId = 4;
        uint256 _value = amount;
        bytes memory _bytes = "0x02";
        (bool success, bytes memory returndata) = address(investToken).call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", _from, _to, _nftId, _value, _bytes));
        if (!success)
            revert();
    }
}

contract TreaPoolToken is Wrapper, Ownable {

    IERC20 public rewardToken; 
    uint256 public constant DURATION = 100 days; 
    uint256 public constant DEV_FUND_PERCENT = 5; 

    uint256 public starttime; 
    uint256 public periodFinish = 0; 
    uint256 public rewardRate = 0; 
    uint256 public lastUpdateTime; 
    uint256 public rewardPerTokenStored; 

    address public devFundAddress; 

    mapping(address => uint256) public userRewardPerTokenPaid; 
    mapping(address => uint256) public rewards; 
    mapping(address => uint256) public deposits; 

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RiskFundRewardPaid(address indexed user, uint256 reward);
    event DevFundRewardPaid(address indexed user, uint256 reward);
    event ReferralRewardPaid(address indexed user, address indexed referral, uint256 reward);

    constructor(
        address rewardToken_,
        address investToken_,
        address devFundAddress_,
        uint256 starttime_
    ) public {
        rewardToken = IERC20(rewardToken_);
        investToken = investToken_;
        devFundAddress = devFundAddress_;
        starttime = starttime_;

        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
      
    }


    modifier checkStart() {
        require(block.timestamp >= starttime, 'Pool: not start');
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'OSCHUSDPool: Cannot stake 0');
        uint256 newDeposit = deposits[msg.sender].add(amount);
        deposits[msg.sender] = newDeposit;
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'OSCHUSDPool: Cannot withdraw 0');
        deposits[msg.sender] = deposits[msg.sender].sub(amount);
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;


            uint256 devPaid = reward.mul(DEV_FUND_PERCENT).div(100);
            uint256 actualPaid = reward;

            if(devFundAddress != address(0) && devPaid > 0){
               actualPaid = actualPaid.sub(devPaid);
               rewardToken.safeTransfer(devFundAddress, devPaid);
               emit DevFundRewardPaid(devFundAddress, devPaid);     
            }

            rewardToken.safeTransfer(msg.sender, actualPaid);
            emit RewardPaid(msg.sender, actualPaid);
        }
    }


    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }

        _checkRewardRate();
    }

    function _checkRewardRate() internal view returns (uint256) {
        return DURATION.mul(rewardRate).mul(1e18);
    }

}