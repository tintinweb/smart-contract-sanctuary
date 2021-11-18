pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IAToken.sol";
import "./interfaces/IAaveIncentivesController.sol";
import "./interfaces/IArtizenCore.sol";
import "./interfaces/IArtizenTreasury.sol";

// ------------------------------------------ //
//            ArtizenTreasury v0.1            //
// ------------------------------------------ //

// Yield Source: Aave (aDAI)
/**
    @title ArtizenTreasury
 */
contract ArtizenTreasury is IArtizenTreasury, Ownable {
    // Tracks grant donations and grant admin fees held (in Treasury or Aave)
    // Rest of DAI is protocol fees or Aave yield (also owned by protocol)
    uint256 public override grantDaiInTreasury;
    uint256 constant SCALE = 10000; // Scale is 10 000

    IERC20 public DAI;
    IAToken public aDAI;
    IAaveIncentivesController public AaveIncentivesController;
    ILendingPool AaveLendingPool;
    address public override artizenCoreAddress;
    address public override daiAddress; // needed for lending pool ops
    address public override aaveLendingPoolAddress;
    bool public override isShutdown;

    // ------------------------------------------ //
    //                  EVENTS                    //
    // ------------------------------------------ //

    event DaiDeposit(uint256 amountDeposited, uint256 protocolFeeOnDeposit);
    event DaiWithdrawal(uint256 amountWithdrawn);
    event DaiWithdrawalAdmin(address indexed recipient, uint256 amount);

    event DaiMovedFromAaveToTreasury(uint256 amount);
    event DaiMovedFromTreasuryToAave(uint256 amount);

    event ProtocolFeesReduced(uint256 amount);

    // ------------------------------------------ //
    //                 CONSTRUCTOR                //
    // ------------------------------------------ //

    constructor(
        address _DAI,
        address _aDAI,
        address _aaveIncentivesController,
        address _lendingPool
    ) {
        daiAddress = _DAI;
        aaveLendingPoolAddress = _lendingPool;
        DAI = IERC20(_DAI);
        aDAI = IAToken(_aDAI);
        AaveIncentivesController = IAaveIncentivesController(
            _aaveIncentivesController
        );
        AaveLendingPool = ILendingPool(_lendingPool);

        // Infinite approve Aave for DAI deposits
        DAI.approve(_lendingPool, type(uint256).max);
    }

    // ------------------------------------------ //
    //      PUBLIC STATE-MODIFYING FUNCTIONS      //
    // ------------------------------------------ //

    // Takes from grant DAI balance
    function withdraw(address _recipient, uint256 _amount)
        external
        override
        notShutdown
        onlyArtizenCore
    {
        // Check withdraw isn't sending DAI to zero address
        require(_recipient != address(0), "ART_T: WITHDRAW TO ZERO ADDRESS");

        // check if enough grant funds in treasury + Aave
        require(grantDaiInTreasury >= _amount, "ART_T: GRANT DAI TOO LOW");

        (
            uint256 _daiInTreasury,
            uint256 _daiInAave
        ) = getDaiInTreasuryAndAave();

        // Sanity check: grant DAI tracker always <= total actual DAI balances
        // NOTE: If this fails, Artizen team should deposit DAI into this contract
        // to allow withdrawals to be processed
        require(
            _daiInTreasury + _daiInAave >= grantDaiInTreasury,
            "ART_T: SANITY CHECK FAILED"
        );

        // Account for withdraw
        grantDaiInTreasury -= _amount;

        if (_daiInTreasury < _amount) {
            // Withdraw difference from Aave - enough guaranteed by require above
            _withdrawFromAave(_amount - _daiInTreasury);
            emit DaiMovedFromAaveToTreasury(_amount - _daiInTreasury);
        }

        require(DAI.transfer(_recipient, _amount), "ART_T: WITHDRAW FAILED");

        emit DaiWithdrawal(_amount);
    }

    function deposit(uint256 _amount)
        external
        override
        notShutdown
        onlyArtizenCore
    {
        require(
            DAI.transferFrom(artizenCoreAddress, address(this), _amount),
            "ART_T: DEPOSIT FAILED"
        );

        uint256 _protocolFee = IArtizenCore(artizenCoreAddress).protocolFee();

        uint256 _feesEarnedOnDeposit = ((_amount * _protocolFee) / SCALE);

        // accounting for increase in grant funds (excl. protocol fee)
        grantDaiInTreasury += (_amount - _feesEarnedOnDeposit);

        // Deposits new DAI directly into Aave
        _depositToAave(_amount);

        // emit event with amount deposited, and fee taken by protocol
        emit DaiDeposit(_amount, _feesEarnedOnDeposit);
    }

    function moveEnoughDaiFromAaveToTreasury(uint256 _amount)
        external
        override
        notShutdown
        onlyOwnerOrArtizenCore
    {
        (
            uint256 _daiInTreasury,
            uint256 _daiInAave
        ) = getDaiInTreasuryAndAave();

        require(
            _daiInTreasury + _daiInAave >= _amount,
            "ART_T: INSUFFICIENT DAI IN TOTAL"
        );

        if (_daiInTreasury < _amount) {
            // Withdraw remainder and emit event
            _withdrawFromAave(_amount - _daiInTreasury);
            emit DaiMovedFromAaveToTreasury(_amount - _daiInTreasury);
        }
    }

    // Reduce protocol fee by increasing grantDaiInTreasury
    function reduceProtocolFeesEarned(uint256 _amount)
        external
        override
        notShutdown
        onlyOwnerOrArtizenCore
    {
        // NOTE: This only modifies the internal fee accounting to enable full refunds to grants
        // Artizen is responsible for ensuring that enough DAI is available in this Treasury contract
        // and/or the Treasury's Aave deposits to fulfil all refunds to the cancelled grant.

        grantDaiInTreasury += _amount;

        emit ProtocolFeesReduced(_amount);
    }

    // ------------------------------------------ //
    //           ONLY OWNER FUNCTIONS             //
    // ------------------------------------------ //

    // For Artizen team to withdraw DAI revenue
    function withdrawAdmin(address _recipient, uint256 _amount)
        external
        override
        notShutdown
        onlyOwner
    {
        (
            uint256 _daiInTreasury,
            uint256 _daiInAave
        ) = getDaiInTreasuryAndAave();

        // Check enough DAI in Treasury + Aave to honor all grant funds owed
        require(
            (_daiInTreasury + _daiInAave - grantDaiInTreasury) >= _amount,
            "ART_T: NOT ENOUGH NON-GRANT DAI"
        );

        if (_daiInTreasury < _amount) {
            // Withdraw difference from Aave - enough guaranteed by require above
            _withdrawFromAave(_daiInTreasury - _amount);
        }

        // Only takes from protocol DAI
        require(
            DAI.transfer(_recipient, _amount),
            "ART_T: ADMIN WITHDRAW FAILED"
        );

        emit DaiWithdrawalAdmin(_recipient, _amount);
    }

    function moveDaiFromTreasuryToAave(uint256 _amountDAI)
        external
        override
        notShutdown
        onlyOwner
    {
        _depositToAave(_amountDAI);

        emit DaiMovedFromTreasuryToAave(_amountDAI);
    }

    function moveDaiFromAaveToTreasury(uint256 _amountDAI)
        external
        override
        onlyOwner
    {
        _withdrawFromAave(_amountDAI);

        emit DaiMovedFromAaveToTreasury(_amountDAI);
    }

    // Claim rewards in wMATIC and send to owner wallet
    function claimAaveRewards(
        address[] calldata _assets,
        uint256 _amountToClaim
    ) external override notShutdown onlyOwner {
        AaveIncentivesController.claimRewards(
            _assets,
            _amountToClaim,
            msg.sender
        );
    }

    function setLendingPool(address _lendingPool)
        external
        override
        onlyOwner
        notShutdown
    {
        require(_lendingPool != address(0), "ART_T: NO ZERO ADDRESS");
        AaveLendingPool = ILendingPool(_lendingPool);
        // Infinite approve Aave for DAI deposits
        DAI.approve(_lendingPool, type(uint256).max);
    }

    function setCoreAddress(address _core) external onlyOwner notShutdown {
        require(_core != address(0), "ART_T: NO ZERO ADDRESS");
        artizenCoreAddress = _core;
        // Infinite approve Core for DAI withdraws
        DAI.approve(_core, type(uint256).max);
    }

    function setTokenAddresses(address _DAI, address _aDAI)
        external
        override
        onlyOwner
        notShutdown
    {
        require(
            _DAI != address(0) && _aDAI != address(0),
            "ART_T: NO ZERO ADDRESS"
        );
        daiAddress = _DAI;
        DAI = IERC20(_DAI);
        aDAI = IAToken(_aDAI);
        DAI.approve(artizenCoreAddress, type(uint256).max);
        DAI.approve(aaveLendingPoolAddress, type(uint256).max);
    }

    function setAaveIncentivesController(address _newController)
        external
        override
        onlyOwner
        notShutdown
    {
        require(_newController != address(0), "ART_T: NO ZERO ADDRESS");
        AaveIncentivesController = IAaveIncentivesController(_newController);
    }

    function shutdown(bool _isShutdown) external override onlyOwner {
        isShutdown = _isShutdown;
    }

    // ------------------------------------------ //
    //     INTERNAL STATE-MODIFYING FUNCTIONS     //
    // ------------------------------------------ //

    function _depositToAave(uint256 _amount) internal {
        require(_amount > 0, "ART_T: NO ZERO DEPOSITS");
        AaveLendingPool.deposit(daiAddress, _amount, address(this), 0);
    }

    function _withdrawFromAave(uint256 _amount) internal {
        require(_amount > 0, "ART_T: NO ZERO WITHDRAWS");
        AaveLendingPool.withdraw(daiAddress, _amount, address(this));
    }

    // ------------------------------------------ //
    //             VIEW FUNCTIONS                 //
    // ------------------------------------------ //

    function getDaiInTreasuryAndAave()
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 daiInTreasury = DAI.balanceOf(address(this));
        uint256 daiInAave = aDAI.balanceOf(address(this));
        return (daiInTreasury, daiInAave);
    }

    // all funds in Treasury/Aave less funds owed to grants/admins
    function getTotalDaiOwnedByArtizen()
        external
        view
        override
        returns (uint256)
    {
        (
            uint256 _daiInTreasury,
            uint256 _daiInAave
        ) = getDaiInTreasuryAndAave();
        return (_daiInTreasury + _daiInAave - grantDaiInTreasury);
    }

    // ------------------------------------------ //
    //                MODIFIERS                   //
    // ------------------------------------------ //

    modifier onlyArtizenCore() {
        require(
            msg.sender == artizenCoreAddress,
            "ART_T: ONLY ARTIZEN CORE ALLOWED"
        );
        _;
    }

    modifier onlyOwnerOrArtizenCore() {
        require(
            msg.sender == artizenCoreAddress || msg.sender == owner(),
            "ART_T: ONLY OWNER OR CORE"
        );
        _;
    }

    modifier notShutdown() {
        require(!isShutdown, "ART_T: CONTRACT IS SHUTDOWN");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: agpl-3.0
// AAVE LENDING POOL
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

interface IAToken is IERC20, IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(
        address indexed from,
        address indexed target,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Mints aTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the aTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount)
        external
        returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(
        address indexed user,
        address indexed to,
        uint256 amount
    );

    // event RewardsClaimed(
    //     address indexed user,
    //     address indexed to,
    //     address indexed claimer,
    //     uint256 amount
    // );

    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(
        address[] calldata assets,
        uint256[] calldata emissionsPerSecond
    ) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address asset,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user)
        external
        view
        returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

