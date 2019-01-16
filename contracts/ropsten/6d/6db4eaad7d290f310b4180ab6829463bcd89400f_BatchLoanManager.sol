pragma solidity ^0.4.25;

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
}

contract Oracle {}

contract NanoLoanEngine {
    function createLoan(address _oracleContract, address _borrower, bytes32 _currency,
        uint256 _amount, uint256 _interestRate, uint256 _interestRatePunitory, uint256 _duesIn,
        uint256 _cancelableAt, uint256 _expirationRequest, string _metadata) public returns (uint256);
}

contract BatchLoanManager {
    NanoLoanEngine public engine;
    Token public RCNToken;
    // Loan parameters
    Oracle  public oracle               = Oracle(0x0);
    bytes32 public currency             = 0x0;
    uint256 public interestRate         = 6912000000000; // % 45
    uint256 public interestRatePunitory = 4608000000000; // % 67.5
    uint256 public duesIn               = 45 days; // 45 days
    uint256 public cancelableAt         = 30 days; // 30 days
    uint256 public expirationRequest    = now + (10 * 365 * 24 * 60 * 60); // now + 10 years
    uint256 public amount               = 100 ** 18; // 100 RCN
    string public metadata               = "RCN";

    function setToken(Token _RCNToken) external {
        RCNToken = _RCNToken;
    }

    function setEngine(NanoLoanEngine _engine) external {
        engine = _engine;
    }

    function setOracle(Oracle  _oracle) external {
        oracle = _oracle;
    }

    function setCurrency(bytes32 _currency) external {
        currency = _currency;
    }

    function setInterestRate(uint256 _interestRate) external {
        interestRate = _interestRate;
    }

    function setInterestRatePunitory(uint256 _interestRatePunitory) external {
        interestRatePunitory = _interestRatePunitory;
    }

    function setDuesIn(uint256 _duesIn) external {
        duesIn = _duesIn;
    }

    function setCancelableAt(uint256 _cancelableAt) external {
        cancelableAt = _cancelableAt;
    }

    function setExpirationRequest(uint256 _expirationRequest) external {
        expirationRequest = _expirationRequest;
    }

    function setAmount(uint256 _amount) external {
        amount = _amount;
    }

    function setMetadata(string _metadata) external {
        metadata = _metadata;
    }

    function setLoanParameters(
        Oracle  _oracle,
        bytes32 _currency,
        uint256 _interestRate,
        uint256 _interestRatePunitory,
        uint256 _duesIn,
        uint256 _cancelableAt,
        uint256 _expirationRequest,
        string _metadata
    ) external returns(bool){
        oracle = _oracle;
        currency = _currency;
        interestRate = _interestRate;
        interestRatePunitory = _interestRatePunitory;
        duesIn = _duesIn;
        cancelableAt = _cancelableAt;
        expirationRequest = _expirationRequest;
        metadata = _metadata;

        return true;
    }

    function requestLoans(uint _quant) external{
        _requestLoans(address(this), _quant);
    }

    function requestLoans(address _borrower, uint _quant) external{
        _requestLoans(_borrower, _quant);
    }

    function _requestLoans(address _borrower, uint _cant) internal returns(bool) {
        for (uint256 i = 0; i < _cant; i++) {
            engine.createLoan(
                oracle,
                _borrower,
                currency,
                amount,
                interestRate,
                interestRatePunitory,
                duesIn,
                cancelableAt,
                expirationRequest,
                metadata
            );
        }

        return true;
    }

    function withdraw(address _to, uint256 _value) external returns(bool) {
        return RCNToken.transfer(_to, _value);
    }
}