/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint256) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.value;
    }
}


abstract contract Pausable is Context {

  bool isReentrant = false;
    bool private isPaused;
    event PauseState(address indexed _pauser, bool isPaused);

    constructor() {
        isPaused = false;
    }

    modifier whenNotPaused() {
        require(!_paused(), "Paused status");
        _;
    }

    modifier whenPaused() {
        require(_paused(), "Not paused status");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        isPaused = true;
        emit PauseState(_msgSender(), true);
    }

    function _unpause() internal virtual whenPaused {
        isPaused = false;
        emit PauseState(_msgSender(), false);
    }

    function _paused() internal virtual view returns(bool) {
        return isPaused;
    }

    function _checkPauseState() internal view {
        require(isPaused == false,"The contract is paused. Transfer functions are temporarily disabled");
    }

    modifier nonReentrant() {
    require(isReentrant == false, "Re-entrant alert!");
    isReentrant = true;
    _;
    isReentrant = false;
  }
}
pragma experimental ABIEncoderV2;


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IBEP20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function approveFrom(address _sender, address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function increaseAllowance(address _spender, uint256 _value) external returns(bool);
    function decreaseAllowance(address _spender, uint256 _value) external returns(bool);
    function transferFrom(address _from,address _to,uint256 _value) external returns (bool);
    function pauseState() external view returns(string memory);
}


interface ITokenList {
    function isMarketSupported(bytes32  market_) external view returns (bool);
    function getMarketAddress(bytes32 market_) external view returns (address);
    function getMarketDecimal(bytes32 market_) external view returns (uint);
    function addMarketSupport(bytes32 _market,uint256 _decimals,address marketAddress_, uint _amount) external returns (bool);
    function minAmountCheck(bytes32 _market, uint _amount) external view;
    function removeMarketSupport(bytes32 market_) external returns(bool);
    function updateMarketSupport(bytes32 market_, uint256 decimals_,address tokenAddress_) external returns(bool);
    // function quantifyAmount(bytes32 _market, uint _amount) external view returns (uint);
    function isMarket2Supported(bytes32  market_) external view returns (bool);
    function getMarket2Address(bytes32 market_) external view returns (address);
    function getMarket2Decimal(bytes32 market_) external view returns (uint);
    function addMarket2Support(bytes32 market_,uint256 decimals_,address tokenAddress_) external returns (bool);
    function removeMarket2Support(bytes32 market_) external returns(bool);
    function updateMarket2Support(bytes32 market_, uint256 decimals_,address tokenAddress_) external returns(bool);
    function pauseTokenList() external;
    function unpauseTokenList() external;
    function isPausedTokenList() external view returns (bool);
}
interface IComptroller {
    function getAPR(bytes32 commitment_) external view returns (uint);
    function getAPRInd(bytes32 _commitment, uint index) external view returns (uint);
    function getAPY(bytes32 _commitment) external view returns (uint);
    function getAPYInd(bytes32 _commitment, uint _index) external view returns (uint);
    function getApytime(bytes32 _commitment, uint _index) external view returns (uint);
    function getAprtime(bytes32 _commitment, uint _index) external view returns (uint);
    function getApyLastTime(bytes32 commitment_) external view returns (uint);
    function getAprLastTime(bytes32 commitment_) external view returns (uint);
    function getApyTimeLength(bytes32 commitment_) external view returns (uint);
    function getAprTimeLength(bytes32 commitment_) external view returns (uint);
    function getCommitment(uint index_) external view returns (bytes32);
    function setCommitment(bytes32 _commitment) external;
    function liquidationTrigger(uint loanID) external;
    function updateAPY(bytes32 _commitment, uint _apy) external returns (bool);
    function updateAPR(bytes32 _commitment, uint _apr) external returns (bool);
    function calcAPR(bytes32 _commitment, uint oldLengthAccruedInterest, uint oldTime, uint aggregateInterest) external view returns (uint, uint);
    function calcAPY(bytes32 _commitment, uint oldLengthAccruedYield, uint oldTime, uint aggregateYield) external view returns (uint, uint);
    function updateLoanIssuanceFees(uint fees) external returns(bool success);
    function updateLoanClosureFees(uint fees) external returns (bool success);
    function updateLoanPreClosureFees(uint fees) external returns (bool success);
    function updateDepositPreclosureFees(uint fees) external returns(bool success);
    function updateWithdrawalFees(uint fees) external returns(bool success);
    function updateCollateralReleaseFees(uint fees) external returns(bool success);
    function updateYieldConversion(uint fees) external returns (bool success);
    function updateMarketSwapFees(uint fees) external returns (bool success);
    function updateReserveFactor(uint _reserveFactor) external returns (bool success);
    function updateMaxWithdrawal(uint factor, uint blockLimit) external returns (bool success);
    function getReserveFactor() external view returns (uint256);
    function pauseComptroller() external;
    function unpauseComptroller() external;
    function isPausedComptroller() external view returns (bool);
    function depositPreClosureFees() external view returns (uint);
    function depositWithdrawalFees() external view returns (uint);
    function collateralReleaseFees() external view returns (uint);
}
interface ILiquidator {
    function swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 mode) external returns (uint256 receivedAmount);
    function pauseLiquidator() external;
    function unpauseLiquidator() external;
    function isPausedLiquidator() external view returns (bool);
}
interface IDeposit {
  enum SAVINGSTYPE{DEPOSIT, YIELD, BOTH}
  function hasAccount(address account_) external view returns (bool);
    function savingsBalance(bytes32 _market, bytes32 _commitment) external returns (uint);
  function convertYield(bytes32 _market, bytes32 _commitment) external returns (bool success);
  function hasYield(bytes32 _market, bytes32 _commitment) external view returns (bool);
  function avblReservesDeposit(bytes32 _market) external view returns (uint);
  function utilisedReservesDeposit(bytes32 _market) external view returns(uint);
  function hasDeposit(bytes32 _market, bytes32 _commitment) external view returns (bool);
  function createDeposit(bytes32 _market, bytes32 _commitment, uint256 _amount) external returns (bool);
  function withdrawDeposit (bytes32 _market, bytes32 _commitment, uint _amount, SAVINGSTYPE _request) external returns (bool success);
  function addToDeposit(bytes32 _market, bytes32 _commitment, uint _amount) external returns(bool success);
    function getFairPriceDeposit(uint _requestId) external returns (uint);
  function pauseDeposit() external;
  function unpauseDeposit() external;
  function isPausedDeposit() external view returns (bool);
}
interface IReserve {
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
    function avblMarketReserves(bytes32 _market) external view returns (uint);
    function marketReserves(bytes32 _market) external view returns(uint);
    function marketUtilisation(bytes32 _market) external view returns(uint);
    function collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) external returns (bool);
    function pauseReserve() external;
    function unpauseReserve() external;
    function isPausedReserve() external view returns (bool);
}

interface ILoan {
  enum STATE {ACTIVE,REPAID}

    function swapLoan(bytes32 _market, bytes32 _commitment, bytes32 _swapMarket) external returns (bool);
    function swapToLoan(bytes32 _swapMarket, bytes32 _commitment, bytes32 _market ) external returns (bool);
    function withdrawCollateral(bytes32 _market, bytes32 _commitment) external returns (bool);
    function collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) external view returns (bool);
    function repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount) external  returns (bool);
    function getFairPriceLoan(uint _requestId) external returns (uint);
    function pauseLoan() external;
    function unpauseLoan() external;
    function isPausedLoan() external view returns (bool);
}
interface ILoan1 {
  enum STATE {ACTIVE,REPAID}

    function hasLoanAccount(address _account) external view returns (bool);
    function avblReservesLoan(bytes32 _market) external view returns(uint);
    function utilisedReservesLoan(bytes32 _market) external view returns(uint);
    function loanRequest(bytes32 _market, bytes32 _commitment, uint256 _loanAmount, bytes32 _collateralMarket, uint256 _collateralAmount) external returns (bool);
    function addCollateral(bytes32 _market, bytes32 _commitment, bytes32 _collateralMarket, uint256 _collateralAmount) external returns (bool);
    function liquidation(address _account, uint256 id) external returns (bool success);
    function permissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) external returns (bool success);
    function pauseLoan1() external;
    function unpauseLoan1() external;
    function isPausedLoan1() external view returns (bool);
}
interface IOracleOpen {
    function getLatestPrice(bytes32 _market) external returns (uint);
    function getFairPrice(uint _requestId) external returns (uint);
    function liquidationTrigger(address account, uint loanId) external returns (bool);
    function pauseOracle() external;
    function unpauseOracle() external;
    function isPausedOracle() external view returns (bool);
}
interface IAccessRegistry{
    function hasRole(bytes32 role, address account) external view returns (bool);
    function addRole(bytes32 role, address account) external;
    function removeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function transferRole(bytes32 role, address oldAccount, address newAccount) external;
    function hasAdminRole(bytes32 role, address account) external view returns (bool);
    function addAdminRole(bytes32 role, address account) external;
    function removeAdminRole(bytes32 role, address account) external;
    function adminRoleTransfer(bytes32 role, address oldAccount, address newAccount) external;
    function adminRoleRenounce(bytes32 role, address account) external;
    function pauseAccessRegistry() external;
    function unpauseAccessRegistry() external;
    function isPausedAccessRegistry() external view returns (bool);
}
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
interface IAugustusSwapper {
    function simpleSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 expectedAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer,
        bool useReduxToken
    )
        external
        payable
        returns (uint256 receivedAmount);
    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint8 referrer
    )
        external
        payable
        returns (uint256 receivedAmount);
    
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
        uint8 facetId;
    }
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}


library LibDiamond {
    using Address for address;

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.hashstack.diamond.storage");
  uint8 constant TOKENLIST_ID = 10;
  uint8 constant COMPTROLLER_ID = 11;
  // uint8 constant LIQUIDATOR_ID = 12;
  uint8 constant RESERVE_ID = 13;
  // uint8 constant ORACLEOPEN_ID = 14;
  uint8 constant LOAN_ID = 15;
  uint8 constant LOAN1_ID = 16;
  uint8 constant DEPOSIT_ID = 17; 
  uint8 constant ACCESSREGISTRY_ID = 18;
  address internal constant PANCAKESWAP_ROUTER_ADDRESS = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 ; // pancakeswap bsc testnet router address
  address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  bytes32 constant MARKET_USDT = 0x555344542e740000000000000000000000000000000000000000000000000000;
  bytes32 constant MARKET_BUSD = 0x555344542e740000000000000000000000000000000000000000000000000000;
  bytes32 constant MARKET_DAI = 0x555344542e740000000000000000000000000000000000000000000000000000;
  bytes32 constant MARKET_WBNB = 0x555344542e740000000000000000000000000000000000000000000000000000;


    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    uint8 facetId;
    }

// =========== TokenList structs ===========
    struct MarketData {
        bytes32 market;
        address tokenAddress;
        uint256 decimals;
        uint256 chainId;
        uint minAmount;
    }
    
// =========== Comptroller structs ===========
    /// @notice each APY or APR struct holds the recorded changes in interest data & the
  /// corresponding time for a particular commitment type.
    struct APY  {
      bytes32 commitment; 
      uint[] time; // ledger of time when the APY changes were made.
      uint[] apyChanges; // ledger of APY changes.
    }

    struct APR  {
      bytes32 commitment; // validity
      uint[] time; // ledger of time when the APR changes were made.
      uint[] aprChanges; // Per block.timestamp APR is tabulated in here.
    }