// TODO Update to include latest Core functions
interface IArtizenCore {
    function grantCount() external view returns (uint256);

    function projectCount() external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function adminFee() external view returns (uint256);

    function SCALE() external view returns (uint256);

    function isShutdown() external view returns (bool);

    function treasuryAddress() external view returns (address);

    function getGrant(uint256 _grantID)
        external
        view
        returns (
            address[] memory, // grantAdmins
            bool, // adminFeeClaimed
            uint256, // startTime
            uint256, // endTime
            uint256, // totalVotePoint
            uint256, // totalDonations
            bool // cancelled
        );

    function getProjectsInGrant(uint256 _grantID)
        external
        view
        returns (uint256[] memory);

    function getGrantAdminFee(uint256 _grantID) external view returns (uint256);

    function getProjectDonations(uint256 _grantID, uint256 _projectID)
        external
        view
        returns (uint256);

    function voteBalanceInGrant(address _account, uint256 _grantID)
        external
        view
        returns (uint256);

    function projectVotesInGrant(uint256 _grantID, uint256 _projectID)
        external
        view
        returns (uint256);

    function isGrantAdmin(address _account, uint256 _grantID)
        external
        view
        returns (bool);

    function isProjectOwner(address _account, uint256 _projectID)
        external
        view
        returns (bool);

