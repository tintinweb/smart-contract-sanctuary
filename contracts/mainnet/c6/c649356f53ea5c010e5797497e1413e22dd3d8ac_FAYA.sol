/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// ‎️‍🔥faya.finance (FAYA)‎️‍🔥
// FAYA BURNS TOKENS
//
// Randomized token burns and redistribution + massive charity
// 10% tax on buys, 17.5% on sells
//
// __Tokenomics__
// - Each transaction results in up to a 0.2% burn of the current UNISWAP supply.
// - Each buy has a 5% tax, given to one random holder*, + 5% to the charity wallet.
// - Each sell has a 10% tax, split between 2 random holders*, + 7.5% to the charity wallet.
// - BUT, if the lucky one sold tokens in the past, they get less. If sold once, gets half. Sold twice, gets a third.
//   The rest of the tax is BURNT
// - max buy = 2% of current supply, i.e. 2,000 tokens a launch
// - max sell = 1% of current supply, i.e. 1,000 tokens a launch
//
// Initial supply: 100,000
// Burns stop after 90% is burnt
//
// Charity funds to be distributed based on community votes, TBD
//
// https://faya.finance
// Telegram: https://t.me/FAYAToken

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;


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


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FAYA is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => uint) private _sells;
    mapping (address => uint256) private _lastTXs;
    mapping (address => bool) private _isHolder;
    address[] private _holders;

    mapping (address => mapping (address => uint256)) private _allowances;


    uint256 private _totalSupply = 100000 * 10**12;
    uint256 private _minSupply = 10000 * 10**12;
    string private _name = 'FAYA.Finance';
    string private _symbol = 'FAYA';
    uint8 private _decimals = 12;

    address _reserve;
    address _charity;
    
    
    constructor() {
        _reserve = address(0); // until set later to uniswap
        _charity = address(0); // until set later to dedicated wallet
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);      
    }
    
    function name() public view virtual  returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual  returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function setReserveAddress(address reserve) public onlyOwner() {
        _reserve = reserve;
    }

    function setCharityAddress(address charity) public onlyOwner() {
        _charity = charity;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        // Exclude owner from taxes, to allow transfer of funds to uniswap and other wallets.
        if (owner() == sender || owner() == recipient) {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            // Tax on transaction
            if (_isContract(recipient)) {
                // sell
                require(_totalSupply.div(100) >= amount, "ERC20: sell amount exceeds 1% of current supply");
                require(_lastTXs[sender] < block.timestamp - 1 minutes, "ERC20: sell happening less than a minute after last tx");

                _balances[sender] = _balances[sender].sub(amount);
                uint tax = amount.div(10);
                uint donation = amount.div(10);
                uint finalAmount = amount.sub(tax).sub(donation);
                _balances[recipient] = _balances[recipient].add(finalAmount);

                _sendToRandomHolder(sender, tax.div(2));
                _sendToRandomHolder(sender, tax.div(2));
                _sendToCharity(sender, donation);

                emit Transfer(sender, recipient, finalAmount);

                _sells[sender] = _sells[sender].add(1);
            } else {
                // buy or transfer
                require(_totalSupply.div(50) >= amount, "ERC20: buy amount exceeds 2% of current supply");

                _balances[sender] = _balances[sender].sub(amount);
                uint tax = amount.div(20);
                uint donation = amount.div(1000).mul(75);
                uint finalAmount = amount.sub(tax).sub(donation);
                _balances[recipient] = _balances[recipient].add(finalAmount);

                _sendToRandomHolder(sender, tax);
                _sendToCharity(sender, donation);

                emit Transfer(sender, recipient, finalAmount);
                
                _lastTXs[recipient] = block.timestamp;
                _addToHolders(recipient);
            }

            // Burn of supply for this transaction
            if (_reserve != address(0)) {
                uint _toBurn = _balances[_reserve].div(1000).mul(_getRandomNumber(3));
                _sendToBurn(_reserve, _toBurn);
            }
        }
    }

    function _sendToRandomHolder(address sender, uint256 amount) private {
        address luckyOne = _getRandomHolder();
        uint luckyAmount = amount.div(_sells[luckyOne].add(1));

        uint toBurn = amount.sub(luckyAmount);

        if (toBurn > 0) {
            _sendToBurn(sender, toBurn);
        }

        _balances[luckyOne] = _balances[luckyOne].add(luckyAmount);
        emit Transfer(sender, luckyOne, luckyAmount);
    }

    function _sendToBurn(address sender, uint256 amount) private {
        if (amount > 0 && _minSupply < _totalSupply) {
            uint newSupply = _totalSupply.sub(amount);
            if (newSupply < _minSupply) {
                newSupply = _minSupply;
            }
            uint toBurn = _totalSupply.sub(newSupply);
            _totalSupply = newSupply;
            emit Transfer(sender, address(0), toBurn);
        }
    }

    function _sendToCharity(address sender, uint256 amount) private {
        if (_charity != address(0)) {
            _balances[_charity] = _balances[_charity].add(amount);
            emit Transfer(sender, _charity, amount);
        } else {
            // charity not set yet? BURN!
            _sendToBurn(sender, amount);
        }
    }

    function _getRandomHolder() private view returns (address) {
        if (_holders.length < 10) {
            return address(0);
        } else {
            return _holders[_getRandomNumber(_holders.length)];
        }
    }

    function _getRandomNumber(uint cap) private view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        return randomHash % cap;
    }

    function _addToHolders(address holder) private {
        if (!_isHolder[holder]) {
            _holders.push(holder);
            _isHolder[holder] = true;
        }
    }

    function _isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}