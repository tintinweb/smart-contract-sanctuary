/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity 0.8.5;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/OpenZeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    
    uint256 private _cap = 21000000 *10**18;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(_totalSupply < _cap, "ERC20: No more mint");
        require(account != address(0), "ERC20: mint to the zero address");
        
        if (_totalSupply.add(amount) > _cap) {
            uint256 lastMintAmount = _cap.sub(_totalSupply);
            
            _beforeTokenTransfer(address(0), account, lastMintAmount);
            
            _totalSupply = _totalSupply.add(lastMintAmount);
            _balances[account] = _balances[account].add(lastMintAmount);
            emit Transfer(address(0), account, lastMintAmount);
        }
        
        if (_totalSupply.add(amount) <= _cap) {
            
            _beforeTokenTransfer(address(0), account, amount);
            
            _totalSupply = _totalSupply.add(amount);
            _balances[account] = _balances[account].add(amount);
            emit Transfer(address(0), account, amount);
        }
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountETH);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface Token {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external returns (uint256);
}

contract Earn_Finance is ERC20, Ownable {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    mapping (address => bool) public minters;
    
    bool public canAddMinter = true;
    
    event SwapedTokenForEth(uint256 EthAmount, uint256 TokenAmount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event RewardsTransferred(address holder, uint256 amount);
    
    constructor() ERC20("Earn-Finance", "EARN") {
        _mint(msg.sender, 2000000 *10**18); // Team Token..
        
        minters[address(this)] = true;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         //@dev Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
    }

    function approveFrom(address owner, address spender, uint256 amount) public onlyMinter {
        _approve(owner, spender, amount);
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the Minter.
    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }
    
    function burn(uint amount) public {
        require(amount > 0);
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
    }

    function addMinter(address account) public onlyOwner {
        require(canAddMinter, "No more minter");
        minters[account] = true;
    }
    
    function StopAddingMinter() public onlyOwner {
        canAddMinter = false;
    }

    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Restricted to minters.");
        _;
    }
    
    function swapAndLiquify(address _to, uint256 TokenBalance) public onlyMinter {
        // split the contract balance into halves
        uint256 half = TokenBalance.div(2);
        uint256 otherHalf = TokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(_to, half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }
    
    function swapTokensForEth(address _to, uint256 tokenAmount) public onlyMinter {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _to,
            block.timestamp
        );
    }
    
    // function allow owner to transfer ETH from this address.
    function transferETH(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
    }
    
    // function to allow admin to claim ERC20 tokens from this contract..
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: amount must be greater than 0");
        require(recipient != address(0), "ERC20: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
    
    receive() external payable {}
}

contract Earn_Finance_Pool_1 is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsTransferred(address holder, uint256 amount);
    
    // Earn/ETH LP token contract address
    address public LPtokenAddress;
    address public devAddress;
    
    // reward rate 300 % per year
    uint256 public rewardRate = 30000;
    uint256 public devFee = 1000;
    
    // reward interval 365 days
    uint256 public rewardInterval = 365 days;
    
    // unstaking possible after 0 days
    uint256 public cliffTime = 0 days;
    
    uint256 public totalClaimedRewards;
    uint256 public totalDevFee;
    
    uint256 private stakingAndDaoTokens = 19000000 *10**18; // Maximum token amount can be farmed.
    
    bool public farmEnabled = false;
    
    EnumerableSet.AddressSet private holders;
    Earn_Finance public EARN;
    
    mapping (address => uint256) public depositedTokens;
    mapping (address => uint256) public TotalLPDeposited;
    mapping (address => uint256) public stakingTime;
    mapping (address => uint256) public lastClaimedTime;
    mapping (address => uint256) public totalEarnedTokens;
    
    constructor (Earn_Finance _EARN, address _LPtokenAddress, address _devAddress) {
        EARN = _EARN;
        LPtokenAddress = _LPtokenAddress;
        devAddress = _devAddress;
    }
    
    function updateAccount(address account) private {
        uint256 pendingDivs = getPendingDivs(account);
        uint256 _devFee = pendingDivs.mul(devFee).div(1e4);
        
        if (pendingDivs > 0) {
            EARN.mint(address(EARN), pendingDivs);
            
            EARN.swapTokensForEth(account, pendingDivs);
            
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(address(EARN), pendingDivs);
        }
        
        if (_devFee > 0) {
            EARN.mint(address(EARN), _devFee);
            EARN.swapTokensForEth(devAddress, _devFee);
            totalDevFee = totalDevFee.add(_devFee);
            emit RewardsTransferred(address(EARN), _devFee);
        }
        
        lastClaimedTime[account] = block.timestamp;
    }
    
    function getPendingDivs(address _holder) public view returns (uint256 _pendingDivs) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;
        
        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 stakedAmount = depositedTokens[_holder];
        
        uint256 pendingDivs = stakedAmount.mul(rewardRate).mul(timeDiff).div(rewardInterval).div(1e4);
        
        return pendingDivs;
    }
    
    function getNumberOfHolders() public view returns (uint256) {
        return holders.length();
    }
    
    function deposit(uint256 amountToStake) public {
        require(farmEnabled, "Farming not enabled yet");
        
        uint256 currentLPBalance = Token(LPtokenAddress).balanceOf(address(this));
        
        EARN.approveFrom(msg.sender, address(this), amountToStake);
        
        EARN.transferFrom(msg.sender, address(EARN), amountToStake);
        
        EARN.swapAndLiquify(address(EARN), amountToStake);
        
        uint256 newBalance = Token(LPtokenAddress).balanceOf(address(this)).sub(currentLPBalance);
        
        updateAccount(msg.sender);
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToStake);
        TotalLPDeposited[msg.sender] = TotalLPDeposited[msg.sender].add(newBalance);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = block.timestamp;
        }
    }
    
    // function to allow users to withdraw deposited LP from this...
    function emergencyWithdraw() public {
        
        require(block.timestamp.sub(stakingTime[msg.sender]) > cliffTime, "You recently staked, please wait before withdrawing.");
        
        Token(LPtokenAddress).transfer(msg.sender, TotalLPDeposited[msg.sender]);
        
        TotalLPDeposited[msg.sender] = 0;
        
        holders.remove(msg.sender);
    }
    
    function withdraw(uint256 amount) public {
        require(depositedTokens[msg.sender] >= amount, "Invalid amount to withdraw");
        uint256 totalLPDeposited = TotalLPDeposited[msg.sender];
        uint256 totalEARNDeposited = depositedTokens[msg.sender];
        
        uint256 amountToWithdraw = totalLPDeposited.mul(amount).div(totalEARNDeposited);
        
        require(block.timestamp.sub(stakingTime[msg.sender]) > cliffTime, "You recently staked, please wait before withdrawing.");
        
        updateAccount(msg.sender);
        
        Token(LPtokenAddress).transfer(msg.sender, amountToWithdraw);
        
        TotalLPDeposited[msg.sender] = TotalLPDeposited[msg.sender].sub(amountToWithdraw);
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amount);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function claimDivs() public {
        updateAccount(msg.sender);
    }
    
    function getStakingAndDaoAmount() public view returns (uint256) {
        if (totalClaimedRewards >= stakingAndDaoTokens) {
            return 0;
        }
        uint256 remaining = stakingAndDaoTokens.sub(totalClaimedRewards);
        return remaining;
    }
    
    // function to allow admin to set dev address..
    function setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }
    
    // function to allow admin to set Earn_Finance token address..
    function setEARNAddress(Earn_Finance _earnAddress) public onlyOwner {
        require(!farmEnabled, "Farm enabled, you cannot change EARN address");
        EARN = _earnAddress;
    }
    
    // function to allow admin to set LP token address..
    function setLPTokenAddress(address _LPtokenAddress) public onlyOwner {
        require(!farmEnabled, "Farm enabled, you cannot change LP address");
        LPtokenAddress = _LPtokenAddress;
    }
    
    // function to allow admin to set dev fee percentage..
    function setDevFeePercent(uint256 _percent) public onlyOwner {
        devFee = _percent;
    }
    
    // function to allow admin to set cliff time..
    function setCliffTime(uint256 _time) public onlyOwner {
        cliffTime = _time;
    }
    
    // function to allow admin to set reward interval..
    function setRewardInterval(uint256 _rewardInterval) public onlyOwner {
        rewardInterval = _rewardInterval;
    }
    
    // function to allow admin to set staking and dao tokens amount..
    function setStakingAndDaoTokens(uint256 _stakingAndDaoTokens) public onlyOwner {
        stakingAndDaoTokens = _stakingAndDaoTokens;
    }
    
    // function to allow admin to set reward rate..
    function setRewardRate(uint256 _rewardRate) public onlyOwner {
        rewardRate = _rewardRate;
    }
    
     // function to allow admin to enable farming..
    function enableFarm() external onlyOwner() {
        farmEnabled = true;
    }
    
    // function to allow admin to claim ERC20 tokens from this contract..
    function transferAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        require(_tokenAddress != LPtokenAddress);
        
        Token(_tokenAddress).transfer(_to, _amount);
    }
}