// =========== Deposit structs ===========
    struct SavingsAccount {
        uint accOpenTime;
        address account; 
        DepositRecords[] deposits;
        YieldLedger[] yield;
    }

    struct DepositRecords   {
        uint id;
        bytes32 market;
        bytes32 commitment;
        uint amount;
        uint lastUpdate;
    bool isTimelockApplicable; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        uint timelockValidity; // timelock duration
        uint activationTime; // block.timestamp(isTimelockActivated) + timelockValidity.
    }

    struct YieldLedger    {
        uint id;
        bytes32 market; //_market this yield is calculated for
        uint oldLengthAccruedYield; // length of the APY time array.
        uint oldTime; // last recorded block num. This is when this struct is lastly updated.
        uint accruedYield; // accruedYield in 
        bool isTimelockApplicable; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        uint timelockValidity; // timelock duration
        uint activationTime; // block.timestamp(isTimelockActivated) + timelockValidity.
    }
// =========== Loan structs ===========
    struct LoanAccount {
    uint256 accOpenTime;
    address account;
    LoanRecords[] loans; // 2 types of loans. 3 markets intially. So, a maximum o f6 records.
    CollateralRecords[] collaterals;
    DeductibleInterest[] accruedAPR;
    CollateralYield[] accruedAPY;
    LoanState[] loanState;
  }
  struct LoanRecords {
    uint256 id;
    bytes32 market;
    bytes32 commitment;
    uint256 amount;
    bool isSwapped; //true or false. Update when a loan is swapped
    uint256 lastUpdate; // block.timestamp
  }

  struct LoanState {
    uint256 id; // loan.id
    bytes32 loanMarket;
    uint256 actualLoanAmount;
    bytes32 currentMarket;
    uint256 currentAmount;
    ILoan.STATE state;
  }
  struct CollateralRecords {
    uint256 id;
    bytes32 market;
    bytes32 commitment;
    uint256 amount;
    bool isCollateralisedDeposit;
    uint256 timelockValidity;
    bool isTimelockActivated; // timelock duration
    uint256 activationTime; // blocknumber when yield withdrawal request was placed.
  }

  struct CollateralYield {
    uint256 id;
    bytes32 market;
    bytes32 commitment;
    uint256 oldLengthAccruedYield; // length of the APY time array.
    uint256 oldTime; // last recorded block num
    uint256 accruedYield; // accruedYield in
  }

  // DeductibleInterest stores the amount_ of interest deducted.
  struct DeductibleInterest {
    uint256 id; // Id of the loan the interest is being deducted for.
    bytes32 market; // market_ this yield is calculated for
    uint256 oldLengthAccruedInterest; // length of the APY time array.
    uint256 oldTime; // length of the APY time array.
    uint256 accruedInterest;
  }

// =========== OracleOpen structs =============
  struct PriceData {
    bytes32 market;
    uint amount;
    uint price;
  }

// =========== AccessRegistry structs =============
    struct RoleData {
        mapping(address => bool) _members;
        bytes32 _role;
    }

    struct AdminRoleData {
        mapping(address => bool) _adminMembers;
        bytes32 _adminRole;
    }

// =========== Diamond structs ===========
    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        //  Function selectors with the ABI of a contract provide enough information about functions to be useful for user-interface software.
  mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    address[] facetAddresses;
    // address reserveAddress;
        IBEP20 token;

    // ===========  admin addresses ===========
        bytes32 superAdmin;
        // address superAdminAddress;

    // =========== TokenList state variables ===========
        bytes32 adminTokenList;
        address adminTokenListAddress;
        bytes32[] pMarkets; // Primary markets
        bytes32[] sMarkets; // Secondary markets

        mapping (bytes32 => bool) tokenSupportCheck;
        mapping (bytes32=>uint256) marketIndex;
        mapping (bytes32 => MarketData) indMarketData;

        mapping (bytes32 => bool) token2SupportCheck;
        mapping (bytes32=>uint256) market2Index;
        mapping (bytes32 => MarketData) indMarket2Data;

    // =========== Comptroller state variables ===========
        bytes32 adminComptroller;
        address adminComptrollerAddress;        
        bytes32[] commitment; // NONE, TWOWEEKS, ONEMONTH, THREEMONTHS
        uint reserveFactor;
        uint loanIssuanceFees;
        uint loanClosureFees;
        uint loanPreClosureFees;
        uint depositPreClosureFees;
        uint maxWithdrawalFactor;
        uint maxWithdrawalBlockLimit;
        uint depositWithdrawalFees;
        uint collateralReleaseFees;
        uint yieldConversionFees;
        uint marketSwapFees;
        mapping(bytes32 => APY) indAPYRecords;
        mapping(bytes32 => APR) indAPRRecords;

    // =========== Liquidator state variables ===========
        bytes32 adminLiquidator;
        address adminLiquidatorAddress;

    // =========== Deposit state variables ===========
        bytes32 adminDeposit;
        address adminDepositAddress;

        mapping(address => SavingsAccount) savingsPassbook;  // Maps an account to its savings Passbook
        mapping(address => mapping(bytes32 => mapping(bytes32 => DepositRecords))) indDepositRecord; // address =>_market => _commitment => depositRecord
        mapping(address => mapping(bytes32 => mapping(bytes32 => YieldLedger))) indYieldRecord; // address =>_market => _commitment => depositRecord

        //  Balance monitoring  - Deposits
        mapping(bytes32 => uint) marketReservesDeposit; // mapping(market => marketBalance)
        mapping(bytes32 => uint) marketUtilisationDeposit; // mapping(market => marketBalance)

    // =========== OracleOpen state variables ==============
        bytes32 adminOpenOracle;
        address adminOpenOracleAddress;
    mapping(bytes32 => address) pairAddresses;
    PriceData[] prices;
    mapping(uint => PriceData) priceData;
    uint requestEventId;
    // =========== Loan state variables ============
        bytes32 adminLoan;
        address adminLoanAddress;
    bytes32 adminLoan1;
    address adminLoan1Address;
        IBEP20 loanToken;
        IBEP20 collateralToken;
        IBEP20 withdrawToken;

        ILoan.STATE state;

        // STRUCT Mapping
        mapping(address => LoanAccount) loanPassbook;
        mapping(address => mapping(bytes32 => mapping(bytes32 => LoanRecords))) indLoanRecords;
        mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralRecords))) indCollateralRecords;
        mapping(address => mapping(bytes32 => mapping(bytes32 => DeductibleInterest))) indAccruedAPR;
        mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralYield))) indAccruedAPY;
        mapping(address => mapping(bytes32 => mapping(bytes32 => LoanState))) indLoanState;

        //  Balance monitoring  - Loan
        mapping(bytes32 => uint) marketReservesLoan; // mapping(market => marketBalance)
        mapping(bytes32 => uint) marketUtilisationLoan; // mapping(market => marketBalance)

    // =========== Reserve state variables ===========
        bytes32 adminReserve;
        address adminReserveAddress;

    // =========== AccessRegistry state variables ==============
        mapping(bytes32 => RoleData) _roles;
        mapping(bytes32 => AdminRoleData) _adminRoles;
    }
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

// =========== TokenList events ==============
  event MarketSupportAdded(bytes32 indexed _market,uint256 _decimals,address indexed MarketAddress_,uint256 indexed _timestamp);
  event MarketSupportUpdated(bytes32 indexed _market,uint256 _decimals,address indexed MarketAddress_,uint256 indexed _timestamp);
  event MarketSupportRemoved(bytes32 indexed _market, uint256 indexed _timestamp);
  event Market2Added(
    bytes32 indexed _market,
    uint256 _decimals,
    address indexed MarketAddress_,
    uint256 indexed _timestamp
  );
    event Market2Updated(
    bytes32 indexed _market,
        uint256 _decimals,
        address indexed tokenAddress_,
        uint256 indexed _timestamp
    );
    event Market2Removed(bytes32 indexed _market, uint256 indexed _timestamp);

// =========== Comptroller events ================

