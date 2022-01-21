// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IsPana.sol";
import "./interfaces/IKarsha.sol";
import "./interfaces/IDistributor.sol";

import "./types/PanaAccessControlled.sol";

contract PanaStaking is PanaAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IsPana;
    using SafeERC20 for IKarsha;

    /* ========== EVENTS ========== */

    event DistributorSet(address distributor);
    event WarmupSet(uint256 warmup);

    /* ========== DATA STRUCTURES ========== */

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    struct LockedClaim {
        uint256 deposit; // if forfeiting
        uint256 gons; // staked balance
        uint256 expiry; // end of warmup period
        bool lock; // prevents further staking if there is unclaimed stake.
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable PANA;
    IsPana public immutable sPANA;
    IKarsha public immutable KARSHA;

    Epoch public epoch;

    IDistributor public distributor;

    mapping(address => LockedClaim) public lockedStakeInfo;

    uint256 private gonsInLocked;
    bool private _allowedExternalStaking;
    address public bondDepositor;
    address public pKarshaRedemption;
    address public aKarshaRedemption;


    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _pana,
        address _sPana,
        address _karsha,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochTime,
        address _authority
    ) PanaAccessControlled(IPanaAuthority(_authority)) {
        require(_pana != address(0), "Zero address: PANA");
        PANA = IERC20(_pana);
        require(_sPana != address(0), "Zero address: sPANA");
        sPANA = IsPana(_sPana);
        require(_karsha != address(0), "Zero address: KARSHA");
        KARSHA = IKarsha(_karsha);

        epoch = Epoch({length: _epochLength, number: _firstEpochNumber, end: _firstEpochTime, distribute: 0});

    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake Pana
     * @param _to address
     * @param _amount uint
     * @return uint
     */
    function stake(
        address _to,
        uint256 _amount
    ) external returns (uint256) {
        // check if external staking is not allowed, only bond depositor should be able to stake it.
        if (!_allowedExternalStaking) {
            require(msg.sender == bondDepositor || msg.sender == aKarshaRedemption, "External Staking is not allowed");
        }

        PANA.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = _amount.add(rebase()); // add bounty if rebase occurred
        return _send(_to, _amount);
    }

    /**
     * @notice stake pana with lock. This function  is restricted to be called only from pKarsha redemption contract 
     * @param _to address
     * @param _amount uint
     * @param lockPeriod uint
     * @return uint
     */
    function lockedStake(
        address _to,
        uint256 _amount, 
        uint256 lockPeriod
    ) external returns (uint256) {
        require(msg.sender == pKarshaRedemption, "External staking is not allowed");
        LockedClaim memory info = lockedStakeInfo[_to];
        require(info.lock == false, "Account has locked or unclaimed stake");        

        PANA.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = _amount.add(rebase()); // add bounty if rebase occurred
        
        lockedStakeInfo[_to] = LockedClaim({
            deposit: _amount,
            gons: sPANA.gonsForBalance(_amount),
            expiry: block.timestamp.add(lockPeriod),
            lock: true
        });

        gonsInLocked = gonsInLocked.add(sPANA.gonsForBalance(_amount));

        return _amount;

    }

    /**
     * @notice retrieve stake from lock
     * @param _to address
     * @return uint
     */
    function claimRedeemable(address _to) external returns (uint256) {
        require(msg.sender == pKarshaRedemption, "External claim is not allowed");
        LockedClaim memory lockInfo = lockedStakeInfo[_to]; 

        if (block.timestamp >= lockInfo.expiry && lockInfo.lock ) {
            delete lockedStakeInfo[_to];
            gonsInLocked = gonsInLocked.sub(lockInfo.gons);

            return _send(_to, sPANA.balanceForGons(lockInfo.gons));            
        }
        return 0;
    }

    /**
     * @notice redeem Pana/sPana for Karsha/Pana
     * @param _to address
     * @param _amount uint
     * @param _trigger bool
     * @return amount_ uint
     */
    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger
    ) external returns (uint256 amount_) {
        amount_ = _amount;
        uint256 bounty;
        if (_trigger) {
            bounty = rebase();
        }

        KARSHA.burn(msg.sender, _amount); // amount was given in Karsha terms
        amount_ = KARSHA.balanceFrom(amount_).add(bounty); // convert amount to Pana terms & add bounty
    
        require(amount_ <= PANA.balanceOf(address(this)), "Insufficient Pana balance in contract");
        PANA.safeTransfer(_to, amount_);
    }

    /**
     * @notice trigger rebase if epoch over
     * @return uint256
     */
    function rebase() public returns (uint256) {
        uint256 bounty;
        if (epoch.end <= block.timestamp) {
            sPANA.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end.add(epoch.length);
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
                bounty = distributor.retrieveBounty(); // Will mint Pana for this contract if there exists a bounty
            }
            uint256 balance = PANA.balanceOf(address(this));
            uint256 staked = sPANA.circulatingSupply();
            if (balance <= staked.add(bounty)) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked).sub(bounty);
            }
        }
        return bounty;
    }

    // Set Depositor Contract after creating Contract
    function setBondDepositor(address _bondDepositor) external onlyGovernor {
        bondDepositor = _bondDepositor;
    }

    function setPKarshaRedemption(address _pKarshaRedemption) external onlyGovernor {
        pKarshaRedemption = _pKarshaRedemption;
    }
    
    function setAKarshaRedemption(address _aKarshaRedemption) external onlyGovernor {
        aKarshaRedemption = _aKarshaRedemption;
    }
    
    // Allow External Staking directly using PANA
    function allowExternalStaking(bool allow) external onlyGovernor {
        _allowedExternalStaking = allow;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as Karsha
     * @param _to address
     * @param _amount uint
     */
    function _send(
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        KARSHA.mint(_to, KARSHA.balanceTo(_amount)); // send as Karsha (convert units from Pana)
        return KARSHA.balanceTo(_amount);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns the sPana index, which tracks rebase growth
     * @return uint
     */
    function index() public view returns (uint256) {
        return sPANA.index();
    }
    
    /**
     * @notice total supply in locked state
     */
    function supplyInLocked() public view returns (uint256) {
        return sPANA.balanceForGons(gonsInLocked);
    }

    /**
     * @notice seconds until the next epoch begins
     */
    function secondsToNextEpoch() external view returns (uint256) {
        return epoch.end.sub(block.timestamp);
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice sets the contract address for LP staking
     * @param _distributor address
     */
    function setDistributor(address _distributor) external onlyGovernor {
        distributor = IDistributor(_distributor);
        emit DistributorSet(_distributor);
    }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

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

import "./IERC20.sol";

interface IKarsha is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function index() external view returns (uint256);
  
  function balanceOfPANA(address _address) external view returns (uint256);

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

  function migrate( address _staking, address _sPana ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IPanaAuthority {
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

import "./IERC20.sol";

interface IsPana is IERC20 {
    function rebase( uint256 panaProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );

    function index() external view returns ( uint );

    function toKARSHA(uint amount) external view returns (uint);

    function fromKARSHA(uint amount) external view returns (uint);

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

import "../interfaces/IPanaAuthority.sol";

abstract contract PanaAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPanaAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IPanaAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IPanaAuthority _authority) {
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
    
    function setAuthority(IPanaAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}