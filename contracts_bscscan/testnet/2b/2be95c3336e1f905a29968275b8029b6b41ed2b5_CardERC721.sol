// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TokenERC721.sol";
contract CardERC721 is TokenERC721{
    struct Card{
        string name;
        uint256 level;
    }

    Card[] public cards;
    address public owner;

    constructor () TokenERC721("Junk Card","JCD","https://u3flw3vcfmq9.usemoralis.com/"){
        owner = msg.sender;
    }

    function mintCard(string memory name, address account, string memory tokenUri ) public {
        require(owner == msg.sender,"Not owner of this card");
        uint256 cardId = cards.length;
        cards.push(Card(name,1));   
        _mint(account, cardId);
        _setTokenUri(cardId,tokenUri);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
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

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract TokenERC721 is IERC721 {
    using Address for address;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // token name
    string private _name;

    // token symbol
    string private _symbol;

    // base uri
    string private _uriBase;

    // mapping token id to its URI
    mapping(uint256 => string) private _tokenURI;

    // mapping from token id to owner
    mapping(uint256 => address) private _owner;

    // mapping owner to token count
    mapping(address => uint256) private _balance;

    // mapping from token to approved Address
    mapping(uint256 => address) private _tokenApproval;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory name,
        string memory symbol,
        string memory uriBase
    ) {
        _name = name;
        _symbol = symbol;
        _uriBase = uriBase;
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(owner != address(0), "Balance of the zero address");
        return _balance[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owner[tokenId];
        require(owner != address(0), "Owner query for none-existent token");
        return owner;
    }

    

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owner[tokenId] != address(0);
    }

    function mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "mint to zero address");
        require(!_exists(tokenId), "Token is available!");
        _balance[to] += 1;
        _owner[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {

    // }

    function _saveTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }
    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _owner[tokenId] = to;
        _balance[to] +=1;

        emit Transfer(address(0), to, tokenId);
    }

    // check if the token is managed by the spender
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), "non-existent token");
        address owner = TokenERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(TokenERC721.ownerOf(tokenId) == from, "Incorrect owner");
        require(to != address(0), "Transfer to address zero ");

        _balance[from] -= 1;
        _balance[to] += 1;
        _owner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);

        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "Transfer to non ERC721Reciever implement"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _safeTransfer(from, to, tokenId, _data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
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

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _owner[tokenId];
        require(owner != to, "Approval to the current owner");
        require(
            msg.sender != owner,
            "Approval call is not from the current owner"
        );

        _tokenApproval[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_exists(tokenId), "Non existence token");
        return _tokenApproval[tokenId];
    }

    function setApprovalForAll(address to, bool approved)
        public
        virtual
        override
    {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory tokenUri = _tokenURI[tokenId];
        string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) {
            return tokenUri;
        }
        if (bytes(tokenUri).length == 0) {
            return string(abi.encodePacked(baseURI, tokenUri));
        }
        return string(abi.encodePacked(baseURI, tokenId));
    }
    function _setTokenUri(uint256 tokenId, string memory _tokenUri) internal virtual{
        require(_exists(tokenId), "non-existent token id");
        _tokenURI[tokenId] = _tokenUri;
    }
    function _baseURI() internal view virtual returns (string memory) {
        return _uriBase;
    }
}