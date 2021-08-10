/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

//  SPDX-License-Identifier: Unlicensed

/*

Welcome to Genius Boy Æ369 (You can call me Ash!)

For as long as he can remember, Genius Boy has always
dreamed of putting his precious Æ369 token on the moon.

But tokens can’t get to the moon all by themselves. 

At just 8 years old, even Genius Boy knows that tokens need marketing. 

Returning his treasured copy of the Encyclopaedia Britannica
to his bedside table, Genius Boy closed his heavy eyelids
and settled into a deep slumber.

A smile spread across his face, as he began to dream of an
incredible journey.

A journey that would take him from his humble beginnings
in SunnyVale, Pretoria all the way to Silicon Valley...and then...
on to the moon...

...and who knows, maybe one day, even Mars!

Æ369 is much more than a token, it’s an adventure of discovery. 

Can you help Genius Boy put his token on the Moon! 

Visit our website to find out more!

The Genius Boy mobile game helps the token in two really valuable ways. 

It has micro transactions, some of the profits of these
will be used to buy, and then burn, Æ369 tokens.

That’s a pretty awesome bonus for any token.

But the real benefit of the game is the person it targets...

Genius Boy is about the life of Elon Musk. It champions all of
his greatest achievements, in a very complimentary way. The game
is full of easter eggs designed to make Elon smile :) 

Even the name itself was hand-picked to grab his attention.
Elon’s mother used to call Elon “Genius Boy” when he was little.

The token symbol also has special meaning for Elon, as well as
any fan of Nikola Tesla.

We are doing all of this with one goal in mind, to get Elon’s
attention. So that maybe one day, he will play our game,
love it and maybe even become addicted to it.

As Elon becomes aware of our project we hope that he tweets
about our token. And we all know what happens when Elon Tweets!
It will put Æ369 on the moon! 

So buy some Æ369 today, HODL onto it for dear life, and while
you wait for Elon’s Tweet, download and play the Genius Boy game...
you might even win a Tesla!!! 

Visit our website to find out more!


Website:  https:// geniusboy.cc/
Telegram:  XXXXXXX
Twitter:  https://twitter.com/GeniusBoy369


Created by GenTokens
https:// gentokens.com/

Special thanks to...

    Pavel
    Piotr
    Savage Wolf
    Thomas
    Nick
    CryptoBear
    Spinel
    Combat Medic
    Nanithefk
    Crypto Wolf
    Ryan



Launch Tokenomics

3% Liquidity
10% Marketing
2% Reflection

Tokenomics will be adjusted over time to help the token grow. 
Reflections will be increased post launch.

Contract by GEN
https://gentokens.com/


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

// On June 28th 1971 the world become a better place when Genius Boy was born in Pretoria, South Africa.

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

// Genius Boy is most famous for starting Tesla Motors and SpaceX but was also the co-founder of PayPal, which made his mom very proud. I want a Tesla, they're great!

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x23ADAE3696621f58eF8D846423A15B0002FAEeBA; // AE369 Wallet
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

// Genius Boy has a cameo in Iron Man! Did you spot him? I didn't, but I've not seen it :( 

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

// Like Steve Jobs, (No Steve, that's not the end of the sentence!) Genius Boy's official annual salary for Tesla Motors is only $1.

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

// When he was 12 (that's 4 years into the future!), Genius Boy wrote a cool computer game called Blastar, he sold it he sold for $500. His mother will be very proud when this happens! 

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

// Genius Boy won't become an America citizen until 2002! By then he will be 31 years old! Not a boy at all!! 

contract AE369 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    // _isBlacklisted = Can not buy or sell or transfer tokens at all <-----for bots! 
    mapping (address => bool) public _isWhitelisted;
    mapping (address => bool) public _isBlacklisted;
    
    // need to add uniswapV2Pair address to whitelist list in order to add liquidity 
    //xxxx
    bool public onlyWhitelist = false;


    /*

    Lock Settings Feature - Keeping you safe!

    lockSettings is a bool that is set to false on deployment. 
    In order to change certain functions lockSettings must be false.
    lockSettings can be set to true, but it can never be set back to false!
    When lockSettings is set to true, certain functions can not be changed. 

    They are locked!

    In this contract lockSettings is used to remove the requirement to hold GEN
    and to remove the whitelist restriction, ensuring that these restrictions
    can never be put back in place once lockSettings is set to true.

    lockSettings is a public boolean and anybody can see the current status.

    */

    bool public lockSettings = false;

    function safeLaunch_lock_settings() public onlyOwner {
        lockSettings = true;
    } 
    

