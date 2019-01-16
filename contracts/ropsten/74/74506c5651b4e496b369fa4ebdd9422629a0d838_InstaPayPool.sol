pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    function PermissionGroups() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[]) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[]) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(newAdmin);
        AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE);

        AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;

        for (uint i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE);

        OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;

        for (uint i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                OperatorAdded(operator, false);
                break;
            }
        }
    }
}

/**
 * @title Contracts that should be able to recover tokens or ethers
 * @author Ilan Doron
 * @dev This allows to recover any tokens or Ethers received in a contract.
 * This will prevent any accidental loss of tokens.
 */
contract Withdrawable is PermissionGroups {

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all ERC20 compatible tokens
     * @param token ERC20 The address of the token contract
     */
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        EtherWithdraw(amount, sendTo);
    }
}



/// @title Kyber constants contract
contract Utils {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint  constant internal PRECISION = (10**18);
    uint  constant internal MAX_QTY   = (10**28); // 10B tokens
    uint  constant internal MAX_RATE  = (PRECISION * 10**6); // up to 1M tokens per ETH
    uint  constant internal MAX_DECIMALS = 18;
    uint  constant internal ETH_DECIMALS = 18;
    mapping(address=>uint) internal decimals;

    function setDecimals(ERC20 token) internal {
        if (token == ETH_TOKEN_ADDRESS) decimals[token] = ETH_DECIMALS;
        else decimals[token] = token.decimals();
    }

    function getDecimals(ERC20 token) internal view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint tokenDecimals = decimals[token];
        // technically, there might be token with decimals 0
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if(tokenDecimals == 0) return token.decimals();

        return tokenDecimals;
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(srcQty <= MAX_QTY);
        require(rate <= MAX_RATE);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(dstQty <= MAX_QTY);
        require(rate <= MAX_RATE);

        //source quantity is rounded up. to avoid dest quantity being too low.
        uint numerator;
        uint denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }
}


contract Utils2 is Utils {

    /// @dev get the balance of a user.
    /// @param token The token type
    /// @return The balance
    function getBalance(ERC20 token, address user) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return user.balance;
        else
            return token.balanceOf(user);
    }

    function getDecimalsSafe(ERC20 token) internal returns(uint) {

        if (decimals[token] == 0) {
            setDecimals(token);
        }

        return decimals[token];
    }

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal view returns(uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns(uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
    }
}


/// @title Kyber Network interface
interface KyberNetworkInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(address trader, ERC20 src, uint srcAmount, ERC20 dest, address destAddress,
        uint maxDestAmount, uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}

/// @title Kyber Network interface
interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}


/// @title simple interface for Kyber Network
interface SimpleNetworkInterface {
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) public returns(uint);
    function swapEtherToToken(ERC20 token, uint minConversionRate) public payable returns(uint);
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) public returns(uint);
}



