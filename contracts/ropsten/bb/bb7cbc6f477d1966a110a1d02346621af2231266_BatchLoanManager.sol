pragma solidity ^0.4.24;

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
}

contract NanoLoanEngine {
    function createLoan(address _oracleContract, address _borrower, bytes32 _currency,
        uint256 _amount, uint256 _interestRate, uint256 _interestRatePunitory, uint256 _duesIn,
        uint256 _cancelableAt, uint256 _expirationRequest, string _metadata) public returns (uint256);
        function getTotalLoans() public view returns (uint256);
}

contract BatchLoanManager {
    NanoLoanEngine public engine = NanoLoanEngine(0xbeE217bfe06C6FAaa2d5f2e06eBB84C5fb70d9bF);
    Token public RCNToken = Token(0x2f45b6Fb2F28A73f110400386da31044b2e953D4);

    // Loan parameters
    address public oracle               = address(0x0);
    bytes32 public currency             = 0x0;
    uint256 public interestRate         = 6912000000000; // % 45
    uint256 public interestRatePunitory = 4608000000000; // % 67.5
    uint256 public duesIn               = 45 days; // 45 days
    uint256 public cancelableAt         = 30 days; // 30 days
    uint256 public expirationRequest    = now + (10 * 365 * 24 * 60 * 60); // now + 10 years
    uint256 public amount               = 10 * (10 ** 18); // 100 RCN
    address public borrower             = address(0x00225bea75d0b4c0686597097d28d81db86b42ee78);

    uint256 public totalLoans           = 0;

    function setOracle(address  _oracle) external {
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

    function setBorrower(address _borrower) external {
        borrower = _borrower;
    }

    function setLoanParameters(
        address  _oracle,
        bytes32 _currency,
        uint256 _interestRate,
        uint256 _interestRatePunitory,
        uint256 _duesIn,
        uint256 _cancelableAt,
        uint256 _expirationRequest
    ) external returns(bool){
        oracle = _oracle;
        currency = _currency;
        interestRate = _interestRate;
        interestRatePunitory = _interestRatePunitory;
        duesIn = _duesIn;
        cancelableAt = _cancelableAt;
        expirationRequest = _expirationRequest;

        return true;
    }

    event LoansCreateds(uint256 from, uint256 to, address oracle, address borrower,
        bytes32 currency, uint256 amount, uint256 interestRate, uint256 interestRatePunitory,
        uint256 duesIn, uint256 cancelableAt, uint256 expirationRequest);

    function requestLoans(uint _quant) external {
        uint256 from = engine.getTotalLoans();

        for (uint256 i = 0; i < _quant; i++) {
            engine.createLoan(
                oracle,
                borrower,
                currency,
                amount,
                interestRate,
                interestRatePunitory,
                duesIn,
                cancelableAt,
                expirationRequest,
                string(new bytes(engine.getTotalLoans()))
            );
        }
        emit LoansCreateds(
            from,
            engine.getTotalLoans() - 1,
            oracle,
            borrower,
            currency,
            amount,
            interestRate,
            interestRatePunitory,
            duesIn,
            cancelableAt,
            expirationRequest
        );
    }

    function withdraw(address _to, uint256 _value) external returns(bool) {
        return RCNToken.transfer(_to, _value);
    }
}