/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBEP721 {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
    //function balanceOf(address _owner) external view returns(uint256);
    //function ownerOf(uint256 _cardId) external view returns(address);

    function CreateCard(address _owner) external returns(uint256);
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) external returns(uint256);
    function getOwnerNFTCount(address _owner) external view returns(uint256);
    function getOwnerNFTIDs(address _owner) external view returns(uint256[] memory);
    function totalSupply() external view returns(uint256);

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function getApproved(uint256 _tokenId) external view returns (address);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address _owner) external view returns (uint256);
}

contract AccessControl {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event ControllerAccessChanged(address indexed _controller, bool indexed _access);

    mapping(address => bool) whitelistController;
    modifier onlyOwner {
        require(msg.sender == owner, "invalid owner");
        _;
    }
    modifier onlyController {
        require(whitelistController[msg.sender] == true, "invalid controller");
        _;
    }
    function TransferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
    function WhitelistController(address _controller) public onlyOwner {
        whitelistController[_controller] = true;
        emit ControllerAccessChanged(_controller, true);
    }
    function BlacklistController(address _controller) public onlyOwner {
        whitelistController[_controller] = false;
        emit ControllerAccessChanged(_controller, false);
    }
    function Controller(address _controller) public view returns(bool) {
        return whitelistController[_controller];
    }
}

contract TestNFT is IBEP721, AccessControl {
    
    // Token name
    string public name = "Test NFT";
    // Token symbol
    string public symbol = "TEST";
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) owners;
    // Mapping owner address to token count
    mapping(address => uint256) balances;

    //dev Array of all NFT IDs.
    uint256[] internal tokens;
    //Mapping from token ID to its index in global tokens array.
    mapping(uint256 => uint256) internal idToIndex;
    //Mapping from owner to list of owned NFT IDs.
    mapping(address => uint256[]) internal ownerToIds;
    //Mapping from NFT ID to its index in the owner tokens list.
    mapping(uint256 => uint256) internal idToOwnerIndex;

    uint256 public TokenId;

    string public baseTokenURI;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    constructor() {
        AccessControl.owner = msg.sender;
    }

    function create(address _owner) public returns(uint256) {
        TokenId += 1;
        owners[TokenId] = _owner;

        //add new nft item 
        _mint(_owner, TokenId);

        //set owner of new nft item
        addNFToken(_owner, TokenId);
        return TokenId;
    }

    function CreateCard(address _owner) onlyController external virtual override returns(uint256) {
        TokenId += 1;
        owners[TokenId] = _owner;

        //add new nft item 
        _mint(_owner, TokenId);

        //set owner of new nft item
        addNFToken(_owner, TokenId);
        return TokenId;
    }
    
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) onlyController external virtual override returns(uint256)  {
        
        return _transferCard(_cardId, _fromowner, _newowner);
        /*
        require(ownerOf(_cardId) == _fromowner, "invalid owner");
        require(_newowner != address(0), "invalid new owner address");
        //cardForSale[_cardId] = false;
        //_beforeTokenTransfer(from, to, tokenId);

        removeNFToken(_fromowner, _cardId);

        //set nft to the new owner
        addNFToken(_newowner, _cardId);
        
        emit Transfer(_fromowner, _newowner, _cardId);
        return _cardId;
        */
    }

    function _transferCard(uint256 _cardId, address _fromowner, address _newowner) internal returns(uint256)  {
        require(ownerOf(_cardId) == _fromowner, "invalid owner");
        require(_newowner != address(0), "invalid new owner address");
        //cardForSale[_cardId] = false;
        //_beforeTokenTransfer(from, to, tokenId);

        removeNFToken(_fromowner, _cardId);

        //set nft to the new owner
        addNFToken(_newowner, _cardId);
        
        emit Transfer(_fromowner, _newowner, _cardId);
        return _cardId;
    }

     function transferFrom( address from, address to, uint256 tokenId) public payable virtual override  {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transferCard(tokenId, from, to);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

     function tokenURI(uint256 _tokenId) public view returns (string memory uri) {
        require(_exists(_tokenId), "token not exist!");
        uri = string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }
    

    function tokenByIndex(uint256 _index) internal view returns(uint256)
    {
        require(_index < tokens.length, "invalid index");
        return tokens[_index];
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) internal view returns(uint256)
    {
        require(_index < ownerToIds[_owner].length, "invalid index");
        return ownerToIds[_owner][_index];
    }

    function getOwnerNFTCount(address _owner) external override virtual view returns(uint256)
    {
        return ownerToIds[_owner].length;
    }

    function getOwnerNFTIDs(address _owner) external override  virtual view returns(uint256[] memory)
    {
        return ownerToIds[_owner];
    }
    
    

    function addNFToken(address _to, uint256 _cardId) internal
    {
        balances[_to] += 1;
        owners[_cardId] = _to;
        ownerToIds[_to].push(_cardId);
        idToOwnerIndex[_cardId] = ownerToIds[_to].length - 1;
    }

    function removeNFToken(address _from, uint256 _cardId) internal  virtual
    {
        delete owners[_cardId];
        balances[_from] -= 1;
        uint256 tokenToRemoveIndex = idToOwnerIndex[_cardId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    function _mint(address to, uint256 _cardId) internal virtual {
        require(to != address(0), "invalid owner address");
        tokens.push(_cardId);
        idToIndex[_cardId] = tokens.length - 1;

        emit Transfer(address(0), to, _cardId);
    }
    
        function _exists(uint256 _cardId) internal view virtual returns(bool) {
        return owners[_cardId] != address(0);
    }
    
    //total count of nfts
    function totalSupply() external override view returns(uint256)
    {
        return tokens.length;
    }
    
    function balanceOf(address _owner) public view virtual override returns(uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return balances[_owner];
    }
    
    function ownerOf(uint256 _cardId) public view virtual override returns(address) {
        address owner = owners[_cardId];
        require(owner != address(0), "owner query for nonexistent token");
        return owner;
    }
    
    function shutdown()  public onlyOwner {
        selfdestruct(payable(AccessControl.owner));
    }


  

    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        //emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override  returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */

    function setApprovalForAll(address operator, bool approved) public virtual override  {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        //emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }



}


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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