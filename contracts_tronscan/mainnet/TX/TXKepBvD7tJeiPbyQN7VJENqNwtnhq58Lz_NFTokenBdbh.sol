//SourceUnit: NFT.sol

pragma solidity >=0.5.1;

/**
 * @dev ERC-721 non-fungible token standard. 
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function approve(address _approved, uint256 _tokenId) external;
  function setApprovalForAll(address _operator, bool _approved) external;
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/**
 * @dev ERC-721 interface for accepting safe transfers. 
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver
{
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/**
 * @dev Math operations with safety checks that throw on error. This contract is based on the 
 * source code at: 
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol.
 */
library SafeMath
{
  function mul(uint256 _factor1, uint256 _factor2) internal pure returns (uint256 product)
  {
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2);
  }

  function div(uint256 _dividend, uint256 _divisor) internal pure returns (uint256 quotient)
  {
    require(_divisor > 0);
    quotient = _dividend / _divisor;
  }

  function sub(uint256 _minuend, uint256 _subtrahend) internal pure returns (uint256 difference)
  {
    require(_subtrahend <= _minuend);
    difference = _minuend - _subtrahend;
  }

  function add(uint256 _addend1, uint256 _addend2) internal pure returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1);
  }

  function mod(uint256 _dividend, uint256 _divisor) internal pure returns (uint256 remainder) 
  {
    require(_divisor != 0);
    remainder = _dividend % _divisor;
  }
}

/**
 * @dev A standard for detecting smart contract interfaces. 
 * See: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md.
 */
interface ERC165
{
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is ERC165
{
  mapping(bytes4 => bool) internal supportedInterfaces;

  constructor() public 
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  function supportsInterface(bytes4 _interfaceID) external view returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }
}

/**
 * @dev Utility library of inline functions on addresses.
 */
library AddressUtils
{
  function isContract(address _addr) internal view returns (bool addressCheck)
  {
    uint256 size;

    assembly { size := extcodesize(_addr) } // solhint-disable-line
    addressCheck = size > 0;
  }

}

/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract NFToken is ERC721, SupportsInterface
{
  using SafeMath for uint256;
  using AddressUtils for address;

  string public name = "BIDANFT";
  string public symbol = "BDNFT";

  bytes4 private constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  mapping (uint256 => address) internal idToOwner;
  mapping (uint256 => address) internal idToApprovals;
  mapping (address => uint256) private ownerToNFTokenCount;
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  modifier canOperate(uint256 _tokenId) 
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
    _;
  }

  modifier canTransfer(uint256 _tokenId) 
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApprovals[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender]
    );
    _;
  }

  modifier validNFToken(uint256 _tokenId)
  {
    require(idToOwner[_tokenId] != address(0));
    _;
  }

  constructor() public
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);
  }

  function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner);

    idToApprovals[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) external
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf(address _owner) external view returns (uint256)
  {
    require(_owner != address(0));
    return _getOwnerNFTCount(_owner);
  }

  function ownerOf(uint256 _tokenId) external view returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0));
  }

  function getApproved(uint256 _tokenId) external view validNFToken(_tokenId) returns (address)
  {
    return idToApprovals[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) external view returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  function _transfer(address _to, uint256 _tokenId) internal
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }
   
  function _mint(address _to, uint256 _tokenId) internal
  {
    require(_to != address(0));
    require(idToOwner[_tokenId] == address(0));

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  function _burn(uint256 _tokenId) internal validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }

  function _removeNFToken(address _from, uint256 _tokenId) internal
  {
    require(idToOwner[_tokenId] == _from);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
  }

  function _addNFToken(address _to, uint256 _tokenId) internal
  {
    require(idToOwner[_tokenId] == address(0));

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }

  function _getOwnerNFTCount(address _owner) internal view returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);

    if (_to.isContract()) 
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED);
    }
  }

  function _clearApproval(uint256 _tokenId) private
  {
    if (idToApprovals[_tokenId] != address(0))
    {
      delete idToApprovals[_tokenId];
    }
  }
}

/**
 * @dev This is an contract implementation of NFToken.
 */
contract NFTokenBdbh is NFToken
{
	address public wrapper;
	address public dev;

	constructor(address _dev) public {
		require(_dev != address(0), "dev can't be zero");
		dev = _dev;
	}

	modifier onlyDeveloper() {
	    require(msg.sender == dev);
	    _;
	}

	function setDev(address _dev) external onlyDeveloper {
		require(_dev != address(0), "dev can't be zero");
		dev = _dev;
	}

	function setWrapper(address _wrapper) external onlyDeveloper {
		require(_wrapper != address(0), "wrapper can't be zero");
		wrapper = _wrapper;
	}

    function mint(address _to, uint256 _tokenId) external
    {
    	require(wrapper != address(0) && msg.sender == wrapper, "only wrapper can mint");
        super._mint(_to, _tokenId);
    }

    // function burn(uint256 _tokenId) external
    // {
    //     super._burn(_tokenId);
    // }
}