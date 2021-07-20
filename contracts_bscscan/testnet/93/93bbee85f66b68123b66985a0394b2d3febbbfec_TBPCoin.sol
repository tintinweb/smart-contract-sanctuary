/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

interface IERC20 {
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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
 contract TBPCoin is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public symbol;
    string public  name;
    uint8 public decimals;
    
    bool public blockSell;
    address admin = msg.sender;
    // define function modifier restricting to owner only
    modifier onlyAdmin() {
        if (msg.sender != admin) revert();
        _;
    }
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public  {
        symbol = "TBP3";
        name = "TBP3 Token";
        decimals = 18;
        _totalSupply = 21000000000000000000000000;
        _balances[0x3E97ebf735319AE3A8834a72A582830efaB94E91] = _totalSupply;
        emit Transfer(address(0), 0x3E97ebf735319AE3A8834a72A582830efaB94E91, _totalSupply);
        blockSell=false;
    }

    /**
    *@dev setBlockSell configures user selling block
     */
    function setBlockSell() public
    onlyAdmin
    {
        if(blockSell==true)
            blockSell=false;
        if(blockSell==false)
            blockSell=true;    
    }
    
    /**
    *@dev getBlockSell get the blockSell Value
     */
    function getBlockSell() public view onlyAdmin returns (bool)
    {
        return blockSell;
    }
    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(blockSell==false,"No it's posible to transfer token at this moment");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual onlyAdmin {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function mint(address account, uint256 amount) public {

         _mint(account, amount);

    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual onlyAdmin {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function burn(address account, uint256 amount) public {

         _burn(account, amount);

    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  TBPCoin public token;

  // Address where funds are collected
  address payable public wallet = 0x3E97ebf735319AE3A8834a72A582830efaB94E91;

  // How many token units a buyer gets per wei
  uint256 public rate = 120000000000000;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address payable _wallet, TBPCoin _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    //require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  fallback () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
   pure internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    //return _weiAmount.mul(rate);
    return _weiAmount.div(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}
/** The TBPcoinCrowdSale contract inherits standards and properties from the following Crowdsale contracts:
 * 
 * CROWDSALE: Base architecture for crowdsales. Sets up a wallet to collect funds. Framework to send Ether to the Smart Contract &
 * compute the amount of Tokens disbursed based on the rate.
 * 
 * MINTEDCROWDSALE: The contract will mint Tokens anytime they are purchased, instead of having a preset total supply.
 * The total amount of tokens in distribution is determined by how many are actually sold.
 * 
 * TIMEDCROWDSALE: Sets parameters to start (openingTime) and end (closingTime) the Crowdsale.
 * 
 * CAPPEDCROWDSALE: Sets the max amount of runds it can raise in the Crowdsale.
 * 
 * WHITELISTCROWDSALE: Sets parameters to fullfill KYC requirements. Match contributions in the Crowdsale to real people. Investors 
 * must be WhiteListed before they can purchase Tokens.
 * 
 * STAGED CROWDSALE: Creates 2 stages (pre-sale and public sale) to set rates where investors can receive more Tokens in the pre-sale
 * vs the public sale. In pre-sale, funds go to the wallet, not to the refund escrow vault.
 * 
 * REFUNDABLECROWDSALE: Sets a minimum goal of funds to raise in the Crowdsale. If goal isn't reached, it will refund investors.
 * 
 * DISTRIBUTION & VESTING: Set amount of Tokens to distribute to Founders, Company, and Public.
 */


contract TBPcoinCrowdSale is Crowdsale {
    
    address owner = msg.sender;
    address payable liquidity_address;
    address payable holders_address;
    address payable mto_address;
    
    // define function modifier restricting to owner only
    modifier onlyOwner() {
        if (msg.sender != owner) revert();
        _;
    }


    // Set Crowdsale Stages to manage presale and public token rates
    enum CrowdsaleStage { PreICO, ICO }
    // Set default stage to presale stage
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;

    // Set token Distribution percentages for public sale and Token Resereves 
    // (Public: 70%, Founders, Foundation, Partners: 10% each)
    uint256 public tokenSalePercentage   = 70;
    uint256 public liquidityPercentage   = 4;
    uint256 public holdersPercentage     = 4;
    uint256 public mtoPercentage         = 2;
    uint256 private _weiRaised = 0; 
   
    
    //For the proposal vote system
    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
      function quorumVotes() public pure returns (uint256) { return 50000e18; } // 50,000 = 5% of TBP
    
      /// @notice The number of votes required in order for a voter to become a proposer
      function proposalThreshold() public pure returns (uint256) { return 10000e18; } // 10,000 = 1% of TBP
    
      /// @notice The delay before voting on a proposal may take place, once proposed
      function votingDelay() public pure returns (uint256) { return 1; } // 1 block
    
      /// @notice The duration of voting on a proposal, in blocks
      function votingPeriod() public pure returns (uint256) { return 17280; } // ~3 days in blocks (assuming 15s blocks)
      uint256 public proposalCount;

      struct Proposal {
        // Unique id for looking up a proposal
        uint256 id;
    
        // Creator of the proposal
        address proposer;
    
        // The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
    
        // The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
    
        // Current number of votes in favor of this proposal
        uint256 forVotes;
    
        // Current number of votes in opposition to this proposal
        uint256 againstVotes;
    
        // Flag marking whether the proposal has been canceled
        bool canceled;
    
        // Raw votes (without rooting) given to this proposal
        uint256 rawVotes;
    
        // Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
      }
    
      /// @notice Ballot receipt record for a voter
      struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;
    
        // Whether or not the voter supports the proposal
        bool support;
    
        // The number of votes the voter had, which were cast
        uint256 votes;
      }
      /// @notice Possible states that a proposal may be in
      enum ProposalState {
        Pending,
        Canceled,
        Defeated,
        Succeeded,
        Active
      }
    
      /// @notice The official record of all proposals ever proposed
      mapping (uint256 => Proposal) public proposals;
    
      /// @notice The latest proposal for each proposer
      mapping (address => uint256) public latestProposalIds;
    
      /// @notice An event emitted when a new proposal is created
      event ProposalCreated(uint256 id, address proposer, uint256 startBlock, uint256 endBlock, string description);
    
      /// @notice An event emitted when a vote has been cast on a proposal
      event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);
    
      /// @notice An event emitted when a proposal has been canceled
      event ProposalCanceled(uint256 id);
    
    // Create the contract's constructor to pass parameters from inherited contracts 
    // Crowdsale(rate, wallet, token), CappedCrowdsale(cap), TimedCrowdsale(openingTime, closingTime), RefundableCrowdsale(goal)
    // Include addresses for investors' token reserve funds and for releaseTime
    
    uint fakenow = now;
    uint256         cap;
    uint256  openingTime = fakenow;
    uint256  closingTime = fakenow + 15 days;
    uint256         goal;
    
    constructor()
        Crowdsale(rate, wallet, token)
        public
        {
            
        }
    
   /**
    * Create public function to setup opening time 
    * @dev Setup de opening time.
    * @param newOpeningTime the opening new time
    */
    function setOpeningTime(uint256 newOpeningTime) public
    onlyOwner
    {
        openingTime = newOpeningTime;
    }
    
    /**
    * Create public function to setup closing time 
    * @dev Setup de closing time.
    * @param newClosingTime The closing new time
    */
    function setClosingTime(uint256 newClosingTime) public
    onlyOwner
    {
        closingTime = newClosingTime;
    }
    
    /**
    *@dev Configure Porcentage addresses
    *@param liquidity address for the percentage liquidity
    *@param holders address for holders percentage
    *@param mto address for mto percentage
     */
    function setPorcAdrresses(address payable liquidity,address payable holders, address payable mto) public
    onlyOwner
    {
      liquidity_address = liquidity;
      holders_address = holders;
      mto_address = mto;
    }
    
    /**
    *@dev Get's actual percentage addresses
     */
    function getPorcAdresses()public view onlyOwner returns(address payable,address payable,address payable)
    {
      return (liquidity_address,holders_address,mto_address);
    }   

    
    /**
    * Create public function to setup sell rate 
    * @dev Setup of sell rate.
    * @param newRate The new rate for sell
    */
    function setRate(uint256 newRate) public
    onlyOwner
    {
        rate = newRate;
    }
    
     /**
    *@dev Get's the actual price rate
     */
    function getRate() public view onlyOwner returns(uint256)
    {
      return rate;
    }
    
    /**
    *@dev Get's the actual opening time
     */
    function getOpeningTime() public view onlyOwner returns(uint256)
    {
      return openingTime;
    }

    /**
    *@dev Get's the actual closing time
     */
    function getClosingTime() public view onlyOwner returns(uint256)
    {
      return closingTime;
    }
  
    /**
     *@dev Allows admin to update the crowdsale stage
     * @param _stage Crowdsale stage
     */
    function setCrowdsaleStage(uint _stage) public {
        require(msg.sender == owner, "You are not the owner");
        
        if(uint(CrowdsaleStage.PreICO) == _stage) {
            stage = CrowdsaleStage.PreICO;
        } else if (uint(CrowdsaleStage.ICO) == _stage) {
            stage = CrowdsaleStage.ICO;
        }
         if(stage == CrowdsaleStage.PreICO) {
              rate = 120000000000000;
         } else if (stage == CrowdsaleStage.ICO) {
              rate = 600000000000000;
         }
    }
    
    /**
     * @dev forwards funds to the wallet during the PreICO stage, then the refund vault during ICO stage
     */
    function _forwardFunds(address payable wallet) internal {
         if(stage == CrowdsaleStage.PreICO) {
             wallet.transfer(msg.value);
         } else if (stage == CrowdsaleStage.ICO) {
             super._forwardFunds();
         }
    }
    
    
    /**
    * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    */
    function _preValidatePurchase(
        address payable _beneficiary, 
        uint256 _weiAmount
        ) 
        internal 
        {
        uint256 date = now;
        require(date>=openingTime && date<=closingTime);    
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
    
    /**
     * @return the amount of wei raised.
     */
    function fundsRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    function _buyTokens(address beneficiary, uint256 amount) public payable {
        //super.buyTokens(beneficiary);
        require(amount>=rate,'Debe ingresar el precio minimo por token');
        uint256 weiAmount = amount;
        _preValidatePurchase(beneficiary, weiAmount);
    
        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        //BuyerPercentage
        uint256 tokens_beneficiary = tokens.mul(tokenSalePercentage).div(100);

        //Liquidity Percentage
        uint256 tokens_liquidity = tokens.mul(liquidityPercentage).div(100);

        //holders percentage
        uint256 tokens_holders = tokens.mul(holdersPercentage).div(100);

        //mto percentage
        uint256 tokens_mto = tokens.mul(mtoPercentage).div(100);

        _processPurchase(beneficiary, tokens_beneficiary); 
        //emit TokenPurchase(_msgSender(), beneficiary, amount, tokens);
        _processPurchase(liquidity_address,tokens_liquidity);

        _processPurchase(holders_address,tokens_holders);

        _processPurchase(mto_address,tokens_mto);

        _forwardFunds(); 
        
    }
    
    
    /**
    *@dev enables token transfers, called when owner calls finalize()
    */
    function finalization(  ) internal {
       //super._finalization();
       //TODO implement Last operations of end crowd sale      
    }
    
    
    //Proposal vote system functions
    function propose (string memory description) public returns (uint256) {
        require(token.balanceOf(msg.sender) >= proposalThreshold());
        address _proposer = msg.sender;
        uint256 _startBlock = block.number;
        uint256 _endBlock = _startBlock + votingPeriod();
        uint256 _id = proposalCount;
    
        Proposal memory newProposal = Proposal({
          id: _id,
          proposer: _proposer,
          startBlock: _startBlock,
          endBlock: _endBlock,
          forVotes: 0,
          againstVotes: 0,
          rawVotes: 0,
          canceled: false
        });
    
        proposals[_id] = newProposal;
        proposalCount++;
    
        emit ProposalCreated(_id, _proposer, _startBlock, _endBlock, description);
        return newProposal.id;
    }
    
    function cancel(uint256 proposalId) public {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Succeeded, "GovernorAlpha::cancel: cannot cancel succeeded proposal");
    
        Proposal storage proposal = proposals[proposalId];
        address _proposer = proposal.proposer;
        require(_proposer == msg.sender, "GovernorAlpha::cancel: proposal can only be cancelled by proposer");
    
        proposal.canceled = true;
        
        emit ProposalCanceled(proposalId);
    }
    
    function vote(uint256 proposalId, bool support) public {
        address _voter = msg.sender;
        uint256 _rawVotes = token.balanceOf(_voter);
        uint256 _votes = sqrt(_rawVotes);
        
        Proposal storage _proposal = proposals[proposalId];
        Receipt storage _receipt = _proposal.receipts[_voter];
        require(_receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
    
        if (support) {
          _proposal.forVotes = _proposal.forVotes.add (_votes);
        } else {
          _proposal.againstVotes = _proposal.againstVotes.add(_votes);
        }
    
        _proposal.rawVotes = _proposal.rawVotes.add(_rawVotes);
    
        _receipt.hasVoted = true;
        _receipt.support = support;
        _receipt.votes = _votes;
    
        emit VoteCast(_voter, proposalId, support, _votes);
    }

    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
      return proposals[proposalId].receipts[voter];
    }

    
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount > proposalId && proposalId >= 0, "GovernorAlpha::state: invalid proposal id");
        
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
          return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
          return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
          return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.rawVotes < quorumVotes()) {
          return ProposalState.Defeated;
        } else if (proposal.forVotes >= proposal.againstVotes && proposal.rawVotes >= quorumVotes()) {
          return ProposalState.Succeeded;
        }
    }
    //Math auxiliary function
    // Sqrt
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x.add(1)).div(2);//div(add(x, 1), 2);
        y = x;
        while (z < y) {
        y = z;
        z = ((x.div(z)).add(z)).div(2);//div(add(div(x, z), z), 2);
        }
    }

}