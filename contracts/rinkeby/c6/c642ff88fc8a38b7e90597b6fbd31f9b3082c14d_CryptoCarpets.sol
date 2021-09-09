//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Interfaces.sol";

contract CryptoCarpets is ERC721Metadata, ERC721Enumerable {
    string constant NOTOKEN = "NOTOKEN";
    string constant NOACCESS = "NOACCESS";
    string constant PRICE = "PRICE";
    string constant ZERO_ADDRESS = "ZERO_ADDRESS";
    string constant OUT_OF_RANGE = "OUT_OF_RANGE";
    string constant NO_FUNDS = "NO_FUNDS";
    string constant ONLY_OWNER = "ONLY_OWNER";
    string constant SUPPLY = "SUPPLY";
    string constant LIMIT = "LIMIT";

    string private baseURI;

    mapping(uint256 => address) private owners; //maps tokens to owners
    mapping(address => uint256[]) private ownerTokens; // maps owner address to the list of tokens
    mapping(uint256 => uint256) private ownerIndex; //maps tokens to index in the token owner's list

    mapping(address => mapping(address => bool)) private operators;
    mapping(uint256 => address) private approved;

    uint256 private price;
    address private contractOwner;

    uint32 private maxSupply;
    uint32 private mintLimit;
    uint32 private minted;

    modifier canOperate(
        address _from,
        address _to,
        uint256 _tokenId
    ) {
        require(_to != address(0), NOACCESS);
        address _owner = owners[_tokenId];
        require(_owner != address(0), NOACCESS);
        require(_owner == _from, NOACCESS);
        if (_owner != msg.sender) {
            if (!operators[_owner][msg.sender]) {
                if (approved[_tokenId] != msg.sender) {
                    require(false, NOACCESS);
                }
            }
        }
        _;
    }

    modifier ownerOrOperator(uint256 _tokenId) {
        address _owner = owners[_tokenId];
        require(_owner != address(0));
        if (_owner != msg.sender) {
            if (!operators[_owner][msg.sender]) {
                require(false, NOACCESS);
            }
        }
        _;
    }

    modifier requireContractOwner() {
        require(msg.sender == contractOwner, ONLY_OWNER);
        _;
    }

    constructor(
        uint256 _initialPrice,
        uint32 _maxSupply,
        uint32 _mintLimit
    ) {
        require(_maxSupply > 0);
        price = _initialPrice;
        maxSupply = _maxSupply;
        mintLimit = _mintLimit;
        contractOwner = msg.sender;
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceID == 0x01ffc9a7 || // ERC165
            interfaceID == 0x5b5e139f || // ERC721Metadata
            interfaceID == 0x80ac58cd || // ERC721
            interfaceID == 0x780e9d63; // ERC721Enumerable
    }

    function emitTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data,
        bool _notifyContract
    ) internal {
        if (_notifyContract && isContract(_to)) {
            require(
                ERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    _data
                ) == 0x150b7a02
            );
        }
        emit Transfer(_from, _to, _tokenId);
    }

    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        require(_owner != address(0), ZERO_ADDRESS);
        return ownerTokens[_owner].length;
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        return owners[_tokenId];
    }

    function setBasURI(string calldata uri) external requireContractOwner {
        baseURI = uri;
    }

    function _transferInternal(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data,
        bool safe
    ) internal canOperate(_from, _to, _tokenId) {
        approved[_tokenId] = address(0);

        uint256 _index = ownerIndex[_tokenId];
        uint256[] storage _ownerTokens = ownerTokens[_from];
        uint256 l_1 = _ownerTokens.length - 1;
        if (_index < l_1) {
            _ownerTokens[_index] = _ownerTokens[l_1];
        }
        _ownerTokens.pop();

        addToken(_to, _tokenId);
        emitTransfer(_from, _to, _tokenId, data, safe);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external override {
        _transferInternal(_from, _to, _tokenId, data, true);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        _transferInternal(_from, _to, _tokenId, "", true);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        _transferInternal(_from, _to, _tokenId, "", false);
    }

    function approve(address _approved, uint256 _tokenId)
        external
        override
        ownerOrOperator(_tokenId)
    {
        approved[_tokenId] = _approved;
        emit Approval(owners[_tokenId], _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        require(owners[_tokenId] != address(0));
        return approved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return operators[_owner][_operator];
    }

    function name() external pure override returns (string memory _name) {
        return "Crypto Carpets";
    }

    function symbol() external pure override returns (string memory _symbol) {
        return "CCARPET";
    }

    function tokenURI(uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(_tokenId < minted, NOTOKEN);
        bytes memory s = hex"41";
        while (_tokenId > 0) {
            s = bytes.concat(s, bytes1(uint8((_tokenId & 0x0F) + 65)));
            _tokenId >>= 4;
        }
        return string(bytes.concat(bytes(baseURI), s));
    }

    function addToken(address _to, uint256 _tokenId) internal {
        owners[_tokenId] = _to;
        ownerIndex[_tokenId] = ownerTokens[_to].length;
        ownerTokens[_to].push(_tokenId);
    }

    function mint(uint16 _n) external payable {
        require(_n <= mintLimit, LIMIT);
        require(maxSupply >= minted + _n, SUPPLY);
        require(msg.value >= price * _n, PRICE);
        uint256 _tokenId = minted;
        while (_n > 0) {
            addToken(msg.sender, _tokenId);
            emitTransfer(address(0), msg.sender, _tokenId, "", false);
            _n--;
            _tokenId++;
        }
        minted = uint32(_tokenId);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function changeOwner(address _newOwner) external requireContractOwner {
        require(!isContract(_newOwner));
        contractOwner = _newOwner;
    }

    function withdraw(address _to, uint256 amount)
        external
        requireContractOwner
    {
        require(amount <= address(this).balance, NO_FUNDS);
        payable(_to).transfer(amount);
    }

    function totalSupply() external view override returns (uint256) {
        return minted;
    }

    function tokenByIndex(uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        require(_index < minted, OUT_OF_RANGE);
        return _index;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        require(_owner != address(0), ZERO_ADDRESS);
        uint256[] storage _tokens = ownerTokens[_owner];
        require(_index < _tokens.length, OUT_OF_RANGE);
        return _tokens[_index];
    }
}