/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// File: contracts/interface/ICoFiXV2DAO.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

interface ICoFiXV2DAO {

    function setGovernance(address gov) external;
    function start() external; 

    // function addETHReward() external payable; 

    event FlagSet(address gov, uint256 flag);
    event CoFiBurn(address gov, uint256 amount);
}
// File: contracts/interface/ICoFiXV2Controller.sol

pragma solidity 0.6.12;

interface ICoFiXV2Controller {

    event NewK(address token, uint256 K, uint256 sigma, uint256 T, uint256 ethAmount, uint256 erc20Amount, uint256 blockNum);
    event NewGovernance(address _new);
    event NewOracle(address _priceOracle);
    event NewKTable(address _kTable);
    event NewTimespan(uint256 _timeSpan);
    event NewKRefreshInterval(uint256 _interval);
    event NewKLimit(int128 maxK0);
    event NewGamma(int128 _gamma);
    event NewTheta(address token, uint32 theta);
    event NewK(address token, uint32 k);
    event NewCGamma(address token, uint32 gamma);

    function addCaller(address caller) external;

    function setCGamma(address token, uint32 gamma) external;

    function queryOracle(address token, uint8 op, bytes memory data) external payable returns (uint256 k, uint256 ethAmount, uint256 erc20Amount, uint256 blockNum, uint256 theta);

    function getKInfo(address token) external view returns (uint32 k, uint32 updatedAt, uint32 theta);

    function getLatestPriceAndAvgVola(address token) external payable returns (uint256, uint256, uint256, uint256);
}

// File: contracts/interface/ICoFiXV2Factory.sol

pragma solidity 0.6.12;

interface ICoFiXV2Factory {
    // All pairs: {ETH <-> ERC20 Token}
    event PairCreated(address indexed token, address pair, uint256);
    event NewGovernance(address _new);
    event NewController(address _new);
    event NewFeeReceiver(address _new);
    event NewFeeVaultForLP(address token, address feeVault);
    event NewVaultForLP(address _new);
    event NewVaultForTrader(address _new);
    event NewVaultForCNode(address _new);
    event NewDAO(address _new);

    /// @dev Create a new token pair for trading
    /// @param  token the address of token to trade
    /// @param  initToken0Amount the initial asset ratio (initToken0Amount:initToken1Amount)
    /// @param  initToken1Amount the initial asset ratio (initToken0Amount:initToken1Amount)
    /// @return pair the address of new token pair
    function createPair(
        address token,
	    uint256 initToken0Amount,
        uint256 initToken1Amount
        )
        external
        returns (address pair);

    function getPair(address token) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function getTradeMiningStatus(address token) external view returns (bool status);
    function setTradeMiningStatus(address token, bool status) external;
    function getFeeVaultForLP(address token) external view returns (address feeVault); // for LPs
    function setFeeVaultForLP(address token, address feeVault) external;

    function setGovernance(address _new) external;
    function setController(address _new) external;
    function setFeeReceiver(address _new) external;
    function setVaultForLP(address _new) external;
    function setVaultForTrader(address _new) external;
    function setVaultForCNode(address _new) external;
    function setDAO(address _new) external;
    function getController() external view returns (address controller);
    function getFeeReceiver() external view returns (address feeReceiver); // For CoFi Holders
    function getVaultForLP() external view returns (address vaultForLP);
    function getVaultForTrader() external view returns (address vaultForTrader);
    function getVaultForCNode() external view returns (address vaultForCNode);
    function getDAO() external view returns (address dao);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// File: contracts/interface/ICoFiToken.sol

pragma solidity 0.6.12;

interface ICoFiToken is IERC20 {

    /// @dev An event thats emitted when a new governance account is set
    /// @param  _new The new governance address
    event NewGovernance(address _new);

    /// @dev An event thats emitted when a new minter account is added
    /// @param  _minter The new minter address added
    event MinterAdded(address _minter);

    /// @dev An event thats emitted when a minter account is removed
    /// @param  _minter The minter address removed
    event MinterRemoved(address _minter);

    /// @dev Set governance address of CoFi token. Only governance has the right to execute.
    /// @param  _new The new governance address
    function setGovernance(address _new) external;

    /// @dev Add a new minter account to CoFi token, who can mint tokens. Only governance has the right to execute.
    /// @param  _minter The new minter address
    function addMinter(address _minter) external;

    /// @dev Remove a minter account from CoFi token, who can mint tokens. Only governance has the right to execute.
    /// @param  _minter The minter address removed
    function removeMinter(address _minter) external;

