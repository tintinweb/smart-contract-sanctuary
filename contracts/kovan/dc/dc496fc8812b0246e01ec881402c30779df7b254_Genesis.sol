/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity ^0.5.0;

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


pragma solidity ^0.5.0;

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
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

pragma solidity ^0.5.16;

interface IERC165 {
    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) { return 0; }
    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
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


pragma solidity ^0.5.16;

library Address {
    bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    function isContract(address _address) internal view returns (bool) {
        bytes32 codehash;
        assembly { codehash := extcodehash(_address) }
        return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

contract ERC1155 is IERC165, IERC1155 {
    using SafeMath for uint256;
    using Address for address;
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    mapping (address => mapping(uint256 => uint256)) internal balances;
    
    /*-----------------------------------------------------------*/
    uint256 [] internal balancesList;
    uint256 [] internal onSaleBalancesList;
    uint256 [] internal pricesList;
    address [] internal ownerAddressList;
    
    mapping (address => mapping(uint256 => uint256)) internal onSaleBalances;
    mapping (address => mapping(uint256 => uint256)) internal prices;
    /*-----------------------------------------------------------*/
    
    

    
    mapping (address => mapping(address => bool)) internal operators;
    
    
    

    /*-----------------------------------------------------------*/
    function onSale(address _from, uint256 _id, uint256 _amount, uint256 _price) public {
        uint256 _balance = balanceOf(_from, _id);
        uint256 _onSaleBalance = onSaleBalanceOf(_from, _id);
        
        require(_amount <= _balance.sub(_onSaleBalance),"balance is not enough");
       
        onSaleBalances[_from][_id] = onSaleBalances[_from][_id].add(_amount); 
        prices[_from][_id] = _price;
        
        onSaleBalancesList[_id-1].add(_amount); 
        pricesList[_id-1] = _price;
    }
    
    function offSale(address _from, uint256 _id, uint256 _amount) public {
        uint256 _onSaleBalance = onSaleBalanceOf(_from, _id);
            
        require( (_onSaleBalance > 0) && (_amount <= _onSaleBalance),"balance should bigger than 0 and amout should smaller than onSaleBalance");
           
        onSaleBalances[_from][_id] = onSaleBalances[_from][_id].sub(_amount);
        
        onSaleBalancesList[_id-1].sub(_amount); 
    }
  
    /*-----------------------------------------------------------*/

    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
    {
        balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
        balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

        /*--------------------------------*/
        ownerAddressList[_id-1] = _to;
        /*--------------------------------*/
        
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
    {
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received.gas(_gasLimit)(msg.sender, _from, _id, _amount, _data);
            require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
        }
    }

    function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
    {
        require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

        uint256 nTransfer = _ids.length;

        for (uint256 i = 0; i < nTransfer; i++) {
            balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
            balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

 
    function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
    {
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived.gas(_gasLimit)(msg.sender, _from, _ids, _amounts, _data);
            require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
        }
    }


    function setApprovalForAll(address _operator, bool _approved)
    external
    {
      
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }


    function isApprovedForAll(address _owner, address _operator)
    public view returns (bool isOperator)
    {
        return operators[_owner][_operator];
    }


    function balanceOf(address _owner, uint256 _id)
    public view returns (uint256)
    {
        return balances[_owner][_id];
    }

    /*-----------------------------------------------------------*/
    
    function onSaleBalanceOf(address _owner, uint256 _id)
    public view returns (uint256)
    {
        return onSaleBalances[_owner][_id];
    }

    function priceOf(address _owner, uint256 _id)
    public view returns (uint256)
    {
        return prices[_owner][_id];
    }
    
    /*-----------------------------------------------------------*/
 
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public view returns (uint256[] memory)
    {
        require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");
        uint256[] memory batchBalances = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }


    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

 
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
            return true;
        }
        return false;
    }
}

contract ERC1155Metadata {
    string internal baseMetadataURI;
    event URI(string _uri, uint256 indexed _id);
  function uri(uint256 _id) public view returns (string memory) {
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
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;
    while (ii != 0) {
      bstr[k--] = byte(uint8(48 + ii % 10));
      ii /= 10;
    }
    return string(bstr);
  }
}

contract ERC1155MintBurn is ERC1155 {

    function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
    {
        balances[_to][_id] = balances[_to][_id].add(_amount);
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);
        _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
    }

    function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
    {
        require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");
        uint256 nMint = _ids.length;
        for (uint256 i = 0; i < nMint; i++) {
            balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
        }

        emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);
        _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
    }


    function _burn(address _from, uint256 _id, uint256 _amount)
    internal
    {
        require(_amount>=balances[_from][_id].sub(onSaleBalances[_from][_id]), "balance is not enough, can not burn");
        balances[_from][_id] = balances[_from][_id].sub(_amount);
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
    }


    function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
    {
        uint256 nBurn = _ids.length;
        require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");
        for (uint256 i = 0; i < nBurn; i++) {
            balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
        }
        emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
    }
}