    function grantDonationsFromAccount(address _account, uint256 _grantID)
        external
        view
        returns (uint256);

    function donate(
        uint256 _grantID,
        uint256 _amountDonated,
        address _delegateVotesTo
    ) external;

    function giftVotes(
        uint256 _amountVotes,
        address _to,
        uint256 _grantID
    ) external;

    function vote(
        uint256 _grantID,
        uint256 _projectID,
        uint256 _amountVotes
    ) external;

    function payGrantAdminFees(uint256 _grantID) external;

    function payDonationsToProject(uint256 _grantID, uint256 _projectID)
        external;

    function payDonationsToAllProjectsInGrant(uint256 _grantID) external;

    function createGrant(
        address[] calldata _grantAdmins,
        uint256 _startTime,
        uint256 _endTime
    ) external returns (uint256);

    function createProject(
        string calldata _projectName,
        address[] calldata _projectOwners
    ) external returns (uint256);

    function renewGrant(
        uint256 _grantID,
        uint256 _startTime,
        uint256 _endTime
    ) external returns (uint256);

    function cancelGrant(uint256 _grantID) external;

    function refundGrantDonor(uint256 _grantID, address _donor) external;

    function setProjectInGrant(
        uint256 _grantID,
        uint256 _projectID,
        bool _inGrant
    ) external;