    /// @dev mint is used to distribute CoFi token to users, minters are CoFi mining pools
    /// @param  _to The receiver address
    /// @param  _amount The amount of tokens minted
    function mint(address _to, uint256 _amount) external;
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/lib/TransferHelper.sol

pragma solidity 0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/CoFiXV2DAO.sol

pragma solidity 0.6.12;

contract CoFiXV2DAO is ICoFiXV2DAO, ReentrancyGuard {

    using SafeMath for uint256;

    /* ========== STATE ============== */

    uint8 public flag; 

    uint32  public startedBlock;
    // uint32  public lastCollectingBlock;
    uint32 public lastBlock;
    uint128 public redeemedAmount;
    uint128 public quotaAmount;

    uint8 constant DAO_FLAG_UNINITIALIZED    = 0;
    uint8 constant DAO_FLAG_INITIALIZED      = 1;
    uint8 constant DAO_FLAG_ACTIVE           = 2;
    uint8 constant DAO_FLAG_NO_STAKING       = 3;
    uint8 constant DAO_FLAG_PAUSED           = 4;
    uint8 constant DAO_FLAG_SHUTDOWN         = 127;

    /* ========== PARAMETERS ============== */

    uint256 constant DAO_REPURCHASE_PRICE_DEVIATION = 10;  // price deviation < 5% 
    uint256 constant _oracleFee = 0.01 ether;


    /* ========== ADDRESSES ============== */

    address public cofiToken;

    address public factory;

    address public governance;

    /* ========== CONSTRUCTOR ========== */

    receive() external payable {
    }

    constructor(address _cofiToken, address _factory) public {
        cofiToken = _cofiToken;
        factory = _factory;
        governance = msg.sender;
        flag = DAO_FLAG_INITIALIZED;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernance() 
    {
        require(msg.sender == governance, "CDAO: not governance");
        _;
    }

    modifier whenActive() 
    {
        require(flag == DAO_FLAG_ACTIVE, "CDAO: not active");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function setGovernance(address _new) external override onlyGovernance {
        governance = _new;
    }

    function start() override external onlyGovernance
    {  
        require(flag == DAO_FLAG_INITIALIZED, "CDAO: not initialized");

        startedBlock = uint32(block.number);
        flag = DAO_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(DAO_FLAG_ACTIVE));
    }

    function pause() external onlyGovernance
    {
        flag = DAO_FLAG_PAUSED;
        emit FlagSet(address(msg.sender), uint256(DAO_FLAG_PAUSED));
    }

    function resume() external onlyGovernance
    {
        flag = DAO_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(DAO_FLAG_ACTIVE));
    }

    function totalETHRewards()
        external view returns (uint256) 
    {
       return address(this).balance;
    }

    function migrateTo(address _newDAO) external onlyGovernance
    {
        require(flag == DAO_FLAG_PAUSED, "CDAO: not paused");
        
        if(address(this).balance > 0) {
            TransferHelper.safeTransferETH(_newDAO, address(this).balance);
        }
        // ICoFiXV2DAO(_newDAO).addETHReward{value: address(this).balance}();

        uint256 _cofiTokenAmount = ICoFiToken(cofiToken).balanceOf(address(this));
        if (_cofiTokenAmount > 0) {
            ICoFiToken(cofiToken).transfer(_newDAO, _cofiTokenAmount);
        }
    }

    function burnCofi(uint256 amount) external onlyGovernance {
        require(amount > 0, "CDAO: illegal amount");

        uint256 _cofiTokenAmount = ICoFiToken(cofiToken).balanceOf(address(this));

        require(_cofiTokenAmount >= amount, "CDAO: insufficient cofi");

        ICoFiToken(cofiToken).transfer(address(0x1), amount);
        emit CoFiBurn(address(msg.sender), amount);
    }

    /* ========== MAIN ========== */

    // function addETHReward() 
    //     override
    //     external
    //     payable
    // { }

    function redeem(uint256 amount) 
        external payable nonReentrant whenActive
    {
        require(address(this).balance > 0, "CDAO: insufficient balance");
        require (msg.value == _oracleFee, "CDAO: !oracleFee");

        // check the repurchasing quota
        uint256 quota = quotaOf();

        uint256 price;
        {
            // check if the price is steady
            (uint256 ethAmount, uint256 tokenAmount, uint256 avg, ) = ICoFiXV2Controller(ICoFiXV2Factory(factory).getController())
                    .getLatestPriceAndAvgVola{value: msg.value}(cofiToken);
            price = tokenAmount.mul(1e18).div(ethAmount);

            uint256 diff = price > avg ? (price - avg) : (avg - price);
            bool isDeviated = (diff.mul(100) < avg.mul(DAO_REPURCHASE_PRICE_DEVIATION))? false : true;
            require(isDeviated == false, "CDAO: price deviation"); // validate
        }

        // check if there is sufficient quota for repurchase
        require (amount <= quota, "CDAO: insufficient quota");
        require (amount.mul(1e18) <= address(this).balance.mul(price), "CDAO: insufficient balance2");

        redeemedAmount = uint128(amount.add(redeemedAmount));
        quotaAmount = uint128(quota.sub(amount));
        lastBlock = uint32(block.number);

        uint256 amountEthOut = amount.mul(1e18).div(price);

        // transactions
        ICoFiToken(cofiToken).transferFrom(address(msg.sender), address(this), amount);
        TransferHelper.safeTransferETH(msg.sender, amountEthOut);
    }

    function _quota() internal view returns (uint256 quota) 
    {
        uint256 n = 100;
        uint256 intv = (lastBlock == 0) ? 
            (block.number).sub(startedBlock) : (block.number).sub(uint256(lastBlock));
        uint256 _acc = (n * intv > 30_000) ? 30_000 : (n * intv);

        // check if total amounts overflow
        uint256 total = _acc.mul(1e18).add(quotaAmount);
        if (total > uint256(30_000).mul(1e18)){
            quota = uint256(30_000).mul(1e18);
        } else{
            quota = total;
        }
    }

    /* ========== VIEWS ========== */

    function quotaOf() public view returns (uint256 quota) 
    {
        return _quota();
    }

}