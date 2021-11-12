/**
 *Submitted for verification at Etherscan.io on 2021-11-11
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

pragma solidity ^0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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
                hex'3f88503e8580ab941773b59034fb4b2a63e86dbc031b3633a925533ad3ed2b93' // init code hash
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
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
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


interface IHedgeySwap {
    function hedgeyPutSwap(address originalOwner, uint _p, uint _totalPurchase, address[] memory path) external;
}


contract HedgeyPuts is ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public asset; 
    address public pymtCurrency; 
    uint public assetDecimals;
    address public uniPair;
    address payable public weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //rinkeby weth      
    uint public fee;
    address payable public feeCollector;
    uint public p = 0; 
    address public uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //uniswap 
    bool private assetWeth;
    bool private pymtWeth;
    bool public cashCloseOn;
    

    constructor(address _asset, address _pymtCurrency, address payable _feeCollector, uint _fee) public {
        asset = _asset;
        pymtCurrency = _pymtCurrency;
        feeCollector = _feeCollector;
        fee = _fee;
        assetDecimals = IERC20(_asset).decimals();
        uniPair = IUniswapV2Factory(uniFactory).getPair(_asset, _pymtCurrency);
        if (uniPair == address(0x0)) {
            cashCloseOn = false;
        } else {
            cashCloseOn = true;
        }
        if (_asset == weth) {
            assetWeth = true;
            pymtWeth = false;
        } else if (_pymtCurrency == weth) {
            assetWeth = false;
            pymtWeth = true;
        } else {
            assetWeth = false;
            pymtWeth = false;
        }
    }
    

    struct Put {
        address payable short;
        uint assetAmt;
        uint minimumPurchase;
        uint strike;
        uint totalPurch;
        uint price;
        uint expiry;
        bool open;
        bool tradeable;
        address payable long;
        bool exercised;
    }

    mapping (uint => Put) public puts;

    //internal and setup functions

    receive() external payable {    
    }

    function depositPymt(bool _isWeth, address _token, address _sender, uint _amt) internal {
        if (_isWeth) {
            require(msg.value == _amt, "deposit issue: sending in wrong amount of eth");
            IWETH(weth).deposit{value: _amt}();
            assert(IWETH(weth).transfer(address(this), _amt));
        } else {
            SafeERC20.safeTransferFrom(IERC20(_token), _sender, address(this), _amt);
        }
    }

    function withdrawPymt(bool _isWeth, address _token, address payable to, uint _amt) internal {
        if (_isWeth && (!Address.isContract(to))) {
            //if the address is a contract - then we should actually just send WETH out to the contract, else send the wallet eth
            IWETH(weth).withdraw(_amt);
            to.transfer(_amt);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), to, _amt);
        }
    }

    function transferPymt(bool _isWETH, address _token, address from, address payable to, uint _amt) internal {
        if (_isWETH) {
            
            if (!Address.isContract(to)) {
                to.transfer(_amt);
            } else {
                // we want to deliver WETH from ETH here for better handling at contract
                IWETH(weth).deposit{value: _amt}();
                assert(IWETH(weth).transfer(to, _amt));
            }
        } else {
            SafeERC20.safeTransferFrom(IERC20(_token), from, to, _amt);         
        }
    }

    function transferPymtWithFee(bool _isWETH, address _token, address from, address payable to, uint _total) internal {
        uint _fee = (_total * fee).div(1e4);
        uint _amt = _total.sub(_fee);
        if (_isWETH) {
            require(msg.value == _total, "transfer issue: wrong amount of eth sent");
        }
        transferPymt(_isWETH, _token, from, to, _amt); //transfer the stub to recipient
        if (_fee > 0) transferPymt(_isWETH, _token, from, feeCollector, _fee); //transfer fee to fee collector
           
    }


    //admin function to update the fee amount
    function changeFee(uint _fee, address payable _collector) external {
        require(msg.sender == feeCollector, "only fee collector");
        fee = _fee;
        feeCollector = _collector;
    }

    

    function updateAMM() public {
        uniPair = IUniswapV2Factory(uniFactory).getPair(asset, pymtCurrency);
        if (uniPair == address(0x0)) {
            cashCloseOn = false;
        } else {
            cashCloseOn = true;
        }
        emit AMMUpdate(cashCloseOn);
    }

    
    // PUT FUNCTIONS  **********************************************

    //function for someone wanting to buy a new put
    function newBid(uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public {
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "p: totalPurchase error: too small amount");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= _price, "p: insufficent purchase cash");
        depositPymt(pymtWeth, pymtCurrency, msg.sender, _price); //handles weth and token deposits into contract
        puts[p++] = Put(address(0x0), _assetAmt, _assetAmt, _strike, _totalPurch, _price, _expiry, false, true, msg.sender, false);
        emit NewBid(p.sub(1), _assetAmt, _assetAmt, _strike, _price, _expiry);
    }


    function cancelNewBid(uint _p) public nonReentrant {
        Put storage put = puts[_p];
        require(msg.sender == put.long, "p:only long can cancel a bid");
        require(!put.open, "p: put already open");
        require(!put.exercised, "p: put already exercised");
        require(put.short == address(0x0), "p: not a new bid"); 
        put.tradeable = false;
        put.exercised = true;
        withdrawPymt(pymtWeth, pymtCurrency, put.long, put.price);
        emit OptionCancelled(_p);
    }

    //function for an existing long to sell position to a new bidder
    function sellOpenOptionToNewBid(uint _p, uint _q, uint _price) payable public nonReentrant {
        Put storage openPut = puts[_p];
        Put storage newBid = puts[_q];
        require(_p != _q, "p: wrong sale function");
        require(_price == newBid.price, "p: price changed before execution");
        require(msg.sender == openPut.long, "p: you dont own this");
        require(openPut.strike == newBid.strike, "p: not the right strike");
        require(openPut.assetAmt == newBid.assetAmt, "p: not the right assetAmt");
        require(openPut.expiry == newBid.expiry, "p: not the right expiry");
        require(newBid.short == address(0x0), "p: newBid is not new");
        require(openPut.open && !newBid.open && newBid.tradeable && !openPut.exercised && !newBid.exercised && openPut.expiry > now && newBid.expiry > now, "something is wrong");
        //close out our new bid
        newBid.exercised = true;
        newBid.tradeable = false;
        uint feePymt = (newBid.price * fee).div(1e4);
        uint remainder = newBid.price.sub(feePymt);
        withdrawPymt(pymtWeth, pymtCurrency, openPut.long, remainder);
        SafeERC20.safeTransfer(IERC20(pymtCurrency), feeCollector, feePymt);
        //assign the put.long
        openPut.long = newBid.long;
        openPut.price = newBid.price;
        openPut.tradeable = false;
        emit OpenOptionSold(_p, _q, openPut.long, _price);
    }

    //function for someone to write the put for the open bid
    function sellNewOption(uint _p, uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public {
        Put storage put = puts[_p];
        require(put.strike == _strike && put.assetAmt == _assetAmt && put.price == _price && put.expiry == _expiry, "p details mismatch: something has changed before execution");
        require(put.short == address(0x0));
        require(msg.sender != put.long, "p: you already own this");
        require(put.expiry > now, "p: This is already expired");
        require(put.tradeable, "p: not tradeable");
        require(!put.open, "p: put not open");
        require(!put.exercised, "p: this has been exercised");
        uint feePymt = (put.price * fee).div(1e4);
        uint shortPymt = (put.totalPurch).add(feePymt).sub(put.price); //net amount the short must send into the contract for escrow
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= shortPymt, "p: sell new option: insufficent collateral");
        depositPymt(pymtWeth, pymtCurrency, msg.sender, shortPymt);
        SafeERC20.safeTransfer(IERC20(pymtCurrency), feeCollector, feePymt);
        put.open = true;
        put.short = msg.sender;
        put.tradeable = false;
        emit NewOptionSold(_p);
    }


    function changeNewOption(uint _p, uint _assetAmt, uint _minimumPurchase, uint _strike, uint _price, uint _expiry) payable public nonReentrant {
        Put storage put = puts[_p];
        require(put.long == msg.sender, "p: you do not own this put");
        require(!put.exercised, "p: this has been exercised");
        require(!put.open, "p: this is already open");
        require(put.tradeable, "p: this is not a tradeable option");
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "totalPurchase error: too small amount");
        //lets check if this is a new ask or new bid
        //if its a newAsk
        if (msg.sender == put.short) {
            require(_minimumPurchase.mul(_strike).div(10 ** assetDecimals) > 0, "p: minimum purchase error, too small of a minimum");
            require(_assetAmt % _minimumPurchase == 0, "p: asset amount needs to be a multiple of the minimum");
            uint refund = (put.totalPurch > _totalPurch) ? put.totalPurch.sub(_totalPurch) : _totalPurch.sub(put.totalPurch);
            uint oldPurch = put.totalPurch;
            put.strike = _strike;
            put.totalPurch = _totalPurch;
            put.assetAmt = _assetAmt;
            put.minimumPurchase = _minimumPurchase;
            put.price = _price;
            put.expiry = _expiry;
            put.tradeable = true;
            if (oldPurch > _totalPurch) {
                withdrawPymt(pymtWeth, pymtCurrency, put.short, refund);
            } else if (oldPurch < _totalPurch) {
                uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
                require(balCheck >= refund, "p: not enough to change this put option");
                depositPymt(pymtWeth, pymtCurrency, msg.sender, refund);
            }
            emit OptionChanged(_p, _assetAmt, _minimumPurchase, _strike, _price, _expiry);

        } else if (put.short == address(0x0)) {
            //its a newBid
            uint refund = (_price > put.price) ? _price.sub(put.price) : put.price.sub(_price);
            put.assetAmt = _assetAmt;
            put.minimumPurchase = _assetAmt;
            put.strike = _strike;
            put.expiry = _expiry;
            put.totalPurch = _totalPurch;
            put.tradeable = true;
            if (_price > put.price) {
                put.price = _price;
                //we need to pull in more cash
                uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
                require(balCheck >= refund, "p: not enough cash to bid");
                depositPymt(pymtWeth, pymtCurrency, msg.sender, refund);
            } else if (_price < put.price) {
                put.price = _price;
                //need to refund the put bidder
                withdrawPymt(pymtWeth, pymtCurrency, put.long, refund);
            }
            emit OptionChanged(_p, _assetAmt, _assetAmt, _strike, _price, _expiry);
                
        }
           
    }



    //function for submitting a new ask
     function newAsk(uint _assetAmt, uint _minimumPurchase, uint _strike, uint _price, uint _expiry) payable public {
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "p totalPurchase error: too small amount");
        require(_minimumPurchase.mul(_strike).div(10 ** assetDecimals) > 0, "p: minimum purchase error, too small of a min");
        require(_assetAmt % _minimumPurchase == 0, "p: asset amount needs to be a multiple of the minimum");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= _totalPurch, "p: you dont have enough collateral to write this option");
        depositPymt(pymtWeth, pymtCurrency, msg.sender, _totalPurch);
        puts[p++] = Put(msg.sender, _assetAmt, _minimumPurchase, _strike, _totalPurch, _price, _expiry, false, true, msg.sender, false);
        emit NewAsk(p.sub(1), _assetAmt, _minimumPurchase, _strike, _price, _expiry);
    }
    
    
    //function to cancel a new ask from writter side
    function cancelNewAsk(uint _p) public nonReentrant {
        Put storage put = puts[_p];
        require(msg.sender == put.short && msg.sender == put.long, "p: only short can change an ask");
        require(!put.open, "p: put already open");
        require(!put.exercised, "p: put already exercised");
        put.tradeable = false; 
        put.exercised = true;
        withdrawPymt(pymtWeth, pymtCurrency, put.short, put.totalPurch);
        emit OptionCancelled(_p);
    }


    //function to purchase the first newly written put
    function buyNewOption(uint _p, uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public {
        Put storage put = puts[_p];
        require(put.strike == _strike && put.expiry == _expiry, "p details mismatch: something has changed before execution");
        require(put.expiry > now, "p: This put is already expired");
        require(!put.exercised, "p: This has already been exercised");
        require(put.tradeable, "p: this is not ready to trade");
        require(msg.sender != put.short, "p: you are the short");
        require(put.short != address(0x0) && put.short == put.long, "p: this is not a newAsk");
        require(!put.open, "p: This put is already open");
        require(_assetAmt >= put.minimumPurchase, "purchase size does not meet minimum");
        if (_assetAmt == put.assetAmt) {
            require(_price == put.price, "p: price mismatch");
            uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
            require(balCheck >= put.price, "p: not enough to buy this put");
            transferPymtWithFee(pymtWeth, pymtCurrency, msg.sender, put.short, _price);
            put.open = true; 
            put.long = msg.sender; 
            put.tradeable = false; 
            emit NewOptionBought(_p);
        } else {
            uint proRataPurchase = _assetAmt.mul(10 ** assetDecimals).div(put.assetAmt);
            uint pricePerToken = put.price.mul(10 ** 32).div(put.assetAmt);
            uint proRataPrice = _assetAmt.mul(pricePerToken).div(10 ** 32);
            require(_price == proRataPrice, "p: price doesnt match pro rata price");
            require(put.assetAmt.sub(_assetAmt) >= put.minimumPurchase, "p: remainder too small");
            uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
            require(balCheck >= proRataPrice, "p: not enough to buy this put");
            uint proRataTotalPurchase = put.totalPurch.mul(proRataPurchase).div(10 ** assetDecimals);
            transferPymtWithFee(pymtWeth, pymtCurrency, msg.sender, put.short, proRataPrice);
            puts[p++] = Put(put.short, _assetAmt, put.minimumPurchase, put.strike, proRataTotalPurchase, _price, _expiry, true, false, msg.sender, false);
            emit PoolOptionBought(_p, p.sub(1), put.assetAmt.sub(_assetAmt), put.minimumPurchase, _strike, _price, _expiry);
            //update the current call to become the remainder
            put.assetAmt -= _assetAmt;
            put.price -= _price;
            put.totalPurch -= proRataTotalPurchase;
        }
        
    }    


    

    function buyOptionFromAsk(uint _p, uint _q, uint _price) payable public nonReentrant {
        Put storage openShort = puts[_p];
        Put storage ask = puts[_q];
        require(_p != _q, "p: wrong function for buyback");
        require(_price == ask.price, "p details mismatch: something has changed before execution");
        require(msg.sender == openShort.short, "p: your not the short");
        require(ask.tradeable && !ask.exercised && ask.expiry > now,"p: ask issue");
        require(openShort.open && !openShort.exercised && openShort.expiry > now, "p: short issue");
        require(openShort.strike == ask.strike, "p: not the right strike");
        require(openShort.assetAmt == ask.assetAmt, "p: not the right assetAmt");
        require(openShort.expiry == ask.expiry, "p: not the right expiry");
        //openShort pays the ask long with their existing escrow balances
        require(openShort.totalPurch > _price, "not enough in escrow to buy");
        uint refund = openShort.totalPurch.sub(_price);
        uint feePymt = (_price * fee).div(1e4);
        withdrawPymt(pymtWeth, pymtCurrency, ask.long, _price.sub(feePymt));
        //send the fee
        if (feePymt > 0) SafeERC20.safeTransfer(IERC20(pymtCurrency), feeCollector, feePymt);
        //if newAsk then ask.long == ask.short, if openAsk then ask.long is the one receiving the payment
        
        ask.exercised = true;
        ask.tradeable = false;
        ask.open = false;
        //now withdraw the openShort's total purchase collateral back to them
        withdrawPymt(pymtWeth, pymtCurrency, openShort.short, refund);
        openShort.short = ask.short;
        emit OpenShortRePurchased( _p, _q, openShort.short, _price); 
    }


    //function to set a price of a put as the long, or to turn the open order off
    function setPrice(uint _p, uint _price, bool _tradeable) public {
        Put storage put = puts[_p];
        require((msg.sender == put.long && msg.sender == put.short) || (msg.sender == put.long && put.open), "p: you cant change the price");
        require(put.expiry > now, "p: already expired");
        require(!put.exercised, "p: already exercised");
        put.price = _price;
        put.tradeable = _tradeable;
        emit PriceSet(_p, _price, _tradeable);
    }

    
    //function for someone to purchase an open option
    function buyOpenOption(uint _p, uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public nonReentrant {
        Put storage put = puts[_p];
        require(put.strike == _strike && put.assetAmt == _assetAmt && put.price == _price && put.expiry == _expiry, "p details mismatch: something has changed before execution");
        require(msg.sender != put.long, "p: You already own this"); 
        require(put.open, "p: This put isnt opened yet"); 
        require(put.expiry >= now, "p: This put is already expired");
        require(!put.exercised, "p: This has already been exercised!");
        require(put.tradeable, "p: put not tradeable");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= put.price, "p: not enough to buy this put");
        transferPymtWithFee(pymtWeth, pymtCurrency, msg.sender, put.long, _price);
        if (msg.sender == put.short) {
            withdrawPymt(pymtWeth, pymtCurrency, put.short, put.totalPurch);//send the money back to the put writer
            put.exercised = true;
            put.open = false;
        }
        
        put.tradeable = false;
        put.long = msg.sender;
        emit OpenOptionPurchased(_p);
    }

    //function to physiputy exercise
    function exercise(uint _p) payable public nonReentrant {
        Put storage put = puts[_p];
        require(put.open, "p: This isnt open");
        require(put.expiry >= now, "p: This put is already expired");
        require(!put.exercised, "p: This has already been exercised!");
        require(msg.sender == put.long, "p: You dont own this put");
        uint balCheck = assetWeth ? msg.value : IERC20(asset).balanceOf(msg.sender);
        require(balCheck >= put.assetAmt, "p: not enough of the asset to close this put");
        put.exercised = true;
        put.open = false;
        put.tradeable = false;
        if (assetWeth) {
            require(msg.value == put.assetAmt, "p: eth mismatch, transferring the incorrect amount");
        }
        transferPymt(assetWeth, asset, msg.sender, put.short, put.assetAmt);
        withdrawPymt(pymtWeth, pymtCurrency, msg.sender, put.totalPurch);
        emit OptionExercised(_p, false);
    }

    //function to cash close with the uniswap flash swaps tool - bool is a dummy to match puts
    function cashClose(uint _p) payable public nonReentrant {
        require(cashCloseOn, "p: This is not setup to cash close");
        Put storage put = puts[_p];
        require(put.open, "p: This isnt open");
        require(put.expiry >= now, "p: This put is already expired");
        require(!put.exercised, "p: This has already been exercised!");
        require(msg.sender == put.long, "p: You dont own this put");
        uint pymtEst = estIn(put.assetAmt);
        require(pymtEst < put.totalPurch, "p: this put is not in the money"); 
        address to = assetWeth ? address(this) : put.short;
        put.exercised = true;
        put.open = false;
        put.tradeable = false;
        swap(pymtCurrency, put.assetAmt, pymtEst, to);
        if (assetWeth) {
            withdrawPymt(assetWeth, asset, put.short, put.assetAmt);
        }
        put.totalPurch -= pymtEst;  
        
        withdrawPymt(pymtWeth, pymtCurrency, put.long, put.totalPurch);
        emit OptionExercised(_p, true);
    }
    
    //function to return an expired put back to the short assuming it has not been exercised
    function returnExpired(uint _p) payable public nonReentrant {
        Put storage put = puts[_p];
        require(!put.exercised, "p: This has been exercised");
        require(put.expiry < now, "p: Not expired yet");
        require(msg.sender == put.short, "p: You cant do that");
        put.tradeable = false;
        put.open = false;
        put.exercised = true;
        withdrawPymt(pymtWeth, pymtCurrency, put.short, put.totalPurch);//send back their deposit
        emit OptionReturned(_p);
    }


    /**
    //function to roll an expired put into a new one
    function rollExpired(uint _p, uint _assetAmt, uint _newStrike, uint _price, uint _newExpiry) payable public nonReentrant {
        Put storage put = puts[_p];
        require(!put.exercised, "p: This has been exercised");
        require(put.expiry < now, "p: Not expired yet");
        require(msg.sender == put.short, "p: You cant do that");
        require(_newExpiry > now, "p: this is already in the past");
        uint _totalPurch = (_assetAmt).mul(_newStrike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "totalPurchase error: too small amount");
        uint refund = (_totalPurch > put.totalPurch) ? _totalPurch.sub(put.totalPurch) : put.totalPurch.sub(_totalPurch);
        put.open = false;
        put.exercised = true;
        put.tradeable = false;
        if (_totalPurch > put.totalPurch) {
            uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
            require(balCheck >= refund, "p: you dont have enough collateral to sell this option");
            depositPymt(pymtWeth, pymtCurrency, msg.sender, refund);
        } else if (_totalPurch < put.totalPurch) {
            withdrawPymt(pymtWeth, pymtCurrency, msg.sender, refund);
        }
        puts[p++] = Put(msg.sender, _assetAmt, _newStrike, _totalPurch, _price, _newExpiry, false, true, msg.sender, false);
        emit OptionRolled(_p, p.sub(1), _assetAmt, _newStrike, _price, _newExpiry);
    }

    ****/
    
    //function to transfer an owned call (only long) for the primary purpose of leveraging external swap functions to physically exercise in the case of no cash closing
    function transferAndSwap(uint _p, address payable newOwner, address[] memory path) external {
        Put storage put = puts[_p];
        require(put.expiry >= block.timestamp, "p: This put is already expired");
        require(!put.exercised, "p: This has already been exercised!");
        require(put.open, "p: only open puts can be swapped");
        require(msg.sender == put.long, "p: You dont own this put");
        require(newOwner != put.short, "p: you cannot transfer to the short");
        put.long = newOwner; //set long to new owner
        if (path.length > 0) {
            require(Address.isContract(newOwner));
            require(path.length > 2, "use the normal cash close method for single pool swaps");
            //swapping from asset to payment currency - need asset first and payment currency last in the path
            require(path[0] == pymtCurrency && path[path.length - 1] == asset, "your not swapping the right currencies");
            IHedgeySwap(newOwner).hedgeyPutSwap(msg.sender, _p, put.assetAmt, path);
        }
        
        emit OptionTransferred(_p, newOwner);
    }
    
    
    //************SWAP SPECIFIC FUNCTIONS USED FOR THE CASH CLOSE METHODS***********************/

    //function to swap from this contract to uniswap pool
    function swap(address token, uint out, uint _in, address to) internal {
        SafeERC20.safeTransfer(IERC20(token), uniPair, _in); //sends the asset amount in to the swap
        address token0 = IUniswapV2Pair(uniPair).token0();
        if (token == token0) {
            IUniswapV2Pair(uniPair).swap(0, out, to, new bytes(0));
        } else {
            IUniswapV2Pair(uniPair).swap(out, 0, to, new bytes(0));
        }
        
    }
    
    
    function estIn(uint amountOut) public view returns (uint amountIn) {
        (uint resA, uint resB,) = IUniswapV2Pair(uniPair).getReserves();
        address token1 = IUniswapV2Pair(uniPair).token1();
        amountIn = (token1 == pymtCurrency) ? UniswapV2Library.getAmountIn(amountOut, resA, resB) : UniswapV2Library.getAmountIn(amountOut, resB, resA);
    }


    /***events*****/
    event NewBid(uint _i, uint _assetAmt, uint _minimumPurchase, uint _strike, uint _price, uint _expiry);
    event NewAsk(uint _i, uint _assetAmt, uint _minimumPurchase, uint _strike, uint _price, uint _expiry);
    event NewOptionSold(uint _i);
    event NewOptionBought(uint _i);
    event OpenOptionSold(uint _i, uint _j, address _long, uint _price);
    event OpenShortRePurchased(uint _i, uint _j, address _short, uint _price);
    event OpenOptionPurchased(uint _i);
    event OptionChanged(uint _i, uint _assetAmt, uint _minimumPurchase, uint _strike, uint _price, uint _expiry);
    event PriceSet(uint _i, uint _price, bool _tradeable);
    event OptionExercised(uint _i, bool cashClosed);
    event OptionRolled(uint _i, uint _j, uint _assetAmt, uint _minimumPurchase, uint _strike, uint _price, uint _expiry);
    event OptionReturned(uint _i);
    event OptionCancelled(uint _i);
    event OptionTransferred(uint _i, address newOwner);
    event PoolOptionBought(uint i, uint _j, uint _assetAmt, uint _minimumPurchase, uint _strike, uint _price, uint _expiry);
    event AMMUpdate(bool _cashCloseOn);
}


contract HedgeyPutsFactory {
    
    mapping(address => mapping(address => address)) public pairs;
    address payable public collector;
    uint public fee;

    constructor (address payable _collector, uint _fee) public {
        collector = _collector;
        fee = _fee;
    }
    
    function changeFee(uint _newFee, address payable _collector) public {
        require(msg.sender == collector, "only the collector");
        fee = _newFee;
        collector = _collector;
    }

    
    function getPair(address asset, address pymtCurrency) public view returns (address pair) {
        pair = pairs[asset][pymtCurrency];
    }
    

    function createContract(address asset, address pymtCurrency) public {
        require(asset != pymtCurrency, "same currencies");
        require(pairs[asset][pymtCurrency] == address(0), "contract exists");
        HedgeyPuts putContract = new HedgeyPuts(asset, pymtCurrency, collector, fee);
        pairs[asset][pymtCurrency] = address(putContract);
        //totalContracts.push(address(putContract));
        emit NewPairCreated(asset, pymtCurrency, address(putContract));
    }

    event NewPairCreated(address _asset, address _pymtCurrency, address _pair);
}