////////////////////////////////////////////////////////////////////////////////////////////////////////
/// @title Kyber Network proxy for main contract
contract KyberNetworkProxy is KyberNetworkProxyInterface, SimpleNetworkInterface, Withdrawable, Utils2 {

    KyberNetworkInterface public kyberNetworkContract;

    function KyberNetworkProxy(address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest   Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @param walletId is the wallet ID to send part of the fees
    /// @return amount of actual dest tokens
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint)
    {
        bytes memory hint;

        return tradeWithHint(
            src,
            srcAmount,
            dest,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );
    }

    /// @dev makes a trade between src and dest token and send dest tokens to msg sender
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest Destination token
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @return amount of actual dest tokens
    function swapTokenToToken(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        uint minConversionRate
    )
        public
        returns(uint)
    {
        bytes memory hint;

        return tradeWithHint(
            src,
            srcAmount,
            dest,
            msg.sender,
            MAX_QTY,
            minConversionRate,
            0,
            hint
        );
    }

    /// @dev makes a trade from Ether to token. Sends token to msg sender
    /// @param token Destination token
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @return amount of actual dest tokens
    function swapEtherToToken(ERC20 token, uint minConversionRate) public payable returns(uint) {
        bytes memory hint;

        return tradeWithHint(
            ETH_TOKEN_ADDRESS,
            msg.value,
            token,
            msg.sender,
            MAX_QTY,
            minConversionRate,
            0,
            hint
        );
    }

    /// @dev makes a trade from token to Ether, sends Ether to msg sender
    /// @param token Src token
    /// @param srcAmount amount of src tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @return amount of actual dest tokens
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) public returns(uint) {
        bytes memory hint;

        return tradeWithHint(
            token,
            srcAmount,
            ETH_TOKEN_ADDRESS,
            msg.sender,
            MAX_QTY,
            minConversionRate,
            0,
            hint
        );
    }

    struct UserBalance {
        uint srcBalance;
        uint destBalance;
    }

    event ExecuteTrade(address indexed trader, ERC20 src, ERC20 dest, uint actualSrcAmount, uint actualDestAmount);

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @param walletId is the wallet ID to send part of the fees
    /// @param hint will give hints for the trade.
    /// @return amount of actual dest tokens
    function tradeWithHint(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId,
        bytes hint
    )
        public
        payable
        returns(uint)
    {
        require(src == ETH_TOKEN_ADDRESS || msg.value == 0);

        UserBalance memory userBalanceBefore;

        userBalanceBefore.srcBalance = getBalance(src, msg.sender);
        userBalanceBefore.destBalance = getBalance(dest, destAddress);

        if (src == ETH_TOKEN_ADDRESS) {
            userBalanceBefore.srcBalance += msg.value;
        } else {
            require(src.transferFrom(msg.sender, kyberNetworkContract, srcAmount));
        }

        uint reportedDestAmount = kyberNetworkContract.tradeWithHint.value(msg.value)(
            msg.sender,
            src,
            srcAmount,
            dest,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );

        TradeOutcome memory tradeOutcome = calculateTradeOutcome(
            userBalanceBefore.srcBalance,
            userBalanceBefore.destBalance,
            src,
            dest,
            destAddress
        );

        require(reportedDestAmount == tradeOutcome.userDeltaDestAmount);
        require(tradeOutcome.userDeltaDestAmount <= maxDestAmount);
        require(tradeOutcome.actualRate >= minConversionRate);

        ExecuteTrade(msg.sender, src, dest, tradeOutcome.userDeltaSrcAmount, tradeOutcome.userDeltaDestAmount);
        return tradeOutcome.userDeltaDestAmount;
    }

    event KyberNetworkSet(address newNetworkContract, address oldNetworkContract);

    function setKyberNetworkContract(KyberNetworkInterface _kyberNetworkContract) public onlyAdmin {

        require(_kyberNetworkContract != address(0));

        KyberNetworkSet(_kyberNetworkContract, kyberNetworkContract);

        kyberNetworkContract = _kyberNetworkContract;
    }

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty)
        public view
        returns(uint expectedRate, uint slippageRate)
    {
        return kyberNetworkContract.getExpectedRate(src, dest, srcQty);
    }

    function getUserCapInWei(address user) public view returns(uint) {
        return kyberNetworkContract.getUserCapInWei(user);
    }

    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint) {
        return kyberNetworkContract.getUserCapInTokenWei(user, token);
    }

    function maxGasPrice() public view returns(uint) {
        return kyberNetworkContract.maxGasPrice();
    }

    function enabled() public view returns(bool) {
        return kyberNetworkContract.enabled();
    }

    function info(bytes32 field) public view returns(uint) {
        return kyberNetworkContract.info(field);
    }

    struct TradeOutcome {
        uint userDeltaSrcAmount;
        uint userDeltaDestAmount;
        uint actualRate;
    }

    function calculateTradeOutcome (uint srcBalanceBefore, uint destBalanceBefore, ERC20 src, ERC20 dest,
        address destAddress)
        internal returns(TradeOutcome outcome)
    {
        uint userSrcBalanceAfter;
        uint userDestBalanceAfter;

        userSrcBalanceAfter = getBalance(src, msg.sender);
        userDestBalanceAfter = getBalance(dest, destAddress);

        //protect from underflow
        require(userDestBalanceAfter > destBalanceBefore);
        require(srcBalanceBefore > userSrcBalanceAfter);

        outcome.userDeltaDestAmount = userDestBalanceAfter - destBalanceBefore;
        outcome.userDeltaSrcAmount = srcBalanceBefore - userSrcBalanceAfter;

        outcome.actualRate = calcRateFromQty(
                outcome.userDeltaSrcAmount,
                outcome.userDeltaDestAmount,
                getDecimalsSafe(src),
                getDecimalsSafe(dest)
            );
    }
}



