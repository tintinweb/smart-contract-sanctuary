/**
 *Submitted for verification at cronoscan.com on 2022-05-31
*/

/*
*
*	██████╗░███████╗░██████╗░███████╗███╗░░██╗░██████╗  ██╗░░░██╗███╗░░██╗██╗████████╗███████╗██████╗░
*	██╔══██╗██╔════╝██╔════╝░██╔════╝████╗░██║██╔════╝  ██║░░░██║████╗░██║██║╚══██╔══╝██╔════╝██╔══██╗
*	██║░░██║█████╗░░██║░░██╗░█████╗░░██╔██╗██║╚█████╗░  ██║░░░██║██╔██╗██║██║░░░██║░░░█████╗░░██║░░██║
*	██║░░██║██╔══╝░░██║░░╚██╗██╔══╝░░██║╚████║░╚═══██╗  ██║░░░██║██║╚████║██║░░░██║░░░██╔══╝░░██║░░██║
*	██████╔╝███████╗╚██████╔╝███████╗██║░╚███║██████╔╝  ╚██████╔╝██║░╚███║██║░░░██║░░░███████╗██████╔╝
*	╚═════╝░╚══════╝░╚═════╝░╚══════╝╚═╝░░╚══╝╚═════╝░  ░╚═════╝░╚═╝░░╚══╝╚═╝░░░╚═╝░░░╚══════╝╚═════╝░
*
*	https://degensunited.io/
*	https://t.me/Degens_United
*	https://twitter.com/degensunited_
*	
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

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

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPair {
        function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
        function token0() external view returns (address);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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
        uint deadline) external;
}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


interface DividendPayingTokenOptionalInterface {

  function withdrawableDividendOf(address _owner) external view returns(uint256);

  function withdrawnDividendOf(address _owner) external view returns(uint256);

  function accumulativeDividendOf(address _owner) external view returns(uint256);
}


interface DividendPayingTokenInterface {

  function dividendOf(address _owner) external view returns(uint256);

  function distributeDividends() external payable;

  function withdrawDividend() external;

  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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


contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 constant internal magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => uint256) internal rawCROWithdrawnDividends;
    mapping(address => address) public userCurrentRewardToken;
    mapping(address => bool) public userHasCustomRewardToken;
    mapping(address => address) public userCurrentRewardAMM;
    mapping(address => bool) public userHasCustomRewardAMM;
    mapping(address => uint256) public rewardTokenSelectionCount; // keep track of how many people have each reward token selected (for fun mostly)
    mapping(address => bool) public ammIsWhiteListed; // only allow whitelisted AMMs
    mapping(address => bool) public ignoreRewardTokens;
 
    IRouter public router = IRouter(0xd30d3aC04E2325E19A2227cfE6Bc860376Ba20b1); 
  
    function updateDividendrouter(address newAddress) external onlyOwner {
        require(newAddress != address(router), "DEGENS: The router already has that address");
        router = IRouter(newAddress);
    }
  
    uint256 public totalDividendsDistributed; // dividends distributed per reward token

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {
        // add whitelisted AMMs here -- more will get added postlaunch
        ammIsWhiteListed[address(0x90e77a81BB5939c7886912461587C504a450f391)] = true; // Crowfi.app testnet
        ammIsWhiteListed[address(0xd30d3aC04E2325E19A2227cfE6Bc860376Ba20b1)] = true; // Crowfi.app mainnet
        ammIsWhiteListed[address(0x145677FC4d9b8F19B5D56d1820c48e0443049a30)] = true; // MMF mainnet 
        ammIsWhiteListed[address(0x145863Eb42Cf62847A6Ca784e6416C1682b1b2Ae)] = true; // VVS mainnet 
        ammIsWhiteListed[address(0xcd7d16fB918511BF7269eC4f48d61D79Fb26f918)] = true; // Cronaswap mainnet 
        ammIsWhiteListed[address(0xeC0A7a0C2439E8Cb67b992b12ecd020Ea943c7Be)] = true; // Crodex mainnet 
        ammIsWhiteListed[address(0x3c1997d8738dcaB7Ed099105fCd61A9fe5f351Dd)] = true; // Cougar mainnet 
        ammIsWhiteListed[address(0xD3B68a35002B1d328a5414cb60Ad95F458a8cf92)] = true; // Cyborg mainnet 
        ammIsWhiteListed[address(0x69004509291F4a4021fA169FafdCFc2d92aD02Aa)] = true; // Photonswap mainnet 
        ammIsWhiteListed[address(0x28a10fE91d4a8D0637999a903eEf9Ad5b1D9947C)] = true; // duckydefi mainnet 
        ammIsWhiteListed[address(0x77bEFDE82ebA4BDC4D3E4a853BF3EA4FFB49Dd58)] = true; // Annex mainnet 																																				  
    }

    receive() external payable {
        distributeDividends();
    }

    function swapETHForTokens(
        address recipient,
        uint256 ethAmount
    ) private returns (uint256) {
        
        bool swapSuccess;
        IERC20 token = IERC20(userCurrentRewardToken[recipient]);
        IRouter swapRouter = router;
        
        if(userHasCustomRewardAMM[recipient] && ammIsWhiteListed[userCurrentRewardAMM[recipient]]){
            swapRouter = IRouter(userCurrentRewardAMM[recipient]);
        }
        
        // generate the DEX pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(token);
        
        // make the swap
        try swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}( //try to swap for tokens, if it fails (bad contract, or whatever other reason, send CRO)
            1, // accept any amount of Tokens above 1 wei (so it will fail if nothing returns)
            path,
            address(recipient),
            block.timestamp + 360
        ){
            swapSuccess = true;
        }
        catch {
            swapSuccess = false;
        }
        
        // if the swap failed, send them their CRO instead
        if(!swapSuccess){
            rawCROWithdrawnDividends[recipient] = rawCROWithdrawnDividends[recipient].add(ethAmount);
            (bool success,) = recipient.call{value: ethAmount, gas: 3000}("");
    
            if(!success) {
                withdrawnDividends[recipient] = withdrawnDividends[recipient].sub(ethAmount);
                rawCROWithdrawnDividends[recipient] = rawCROWithdrawnDividends[recipient].sub(ethAmount);
                return 0;
            }
        }
        return ethAmount;
    }
  
    function setIgnoreToken(address tokenAddress, bool isIgnored) external onlyOwner {
        ignoreRewardTokens[tokenAddress] = isIgnored;
    }
  
    function isIgnoredToken(address tokenAddress) public view returns (bool){
        return ignoreRewardTokens[tokenAddress];
    }
  
    function getRawCRODividends(address holder) external view returns (uint256){
        return rawCROWithdrawnDividends[holder];
    }
    
    function setWhiteListAMM(address ammAddress, bool whitelisted) external onlyOwner {
        ammIsWhiteListed[ammAddress] = whitelisted;
    }
  
    // call this to set a custom reward token (call from token contract only)
    function setRewardToken(address holder, address rewardTokenAddress, address ammContractAddress) external onlyOwner {
        if(userHasCustomRewardToken[holder] == true){
            if(rewardTokenSelectionCount[userCurrentRewardToken[holder]] > 0){
                rewardTokenSelectionCount[userCurrentRewardToken[holder]] -= 1; // remove count from old token
            }
        }

        userHasCustomRewardToken[holder] = true;
        userCurrentRewardToken[holder] = rewardTokenAddress;
        // only set custom AMM if the AMM is whitelisted.
        if(ammContractAddress != address(router) && ammIsWhiteListed[ammContractAddress]){
            userHasCustomRewardAMM[holder] = true;
            userCurrentRewardAMM[holder] = ammContractAddress;
        } else {
            userHasCustomRewardAMM[holder] = false;
            userCurrentRewardAMM[holder] = address(router);
        }
        rewardTokenSelectionCount[rewardTokenAddress] += 1; // add count to new token
    }
  
  
    // call this to go back to receiving CRO after setting another token. (call from token contract only)
    function unsetRewardToken(address holder) external onlyOwner {
        userHasCustomRewardToken[holder] = false;
        if(rewardTokenSelectionCount[userCurrentRewardToken[holder]] > 0){
            rewardTokenSelectionCount[userCurrentRewardToken[holder]] -= 1; // remove count from old token
        }
        userCurrentRewardToken[holder] = address(0);
        userCurrentRewardAMM[holder] = address(router);
        userHasCustomRewardAMM[holder] = false;
    }
    
    function distributeDividends() public override payable {
        require(totalSupply() > 0);

        if (msg.value > 0) {
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (msg.value).mul(magnitude) / totalSupply()
        );
        emit DividendsDistributed(msg.sender, msg.value);

        totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }
    
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            // if no custom reward token or reward token is ignored, send CRO.
            if(!userHasCustomRewardToken[user] && !isIgnoredToken(userCurrentRewardToken[user])){
            
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            rawCROWithdrawnDividends[user] = rawCROWithdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");
        
            if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                rawCROWithdrawnDividends[user] = rawCROWithdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }
            return _withdrawableDividend;
            
            // the reward is a token, not CRO, use an IERC20 buyback instead!
            } else { 
                
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            return swapETHForTokens(user, _withdrawableDividend);
            }
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

/*
*********** DEGENS UNITED CONTRACT START **********
*/
contract DegensUnited is ERC20, Ownable {
    using SafeMath for uint256;

    IRouter public router;
    address public pair;
    
    bool private swapping;
    bool public swapEnabled;
    bool private isTradingEnabled;

    DEGENSDividendTracker public dividendTracker;
    
    mapping(address => uint256) public holderCROUsedForBuyBacks;
    mapping(address => bool) public _isBot;
    

    address public liquidityWallet;
    address public operationsWallet;

    uint256 public swapTokensAtAmount = 200_000 * (1e9);
    
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    //Anti-dump    
    uint256 public maxSellPercentage = 1;
    uint256 public sellIncreaseFactor = 2;
    struct UserSellPerCycle  {
        uint256 currentSellFee;
        uint256 firstSellTime;
    }
    mapping(address => UserSellPerCycle) public userSellPerCycle;
    
    // fees
    uint256 public RewardsFee = 5;
    uint256 public liquidityFee = 2;
    uint256 public operationFee = 1;
    uint256 public totalFees = RewardsFee + liquidityFee + operationFee;

    uint256 public sellRewardsFee = 7;
    uint256 public sellLiquidityFee = 5;
    uint256 public sellOperationFee = 3;
    uint256 public sellTotalFees = sellRewardsFee + sellLiquidityFee + sellOperationFee;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event Updaterouter(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BuyBackWithNoFees(address indexed holder, uint256 indexed croSpent);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event OperationsWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);    
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends( uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("Degens United", "DEGENS", 9) {

        dividendTracker = new DEGENSDividendTracker();

        liquidityWallet = owner();
        operationsWallet = owner();
        //liquidityWallet = 0x000000000000000000000000000000000000dEaD;
        //operationsWallet = 0x000000000000000000000000000000000000dEaD;

        router = IRouter(0xd30d3aC04E2325E19A2227cfE6Bc860376Ba20b1);
        
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());

        _setAutomatedMarketMakerPair(pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));
        dividendTracker.excludeFromDividends(address(0x0000000000000000000000000000000000000000));
        dividendTracker.excludeFromDividends(address(router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);
        excludeFromFees(address(operationsWallet), true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1e9 * (1e9));
    }

    receive() external payable {

    }
    
    // @dev Owner functions start -------------------------------------
    
    // enable / disable custom AMMs
    function setWhiteListAMM(address ammAddress, bool isWhiteListed) external onlyOwner {
      require(isContract(ammAddress), "DEGENS: setWhiteListAMM:: AMM is a wallet, not a contract");
      dividendTracker.setWhiteListAMM(ammAddress, isWhiteListed);
    }
    
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        swapTokensAtAmount = newAmount * 1e9;
    }
    
    // remove transfer delay after launch
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }
    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "DEGENS: The dividend tracker already has that address");

        DEGENSDividendTracker newDividendTracker = DEGENSDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "DEGENS: The new dividend tracker must be owned by the DEGENS token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }
    
    // updates the minimum amount of tokens people must hold in order to get dividends
    function updateDividendTokensMinimum(uint256 minimumToEarnDivs) external onlyOwner {
        dividendTracker.updateDividendMinimum(minimumToEarnDivs);
    }

    // updates the default router for selling tokens
    function updateRouter(address newAddress) external onlyOwner {
        require(newAddress != address(router), "DEGENS: The router already has that address");
        emit Updaterouter(newAddress, address(router));
        router = IRouter(newAddress);
    }
    
    // updates the default router for buying tokens from dividend tracker
    function updateDividendrouter(address newAddress) external onlyOwner {
        dividendTracker.updateDividendrouter(newAddress);
    }

    // excludes wallets from max txn and fees.
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    // allows multiple exclusions at once
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    
    function setIsBot(address wallet, bool status) external onlyOwner {
        _isBot[wallet] = status;
    }

    function setAntiDump(uint256 _maxSellPercent, uint256 _sellIncreaseFactor) external onlyOwner{
        maxSellPercentage = _maxSellPercent;
        sellIncreaseFactor = _sellIncreaseFactor;
    }

    // excludes wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    // removes exclusion on wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
    }
    
    // allow adding additional AMM pairs to the list
    function setAutomatedMarketMakerPair(address newpair, bool value) external onlyOwner {
        _setAutomatedMarketMakerPair(newpair, value);
    }
    
    // sets the wallet that receives LP tokens to lock
    function updateLiquidityWallet(address newLiquidityWallet) external onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "DEGENS: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    
    // updates the operations wallet (marketing, charity, etc.)
    function updateOperationsWallet(address newOperationsWallet) external onlyOwner {
        require(newOperationsWallet != operationsWallet, "DEGENS: The operations wallet is already this address");
        excludeFromFees(newOperationsWallet, true);
        emit OperationsWalletUpdated(newOperationsWallet, operationsWallet);
        operationsWallet = newOperationsWallet;
    }

    
    function updateFees(uint256 _rewards, uint256 _liquidity, uint256 _operation) external onlyOwner {
        RewardsFee = _rewards;
        liquidityFee = _liquidity;
        operationFee = _operation;        
        totalFees = RewardsFee + liquidityFee + operationFee;
    }

    function updateSellFees(uint256 _rewards, uint256 _liquidity, uint256 _operation) external onlyOwner {
        sellRewardsFee = _rewards;
        sellLiquidityFee = _liquidity;
        sellOperationFee = _operation;        
        sellTotalFees = sellRewardsFee + sellLiquidityFee + sellOperationFee;
    }

    // changes the gas reserve for processing dividend distribution
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "DEGENS: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "DEGENS: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    // changes the amount of time to wait for claims (1-24 hours, expressed in seconds)
    function updateClaimWait(uint256 claimWait) external onlyOwner returns (bool){
        dividendTracker.updateClaimWait(claimWait);
        return true;
    }
    
    function setIgnoreToken(address tokenAddress, bool isIgnored) external onlyOwner returns (bool){
        dividendTracker.setIgnoreToken(tokenAddress, isIgnored);
        return true;
    }
    
    function setSwapEnabled(bool state) external onlyOwner{
        swapEnabled = state;
    }
    
    // determines if an AMM can be used for rewards
    function isAMMWhitelisted(address ammAddress) public view returns (bool){
        return dividendTracker.ammIsWhiteListed(ammAddress);
    }
    
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function getUserCurrentRewardToken(address holder) public view returns (address){
        return dividendTracker.userCurrentRewardToken(holder);
    }
    
    function getUserHasCustomRewardToken(address holder) public view returns (bool){
        return dividendTracker.userHasCustomRewardToken(holder);
    }
    
    function getRewardTokenSelectionCount(address token) public view returns (uint256){
        return dividendTracker.rewardTokenSelectionCount(token);
    }
    
    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
     function getDividendTokensMinimum() external view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
    }
    
    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
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
        return dividendTracker.getAccount(account);
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
        return dividendTracker.getAccountAtIndex(index);
    }
    
    function getRawCRODividends(address holder) public view returns (uint256){
        return dividendTracker.getRawCRODividends(holder);
    }
    
    function getCROAvailableForHolderBuyBack(address holder) public view returns (uint256){
        return getRawCRODividends(holder).sub(holderCROUsedForBuyBacks[msg.sender]);
    }
    
    function isIgnoredToken(address tokenAddress) public view returns (bool){
        return dividendTracker.isIgnoredToken(tokenAddress);
    }
    
    // @dev User Callable Functions start here! ---------------------------------------------
    
    // set the reward token for the user.  Call from here.
    function setRewardToken(address rewardTokenAddress) public returns (bool) {
        require(isContract(rewardTokenAddress), "DEGENS: setRewardToken:: Address is a wallet, not a contract.");
        require(rewardTokenAddress != address(this), "DEGENS: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
        require(!isIgnoredToken(rewardTokenAddress), "DEGENS: setRewardToken:: Reward Token is ignored from being used as rewards.");
        dividendTracker.setRewardToken(msg.sender, rewardTokenAddress, address(router));
        return true;
    }
    
    // set the reward token for the user with a custom AMM (AMM must be whitelisted).  Call from here.
    function setRewardTokenWithCustomAMM(address rewardTokenAddress, address ammContractAddress) public returns (bool) {
        require(isContract(rewardTokenAddress), "DEGENS: setRewardToken:: Address is a wallet, not a contract.");
        require(ammContractAddress != address(router), "DEGENS: setRewardToken:: Use setRewardToken to use default Router");
        require(rewardTokenAddress != address(this), "DEGENS: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
        require(!isIgnoredToken(rewardTokenAddress), "DEGENS: setRewardToken:: Reward Token is ignored from being used as rewards.");
        require(isAMMWhitelisted(ammContractAddress) == true, "DEGENS: setRewardToken:: AMM is not whitelisted!");
        dividendTracker.setRewardToken(msg.sender, rewardTokenAddress, ammContractAddress);
        return true;
    }
    
    // Unset the reward token back to CRO.  Call from here.
    function unsetRewardToken() public returns (bool){
        dividendTracker.unsetRewardToken(msg.sender);
        return true;
    }
    
    // Activate trading on the contract and enable swapAndLiquify for tax redemption against LP
    function activateContract() public onlyOwner {
        isTradingEnabled = true;
        swapEnabled = true;
    }
    
    // Holders can buyback with no fees up to their claimed raw CRO amount.
    function buyBackTokensWithNoFees() external payable returns (bool) {
        uint256 userRawCRODividends = getRawCRODividends(msg.sender);
        require(userRawCRODividends >= holderCROUsedForBuyBacks[msg.sender].add(msg.value), "DEGENS: buyBackTokensWithNoFees:: Cannot Spend more than earned.");
        
        uint256 ethAmount = msg.value;
        
        // generate the DEX pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);
        
        // update amount to prevent user from buying with more CRO than they've received as raw rewards (lso update before transfer to prevent reentrancy)
        holderCROUsedForBuyBacks[msg.sender] = holderCROUsedForBuyBacks[msg.sender].add(msg.value);
        
        bool prevExclusion = _isExcludedFromFees[msg.sender]; // ensure we don't remove exclusions if the current wallet is already excluded
        // make the swap to the contract first to bypass fees
        _isExcludedFromFees[msg.sender] = true;
        
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}( //try to swap for tokens, if it fails (bad contract, or whatever other reason, send CRO)
            0, // accept any amount of Tokens
            path,
            address(msg.sender),
            block.timestamp + 360
        );
        
        _isExcludedFromFees[msg.sender] = prevExclusion; // set value to match original value
        emit BuyBackWithNoFees(msg.sender, ethAmount);
        return true;
    }
    
    // allows a user to manually claim their tokens.
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }
    
    // allow a user to manuall process dividends.
    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
    
    // @dev Token functions
    
    function _setAutomatedMarketMakerPair(address _pair, bool value) private {
        require(automatedMarketMakerPairs[_pair] != value, "DEGENS: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[_pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(_pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function checkMaxSell(uint256 amount) internal view{
        uint256 liqSupply;
        if(IPair(pair).token0() == address(this)){
            (liqSupply,,) = IPair(pair).getReserves();
        }
        else{
            (,liqSupply,) = IPair(pair).getReserves();
        }
        require(amount <= (liqSupply * maxSellPercentage) / 100, "You are exceeding maxSellPercentage");   
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBot[to] || !_isBot[from], "DEGENS: To/from address is ignored");
        
        if(!_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            require(isTradingEnabled, "Trading is currently disabled");
        }

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !automatedMarketMakerPairs[from]){
            checkMaxSell(amount);

            bool newCycle = block.timestamp - userSellPerCycle[from].firstSellTime >= 24 hours;
            if(!newCycle){
               userSellPerCycle[from].currentSellFee += sellIncreaseFactor;
            }
            else{
               userSellPerCycle[from].currentSellFee = 0;
               userSellPerCycle[from].firstSellTime = block.timestamp;
            }
        }
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        // Prevent buying more than 1 txn each 5 seconds at launch. Bot killer. Will be removed shortly after launch.
        if (transferDelayEnabled){
            if (!automatedMarketMakerPairs[to] && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]){
                require(_holderLastTransferTimestamp[to] < block.timestamp, "_transfer:: Transfer Delay enabled.  Please try again later.");
                _holderLastTransferTimestamp[to] = block.timestamp + 5;
            }
        }
        

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && !swapping && swapEnabled && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            swapping = true;
            swapAndLiquify(contractTokenBalance);
            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            
            uint256 fees;
            if(automatedMarketMakerPairs[to]) fees = amount * sellTotalFees / 100;

            else fees = amount * totalFees / 100;

            if(!automatedMarketMakerPairs[from]){
                fees += amount * userSellPerCycle[from].currentSellFee / 100;
            }

            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } 
            catch {
            }
        }
    }

    function swapAndLiquify(uint256 tokens) private{
       // Split the contract balance into halves
        uint256 denominator = (sellTotalFees) * 2;
        uint256 tokensToAddLiquidityWith = tokens * sellLiquidityFee / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - sellLiquidityFee);
        uint256 croToAddLiquidityWith = unitBalance * sellLiquidityFee;

        if(croToAddLiquidityWith > 0){
            // Add liquidity to DEX
            addLiquidity(tokensToAddLiquidityWith, croToAddLiquidityWith);
        }

        uint256 operationAmt = unitBalance * 2 * sellOperationFee;
        if(operationAmt > 0){
            payable(operationsWallet).transfer(operationAmt);
        }

        uint256 dividends = unitBalance * 2 * sellRewardsFee;
        if(dividends > 0){
            (bool success,) = address(dividendTracker).call{value: dividends}("");

            if(success) {
                emit SendDividends(tokens, dividends);
            }
        }

    }

    function swapTokensForEth(uint256 tokenAmount) private {

        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
        
    }


	function recoverContractCRO(uint256 amount) public onlyOwner{
        if(amount >= address(this).balance){
            payable(operationsWallet).transfer(amount);
        }
    }
}

library IterableMapping {
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

contract DEGENSDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("DEGENS_Dividend_Tracker", "DEGENS_Dividend_Tracker", 9) {

        claimWait = 3600;
        minimumTokenBalanceForDividends = 20_000 * (1e9); //must hold 20,000+ tokens to get rewards
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "DEGENS_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "DEGENS_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main DEGENS contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function includeInDividends(address account) external onlyOwner {
        require(excludedFromDividends[account]);
        excludedFromDividends[account] = false;

        emit IncludeInDividends(account);
    }
    
    function updateDividendMinimum(uint256 minimumToEarnDivs) external onlyOwner {
        minimumTokenBalanceForDividends = minimumToEarnDivs;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "DEGENS_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "DEGENS_Dividend_Tracker: Cannot update claimWait to same value");
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
                                tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                            iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
                    }
                }

                withdrawableDividends = withdrawableDividendOf(account);
                totalDividends = accumulativeDividendOf(account);
                lastClaimTime = lastClaimTimes[account];
                nextClaimTime = lastClaimTime > 0 ?
                    lastClaimTime.add(claimWait) : 0;
                secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                    nextClaimTime.sub(block.timestamp) : 0;
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