// Genius Boy studied physics at Stanford University! But only for 2 days, and he was too young to join in any campus parties! 


    address[] private _excluded;
    address payable private Wallet_AE369 = payable(0x23ADAE3696621f58eF8D846423A15B0002FAEeBA);


    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private _name = "Genius Boy";
    string private _symbol = "AE369";
    uint8 private _decimals = 9;


    // 30 mins Pre-Public launch on the GenTokens LaunchPad. 5T GEN/2 required to purchase before public launch.
    IERC20 GEN1 = IERC20(0xd4294c0f64eBA74089315D4b0278698f7181037e);
    IERC20 GEN2 = IERC20(0x9973885595Cf0C17accD7E46f96dbd937A7E627C);
    IERC20 MBD = IERC20(0xC05244af69120934Dd93787E3fE9a4c37c01fA0a);
     
    // need to hold about 0.2 bnb of GEN or GEN2 to be able to buy on day one
    uint256 public howMuchGEN1 = 5000000 * 10**6 * 10**9; 
    uint256 public howMuchGEN2 = 5000000 * 10**6 * 10**9; 

    // Hold GEN/2 in order to purchase
    bool public bringOutYourGEN = false; 

    // Change required amount of GEN/2 in order to buy early
    function gen_checkYourGEN(uint256 gen1Needed) external onlyOwner() {
        howMuchGEN1 = gen1Needed;
    }
    function gen_checkYourGEN2(uint256 gen2Needed) external onlyOwner() {
        howMuchGEN2 = gen2Needed;
    }

// Ever one to make his mom proud, Genius Boy created a new business called Zip2, which he will sell in 1999 for $307 million! Genius Boy FTW!!

    // People that are exempt from needing to hold GEN/2 when buying early
    mapping (address => bool) public putYourGenAway;

    // Wallet address does not need to hold GEN
    function gen_youDontNeedGEN(address account) public onlyOwner {
        putYourGenAway[account] = true;
    }

    // Wallet address needs to hold GEN/2 to buy early
    function gen_youDoNeedGEN(address account) public onlyOwner {
        putYourGenAway[account] = false;
    }

    // Toggle on/off "Need to be holding GEN/2 to buy" - Turn off at public launch phase
    function gen_onlyGenHolders(bool needGen) public onlyOwner {
        require(!lockSettings, "This function can not be updated, it is locked!");
        bringOutYourGEN = needGen;
    }

    // Update GEN address (for testnet)
    function gen_useTestTokenGEN1(address dummyGen1) external onlyOwner(){
        GEN1 = IERC20(dummyGen1);
    }
    // Update GEN2 address (for testnet)
    function gen_useTestTokenGEN2(address dummyGen2) external onlyOwner(){
        GEN2 = IERC20(dummyGen2);
    }

   
// In 1999, Genius Boy co-founded X.com, then sold it to eBay for more money than I've ever seen! 

    /*

    FEES 

    */


    // fees at launch - reflection will be increased post launch
    uint256 public _FeeReflection = 2;
    uint256 public _FeeLiquidity = 3; 
    uint256 public _FeeMarketing = 10; 


    // Dev tokens fee - may be used later! 
    uint256 public _FeeDevTokens = 0; 



    // 'previous fees' are used when removing and restoring fees
    uint256 private _previousFeeReflection = _FeeReflection;
    uint256 private _previousFeeLiquidity = _FeeLiquidity;
    uint256 private _previousFeeMarketing = _FeeMarketing;
    uint256 private _previousFeeDevTokens = _FeeDevTokens;


    // used to process fees in one calculation to reduce gas and avoid 'too deep in the stack' errors
    uint256 private _liquidityAndPromoFee = _FeeLiquidity+_FeeMarketing;
    
    // Shows the total amount of fees as a percent
    // NOTE: because solidity does not support decimals, this figure is only accurate if all fees add up to a whole number!
    uint256 public _FeesTotal = _FeeLiquidity+_FeeMarketing+_FeeDevTokens+_FeeReflection;