// =========== Deposit events ===========
  event NewDeposit(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
  event DepositAdded(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
  event YieldDeposited(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
  event Withdrawal(address indexed account, bytes32 indexed market, uint indexed amount, bytes32 commitment, uint timestamp);
  
// =========== Loan events ===============
  /// EVENTS
  event NewLoan(
    address indexed _account,
    bytes32 indexed market,
    uint256 indexed amount,
    bytes32 loanCommitment,
    uint256 timestamp
  );
  event LoanRepaid(
    address indexed _account,
    uint256 indexed id,
    bytes32 indexed market,
    uint256 timestamp
  );
  event WithdrawalProcessed(
    address indexed _account,
    uint256 indexed id,
    uint256 indexed amount,
    bytes32 market,
    uint256 timestamp
  );
  event MarketSwapped(
    address indexed _account,
    uint256 indexed id,
    bytes32 marketFrom,
    bytes32 marketTo,
    uint256 timestamp
  );
  event CollateralReleased(
    address indexed _account,
    uint256 indexed amount,
    bytes32 indexed market,
    uint256 timestamp
  );

  event AddCollateral(
    address indexed _account,
    uint256 indexed id,
    uint256 amount,
    uint256 timestamp
  );

  event Liquidation(
    address indexed _account,
    bytes32 indexed market,
    bytes32 indexed commitment,
    uint256 amount,
    uint256 time
  );

// =========== Liquidator events ===============
// =========== OracleOpen events ===============
  event FairPriceCall(uint requestId, bytes32 market, uint amount);

// =========== AccessRegistry events ===============
    event AdminRoleDataGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event AdminRoleDataRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
// =========== TokenList functions ===========
    
  function _isMarketSupported(bytes32  _market) internal view {
        DiamondStorage storage ds = diamondStorage(); 
    require(ds.tokenSupportCheck[_market] == true, "ERROR: Unsupported market");
  }

    function _addMarketSupport( bytes32 _market,uint256 _decimals,address tokenAddress_, uint _amount) internal authContract(TOKENLIST_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        MarketData storage marketData = ds.indMarketData[_market];
        
        marketData.market = _market;
        marketData.tokenAddress = tokenAddress_;
        marketData.minAmount = _amount*_decimals;
        marketData.decimals = _decimals;
        
        ds.pMarkets.push(_market);
        ds.tokenSupportCheck[_market] = true;
        ds.marketIndex[_market] = ds.pMarkets.length-1;
      emit MarketSupportAdded(_market,_decimals,tokenAddress_,block.timestamp);
    }

    function _removeMarketSupport(bytes32 _market) internal authContract(TOKENLIST_ID) {
        DiamondStorage storage ds = diamondStorage(); 

        ds.tokenSupportCheck[_market] = false;
        delete ds.indMarketData[_market];
        
        if (ds.marketIndex[_market] >= ds.pMarkets.length) return;

        bytes32 lastmarket = ds.pMarkets[ds.pMarkets.length - 1];

        if (ds.marketIndex[lastmarket] != ds.marketIndex[_market]) {
            ds.marketIndex[lastmarket] = ds.marketIndex[_market];
            ds.pMarkets[ds.marketIndex[_market]] = lastmarket;
        }
        ds.pMarkets.pop();
        delete ds.marketIndex[_market];

      emit MarketSupportRemoved(_market, block.timestamp);
    }

    function _updateMarketSupport(
        bytes32 _market,
        uint256 _decimals,
        address tokenAddress_
    ) internal authContract(TOKENLIST_ID) 
    {
        DiamondStorage storage ds = diamondStorage(); 

        MarketData storage marketData = ds.indMarketData[_market];

        marketData.market = _market;
        marketData.tokenAddress = tokenAddress_;
        marketData.decimals = _decimals;

        ds.tokenSupportCheck[_market] = true;
      emit MarketSupportUpdated(_market,_decimals,tokenAddress_,block.timestamp);
    }

  function _getMarketAddress(bytes32 _market) internal view returns (address) {
    DiamondStorage storage ds = diamondStorage(); 
      return ds.indMarketData[_market].tokenAddress;
  }

  function _getMarketDecimal(bytes32 _market) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
      return ds.indMarketData[_market].decimals;
  }

  function _minAmountCheck(bytes32 _market, uint _amount) internal view {
    DiamondStorage storage ds = diamondStorage(); 
    MarketData memory marketData = ds.indMarketData[_market];
    require(marketData.minAmount <= _amount, "ERROR: Less than minimum deposit");
  }

  // function _quantifyAmount(bytes32 _market, uint _amount) internal view returns (uint amount) {
  //  DiamondStorage storage ds = diamondStorage(); 
  //     MarketData memory marketData = ds.indMarketData[_market];
    //  amount = _amount * marketData.decimals;
  // }

    function _isMarket2Supported(bytes32  _market) internal view {
    require(diamondStorage().token2SupportCheck[_market] == true, "Secondary Token is not supported");
  }

  function _getMarket2Address(bytes32 _market) internal view returns (address) {
    DiamondStorage storage ds = diamondStorage(); 
      return ds.indMarket2Data[_market].tokenAddress;
  }

    function _addMarket2Support( bytes32 _market,uint256 _decimals,address tokenAddress_) internal authContract(TOKENLIST_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        MarketData storage marketData = ds.indMarket2Data[_market];
        
        marketData.market = _market;
        marketData.tokenAddress = tokenAddress_;
        marketData.decimals = _decimals;
        
        ds.sMarkets.push(_market);
        ds.token2SupportCheck[_market] = true;
        ds.market2Index[_market] = ds.sMarkets.length-1;
      emit Market2Added(_market,_decimals,tokenAddress_,block.timestamp);
    }

    function _removeMarket2Support(bytes32 _market) internal authContract(TOKENLIST_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        ds.token2SupportCheck[_market] = false;
        delete ds.indMarket2Data[_market];

        if (ds.market2Index[_market] >= ds.sMarkets.length) return;

        bytes32 lastmarket = ds.sMarkets[ds.sMarkets.length - 1];

        if (ds.market2Index[lastmarket] != ds.market2Index[_market]) {
            ds.market2Index[lastmarket] = ds.market2Index[_market];
            ds.sMarkets[ds.market2Index[_market]] = lastmarket;
        }
        ds.sMarkets.pop();
        delete ds.market2Index[_market];
      emit Market2Removed(_market, block.timestamp);
    }

    function _updateMarket2Support(
        bytes32 _market,
        uint256 _decimals,
        address tokenAddress_
    ) internal authContract(TOKENLIST_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        MarketData storage marketData = ds.indMarket2Data[_market];

        marketData.market = _market;
        marketData.tokenAddress = tokenAddress_;
        marketData.decimals = _decimals;

        ds.token2SupportCheck[_market] = true;
      emit Market2Updated(_market,_decimals,tokenAddress_,block.timestamp);
    }

  function _getMarket2Decimal(bytes32 _market) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage();
      return ds.indMarket2Data[_market].decimals;
  }

    function _connectMarket(bytes32 _market) private view returns (address addr) {
        DiamondStorage storage ds = diamondStorage(); 
        MarketData memory marketData = ds.indMarketData[_market];
    addr = marketData.tokenAddress;
    }
  
// =========== Comptroller Functions ===========

  function _getAPR(bytes32 _commitment) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPRRecords[_commitment].aprChanges[ds.indAPRRecords[_commitment].aprChanges.length - 1];
  }

  function _getAPRInd(bytes32 _commitment, uint _index) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPRRecords[_commitment].aprChanges[_index];
  }

  function _getAPY(bytes32 _commitment) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPYRecords[_commitment].apyChanges[ds.indAPYRecords[_commitment].apyChanges.length - 1];
  }

  function _getAPYInd(bytes32 _commitment, uint _index) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPYRecords[_commitment].apyChanges[_index];
  }

  function _getApytime(bytes32 _commitment, uint _index) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPYRecords[_commitment].time[_index];
  }

  function _getAprtime(bytes32 _commitment, uint _index) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPRRecords[_commitment].time[_index];
  }

  function _getApyLastTime(bytes32 _commitment) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPYRecords[_commitment].time[ds.indAPYRecords[_commitment].time.length - 1];
  }

  function _getAprLastTime(bytes32 _commitment) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPRRecords[_commitment].time[ds.indAPRRecords[_commitment].time.length - 1];
  }

  function _getApyTimeLength(bytes32 _commitment) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPYRecords[_commitment].time.length;
  }

  function _getAprTimeLength(bytes32 _commitment) internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.indAPRRecords[_commitment].time.length;
  }

  function _getCommitment(uint _index) internal view returns (bytes32) {
    DiamondStorage storage ds = diamondStorage(); 
    require(_index < ds.commitment.length, "Commitment Index out of range");
    return ds.commitment[_index];
  }

    function _updateApy(bytes32 _commitment, uint _apy) internal authContract(COMPTROLLER_ID) returns (bool) {
        DiamondStorage storage ds = diamondStorage(); 
    APY storage apyUpdate = ds.indAPYRecords[_commitment];

    // if(apyUpdate.time.length != apyUpdate.apyChanges.length) return false;

    apyUpdate.commitment = _commitment;
    apyUpdate.time.push(block.timestamp);
    apyUpdate.apyChanges.push(_apy);
    return true;
  }

  function _setCommitment(bytes32 _commitment) internal authContract(COMPTROLLER_ID) {
    DiamondStorage storage ds = diamondStorage();
    ds.commitment.push(_commitment);
  }
  
  function _updateApr(bytes32 _commitment, uint _apr) internal authContract(COMPTROLLER_ID) returns (bool) {
        DiamondStorage storage ds = diamondStorage();
    APR storage aprUpdate = ds.indAPRRecords[_commitment];

    if(aprUpdate.time.length != aprUpdate.aprChanges.length) return false;

    aprUpdate.commitment = _commitment;
    aprUpdate.time.push(block.timestamp);
    aprUpdate.aprChanges.push(_apr);
    return true;
  }

  function _calcAPR(bytes32 _commitment, uint oldLengthAccruedInterest, uint oldTime, uint aggregateInterest) internal view returns (uint, uint) {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
    
    LibDiamond.APR storage apr = ds.indAPRRecords[_commitment];

    require(oldLengthAccruedInterest > 0, "oldLengthAccruedInterest is 0");

    uint256 index = oldLengthAccruedInterest - 1;
    uint256 time = oldTime;

    // // 1. apr.time.length > oldLengthAccruedInterest => there is some change.

    if (apr.time.length > oldLengthAccruedInterest)  {

      if (apr.time[index] < time) {
        uint256 newIndex = index + 1;
        // Convert the aprChanges to the lowest unit value.
        aggregateInterest = (((apr.time[newIndex] - time) *apr.aprChanges[index])/100)*365/(100*1000);
      
        for (uint256 i = newIndex; i < apr.aprChanges.length; i++) {
          uint256 timeDiff = apr.time[i + 1] - apr.time[i];
          aggregateInterest += (timeDiff*apr.aprChanges[newIndex] / 100)*365/(100*1000);
        }
      }
      else if (apr.time[index] == time) {
        for (uint256 i = index; i < apr.aprChanges.length; i++) {
          uint256 timeDiff = apr.time[i + 1] - apr.time[i];
          aggregateInterest += (timeDiff*apr.aprChanges[index] / 100)*365/(100*1000);
        }
      }
    } else if (apr.time.length == oldLengthAccruedInterest && block.timestamp > oldLengthAccruedInterest) {
      if (apr.time[index] < time || apr.time[index] == time) {
        aggregateInterest += (block.timestamp - time)*apr.aprChanges[index]/100;
        // Convert the aprChanges to the lowest unit value.
        // aggregateYield = (((apr.time[newIndex] - time) *apr.aprChanges[index])/100)*365/(100*1000);
      }
    }
    oldLengthAccruedInterest = apr.time.length;
    oldTime = block.timestamp;
    return (oldLengthAccruedInterest, oldTime);
  }

  function _calcAPY(bytes32 _commitment, uint oldLengthAccruedYield, uint oldTime, uint aggregateYield) internal view returns (uint, uint) {
    DiamondStorage storage ds = diamondStorage(); 
    APY storage apy = ds.indAPYRecords[_commitment];

    require(oldLengthAccruedYield>0, "ERROR : oldLengthAccruedYield < 1");
    
    uint256 index = oldLengthAccruedYield - 1;
    uint256 time = oldTime;

    // 1. apr.time.length > oldLengthAccruedInterest => there is some change.

    if (apy.time.length > oldLengthAccruedYield)  {

      if (apy.time[index] < time) {
        uint256 newIndex = index + 1;
        // Convert the aprChanges to the lowest unit value.
        aggregateYield = (((apy.time[newIndex] - time) *apy.apyChanges[index])/100)*365/(100*1000);
      
        for (uint256 i = newIndex; i < apy.apyChanges.length; i++) {
          uint256 timeDiff = apy.time[i + 1] - apy.time[i];
          aggregateYield += (timeDiff*apy.apyChanges[newIndex] / 100)*365/(100*1000);
        }
      }
      else if (apy.time[index] == time) {
        for (uint256 i = index; i < apy.apyChanges.length; i++) {
          uint256 timeDiff = apy.time[i + 1] - apy.time[i];
          aggregateYield += (timeDiff*apy.apyChanges[index] / 100)*365/(100*1000);
        }
      }
    } else if (apy.time.length == oldLengthAccruedYield && block.timestamp > oldLengthAccruedYield) {
      if (apy.time[index] < time || apy.time[index] == time) {
        aggregateYield += (block.timestamp - time)*apy.apyChanges[index]/100;
        // Convert the aprChanges to the lowest unit value.
        // aggregateYield = (((apr.time[newIndex] - time) *apr.aprChanges[index])/100)*365/(100*1000);
      }
    }
    oldLengthAccruedYield = apy.time.length;
    oldTime = block.timestamp;

    return (oldLengthAccruedYield, oldTime);
  }

  function _getReserveFactor() internal view returns (uint) {
    DiamondStorage storage ds = diamondStorage(); 
    return ds.reserveFactor;
  }
