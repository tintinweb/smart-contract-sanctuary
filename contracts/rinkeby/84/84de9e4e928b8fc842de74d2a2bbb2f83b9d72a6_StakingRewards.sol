/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

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

// TODO(zx): Replace all instances of SafeMath with OZ implementation
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
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}


// File contracts/interfaces/IERC20.sol

pragma solidity >=0.7.5;

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


// File contracts/libraries/SafeERC20.sol

pragma solidity >=0.7.5;

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}


// File contracts/interfaces/IsOHM.sol


interface IsOHM is IERC20 {
    function rebase( uint256 ohmProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );

    function index() external view returns ( uint );

    function toG(uint amount) external view returns (uint);

    function fromG(uint amount) external view returns (uint);

     function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);

}


// File contracts/interfaces/IgOHM.sol


interface IgOHM is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function index() external view returns (uint256);

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

  function migrate( address _staking, address _sOHM ) external;
}


// TAZ token interface.

interface ITAZ is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

  function safeTransferFrom(address sender, address receipient, uint256 amount) external returns (bool) ;

  function safeTransfer(address receipient, uint256 amount) external returns (bool);
}



// File contracts/interfaces/IDistributor.sol

interface IDistributor {
    function distribute() external;

    function bounty() external view returns (uint256);

    function retrieveBounty() external returns (uint256);

    function nextRewardAt(uint256 _rate) external view returns (uint256);

    function nextRewardFor(address _recipient) external view returns (uint256);

    function setBounty(uint256 _bounty) external;

    function addRecipient(address _recipient, uint256 _rewardRate) external;

    function removeRecipient(uint256 _index) external;

    function setAdjustment(
        uint256 _index,
        bool _add,
        uint256 _rate,
        uint256 _target
    ) external;
}


// File contracts/interfaces/IOlympusAuthority.sol

interface IOlympusAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);    

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
}


// File contracts/types/OlympusAccessControlled.sol


abstract contract OlympusAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /* ========== MODIFIERS ========== */
    
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}


// File contracts/MyStaking.sol
//////////


abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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


