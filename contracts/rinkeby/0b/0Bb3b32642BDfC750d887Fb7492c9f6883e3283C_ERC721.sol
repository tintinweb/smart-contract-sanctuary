/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    
}

interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);
    
    function totalSupply() external view returns(uint256);
    
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library Strings {

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

}

contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Strings for uint256;

    address private _owner;

    mapping(address => bool) private _manager;

    string private uriLink = "";
    
    uint256 private _totalSupply;

    string private _name = "Surreal Society";
    string private _symbol = "SURREAL";

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    bool private _whiteMinting = false;//if minting is on or off
    bool private _minting = false;//if minting is on or off

    uint256 private _whitePrice = 100000000000000000;
    uint256 private _publicPrice = 150000000000000000;

    mapping(address => uint256) private _userWhiteMints; //How many times did the user mint in white lsit minting
    mapping(address => uint256) private _userMints;

    uint256 private _whiteMinted;

    mapping(address => bool) private _whiteAccess;

    bool private _reveal = false;

    modifier Manager() {
      require(_manager[msg.sender]);
      _;  
    }

    modifier Owner() {
        require(msg.sender == _owner);
      _;  
    }

    constructor () {
        _owner = msg.sender;
        _manager[msg.sender] = true;
    } 
    
    //Read Functions======================================================================================================================================================
    function owner() external view returns (address) {
        return _owner;
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view override returns(uint256){return _totalSupply;}

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        if(_reveal) {string(abi.encodePacked(uriLink, tokenId.toString(), ".json"));}
        return string(abi.encodePacked(uriLink, "secret.json"));

    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function manager(address user) external view returns(bool) {
        return _manager[user];
    }

    function prices() public view returns(uint256 whitePrice, uint256 publicPrice) {
        whitePrice = _whitePrice;
        publicPrice = _publicPrice;
    }

    function minting() public view returns(bool whiteMint, bool publicMint) {
        whiteMint = _whiteMinting;
        publicMint = _minting;
    }
    
    //Moderator Functions======================================================================================================================================================

    function setNewOwner(address user) external Owner {
        _owner = user;
    }

    function addManager(address user) external Owner {
        _manager[user] = true;
    }

    function removeManager(address user) external Owner {
        _manager[user] = false;
    }

    function setWhiteList(address[] calldata whiteUsers) external Owner {
        uint256 size = whiteUsers.length;
            
            for(uint256 t; t < size; ++t) {
                _whiteAccess[whiteUsers[t]] = true;
            }
    }

    function adminMint(address to, uint256 amount) external Manager {
        _mint(to, amount);
    }

    function adminMint(address[] calldata to, uint256[] calldata amount) external Manager {
        uint256 size = to.length;

        for(uint256 t; t < size; ++t) {_mint(to[t], amount[t]);}
    }

    function changeURIlink(string calldata newUri) external Manager {
        uriLink = newUri;
    }

    function changeData(string calldata name, string calldata symbol) external Manager {
        _name = name;
        _symbol = symbol;
    }

    function changePrices(uint256 whitePrice, uint256 publicPrice) external Manager {
        _whitePrice = whitePrice;
        _publicPrice = publicPrice;
    }

    function setMinting(bool whiteMinting, bool publicMinting) external Manager {
        _whiteMinting = whiteMinting;
        _minting = publicMinting;
    }

    function toggleReveal() external Manager {
        _reveal = !_reveal;
    }

    function withdraw(address payable to, uint256 value) external Manager {
        to.transfer(value);
    }

    function distribute() public Manager {
        
        uint256 balance = address(this).balance / 10000; // This is 0.01% of the total balance -> Needed to do presition calculations without floating point.
        
        require(payable(0x7A6c41c001d6Fbf4AE6022E936B24d0d39AE3a25).send(balance * 500));
        require(payable(0x6Ec4EAA315aba37B7558A66c51D0dd4986128bCb).send(balance * 500));
        require(payable(0x2954F886f9E118F4a680D4B65627ca6b6f6094B3).send(balance * 620));
        require(payable(0x37B8C37EB031312c5DaaA02fD5baD9Dc380a8cc4).send(balance * 130));
        require(payable(0xcc2ba3C4E74A531635b928D2aC5B3f176C8B6ec3).send(balance * 460));
        require(payable(0xC970bd4E2dF5F33ea62c72b9c3d808b8a609e5e1).send(balance * 580));
        require(payable(0x02916D0f68a02c502476DC630628B01Ee36A7826).send(balance * 60));
        require(payable(0x2C1Ba2909A0dC98A6219079FBe9A4ab23517D47E).send(balance * 60));
        require(payable(0x38cA9DAACB4d5e493132c2fE9507bbaee4AB86aC).send(balance * 60));
        require(payable(0x50a583Ab2432BF3bC5E7458C8ed10BC5Ec3AB23E).send(balance * 620));
        require(payable(0x58EE6F81AE4Ed77E8Dc50344Ab7571EA7A75a9b7).send(balance * 24));
        require(payable(0x10f3667970FAd7dA441261c80727caCd8B164806).send(balance * 1000));
        require(payable(0x9D7a3F970Bbc7aB9C8537dc9637051b824A9eD0C).send(balance * 100));
        require(payable(0x41b6cb632F5707bF80a1c904316b19fcBee2a4cF).send(balance * 60));
        require(payable(0x3b0f95D44f629e8E24a294799c4A1D21f06B6969).send(balance * 226));
        require(payable(0x07b699C2B00c08cb017e93e45fab21EA3D5c6Bdc).send(balance * 60));
        require(payable(0x81cc8A4bb62fF93f62EC94e3AA40A3A862c54368).send(balance * 4840));

        require(payable(0x81cc8A4bb62fF93f62EC94e3AA40A3A862c54368).send(address(this).balance));
    }
 
    
    //User Functions======================================================================================================================================================
    function approve(address to, uint256 tokenId) external override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function whiteMint(uint256 amount) external payable {
        require(++_userWhiteMints[msg.sender] < 4, "SURREAL: Minting Limit Reached");
        require(amount < 6, "SURREAL: Max of 5 Mints Per Transaction");

        require(_whiteMinting, "SURREAL: Minting Has Not Started Yet"); 
        require(_whiteAccess[msg.sender], "SURREAL: Invalid Access"); 
        require(msg.value == _whitePrice * amount, "SURREAL: Wrong ETH Value");
        _whiteMinted += amount;
        require(_whiteMinted < 2000,"SURREAL: Insufficient White Mint Tokens");

        _mint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(++_userMints[msg.sender] < 4, "SURREAL: Minting Limit Reached");
        require(amount < 6, "SURREAL: Max of 5 Mints Per Transaction");
        
        require(_minting, "SURREAL: Minting Has Not Started Yet"); 
        require(_totalSupply + amount < 5000, "SURREAL: Insufficient Tokens");
        require(msg.value == _publicPrice * amount, "SURREAL: Wrong ETH Value");

        _mint(msg.sender, amount);
    }
    
    //Internal Functions======================================================================================================================================================
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = _owners[tokenId];
        require(spender == owner || _tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender), "ERC721: Not approved or owner");
        return true;
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_owners[tokenId] == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _mint(address user, uint256 amount) internal {
        _balances[user] += amount;
        
        uint256 tokenId;
        for(uint256 t; t < amount; ++t) {
            tokenId = _totalSupply++;
            
            _owners[tokenId] = user;
                
            emit Transfer(address(0), user, tokenId);
        }
        
    }

}