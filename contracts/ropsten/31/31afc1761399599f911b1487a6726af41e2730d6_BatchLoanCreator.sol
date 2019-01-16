pragma solidity ^0.4.24;

contract NanoLoanEngine {
    function createLoan(address _oracleContract, address _borrower, bytes32 _currency,
        uint256 _amount, uint256 _interestRate, uint256 _interestRatePunitory, uint256 _duesIn,
        uint256 _cancelableAt, uint256 _expirationRequest, string _metadata) public returns (uint256);
        function getTotalLoans() public view returns (uint256);
}

contract BatchLoanCreator {
    NanoLoanEngine public engine = NanoLoanEngine(0xbeE217bfe06C6FAaa2d5f2e06eBB84C5fb70d9bF);

    constructor(NanoLoanEngine _engine) public {
        if(_engine != address(0x0)) engine = _engine;
    }

    // Loan parameters
    address public oracle               = address(0x0);
    bytes32 public currency             = 0x0;
    uint256 public interestRate         = 6912000000000; // % 45
    uint256 public interestRatePunitory = 4608000000000; // % 67.5
    uint256 public duesIn               = 45 days;
    uint256 public cancelableAt         = 30 days;
    uint256 public expirationRequest    = now + (10 * 365 * 1 days); // now + 10 years
    uint256 public amount               = 10 * (10 ** 18); // 100 RCN

    uint256 public totalLoans           = 0;

    function setLoanParameters(
        address  _oracle,
        bytes32 _currency,
        uint256 _amount,
        uint256 _interestRate,
        uint256 _interestRatePunitory,
        uint256 _duesIn,
        uint256 _cancelableAt,
        uint256 _expirationRequest
    ) external returns(bool){
        if(_oracle != 0x0)               oracle = _oracle;
        if(_currency != 0x0)             currency = _currency;
        if(_amount != 0x0)               amount = _amount;
        if(_interestRate != 0x0)         interestRate = _interestRate;
        if(_interestRatePunitory != 0x0) interestRatePunitory = _interestRatePunitory;
        if(_duesIn != 0x0)               duesIn = _duesIn;
        if(_cancelableAt != 0x0)         cancelableAt = _cancelableAt;
        if(_expirationRequest != 0x0)    expirationRequest = _expirationRequest;

        return true;
    }

    event LoansCreateds(uint256 from, uint256 to, address borrower, address oracle,
        bytes32 currency, uint256 amount, uint256 interestRate, uint256 interestRatePunitory,
        uint256 duesIn, uint256 cancelableAt, uint256 expirationRequest);

    function requestLoans(address _borrower, uint _quant) external {
        uint256 from = engine.getTotalLoans();
        address borrower = _borrower == 0x0 ? address(this) : _borrower;

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
            borrower,
            oracle,
            currency,
            amount,
            interestRate,
            interestRatePunitory,
            duesIn,
            cancelableAt,
            expirationRequest
        );
    }
}