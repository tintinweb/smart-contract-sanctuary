// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

// This contract generates Presale01 contracts and registers them in the PresaleFactory.
// Ideally you should not interact with this contract directly, and use the Octofi presale app instead so warnings can be shown where necessary.

pragma solidity 0.6.12;
import "./SafeMath.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./PresaleSetting.sol";
import "./PresaleLockForwarder.sol";
import "./Presale.sol";

// interface IPresaleSettings {
//     function getRaisedFeeAddress () external view returns (address _raise_fee_addr);
//     function getRasiedFee () external view returns (uint256);
//     function getSoleFeeAddress () external view returns (address _sole_fee_address);
//     function getSoldFee () external view returns (uint256);
//     function getReferralFeeAddress () external view returns (address);
//     function getRefferralFee () external view returns (uint256);
//     function getLockFee() external view returns (uint256);
// }

contract PresaleManage {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PresaleInfo {
        address payable presale_owner;
        address sale_token; // sale token
        uint256 token_rate; // 1 base token = ? s_tokens, fixed price
        uint256 raise_min; // maximum base token BUY amount per buyer
        uint256 raise_max; // the amount of presale tokens up for presale
        uint256 hardcap; // Maximum riase amount
        uint256 softcap; //Minimum raise amount
        uint256 liqudity_percent; // divided by 1000
        uint256 listing_rate; // fixed rate at which the token will list on uniswap
        uint256 lock_end; // uniswap lock timestamp -> e.g. 2 weeks
        uint256 lock_start;
        uint256 presale_end;// presale period
        uint256 presale_start; // presale start
    }
    
    struct PresaleLink {
        string website_link;
        string github_link;
        string twitter_link;
        string reddit_link;
        string telegram_link;
    }

    EnumerableSet.AddressSet private presales;

    address private presale_lock_forward_addr;
    address private presale_setting_addr;
    PresaleLockForwarder _lock;

    address private uniswap_factory_address;
    address private uniswap_pair_address;
    
    address private weth_address;

    address payable owner;

    PresaleInfo presale_info;
    PresaleLink presalelink;

    IPresaleSettings public settings;

    event OwnerWithdrawSucess(uint value);

    constructor(address payable _owner, address lock_addr, address uniswapfactory_addr, address uniswappair_addr, address weth_addr) public {
        owner = _owner;

        uniswap_factory_address = uniswapfactory_addr;
        weth_address = weth_addr;

        _lock = new PresaleLockForwarder(lock_addr, uniswapfactory_addr, uniswappair_addr);
        presale_lock_forward_addr = address(_lock);
        
        PresaleSettings _setting;
        
        _setting = new PresaleSettings(address(this), _owner, lock_addr);
        
        _setting.init( 0.1 ether, owner, 20, owner, 20, owner, 20);
        
        presale_setting_addr = address(_setting);

        settings = IPresaleSettings(presale_setting_addr);
    }

    function ownerWithdraw() public {
        owner.transfer(address(this).balance);
        emit OwnerWithdrawSucess(address(this).balance);
    }
    
    /**
     * @notice Creates a new Presale contract and registers it in the PresaleFactory.sol.
     */

    function calculateAmountRequired (uint256 _amount, uint256 _tokenPrice, uint256 _listingRate, uint256 _liquidityPercent, uint256 _tokenFee) public pure returns (uint256) {
        uint256 tokenamount = _amount.mul(_tokenPrice).div(100);
        uint256 TokenFee = _amount.mul(_tokenFee).div(100);
        uint256 liquidityRequired = _amount.mul(_liquidityPercent).mul(_listingRate).div(10000);
        uint256 tokensRequiredForPresale = tokenamount.add(liquidityRequired).add(TokenFee);
        return tokensRequiredForPresale;
    }

    function createPresale  (
        address payable _presaleOwner,
        address _presaleToken,
        uint256[11] memory uint_params,
        string memory _website_link,
        string memory _github_link,
        string memory _twitter_llink,
        string memory _reddit_link,
        string memory _telegram_link
        ) public payable {

        presale_info.presale_owner = _presaleOwner;
        presale_info.sale_token = _presaleToken;
        presale_info.token_rate = uint_params[0];
        presale_info.raise_min = uint_params[1];
        presale_info.raise_max = uint_params[2];
        presale_info.softcap = uint_params[3];
        presale_info.hardcap = uint_params[4];
        presale_info.liqudity_percent = uint_params[5];
        presale_info.listing_rate = uint_params[6];
        presale_info.presale_start = uint_params[7];
        presale_info.presale_end = uint_params[8];
        presale_info.lock_start = uint_params[9];
        presale_info.lock_end = uint_params[10];

        presalelink.website_link = _website_link;
        presalelink.github_link = _github_link;
        presalelink.twitter_link = _twitter_llink;
        presalelink.reddit_link = _reddit_link;
        presalelink.telegram_link = _telegram_link;
        
        if ( (presale_info.presale_end - presale_info.presale_start) < 1 weeks) {
            presale_info.presale_end = presale_info.presale_start + 1 weeks;
        }

        if ( (presale_info.lock_end - presale_info.lock_start) < 4 weeks) {
            presale_info.lock_end = presale_info.lock_start + 4 weeks;
        }
        
        // Charge ETH fee for contract creation
        require(msg.value >= settings.getPresaleCreateFee() + settings.getLockFee(), 'Balance is insufficent');

        require(presale_info.token_rate > 0, 'token rate is invalid'); 
        require(presale_info.raise_min < presale_info.raise_max, "raise min/max in invalid");
        require(3 * presale_info.softcap >= presale_info.hardcap && presale_info.softcap <= presale_info.hardcap, "softcap/hardcap is invalid");
        require(presale_info.liqudity_percent >= 30 && presale_info.liqudity_percent <= 100, 'Liqudity percent is invalid'); 
        require(presale_info.listing_rate > 0, 'Listing rate is invalid');

        // Calculate required token amount
        uint256 tokensRequiredForPresale = calculateAmountRequired(presale_info.hardcap, presale_info.token_rate, presale_info.listing_rate, presale_info.liqudity_percent, settings.getSoldFee());
        
        // Create New presale
        PresaleV1 newPresale = (new PresaleV1){value: settings.getLockFee()}(address(this), weth_address, presale_setting_addr, presale_lock_forward_addr);
        
        // newPresale.delegatecall(bytes4(sha3("destroy()")));
        
        if(address(newPresale) == address(0)) {
            newPresale.destroy();
            require(false,'Create presale Failed'); 
        }

        TransferHelper.safeTransferFrom(address(_presaleToken), address(msg.sender), address(newPresale), tokensRequiredForPresale);
    
        newPresale.init_private(presale_info.presale_owner, presale_info.sale_token, presale_info.token_rate, presale_info.raise_min, presale_info.raise_max, presale_info.softcap, 
        presale_info.hardcap, presale_info.liqudity_percent, presale_info.listing_rate, presale_info.lock_end, presale_info.presale_start, presale_info.presale_end);

        newPresale.init_link(presalelink.website_link, presalelink.github_link, presalelink.twitter_link, presalelink.reddit_link, presalelink.telegram_link);
        
        newPresale.init_fee();

        presales.add(address(newPresale));
    }

    function getCount () external view returns (uint256) {
        return presales.length();
    }

    function get5Presale (uint256 index) external view returns (address) {
        return presales.at(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
// Subject to the MIT license.

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

// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

// Settings to initialize presale contracts and edit fees.

pragma solidity 0.6.12;

interface ILpLocker {
    function price() external pure returns (uint256);
}

contract PresaleSettings {
    
    address private owner;
    address private manage;
    ILpLocker locker;
    
    struct SettingsInfo {
        uint256 raised_fee; // divided by 100
        uint256 sold_fee; // divided by 100
        uint256 referral_fee; // divided by 100
        uint256 presale_create_fee; // divided by 100
        address payable raise_fee_address;
        address payable sole_fee_address;
        address payable referral_fee_address; // if this is not address(0), there is a valid referral
    }

    SettingsInfo public info;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyManager() {
        require(manage == msg.sender, "Ownable: caller is not the manager");
        _;
    }
    
    event setRaiseFeeAddrSuccess(address indexed addr);
    event setRaisedFeeSuccess(uint256 num);
    event setSoleFeeAddrSuccess(address indexed addr);
    event setSoldFeeSuccess(uint256 num);
    event setReferralFeeAddrSuccess(address addr);
    event setReferralFeeSuccess(uint256 num);
    
    constructor(address _manage, address _owner, address lockaddr) public {
        owner = _owner;
        manage = _manage;
        locker = ILpLocker(lockaddr);
    }
    
    function init (
        uint256 _presale_create_fee,
        address payable _raise_fee_addr,
        uint256 _raised_fee, 
        address payable _sole_fee_address, 
        uint256 _sold_fee, 
        address payable _referral_fee_address, 
        uint256 _referral_fee
        ) public onlyManager {
        info.presale_create_fee = _presale_create_fee;
        info.raise_fee_address = _raise_fee_addr;
        info.raised_fee = _raised_fee;
        info.sole_fee_address = _sole_fee_address;
        info.sold_fee = _sold_fee;
        info.referral_fee_address = _referral_fee_address;
        info.referral_fee = _referral_fee;
    }
    
    function getRaisedFeeAddress () external view returns (address payable _raise_fee_addr) {
        return info.raise_fee_address;
    }
    
    function setRaisedFeeAddress (address payable _raised_fee_addr) external onlyOwner {
        info.raise_fee_address = _raised_fee_addr;
        emit setRaiseFeeAddrSuccess(info.raise_fee_address);
    }

    function getRasiedFee () external view returns (uint256) {
        return info.raised_fee;
    }
    
    function setRaisedFee (uint256 _raised_fee) external onlyOwner {
        info.raised_fee = _raised_fee;
        emit setRaisedFeeSuccess(info.raised_fee);
    }
    
    function getSoleFeeAddress () external view returns (address payable _sole_fee_address) {
        return info.sole_fee_address;
    }
    
    function setSoleFeeAddress (address payable _sole_fee_address) external onlyOwner {
        info.sole_fee_address = _sole_fee_address;
        emit setSoleFeeAddrSuccess(info.sole_fee_address);
    }

    function getSoldFee () external view returns (uint256) {
        return info.sold_fee;
    }
    
    function setSoldFee (uint256 _sold_fee) external onlyOwner {
        info.sold_fee = _sold_fee;
        emit setSoldFeeSuccess(info.sold_fee);
    }
    
    function getReferralFeeAddress () external view returns (address payable) {
        return info.referral_fee_address;
    }
    
    function setReferralFeeAddress (address payable _referral_fee_address) external onlyOwner {
        info.sole_fee_address = _referral_fee_address;
        emit setReferralFeeAddrSuccess(info.referral_fee_address);
    }

    function getRefferralFee () external view returns (uint256) {
        return info.referral_fee;
    }
    
    function setRefferralFee (uint256 _referral_fee) external onlyOwner {
        info.referral_fee = _referral_fee;
        emit setReferralFeeSuccess(info.referral_fee);
    }
    
    function getLockFee() external view returns (uint256) {
        return locker.price();
    }
    
    function getPresaleCreateFee () external view returns (uint256) {
        return info.presale_create_fee;
    }
    
    function setSetPresaleCreateFee (uint256 _presale_create_fee) external onlyOwner {
        info.presale_create_fee = _presale_create_fee;
        emit setReferralFeeSuccess(info.presale_create_fee);
    }
}

// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

/**
    This contract creates the lock on behalf of each presale. This contract will be whitelisted to bypass the flat rate 
    ETH fee. Please do not use the below locking code in your own contracts as the lock will fail without the ETH fee
*/

pragma solidity 0.6.12;

import "./TransferHelper.sol";
import "./IERC20.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

interface IILpLocker {
    function lpLock(address token, uint256 amount, uint256 unlockTime, address _withdrawer) payable external;
    function price() external pure returns (uint256);
    event Hold(address indexed holder, address token, uint256 amount, uint256 unlockTime);
}

contract PresaleLockForwarder {
    IILpLocker public lplocker;
    IUniswapV2Factory public uniswapfactory;
    IUniswapV2Pair public uniswappair;

    constructor(address lplock_addrress, address unifactaddr, address unipairaddr) public {
        lplocker = IILpLocker(lplock_addrress);
        uniswappair = IUniswapV2Pair(unipairaddr);
        uniswapfactory = IUniswapV2Factory(unifactaddr);
    }

    /**
        Send in _token0 as the PRESALE token, _token1 as the BASE token (usually WETH) for the check to work. As anyone can create a pair,
        and send WETH to it while a presale is running, but no one should have access to the presale token. If they do and they send it to 
        the pair, scewing the initial liquidity, this function will return true
    */
    function uniswapPairIsInitialised (address _token0, address _token1) public view returns (bool) {
        address pairAddress = uniswapfactory.getPair(_token0, _token1);
        if (pairAddress == address(0)) {
            return false;
        }
        uint256 balance = IERC20(_token0).balanceOf(pairAddress);
        if (balance > 0) {
            return true;
        }
        return false;
    }
    
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) payable external {
        // require(PRESALE_FACTORY.presaleIsRegistered(msg.sender), 'PRESALE NOT REGISTERED');
        require(msg.value >= lplocker.price(), 'Balance is insufficient');
        address pair = uniswapfactory.getPair(address(_baseToken), address(_saleToken));
        if (pair == address(0)) {
            uniswapfactory.createPair(address(_baseToken), address(_saleToken));
            pair = uniswapfactory.getPair(address(_baseToken), address(_saleToken));
        }
        
        TransferHelper.safeTransferFrom(address(_baseToken), msg.sender, address(pair), _baseAmount);
        TransferHelper.safeTransferFrom(address(_saleToken), msg.sender, address(pair), _saleAmount);
        IUniswapV2Pair(pair).mint(_withdrawer);
        uint256 totalLPTokensMinted = IUniswapV2Pair(pair).balanceOf(_withdrawer);
        require(totalLPTokensMinted != 0 , "LP creation failed");
    
        TransferHelper.safeApprove(pair, address(lplocker), totalLPTokensMinted);
        uint256 unlock_date = _unlock_date > 9999999999 ? 9999999999 : _unlock_date;
        lplocker.lpLock{value:msg.value}(pair, totalLPTokensMinted, unlock_date, _withdrawer );
    }
    
}

// SPDX-License-Identifier: UNLICENSED
// @Credits Defi Site Network 2021

// Presale contract. Version 1

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

// interface IUniswapV2Factory {
//     function getPair(address tokenA, address tokenB) external view returns (address pair);
//     function createPair(address tokenA, address tokenB) external returns (address pair);
// }

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IPresaleSettings {
    function getRaisedFeeAddress () external view returns (address payable);
    function getRasiedFee () external view returns (uint256);
    function getSoleFeeAddress () external view returns (address payable);
    function getSoldFee () external view returns (uint256);
    function getReferralFeeAddress () external view returns (address payable);
    function getRefferralFee () external view returns (uint256);
    function getLockFee() external view returns (uint256);
    function getPresaleCreateFee () external view returns (uint256);
}

interface IPresaleLockForwarder {
    function uniswapPairIsInitialised (address _token0, address _token1) external view returns (bool);
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) payable external;
}

contract PresaleV1 is ReentrancyGuard {
  using SafeMath for uint256;
  /// @notice Presale Contract Version, used to choose the correct ABI to decode the contract
  uint256 public contract_version = 1;
  
  struct PresaleInfo {
    address payable presale_owner;
    IERC20 sale_token; // sale token
    IERC20 base_token; // base token // usually WETH (ETH)
    uint256 token_rate; // 1 base token = ? s_tokens, fixed price
    uint256 raise_min; // maximum base token BUY amount per buyer
    uint256 raise_max; // the amount of presale tokens up for presale
    uint256 hardcap; // Maximum riase amount
    uint256 softcap; //Minimum raise amount
    uint256 liqudity_percent; // divided by 1000
    uint256 listing_rate; // fixed rate at which the token will list on uniswap
    uint256 lock_end; // uniswap lock timestamp -> e.g. 2 weeks
    uint256 lock_start;
    uint256 presale_end;// presale period
    uint256 presale_start; // presale start
    // bool iseth; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as DAI
  }
  
  struct PresaleLink {
      string website_link;
      string github_link;
      string twitter_link;
      string reddit_link;
      string telegram_link;
  }
  
  struct PresaleFeeInfo {
    uint256 raised_fee; // divided by 100
    uint256 sold_fee; // divided by 100
    uint256 referral_fee; // divided by 100
    address payable raise_fee_address;
    address payable sole_fee_address;
    address payable referral_fee_address; // if this is not address(0), there is a valid referral
  }
  
  struct PresaleStatus {
    bool lp_generation_complete; // final flag required to end a presale and enable withdrawls
    bool force_failed; // set this flag to force fail the presale
    uint256 raised_amount; // total base currency raised (usually ETH)
    uint256 sold_amount; // total presale tokens sold
    uint256 token_withdraw; // total tokens withdrawn post successful presale
    uint256 base_withdraw; // total base tokens withdrawn on presale failure
    uint256 num_buyers; // number of unique participants
  }

  struct BuyerInfo {
    uint256 base; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
    uint256 sale; // num presale tokens a user is owed, can be withdrawn on presale success
  }
  
  PresaleInfo public presale_info;
  PresaleStatus public status;
  PresaleLink public link;
  PresaleFeeInfo public presale_fee_info;

  address manage_addr;

  // IUniswapV2Factory public uniswapfactory;
  IWETH public WETH;
  IPresaleSettings public presale_setting;
  IPresaleLockForwarder public presale_lock_forwarder;
  
  mapping(address => BuyerInfo) public buyers;

  constructor(address manage, address wethfact, address setting, address lockaddr) public payable{
      
    presale_setting = IPresaleSettings(setting);

    require(msg.value >= presale_setting.getLockFee(), 'Balance is insufficent');

    manage_addr = manage;
    
    // uniswapfactory = IUniswapV2Factory(uniswapfact);
    WETH = IWETH(wethfact);
    
    presale_lock_forwarder = IPresaleLockForwarder(lockaddr);
  }

  function init_private (
    address payable _presale_owner,
    address _sale_token,
    // address _base_token,
    uint256 _token_rate,
    uint256 _raise_min, 
    uint256 _raise_max, 
    uint256 _softcap, 
    uint256 _hardcap,
    uint256 _liqudity_percent,
    uint256 _listing_rate,
    uint256 _lock_end,
    uint256 _presale_start,
    uint256 _presale_end
    // bool _iseth
    ) external {
      
      require(msg.sender == manage_addr, 'Only manage address is available');
      
      presale_info.presale_owner = _presale_owner;
      presale_info.sale_token = IERC20(_sale_token);
    //   if( !_iseth ) {
        presale_info.base_token = IERC20(address(WETH));
    //   } else {
    //     presale_info.base_token = _base_token;  
    //   }
      presale_info.token_rate = _token_rate;
      presale_info.raise_min = _raise_min;
      presale_info.raise_max = _raise_max;
      presale_info.softcap = _softcap;
      presale_info.hardcap = _hardcap;
      presale_info.liqudity_percent = _liqudity_percent;
      presale_info.listing_rate = _listing_rate;
      presale_info.lock_end = _lock_end;
      presale_info.presale_end = _presale_end;
      presale_info.presale_start =  _presale_start;
  }

  function init_link (
    string memory _website_link,
    string memory _github_link,
    string memory _twitter_link,
    string memory _reddit_link,
    string memory _telegram_link
  ) external {
      
      require(msg.sender == manage_addr, 'Only manage address is available');
      
      link.website_link = _website_link;
      link.github_link = _github_link;
      link.twitter_link = _twitter_link;
      link.reddit_link = _reddit_link;
      link.telegram_link = _telegram_link;
  }
  
  function init_fee () external {
          
    require(msg.sender == manage_addr, 'Only manage address is available');

    presale_fee_info.raised_fee = presale_setting.getRasiedFee(); // divided by 100
    presale_fee_info.sold_fee = presale_setting.getSoldFee(); // divided by 100
    presale_fee_info.referral_fee = presale_setting.getRefferralFee(); // divided by 100
    presale_fee_info.raise_fee_address = presale_setting.getRaisedFeeAddress();
    presale_fee_info.sole_fee_address = presale_setting.getSoleFeeAddress();
    presale_fee_info.referral_fee_address = presale_setting.getReferralFeeAddress(); // if this is not address(0), there is a valid referral
  }
  
  modifier onlyPresaleOwner() {
    require(presale_info.presale_owner == msg.sender, "NOT PRESALE OWNER");
    _;
  }
  
  function presaleStatus () public view returns (uint256) {
    if (status.force_failed) {
      return 3; // FAILED - force fail
    }
    if ((block.timestamp > presale_info.presale_end) && (status.raised_amount < presale_info.softcap)) {
      return 3;
    }
    if (status.raised_amount >= presale_info.hardcap) {
      return 2; // SUCCESS - hardcap met
    }
    if ((block.timestamp > presale_info.presale_end) && (status.raised_amount >= presale_info.softcap)) {
      return 2; // SUCCESS - preslae end and soft cap reached
    }
    if ((block.timestamp >= presale_info.presale_start) && (block.timestamp <= presale_info.presale_end)) {
      return 1; // ACTIVE - deposits enabled
    }
    return 0; // QUED - awaiting start block
  }
  
  // accepts msg.value for eth or _amount for ERC20 tokens
  function userDeposit () external payable nonReentrant {
    require(presaleStatus() == 1, 'NOT ACTIVE'); // ACTIVE

    BuyerInfo storage buyer = buyers[msg.sender];

    uint256 amount_in = msg.value;
    uint256 allowance = presale_info.raise_max.sub(buyer.base);
    uint256 remaining = presale_info.hardcap - status.raised_amount;
    allowance = allowance > remaining ? remaining : allowance;
    if (amount_in > allowance) {
      amount_in = allowance;
    }
    uint256 tokensSold = amount_in.mul(presale_info.token_rate).div(10 ** uint256(presale_info.sale_token.decimals()));
    require(tokensSold > 0, 'ZERO TOKENS');
    if (buyer.base == 0) {
        status.num_buyers++;
    }
    buyers[msg.sender].base = buyers[msg.sender].base.add(amount_in);
    buyers[msg.sender].sale = buyers[msg.sender].sale.add(tokensSold);
    status.raised_amount = status.raised_amount.add(amount_in);
    status.sold_amount = status.sold_amount.add(tokensSold);
    
    // return unused ETH
    if (amount_in < msg.value) {
      msg.sender.transfer(msg.value.sub(amount_in));
    }
  }
  
  // withdraw presale tokens
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawTokens () external nonReentrant {
    require(status.lp_generation_complete, 'AWAITING LP GENERATION');
    BuyerInfo storage buyer = buyers[msg.sender];
    uint256 tokensRemainingDenominator = status.sold_amount.sub(status.token_withdraw);
    uint256 tokensOwed = presale_info.sale_token.balanceOf(address(this)).mul(buyer.sale).div(tokensRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    status.token_withdraw = status.token_withdraw.add(buyer.sale);
    buyers[msg.sender].sale = 0;
    TransferHelper.safeTransfer(address(presale_info.sale_token), msg.sender, tokensOwed);
  }
  
  // on presale failure
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawBaseTokens () external nonReentrant {
    require(presaleStatus() == 3, 'NOT FAILED'); // FAILED
    BuyerInfo storage buyer = buyers[msg.sender];
    uint256 baseRemainingDenominator = status.raised_amount.sub(status.base_withdraw);
    uint256 remainingBaseBalance = address(this).balance;
    uint256 tokensOwed = remainingBaseBalance.mul(buyer.base).div(baseRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    status.base_withdraw = status.base_withdraw.add(buyer.base);
    buyer.base = 0;
    TransferHelper.safeTransferBaseToken(address(presale_info.base_token), msg.sender, tokensOwed, false);
  }
  
  // on presale failure
  // allows the owner to withdraw the tokens they sent for presale & initial liquidity
  function ownerWithdrawTokens () external onlyPresaleOwner {
    require(presaleStatus() == 3); // FAILED
    TransferHelper.safeTransfer(address(presale_info.sale_token), presale_info.presale_owner, presale_info.sale_token.balanceOf(address(this)));
  }
  

  // Can be called at any stage before or during the presale to cancel it before it ends.
  // If the pair already exists on uniswap and it contains the presale token as liquidity 
  // the final stage of the presale 'addLiquidity()' will fail. This function 
  // allows anyone to end the presale prematurely to release funds in such a case.
  function forceFailIfPairExists () external {
    require(!status.lp_generation_complete && !status.force_failed);
    if (presale_lock_forwarder.uniswapPairIsInitialised(address(presale_info.sale_token), address(presale_info.base_token))) {
        status.force_failed = true;
    }
  }
  
  // if something goes wrong in LP generation
  // function forceFail () external {
  //     require(msg.sender == OCTOFI_FEE_ADDRESS);
  //     status.force_failed = true;
  // }
  
  // on presale success, this is the final step to end the presale, lock liquidity and enable withdrawls of the sale token.
  // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
  // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to 
  // the presale parameters and fixed prices.
  function addLiquidity() external nonReentrant {
    require(!status.lp_generation_complete, 'GENERATION COMPLETE');
    require(presaleStatus() == 2, 'NOT SUCCESS'); // SUCCESS
    // Fail the presale if the pair exists and contains presale token liquidity
    if (presale_lock_forwarder.uniswapPairIsInitialised(address(presale_info.sale_token), address(presale_info.base_token))) {
        status.force_failed = true;
        return;
    }
    
    uint256 presale_raisedfee = status.raised_amount.mul(presale_setting.getRasiedFee()).div(100);
    
    // base token liquidity
    uint256 baseLiquidity = status.raised_amount.sub(presale_raisedfee).mul(presale_info.liqudity_percent).div(100);

    WETH.deposit{value : baseLiquidity}();

    TransferHelper.safeApprove(address(presale_info.base_token), address(presale_lock_forwarder), baseLiquidity);
    
    // sale token liquidity
    uint256 tokenLiquidity = baseLiquidity.mul(presale_info.listing_rate).div(10 ** uint256(presale_info.base_token.decimals()));
    TransferHelper.safeApprove(address(presale_info.sale_token), address(presale_lock_forwarder), tokenLiquidity);
    
    presale_lock_forwarder.lockLiquidity{value : presale_setting.getLockFee()}(presale_info.base_token, presale_info.sale_token, baseLiquidity, tokenLiquidity, presale_info.lock_end, presale_info.presale_owner);
    
    // transfer fees
    uint256 presaleSoldFee = status.sold_amount.mul(presale_setting.getSoldFee()).div(100);
    // referrals are checked for validity in the presale generator
    // if (presale_fee_info.referral_fee_address != address(0)) {
    //     // Base token fee
    //     uint256 referralBaseFee = presaleSoldFee.mul(presale_fee_info.referral_fee).div(100);
    //     TransferHelper.safeTransferBaseToken(address(presale_info.base_token), presale_fee_info.referral_fee_address, referralBaseFee, false);
    //     presale_raisedfee = presale_raisedfee.sub(referralBaseFee);
    //     // Token fee
    //     uint256 referralTokenFee = presaleSoldFee.mul(presale_fee_info.referral_fee).div(100);
    //     TransferHelper.safeTransfer(address(presale_info.sale_token), presale_fee_info.referral_fee_address, referralTokenFee);
    //     presaleSoldFee = presaleSoldFee.sub(referralTokenFee);
    // }
    TransferHelper.safeTransferBaseToken(address(presale_info.base_token), presale_fee_info.raise_fee_address, presale_raisedfee, false);
    TransferHelper.safeTransfer(address(presale_info.sale_token), presale_fee_info.sole_fee_address, presaleSoldFee);
    
    // burn unsold tokens
    uint256 remainingSBalance = presale_info.sale_token.balanceOf(address(this));
    if (remainingSBalance > status.sold_amount) {
        uint256 burnAmount = remainingSBalance.sub(status.sold_amount);
        TransferHelper.safeTransfer(address(presale_info.sale_token), 0x000000000000000000000000000000000000dEaD, burnAmount);
    }
    
    // send remaining base tokens to presale owner
    uint256 remainingBaseBalance = address(this).balance;
    TransferHelper.safeTransferBaseToken(address(presale_info.base_token), presale_info.presale_owner, remainingBaseBalance, false);
    
    status.lp_generation_complete = true;
  }

  function destroy() external {
    selfdestruct(presale_info.presale_owner);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol
// Subject to the MIT license.

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}