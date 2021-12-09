/**
 *Submitted for verification at polygonscan.com on 2021-12-08
*/

/**
 *Submitted for verification at polygonscan.com on 2021-08-26
 */

/**
 *Submitted for verification at Etherscan.io on 2021-07-09
 */

/**
 *Submitted for verification at Etherscan.io on 2021-07-03
 */

pragma solidity ^0.5.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.0;

contract IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function approve(address to, uint256 tokenId) public;

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public;
}

pragma solidity ^0.5.0;

contract IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
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
        assembly {
            size := extcodesize(account)
        }
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

    constructor() internal {}

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
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

    mapping(uint256 => address) private _tokenOwner;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => Counters.Counter) private _ownedTokensCount;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor() public {}

    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _ownedTokensCount[owner].current();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(from, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal {
        require(
            ownerOf(tokenId) == owner,
            "ERC721: burn of token that is not own"
        );

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            tokenId,
            _data
        );
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

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity ^0.5.0;

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor() public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
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

    function _tokensOfOwner(address owner)
        internal
        view
        returns (uint256[] storage)
    {
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

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _ownedTokens[from].length--;
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

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

    constructor(string memory name, string memory symbol) public {
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
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = uri;
    }

    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity ^0.5.0;

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor(string memory name, string memory symbol)
        public
        ERC721Metadata(name, symbol)
    {
        // solhint-disable-previous-line no-empty-blocks
    }
}

pragma solidity >=0.4.0 <0.8.2;

contract Colexion is ERC721Full {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address payable public manager;
    mapping(string => bool) private _nftExists;
    mapping(uint256 => address) public creator;
    mapping(uint256 => uint256) public tCost;
    uint256 public marketPer = 7;
    uint256 public creatorPer = 10;
    uint256 public ownerPer = 83;

    modifier inAuction(uint256 tId) {
        require(tInAuction[tId], "tokenNotInAuction");
        _;
    }

    modifier notOnSale(uint256 tId) {
        require(!tOnSale[tId], "Token Already On Sale");
        _;
    }

    modifier auctionEnded(uint256 tId) {
        require(!tAuction[tId].status, "AuctionIsGoing");
        _;
    }

    modifier onlyOwner(uint256 tId) {
        require(msg.sender == ownerOf(tId), "OnlyOwner");
        _;
    }

    modifier onlyBidders(uint256 tId) {
        require(msg.sender != ownerOf(tId), "OnlyBidderAction");
        _;
    }

    modifier notAuctionWinner(uint256 tId) {
        require(msg.sender != tAuction[tId].hBidder, "AuctionWinner");
        _;
    }

    mapping(uint256 => bool) public tInAuction;
    mapping(uint256 => bool) public tOnSale;
    mapping(uint256 => AuctionData) public tAuction;
    mapping(uint256 => mapping(address => uint256)) public bids;
    mapping(uint256 => address[]) public bidderList;

    struct AuctionData {
        uint256 tId;
        uint256 hBid;
        address hBidder;
        bool status;
        uint256 maximunBid;
    }

    event UpdateTokenPrice(uint256 tId, uint256 price);
    event Bid(uint256 tId, address);
    event CreateAuction(uint256 tId, uint256 maxBid);
    event EndAuction(uint64 tId, string);
    event TokenForSale(uint256 tId, uint256 price);

    // ipfs/QmaauyTdka44jYkjKhrA8i5kbZD3skGmVLhG8yLmbffM5d
    // 2 * 1000000000000000000

    constructor() public ERC721Full("Colexion", "CLXN") {
        manager = address(0x34B2aF9EAcDcA0046daf55e1d580B2302DE6a9da);
    }

    function setMarketPer(uint256 _marketPer) public {
        require(msg.sender == manager, "caller must be manager");
        marketPer = _marketPer;
    }

    function setCreatorPer(uint256 _creatorPer) public {
        require(msg.sender == manager, "caller must be manager");
        creatorPer = _creatorPer;
    }

    function setOwnerPer(uint256 _ownerPer) public {
        require(msg.sender == manager, "caller must be manager");
        ownerPer = _ownerPer;
    }

    function mint(
        string memory url,
        uint256 cost,
        bool tokenForSale
    ) public {
        require(!_nftExists[url], "AlreadyExist");
        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _mint(msg.sender, newId);
        _setTokenURI(newId, url);

        _nftExists[url] = true;
        creator[newId] = msg.sender;

        if (tokenForSale) {
            tOnSale[newId] = true;
            tCost[newId] = cost;
            approve(address(this), newId);
        } else {
            tCost[newId] = 0;
        }
    }

    function purchaseToken(uint64 tId) public payable {
        require(!tInAuction[tId], "Token is Auction Only"); // User can't buy token which is in Auction
        require(tOnSale[tId], "Token is Not for sale"); // User can't buy token which is in Not for sale
        _tTransfer(ownerOf(tId), msg.sender, tId, tCost[tId]);
    }

    function _tTransfer(
        address owner,
        address to,
        uint64 tId,
        uint256 cost
    ) internal {
        address payable ownToken = address(uint168(owner));
        address payable cre = address(uint168(creator[tId]));
        tCost[tId] = cost;
        tOnSale[tId] = false; // When token is being purchased or auctioned, by default it will be reset to NOT For SALE
        manager.transfer(((cost / 100) * marketPer)); // transfer 7% to token manager.
        (cre).transfer(((cost / 100) * creatorPer)); // transfer 10% to token creator.
        (ownToken).transfer(((cost / 100) * ownerPer)); // transfer 83% to token owner.
        transferFrom(owner, to, tId);
    }

    function updateTokenPrice(uint256 tId, uint256 _price)
        public
        onlyOwner(tId)
        returns (string memory)
    {
        tCost[tId] = _price;
        emit UpdateTokenPrice(tId, _price);
    }

    function enableTokenSale(uint256 tId, uint256 _cost)
        public
        notOnSale(tId)
        onlyOwner(tId)
    {
        tOnSale[tId] = true;
        tCost[tId] = _cost;
        approve(address(this), tId);
        emit TokenForSale(tId, _cost);
    }

    function createAuction(uint256 tId, uint256 _maxBid) public onlyOwner(tId) {
        require(tOnSale[tId], "Token is Not for sale"); // User can't auction token which is in Not for sale
        AuctionData memory data1750 = AuctionData(
            tId,
            0,
            address(0),
            true,
            _maxBid
        );
        tAuction[tId] = data1750;
        tInAuction[tId] = true;
        approve(address(this), tId);
        emit CreateAuction(tId, _maxBid);
    }

    function bid(uint64 tId) public payable inAuction(tId) onlyBidders(tId) {
        if (bids[tId][msg.sender] + msg.value >= tAuction[tId].maximunBid) {
            // bid hits maximum amount
            tAuction[tId].status = false;
            tAuction[tId].hBidder = msg.sender;
            tAuction[tId].hBid = bids[tId][msg.sender] + msg.value;
            bids[tId][msg.sender] = 0;
            tInAuction[tId] = false;
            _tTransfer(ownerOf(tId), msg.sender, tId, tAuction[tId].hBid);
        } else {
            // bid not hits maximum amount
            bids[tId][msg.sender] = bids[tId][msg.sender] + msg.value;
            bidderList[tId].push(msg.sender);
            tAuction[tId].hBidder = tAuction[tId].hBid > bids[tId][msg.sender]
                ? tAuction[tId].hBidder
                : msg.sender;
            tAuction[tId].hBid = tAuction[tId].hBid > bids[tId][msg.sender]
                ? tAuction[tId].hBid
                : bids[tId][msg.sender];
        }

        emit Bid(tId, msg.sender);
    }

    function checkWithdraw(uint256 tId) public returns (string memory) {
        if (bids[tId][msg.sender] > 0) {
            withdraw(tId);
        } else {
            return "Zero balance";
        }
    }

    function withdraw(uint256 tId)
        public
        payable
        onlyBidders(tId)
        auctionEnded(tId)
        notAuctionWinner(tId)
        returns (string memory)
    {
        uint256 amount = bids[tId][msg.sender];
        bids[tId][msg.sender] = 0;
        msg.sender.transfer(amount);
        return "Amount withdraw";
    }

    function endAuction(uint64 tId)
        public
        payable
        inAuction(tId)
        onlyOwner(tId)
        returns (string memory)
    {
        tAuction[tId].status = false;
        tInAuction[tId] = false;
        if (tAuction[tId].hBidder == address(0)) {
            return ("Auction Ended");
        }
        uint256 auctionWinBid = tAuction[tId].hBid;
        address auctionWinner = tAuction[tId].hBidder;
        tAuction[tId].hBidder = address(0);
        tAuction[tId].hBid = 0;
        _tTransfer(ownerOf(tId), auctionWinner, tId, auctionWinBid);
        emit EndAuction(tId, "Auction ended");
    }
}