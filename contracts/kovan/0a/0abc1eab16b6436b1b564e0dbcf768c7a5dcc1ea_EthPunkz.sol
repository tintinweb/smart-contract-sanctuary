// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.7.4;

import './Strings.sol';
import './SafeMath.sol';

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns(string memory);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to) external;
}

contract EthPunkz {

     using Strings for string;

     string private _name;
     string private _symbol;
     uint256 private _totalSupply;
     address public admin;

     mapping(uint256 => address) private _owners;
     mapping(address => uint256) private _balances;
     mapping(uint256 => address) private _tokenApprovals;
     mapping(address => mapping(address => bool)) private _operatorApprovals;
     mapping(uint256 => string) private _tokenURI;
     mapping(address => bool) private _governor;

     event Approval(address indexed from, address indexed to, uint256 tokenId);
     event ApprovalForAll(address indexed owner, address indexed operator,bool approved);
     event Transfer(address indexed from, address indexed to, uint256 tokenId);
    
     modifier exists(uint256 tokenId){
        require(
            _owners[tokenId] != address(0),"Invalid TokenId"
        );
        _;
     }

     modifier isAdmin(){
         require(
            msg.sender == admin, "Access Error : Caller Not Admin"
         );
         _;
     }

     modifier onlyGovernor(){
         require(
             _governor[msg.sender], "Access Error : Caller Not Governor"
         );
         _;
     }

     constructor(string memory name_ , string memory symbol_ , address admin_){
         _name = name_;
         _symbol = symbol_;
         admin = admin_;
     }

     function name() public view virtual returns(string memory){
         return _name;
     }

     function symbol() public view virtual returns(string memory){
         return _symbol;
     }

     function totalSupply() public view virtual returns(uint256){
         return _totalSupply;
     }

     function balanceOf(address owner) public view virtual returns(uint256){
         require(
             owner != address(0), "Query Error : Zero Address : 01"
         );
         return _balances[owner];
     }

     function ownerOf(uint256 tokenId) public view virtual returns(address){
         address owner = _owners[tokenId];
         require(owner != address(0),"Query Error : Zero Address : 01");
         return owner;
     }

     function tokenURI(uint256 tokenId) public view virtual exists(tokenId) returns(string memory){
         return _tokenURI[tokenId];
     }

     function approve(address to, uint256 tokenId) public virtual{
         address owner = _owners[tokenId];
         require(to != owner, "Error : Approval to Owner : 02");
         require(
             msg.sender == owner || isApprovedForAll(owner,msg.sender),
            "Error Approval : 02"
         );
         _approve(to,tokenId);
     }

    function _approve(address to, uint256 tokenId) internal virtual{
         _tokenApprovals[tokenId] = to;
         emit Approval(ownerOf(tokenId), to, tokenId);
     }

     function getApproved(uint256 tokenId) public view virtual exists(tokenId) returns(address){
         return _tokenApprovals[tokenId];
     }

     function setApprovalForAll(address operator, bool approved) public virtual {
         require(operator != address(0),"Error : Zero Address : 01");
         _operatorApprovals[msg.sender][operator] = approved;
         emit ApprovalForAll(msg.sender, operator, approved);
     }

    function isApprovedForAll(address owner, address operator) public view virtual returns(bool){
        return _operatorApprovals[owner][operator];
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        /* solhint-disable */
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function transferFrom(address from, address to,uint256 tokenId) public virtual{
        require(
            _isApprovedOrOwner(msg.sender,tokenId),"Access Error : 03"
        );
        _transfer(from,to,tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from,to,tokenId,"");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual{
        require(
            _isApprovedOrOwner(msg.sender,tokenId),"Access Error : No Owner : 04"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function mint(address to) public virtual onlyGovernor {
        mint(to,"");
    }

    function mint(address to, bytes memory _data) public virtual onlyGovernor {
        uint256 tokenId = SafeMath.add(_totalSupply,1);
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "Error : Unsupported Address"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual{
        require( to != address(0),"Error : Zero Address : 01");
        require( _owners[tokenId] == address(0), "Error, Already Minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;
        _tokenURI[tokenId] = generateTokenURI(tokenId);

        emit Transfer(address(0),to,tokenId);

    }

    function generateTokenURI(uint256 _tokenId) public pure returns (string memory) {
        return Strings.strConcat(
            Strings.strConcat(
            baseTokenURI(),
            Strings.uint2str(_tokenId)
            ),".json"
        );
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://niftypunks.s3.amazonaws.com/metadata/";
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual{
        _transfer(from,to,tokenId);
        require(_checkOnERC721Received(from,to,tokenId,_data),"Error : Unsupported Contract");
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "Access Error : No Owner : 04");
        require(to != address(0),"Error : Zero Address : 01");
        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0),tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender,uint256 tokenId) internal view virtual exists(tokenId) returns(bool){
        address owner = ownerOf(tokenId);
        return(
            spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner,spender)
        );
    }

    function addGovernor(address _newGovernor) public virtual returns(bool){
        _governor[_newGovernor] = true;
        return true;
    }

    function removeGovernor(address _oldGovernor) public virtual returns(bool){
        _governor[_oldGovernor] = false;
        return true;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /* solhint-disable */
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity <=0.7.4;

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
		require(c / a == b, "multiplication overflow");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity <=0.7.4;

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

