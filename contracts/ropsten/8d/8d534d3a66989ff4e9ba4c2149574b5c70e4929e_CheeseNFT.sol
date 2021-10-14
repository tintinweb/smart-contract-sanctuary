/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.5.12;




 
interface IERC165 {
 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



pragma solidity ^0.5.12;



contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}



pragma solidity ^0.5.12;


contract IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}



pragma solidity ^0.5.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



pragma solidity ^0.5.12;


library Address {

    function isContract(address account) internal view returns (bool) {


        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}



pragma solidity ^0.5.12;


library Counters {
    using SafeMath for uint256;

    struct Counter {

        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}



pragma solidity ^0.5.12;


contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {

        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}



pragma solidity ^0.5.12;



contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping (uint256 => address) private _tokenOwner;

    mapping (uint256 => address) private _tokenApprovals;

    mapping (address => Counters.Counter) private _ownedTokensCount;

    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {

        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

  
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}



pragma solidity ^0.5.12;

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}



pragma solidity ^0.5.12;



contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
 
    mapping(address => uint256[]) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);

        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {


        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; 
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }

        _ownedTokens[from].length--;

    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {


        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex; 

        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}


pragma solidity ^0.5.12;


contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}



pragma solidity ^0.5.12;




contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {

    string private _name;

    string private _symbol;

    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }


    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


pragma solidity ^0.5.12;


contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}


pragma solidity 0.5.12;


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {


        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }


    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity 0.5.12;