contract StakingRewards is OlympusAccessControlled, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IUniswapV2Router02 public uniswapV2Router;

    address public routerAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // rinkeby test router

    ITAZ    public tazToken;
    IERC20  public tazorToken;

    struct UserInfo {
        uint256 tazorNum;
        uint256 tazNum;
        uint256 reward;
        uint256 apr;
        uint256 lastUpdateTime;
        uint256 burnAmount;
    }
    
    //uint256 public periodFinish = 0;
    //uint256 public rewardRate = 0;
    //uint256 public rewardsDuration = 7 days;
    //uint256 public lastUpdateTime;          //last updated time  modified when staked, getReward, withdraw.
    //uint256 public rewardPerTokenStored;    // stored reward per token before updating.

    //mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;         // number of  reward token should be paid to each account

    uint256 private _totalTazorSupply;                       // total number of staked TAZOR token
    uint256 private _totalTazSupply;                       // total number of staked TAZOR token
    mapping(address => UserInfo) public  userInfos;    // number of staked TAZOR token per user

    /* ========== CONSTRUCTOR ========== */

    constructor(        
        address _tazToken,
        address _tazorToken,
        address _authority
    ) OlympusAccessControlled(IOlympusAuthority(_authority)) {
        tazToken = ITAZ(_tazToken);
        tazorToken = IERC20(_tazorToken);        

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
    	// testnet PCS router: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    	// mainnet PCS V2 router: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // rinkeby router address: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    	
        uniswapV2Router = _uniswapV2Router;
    }

    /* ========== VIEWS ========== */

    function totalTazorSupply() external view returns (uint256) {
        return _totalTazorSupply;
    }

    function totalTazSupply() external view returns (uint256) {
        return _totalTazSupply;
    }

    function balanceOfTazor(address account) external view returns (uint256) {
        return userInfos[account].tazorNum;
    }

    function balanceOfTaz(address account) external view returns (uint256) {
        return userInfos[account].tazNum;
    }
   
    // add new reward to previously earned reward
    function calcReward(address account) public returns (uint256) {
        uint256 timeinterval = block.timestamp.sub(userInfos[account].lastUpdateTime);

        // uint256 rate = getTazorAndTazRate(); // get TAZOR/TAZ rate
        UserInfo memory user = userInfos[account];
        uint256 _apr = user.apr.mul(timeinterval).div(365 days);
        uint256 newEarned = userInfos[account].tazorNum.mul(1).mul(_apr); // reward TAZ amount

        userInfos[account].reward = newEarned.add(userInfos[account].reward);
        return userInfos[account].reward;
    }


    function calcBurn(address account) public {
        
        uint256 timeinterval = block.timestamp.sub(userInfos[account].lastUpdateTime);
        
        require(timeinterval > 24 hours, "can't burn Taz tokens");

        UserInfo memory user = userInfos[account];

        uint256 numberOfBurn = timeinterval.div(86400);

        uint256 burnNum = user.tazNum.sub(getTaylorValue(numberOfBurn, account));

        userInfos[account].burnAmount = userInfos[account].burnAmount.add(burnNum);

        // userInfos[account].reward = newEarned.add(userInfos[account].reward);
        // return userInfos[account].reward;
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeTazor(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake tazor 0");
        _totalTazorSupply = _totalTazorSupply.add(amount);
        userInfos[msg.sender].tazorNum = userInfos[msg.sender].tazorNum.add(amount);

        tazorToken.safeTransferFrom(msg.sender, address(this), amount);
        emit TazorStaked(msg.sender, amount);
    }


    function stakeTaz(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake taz 0");
        _totalTazSupply = _totalTazSupply.add(amount);
        userInfos[msg.sender].tazNum = userInfos[msg.sender].tazNum.add(amount);

        // update apr
        setAPRvalue();

        tazToken.safeTransferFrom(msg.sender, address(this), amount);
        emit TazStaked(msg.sender, amount);
    }


    function unstakeTazor(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        // require(block.timestamp > userInfos[msg.sender].lastUpdateTime + 12 hours, "can't draw tokens");
        _totalTazorSupply = _totalTazorSupply.sub(amount);
        userInfos[msg.sender].tazorNum = userInfos[msg.sender].tazorNum.sub(amount);
        tazorToken.safeTransfer(msg.sender, amount);
        emit TazorWithdrawn(msg.sender, amount);
    }

    function unstakeTaz(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        // require(block.timestamp > userInfos[msg.sender].lastUpdateTime + 12 hours, "can't draw tokens");
        _totalTazSupply = _totalTazSupply.sub(amount);
        userInfos[msg.sender].tazNum = userInfos[msg.sender].tazNum.sub(amount);
        tazToken.safeTransfer(msg.sender, amount);
        emit TazWithdrawn(msg.sender, amount);
    }


    function getReward() public nonReentrant {

        require(block.timestamp > userInfos[msg.sender].lastUpdateTime + 24 hours, "can't get rewards");
        
        uint256 reward = userInfos[msg.sender].reward - userInfos[msg.sender].burnAmount;

        tazToken.burn(msg.sender, userInfos[msg.sender].burnAmount);

        if (reward > 0) {
            userInfos[msg.sender].reward = 0;
     
            tazToken.safeTransfer(msg.sender, reward);
            userInfos[msg.sender].lastUpdateTime = block.timestamp;
            emit RewardPaid(msg.sender, reward);
        }
    }

    function setAPRvalue() private {
        userInfos[msg.sender].apr = ((userInfos[msg.sender].tazNum.mul(10000).mul(5)).add(10 ** 17)).div(10 ** 9);
    }

    function exitTazor() external {
        unstakeTazor(userInfos[msg.sender].tazorNum);
        getReward();
    }

    function updateRouterAddress(address _routerAddress) public onlyGovernor {
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
    }

    function getTazorAndTazRate() private view returns(uint256) {

        address[] memory path = new address[](2);
        path[0] = address(tazToken);
        path[1] = uniswapV2Router.WETH();
        path[2] = address(tazorToken);

        uint256[] memory amountOutMins = uniswapV2Router.getAmountsOut(1, path);
        return amountOutMins[path.length - 1];
    }



    // (1 + x)^a = 1 + ax + a*(a-1)*x*2 / 2 + a*(a-1)*(a-2)*x^3/6;
    // alpha = tazor / totTazor * 0.03

    function getTaylorValue(uint256 numberOfBurn, address account) internal view returns (uint256) {

        UserInfo memory user = userInfos[account];

        uint256 secondNode = user.tazNum.mul(numberOfBurn).mul(user.tazorNum).div(_totalTazorSupply).mul(3).div(100);

        uint256 thirdNode = user.tazNum.mul(numberOfBurn).mul(numberOfBurn.sub(1)).mul(9).div(20000);
        
        thirdNode = thirdNode.mul(user.tazorNum).div(_totalTazorSupply).mul(user.tazorNum).div(_totalTazorSupply);

        uint256 fourthNode = user.tazNum.mul(numberOfBurn).mul(numberOfBurn.sub(1)).mul(numberOfBurn.sub(2));

        fourthNode = fourthNode.mul(27).div(6000000).mul(user.tazorNum).div(_totalTazorSupply);

        fourthNode = fourthNode.mul(user.tazorNum).div(_totalTazorSupply).mul(user.tazorNum).div(_totalTazorSupply);

        uint256 realTazNum = user.tazNum.sub(secondNode).add(thirdNode).sub(fourthNode);

        return realTazNum;
    }

    
    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
                
        if (account != address(0)) {
            if (userInfos[account].lastUpdateTime == 0) {
                userInfos[account].lastUpdateTime = block.timestamp;
                userInfos[account].apr = (10 ** 8);
            }
            userInfos[account].reward = calcReward(account);
            calcBurn(account);
            userInfos[account].lastUpdateTime = block.timestamp;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event TazorStaked(address indexed user, uint256 amount);
    event TazStaked(address indexed user, uint256 amount);
    event TazorWithdrawn(address indexed user, uint256 amount);
    event TazWithdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}