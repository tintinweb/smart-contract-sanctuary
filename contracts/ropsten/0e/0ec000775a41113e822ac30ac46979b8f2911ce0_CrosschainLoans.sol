/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

pragma solidity 0.6.0;


interface ERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Administration {
    // --- Data ---
    uint256 public contractEnabled = 0;

    // --- Auth ---
    mapping(address => uint256) public authorizedAccounts;

    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account)
        external
        isAuthorized
        contractIsEnabled
    {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }

    /**
     * @notice Remove auth from an account
     * @param account Account to add auth to
     */
    function removeAuthorization(address account)
        external
        isAuthorized
        contractIsEnabled
    {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }

    /**
     * @notice Checks whether msg.sender can call an authed function
     */
    modifier isAuthorized {
        require(
            authorizedAccounts[msg.sender] == 1,
            "CrosschainLoans/account-not-authorized"
        );
        _;
    }

    /**
     * @notice Checks whether the contract is enabled
     */
    modifier contractIsEnabled {
        require(contractEnabled == 1, "CrosschainLoans/contract-not-enabled");
        _;
    }

    // --- Administration ---

    function enableContract() external isAuthorized {
        contractEnabled = 1;
        emit EnableContract();
    }

    /**
     * @notice Disable this contract
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event EnableContract();
    event DisableContract();
}

contract CrosschainLoans is Administration {
    using SafeMath for uint256;

    // --- Data ---
    uint256 public secondsPerYear = 31556952;
    uint256 public loanExpirationPeriod = 2592000; // 30 days
    uint256 public acceptExpirationPeriod = 259200; // 3 days

    // --- Loans Data ---
    mapping(uint256 => Loan) loans;
    uint256 public loanIdCounter;
    mapping(address => uint256[]) public userLoans;
    mapping(address => uint256) public userLoansCount;

    enum State {
        Open,
        Funded,
        Approved,
        Withdrawn,
        Repaid,
        PaybackRefunded,
        Closed,
        Canceled
    }

    struct Loan {
        // Actors
        address payable borrower;
        address payable lender;
        address lenderAuto;
        // Lender's aCoin address
        address aCoinLenderAddress;
        // Hashes
        bytes32 secretHashA1;
        bytes32 secretHashB1;
        bytes32 secretHashAutoB1;
        // Secrets
        bytes32 secretA1;
        bytes32 secretB1;
        bytes32 secretAutoB1;
        // Expiration Dates
        uint256 loanExpiration;
        uint256 acceptExpiration;
        uint256 createdAt;
        // Loan Details
        uint256 principal;
        uint256 interest;
        // Loan State
        State state;
        // token
        address contractAddress;
        ERC20 token;
    }

    struct AssetType {
        uint256 maxLoanAmount;
        uint256 minLoanAmount;
        uint256 supply;
        uint256 demand;
        uint256 baseRatePerPeriod;
        uint256 multiplierPerPeriod;
        uint256 enabled;
        address contractAddress;
        ERC20 token;
    }

    // Data about each asset type
    mapping(address => AssetType) public assetTypes;

    // -- Init ---
    constructor() public {
        contractEnabled = 1;
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }

    /**
     * @notice Calculates the utilization rate for the given asset
     * @param _supply The total supply for the given asset
     * @param _demand The total demand for the given asset
     */
    function utilizationRate(uint256 _supply, uint256 _demand)
        public
        pure
        returns (uint256)
    {
        if (_demand == 0) {
            return 0;
        }
        return _demand.mul(1e18).div(_supply.add(_demand));
    }

    /**
     * @notice Calculates the loan period interest rate
     * @param _contractAddress The contract address of the given asset
     */
    function getAssetInterestRate(address _contractAddress)
        public
        view
        returns (uint256)
    {
        uint256 ur =
            utilizationRate(
                assetTypes[_contractAddress].supply,
                assetTypes[_contractAddress].demand
            );
        return
            ur
                .mul(assetTypes[_contractAddress].multiplierPerPeriod)
                .div(1e18)
                .add(assetTypes[_contractAddress].baseRatePerPeriod);
    }

    /**
     * @notice Create a loan offer
     * @param _lenderAuto Address of auto lender
     * @param _secretHashB1 Hash of the secret B1
     * @param _secretHashAutoB1 Hash fo the secret B1 of auto lender
     * @param _principal Principal of the loan
     * @param _contractAddress The contract address of the ERC20 token
     */
    function createLoan(
        // actors
        address _lenderAuto,
        // secret hashes
        bytes32 _secretHashB1,
        bytes32 _secretHashAutoB1,
        // loan details
        uint256 _principal,
        address _contractAddress,
        address _aCoinLenderAddress
    ) public contractIsEnabled returns (uint256 loanId) {
        require(_principal > 0, "CrosschainLoans/invalid-principal-amount");
        require(
            assetTypes[_contractAddress].enabled == 1,
            "CrosschainLoans/asset-type-disabled"
        );
        require(
            _principal <= assetTypes[_contractAddress].maxLoanAmount &&
                _principal >= assetTypes[_contractAddress].minLoanAmount,
            "CrosschainLoans/invalid-principal-range"
        );

        // Check allowance
        ERC20 token = ERC20(_contractAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(
            allowance >= _principal,
            "CrosschainLoans/insufficient-token-allowance"
        );

        // Transfer Token
        require(
            token.transferFrom(msg.sender, address(this), _principal),
            "CrosschainLoans/token-transfer-failed"
        );

        // Increment loanIdCounter
        loanIdCounter = loanIdCounter + 1;

        // Add Loan to mapping
        loans[loanIdCounter] = Loan({ // Actors
            borrower: address(0),
            lender: msg.sender,
            lenderAuto: _lenderAuto,
            aCoinLenderAddress: _aCoinLenderAddress, // Secret Hashes
            secretHashA1: "",
            secretHashB1: _secretHashB1,
            secretHashAutoB1: _secretHashAutoB1,
            secretA1: "",
            secretB1: "",
            secretAutoB1: "", // Expiration dates
            loanExpiration: 0,
            acceptExpiration: 0,
            createdAt: now,
            principal: _principal,
            interest: _principal
                .mul(getAssetInterestRate(_contractAddress))
                .div(1e18),
            contractAddress: _contractAddress,
            token: token,
            state: State.Funded
        });

        // Add LoanId to user
        userLoans[msg.sender].push(loanIdCounter);

        // Increase userLoansCount
        userLoansCount[msg.sender] = userLoansCount[msg.sender] + 1;

        // Increase asset type supply
        assetTypes[_contractAddress].supply = assetTypes[_contractAddress]
            .supply
            .add(_principal);

        emit LoanCreated(loanIdCounter);
        return loanIdCounter;
    }

    /**
     * @notice Set borrower and approve loan
     * @param _loanId The ID of the loan
     * @param _borrower Borrower's address
     * @param _secretHashA1 The hash of borrower's secret A1
     */
    function setBorrowerAndApprove(
        uint256 _loanId,
        address payable _borrower,
        bytes32 _secretHashA1
    ) public contractIsEnabled {
        require(
            loans[_loanId].state == State.Funded,
            "CrosschainLoans/loan-not-funded"
        );
        require(
            msg.sender == loans[_loanId].lender ||
                msg.sender == loans[_loanId].lenderAuto,
            "CrosschainLoans/account-not-authorized"
        );

        // Add LoanId to user
        userLoans[_borrower].push(loanIdCounter);

        // Increase userLoanCount
        userLoansCount[_borrower] = userLoansCount[_borrower] + 1;

        loans[_loanId].state = State.Approved;
        loans[_loanId].borrower = _borrower;
        loans[_loanId].secretHashA1 = _secretHashA1;
        loans[_loanId].loanExpiration = now.add(loanExpirationPeriod);
        loans[_loanId].acceptExpiration = now.add(loanExpirationPeriod).add(
            acceptExpirationPeriod
        );

        emit LoanAssignedAndApproved(
            _loanId,
            _borrower,
            _secretHashA1,
            loans[_loanId].state
        );
    }

    /**
     * @notice Withdraw the loan's principal
     * @param _loanId The ID of the loan
     * @param _secretA1 Borrower's secret A1
     */
    function withdraw(uint256 _loanId, bytes32 _secretA1)
        public
        contractIsEnabled
    {
        require(
            loans[_loanId].state == State.Approved,
            "CrosschainLoans/loan-not-approved"
        );
        require(
            sha256(abi.encodePacked(_secretA1)) == loans[_loanId].secretHashA1,
            "CrosschainLoans/invalid-secret-A1"
        );
        require(
            now <= loans[_loanId].loanExpiration,
            "CrosschainLoans/loan-expired"
        );

        loans[_loanId].state = State.Withdrawn;
        loans[_loanId].secretA1 = _secretA1;

        loans[_loanId].token.transfer(
            loans[_loanId].borrower,
            loans[_loanId].principal
        );

        // Increase asset type demand
        address contractAddress = loans[_loanId].contractAddress;
        assetTypes[contractAddress].demand = assetTypes[contractAddress]
            .demand
            .add(loans[_loanId].principal);

        emit LoanPrincipalWithdrawn(
            _loanId,
            loans[_loanId].borrower,
            loans[_loanId].principal,
            _secretA1,
            loans[_loanId].state
        );
    }

    /**
     * @notice Accept borrower's repayment of principal
     * @param _loanId The ID of the loan
     * @param _secretB1 Lender's secret B1
     */
    function acceptRepayment(uint256 _loanId, bytes32 _secretB1)
        public
        contractIsEnabled
    {
        require(
            sha256(abi.encodePacked(_secretB1)) ==
                loans[_loanId].secretHashB1 ||
                sha256(abi.encodePacked(_secretB1)) ==
                loans[_loanId].secretHashAutoB1,
            "CrosschainLoans/invalid-secret-B1"
        );
        require(
            now <= loans[_loanId].acceptExpiration,
            "CrosschainLoans/accept-period-expired"
        );
        require(
            loans[_loanId].state == State.Repaid,
            "CrosschainLoans/loan-not-repaid"
        );

        loans[_loanId].state = State.Closed;
        loans[_loanId].secretB1 = _secretB1;

        uint256 repayment =
            loans[_loanId].principal.add(loans[_loanId].interest);
        require(
            loans[_loanId].token.transfer(loans[_loanId].lender, repayment),
            "CrosschainLoans/token-transfer-failed"
        );

        emit LoanRepaymentAccepted(_loanId, repayment, loans[_loanId].state);
    }

    /**
     * @notice Cancel loan before the borrower withdraws the loan's principal
     * @param _loanId The ID of the loan
     * @param _secretB1 Lender's secret B1
     */
    function cancelLoanBeforePrincipalWithdraw(
        uint256 _loanId,
        bytes32 _secretB1
    ) public contractIsEnabled {
        require(
            sha256(abi.encodePacked(_secretB1)) ==
                loans[_loanId].secretHashB1 ||
                sha256(abi.encodePacked(_secretB1)) ==
                loans[_loanId].secretHashAutoB1,
            "CrosschainLoans/invalid-secret-B1"
        );
        // require(now <= loans[_loanId].acceptExpiration,"CrosschainLoans/accept-period-expired");
        require(
            loans[_loanId].state == State.Funded ||
                loans[_loanId].state == State.Approved,
            "CrosschainLoans/principal-withdrawn"
        );
        loans[_loanId].state = State.Canceled;
        uint256 principal = loans[_loanId].principal;
        loans[_loanId].principal = 0;
        loans[_loanId].secretB1 = _secretB1;

        // Decrease supply
        address contractAddress = loans[_loanId].contractAddress;
        assetTypes[contractAddress].supply = assetTypes[contractAddress]
            .supply
            .sub(loans[_loanId].principal);

        require(
            loans[_loanId].token.transfer(loans[_loanId].lender, principal),
            "CrosschainLoans/token-refund-failed"
        );
        emit CancelLoan(_loanId, _secretB1, loans[_loanId].state);
    }

    /**
     * @notice Payback loan's principal and interest
     * @param _loanId The ID of the loan
     */
    function payback(uint256 _loanId) public contractIsEnabled {
        require(
            loans[_loanId].state == State.Withdrawn,
            "CrosschainLoans/invalid-loan-state"
        );
        require(
            now <= loans[_loanId].loanExpiration,
            "CrosschainLoans/loan-expired"
        );

        uint256 repayment =
            loans[_loanId].principal.add(loans[_loanId].interest);

        // Check allowance
        uint256 allowance =
            loans[_loanId].token.allowance(msg.sender, address(this));
        require(
            allowance >= repayment,
            "CrosschainLoans/insufficient-token-allowance"
        );

        loans[_loanId].state = State.Repaid;
        require(
            loans[_loanId].token.transferFrom(
                msg.sender,
                address(this),
                repayment
            ),
            "CrosschainLoans/token-transfer-failed"
        );

        emit Payback(
            _loanId,
            loans[_loanId].borrower,
            repayment,
            loans[_loanId].state
        );
    }

    /**
     * @notice Refund the payback amount
     * @param _loanId The ID of the loan
     */
    function refundPayback(uint256 _loanId) public contractIsEnabled {
        require(
            now > loans[_loanId].acceptExpiration,
            "CrosschainLoans/accept-period-not-expired"
        );
        require(
            loans[_loanId].state == State.Repaid,
            "CrosschainLoans/loan-not-repaid"
        );
        loans[_loanId].state = State.PaybackRefunded;
        uint256 refund = loans[_loanId].principal.add(loans[_loanId].interest);
        loans[_loanId].principal = 0;
        loans[_loanId].interest = 0;
        require(
            loans[_loanId].token.transfer(loans[_loanId].borrower, refund),
            "CrosschainLoans/token-transfer-failed"
        );
        emit RefundPayback(
            _loanId,
            loans[_loanId].borrower,
            refund,
            loans[_loanId].state
        );
    }

    /**
     * @notice Get information about an Asset Type
     * @param contractAddress The contract address of the given asset
     */
    function getAssetType(address _contractAddress)
        public
        view
        returns (
            uint256 maxLoanAmount,
            uint256 minLoanAmount,
            uint256 supply,
            uint256 demand,
            uint256 baseRatePerPeriod,
            uint256 multiplierPerPeriod,
            uint256 interestRate,
            uint256 enabled,
            address contractAddress
        )
    {
        maxLoanAmount = assetTypes[_contractAddress].maxLoanAmount;
        minLoanAmount = assetTypes[_contractAddress].minLoanAmount;
        supply = assetTypes[_contractAddress].supply;
        demand = assetTypes[_contractAddress].demand;
        baseRatePerPeriod = assetTypes[_contractAddress].baseRatePerPeriod;
        multiplierPerPeriod = assetTypes[_contractAddress].multiplierPerPeriod;
        interestRate = getAssetInterestRate(_contractAddress);
        enabled = assetTypes[_contractAddress].enabled;
        contractAddress = assetTypes[_contractAddress].contractAddress;
    }

    /**
     * @notice Get information about a loan
     * @param _loanId The ID of the loan
     */
    function fetchLoan(uint256 _loanId)
        public
        view
        returns (
            address[3] memory actors,
            bytes32[3] memory secretHashes,
            bytes32[3] memory secrets,
            uint256[2] memory expirations,
            uint256[2] memory details,
            address aCoinLenderAddress,
            State state,
            address contractAddress
        )
    {
        actors = [
            loans[_loanId].borrower,
            loans[_loanId].lender,
            loans[_loanId].lenderAuto
        ];
        secretHashes = [
            loans[_loanId].secretHashA1,
            loans[_loanId].secretHashB1,
            loans[_loanId].secretHashAutoB1
        ];
        secrets = [
            loans[_loanId].secretA1,
            loans[_loanId].secretB1,
            loans[_loanId].secretAutoB1
        ];
        expirations = [
            loans[_loanId].loanExpiration,
            loans[_loanId].acceptExpiration
        ];
        aCoinLenderAddress = loans[_loanId].aCoinLenderAddress;
        state = loans[_loanId].state;
        details = [loans[_loanId].principal, loans[_loanId].interest];
        contractAddress = loans[_loanId].contractAddress;
    }

    /**
     * @notice Get Account loans
     * @param _account The user account
     */
    function getAccountLoans(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return userLoans[_account];
    }

    /**
     * @notice Modify Loan expiration periods
     * @param _parameter The name of the parameter modified
     * @param _data The new value for the parameter
     */
    function modifyLoanParameters(bytes32 _parameter, uint256 _data)
        external
        isAuthorized
        contractIsEnabled
    {
        require(_data > 0, "CrosschainLoans/null-data");
        if (_parameter == "loanExpirationPeriod") loanExpirationPeriod = _data;
        else if (_parameter == "acceptExpirationPeriod")
            acceptExpirationPeriod = _data;
        else revert("CrosschainLoans/modify-unrecognized-param");
        emit ModifyLoanParameters(_parameter, _data);
    }

    /**
     * @notice Modify AssetType related parameters
     * @param _contractAddress The contract address of the ERC20 token
     * @param _parameter The name of the parameter modified
     * @param _data The new value for the parameter
     */
    function modifyAssetTypeLoanParameters(
        address _contractAddress,
        bytes32 _parameter,
        uint256 _data
    ) external isAuthorized contractIsEnabled {
        require(_data > 0, "CrosschainLoans/null-data");
        require(
            _contractAddress != address(0) &&
                assetTypes[_contractAddress].contractAddress != address(0),
            "CrosschainLoans/invalid-assetType"
        );
        if (_parameter == "maxLoanAmount")
            assetTypes[_contractAddress].maxLoanAmount = _data;
        else if (_parameter == "minLoanAmount")
            assetTypes[_contractAddress].minLoanAmount = _data;
        else if (_parameter == "baseRatePerYear") {
            assetTypes[_contractAddress].baseRatePerPeriod = _data
                .mul(loanExpirationPeriod)
                .div(secondsPerYear);
        } else if (_parameter == "multiplierPerYear") {
            assetTypes[_contractAddress].multiplierPerPeriod = _data
                .mul(loanExpirationPeriod)
                .div(secondsPerYear);
        } else revert("CrosschainLoans/modify-unrecognized-param");
        emit ModifyAssetTypeLoanParameters(_parameter, _data);
    }

    /**
     * @notice Disable AssetType
     * @param _contractAddress The contract address of the ERC20 token
     */
    function disableAssetType(address _contractAddress)
        external
        isAuthorized
        contractIsEnabled
    {
        require(
            _contractAddress != address(0) &&
                assetTypes[_contractAddress].contractAddress != address(0),
            "CrosschainLoans/invalid-assetType"
        );
        assetTypes[_contractAddress].enabled = 0;
        emit DisableAssetType(_contractAddress);
    }

    /**
     * @notice Enable AssetType
     */
    function enableAssetType(address _contractAddress)
        external
        isAuthorized
        contractIsEnabled
    {
        require(
            _contractAddress != address(0) &&
                assetTypes[_contractAddress].contractAddress != address(0),
            "CrosschainLoans/invalid-assetType"
        );
        assetTypes[_contractAddress].enabled = 1;
        emit EnableAssetType(_contractAddress);
    }

    /**
     * @notice Add AssetType
     * @param _contractAddress The contract address of the ERC20 token
     * @param _maxLoanAmount The maximum principal allowed for the token
     * @param _minLoanAmount The minimum principal allowerd for the token
     * @param _baseRatePerYear The approximate target base APR
     * @param _multiplierPerYear The rate of increase in interest rate
     */
    function addAssetType(
        address _contractAddress,
        uint256 _maxLoanAmount,
        uint256 _minLoanAmount,
        uint256 _baseRatePerYear,
        uint256 _multiplierPerYear
    ) external isAuthorized contractIsEnabled {
        require(_contractAddress != address(0));
        require(_maxLoanAmount > 0, "CrosschainLoans/invalid-maxLoanAmount");
        require(_minLoanAmount > 0, "CrosschainLoans/invalid-minLoanAmount");
        require(
            assetTypes[_contractAddress].minLoanAmount == 0,
            "CrosschainLoans/assetType-already-exists"
        );

        assetTypes[_contractAddress] = AssetType({
            contractAddress: _contractAddress,
            token: ERC20(_contractAddress),
            maxLoanAmount: _maxLoanAmount,
            minLoanAmount: _minLoanAmount,
            baseRatePerPeriod: _baseRatePerYear.mul(loanExpirationPeriod).div(
                secondsPerYear
            ),
            multiplierPerPeriod: _multiplierPerYear
                .mul(loanExpirationPeriod)
                .div(secondsPerYear),
            enabled: 1,
            supply: 0,
            demand: 0
        });
        emit AddAssetType(_contractAddress, _maxLoanAmount, _minLoanAmount);
    }

    // --- Events ---
    event LoanCreated(uint256 loanId);
    event LoanFunded(uint256 loanId, uint256 amount, State state);
    event LoanAssignedAndApproved(
        uint256 loanId,
        address borrower,
        bytes32 secretHashA1,
        State state
    );
    event LoanPrincipalWithdrawn(
        uint256 loanId,
        address borrower,
        uint256 amount,
        bytes32 secretA1,
        State state
    );
    event LoanRepaymentAccepted(uint256 loanId, uint256 amount, State state);
    event CancelLoan(uint256 loanId, bytes32 secretB1, State state);
    event Payback(
        uint256 loanId,
        address borrower,
        uint256 amount,
        State state
    );
    event RefundPayback(
        uint256 loanId,
        address borrower,
        uint256 amount,
        State state
    );

    event ModifyLoanParameters(bytes32 parameter, uint256 data);
    event ModifyAssetTypeLoanParameters(bytes32 parameter, uint256 data);
    event DisableAssetType(address contractAddress);
    event EnableAssetType(address contractAddress);
    event AddAssetType(
        address contractAddress,
        uint256 maxLoanAmount,
        uint256 minLoanAmount
    );
}