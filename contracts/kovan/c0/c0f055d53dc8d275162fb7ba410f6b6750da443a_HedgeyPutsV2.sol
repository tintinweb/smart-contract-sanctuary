/**
 *Submitted for verification at Etherscan.io on 2021-05-07
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

interface IHedgeyStaking {
    function receiveFee(uint amt, address token) external;
    function addWhitelist(address hedgey) external;
}


contract HedgeyPutsV2 is ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public asset; 
    address public pymtCurrency; 
    uint public assetDecimals;
    address public uniPair;
    address public unindex0;
    address public unindex1;
    address payable public weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    uint public fee;
    bool public feeCollectorSet; //set to false until the staking contract has been defined
    address payable public feeCollector;
    uint public p = 0; 
    address public uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    bool private assetWeth;
    bool private pymtWeth;
    bool public cashCloseOn;
    

    constructor(address _asset, address _pymtCurrency, address payable _feeCollector, uint _fee, bool _feeCollectorSet) public {
        asset = _asset;
        pymtCurrency = _pymtCurrency;
        feeCollector = _feeCollector;
        fee = _fee;
        feeCollectorSet = _feeCollectorSet;
        assetDecimals = IERC20(_asset).decimals();
        uniPair = IUniswapV2Factory(uniFactory).getPair(_asset, _pymtCurrency);
        if (uniPair == address(0x0)) {
            cashCloseOn = false;
            unindex0 = address(0x0);
            unindex1 = address(0x0);
        } else {
            cashCloseOn = true;
            unindex0 = IUniswapV2Pair(uniPair).token0();
            unindex1 = IUniswapV2Pair(uniPair).token1();
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

    //admin function to update the fee amount
    function changeFee(uint _fee) external {
        require(msg.sender == feeCollector, "only fee collector");
        fee = _fee;
    }

    function changeCollector(address payable _collector, bool _set) external returns (bool) {
        require(msg.sender == feeCollector, "only fee collector");
        feeCollector = _collector;
        feeCollectorSet = _set; //this tells us if we've set our fee collector to the smart contract handling the fees, otherwise keep false
        return _set;
    }

    function updateAMM() public returns (bool) {
        uniPair = IUniswapV2Factory(uniFactory).getPair(asset, pymtCurrency);
        if (uniPair == address(0x0)) {
            cashCloseOn = false;
            unindex0 = address(0x0);
            unindex1 = address(0x0);
        } else {
            cashCloseOn = true;
            unindex0 = IUniswapV2Pair(uniPair).token0();
            unindex1 = IUniswapV2Pair(uniPair).token1();
        }
        return cashCloseOn;
        emit AMMUpdate(cashCloseOn);
    }

    
    // PUT FUNCTIONS  **********************************************

    //function for someone wanting to buy a new put
    function newBid(uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public {
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "totalPurchase error: too small amount");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= _price, "insufficent purchase cash");
        depositPymt(pymtWeth, pymtCurrency, msg.sender, _price); //handles weth and token deposits into contract
        puts[p++] = Put(address(0x0), _assetAmt, _strike, _totalPurch, _price, _expiry, false, true, msg.sender, false);
        emit NewBid(p.sub(1), _assetAmt, _strike, _price, _expiry);
    }


    function cancelNewBid(uint _p) public nonReentrant {
        Put storage put = puts[_p];
        require(msg.sender == put.long, "only long can cancel a bid");
        require(!put.open, "put already open");
        require(!put.exercised, "put already exercised");
        require(put.short == address(0x0)); 
        put.tradeable = false;
        put.exercised = true;
        withdrawPymt(pymtWeth, pymtCurrency, put.long, put.price);
        emit OptionCancelled(_p);
    }

    //function for an existing long to sell position to a new bidder
    function sellOpenOptionToNewBid(uint _p, uint _q, uint _price) payable public nonReentrant {
        Put storage openPut = puts[_p];
        Put storage newBid = puts[_q];
        require(_price == newBid.price, "price changed before execution");
        require(msg.sender == openPut.long, "you dont own this");
        require(openPut.strike == newBid.strike, "not the right strike");
        require(openPut.assetAmt == newBid.assetAmt, "not the right assetAmt");
        require(openPut.expiry == newBid.expiry, "not the right expiry");
        require(newBid.short == address(0x0), "newBid is not new");
        require(openPut.open && !newBid.open && newBid.tradeable && !openPut.exercised && !newBid.exercised && openPut.expiry > now && newBid.expiry > now, "something is wrong");
        //close out our new bid
        newBid.exercised = true;
        newBid.tradeable = false;
        uint feePymt = (newBid.price * fee).div(1e4);
        uint remainder = newBid.price.sub(feePymt);
        withdrawPymt(pymtWeth, pymtCurrency, openPut.long, remainder);
        SafeERC20.safeTransfer(IERC20(pymtCurrency), feeCollector, feePymt);
        if (feeCollectorSet) {
            IHedgeyStaking(feeCollector).receiveFee(feePymt, pymtCurrency); //this simple expression will default to true if the fee collector hasn't been set, and if it has will run the specific receive fee function
        }
        //assign the put.long
        openPut.long = newBid.long;
        openPut.price = newBid.price;
        openPut.tradeable = false;
        emit OpenOptionSold(_p, _q, openPut.long, _price);
    }

    //function for someone to write the put for the open bid
    function sellNewOption(uint _p, uint _strike, uint _assetAmt, uint _price, uint _expiry) payable public {
        Put storage put = puts[_p];
        require(put.strike == _strike && put.assetAmt == _assetAmt && put.price == _price && put.expiry == _expiry, "details mismatch: something has changed before execution");
        require(put.short == address(0x0));
        require(msg.sender != put.long, "you already own this");
        require(put.expiry > now, "This is already expired");
        require(put.tradeable, "not tradeable");
        require(!put.open, "put not open");
        require(!put.exercised, "this has been exercised");
        uint feePymt = (put.price * fee).div(1e4);
        uint shortPymt = (put.totalPurch).add(feePymt).sub(put.price); //net amount the short must send into the contract for escrow
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= shortPymt, "sell new option: insufficent collateral");
        depositPymt(pymtWeth, pymtCurrency, msg.sender, shortPymt);
        SafeERC20.safeTransfer(IERC20(pymtCurrency), feeCollector, feePymt);
        if (feeCollectorSet) {
            IHedgeyStaking(feeCollector).receiveFee(feePymt, pymtCurrency);
        }
        put.open = true;
        put.short = msg.sender;
        put.tradeable = false;
        emit NewOptionSold(_p);
    }


    function changeNewOption(uint _p, uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public nonReentrant {
        Put storage put = puts[_p];
        require(put.long == msg.sender, "you do not own this put");
        require(!put.exercised, "this has been exercised");
        require(!put.open, "this is already open");
        require(put.tradeable, "this is not a tradeable option");
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "totalPurchase error: too small amount");
        //lets check if this is a new ask or new bid
        //if its a newAsk
        if (msg.sender == put.short) {
            uint refund = (put.totalPurch > _totalPurch) ? put.totalPurch.sub(_totalPurch) : _totalPurch.sub(put.totalPurch);
            uint oldPurch = put.totalPurch;
            put.strike = _strike;
            put.totalPurch = _totalPurch;
            put.assetAmt = _assetAmt;
            put.price = _price;
            put.expiry = _expiry;
            put.tradeable = true;
            if (oldPurch > _totalPurch) {
                withdrawPymt(pymtWeth, pymtCurrency, put.short, refund);
            } else if (oldPurch < _totalPurch) {
                uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
                require(balCheck >= refund, "not enough to change this put option");
                depositPymt(pymtWeth, pymtCurrency, msg.sender, refund);
            }
            emit OptionChanged(_p, _assetAmt, _strike, _price, _expiry);

        } else if (put.short == address(0x0)) {
            //its a newBid
            uint refund = (_price > put.price) ? _price.sub(put.price) : put.price.sub(_price);
            put.assetAmt = _assetAmt;
            put.strike = _strike;
            put.expiry = _expiry;
            put.totalPurch = _totalPurch;
            put.tradeable = true;
            if (_price > put.price) {
                put.price = _price;
                //we need to pull in more cash
                uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
                require(balCheck >= refund, "not enough cash to bid");
                depositPymt(pymtWeth, pymtCurrency, msg.sender, refund);
            } else if (_price < put.price) {
                put.price = _price;
                //need to refund the put bidder
                withdrawPymt(pymtWeth, pymtCurrency, put.long, refund);
            }
            emit OptionChanged(_p, _assetAmt, _strike, _price, _expiry);
                
        }
           
    }



    //function for submitting a new ask
     function newAsk(uint _assetAmt, uint _strike, uint _price, uint _expiry) payable public {
        uint _totalPurch = _assetAmt.mul(_strike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "totalPurchase error: too small amount");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= _totalPurch, "you dont have enough collateral to write this option");
        depositPymt(pymtWeth, pymtCurrency, msg.sender, _totalPurch);
        puts[p++] = Put(msg.sender, _assetAmt, _strike, _totalPurch, _price, _expiry, false, true, msg.sender, false);
        emit NewAsk(p.sub(1), _assetAmt, _strike, _price, _expiry);
    }
    
    
    //function to cancel a new ask from writter side
    function cancelNewAsk(uint _p) public nonReentrant {
        Put storage put = puts[_p];
        require(msg.sender == put.short && msg.sender == put.long, "only short can change an ask");
        require(!put.open, "put already open");
        require(!put.exercised, "put already exercised");
        put.tradeable = false; 
        put.exercised = true;
        withdrawPymt(pymtWeth, pymtCurrency, put.short, put.totalPurch);
        emit OptionCancelled(_p);
    }


    //function to purchase the first newly written put
    function buyNewOption(uint _p, uint _strike, uint _assetAmt, uint _price, uint _expiry) payable public {
        Put storage put = puts[_p];
        require(put.strike == _strike && put.assetAmt == _assetAmt && put.price == _price && put.expiry == _expiry, "details mismatch: something has changed before execution");
        require(put.expiry > now, "This put is already expired");
        require(!put.exercised, "This has already been exercised");
        require(put.tradeable, "this is not ready to trade");
        require(msg.sender != put.short, "this is your lost chicken");
        require(put.short != address(0x0) && put.short == put.long, "this is not your chicken");
        require(!put.open, "This put is already open");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= put.price, "not enough to buy this put");
        uint feePymt = (put.price * fee).div(1e4);
        uint shortPymt = (put.price).sub(feePymt);
        transferPymt(pymtWeth, pymtCurrency, msg.sender, feeCollector, feePymt);
        if (feeCollectorSet) {
            IHedgeyStaking(feeCollector).receiveFee(feePymt, pymtCurrency);
        }
        transferPymt(pymtWeth, pymtCurrency, msg.sender, put.short, shortPymt);
        put.open = true; 
        put.long = msg.sender; 
        put.tradeable = false; 
        emit NewOptionBought(_p);
    }    


    //function for a short to buy back an open position and remove their exposure / liability
    //only possible when someone places a writePut - can sell your short position to them
    function buyOptionFromNewShort(uint _p, uint _q, uint _price) payable public nonReentrant {
        Put storage openShort = puts[_p];
        Put storage newAsk = puts[_q];
        //everything needs to match
        require(_price == newAsk.price, "details mismatch: something has changed before execution");
        require(msg.sender == openShort.short, "your not the short");
        require(openShort.strike == newAsk.strike, "not the right strike");
        require(openShort.assetAmt == newAsk.assetAmt, "not the right assetAmt");
        require(openShort.expiry == newAsk.expiry, "not the right expiry");
        require(newAsk.short == newAsk.long, "_q is not a new ask"); //we know that a new ask sets the long equal to the short address
        require(openShort.open && !newAsk.open && newAsk.tradeable && !openShort.exercised && !newAsk.exercised && openShort.expiry > now && newAsk.expiry > now, "something is wrong");
        newAsk.exercised = true;
        newAsk.tradeable = false;
        newAsk.open = false;
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= newAsk.price, "not enough to buy this put");
        uint feePymt = (newAsk.price * fee).div(1e4);
        uint remainder = newAsk.price.sub(feePymt);
        transferPymt(pymtWeth, pymtCurrency, msg.sender, feeCollector, feePymt);
        if (feeCollectorSet) {
            IHedgeyStaking(feeCollector).receiveFee(feePymt, pymtCurrency);
        }
        transferPymt(pymtWeth, pymtCurrency, openShort.short, newAsk.short, remainder);
        withdrawPymt(pymtWeth, pymtCurrency, openShort.short, openShort.totalPurch);
        openShort.short = newAsk.short;
        openShort.price = _price;
        emit OpenShortRePurchased(_p, _q, openShort.short, _price);
    }


    //function to set a price of a put as the long, or to turn the open order off
    function setPrice(uint _p, uint _price, bool _tradeable) public {
        Put storage put = puts[_p];
        require((msg.sender == put.long && msg.sender == put.short) || (msg.sender == put.long && put.open), "you cant change the price");
        require(put.expiry > now, "already expired");
        require(!put.exercised, "already exercised");
        put.price = _price;
        put.tradeable = _tradeable;
        emit PriceSet(_p, _price, _tradeable);
    }

    
    //function for someone to purchase an open option
    function buyOpenOption(uint _p, uint _strike, uint _assetAmt, uint _price, uint _expiry) payable public nonReentrant {
        Put storage put = puts[_p];
        require(put.strike == _strike && put.assetAmt == _assetAmt && put.price == _price && put.expiry == _expiry, "details mismatch: something has changed before execution");
        require(msg.sender != put.long, "You already own this"); 
        require(put.open, "This put isnt opened yet"); 
        require(put.expiry >= now, "This put is already expired");
        require(!put.exercised, "This has already been exercised!");
        require(put.tradeable, "put not tradeable");
        uint balCheck = pymtWeth ? msg.value : IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= put.price, "not enough to buy this put");
        uint feePymt = (put.price * fee).div(1e4);
        uint longtPymt = (put.price).sub(feePymt);
        transferPymt(pymtWeth, pymtCurrency, msg.sender, feeCollector, feePymt);
        if (feeCollectorSet) {
            IHedgeyStaking(feeCollector).receiveFee(feePymt, pymtCurrency);
        }
        transferPymt(pymtWeth, pymtCurrency, msg.sender, put.long, longtPymt);
        if (msg.sender == put.short) {
            withdrawPymt(pymtWeth, pymtCurrency, put.short, put.totalPurch);//send the money back to the put writer
            put.exercised = true;
            put.open = false;
        }
        put.tradeable = false;
        put.long = msg.sender;
        emit OpenOptionPurchased(_p, put.exercised);
    }

    //function to physiputy exercise
    function exercise(uint _p) payable public nonReentrant {
        Put storage put = puts[_p];
        require(put.open, "This isnt open");
        require(put.expiry >= now, "This put is already expired");
        require(!put.exercised, "This has already been exercised!");
        require(msg.sender == put.long, "You dont own this put");
        uint balCheck = assetWeth ? msg.value : IERC20(asset).balanceOf(msg.sender);
        require(balCheck >= put.assetAmt, "not enough of the asset to close this put");
        put.exercised = true;
        put.open = false;
        put.tradeable = false;
        transferPymt(assetWeth, asset, msg.sender, put.short, put.assetAmt);
        withdrawPymt(pymtWeth, pymtCurrency, msg.sender, put.totalPurch);
        emit OptionExercised(_p, false);
    }

    //function to cash close with the uniswap flash swaps tool - bool is a dummy to match puts
    function cashClose(uint _p, bool dummy) payable public nonReentrant {
        require(cashCloseOn, "This is not setup to cash close");
        Put storage put = puts[_p];
        require(put.open, "This isnt open");
        require(put.expiry >= now, "This put is already expired");
        require(!put.exercised, "This has already been exercised!");
        require(msg.sender == put.long, "You dont own this put");
        uint pymtEst = estIn(put.assetAmt);
        require(pymtEst < put.totalPurch, "this put is not in the money"); 
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
        require(!put.exercised, "This has been exercised");
        require(put.expiry < now, "Not expired yet");
        require(msg.sender == put.short, "You cant do that");
        put.tradeable = false;
        put.open = false;
        put.exercised = true;
        withdrawPymt(pymtWeth, pymtCurrency, put.short, put.totalPurch);//send back their deposit
        emit OptionReturned(_p);
    }

    //function to roll an expired put into a new one
    function rollExpired(uint _p, uint _assetAmt, uint _newStrike, uint _price, uint _newExpiry) payable public nonReentrant {
        Put storage put = puts[_p];
        require(!put.exercised, "This has been exercised");
        require(put.expiry < now, "Not expired yet");
        require(msg.sender == put.short, "You cant do that");
        require(_newExpiry > now, "this is already in the past");
        uint _totalPurch = (_assetAmt).mul(_newStrike).div(10 ** assetDecimals);
        require(_totalPurch > 0, "totalPurchase error: too small amount");
        uint refund = (_totalPurch > put.totalPurch) ? _totalPurch.sub(put.totalPurch) : put.totalPurch.sub(_totalPurch);
        put.open = false;
        put.exercised = true;
        put.tradeable = false;
        if (_totalPurch > put.totalPurch) {
            uint balCheck = pymtWeth ? msg.value : IERC20(asset).balanceOf(msg.sender);
            require(balCheck >= refund, "you dont have enough collateral to sell this option");
            depositPymt(pymtWeth, pymtCurrency, msg.sender, refund);
        } else if (_totalPurch < put.totalPurch) {
            withdrawPymt(pymtWeth, pymtCurrency, put.short, refund);
        }
        puts[p++] = Put(msg.sender, _assetAmt, _newStrike, _totalPurch, _price, _newExpiry, false, true, msg.sender, false);
        emit OptionRolled(p.sub(1), _assetAmt, _newStrike, _price, _newExpiry);
    }

    //************SWAP SPECIFIC FUNCTIONS USED FOR THE CASH CLOSE METHODS***********************/

    //function to swap from this contract to uniswap pool
    function swap(address token, uint out, uint _in, address to) internal {
        SafeERC20.safeTransfer(IERC20(token), uniPair, _in);
        if (token == unindex0) {
            IUniswapV2Pair(uniPair).swap(0, out, to, new bytes(0));
        } else {
            IUniswapV2Pair(uniPair).swap(out, 0, to, new bytes(0));
        }
        
    }

    function estIn(uint _assetAmt) public view returns (uint cash) {
        (uint resA, uint resB) = UniswapV2Library.getReserves(uniFactory, unindex0, unindex1);
        cash = (unindex0 == pymtCurrency) ? UniswapV2Library.getAmountIn(_assetAmt, resA, resB) : UniswapV2Library.getAmountIn(_assetAmt, resB, resA);
    }


    //events
    event NewBid(uint _p, uint _assetAmt, uint _strike, uint _price, uint _expiry);
    event NewAsk(uint _p, uint _assetAmt, uint _strike, uint _price, uint _expiry);
    event NewOptionSold(uint _p);
    event NewOptionBought(uint _p);
    event OpenOptionSold(uint _p, uint _q, address _long, uint _price);
    event OpenShortRePurchased(uint _p, uint _q, address _short, uint _price);
    event OpenOptionPurchased(uint _p, bool _returned);
    event OptionChanged(uint _p, uint _assetAmt, uint _strike, uint _price, uint _expiry);
    event PriceSet(uint _p, uint _price, bool tradeable);
    event OptionExercised(uint _p, bool cashClosed);
    event OptionRolled(uint _p, uint _assetAmt, uint _strike, uint _price, uint _expiry);
    event OptionReturned(uint _p);
    event OptionCancelled(uint _p);
    event AMMUpdate(bool _cashCloseOn);
}