// Genius Boy is so clever that he regularly breaks the rules of maths! His Tesla Model S was awarded a safety score of 5.4 out of 5! That's VERY safe!

    // max wallet holding 
    uint256 public _maxWalletToken = _tTotal.mul(3).div(100);

    // max transaction amount 
    uint256 public _maxTxAmount = _tTotal.mul(3).div(100);

    // this is the number of tokens to accumulate before adding liquidity or taking the promotion fee
    // amount (in tokens) at launch set to 1% of total supply - 1% at launch
    uint256 public _numTokensSellToAddToLiquidity = 10000000 * 10**6 * 10**9;
    

// Genius Boy is the only person ever to send a car into space! That's pretty damned epic!! 
                            

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
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

// Genius Boy is a frugal explorer, he reduced the cost of travelling to the ISS from $1 billion per mission to just $60 million.
    
    constructor () {
        _rOwned[owner()] = _rTotal;
        
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //  <---for testing things! 
        

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_AE369] = true; 
        
        // other wallets are added to the communtiy list manually post launch
        _isWhitelisted[owner()] = true;
        _isWhitelisted[address(this)] = true;
        _isWhitelisted[Wallet_AE369] = true; 

        // don't need to hold GEN
        putYourGenAway[owner()] = true;
        putYourGenAway[address(this)] = true;
        putYourGenAway[Wallet_AE369] = true; 
        
        emit Transfer(address(0), owner(), _tTotal);
    }

// Genius Boy loves Star Wars! So he named his cool rocket after the Millennium Falcon! (I used to have one of those when I was Genius Boy's age!)

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

// Genius Boy has signed the Giving Pledge, a pledge that promises to donate loads of money to people that need it :) He's a really generous boy!

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

    // shall we make it fair? Let everybody have a go at getting in cheap? yes. yes we will. 
    bool public slowFairBuys = true;
    uint8 public justChillFor = 4;
    mapping (address => uint) private stillWaiting;

    // slow it down and make it fair, restrict buying in seconds
    function sefeLaunch_keepCalmAndBuySlowly(bool setBool, uint8 numSeconds) public onlyOwner {
        slowFairBuys = setBool;
        justChillFor = numSeconds;
    }

// Remember that really cool submarine Lotus Esprit in The Spy Who Loved Me? Yes, Genius Boy owns that!! Wow!!! Just WOW! That's better than a flying Tesla!! 

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }


