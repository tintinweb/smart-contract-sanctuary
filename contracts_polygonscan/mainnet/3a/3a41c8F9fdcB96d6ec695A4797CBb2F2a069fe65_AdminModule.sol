pragma solidity ^0.8.0;


import "../common/variables.sol";
import "./events.sol";
import "../../infiniteProxy/IProxy.sol";

contract AdminModule is Variables, Events {

    modifier onlyOwner {
        require(IProxy(address(this)).getAdmin() == msg.sender, "not-an-admin");
        _;
    }

    modifier isProtocolMod(address protocol_) {
        require(_isProtocol[protocol_], "not-a-protocol");
        _;
    }

    // To enable a protocol.
    function enableProtocol(address protocol_) public onlyOwner {
        require(!_isProtocol[protocol_], "protocol-already-enabled");
        _isProtocol[protocol_] = true;
        emit enableProtocolLog(protocol_);
    }

    // To disable a protocol.
    function disableProtocol(address protocol_) public onlyOwner isProtocolMod(protocol_) {
        _isProtocol[protocol_] = false;
        emit disableProtocolLog(protocol_);
    }

    // making supply limit 0 will disable supply
    function setSupplyLimits(address protocol_, address token_, uint amount_) public onlyOwner isProtocolMod(protocol_) {
        _protocolSupplyLimits[protocol_][token_] = amount_;
        emit setSupplyLimitLog(protocol_, token_, amount_);
    }

    // making borrow limit 0 will disable supply
    function setBorrowLimits(address protocol_, address token_, uint amount_) public onlyOwner isProtocolMod(protocol_) {
        _protocolBorrowLimits[protocol_][token_] = amount_;
        emit setBorrowLimitLog(protocol_, token_, amount_);
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

pragma solidity ^0.8.0;


contract Events {

    event enableProtocolLog(address protocol_);

    event disableProtocolLog(address protocol_);

    event setSupplyLimitLog(address protocol_, address token_, uint amount_);

    event setBorrowLimitLog(address protocol_, address token_, uint amount_);

}

pragma solidity ^0.8.0;


interface IProxy {

    function getAdmin() external view returns (address);

}