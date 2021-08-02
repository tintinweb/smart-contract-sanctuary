/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

pragma solidity >=0.5.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
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

library Address {
  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { codehash := extcodehash(account) }
    return (codehash != 0x0 && codehash != accountHash);
  }

}

library Strings {
	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c,
		string memory _d,
		string memory _e
	) internal pure returns (string memory) {
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		bytes memory _bc = bytes(_c);
		bytes memory _bd = bytes(_d);
		bytes memory _be = bytes(_e);
		string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
		bytes memory babcde = bytes(abcde);
		uint256 k = 0;
		for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
		for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
		for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
		for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
		for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
		return string(babcde);
	}

	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c,
		string memory _d
	) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, _d, "");
	}

	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c
	) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, "", "");
	}

	function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
		return strConcat(_a, _b, "", "", "");
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len - 1;
		while (_i != 0) {
			bstr[k--] = bytes1(uint8(48 + (_i % 10)));
			_i /= 10;
		}
		return string(bstr);
	}
}

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
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == owner;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

interface IERC1155TokenReceiver {
  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more than 5,000 gas.
   * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
   */
  function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

interface IERC1155 {
  // Events

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
   * @dev MUST emit when the URI is updated for a token ID
   *   URIs are defined in RFC 3986
   *   The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema"
   */
  event URI(string _amount, uint256 indexed _id);

  /**
   * @notice Transfers amount of an _id from the _from address to the _to address specified
   * @dev MUST emit TransferSingle event on success
   * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
   * MUST throw if `_to` is the zero address
   * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
   * MUST throw on any other error
   * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev MUST emit TransferBatch event on success
   * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
   * MUST throw if `_to` is the zero address
   * MUST throw if length of `_ids` is not the same as length of `_amounts`
   * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
   * MUST throw on any other error
   * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  
  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return           True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);

}

contract ERC1155 is IERC165 {
  using SafeMath for uint256;
  using Address for address;


  /***********************************|
  |        Variables and Events       |
  |__________________________________*/
  MarketPlace public marketplace;
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  mapping (address => mapping(uint256 => uint256)) internal balances;

  mapping (address => mapping(address => bool)) internal operators;

  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event URI(string _uri, uint256 indexed _id);


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender) || (msg.sender == address(marketplace)), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, _data);
  }
  
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
  }

  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }
  
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
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

  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

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


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  function balanceOf(address _owner, uint256 _id)
    public view returns (uint256)
  {
    return balances[_owner][_id];
  }

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


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
   */
  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

  /**
   * INTERFACE_SIGNATURE_ERC1155 =
   * bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
   * bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
   * bytes4(keccak256("balanceOf(address,uint256)")) ^
   * bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
   * bytes4(keccak256("setApprovalForAll(address,bool)")) ^
   * bytes4(keccak256("isApprovedForAll(address,address)"));
   */
  bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
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

  /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

  function uri(uint256 _id) public view returns (string memory) {
    return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
  }


  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseMetadataURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }

  function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs) internal {
    require(_tokenIDs.length == _URIs.length, "ERC1155Metadata#_logURIs: INVALID_ARRAYS_LENGTH");
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      emit URI(_URIs[i], _tokenIDs[i]);
    }
  }

  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }


  /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

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

contract ERC1155MintBurn is ERC1155 {
  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    balances[_to][_id] = balances[_to][_id].add(_amount);

    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
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

    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    uint256 nBurn = _ids.length;
    for (uint256 i = 0; i < nBurn; i++) {
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }

}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

contract Random {
    uint256 radex = 66;
    
    function _random (uint256 range, uint256 time, bytes32 data) internal view returns (uint256) {
        uint256 key = uint256(keccak256(abi.encodePacked(blockhash(block.number), radex, uint256(21), time, data)));
        return key%range;
    }
    
    function _radex(address player, uint256 time) internal returns (uint256) {
        if(radex > 256) {
            radex = radex/(_random(uint256(keccak256(abi.encodePacked(time, player)))%radex, time, "radex"));
        } else {
            radex = radex + uint256(blockhash(block.number - radex))%radex;
        }
    } 
    
    function random(uint256 range, string memory data) internal returns (uint256) {
        _radex(msg.sender, uint256(now));
        bytes32 hash = keccak256(abi.encodePacked(data));
        return _random(range, uint256(now), hash);
    }
}

