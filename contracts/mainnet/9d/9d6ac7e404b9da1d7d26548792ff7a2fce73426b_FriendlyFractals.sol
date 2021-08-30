/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract FriendlyFractals is Ownable, ERC721("Friendly Fractals", "FRFRAC"), ERC721Enumerable, ReentrancyGuard {
	uint256 public curId = 0;
	uint256 public mintPrice = 0;
	mapping(uint256 => uint256) public tokenSeed;

	bytes private uriHead1 = "data:application/json;charset=utf-8,%7B%22name%22%3A%20%22Friendly%20Fractals%22%2C%22description%22%3A%20%22Fully%20on-chain%20generative%20fractal%20patterns%20based%20on%20the%20dragon%20curve.%22%2C%22image%22%3A%20%22data%3Aimage%2Fsvg%2Bxml%3Bcharset%3Dutf-8%2C%3Csvg%20width%3D'100%25'%20height%3D'100%25'%20viewBox%3D'0%200%20100000%20100000'%20style%3D'stroke-width%3A400%3B%20";
	bytes private uriHead2 = "%20background-color%3Argb(50%2C50%2C50)'%20xmlns%3D'http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg'%3E";
	bytes private uriTail = "%3C%2Fsvg%3E%22%7D";

    constructor() {
        mint(); // tokenId 0 for deployer
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint() payable public nonReentrant {
    	require(curId < 300, "FriendlyFractals: Max 300 tokens");
    	require(msg.value >= mintPrice, "FriendlyFractals: Insufficient value to mint");

    	_safeMint(_msgSender(), curId);
    	// generate random seed
    	tokenSeed[curId] = uint256(keccak256(abi.encodePacked(curId, block.timestamp, blockhash(block.number - 1))));
    	curId += 1;

    	// refund value above mint price
    	if (msg.value > mintPrice) {
	    	address payable refundee = payable(_msgSender());
	    	refundee.transfer(msg.value - mintPrice);
    	}

    	mintPrice += 1e16;
    }

    function claim() public onlyOwner {
    	address payable sendee = payable(owner());
    	sendee.transfer(address(this).balance);
    }

    function contractURI() public view returns (string memory) {
        return tokenURI(0);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenSVGFromSeed(tokenSeed[tokenId]);
    }

    function tokenSVGFromSeed(uint256 seed) internal view returns (string memory) {
        uint256 numIterations = 8;

        // space to store the string format of x1, y1, x2, y2
        string[4] memory vars = ["1000000", "1000000", "1000000", "1000000"];

        // constants which affect the final outcome	
        seed = uint256(keccak256(abi.encodePacked(seed)));
        uint256 min_subiteration = 1 + seed % 2;

        // space for all the data to compute the fractal
        uint256[] memory data = new uint256[](2**(numIterations+1)-1);

        data[0]= compact(seed, 0, 0, 35000, 35000, 30000, 30000);
        for (uint256 i=0; i<2**numIterations-1; i++) {
            //generate both children
            data[2*i+1] = getChildData(data[i], true, min_subiteration);
            data[2*i+2] = getChildData(data[i], false, min_subiteration);
        }

        // generate result string
        // each line takes up to 84 characters.
        bytes memory result = new bytes(84*(2**numIterations)+550);
        bytes memory cur;
        assembly {
        	cur := add(result, 32) //offset length header
        } 
        uint256 totallen = 0;
    	uint256 linelen;


        // add head
    	(linelen, cur) = copyString(cur, uriHead1);
    	totallen += linelen;

        (linelen, cur) = copyString(cur, getColorString(seed));
    	totallen += linelen;

    	(linelen, cur) = copyString(cur, uriHead2);
    	totallen += linelen;

    	// add body
        for (uint256 i=2**numIterations-1; i<data.length; i++) {
        	bytes memory curLine = getCurLine(data, i, vars);
        	(linelen, cur) = copyString(cur, curLine);
        	totallen += linelen;
        }

        // add tail
    	(linelen, cur) = copyString(cur, uriTail);
    	totallen += linelen;

        // reassign total length
        assembly {
        	mstore(result, totallen)
        }

        return string(result);
    }

    function getChildData(uint256 data, bool leftChild, uint256 min_subiteration) internal view returns (uint256) {
    	uint256 seed;
    	uint256 subiteration;
    	uint256 curtype;
    	int256 x;
        int256 y;
        int256 dx;
        int256 dy;

        (seed, curtype, subiteration, x, y, dx, dy) = expand(data);
        // if subiteration 0, update type and subiteration
        if (subiteration == 0) {
        	seed = uint256(keccak256(abi.encodePacked(seed)));
        	subiteration = min_subiteration + seed % 4;

			seed = uint256(keccak256(abi.encodePacked(seed)));
        	curtype = seed % 9;
        }

		int256 sqrt2a = 14142;
		int256 sqrt2b = 10000;

		// rotate 45 degrees and scale by 1/sqrt(2). dx1,dy1 is for one direction of rotation, dx2,dy2 for the other
        // int256 dx1 = (dx * sqrt2b / sqrt2a - dy * sqrt2b / sqrt2a ) * sqrt2b / sqrt2a;
        // int256 dy1 = (dx * sqrt2b / sqrt2a + dy * sqrt2b / sqrt2a ) * sqrt2b / sqrt2a;
        // int256 dx2 = (dx * sqrt2b / sqrt2a + dy * sqrt2b / sqrt2a ) * sqrt2b / sqrt2a;
        // int256 dy2 =  (-dx * sqrt2b / sqrt2a + dy * sqrt2b / sqrt2a) * sqrt2b / sqrt2a;
        int256 dx1;
        int256 dy1;
        int256 dx2;
        int256 dy2;

        assembly {
        	dx1 := sdiv(mul(sub(sdiv(mul(dx, sqrt2b), sqrt2a),sdiv(mul(dy, sqrt2b),sqrt2a)),sqrt2b),sqrt2a)
        	dy1 := sdiv(mul(add(sdiv(mul(dx, sqrt2b), sqrt2a),sdiv(mul(dy, sqrt2b),sqrt2a)),sqrt2b),sqrt2a)
        	dx2 := sdiv(mul(add(sdiv(mul(dx, sqrt2b), sqrt2a),sdiv(mul(dy, sqrt2b),sqrt2a)),sqrt2b),sqrt2a)
        	dy2 := sdiv(mul(add(sdiv(mul(add(1,not(dx)), sqrt2b), sqrt2a),sdiv(mul(dy, sqrt2b),sqrt2a)),sqrt2b),sqrt2a)
        }


        // reuse x,y,dx,dy for return. Not enough local variables
        if (leftChild && (curtype == 3) || 
            !leftChild && (curtype == 0 || curtype == 4 || curtype == 8)) {
        	assembly {
        		x := add(x, dx)
        		y := add(y, dy)
        	}
        } else if (curtype == 6 || 
        		  !leftChild && (curtype == 1 || curtype == 3)) {
        	assembly {
        		x := add(x, dx1)
        		y := add(y, dy1)
        	}
        } else if (!leftChild && (curtype == 2 || curtype == 5 || curtype == 7)) {
        	assembly {
        		x := add(x, dx2)
        		y := add(y, dy2)
        	}
        }

        if (leftChild && (curtype == 0 || curtype == 1 || curtype == 4 || curtype == 5 || curtype == 7) ||
        	!leftChild && (curtype == 2 || curtype == 5)) {
        	dx = dx1;
        	dy = dy1;

        }  else if (leftChild && (curtype == 6) ||
        			!leftChild && (curtype == 3 || curtype == 4)) {
        	assembly {
        		dx := add(1, not(dx1))
        		dy := add(1, not(dy1))
        	}

        } else if (leftChild && (curtype == 2 || curtype == 8) || 
        		  !leftChild && (curtype == 1 || curtype == 6)) {
    		dx = dx2;
    		dy = dy2;

        } else if (leftChild && (curtype == 3) || 
        			!leftChild && (curtype == 0 || curtype == 7 || curtype == 8)) {
        	assembly {
        		dx := add(1, not(dx2))
        		dy := add(1, not(dy2))
        	}
        } 

    	return compact(seed, curtype, subiteration-1, x, y, dx, dy);
    }

    // compact variables into uint256
    function compact(uint256 seed, uint256 curtype, uint256 subiteration, int256 x, int256 y, int256 dx, int256 dy) internal pure returns (uint256) {
    	uint256 result = 0;
    	result |= uint256(dy & 0xffffffff);
    	result = result << 32;
    	result |= uint256(dx & 0xffffffff);
    	result = result << 32;
    	result |= uint256(y & 0xffffffff);
    	result = result << 32;
    	result |= uint256(x & 0xffffffff);
    	result = result << 32;
    	result |= uint256(subiteration & 0xffffffff);
    	result = result << 32;
    	result |= uint256(curtype & 0xffffffff);
    	result = result << 64;
    	result |= uint256(seed & 0xffffffffffffffff);

    	return result;
    }

    // expand variables from uint256
    function expand(uint256 vars) internal pure returns (uint256 seed, uint256 curtype, uint256 subiteration, int256 x, int256 y, int256 dx, int256 dy) {
    	seed = uint256(vars & 0xffffffffffffffff);
    	vars = vars >> 64;
    	curtype = uint256(vars & 0xffffffff);
    	vars = vars >> 32;
    	subiteration = uint256(vars & 0xffffffff);
    	vars = vars >> 32;
    	x = int256(int32(uint32(vars)));
    	vars = vars >> 32;
    	y = int256(int32(uint32(vars)));
    	vars = vars >> 32;
    	dx = int256(int32(uint32(vars)));
    	vars = vars >> 32;
    	dy = int256(int32(uint32(vars)));
    }

    function uintToString(uint v) public pure returns (string memory) {
        uint maxlength = 8;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i); // i + 1 is inefficient
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
        }
        string memory str = string(s);  // memory isn't implicitly convertible to storage
        return str;
    }

    function getColorString(uint256 seed) internal view returns (bytes memory) {
    	seed = uint256(keccak256(abi.encodePacked(seed)));
        uint256 color_h = 1 + seed % 359;
    	seed = uint256(keccak256(abi.encodePacked(seed)));
        uint256 color_s = 65 + seed % 22;
    	seed = uint256(keccak256(abi.encodePacked(seed)));
        uint256 color_l = 65 + seed % 22;

        return abi.encodePacked("stroke%3Ahsl(", uintToString(color_h), "%2C", uintToString(color_s), "%25%2C", uintToString(color_l), "%25)%3B");
    }

    // returns length of string copied and current position of pointer
    function copyString(bytes memory curPosition, bytes memory strToCopy) internal view returns (uint256 linelen, bytes memory resPosition) {
    	uint256 numloops = (strToCopy.length + 31) / 32;
    	linelen = strToCopy.length;
    	resPosition = curPosition;

    	// copy curLine into result
    	assembly {
	        for {  let j := 0 } lt(j, numloops) { j := add(1, j) } { mstore(add(resPosition, mul(32, j)), mload(add(strToCopy, mul(32, add(1, j))))) }
	        resPosition := add(resPosition, linelen)
	    }
    }

    // get svg line output from data
    function getCurLine(uint256[] memory data, uint256 index, string[4] memory vars) internal view returns (bytes memory) {      
      	uint256 remainder;
        int256 x;
        int256 y;
        int256 dx;
        int256 dy;
        (,,, x, y, dx, dy) = expand(data[index]);

    	uint256 curdigit;
    	uint256 numdigits;
    	string memory stringStart;

    	for (uint256 i=0; i<4; i++) {
    		curdigit = 0;
    		numdigits = 0;
	    	uint256 num;
	    	if (i == 0) {
	    		num = uint256(x);
	    	} else if (i == 1) {
	    		num = uint256(y);
	    	}  else if (i == 2) {
	    		num = uint256(x+dx);
	    	} else {
	    		num = uint256(y+dy);
	    	}

	    	assembly {
	    		stringStart := mload(add(vars, mul(32, i)))
	    	}

	    	uint256 numcopy = num;

	    	// count number of digits
	    	
	    	// while (numcopy > 0) {
	    	// 	numdigits += 1;
	    	// 	numcopy /= 10;
	    	// }
	    	assembly {
	    		for { } gt(numcopy, 0) { numcopy := div(numcopy, 10) } { numdigits := add(numdigits, 1) }
			}

			// convert integer into string format

			// assume number won't be 0, so only handle above 0 case
	        // while (num > 0) {
	        // 	remainder = ((num % 10) + 48);
	        // 	assembly {
	        // 		mstore8(add(stringStart, add(31, sub(numdigits,curdigit))), remainder)
	        // 	}
	        // 	num /= 10;
	        // 	curdigit += 1;
	        // }
	        assembly {
	        	for {} gt(num, 0) {num := div(num, 10)} {
	        		remainder := add(mod(num, 10),  48)
	        		mstore8(add(stringStart, add(31, sub(numdigits,curdigit))), remainder)
	        		curdigit := add(curdigit, 1)
	        	}
	        }

	        assembly {
	    		mstore(stringStart, curdigit)
	    	}
    	}

        return abi.encodePacked("%3Cline%20x1%3D'", vars[0] ,"'%20y1%3D'", vars[1], "'%20x2%3D'", vars[2], "'%20y2%3D'", vars[3], "'%20%2F%3E");

    }
}