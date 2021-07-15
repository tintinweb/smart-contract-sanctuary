/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Address {
  
    function isContract(address account) internal view returns (bool) {
       
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}


interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Mint(uint indexed index, address indexed minter);
    event Deposit(address indexed account, uint indexed amount);
    event Withdraw(address indexed account, uint indexed amount);
    event NewBid(address indexed bidder, uint indexed amount, uint indexed tokenId);
    event Trade(address indexed seller, address indexed buyer, uint indexed tokenId,uint amount);
    event SellNft(address indexed owner,uint indexed tokenId,uint indexed minPrice);
    event CancelSellNft(address indexed owner,uint indexed tokenId);
    event SaleIsStarted();

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

abstract contract ERC165 is IERC165 {
       function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

contract ERC721 is  Context, ERC165, AccessControl, IERC721, IERC721Metadata {
    using Address for address;
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    string private _name;
    string private _symbol;
    string internal baseURI;
    uint internal price = 5 * 10 ** 15;
    uint256 internal tokensSold = 0;
    bool public _startSale = false;

    uint256 constant MAX_SUPPLY = 10000;
    address public royalty;


    mapping (uint => ForSale) public nftForSale;
    mapping (uint256 => address) private _owners;
    mapping (address => uint256) private _balances;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (uint256 => string) private _tokenURIs;
    mapping (address => uint256[]) public tokensPerOwner;
    mapping(address => uint256[]) internal ownerToIds;
    mapping(uint256 => uint256) internal idToOwnerIndex;
   
    struct ForSale {
        uint nft_uid;
        address owner;
        address bidder;
        uint minValue;
        uint highestBid;
    }
   
    constructor (string memory name_, string memory symbol_,string memory baseURI_,address _royalty) {
        _name = name_;
        _symbol = symbol_;
        baseURI = baseURI_;
        royalty = _royalty;
    }
    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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


    function totalSupply() public view returns (uint256) {
        return tokensSold;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), toString(tokenId)));
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }


    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

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


    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(_owners[_tokenId] == address(0), "Cannot add, already owned.");
        _owners[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length.sub(1);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(_owners[_tokenId] == _from, "Incorrect owner.");
        delete _owners[_tokenId];
        delete nftForSale[_tokenId];
        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length.sub(1);

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
        emit CancelSellNft(_msgSender(),_tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        tokensSold += 1;
        tokensPerOwner[to].push(tokenId);
        _addNFToken(to, tokenId);
        emit Mint(tokenId, to);
        emit Transfer(address(0), to, tokenId);
    }

    function devMint(uint count, address recipient) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "You must have minter role to change baseURI");
        require(tokensSold+count <=10000, "The tokens limit has reached.");
        for (uint i = 0; i < count; i++) {
            uint256 _tokenId = tokensSold + 1;
            _mint(recipient, _tokenId);
        }
    }


    
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        tokensPerOwner[owner].push(tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);
        
        _removeNFToken(from, tokenId);
        _addNFToken(to, tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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

contract ArtStars is ERC721  {
    using SafeMath for uint256;

    bool private lock = false;
    bool public contractPaused;
    uint256 constant CONTRACT_ROYALTY = 2;//Contract royalty in percent
    
    mapping (address => uint256) public ethBalance;



    constructor() ERC721("Art Stars", "ARTSTR", " https://unencrypted.digital/json/" ,address(0x4204BfFf4752E288f886F8FB06CEecb4c813929f)) {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }
    modifier nonReentrant {
        require(!lock, "ReentrancyGuard: reentrant call");
        lock = true;
        _;
        lock = false;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function pauseContract(bool _paused) external  {
        require(hasRole(MINTER_ROLE, _msgSender()), "You must have minter role to pause the contract");
        contractPaused = _paused;
    }

    function setBaseURI(string memory newURI) public returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "You must have minter role to change baseURI");
        baseURI = newURI;
        return true;

    }

    function changeRoyaltyAddr(address _newRoyaltyAddr) public returns(bool){
        require(hasRole(MINTER_ROLE, _msgSender()), "You must have minter role to change royalty address");
        royalty = _newRoyaltyAddr;
        return true;
    }


    function getTokensByOwner(address _owner) public view returns (uint256[] memory){
        return ownerToIds[_owner];
    }

    function toSellNFT(uint tokenId, uint minPrice) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId), "The seller is not owner or approved");
        nftForSale[tokenId] =ForSale(tokenId,_msgSender(),address(0),minPrice,0);
        emit SellNft(_msgSender(),tokenId,minPrice);
        return true;
    }

    function toCancelSaleOfNFT(uint tokenId) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId), "The seller is not owner or approved");
        delete nftForSale[tokenId];
        emit CancelSellNft(_msgSender(),tokenId);
        return true;
    }


    function toMakeBid(uint tokenId) public payable nonReentrant returns(bool){
        require(_exists(tokenId), "The token is nonexistent");
        ForSale memory order = nftForSale[tokenId];
        require(order.owner != address(0),"The token is not for sale");
        require(!_isApprovedOrOwner(_msgSender(), tokenId), "The owner can't make bid");
        if (order.bidder == _msgSender()){
            require(msg.value > 0,"Insufficient funds to make bid");
            order.highestBid = order.highestBid.add(msg.value);
        } else{
            require(msg.value >= order.minValue && msg.value > order.highestBid, "Insufficient funds to make bid");
            order.highestBid = msg.value;
            order.bidder = _msgSender();
        }
        ethBalance[_msgSender()] = ethBalance[_msgSender()].add(msg.value);
        nftForSale[tokenId] = order;
        emit Deposit(_msgSender(),msg.value);
        emit NewBid(_msgSender(),order.highestBid,tokenId);
        return true;
    }

    function toAcceptBid(uint tokenId) public nonReentrant returns(bool){
        require(!contractPaused);
        require(_exists(tokenId), "The token is nonexistent");
        ForSale memory order = nftForSale[tokenId];
        require(order.owner != address(0),"The token is not for sale");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only owner or approved can accept the bid");
        require(ethBalance[order.bidder] >= order.highestBid,"Insufficient funds of the bidder balance");
        delete nftForSale[tokenId];
        uint256 total_royalty = order.highestBid / 100 * CONTRACT_ROYALTY;
        ethBalance[order.bidder] = ethBalance[order.bidder].sub(order.highestBid);
        ethBalance[_msgSender()] = ethBalance[_msgSender()].add(order.highestBid);
        ethBalance[_msgSender()] = ethBalance[_msgSender()].sub(total_royalty);
        (bool success, ) = royalty.call{value:total_royalty}("");
        require(success);
        _transfer(order.owner,order.bidder,tokenId);
        emit CancelSellNft(_msgSender(),tokenId);
        emit Trade(_msgSender(),order.bidder,order.highestBid,tokenId);
        emit Transfer(order.owner,order.bidder,tokenId);
        return true;
    }

    function startSale() external {
        require(hasRole(MINTER_ROLE, _msgSender()), "You must have minter role to change baseURI");
        require(!_startSale);
        _startSale = true;
        emit SaleIsStarted();
    }



    function buyNFT()external payable nonReentrant returns(bool, uint){
        require(!contractPaused);
        require(_startSale, "The sale hasn't started.");
        require(tokensSold+1 <=10000, "The tokens limit has reached.");
        require(msg.value >= price, "Insufficient funds to purchase.");
        (bool success, ) = royalty.call{value:msg.value}("");
        require(success);
        uint _tokenId = tokensSold + 1;
        _mint(_msgSender(), _tokenId);        
        return (true,_tokenId);
    }

    function withdraw(uint amount) external nonReentrant {
        require(!contractPaused);
        require(amount <= ethBalance[_msgSender()],"Insufficient funds to withdraw.");
        ethBalance[_msgSender()] = ethBalance[_msgSender()].sub(amount);
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success);
        emit Withdraw(_msgSender(), amount);
    }

    function deposit() external payable {
        ethBalance[_msgSender()] = ethBalance[_msgSender()].add(msg.value);
        emit Deposit(_msgSender(), msg.value);
    }


}