// =========== Liquidator Functions ===========
    function _swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 _mode) internal returns (uint256 receivedAmount) {
        address addrFromMarket;
        address addrToMarket;

        if(_mode == 0){
            addrFromMarket = _getMarketAddress(_fromMarket);
            addrToMarket = _getMarket2Address(_toMarket);
        } else if(_mode == 1) {
            addrFromMarket = _getMarket2Address(_fromMarket);
            addrToMarket = _getMarketAddress(_toMarket);
        } else if(_mode == 2) {
            addrFromMarket = _getMarketAddress(_toMarket);
            addrToMarket = _getMarketAddress(_fromMarket);
        }

    //paraswap
    // address[] memory callee = new address[](2);
    // if(_fromMarket == MARKET_WBNB) callee[0] = WBNB;
    // if(_toMarket == MARKET_WBNB) callee[1] = WBNB;
    // IBEP20(addrFromMarket).approve(0xDb28dc14E5Eb60559844F6f900d23Dce35FcaE33, _fromAmount);
    // receivedAmount = IAugustusSwapper(0x3D0Fc2b7A17d61915bcCA984B9eAA087C5486d18).swapOnUniswap(
    //  _fromAmount, 1,
    //  callee,
    //  1
    // );

    //PancakeSwap
    IBEP20(addrFromMarket).transferFrom(msg.sender, address(this), _fromAmount);
        IBEP20(addrFromMarket).approve(PANCAKESWAP_ROUTER_ADDRESS, _fromAmount);

        address[] memory path;
        if (addrFromMarket == WBNB || addrToMarket == WBNB) {
            path = new address[](2);
            path[0] = addrFromMarket;
            path[1] = addrToMarket;
        } else {
            path = new address[](3);
            path[0] = addrFromMarket;
            path[1] = WBNB;
            path[2] = addrToMarket;
        }

        IPancakeRouter01(PANCAKESWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
            _fromAmount,
            _getAmountOutMin(addrFromMarket, addrToMarket, _fromAmount),
            path,
            address(this),
            block.timestamp
        );
    return receivedAmount;
    }

  function _getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn
    ) private view returns (uint) {
        address[] memory path;
        if (_tokenIn == WBNB || _tokenOut == WBNB) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WBNB;
            path[2] = _tokenOut;
        }

        // same length as path
        uint[] memory amountOutMins = IPancakeRouter01(PANCAKESWAP_ROUTER_ADDRESS).getAmountsOut(
            _amountIn,
            path
        );

        return amountOutMins[path.length - 1];
    }

// =========== Deposit Functions ===========
    function _hasDeposit(address _account, bytes32 _market, bytes32 _commitment) internal view returns(bool ret) {
        DiamondStorage storage ds = diamondStorage();
    ret = ds.indDepositRecord[_account][_market][_commitment].id != 0;
    // require (ds.indDepositRecord[_account][_market][_commitment].id != 0, "ERROR: No deposit");
    // return true;
  }

    function _avblReservesDeposit(bytes32 _market) internal view returns (uint) {
        DiamondStorage storage ds = diamondStorage(); 
        return ds.marketReservesDeposit[_market];
    }

    function _utilisedReservesDeposit(bytes32 _market) internal view returns (uint) {
        DiamondStorage storage ds = diamondStorage(); 
    return ds.marketUtilisationDeposit[_market];
    }

    function _avblReservesLoan(bytes32 _market) internal view returns (uint) {
        DiamondStorage storage ds = diamondStorage(); 
    return ds.marketReservesLoan[_market];
    }

    function _utilisedReservesLoan(bytes32 _market) internal view returns (uint) {
        DiamondStorage storage ds = diamondStorage(); 
    return ds.marketUtilisationLoan[_market];
    }

    function _withdrawDeposit(address _account, bytes32 _market, bytes32 _commitment, uint _amount, IDeposit.SAVINGSTYPE _request) internal authContract(DEPOSIT_ID) {
        DiamondStorage storage ds = diamondStorage(); 
    
    _hasAccount(_account);// checks if user has savings account 
    _isMarketSupported(_market);

    DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];

    // DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
    // YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

    _accruedYield(_account,_market,_commitment);

    uint _savingsBalance = _accountBalance(_account, _market, _commitment, _request);
    require(_amount <= _savingsBalance, "Insufficient balance"); // Dinh modified
    if (_commitment == _getCommitment(0)) {
      _updateSavingsBalance(_account, _market, _commitment, _amount, _request);
    }
    /// Transfer funds to the user's wallet.
    ds.token = IBEP20(_connectMarket(_market));
    ds.token.approveFrom(ds.contractOwner, address(this), _amount);
    ds.token.transferFrom(ds.contractOwner, _account, _amount);

    _updateReservesDeposit(_market, _amount, 1);
    emit Withdrawal(_account,_market, _amount, _commitment, block.timestamp);
  }

    function _accruedYield(address _account,bytes32 _market,bytes32 _commitment) internal authContract(DEPOSIT_ID) {
        DiamondStorage storage ds = diamondStorage(); 
    
    _hasDeposit(_account, _market, _commitment);

    uint256 aggregateYield;

    SavingsAccount storage savingsAccount = ds.savingsPassbook[_account];
    DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];
    YieldLedger storage yield = ds.indYieldRecord[_account][_market][_commitment];

    _calcAPY(_commitment, yield.oldLengthAccruedYield, yield.oldTime, aggregateYield);

    aggregateYield *= deposit.amount;

    yield.accruedYield += aggregateYield;
    savingsAccount.yield[deposit.id-1].accruedYield += aggregateYield;

  }

    function _preDepositProcess(
    bytes32 _market,
    uint256 _amount
    // SavingsAccount memory savingsAccount
  ) private {
      DiamondStorage storage ds = diamondStorage(); 

    _isMarketSupported(_market);
    ds.token = IBEP20(_connectMarket(_market));
    // _quantifyAmount(_market, _amount);
    _minAmountCheck(_market, _amount);
  }

  function _processNewDeposit(
    // address _account,
    bytes32 _market,
    bytes32 _commitment,
    uint256 _amount,
    SavingsAccount storage savingsAccount,
    DepositRecords storage deposit,
    YieldLedger storage yield
  ) internal authContract(DEPOSIT_ID) {
    // SavingsAccount storage savingsAccount = savingsPassbook[_account];
    // DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
    // YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

    uint id;

    if (savingsAccount.deposits.length == 0) {
      id = 1;
    } else {
      id = savingsAccount.deposits.length + 1;
    }

    deposit.id = id;  
    deposit.market =_market;
    deposit.commitment = _commitment;
    deposit.amount = _amount;
    deposit.lastUpdate =  block.timestamp;

    
    if (_commitment != _getCommitment(0)) {
      yield.id = id;
      yield.market = bytes32(_market);
      yield.oldLengthAccruedYield = _getApyTimeLength(_commitment);
      yield.oldTime = block.timestamp;
      yield.accruedYield = 0;
      yield.isTimelockApplicable = true;
      yield.isTimelockActivated=  false;
      yield.timelockValidity = 86400;
      yield.activationTime = 0;
    } else if (_commitment == _getCommitment(0)) {
      yield.id=  id;
      yield.market=_market;
      yield.oldLengthAccruedYield = _getApyTimeLength(_commitment);
      yield.oldTime = block.timestamp;
      yield.accruedYield = 0;
      yield.isTimelockApplicable = false;
      yield.isTimelockActivated=  true;
      yield.timelockValidity = 0;
      yield.activationTime = 0;

    }

    savingsAccount.deposits.push(deposit);
    savingsAccount.yield.push(yield);
  }

  function _processDeposit(
    address _account,
    bytes32 _market,
    bytes32 _commitment,
    uint256 _amount
  ) internal authContract(DEPOSIT_ID) {
        DiamondStorage storage ds = diamondStorage(); 
    SavingsAccount storage savingsAccount = ds.savingsPassbook[_account];
    DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];
    YieldLedger storage yield = ds.indYieldRecord[_account][_market][_commitment];

    uint num = deposit.id - 1;

    _accruedYield(_account, _market, _commitment);
    
    deposit.amount += _amount;
    deposit.lastUpdate =  block.timestamp;


    savingsAccount.deposits[num].amount += _amount;
    savingsAccount.deposits[num].lastUpdate =  block.timestamp;

    savingsAccount.yield[num].oldLengthAccruedYield = yield.oldLengthAccruedYield;
    savingsAccount.yield[num].oldTime = yield.oldTime;
    savingsAccount.yield[num].accruedYield = yield.accruedYield;
  }

  function _hasAccount(address _account) internal view {
        DiamondStorage storage ds = diamondStorage(); 
    require(ds.savingsPassbook[_account].accOpenTime!=0, "ERROR: No savings account");
  }

  function _hasYield(YieldLedger memory yield) internal pure {
    require(yield.id !=0, "ERROR: No Yield");
  }

    function _accountBalance(address _account, bytes32 _market, bytes32 _commitment, IDeposit.SAVINGSTYPE _request) internal authContract(DEPOSIT_ID) returns (uint) {
        DiamondStorage storage ds = diamondStorage(); 

    uint _savingsBalance;
    
    DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];
    YieldLedger storage yield = ds.indYieldRecord[_account][_market][_commitment];

    if (_request == IDeposit.SAVINGSTYPE.DEPOSIT) {
      _savingsBalance = deposit.amount;

    } else if (_request == IDeposit.SAVINGSTYPE.YIELD)  {
      _accruedYield(_account,_market,_commitment);
      _savingsBalance =  yield.accruedYield;

    } else if (_request == IDeposit.SAVINGSTYPE.BOTH) {
      _accruedYield(_account,_market,_commitment);
      _savingsBalance = deposit.amount + yield.accruedYield;
    }
    return _savingsBalance;
  }

  function _updateSavingsBalance(address _account, bytes32 _market, bytes32 _commitment, uint _amount, IDeposit.SAVINGSTYPE _request) internal authContract(DEPOSIT_ID) {
        DiamondStorage storage ds = diamondStorage(); 

    DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];
    YieldLedger storage yield = ds.indYieldRecord[_account][_market][_commitment];

    if (_request == IDeposit.SAVINGSTYPE.DEPOSIT) {
      deposit.amount -= _amount;
      deposit.lastUpdate =  block.timestamp;

    } else if (_request == IDeposit.SAVINGSTYPE.YIELD)  {

      if (yield.isTimelockApplicable == false || block.timestamp >= yield.activationTime+yield.timelockValidity)  {
        
        // _accruedYield(_account,_market,_commitment);
        yield.accruedYield -= _amount;
        yield.oldTime = block.timestamp;
      } else if (yield.isTimelockApplicable != false || block.timestamp < yield.activationTime+yield.timelockValidity)  {
        revert ('Withdrawal can not be processed');
      }

    } else if (_request == IDeposit.SAVINGSTYPE.BOTH) {

      // require (deposit.id == yield.id, "mapping error");

      if (yield.isTimelockApplicable == false || block.timestamp >= yield.activationTime+yield.timelockValidity)  {
        // _accruedYield(_account,_market,_commitment);
        yield.accruedYield -= _amount;
        yield.oldTime = block.timestamp;

      } else if (yield.isTimelockApplicable != false || block.timestamp < yield.activationTime+yield.timelockValidity)  {
        revert ('Withdrawal can not be processed');
      }
      
      deposit.amount -= _amount;
      deposit.lastUpdate =  block.timestamp;
    }
  }

    function _updateReservesDeposit(bytes32 _market, uint _amount, uint _num) internal authContract(DEPOSIT_ID) {
        DiamondStorage storage ds = diamondStorage();
    if (_num == 0)  {
      ds.marketReservesDeposit[_market] += _amount;
    } else if (_num == 1) {
      ds.marketReservesDeposit[_market] -= _amount;
    }
  }

    function _createNewDeposit(bytes32 _market,bytes32 _commitment,uint256 _amount, address _sender) internal authContract(DEPOSIT_ID) {
    DiamondStorage storage ds = diamondStorage(); 

    SavingsAccount storage savingsAccount = ds.savingsPassbook[_sender];
    DepositRecords storage deposit = ds.indDepositRecord[_sender][_market][_commitment];
    YieldLedger storage yield = ds.indYieldRecord[_sender][_market][_commitment];
    
    _preDepositProcess(_market, _amount);
    
    _ensureSavingsAccount(_sender,savingsAccount);
    ds.token.approveFrom(_sender, address(this), _amount);
    ds.token.transferFrom(_sender, ds.contractOwner, _amount);
    
    _processNewDeposit(_market, _commitment, _amount, savingsAccount, deposit, yield);

    uint id;

    if (savingsAccount.deposits.length == 0) {
      id = 1;
    } else {
      id = savingsAccount.deposits.length + 1;
    }
    
    yield.id = id;
    yield.market = _market;

    if (_commitment != _getCommitment(0)) {
      // yield.id = id;
      // yield.market = _market;
      yield.oldLengthAccruedYield = _getApyTimeLength(_commitment);
      yield.oldTime = block.timestamp;
      yield.accruedYield = 0;
      yield.isTimelockApplicable = true;
      yield.isTimelockActivated=  false;
      yield.timelockValidity = 86400;
      yield.activationTime = 0;

    } else if (_commitment == _getCommitment(0)) {
      // yield.id=  id;
      // yield.market=_market;
      yield.oldLengthAccruedYield = _getApyTimeLength(_commitment);
      yield.oldTime = block.timestamp;
      yield.accruedYield = 0;
      yield.isTimelockApplicable = false;
      yield.isTimelockActivated=  true;
      yield.timelockValidity = 0;
      yield.activationTime = 0;
    }

    savingsAccount.deposits.push(deposit);
    savingsAccount.yield.push(yield);
    _updateReservesDeposit(_market, _amount, 0);
    emit NewDeposit(_sender, _market, _commitment, _amount);
  }

  function _addToDeposit(address _sender, bytes32 _market, bytes32 _commitment, uint _amount) internal authContract(DEPOSIT_ID) {
    if (!_hasDeposit(_sender, _market, _commitment))  {
      _createNewDeposit(_market, _commitment, _amount, _sender);
    } 
    
    _processDeposit(_sender, _market, _commitment, _amount);
    _updateReservesDeposit(_market, _amount, 0);

    emit DepositAdded(_sender, _market, _commitment, _amount);
  }

    function _ensureSavingsAccount(address _account, SavingsAccount storage savingsAccount) private {

    if (savingsAccount.accOpenTime == 0) {

      savingsAccount.accOpenTime = block.timestamp;
      savingsAccount.account = _account;
    }
  }

  function _convertYield(address _account, bytes32 _market, bytes32 _commitment, uint _amount) internal authContract(DEPOSIT_ID) {
        DiamondStorage storage ds = diamondStorage(); 

    _hasAccount(_account);

    SavingsAccount storage savingsAccount = ds.savingsPassbook[_account];
    DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];
    YieldLedger storage yield = ds.indYieldRecord[_account][_market][_commitment];

    _hasYield(yield);
    _accruedYield(_account,_market,_commitment);

    _amount = yield.accruedYield;

    // updating yield
    yield.accruedYield = 0;

    deposit.amount += _amount;
    deposit.lastUpdate = block.timestamp;

    savingsAccount.deposits[deposit.id -1].amount += _amount;
    savingsAccount.deposits[deposit.id -1].lastUpdate = block.timestamp;
    savingsAccount.yield[deposit.id-1].accruedYield = 0;
    emit YieldDeposited(_account, _market, _commitment, _amount);
  }