contract ERC1155Tradable is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable, Random {
    using Strings for string;
    
    event NFTGenerated(uint256 indexed _nft, bytes4[4] indexed _seeds);
    event NewNFTPrice(uint256 indexed _newprice);
    
	address proxyRegistryAddress;
	uint256 public totalNFTs;
	uint256 public NFTprice = 1 ether;
	string public name;
	string public symbol;
    
    struct NFT {
        bytes4 headseed;
        bytes4 bodyseed;
        bytes4 limbseed;
        bytes4 weaponseed;
    }
    
    NFT[] NFTs;
    
    uint256 public maxSigns = 5;
    struct Sign {
        address signer;
        string signature;
    }
    
    mapping (uint256 => address) NFTtoCreator;
    mapping (address => bool) public ifAirdropped;
    mapping (address => uint256) public OwnBoxes;
    mapping (address => mapping(uint256 => bytes8)) BoxLabels;
    mapping (uint256 => mapping(address => bool)) public ifSignedNFT;
    mapping (uint256 => uint256) public NFTtoTotalSigned;
    mapping (uint256 => Sign[]) NFTtoSign;
    
	constructor(
		string memory _name,
		string memory _symbol,
		uint256 _totalNFTs,
		address _proxyRegistryAddress
	) public {
		name = _name;
		symbol = _symbol;
		totalNFTs = _totalNFTs;
		proxyRegistryAddress = _proxyRegistryAddress;
		
	}
	
	function setProxyAddress(address _proxyAddress) public onlyOwner {
	    proxyRegistryAddress = _proxyAddress;
	}

	function uri(uint256 _id) public view returns (string memory) {
		require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
		return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id));
	}

	function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyOwner {
		_setBaseMetadataURI(_newBaseMetadataURI);
	}
    
    function _exists(uint256 _id) internal view returns (bool) {
		return NFTtoCreator[_id] != address(0);
    }
    
    function setNFTprice(uint256 _price) public onlyOwner {
        NFTprice = _price;
        emit NewNFTPrice( _price);
    }
    
    function addNFTCapacity(uint256 amount) public onlyOwner {
	    totalNFTs = totalNFTs + amount;
	}
	
	function airdrop(address[] memory _users) public onlyOwner {
	    for (uint256 i=0; i< _users.length; i++) {
	        ifAirdropped[_users[i]] = true;
	    }
	}
    
    function openNFT() public returns(uint256) {
        if (ifAirdropped[_msgSender()] == true) {
            ifAirdropped[_msgSender()] = false;
        } else {
            require(OwnBoxes[_msgSender()] > 0);
            OwnBoxes[_msgSender()] = OwnBoxes[_msgSender()].sub(1);
        }
        
        bytes4 headseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "HEAD"), "HEADSEED")));
        bytes4 bodyseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "BODY"), "BODYSEED")));
        bytes4 limbseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "LIMP"), "LIMPSEED")));
        bytes4 weaponseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "WEAPON"), "WEAPONSEED")));
        bytes4[4] memory seeds = [headseed, bodyseed, limbseed, weaponseed];
        
        NFT memory _NFT = NFT({
           headseed: headseed,
           bodyseed: bodyseed,
           limbseed: limbseed,
           weaponseed: weaponseed
        });
        NFTs.push(_NFT);
        uint256 nftId = NFTs.length - 1;
        _mint(msg.sender, nftId, 1, "");
        NFTtoCreator[nftId] = msg.sender;
        
        emit NFTGenerated(nftId, seeds);
        
        return nftId;
    }
    
    function getNFT(uint256 nftId) public view returns(
        bytes4 headseed,
        bytes4 bodyseed,
        bytes4 limbseed,
        bytes4 weaponseed
    ){
        NFT memory _NFT = NFTs[nftId];
        headseed = _NFT.headseed;
        bodyseed = _NFT.bodyseed;
        limbseed = _NFT.limbseed;
        weaponseed = _NFT.weaponseed;
    }
    
    function getNFTCreator(uint256 nftId) public view returns(address) {
        return NFTtoCreator[nftId];
    }
    
    function NFTleft() public view returns(uint256) {
        return SafeMath.sub(totalNFTs, NFTs.length);
    }

	function isApprovedForAll(address _owner, address _operator) public view returns (bool isOperator) {
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(_owner)) == _operator) {
			return true;
		}

		return ERC1155.isApprovedForAll(_owner, _operator);
	}
	
	function signNFT(uint256 nftId, string memory signature) public {
	    require(_exists(nftId), "NFT is not exist");
	    require(NFTtoTotalSigned[nftId] < maxSigns, "NFT reaches max signs");
	    require(balanceOf(msg.sender, nftId) > 0, "You do not own this NFT");
	    require(ifSignedNFT[nftId][msg.sender] == false, "You signed already");
	    ifSignedNFT[nftId][msg.sender] = true;
	    Sign memory sign = Sign({
	        signer:msg.sender,
	        signature: signature
	    });
	    NFTtoSign[nftId].push(sign);
	    NFTtoTotalSigned[nftId] += 1;
	}
	
	function setMaxSigns(uint256 _amount) public onlyOwner {
	    require(_amount > 0);
	    maxSigns = _amount;
	}
	
	function getSigns(uint256 nftId, uint256 index) public view returns(
        address,
        string memory
	){
	    Sign[] memory signs = NFTtoSign[nftId];
	    return (signs[index].signer, signs[index].signature);
	}
}

