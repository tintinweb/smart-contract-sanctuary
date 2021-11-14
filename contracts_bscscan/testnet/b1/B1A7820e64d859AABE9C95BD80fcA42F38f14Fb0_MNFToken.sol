/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

   
    function div(int256 a, int256 b) internal pure returns (int256) {
       
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
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

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
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

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);

    
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

interface IBEP20Metadata is IBEP20 {
  
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract BEP20 is Context, IBEP20, IBEP20Metadata {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

   
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface RewardPayingTokenInterface {
   function RewardOf(address _owner) external view returns(uint256);
 function distributeRewards() external payable;

   function withdrawReward() external;

  event RewardsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  event RewardWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

interface RewardPayingTokenOptionalInterface {
  function withdrawableRewardOf(address _owner) external view returns(uint256);

  function withdrawnRewardOf(address _owner) external view returns(uint256);
 function accumulativeRewardOf(address _owner) external view returns(uint256);
}

contract RewardPayingToken is BEP20, RewardPayingTokenInterface, RewardPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedRewardPerShare;
mapping(address => int256) internal magnifiedRewardCorrections;
  mapping(address => uint256) internal withdrawnRewards;

  uint256 public totalRewardsDistributed;

  constructor(string memory _name, string memory _symbol) BEP20(_name, _symbol) {

  }

  receive() external payable {
    distributeRewards();
  }

  function distributeRewards() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedRewardPerShare = magnifiedRewardPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit RewardsDistributed(msg.sender, msg.value);

      totalRewardsDistributed = totalRewardsDistributed.add(msg.value);
    }
  }

  function withdrawReward() public virtual override {
    _withdrawRewardOfUser(payable(msg.sender));
  }

  function _withdrawRewardOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableReward = withdrawableRewardOf(user);
    if (_withdrawableReward > 0) {
      withdrawnRewards[user] = withdrawnRewards[user].add(_withdrawableReward);
      emit RewardWithdrawn(user, _withdrawableReward);
      (bool success,) = user.call{value: _withdrawableReward, gas: 3000}("");

      if(!success) {
        withdrawnRewards[user] = withdrawnRewards[user].sub(_withdrawableReward);
        return 0;
      }

      return _withdrawableReward;
    }

    return 0;
  }


   function RewardOf(address _owner) public view override returns(uint256) {
    return withdrawableRewardOf(_owner);
  }

  function withdrawableRewardOf(address _owner) public view override returns(uint256) {
    return accumulativeRewardOf(_owner).sub(withdrawnRewards[_owner]);
  }

  function withdrawnRewardOf(address _owner) public view override returns(uint256) {
    return withdrawnRewards[_owner];
  }

 function accumulativeRewardOf(address _owner) public view override returns(uint256) {
    return magnifiedRewardPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedRewardCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedRewardPerShare.mul(value).toInt256Safe();
    magnifiedRewardCorrections[from] = magnifiedRewardCorrections[from].add(_magCorrection);
    magnifiedRewardCorrections[to] = magnifiedRewardCorrections[to].sub(_magCorrection);
  }
 function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedRewardCorrections[account] = magnifiedRewardCorrections[account]
      .sub( (magnifiedRewardPerShare.mul(value)).toInt256Safe() );
  }

   function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedRewardCorrections[account] = magnifiedRewardCorrections[account]
      .add( (magnifiedRewardPerShare.mul(value)).toInt256Safe() );
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

