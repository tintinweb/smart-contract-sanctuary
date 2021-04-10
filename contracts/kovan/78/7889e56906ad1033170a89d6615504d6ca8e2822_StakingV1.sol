/**
 *Submitted for verification at Etherscan.io on 2021-04-09
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

interface IHC {
    function changeFee(uint _fee) external;
    function changeCollector(address payable _collector, bool _set) external returns (bool);
}


contract StakingV1 is ReentrancyGuard, Ownable {

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    bool isInitialized = false;
    address public hPAR;
    //bool public hparSet = false;
    address public hedgeyCallsFactory;
    address public hedgeyPutsFactory;
    //bool factorySet = false;
    address payable public weth;
    uint public s = 1; //index or number of stakers
    uint public startTime;
    uint public periodEpoc;// 3600 * 24 * 30 30 day periods
    uint public totalPeriods = 0;
    address[] public feeTokens; //just the addresses of any token we have collected in fees - all ERC20 fees only 
    mapping(address => address) public tokenAddresses;
    
    
    constructor(address payable _weth, uint _periodEpoc) public {
        weth = _weth;
        periodEpoc = _periodEpoc;
    }    

    mapping(address => bool) public whitelist; //whitelist any hedgey contracts - only collect fees from them

    struct Period {
        uint start;
        uint end;
        uint totalStaked;
    }
    
    mapping(uint => Period) public periods; //way for us to access the periods which are really just a start and an end time
    
    struct Staker {
        address payable owner;
        uint amount;
        uint timeIn;
        uint timeOut;
        bool isStaking;
        mapping(uint => uint) periodTokens; //the period rewards - simply the amount * timeWeight
        mapping(uint => bool) rewardsAllocated; //bool to determine if rewards have been allocated for a period or not
        mapping(address => uint) rewards; //lookup by the token address to get the rewards a staker can redeem
    }
    
    mapping(uint => Staker) public stakers; //use the index s to lookup staker and their info
    

    struct CurrentFee {
        uint feesCollected;
    }
    
    mapping(address => mapping(uint => CurrentFee)) public currentFees;


    receive() external payable {    
    }
    
    /************************* Administration type FUNCTIONS *************************************************************************/
    
    //function to setup new period - needs to be done periodically to ensure periods are setup properly
    function setNewPeriod() public {
        Period storage p = periods[totalPeriods++];
        periods[totalPeriods] = Period(p.end.add(1), p.end.add(1).add(periodEpoc), 0);
    }
    
    //this function is set by the owner right after deployment simply to assign the factory addresses - since the staking contract should be set first
    function setFactories(address _hedgeyCallsFactory, address _hedgeyPutsFactory) public onlyOwner {
        //require(!factorySet, "hedgeyStake: factory has already been set");
        hedgeyCallsFactory = _hedgeyCallsFactory;
        hedgeyPutsFactory = _hedgeyPutsFactory;
        //factorySet = true;
    }
    
    //sets the hpar address for ppl ability to staker
    function setHPAR(address _hpar) public onlyOwner {
        //require(!hparSet, "hpar already set");
        hPAR = _hpar;
        //hparSet = true;
    }
    
    //initialize function that just kicks off the first period
    function initialize() public onlyOwner returns (bool) {
        require(!isInitialized, "already initialized");
        Period storage p = periods[0];
        p.start = block.timestamp;
        p.end = p.start.add(periodEpoc);
        startTime = block.timestamp;
        setNewPeriod();
        isInitialized = true;
        return isInitialized;
    }
    
    
    //function to add new hedgey options pairs as they are produced by the factories
    function addWhitelist(address hedgey) external {
        require(msg.sender == hedgeyCallsFactory || msg.sender == hedgeyPutsFactory, "hedgeyStake: only factory can whitelist");
        whitelist[hedgey] = true;
    }
    
    //function for adding hedgey options pairs before this contract is deployed
    function manualWhiteList(address[] memory hedgey) external onlyOwner {
        for (uint i; i < hedgey.length; i++) {
            whitelist[hedgey[i]] = true;
        }
    }
    
    function changeFee(address hedgey, uint newFee) external onlyOwner {
        IHC(hedgey).changeFee(newFee);
    }
    
    function changeCollector(address hedgey, address payable _newCollector, bool _set) external onlyOwner returns (bool success) {
        success = IHC(hedgey).changeCollector(_newCollector, _set);
    }
    
    
    //function to put a time stamp on the fees received for calculation and alloctions
    //need some requirements to confirm that the amount sent into the contract has changed by the same
    function receiveFee(uint amt, address token) external {
        require(whitelist[msg.sender], "hedgeyStake: you are not a whitelisted address to send fees");
        uint period = (block.timestamp.sub(startTime)).div(periodEpoc); //determines period simply by subtracting from the start and dividing by epoch. since its a uint decimals get choppoed off
        CurrentFee storage c = currentFees[token][period]; //setup c with the token address and current currentPeriod
        //then all we do is add the amt to the currentFee struct
        c.feesCollected += amt;
        //tokenBalances[token] = IERC20(token).balanceOf(address(this)); //tells our contract how much it has so we cant overspend
        if (tokenAddresses[token] == address(0)) {
            tokenAddresses[token] = token;
            feeTokens.push(token);
        }
    }

    /************************* INTERNAL WETH HANDLERS *******************************************************************************/
    
    function withdrawPymt(bool _isWeth, address _token, address payable to, uint _amt) internal {
        if (_isWeth && (!Address.isContract(to))) {
            //if the address is ta contract - then we should actually just send WETH out to the contract
            IWETH(weth).withdraw(_amt);
            to.transfer(_amt);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), to, _amt);
        }
    }

    
    /******************************OTHER INTERNAL FUNCTIONS*************************************************************************/
  

    function inWeight(uint _s, uint _p, uint _amt) internal returns (uint weight) {
        Staker storage st = stakers[_s];
        Period storage p = periods[_p];
        weight = _amt.mul(1 - ((block.timestamp - p.start).mul(1e18).div(periodEpoc))).div(1e18); //if this is at the beginning then its = 1 otherwise its proportional to when they started
        p.totalStaked += weight;
        st.periodTokens[_p] += weight;
        st.amount += _amt;
    }

    function outWeight(uint _s, uint _p, uint _amt) internal returns (uint weight) {
        Staker storage st = stakers[_s];
        Period storage p = periods[_p];
        //for this we need to update our total and staker periodTokens
        //we need to take the min of timeOut - timeIn, and timeOut - periodStart
        uint periodTime = block.timestamp.sub(p.start);
        uint totalTime = block.timestamp.sub(st.timeIn);
        uint minTime = periodTime.min(totalTime).mul(1e18).div(periodEpoc);
        weight = _amt.mul(1 - minTime).div(1e18);
        st.periodTokens[_p] -= weight;
        p.totalStaked -= weight;
    }

    //********************************STAKING FUNCTIONS****************************************************************************************************** */

    function stake(uint amt, uint _s) public {
        require(IERC20(hPAR).balanceOf(msg.sender) >= amt, "you dont have enough hpar");
        uint period = (block.timestamp.sub(startTime)).div(periodEpoc);
        SafeERC20.safeTransferFrom(IERC20(hPAR), msg.sender, address(this), amt); //pulls in the staked hPAR
        if (_s >0) {
            //this is an existing staker, lets make sure they own that staking struct
            Staker storage st = stakers[_s];
            require(msg.sender == st.owner, "you dont own this staking right");
            inWeight(_s, period, amt);
        } else {
             //now we setup the new staker struct
            stakers[s++] = Staker(msg.sender, amt, block.timestamp, 0, true); //sets up our initial staker metrics        
            //internal function handles calculation of the weighted time in and assigns to the staker and period totals
            inWeight(s.sub(1), period, amt);
        }
        setNewPeriod();
        emit newStaker(amt, msg.sender);
    }

    function unStake(uint _s, uint amt) public nonReentrant {
        Staker storage st = stakers[_s];
        require(msg.sender == st.owner, "you dont own this");
        require(st.isStaking, "you alread unstaked");
        st.timeOut = block.timestamp;
        st.isStaking = false;
        uint period = (block.timestamp.sub(startTime)).div(periodEpoc);
        outWeight(_s, period, amt);
        SafeERC20.safeTransfer(IERC20(hPAR), msg.sender, amt);
        setNewPeriod();
        emit unStaked(amt, msg.sender);
    }

    function reStake(uint _s) public {
        Staker storage st = stakers[_s];
        uint period = (block.timestamp.sub(startTime)).div(periodEpoc);
        Period storage p = periods[period];
        require(msg.sender == st.owner, "you dont own this");
        require(st.isStaking, "you alread unstaked");
        //now we give the staker the full weight for restaking
        st.periodTokens[period] = st.amount;
        p.totalStaked += st.amount;
        emit reStaked(st.amount, msg.sender);
    }


    function getTokenWeight(uint _s, uint _p) external view returns (uint weight) {
        Staker storage st = stakers[_s];
        weight = st.periodTokens[_p];
    }



    function getRewards(uint _s, address token) external view returns (uint _rewards) {
        Staker storage st = stakers[_s];
        _rewards = st.rewards[token];
    }
    
    function pullRewards(uint _s, address token) public payable nonReentrant {
        Staker storage st = stakers[_s];
        require(msg.sender == st.owner, "you dont own this bad boi");
        uint _rewards = st.rewards[token];
        st.rewards[token] = 0; //resets this back to 0
        bool isWeth = (token == weth);
        withdrawPymt(isWeth, token, msg.sender, _rewards);
    }

    function pullAllRewards(uint _s) public payable {
        Staker storage st = stakers[_s];
        require(msg.sender == st.owner, "you dont own this");
        for (uint i = 0; i < feeTokens.length; i++) {
            pullRewards(_s, feeTokens[i]); //runs the pull tokens for each of them
        }
    }

        /******************************ALLOCATION METHODS******************************************/

    //individuals allocate their own rewards for a give period or number of periods
    function allocateRewards(uint _s, uint _p, address feeToken) public returns (uint _rewards) {
        Staker storage st = stakers[_s];
        require(msg.sender == st.owner, "you dont own this");
        require(!st.rewardsAllocated[_p], "Rewards for this period already allocated"); //require that rewards haven't been allocated for this period yet
        st.rewardsAllocated[_p] = true;
        Period storage p = periods[_p];
        require(p.end < block.timestamp, "this period hasnt ended yet");
        CurrentFee storage c = currentFees[feeToken][_p];
        //to get your share fo the pool, we simply divide your weighted tokens by the weighted total
        uint share = st.periodTokens[_p].mul(1e18).div(p.totalStaked); //six decimals of precision
        _rewards = c.feesCollected.mul(share).div(1e18); //rewards are then the total fees earnd by the pool times the share
        st.rewards[feeToken] += _rewards;
        setNewPeriod();
    }

    function allocateAllRewards(uint _s, uint _p) public {
        for (uint i = 0; i < feeTokens.length; i++) {
            allocateRewards(_s, _p, feeTokens[i]);
        }
    }

    /******EVENTS */
    event newStaker(uint _amount, address _staker);
    event unStaked(uint _amount, address _staker);
    event reStaked(uint _amount, address _staker);

}