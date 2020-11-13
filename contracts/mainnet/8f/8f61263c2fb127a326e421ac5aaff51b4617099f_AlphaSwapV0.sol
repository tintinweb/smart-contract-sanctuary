//   _    _ _   _                __ _                            
//  | |  (_) | | |              / _(_)                           
//  | | ___| |_| |_ ___ _ __   | |_ _ _ __   __ _ _ __   ___ ___ 
//  | |/ / | __| __/ _ \ '_ \  |  _| | '_ \ / _` | '_ \ / __/ _ \
//  |   <| | |_| ||  __/ | | |_| | | | | | | (_| | | | | (_|  __/
//  |_|\_\_|\__|\__\___|_| |_(_)_| |_|_| |_|\__,_|_| |_|\___\___|
//
//  AlphaSwap v0 contract (AlphaDex)
//
//  https://www.AlphaSwap.org
//
pragma solidity ^0.5.16;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "!addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "!subtraction overflow");
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
        require(c / a == b, "!multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "!division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

contract AlphaSwapV0 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct MARKET_EPOCH {
        uint timestamp;
        uint accuPrice;
        uint32 pairTimestamp;
        mapping (address => mapping(uint => mapping (address => uint))) stake;
        mapping (address => mapping(uint => uint)) totalStake;
    }

    mapping (address => mapping(uint => MARKET_EPOCH)) public market;
    mapping (address => uint) public marketEpoch;
    mapping (address => uint) public marketEpochPeriod;
    
    mapping (address => uint) public marketWhitelist;
    mapping (address => uint) public tokenWhitelist;

    event STAKE(address indexed user, address indexed market, uint opinion, address indexed token, uint amt);
    event SYNC(address indexed market, uint epoch);
    event PAYOFF(address indexed user, address indexed market, uint opinion, address indexed token, uint amt);
    
    event MARKET_PERIOD(address indexed market, uint period);
    event MARKET_WHITELIST(address indexed market, uint status);
    event TOKEN_WHITELIST(address indexed token, uint status);
    event FEE_CHANGE(address indexed market, address indexed token, uint BP);
    
    //====================================================================
    
    address public govAddr;
    address public devAddr;
    
    mapping (address => mapping(address => uint)) public devFeeBP; // in terms of basis points (1 bp = 0.01%)
    mapping (address => uint) public devFeeAmt;
    
    constructor () public {
        govAddr = msg.sender;
        devAddr = msg.sender;
    }
    
    modifier govOnly() {
    	require(msg.sender == govAddr, "!gov");
    	_;
    }
    function govTransferAddr(address newAddr) external govOnly {
    	require(newAddr != address(0), "!addr");
    	govAddr = newAddr;
    }
    function govSetEpochPeriod(address xMarket, uint newPeriod) external govOnly {
        require (newPeriod > 0, "!period");
        marketEpochPeriod[xMarket] = newPeriod;
        emit MARKET_PERIOD(xMarket, newPeriod);
    }
    function govMarketWhitelist(address xMarket, uint status) external govOnly {
        require (status <= 1, "!status");
        marketWhitelist[xMarket] = status;
        emit MARKET_WHITELIST(xMarket, status);
    }
    function govTokenWhitelist(address xToken, uint status) external govOnly {
        require (status <= 1, "!status");
        tokenWhitelist[xToken] = status;
        emit TOKEN_WHITELIST(xToken, status);
    }
    function govSetDevFee(address xMarket, address xToken, uint newBP) external govOnly {
        require (newBP <= 10); // max fee = 10 basis points = 0.1%
    	devFeeBP[xMarket][xToken] = newBP;
    	emit FEE_CHANGE(xMarket, xToken, newBP);
    }
    
    modifier devOnly() {
    	require(msg.sender == devAddr, "!dev");
    	_;
    }
    function devTransferAddr(address newAddr) external devOnly {
    	require(newAddr != address(0), "!addr");
    	devAddr = newAddr;
    }
    function devWithdrawFee(address xToken, uint256 amt) external devOnly {
        require (amt <= devFeeAmt[xToken]);
        devFeeAmt[xToken] = devFeeAmt[xToken].sub(amt);
        IERC20(xToken).safeTransfer(devAddr, amt);
    }
    
    //====================================================================

    function readStake(address user, address xMarket, uint xEpoch, uint xOpinion, address xToken) external view returns (uint) {
        return market[xMarket][xEpoch].stake[xToken][xOpinion][user];
    }
    function readTotalStake(address xMarket, uint xEpoch, uint xOpinion, address xToken) external view returns (uint) {
        return market[xMarket][xEpoch].totalStake[xToken][xOpinion];
    }
    
    //====================================================================
    
    function Stake(address xMarket, uint xEpoch, uint xOpinion, address xToken, uint xAmt) external {
        require (xAmt > 0, "!amt");
        require (xOpinion <= 1, "!opinion");
        require (marketWhitelist[xMarket] > 0, "!market");
        require (tokenWhitelist[xToken] > 0, "!token");

        uint thisEpoch = marketEpoch[xMarket];
        require (xEpoch == thisEpoch, "!epoch");
        MARKET_EPOCH storage m = market[xMarket][thisEpoch];

        if (m.timestamp == 0) { // new market
            m.timestamp = block.timestamp;
            
            IUniswapV2Pair pair = IUniswapV2Pair(xMarket);
            uint112 reserve0;
            uint112 reserve1;
            uint32 pairTimestamp;
            (reserve0, reserve1, pairTimestamp) = pair.getReserves();
        
            m.pairTimestamp = pairTimestamp;
            m.accuPrice = pair.price0CumulativeLast();
        }

        address user = msg.sender;
        IERC20(xToken).safeTransferFrom(user, address(this), xAmt);
        
        m.stake[xToken][xOpinion][user] = m.stake[xToken][xOpinion][user].add(xAmt);
        m.totalStake[xToken][xOpinion] = m.totalStake[xToken][xOpinion].add(xAmt);
        
        emit STAKE(user, xMarket, xOpinion, xToken, xAmt);
    }
    
    function _Sync(address xMarket) private {
        uint epochPeriod = marketEpochPeriod[xMarket];
        uint thisPeriod = (block.timestamp).div(epochPeriod);
        
        MARKET_EPOCH memory mmm = market[xMarket][marketEpoch[xMarket]];
        uint marketPeriod = (mmm.timestamp).div(epochPeriod);
        
        if (thisPeriod <= marketPeriod)
            return;

        IUniswapV2Pair pair = IUniswapV2Pair(xMarket);
        uint112 reserve0;
        uint112 reserve1;
        uint32 pairTimestamp;
        (reserve0, reserve1, pairTimestamp) = pair.getReserves();
        if (pairTimestamp <= mmm.pairTimestamp)
            return;
            
        MARKET_EPOCH memory m;
        m.timestamp = block.timestamp;
        m.pairTimestamp = pairTimestamp;
        m.accuPrice = pair.price0CumulativeLast();
        
        uint newEpoch = marketEpoch[xMarket].add(1);
        marketEpoch[xMarket] = newEpoch;
        market[xMarket][newEpoch] = m;
        
        emit SYNC(xMarket, newEpoch);
    }
    
    function Sync(address xMarket) external {
        uint epochPeriod = marketEpochPeriod[xMarket];
        uint thisPeriod = (block.timestamp).div(epochPeriod);
        
        MARKET_EPOCH memory mmm = market[xMarket][marketEpoch[xMarket]];
        uint marketPeriod = (mmm.timestamp).div(epochPeriod);
        require (marketPeriod > 0, "!marketPeriod");
        require (thisPeriod > marketPeriod, "!thisPeriod");

        IUniswapV2Pair pair = IUniswapV2Pair(xMarket);
        uint112 reserve0;
        uint112 reserve1;
        uint32 pairTimestamp;
        (reserve0, reserve1, pairTimestamp) = pair.getReserves();
        require (pairTimestamp > mmm.pairTimestamp, "!no-trade");

        MARKET_EPOCH memory m;
        m.timestamp = block.timestamp;
        m.pairTimestamp = pairTimestamp;
        m.accuPrice = pair.price0CumulativeLast();
        
        uint newEpoch = marketEpoch[xMarket].add(1);
        marketEpoch[xMarket] = newEpoch;
        market[xMarket][newEpoch] = m;
        
        emit SYNC(xMarket, newEpoch);
    }
    
    function Payoff(address xMarket, uint xEpoch, uint xOpinion, address xToken) external {
        require (xOpinion <= 1, "!opinion");
        
        uint thisEpoch = marketEpoch[xMarket];
        require (thisEpoch >= 1, "!marketEpoch");
        _Sync(xMarket);
        
        thisEpoch = marketEpoch[xMarket];
        require (xEpoch <= thisEpoch.sub(2), "!epoch");

        address user = msg.sender;
        uint amtOut = 0;
        
        MARKET_EPOCH storage m0 = market[xMarket][xEpoch];
        {
            uint224 p01 = 0;
            uint224 p12 = 0;
            {
                MARKET_EPOCH memory m1 = market[xMarket][xEpoch.add(1)];
                MARKET_EPOCH memory m2 = market[xMarket][xEpoch.add(2)];
                
                // overflow is desired
                uint32 t01 = m1.pairTimestamp - m0.pairTimestamp;
                if (t01 > 0)
                    p01 = uint224((m1.accuPrice - m0.accuPrice) / t01);
                
                uint32 t12 = m2.pairTimestamp - m1.pairTimestamp;
                if (t12 > 0)
                    p12 = uint224((m2.accuPrice - m1.accuPrice) / t12);
            }
            
            uint userStake = m0.stake[xToken][xOpinion][user];
            if ((p01 == p12) || (p01 == 0) || (p12 == 0)) {
                amtOut = userStake;
            }
            else {
                uint sameOpinionStake = m0.totalStake[xToken][xOpinion];
                uint allStake = sameOpinionStake.add(m0.totalStake[xToken][1-xOpinion]);
                if (sameOpinionStake == allStake) {
                    amtOut = userStake;
                } 
                else {
                    if (
                        ((p12 > p01) && (xOpinion == 1))
                        ||
                        ((p12 < p01) && (xOpinion == 0))
                    )
                    {
                        amtOut = userStake.mul(allStake).div(sameOpinionStake);
                    }
                }
            }
        }
        
        require (amtOut > 0, "!zeroAmt");
        
        uint devFee = amtOut.mul(devFeeBP[xMarket][xToken]).div(10000);
        devFeeAmt[xToken] = devFeeAmt[xToken].add(devFee);

        amtOut = amtOut.sub(devFee);
        
        m0.stake[xToken][xOpinion][user] = 0;
        IERC20(xToken).safeTransfer(user, amtOut);
        
        emit PAYOFF(user, xMarket, xOpinion, xToken, amtOut);
    }
}