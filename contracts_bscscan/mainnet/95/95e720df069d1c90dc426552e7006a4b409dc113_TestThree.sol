/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library SignedSafeMath {

    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

library SafeCast {
    
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

interface IUniswapV2Factory {
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
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
        return 18;
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
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        _previousOwner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
        _previousOwner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
    
    function lockOwnership(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlockOwnership() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(_owner == address(0), "The owner isn't the burn address");
        require(block.timestamp > _lockTime, "Contract is still locked");
        _owner = _previousOwner;
        _previousOwner = address(0);
        emit OwnershipTransferred(_owner, _previousOwner);
    }
}

interface RewardPayingTokenOptionalInterface {
  function withdrawableRewardOf(address _owner) external view returns(uint256);
  function withdrawnRewardOf(address _owner) external view returns(uint256);
  function accumulativeRewardOf(address _owner) external view returns(uint256);
}

interface RewardPayingTokenInterface {
  function rewardOf(address _owner) external view returns(uint256);
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

contract RewardPayingToken is ERC20, RewardPayingTokenInterface, RewardPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SignedSafeMath for int256;
  using SafeCast for uint256;
  using SafeCast for int256;

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedRewardPerShare;

  mapping(address => int256) internal magnifiedRewardCorrections;
  mapping(address => uint256) internal withdrawnRewards;

  uint256 public totalRewardsDistributed;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

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

  function rewardOf(address _owner) public view override returns(uint256) {
    return withdrawableRewardOf(_owner);
  }

  function withdrawableRewardOf(address _owner) public view override returns(uint256) {
    return accumulativeRewardOf(_owner).sub(withdrawnRewards[_owner]);
  }

  function withdrawnRewardOf(address _owner) public view override returns(uint256) {
    return withdrawnRewards[_owner];
  }

  function accumulativeRewardOf(address _owner) public view override returns(uint256) {
    return magnifiedRewardPerShare.mul(balanceOf(_owner)).toInt256()
      .add(magnifiedRewardCorrections[_owner]).toUint256() / magnitude;
  }

  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedRewardPerShare.mul(value).toInt256();
    magnifiedRewardCorrections[from] = magnifiedRewardCorrections[from].add(_magCorrection);
    magnifiedRewardCorrections[to] = magnifiedRewardCorrections[to].sub(_magCorrection);
  }

  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedRewardCorrections[account] = magnifiedRewardCorrections[account]
      .sub( (magnifiedRewardPerShare.mul(value)).toInt256() );
  }

  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedRewardCorrections[account] = magnifiedRewardCorrections[account]
      .add( (magnifiedRewardPerShare.mul(value)).toInt256() );
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

contract TestThreeRewardTracker is RewardPayingToken, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    
    uint256 public lastProcessedIndex;
    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForRewards;

    address[] private arrayExcludedFromRewards;

    mapping (address => bool) public excludedFromRewards;
    mapping (address => uint256) public lastClaimTimes;

    event ExcludeFromRewards(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() RewardPayingToken("TestThree_Reward_Tracker", "TestThree_Reward_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForRewards = 10000 * (10**18); 
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "TestThree_Reward_Tracker: No transfers allowed");
    }

    function withdrawReward() public pure override {
        require(false, "TestThree_Reward_Tracker: withdrawReward disabled. Use the 'claim' function on the main TestThree contract.");
    }

    function excludeFromRewards(address account) external onlyOwner {
    	require(!excludedFromRewards[account]);
    	excludedFromRewards[account] = true;
        arrayExcludedFromRewards.push(account);
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromRewards(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "TestThree_Reward_Tracker: claimWait must be updated to between 1 and 24 hours");	
        require(newClaimWait != claimWait, "TestThree_Reward_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    
    function getAddressFromExcludedFromRewardsAt(uint256 index) public view returns(address) {
        return arrayExcludedFromRewards[index];    
    }
    
    function getNumberOfExcludedFromRewards() public view returns(uint256) {
        return arrayExcludedFromRewards.length;    
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

contract TestThree is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool private inSwapAndLiquify;
    
  	bool public tradingEnable = false;
    bool public swapAndLiquifyEnabled = true;

    TestThreeRewardTracker public rewardTracker;

    uint256 public maxSellTransactionAmount = 100000000 * (10**18);
    uint256 public maxTestThreePerWallet = 100000000 * (10**18);
    uint256 public swapTokensAtAmount = 1000000 * (10**18);
    
    uint256 public teamFee;
    uint256 public holderRewardFee;
    uint256 public liquidityFee;
    uint256 public extraFeeOnSell;
    uint256 public totalFees;

    address payable teamWallet;

    uint256 public gasForProcessing = 500000;

    mapping (address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTokens;
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetFees(uint256 newRewardFee, uint256 newLiquidityFee, uint256 newTeamFee);
    event SetSellFee(uint256 newSellFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    
    event UpdateRewardTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensIntoLiqudity,
        uint256 ethReceived
    );

    event SendRewards(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedRewardTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    modifier open(address from, address to) {
        require(tradingEnable, "Not Open");
        _;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20("TestThree", "TestThree") {
        holderRewardFee = 3;
        liquidityFee = 2;
        teamFee = 7;
        
        extraFeeOnSell = 0; 

        teamWallet = payable(0xa3089EeEdF7d7Ba59684835425a9B84E52B0844A);

        totalFees = holderRewardFee.add(liquidityFee).add(teamFee);

    	rewardTracker = new TestThreeRewardTracker();

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        rewardTracker.excludeFromRewards(address(this));
        rewardTracker.excludeFromRewards(address(rewardTracker));
        rewardTracker.excludeFromRewards(address(_uniswapV2Router));
        rewardTracker.excludeFromRewards(0x0000000000000000000000000000000000000000);
        rewardTracker.excludeFromRewards(0x000000000000000000000000000000000000dEaD);

        excludeFromFees(owner(), true);
        excludeFromFees(teamWallet, true);
        excludeFromFees(address(this), true);
        
        _isExcludedFromMaxTokens[owner()] = true;
        _isExcludedFromMaxTokens[teamWallet] = true;
        _isExcludedFromMaxTokens[address(this)] = true;
        
        _mint(owner(), 100000000 * (10**18));
    }
    
    receive() external payable {}

    
    function setFees(uint256 _bnbRewardFee, uint256 _liquidityFee, uint256 _teamFee) public onlyOwner {
        holderRewardFee = _bnbRewardFee;
        liquidityFee = _liquidityFee;
        teamFee = _teamFee;
        totalFees = holderRewardFee.add(liquidityFee).add(teamFee); 
        emit SetFees(_bnbRewardFee, _liquidityFee, _teamFee);
    }

    function setExtraFeeOnSell(uint256 _extraFeeOnSell) public onlyOwner {
        extraFeeOnSell = _extraFeeOnSell; 
        emit SetSellFee(_extraFeeOnSell);
    }

    function setMaxSellTestThrees(uint256 _maxSellTokensAmount) public onlyOwner {
        maxSellTransactionAmount = _maxSellTokensAmount * (10 ** 18);
    }
    
    function setMaxTestThreePerWallet(uint256 maxTokensPerWallet) external onlyOwner {
  	    maxTestThreePerWallet = maxTokensPerWallet * (10**18);
  	}
    
    function enableTrading() external onlyOwner {
        tradingEnable = true;
    }
    
    function updateRewardTracker(address newAddress) public onlyOwner {
        require(newAddress != address(rewardTracker), "TestThree: The reward tracker already has that address");

        TestThreeRewardTracker newRewardTracker = TestThreeRewardTracker(payable(newAddress));

        require(newRewardTracker.owner() == address(this), "TestThree: The new reward tracker must be owned by the TestThree token contract");
        
        uint256 numberOfExcludedFromRewards = rewardTracker.getNumberOfExcludedFromRewards();
    	uint256 index = 0;
    	
        while(index < numberOfExcludedFromRewards) {
            address excludedAddress = rewardTracker.getAddressFromExcludedFromRewardsAt(index);
            newRewardTracker.excludeFromRewards(excludedAddress);
            index++;
        }
        newRewardTracker.excludeFromRewards(newAddress);
        
        emit UpdateRewardTracker(newAddress, address(rewardTracker));

        rewardTracker = newRewardTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "TestThree: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "TestThree: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function setExcludeFromMaxTokens(address _address, bool value) public onlyOwner { 
        _isExcludedFromMaxTokens[_address] = value;
    }
    
    function setTeamWallet(address payable _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function setExcludeFromAll(address _address) public onlyOwner {
        _isExcludedFromMaxTokens[_address] = true;
        _isExcludedFromFees[_address] = true;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "TestThree: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
     
    function setSWapTokensAtAmount(uint256 _newAmount) public onlyOwner {
        swapTokensAtAmount = _newAmount * (10 ** 18);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "TestThree: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            rewardTracker.excludeFromRewards(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 700000, "TestThree: gasForProcessing must be between 200,000 and 700,000");
        require(newValue != gasForProcessing, "TestThree: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        rewardTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return rewardTracker.claimWait();
    }

    function getTotalRewardsDistributed() external view returns (uint256) {
        return rewardTracker.totalRewardsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function isExcludedFromMaxTokens(address account) public view returns(bool) {
        return _isExcludedFromMaxTokens[account];
    }

    function withdrawableRewardOf(address account) public view returns(uint256) {
    	return rewardTracker.withdrawableRewardOf(account);
  	}

	function rewardTokenBalanceOf(address account) public view returns (uint256) {
		return rewardTracker.balanceOf(account);
	}

    function getAccountRewardsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return rewardTracker.getAccount(account);
    }

	function getAccountRewardsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return rewardTracker.getAccountAtIndex(index);
    }

	function processRewardTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = rewardTracker.process(gas);
		emit ProcessedRewardTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		rewardTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return rewardTracker.getLastProcessedIndex();
    }

    function getNumberOfRewardTokenHolders() external view returns(uint256) {
        return rewardTracker.getNumberOfTokenHolders();
    }

    function excludeFromRewards(address account) external onlyOwner {
        rewardTracker.excludeFromRewards(account);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) open(from, to) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            to != uniswapV2Pair
        ) {

            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= maxTestThreePerWallet,
                "Exceeds maximum wallet token amount."
            );
            
        }

        if(automatedMarketMakerPairs[to] && (!_isExcludedFromMaxTokens[from]) && (!_isExcludedFromMaxTokens[to])){
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

    	uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;
       
        if(
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !automatedMarketMakerPairs[from] && 
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
        	uint256 fees = (amount*totalFees)/100;
            uint256 extraFee;

            if(automatedMarketMakerPairs[to]) {
                extraFee =(amount*extraFeeOnSell)/100;
                fees=fees+extraFee;
            }
        	amount = amount-fees;
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try rewardTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try rewardTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!inSwapAndLiquify) {
	    	uint256 gas = gasForProcessing;

	    	try rewardTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedRewardTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {

	    	}
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 tokensToAddLiquidityWith = contractTokenBalance.div(totalFees.mul(2)).mul(liquidityFee);
 
        uint256 toSwap = contractTokenBalance-tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForBnb(toSwap, address(this)); 

        uint256 deltaBalance = address(this).balance-initialBalance;

        uint256 bnbToAddLiquidityWith = deltaBalance.mul(liquidityFee).div(totalFees.mul(2).sub(liquidityFee));
        
        addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);

        uint256 teamAmount = deltaBalance.sub(bnbToAddLiquidityWith).div(totalFees.sub(liquidityFee)).mul(teamFee);
        teamWallet.transfer(teamAmount);

        uint256 rewards = address(this).balance;
        (bool success,) = address(rewardTracker).call{value: rewards}("");

        if(success) {
   	 		emit SendRewards(toSwap-tokensToAddLiquidityWith, rewards);
        }
        
        emit SwapAndLiquify(tokensToAddLiquidityWith, deltaBalance);
    }

    function swapTokensForBnb(uint256 tokenAmount, address _to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if(allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
          _approve(address(this), address(uniswapV2Router), ~uint256(0));
        }

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _to,
            block.timestamp
        );
        
    }

    function swapAndSendBNBToTeam(uint256 tokenAmount) private {
        swapTokensForBnb(tokenAmount, teamWallet);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(), 
            block.timestamp
        );
    }
    
}