/// @title InstaPay On Chain Reserve Pool Contract
/// @dev 1) Fund contract with ETH, convert everything to DAI. Borrow and repay in DAI.
///      2) Faciliate reserve pool functions: transfer in/out, threshold warning
///         and loan repay.
///      3) Transactions should be tracked on chain. Due to lack of daemon
///         support in this version, it is tracked by mapping for now.
///      TODO: remove mapping when daemon is implemented
contract InstaPayPool is Ownable {
    // Kyber Network Setup
    KyberNetworkProxy public proxy = KyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    ERC20 DAI = ERC20(0xaD6D458402F60fD3Bd25163575031ACDce07538D);
    ERC20 ETH = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // Dummy ETH token address for Kyber

    uint public DECIMALS = 18;                              // Both DAI & ETH uses 18 decimals
    uint public MAX_DAI_AMOUNT = 100000 * 10 ** DECIMALS;   // Maximum amount of DAI from ETH
    uint public OUTSTANDING_LOAN_AMOUNT = 0;                // in DAI
    uint public THRESHOLD = 10 * 10 ** DECIMALS;            // 10 DAI
    uint public RELOAD_AMOUNT = 5 * 10 ** DECIMALS;         //  5 DAI
    bool public BELOW_THRESHOLD = false;                    // initiate loan order if below
    bool public UNDER_FUNDED = false;                       // pool < outstanding loans

    mapping(address => uint) public balances;

    event logThresholdUpdated(uint _oldThreshold, uint _threshold);
    event logReloadAmountUpdated(uint _oldAmount, uint _amount);

    event warnBelowThreshold(uint _threshold, uint _balance);
    event warnUnderFunded(uint _loanBalance, uint _balance);

    event logLoanFulfilled(address _borrower, uint _amount);
    event logLoanFailed(address _borrower, uint _amount);
    event logLoanRepaid(address _borrower, uint _amount);

    event logSwapped(address _src, uint _srcAmount, address _dest, uint _destAmount);
    event logSwapFailed(address _src, uint _srcAmount, address _dest);

    event logFundReceived(address _sender, uint _amount);

    // @dev fall back function
    function () external payable {
        revert();
    }

    // @dev accept ETH funding
    function fund() external payable {
        emit logFundReceived(msg.sender, msg.value);
    }

    // @dev Convert all ETH to DAI
    function stablize() public onlyOwner returns(bool success) {
        uint srcQty = address(this).balance;    // Convert all ETH to DAI
        require(
            srcQty > 0,
            "Nothing to stablize"
        );
        uint maxDestAmount = MAX_DAI_AMOUNT;
        uint minConversionRate;
        uint newTokenCount;
        address walletId = address(0);  // not using this param
        (minConversionRate,) = proxy.getExpectedRate(ETH, DAI, srcQty);
        newTokenCount = proxy.trade.value(srcQty)(
            ETH,
            srcQty,
            DAI,
            address(this),
            maxDestAmount,
            minConversionRate,
            walletId
        );
        if (newTokenCount > 0) {
            _checkThreshold();
            _checkLoanBalance();
            emit logSwapped(ETH, srcQty, DAI, newTokenCount);
            success = true;   
        } else {
            emit logSwapFailed(ETH, srcQty, DAI);
        }
    }

    // @dev Transfer _amount to _borrower wallet, update mapping the loan amount
    // @param _borrower wallet address of the borrower
    // @param _amount in DAI (USD), with 18 decimals
    function loan(address _borrower, uint _amount) public onlyOwner returns(bool success) {
        require(
            _amount > 0 && _amount <= DAI.balanceOf(address(this)),
            "Invalid amount."
        );
        success = DAI.transfer(_borrower, _amount);

        if (success) {
            // Bookkeeping
            OUTSTANDING_LOAN_AMOUNT += _amount;
            balances[_borrower] = balances[_borrower] + _amount;
            _checkThreshold();
            _checkLoanBalance();
            emit logLoanFulfilled(_borrower, _amount);
        } else {
            emit logLoanFailed(_borrower, _amount);
        }
    }

    // @dev Need to call DAI.transfer, upon success, trigger a call to this function
    // @param _borrower wallet address of the borrower
    // @param _amount in DAI (USD), with 18 decimals
    function repay(address _borrower, uint _amount) public onlyOwner {
        require(
            _amount > 0 && _amount <= balances[_borrower],
            "Invalid amount"
        );
        OUTSTANDING_LOAN_AMOUNT -= _amount;
        balances[_borrower] = balances[_borrower] - _amount;
        _checkThreshold();
        _checkLoanBalance();
    }

    /* Internal functions: Fund status checks */
    function _checkThreshold() internal {
        if (DAI.balanceOf(address(this)) < THRESHOLD) {
            BELOW_THRESHOLD = true;
            emit warnBelowThreshold(THRESHOLD, address(this).balance);
        } else {
            BELOW_THRESHOLD = false;
        }
    }

    function _checkLoanBalance() internal {
        if (DAI.balanceOf(address(this)) < OUTSTANDING_LOAN_AMOUNT) {
            UNDER_FUNDED = true;
            emit warnUnderFunded(OUTSTANDING_LOAN_AMOUNT, DAI.balanceOf(address(this)));
        } else {
            UNDER_FUNDED = false;
        }
    }

    /* Admin functions below */
    function updateThreshold(uint _threshold) external onlyOwner {
        uint oldThreshold = THRESHOLD;
        THRESHOLD = _threshold;
        emit logThresholdUpdated(oldThreshold, _threshold);
    }

    function updateReloadAmount(uint _amount) external onlyOwner {
        uint oldAmount = RELOAD_AMOUNT;
        RELOAD_AMOUNT = _amount;
        emit logReloadAmountUpdated(oldAmount, _amount);
    }

    /* Withdraw ETH balance */
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    /* Withdraw DAI balance */
    function withdrawDai() external onlyOwner returns(bool success) {
        success = DAI.transfer(owner, DAI.balanceOf(address(this)));
    }
}