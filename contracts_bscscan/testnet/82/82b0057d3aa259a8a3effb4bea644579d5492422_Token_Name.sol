/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: Unlicensed

/*



http://t.me/champiooontoken
www.champiooon.com
https://twitter.com/Champiooon2?s=09 

4% LP
3% Reflection
3.5% Marketing - DApp Dev
0.5% Dev fee

No mint
100% LP Locked

1000000000000000 Supply
30% initial burn

Holder Burns - 20% at holder milestones

Features needed:

* We would need the whitelist/community option so we can add liquidity and lock before launch.
* Blacklist is a nice to have but probably won't use it, leave it in there just in case we want it on the next token.

4% auto lp (with adjustment if necessary)
4% dev wallet, but we need to option to change the address to 0x00dead in case we want to auto burn. Also we need to be able to adjust % if it's too much etc...
3% Redistribution to tokens to holders (adjustable)

10% wallet will be setup manually by transfering to another wallet
The 20% incentive burn can be done in a similar way, we setup a new wallet transfer the tokens and burn % that way, or do you recommend we do this differently? It's open to improvement.
Also we will need to burn 30% before contract launch.

---------------------------

TESTNET SETTINGS
(XXXTESTNET and XXXMAINNET)

If you want to deploy to the testnet, comment our the XXXMAINNET code line
If you want to deploy to mainnet, comment out the XXXTESTNET code line

PancakeSwap address for testnet: https://pancake.kiemtienonline360.com/
BSCScan for testnet: https://testnet.bscscan.com/

TESTNET SETTINGS FOR METAMASK

Name - Binance Smart Chain Testnet
New RPC URL - https://data-seed-prebsc-1-s1.binance.org:8545
Chain ID - 97
Currency Symbol - tBNB
Block Explorer - https://testnet.bscscan.com

---------------------------

BEFORE DEPLOYING:

1. Change the name and symbol for each contract you need
(XXXNAME) 3 places!

2. Set your owner wallet - this is the wallet that the tokens will deploy too, it is also the wallet you will need to use to log into web3 on BSCscan
if you want to change any of the settings
(XXXOWNER)

3. Set the marketing wallet
(XXXMARKETING)

4. The contract is currently set to send the Auto Liquidity Cake LP tokens to the owner wallet, if you want to change this to the burn address then 
change owner(), to Wallet_Burn,
(XXXCAKELP)

---------------------------

PRE SALE?

If you are doing a pre-sale, use '32. setup_Presale_On'

This sets all of the fees to 0, turns swapAndLiquify to false and removes all wallet and transaction limits. DXsale require the contract to be in this state
You cannot have Whitelist enabled during a presale. 
When the presale is over, you can activate the whitelist option and also use '31. setup_Presale_Off' to restore the fees, wallet limits and swapAndLiquidy

After pre-sale, set the contract to Whitelist only (Set 24 to true) this will lock the contract down so nobody can add liquidity etc. 
When in 'whitelist only' mode, the owner wallet can send tokens. But any transaction that is not sent from the owner wallet will require the to and from 
address to be whitelisted.  The uniswapV2pair address will need to be whitelisted.

---------------------------

AFTER DEPLOYING:


1. If Whitelist is required, set 24. safeLaunch_OnlyWhitelist to true 

2. Initial Burn: From the Owner wallet, send 30% of the tokens to 0x000000000000000000000000000000000000dEaD 

3. Send the 10% Ambassador and Giveaway tokens to a wallet 

4. Send the 20% Incentive Burn tokens to a wallet 

Total Supply
1000000000000000
30% to burn
300000000000000
10% to Ambassador and Giveaway
100000000000000
20% to incentive burn wallet
200000000000000


NOTE: The above wallets will scare people! So either split them up to several wallets or lock them. Even if you tell your community what they are for
a lot of investors that are not in your community will not buy if they see a wallet holding over 2 or 3% of the supply. So probably better to split these
tokens over several wallets. 

5. Whitelist the uniswapV2Pair address - Go to the contract read page, the address on 28. uniswapV2Pair needs to be whitelisted (to do this paste the 
address into 25. safeLaunch_Whitelist_ADD) 

(Whitelisted wallets will not be able to buy or sell until you add the uniswapV2pair address to the whitelist)

6. If Blacklist is required, set 23. safeLaunch_NoBlacklist to true

7. Add any wallets you want to blacklist to 20. safeLaunch_Blacklist_ADD (comma separate wallets to add multiple)

----------------------------

LOCKING WHITELIST OFF

When you are ready for public launch, you need to turn the whitelist only option off. (set 24 to false)
You can then lock this setting by clicking 22 (safeLaunch_LockSettings) 
Locking the settings is a one way function, you cannot unlock them later. 
It can only be triggered if whitelist only is set to false. 
Once locked you cannot re-activate whitelist only mode.
This is included to increase buyer confidence as the whitelist only option could be used to stop people selling.
It will also help to improve an audit score.


----------------------------

ABOUT THE BURN

You have reflections (redistribution to holders) when you do the initial burn, the burn address will become a holder and it wil get reflections. 
You can leave this on, and the token is automatically deflationary, but it takes some of the total reflections away so the other holders get less. 
You can turn the reflections off for the burn address and then it stops doing the 'auto-burn' and holders will get a little more. 

The burn address is 0x000000000000000000000000000000000000dEaD 

To stop the burn address from getting reflections paste this address into 7. excludeFromReward. To add it again, use 13. includeInReward

----------------------------

BURN OPTION - USING BUYBACK AND BURN AS PUBLICITY INSTEAD OF AUTO-BURN

Instead of changing the marketing wallet to a burn address, have the BNB going to the marketing wallet and if you want to burn use the money to 
buy and then burn tokens. The purchase will put green candles on the chart and the burn will increase the dollar value on tokens people hold
this is a much better option than an auto-burn as you can use it as a publicity event. Or you can buy-back tokens and use then as a giveaway contest prize.

---------------------------

ANTI-WHALE WALLET LIMITS
(XXXMAXWALL and XXXMAXTRANS)

You can restrict the max transaaction and the max wallet holding. This is more for appearance really, as anybody can make several wallets! 
These are currently set to 3% of the total supply.

To change these before launch look for XXXMAXWALL and XXXMAXTRANS and swap the number 3 to whatever you need. It must be a whole number, so 1% is
the lowest.

To change these post-launch you can change them as a percentage of total supply using 27 and 29. But this has to be a whole number, so you can only
set 1 as the lowest. If you want to set 0.5% you need to set the amount in tokens, using 28 and 30. When you set a token amount you need to add
the decimals. 

The total supply is:
1000000000000000
But the are 9 decimals, so that becomes:
1000000000000000000000000
Therefore 0.5% of this would be
5000000000000000000000

So if you wanted to set the max transaction to 0.5% of total supply you would enter this number in 28
As an example 2.5% would be 25000000000000000000000 is you wanted this as the max wallet holding you would enter it in 30

---------------------------

ADJUSTING FEES

Reflection (redistribution to holders) this fee is set as a percent, all other fees are multiplied by 100 to allow for decimals.

Fees at launch:

_FeeReflection = 5; // 5%

_FeeLiquidity_X100 = 400; // 4%
_FeeMarketing_X100 = 350; // 3.5%
_FeeDev_X100 = 50; // 0.5%

Liquidity, Marketing and Dev fee are all processed together. The total of these fees divided by 100 must be a whole number. 
(400+350+50)/100 = 8 (plus the 5% for reflection) = 13% Total Fees

---------------------------

The OnlyGEN modifier

I've added a modifier that is locked to my wallet, this is incase I need to change the wallet address in future for the dev fee. 
This modifier cannot change any other settings in the contract. 

---------------------------

THE AUTO LIQUIDITY AND BNB WALLET PROCESSING
(LPCOUNTER)

This is usually done when the fees that build up on the contract hit a set number of tokens. For this reason is must be constantly adjusted.
To avoid this I have set it on a counter. It now triggers automatically after 10 transaction (transaction that do not take a fee are not counted)

The processing only triggers on a sell, not a buy. So it will count up 10 transactions then trigger on the next sell. If you are only getting lots of 
buys and no sells you can sell a token to trigger it, or you can use the manual functions (below)

You can change this number with 17

---------------------------

MANUAL PROCESS - Trigger Swap and Liquify

When you do this, some people will say that the contract is selling tokens! To stop FUD explain to them that it is processing the auto-liquidity and
marketing. You can show the transaction hash so they can see this. 

To trigger this use 16. 

You need to enter a number of tokens, if you just enter 0 it will process whatever has built up on the contract. Or you can process just a portion of them
by entering a number. This number needs to incldue the 9 decimals. So if you wanted to process 100 tokens you would enter 100000000000

To find out how many tokens are currently on the contract waiting to be processed enter the contract address into 12. BalanceOf (on the READ page) this
number has the 9 decimals included too. 

---------------------------

*/

