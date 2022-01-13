/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library Math {
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a & b) + (a ^ b) / 2;
    }

    
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

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

interface IPancakePair {
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

interface IPancakeRouter {
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

interface IERC20 {
    
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

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
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

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract HoneyToken is ERC20, Ownable {

  mapping(address => uint256) minters;

  constructor() ERC20("Honey", "HONEY") {
    _mint(msg.sender, uint256(1e9) * 10 ** uint256(decimals()));
  }

  function addMinter(address _minter) external onlyOwner {
    require(minters[_minter] == 0, "Minter already added");

    minters[_minter] = block.timestamp;
  }

  modifier onlyMinter() {
    require(minters[_msgSender()] > 0 && Address.isContract(_msgSender()), "Caller could be only minter contract");
    _;
  }

  function mint(address _receiver, uint256 _amount) external onlyMinter {
    _mint(_receiver, _amount);
  }

  function burn(uint256 amount) external {
    _burn(_msgSender(), amount);
  }

}

contract Claimable is Ownable {

    address public pendingOwner;

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    function renounceOwnership() public view override(Ownable) onlyOwner {
        revert();
    }

    function transferOwnership(address newOwner) public override(Ownable) onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public virtual onlyPendingOwner {
        transferOwnership(pendingOwner);
        delete pendingOwner;
    }
}

contract BNBeeCraft is Claimable {

    using SafeMath for uint256;

    address public constant PANCAKE_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    uint256 public constant BEES_COUNT = 8;

    struct Player {
        uint256 registeredDate;
        bool airdropCollected;
        address referrer;
        uint256 balanceHoney;
        uint256 balanceWax;
        uint256 points;
        uint256 medals;
        uint256 qualityLevel;
        uint256 lastTimeCollected;
        uint256 unlockedBee;
        uint256[BEES_COUNT] bees;

        uint256 totalDeposited;
        uint256 totalWithdrawed;
        uint256 referralsTotalDeposited;
        uint256 subreferralsCount;
        address[] referrals;
    }

    uint256 public constant SUPER_BEE_INDEX = BEES_COUNT - 1;
    uint256 public constant TRON_BEE_INDEX = BEES_COUNT - 2;
    uint256 public constant MEDALS_COUNT = 10;
    uint256 public constant QUALITIES_COUNT = 6;
    uint256[BEES_COUNT] public BEES_PRICES = [0e18, 1500e18, 7500e18, 30000e18, 75000e18, 250000e18, 750000e18, 100000e18];
    uint256[BEES_COUNT] public BEES_LEVELS_PRICES = [0e18, 0e18, 11250e18, 45000e18, 112500e18, 375000e18, 1125000e18, 0];
    uint256[BEES_COUNT] public BEES_MONTHLY_PERCENTS = [0, 220, 223, 226, 229, 232, 235, 333];
    uint256[MEDALS_COUNT] public MEDALS_POINTS = [0e18, 50000e18, 190000e18, 510000e18, 1350000e18, 3225000e18, 5725000e18, 8850000e18, 12725000e18, 23500000e18];
    uint256[MEDALS_COUNT] public MEDALS_REWARDS = [0e18, 3500e18, 10500e18, 24000e18, 65000e18, 140000e18, 185000e18, 235000e18, 290000e18, 800000e18];
    uint256[QUALITIES_COUNT] public QUALITY_HONEY_PERCENT = [50, 52, 54, 56, 58, 60];
    uint256[QUALITIES_COUNT] public QUALITY_PRICE = [0e18, 15000e18, 50000e18, 120000e18, 250000e18, 400000e18];

    uint256 public constant COINS_PER_BNB = 250000;
    uint256 public constant MAX_BEES_PER_TARIFF = 32;
    uint256 public constant FIRST_BEE_AIRDROP_AMOUNT = 500e18;
    uint256 public constant ADMIN_PERCENT = 10;
    uint256 public constant SUPERBEE_PERCENT_UNLOCK = 5;
    uint256 public constant SUPERBEE_PERCENT_LOCK = 5;
    uint256 public constant SUPER_BEE_BUYER_PERIOD = 7 days;
    uint256[] public REFERRAL_PERCENT_PER_LEVEL = [5, 2, 1, 1, 1];
    uint256[] public REFERRAL_POINT_PERCENT = [50, 25, 0, 0, 0];

    uint256 public maxBalance;
    uint256 public maxBalanceClose;
    uint256 public totalPlayers;
    uint256 public totalDeposited;
    uint256 public totalWithdrawed;
    uint256 public totalBeesBought;
    mapping(address => Player) public players;

    mapping(address => uint256) public ambassadorBonus;

    bool public isSuperBeeUnlocked = false;

    address public honeyTokenContractAddress;
    address public lpTokenContractAddress;

    event Registered(address indexed user, address indexed referrer);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawed(address indexed user, uint256 tokensAmount, uint256 bnbValue);
    event ReferrerPaid(address indexed user, address indexed referrer, uint256 indexed level, uint256 amount);
    event MedalAwarded(address indexed user, uint256 indexed medal);
    event QualityUpdated(address indexed user, uint256 indexed quality);
    event RewardCollected(address indexed user, uint256 honeyReward, uint256 waxReward);
    event BeeUnlocked(address indexed user, uint256 bee);
    event BeesBought(address indexed user, uint256 bee, uint256 count);

    event AddLiquidity(uint256 bnbAmount, uint256 tokensAmount, uint256 deadline);
    event LiquidityAdded(uint256 bnbAmount, uint256 tokensAmount, uint256 liquidity);

    constructor(address _honeyTokenContractAddress, address _lpTokenContractAddress) {
      require(Address.isContract(_honeyTokenContractAddress), "Invalid HONEY token contract address");
      require(Address.isContract(_lpTokenContractAddress), "Invalid HONEY-LP token contract address");

      _register(owner(), address(0));
      players[owner()].balanceWax = 200 ether * COINS_PER_BNB;

      honeyTokenContractAddress = _honeyTokenContractAddress;
      lpTokenContractAddress = _lpTokenContractAddress;
    }

    receive() external payable {
        if (msg.value == 0) {
            if (players[msg.sender].registeredDate > 0) {
                collect();
            }
        } else {
            deposit(address(0));
        }
    }

    function playerBees(address who) public view returns(uint256[BEES_COUNT] memory) {
        return players[who].bees;
    }

    function changeSuperBeeStatus() public returns(bool) {
      if (address(this).balance <= maxBalance.mul(100 - SUPERBEE_PERCENT_UNLOCK).div(100)) {
        isSuperBeeUnlocked = true;
        maxBalanceClose = maxBalance;
      }

      if (address(this).balance >= maxBalanceClose.mul(100 + SUPERBEE_PERCENT_LOCK).div(100)) {
        isSuperBeeUnlocked = false;
      }

      return isSuperBeeUnlocked;
    }

    function referrals(address user) public view returns(address[] memory) {
        return players[user].referrals;
    }

    function referrerOf(address user, address ref) internal view returns(address) {
        if (players[user].registeredDate == 0 && ref != user) {
            return ref;
        }
        return players[user].referrer;
    }

    function transfer(address account, uint256 amount) external onlyOwner {
        collect();

        _payWithWaxOnly(msg.sender, amount);
        players[account].balanceWax = players[account].balanceWax.add(amount);

        
        ambassadorBonus[account] = ambassadorBonus[account].add(bnbValue(amount));
    }

    function deposit(address ref) public payable {
        require(players[ref].registeredDate != 0, "Referrer address should be registered");

        Player storage player = players[msg.sender];
        address refAddress = referrerOf(msg.sender, ref);

        require((msg.value == 0) != player.registeredDate > 0, "Send 0 for registration");

        
        if (player.registeredDate == 0) {
            _register(msg.sender, refAddress);
        }

        collect();

        
        uint256 wax = msg.value.mul(COINS_PER_BNB);
        player.balanceWax = player.balanceWax.add(wax);
        player.totalDeposited = player.totalDeposited.add(msg.value);
        totalDeposited = totalDeposited.add(msg.value);
        player.points = player.points.add(wax);
        emit Deposited(msg.sender, msg.value);

        

        _distributeFees(msg.sender, wax, msg.value, refAddress);

        uint256 adminWithdrawed = players[owner()].totalWithdrawed;
        maxBalance = Math.max(maxBalance, address(this).balance.add(adminWithdrawed));
        if (maxBalance >= maxBalanceClose.mul(100 + SUPERBEE_PERCENT_LOCK).div(100)) {
          isSuperBeeUnlocked = false;
        }
    }

    function withdraw(uint256 amount) public {
        Player storage player = players[msg.sender];

        collect();

        
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(lpTokenContractAddress).getReserves();

        uint256 value = amount.mul(reserve1).div(reserve0);
        require(value > 0, "Trying to withdraw too small");
        
        
        if (player.totalWithdrawed.add(value) > (player.totalDeposited.add(ambassadorBonus[msg.sender])).mul(18).div(10)) {
          value = (player.totalDeposited.add(ambassadorBonus[msg.sender])).mul(18).div(10).sub(player.totalWithdrawed);
          amount = value.mul(reserve0).div(reserve1);
        }

        player.balanceHoney = player.balanceHoney.sub(amount);
        player.totalWithdrawed = player.totalWithdrawed.add(value);
        totalWithdrawed = totalWithdrawed.add(value);
        
        
        HoneyToken(honeyTokenContractAddress).mint(msg.sender, amount);
        emit Withdrawed(msg.sender, amount, value);

        changeSuperBeeStatus();
    }

    function collect() public {
        Player storage player = players[msg.sender];
        require(player.registeredDate > 0, "Not registered yet");

        (uint256 balanceHoney, uint256 balanceWax) = instantBalance(msg.sender);
        emit RewardCollected(
            msg.sender,
            balanceHoney.sub(player.balanceHoney),
            balanceWax.sub(player.balanceWax)
        );

        if (!player.airdropCollected && player.registeredDate < block.timestamp) {
            player.airdropCollected = true;
        }

        player.balanceHoney = balanceHoney;
        player.balanceWax = balanceWax;
        player.lastTimeCollected = block.timestamp;
    }

    function instantBalance(address account)
        public
        view
        returns(
            uint256 balanceHoney,
            uint256 balanceWax
        )
    {
        Player storage player = players[account];
        if (player.registeredDate == 0) {
            return (0, 0);
        }

        balanceHoney = player.balanceHoney;
        balanceWax = player.balanceWax;

        uint256 collected = earned(account);
        if (!player.airdropCollected && player.registeredDate < block.timestamp) {
            collected = collected.sub(FIRST_BEE_AIRDROP_AMOUNT);
            balanceWax = balanceWax.add(FIRST_BEE_AIRDROP_AMOUNT);
        }

        uint256 honeyReward = collected.mul(QUALITY_HONEY_PERCENT[player.qualityLevel]).div(100);
        uint256 waxReward = collected.sub(honeyReward);

        balanceHoney = balanceHoney.add(honeyReward);
        balanceWax = balanceWax.add(waxReward);
    }

    function unlock(uint256 bee) public payable {
        Player storage player = players[msg.sender];

        if (msg.value > 0) {
            deposit(address(0));
        }

        collect();

        require(bee < SUPER_BEE_INDEX, "No more levels to unlock"); 
        require(player.bees[bee - 1] == MAX_BEES_PER_TARIFF, "Prev level must be filled");
        require(bee == player.unlockedBee + 1, "Trying to unlock wrong bee type");

        if (bee == TRON_BEE_INDEX) {
            require(player.medals >= 9);
        }
        _payWithWaxAndHoney(msg.sender, BEES_LEVELS_PRICES[bee]);
        player.unlockedBee = bee;
        player.bees[bee] = 1;
        emit BeeUnlocked(msg.sender, bee);
    }

    function buyBees(uint256 bee, uint256 count) public payable {
        Player storage player = players[msg.sender];

        if (msg.value > 0) {
          deposit(address(0));
        }

        collect();

        require(bee > 0 && bee < BEES_COUNT, "Don't try to buy bees of type 0");
        if (bee == SUPER_BEE_INDEX) {
            require(changeSuperBeeStatus(), "SuperBee is not unlocked yet");
            require(block.timestamp.sub(player.registeredDate) < SUPER_BEE_BUYER_PERIOD, "You should be registered less than 7 days ago");
        } else {
            require(bee <= player.unlockedBee, "This bee type not unlocked yet");
        }

        require(player.bees[bee].add(count) <= MAX_BEES_PER_TARIFF);
        player.bees[bee] = player.bees[bee].add(count);
        totalBeesBought = totalBeesBought.add(count);
        _payWithWaxOnly(msg.sender, BEES_PRICES[bee].mul(count));

        emit BeesBought(msg.sender, bee, count);
    }

    function updateQualityLevel() public {
        Player storage player = players[msg.sender];

        collect();

        require(player.qualityLevel < QUALITIES_COUNT - 1);
        _payWithHoneyOnly(msg.sender, QUALITY_PRICE[player.qualityLevel + 1]);
        player.qualityLevel++;
        emit QualityUpdated(msg.sender, player.qualityLevel);
    }

    function earned(address user) public view returns(uint256) {
        Player storage player = players[user];
        if (player.registeredDate == 0) {
            return 0;
        }

        uint256 total = 0;
        for (uint i = 1; i < BEES_COUNT; i++) {
            total = total.add(
                player.bees[i].mul(BEES_PRICES[i]).mul(BEES_MONTHLY_PERCENTS[i]).div(100)
            );
        }

        return total
            .mul(block.timestamp.sub(player.lastTimeCollected))
            .div(30 days)
            .add(player.airdropCollected || player.registeredDate == block.timestamp ? 0 : FIRST_BEE_AIRDROP_AMOUNT);
    }

    function collectMedals(address user) public {
        Player storage player = players[user];

        collect();

        for (uint i = player.medals; i < MEDALS_COUNT; i++) {
            if (player.points >= MEDALS_POINTS[i]) {
                player.balanceWax = player.balanceWax.add(MEDALS_REWARDS[i]);
                player.medals = i + 1;
                emit MedalAwarded(user, i + 1);
            }
        }
    }

    function claimOwnership() public override(Claimable) {
        super.claimOwnership();
        _register(owner(), address(0));
    }

    function _distributeFees(address user, uint256 wax, uint256 deposited, address refAddress) internal {
        
        payable(owner()).transfer(wax * ADMIN_PERCENT / 100 / COINS_PER_BNB);

        
        if (refAddress != address(0)) {
            Player storage referrer = players[refAddress];
            referrer.referralsTotalDeposited = referrer.referralsTotalDeposited.add(deposited);

            
            address to = refAddress;
            for (uint i = 0; to != address(0) && i < REFERRAL_PERCENT_PER_LEVEL.length; i++) {
                uint256 reward = wax.mul(REFERRAL_PERCENT_PER_LEVEL[i]).div(100);
                
                HoneyToken(honeyTokenContractAddress).mint(to, reward);
                players[to].points = players[to].points.add(wax.mul(REFERRAL_POINT_PERCENT[i]).div(100));
                emit ReferrerPaid(user, to, i + 1, reward);
                

                to = players[to].referrer;
            }
        }
    }

    function _register(address user, address refAddress) internal {
        Player storage player = players[user];

        player.registeredDate = block.timestamp;
        player.bees[0] = MAX_BEES_PER_TARIFF;
        player.unlockedBee = 1;
        player.lastTimeCollected = block.timestamp;
        totalBeesBought = totalBeesBought.add(MAX_BEES_PER_TARIFF);
        totalPlayers++;

        if (refAddress != address(0)) {
            player.referrer = refAddress;
            players[refAddress].referrals.push(user);

            if (players[refAddress].referrer != address(0)) {
                players[players[refAddress].referrer].subreferralsCount++;
            }
        }
        emit Registered(user, refAddress);
    }

    function _payWithHoneyOnly(address user, uint256 amount) internal {
        Player storage player = players[user];
        player.balanceHoney = player.balanceHoney.sub(amount);
    }

    function _payWithWaxOnly(address user, uint256 amount) internal {
        Player storage player = players[user];
        player.balanceWax = player.balanceWax.sub(amount);
    }

    function _payWithWaxAndHoney(address user, uint256 amount) internal returns(uint256) {
        Player storage player = players[user];

        uint256 wax = Math.min(amount, player.balanceWax);
        uint256 honey = amount.sub(wax);

        player.balanceWax = player.balanceWax.sub(wax);
        _payWithHoneyOnly(user, honey);

        return honey;
    }

    function bnbValue(uint256 amount) private view returns(uint256 value) {
      
      (uint256 reserve0, uint256 reserve1, ) = IPancakePair(lpTokenContractAddress).getReserves();

      value = amount.mul(reserve1).div(reserve0);
    }

    function tokensAmount(uint256 value) private view returns(uint256 amount) {
      
      (uint256 reserve0, uint256 reserve1, ) = IPancakePair(lpTokenContractAddress).getReserves();

      amount = value.mul(reserve0).div(reserve1);
    }

    function addLiquidity(uint256 bnbAmount) external onlyOwner {
      uint256 amount = tokensAmount(bnbAmount);

      HoneyToken(honeyTokenContractAddress).mint(address(this), amount);
      HoneyToken(honeyTokenContractAddress).increaseAllowance(PANCAKE_ROUTER_ADDRESS, amount);

      emit AddLiquidity(bnbAmount, amount, block.timestamp + 20 minutes);

      (uint256 amountToken, uint256 amountETH, uint256 liquidity) = IPancakeRouter(PANCAKE_ROUTER_ADDRESS).addLiquidityETH {value: bnbAmount} (
        honeyTokenContractAddress,
        amount,
        amount,
        bnbAmount,
        address(this),
        block.timestamp + 20 minutes
      );

      emit LiquidityAdded(amountETH, amountToken, liquidity);

      
    }

    function deposit() external payable {
      payable(msg.sender).transfer(msg.value);
    }

    

    
    function retrieveTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
      IERC20(_tokenAddress).transfer(owner(), _amount);
    }

    
    function retrieveBNB() external onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
    }

    
    function depHoney(uint256 amount) external {
      players[msg.sender].balanceHoney+= amount * 10**18;
    }

    

}