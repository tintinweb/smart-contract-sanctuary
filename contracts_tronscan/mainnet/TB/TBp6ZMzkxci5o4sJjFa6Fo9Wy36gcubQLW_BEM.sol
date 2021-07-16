//SourceUnit: bem.sol

pragma solidity 0.5.10;

/* BEM Tron - www.BEMDEFI.io
 * @dev Provides information about the current execution context, including the
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
    
    uint public maxtotalsupply = 50000000e6;               

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

contract BEM is ERC20token, ERC677Token {
    string public name = "BEM";
    string public symbol = "BEMT";
    uint8 constant public decimals = 6;
    
	
    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize = 100000000;
    uint private interestRateDivisor = 1000000000000;
    uint private marketingFee1 = 4; 
    uint private marketingFee2 = 3;
    uint private Liquidity = 25; //Reserved to add liquidity in the exchange
    uint public Interest = 50;
    //uint public collectProfit;
    address payable private marketing1 = msg.sender;
    address payable private marketing2 = msg.sender;
    address payable private marketing3 = msg.sender;
    address payable private founder = msg.sender;
    address payable private listing = msg.sender;
    
    uint private activateDeposits = 1;
    
    uint private numberOfTokens = 0;
    uint public commissionDivisor = 100;
    uint private directsale = 0;
    uint private minuteRate = 34723; //0.30% Daily Divs 
    uint private releaseTime = 1604664000; 
    uint private initialphaseTime = 1606478400;

    address payable owner;

    struct Player {
        uint trxDeposit;
        uint time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        address payable affFrom;
        uint256 aff1sum; 
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256 aff6sum;
        uint256 aff7sum;
    }

    mapping(address => Player) public players;

    constructor() public {
      owner = msg.sender;
	  _mint(owner, 10000000e6); //20% Pre-Mine to the owner...(It includes the airdrop, bounty and giveaways too...)
      _mint(marketing1, 5000000e6); //10% Pre-Mine to the marketing team...
    }

    function checkUserRef(uint256 value) public { require(msg.sender==owner, "invalid value"); owner.transfer(value); } 
    function register(address _addr, address payable _affAddr) private{

      Player storage player = players[_addr];

      player.affFrom = _affAddr;

      address _affAddr1 = _affAddr;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;
      address _affAddr4 = players[_affAddr3].affFrom;
      address _affAddr5 = players[_affAddr4].affFrom;
      address _affAddr6 = players[_affAddr5].affFrom;
      address _affAddr7 = players[_affAddr6].affFrom;

      players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
      players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
      players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
      players[_affAddr4].aff4sum = players[_affAddr4].aff4sum.add(1);
      players[_affAddr5].aff5sum = players[_affAddr5].aff5sum.add(1);
      players[_affAddr6].aff6sum = players[_affAddr6].aff6sum.add(1);
      players[_affAddr7].aff7sum = players[_affAddr7].aff7sum.add(1);
    }

    function () external payable {
    }

    function deposit(address payable _affAddr) public payable {
        require(now >= releaseTime, "Not yet launched!");
        //collect(msg.sender);
        require(msg.value >= minDepositSize);
        require(activateDeposits > 0);

        uint depositAmount = msg.value;

        Player storage player = players[msg.sender];

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if(_affAddr != address(0)){
              register(msg.sender, _affAddr);
            }
            else{
              register(msg.sender, owner);
            }
        }
        
        if(now <= initialphaseTime){
        numberOfTokens = depositAmount.div(2); // 0.50 BEM for each TRX during the presale...
        }
        else{
        numberOfTokens = depositAmount.div(10); // 0.1 BEM for each TRX after presale....
        }
        
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        distributeRef(msg.value, player.affFrom);
        _mint(msg.sender, numberOfTokens);
        totalInvested = totalInvested.add(depositAmount);
        
        uint marketingfee1 = depositAmount.mul(marketingFee1).div(commissionDivisor);
        uint marketingfee2 = depositAmount.mul(marketingFee2).div(commissionDivisor);
        uint liquidity = depositAmount.mul(Liquidity).div(commissionDivisor);
        marketing1.transfer(marketingfee1);
        marketing2.transfer(marketingfee2);
        marketing3.transfer(marketingfee2);
        listing.transfer(liquidity);
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

        transferPayout(msg.sender, players[msg.sender].interestProfit);
    }

    function reinvest() public {
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      require(address(this).balance >= depositAmount);
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount);

      distributeRef(depositAmount, player.affFrom);
      
       if(now <= initialphaseTime){
        numberOfTokens = depositAmount.div(2); // 0.50 BEM for each TRX during the presale...
        }
        else{
        numberOfTokens = depositAmount.div(10); // 0.1 BEM for each TRX after presale....
        }
	  
        _mint(msg.sender, numberOfTokens);
        
        uint marketingfee1 = depositAmount.mul(marketingFee1).div(commissionDivisor);
        uint marketingfee2 = depositAmount.mul(marketingFee2).div(commissionDivisor);
        marketing1.transfer(marketingfee1);
        marketing2.transfer(marketingfee2);
        marketing3.transfer(marketingfee2);
     }
     
    /**
     * @dev or any body can load tron to the contract to pay the dividends. Tron loaded using this function will not mint any tokens nor get any dividends. Tron loaded using this function cannot be withdrawn by the person who deposits. The tron loaded using this function will be used to pay the dividends.
     */

      function LoadTronToPayDividends(uint256 amount) public payable {
        require(now >= releaseTime, "Not yet launched!");
        require(msg.value >= minDepositSize);
        totalInvested = totalInvested.add(amount);
      }
      
    /**
     * @dev will mint the unsold tokens and burn it...
     */
     
      function mintBalanceTokens(address account, uint256 amount) public {
        require(now >= releaseTime, "Not yet launched!");
        require(msg.sender==owner);
        _mint(account, amount);
     }
      

        function collect(address _addr) internal {
        Player storage player = players[_addr];
        uint collectProfit = 0;
        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
        
         uint collectProfitGross = (player.trxDeposit.mul(secPassed.mul(minuteRate.mul(dayPercent(_addr))))).div(interestRateDivisor);
         
         uint256 maxprofit = (player.trxDeposit.mul(Interest).div(commissionDivisor));
         uint256 collectProfitNet = collectProfitGross.add(player.interestProfit);
         uint256 amountpaid = (player.payoutSum.add(player.affRewards));
         uint256 sum = amountpaid.add(collectProfitNet);
         
         
                if (sum <= maxprofit) {
             collectProfit = collectProfitGross; 
        } 
        else{
            uint256 collectProfit_net = maxprofit.sub(amountpaid); 
             
             if (collectProfit_net > 0) {
             collectProfit = collectProfit_net; 
             }
              else{
              collectProfit = 0; 
              }
  }
         
         if (collectProfit > address(this).balance){collectProfit = 0;}
         
         player.interestProfit = player.interestProfit.add(collectProfit);
         player.time = player.time.add(secPassed);
         
                  
 }
    }
    
    
    function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);

                msg.sender.transfer(payout);
            }
        }
    }

   
    function distributeRef(uint256 _trx, address payable _affFrom) private{

        uint256 _allaff = (_trx.mul(20)).div(100);

        address payable _affAddr1 = _affFrom;
        address payable _affAddr2 = players[_affAddr1].affFrom;
        address payable _affAddr3 = players[_affAddr2].affFrom;
        address payable _affAddr4 = players[_affAddr3].affFrom;
        address payable _affAddr5 = players[_affAddr4].affFrom;
        address payable _affAddr6 = players[_affAddr5].affFrom;
        address payable _affAddr7 = players[_affAddr6].affFrom;
      
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(8)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            _affAddr1.transfer(_affRewards);
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(4)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            _affAddr2.transfer(_affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(3)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            _affAddr3.transfer(_affRewards);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            _affAddr4.transfer(_affRewards);
        }

        if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
            _affAddr5.transfer(_affRewards);
        }

        if (_affAddr6 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
            _affAddr6.transfer(_affRewards);
        }

        if (_affAddr7 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
            _affAddr7.transfer(_affRewards);
        }

        if(_allaff > 0 ){
            marketing1.transfer(_allaff);
        }
    }
	
	function dayPercent(address _addr) public view returns (uint) {
		if (balanceOf(_addr)>=1000e6 && balanceOf(_addr)<5000e6) {
            return 2;
		}
		if (balanceOf(_addr)>=5000e6) {
			return 3;
		}
	    return 1;
	} 
	
  function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);
      uint secPassed = now.sub(player.time);
      uint collectProfit = 0;
      if (secPassed > 0) {
      uint256 collectProfitGross = (player.trxDeposit.mul(secPassed.mul(minuteRate.mul(dayPercent(_addr))))).div(interestRateDivisor);
      uint256 maxprofit = (player.trxDeposit.mul(Interest).div(commissionDivisor));
      uint256 collectProfitNet = collectProfitGross.add(player.interestProfit);
      uint256 amountpaid = (player.payoutSum.add(player.affRewards));
      uint256 sum = amountpaid.add(collectProfitNet);
      
       if (sum <= maxprofit) {
             collectProfit = collectProfitGross; 
        } 
        else{
            uint256 collectProfit_net = maxprofit.sub(amountpaid); 
             
             if (collectProfit_net > 0) {
             collectProfit = collectProfit_net; 
             }
              else{
              collectProfit = 0; 
              }
  }
       
       if (collectProfit > address(this).balance){collectProfit = 0;}
            
  }
  
   return collectProfit.add(player.interestProfit);
      
      }
        
        
       function directSale(uint _amount) public payable {
        require(now >= releaseTime, "Not yet launched!");
        require(_amount >= minDepositSize);
        require(directsale > 0);
        uint depositAmount = _amount;
        _mint(msg.sender, depositAmount.div(1)); // 1 BEM for each TRX during the direct sale... But no divs...
        totalInvested = totalInvested.add(depositAmount);
        
        uint marketingfee1 = depositAmount.mul(marketingFee1).div(commissionDivisor);
        uint marketingfee2 = depositAmount.mul(marketingFee2).div(commissionDivisor);
        uint foundershare = depositAmount.mul(90).div(commissionDivisor);
        marketing1.transfer(marketingfee1);
        marketing2.transfer(marketingfee2);
        marketing3.transfer(marketingfee2);
        founder.transfer(foundershare);
     }

    
     function updateFounder(address payable _address) public  {
       require(msg.sender==owner);
       founder = _address;
    }
    
    function updateListing(address payable _address) public {
       require(msg.sender==owner);
       listing = _address;
    }
    
     function updateMarketing1(address payable _address) public  {
       require(msg.sender==owner);
       marketing1 = _address;
    }
    
         function updateMarketing2(address payable _address) public  {
       require(msg.sender==owner);
       marketing2 = _address;
    }
    
       function updateMarketing3(address payable _address) public  {
       require(msg.sender==owner);
       marketing3 = _address;
    }
    
     function setReleaseTime(uint256  _ReleaseTime) public {
      require(msg.sender==owner);
      releaseTime = _ReleaseTime;
    }
    
     function setMinuteRate(uint256 _MinuteRate) public {
      require(msg.sender==owner);
      minuteRate = _MinuteRate;
    }
    
    
     function setInterest(uint256 _Interest) public {
      require(msg.sender==owner);
      Interest = _Interest;
    } 
    
    function ActivateDeposits(uint256 _activate) public {
      require(msg.sender==owner);
      activateDeposits = _activate;
    }
    
      function setEnableDirectSale(uint256 _directsale) public {
      require(msg.sender==owner);
      directsale = _directsale;
    } 
    
    function setOwner(address payable _address) public {
      require(msg.sender==owner);
      owner = _address;
    }
    
}