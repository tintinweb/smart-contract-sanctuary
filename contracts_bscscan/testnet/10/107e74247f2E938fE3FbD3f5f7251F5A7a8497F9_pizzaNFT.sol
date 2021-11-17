/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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

interface IERC721 is IERC165 {
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
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success,) = recipient.call{value : amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return
        functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require( address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value : value}(
        data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view
    returns (bytes memory)
    {
        return
        functionStaticCall(
            target,
            data,
            "Address: low-level static call failed"
        );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return
        functionDelegateCall(
            target,
            data,
            "Address: low-level delegate call failed"
        );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
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
    function supportsInterface(bytes4 interfaceId)public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
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
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );
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

    function transferFrom( address from, address to, uint256 tokenId) internal virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom( address from, address to, uint256 tokenId) internal virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom( address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer( address from, address to, uint256 tokenId, bytes memory _data ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
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

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
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
        try
        IERC721Receiver(to).onERC721Received(
        _msgSender(),
        from,
        tokenId,
        _data
        )
        returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
        if (reason.length == 0) {
        revert(
        "ERC721: transfer to non ERC721Receiver implementer"
        );
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

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _setOwner(_msgSender());
    }function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Counters {
    struct Counter {
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
    function tryAdd(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
    }
    }

    function trySub(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    if (b > a) return (false, 0);
    return (true, a - b);
    }
    }

    function tryMul(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    if (b == 0) return (false, 0);
    return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    if (b == 0) return (false, 0);
    return (true, a % b);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
    require(b <= a, errorMessage);
    return a - b;
    }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
    require(b > 0, errorMessage);
    return a / b;
    }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
    require(b > 0, errorMessage);
    return a % b;
    }
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract pizzaNFT is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    uint ARTIST_SHARE = 10;
    Counters.Counter private _IngredientIds;
    Counters.Counter private _buyPizzaIds;
    Counters.Counter private _nftIds;
    event createIngredientEvent( uint256 indexed _ingredientId);
    event mintIngredient( uint256 indexed _nftId);
    event mintPizza( uint256 indexed _nftId);

    modifier onlyNFTOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "Ownable: caller is not the owner of the NFT");
        _;
    }

    struct Ingredients {
        uint256 _ingredientId;
        string metadata;
        uint256 price;
        uint256 created;
        address artist;
        uint256 ingType;
    }

    struct Pizzas {
        uint256 _pizzaId;
        uint256 base;
        uint256 sauce;
        uint256 cheeze;
        uint256[] meets;
        uint256[] toppings;
        bool isRandom;
        bool unbaked;
    }

    mapping(address => uint256) public claimableList;
    mapping(uint256 => Ingredients) public ingredientsList;
    mapping(uint256 => uint256) public ingredientTypes;
    mapping(uint256 => Pizzas) public pizzasList;
    constructor() ERC721("Pizza Bake", "PNFT") {}
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function updateArtistShare( uint feePercent) public onlyOwner {
        ARTIST_SHARE = feePercent;
    }
    function claimFunds( uint256 amount) public payable {
        uint256 claimableAmount = claimableList[msg.sender];
        require( claimableAmount >= amount, "You can not claim the specified amount");
        payable(msg.sender).transfer(amount);
    }
    function createIngredient( string memory ingredientTokenURI, uint256 price, address artist, uint256 ingType) public onlyOwner {
        _IngredientIds.increment();
        uint256 _ingredientId = _IngredientIds.current();
        Ingredients memory ingredientDetail = Ingredients(
            _ingredientId,
            ingredientTokenURI,
            price,
            1,
            artist,
            ingType
        );
        ingredientsList[_ingredientId] = ingredientDetail;
        ingredientTypes[_ingredientId] = ingType;
        emit createIngredientEvent(_ingredientId);
    }
    function editIngredient( uint256 _ingredientId, string memory ingredientTokenURI, uint256 price, address artist, uint256 ingType) public onlyOwner {
        Ingredients memory ingredientDetail = Ingredients(
            _ingredientId,
            ingredientTokenURI,
            price,
            1,
            artist,
            ingType
        );
        ingredientsList[_ingredientId] = ingredientDetail;
        ingredientTypes[_ingredientId] = ingType;
    }
    function purchaseAndMintIngretient( uint256 _ingredientId) public payable {
        Ingredients memory ingredientDetail = ingredientsList[_ingredientId];
        require(ingredientDetail.created > 0, "Invalid ingredient");
        require(msg.value >= ingredientDetail.price, "Price is not valid");
        address payable artist = payable(ingredientDetail.artist);
        _nftIds.increment();
        uint256 _nftId = _nftIds.current();
        _mint(msg.sender, _nftId);
        _setTokenURI(_nftId, ingredientDetail.metadata);
        if(artist != address(0)) {
            uint256 currentClaimable = claimableList[ingredientDetail.artist];
            currentClaimable += (msg.value * ARTIST_SHARE / 100);
            claimableList[ingredientDetail.artist] = currentClaimable;
        }
        emit mintIngredient(_nftId);
    }
    //called on bake and random bake
    function bakePizzaAndMint( string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings ) public {
        uint256 baseType = ingredientTypes[base];
        require(baseType == 1, "Please select valid base type");
        require(ownerOf(base) == msg.sender, "You are not owner of base you selected");
        uint256 sauceType = ingredientTypes[sauce];
        require(sauceType == 2, "Please select valid sauce type");
        require(ownerOf(sauce) == msg.sender, "You are not owner of sauce you selected");
        uint256 cheeseType = ingredientTypes[cheese];
        require(cheeseType == 3, "Please select valid cheese type");
        require(ownerOf(cheese) == msg.sender, "You are not owner of cheeze you selected");
        uint256 meatType = 0;
        uint256 toppingType = 0;
        for(uint256 x = 0; x < meats.length; x++) {
            meatType = ingredientTypes[meats[x]];
            require(meatType == 4, "Please select valid meat type");
            require(ownerOf(meats[x]) == msg.sender, "You are not owner of meet you selected");
        }
        for(uint256 x = 0; x < toppings.length; x++) {
            toppingType = ingredientTypes[toppings[x]];
            require(toppingType == 5, "Please select valid topping type");
            require(ownerOf(toppings[x]) == msg.sender, "You are not owner of toppings you selected");
        }
        _IngredientIds.increment();
        uint256 _ingredientId = _IngredientIds.current();
        _mint(owner(), _ingredientId);
        _setTokenURI(_ingredientId, metadata);
        Pizzas memory mintedPizza = Pizzas(
        _ingredientId,
        base,
        sauce,
        cheese,
        meats,
        toppings,
        false,
        false
        );
        pizzasList[_ingredientId] = mintedPizza;
        emit mintPizza(_ingredientId);
    }
    //called on rebake
    function rebakePizza( uint256 _pizzaId, string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings ) public onlyNFTOwner(_pizzaId) {
        uint256 baseType = ingredientTypes[base];
        require(baseType == 1, "Please select valid base type");
        require(ownerOf(base) == msg.sender, "You are not owner of base you selected");
        uint256 sauceType = ingredientTypes[sauce];
        require(sauceType == 2, "Please select valid sauce type");
        require(ownerOf(sauce) == msg.sender, "You are not owner of sauce you selected");
        uint256 cheeseType = ingredientTypes[cheese];
        require(cheeseType == 3, "Please select valid cheese type");
        require(ownerOf(cheese) == msg.sender, "You are not owner of cheeze you selected");
        uint256 meatType = 0;
        uint256 toppingType = 0;
        for(uint256 x = 0; x < meats.length; x++) {
            meatType = ingredientTypes[meats[x]];
            require(meatType == 4, "Please select valid meat type");
            require(ownerOf(meats[x]) == msg.sender, "You are not owner of meet you selected");
        }
        for(uint256 x = 0; x < toppings.length; x++) {
            toppingType = ingredientTypes[toppings[x]];
            require(toppingType == 5, "Please select valid topping type");
            require(ownerOf(toppings[x]) == msg.sender, "You are not owner of toppings you selected");
        }
        _setTokenURI(_pizzaId, metadata);
        // Pizzas memory mintedPizza = Pizzas(
        // _pizzaId,
        // base,
        // sauce,
        // cheese,
        // meats,
        // toppings,
        // false,
        // false
        // );
        // pizzasList[_pizzaId] = mintedPizza;
        emit mintPizza(_pizzaId);
    }
    //called on unbake
    function unbakePizza( uint256 _pizzaId) public onlyNFTOwner(_pizzaId) {
       _burn(_pizzaId);
    }
}