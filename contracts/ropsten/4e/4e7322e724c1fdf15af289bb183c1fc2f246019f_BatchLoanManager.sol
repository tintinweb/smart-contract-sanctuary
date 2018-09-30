pragma solidity ^0.4.24;

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0), &#39;to, should not be the address 0x0&#39;);
        owner = _to;
        return true;
    }
}

contract SimpleDelegable is Ownable {
    mapping(address => bool) delegates;

    modifier onlyDelegate() {
        require(delegates[msg.sender]);
        _;
    }

    function isDelegate(address _delegate) public view returns (bool) {
        return delegates[_delegate];
    }

    function addDelegate(address _delegate) public onlyOwner returns (bool) {
        delegates[_delegate] = true;
        return true;
    }

    function removeDelegate(address _delegate) public onlyOwner returns (bool) {
        delegates[_delegate] = false;
        return true;
    }
}

/**
    @dev Defines the interface of a standard RCN oracle.

    The oracle is an agent in the RCN network that supplies a convertion rate between RCN and any other currency,
    it&#39;s primarily used by the exchange but could be used by any other agent.
*/
contract Oracle is Ownable {
    uint256 public constant VERSION = 4;

    event NewSymbol(bytes32 _currency);

    mapping(bytes32 => bool) public supported;
    bytes32[] public currencies;

    /**
        @dev Returns the url where the oracle exposes a valid "oracleData" if needed
    */
    function url() public view returns (string);

    /**
        @dev Returns a valid convertion rate from the currency given to RCN

        @param symbol Symbol of the currency
        @param data Generic data field, could be used for off-chain signing
    */
    function getRate(bytes32 symbol, bytes data) public returns (uint256 rate, uint256 decimals);

    /**
        @dev Adds a currency to the oracle, once added it cannot be removed

        @param ticker Symbol of the currency

        @return if the creation was done successfully
    */
    function addCurrency(string ticker) public onlyOwner returns (bool) {
        bytes32 currency = encodeCurrency(ticker);
        NewSymbol(currency);
        supported[currency] = true;
        currencies.push(currency);
        return true;
    }

    /**
        @return the currency encoded as a bytes32
    */
    function encodeCurrency(string currency) public pure returns (bytes32 o) {
        require(bytes(currency).length <= 32);
        assembly {
            o := mload(add(currency, 32))
        }
    }

    /**
        @return the currency string from a encoded bytes32
    */
    function decodeCurrency(bytes32 b) public pure returns (string o) {
        uint256 ns = 256;
        while (true) { if (ns == 0 || (b<<ns-8) != 0) break; ns -= 8; }
        assembly {
            ns := div(ns, 8)
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(ns, 0x20), 0x1f), not(0x1f))))
            mstore(o, ns)
            mstore(add(o, 32), b)
        }
    }

}

contract NanoLoanEngine {
    function createLoan(address _oracleContract, address _borrower, bytes32 _currency,
        uint256 _amount, uint256 _interestRate, uint256 _interestRatePunitory, uint256 _duesIn,
        uint256 _cancelableAt, uint256 _expirationRequest, string _metadata) public returns (uint256);
}

contract BatchLoanManager is SimpleDelegable {
    NanoLoanEngine public engine;
    Token public RCNToken;
    // Loan parameters
    Oracle  public oracle;
    bytes32 public currency;
    uint256 public interestRate;
    uint256 public interestRatePunitory;
    uint256 public duesIn;
    uint256 public cancelableAt;
    uint256 public expirationRequest;

    constructor(NanoLoanEngine _engine, Token _RCNToken) public {
        engine = _engine;
        RCNToken = _RCNToken;
    }

    function setLoanParameters(
        Oracle  _oracle,
        bytes32 _currency,
        uint256 _interestRate,
        uint256 _interestRatePunitory,
        uint256 _duesIn,
        uint256 _cancelableAt,
        uint256 _expirationRequest
    ) external onlyOwner returns(bool){
        oracle = _oracle;
        currency = _currency;
        interestRate = _interestRate;
        interestRatePunitory = _interestRatePunitory;
        duesIn = _duesIn;
        cancelableAt = _cancelableAt;
        expirationRequest = _expirationRequest;

        return true;
    }

    function requestLoans(
        uint256[] _amount,
        bytes32[] _metadata
    ) public onlyDelegate returns(bool) {
        uint256 loansLength = _amount.length;

        for (uint256 i = 0; i < loansLength; i++) {
            engine.createLoan(
                oracle,
                address(this),
                currency,
                _amount[i],
                interestRate,
                interestRatePunitory,
                duesIn,
                cancelableAt,
                expirationRequest,
                decodeCurrency(_metadata[i])
            );
        }

        return true;
    }

    function withdraw(address _to, uint256 _value) onlyDelegate external returns(bool) {
        return RCNToken.transfer(_to, _value);
    }

    /**
        @return the currency string from a encoded bytes32
    */
    function decodeCurrency(bytes32 b) internal pure returns (string o) {
        uint256 ns = 256;
        while (true) { if (ns == 0 || (b<<ns-8) != 0) break; ns -= 8; }
        assembly {
            ns := div(ns, 8)
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(ns, 0x20), 0x1f), not(0x1f))))
            mstore(o, ns)
            mstore(add(o, 32), b)
        }
    }
}