library Strings {
 
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

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender, "CRCN: ONLY_CREATOR_ALLOWED");
        _;
    }

   
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

    /*------------------------------------------------------------------------------*/
    
    function getNftInfos(uint256 _id)
    public view returns (address _ownerAddress, uint256 _balance, uint256 _onSaleNum, uint256 _price)
    {
        address ownerAddress = owners[_id]._values[0];
        uint256 balance = balances[ownerAddress][_id];
        uint256 onSaleNum = onSaleBalances[ownerAddress][_id];
        uint256 price = prices[ownerAddress][_id];
        return (ownerAddress, balance, onSaleNum, price);
    }
    
    /*------------------------------------------------------------------------------*/
    
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }
    
    function tokensOf(address owner) public view returns (uint256[] memory) {
        return holderTokens[owner]._values;
    }

    function getNextTokenID() public view returns (uint256) {
        return _currentTokenID.add(1);
    }

   
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
         
        /*--------------------------------*/
        ownerAddressList.push(_initialOwner);
        onSaleBalancesList.push(0);
        pricesList.push(0);
        /*--------------------------------*/
        
        return _id;
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) public {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
        require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");

        _safeTransferFrom(_from, _to, _id, _amount);
       
        if (balanceOf(_from, _id) == 0) {
            setRemove(_from, _id);
        }

        setAdd(_to, _id);
        
    }

    
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
        public
    {
        
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
    ) public view returns (bool isOperator) {

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
           
            holderTokens[owner]._indexes[value] = holderTokens[owner]._values.length;

            owners[value]._values.push(owner);
            owners[value]._indexes[owner] = owners[value]._values.length;

            return true;
        } else {
            return false;
        }
    }

  
    function setRemove(address owner, uint256 value) internal returns (bool) {
       
        uint256 valueIndex = holderTokens[owner]._indexes[value];
        uint256 ownerIndex = owners[value]._indexes[owner];

        if (valueIndex != 0) {
         
            uint256 toDeleteValueIndex = valueIndex - 1;
            uint256 lastIndex = holderTokens[owner]._values.length - 1;
            uint256 lastValue = holderTokens[owner]._values[lastIndex];
            holderTokens[owner]._values[toDeleteValueIndex] = lastValue;
            holderTokens[owner]._indexes[lastValue] = toDeleteValueIndex + 1; 
            holderTokens[owner]._values.pop();
            delete holderTokens[owner]._indexes[value];

            uint256 toDeleteOwnerIndex = ownerIndex - 1;
            lastIndex = owners[value]._values.length - 1;
            address lastAddress = owners[value]._values[lastIndex];
            owners[value]._values[toDeleteOwnerIndex] = lastAddress;
            owners[value]._indexes[lastAddress] = toDeleteOwnerIndex + 1; 
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


pragma solidity 0.5.16;

contract Genesis is CRCN, IERC777Sender {
    event Opened(address indexed account, uint256 id, uint256 categoryId);
    event Forged(address indexed account, uint256[] ids, uint256 bounty);
    address public devAddr;
    constructor( address _devAddr, string memory _baseMetadataURI)
        CRCN("Angel Universe", "NFT")
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
    ) public
    {
        require(from == address(this), "Genesis: deposit not authorized");
    }

    function setDevAddr(address _devAddr) public onlyOwner {
        devAddr = _devAddr;
    }

    function uri(uint256 _id) public view returns (string memory) {
        return _getUri(_id);
    }

    /*
    function batchCreateNFT(
        address[] calldata _initialOwners,
        string[] calldata _uris,
        bytes calldata _data
    ) external onlyOwner returns (uint256[] memory tokenIds) {
        require(_initialOwners.length == _uris.length, "Genesis: uri length mismatch");

        tokenIds = new uint256[](_initialOwners.length);
        for (uint i = 0; i < _initialOwners.length; i++) {
            tokenIds[i] = createNFT(_initialOwners[i], _uris[i], _data);
        }
    }
    */
    
    function getNftsOnSaleBalance()
    public view returns (uint256 [] memory)
    {
        return onSaleBalancesList;
    }
    
    function getNftsPrice()
    public view returns (uint256 [] memory)
    {
        return pricesList;
    }
    
    function getNftsAddress()
    public view returns (address [] memory)
    {
        return ownerAddressList;
    }
    
    function createNFT(
        address _initialOwner,
        string memory _uri,
        bytes memory _data
    ) public onlyOwner returns (uint256 tokenId) {
        tokenId = create(_initialOwner, 1, 1, _uri, _data);
    }
}