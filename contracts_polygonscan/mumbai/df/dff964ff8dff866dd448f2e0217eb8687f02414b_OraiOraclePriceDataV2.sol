/**
 *Submitted for verification at polygonscan.com on 2021-07-02
*/

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * onlyOwner functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IOraiBase {
    struct ResponsePriceData {
        uint128 rate;
        uint64 lastUpdatedBase;
        uint64 lastUpdatedQuote;
    }

    struct PriceData {
        uint128 rate; // USD-rate, multiplied by 1e18.
        uint64 resolveTime; // UNIX epoch when data is last resolved.
    }

    function getPrice(string memory _base, string memory _quote)
    external
    view
    returns (ResponsePriceData memory);

    function getPrice(string memory _base)
    external
    view
    returns (PriceData memory);

    function getPriceBulk(string[] memory _bases)
    external
    view
    returns (PriceData[] memory);

    function getPriceBulk(string[] memory _bases, string[] memory _quotes)
    external
    view
    returns (ResponsePriceData[] memory);


}

abstract contract OraiBase is IOraiBase {

    function getPrice(string memory _base, string memory _quote)
    public
    virtual
    override
    view
    returns (ResponsePriceData memory);

    function getPrice(string memory _base)
    public
    virtual
    override
    view
    returns (PriceData memory);

    function getPriceBulk(string[] memory _bases)
    public
    override
    view
    returns (PriceData[] memory)
    {
        uint256 len = _bases.length;
        PriceData[] memory results = new PriceData[](len);
        for (uint256 idx = 0; idx < len; idx++) {
            results[idx] = getPrice(_bases[idx]);
        }
        return results;
    }

    function getPriceBulk(string[] memory _bases, string[] memory _quotes)
    public
    override
    view
    returns (ResponsePriceData[] memory)
    {
        require(_bases.length == _quotes.length, "BAD_INPUT_LENGTH");
        uint256 len = _bases.length;
        ResponsePriceData[] memory results = new ResponsePriceData[](len);
        for (uint256 idx = 0; idx < len; idx++) {
            results[idx] = getPrice(_bases[idx], _quotes[idx]);
        }
        return results;
    }
}

contract SignData {
    string public NAME;
    mapping(address => uint) public nonces;

    bytes32 public constant EIP712DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // keccak256('Data(address to,uint16[] memory _symbolIds, uint128[] memory _rates, uint64[] memory _resolveTimes, uint256 deadline, uint256 nonce)')
    bytes32 public constant UPDATE_PRICE_TYPEHASH = 0x9aa2a919c86518d56eb4794f5980c5922e480627ce2e570c3fa456583929d761;

    bytes32 public DOMAIN_SEPARATOR;

    function verify(bytes32 hash, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public returns (address sender){
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hash
            )
        );
        sender = ecrecover(digest, v, r, s);
        require(nonce == nonces[sender], "Invalid nonce");
        nonces[sender]++;

    }

    constructor() public {
        NAME = "OraiOraclePriceData";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                this
            )
        );
    }
}

contract OraiOraclePriceDataV2 is OraiBase, SignData, Ownable {
    event PriceDataUpdate(uint256 blockNumber);


    string[] public  symbols;
    mapping(uint16 => PriceData) public rPrices; // Mapping from symbol to ref data.
    mapping(string => uint16) public supportedAsset;
    mapping(address => bool) public dataSubmitter;

    constructor() public {
        dataSubmitter[msg.sender] = true;
    }
    modifier ensure(uint256 deadline){
        require(deadline > block.timestamp, "DEADLINE_OUT_OF_DATE");
        _;
    }

    function addAssetSupport(string[] calldata _symbols) external onlyOwner {
        for (uint256 i = 0; i < _symbols.length; i++) {
            require(supportedAsset[_symbols[i]] == 0, "supported asset");
            supportedAsset[_symbols[i]] = uint16(symbols.length);
            symbols.push(_symbols[i]);
        }
    }

    function setDataSubmitter(address _submitter, bool approval) public onlyOwner {
        dataSubmitter[_submitter] = approval;
    }

    function updatePrice(
        uint16[] calldata _symbolIds,
        uint128[] calldata _rates,
        uint64[] calldata _resolveTimes
    ) external {
        require(dataSubmitter[msg.sender], "NOT_DATA_SUBMITTER");
        _updatePrice(_symbolIds, _rates, _resolveTimes);
    }

    function updatePricePermit(uint16[] calldata _symbolIds, uint128[] calldata _rates, uint64[] calldata _resolveTimes, uint256 deadline, uint256 nonce, uint8 v, bytes32 r, bytes32 s) external ensure(deadline) {
        address keep3r = verify(keccak256(abi.encode(UPDATE_PRICE_TYPEHASH, this, _symbolIds, _rates, _resolveTimes, deadline, nonce)), nonce, v, r, s);
        require(dataSubmitter[keep3r], "NOT_DATA_SUBMITTER");
        _updatePrice(_symbolIds, _rates, _resolveTimes);
    }

    function _updatePrice(
        uint16[] memory _symbolIds,
        uint128[] memory _rates,
        uint64[] memory _resolveTimes
    ) internal {
        uint256 len = _symbolIds.length;
        require(_rates.length == len, "RATES_LENGTH_NOT_EQUAL_SYMBOLS_LENGTH");
        require(_resolveTimes.length == len, "RESOLVE_TIMES_LENGTH_NOT_EQUAL_SYMBOLS_LENGTH");
        emit PriceDataUpdate(block.number);
        for (uint256 idx = 0; idx < len; idx++) {
            rPrices[_symbolIds[idx]] = PriceData({rate : _rates[idx], resolveTime : _resolveTimes[idx]});
        }
    }

    function getPrice(string memory _base, string memory _quote)
    public override view returns (ResponsePriceData memory)
    {
        PriceData memory basePriceData = getPrice(_base);
        PriceData memory quotePriceData = getPrice(_quote);
        return ResponsePriceData({
            rate : uint128((uint256(basePriceData.rate) * 1e18) / quotePriceData.rate),
            lastUpdatedBase : basePriceData.resolveTime,
            lastUpdatedQuote : quotePriceData.resolveTime
        });
    }

    function getPrice(string memory _symbol) public override view returns (PriceData memory)
    {
        if (keccak256(bytes(_symbol)) == keccak256(bytes("USD"))) {
            return PriceData(1e18, uint64(now));
        }
        uint16 idx = supportedAsset[_symbol];
        PriceData storage rData = rPrices[idx];
        require(rData.resolveTime > 0, "DATA_NOT_AVAILABLE");
        return rData;
    }

}