// In 2013, Genius Boy will be named Fortune's "Business boy of the Year", I bet his mom can't wait!


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
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
        function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
   
    
    // set a wallet address so that it does not have to pay transaction fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    // set a wallet address so that it has to pay transaction fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    // set the number of tokens required to activate auto-liquidity and promotion wallet payout
    function process_setNumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiquidity) external onlyOwner() {
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
    }














    // set the fee that is automatically distributed to all holders (reflection) 
    function fees_setFeeReflectionPercent(uint256 FeeReflection) external onlyOwner() {
        _FeeReflection = FeeReflection;
    }

    // set fee for the giveaway and manual burn wallet 
    function fees_setFeeDevTokensPercent(uint256 FeeDevTokens) external onlyOwner() {
        _FeeDevTokens = FeeDevTokens;
    }






    // set fee for auto liquidity
    function fees_setFee_Liquidity(uint256 FeeLiquidity) external onlyOwner() {
        _FeeLiquidity = FeeLiquidity;
        _FeesTotal = _FeeLiquidity+_FeeMarketing+_FeeDevTokens+_FeeReflection;
        _liquidityAndPromoFee = _FeeLiquidity+_FeeMarketing;
    }
    
    // set fee for the marketing
    function fees_setFee_Marketing(uint256 FeeMarketing) external onlyOwner() {
        _FeeMarketing = FeeMarketing;
        _FeesTotal = _FeeLiquidity+_FeeMarketing+_FeeDevTokens+_FeeReflection;
        _liquidityAndPromoFee = _FeeLiquidity+_FeeMarketing;
    }
    
    // set fee for the reflection
    function fees_setFee_Reflection(uint256 FeeReflection) external onlyOwner() {
        _FeeReflection = FeeReflection;
        _FeesTotal = _FeeLiquidity+_FeeMarketing+_FeeDevTokens+_FeeReflection;
        _liquidityAndPromoFee = _FeeLiquidity+_FeeMarketing;
    }
    
    // set fee for the dev tokens
    function fees_setFee_DevTokens(uint256 FeeDevTokens) external onlyOwner() {
        _FeeDevTokens = FeeDevTokens;
        _FeesTotal = _FeeLiquidity+_FeeMarketing+_FeeDevTokens+_FeeReflection;
        _liquidityAndPromoFee = _FeeLiquidity+_FeeMarketing;
    }


    // changing wallets 

    function Set_Wallet_AE369(address payable wallet) public onlyOwner() {
        Wallet_AE369 = wallet;
        _isWhitelisted[Wallet_AE369] = true;
        _isExcludedFromFee[Wallet_AE369] = true;
        putYourGenAway[Wallet_AE369] = true;
    }










    
    // toggle on and off to activate auto liquidity and the promo wallet 
    function process_setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    // receive BNB from PCS Router
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }









    /*

    SafeLaunch Features - Blacklist and Whitelist functions

    Blacklist - This is used to block a person from buying - known bot users are added to this
    list prior to launch. We also check for people using snipe bots on the contract before we
    add liquidity and block these wallets. We like all of our buys to be natural and fair!

    Whitelist - At launch, we lock down the contract so only whitelisted wallets can buy. This
    restriction can be removed using the bool 'WhitelistOnly'

    */

    
    // Whitelist - approve people to buy (ADD - COMMA SEPARATE MULTIPLE WALLETS)
    function safeLaunch_Whitelist_ADD(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isWhitelisted[addresses[i]] = true;
      }
    }

    // Whitelist - approve people to buy (REMOVE - COMMA SEPARATE MULTIPLE WALLETS)
     function safeLaunch_Whitelist_REMOVE(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isWhitelisted[addresses[i]] = false;
      }
    }
    
    // Blacklist - Block people from buying - used for known bots (ADD - COMMA SEPARATE MULTIPLE WALLETS)
    function safeLaunch_Blacklist_ADD(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isBlacklisted[addresses[i]] = true;
      }
    }

    
    // Blacklist - Block people from buying - used for known bots (REMOVE - COMMA SEPARATE MULTIPLE WALLETS)
    function safeLaunch_Blacklist_REMOVE(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isBlacklisted[addresses[i]] = false;
      }
    }

    // Whitelist Switch - Turn on/off only whitelisted buyers 
    function safeLaunch_OnlyWhitelist(bool _enabled) public onlyOwner {
        require(!lockSettings, "This function can not be updated, it is locked!");
        onlyWhitelist = _enabled;
    } 
    
   
    // set the Max transaction amount (percent of total supply)
    function safeLaunch_setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
    
    // set the Max transaction amount (in tokens)
     function safeLaunch_setMaxTxTokens(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmount = maxTxTokens;
    }
    
    
    
    // settting the maximum permitted wallet holding (percent of total supply)
     function safeLaunch_setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = _tTotal.mul(maxWallPercent).div(
            10**2
        );
    }
    
    // settting the maximum permitted wallet holding (in tokens)
     function safeLaunch_setMaxWalletTokens(uint256 maxWallTokens) external onlyOwner() {
        _maxWalletToken = maxWallTokens;
    }
    
    






    







    
   
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tDev);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateFeeReflection(tAmount);
        uint256 tLiquidity = calculateLiquidityAndPromoFee(tAmount);
        uint256 tDev = calculateFeeDevTokens(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tDev);
        return (tTransferAmount, tFee, tLiquidity, tDev);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rDev = tDev.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rDev);
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
    
    function _takeDev(uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[Wallet_AE369] = _rOwned[Wallet_AE369].add(rDev);
        if(_isExcluded[Wallet_AE369])
            _tOwned[Wallet_AE369] = _tOwned[Wallet_AE369].add(tDev);
    }
    
    function calculateFeeReflection(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_FeeReflection).div(
            10**2
        );
    }

    function calculateFeeDevTokens(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_FeeDevTokens).div(
            10**2
        );
    }

    function calculateLiquidityAndPromoFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityAndPromoFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_FeeReflection == 0 && _FeeDevTokens == 0 && _FeeLiquidity == 0 && _FeeMarketing == 0) return;

        _previousFeeReflection = _FeeReflection;
        _previousFeeDevTokens = _FeeDevTokens;
        _previousFeeLiquidity = _FeeLiquidity;
        _previousFeeMarketing = _FeeMarketing;
        
        _FeeReflection = 0;
        _FeeDevTokens = 0;
        _FeeLiquidity = 0;
        _FeeMarketing = 0;

        _FeesTotal = 0;
        _liquidityAndPromoFee = 0;

    }
    
    function restoreAllFee() private {

         _FeeReflection = _previousFeeReflection;
         _FeeDevTokens = _previousFeeDevTokens;
         _FeeLiquidity = _previousFeeLiquidity;
         _FeeMarketing = _previousFeeMarketing;

         _FeesTotal = _FeeLiquidity+_FeeMarketing+_FeeDevTokens+_FeeReflection;
         _liquidityAndPromoFee = _FeeLiquidity+_FeeMarketing;

    }
    




    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Nope, can't do that. Sorry, the owner is... dead!");
        require(spender != address(0), "No puedo hacer esta, disculpa.");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        
        // limits the amount of tokens that each person can buy - launch limit is 3% of total supply!
        if (to != owner() && to != address(this)  && to != address(0x000000000000000000000000000000000000dEaD) && to != uniswapV2Pair){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"You are trying to buy over the max limit... Who do you think you are? Jeff Bezos??");}
        
        // if onlyWhitelist is set to true, then only people that have been approved can buy 
        if (onlyWhitelist){
        require(_isWhitelisted[to], "Sale restricted to whitelsited wallets! Pass your wallet to an admin, or come back later");}

        // blacklisted addreses can not buy! If you have ever used a bot, or scammed anybody, then you're wallet address will probably be blacklisted
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Nope. Not gunna happen. This address is blacklisted");
        require(from != address(0), "from 0 address");
        require(to != address(0), "to 0 address");
        require(amount > 0, "no tokens, just burning gas");


        // must wait 4 seconds between buys
        if (from == uniswapV2Pair &&
            slowFairBuys &&
            !_isExcludedFromFee[to] &&
            to != address(this)  && 
            to != address(0x000000000000000000000000000000000000dEaD)) {
            require(stillWaiting[to] < block.timestamp,"You buy so fast! Relax, buy sloooowly, give other people a chance for a few seconds.");
            stillWaiting[to] = block.timestamp + justChillFor;
        }

     
        // Dude, where's your GEN? Didn't you get the memo? You need some GEN!
         if(bringOutYourGEN)
                {require(putYourGenAway[to]
                    || GEN1.balanceOf(to) >= howMuchGEN1 || GEN2.balanceOf(to) >= howMuchGEN2 || MBD.balanceOf(to) >= 1
                    ,"To buy this early you need to hold some GEN or MBD. Pop back in 30 mins, or buy some GEN!");}
           


        
        // limit the maximum number of tokens that can be bought or sold in one transaction
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Easy there tiger! Put your fat wallet away, that's too much!");



        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        
        bool takeFee = true;
        
       
         require(to != address(0), "ERC20: transfer to the zero address");
         
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


       uint256 splitPromo = 0;
       uint256 tokensToPromo = 0;
       uint256 promoBNB = 0;
       uint256 lpBNB = 0;
       

        // Processing tokens into BNB, adding liquidity and sending marketing BNB to wallet
        if (_FeeMarketing != 0 && _FeeLiquidity != 0){


            // Calculate the correct ratio splits for marketing an dauto liquidity
            splitPromo = precDiv(_FeeMarketing,_liquidityAndPromoFee,2);
            tokensToPromo = contractTokenBalance*splitPromo/100;


        uint256 tokenstoLP = contractTokenBalance-tokensToPromo;
        uint256 firstHalf = tokenstoLP.div(2);
        uint256 secondHalf = tokenstoLP.sub(firstHalf);

        uint256 swapTotal = firstHalf+tokensToPromo;

        uint256 balanceBeforeSwap = address(this).balance;
        swapTokensForEth(swapTotal);
        // what did we get?
        uint256 totalBNB = address(this).balance - balanceBeforeSwap;

        // Split the BNB
        promoBNB = totalBNB*splitPromo/100;
        lpBNB = totalBNB-promoBNB;

        // Add the liquidity
        addLiquidity(secondHalf, lpBNB);
        emit SwapAndLiquify(firstHalf, lpBNB, secondHalf);

        // send BNB to marketing wallet
        sendToWallet(Wallet_AE369, promoBNB);

    }


