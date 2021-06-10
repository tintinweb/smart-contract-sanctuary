// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from "./IERC20.sol";
import {SafeERC20} from "./SafeERC20.sol";
import {IMarginPool} from "./IMarginPool.sol";
import {IXToken} from "./IXToken.sol";
import {WadRayMath} from "./WadRayMath.sol";
import {Errors} from "./Errors.sol";
import {IncentivizedERC20} from "./IncentivizedERC20.sol";
import {SafeMath} from "./SafeMath.sol";
import {
    IMarginPoolAddressesProvider
} from "./IMarginPoolAddressesProvider.sol";
import {Address} from "./Address.sol";

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
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(
            localCounter == _guardCounter,
            "ReentrancyGuard: reentrant call"
        );
    }
}

/**
 * @title Lever ERC20 XToken
 * @dev Implementation of the interest bearing token for the Lever protocol
 * @author Lever
 */
contract XToken is
    IncentivizedERC20,
    IXToken,
    ReentrancyGuard
{
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    // address public rewardsDistribution;
    IERC20 public rewardsToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 public constant UINT_MAX_VALUE = uint256(-1);
    address public immutable UNDERLYING_ASSET_ADDRESS;
    address public immutable RESERVE_TREASURY_ADDRESS;
    IMarginPool public immutable POOL;
    IMarginPoolAddressesProvider public addressesProvider;

    /// @dev owner => next valid nonce to submit with permit()
    mapping(address => uint256) public _nonces;

    bytes32 public DOMAIN_SEPARATOR;

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == addressesProvider.getRewardsDistribution(),
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    modifier onlyMarginPool {
        require(
            _msgSender() == address(POOL),
            Errors.CT_CALLER_MUST_BE_MARGIN_POOL
        );
        _;
    }

    constructor(
        address _addressesProvider,
        address underlyingAssetAddress,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 decimals
    ) public IncentivizedERC20(tokenName, tokenSymbol, decimals) {
        addressesProvider = IMarginPoolAddressesProvider(_addressesProvider);
        POOL = IMarginPool(addressesProvider.getMarginPool());
        UNDERLYING_ASSET_ADDRESS = underlyingAssetAddress;
        RESERVE_TREASURY_ADDRESS = addressesProvider.getTreasuryAddress();
        // rewardsDistribution = addressesProvider.getRewardsDistribution();
        rewardsToken = IERC20(IMarginPoolAddressesProvider(_addressesProvider).getLeverToken());
    }

    /**
     * @dev Burns xTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * - Only callable by the MarginPool, as extra state updates there need to be managed
     * @param user The owner of the xTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external override onlyMarginPool updateReward(user) {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
        _burn(user, amountScaled);
        if (receiverOfUnderlying != address(this)) {
            IERC20(UNDERLYING_ASSET_ADDRESS).safeTransfer(
                receiverOfUnderlying,
                amount
            );
        }

        emit Transfer(user, address(0), amount);
        emit Burn(user, receiverOfUnderlying, amount, index);
    }

    /**
     * @dev Mints `amount` xTokens to `user`
     * - Only callable by the MarginPool, as extra state updates there need to be managed
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external override onlyMarginPool updateReward(user) returns (bool) {
        uint256 previousBalance = super.balanceOf(user);

        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
        _mint(user, amountScaled);
        emit Transfer(address(0), user, amount);
        emit Mint(user, amount, index);

        return previousBalance == 0;
    }

    /**
     * @dev Mints xTokens to the reserve treasury
     * - Only callable by the MarginPool
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index)
        external
        override
        onlyMarginPool
        updateReward(RESERVE_TREASURY_ADDRESS)
    {
        if (amount == 0) {
            return;
        }

        // Compared to the normal mint, we don't check for rounding errors.
        // The amount to mint can easily be very small since it is a fraction of the interest ccrued.
        // In that case, the treasury will experience a (very small) loss, but it
        // wont cause potentially valid transactions to fail.
        _mint(RESERVE_TREASURY_ADDRESS, amount.rayDiv(index));
        emit Transfer(address(0), RESERVE_TREASURY_ADDRESS, amount);
        emit Mint(RESERVE_TREASURY_ADDRESS, amount, index);
    }

    /**
     * @dev Transfers xTokens in the event of a borrow being liquidated, in case the liquidators reclaims the xToken
     * - Only callable by the MarginPool
     * @param from The address getting liquidated, current owner of the xTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external override onlyMarginPool updateReward(from) updateReward(to) {
        // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
        // so no need to emit a specific event here
        _transfer(from, to, value, false);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Calculates the balance of the user: principal balance + interest generated by the principal
     * @param user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(address user)
        public
        view
        override(IncentivizedERC20, IERC20)
        returns (uint256)
    {
        return
            super.balanceOf(user).rayMul(
                POOL.getReserveNormalizedIncome(UNDERLYING_ASSET_ADDRESS)
            );
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return super.balanceOf(user);
    }

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (super.balanceOf(user), super.totalSupply());
    }

    /**
     * @dev calculates the total supply of the specific xToken
     * since the balance of every single user increases over time, the total supply
     * does that too.
     * @return the current total supply
     **/
    function totalSupply()
        public
        view
        override(IncentivizedERC20, IERC20)
        returns (uint256)
    {
        uint256 currentSupplyScaled = super.totalSupply();

        if (currentSupplyScaled == 0) {
            return 0;
        }

        return
            currentSupplyScaled.rayMul(
                POOL.getReserveNormalizedIncome(UNDERLYING_ASSET_ADDRESS)
            );
    }

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return the scaled total supply
     **/
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.totalSupply();
    }

    /**
     * @dev Transfers the underlying asset to `target`. Used by the MarginPool to transfer
     * assets in borrow(), withdraw()
     * @param target The recipient of the xTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address target, uint256 amount)
        external
        override
        onlyMarginPool
        returns (uint256)
    {
        IERC20(UNDERLYING_ASSET_ADDRESS).safeTransfer(target, amount);
        return amount;
    }

    /**
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(owner != address(0), "INVALID_OWNER");
        //solium-disable-next-line
        require(block.timestamp <= deadline, "INVALID_EXPIRATION");
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            currentValidNonce,
                            deadline
                        )
                    )
                )
            );
        require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
        _nonces[owner] = currentValidNonce.add(1);
        _approve(owner, spender, value);
    }

    /**
     * @dev Transfers the xTokens between two users. Validates the transfer
     * (ie checks for valid HF after the transfer) if required
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     * @param validate `true` if the transfer needs to be validated
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount,
        bool validate
    ) internal updateReward(from) updateReward(to) {
        uint256 index =
            POOL.getReserveNormalizedIncome(UNDERLYING_ASSET_ADDRESS);

        uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
        uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

        super._transfer(from, to, amount.rayDiv(index));
        if (validate) {
            POOL.finalizeTransfer(
                UNDERLYING_ASSET_ADDRESS,
                from,
                to,
                amount,
                fromBalanceBefore,
                toBalanceBefore
            );
        }

        emit BalanceTransfer(from, to, amount, index);
    }

    /**
     * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _transfer(from, to, amount, true);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0);
        rewards[msg.sender] = 0;
        rewardsToken.safeTransfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward, uint256 _rewardsDuration)
        external
        onlyRewardsDistribution
        updateReward(address(0))
    {
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        if (block.timestamp >= periodFinish) {
            rewardsDuration = _rewardsDuration;
            rewardRate = reward.div(rewardsDuration);
            require(
                rewardRate <= balance.div(rewardsDuration),
                "Provided reward too high"
            );
            periodFinish = block.timestamp.add(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(remaining);
            require(
                rewardRate <= balance.div(remaining),
                "Provided reward too high"
            );
        }

        lastUpdateTime = block.timestamp;
        emit RewardAdded(reward, _rewardsDuration);
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint256 _rewardsDuration);
    event RewardPaid(address indexed user, uint256 reward);
}