// =========== Loan Functions ===========
    function _updateReservesLoan(bytes32 _market, uint256 _amount, uint256 _num) private {
        DiamondStorage storage ds = diamondStorage(); 
    if (_num == 0)  {
      ds.marketReservesLoan[_market] += _amount;
    } else if (_num == 1) {
      ds.marketReservesLoan[_market] -= _amount;
    }
  }

  function _updateUtilisationLoan(bytes32 _market, uint256 _amount, uint256 _num) private {
        DiamondStorage storage ds = diamondStorage(); 
    if (_num == 0)  {
      ds.marketUtilisationLoan[_market] += _amount;
    } else if (_num == 1) {
      ds.marketUtilisationLoan[_market] -= _amount;
    }
  }

    function _swapToLoan(
      address _account,
    bytes32 _swapMarket,
    bytes32 _commitment,
    bytes32 _market,
    uint256 _swappedAmount
    ) internal authContract(LOAN_ID) returns (bool success)
    {
        return _swapToLoanProcess(_account, _swapMarket, _commitment, _market, _swappedAmount);
    }

    function _swapToLoanProcess(
    address _account,
    bytes32 _swapMarket,
    bytes32 _commitment,
    bytes32 _market,
    uint256 _swappedAmount
  ) private returns (bool success){
        DiamondStorage storage ds = diamondStorage(); 
    _hasLoanAccount(_account);
    
    _isMarketSupported(_market);
    _isMarket2Supported(_swapMarket);

    LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
    LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
    CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];
    CollateralYield storage cYield = ds.indAccruedAPY[_account][_market][_commitment];

    require(loan.id != 0, "ERROR: No loan");
    require(loan.isSwapped == true && loanState.currentMarket == _swapMarket, "ERROR: Swapped market does not exist");
    // require(loan.isSwapped == true, "Swapped market does not exist");

    uint256 num = loan.id - 1;

    _swappedAmount = _swap(_swapMarket,_market,loanState.currentAmount, 1);

    /// Updating LoanRecord
    loan.isSwapped = false;
    loan.lastUpdate = block.timestamp;

    /// updating the LoanState
    loanState.currentMarket = _market;
    loanState.currentAmount = _swappedAmount;

    /// Updating LoanAccount
    ds.loanPassbook[_account].loans[num].isSwapped = false;
    ds.loanPassbook[_account].loans[num].lastUpdate = block.timestamp;
    ds.loanPassbook[_account].loanState[num].currentMarket = _market;
    ds.loanPassbook[_account].loanState[num].currentAmount = _swappedAmount;

    _accruedInterest(_account, _market, _commitment);
    _accruedYield(ds.loanPassbook[_account], collateral, cYield);

    emit MarketSwapped(_account,loan.id,_swapMarket,_market,block.timestamp);
        success = true;
  }

    function _withdrawCollateral(address _account, bytes32 _market, bytes32 _commitment) internal authContract(LOAN_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        LoanAccount storage loanAccount = ds.loanPassbook[_account];
    LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
    LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
    CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];

    _isMarketSupported(_market);
    //Below are checked in _collateralPointer

    // _hasLoanAccount(_account);
    // require(loan.id !=0, "ERROR: No Loan");
    // require(loanState.state == ILoan.STATE.REPAID, "ERROR: Active loan");
    // if (_commitment != _getCommitment(0)) {
    //  require((collateral.timelockValidity + collateral.activationTime) >= block.timestamp, "ERROR: Timelock in progress");
    // }
    _collateralTransfer(_account, loan.market, loan.commitment);

    delete ds.indCollateralRecords[_account][loan.market][loan.commitment];
    delete ds.indLoanState[_account][loan.market][loan.commitment];
    delete ds.indLoanRecords[_account][loan.market][loan.commitment];

    delete loanAccount.loanState[loan.id-1];
    delete loanAccount.loans[loan.id-1];    
    delete loanAccount.collaterals[loan.id-1];
        _updateReservesLoan(collateral.market, collateral.amount, 1);

    emit CollateralReleased(_account, collateral.amount, collateral.market, block.timestamp);
  }

  function _collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) internal view {
    DiamondStorage storage ds = diamondStorage(); 
    
    _hasLoanAccount(_account);

    LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
    LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
    CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];

    //require(loan.id !=0, "ERROR: No Loan");
    require(loanState.state == ILoan.STATE.REPAID, "ERROR: Active loan");
    //if (_commitment != _getCommitment(0)) {
      require((collateral.timelockValidity + collateral.activationTime) >= block.timestamp, "ERROR: Timelock in progress");
    //}   
    collateralMarket = collateral.market;
    collateralAmount = collateral.amount;
  }

    function _accruedYield(LoanAccount storage loanAccount, CollateralRecords storage collateral, CollateralYield storage cYield) private {
    bytes32 _commitment = cYield.commitment;
    uint256 aggregateYield;
    uint256 num = collateral.id-1;
    
    _calcAPY(_commitment, cYield.oldLengthAccruedYield, cYield.oldTime, aggregateYield);

    aggregateYield *= collateral.amount;

    cYield.accruedYield += aggregateYield;
    loanAccount.accruedAPY[num].accruedYield += aggregateYield;
  }

  function _updateDebtRecords(LoanAccount storage loanAccount,LoanRecords storage loan, LoanState storage loanState, CollateralRecords storage collateral/*, DeductibleInterest storage deductibleInterest, CollateralYield storage cYield*/) private {
        DiamondStorage storage ds = diamondStorage(); 
    uint256 num = loan.id - 1;
    bytes32 _market = loan.market;

    loan.amount = 0;
    loan.isSwapped = false;
    loan.lastUpdate = block.timestamp;
    
    loanState.currentMarket = _market;
    loanState.currentAmount = 0;
    loanState.actualLoanAmount = 0;
    loanState.state = ILoan.STATE.REPAID;

    collateral.isCollateralisedDeposit = false;
    collateral.isTimelockActivated = true;
    collateral.activationTime = block.timestamp;

    // delete cYield;
    // delete deductibleInterest;
    delete ds.indAccruedAPY[loanAccount.account][loan.market][loan.commitment];
    delete ds.indAccruedAPR[loanAccount.account][loan.market][loan.commitment];

    // Updating LoanPassbook
    loanAccount.loans[num].amount = 0;
    loanAccount.loans[num].isSwapped = false;
    loanAccount.loans[num].lastUpdate = block.timestamp;

    loanAccount.loanState[num].currentMarket = _market;
    loanAccount.loanState[num].currentAmount = 0;
    loanAccount.loanState[num].actualLoanAmount = 0;
    loanAccount.loanState[num].state = ILoan.STATE.REPAID;
    
    loanAccount.collaterals[num].isCollateralisedDeposit = false;
    loanAccount.collaterals[num].isTimelockActivated = true;
    loanAccount.collaterals[num].activationTime = block.timestamp;

    
    delete loanAccount.accruedAPY[num];
    delete loanAccount.accruedAPR[num];
  }

  function _accruedInterest(address _account, bytes32 _loanMarket, bytes32 _commitment) private /*authContract(LOAN_ID)*/ {
        DiamondStorage storage ds = diamondStorage(); 

    emit FairPriceCall(ds.requestEventId++, _loanMarket, ds.indLoanRecords[_account][_loanMarket][_commitment].amount);
    emit FairPriceCall(ds.requestEventId++, ds.indCollateralRecords[_account][_loanMarket][_commitment].market, ds.indCollateralRecords[_account][_loanMarket][_commitment].amount);

    // LoanAccount storage loanAccount = ds.loanPassbook[_account];
    // LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
    // DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_account][_loanMarket][_commitment];

    require(ds.indLoanState[_account][_loanMarket][_commitment].state == ILoan.STATE.ACTIVE, "ERROR: INACTIVE LOAN");
    require(ds.indAccruedAPR[_account][_loanMarket][_commitment].id != 0, "ERROR: APR does not exist");

    uint256 aggregateYield;
    uint256 deductibleUSDValue;
    uint256 oldLengthAccruedInterest;
    uint256 oldTime;

    (oldLengthAccruedInterest, oldTime) = _calcAPR(
      ds.indLoanRecords[_account][_loanMarket][_commitment].commitment, 
      ds.indAccruedAPR[_account][_loanMarket][_commitment].oldLengthAccruedInterest,
      ds.indAccruedAPR[_account][_loanMarket][_commitment].oldTime, 
      aggregateYield);

    deductibleUSDValue = ((ds.indLoanRecords[_account][_loanMarket][_commitment].amount) * _getFairPrice(ds.requestEventId - 2)) * aggregateYield;
    ds.indAccruedAPR[_account][_loanMarket][_commitment].accruedInterest += deductibleUSDValue / _getFairPrice(ds.requestEventId - 1);
    ds.indAccruedAPR[_account][_loanMarket][_commitment].oldLengthAccruedInterest = oldLengthAccruedInterest;
    ds.indAccruedAPR[_account][_loanMarket][_commitment].oldTime = oldTime;

    ds.loanPassbook[_account].accruedAPR[ds.indLoanRecords[_account][_loanMarket][_commitment].id - 1].accruedInterest = ds.indAccruedAPR[_account][_loanMarket][_commitment].accruedInterest;
    ds.loanPassbook[_account].accruedAPR[ds.indLoanRecords[_account][_loanMarket][_commitment].id - 1].oldLengthAccruedInterest = oldLengthAccruedInterest;
    ds.loanPassbook[_account].accruedAPR[ds.indLoanRecords[_account][_loanMarket][_commitment].id - 1].oldTime = oldTime;
  }

    function _checkPermissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount, address _sender) private /*authContract(LOAN_ID)*/ {

    
        DiamondStorage storage ds = diamondStorage(); 
    // LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
    LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
    CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
    // DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_sender][_market][_commitment];
    emit FairPriceCall(ds.requestEventId++, _collateralMarket, _amount);
    emit FairPriceCall(ds.requestEventId++, _market, _amount);
    emit FairPriceCall(ds.requestEventId++, loanState.currentMarket, loanState.currentAmount);    
    // _quantifyAmount(loanState.currentMarket, _amount);
    require(_amount <= loanState.currentAmount, "ERROR: Exceeds available loan");
    
    _accruedInterest(_sender, _market, _commitment);
    uint256 collateralAvbl = collateral.amount - ds.indAccruedAPR[_sender][_market][_commitment].accruedInterest;

    // fetch usdPrices
    uint256 usdCollateral = _getFairPrice(ds.requestEventId - 3);
    uint256 usdLoan = _getFairPrice(ds.requestEventId - 2);
    uint256 usdLoanCurrent = _getFairPrice(ds.requestEventId - 1);

    // Quantification of the assets
    // uint256 cAmount = usdCollateral*collateral.amount;
    // uint256 cAmountAvbl = usdCollateral*collateralAvbl;

    // uint256 lAmountCurrent = usdLoanCurrent*loanState.currentAmount;
    uint256 permissibleAmount = ((usdCollateral*collateralAvbl - (30*usdCollateral*collateral.amount/100))/usdLoanCurrent);

    require(permissibleAmount > 0, "ERROR: Can not withdraw zero funds");
    require(permissibleAmount > (_amount), "ERROR:Request exceeds funds");
    
    // calcualted in usdterms
    require((usdCollateral*collateralAvbl + usdLoanCurrent*loanState.currentAmount - (_amount*usdLoanCurrent)) >= (11*(usdLoan*ds.indLoanRecords[_sender][_market][_commitment].amount)/10), "ERROR: Risks liquidation");
  }

  function _repaymentProcess(
    address _account,
    uint256 _repayAmount,
    LoanAccount storage loanAccount,
    LoanRecords storage loan,
    LoanState storage loanState,
    CollateralRecords storage collateral,
    DeductibleInterest storage deductibleInterest,
    CollateralYield storage cYield
  ) private {
        DiamondStorage storage ds = diamondStorage(); 
    
    bytes32 _commitment = loan.commitment;
    uint256 num = loan.id - 1;
    
    // convert collateral into loan market to add to the repayAmount
    uint256 collateralAmount = collateral.amount - (deductibleInterest.accruedInterest + cYield.accruedYield);
    _repayAmount += _swap(collateral.market,loan.market,collateralAmount,2);

    // Excess amount is tranferred back to the collateral record
    uint256 _remnantAmount = _repayAmount - loan.amount;
    collateral.amount = _swap(loan.market,collateral.market,_remnantAmount,2);

    /// updating LoanRecords
    loan.amount = 0;
    loan.isSwapped = false;
    loan.lastUpdate = block.timestamp;
    /// updating LoanState
    loanState.actualLoanAmount = 0;
    loanState.currentAmount = 0;
    loanState.state = ILoan.STATE.REPAID;

    delete ds.indAccruedAPR[_account][loan.market][loan.commitment];
    delete ds.indAccruedAPY[_account][loan.market][loan.commitment];

    delete loanAccount.accruedAPR[num];
    delete loanAccount.accruedAPY[num];
    
    emit LoanRepaid(_account, loan.id, loan.market, block.timestamp);

    if (_commitment == _getCommitment(2)) {
      /// updating CollateralRecords
      collateral.isCollateralisedDeposit = false;
      collateral.isTimelockActivated = true;
      collateral.activationTime = block.timestamp;

    } else if (_commitment == _getCommitment(0)) {
      /// transfer collateral.amount from reserve contract to the _sender
      ds.collateralToken = IBEP20(_connectMarket(collateral.market));
      // reserveAddress.transferAnyBEP20(collateralToken, loanAccount.account, collateral.amount);

      /// delete loan Entries, loanRecord, loanstate, collateralrecords
      // delete loanState;
      // delete loan;
      // delete collateral;
      delete ds.indCollateralRecords[_account][loan.market][loan.commitment];
      delete ds.indLoanState[_account][loan.market][loan.commitment];
      delete ds.indLoanRecords[_account][loan.market][loan.commitment];

      delete loanAccount.collaterals[num];
      delete loanAccount.loanState[num];
      delete loanAccount.loans[num];

      _updateReservesLoan(collateral.market, collateral.amount, 1);
      emit CollateralReleased(_account,collateral.amount,collateral.market,block.timestamp);
    }
  }

    function _preLoanRequestProcess(
    bytes32 _market,
    uint256 _loanAmount,
    bytes32 _collateralMarket,
    uint256 _collateralAmount
  ) private {
        DiamondStorage storage ds = diamondStorage(); 
    require(
      _loanAmount != 0 && _collateralAmount != 0,
      "Loan or collateral cannot be zero"
    );

    _permissibleCDR(_market,_collateralMarket,_loanAmount,_collateralAmount);

    // Check for amrket support
    _isMarketSupported(_market);
    _isMarketSupported(_collateralMarket);

    // _quantifyAmount(_market, _loanAmount);
    // _quantifyAmount(_collateralMarket, _collateralAmount);

    // check for minimum permissible amount
    _minAmountCheck(_market, _loanAmount);
    _minAmountCheck(_collateralMarket, _collateralAmount);

    // Connect
    ds.loanToken = IBEP20(_connectMarket(_market));
    ds.collateralToken = IBEP20(_connectMarket(_collateralMarket)); 
  }

  function _processNewLoan(
    address _account,
    bytes32 _market,
    bytes32 _commitment,
    uint256 _loanAmount,
    bytes32 _collateralMarket,
    uint256 _collateralAmount
  ) private {
        DiamondStorage storage ds = diamondStorage();
    // uint256 id;

    LoanAccount storage loanAccount = ds.loanPassbook[_account];
    LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
    LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
    CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];
    DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_account][_market][_commitment];
    CollateralYield storage cYield = ds.indAccruedAPY[_account][_market][_commitment];

    // if (loanAccount.loans.length == 0) {
    //  id = 1;
    // } else if (loanAccount.loans.length != 0) {
      // id = loanAccount.loans.length + 1;
    // }

    
    // Updating loanRecords
    loan.id = loanAccount.loans.length + 1;
    loan.market = _market;
    loan.commitment = _commitment;
    loan.amount = _loanAmount;
    loan.isSwapped = false;
    loan.lastUpdate = block.timestamp;
    
    // Updating deductibleInterest
    deductibleInterest.id = loanAccount.loans.length + 1;
    deductibleInterest.market = _collateralMarket;
    deductibleInterest.oldTime= block.timestamp;
    deductibleInterest.accruedInterest = 0;

    // Updating loanState
    loanState.id = loanAccount.loans.length + 1;
    loanState.loanMarket = _market;
    loanState.actualLoanAmount = _loanAmount;
    loanState.currentMarket = _market;
    loanState.currentAmount = _loanAmount;
    loanState.state = ILoan.STATE.ACTIVE;

    collateral.id= loanAccount.loans.length + 1;
    collateral.market= _collateralMarket;
    collateral.commitment= _commitment;
    collateral.amount = _collateralAmount;

    loanAccount.loans.push(loan);
    loanAccount.loanState.push(loanState);

    if (_commitment == _getCommitment(0)) {
      
      collateral.isCollateralisedDeposit = false;
      collateral.timelockValidity = 0;
      collateral.isTimelockActivated = true;
      collateral.activationTime = 0;

      // pays 18% APR
      deductibleInterest.oldLengthAccruedInterest = _getAprTimeLength(_commitment);

      loanAccount.collaterals.push(collateral);
      loanAccount.accruedAPR.push(deductibleInterest);
      // loanAccount.accruedAPY.push(accruedYield); - no yield because it is
      // a flexible loan
    } else if (_commitment == _getCommitment(2)) {
      
      collateral.isCollateralisedDeposit = true;
      collateral.timelockValidity = 86400;
      collateral.isTimelockActivated = false;
      collateral.activationTime = 0;

      // 15% APR
      deductibleInterest.oldLengthAccruedInterest = _getAprTimeLength(_commitment);
      
      cYield.id = loanAccount.loans.length + 1;
      cYield.market = _collateralMarket;
      cYield.commitment = _getCommitment(1);
      cYield.oldLengthAccruedYield = _getApyTimeLength(_commitment);
      cYield.oldTime = block.timestamp;
      cYield.accruedYield =0;

      loanAccount.collaterals.push(collateral);
      loanAccount.accruedAPY.push(cYield);
      loanAccount.accruedAPR.push(deductibleInterest);
    }
    _updateUtilisationLoan(_market, _loanAmount, 0);
  }

  function _preAddCollateralProcess(
    bytes32 _collateralMarket,
    uint256 _collateralAmount,
    LoanAccount storage loanAccount,
    LoanRecords storage loan,
    LoanState storage loanState,
    CollateralRecords storage collateral
  ) internal view {
    require(loanAccount.accOpenTime != 0, "ERROR: No Loan account");
    require(loan.id != 0, "ERROR: No loan");
    require(loanState.state == ILoan.STATE.ACTIVE, "ERROR: Inactive loan");
    require(collateral.market == _collateralMarket, "ERROR: Mismatch collateral market");

    _isMarketSupported(_collateralMarket);
    _minAmountCheck(_collateralMarket, _collateralAmount);
  }

  function _ensureLoanAccount(address _account) private {
        DiamondStorage storage ds = diamondStorage();
    LoanAccount storage loanAccount = ds.loanPassbook[_account];
    if (loanAccount.accOpenTime == 0) {
      loanAccount.accOpenTime = block.timestamp;
      loanAccount.account = _account;
    }
  }

  function _permissibleCDR (
        bytes32 _market,
        bytes32 _collateralMarket,
        uint256 _loanAmount,
        uint256 _collateralAmount
    ) internal {
        DiamondStorage storage ds = diamondStorage();

    emit FairPriceCall(ds.requestEventId++, _market, _loanAmount);
    emit FairPriceCall(ds.requestEventId++, _collateralMarket, _collateralAmount);

        uint256 loanByCollateral;
        uint256 amount = _avblMarketReserves(_market) - _loanAmount ;
        uint rF = _getReserveFactor()* _marketReserves(_market);

        uint256 usdLoan = (_getFairPrice(ds.requestEventId - 2)) * _loanAmount;
        uint256 usdCollateral = (_getFairPrice(ds.requestEventId - 1)) * _collateralAmount;

        require(amount > 0, "ERROR: Loan exceeds reserves");
        require(_marketReserves(_market) - amount >= rF, "ERROR: Minimum reserve exeception");
        require (usdLoan/usdCollateral <=3, "ERROR: Exceeds permissible CDR");

        // calculating cdrPermissible.
        if (_marketReserves(_market) - amount >= 3*_marketReserves(_market)/4)    {
            loanByCollateral = 3;
        } else     {
            loanByCollateral = 2;
        }
        require (usdLoan/usdCollateral <= loanByCollateral, "ERROR: Exceeds permissible CDR");
    }

    function _addCollateral(
        bytes32 _market,
    bytes32 _commitment,
    bytes32 _collateralMarket,
    uint256 _collateralAmount,
    address _sender
    ) internal authContract(LOAN1_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        LoanAccount storage loanAccount = ds.loanPassbook[_sender];
    LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
    LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
    CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
    CollateralYield storage cYield = ds.indAccruedAPY[_sender][_market][_commitment];

    _preAddCollateralProcess(_collateralMarket, _collateralAmount, loanAccount, loan,loanState, collateral);

    ds.collateralToken = IBEP20(_connectMarket(_collateralMarket));
    // _quantifyAmount(_collateralMarket, _collateralAmount);
    ds.collateralToken.approveFrom(_sender, address(this), _collateralAmount);
    ds.collateralToken.transferFrom(_sender, ds.contractOwner, _collateralAmount);
    _updateReservesLoan(_collateralMarket, _collateralAmount, 0);
    
    _addCollateralAmount(loanAccount, collateral, _collateralAmount, loan.id-1);
    _accruedInterest(_sender, _market, _commitment);

    if (collateral.isCollateralisedDeposit) _accruedYield(loanAccount, collateral, cYield);

    emit AddCollateral(_sender, loan.id, _collateralAmount, block.timestamp);
    }

  function _addCollateralAmount(
    LoanAccount storage loanAccount,
    CollateralRecords storage collateral,
    uint256 _collateralAmount,
    uint256 num
  ) private {
    collateral.amount += _collateralAmount;
    loanAccount.collaterals[num].amount = _collateralAmount;
  }

    function _swapLoan(
    address _sender,
        bytes32 _market,
    bytes32 _commitment,
    bytes32 _swapMarket
    ) internal authContract(LOAN_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        _hasLoanAccount(_sender);
    
    _isMarketSupported(_market);
    _isMarket2Supported(_swapMarket);

    LoanAccount storage loanAccount = ds.loanPassbook[_sender];
    LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
    LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
    CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
    CollateralYield storage cYield = ds.indAccruedAPY[_sender][_market][_commitment];

    require(loan.id != 0, "ERROR: No loan");
    require(loan.isSwapped == false && loanState.currentMarket == _market, "ERROR: Already swapped");

    uint256 _swappedAmount;
    uint256 num = loan.id - 1;

    _swappedAmount = _swap(_market, _swapMarket, loan.amount, 0);

    /// Updating LoanRecord
    loan.isSwapped = true;
    loan.lastUpdate = block.timestamp;
    /// Updating LoanState
    loanState.currentMarket = _swapMarket;
    loanState.currentAmount = _swappedAmount;

    /// Updating LoanAccount
    loanAccount.loans[num].isSwapped = true;
    loanAccount.loans[num].lastUpdate = block.timestamp;
    loanAccount.loanState[num].currentMarket = _swapMarket;
    loanAccount.loanState[num].currentAmount = _swappedAmount;

    _accruedInterest(_sender, _market, _commitment);
    if (collateral.isCollateralisedDeposit) _accruedYield(loanAccount, collateral, cYield);

    emit MarketSwapped(_sender,loan.id,_market,_swapMarket, block.timestamp);
    }

  

    function _loanRequest(
        bytes32 _market,
    bytes32 _commitment,
    uint256 _loanAmount,
    bytes32 _collateralMarket,
    uint256 _collateralAmount,
    address _sender
    ) internal authContract(LOAN1_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        _preLoanRequestProcess(_market,_loanAmount,_collateralMarket,_collateralAmount);

    // LoanAccount storage loanAccount = ds.loanPassbook[_sender];
    LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];

    require(loan.id == 0, "ERROR: Active loan");

    ds.collateralToken.approveFrom(_sender, address(this), _collateralAmount);
    ds.collateralToken.transferFrom(_sender, ds.contractOwner, _collateralAmount);
    _updateReservesLoan(_collateralMarket,_collateralAmount, 0);
    _ensureLoanAccount(_sender);

    _processNewLoan(_sender,_market,_commitment,_loanAmount,_collateralMarket,_collateralAmount);

    emit NewLoan(_sender, _market, _loanAmount, _commitment, block.timestamp);
    }

    function _repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount, address _sender) internal authContract(LOAN_ID) {
        // DiamondStorage storage ds = diamondStorage(); 
        _hasLoanAccount(_sender);
    // LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
    // LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
    // CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
    // DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_sender][_market][_commitment];
    // CollateralYield storage cYield = ds.indAccruedAPY[_sender][_market][_commitment];    
    
    require(diamondStorage().indLoanRecords[_sender][_market][_commitment].id != 0,"ERROR: No Loan");
    
    _accruedInterest(_sender, _market, _commitment);
    _accruedYield(diamondStorage().loanPassbook[_sender], diamondStorage().indCollateralRecords[_sender][_market][_commitment], diamondStorage().indAccruedAPY[_sender][_market][_commitment]);

    if (_repayAmount == 0) {
      // converting the current market into loanMarket for repayment.
      if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket == _market)  _repayAmount = diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount;
      else if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket != _market) _repayAmount = _swap(diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket, _market,diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount, 1);
      
      _repaymentProcess(
        _sender,
        _repayAmount, 
        diamondStorage().loanPassbook[_sender],
        diamondStorage().indLoanRecords[_sender][_market][_commitment],
        diamondStorage().indLoanState[_sender][_market][_commitment],
        diamondStorage().indCollateralRecords[_sender][_market][_commitment],
        diamondStorage().indAccruedAPR[_sender][_market][_commitment], 
        diamondStorage().indAccruedAPY[_sender][_market][_commitment]);
      
      // if (loanState.currentMarket == _market) {
      //  _repayAmount = loanState.currentAmount;
      //  _repaymentProcess(_sender,_repayAmount,loanPassbook[_sender],loan,loanState,collateral,deductibleInterest,cYield);
        
      // } else if (loanState.currentMarket != _market) {
      //  _repayAmount = liquidator.swap(loanState.currentMarket,_market,loanState.currentAmount, 1);
      //  _repaymentProcess(_sender,_repayAmount,loanPassbook[_sender],loan,loanState,collateral,deductibleInterest,cYield);
      // }
    }
    else if (_repayAmount > 0) {
      /// transfering the repayAmount to the reserve contract.
      diamondStorage().loanToken = IBEP20(_connectMarket(_market));
      // _quantifyAmount(_market, _repayAmount);

      diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount += (diamondStorage().indAccruedAPY[_sender][_market][_commitment].accruedYield - diamondStorage().indAccruedAPR[_sender][_market][_commitment].accruedInterest);
      
      uint256 _swappedAmount;
      uint256 _remnantAmount;

      if (_repayAmount >= diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {
        _remnantAmount = _repayAmount - diamondStorage().indLoanRecords[_sender][_market][_commitment].amount;

        if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket == _market){
          _remnantAmount += diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount;
        }
        else {
          _swapToLoanProcess(_sender, diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket, _commitment, _market, _swappedAmount);
          _repayAmount += _swappedAmount;
        }

        _updateDebtRecords(diamondStorage().loanPassbook[_sender],diamondStorage().indLoanRecords[_sender][_market][_commitment],diamondStorage().indLoanState[_sender][_market][_commitment],diamondStorage().indCollateralRecords[_sender][_market][_commitment]/*, deductibleInterest, cYield*/);
        diamondStorage().loanToken.approveFrom(diamondStorage().contractOwner, address(this), _remnantAmount);
        diamondStorage().loanToken.transferFrom(diamondStorage().contractOwner, diamondStorage().loanPassbook[_sender].account, _remnantAmount);

        emit LoanRepaid(_sender, diamondStorage().indLoanRecords[_sender][_market][_commitment].id, diamondStorage().indLoanRecords[_sender][_market][_commitment].market, block.timestamp);
        
        if (_commitment == _getCommitment(0)) {
          /// transfer collateral.amount from reserve contract to the _sender
          // collateralToken = IBEP20(markets.connectMarket(collateral.market));
          _transferAnyBEP20(_connectMarket(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market), _sender, diamondStorage().loanPassbook[_sender].account,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount);

      /// delete loan Entries, loanRecord, loanstate, collateralrecords
          // delete loanState;
          // delete loan;
          // delete collateral;

          delete diamondStorage().indLoanRecords[_sender][_market][_commitment];
          delete diamondStorage().indLoanState[_sender][_market][_commitment];
          delete diamondStorage().indCollateralRecords[_sender][_market][_commitment];


          delete diamondStorage().loanPassbook[_sender].loanState[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
          delete diamondStorage().loanPassbook[_sender].loans[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
          delete diamondStorage().loanPassbook[_sender].collaterals[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
          
          _updateReservesLoan(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market, diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount, 1);
          emit CollateralReleased(_sender,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount,diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,block.timestamp);
        }
      } else if (_repayAmount < diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {

        if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket == _market)  _repayAmount += diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount;
        else if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket != _market) {
          _swapToLoanProcess(_sender, diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket, _commitment, _market, _swappedAmount);
          _repayAmount += _swappedAmount;
        }
        
        if (_repayAmount > diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {
          _remnantAmount = _repayAmount - diamondStorage().indLoanRecords[_sender][_market][_commitment].amount;
          diamondStorage().loanToken.approveFrom(diamondStorage().contractOwner, address(this), _remnantAmount);
          diamondStorage().loanToken.transferFrom(diamondStorage().contractOwner, diamondStorage().loanPassbook[_sender].account, _remnantAmount);
        } else if (_repayAmount <= diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {
          
          _repayAmount += _swap(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,_market,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount, 1);
          // _repayAmount += _swapToLoanProcess(loanState.currentMarket, _commitment, _market);
          _remnantAmount = _repayAmount - diamondStorage().indLoanRecords[_sender][_market][_commitment].amount;
          diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount += _swap(diamondStorage().indLoanRecords[_sender][_market][_commitment].market,diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,_remnantAmount, 2);
        }
        _updateDebtRecords(diamondStorage().loanPassbook[_sender],diamondStorage().indLoanRecords[_sender][_market][_commitment],diamondStorage().indLoanState[_sender][_market][_commitment],diamondStorage().indCollateralRecords[_sender][_market][_commitment]/*, deductibleInterest, cYield*/);
        
        if (_commitment == _getCommitment(0)) {
          
          // collateralToken = IBEP20(markets.connectMarket(collateral.market));
          _transferAnyBEP20(_connectMarket(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market), _sender, diamondStorage().loanPassbook[_sender].account, diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount);


        /// delete loan Entries, loanRecord, loanstate, collateralrecords
          // delete loanState;
          // delete loan;
          // delete collateral;
          delete diamondStorage().indLoanRecords[_sender][_market][_commitment];
          delete diamondStorage().indLoanState[_sender][_market][_commitment];
          delete diamondStorage().indCollateralRecords[_sender][_market][_commitment];

          delete diamondStorage().loanPassbook[_sender].loanState[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
          delete diamondStorage().loanPassbook[_sender].loans[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
          delete diamondStorage().loanPassbook[_sender].collaterals[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
          
          _updateReservesLoan(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market, diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount, 1);
          emit CollateralReleased(_sender,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount,diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,block.timestamp);
        }
      }
    }
    
    _updateUtilisationLoan(diamondStorage().indLoanRecords[_sender][_market][_commitment].market, diamondStorage().indLoanRecords[_sender][_market][_commitment].amount, 1);
    }

    function _hasLoanAccount(address _account) internal view returns (bool) {
        DiamondStorage storage ds = diamondStorage(); 
        require(ds.loanPassbook[_account].accOpenTime !=0, "ERROR: No Loan Account");
    return true;
    }

    function _permissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount, address _sender) internal authContract(LOAN1_ID) returns (bool success) {
        DiamondStorage storage ds = diamondStorage(); 
        _hasLoanAccount(_sender);

    LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
    LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
    
    _checkPermissibleWithdrawal(_market, _commitment, _collateralMarket, _amount, _sender);
    
    ds.withdrawToken = IBEP20(_connectMarket(loanState.currentMarket));
    ds.withdrawToken.transfer(_sender,_amount);

    emit WithdrawalProcessed(_sender, loan.id, _amount, loanState.currentMarket, block.timestamp);

    success = true;
    }

    function _liquidation(address _account, uint256 _id) internal authContract(LOAN1_ID){
        DiamondStorage storage ds = diamondStorage(); 
        bytes32 _commitment = ds.loanPassbook[_account].loans[_id-1].commitment;
    bytes32 _market = ds.loanPassbook[_account].loans[_id-1].market;

    LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
    LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
    CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];
    DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_account][_market][_commitment];
    // CollateralYield storage cYield = ds.indAccruedAPY[_account][_market][_commitment];

    emit FairPriceCall(ds.requestEventId++, collateral.market, collateral.amount);
    emit FairPriceCall(ds.requestEventId++, loanState.currentMarket, loanState.currentAmount);

    require(loan.id == _id, "ERROR: id mismatch");

    _accruedInterest(_account, _market, _commitment);
    
    if (loan.commitment == _getCommitment(2))
      collateral.amount += ds.indAccruedAPY[_account][_market][_commitment].accruedYield - deductibleInterest.accruedInterest;
    else if (loan.commitment == _getCommitment(2))
      collateral.amount -= deductibleInterest.accruedInterest;

    delete ds.indAccruedAPY[_account][_market][_commitment];
    delete ds.indAccruedAPR[_account][_market][_commitment];
    delete ds.loanPassbook[_account].accruedAPR[loan.id - 1];
    delete ds.loanPassbook[_account].accruedAPY[loan.id - 1];

    // Convert to USD.
    uint256 cAmount = _getFairPrice(ds.requestEventId - 2) * collateral.amount;
    uint256 lAmountCurrent = _getFairPrice(ds.requestEventId - 1) * loanState.currentAmount;
    // convert collateral & loanCurrent into loanActual
    uint256 _repaymentAmount = _swap(collateral.market, loan.market, cAmount, 2);
    _repaymentAmount += _swap(loanState.currentMarket, loan.market, lAmountCurrent, 1);
    uint256 _remnantAmount = _repaymentAmount - lAmountCurrent;

    delete ds.indLoanState[_account][_market][_commitment];
    delete ds.indLoanRecords[_account][_market][_commitment];
    delete ds.indCollateralRecords[_account][_market][_commitment];

    delete ds.loanPassbook[_account].loanState[_id - 1];
    delete ds.loanPassbook[_account].loans[_id - 1];
    delete ds.loanPassbook[_account].collaterals[_id - 1];
    _updateUtilisationLoan(loan.market, loan.amount, 1);

    emit LoanRepaid(_account, _id, loan.market, block.timestamp);
    emit Liquidation(_account,_market, _commitment, loan.amount, block.timestamp);
    
    }

// =========== Reserve Functions =====================
  function _collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) internal authContract(RESERVE_ID) {
        DiamondStorage storage ds = diamondStorage(); 

    bytes32 collateralMarket;
        uint collateralAmount;

    _collateralPointer(_account,_market,_commitment, collateralMarket, collateralAmount);
    ds.token = IBEP20(_connectMarket(collateralMarket));
    ds.token.approveFrom(ds.contractOwner, address(this), collateralAmount);
        ds.token.transferFrom(ds.contractOwner, _account, collateralAmount);
  }

  function _transferAnyBEP20(address _token, address _sender, address _recipient, uint256 _value) internal authContract(RESERVE_ID) {
    IBEP20(_token).approveFrom(_sender, address(this), _value);
        IBEP20(_token).transferFrom(_sender, _recipient, _value);
  }

  function _avblMarketReserves(bytes32 _market) internal view returns (uint) {
        require((_marketReserves(_market) - _marketUtilisation(_market)) >=0, "Mathematical error");
        return _marketReserves(_market) - _marketUtilisation(_market);
    }

  function _marketReserves(bytes32 _market) internal view returns (uint) {
        return _avblReservesDeposit(_market) + _avblReservesLoan(_market);
  }

  function _marketUtilisation(bytes32 _market) internal view returns (uint) {
    return _utilisedReservesDeposit(_market) + _utilisedReservesLoan(_market);
  }

// =========== OracleOpen Functions =================
  function _getLatestPrice(bytes32 _market) internal view returns (uint) {
        DiamondStorage storage ds = diamondStorage();
    ( , int price, , , ) = AggregatorV3Interface(ds.pairAddresses[_market]).latestRoundData();
        return uint256(price);
  }

  function _getFairPrice(uint _requestId) internal view returns (uint retPrice) {
    DiamondStorage storage ds = diamondStorage();
    require(ds.priceData[_requestId].price != 0, "No fetched price");
    retPrice = ds.priceData[_requestId].price;
  }

  function _fairPrice(uint _requestId, uint _fPrice, bytes32 _market, uint _amount) internal {
    DiamondStorage storage ds = diamondStorage();
    PriceData storage newPrice = ds.priceData[_requestId];
    newPrice.market = _market;
    newPrice.amount = _amount;
    newPrice.price = _fPrice;
  }

// =========== AccessRegistry Functions =================
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        DiamondStorage storage ds = diamondStorage(); 
        return ds._roles[role]._members[account];
    }

    function _addRole(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        ds._roles[role]._members[account] = true;
        emit RoleGranted(role, account, msg.sender);
    }
    
    function _revokeRole(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        ds._roles[role]._members[account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    function _hasAdminRole(bytes32 role, address account) internal view returns (bool) {
        DiamondStorage storage ds = diamondStorage(); 
        return ds._adminRoles[role]._adminMembers[account];
    }

    function _addAdminRole(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        ds._adminRoles[role]._adminMembers[account] = true;
        emit AdminRoleDataGranted(role, account, msg.sender);
    }

    function _revokeAdmin(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
        DiamondStorage storage ds = diamondStorage(); 
        ds._adminRoles[role]._adminMembers[account] = false;
        emit AdminRoleDataRevoked(role, account, msg.sender);
    }

// =========== Diamond Functions ===========
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
    ds.superAdmin = keccak256("AccessRegistry.admin");
    _addAdminRole(keccak256("AccessRegistry.admin"), _newOwner);
        emit OwnershipTransferred(previousOwner, _newOwner);

    //BSC testnet pair addresses.
    ds.pairAddresses[MARKET_USDT] = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684; // USDT.t ~ decimal 8, not 18
    ds.pairAddresses[MARKET_BUSD] = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // BUSD
    ds.pairAddresses[MARKET_DAI] = 0x8a9424745056Eb399FD19a0EC26A14316684e274; // DAI
    ds.pairAddresses[MARKET_WBNB] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // BNB.t
    }


  function addFacetAddress(address _address) internal {
        DiamondStorage storage ds = diamondStorage();
    ds.facetAddresses.push(_address);
  }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors, _diamondCut[facetIndex].facetId);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors, _diamondCut[facetIndex].facetId);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors, uint8 _facetId) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount, _facetId);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors, uint8 _facetId) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
            ds.facetAddressAndSelectorPosition[selector].facetId = _facetId;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

  modifier authContract(uint _facetId) {
    // console.log("_facetId is ", _facetId);
    // console.log("diamond fId is", LibDiamond.diamondStorage().facetAddressAndSelectorPosition[msg.sig].facetId);
    require(_facetId == LibDiamond.diamondStorage().facetAddressAndSelectorPosition[msg.sig].facetId || 
        LibDiamond.diamondStorage().facetAddressAndSelectorPosition[msg.sig].facetId == 0, "Not permitted");
    _;
  }
}


