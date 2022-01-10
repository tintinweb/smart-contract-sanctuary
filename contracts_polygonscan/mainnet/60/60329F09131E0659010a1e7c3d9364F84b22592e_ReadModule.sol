pragma solidity ^0.8.0;


import "../common/variables.sol";

contract ReadModule is Variables {

    function isProtocol(address protocol_) external view returns (bool) {
        return _isProtocol[protocol_];
    }

    function protocolSupplyLimit(address protocol_, address token_) external view returns (uint256) {
        return _protocolSupplyLimits[protocol_][token_];
    }

    function protocolBorrowLimit(address protocol_, address token_) external view returns (uint256) {
        return _protocolBorrowLimits[protocol_][token_];
    }

    function totalSupplyRaw(address token_) external view returns (uint256) {
        return _rawSupply[token_];
    }

    function totalBorrowRaw(address token_) external view returns (uint256) {
        return _rawBorrow[token_];
    }

    function protocolRawSupply(address protocol_, address token_) external view returns (uint256) {
        return _protocolRawSupply[protocol_][token_];
    }

    function protocolRawBorrow(address protocol_, address token_) external view returns (uint256) {
        return _protocolRawBorrow[protocol_][token_];
    }

    function rate(address token_) external view returns (Rates memory) {
        return _rate[token_];
    }

}

pragma solidity ^0.8.0;


contract Variables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    // Addresses have access to interact with the liquidity contract
    mapping (address => bool) internal _isProtocol;

    // Protocol => token => uint. Tokens limits for supply for a particular protocol. uint = limit of tokens.
    mapping (address => mapping(address => uint)) internal _protocolSupplyLimits;
    // Protocol => token => uint. Tokens limits for borrow for a particular protocol. uint = limit of tokens.
    mapping (address => mapping(address => uint)) internal _protocolBorrowLimits;

    uint public constant initialExchangePrice = 1e18;
    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    // total Supply of a token in raw. raw = totalSupply / supplyExchangePrice.
    mapping (address => uint) internal _rawSupply;
    // total Borrow of a token in raw. raw = totalBorrow / borrowExchangePrice.
    mapping (address => uint) internal _rawBorrow;
    // total Supply of a token in a protocol in raw. raw = totalProtocolSupply / supplyExchangePrice.
    mapping (address => mapping(address => uint)) internal _protocolRawSupply;
    // total Borrow of a token in a protocol in raw. raw = totalProtocolBorrow / borrowExchangePrice.
    mapping (address => mapping(address => uint)) internal _protocolRawBorrow;
    // token rates going on. Rates are calculated using _totalSupply, _totalBorrow, utilization at the time of last interaction.
    mapping(address => Rates) internal _rate;

}