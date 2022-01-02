/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// Set standard token interface
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
// Add SafeMath Library
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
// Add Address Library
library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
// Set Ownable contract properties
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
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
// Set up PancakeSwap Interface
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
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
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
// Main Contract Information
contract SpooderToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address payable private marketingWallet = payable(0x7F1891232816666bAdF326f8cBE70964522557E8); // Marketing Wallet
    address payable private ecosystemWallet = payable(0xc3aD2641e14E0D87F29f6c1cAC5579B502bc511e); // Ecosystem Wallet
    address payable private devWallet = payable (0xC090B6CA99FBc9C2CF2ff96916124969f33D8E92); // dev Wallet
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) public _stakingBalance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isSniper;
    
    uint256 public deadBlocks = 2;
    uint256 public launchedAt = 0;
    

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isMaxWalletExempt;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isTrusted;
    address[] private _excluded;
    mapping (address => bool) internal authorizations;
   
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint8 private _decimals = 18;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Spooder-V2";
    string private _symbol = "SPOOD-V2";

    uint256 public _maxWalletToken = _tTotal.div(100).mul(10); //10% for first few mins

    uint256 public _buyLiquidityFee = 20; //2%
    uint256 public _buyDevFee = 2;     //0% 
    uint256 public _buyMarketingFee = 30;   //3%
    uint256 public _buyReflectionFee = 0;   //0%

    uint256 public _sellLiquidityFee = 20; //2%
    uint256 public _sellDevFee = 2;   //0%
    uint256 public _sellMarketingFee = 30;  //3%
    uint256 public _sellReflectionFee = 0;   //0%
    
    uint256 private ecosystemFee = 0;   //2% same for buys and sells
    uint256 private stakeFee = 20;   //2% same for buys and sells
    uint256 private liquidityFee = _buyLiquidityFee;
    uint256 private marketingFee = _buyMarketingFee;
    uint256 private devFee = _buyDevFee;
    uint256 private reflectionFee=_buyReflectionFee;

    
    uint public totalStaked = 0;
    address[] public userStaked;
    address public user;
    uint public userReward;
    uint public rewardVectorLength = 0;


    uint256 private totalFee = liquidityFee.add(marketingFee).add(devFee).add(ecosystemFee);
    uint256 private currenttotalFee = totalFee;
    
    uint256 public swapThreshold = _tTotal.div(10000).mul(5); //0.05%
   
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwap;
    
    bool public tradingOpen = false;
    
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event Stake(address indexed from, uint value);
    event UnStake(address indexed to, uint value);
    event UpdateRewards(uint value);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        // Initialize PancakeSwap
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        // Initialize Fee, Max Wallet, and Trusted Exemptions
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isMaxWalletExempt[owner()] = true;
        _isMaxWalletExempt[address(this)] = true;
        _isMaxWalletExempt[uniswapV2Pair] = true;
        _isMaxWalletExempt[DEAD] = true;
        _isTrusted[owner()] = true;
        _isTrusted[uniswapV2Pair] = true;
        authorizations[msg.sender] = true;
        
        // Add staking rewards from V1
        _stakingBalance[0xB28f13732211f3F3Fdadb2FD656F29Ca2739f989] = 496214622324464479026659;
        userStaked.push(0xB28f13732211f3F3Fdadb2FD656F29Ca2739f989);
        _stakingBalance[0xB13D8215c1935A27aD70F18b19b6E467a5F9bCE2] = 46617967420057055181449;
        userStaked.push(0xB13D8215c1935A27aD70F18b19b6E467a5F9bCE2);
        _stakingBalance[0xC0934648310f31ED0ECad69108B54F9eD7b10E28] = 61132218040563105763049;
        userStaked.push(0xC0934648310f31ED0ECad69108B54F9eD7b10E28);
        _stakingBalance[0xA422F0Db3b2f8F69C351788fbe7cb7F529264E8a] = 326245581737620017745409;
        userStaked.push(0xA422F0Db3b2f8F69C351788fbe7cb7F529264E8a);
        _stakingBalance[0x84E64a46a76347e26A10d05a565481f50CcF2F63] = 678829076148452212448060;
        userStaked.push(0x84E64a46a76347e26A10d05a565481f50CcF2F63);
        _stakingBalance[0x7465756A8A250E4483a91824d8146Cc19dFC63c9] = 2162127601824164279418203;
        userStaked.push(0x7465756A8A250E4483a91824d8146Cc19dFC63c9);
        _stakingBalance[0x418Cf9774F74ef3D0d90a99bf5Bc8058aA5d3269] = 46853680525400256580517;
        userStaked.push(0x418Cf9774F74ef3D0d90a99bf5Bc8058aA5d3269);
        _stakingBalance[0x9101cae444ACEE5CA72F0B0d67eb9DB4b1a85ce2] = 10804770335273602709166;
        userStaked.push(0x9101cae444ACEE5CA72F0B0d67eb9DB4b1a85ce2);
        _stakingBalance[0x7339102C251D2BA507B7D8e9356a18A24B154E35] = 721688827053107506;
        userStaked.push(0x7339102C251D2BA507B7D8e9356a18A24B154E35);
        _stakingBalance[0xE2e177cc0Ad424170e000d49b1C369Cd3f52b5D4] = 380509885328351506;
        userStaked.push(0xE2e177cc0Ad424170e000d49b1C369Cd3f52b5D4);
        _stakingBalance[0xbD89f3D00d2A140F79B01131faA05b2C4B2070E1] = 84934563915144342220919;
        userStaked.push(0xbD89f3D00d2A140F79B01131faA05b2C4B2070E1);
        _stakingBalance[0x9E98E1B298DE4fE801f538De6f5b46C4BA9b36d4] = 54373169999229830936505;
        userStaked.push(0x9E98E1B298DE4fE801f538De6f5b46C4BA9b36d4);
        _stakingBalance[0x84E64a46a76347e26A10d05a565481f50CcF2F63] = 678829076148452212448060;
        userStaked.push(0x84E64a46a76347e26A10d05a565481f50CcF2F63);
        _stakingBalance[0xE445DD24520B44E8bf07fd3820d8B4960fF3eCF1] = 10616539991077113777843;
        userStaked.push(0xE445DD24520B44E8bf07fd3820d8B4960fF3eCF1);
        _stakingBalance[0xC56479459905d63b6794B535afa9c0143D01c979] = 10616518633969109006129;
        userStaked.push(0xC56479459905d63b6794B535afa9c0143D01c979);
        _stakingBalance[0x33D106599E243E94E836a6002F621E02FCb05AaE] = 10616497279332207794073;
        userStaked.push(0x33D106599E243E94E836a6002F621E02FCb05AaE);
        _stakingBalance[0x602471d709Be89bd38b39c03eaf544085C4Bb107] = 449955252420712091003533;
        userStaked.push(0x602471d709Be89bd38b39c03eaf544085C4Bb107);
        // Add LP farm rewards from V1
        _stakingBalance[0xB28f13732211f3F3Fdadb2FD656F29Ca2739f989] += 344988344988344988344987;
        _stakingBalance[0xC0934648310f31ED0ECad69108B54F9eD7b10E28] += 523412506970245665916908;
        _stakingBalance[0xC7f8FaF9014bff1A2162d9836F54aFe3AD18f027] = 350000000000000000000000;
        userStaked.push(0xC7f8FaF9014bff1A2162d9836F54aFe3AD18f027);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    function stake(uint value) public returns(bool) {
        // Require stake amount balance of SPOOD
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        _stakingBalance[msg.sender] += value;
        _rOwned[msg.sender] -= value;
        // Increase total staked
        totalStaked += value;
        // Make sure address has been added to reward list
        bool stakeCheck = false;
        if (userStaked.length == 0) {
            userStaked.push(msg.sender);
        }
        for (uint i = 0; i < userStaked.length; i++) {
            user = userStaked[i];
            if (user == msg.sender) {
                stakeCheck = true;
                break;
            }
        }
        if (stakeCheck == false) {
            // Put new address at end
            userStaked.push(msg.sender);
        }
        emit Stake(msg.sender, value);
        return true;
    }
    function unstake(uint value) public returns(bool) {
        // Require unstake amount balance of SILK
        require(_stakingBalance[msg.sender] >= value, 'Insuficient Balance');
        // Transfer SILK to Staking Wallet
        _rOwned[msg.sender] += value;
        _stakingBalance[msg.sender] -= value;
        // Decrease total staked
        totalStaked -= value;
        emit UnStake(msg.sender, value);
        return true;
    }
    function updateRewards(uint value) private {
        rewardVectorLength = userStaked.length;
        require(rewardVectorLength > 0,'No Stakers');
        
        // Distribute rewards through SILK
        for (uint i = 0; i < rewardVectorLength; i++) {
            // Calculate percantage of reward per wallet
            user = userStaked[i];
            userReward = uint(value*balanceOf(user)/totalStaked);
            // Transfer SILK to user
            _stakingBalance[user] += userReward;
            // Increase total staked
            totalStaked += userReward;
        }
        emit UpdateRewards(value);
    }
    function openTrading(bool _status,uint256 _deadBlocks) external onlyOwner() {
        tradingOpen = _status;
        excludeFromReward(address(this));
        excludeFromReward(uniswapV2Pair);
        if(tradingOpen && launchedAt == 0){
            launchedAt = block.number;
            deadBlocks = _deadBlocks;
        }
    }
    function setNewRouter(address newRouter) external onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            uniswapV2Pair = get_pair;
        }
        uniswapV2Router = _newRouter;
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
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    function excludeFromReward(address account) public onlyOwner() {
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isSniper[to], "You have no power here!");
        require(!_isSniper[from], "You have no power here!");
        if(!authorizations[from]){
            require(tradingOpen,"Trading not open yet");
        }
        bool takeFee = false;
        //take fee only on swaps
        if ( (from==uniswapV2Pair || to==uniswapV2Pair) && !(_isExcludedFromFee[from] || _isExcludedFromFee[to]) ) {
            takeFee = true;
        }
        if(launchedAt>0 && (!_isMaxWalletExempt[to] && !authorizations[from])){
                require(amount+ balanceOf(to)<=_maxWalletToken, "Total Holding is currently limited");
        }
        currenttotalFee=totalFee;
        reflectionFee=_buyReflectionFee;
        if(tradingOpen && to == uniswapV2Pair) { //sell
            currenttotalFee= _sellLiquidityFee.add(_sellMarketingFee).add(_sellDevFee);
            reflectionFee=_sellReflectionFee;
        }
        //antibot - first 2 blocks
        if(launchedAt>0 && (launchedAt + deadBlocks) > block.number){
                _isSniper[to]=true;
        }
        //sell
        if (!inSwap && tradingOpen && to == uniswapV2Pair) {
      
            uint256 contractTokenBalance = balanceOf(address(this));
            
            if(contractTokenBalance>=swapThreshold){
                    contractTokenBalance = swapThreshold;
                    swapTokens(contractTokenBalance);
            }
          
        }
        _tokenTransfer(from,to,amount,takeFee);
    }
    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToReward = contractTokenBalance.mul(stakeFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify).sub(amountToReward);
        
        swapTokensForEth(amountToSwap);
        updateRewards(amountToReward);

        uint256 amountETH = address(this).balance;
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHdev = amountETH.mul(devFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHEcosystem = amountETH.mul(ecosystemFee).div(totalETHFee);
        //Send to marketing wallet and dev wallet
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) {
            SendTaxAllocation(amountETHMarketing,marketingWallet);
            SendTaxAllocation(amountETHEcosystem,ecosystemWallet);
            SendTaxAllocation(amountETHdev,devWallet);
        }
        if (amountToLiquify > 0) {
                addLiquidity(amountToLiquify,amountETHLiquidity);
        }
    }
    function SendTaxAllocation(uint256 amount,address payable wallet) private {
        wallet.transfer(amount);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
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
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
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
            owner(),
            block.timestamp
        );
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        uint256 _previousReflectionFee=reflectionFee;
        uint256 _previousTotalFee=currenttotalFee;
        if(!takeFee){
            reflectionFee = 0;
            currenttotalFee=0;
        }
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee){
            reflectionFee = _previousReflectionFee;
            currenttotalFee=_previousTotalFee;
        }
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(reflectionFee).div(
            10**3
        );
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(currenttotalFee).div(
            10**3
        );
    }
    function excludeMultiple(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function excludeFromFee(address[] calldata addresses) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isExcludedFromFee[addresses[i]] = true;
        }
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function setWallets(address _marketingWallet,address _devWallet) external onlyOwner() {
        marketingWallet = payable(_marketingWallet);
        devWallet = payable(_devWallet);
    }
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }
    function manage_Snipers(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            if(!_isTrusted[addresses[i]]){
                _isSniper[addresses[i]] = status;
            }
        }
    }
    function manage_trusted(address[] calldata addresses) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isTrusted[addresses[i]]=true;
        }
    }
    function withDrawLeftoverETH(address payable receipient) public onlyOwner {
        receipient.transfer(address(this).balance);
    }
    function withdrawStuckTokens(IERC20 token, address to) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(to, balance);
    }
    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner() {
        _maxWalletToken = _tTotal.div(1000).mul(maxWallPercent_base1000);
    }
    function setMaxWalletExempt(address _addr) external onlyOwner {
        _isMaxWalletExempt[_addr] = true;
    }
    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
    }
    function airdrop(address from, address[] calldata addresses, uint256 tokens) external onlyOwner {

        require(addresses.length < 2001,"GAS Error: max airdrop limit is 2000 addresses"); // to prevent overflow

        uint256 SCCC = tokens* 10**_decimals * addresses.length;

        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            _transfer(from,addresses[i],(tokens* 10**_decimals));
        }
    }
    function setTaxesBuy(uint256 _reflectionFee, uint256 _liquidityFee, uint256 _marketingFee,uint256 _devFee,uint256 _ecosystemFee) external onlyOwner {
       
        _buyLiquidityFee = _liquidityFee;
        _buyMarketingFee = _marketingFee;
        _buyDevFee = _devFee;
        _buyReflectionFee= _reflectionFee;

        reflectionFee= _reflectionFee;
        liquidityFee = _liquidityFee;
        devFee = _devFee;
        marketingFee = _marketingFee;
        ecosystemFee = _ecosystemFee;
        totalFee = liquidityFee.add(marketingFee).add(devFee).add(ecosystemFee);
        require(totalFee.add(_buyReflectionFee) <= 500, "Must keep taxes below 50%");
    }
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }
    function setTaxesSell(uint256 _reflectionFee,uint256 _liquidityFee, uint256 _marketingFee,uint256 _devFee) external onlyOwner {
        _sellLiquidityFee = _liquidityFee;
        _sellMarketingFee = _marketingFee;
        _sellDevFee = _devFee;
        _sellReflectionFee= _reflectionFee;
        require(_sellLiquidityFee.add(_sellMarketingFee).add(_sellDevFee).add(_sellReflectionFee).add(ecosystemFee) <= 500, "Must keep taxes below 50%");
    }
    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}