library IterableMapping {
    
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

contract MNFRewardTracker is RewardPayingToken, Ownable {
    
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromRewards;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForRewards;

    event ExcludeFromRewards(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() RewardPayingToken("MNF_Reward_Tracker", "MNF_Reward_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForRewards = 10000 * (10**9); 
    }

    function _transfer(address, address, uint256) internal override pure {
        require(false, "MNF_Reward_Tracker: No transfers allowed");
    }

    function withdrawReward() public override  pure {
        require(false, "MNF_Reward_Tracker: withdrawReward disabled. Use the 'claim' function on the main contract.");
    }

    function excludeFromRewards(address account) external onlyOwner {
    	require(!excludedFromRewards[account]);
    	excludedFromRewards[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromRewards(account);
    }

    function includeInRewards(address payable account, uint256 newBalance) external onlyOwner {
    	require(excludedFromRewards[account]);
    	excludedFromRewards[account] = false;

    	if(newBalance >= minimumTokenBalanceForRewards) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
    }
    
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 600 && newClaimWait <= 86400, "MNF_Reward_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "MNF_Reward_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
    
    function updateMinimumTokenBalanceForRewards(uint256 newLimit) external onlyOwner {
        minimumTokenBalanceForRewards = newLimit;
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
            uint256 withdrawableRewards,
            uint256 totalRewards,
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


        withdrawableRewards = withdrawableRewardOf(account);
        totalRewards = accumulativeRewardOf(account);

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
    	if(excludedFromRewards[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForRewards) {
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
        uint256 amount = _withdrawRewardOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}

interface IDEXFactory {
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

interface IIDEXV2Pair {
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

interface IIDEXV2Router01 {
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
interface ILP {
  function sync() external;
}

interface IDEXRouter is IIDEXV2Router01 {
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

contract MNFToken is BEP20, Ownable {
    
    using SafeMath for uint256;

  
uint256 private constant INITIAL_SUPPLY =  10000000   * 10 ** DECIMALS;
  uint256 private constant TOTAL_TOKEN = MAX_UINT256 - (MAX_UINT256 % INITIAL_SUPPLY);
 uint256 private _totalSupply=INITIAL_SUPPLY;
    uint256 public maxTxAmount = INITIAL_SUPPLY;
    uint256 public walletMax = _totalSupply;
    uint256 public swapTokensAtAmount = 45000 * (10**9);

    uint256 public rewardsRate = 7;
    uint256 public liquidityChargesPer = 3;
    uint256 public marketingFee =3;
    uint256 public BuyBackCharges = 2;
   
   
    uint256 public totalFees;
     uint256 private constant DECIMALS = 9;
  uint256 private constant MAX_UINT256 = ~uint256(0);
   
  uint256 private constant Final_SUPPLY = ~uint128(0); 

    uint256 public gasForProcessing = 300000;

    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public isWalletLimitExcept;
    mapping (address => bool) public isTxLimitExcept;
    mapping (address => bool) public _isNotAllowed;
      address public IDEXV2Pair;
    IDEXRouter public IDEXV2Router;
    MNFRewardTracker public RewardTracker;

    address public walletMarket = 0xca9023B5A7f3b18B57e4A9C15Ab2C2a59BB2C9c3;
    address public _walletBack = 0xca9023B5A7f3b18B57e4A9C15Ab2C2a59BB2C9c3;
   
    bool public enableDisableWallet = true;
    mapping (address => bool) public _isAddressLocked;
 uint256 private _TOKENPerFragment;
    bool private swapping;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    event UpdateIDEXV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SendRewards(uint256 tokensSwapped, uint256 amount);
      event RebaseLog(uint256 indexed epoch, uint256 totalSupply);
    event ProcessedRewardTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
address public lp;
  ILP public liquidutyReciever;
  
    constructor() BEP20("MOON FLOKI", "MNF") {

    	RewardTracker = new MNFRewardTracker();
        totalFees = rewardsRate.add(liquidityChargesPer).add(marketingFee).add(BuyBackCharges);

    	IDEXRouter _IDEXV2Router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

         // Create a IDEX pair for this new token
        address _IDEXV2Pair = IDEXFactory(_IDEXV2Router.factory())
            .createPair(address(this), _IDEXV2Router.WETH());

        IDEXV2Router = _IDEXV2Router;
        IDEXV2Pair = _IDEXV2Pair;
    lp = _IDEXV2Pair;
    liquidutyReciever =ILP(_IDEXV2Pair);
        // exclude from receiving Rewards
        

        isWalletLimitExcept[owner()] = true;
        isWalletLimitExcept[IDEXV2Pair] = true;
        isWalletLimitExcept[address(this)] = true;
        
          _TOKENPerFragment = TOTAL_TOKEN.div(_totalSupply);
        isTxLimitExcept[owner()] = true;
        isTxLimitExcept[address(this)] = true;

        // exclude from paying fees or having max transaction amount    
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        RewardTracker.excludeFromRewards(owner());
        RewardTracker.excludeFromRewards(address(this));
        RewardTracker.excludeFromRewards(address(IDEXV2Pair));
        RewardTracker.excludeFromRewards(address(IDEXV2Router));
        RewardTracker.excludeFromRewards(address(RewardTracker));
        RewardTracker.excludeFromRewards(0x000000000000000000000000000000000000dEaD);
        RewardTracker.excludeFromRewards(address(0));
       _mint(msg.sender, _totalSupply);
        
    }

    receive() external payable {}
  
 
  
 function rebaseToken(uint256 epoch, int256 supplyDelta)
  external
  onlyOwner
  returns (uint256)
  {
    if (supplyDelta == 0) {
      emit RebaseLog(epoch, _totalSupply);
      return _totalSupply;
    }

    if (supplyDelta < 0) {
      _totalSupply = _totalSupply.sub(uint256(- supplyDelta));
    } else {
      _totalSupply = _totalSupply.add(uint256(supplyDelta));
    }

    if (_totalSupply > Final_SUPPLY) {
      _totalSupply = Final_SUPPLY;
    }

    _TOKENPerFragment = TOTAL_TOKEN.div(_totalSupply);
    liquidutyReciever.sync();

    emit RebaseLog(epoch, _totalSupply);
    return _totalSupply;
  }
    function updateFees(uint256 newRewardFee, uint256 newLiqFee, uint256 newMarketingFee, uint256 newBuyBackCharges) public onlyOwner {
        rewardsRate = newRewardFee;
        liquidityChargesPer = newLiqFee;
        marketingFee = newMarketingFee;
        BuyBackCharges = newBuyBackCharges;
       
        
        totalFees = rewardsRate.add(liquidityChargesPer).add(marketingFee).add(BuyBackCharges);
    }
    
    function changeIsRewardExcept(address holder, bool Except) external onlyOwner {
        if(Except){
            RewardTracker.excludeFromRewards(holder);
        }else{
             try RewardTracker.includeInRewards(payable(holder), balanceOf(holder)) {} catch {}
        }
    }

    function changeIsTxLimitExcept(address holder, bool Except) external onlyOwner {
        isTxLimitExcept[holder] = Except;
    }

    function setMarketingWallet(address wallet) public onlyOwner {
        walletMarket = payable(wallet);
    }
    
    function setwalletBack(address wallet) public onlyOwner {
        _walletBack = payable(wallet);
    }
    
   
    function updateIDEXV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(IDEXV2Router), "MNF: The router already has that address");
        emit UpdateIDEXV2Router(newAddress, address(IDEXV2Router));
        IDEXV2Router = IDEXRouter(newAddress);
    }

    function blacklistAddress(address account, bool value) public onlyOwner {
        _isNotAllowed[account] = value;
    }
    
    function updateLockStatus(address[] calldata addressList, bool value) public onlyOwner {
        for (uint8 i = 0; i < addressList.length; i++) {
			_isAddressLocked[addressList[i]] = value;
		}
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "MNF: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 750000, "MNF: gasForProcessing must be between 200,000 and 750,000");
        require(newValue != gasForProcessing, "MNF: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        RewardTracker.updateClaimWait(claimWait);
    }

    function updateMinimumTokenBalanceForRewards(uint256 claimWait) external onlyOwner {
        RewardTracker.updateMinimumTokenBalanceForRewards(claimWait);
    }

    function getDistributionSettings() external view returns(uint256, uint256) {
        return (RewardTracker.claimWait(), RewardTracker.minimumTokenBalanceForRewards());
    }

    function getTotalRewardsDistributed() external view returns (uint256) {
        return RewardTracker.totalRewardsDistributed();
    }

    function withdrawableRewardOf(address account) public view returns(uint256) {
    	return RewardTracker.withdrawableRewardOf(account);
  	}

	function RewardTokenBalanceOf(address account) public view returns (uint256) {
		return RewardTracker.balanceOf(account);
	}

	function processRewardTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = RewardTracker.process(gas);
		emit ProcessedRewardTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		RewardTracker.processAccount(payable(msg.sender), false);
    }

    function setMaxTxAMount(uint256 amount) external onlyOwner{
        maxTxAmount = amount;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        walletMax  = newLimit;
    }

    function enableDisableWalletMax(bool newValue) external onlyOwner {
       enableDisableWallet = newValue;
    }

    function changeIsWalletLimitExcept(address holder, bool Except) external onlyOwner {
        isWalletLimitExcept[holder] = Except;
    }

    function changeSwapBackSettings(bool enableSwapBack, bool swapByLimitOnly, uint256 newSwapBackLimit) external onlyOwner {
        swapAndLiquifyByLimitOnly = swapByLimitOnly;
        swapTokensAtAmount = newSwapBackLimit;
        
        if(swapAndLiquifyEnabled != enableSwapBack)
        {
            swapAndLiquifyEnabled = enableSwapBack;
            emit SwapAndLiquifyEnabledUpdated(enableSwapBack);
        }
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function _transfer(address from, address to, uint256 amount ) internal override {
        
        require(to != address(0), "BEP20: transfer to the zero address");
        require(from != address(0), "BEP20: transfer from the zero address");
        require(!_isNotAllowed[from] && !_isNotAllowed[to], "To/from address is blacklisted!");
        
        if(_isAddressLocked[from]) {
            require(_isExcludedFromFees[to], "Tokens Locked!");
        }
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }    

        if(!isTxLimitExcept[from] && !isTxLimitExcept[to] && !swapping) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if(enableDisableWallet && !isWalletLimitExcept[to]){
            require(balanceOf(to).add(amount) <= walletMax, "Wallet limit reached");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if(swapAndLiquifyEnabled &&  totalFees > 0 && contractTokenBalance >= swapTokensAtAmount && !swapping && from != IDEXV2Pair) { 
            if(swapAndLiquifyByLimitOnly)
                contractTokenBalance = swapTokensAtAmount;
                
            swapBack(contractTokenBalance); 
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee && totalFees > 0) {
        	uint256 fees = amount.mul(totalFees).div(100);

            
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try RewardTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try RewardTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try RewardTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedRewardTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {}
        }
    }
    
    function swapBack(uint256 tokensToLiquify) internal lockTheSwap {

        uint256 tRewards = tokensToLiquify.mul(rewardsRate).div(totalFees);
        uint256 tokensToLP = tokensToLiquify.mul(liquidityChargesPer).div(totalFees).div(2);
        uint256 amountToSwap = tokensToLiquify.sub(tokensToLP);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IDEXV2Router.WETH();

        _approve(address(this), address(IDEXV2Router), tokensToLiquify);
        IDEXV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        uint256 bnbBalance = address(this).balance;
        uint256 bnbFeeFactor = totalFees.sub(liquidityChargesPer.div(2));
        
        uint256 bnbForLiquidity = bnbBalance.mul(liquidityChargesPer).div(bnbFeeFactor).div(2);
        uint256 bnbForReflection = bnbBalance.mul(rewardsRate).div(bnbFeeFactor);
        uint256 bnbForMNFBuyBack = bnbBalance.mul(BuyBackCharges).div(bnbFeeFactor);
      
        uint256 bnbForMarketing = bnbBalance.sub(bnbForLiquidity).sub(bnbForReflection).sub(bnbForMNFBuyBack);

        if(tokensToLP > 0 && bnbForLiquidity > 0)    
            addLiquidity(tokensToLP, bnbForLiquidity);
    
        if(bnbForMarketing > 0)    
            payable(walletMarket).transfer(bnbForMarketing);
        
        if(bnbForMNFBuyBack > 0)    
            payable(_walletBack).transfer(bnbForMNFBuyBack);
        
       
        if(bnbForReflection > 0) 
        {
            (bool success,) = address(RewardTracker).call{value: bnbForReflection}("");
            
            if(success) {
       	 		emit SendRewards(tRewards, bnbForReflection);
            }
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // add the liquidity
        IDEXV2Router.addLiquidityETH{value: ethAmount}(
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