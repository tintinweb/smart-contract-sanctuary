//SourceUnit: JustRoi-Live.sol

pragma solidity 0.5.8;

 /* @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
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
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

 
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20token is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    
    uint public maxtotalsupply = 100000000e6;  //100 Million Maximum Token Supply            

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function maxTokenSupply() public view returns (uint256) {
        return maxtotalsupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: Cannot mint to the zero address");

        //_totalSupply = _totalSupply.add(amount);
        //_balances[account] = _balances[account].add(amount);
        //emit Transfer(address(0), account, amount);
        
        uint sumofTokens = _totalSupply.add(amount); 
        if(sumofTokens <= maxtotalsupply){
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        }else{
        uint netTokens = maxtotalsupply.sub(_totalSupply);
        if(netTokens >0) {
        _totalSupply = _totalSupply.add(netTokens);
        _balances[account] = _balances[account].add(netTokens);
        emit Transfer(address(0), account, netTokens);
        }
        }
 }
 
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: Cannot burn from the zero address");
        require(amount <= _balances[account]);

        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds your balance");
        _totalSupply = _totalSupply.sub(amount);
        maxtotalsupply = maxtotalsupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _burnTokens(address account, uint256 amount) public {
        require(account != address(0), "ERC20: Cannot burn from the zero address");
        require(msg.sender==account);
        require(amount <= _balances[account]);
        

        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds your balance");
        _totalSupply = _totalSupply.sub(amount);
        maxtotalsupply = maxtotalsupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC677 is ERC20token {
  function transferAndCall(address to, uint value, bytes memory data) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

interface ERC677Receiver {
  function onTokenTransfer(address _sender, uint _value, bytes calldata _data) external;
}

contract ERC677Token is ERC677 {

  /**
  * @dev transfer token to a contract address with additional data if the recipient is a contact.
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  * @param _data The extra data to be passed to the receiving contract.
  */
  function transferAndCall(address _to, uint _value, bytes memory _data) public returns (bool success) {
    super.transfer(_to, _value);
    emit Transfer(msg.sender, _to, _value, _data);
    if (isContract(_to)) {
      contractFallback(_to, _value, _data);
    }
    return true;
  }


  // PRIVATE

  function contractFallback(address _to, uint _value, bytes memory _data) private {
    ERC677Receiver receiver = ERC677Receiver(_to);
    receiver.onTokenTransfer(msg.sender, _value, _data);
  }

  function isContract(address _addr) private view returns (bool hasCode) {
    uint length;
    assembly { length := extcodesize(_addr) }
    return length > 0;
  }

}

