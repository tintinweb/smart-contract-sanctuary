/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

//   /$$$$$$  /$$      /$$  /$$$$$$
//  /$$__  $$| $$$    /$$$ /$$__  $$
// | $$  \ $$| $$$$  /$$$$| $$  \ $$
// | $$  | $$| $$ $$/$$ $$| $$$$$$$$
// | $$  | $$| $$  $$$| $$| $$__  $$
// | $$  | $$| $$\  $ | $$| $$  | $$
// |  $$$$$$/| $$ \/  | $$| $$  | $$
//  \______/ |__/     |__/|__/  |__/
// Project of oma.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
        require(address(this).balance >= amount);
        (bool success, ) = recipient.call{value: amount}("");
        require(success);
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

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0);
        return string(buffer);
    }
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 internal counter;
    string private _name;
    string private _symbol;

    string internal __baseURI = "https://metadata.swissstyle.io/";

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => address[]) internal _owners;
    mapping(uint256 => uint32) internal _ownerCount;

    mapping(uint256 => uint256) private _mintBlockNumbers;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(owner != address(0));
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_ownerCount[tokenId] != 0);
        address owner = _owners[tokenId][_ownerCount[tokenId] - 1];
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return __baseURI;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner);
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()));
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_exists(tokenId));

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender());

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
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
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerCount[tokenId] != 0;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId));
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
        require(_checkOnERC721Received(address(0), to, tokenId, _data));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0));
        require(!_exists(tokenId));

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _ownerCount[tokenId] += 1;
        _owners[tokenId].push(to);
        _mintBlockNumbers[tokenId] = block.number;
        counter++;
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
        require(ERC721.ownerOf(tokenId) == from);
        require(to != address(0));
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _ownerCount[tokenId] += 1;
        _owners[tokenId].push(to);
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function getBlockNumber(uint256 tokenId) public view returns (uint256) {
        return _mintBlockNumbers[tokenId];
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
                    revert();
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

    function ownerCount(uint256 tokenId) public view returns (uint32) {
        return _ownerCount[tokenId];
    }

    function ownerAtIndex(uint256 tokenId, uint32 index)
        public
        view
        returns (address)
    {
        return _owners[tokenId][index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    constructor() payable {}

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = (totalReceived * _shares[account]) /
            _totalShares -
            _released[account];

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] = _released[account] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    function _addPayee(address account, uint256 shares_) internal {
        require(account != address(0));
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0);

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) public view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) public {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) public {
        uint256 value = counter._value;
        require(value > 0);
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) public {
        counter._value = 0;
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
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
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

contract Swissstyle is ERC721, Ownable, PaymentSplitter {
    using Strings for uint256;
    uint256 TOKEN_PRICE = 0.08 * 1e18;
    uint256 constant TOKEN_COUNT = 8888;
    uint256 constant MAX_PRESALE_COUNT = 2;
    bool public mintEnabled = false;
    bool public premintEnabled = false;
    address constant DEV_ADDRESS = 0x73124518c6a1e9f63D5867a0C06161963501D2Bf;
    address constant PRIMARY_ADDRESS =
        0xF62FDf9De5D8E0AF9d994874F48129f5BA365574;
    address constant SECONDARY_ADDRESS =
        0x84973268c54a37D40AA4d46F9cE9A279C0d298B0;

    constructor() ERC721("SwissStyle", "SSS") PaymentSplitter() {
        _addPayee(PRIMARY_ADDRESS, 60);
        _addPayee(SECONDARY_ADDRESS, 30);
        _addPayee(DEV_ADDRESS, 10);
    }

    function mintMany(uint256 amount)
        public
        payable
        costs(TOKEN_PRICE * amount)
        onMint
    {
        require(totalSupply() + amount <= TOKEN_COUNT, "Not enough tokens.");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function mint() public payable costs(TOKEN_PRICE) onMint {
        require(totalSupply() < TOKEN_COUNT, "Not enough tokens.");
        _safeMint(msg.sender, totalSupply());
    }

    function mintOwner() public onlyOwner {
        require(totalSupply() < TOKEN_COUNT, "Not enough tokens.");
        _safeMint(msg.sender, totalSupply());
    }

    function mintOwnerMany(uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= TOKEN_COUNT, "Not enough tokens.");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function setMintEnabled(bool enabled) public onlyOwner {
        mintEnabled = enabled;
    }
    function setPremintEnabled(bool enabled) public onlyOwner {
        premintEnabled = enabled;
    }

    function setTokenPrice(uint256 tokenPrice) public onlyOwner {
        TOKEN_PRICE = tokenPrice;
    }

    modifier costs(uint256 price) {
        require(msg.value == price);
        _;
    }
    modifier onMint() {
        require(mintEnabled);
        _;
    }
    modifier onPremint() {
        require(premintEnabled);
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        __baseURI = uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));
        string memory base = _baseURI();
        return
            string(abi.encodePacked(base, Strings.toString(tokenId), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalSupply() public view returns (uint256) {
        return counter;
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256 tokenId)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );

        uint256 count;
        for (uint256 i; i < totalSupply(); i++) {
            if (owner == _owners[i][_ownerCount[i] - 1]) {
                if (count == index) return i;
                else count++;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }

    function presaleMintMany(uint256 amount, bytes memory signature)
        public
        payable
        costs(TOKEN_PRICE * amount)
        onPremint
    {
        require(totalSupply() + amount <= TOKEN_COUNT, "Not enough tokens.");
        require(balanceOf(msg.sender) + amount <= MAX_PRESALE_COUNT);
        require(verify(addressToMessage(msg.sender), signature));
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function presaleMint(bytes memory signature) public payable costs(TOKEN_PRICE) onPremint {
        require(totalSupply() < TOKEN_COUNT, "Not enough tokens.");
        require(balanceOf(msg.sender) < MAX_PRESALE_COUNT);
        require(verify(addressToMessage(msg.sender), signature));
        _safeMint(msg.sender, totalSupply());
    }

    address constant VERIFY_ADDRESS =
        0xb997ADc54278348FDD86A5543c0250774F55c729;

    function verify(bytes memory h, bytes memory signature)
        internal
        pure
        returns (bool)
    {
        return recover(signature, getSignedMessageHash(h)) == VERIFY_ADDRESS;
    }

    function recover(bytes memory signature, bytes32 h)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(h, v, r, s);
    }

    function getSignedMessageHash(bytes memory message)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    uint2str(message.length),
                    message
                )
            );
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    function addressToMessage(address a) internal pure returns (bytes memory) {
        return abi.encodePacked("0x", toAsciiString(a));
    }
}