contract Loan is Pausable, ILoan {
  
  constructor() {
      // LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
    // ds.adminLoanAddress = msg.sender;
    // ds.loan = ILoan(msg.sender);
  }

  // receive() external payable {
    //  LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
  //   payable(ds.contractOwner).transfer(_msgValue());
  // }
  
  // fallback() external payable {
    //  LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
  //  payable(ds.contractOwner).transfer(_msgValue());
  // }

  // External view functions

  /// Swap loan to a secondary market.
  function swapLoan(
    bytes32 _market,
    bytes32 _commitment,
    bytes32 _swapMarket
  ) external override nonReentrant() returns (bool) {
    LibDiamond._swapLoan(msg.sender, _market, _commitment, _swapMarket);
    return true;
  }

/// SwapToLoan
  function swapToLoan(
    bytes32 _swapMarket,
    bytes32 _commitment,
    bytes32 _market
  ) external override nonReentrant() returns (bool) {
    uint256 _swappedAmount;
    LibDiamond._swapToLoan(msg.sender, _swapMarket,_commitment, _market, _swappedAmount);
    return true;
  }

  function withdrawCollateral(bytes32 _market, bytes32 _commitment) external override returns (bool) {
    LibDiamond._withdrawCollateral(msg.sender, _market, _commitment);
    return true;
  }

  function repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount) external override returns (bool success) {
    LibDiamond._repayLoan(_market, _commitment, _repayAmount, msg.sender);
    return true;
  }

    function getFairPriceLoan(uint _requestId) external override returns (uint price){
    price = LibDiamond._getFairPrice(_requestId);
  }


  function collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) external view override returns (bool) {
      LibDiamond._collateralPointer(_account, _market, _commitment, collateralMarket, collateralAmount);
    return true;
  }

  function pauseLoan() external override authLoan() nonReentrant() {
    _pause();
  }
  
  function unpauseLoan() external override authLoan() nonReentrant() {
    _unpause();   
  }

  function isPausedLoan() external view virtual override returns (bool) {
    return _paused();
  }

  modifier authLoan() {
      LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    require(
      msg.sender == ds.contractOwner || msg.sender == ds.adminLoanAddress,
      "ERROR: Require Admin access"
    );
    _;
  }
}