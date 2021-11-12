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
    
    

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
    

    
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
   
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    
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
    function hedgeyCallSwap(address payable originalOwner, uint _c, uint _totalPurchase, address[] memory path, bool cashBack) external;
}

contract HedgeyCalls is ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public asset;
    address public pymtCurrency;
    uint public assetDecimals;
    address public uniPair; 
    address payable public weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //weth address    
    uint public fee;
    address payable public feeCollector;
    uint public c = 0;
    address public uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //AMM factory address
    bool private assetWeth;
    bool private pymtWeth;
    bool public cashCloseOn;
    

    constructor(address _asset, address _pymtCurrency, address payable _feeCollector, uint _fee) public {
        require(_asset != _pymtCurrency);
        asset = _asset;
        pymtCurrency = _pymtCurrency;
        feeCollector = _feeCollector;
        fee = _fee;
        assetDecimals = IERC20(_asset).decimals();
        uniPair = IUniswapV2Factory(uniFactory).getPair(asset, pymtCurrency);
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
    
    struct Call {
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

    
    mapping (uint => Call) public calls;

    
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
        require(msg.sender == feeCollector);
        fee = _fee;
        feeCollector = _collector;
    }

    
    //function anyone can call after the contract is set to update if there was no AMM before but now there is
    function updateAMM() public {
        uniPair = IUniswapV2Factory(uniFactory).getPair(asset, pymtCurrency);
        if (uniPair == address(0x0)) {
            cashCloseOn = false;
        } else {
            cashCloseOn = true;
        }
        emit AMMUpdate(cashCloseOn);
        
    }


    //CALL FUNCTIONS GOING HERE**********************************************************

    //function for someone wanting to buy a new call
    function newBid(uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public {
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "c: totalPurchase error: too small amount");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= _price, "c: not enough cash to bid");
        depositPymt(pymtWeth, pymtCurrency, msg.sender, _price); 
        calls[c++] = Call(address(0x0), _assetAmt, _assetAmt, _strike, _totalPurch, _price, _expiry, false, true, msg.sender, false);
        emit NewBid(c.sub(1), _assetAmt, _assetAmt, _strike, _price, _expiry);
    }
    
    //function to cancel a new bid
    function cancelNewBid(uint _c) public nonReentrant {
        Call storage call = calls[_c];
        require(msg.sender == call.long, "c: only long can cancel a bid");
        require(!call.open, "c: call already open");
        require(!call.exercised, "c: call already exercised");
        require(call.short == address(0x0), "c: this is not a new bid");
        call.tradeable = false;
        call.exercised = true;
        withdrawPymt(pymtWeth, pymtCurrency, call.long, call.price);
        emit OptionCancelled(_c);
    }

    
    function sellOpenOptionToNewBid(uint _c, uint _d, uint _price) payable public nonReentrant {
        Call storage openCall = calls[_c];
        Call storage newBid = calls[_d];
        require(_c != _d, "c: wrong sale function");
        require(_price == newBid.price, "c: price changed before you could execute");
        require(msg.sender == openCall.long, "c: you dont own this");
        require(openCall.strike == newBid.strike, "c: not the right strike");
        require(openCall.assetAmt == newBid.assetAmt, "c: not the right assetAmt");
        require(openCall.expiry == newBid.expiry, "c: not the right expiry");
        require(newBid.short == address(0x0), "c: this is not a new bid"); //newBid always sets the short address to 0x0
        require(openCall.open && !newBid.open && newBid.tradeable && !openCall.exercised && !newBid.exercised && openCall.expiry > now && newBid.expiry > now, "something is wrong");
        newBid.exercised = true;
        newBid.tradeable = false;
        uint feePymt = (newBid.price * fee).div(1e4);
        uint shortPymt = newBid.price.sub(feePymt);
        withdrawPymt(pymtWeth, pymtCurrency, openCall.long, shortPymt);
        if (feePymt > 0) SafeERC20.safeTransfer(IERC20(pymtCurrency), feeCollector, feePymt);
        openCall.long = newBid.long;
        openCall.price = newBid.price;
        openCall.tradeable = false;
        emit OpenOptionSold( _c, _d, openCall.long, _price);
    }

    //function for someone to write the call for the open bid
    //, uint _strike, uint _assetAmt, uint _price, uint _expiry
    function sellNewOption(uint _c, uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public nonReentrant {
        Call storage call = calls[_c];
        require(call.strike == _strike && call.assetAmt == _assetAmt && call.price == _price && call.expiry == _expiry, "c details issue: something changed");
        require(call.short == address(0x0));
        require(msg.sender != call.long, "c: you are the long");
        require(call.expiry > now, "c: This is already expired");
        require(call.tradeable, "c: not tradeable");
        require(!call.open, "c: call already open");
        require(!call.exercised, "c: this has been exercised");
        uint feePymt = (call.price * fee).div(1e4);
        uint shortPymt = (call.price).sub(feePymt);
        uint balCheck = assetWeth ? msg.value : IERC20(asset).balanceOf(msg.sender);
        require(balCheck >= call.assetAmt, "c: not enough cash to bid");
        depositPymt(assetWeth, asset, msg.sender, call.assetAmt);
        if (feePymt > 0) SafeERC20.safeTransfer(IERC20(pymtCurrency), feeCollector, feePymt);
        withdrawPymt(pymtWeth, pymtCurrency, msg.sender, shortPymt);
        call.short = msg.sender;
        call.tradeable = false;
        call.open = true;
        emit NewOptionSold(_c);
    }

    
    function changeNewOption(uint _c, uint _assetAmt, uint _minimumPurchase, uint _strike, uint _price, uint _expiry) payable public nonReentrant {
        Call storage call = calls[_c];
        require(call.long == msg.sender, "c: you do not own this call");
        require(!call.exercised, "c: this has been exercised");
        require(!call.open, "c: this is already open");
        require(call.tradeable, "c: this is not a tradeable option");
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "c: totalPurchase error: too small amount");
        //lets check if this is a new ask or new bid
        //if its a newAsk
        if (msg.sender == call.short) {
            require(_minimumPurchase.mul(_strike).div(10 ** assetDecimals) > 0, "c: minimum purchase error, too small of a minimum");
            require(_assetAmt % _minimumPurchase == 0, "c: asset amount needs to be a multiple of the minimum");
            uint refund = (call.assetAmt > _assetAmt) ? call.assetAmt.sub(_assetAmt) : _assetAmt.sub(call.assetAmt);
            call.strike = _strike;
            call.price = _price;
            call.expiry = _expiry;
            call.minimumPurchase = _minimumPurchase;
            call.totalPurch = _totalPurch;
            call.tradeable = true;
            if (call.assetAmt > _assetAmt) {
                call.assetAmt = _assetAmt;
                withdrawPymt(assetWeth, asset, call.short, refund);
            } else if (call.assetAmt < _assetAmt) {
                call.assetAmt = _assetAmt;
                uint balCheck = assetWeth ? msg.value : IERC20(asset).balanceOf(msg.sender);
                require(balCheck >= refund, "c: not enough to change this call option");
                depositPymt(assetWeth, asset, msg.sender, refund);
            }
            
            emit OptionChanged(_c, _assetAmt, _minimumPurchase, _strike, _price, _expiry);

        } else if (call.short == address(0x0)) {
            //its a newBid
            uint refund = (_price > call.price) ? _price.sub(call.price) : call.price.sub(_price);
            call.assetAmt = _assetAmt;
            call.minimumPurchase = _assetAmt;
            call.strike = _strike;
            call.expiry = _expiry;
            call.totalPurch = _totalPurch;
            call.tradeable = true;
            if (_price > call.price) {
                call.price = _price;
                uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
                require(balCheck >= refund, "c: not enough cash to bid");
                depositPymt(pymtWeth, pymtCurrency, msg.sender, refund);
            } else if (_price < call.price) {
                call.price = _price;
                withdrawPymt(pymtWeth, pymtCurrency, call.long, refund);
            }
            
            emit OptionChanged(_c, _assetAmt, _minimumPurchase, _strike, _price, _expiry);    
        }
           
    } 
    

    //function to write a new call
    function newAsk(uint _assetAmt, uint _minimumPurchase, uint _strike, uint _price, uint _expiry) payable public {
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "c: totalPurchase error: too small amount");
        require(_minimumPurchase.mul(_strike).div(10 ** assetDecimals) > 0, "c: minimum purchase error, too small of a min");
        require(_assetAmt % _minimumPurchase == 0, "c: asset amount needs to be a multiple of the minimum");
        uint balCheck = assetWeth ? msg.value : IERC20(asset).balanceOf(msg.sender);
        require(balCheck >= _assetAmt, "c: not enough to sell this call option");
        depositPymt(assetWeth, asset, msg.sender, _assetAmt);
        calls[c++] = Call(msg.sender, _assetAmt, _minimumPurchase, _strike, _totalPurch, _price, _expiry, false, true, msg.sender, false);
        emit NewAsk(c.sub(1), _assetAmt, _minimumPurchase, _strike, _price, _expiry);
    }


    //function to cancel a new ask from writter side
    function cancelNewAsk(uint _c) public nonReentrant {
        Call storage call = calls[_c];
        require(msg.sender == call.short && msg.sender == call.long, "c: only short can change an ask");
        require(!call.open, "c: call already open");
        require(!call.exercised, "c: call already exercised");
        call.tradeable = false;
        call.exercised = true;
        withdrawPymt(assetWeth, asset, call.short, call.assetAmt);
        emit OptionCancelled(_c);
    }
    
    //function to purchase a new call that hasn't changed hands yet
    //, uint _strike, uint _assetAmt, uint _price, uint _expiry
    function buyNewOption(uint _c, uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public {
        Call storage call = calls[_c];
        require(call.strike == _strike && call.expiry == _expiry, "c details issue: something changed");
        require(msg.sender != call.short, "c: you cannot buy this");
        require(call.short != address(0x0) && call.short == call.long, "c: this option is not a new ask");
        require(call.expiry > now, "c: This call is already expired");
        require(!call.exercised, "c: This has already been exercised");
        require(call.tradeable, "c: This isnt tradeable yet");
        require(!call.open, "c: This call is already open");
        require(_assetAmt >= call.minimumPurchase, "purchase size does not meet minimum");
        if (_assetAmt == call.assetAmt) {
            require(_price == call.price, "c: price does not match");
            uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
            require(balCheck >= call.price, "c: not enough to sell this call option");
            transferPymtWithFee(pymtWeth, pymtCurrency, msg.sender, call.short, _price);
            call.open = true;
            call.long = msg.sender;
            call.tradeable = false;
            emit NewOptionBought(_c);
        } else {
            uint proRataPurchase = _assetAmt.mul(10 ** assetDecimals).div(call.assetAmt);
            uint pricePerToken = call.price.mul(10 ** 32).div(call.assetAmt);
            uint proRataPrice = _assetAmt.mul(pricePerToken).div(10 ** 32);
            require(_price == proRataPrice, "c: price doesnt match pro rata price");
            require(call.assetAmt.sub(_assetAmt) >= call.minimumPurchase, "c: remainder too small");
            uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
            require(balCheck >= proRataPrice, "c: not enough to sell this call option");
            uint proRataTotalPurchase = call.totalPurch.mul(proRataPurchase).div(10 ** assetDecimals);
            transferPymtWithFee(pymtWeth, pymtCurrency, msg.sender, call.short, proRataPrice);
            calls[c++] = Call(call.short, _assetAmt, call.minimumPurchase, call.strike, proRataTotalPurchase, _price, _expiry, true, false, msg.sender, false);
            emit PoolOptionBought(_c, c.sub(1), call.assetAmt.sub(_assetAmt), call.minimumPurchase, _strike, _price, _expiry);
            //update the current call to become the remainder
            call.assetAmt -= _assetAmt;
            call.price -= _price;
            call.totalPurch -= proRataTotalPurchase;
            
        }
        
    }
    

    
    /**function to buy an openAsk or newAsk and then replace the long from one position with the long of the other position and remove openShort from obligation */
    function buyOptionFromAsk(uint _c, uint _d, uint _price) payable public nonReentrant {
        Call storage openShort = calls[_c];
        Call storage ask = calls[_d];
        require(msg.sender == openShort.short, "c: your not the short");
        require(ask.short != address(0x0), "c: this is a newBid");
        require(_price == ask.price, "c: price changed before executed");
        require(ask.tradeable && !ask.exercised && ask.expiry > now,"c: ask issue");
        require(openShort.open && !openShort.exercised && openShort.expiry > now, "c: short issue");
        require(openShort.strike == ask.strike, "c: strikes do not match");
        require(openShort.assetAmt == ask.assetAmt, "c: asset amount does not match");
        require(openShort.expiry == ask.expiry, "c: expiry does not match");
        require(_c != _d, "c: wrong function to buyback");
        //openShort pays the ask
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= ask.price, "c: not enough to buy this put");
        transferPymtWithFee(pymtWeth, pymtCurrency, openShort.short, ask.long, _price); //if newAsk then ask.long == ask.short, if openAsk then ask.long is the one receiving the payment
        //all the checks having been matched - now we assign the openAsk short to the openShort short position
        //then we close out the openAsk position
        ask.exercised = true;
        ask.tradeable = false;
        ask.open = false;
        //now withdraw the openShort's asset back to them
        withdrawPymt(assetWeth, asset, openShort.short, openShort.assetAmt);
        openShort.short = ask.short;
        emit OpenShortRePurchased( _c, _d, openShort.short, _price);
    }
    


    //this function lets the long set a new price on the call - typically used for existing open positions
    function setPrice(uint _c, uint _price, bool _tradeable) public {
        Call storage call = calls[_c];
        require((msg.sender == call.long && msg.sender == call.short) || (msg.sender == call.long && call.open), "c: you cant change the price");
        require(call.expiry > now, "c: already expired");
        require(!call.exercised, "c: already expired");
        call.price = _price; 
        call.tradeable = _tradeable;
        emit PriceSet(_c, _price, _tradeable);
    }



    //use this function to sell existing calls
    //uint _strike, uint _assetAmt, uint _price, uint _expiry
    function buyOpenOption(uint _c, uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public nonReentrant {
        Call storage call = calls[_c];
        require(call.strike == _strike && call.assetAmt == _assetAmt && call.price == _price && call.expiry == _expiry, "c: something changed");
        require(msg.sender != call.long, "c: You already own this");
        require(call.open, "c: This call isnt opened yet");
        require(call.expiry >= now, "c: This call is already expired");
        require(!call.exercised, "c: This has already been exercised");
        require(call.tradeable, "c: not tradeable");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= call.price, "c: not enough to sell this call option");
        transferPymtWithFee(pymtWeth, pymtCurrency, msg.sender, call.long, call.price);
        if (msg.sender == call.short) {
            call.exercised = true;
            call.open = false;
            withdrawPymt(assetWeth, asset, call.short, call.assetAmt);
        }
        call.tradeable = false;
        call.long = msg.sender;
        emit OpenOptionPurchased(_c);
    }


    //this is the basic exercise execution function that needs to be invoked prior to maturity to receive the physical asset
    function exercise(uint _c) payable public nonReentrant {
        Call storage call = calls[_c];
        require(call.open, "c: This isnt open");
        require(call.expiry >= now, "c: This call is already expired");
        require(!call.exercised, "c: This has already been exercised!");
        require(msg.sender == call.long, "c: You dont own this call");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= call.totalPurch, "c: not enough to exercise this call option");
        call.exercised = true;
        call.open = false;
        call.tradeable = false;
        if(pymtWeth) {
            require(msg.value == call.totalPurch,"eth mismatch on value to purchase the asset");
        }
        transferPymt(pymtWeth, pymtCurrency, msg.sender, call.short, call.totalPurch);   
        withdrawPymt(assetWeth, asset, call.long, call.assetAmt);
        emit OptionExercised(_c, false);
    }


    //this is the exercise alternative for ppl who want to receive payment currency instead of the underlying asset
    function cashClose(uint _c, bool cashBack) payable public nonReentrant {
        require(cashCloseOn, "c: this pair cannot be cash closed");
        Call storage call = calls[_c];
        require(call.open, "c: This isnt open");
        require(call.expiry >= now, "c: This call is already expired");
        require(!call.exercised, "c: This has already been exercised!");
        require(msg.sender == call.long, "c: You dont own this call");
   
        uint assetIn = estIn(call.totalPurch);
        require(assetIn < (call.assetAmt), "c: Underlying is not in the money");
        
        address to = pymtWeth ? address(this) : call.short;
        call.exercised = true;
        call.open = false;
        call.tradeable = false;
        swap(asset, call.totalPurch, assetIn, to);
        if (pymtWeth) {
            withdrawPymt(pymtWeth, pymtCurrency, call.short, call.totalPurch);
        }
        
        call.assetAmt -= assetIn;
        
        if (cashBack) {
            
            uint cashEst = estCashOut(call.assetAmt);
            address _to = pymtWeth ? address(this) : call.long;
            swap(asset, cashEst, call.assetAmt, _to);
            if (pymtWeth) {
                withdrawPymt(pymtWeth, pymtCurrency, call.long, cashEst); 
            }
        } else {
            withdrawPymt(assetWeth, asset, call.long, call.assetAmt);
        }
        
        emit OptionExercised(_c, true);
    }


    

    //returns an expired call back to the short
    function returnExpired(uint _c) public nonReentrant {
        Call storage call = calls[_c];
        require(!call.exercised, "c: This has been exercised");
        require(call.expiry < now, "c: Not expired yet"); 
        require(msg.sender == call.short, "c: You cant do that");
        call.tradeable = false;
        call.open = false;
        call.exercised = true;
        withdrawPymt(assetWeth, asset, call.short, call.assetAmt);
        emit OptionReturned(_c);
    }
    
    /**

    //function to roll expired call into a new short contract
    function rollExpired(uint _c, uint _assetAmt, uint _minimumPurchase, uint _newStrike, uint _price, uint _newExpiry) payable public nonReentrant {
        Call storage call = calls[_c]; 
        require(!call.exercised, "c: This has been exercised");
        require(call.expiry < now, "c: Not expired yet"); 
        require(msg.sender == call.short, "c: You cant do that");
        require(_newExpiry > now, "c: this is already in the past");
        require(_assetAmt % _minimumPurchase == 0, "c: asset amount needs to be a multiple of the minimum");
        uint refund = (call.assetAmt > _assetAmt) ? call.assetAmt.sub(_assetAmt) : _assetAmt.sub(call.assetAmt);
        uint _totalPurch = (_assetAmt).mul(_newStrike).div(10 ** assetDecimals);
        require(_totalPurch > 0 && _minimumPurchase.mul(_newStrike).div(10 ** assetDecimals) > 0, "c: totalPurchase error: too small amount");
        call.tradeable = false;
        call.open = false;
        call.exercised = true;
        if (call.assetAmt > _assetAmt) {
            withdrawPymt(assetWeth, asset, call.short, refund); 
        } else if (call.assetAmt < _assetAmt) {
            uint balCheck = assetWeth ? msg.value : IERC20(asset).balanceOf(msg.sender);
            require(balCheck >= refund, "c: not enough to change this call option");
            depositPymt(assetWeth, asset, msg.sender, refund); 
        }
        
        calls[c++] = Call(msg.sender, _assetAmt, _minimumPurchase, _newStrike, _totalPurch, _price, _newExpiry, false, true, msg.sender, false);
        emit OptionRolled(_c, c.sub(1), _assetAmt, _minimumPurchase, _newStrike, _price, _newExpiry);
    }

    
    ****/
    //function to transfer an owned call (only long) for the primary purpose of leveraging external swap functions to physically exercise in the case of no cash closing
    function transferAndSwap(uint _c, address payable newOwner, address[] memory path, bool cashBack) external {
        Call storage call = calls[_c];
        require(call.expiry >= block.timestamp, "c: This call is already expired");
        require(!call.exercised, "c: This has already been exercised!");
        require(call.open, "c: only open calls can be transferred");
        require(msg.sender == call.long, "c: You dont own this call");
        require(newOwner != call.short, "c: you cannot transfer to the short");
        call.long = newOwner; //set long to new owner
        if (path.length > 0) {
            require(path.length > 2, "use the normal cash close method for single pool swaps");
            //swapping from asset to payment currency - need asset first and payment currency last in the path
            require(path[0] == asset && path[path.length - 1] == pymtCurrency, "your not swapping the right currencies");
            IHedgeySwap(newOwner).hedgeyCallSwap(msg.sender, _c, call.totalPurch, path, cashBack);
        }
        
        emit OptionTransferred(_c, newOwner);
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
    
    function estCashOut(uint amountIn) public view returns (uint amountOut) {
        (uint resA, uint resB,) = IUniswapV2Pair(uniPair).getReserves();
        address token1 = IUniswapV2Pair(uniPair).token1();
        amountOut = (token1 == pymtCurrency) ? UniswapV2Library.getAmountOut(amountIn, resA, resB) : UniswapV2Library.getAmountOut(amountIn, resB, resA);
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