interface MarketPlace {
    function isMarket() external pure returns(bool);
    function createSale(uint256 _tokenId, uint256 _amount, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address payable _seller) external;
    function createAuction(uint256 _tokenId, uint256 _amount, uint256 _initialPrice, uint256 _duration, address payable _seller) external;
    function withdrawBalance() external;
}

contract HonHuangMarket is ERC1155Tradable {
    function setMarketPlaceAddress(address _address) external onlyOwner {
        MarketPlace candidateContract = MarketPlace(_address);

        require(candidateContract.isMarket());

        marketplace = candidateContract;
    }
    
    function createSale(
        uint256 _id,
        uint256 _amount,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
    {
        require(balanceOf(msg.sender, _id) >= _amount, "You do not have enough!");
        marketplace.createSale(
            _id,
            _amount,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
    
    function createAuction(
        uint256 _id,
        uint256 _amount,
        uint256 _initialPrice,
        uint256 _duration
    )
        external
    {
        marketplace.createAuction(
            _id,
            _amount,
            _initialPrice,
            _duration,
            msg.sender
        );
    }
    
    function withdrawMarketBalances() external onlyOwner {
        marketplace.withdrawBalance();
    }

}

interface USDTERC20 {
    function allowance(address owner, address spender) external returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract HonHuangLTD is HonHuangMarket {
    event BoughtMesteryBox(uint256 indexed boxNum, bytes8 indexed label);
    event RepickBox(uint256 indexed boxNum, bytes8 indexed label);
    
    USDTERC20 public usdtERC20;
    uint256 public usdtPrice = 50*10**6;
    uint256 public repickPrice = 1*10**6;
    
    function setUSDTAddress(address _address) external onlyOwner {
        USDTERC20 candidateContract = USDTERC20(_address);
        usdtERC20 = candidateContract;
    }
    
    function setUSDTPrice(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        usdtPrice = _amount;
    }
    
    function setRepickPrice(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        repickPrice = _amount;
    }
    
    function buyBoxwithUSDT() public returns(uint256) {
        require(usdtERC20.allowance(msg.sender, address(this)) >= usdtPrice, "Insuffcient approved USDT");
        usdtERC20.transferFrom(msg.sender, address(this), usdtPrice);
        
        uint256 nextBoxNum = OwnBoxes[msg.sender].add(1);
        bytes8 label = bytes8(keccak256(abi.encodePacked(random(totalNFTs, "Label"), msg.sender)));
        
        BoxLabels[msg.sender][nextBoxNum] = label;
        
        emit BoughtMesteryBox(nextBoxNum, label);
        
        return nextBoxNum;
    }
    
    function boxRePick(uint256 index) public {
        require(BoxLabels[msg.sender][index] != "");
        require(usdtERC20.allowance(msg.sender, address(this)) >= repickPrice, "Insuffcient approved USDT");
        usdtERC20.transferFrom(msg.sender, address(this), repickPrice);
        
        bytes8 label = bytes8(keccak256(abi.encodePacked(random(totalNFTs, "Label"), msg.sender)));
        BoxLabels[msg.sender][index] = label;
        
        emit RepickBox(index, label);
    }
    
    function getBoxLabel(uint256 index) public view returns(bytes8) {
        return BoxLabels[msg.sender][index];
    }
    
	constructor(address _proxyRegistryAddress) public ERC1155Tradable("HonHuang Ltd.", "HHG", 10000, _proxyRegistryAddress) {
		_setBaseMetadataURI("https://yanyi-test.oss-cn-hangzhou.aliyuncs.com/");
		usdtERC20 = USDTERC20(0xc2e0FCE0278aaE1034F1b8E50d22931a751538bD);
	}

	function contractURI() public pure returns (string memory) {
		return "https://yanyi-test.oss-cn-hangzhou.aliyuncs.com/honhuang-erc1155";
	}
	
	function withdrawBalance() external onlyOwner {
        owner.transfer(address(this).balance);
    }

}