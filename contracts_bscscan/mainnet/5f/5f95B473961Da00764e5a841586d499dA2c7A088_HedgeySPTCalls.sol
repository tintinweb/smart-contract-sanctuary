/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

pragma solidity ^0.6.12;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    
    function safeMultiTransfer(IERC20 token, address[] memory to, uint256[] memory values) internal {
        require(to.length == values.length, "Different number of recipients than values");
        for (uint i = 0; i < to.length; i++) {
            callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to[i], values[i]));
        }
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeMultiTransferFrom(IERC20 token, address from, address[] memory to, uint256[] memory values) internal {
        require(to.length == values.length, "Different number of recipients than values");
        for (uint i = 0; i < to.length; i++) {
            callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to[i], values[i]));
        }
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface ISPT {
    function burn(address, uint256) external;
}


contract HedgeySPTCalls is ReentrancyGuard, Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public asset;
    address public pymtCurrency;
    address public spt; //special purpose token address
    uint public assetDecimals;
    address public paymentPair;
    address public assetPair;
    address payable public weth = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint public c = 0;
    address public uniFactory = 0xBCfCcbde45cE874adCB698cC183deBcF17952812;
    bool public cashCloseOn;
    

    constructor(address _asset, address _pymtCurrency, address _spt) public {
        asset = _asset;
        pymtCurrency = _pymtCurrency;
        spt = _spt;
        assetDecimals = IERC20(_asset).decimals();
        paymentPair = IUniswapV2Factory(uniFactory).getPair(weth, pymtCurrency);
        assetPair = IUniswapV2Factory(uniFactory).getPair(weth, asset);
        if (paymentPair != address(0x0) && assetPair != address(0x0)){
            //if neither of the currencies is weth then we can test if both asset and payment have a pair with weth
            cashCloseOn = true;
        } else {
            cashCloseOn = false;
        }
    }
    
    struct Call {
        address payable short;
        uint assetAmt;
        uint strike;
        uint totalPurch;
        uint price;
        uint expiry;
        bool open;
        bool tradeable;
        address payable long;
        bool exercised;
    }

    
    mapping (uint => Call) public calls;



    //internal and setup functions

    receive() external payable {    
    }

    function depositPymt(address _token, address _sender, uint _amt) internal {
        SafeERC20.safeTransferFrom(IERC20(_token), _sender, address(this), _amt);
    }

    function withdrawPymt(address _token, address payable to, uint _amt) internal {
        SafeERC20.safeTransfer(IERC20(_token), to, _amt);
    }

    function transferPymt(address _token, address from, address payable to, uint _amt) internal {
        SafeERC20.safeTransferFrom(IERC20(_token), from, to, _amt);         
    
    }

    //function to write a new call
    function newAsk(uint _assetAmt, uint _strike, uint _price, uint _expiry) public onlyOwner {
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "totalPurchase error: too small amount");
        uint balCheck = IERC20(asset).balanceOf(msg.sender);
        require(balCheck >= _assetAmt, "not enough to sell this call option");
        depositPymt(asset, msg.sender, _assetAmt);
        calls[c++] = Call(msg.sender, _assetAmt, _strike, _totalPurch, _price, _expiry, false, true, msg.sender, false);
        emit NewAsk(c.sub(1), _assetAmt, _strike, _price, _expiry);
    }

    function cancelNewAsk(uint _c) public nonReentrant onlyOwner {
        Call storage call = calls[_c];
        require(msg.sender == call.short && msg.sender == call.long, "only short can change an ask");
        require(!call.open, "call already open");
        require(!call.exercised, "call already exercised");
        call.tradeable = false;
        call.exercised = true;
        withdrawPymt(asset, call.short, call.assetAmt);
        emit OptionCancelled(_c);
    }

    //function to purchase a new call that hasn't changed hands yet
    function buyNewOption(uint _c) public {
        Call storage call = calls[_c];
        require(msg.sender != call.short, "this is your lost chicken");
        require(call.short != address(0x0) && call.short == call.long, "not your chicken");
        require(call.expiry > now, "This call is already expired");
        require(!call.exercised, "This has already been exercised");
        require(call.tradeable, "This isnt tradeable yet");
        require(!call.open, "This call is already open");
        uint balCheck = IERC20(spt).balanceOf(msg.sender); //pulls SPT instead of payment currency
        require(balCheck >= call.price, "not enough to buy this call option");
        ISPT(spt).burn(msg.sender, call.price); //burns the tokens  
        call.open = true;
        call.long = msg.sender;
        call.tradeable = false;
        emit NewOptionBought(_c);
    }

    function exercise(uint _c) public nonReentrant {
        Call storage call = calls[_c];
        require(call.open, "This isnt open");
        require(call.expiry >= now, "This call is already expired");
        require(!call.exercised, "This has already been exercised!");
        require(msg.sender == call.long, "You dont own this call");
        uint balCheck = IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= call.totalPurch, "not enough to exercise this call option");
        call.exercised = true;
        call.open = false;
        call.tradeable = false;
        transferPymt(pymtCurrency, msg.sender, call.short, call.totalPurch);   
        withdrawPymt(asset, call.long, call.assetAmt);
        emit OptionExercised(_c, false);
    }

    //this is the exercise alternative for ppl who want to receive payment currency instead of the underlying asset
    function cashClose(uint _c, bool cashBack) public nonReentrant {
        require(cashCloseOn, "c: this pair cannot be cash closed");
        Call storage call = calls[_c];
        require(call.open, "c: This isnt open");
        require(call.expiry >= now, "c: This call is already expired");
        require(!call.exercised, "c: This has already been exercised!");
        require(msg.sender == call.long, "c: You dont own this call");
        (uint assetIn, uint wethIn) = getTo(call.totalPurch);
        require(assetIn < (call.assetAmt), "c: Underlying is not in the money");
        call.exercised = true;
        call.open = false;
        call.tradeable = false;
        //swap(asset, call.totalPurch, assetIn, call.short);
        swapTo(call.totalPurch, call.short);     
        call.assetAmt -= assetIn;
        if (cashBack) {
            swapFrom(call.assetAmt, call.long);
        } else {
            withdrawPymt(asset, call.long, call.assetAmt);
        }
        
        emit OptionExercised(_c, true);
    }

    function returnExpired(uint _c) public nonReentrant onlyOwner {
        Call storage call = calls[_c];
        require(!call.exercised, "This has been exercised");
        require(call.expiry < now, "Not expired yet"); 
        require(msg.sender == call.short, "You cant do that");
        call.tradeable = false;
        call.open = false;
        call.exercised = true;
        withdrawPymt(asset, call.short, call.assetAmt);
        emit OptionReturned(_c);
    }


    //************SWAP SPECIFIC FUNCTIONS USED FOR THE CASH CLOSE METHODS***********************/

    //primary function to swap asset into pymtCurrency to payoff the short
    function swapTo(uint amountOut, address to) internal {
        (uint tokenIn, uint wethIn) = getTo(amountOut);
        swap(assetPair, asset, wethIn, tokenIn, address(this)); //sends asset token into the pair, and delivers weth to us
        swap(paymentPair, weth, amountOut, wethIn, to); //swaps to send the just received wethIn and finally gets the USD Out
    }

    //secondary function to convert profit from remaining asset into pymtCurrency
    function swapFrom(uint amountIn, address to) internal {
        (uint cashOut, uint wethOut) = getFrom(amountIn);
        swap(assetPair, asset, wethOut, amountIn, address(this)); //send it to this address
        swap(paymentPair, weth, cashOut, wethOut, to); 
    }


    //function to swap from this contract to uniswap pool
    function swap(address pair, address token, uint out, uint _in, address to) internal {
        SafeERC20.safeTransfer(IERC20(token), pair, _in); //sends the asset amount in to the swap
        address token0 = IUniswapV2Pair(pair).token0();
        if (token == token0) {
            IUniswapV2Pair(pair).swap(0, out, to, new bytes(0));
        } else {
            IUniswapV2Pair(pair).swap(out, 0, to, new bytes(0));
        }
        
    }

    //primary function to get the amounts in required to pay off the short position total purchase
    //amount out is the total purchase necessary
    function getTo(uint amountOut) public view returns (uint amountIn, uint wethIn) {
        wethIn = estIn(amountOut, paymentPair, pymtCurrency);       
        amountIn = estIn(wethIn, assetPair, weth);

    }

    //secondary function to pay off the remaining profit to the long position
    function getFrom(uint amountIn) public view returns (uint cashOut, uint wethOut) {
        wethOut = estCashOut(amountIn, assetPair, weth);
        cashOut = estCashOut(wethOut, paymentPair, pymtCurrency);
    }

    

    function estCashOut(uint amountIn, address pair, address token) public view returns (uint amountOut) {
        (uint resA, uint resB,) = IUniswapV2Pair(pair).getReserves();
        address token1 = IUniswapV2Pair(pair).token1();
        amountOut = (token1 == token) ? UniswapV2Library.getAmountOut(amountIn, resA, resB) : UniswapV2Library.getAmountOut(amountIn, resB, resA);
    }

    function estIn(uint amountOut, address pair, address token) public view returns (uint amountIn) {
        (uint resA, uint resB,) = IUniswapV2Pair(pair).getReserves();
        address token1 = IUniswapV2Pair(pair).token1();
        amountIn = (token1 == token) ? UniswapV2Library.getAmountIn(amountOut, resA, resB) : UniswapV2Library.getAmountIn(amountOut, resB, resA);
    }



    event NewAsk(uint _i, uint _assetAmt, uint _strike, uint _price, uint _expiry);
    event NewOptionBought(uint _i);
    event OptionExercised(uint _i, bool cashClosed);
    event OptionReturned(uint _i);
    event OptionCancelled(uint _i);


}