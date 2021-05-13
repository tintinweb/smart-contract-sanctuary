/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^0.4.24;

interface ITetherERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public;
    function transferFrom(address _from, address _to, uint _value) public;
    function approve(address _spender, uint _value) public;
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint8 digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances; // Storage slot 0

  uint256 totalSupply_; // Storage slot 1

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
* @title Standard ERC20 token
*
* @dev Implementation of the basic standard token.
* https://github.com/ethereum/EIPs/issues/20
* Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
*/
contract StandardToken is ERC20, BasicToken {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) internal allowed; // Storage slot 2

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract StandardTokenMintableBurnable is StandardToken {
  using SafeMath for uint256;

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");
    totalSupply_ = totalSupply_.add(amount);
    balances[account] = balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) public {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from the zero address");
    totalSupply_ = totalSupply_.sub(amount);
    balances[account] = balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
}

contract WhiteListToken is StandardTokenMintableBurnable{
  address public whiteListAdmin;
  bool public isTransferRestricted;
  bool public isReceiveRestricted;
  mapping(address => bool) public transferWhiteList;
  mapping(address => bool) public receiveWhiteList;


  constructor(address _admin) public {
    whiteListAdmin = _admin;
    isReceiveRestricted = true;
  }

  modifier isWhiteListAdmin() {
      require(msg.sender == whiteListAdmin);
      _;
  }

  function transfer(address _to, uint256 _value) public returns (bool){
    if (isTransferRestricted) {
      require(transferWhiteList[msg.sender], "only whitelist senders can transfer tokens");
    }
    if (isReceiveRestricted) {
      require(receiveWhiteList[_to], "only whiteList receivers can receive tokens");
    }
    return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
    if (isTransferRestricted) {
      require(transferWhiteList[_from], "only whiteList senders can transfer tokens");
    }
    if (isReceiveRestricted) {
      require(receiveWhiteList[_to], "only whiteList receivers can receive tokens");
    }
    return super.transferFrom(_from, _to, _value);
  }

  function enableTransfer() isWhiteListAdmin public {
    require(isTransferRestricted);
    isTransferRestricted = false;
  }

  function restrictTransfer() isWhiteListAdmin public {
    require(isTransferRestricted == false);
    isTransferRestricted = true;
  }

  function enableReceive() isWhiteListAdmin public {
    require(isReceiveRestricted);
    isReceiveRestricted = false;
  }

  function restrictReceive() isWhiteListAdmin public {
    require(isReceiveRestricted == false);
    isReceiveRestricted = true;
  }


  function removeTransferWhiteListAddress(address _whiteListAddress) public isWhiteListAdmin returns(bool) {
    require(transferWhiteList[_whiteListAddress]);
    transferWhiteList[_whiteListAddress] = false;
    return true;
  }

  function addTransferWhiteListAddress(address _whiteListAddress) public isWhiteListAdmin returns(bool) {
    require(transferWhiteList[_whiteListAddress] == false);
    transferWhiteList[_whiteListAddress] = true;
    return true;
  }

  function removeReceiveWhiteListAddress(address _whiteListAddress) public isWhiteListAdmin returns(bool) {
    require(receiveWhiteList[_whiteListAddress]);
    receiveWhiteList[_whiteListAddress] = false;
    return true;
  }

  function addReceiveWhiteListAddress(address _whiteListAddress) public isWhiteListAdmin returns(bool) {
    require(receiveWhiteList[_whiteListAddress] == false);
    receiveWhiteList[_whiteListAddress] = true;
    return true;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SimpleOracleAccruedRatioUSD {
    using SafeMath for uint256;
    address public admin;
    address public superAdmin;
    uint256 public accruedRatioUSD;
    uint256 public lastUpdateTime;
    uint256 public MAXIMUM_CHANGE_PCT = 3;

    constructor(uint256 _accruedRatioUSD, address _admin, address _superAdmin) public {
        admin = _admin;
        superAdmin = _superAdmin;
        accruedRatioUSD = _accruedRatioUSD;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == superAdmin);
        _;
    }

    modifier onlySuperAdmin {
        require(msg.sender == superAdmin);
        _;
    }

    function isValidRatio(uint256 _accruedRatioUSD) view internal {
      require(_accruedRatioUSD >= accruedRatioUSD, "ratio should be monotonically increased");
      uint256 maximumChange = accruedRatioUSD.mul(MAXIMUM_CHANGE_PCT).div(100);
      require(_accruedRatioUSD.sub(accruedRatioUSD) < maximumChange, "exceeds maximum chagne");
    }

    function checkTimeStamp() view internal {
      // 82800 = 23 * 60 * 60  (23 hours)
      require(block.timestamp.sub(lastUpdateTime) > 82800, "oracle are not allowed to update two times within 23 hours");
    }

    function set(uint256 _accruedRatioUSD) onlyAdmin public{
        if(msg.sender != superAdmin) {
          isValidRatio(_accruedRatioUSD);
          checkTimeStamp();
        }
        lastUpdateTime = block.timestamp;
        accruedRatioUSD = _accruedRatioUSD;
    }

    function query() external view returns(uint256)  {
        // QueryEvent(msg.sender, block.number);
        return accruedRatioUSD;
    }
}

interface CERC20 {
    function mint(uint mintAmount) returns (uint);
    function redeem(uint redeemTokens) returns (uint);
    function supplyRatePerBlock() returns (uint);
    function exchangeRateCurrent() returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function balanceOfUnderlying(address account) returns (uint);
}

interface CEther {
    function mint() payable;
    function redeem(uint redeemTokens) returns (uint);
    function supplyRatePerBlock() returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function balanceOfUnderlying(address account) returns (uint);
}

contract CoolBitETFUSDTAndCompound is WhiteListToken{
    using SafeMath for uint256;

    uint256 public baseRatio;
    string public name = "X-Saving Certificate";
    string public constant symbol = "XSCert";
    uint8 public decimals;

    // USDT token contract
    ITetherERC20 public StableToken;
    SimpleOracleAccruedRatioUSD public oracle;
    // Defi contract
    CERC20 public cToken;

    // Roles
    address public bincentiveHot; // i.e., Platform Owner
    address public bincentiveCold;
    address[] public investors;
    mapping(address => bool) public isInInvestorList;

    uint256 public numAUMDistributedInvestors; // i.e., number of investors that already received AUM

    // Contract(Fund) Status
    // 0: not initialized
    // 1: initialized
    // 2: not enough fund came in in time
    // 3: fundStarted
    // 4: running
    // 5: stoppped
    // 6: closed
    // 7: suspended
    uint256 public fundStatus;

    // Money
    mapping(address => uint256) public investorDepositUSDTAmount;  // denominated in stable token
    uint256 public currentInvestedAmount;  // denominated in stable token

    // Fund Parameters
    uint256 public investPaymentDueTime;  // deadline for deposit which comes in before fund starts running
    uint256 public percentageOffchainFund;  // percentage of fund that will be transfered off-chain
    uint256 public percentageMinimumFund;  // minimum percentage of fund required to keep the fund functioning
    uint256 public minimumFund;  // minimum amounf required to keep the fund functioning
    uint256 public minPenalty;  // a minimum 100 USDT penalty

    // Events
    event Deposit(address indexed investor, uint256 investAmount, uint256 mintedAmount);
    event UserInfo(bytes32 indexed uuid, string referralCode);
    event StartFund(uint256 timeStamp, uint256 num_investors, uint256 totalInvestedAmount, uint256 totalMintedTokenAmount);
    event Withdraw(address indexed investor, uint256 tokenAmount, uint256 USDTAmount, uint256 ToBincentiveColdUSDTAmount);
    event MidwayQuit(address indexed investor, uint256 tokenAmount, uint256 USDTAmount);
    event ReturnAUM(uint256 StableTokenAmount);
    event DistributeAUM(address indexed to, uint256 tokenAmount, uint256 StableTokenAmount);
    // Admin Events
    event NewBincentiveCold(address newBincentiveCold);
    // Defi Events
    event MintcUSDT(uint USDTAmount);
    event RedeemcUSDT(uint RedeemcUSDTAmount);

    // Modifiers
    modifier initialized() {
        require(fundStatus == 1);
        _;
    }

    // modifier fundStarted() {
    //     require(fundStatus == 3);
    //     _;
    // }

    modifier running() {
        require(fundStatus == 4);
        _;
    }

    modifier runningOrSuspended() {
        require((fundStatus == 4) || (fundStatus == 7));
        _;
    }

    modifier stoppedOrSuspended() {
        require((fundStatus == 5) || (fundStatus == 7));
        _;
    }

    modifier runningOrStoppedOrSuspended() {
        require((fundStatus == 4) || (fundStatus == 5) || (fundStatus == 7));
        _;
    }

    modifier closedOrAbortedOrSuspended() {
        require((fundStatus == 6) || (fundStatus == 2) || (fundStatus == 7));
        _;
    }

    modifier isBincentive() {
        require(
            (msg.sender == bincentiveHot) || (msg.sender == bincentiveCold)
        );
        _;
    }

    modifier isBincentiveCold() {
        require(msg.sender == bincentiveCold);
        _;
    }

    modifier isInvestor() {
        // bincentive is not investor
        require(msg.sender != bincentiveHot);
        require(msg.sender != bincentiveCold);
        require(balances[msg.sender] > 0);
        _;
    }


    // Transfer functions for USDT
    function checkBalanceTransfer(address to, uint256 amount) internal {
        uint256 balanceBeforeTransfer = StableToken.balanceOf(to);
        uint256 balanceAfterTransfer;
        StableToken.transfer(to, amount);
        balanceAfterTransfer = StableToken.balanceOf(to);
        require(balanceAfterTransfer == balanceBeforeTransfer.add(amount));
    }

    function checkBalanceTransferFrom(address from, address to, uint256 amount) internal {
        uint256 balanceBeforeTransfer = StableToken.balanceOf(to);
        uint256 balanceAfterTransfer;
        StableToken.transferFrom(from, to, amount);
        balanceAfterTransfer = StableToken.balanceOf(to);
        require(balanceAfterTransfer == balanceBeforeTransfer.add(amount));
    }


    // Getter Functions

    // Get the balance of an investor, denominated in stable token
    function getBalanceValue(address investor) public view returns(uint256) {
        uint256 accruedRatioUSDT = oracle.query();
        return balances[investor].mul(accruedRatioUSDT).div(baseRatio);
    }

    // Defi Functions

    function querycUSDTAmount() internal returns(uint256) {
        return cToken.balanceOf(address(this));
    }

    function querycExgRate() internal returns(uint256) {
        return cToken.exchangeRateCurrent();
    }

    function mintcUSDT(uint USDTAmount) public isBincentive {

        StableToken.approve(address(cToken), USDTAmount); // approve the transfer
        assert(cToken.mint(USDTAmount) == 0);

        emit MintcUSDT(USDTAmount);
    }

    function redeemcUSDT(uint RedeemcUSDTAmount) public isBincentive {

        require(cToken.redeem(RedeemcUSDTAmount) == 0, "something went wrong");

        emit RedeemcUSDT(RedeemcUSDTAmount);
    }


    // Investor Deposit
    // It can either be called by investor directly or by bincentive accounts.
    // Only the passed in argument `investor` would be treated as the real investor.
    function deposit(address investor, uint256 depositUSDTAmount, bytes32 uuid, string referralCode) initialized public {
        require(now < investPaymentDueTime, "Deposit too late");
        require((investor != bincentiveHot) && (investor != bincentiveCold), "Investor can not be bincentive accounts");
        require(depositUSDTAmount > 0, "Deposited stable token amount should be greater than zero");

        // Transfer Stable Token to this contract
        checkBalanceTransferFrom(msg.sender, address(this), depositUSDTAmount);

        // Add investor to investor list if not present in the record before
        if(isInInvestorList[investor] == false) {
            investors.push(investor);
            isInInvestorList[investor] = true;
        }
        currentInvestedAmount = currentInvestedAmount.add(depositUSDTAmount);
        investorDepositUSDTAmount[investor] = investorDepositUSDTAmount[investor].add(depositUSDTAmount);

        // Query Oracle for current stable token ratio
        uint256 accruedRatioUSDT = oracle.query();
        // Mint and distribute tokens to investors
        uint256 mintedTokenAmount;
        mintedTokenAmount = depositUSDTAmount.mul(baseRatio).div(accruedRatioUSDT);
        _mint(investor, mintedTokenAmount);

        emit Deposit(investor, depositUSDTAmount, mintedTokenAmount);
        emit UserInfo(uuid, referralCode);
    }

    // Start Investing
    // Send part of the funds offline
    // and calculate the minimum amount of fund needed to keep the fund functioning
    // and calculate the maximum amount of fund allowed to be withdrawn per period.
    function start() initialized isBincentive public {
        // Send some USDT offline
        uint256 amountSentOffline = currentInvestedAmount.mul(percentageOffchainFund).div(100);
        checkBalanceTransfer(bincentiveCold, amountSentOffline);

        minimumFund = totalSupply().mul(percentageMinimumFund).div(100);
        // Start the contract
        fundStatus = 4;
        emit StartFund(now, investors.length, currentInvestedAmount, totalSupply());
    }

    function amountWithdrawable() public view returns(uint256) {
        return totalSupply().sub(minimumFund);
    }

    function isAmountWithdrawable(address investor, uint256 tokenAmount) public view returns(bool) {
        require(tokenAmount > 0, "Withdrawn amount must be greater than zero");
        require(balances[investor] >= tokenAmount, "Not enough token to be withdrawn");
        require(totalSupply().sub(tokenAmount) >= minimumFund, "Amount of fund left would be less than minimum fund threshold after withdrawal");

        return true;
    }

    function withdraw(address investor, uint256 tokenAmount) running isBincentive public {
        require(tokenAmount > 0, "Withdrawn amount must be greater than zero");
        require(balances[investor] >= tokenAmount, "Not enough token to be withdrawn");
        require(totalSupply().sub(tokenAmount) >= minimumFund, "Amount of fund left would be less than minimum fund threshold after withdrawal");

        uint256 investorBalanceBeforeWithdraw = balances[investor];
        // Substract withdrawing amount from investor's balance
        _burn(investor, tokenAmount);

        uint256 depositUSDTAmount = investorDepositUSDTAmount[investor];

        // Query Oracle for current stable token ratio
        uint256 accruedRatioUSDT = oracle.query();
        uint256 principle;
        uint256 interest;
        uint256 amountUSDTToWithdraw;
        uint256 amountUSDTForInvestor;
        uint256 amountUSDTToBincentiveCold;

        amountUSDTToWithdraw = tokenAmount.mul(accruedRatioUSDT).div(baseRatio);
        principle = depositUSDTAmount.mul(tokenAmount).div(investorBalanceBeforeWithdraw);
        interest = amountUSDTToWithdraw.sub(principle);
        amountUSDTForInvestor = principle.mul(99).div(100).add(interest.div(2));
        amountUSDTToBincentiveCold = amountUSDTToWithdraw.sub(amountUSDTForInvestor);

        // Check if `amountUSDTToBincentiveCold >= penalty`
        if (amountUSDTToBincentiveCold < minPenalty) {
            uint256 dif = minPenalty.sub(amountUSDTToBincentiveCold);
            require(dif <= amountUSDTForInvestor, "Withdraw amount is not enough to cover minimum penalty");
            amountUSDTForInvestor = amountUSDTForInvestor.sub(dif);
            amountUSDTToBincentiveCold = minPenalty;
        }

        investorDepositUSDTAmount[investor] = investorDepositUSDTAmount[investor].sub(principle);

        checkBalanceTransfer(investor, amountUSDTForInvestor);
        checkBalanceTransfer(bincentiveCold, amountUSDTToBincentiveCold);

        emit Withdraw(investor, tokenAmount, amountUSDTForInvestor, amountUSDTToBincentiveCold);

        // Suspend the contract if not enough fund remained
        if(totalSupply() == minimumFund) {
            fundStatus = 7;
        }
    }

    // Return AUM
    // Transfer the fund back to the contract
    function returnAUM(uint256 stableTokenAmount) runningOrSuspended isBincentiveCold public {
        // Option 1: contract transfer AUM directly from bincentiveCold
        checkBalanceTransferFrom(bincentiveCold, address(this), stableTokenAmount);

        emit ReturnAUM(stableTokenAmount);

        // If fund is running, stop the fund after AUM is returned
        if(fundStatus == 4) fundStatus = 5;
    }

    // Add an overlay on top of underlying token transfer
    // because token receiver should also be added to investor list to be able to receive AUM.
    function transfer(address _to, uint256 _value) public returns (bool){
        uint256 tokenBalanceBeforeTransfer = balances[msg.sender];
        bool success = super.transfer(_to, _value);

        if(success == true) {
            if(isInInvestorList[_to] == false) {
                investors.push(_to);
                isInInvestorList[_to] = true;
            }
            // Also transfer the deposited USDT so the receiver can withdraw
            uint256 USDTAmountToTransfer = investorDepositUSDTAmount[msg.sender].mul(_value).div(tokenBalanceBeforeTransfer);
            investorDepositUSDTAmount[msg.sender] = investorDepositUSDTAmount[msg.sender].sub(USDTAmountToTransfer);
            investorDepositUSDTAmount[_to] = investorDepositUSDTAmount[_to].add(USDTAmountToTransfer);
        }
        return success;
    }

    // Add an overlay on top of underlying token transferFrom
    // because token receiver should also be added to investor list to be able to receive AUM.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        uint256 tokenBalanceBeforeTransfer = balances[_from];
        bool success = super.transferFrom(_from, _to, _value);

        if(success == true) {
            if(isInInvestorList[_to] == false) {
                investors.push(_to);
                isInInvestorList[_to] = true;
            }
            // Also transfer the deposited USDT so the receiver can withdraw
            uint256 USDTAmountToTransfer = investorDepositUSDTAmount[_from].mul(_value).div(tokenBalanceBeforeTransfer);
            investorDepositUSDTAmount[_from] = investorDepositUSDTAmount[_from].sub(USDTAmountToTransfer);
            investorDepositUSDTAmount[_to] = investorDepositUSDTAmount[_to].add(USDTAmountToTransfer);
        }
        return success;
    }

    function update_investor(address _old_address, address _new_address) public isBincentiveCold {
        require((_new_address != bincentiveHot) && (_new_address != bincentiveCold), "Investor can not be bincentive accounts");
        require(isInInvestorList[_old_address] == true, "Investor does not exist");

        uint256 balance = balances[_old_address];
        balances[_old_address] = balances[_old_address].sub(balance);
        balances[_new_address] = balances[_new_address].add(balance);
        emit Transfer(_old_address, _new_address, balance);
        if(isInInvestorList[_new_address] == false) {
            investors.push(_new_address);
            isInInvestorList[_new_address] = true;
        }
        uint256 USDTAmountToTransfer = investorDepositUSDTAmount[_old_address];
        investorDepositUSDTAmount[_old_address] = investorDepositUSDTAmount[_old_address].sub(USDTAmountToTransfer);
        investorDepositUSDTAmount[_new_address] = investorDepositUSDTAmount[_new_address].add(USDTAmountToTransfer);
    }

    // Distribute AUM
    // Dispense the fund returned to each investor according to his portion of the token he possessed.
    // All withdraw requests should be processed before calling this function.
    // Since there might be too many investors, each time this function is called,
    // a parameter `numInvestorsToDistribute` is passed in to indicate how many investors to process this time.
    function distributeAUM(uint256 numInvestorsToDistribute) stoppedOrSuspended isBincentive public {
        require(numAUMDistributedInvestors.add(numInvestorsToDistribute) <= investors.length, "Distributing to more than total number of investors");

        // Query Oracle for current stable token ratio
        uint256 accruedRatioUSDT = oracle.query();

        uint256 stableTokenDistributeAmount;
        address investor;
        uint256 investor_amount;
        // Distribute Stable Token to investors
        for(uint i = numAUMDistributedInvestors; i < (numAUMDistributedInvestors.add(numInvestorsToDistribute)); i++) {
            investor = investors[i];
            investor_amount = balances[investor];
            if(investor_amount == 0) continue;
            _burn(investor, investor_amount);

            stableTokenDistributeAmount = investor_amount.mul(accruedRatioUSDT).div(baseRatio);
            checkBalanceTransfer(investor, stableTokenDistributeAmount);

            emit DistributeAUM(investor, investor_amount, stableTokenDistributeAmount);
        }

        numAUMDistributedInvestors = numAUMDistributedInvestors.add(numInvestorsToDistribute);
        // If all investors have received AUM, then close the fund.
        if(numAUMDistributedInvestors >= investors.length) {
            currentInvestedAmount = 0;
            // If fund is stopped, close the fund
            if(fundStatus == 5) fundStatus = 6;
        }
    }

    function claimWronglyTransferredFund() closedOrAbortedOrSuspended isBincentive public {
        // withdraw leftover funds from Defi
        uint256 totalcUSDTAmount;
        totalcUSDTAmount = querycUSDTAmount();
        redeemcUSDT(totalcUSDTAmount);

        uint256 leftOverAmount = StableToken.balanceOf(address(this));
        if(leftOverAmount > 0) {
            checkBalanceTransfer(bincentiveCold, leftOverAmount);
        }
    }

    function updateBincentiveColdAddress(address _newBincentiveCold) public isBincentiveCold {
        require(_newBincentiveCold != address(0), "New BincentiveCold address can not be zero");

        bincentiveCold = _newBincentiveCold;
        emit NewBincentiveCold(_newBincentiveCold);
    }

    constructor(
        address _oracle,
        address _StableToken,
        address _cToken,
        address _bincentiveHot,
        address _bincentiveCold,
        uint256 _investPaymentPeriod,
        uint256 _percentageOffchainFund,
        uint256 _percentageMinimumFund) WhiteListToken(_bincentiveCold) public {

        oracle = SimpleOracleAccruedRatioUSD(_oracle);
        bincentiveHot = _bincentiveHot;
        bincentiveCold = _bincentiveCold;
        StableToken = ITetherERC20(_StableToken);
        cToken = CERC20(_cToken);

        decimals = StableToken.decimals();
        minPenalty = 100 * (10 ** uint256(decimals));  // a minimum 100 USDT penalty
        baseRatio = oracle.query();
        require(baseRatio > 0, "baseRatio should always greater than zero");

        // Set parameters
        investPaymentDueTime = now.add(_investPaymentPeriod);
        percentageOffchainFund = _percentageOffchainFund;
        percentageMinimumFund = _percentageMinimumFund;

        // Initialized the contract
        fundStatus = 1;
    }
}