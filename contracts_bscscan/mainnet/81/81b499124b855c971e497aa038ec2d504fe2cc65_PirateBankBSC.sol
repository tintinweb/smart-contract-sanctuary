pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0 <0.8.0;

import "pantherswap-peripheral/contracts/interfaces/IPantherRouter02.sol";
import "../libraries/SafeMath.sol";
import "../libraries/WhitelistUpgradeable.sol";
import "../interfaces/IStakingRewards.sol";

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PirateBankBSC is WhitelistUpgradeable {
    using SafeMath for uint256;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant PIRATE = 0x63041a8770c4CFE8193D784f3Dc7826eAb5B7Fd2;
    address private constant PIRATE_BNB = 0x3F2FC02441fE78217F08A9B7a3c0107380025347;
    address private constant KEEPER = 0x3953Eb16238faB5c3C5C535Ea1c5310AEF13AC31;
    IPantherRouter02 private constant ROUTER = IPantherRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PCS Router

    address public PIRATE_POOL;
    uint public dividendRate; // percentage to pay out to dividend pool (10 basis points)
    mapping(address => address) public tokenOwner; // token => owner
    mapping(address => uint256) public tokenFunds; // token => injected funds
    mapping(address => uint256) public tokenReturnRatio; // token => ratio to return to token owner (10 basis points)
    mapping(address => uint256) public tokenEarnTotal; // token => amount token withdrawn as earnings
    mapping(address => uint256) public tokenTotal; // token => tracked token sums
    mapping(address => address) public tokenRouter; // token => router to use
    address public PIRATE_PIRATE_POOL;
    mapping(address => uint256) public lockedInAmount; // token => amount locked in

    event EarningsWithdrawn(address indexed account, address token, uint256 amount, uint timestamp);
    event DepositedCapital(address indexed account, address token, uint256 amount, uint timestamp);
    event WithdrawnAll(address indexed account, address token, uint256 amount, uint timestamp);

    function initialize(address _pool) external initializer {
        __WhitelistUpgradeable_init();
        require(owner() != address(0), "owner must be set");
        setTokenOwner(address(0), owner());
        setTokenOwner(PIRATE, owner());
        setTokenReturnRatio(address(0), 0);
        setTokenReturnRatio(PIRATE, 0);
        setTokenRouter(0xdD97AB35e3C0820215bc85a395e13671d84CCBa2, 0x24f7C33ae5f77e2A9ECeed7EA858B4ca2fa1B7eC); // JAWS -> Panther router
        setTokenRouter(address(0), 0x24f7C33ae5f77e2A9ECeed7EA858B4ca2fa1B7eC); // BNB -> Panther router
        setTokenRouter(PIRATE, 0x24f7C33ae5f77e2A9ECeed7EA858B4ca2fa1B7eC); // PIRATE -> Panther router
        dividendRate = 50; // 5%
        PIRATE_POOL = _pool;

        ERC20(WBNB).approve(address(ROUTER), uint(~0));
        ERC20(PIRATE).approve(address(ROUTER), uint(~0));
    }

    fallback() external payable {}
    receive() external payable {}

    /* ========== View functions ========== */

    // @dev returns the tracked token total
    function balanceOf(address token) public view returns (uint) {
        return tokenTotal[token];
    }

    // @dev returns the amounts of tokens earned
    // amount earnt = total tracked tokens - principal - amounts locked in bets
    function earned(address token) public view returns (uint) {
        if (tokenTotal[token] > tokenFunds[token]) {
            return tokenTotal[token].sub(tokenFunds[token]);
        }
        else return 0;
    }

    // @dev returns amount of funds that bank still has to accept bets
    function serviceableBetAmount(address token) public view returns (uint) {
        if (tokenTotal[token] > lockedInAmount[token]) {
            return tokenTotal[token].sub(lockedInAmount[token]);
        }
        else return 0;
    }

    /* ========== External functions ========== */

    // @dev only whitelisted contracts can attempt to withdraw a token to a recipient
    function withdrawTo(address token, uint256 amount, address recipient) external onlyWhitelisted {
        if (token == address(0)) {
            payable(recipient).transfer(amount);
        } else {
            require(ERC20(token).transfer(recipient, amount));
        }
        tokenTotal[token] = tokenTotal[token].sub(amount);
    }

    // @dev only whitelisted contracts can attempt to withdraw a token
    function withdraw(address token, uint256 amount) external onlyWhitelisted {
        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }
        tokenTotal[token] = tokenTotal[token].sub(amount);
    }

    // @dev only whitelisted contracts can attempt to deposit a token
    function deposit(address token, uint256 amount) external payable onlyWhitelisted {
        if (token == address(0)) {
            require(msg.value == amount, "BNB: Deposit amount does not match specified amount");
        } else {
            require(msg.value == 0, "Token: Not supposed to deposit BNB");
            require(ERC20(token).transferFrom(msg.sender, address(this), amount));
        }
        tokenTotal[token] = tokenTotal[token].add(amount);
    }

    // @dev only whitelisted contracts can attempt to lock funds
    // This lock is used when a user has placed a bets with a `possibleWinAmount`
    function lockFunds(address token, uint256 amount) external onlyWhitelisted {
        lockedInAmount[token] = lockedInAmount[token].add(amount);
    }

    // @dev only whitelisted contracts can attempt to unlock funds
    // This unlock is used when a user has lost a bet, and we unlock the funds
    // DO NOT use this when we mark a user as having won, because we need funds to be locked until users withdraw
    function unlockFunds(address token, uint256 amount) external onlyWhitelisted {
        lockedInAmount[token] = lockedInAmount[token].sub(amount);
    }

    // @dev reset lock when locked funds are too high, happens when there's congestion
    function resetLock(address token, uint256 amount) external onlyOwner {
        lockedInAmount[token] = amount;
    }

    /* ========== Core banking logic ========== */

    // @dev only token owners or owners can deposit capital into the bank
    function depositCapital(address token, uint amount) external payable onlyTokenOwnerOrOwnerOrKeeper(token) {
        if (token == address(0)) {
            require(msg.value == amount, "BNB: Deposit amount does not match specified amount");
        } else {
            require(msg.value == 0, "Token: Not supposed to deposit BNB");
            require(ERC20(token).transferFrom(msg.sender, address(this), amount));
        }
        tokenFunds[token] = tokenFunds[token].add(amount);
        tokenTotal[token] = tokenTotal[token].add(amount);

        emit DepositedCapital(msg.sender, token, amount, now);
    }

    // @dev only owner or token owners can attempt to withdraw earnings for a token
    // earnings is defined as (totalBalance - principal)
    // rest of earnings is sent to Treasure Key team
    function withdrawEarnings(address token, uint256 amount) external onlyTokenOwnerOrOwnerOrKeeper(token) {
        require(earned(token) >= amount, "Withdraw: needs to be profitable to withdraw earnings");
        
        uint toReturn = tokenReturnRatio[token].mul(amount).div(1000);

        if (token == address(0)) {
            // We naively send all requested BNB (minus dividends) since the owner of BNB is the owner
            // uint payout = processDividends(token, amount);
            payable(ownerOrKeeper()).transfer(amount);
        } else {
            // Transfer returned funds to token owner
            require(ERC20(token).transfer(tokenOwner[token], toReturn));
            // Uses remaining funds to calculate dividend payouts
            uint remaining = amount.sub(toReturn);
            // uint payout = processDividends(token, remaining);
            // Transfers remaining funds minus dividends
            require(ERC20(token).transfer(ownerOrKeeper(), remaining));
        }
        
        tokenTotal[token] = tokenTotal[token].sub(amount);
        tokenEarnTotal[token] = tokenEarnTotal[token].add(amount);

        emit EarningsWithdrawn(msg.sender, token, amount, now);
    }

    function distributeProfits() external payable onlyOwnerOrKeeper {
        processDividendsManually(msg.value);
    }

    // @dev only token owners can withdraw both earnings and initial capital
    function withdrawAll(address token) external payable onlyTokenOwner(token) {
        uint totalBalance = balanceOf(token);
        uint earnings = earned(token); // to return to tokenOwner based on basis points
        uint toReturn = tokenReturnRatio[token].mul(earnings).div(1000); // to return to tokenOwner

        if (token == address(0)) {
            // We naively send all BNB (minus dividends) since the owner of BNB is the owner
            // uint payout = processDividends(token, earnings);
            payable(ownerOrKeeper()).transfer(totalBalance);
        } else {
            // Uses remaining funds to calculate dividend payouts
            uint remaining = earnings.sub(toReturn);
            // uint payout = processDividends(token, remaining);
            // Transfer remaining funds minus dividends to Treasure Key dev
            require(ERC20(token).transfer(ownerOrKeeper(), remaining));
            // Transfer principal and toReturn to token owner
            require(ERC20(token).transfer(tokenOwner[token], totalBalance.sub(earnings).add(toReturn)));
        }
        tokenFunds[token] = 0;
        tokenTotal[token] = 0;
        tokenEarnTotal[token] = tokenEarnTotal[token].add(earnings);

        emit WithdrawnAll(msg.sender, token, totalBalance, now);
    }

    // @dev recover DUST tokens accumulated through swaps
    function recoverToken(address token, uint amount) external onlyOwner {
        if (token == address(0)) {
            require(address(this).balance.sub(amount) >= tokenTotal[token], "cannot recover token");
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).balanceOf(address(this)).sub(amount) >= tokenTotal[token], "cannot recover token");
            require(ERC20(token).transfer(owner(), amount));
        }
    }

    /* ========== Public Setters ========== */

    // @dev set token owner
    function setTokenOwner(address token, address account) public onlyOwner {
        require(tokenOwner[token] == address(0));
        require(account != address(0));
        tokenOwner[token] = account;
    }

    // @dev set token ratio out of 1000. e.g. 10/1000 is 1%
    function setTokenReturnRatio(address token, uint ratio) public onlyOwner {
        tokenReturnRatio[token] = ratio;
    }

    // @dev set token owner
    function setTokenRouter(address token, address router) public onlyOwner {
        require(router != address(0));
        tokenRouter[token] = router;
    }

    // @dev set pirate pool
    function setPiratePool(address pool) public onlyOwner {
        require(pool != address(0));
        PIRATE_POOL = pool;
    }

    // @dev set pirate pirate pool
    function setPiratePiratePool(address pool) public onlyOwner {
        require(pool != address(0));
        PIRATE_PIRATE_POOL = pool;
    }

    // @dev set dividend rate
    function setDividendRate(uint rate) public onlyOwner {
        require(rate >= 50); // above 5%
        require(rate <= 500); // below 50%
        dividendRate = rate;
    }

    /* ========== Profit distribution logic ========== */

    // @dev dividends are paid out to our PIRATE pool as PIRATE-BNB
    function processDividends(address token, uint amount) internal returns (uint dividendPayout) {
        dividendPayout = amount.mul(dividendRate).div(1000);
        uint wbnbAmount = 0;
        uint pirateAmount = 0;
        _approveTokenIfNeeded(WBNB);
        _approveTokenIfNeeded(PIRATE);
        if (token == address(0)) {
            wbnbAmount = dividendPayout.div(2);
            pirateAmount = _swapFromBNB(tokenRouter[PIRATE], WBNB, dividendPayout.sub(wbnbAmount), PIRATE, address(this));
            ROUTER.addLiquidityETH{value: wbnbAmount}(PIRATE, pirateAmount, 0, 0, address(this), block.timestamp);
        } else if (token == PIRATE) {
            // wbnbAmount = dividendPayout.div(2);
            // pirateAmount = _swapFromBNB(tokenRouter[PIRATE], PIRATE, dividendPayout.sub(wbnbAmount), WBNB, address(this));
            // PANTHER_ROUTER.addLiquidity(WBNB, PIRATE, wbnbAmount, pirateAmount, 0, 0, address(this), block.timestamp);
            // If PIRATE token, we share half of profits into pool
            // dividendPayout = amount.mul(500).div(1000);
            // ERC20(PIRATE).transfer(PIRATE_PIRATE_POOL, dividendPayout);
            // IStakingRewards(PIRATE_PIRATE_POOL).notifyRewardAmount(dividendPayout);
            // return dividendPayout;
            return 0;
        } else {
            wbnbAmount = _swap(tokenRouter[token], token, dividendPayout, WBNB, address(this));
            pirateAmount = _swap(tokenRouter[PIRATE], WBNB, wbnbAmount.div(2), PIRATE, address(this));
            ROUTER.addLiquidity(WBNB, PIRATE, wbnbAmount.sub(wbnbAmount.div(2)), pirateAmount, 0, 0, address(this), block.timestamp);
        }
        
        uint256 pirateBNBAmount = ERC20(PIRATE_BNB).balanceOf(address(this));
        ERC20(PIRATE_BNB).transfer(PIRATE_POOL, pirateBNBAmount);
        IStakingRewards(PIRATE_POOL).notifyRewardAmount(pirateBNBAmount);
    }

    function processDividendsManually(uint amount) internal returns (uint dividendPayout) {
        dividendPayout = amount;
        uint wbnbAmount = 0;
        uint pirateAmount = 0;
        _approveTokenIfNeeded(WBNB);
        _approveTokenIfNeeded(PIRATE);

        wbnbAmount = dividendPayout.div(2);
        pirateAmount = _swapFromBNB(address(ROUTER), WBNB, dividendPayout.sub(wbnbAmount), PIRATE, address(this));
        ROUTER.addLiquidityETH{value: wbnbAmount}(PIRATE, pirateAmount, 0, 0, address(this), block.timestamp);

        uint256 pirateBNBAmount = ERC20(PIRATE_BNB).balanceOf(address(this));
        ERC20(PIRATE_BNB).transfer(PIRATE_POOL, pirateBNBAmount);
        IStakingRewards(PIRATE_POOL).notifyRewardAmount(pirateBNBAmount);
    }

    // @dev swap from BNB into any other token
    function _swapFromBNB(address router, address _from, uint amount, address _to, address receiver) internal returns (uint) {
        if (_from == _to) return amount;
        address[] memory path;
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        
        uint[] memory amounts = IPantherRouter02(router).swapExactETHForTokens{value : amount}(0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    // @dev swap from any token into any other token
    function _swap(address router, address _from, uint amount, address _to, address receiver) internal returns (uint) {
        if (_from == _to) return amount;
        address[] memory path;
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        _approveTokenIfNeeded(_from, router);
        uint[] memory amounts = IPantherRouter01(router).swapExactTokensForTokens(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _approveTokenIfNeeded(address token) private {
        if (ERC20(token).allowance(address(this), address(ROUTER)) == 0) {
            ERC20(token).approve(address(ROUTER), uint(~0));
        }
    }

    function _approveTokenIfNeeded(address token, address router) private {
        if (ERC20(token).allowance(address(this), address(router)) == 0) {
            ERC20(token).approve(address(router), uint(~0));
        }
    }

    /* ========== Modifiers ========== */

    function ownerOrKeeper() internal view returns (address) {
        if (msg.sender == owner()) return owner();
        else return KEEPER;
    }

    modifier onlyTokenOwner(address token) {
        require(tokenOwner[token] == msg.sender, "only token owners");
        _;
    }

    modifier onlyOwnerOrKeeper() {
        require(owner() == msg.sender || KEEPER == msg.sender, "only owner or keeper");
        _;
    }

    modifier onlyTokenOwnerOrOwner(address token) {
        require(tokenOwner[token] == msg.sender || owner() == msg.sender, "only token owners or owner");
        _;
    }

    modifier onlyTokenOwnerOrOwnerOrKeeper(address token) {
        require(tokenOwner[token] == msg.sender || owner() == msg.sender || KEEPER == msg.sender, "only token owners or owner or keeper");
        _;
    }
}

pragma solidity >=0.6.2;

import './IPantherRouter01.sol';

interface IPantherRouter02 is IPantherRouter01 {
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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr
 * - changed asserts to requires with error log outputs
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x) internal pure returns (uint256) {
        return (mul(x, x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) return (0);
        else if (y == 0) return (1);
        else {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++) z = mul(z, x);
            return (z);
        }
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WhitelistUpgradeable is OwnableUpgradeable {
    mapping (address => bool) private _whitelist;
    bool private _disable;                      // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns(bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IStakingRewards {
    function notifyRewardAmount(uint256 reward) external;
}

pragma solidity >=0.6.2;

interface IPantherRouter01 {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

