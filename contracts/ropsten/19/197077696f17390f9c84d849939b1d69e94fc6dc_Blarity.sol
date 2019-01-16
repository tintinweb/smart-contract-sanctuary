pragma solidity 0.4.18;

pragma solidity 0.4.18;

// File: contracts/ERC20Interface.sol

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

// File: contracts/KyberNetworkInterface.sol

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

// File: contracts/KyberNetworkProxyInterface.sol

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

// File: contracts/SimpleNetworkInterface.sol

/// @title simple interface for Kyber Network 
interface SimpleNetworkInterface {
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) public returns(uint);
    function swapEtherToToken(ERC20 token, uint minConversionRate) public payable returns(uint);
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) public returns(uint);
}

// File: contracts/Utils.sol

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

// File: contracts/Utils2.sol

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

// File: contracts/PermissionGroups.sol

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

// File: contracts/Withdrawable.sol

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

// File: contracts/KyberNetworkProxy.sol

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

contract Blarity {
  ERC20 constant internal ACCEPT_DAI_ADDRESS = ERC20(0x00ad6d458402f60fd3bd25163575031acdce07538d);
  // ropsten: ERC20(0x00ad6d458402f60fd3bd25163575031acdce07538d);
  // mainnet: ERC20(0x0089d24a6b4ccb1b6faa2625fe562bdd9a23260359);
  // owner address
  address public owner;
  // campaign creator address
  struct CampaignCreator {
    address addr;
    // maximum amount to receive from smart contract
    uint amount;
    // is requested to get money from SC
    bool isRequested;
  }
  // start and end time
  uint public startTime;
  uint public endTime;
  // accepted token
  ERC20 public acceptedToken;
  uint public targetedMoney;
  bool public isReverted = false;

  struct Supplier {
    address addr;
    // maximum amount to receive from smart contract
    uint amount;
    // requested amount to get money from SC
    bool isRequested;
    bool isOwnerApproved;
    bool isCreatorApproved;
  }

  struct Donator {
    address addr;
    uint amount;
  }

  CampaignCreator campaignCreator;
  Supplier[] suppliers;
  Donator[] donators;

  // Withdraw funds
  event EtherWithdraw(uint amount, address sendTo);
  /**
   * @dev Withdraw Ethers
   */
  function withdrawEther(uint amount, address sendTo) public onlyOwner {
    sendTo.transfer(amount);
    EtherWithdraw(amount, sendTo);
  }

  event TokenWithdraw(ERC20 token, uint amount, address sendTo);
  /**
   * @dev Withdraw all ERC20 compatible tokens
   * @param token ERC20 The address of the token contract
   */
  function withdrawToken(ERC20 token, uint amount, address sendTo) public onlyOwner {
    require(token != acceptedToken);
    token.transfer(sendTo, amount);
    TokenWithdraw(token, amount, sendTo);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyCampaignCreator() {
    require(msg.sender == campaignCreator.addr);
    _;
  }

  // Transfer ownership
  event TransferOwner(address newOwner);
  function transferOwner(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    TransferOwner(newOwner);
  }

  // Transfer camp creator
  event TransferCampaignCreator(address newCampCreator);
  function transferCampaignCreator(address newCampCreator) public onlyCampaignCreator {
    require(newCampCreator != address(0));
    campaignCreator = CampaignCreator({
      addr: newCampCreator,
      amount: campaignCreator.amount,
      isRequested: campaignCreator.isRequested
    });
    TransferOwner(newCampCreator);
  }

  function Blarity(
    address _campCreator,
    uint _campAmount,
    uint _endTime,
    uint _targetMoney,
    address[] supplierAddresses,
    uint[] supplierAmounts
  ) public {
    require(_campCreator != address(0));
    require(_targetMoney > 0);
    require(_endTime > now);
    require(supplierAddresses.length == supplierAmounts.length);
    owner = msg.sender;
    campaignCreator = CampaignCreator({addr: _campCreator, amount: _campAmount, isRequested: false});
    endTime = _endTime;
    acceptedToken = ACCEPT_DAI_ADDRESS;
    targetedMoney = _targetMoney;
    isReverted = false;
    for(uint i = 0; i < supplierAddresses.length; i++) {
      require(supplierAddresses[i] != address(0));
      require(supplierAmounts[i] > 0);
      Supplier memory sup = Supplier({
        addr: supplierAddresses[i],
        amount: supplierAmounts[i],
        isRequested: false,
        isOwnerApproved: false,
        isCreatorApproved: false
      });
      suppliers.push(sup);
    }
  }

  event AddNewSupplier(address _address, uint _amount);
  event ReplaceSupplier(address _address, uint _amount);
  // Add new supplier if not exist, replace current one if exit
  function addNewSupplier(address _address, uint _amount) public onlyOwner {
    require(now < endTime); // must not be ended
    require(_address != address(0));
    require(_amount > 0);
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == _address) {
        if (suppliers[i].amount == _amount) { return; }
        suppliers[i].amount = _amount;
        suppliers[i].isRequested = false;
        suppliers[i].isCreatorApproved = false;
        suppliers[i].isOwnerApproved = false;
        ReplaceSupplier(_address, _amount);
        return;
      }
    }
    Supplier memory sup = Supplier({
      addr: _address,
      amount: _amount,
      isRequested: false,
      isCreatorApproved: false,
      isOwnerApproved: false
    });
    suppliers.push(sup);
    AddNewSupplier(_address, _amount);
  }

  event RemoveSupplier(address _address);
  function removeSupplier(address _address) public onlyOwner {
    require(now < endTime); // must not be ended
    require(_address != address(0));
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == _address) {
        suppliers[i] = suppliers[suppliers.length - 1];
        // delete suppliers[suppliers.length - 1];
        suppliers.length--;
        RemoveSupplier(_address);
      }
    }
  }

  function updateTargetedMoney(uint _money) public onlyOwner {
    require(now < endTime); // must not be ended
    targetedMoney = _money;
  }

  function updateEndTime(uint _endTime) public onlyOwner {
    endTime = _endTime;
  }

  function updateIsReverted(bool _isReverted) public onlyOwner {
    isReverted = _isReverted;
  }

  event UpdateIsReverted(bool isReverted);
  function updateIsRevertedEndTimeReached() public onlyOwner {
    require(now >= endTime);
    require(isReverted == false);
    if (ACCEPT_DAI_ADDRESS.balanceOf(address(this)) < targetedMoney) {
      isReverted = true;
      UpdateIsReverted(true);
    }
  }

  event SupplierFundTransferRequested(address addr, uint amount);
  function requestTransferFundToSupplier() public {
    require(now >= endTime); // must be ended
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == msg.sender) {
        require(suppliers[i].amount > 0);
        require(suppliers[i].isRequested == false);
        require(ACCEPT_DAI_ADDRESS.balanceOf(address(this)) >= suppliers[i].amount);
        suppliers[i].isRequested = true;
        SupplierFundTransferRequested(msg.sender, suppliers[i].amount);
      }
    }
  }

  event ApproveSupplierFundTransferRequested(address addr, uint amount);
  event FundTransferredToSupplier(address supplier, uint amount);
  // Approve fund transfer to supplier from both campaign creator and owner
  function approveFundTransferToSupplier(address _supplier) public {
    require(now >= endTime); // must be ended
    require(msg.sender == owner || msg.sender == campaignCreator.addr);
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == _supplier) {
        require(suppliers[i].amount > 0);
        require(ACCEPT_DAI_ADDRESS.balanceOf(address(this)) >= suppliers[i].amount);
        if (msg.sender == owner) {
          suppliers[i].isOwnerApproved = true;
        } else {
          suppliers[i].isCreatorApproved = true;
        }
        if (suppliers[i].isOwnerApproved && suppliers[i].isCreatorApproved) {
          // both approved, start transferring
          if (ACCEPT_DAI_ADDRESS.transferFrom(address(this), _supplier, suppliers[i].amount)) {
            suppliers[i].amount = 0;
            FundTransferredToSupplier(msg.sender, suppliers[i].amount);
          }
        } else {
          ApproveSupplierFundTransferRequested(msg.sender, suppliers[i].amount);
        }
      }
    }
  }

  event CreatorRequestFundTransfer(address _address, uint _amount);
  function creatorRequestFundTransfer() public onlyCampaignCreator {
    require(now >= endTime); // must be ended
    require(campaignCreator.amount > 0);
    campaignCreator.isRequested = true;
    CreatorRequestFundTransfer(msg.sender, campaignCreator.amount);
  }

  event FundTransferToCreator(address _from, address _to, uint _amount);
  function approveAndTransferFundToCreator() public onlyOwner {
    require(now >= endTime); // must be ended
    require(campaignCreator.amount > 0);
    require(campaignCreator.isRequested);
    if (ACCEPT_DAI_ADDRESS.transferFrom(address(this), campaignCreator.addr, campaignCreator.amount)) {
      campaignCreator.amount = 0;
      FundTransferToCreator(msg.sender, campaignCreator.addr, campaignCreator.amount);
    }
  }
  event Donated(address _address, uint _amount);
  function donateDAI(uint amount) public {
    require(amount > 0);
    require(now < endTime);
    require(ACCEPT_DAI_ADDRESS.balanceOf(msg.sender) >= amount);
    if (ACCEPT_DAI_ADDRESS.transferFrom(msg.sender, address(this), amount)) {
      for(uint i = 0; i < donators.length; i++) {
        if (donators[i].addr == msg.sender) {
          donators[i].amount += amount;
          Donated(msg.sender, amount);
          return;
        }
      }
      donators.push(Donator({addr: msg.sender, amount: amount}));
      Donated(msg.sender, amount);
    }
  }
 
  function donateToken(KyberNetworkProxy network, ERC20 src, uint srcAmount, uint maxDestAmount, uint minConversionRate, address walletId) public {
    uint amount = network.trade(src, srcAmount, ACCEPT_DAI_ADDRESS, address(this), maxDestAmount, minConversionRate, walletId);
    for(uint i = 0; i < donators.length; i++) {
      if (donators[i].addr == msg.sender) {
        donators[i].amount += amount;
        Donated(msg.sender, amount);
        return;
      }
    }
    donators.push(Donator({addr: msg.sender, amount: amount}));
  }

  event Refunded(address _address, uint _amount);
  function requestRefundDonator() public {
    require(isReverted == true); // only refund if it is reverted
    for(uint i = 0; i < donators.length; i++) {
      if (donators[i].addr == msg.sender) {
        require(donators[i].amount > 0);
        uint amount = donators[i].amount;
        if (ACCEPT_DAI_ADDRESS.transfer(msg.sender, amount)) {
          donators[i].amount = 0;
          Refunded(msg.sender, amount);
          return;
        }
      }
    }
  }

  function getCampaignCreator() public view returns (address _address, uint _amount) {
    return (campaignCreator.addr, campaignCreator.amount);
  }

  function getNumberSuppliers() public view returns (uint numberSuppliers) {
    numberSuppliers = suppliers.length;
    return numberSuppliers;
  }

  function getSuppliers()
  public view returns (address[] memory addresses, uint[] memory amounts, bool[] isRequested, bool[] isOwnerApproved, bool[] isCreatorApproved) {
    addresses = new address[](suppliers.length);
    amounts = new uint[](suppliers.length);
    isRequested = new bool[](suppliers.length);
    isOwnerApproved = new bool[](suppliers.length);
    isCreatorApproved = new bool[](suppliers.length);
    for(uint i = 0; i < suppliers.length; i++) {
      addresses[i] = suppliers[i].addr;
      amounts[i] = suppliers[i].amount;
      isRequested[i] = suppliers[i].isRequested;
      isOwnerApproved[i] = suppliers[i].isOwnerApproved;
      isCreatorApproved[i] = suppliers[i].isCreatorApproved;
    }
    return (addresses, amounts, isRequested, isOwnerApproved, isCreatorApproved);
  }

  function getSupplier(address _addr)
  public view returns (address _address, uint amount, bool isRequested, bool isOwnerApproved, bool isCreatorApproved) {
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == _addr) {
        return (_addr, suppliers[i].amount, suppliers[i].isRequested, suppliers[i].isOwnerApproved, suppliers[i].isCreatorApproved);
      }
    }
  }

  function getNumberDonators() public view returns (uint numberDonators) {
    numberDonators = donators.length;
    return numberDonators;
  }

  function getDonators() public view returns (address[] addresses, uint[] amounts) {
    addresses = new address[](donators.length);
    amounts = new uint[](donators.length);
    for(uint i = 0; i < donators.length; i++) {
      addresses[i] = donators[i].addr;
      amounts[i] = donators[i].amount;
    }
    return (addresses, amounts);
  }

  function getDonator(address _addr) public view returns (address _address, uint _amount) {
    for(uint i = 0; i < donators.length; i++) {
      if (donators[i].addr == _addr) {
        return (_addr, donators[i].amount);
      }
    }
  }

  function getDAIBalance() public view returns (uint balance) {
    return ACCEPT_DAI_ADDRESS.balanceOf(address(this));
  }
}