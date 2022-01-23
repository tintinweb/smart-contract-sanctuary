// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IsQUAS.sol";
import "./interfaces/ITeller.sol";

import "./types/QuasarAccessControlled.sol";

contract BondTeller is ITeller, QuasarAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IsQUAS;

    /* ========== EVENTS =========== */

    event BondCreated(address indexed bonder, uint256 payout, uint256 expires);
    event Redeemed(address indexed bonder, uint256 payout);

    /* ========== MODIFIERS ========== */

    modifier onlyDepository() {
        require(msg.sender == depository, "Only depository");
        _;
    }

    /* ========== STRUCTS ========== */

    // Info for bond holder
    struct Bond {
        address principal; // token used to pay for bond
        uint256 principalPaid; // amount of principal token paid for bond
        uint256 payout; // QUAS remaining to be paid. agnostic balance
        uint256 bonded; // QUAS bonded 
        uint256 vested; // Block timestamp when bond is vested
        uint256 created; // time bond was created
        uint256 redeemed; // time bond was redeemed
    }

    /* ========== STATE VARIABLES ========== */

    address internal immutable depository; // contract where users deposit bonds
    IStaking internal immutable staking; // contract to stake payout
    ITreasury internal immutable treasury;
    IERC20 internal immutable QUAS;
    IsQUAS internal immutable sQUAS; // payment token

    mapping(address => mapping(uint256 => Bond)) public bonderInfo; // address => bond id => Bond

    mapping(address => uint256) public FERs; // front end operator rewards
    uint256 public feReward;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _depository,
        address _staking,
        address _treasury,
        address _quas,
        address _sQUAS,
        address _authority
    ) QuasarAccessControlled(IQuasarAuthority(_authority)) {
        require(_depository != address(0), "Zero address: Depository");
        depository = _depository;
        require(_staking != address(0), "Zero address: Staking");
        staking = IStaking(_staking);
        require(_treasury != address(0), "Zero address: Treasury");
        treasury = ITreasury(_treasury);
        require(_quas != address(0), "Zero address: QUAS");
        QUAS = IERC20(_quas);
        require(_sQUAS != address(0), "Zero address: sQUAS");
        sQUAS = IsQUAS(_sQUAS);
    }

    /* ========== DEPOSITORY FUNCTIONS ========== */

    /**
     * @notice add new bond payout to user data
     * @param _bid bond id
     * @param _bonder address
     * @param _principal address
     * @param _principalPaid uint256
     * @param _payout uint256
     * @param _expires uint256
     * @param _feo address
     */
    function newBond(
        uint256 _bid,
        address _bonder,
        address _principal,
        uint256 _principalPaid,
        uint256 _payout,
        uint256 _expires,
        address _feo
    ) external override onlyDepository {
        uint256 reward = _payout.mul(feReward).div(10_000);
        treasury.mint(address(this), _payout.add(reward));

        FERs[_feo] = FERs[_feo].add(reward); // front end operator reward

        Bond memory bondInfo = bonderInfo[_bonder][_bid];
        bonderInfo[_bonder][_bid] = Bond({
            principal: _principal,
            principalPaid: bondInfo.principalPaid + _principalPaid,
            payout: bondInfo.payout + sQUAS.toG(_payout),
            bonded: bondInfo.bonded + _payout,
            vested: _expires,
            created: block.timestamp,
            redeemed: 0
        });

        QUAS.approve(address(staking), _payout);
        staking.stake(address(this), _payout, false, true, true);
    }

    /* ========== INTERACTABLE FUNCTIONS ========== */

    /**
     *  @notice redeem bond for user
     *  @param _bonder address
     *  @param _bid uint256
     *  @param _unstake bool
     */
    function redeem(address _bonder, uint256 _bid, bool _unstake) public override {
        (,,uint256 payout,) = payoutInfo(_bonder, _bid);
        if (payout != 0) {
            delete bonderInfo[_bonder][_bid];
            emit Redeemed(_bonder, payout);
            if (_unstake) {
                payUnstaked(_bonder, payout);
            } else {
                payStaked(_bonder, payout);
            }
        }
    }

    // pay reward to front end operator
    function getReward() external override {
        uint256 reward = FERs[msg.sender];
        FERs[msg.sender] = 0;
        QUAS.safeTransfer(msg.sender, reward);
    }

    /* ========== OWNABLE FUNCTIONS ========== */

    // set reward for front end operator (4 decimals. 100 = 1%)
    function setFEReward(uint256 reward) external override onlyPolicy {
        feReward = reward;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     *  @notice send payout
     *  @param _amount uint256
     */
    function payUnstaked(address _bonder, uint256 _amount) internal {
        sQUAS.approve(address(staking), _amount);
        staking.unstake(address(this), _amount, false, true);
        QUAS.safeTransfer(_bonder, _amount);
    }

    /**
     *  @notice send payout
     *  @param _amount uint256
     */
    function payStaked(address _bonder, uint256 _amount) internal {
        sQUAS.safeTransfer(_bonder, _amount);
    }

    /* ========== VIEW FUNCTIONS ========== */

    // PAYOUT

    /**
     * @notice calculate amount of QUAS available for claim for single bond
     * @param _bonder address
     * @param _bid uint256
     * @return lockedPayout uint256, lockedStakingRewards uint256, pendingPayout uint256, pendingStakingRewards uint256
     */
    function payoutInfo(address _bonder, uint256 _bid) public view override 
        returns (uint256 lockedPayout, uint256 lockedStakingRewards, uint256 pendingPayout, uint256 pendingStakingRewards) {

        uint256 gpayout = bonderInfo[_bonder][_bid].payout;
        uint256 bonded = bonderInfo[_bonder][_bid].bonded;
        uint256 payout = sQUAS.fromG(gpayout);
        uint256 stakingRewards = payout.sub(bonded);

        if (bonderInfo[_bonder][_bid].redeemed == 0 && 
            bonderInfo[_bonder][_bid].vested <= block.timestamp) {
            pendingPayout = payout;
            pendingStakingRewards = stakingRewards;
        } else {
            lockedPayout = payout;
            lockedStakingRewards = stakingRewards;
        }
    }

    // VESTING

    /**
     * @notice calculate how far into vesting a depositor is
     * @param _bonder address
     * @param _bid uint256
     * @return percentVested_ uint256
     */
    function percentVestedFor(address _bonder, uint256 _bid) public view override returns (uint256 percentVested_) {
        Bond memory bond = bonderInfo[_bonder][_bid];

        uint256 timeSince = block.timestamp.sub(bond.created);
        uint256 term = bond.vested.sub(bond.created);

        percentVested_ = timeSince.mul(1e9).div(term);
    }
}

// SPDX-License-Identifier: AGPL-3.0
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.7.5;

interface IQuasarAuthority {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITeller {
    function newBond( 
        uint256 _bid,
        address _bonder, 
        address _principal,
        uint _principalPaid,
        uint _payout, 
        uint _expires,
        address _feo
    ) external;
    function redeem(address _bonder, uint256 _bid, bool _unstake) external;
    function getReward() external;
    function setFEReward(uint256 reward) external;
    function payoutInfo(address _bonder, uint256 _index) external view returns (uint256 lockedPayout, uint256 lockedStakingRewards, uint256 pendingPayout, uint256 pendingStakingRewards);
    function percentVestedFor(address _bonder, uint256 _index) external view returns (uint256 percentVested_);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IsQUAS is IERC20 {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;


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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IQuasarAuthority.sol";

abstract contract QuasarAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IQuasarAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IQuasarAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IQuasarAuthority _authority) {
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
    
    function setAuthority(IQuasarAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}