contract CheeseNFT is ERC721Full{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
   
    struct nftData {
        uint256 clothType; //  --> 1 --> head, 2 --> middle, 3 --> bottom
        string name;
        string description;
        string cid;
        string rarity;
        bool isOnSale;
        uint256 sellPrice;
        bool isBiddable;
        uint256 maxBid;
        address maxBidder;
        bool isWearing;
    }

    struct userData {
        uint256 head; 
        uint256 middle;
        uint256 bottom;
        string username;
        uint256 userBalance;
        string photoCid;
        
    }

    event nftTransaction(
        uint256 indexed id,
        string transactionType,
        address fromAddress,
        address toAddress,
        uint256 value
       
    );
    mapping(address => userData) public users;
    mapping(string => bool) isExist;
    nftData[] public nfts;

 
    address  public owner;
    uint public maxSupply;
    constructor() public ERC721Full("Cheese NFT Games", "cNFTG") {
        owner = msg.sender;
        maxSupply=100000;
    }

    function setUsername(string memory _username) public {
        users[msg.sender].username = _username;
    }
    
    function setPhoto(string memory _photoCid) public {
        users[msg.sender].photoCid = _photoCid;
    }

    function wearItems(
        uint256 _headTokenId,
        uint256 _middleTokenId,
        uint256 _bottomTokenId
    ) public {
        require(
            _headTokenId == 0 ||
                (this.ownerOf(_headTokenId) == msg.sender &&
                    nfts[_headTokenId - 1].clothType == 1)
        ,"you must be the owner or you tried not head item on head");
        require(
            _middleTokenId == 0 ||
                (this.ownerOf(_middleTokenId) == msg.sender &&
                    nfts[_middleTokenId - 1].clothType == 2)
        ,"you must be the owner or you tried not middle item on middle");
        require(
            _bottomTokenId == 0 ||
                (this.ownerOf(_bottomTokenId) == msg.sender &&
                    nfts[_bottomTokenId - 1].clothType == 3)
        ,"you must be the owner or you tried not bottom item on bottom");
        
        require(_headTokenId == 0 || nfts[_headTokenId - 1].isOnSale == false, "head on sale, you cannot wear it!");
        require(_headTokenId == 0 || nfts[_headTokenId - 1].isBiddable == false,"head on bid, you cannot wear it!");

        require(_middleTokenId == 0 || nfts[_middleTokenId - 1].isOnSale == false,"middle on sale, you cannot wear it!");
        require(_middleTokenId == 0 || nfts[_middleTokenId - 1].isBiddable == false,"middle on bid, you cannot wear it!");

        require(_bottomTokenId == 0 || nfts[_bottomTokenId - 1].isOnSale == false,"bottom on sale, you cannot wear it!");
        require(_bottomTokenId == 0 || nfts[_bottomTokenId - 1].isBiddable == false,"middle on bid, you cannot wear it!");

        if (users[msg.sender].head != 0) {
            nfts[users[msg.sender].head - 1].isWearing = false;
        }
        if (users[msg.sender].middle != 0) {
            nfts[users[msg.sender].middle - 1].isWearing = false;
        }
        if (users[msg.sender].bottom != 0) {
            nfts[users[msg.sender].bottom - 1].isWearing = false;
        }

        if (_headTokenId != 0) {
            nfts[_headTokenId - 1].isWearing = true;
        }
        if (_middleTokenId != 0) {
            nfts[_middleTokenId - 1].isWearing = true;
        }
        if (_bottomTokenId != 0) {
            nfts[_bottomTokenId - 1].isWearing = true;
        }

        users[msg.sender].head = _headTokenId;
        users[msg.sender].middle = _middleTokenId;
        users[msg.sender].bottom = _bottomTokenId;

    }

    function wearItem(uint256 _tokenId) public {
        require(this.ownerOf(_tokenId) == msg.sender, "You are not the owner of this item, so you cannot wear it.");
        require(nfts[_tokenId - 1].isOnSale == false, "You cannot wear an item while it is on sale.");
        require(nfts[_tokenId - 1].isBiddable == false, "You cannot wear an item while it is on auction.");
       

        if (nfts[_tokenId - 1].clothType == 1) {
            if (users[msg.sender].head != 0)
            {
                nfts[users[msg.sender].head - 1].isWearing = false;
            }
            users[msg.sender].head = _tokenId;
        } else if (nfts[_tokenId - 1].clothType == 2) {
            if (users[msg.sender].middle != 0)
            {
                nfts[users[msg.sender].middle - 1].isWearing = false;
            }
            users[msg.sender].middle = _tokenId;
        } else if (nfts[_tokenId - 1].clothType == 3) {
            if (users[msg.sender].bottom != 0)
            {
                nfts[users[msg.sender].bottom - 1].isWearing = false;
            }
            users[msg.sender].bottom = _tokenId;
        }
         nfts[_tokenId - 1].isWearing = true;
    }

    function unWearItem(uint256 _clothType) public {
        require(_clothType == 1 || _clothType == 2 || _clothType == 3, "Invalid cloth type.");

        if (_clothType == 1) {
            require(users[msg.sender].head !=0, "You must wear a head item first to unwear.");
            nfts[users[msg.sender].head - 1].isWearing = false;
            users[msg.sender].head = 0;
        } else if (_clothType == 2) {
            require(users[msg.sender].middle !=0, "You must wear a middle item first to unwear.");

            nfts[users[msg.sender].middle - 1].isWearing = false;
            users[msg.sender].middle = 0;
        } else if (_clothType == 3) {
            require(users[msg.sender].bottom !=0, "You must wear a bottom item first to unwear.");
            nfts[users[msg.sender].bottom - 1].isWearing = false;
            users[msg.sender].bottom = 0;
        }
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return _tokensOfOwner(_owner);
    }

    function putOnSale(uint256 _tokenId, uint256 _sellPrice) public {
       
        require(msg.sender == this.ownerOf(_tokenId), "You cannot put this item on sale, because you are not the owner of it.");
       
        require(nfts[_tokenId - 1].isOnSale == false, "Item is already on sale!");
      
        require(nfts[_tokenId - 1].isWearing == false, "You must unwear it first, then you can sell it." );
        
        nfts[_tokenId - 1].isOnSale = true;  
        nfts[_tokenId - 1].sellPrice = _sellPrice;  
        approve(address(this), _tokenId);

        emit nftTransaction(
            _tokenId,
            "On Sale",
            msg.sender,
            address(0x0),
            _sellPrice
        );  
    }

    function cancelSale(uint256 _tokenId) public {
       
        require(nfts[_tokenId - 1].isOnSale == true, "Item should be on sale first, to be cancelled.");
         
        require(msg.sender == this.ownerOf(_tokenId), "You cannot cancel the sale of this item, because you are not the owner.");
        
        nfts[_tokenId - 1].isOnSale = false;  
        nfts[_tokenId - 1].sellPrice = 0;  

        emit nftTransaction(
            _tokenId,
            "Sale Cancelled",
            msg.sender,
            address(0x0),
            0
        );  
    }

    function buyFromSale(uint256 _tokenId) public payable {
      
        require(msg.sender != this.ownerOf(_tokenId), "You cannot buy your own item!");
     
        require(nfts[_tokenId - 1].isOnSale == true, "Item should be on sale for you to buy it.");
   
        require (nfts[_tokenId - 1].sellPrice <= msg.value, "The amount you tried to buy, is less than price.");
    
        require(this.getApproved(_tokenId) == address(this), "Seller did not give the allowance for us to sell this item, contact with seller.");
        address sellerAddress = this.ownerOf(_tokenId);  
        this.safeTransferFrom(sellerAddress, msg.sender, _tokenId); 
        nfts[_tokenId - 1].isOnSale = false;  
        nfts[_tokenId - 1].sellPrice = 0;  
        users[sellerAddress].userBalance = add256(users[sellerAddress].userBalance, msg.value); 

        if (nfts[_tokenId - 1].maxBid > 0) {
            users[nfts[_tokenId - 1].maxBidder].userBalance = add256(users[nfts[_tokenId - 1].maxBidder].userBalance ,  nfts[_tokenId - 1].maxBid); 
        }
        nfts[_tokenId - 1].maxBid = 0;
        nfts[_tokenId - 1].maxBidder = address(0x0);
        nfts[_tokenId - 1].isBiddable = false;  

        emit nftTransaction(
            _tokenId,
            "sold",
            sellerAddress,
            msg.sender,
            msg.value
        );  
    }

    function putOnAuction(uint256 _tokenId) public {

         
        require(msg.sender == this.ownerOf(_tokenId), "Only owner of this item can put on sale" );
        require(nfts[_tokenId - 1].isWearing == false,  "You must unwear it first, then you can put it on auction.");
        require(nfts[_tokenId - 1].isBiddable == false, "This item is already on auction!");
        
        nfts[_tokenId - 1].isBiddable = true;  
        nfts[_tokenId - 1].maxBid = 0;  
        approve(address(this), _tokenId);

        emit nftTransaction(
            _tokenId,
            "Auction Starts",
            msg.sender,
            address(0x0),
            0
        );  
    }

    function cancelAuction(uint256 _tokenId) public {
         
        require(msg.sender == this.ownerOf(_tokenId), "You cannot cancel the auction of this item, because you are not the owner.");
        require(nfts[_tokenId - 1].isBiddable == true, "Item must be on auction before it can be canceled, currently it is not!");
        
        
        if (nfts[_tokenId - 1].maxBid > 0) {
            users[nfts[_tokenId - 1].maxBidder].userBalance = add256(users[nfts[_tokenId - 1].maxBidder].userBalance, nfts[_tokenId - 1].maxBid); 
        }
        nfts[_tokenId - 1].isBiddable = false;  
        nfts[_tokenId - 1].maxBid = 0;  
        nfts[_tokenId - 1].maxBidder = address(0x0);  

        emit nftTransaction(
            _tokenId,
            "Auction Cancelled",
            msg.sender,
            address(0x0),
            0
        );  
    }

    function bid(uint256 _tokenId) public payable {

        require(msg.value > 0, "You did not send any money");
        require(nfts[_tokenId - 1].isBiddable == true,"Item you tried to bid, is not biddable!");
        require(msg.value >= nfts[_tokenId - 1].maxBid, "The amount you tried to bid, is less than current max bid.");
        require(msg.sender != this.ownerOf(_tokenId), "You cannot bid your own item.");
       
        if (nfts[_tokenId - 1].maxBid > 0) {
            users[nfts[_tokenId - 1].maxBidder].userBalance = add256(users[nfts[_tokenId - 1].maxBidder].userBalance, nfts[_tokenId - 1].maxBid);    
        }
        nfts[_tokenId - 1].maxBid = msg.value;
        nfts[_tokenId - 1].maxBidder = msg.sender;

        emit nftTransaction(
            _tokenId,
            "Bidded",
            msg.sender,
            ownerOf(_tokenId),
            msg.value
        );  
    }

    function acceptHighestBid(uint256 _tokenId) public {
       
        require(msg.sender == this.ownerOf(_tokenId), "You need to be owner of this item, to accept its highest bid.");
      
        require(nfts[_tokenId - 1].isBiddable == true , "Item should be biddable for you to accept its highest bid.");
      
        require(nfts[_tokenId - 1].maxBid > 0 ,"Max bid must be more than 0 to accept it, currently it is not!");

        require(nfts[_tokenId - 1].maxBidder != msg.sender, "Max bidder cannot be the same person as seller!");

        address buyer = nfts[_tokenId - 1].maxBidder;
        uint256 soldValue = nfts[_tokenId - 1].maxBid;


        users[msg.sender].userBalance = add256(users[msg.sender].userBalance, nfts[_tokenId - 1].maxBid);    
        nfts[_tokenId - 1].maxBid = 0;  
        nfts[_tokenId - 1].maxBidder = address(0x0);  
        nfts[_tokenId - 1].isBiddable = false;  
        nfts[_tokenId - 1].isOnSale = false;  
        nfts[_tokenId - 1].sellPrice = 0;  


        this.safeTransferFrom(
            msg.sender,
            nfts[_tokenId - 1].maxBidder,
            _tokenId
        ); 


        emit nftTransaction(
            _tokenId,
            "Sold From Auction",
            msg.sender,
            buyer,
            soldValue
        );  
    }

    function withdrawBid(uint256 _tokenId) public {
        //msg.sender maxBidder olmalı
        require(msg.sender == nfts[_tokenId - 1].maxBidder, "You must be the max bidder to withdraw your bid!");
        uint256 withdrawnValue = nfts[_tokenId - 1].maxBid;
        users[nfts[_tokenId - 1].maxBidder].userBalance = add256(users[nfts[_tokenId - 1].maxBidder].userBalance, nfts[_tokenId - 1].maxBid);    
        nfts[_tokenId - 1].maxBid = 0;  
        nfts[_tokenId - 1].maxBidder = address(0x0);  

        emit nftTransaction(
            _tokenId,
            "Bid Withdrawn",
            msg.sender,
            address(0x0),
            withdrawnValue
        );  
    }

    function withdrawMoney(uint256 _amount) public {
       
        require(users[msg.sender].userBalance >= _amount, "You do not have enough balance to withdraw this amount");

        uint initialBalance = users[msg.sender].userBalance;
        users[msg.sender].userBalance = sub256(initialBalance, _amount);
        msg.sender.transfer(_amount);
        
    }

    function mint(
        uint256 _clothType,
        string memory _name,
        string memory _description,
        string memory _cid,
        string memory _rarity
        ) public {
        require(isExist[_cid] == false, "Item link should be unique, for you to mint it");
        require(this.totalSupply() < maxSupply, "You cannot mint any more item since you already reached the maximum supply.");
        require(msg.sender ==owner, "Only owner can of this contract can mint, you are trying to some fraud.");
        require(_clothType == 1 || _clothType == 2 || _clothType == 3, "Invalid cloth type.");
      
        uint256 _id =
            nfts.push(
                nftData(
                    _clothType,
                    _name,
                    _description,
                    _cid,
                    _rarity,
                    true,
                    1,
                    false,
                    0,
                    address(0x0),
                    false
                )
            );
        _mint(msg.sender, _id);
        isExist[_cid] = true;
        emit nftTransaction(_id, "claimed", address(0x0), msg.sender, 0);
        _tokenIds.increment();
       
    }



    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }
}