pragma solidity ^0.8.6;


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

library SafeMath {
    

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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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







abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0; //XXXOWNER
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    modifier onlyGEN() {
        require(0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0 == _msgSender(), "Only GEN can change this setting");
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










contract Token_Name is Context, IERC20, Ownable { //XXXNAME
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee; //excluded from fee 
    mapping (address => bool) private _isExcluded; //excluded from rewards





    /*

    Settign up whitelist and blacklist 

    */
    
    //_isWhitelisted = If 'onlyWhitelist' is true only these wallets can buy and sell
    //_isBlacklisted = If 'noBlackList' is true wallets on this list can not buy - used for known bots
    mapping (address => bool) public _isWhitelisted;
    mapping (address => bool) public _isBlacklisted;
    //Set contract so that only whitelisted wallets can buy
    bool public onlyWhitelist;
    //Set contract so that blacklisted wallets cannot buy
    bool public noBlackList;
   

    address[] private _excluded;
    address payable private Wallet_Marketing = payable(0x6380AD4BdEc5B2c562Cd55dddD650E1d5a7c1eCf); //XXXMARKETING
    address payable private Wallet_Dev = payable(0x60a4EA71566405Fd2717331465F184b5349a28EA); //0.5% fee to GEN
    address payable private Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); 
    address payable private Wallet_zero = payable(0x0000000000000000000000000000000000000000); 




    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private _name = "Token Name";  //XXXNAME
    string private _symbol = "SYM";  //XXXNAME
    uint8 private _decimals = 9;

    //counters for liquify trigger
    uint8 private txCount = 0;
    uint8 private swapTrigger = 10; //LPCOUNTER


    
    //refection fee - can be added later if needed
    uint256 public _FeeReflection = 5; // 5%

    //The following fees are using decimals, which are not permitted on uint256 so we have to multiply them by 100 and divide them later
    uint256 public _FeeLiquidity_X100 = 400; // 4%
    uint256 public _FeeMarketing_X100 = 350; // 3.5%
    uint256 public _FeeDev_X100 = 50; // 0.5%

    //'Previous fees' are used to keep track of fee settings when removing and restoring fees
    uint256 private _previousFeeReflection = _FeeReflection;
    uint256 private _previousFeeLiquidity_X100 = _FeeLiquidity_X100;
    uint256 private _previousFeeMarketing_X100 = _FeeMarketing_X100;
    uint256 private _previousFeeDev_X100 = _FeeDev_X100; 

    //The following settings are used to calculate fee splits when distributing bnb to liquidity and external wallets
    uint256 private _promoFee_X100 = _FeeMarketing_X100+_FeeDev_X100;
    uint256 public _FeesTotal = (_FeeMarketing_X100+_FeeDev_X100+_FeeLiquidity_X100)/100+_FeeReflection;

    //fee for the auto LP and the all bnb wallets - used to process fees 
    uint256 private _liquidityAndPromoFee = (_FeeMarketing_X100+_FeeDev_X100+_FeeLiquidity_X100)/100;


    

    //Wallet limits 

    //Max wallet holding (3% at launch)
    uint256 public _maxWalletToken = _tTotal.mul(3).div(100); //XXXMAXWALL
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    //Maximum transaction amount (3% at launch)
    uint256 public _maxTxAmount = _tTotal.mul(3).div(100); //XXXMAXTRANS
    uint256 private _previousMaxTxAmount = _maxTxAmount;
                                     
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _rOwned[owner()] = _rTotal;
        
    //  IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //XXXMAINNET
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //XXXTESTNET
        

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_Marketing] = true; 
        _isExcludedFromFee[Wallet_Dev] = true; 
        
        //other wallets are added to the communtiy list manually post launch
        _isWhitelisted[owner()] = true;
        _isWhitelisted[address(this)] = true;
        _isWhitelisted[Wallet_Marketing] = true; 
        _isWhitelisted[Wallet_Dev] = true; 
        _isWhitelisted[Wallet_Burn] = true; 
        _isWhitelisted[Wallet_zero] = true; 

      
        
        emit Transfer(address(0), owner(), _tTotal);
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



    /*

    Presale Functions 

    Presales have different settings, turn them on and off with the click on a button!

    */

    //get ready for presale!
    function setup_Presale_ON() external onlyOwner {
        process_set_SwapAndLiquifyEnabled(false);        
        removeAllFee();
        removeWalletLimits();
    }
    
    //presale done! Set all fees 
    function setup_Presale_OFF() external onlyOwner {
        process_set_SwapAndLiquifyEnabled(true);
        restoreAllFee();
        restoreWalletLimits();
    }





   
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
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
    
   
  
    
    //set a wallet address so that it does not have to pay transaction fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    //set a wallet address so that it has to pay transaction fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    









    
    /*

    FEES  

    SAFETY FEATURES TO PROTECT BUYERS!

    The fee adjustments are limited to protect buyers...

    1. The total fees can not go above 12% 
    2. The reflection fee can not be set below 5% 


    REMEMBER TO MULTIPLY BY 100

    Because we are using decimals on the fees, we need to multiply then by a factor of 100.
    This is due to restrictions in the solidity code. 

    So, this means that 500 is just 5%  (250 would be 2.5%)

    When setting fees, the Marketing, Developer, and Liquidity fee must be multiplied by 100.
    To show this they are called FeeMarketing_X100 etc.

    The Reflection fee is processed separately. This does not need to be multiplied by 100. 

    */


    // this is the max fee that the contract will accept, it is hard-coded to protect buyers! 
    uint256 maxFee = 12;

    //set the fee that is automatically distributed to all holders (reflection) 
    function fees_setFeeReflectionPercent(uint256 FeeReflection) external onlyOwner() {

        //buyer protection - reflection fee can not be lowered below 5% - total fees can not be increased above 12%
        uint256 limitCheck = (_FeeMarketing_X100+_FeeDev_X100+_FeeLiquidity_X100)/100+FeeReflection;
        if (limitCheck <= maxFee && FeeReflection >= 5){
            _FeeReflection = FeeReflection;
            _FeesTotal = (_FeeMarketing_X100+_FeeDev_X100+_FeeLiquidity_X100)/100+_FeeReflection;}
    }

    
    //set fee for auto liquidity - Because solidity can not do decimals, the fee is multiplied by 100
    function fees_setFeeLiquidityPercent_X100(uint256 FeeLiquidity_X100) external onlyOwner() {

        //buyer protection - total fees can not be increased above 15%
        uint256 limitCheck = (_FeeMarketing_X100+_FeeDev_X100+FeeLiquidity_X100)/100+_FeeReflection;
        if (limitCheck <= maxFee){
             _FeeLiquidity_X100 = FeeLiquidity_X100;
             _liquidityAndPromoFee = (_FeeLiquidity_X100+_promoFee_X100)/100;
             _FeesTotal = (_FeeMarketing_X100+_FeeDev_X100+_FeeLiquidity_X100)/100+_FeeReflection;}
    }
    
    //set fee for the marketing (BNB) wallet - Because solidity can not do decimals, the fee is multiplied by 100
    function fees_setFeeMarketing_X100(uint256 FeeMarketing_X100) external onlyOwner() {
        
        //buyer protection - total fees can not be increased above 15%
        uint256 limitCheck = (FeeMarketing_X100+_FeeDev_X100+_FeeLiquidity_X100)/100+_FeeReflection;
        if (limitCheck <= maxFee){
        _FeeMarketing_X100 = FeeMarketing_X100;
        _FeesTotal = (_FeeMarketing_X100+_FeeDev_X100+_FeeLiquidity_X100)/100+_FeeReflection;
        _promoFee_X100 = _FeeMarketing_X100+_FeeDev_X100;
        _liquidityAndPromoFee = (_FeeLiquidity_X100+_promoFee_X100)/100;}
    }
    

    







    /*

    Updating Wallets

    */

    

    //Update the marketing wallet
    function Wallet_Update_Marketing(address payable wallet) public onlyOwner() {
        Wallet_Marketing = wallet;
        _isWhitelisted[Wallet_Marketing] = true;
        _isExcludedFromFee[Wallet_Marketing] = true;
    }


    //Update the developer wallet
    function Wallet_Update_Dev(address payable wallet) public onlyGEN() {
        Wallet_Dev = wallet;
        _isWhitelisted[Wallet_Dev] = true;
        _isExcludedFromFee[Wallet_Dev] = true;
    }

   
    




    /*

    SwapAndLiquify Switches

    */
    
    //toggle on and off to activate auto liquidity and the promo wallet 
    function process_set_SwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //this will set the number of transactions required before the 'swapAndLiquify' funcitons triggers
    function process_set_NumberOfTransBeforeLiquifyTrigger(uint8 numTrans) public onlyOwner {
        swapTrigger = numTrans;
    }
    







    //This function is required so that the contract can receive BNB from pancakeswap
    receive() external payable {}





   
    









    /*

    SafeLaunch Features

    Blacklist and Whitelist functions

    Blacklist - This is used to block a person from buying - known bot users are added to this
    list prior to launch. We also check for people using snipe bots on the contract before we
    add liquidity and block these wallets. We like all of our buys to be natural and fair.

    Whitelist - At launch, we lock down the contract so only whitelisted wallets can buy. This
    restriction can be removed using the bool 'WhitelistOnly'

    IMPORTANT: If WhitelistOnly is true, in order to add liquidity the uniswap pair will need 
    to be whitelisted.

    Wallet Limits - There are 4 wallet limit functions. Setting the max permitted transaction
    and the max permitted wallet holding. These can be set as a percentage of the total supply
    (this only works for whole numbers) or as a number of tokens (for more accuracy)

    */


    //Whitelist - approve people to buy (ADD - COMMA SEPARATE MULTIPLE WALLETS)
    function safeLaunch_Whitelist_ADD(address[] calldata addresses) external onlyOwner {
       
        uint256 startGas;
        uint256 gasUsed;

    for (uint256 i; i < addresses.length; ++i) {
        if(gasUsed < gasleft()) {
        startGas = gasleft();
        if(!_isWhitelisted[addresses[i]]){
        _isWhitelisted[addresses[i]] = true;}
        gasUsed = startGas - gasleft();
    }
    }
    }


    //Whitelist - approve people to buy (REMOVE - COMMA SEPARATE MULTIPLE WALLETS)
    function safeLaunch_Whitelist_REMOVE(address[] calldata addresses) external onlyOwner {
       
        uint256 startGas;
        uint256 gasUsed;

    for (uint256 i; i < addresses.length; ++i) {
        if(gasUsed < gasleft()) {
        startGas = gasleft();
        if(_isWhitelisted[addresses[i]]){
        _isWhitelisted[addresses[i]] = false;}
        gasUsed = startGas - gasleft();
    }
    }
    }



    //Blacklist - block wallets (ADD - COMMA SEPARATE MULTIPLE WALLETS)
    function safeLaunch_Blacklist_ADD(address[] calldata addresses) external onlyOwner {
       
        uint256 startGas;
        uint256 gasUsed;

    for (uint256 i; i < addresses.length; ++i) {
        if(gasUsed < gasleft()) {
        startGas = gasleft();
        if(!_isBlacklisted[addresses[i]]){
        _isBlacklisted[addresses[i]] = true;}
        gasUsed = startGas - gasleft();
    }
    }
    }



    //Blacklist - block wallets (REMOVE - COMMA SEPARATE MULTIPLE WALLETS)
    function safeLaunch_Blacklist_REMOVE(address[] calldata addresses) external onlyOwner {
       
        uint256 startGas;
        uint256 gasUsed;

    for (uint256 i; i < addresses.length; ++i) {
        if(gasUsed < gasleft()) {
        startGas = gasleft();
        if(_isBlacklisted[addresses[i]]){
        _isBlacklisted[addresses[i]] = false;}
        gasUsed = startGas - gasleft();
    }
    }
    }



    /*

    You can turn the whitelist and blacklist restrictions on and off.

    During a private 'whitelist only launch' onlyWhitelist is set to true, and only whitelisted wallets can buy
    Once the private launch is over, this setting can be set to false. Now 'non-whitelisted' can also buy

    During launch, it's a good idea to block known bot users from buying. But these are real people, so 
    when the contract is safe (and the price has increased) you can allow these wallets to buy/sell by setting
    noBlackList to false
    
    The LockSettings safety function

    The onlyWhitelist setting can be abused! If it is set to true it can prevent people from selling! 
    For this reason we have a LockSettings feature.

    LockSettings is set to false on launch, it can be set to true, but it cannot be switched back to false
    If LockSettings is true, then it is not possible to set onlyWhitelist to true. This protects buyers
    from the possibility of the contract being restricted to white listed wallets.

    */

    bool public LockSettings;

    //Once triggered, this function locks certain settings in place so they can not be changed
    function safeLaunch_LockSettings() public onlyOwner {
        require(!onlyWhitelist, "Cannot lock settings while restricted to whitelist only.");       
        LockSettings = true;
    }

    //Whitelist Switch - Turn on/off only whitelisted buyers 
    function safeLaunch_OnlyWhitelist(bool _enabled) public onlyOwner {
        require(!LockSettings, "To protect buyers, this setting has been locked.");
        onlyWhitelist = _enabled;
        
    }

    //Blacklist Switch - Turn on/off blacklisted wallet restrictions 
    function safeLaunch_NoBlacklist(bool _enabled) public onlyOwner {
        noBlackList = _enabled;
    } 

    /*

    SafeLaunch Features

    Wallet Limits

    Wallets are limited in two ways. The amount of tokens that can be purchased in one transaction
    and the total amount of tokens a wallet can buy. Limiting a wallet prevents one wallet from holding too
    many tokens, which can scare away potential buyers that worry that a whale might dump!

    */


    //set the Max transaction amount (percent of total supply)
    function safeLaunch_setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
    
    //set the Max transaction amount (in tokens)
     function safeLaunch_setMaxTxTokens(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmount = maxTxTokens;
    }
    
    
    
    //setting the maximum permitted wallet holding (percent of total supply)
     function safeLaunch_setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = _tTotal.mul(maxWallPercent).div(
            10**2
        );
    }
    
    //settting the maximum permitted wallet holding (in tokens)
     function safeLaunch_setMaxWalletTokens(uint256 maxWallTokens) external onlyOwner() {
        _maxWalletToken = maxWallTokens;
    }
    
    









    
   
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateFeeReflection(tAmount);
        uint256 tLiquidity = calculateLiquidityAndPromoFee(tAmount);
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

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function calculateFeeReflection(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_FeeReflection).div(
            10**2
        );
    }

    function calculateLiquidityAndPromoFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityAndPromoFee).div(
            10**2
        );
    }




    /*

    Removing and restoring the various fees and limits

    */


    //Remove all fees
    function removeAllFee() private {
        if(_FeeReflection == 0 && _FeeLiquidity_X100 == 0 && _FeeMarketing_X100 == 0 && _FeeDev_X100 == 0 ) return;
        
        _previousFeeReflection = _FeeReflection;
        _previousFeeLiquidity_X100 = _FeeLiquidity_X100;
        _previousFeeMarketing_X100 = _FeeMarketing_X100;
        _previousFeeDev_X100 = _FeeDev_X100;
        
        _FeeReflection = 0;
        _liquidityAndPromoFee = 0;
        _FeeLiquidity_X100 = 0;
        _FeeMarketing_X100 = 0;
        _FeeDev_X100 = 0;
        _promoFee_X100 = 0;
        _FeesTotal = 0;
    }
    
    //Restore all fees
    function restoreAllFee() private {

        _FeeReflection = _previousFeeReflection;
        _FeeLiquidity_X100 = _previousFeeLiquidity_X100;
        _FeeMarketing_X100 = _previousFeeMarketing_X100;
        _FeeDev_X100 = _previousFeeDev_X100;


        _FeesTotal = (_FeeMarketing_X100+_FeeDev_X100+_FeeLiquidity_X100)/100+_FeeReflection;
        _promoFee_X100 = _FeeMarketing_X100+_FeeDev_X100;
        _liquidityAndPromoFee = (_FeeMarketing_X100+_FeeDev_X100+_FeeLiquidity_X100)/100;
    }

    //Remove wallet limits (used during pre-sale)
    function removeWalletLimits() private {
        if(_maxWalletToken == 100 && _maxTxAmount == 100) return;
        
        _previousMaxWalletToken = _maxWalletToken;
        _previousMaxTxAmount = _maxTxAmount;

        _maxTxAmount = _tTotal;
        _maxWalletToken = _tTotal;
    }

    //Restore wallet limits
    function restoreWalletLimits() private {

        _maxWalletToken = _previousMaxWalletToken;
        _maxTxAmount = _previousMaxTxAmount;

    }









    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        

        /*

        TRANSACTION AND WALLET LIMITS

        */
        

        // Limit wallet total
        if (to != owner() && to != address(this)  && to != address(0x000000000000000000000000000000000000dEaD) && to != uniswapV2Pair){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"You are trying to buy too many tokens. You have reached the limit for one wallet.");}

        // Limit the maximum number of tokens that can be bought or sold in one transaction
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "You are trying to buy more than the max transaction.");



        /*

        WHITELIST AND BLACKLIST RESTRICTIONS

        */
        

        // If onlyWhitelist is set to true, then only people that have been approved can buy or sell
        // If onlyWhitelist is true then the burn address and the uniswap pair must be whitelisted
        // When onlyWhitelist is true the owner wallet can still send tokens
        // If you plan to keep whitelist in place for a private launch you must whitelist the iniswapV2pair address
        if (onlyWhitelist && from != owner()){
        require(_isWhitelisted[to] && _isWhitelisted[from], "Contract is currently restricted to whitelisted wallets only.");}


        // Blacklisted addreses can not buy! If you have ever used a bot, or scammed anybody, then you're wallet address will probably be blacklisted
        if (noBlackList){
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "This address is blacklisted. Transaction reverted.");}


        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");




        // SwapAndLiquify is triggered after every X transactions - this number can be adjusted using swapTrigger
        

        if(
            txCount >= swapTrigger && 
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled 
            )
        {  
            
            txCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= _maxTxAmount) {contractTokenBalance = _maxTxAmount;}
            if(contractTokenBalance > 0){
            swapAndLiquify(contractTokenBalance);
        }
        }



        
        bool takeFee = true;
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }
    
    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }

    function precDiv(uint a, uint b, uint precision) internal pure returns ( uint) {
     return a*(10**precision)/b;
         
    }






    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
       
       uint256 splitPromo;
       uint256 tokensToPromo;
       uint256 splitM;
       uint256 totalBNB;
       

        //Processing tokens into BNB (Used for all external wallets and creating the liquidity pair)


        if (_promoFee_X100 != 0 && _FeeLiquidity_X100 != 0){


            //Calculate the correct ratio splits for marketing and developer
            splitPromo = precDiv(_promoFee_X100,(_FeeLiquidity_X100+_promoFee_X100),2);
            tokensToPromo = contractTokenBalance*splitPromo/100;


        uint256 firstHalf = (contractTokenBalance-tokensToPromo)/2;
        uint256 secondHalf = contractTokenBalance-(tokensToPromo+firstHalf);
        uint256 balanceBeforeSwap = address(this).balance;
        swapTokensForEth(firstHalf+tokensToPromo);
        //what did we get?
        totalBNB = address(this).balance - balanceBeforeSwap;
        //Split the BNB
        uint256 promoBNB = totalBNB*splitPromo/100;
        //Add the liquidity
        addLiquidity(secondHalf, (totalBNB-promoBNB));
        emit SwapAndLiquify(firstHalf, (totalBNB-promoBNB), secondHalf);

        //Now split the BNB for the marketing and dev wallets
        totalBNB = address(this).balance;
        splitM = precDiv(_FeeMarketing_X100,_promoFee_X100,2);
        //Send BNB to marketing wallet
        uint256 marketingBNB = totalBNB*splitM/100;
        sendToWallet(Wallet_Marketing, marketingBNB);
        //Send BNB to developer wallet
        sendToWallet(Wallet_Dev, (totalBNB-marketingBNB));

    } else if (_promoFee_X100 == 0 && _FeeLiquidity_X100 != 0){

        uint256 firstHalf = contractTokenBalance.div(2);
        uint256 secondHalf = contractTokenBalance.sub(firstHalf);
        uint256 balanceBeforeSwap = address(this).balance;
        swapTokensForEth(firstHalf);
        //what did we get?
        uint256 lpBNB = address(this).balance - balanceBeforeSwap;
        //Add the liquidity
        addLiquidity(secondHalf, lpBNB);
        emit SwapAndLiquify(firstHalf, lpBNB, secondHalf);

    } else if (_promoFee_X100 != 0 && _FeeLiquidity_X100 == 0){

        swapTokensForEth(contractTokenBalance);
        totalBNB = address(this).balance;
        //Now split the BNB for the marketing and dev wallets 
        splitM = precDiv(_FeeMarketing_X100,_promoFee_X100,2);
        //Send BNB to marketing wallet
        uint256 marketingBNB = totalBNB*splitM/100;
        sendToWallet(Wallet_Marketing, marketingBNB);
        //Send BNB to developer wallet
        sendToWallet(Wallet_Dev, (totalBNB-marketingBNB));

    }

    }


    function swapTokensForEth(uint256 tokenAmount) private {

        //Sell tokens for BNB - For BNB wallets and auto liquidity creation
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }


    /*

    Creating Auto Liquidity

    */

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        //Add token and BNB pair to liquidity - and send CakeLP tokens directly to burn
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            owner(), //XXXCAKELP
            block.timestamp
        );
    }    



    /*

    
    Purge Functions

    Sometimes, tokens or BNB can get trapped on a contract. Safemoon has about $1.7M trapped on it!
    So let's make sure that doesn't happen here. These functions allow you to manually purge any
    trapped BNB or tokens from the contract! Sorted! 


    */


    // Manually purge BNB from contract and send to wallets
    function process_Purge_BNBFromContract() public onlyOwner {
        //Do not trigger if already in swap
        require(!inSwapAndLiquify, "Processing liquidity, try to purge later.");       
        //Check BNB on contract
        uint256 bnbAmount = address(this).balance;
        //Check correct ratio to purge BNB
        uint256 splitCalcPromo = precDiv(_FeeMarketing_X100,_promoFee_X100,2);
        //Send BNB to marketing wallet
        uint256 marketingBNB = bnbAmount*splitCalcPromo/100;
        if (marketingBNB > 0){sendToWallet(Wallet_Marketing, marketingBNB);}
        //Send BNB to developer wallet
        uint256 developerBNB = bnbAmount-marketingBNB;
        if (developerBNB > 0){sendToWallet(Wallet_Dev, developerBNB);}
    }
    

    // Manual 'swapAndLiquify' Trigger (Helps to reduce the red on the chart)
    function process_Purge_SwapAndLiquify_Now (uint256 tokensToLiquify) public onlyOwner {
        //Do not trigger if already in swap
        require(!inSwapAndLiquify, "Processing liquidity, try to purge later.");    
        uint256 tokensOnContract = balanceOf(address(this));
        //for speed (and ease), if you want to process all tokens just enter 0
        if(tokensToLiquify == 0){tokensToLiquify = tokensOnContract;} else 
        if(tokensToLiquify > tokensOnContract){tokensToLiquify = tokensOnContract;}
        swapAndLiquify(tokensToLiquify);

    }








    /*

    Transfer Functions

    There are 4 transfer options, based on whether the to, from, neither or both wallets are excluded from rewards

    */


    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        
         
        
        if(!takeFee){
            removeAllFee();
            } else {
                txCount++;
            }
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
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

}





//Contract by GEN - GenTokens.com