// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./cn-utils.sol";

interface CryptoMonkeyKing {
    function balanceOf(address _owner) external view returns (uint256);
}

contract CryptoNumber is Ownable, ERC721Enumerable, CnUtils {
    using Address for address;
    using SafeMath for uint256;
    /************************************struct********************************/
    struct NFT {
        uint256 id;
        address owner;
        uint256 state;
    }

    struct MintStat {
        uint256 minted;
        uint256 composed;
    }

    /************************************error********************************/
    string constant ID_NOT_VALID = "004000";
    string constant ID_IS_RESERVE = "004001";
    string constant ID_IS_NOT_RESERVE = "004002";
    string constant ID_IS_COMPOSABLE = "004003";
    string constant ID_IS_NOT_COMPOSABLE = "004004";

    string constant NFT_HAS_NO_OWNER = "004010";
    string constant NFT_HAS_OWNER = "004011";
    string constant IS_NFT_OWNER = "004012";
    string constant NOT_NFT_OWNER = "004013";

    string constant NOT_VALID_ADDRESS = "004020";
    string constant NOT_CONTRACT_ADDRESS = "004021";
    string constant NOT_AIRDROP_ADDRESS = "004022";
    string constant NOT_CMK_ADDRESS = "004023";
    string constant NOT_ENOUGH_BALANCE = "004024";
    string constant OUT_OF_MAX_CMK_VIP_MINT = "004025";
    string constant OUT_OF_MAX_CMK_MINT = "004026";
    string constant OUT_OF_MAX_PAGE_SIZE = "004027";

    string constant TOKEN_ERROR_EXPRESS = "004030";
    string constant TOKEN_INVALID_OPERATOR = "004031";
    string constant TOKEN_INVALID_OPERAND = "004032";
    string constant TOKEN_DIVIDEND_IS_ZERO = "004033";
    string constant TOKEN_OPERAND_OUT_OF_MAX_COUNT = "004034";
    string constant TOKEN_OPERAND_OUT_OF_RANGE = "004035";
    string constant TOKEN_STACK_IS_EMPTY = "004036";
    string constant TOKEN_MIDDLE_VALUE_IS_OVERFLOW = "004037";
    string constant TOKEN_RESULT_IS_NOT_THE_LAST_VALUE = "004038";
    string constant TOKEN_RESULT_OUT_OF_RANGE = "004039";
    string constant TOKEN_RESULT_IS_RESERVE_ID = "004040";
    string constant TOKEN_RESULT_HAS_OWNER = "004041";
    string constant TOKEN_RESULT_IS_NOT_COMPOSABLE_ID = "004042";

    string constant CONTRACT_CALL_FAIL = "004050";

    /************************************variable********************************/
    string private baseURI;
    address private airdropAddress;
    uint256 private maxSupply;
    uint256 private maxMintPerTime;
    uint256 private mintPrice;
    uint256 private maxOperandCount;
    uint256 private maxPageSize;
    MintStat private stat;

    CryptoMonkeyKing private cmkContract;
    uint256 private maxCmkMint;
    uint256 private maxCmkVipMint;
    address[] private cmkVipAddresses;
    mapping(address => uint256) private cmkAddressToMinted;

    /************************************validator********************************/
    modifier validId(uint256 _id) {
        require(_id > 0 && _id <= maxSupply, ID_NOT_VALID);
        _;
    }

    modifier validAddr(address _addr) {
        require(_addr != address(0), NOT_VALID_ADDRESS);
        _;
    }

    modifier onlyAirdrop() {
        require(msg.sender == airdropAddress, NOT_AIRDROP_ADDRESS);
        _;
    }

    /************************************helps********************************/
    function _isCmkAddress(address _addr) internal view returns (bool) {
        return cmkContract.balanceOf(_addr) > 0;
    }

    function _isVipAddress(address _addr) internal view returns (bool) {
        for (uint256 i = 0; i < cmkVipAddresses.length; i++) {
            if (_addr == cmkVipAddresses[i]) return true;
        }
        return false;
    }

    function _isReserveId(uint256 _id)
        internal
        view
        validId(_id)
        returns (bool)
    {
        bool isReserveRange = _id > 0 && _id <= 1000;

        string memory idString = uint2str(_id);
        uint256 length = bytes(idString).length;
        bool isSameWithLastThreeDigit = length >= 3 &&
            bytes(idString)[length - 1] == bytes(idString)[length - 2] &&
            bytes(idString)[length - 1] == bytes(idString)[length - 3];
        return isReserveRange || isSameWithLastThreeDigit;
    }

    function _isCmkId(uint256 _id) internal view returns (bool) {
        if (_isReserveId(_id)) return false;
        return _id > 1000 && _id <= 2000;
    }

    function _isFreeId(uint256 _id) internal view returns (bool) {
        if (_isReserveId(_id)) return false;
        return _id > 2000 && _id <= 10000;
    }

    function _isComposableId(uint256 _id) internal view returns (bool) {
        if (_isReserveId(_id)) return false;
        return _id > 10000 && _id <= maxSupply;
    }

    function __mint(uint256 _id) internal validId(_id) {
        require(!_exists(_id), NFT_HAS_OWNER);
        require(!_isReserveId(_id), ID_IS_RESERVE);
        require(!_isComposableId(_id), ID_IS_COMPOSABLE);

        if (_isCmkId(_id)) {
            require(_isCmkAddress(msg.sender), NOT_CMK_ADDRESS);

            if (_isVipAddress(msg.sender)) {
                uint256 cmkVipMinted = cmkAddressToMinted[msg.sender];
                require(cmkVipMinted < maxCmkVipMint, OUT_OF_MAX_CMK_VIP_MINT);

                cmkAddressToMinted[msg.sender] = cmkVipMinted + 1;
            } else {
                uint256 cmkMinted = cmkAddressToMinted[msg.sender];
                require(cmkMinted < maxCmkMint, OUT_OF_MAX_CMK_MINT);

                cmkAddressToMinted[msg.sender] = cmkMinted + 1;
            }
        }

        _mint(msg.sender, _id);
        stat.minted++;
    }

    /************************************business********************************/
    /***contructor***/
    constructor(
        string memory _baseUri,
        address _airdropAddress,
        address _cmkContractAddress,
        uint256 _maxCmkMint,
        uint256 _maxCmkVipMint
    ) ERC721("The Crypto Number", "TCN") {
        setBaseURI(_baseUri);
        setAirdropAddress(_airdropAddress);
        setCmkContractAddress(_cmkContractAddress);
        setMaxCmkMint(_maxCmkMint);
        setMaxCmkVipMint(_maxCmkVipMint);
        setMaxSupply(99999999);
        setMaxMintPerTime(1);
        setMaxOperandCount(5);
        setMaxPageSize(1000);
        setMintPrice(0.01 ether);
    }

    /***ERC721Metadata***/
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /***onlyOwner***/
    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setCmkContractAddress(address _cmkContractAddress)
        public
        onlyOwner
    {
        require(_cmkContractAddress.isContract(), NOT_CONTRACT_ADDRESS);
        cmkContract = CryptoMonkeyKing(_cmkContractAddress);
    }

    function setAirdropAddress(address _airdropAddress) public onlyOwner {
        airdropAddress = _airdropAddress;
    }

    function setCmkVipAddresses(address[] calldata _vipAddresses)
        public
        onlyOwner
    {
        cmkVipAddresses = _vipAddresses;
    }

    function setMaxCmkVipMint(uint256 _maxCmkVipMint) public onlyOwner {
        maxCmkVipMint = _maxCmkVipMint;
    }

    function setMaxCmkMint(uint256 _maxCmkMint) public onlyOwner {
        maxCmkMint = _maxCmkMint;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintPerTime(uint256 _maxMintPerTime) public onlyOwner {
        maxMintPerTime = _maxMintPerTime;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxOperandCount(uint256 _maxOperandCount) public onlyOwner {
        maxOperandCount = _maxOperandCount;
    }

    function setMaxPageSize(uint256 _maxPageSize) public onlyOwner {
        maxPageSize = _maxPageSize;
    }

    function getCmkVipAddresses()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        return cmkVipAddresses;
    }

    function getMaxCmkVipMint() public view onlyOwner returns (uint256) {
        return maxCmkVipMint;
    }

    function getMaxCmkMint() public view onlyOwner returns (uint256) {
        return maxCmkMint;
    }

    /***business***/
    function getOwnerOf(uint256 _id) public view returns (address _owner) {
        _owner = _exists(_id) ? ownerOf(_id) : address(0);
    }

    function getOwnersOf(uint256[] memory _ids)
        public
        view
        returns (address[] memory)
    {
        address[] memory owners = new address[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            owners[i] = getOwnerOf(_ids[i]);
        }
        return owners;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function getCmkContractAddress() public view returns (address) {
        return address(cmkContract);
    }

    function getAirdropAddress() public view returns (address) {
        return airdropAddress;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getMaxMintPerTime() public view returns (uint256) {
        return maxMintPerTime;
    }

    function getMaxOperandCount() public view returns (uint256) {
        return maxOperandCount;
    }

    function getMaxPageSize() public view returns (uint256) {
        return maxPageSize;
    }

    function getMintStat() public view returns (MintStat memory) {
        return stat;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function validMint(uint256 _id, address _addr)
        public
        view
        validId(_id)
        validAddr(_addr)
        returns (uint256)
    {
        if (_exists(_id)) return 1;
        if (_isReserveId(_id)) return 2;
        if (_isComposableId(_id)) return 3;
        if (_isCmkId(_id)) {
            if (!_isCmkAddress(_addr)) return 4;

            if (_isVipAddress(_addr)) {
                if (cmkAddressToMinted[_addr] >= maxCmkVipMint) return 5;
            } else {
                if (cmkAddressToMinted[_addr] >= maxCmkMint) return 6;
            }
        }
        return 0;
    }

    function validComposeId(uint256 _id)
        public
        view
        validId(_id)
        returns (uint256)
    {
        if (_id > maxSupply) return 1;
        if (_exists(_id)) return 2;
        if (_isReserveId(_id)) return 3;
        if (!_isComposableId(_id)) return 4;

        return 0;
    }

    function getNFT(uint256 _id) public view validId(_id) returns (NFT memory) {
        address owner = getOwnerOf(_id);

        uint256 state = 0;
        if (owner != address(0)) {
            state = 1;
        } else if (_isReserveId(_id)) {
            state = 0;
        } else {
            state = 2;
        }

        return NFT(_id, owner, state);
    }

    function getNFTs(uint256[] calldata _ids)
        public
        view
        returns (NFT[] memory)
    {
        require(
            _ids.length >= 0 && _ids.length <= maxPageSize,
            OUT_OF_MAX_PAGE_SIZE
        );

        NFT[] memory NFTs = new NFT[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            address owner = getOwnerOf(id);

            uint256 state = 0;
            if (owner != address(0)) {
                state = 1;
            } else if (_isReserveId(id)) {
                state = 0;
            } else {
                state = 2;
            }

            NFTs[i] = NFT(id, owner, state);
        }
        return NFTs;
    }

    function getNFTsOfOwner(address _addr)
        public
        view
        validAddr(_addr)
        returns (NFT[] memory)
    {
        uint256 length = this.balanceOf(_addr);
        NFT[] memory list = new NFT[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 id = this.tokenOfOwnerByIndex(_addr, i);

            uint256 state = 0;
            if (_addr != address(0)) {
                state = 1;
            } else if (_isReserveId(id)) {
                state = 0;
            } else {
                state = 2;
            }
            list[i] = NFT(id, _addr, state);
        }
        return list;
    }

    function airdrop(address _to, uint256 _id) public onlyAirdrop validId(_id) {
        require(_isReserveId(_id), ID_IS_NOT_RESERVE);
        require(!_exists(_id), NFT_HAS_OWNER);

        _mint(_to, _id);
        stat.minted++;
    }

    function airdropNFTs(address _to, uint256[] calldata _ids)
        public
        onlyAirdrop
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            airdrop(_to, id);
        }
    }

    function give(address _to, uint256 _id) public validId(_id) validAddr(_to) {
        require(getOwnerOf(_id) == msg.sender, NOT_NFT_OWNER);

        _transfer(msg.sender, _to, _id);
    }

    function giveNFTs(address _to, uint256[] calldata _ids) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            give(_to, id);
        }
    }

    function mint(uint256 _id) public payable validId(_id) {

        require(msg.value >= mintPrice, NOT_ENOUGH_BALANCE);

        __mint(_id);

        payable(owner()).transfer(mintPrice);
    }

    function mintNFTs(uint256[] calldata _ids) public payable {
        require(msg.value >= mintPrice * _ids.length, NOT_ENOUGH_BALANCE);

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            __mint(_id);
        }

        payable(owner()).transfer(mintPrice * _ids.length);
    }

    function compose(string[] calldata _tokens) public payable {
        require(msg.value >= mintPrice, NOT_ENOUGH_BALANCE);
        require(_tokens.length >= 3, TOKEN_ERROR_EXPRESS);
        require(_tokens.length % 2 == 1, TOKEN_ERROR_EXPRESS);

        uint256 operandCount = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            string memory t = _tokens[i];

            if (isOperand(t)) {
                uint256 id = str2uint(t);
                require(id > 0 && id <= maxSupply, TOKEN_OPERAND_OUT_OF_RANGE);
                require(getOwnerOf(id) == msg.sender, NOT_NFT_OWNER);

                operandCount++;
            }
        }

        require(
            operandCount <= maxOperandCount,
            TOKEN_OPERAND_OUT_OF_MAX_COUNT
        );

        uint256[] memory stack = new uint256[](_tokens.length);
        uint256 pos = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            string memory t = _tokens[i];
            if (isOperand(t)) {
                stack[pos] = str2uint(t);
                pos += 1;
            } else if (isOperator(t)) {
                require(pos != 0, TOKEN_STACK_IS_EMPTY);
                pos--;
                uint256 r = stack[pos];

                require(pos != 0, TOKEN_STACK_IS_EMPTY);
                pos--;
                uint256 l = stack[pos];

                uint256 c = 0;
                if (isEqual(t, "+")) {
                    (bool success, uint256 result) = l.tryAdd(r);
                    require(success, TOKEN_MIDDLE_VALUE_IS_OVERFLOW);
                    c = result;
                } else if (isEqual(t, "-")) {
                    (bool success, uint256 result) = l.trySub(r);
                    require(success, TOKEN_MIDDLE_VALUE_IS_OVERFLOW);
                    c = result;
                } else if (isEqual(t, "*")) {
                    (bool success, uint256 result) = l.tryMul(r);
                    require(success, TOKEN_MIDDLE_VALUE_IS_OVERFLOW);
                    c = result;
                } else if (isEqual(t, "/")) {
                    (bool success, uint256 result) = l.tryDiv(r);
                    require(success, TOKEN_DIVIDEND_IS_ZERO);
                    c = result;
                } else {
                    require(false, TOKEN_INVALID_OPERATOR);
                }

                stack[pos] = c;
                pos++;
            } else {
                require(false, TOKEN_ERROR_EXPRESS);
            }
        }

        require(pos == 1, TOKEN_RESULT_IS_NOT_THE_LAST_VALUE);
        pos--;

        uint256 newComposedId = stack[pos];

        require(newComposedId <= maxSupply, TOKEN_RESULT_OUT_OF_RANGE);

        require(!_exists(newComposedId), TOKEN_RESULT_HAS_OWNER);

        require(!_isReserveId(newComposedId), TOKEN_RESULT_IS_RESERVE_ID);

        require(
            _isComposableId(newComposedId),
            TOKEN_RESULT_IS_NOT_COMPOSABLE_ID
        );

        _mint(msg.sender, newComposedId);

        stat.minted++;
        stat.composed++;
        
        payable(owner()).transfer(mintPrice);
    }
}