    function setFees(uint256 _protocolFee, uint256 _adminFee) external;

    function setTreasury(address _newTreasury) external;

    function shutdown(bool _isShutdown) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

// TODO Update to include latest Treasury functions
interface IArtizenTreasury {
    function artizenCoreAddress() external view returns (address);

    function daiAddress() external view returns (address);

    function aaveLendingPoolAddress() external view returns (address);

    function isShutdown() external view returns (bool);

    function grantDaiInTreasury() external view returns (uint256);

    function withdraw(address _recipient, uint256 _amount) external;

    function deposit(uint256 _amount) external;

    function withdrawAdmin(address _recipient, uint256 _amount) external;

    function moveDaiFromTreasuryToAave(uint256 _amountDAI) external;

    function moveDaiFromAaveToTreasury(uint256 _amountDAI) external;

    function moveEnoughDaiFromAaveToTreasury(uint256 _amountDAI) external;

    function reduceProtocolFeesEarned(uint256 _amount) external;

    function claimAaveRewards(
        address[] calldata _assets,
        uint256 _amountToClaim
    ) external;

    function setLendingPool(address _lendingPool) external;

    function setTokenAddresses(address _DAI, address _aDAI) external;

    function setAaveIncentivesController(address _newController) external;

    function shutdown(bool _isShutdown) external;

    function getDaiInTreasuryAndAave() external view returns (uint256, uint256);

    function getTotalDaiOwnedByArtizen() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

interface IScaledBalanceToken {
    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}