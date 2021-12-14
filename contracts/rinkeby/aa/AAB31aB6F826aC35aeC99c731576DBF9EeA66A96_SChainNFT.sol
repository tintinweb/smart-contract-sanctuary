/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

interface IERC721Base {
 
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256);
 
  function ownerOf(uint256 _tokenId) external view returns (address);
  
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external payable;

  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

  function approve(address _approved, uint256 _tokenId) external payable;
  
  function setApprovalForAll(address _operator, bool _approved) external;
  
  function getApproved(uint256 _tokenId) external view returns (address);

  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes memory _data) external returns (bytes4);
}

interface IERC721Metadata {

  function name() external view returns (string memory _name);


  function symbol() external view returns (string memory _symbol);

  
  function totalSupply() external view returns (uint256);

}

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

library SafeMath {
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract SChainNFT is IERC721Base,IERC721Metadata,IERC721TokenReceiver{

  using Counters for Counters.Counter;
  
  Counters.Counter private _tokenIds;
  
  using SafeMath for uint256;

  uint256 private _totalTokens;
  
  string private _name;

  string private _symbol;
  
  address private contractAddress;
  
  mapping (uint256 => string) private _tokenURIs;

  mapping (address => uint256[]) private _ownedTokens;
  
  mapping (uint256 => uint256) private _overallTokenId;
  
  mapping (uint256 => uint256) private _overallTokenIndex;

  mapping (uint256 => address) private _tokenOwner;
  
  mapping (uint256 => address) private _tokenApproval;
  
  mapping (address => mapping (address => bool)) private _tokenOperator;
  
  mapping (uint256 => uint256) private _ownedTokenIndex;


    constructor(){
         contractAddress = msg.sender;
         _name = "Metaverse Tokens";
         _symbol = "MNFT";
    }
    
    modifier onlyTokenAuthorized(uint256 _tokenId) {
        require(
          _isTokenOwner(msg.sender, _tokenId) ||
            _isTokenOperator(msg.sender, _tokenId) ||
            _isApproved(msg.sender, _tokenId)
          , "ERROR: not token authorized"
        );
        _;
    }
    
    modifier mustBeValidToken(uint256 _tokenId) {
        require(_tokenOwner[_tokenId] != address(0), "ERROR: valid token id");
        _;
    }
    
    modifier onlyTokenOwnerOrOperator(uint256 _tokenId) {
        require(_isTokenOwner(msg.sender, _tokenId) || _isTokenOperator(msg.sender, _tokenId), 
            "ERROR: not token owner or operator");
        _;
    }
    
    function _isTokenOperator(address _operatorToCheck, uint256 _tokenId) private view returns (bool) {
        return _tokenOperator[_tokenOwner[_tokenId]][_operatorToCheck];
    }
    
    function _isApproved(address _approvedToCheck, uint256 _tokenId) private view returns (bool) {
        return _tokenApproval[_tokenId] == _approvedToCheck;
    }
    
    function onERC721Received(address, uint256, bytes memory) override pure external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() override external view returns (uint256) {
        return _totalTokens;
    }

    function balanceOf(address _owner) override external view returns (uint256) {
        return _ownedTokens[_owner].length;
    }

    function ownerOf(uint256 _tokenId) override external view mustBeValidToken(_tokenId)  returns (address) {
        return _tokenOwner[_tokenId];
    }
    
    function approve(address _approved,uint256 _tokenId) override external payable mustBeValidToken(_tokenId) onlyTokenOwnerOrOperator(_tokenId) {
        address _owner = _tokenOwner[_tokenId];
        require(_owner != _approved, "ERROR: address error");
        require(_tokenApproval[_tokenId] != _approved, "ERROR: address error");
        _tokenApproval[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }
    
    function getApproved(uint256 _tokenId) override external view mustBeValidToken(_tokenId) returns (address) {
        return _tokenApproval[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) override external view returns (bool) {
        return _tokenOperator[_owner][_operator];
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) override external payable {
        _transferFrom(_from, _to, _tokenId, _data, true);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) override external payable {
        _transferFrom(_from, _to, _tokenId, "", false);
    }
    
    function setApprovalForAll(address _operator, bool _approved) override external {
        require(_tokenOperator[msg.sender][_operator] != _approved, "ERROR: operator error");
        _tokenOperator[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function _isTokenOwner(address _ownerToCheck, uint256 _tokenId) private view returns (bool) {
        return _tokenOwner[_tokenId] == _ownerToCheck;
    }
    
    function _transferFrom(address _from,address _to,uint256 _tokenId,bytes memory _data,bool _check) mustBeValidToken(_tokenId) onlyTokenAuthorized(_tokenId) internal{
        require(_isTokenOwner(_from, _tokenId), "ERROR: authorized error");
        require(_to != address(0), "ERROR: address 0");
        require(_to != _from, "ERROR: from equals to");
        _removeTokenFrom(_from, _tokenId);
        delete _tokenApproval[_tokenId];
        emit Approval(_from, address(0), _tokenId);
        _addTokenTo(_to, _tokenId);
        if (_check && _isContract(_to)) {
          IERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, _data);
        }
        emit Transfer(_from, _to, _tokenId);
    }
    
    function _isContract(address _address) private view returns (bool) {
        uint _size;
        // solium-disable-next-line security/no-inline-assembly
        assembly { _size := extcodesize(_address) }
        return _size > 0;
    }
    
    function _removeTokenFrom(address _from, uint256 _tokenId) private {
        require(_from != address(0), "ERROR: address 0");
        uint256 _tokenIndex = _ownedTokenIndex[_tokenId];
        uint256 _lastTokenIndex = _ownedTokens[_from].length.sub(1);
        uint256 _lastTokenId = _ownedTokens[_from][_lastTokenIndex];
        _tokenOwner[_tokenId] = address(0);
        _ownedTokens[_from][_tokenIndex] = _lastTokenId;
        _ownedTokenIndex[_lastTokenId] = _tokenIndex;
        // Resize the array.
        _ownedTokens[_from].pop();
    
        // Remove the array if no more tokens are owned to prevent pollution.
        if (_ownedTokens[_from].length == 0) {
          delete _ownedTokens[_from];
        }
        // Update the index of the removed token.
        delete _ownedTokenIndex[_tokenId];
    }
    
    function _addTokenTo(address _to, uint256 _tokenId) private {
        require(_to != address(0), "ERROR: address 0");
        _tokenOwner[_tokenId] = _to;
        uint256 length = _ownedTokens[_to].length;
        _ownedTokens[_to].push(_tokenId);
        _ownedTokenIndex[_tokenId] = length;
    }
    
    function _mint(address _to, uint256 _tokenId) internal {
        require(_tokenOwner[_tokenId] == address(0), "ERROR: address 0");
        _addTokenTo(_to, _tokenId);
        _overallTokenId[_totalTokens] = _tokenId;
        _overallTokenIndex[_tokenId] = _totalTokens;
        _totalTokens = _totalTokens.add(1);
        emit Transfer(address(0), _to, _tokenId);
    }
    
    function createToken(string memory _tokensURI) public returns(uint256){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        require(_tokenOwner[newItemId] != address(0));
        _tokenURIs[newItemId] = _tokensURI;
        _tokenOperator[msg.sender][contractAddress] = true;
        emit ApprovalForAll(msg.sender, contractAddress, true);
        return newItemId;
    }
    
    function _burn(uint256 _tokenId) public {
        
        address _from = _tokenOwner[_tokenId];
    
        require(_from != address(0) && _from == msg.sender, "ERROR: token is not owned");
    
        _removeTokenFrom(_from, _tokenId);
        _totalTokens = _totalTokens.sub(1);
    
        uint256 _tokenIndex = _overallTokenIndex[_tokenId];
        uint256 _lastTokenId = _overallTokenId[_totalTokens];
    
        delete _overallTokenIndex[_tokenId];
        delete _overallTokenId[_totalTokens];
        _overallTokenId[_tokenIndex] = _lastTokenId;
        _overallTokenIndex[_lastTokenId] = _tokenIndex;
    
        emit Transfer(_from, address(0), _tokenId);
    }
  
    function getContractAddr() public view returns(address){
        return contractAddress;
    }
}