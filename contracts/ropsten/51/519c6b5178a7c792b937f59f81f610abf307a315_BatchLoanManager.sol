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
        require(msg.sender == owner, &#39;The sender is not the owner&#39;);
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

    event AddDelegate(address delegate, address owner);
    event RemoveDelegate(address delegate, address owner);

    constructor() public {
        addDelegate(msg.sender);
    }

    modifier onlyDelegate() {
        require(delegates[msg.sender], &#39;The sender is not a delegate&#39;);
        _;
    }

    function isDelegate(address _delegate) public view returns (bool) {
        return delegates[_delegate];
    }

    function addDelegate(address _delegate) public onlyOwner returns (bool) {
        delegates[_delegate] = true;
        emit AddDelegate(_delegate, owner);
        return true;
    }

    function removeDelegate(address _delegate) public onlyOwner returns (bool) {
        delegates[_delegate] = false;
        emit RemoveDelegate(_delegate, owner);
        return true;
    }
}

contract Oracle  {}

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