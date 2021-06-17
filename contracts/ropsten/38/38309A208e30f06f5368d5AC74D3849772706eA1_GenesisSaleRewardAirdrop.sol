// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol"; 

import "../lib/Ownable.sol";

contract GenesisSaleRewardAirdrop is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice The address of the GridZone token
    IERC20 public zoneToken;

    uint256 private constant REWARD_SUPPLY = 140000e18; // 140K ZONE
    uint256 public immutable totalPurchasedAmount;
    uint256 public totalRewardedAmount;

    uint256 private constant DENOMINATOR = 10000;
    uint256 public immutable rewardRate;

    uint32 public immutable rewardsCount;
    uint32 public rewardedCount;
    bool public airdropActivated = false;

    mapping(address => uint256) public purchasedAmounts;

    address public admin;
    address public pendingAdmin;

    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewAdmin(address indexed newAdmin);
    event AirdropActivated(bool activate);
    event RewardClaimed(address indexed account, uint256 purchasedAmount, uint256 rewardAmount);

    modifier onlyAdmin() {
        require(admin == _msgSender(), "Restricted Access!");
        _;
    }

    constructor(address _zoneToken, address _ownerAddress, address _adminAddress) Ownable(_ownerAddress) public {
        require(_ownerAddress != address(0), "Owner address is invalid");
        zoneToken = IERC20(_zoneToken);
        admin = _adminAddress;

        (uint256 _totalPurchasedAmount, uint32 _rewardsCount) = _initRewards();
        totalPurchasedAmount = _totalPurchasedAmount;
        rewardsCount = _rewardsCount;
        rewardRate = REWARD_SUPPLY.mul(DENOMINATOR).div(_totalPurchasedAmount);
    }

    receive() external payable {
        require(false, "We will not accept ETH");
    }

    /* Update admin address */
    function setPendingAdmin(address _pendingAdmin) external onlyOwner() {
        pendingAdmin = _pendingAdmin;
        emit NewPendingAdmin(pendingAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);
        emit NewAdmin(admin);
    }

    function _initRewards() private returns (uint256 _totalPurchasedAmount, uint32 _rewardsCount) {
        uint256 _amount;
        _amount = 4876597000000000000000; purchasedAmounts[0xAa5d61cE6eB431f55dE741Ea6a6ff3a1AfE4D47B] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++; // TEMP
        _amount = 1642643200000000000000; purchasedAmounts[0xeFd9928Aa5A192C0267CdAed43235006B7A28628] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++; // TEMP
        _amount = 50819274000000000000000; purchasedAmounts[0xd91Fbc9b431464D737E1BC4e76900D43405a639b] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++; // TEMP
        _amount = 279996000000000000000000; purchasedAmounts[0x0C1b02F8126C3927DC8e71276e76193d6c3009a2] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++; // TEMP
        // _amount = 4876597000000000000000; purchasedAmounts[0xAE2a5Bca8E91b1e628453F46636632D7865a5B76] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        // _amount = 1642643200000000000000; purchasedAmounts[0x61befbBA6b5DB03D4564c9D6AD82B0Ff7a174DfC] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        // _amount = 50819274000000000000000; purchasedAmounts[0x3fD778F102e556D9d1b7054Bee1F996354137d60] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        // _amount = 279996000000000000000000; purchasedAmounts[0x504C11bDBE6E29b46E23e9A15d9c8d2e2e795709] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 12833150000000000000000; purchasedAmounts[0x93f5af632Ce523286e033f0510E9b3C9710F4489] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 12833150000000000000000; purchasedAmounts[0xecc8f56792CDb7983Aed06AE5d8eBf2eF1A55651] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 1343980800000000000000000; purchasedAmounts[0x83b4271b054818a93325c7299f006AEc2E90ef96] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 53899230000000000000000; purchasedAmounts[0xF2cDCA7e16407400d966c5DecD58E993C6bb1448] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 7699890000000000000000; purchasedAmounts[0x6e83e5fEa3f5D399BF8004a820A4fed518F26078] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 5133260000000000000000; purchasedAmounts[0x1de70e8fBBFB0Ca0c75234c499b5Db74BAE0D66B] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 128331500000000000000000; purchasedAmounts[0x50e954cCcf4376E3A1e43Ac37070215167baD93A] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 128331500000000000000000; purchasedAmounts[0x86A41524CB61edd8B115A72Ad9735F8068996688] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 128331500000000000000000; purchasedAmounts[0xF47588a5a54A0A2a1De1863A88A120bbc0b4b777] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 25666300000000000000000; purchasedAmounts[0x37b3fAe959F171767E34e33eAF7eE6e7Be2842C3] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 128331500000000000000000; purchasedAmounts[0x5b049c3Bef543a181A720DcC6fEbc9afdab5D377] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 51332600000000000000000; purchasedAmounts[0xEc7B7a7D8e5427e38C1cf57488c1d652924FF65A] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 25666300000000000000000; purchasedAmounts[0x4e6Eeea64b668502C43F5eD3B52c8591A7BB34Fd] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 25666300000000000000000; purchasedAmounts[0xF24A0018befb3D7503b46c110f83D927d64E727d] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 12833150000000000000000; purchasedAmounts[0x47115466E589aDD0E1409ad75e10F965719f69c5] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 14116465000000000000000; purchasedAmounts[0x8Cd05c3F9A1aE00e827312cB190B1d897CC5cC67] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 25666300000000000000000; purchasedAmounts[0x007800BFFc1c88eDbcd21835A71D17A7a87BA42D] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 35010823650000000000000; purchasedAmounts[0x07647C47d6823ad7785155C856b8bD22A4C3C1C4] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 1026652000000000000000; purchasedAmounts[0x526026039434039Ea966075F7bd0f4EBb3EBc6aF] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 23099670000000000000000; purchasedAmounts[0x7D7d7C915053a74DCD4d565619b2Eb36eef6220A] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 1283315000000000000000; purchasedAmounts[0x140CEe91461cCd2E0c8EAAe1580f9C0c5438511C] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 13346476000000000000000; purchasedAmounts[0xB9a0c9D0200A08aF16b4A149b3b9d45758ad29Df] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 1100000000000000000000; purchasedAmounts[0xfb7F46F5ac1189f768d1E3D470346135CeEc699E] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 256663000000000000000; purchasedAmounts[0xaa26cB9e66eDBAf69FeFC3F0847493fcec923734] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 13449141200000000000000; purchasedAmounts[0x76ccA216cEf6869926f20303e8B27A2344285DC7] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 13603139000000000000000; purchasedAmounts[0x50d06F7a017Fb5f5556f5FB4C11fAb0cC0A68b70] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 2566630000000000000000; purchasedAmounts[0x53Eebf648BdA109B9EdF1910Ef24A6ba14ab0806] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 16951406790000000000000; purchasedAmounts[0xBB6f34EC1f57Cd9FBf23A93Eb460B4BdD9CE0E35] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 7369934000000000000000; purchasedAmounts[0xF18Ca3753c5bba51B97Fd410542ca739b4De5E71] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 3079956000000000000000; purchasedAmounts[0x4102968b5eAE824D21f4aeaAB30974D1C257f90b] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 51332600000000000000000; purchasedAmounts[0xfcc34cB29FF87186ec256a1550Eb8c06dF6d8199] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 12833150000000000000000; purchasedAmounts[0x5dc52Bf79Ea83eFf9195540fB0D6265C77Fd5e62] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 8213216000000000000000; purchasedAmounts[0x7D9dCC23989Dddd636850cEd0e68b12478890e0f] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 15099484290000000000000; purchasedAmounts[0x34285C30FcEC41bcdF7C25dd7Cd908bcA7920C7a] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 1159658622000000000000; purchasedAmounts[0xb150B53A0a444eB153d1823C67d22795A3735DDa] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 1925000000000000000000; purchasedAmounts[0xbE3ab975D35c1493a92119658EDFeaEB575F660F] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
        _amount = 11267075250000000000000; purchasedAmounts[0x2781B553CaE0f0502Ee4a6c38cB6459bADef17E8] = _amount; _totalPurchasedAmount = _totalPurchasedAmount.add(_amount); _rewardsCount ++;
    }

    /**
     * @dev Activate/Deactivate the airdrop
     * @param _activate The flag to activate the airdrop
     */
    function activateAirdrop(bool _activate) external onlyOwner() {
        airdropActivated = _activate;
        emit AirdropActivated(airdropActivated);
    }

    function getRewardAmount(address _account) external view returns (uint256 _purchasedAmount, uint256 _rewardAmount) {
        _purchasedAmount = purchasedAmounts[_account];
        _rewardAmount = (0 < _purchasedAmount) ? _purchasedAmount.mul(rewardRate).div(DENOMINATOR) : 0;
    }

    function claimReward(address _account) external onlyAdmin() {
        require(airdropActivated, "The airdrop not activated yet");
        uint256 _purchasedAmount = purchasedAmounts[_account];
        require(0 < _purchasedAmount, "No purchased ZONE token");
        uint256 _rewardAmount = _purchasedAmount.mul(rewardRate).div(DENOMINATOR);

        purchasedAmounts[_account] = 0;
        totalRewardedAmount = totalRewardedAmount.add(_rewardAmount);
        rewardedCount ++;
        zoneToken.safeTransfer(_account, _rewardAmount);

        emit RewardClaimed(_account, _purchasedAmount, _rewardAmount);
    }

    function withdrawLeftToken() external onlyOwner() {
        uint256 _balance = zoneToken.balanceOf(address(this));
        require(0 < _balance, "No balance");
        zoneToken.safeTransfer(owner(), _balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;
    address private _pendingOwner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address _ownerAddress) internal {
        _owner = _ownerAddress;
        emit OwnershipTransferred(address(0), _ownerAddress);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
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
        _pendingOwner = newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == _pendingOwner, "acceptOwnership: Call must come from pendingOwner.");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}