// Genius Boy loves speed! So he invented the HyperLoop! A person in a pod, in a tube, that moves faster than a bullet train! 


        // Processing the auto-liquidity if there are no marketing or developer fees
        if (_FeeMarketing == 0 && _FeeLiquidity != 0){

        uint256 firstHalf = contractTokenBalance.div(2);
        uint256 secondHalf = contractTokenBalance.sub(firstHalf);
        uint256 balanceBeforeSwap = address(this).balance;
        swapTokensForEth(firstHalf);
        // what did we get?
        uint256 liqBNB = address(this).balance - balanceBeforeSwap;
        // Add the liquidity
        addLiquidity(secondHalf, liqBNB);
        emit SwapAndLiquify(firstHalf, liqBNB, secondHalf);

    }
        // Processing the marketing and developer fees if there is no auto-liquidity
        if (_FeeMarketing != 0 && _FeeLiquidity == 0){

        uint256 balanceBeforeSwap = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        // what did we get?
        uint256 marketingBNB = address(this).balance - balanceBeforeSwap;

        // send BNB to marketing wallet
        sendToWallet(Wallet_AE369, marketingBNB);


    }
    }


    function swapTokensForEth(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }    
    
    // manually purge tokens from contract, swap to bnb and send to promo wallet
    function process_TokensFromContract(address payable wallet, uint256 tokenAmount) public onlyOwner {
        uint256 tokensOnWallet = balanceOf(address(this));
        if (tokenAmount > tokensOnWallet) {tokenAmount = tokensOnWallet;}
        uint256 balanceBefore = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 balanceToSend = address(this).balance - balanceBefore;
        sendToWallet(wallet, balanceToSend);
    }

    // manually purge BNB from contract to promo wallet
    function process_BNBFromContract(address payable wallet,uint256 bnbAmount) public onlyOwner {
        uint256 contractBNB = address(this).balance;
        if (contractBNB > 0) {
        if (bnbAmount > contractBNB) {bnbAmount = contractBNB;}
        sendToWallet(wallet, bnbAmount);
    }
    }

    // Manual 'swapAndLiquify' Trigger (Helps to reduce the red on the chart)
    function process_Purge_SwapAndLiquify_Now (uint256 tokensToLiquify) public onlyOwner {

        uint256 tokensOnContract = balanceOf(address(this));
        if(tokensToLiquify > tokensOnContract){tokensToLiquify = tokensOnContract;}
        swapAndLiquify(tokensToLiquify);

    }

// Genius Boy wants to be burried on Mars... But we hope he evolves into a cyborg that lives forever! So he keeps making cool things!

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        
         
        
        if(!takeFee)
            removeAllFee();
        
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
                
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
       
       
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    
    

}





/*



                           *     .--.
                                / /  `
               +               | |
                      '         \ \__,
                  *          +   '--'  *
                      +   /\
         +              .'  '.   *
                *      /======\      +
                      ;:.  _   ;
                      |:. (_)  |
                      |:.  _   |
            +         |:. (_)  |          *
                      ;:.      ;
                    .' \:.    / `.
                   / .-'':._.'`-. \
                   |/    /||\    \|
  GeniusBoy Æ369 _..--"""````"""--.._ To the moon!
           _.-'``                    ``'-._
         -'                                '-




*/




























// Creating by GEN - https://gentokens.com/