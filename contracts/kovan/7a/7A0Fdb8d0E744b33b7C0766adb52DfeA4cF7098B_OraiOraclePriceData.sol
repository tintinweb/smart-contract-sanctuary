/**
 *Submitted for verification at BscScan.com on 2020-10-06
*/

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;


interface IOraiBase {
    /// A structure returned whenever someone requests for standard reference data.
    struct ResponsePriceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getPrice(string memory _base, string memory _quote)
    external
    view
    returns (ResponsePriceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
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

contract OraiOraclePriceData is OraiBase {
    event PriceDataUpdate(
        string symbol,
        uint64 rate,
        uint64 resolveTime,
        bool tag
    );

    struct PriceData {
        uint64 rate; // USD-rate, multiplied by 1e9.
        uint64 resolveTime; // UNIX epoch when data is last resolved.
    }

    address owner;
    uint256 timeout = 180; //3 minutes

    string[]  public  symbols;
    mapping(string => PriceData) public rPrices; // Mapping from symbol to ref data.
    mapping(string => uint256) public assetSupports;
    mapping(address => bool) public dataSubmitter;

    constructor() public {
        owner = msg.sender;
        dataSubmitter[msg.sender] = true;
    }

    function setAssetSupport(string[] memory _symbols) public {
        require(owner == msg.sender, "ONLY_OWNER");
        require(keccak256(bytes(_symbols[0])) == keccak256(bytes("USD")), "MUST_IS_USD");
        symbols = _symbols;
        for (uint256 i = 0; i < _symbols.length; i++) {
            assetSupports[_symbols[i]] = i;
        }
    }

    function getAssetSupport() public view returns (string[]  memory){
        return symbols;
    }

    function setTimeout(uint256 _time) public {
        require(owner == msg.sender, "ONLY_OWNER");
        timeout = _time;
    }


    function updatePrice(
        uint64[] memory _symbolId,
        uint64[] memory _rates,
        uint64[] memory _resolveTimes
    ) external {
        require(dataSubmitter[msg.sender], "NOT_DATA_SUBMITTER");
        uint256 len = _symbolId.length;
        require(_rates.length == len, "RATES_LENGTH_NOT_EQUAL_SYMBOLS_LENGTH");
        require(_resolveTimes.length == len, "RESOLVE_TIMES_LENGTH_NOT_EQUAL_SYMBOLS_LENGTH");

        for (uint256 idx = 0; idx < len; idx++) {
            if (_resolveTimes[idx] + timeout > block.timestamp) {
                rPrices[symbols[_symbolId[idx]]] = PriceData({
                rate : _rates[idx],
                resolveTime : _resolveTimes[idx]
                });

                emit PriceDataUpdate(
                    symbols[_symbolId[idx]],
                    _rates[idx],
                    _resolveTimes[idx],
                    true
                );
            } else {
                emit PriceDataUpdate(
                    symbols[_symbolId[idx]],
                    _rates[idx],
                    _resolveTimes[idx],
                    false
                );
            }
        }
    }

    function setDataSubmitter(address _submitter, bool approval) public {
        require(owner == msg.sender, "ONLY_OWNER");
        dataSubmitter[_submitter] = approval;
    }

    function getPrice(string memory _base, string memory _quote)
    public
    override
    view
    returns (ResponsePriceData memory)
    {
        (uint256 baseRate, uint256 baseLastUpdate) = getPriceRateWithUsdData(_base);
        (uint256 quoteRate, uint256 quoteLastUpdate) = getPriceRateWithUsdData(_quote);
        return
        ResponsePriceData({
        rate : (baseRate * 1e18) / quoteRate,
        lastUpdatedBase : baseLastUpdate,
        lastUpdatedQuote : quoteLastUpdate
        });
    }

    function getPriceRateWithUsdData(string memory _symbol)
    public
    view
    returns (uint256 rate, uint256 lastUpdate)
    {
        if (keccak256(bytes(_symbol)) == keccak256(bytes("USD"))) {
            return (1e9, now);
        }
        PriceData storage rData = rPrices[_symbol];
        require(rData.resolveTime > 0, "DATA_NOT_AVAILABLE");
        return (uint256(rData.rate), uint256(rData.resolveTime));
    }

}