contract ROI is ERC20token, ERC677Token {

    string public name = "ROI";
    string public symbol = "ROI";
    uint8 constant public decimals = 6;
    uint private numberOfTokens = 0;
    uint private releaseTime = 1602691200;
    uint private liquidityTime = 1602950400;
    uint256 private randNonce = 0;
    uint256 randomizer = 456717097;

    using SafeMath for uint256;

    struct PlayerDeposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 timestamp;
    }

    struct Player {
        address referral;
        uint256 first_deposit;
        uint256 last_withdraw;
        uint256 referral_bonus;
        uint256 fee_bonus;
        uint256 dividends;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;

        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) payouts_per_level;
    }

    uint256 total_invested;
    uint256 total_investors;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;

    

    struct TopCount {
        uint count;
        address addr;
    }
    mapping(uint8 => mapping(uint8 => TopCount)) public tops;


    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    address payable owner;
    address payable marketing;
    address payable liquidity;
    
    mapping(address => Player) public players;

    uint8[] public referral_bonuses;

    constructor(address payable _owner, address payable _marketing, address payable _liquidity) public {
        owner = _owner;

        referral_bonuses.push(50);
        referral_bonuses.push(25);
        referral_bonuses.push(10);
        referral_bonuses.push(5);
        referral_bonuses.push(5);
        referral_bonuses.push(5);

        marketing = _marketing;
        liquidity = _liquidity;
        
       
	  _mint(owner, 5000000e6); //5% Pre-Mine to the owner...
      _mint(marketing, 100000e6); //0.1% Pre-Mine to the marketing team...  
      _mint(liquidity, 20000000e6); //20% for staking rewards, farming rewards and liquidity...        
    }

    function deposit(address _referral) external payable {
        require(msg.value >= 1e7, "Zero amount");
        require(msg.value >= 10000000, "Minimal deposit: 10 TRX");
        require(now >= releaseTime, "Not yet launched!");
        Player storage pl = players[msg.sender];
        require(pl.deposits.length < 250, "Max 250 deposits per address");

        _setReferral(msg.sender, _referral);

        pl.deposits.push(PlayerDeposit({
            amount: msg.value,
            withdrawn: 0,
            timestamp: uint256(block.timestamp)
        }));

        if(pl.first_deposit == 0){
            pl.first_deposit = block.timestamp;
        }

        if(pl.total_invested == 0x0){
            total_investors += 1;
        }

        elaborateTopX(1, msg.sender, (pl.total_invested + msg.value));

        pl.total_invested += msg.value;
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);

        _rewardTopList(msg.value);
        owner.transfer(msg.value.mul(6).div(100));
        marketing.transfer(msg.value.mul(4).div(100));
        
        if(now <=liquidityTime){
        liquidity.transfer(msg.value.mul(5).div(100));  //To add liquidity in Justswap
        }
        
         uint256 random = getRandomNumber(msg.sender) + 1;
        
         numberOfTokens = msg.value.div(random);  // ROI token's cost may vary from 1 to 10 TRX. A random number is generated from 1 to 10, and the price is derived from it.
        _mint(msg.sender, numberOfTokens);

        emit Deposit(msg.sender, msg.value);
    }

    function _rewardTopList(uint256 _value) private {
        for(uint8 k = 0; k < 2; k++) {
           for(uint8 i = 0; i < 3; i++){
               address adr = tops[k][i].addr;
               if(adr != address(0) && players[adr].total_invested > 0){
                   players[adr].fee_bonus += _value.mul((i == 0 ? 5 : (i == 1 ? 2 : 1))).div(1000);
               }
           }
        }
    }

    function _setReferral(address _addr, address _referral) private {
        if(players[_addr].referral == address(0)) {
            if(_referral == address(0)){ _referral = owner; }
            players[_addr].referral = _referral;

            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                players[_referral].referrals_per_level[i]++;
                if(i == 0){ elaborateTopX(0, _referral, players[_referral].referrals_per_level[i]); }
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }

    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;

            uint256 bonus;
            if(i == 0){
                bonus = _amount * ((referral_bonuses[i] * 10) + _referralBonus(_addr) + _whaleBonus(_addr) )/ 10000;
            } else {
                bonus = _amount * referral_bonuses[i] / 1000;
            }

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            players[ref].payouts_per_level[i] += bonus;
            total_referral_bonus += bonus;

            ref = players[ref].referral;
        }
    }

  function withdraw() payable external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.referral_bonus + player.fee_bonus;

        player.dividends = 0;
        player.referral_bonus = 0;
        player.fee_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;

        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_withdraw = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _updateTotalPayout(address _addr) private{
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 from = player.last_withdraw > dep.timestamp ? player.last_withdraw : dep.timestamp;
            uint256 to = uint256(block.timestamp);

            if(from < to) {
                uint256 _val = dep.amount * (to - from) * _getPlayerRate(_addr) / 864000000;
                if(_val > ((dep.amount * 3) - dep.withdrawn)){
                    _val = ((dep.amount * 3) - dep.withdrawn);
                }
                player.deposits[i].withdrawn += _val;
            }
        }
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 from = player.last_withdraw > dep.timestamp ? player.last_withdraw : dep.timestamp;
            uint256 to = uint256(block.timestamp);

            if(from < to) {
                uint256 _val = dep.amount * (to - from) * _getPlayerRate(_addr) / 864000000;
                if(_val > ((dep.amount * 3) - dep.withdrawn)){
                    _val = ((dep.amount * 3) - dep.withdrawn);
                }
                value += _val;
            }
        }
        return value;
    }


    function contractStats() view external returns(uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral, uint16 _contract_bonus) {
        return(total_invested, total_investors, total_withdrawn, total_referral_bonus, _contractBonus());
    }

    function playerStats(address _adr) view external returns(uint16 _referral_bonus, uint16 _whale_bonus, uint16 _strong_hand_bonus, uint16 _top_ref_bonus, uint16 _top_whale_bonus, uint16 _roi){
        return(_referralBonus(_adr), _whaleBonus(_adr), _strongHandBonus(_adr), _topReferralBonus(_adr), _topWhaleBonus(_adr), _getPlayerRate(_adr));
    }

    function playerInfo(address _adr) view external returns(uint256 _total_invested, uint256 _total_withdrawn, uint256 _last_withdrawn, uint256 _referral_bonus, uint256 _fee_bonus, uint256 _available){
        Player memory pl = players[_adr];
        return(pl.total_invested, pl.total_withdrawn, pl.last_withdraw, pl.referral_bonus, pl.fee_bonus, (pl.dividends + pl.referral_bonus + pl.fee_bonus + this.payoutOf(_adr)));
    }

    function playerReferrals(address _adr) view external returns(uint256[] memory ref_count, uint256[] memory ref_earnings){
        uint256[] memory _ref_count = new uint256[](6);
        uint256[] memory _ref_earnings = new uint256[](6);
        Player storage pl = players[_adr];

        for(uint8 i = 0; i < 6; i++){
            _ref_count[i] = pl.referrals_per_level[i];
            _ref_earnings[i] = pl.payouts_per_level[i];
        }

        return (_ref_count, _ref_earnings);
    }

    function top10() view external returns(address[] memory top_ref, uint256[] memory top_ref_count, address[] memory top_whale, uint256[] memory top_whale_count){
        address[] memory _top_ref = new address[](10);
        uint256[] memory _top_ref_count = new uint256[](10);
        address[] memory _top_whale = new address[](10);
        uint256[] memory _top_whale_count = new uint256[](10);

        for(uint8 i = 0; i < 10; i++){
            _top_ref[i] = tops[0][i].addr;
            _top_ref_count[i] = tops[0][i].count;
            _top_whale[i] = tops[1][i].addr;
            _top_whale_count[i] = tops[1][i].count;
        }

        return (_top_ref, _top_ref_count, _top_whale, _top_whale_count);
    }

    function investmentsInfo(address _addr) view external returns(uint256[] memory starts, uint256[] memory amounts, uint256[] memory withdrawns) {
        Player storage player = players[_addr];
        uint256[] memory _starts = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _withdrawns = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];
          _amounts[i] = dep.amount;
          _withdrawns[i] = dep.withdrawn;
          _starts[i] = dep.timestamp;
        }
        return (
          _starts,
          _amounts,
          _withdrawns
        );
    }

    function _referralBonus(address _adr) view private returns(uint16){
        Player storage pl = players[_adr];
        uint256 c = pl.referrals_per_level[0];
        uint16 _bonus = 0;
        if(c >= 500){ _bonus = 250; }
        else if(c >= 250){ _bonus = 200; }
        else if(c >= 100){ _bonus = 150; }
        else if(c >= 50){ _bonus = 100; }
        else if(c >= 15){ _bonus = 50; }
        else if(c >= 5){ _bonus = 10; }
        return _bonus;
    }

    function _whaleBonus(address _adr) view private returns(uint16){
        Player storage pl = players[_adr];
        uint256 cur_investment = pl.total_invested;
        uint16 _bonus = 0;
        if(cur_investment >= 1000000000000){ _bonus = 250; }
        else if(cur_investment >= 250000000000){ _bonus = 200; }
        else if(cur_investment >= 100000000000){ _bonus = 150; }
        else if(cur_investment >= 25000000000){ _bonus = 100; }
        else if(cur_investment >= 10000000000){ _bonus = 50; }
        else if(cur_investment >= 2500000000){ _bonus = 10; }
        return _bonus;
    }

    function _strongHandBonus(address _adr) view private returns(uint16){
        Player storage pl = players[_adr];
        uint256 lw = pl.first_deposit;
        if(pl.last_withdraw < lw){ lw = pl.last_withdraw; }
        if(lw == 0){ lw = block.timestamp; }
        uint16 sh = uint16(((block.timestamp - lw)/86400)*100);
        if(sh > 3000){ sh = 3000; }
        return sh;
    }

    function _contractBonus() view private returns(uint16){
        return uint16(address(this).balance/1000000/50000);
    }

    function _topReferralBonus(address _adr) view private returns(uint16){
        uint16 bonus = 0;
        for(uint8 i = 0; i < 10; i++){
            if(tops[0][i].addr == _adr){
                if(i == 0){ bonus = 200; }
                else if(i == 1){ bonus = 150; }
                else if(i == 2){ bonus = 100; }
                else { bonus = 50; }
            }
        }
        return bonus;
    }

    function _topWhaleBonus(address _adr) view private returns(uint16){
        uint16 bonus = 0;
        for(uint8 i = 0; i < 10; i++){
            if(tops[1][i].addr == _adr){
                if(i == 0){ bonus = 200; }
                else if(i == 1){ bonus = 150; }
                else if(i == 2){ bonus = 100; }
                else { bonus = 50; }
            }
        }
        return bonus;
    }

    function _getPlayerRate(address _adr) view private returns(uint16){
        return (100 + _contractBonus() + _strongHandBonus(_adr) + _whaleBonus(_adr) + _referralBonus(_adr) + _topReferralBonus(_adr) + _topWhaleBonus(_adr) );
    }
    
      function setReleaseTime(uint256  _ReleaseTime) public {
      require(msg.sender==owner);
      releaseTime = _ReleaseTime;
    }
    
        function getRandomNumber(address _addr) private returns(uint256 randomNumber) 
    {
        randNonce++;
        randomNumber = uint256(keccak256(abi.encodePacked(now, _addr, randNonce, randomizer, block.coinbase, block.number))) % 9;
        
    }
    
        
     function setOwner(address payable _address) public {
     require(msg.sender==owner);
     owner = _address;
    }
    
     function setMarketing(address payable _address) public {
     require(msg.sender==owner);
     marketing = _address;
    }
    
     function setLiquidity(address payable _address) public {
     require(msg.sender==owner);
     liquidity = _address;
    }

    function elaborateTopX(uint8 kind, address addr, uint currentValue) private {
        if(currentValue > tops[kind][11].count){
            bool shift = false;
            for(uint8 x; x < 12; x++){
                if(tops[kind][x].addr == addr){ shift = true; }
                if(shift == true && x < 11){
                    tops[kind][x].count = tops[kind][x + 1].count;
                    tops[kind][x].addr = tops[kind][x + 1].addr;
                } else if(shift == true && x == 1){
                    tops[kind][x].count = 0;
                    tops[kind][x].addr = address(0);
                }
            }
            uint8 i = 0;
            for(i; i < 12; i++) {
                if(tops[kind][i].count < currentValue) {
                    break;
                }
            }
            uint8 o = 1;
            for(uint8 j = 11; j > i; j--) {
                //if(tops[kind][j - o].addr == addr){ o += 1; }
                tops[kind][j].count = tops[kind][j - o].count;
                tops[kind][j].addr = tops[kind][j - o].addr;
            }
            tops[kind][i].count = currentValue;
            tops[kind][i].addr = addr;
        }
    }
}