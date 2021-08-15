//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface ERC165 {
	function supportsInterface(bytes4 interfaceID) external view returns(bool);
}
interface ERC721 is ERC165 {
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	function balanceOf(address _owner) external view returns(uint256);
	function ownerOf(uint256 _tokenId) external view returns(address);
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
	function transferFrom(address _from, address _to, uint256 _tokenId) external;
	function approve(address _approved, uint256 _tokenId) external;
	function setApprovedForAll(address _operator, bool _approved) external;
	function isApprovedForAll(address _owner, address _operator) external view returns(bool);
}
interface ERC721TokenReceiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
interface ERC721Metadata is ERC721 {
	function name() external view returns(string memory);
	function symbol() external view returns (string memory);
	function tokenURI(uint256 tokenId) external view returns(string memory);
}
abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}
	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
}
abstract contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor() {
		_setOwner(_msgSender());
	}
	function owner() public view virtual returns(address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(owner() == _msgSender(), 'Error: not the owner');
		_;
	}
	function renounceOwnership() public virtual onlyOwner {
		_setOwner(address(0));
	}
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), 'Error: new owner is zero address');
		_setOwner(newOwner);
	}
	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}
library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Insufficient balance');
    (bool success, ) = recipient.call{value:amount}('');
    require(success, 'Unable to send value, recipient may have reverted');
  }
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }
  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, 'Insufficient balance for call');
    require(isContract(target), 'Call to non-contract');
    (bool success, bytes memory returndata) = target.call{value:value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }
  function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
    require(isContract(target), 'Static call to non-contract');
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }
  function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    require(isContract(target), 'Delegate call to non-contract');
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }
  function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
    if(success) {
      return returndata;
    } else {
      if(returndata.length >0) {
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
library Strings {
  bytes private constant _HEX_SYMBOLS = '0123456789abcdef';

  function toString(uint256 value) internal pure returns (string memory) {
    if(value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while(temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while(value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = '0';
    buffer[1] = 'x';
    for(uint256 i = 2 * length +1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, 'Hex length insufficient');
    return string(buffer);
  }
}
contract LongIslandLadies is ERC165, ERC721, ERC721TokenReceiver, ERC721Metadata, Context, Ownable {
	using Address for address;
	using Strings for uint256;

	string private _name = 'Long Island Ladies';
	string private _symbol = 'LIL';
	uint256 Total;
	uint256 Fee = 0.02 ether;
	string private BaseURI;

	mapping(uint256 => string) private _tokenURIs;
	mapping(uint256 => address) private _owners;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => bool)) _operatorApprovals;

	struct Ladies{string name; uint256 Experience; uint256 Attractiveness; uint256 Loyalty;  
		uint256 Kissing; uint256 Oral; uint256 Anal; uint256 Kinks;}

		Ladies[] public ladies;

	event CreateLadies(address indexed owner, uint256 Experience, uint256 Attractiveness, uint256 Loyalty,  
		uint256 Kissing, uint256 Oral, uint256 Anal, uint256 Kinks);

	constructor() {
	}
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(ERC721).interfaceId ||
            interfaceId == type(ERC721TokenReceiver).interfaceId ||
            interfaceId == type(ERC721Metadata).interfaceId ||
            supportsInterface(interfaceId);
    }
	function balanceOf(address _owner) public view virtual override returns(uint256) {
		return _balances[_owner];
	}
	function ownerOf(uint256 _tokenId) public view virtual override returns(address) {
		address _owner = _owners[_tokenId];
		return _owner;
	}
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
		transferFrom(_from, _to, _tokenId);
	}
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public virtual override {
		safeTransferFrom(_from, _to, _tokenId, _data);
	}
	function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
		require(ownerOf(_tokenId) == _from, 'Error: only owner can transfer');
		require(_to != address(0), 'Error: Tranfering to none existing address');
		approve(address(0), _tokenId);
		_balances[_from] -= 1;
		_balances[_to] += 1;
		_owners[_tokenId] = _to;
		emit Transfer(_from, _to, _tokenId);
	}
	function approve(address _to, uint256 _tokenId) public virtual override {
		address _owner = ownerOf(_tokenId);
		require(_to != _owner, 'Error: you are already approved');
		require(_msgSender() == _owner || isApprovedForAll(_owner, _msgSender()), 'Error: not approved');
		_tokenApprovals[_tokenId] = _to;
		emit Approval(ownerOf(_tokenId), _to, _tokenId);
	}
	function setApprovedForAll(address _operator, bool _approved) public virtual override {
		require(_operator != _msgSender(), 'Error: caller is approved');
		_operatorApprovals[_msgSender()][_operator] = _approved;
		emit ApprovalForAll(_msgSender(), _operator, _approved);
	}
	function isApprovedForAll(address _owner, address _operator) public view virtual override returns(bool) {
		return _operatorApprovals[_owner][_operator];
	}
	function onERC721Received(address, address, uint256, bytes calldata) external pure override returns(bytes4) {
		return bytes4(keccak256("onERC721Received(address,address,uint256,bytes calldata)"));
	}
	function name() public view virtual override returns(string memory) {
		return _name;
	}
	function symbol() public view virtual override returns(string memory) {
		return _symbol;
	}
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		string memory _tokenURI = _tokenURIs[tokenId];
		string memory base = baseURI();
		if (bytes(base).length == 0) {
		return _tokenURI;
	}
		if (bytes(_tokenURI).length > 0) {
		return string(abi.encodePacked(base, _tokenURI));
	}
		return tokenURI(tokenId);
	}
	function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
		baseTokenURI(tokenId, _tokenURI);
	}
	function baseTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
		_tokenURIs[tokenId] = _tokenURI;
	}
	function baseURI() internal view virtual returns (string memory) {
        return "";
    }      
	function mint(address _to, uint256 _tokenId) internal virtual {
	  require(_to != address(0), 'Error: address does not exist');
	  _balances[_to] += 1;
	  _owners[_tokenId] = _to;
	  emit Transfer(address(0), _to, _tokenId);
	}
	function burn(uint256 _tokenId) internal {
	address _owner = ownerOf(_tokenId);
	  approve(address(0), _tokenId);
	  _balances[_owner] -= 1;
	  delete _owners[_tokenId];
	  emit Transfer(_owner, address(0), _tokenId);
	}
	function rNumber(uint256 mod) internal view returns(uint256) {
	uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
	return randomNum % mod;
	}
	function updateFee(uint256 _fee) external onlyOwner {
		Fee = _fee;
	}
	function buildLadies(string memory nameOf) public {
		uint256 rExperience = rNumber(50);
		uint256 rAttractiveness = rNumber(999);
		uint256 rLoyalty = rNumber(998);
		uint256 rKissing = rNumber(997);
		uint256 rOral = rNumber(996);
		uint256 rAnal = rNumber(995);
		uint256 rKinks = rNumber(994);
		Ladies memory addLadies = Ladies(nameOf,rExperience, rAttractiveness, rLoyalty, rKissing, rOral, rAnal, rKinks);
		ladies.push(addLadies);
		mint(msg.sender, Total);
		emit CreateLadies(msg.sender, rExperience, rAttractiveness, rLoyalty, rKissing, rOral, rAnal, rKinks);
		Total++;
	}
	function cost(string memory nameOf) public payable {
		require(msg.value >= Fee);
		buildLadies(nameOf);
	}
	function obtainLadies() public view returns (Ladies[] memory) {
		return ladies;
	}
	function obtainOwnerLadies(address _owner) public view returns(Ladies[] memory) {
		Ladies[] memory result = new Ladies[](balanceOf(_owner));
		uint256 total = 0;
		for(uint256 i = 0; i < ladies.length; i++) {
			if(ownerOf(i) == _owner) {
				result[total] = ladies[i];
				total++;
			}
		}
		return result;
	}
	function ExperienceIncrease(uint256 ladiesId) public {
		require(ownerOf(ladiesId) == msg.sender);
		Ladies storage lady = ladies[ladiesId];
		lady.Experience++;
	}
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}