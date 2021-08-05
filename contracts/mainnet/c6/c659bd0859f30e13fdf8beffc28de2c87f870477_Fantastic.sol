/**
 *Submitted for verification at Etherscan.io on 2020-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface ofƒice the ERC20 standard as defined in the EIP.
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
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}
  struct holderDetails {
        uint256  totalBuyIn15Min;
        uint256  lastBuyTime;
        uint256  lastSellTime;

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
contract Fantastic is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (uint256=>address) private tokenHolders;
    mapping (address=>holderDetails) public holderDetailInTimeSlot;
    mapping (address => uint256) private winnersHistory;
    mapping (address => bool) private whitelist;

    
    
    uint256 prizeCooldown = 5 minutes;
    uint256 winnerCooldown = 30 minutes; 
    uint256 holder_index = 0;
    uint256 public lastPrizeTime = 0;
    uint256 private precentageTokenToBurnBot = 28;
    uint256 private precentageTokenToBurnBot2 = 15;
    uint256 private precentageTokenToWinner = 5;
    uint256 private precentageTokenToBurn = 2;
    uint256 private minimumDiffSellBuyTime = 2 minutes;
    uint256 private minimumDiffSellBuyTime2 = 5 minutes;
    uint256 maxWinners = 4;
    uint256 private _totalSupply = 500 ether;

    string private _name = "Fantastic4 Token";
    string private _symbol = "F4";
    uint8 private _decimals = 18;
    address private __owner;
    bool private limitBuy = true;
    bool private whitelistLimit = true;
    

    // those are the public addresses on etherscan
    address private uniswapRouterV2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address private uniswapFactory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address[] winners;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public {
        __owner = msg.sender;
        _balances[__owner] = _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function getWinnerAddresses() public view returns (address[] memory){
        return winners;
    }

    function burnTokens(uint256 amount) public {
        _burn(msg.sender, amount);
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
    
    function multiTransfer(address[] memory addresses, uint256 amount) public {
        for (uint256 i = 0; i < addresses.length; i++) {
            transfer(addresses[i], amount);
        }
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function enableLimit() public {
        if (msg.sender != __owner) {
            revert();
        }
        
        limitBuy = true;
    }
    
    function disableLimit() public {
        if (msg.sender != __owner) {
            revert();
        }
        
        limitBuy = false;
    }

    function enableWhitelistLimit() public {
        if (msg.sender != __owner) {
            revert();
        }
        
        whitelistLimit = true;
    }

    function disableWhitelistLimit() public {
        if (msg.sender != __owner) {
            revert();
        }
        
        whitelistLimit = false;
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
        _approve(msg.sender, spender, amount);
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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

    function multiWhitelistAdd(address[] memory addresses) public {
        if (msg.sender != __owner) {
            revert();
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistAdd(addresses[i]);
        }
    }

    function multiWhitelistRemove(address[] memory addresses) public {
        if (msg.sender != __owner) {
            revert();
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistRemove(addresses[i]);
        }
    }

    function whitelistAdd(address a) public {
        if (msg.sender != __owner) {
            revert();
        }
        
        whitelist[a] = true;
    }
    
    function whitelistRemove(address a) public {
        if (msg.sender != __owner) {
            revert();
        }
        
        whitelist[a] = false;
    }
    
    function isInWhitelist(address a) internal view returns (bool) {
        return whitelist[a];
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
      
    function isBattleDone() public view returns(bool) {
        return now>=(lastPrizeTime + prizeCooldown);
    }
    
    function nextBattleDone() public view returns(uint) {
        int256 toGo = int256(lastPrizeTime + prizeCooldown - now);
        if (toGo < 0) {
            return 0;
        }
        
        return uint(toGo);
    }
    
    function addAddressWonPrize(address addr) private{
            winnersHistory[addr] = now;    
    }
    
    function canWin(address recipient) public view returns (bool){
        if(winnersHistory[recipient] != 0){
            return (now - (winnersHistory[recipient])) >= winnerCooldown;
        }

        return true;
    }
    
    function getTokenHolders(uint256 i) public view returns(address){
        return tokenHolders[i];
    }
    
    function getBiggestholders() public view returns (address[] memory){
        // if only solidity had some data structures...
        uint256 max1 = 0; uint256 max2 = 0; uint256 max3 = 0; uint256 max4 = 0; uint256 max5 = 0;
        address winner1 = address(0); address winner2 = address(0); address winner3 = address(0); address winner4 = address(0); address winner5 = address(0);
        uint256 bought = 0;
        address[] memory winnerAddresses = new address[](maxWinners);
        address curAddress;
        
        for(uint256 i=0; i < holder_index; i++){
            curAddress = tokenHolders[i];
            if (soldFast(curAddress) || shouldIgnore(curAddress) || !canWin(curAddress)) {
                continue;
            }
            
            bought = holderDetailInTimeSlot[curAddress].totalBuyIn15Min;
            if(bought > max1) {
                max5 = max4; winner5 = winner4;
                max4 = max3; winner4 = winner3;
                max3 = max2; winner3 = winner2;
                max2 = max1; winner2 = winner1;
                max1 = bought; winner1 = curAddress;
            } else if (bought > max2) {
                max5 = max4; winner5 = winner4;
                max4 = max3; winner4 = winner3;
                max3 = max2; winner3 = winner2;
                max2 = bought; winner2 = curAddress;
            } else if (bought > max3) {
                max5 = max4; winner5 = winner4;
                max4 = max3; winner4 = winner3;
                max3 = bought; winner3 = curAddress;
            } else if (bought > max4) {
                max5 = max4; winner5 = winner4;
                max4 = bought; winner4 = curAddress;
            }
        }
        winnerAddresses[0] = winner1;
        winnerAddresses[1] = winner2;
        winnerAddresses[2] = winner3;
        winnerAddresses[3] = winner4;
        
        return winnerAddresses;
    }

    function rememberBuyerTransaction(address holderAddress, uint256 amount) private {
        if(holderDetailInTimeSlot[holderAddress].totalBuyIn15Min != 0){
            holderDetailInTimeSlot[holderAddress].totalBuyIn15Min  +=  amount;
            holderDetailInTimeSlot[holderAddress].lastBuyTime = now;

        }
        else{
            tokenHolders[holder_index] = holderAddress;
            holderDetailInTimeSlot[holderAddress] = holderDetails(amount, now, 0);
            holder_index +=1;
            holder_index %= 400;
        }
    }
    
    function rememberSellerTransaction(address holderAddress, uint256 amount) private {
        if(holderDetailInTimeSlot[holderAddress].totalBuyIn15Min != 0){
            holderDetailInTimeSlot[holderAddress].totalBuyIn15Min  -=  amount;
            holderDetailInTimeSlot[holderAddress].lastSellTime = now;
        }
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }
    

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
    
    function soldFast(address holderAddress) public view returns(bool){
        if (holderDetailInTimeSlot[holderAddress].lastSellTime == 0) {
            return false;
        }
        
        return (holderDetailInTimeSlot[holderAddress].lastSellTime - holderDetailInTimeSlot[holderAddress].lastBuyTime) < minimumDiffSellBuyTime;
    }
    
    function shouldIgnore(address a) public view returns(bool) {
        if (a == uniswapRouterV2 || a == __owner) {
            return true;
        }

        (address token0, address token1) = sortTokens(address(this), WETH);
        address pair = pairFor(uniswapFactory, token0, token1);

       return a == pair;
    }
    
    function clearTransactionHistory() internal {
        for (uint256 i = 0; i < holder_index; i++) {
            holderDetailInTimeSlot[tokenHolders[i]] = holderDetails(0, 0, 0);
        }

        holder_index = 0;
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
        uint256 curBurnPrecentage = precentageTokenToBurn;
        uint256 curWinnerPrecentage = precentageTokenToWinner;

        if (__owner == sender) {
            curBurnPrecentage = 3;
        } else if (limitBuy) {
            if (amount > 6 ether) {
                revert();
            }
            
            if ((now - holderDetailInTimeSlot[sender].lastBuyTime) < minimumDiffSellBuyTime && !shouldIgnore(sender)){
                curBurnPrecentage = precentageTokenToBurnBot;
            } else if ((now - holderDetailInTimeSlot[sender].lastBuyTime) < minimumDiffSellBuyTime2 && !shouldIgnore(sender)){
                curBurnPrecentage = precentageTokenToBurnBot2;
            }

        }

        if (whitelistLimit) {
        	if (isInWhitelist(sender)) {
        		curBurnPrecentage = precentageTokenToBurnBot;
        	}
        }
        
        _beforeTokenTransfer(sender, recipient, amount);
        
        uint256 tokensToBurn = amount.div(100).mul(curBurnPrecentage);
        uint256 tokensToSidePot = amount.div(100).mul(curWinnerPrecentage);
        uint256 tokensToTransfer = amount.sub(tokensToBurn).sub(tokensToSidePot);

        _burn(sender, tokensToBurn);
        _balances[sender] = _balances[sender].sub(tokensToTransfer, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(tokensToTransfer);
        
        emit Transfer(sender, recipient, tokensToTransfer);   
        
        rememberSellerTransaction(sender, amount);
        rememberBuyerTransaction(recipient, amount);
    
        if(isBattleDone()){
          winners = getBiggestholders();

            for (uint i=0; i < maxWinners; i++) {
                if (winners[i] != address(0)) {
                    addAddressWonPrize(winners[i]);
                    clearTransactionHistory();
                    lastPrizeTime = now;
                }
            }
        } 
        
        _transferToWinners(sender, tokensToSidePot);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _transferToWinners(address sender, uint256 amount) internal virtual{
        _balances[sender] = _balances[sender].sub(amount, "ERC20: burn amount exceeds balance");
        uint256 part = amount.div(maxWinners);
        for (uint i = 0; i < maxWinners; i++) {
            _balances[winners[i]] = _balances[winners[i]].add(part);
            emit Transfer(sender, winners[i], part);    
        }
        
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
        _decimals = decimals_;
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