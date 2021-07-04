/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity ^0.5.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.0;
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


pragma solidity ^0.5.0;
contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}


pragma solidity ^0.5.0;
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


pragma solidity ^0.5.0;
library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


pragma solidity ^0.5.0;
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

pragma solidity ^0.5.0;
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.0;
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
        require(_isApprovedOrOwner(from, tokenId), "ERC721: transfer caller is not owner nor approved");

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

    function _burn(uint256 tokenId) internal { _burn(ownerOf(tokenId), tokenId); }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
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


pragma solidity ^0.5.0;
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity ^0.5.0;
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
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
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
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}


pragma solidity ^0.5.0;
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


pragma solidity ^0.5.0;
contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
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


pragma solidity ^0.5.0;
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

pragma solidity >=0.4.0 <0.8.2;
contract Nft is ERC721Full { 
    struct data { string URL;address payable creator;uint256 Token_ID;uint256 Token_Price;bool Status; }
    address payable public manager; 
      data[] public nft;
      mapping(string => bool) _nftExists;
    
      constructor() ERC721Full("Colexion", "CLXN") public { manager = address(0x7812ca983E0be569FEc1863Baaec388479577B17); }
      
    function mint(string memory url, uint64 Token_Price, bool _status) public {
        require(!_nftExists[url], "AlreadyExist.");
        data memory data123 = data(url,msg.sender,nft.length,Token_Price,_status);
        uint _id = nft.push(data123);
        _mint(msg.sender, _id-1);
        _setTokenURI( _id-1, url);
        _nftExists[url] = true;
        approve(address(this), _id-1);
    }
     
    function changeStatus(uint Token_ID) public only_owner(Token_ID) not_in_auction(Token_ID) {
        nft[Token_ID].Status = !nft[Token_ID].Status;
    }
    
    function purchaseToken(uint64 t_id, uint8 m, uint8 r, uint8 o) public payable not_in_auction(t_id){
        require(nft[t_id].Status == true, "TokenNotForSale");
         require(nft[t_id].Token_Price <= msg.value, "Invalid price");
        t_transfer(ownerOf(t_id), msg.sender, t_id, msg.value,m,r,o);
    }
     
    function t_transfer(address owner, address to, uint64 t_id, uint256 t_price,uint8 m, uint8 r, uint8 o)internal{
        address payable OwnToken = address (uint168(owner));
        manager.transfer( ( (t_price / 100) * m ) );   // transfer 7% to token manager.
        (nft[t_id].creator).transfer( ( (t_price / 100) * r ) );   // transfer 10% to token creator.
        (OwnToken).transfer( ( (t_price / 100) * o ) );   // transfer 83% to token owner.
        transferFrom(owner, to, t_id);
        nft[t_id].Status = false;
        nft[t_id].Token_Price = t_price;
    }
     
    function updateTokenPrice(uint t_id, uint _price) public only_owner(t_id) not_in_auction(t_id) returns(string memory){
        nft[t_id].Token_Price = _price;
        return "PriceUpdated";
     }
     
    mapping (uint => bool) public T_In_Auction;
    mapping (uint => Auction_data) public T_Auction;
    mapping(uint => mapping(address => uint)) public bids;
    mapping(uint => address[]) public token_bidders;    
    address[] bidder_list;

    struct Auction_data{
        uint Token_id; 
        address auction_owner; 
        address auction_winner; 
        uint256 auction_win_bid; 
        uint256 auction_start; 
        uint256 auction_end; 
        uint256 highestBid; 
        address highestBidder;
        uint256 minimunBid; 
        uint256 maximunBid; 
        bool state;
        address[] bidders;
    }

    function create_Auction (uint _biddingTime, uint t_id, uint _minBid, uint _maxBid) only_owner(t_id) not_in_auction(t_id) public {
        require(nft[t_id].Status == false, "TokeForSale");
        address[] memory emptyAddressList;
        Auction_data memory data1750 = Auction_data(t_id,ownerOf(t_id),address(0),0, now,(now +_biddingTime*1 minutes),0,address(0),_minBid,_maxBid, true, emptyAddressList);
        T_Auction[t_id] = data1750; 
        T_In_Auction[t_id] = true; 
        token_bidders[t_id].length = 0;
        approve(address(this), t_id);
    }

    // Not done yet => agr koi higgest bid kerre to token usko transfer hojai
    function bid(uint64 T_id) public payable in_auction(T_id) only_bidders(T_id) not_auction_winner(T_id) returns (bool){ 
        require(bids[T_id][msg.sender] + msg.value >=  T_Auction[T_id].minimunBid, "makeHigherBid");
        require(bids[T_id][msg.sender] + msg.value <=  T_Auction[T_id].maximunBid, "makeLowerBid");
        if(block.timestamp < T_Auction[T_id].auction_end){
            if(bids[T_id][msg.sender] + msg.value >= T_Auction[T_id].maximunBid){
                // bid hits maximum amount
                T_Auction[T_id].state = false;
                T_Auction[T_id].auction_win_bid = bids[T_id][msg.sender] + msg.value;
                T_Auction[T_id].auction_winner = msg.sender;
                T_Auction[T_id].highestBidder = address(0);
                T_Auction[T_id].highestBid = 0;
                bids[T_id][msg.sender] = 0;
                T_In_Auction[T_id] = false; 
                t_transfer(ownerOf(T_id), msg.sender, T_id, T_Auction[T_id].auction_win_bid,7,10,83);
                emit EndedEvent("Auction ended", block.timestamp); 
            } else {
                // bid not hits maximum amount
                bids[T_id][msg.sender] = bids[T_id][msg.sender] + msg.value;
                bidder_list = token_bidders[T_id];
                bidder_list.push(msg.sender);
                token_bidders[T_id] = bidder_list;
                T_Auction[T_id].highestBidder = T_Auction[T_id].highestBid > bids[T_id][msg.sender]  ? T_Auction[T_id].highestBidder : msg.sender;
                T_Auction[T_id].highestBid =  T_Auction[T_id].highestBid > bids[T_id][msg.sender] ? T_Auction[T_id].highestBid : bids[T_id][msg.sender];
                T_Auction[T_id].bidders.push(msg.sender);
                return true;
            }
        } else {
            end_auction_auto(T_id);
        }
    } 
    
    function withdraw(uint T_id) public payable only_bidders(T_id) auction_ended(T_id) not_auction_winner(T_id) returns (bool){
        uint amount = bids[T_id][msg.sender];
        require( amount > 0, "balance 0");
        
        msg.sender.transfer(amount); 
        bids[T_id][msg.sender] = 0; 
        emit WithdrawalEvent(msg.sender, bids[T_id][msg.sender]); 
        return true;
    }  
    
    function end_auction(uint64 T_id) public payable only_owner(T_id) returns (bool, string memory) { 
        require(T_In_Auction[T_id] == true, "TokenInAuction");
        require(nft[T_id].Status == false,"TokenForSale");
        T_Auction[T_id].state = false;
        T_In_Auction[T_id] = false; 
        if(T_Auction[T_id].highestBidder == address(0)){ return (true, "Auction Ended");}
        T_Auction[T_id].auction_win_bid = T_Auction[T_id].highestBid;
        T_Auction[T_id].auction_winner = T_Auction[T_id].highestBidder;
        T_Auction[T_id].highestBidder = address(0);
        T_Auction[T_id].highestBid = 0;
        bids[T_id][T_Auction[T_id].auction_winner] = 0;
        t_transfer(ownerOf(T_id), T_Auction[T_id].auction_winner, T_id, T_Auction[T_id].auction_win_bid,7,10,83);
        emit EndedEvent("Auction ended", block.timestamp); 
        return (true, "Auction Ended");
    }
    
    function end_auction_auto(uint64 T_id)public payable auctionTime_ends(T_id) returns (bool, string memory) { 
        require(T_In_Auction[T_id] == true , "This Token is not in Auction");
        T_Auction[T_id].state = false;
        T_In_Auction[T_id] = false; 
        T_Auction[T_id].auction_win_bid = T_Auction[T_id].highestBid;
        T_Auction[T_id].auction_winner = T_Auction[T_id].highestBidder;
        T_Auction[T_id].highestBidder = address(0);
        T_Auction[T_id].highestBid = 0;
         bids[T_id][T_Auction[T_id].auction_winner] = 0;
        msg.sender.transfer(msg.value);
        // address(uint168(ownerOf(T_id))).transfer(T_Auction[T_id].highestBid);
        t_transfer(ownerOf(T_id), T_Auction[T_id].auction_winner, T_id, T_Auction[T_id].auction_win_bid,7,10,83);
        emit EndedEvent("Auction ended", block.timestamp); 
        return (true, "Auction Ended");
    }
     
    modifier in_auction(uint T_id){ 
        require( T_In_Auction[T_id] == true, "tokenNotInAuction");
        _;
    } 
    modifier not_in_auction(uint T_id){ 
        require(T_In_Auction[T_id] == false , "TokenInAuction");
        _;
    } 
   
    modifier an_ongoing_auction(uint T_id){ 
        require( block.timestamp < T_Auction[T_id].auction_end, "BiddingIsEnd");
        _;
    } 
   
    modifier auctionTime_ends(uint T_id){ 
        require( block.timestamp > T_Auction[T_id].auction_end, "BiddingNotEnd");
        _;
    } 
   
    modifier auction_ended(uint T_id){ 
        require( T_Auction[T_id].state == false, "AuctionIsGoing");
        _;
    } 
   
    modifier only_owner(uint T_id){ 
        require(msg.sender == ownerOf(T_id), "OnlyOwner");
        _;
    } 
   
    modifier only_bidders(uint T_id){ 
        require(msg.sender != T_Auction[T_id].auction_owner, "OnlyBidderAction");
        _;
    } 
    
    modifier not_auction_winner(uint T_id){ 
        require(msg.sender != T_Auction[T_id].auction_winner, "AuctionWinner");
        _;
    } 
    event BidEvent(address indexed Bidder, uint256 Bid); 
    event WithdrawalEvent(address withdrawer, uint256 amount);
    event EndedEvent(string message, uint256 time);

}