/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
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


// File contracts/interfaces/ITreasury.sol


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
}


// File contracts/interfaces/IStaking.sol


pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
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


// File contracts/interfaces/IOwnable.sol


pragma solidity >=0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;

  function pushManagement( address newOwner_ ) external;

  function pullManagement() external;
}


// File contracts/interfaces/IsOHM.sol


pragma solidity >=0.7.5;

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


// File contracts/interfaces/ITeller.sol


pragma solidity >=0.7.5;

interface ITeller {
    function newBond(
        uint256 _payout,
        uint16 _bid,
        uint48 _expires,
        address _bonder,
        address _feo
    ) external returns (uint16 index_);
    function redeemAll(address _bonder) external returns (uint256);
    function redeem(address _bonder, uint16[] memory _indexes) external returns (uint256);
    function getReward() external;
    function setReward(bool _fe, uint256 _reward) external;
    function vested(address _bonder, uint16 _index) external view returns (bool);
    function pendingForIndexes(address _bonder, uint16[] memory _indexes) external view returns (uint256 pending_);
    function totalPendingFor(address _bonder) external view returns (uint256 pending_);
    function indexesFor(address _bonder) external view returns (uint16[] memory indexes_);
}


// File contracts/interfaces/IOlympusAuthority.sol


pragma solidity =0.7.5;

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

pragma solidity >=0.7.5;

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


// File contracts/BondTeller.sol


pragma solidity ^0.7.5;







contract BondTeller is ITeller, OlympusAccessControlled {

    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IsOHM;

    /* ========== MODIFIERS ========== */

    modifier onlyDepository() {
        require(msg.sender == depository, "Only depository");
        _;
    }

    /* ========== EVENTS ========== */

    event FrontEndRewardChanged(uint256 newReward);
    event BondRedeemed(address redeemer, uint256 payout);
    event RewardClaimed(address claimant, uint256 amount);

    /* ========== STRUCTS ========== */

    // Info for bond holder
    struct Bond {
        uint16 bondId; // ID of bond in depository
        uint48 vested; // time when bond is vested
        uint48 redeemed; // time when bond was redeemed (0 if unredeemed)
        uint128 payout; // sOHM remaining to be paid. gOHM balance
    }

    /* ========== STATE VARIABLES ========== */

    address internal immutable depository; // contract where users deposit bonds
    IStaking internal immutable staking; // contract to stake payout
    ITreasury internal immutable treasury;
    IERC20 internal immutable ohm;
    IsOHM internal immutable sOHM; // payment token
    address public immutable dao;

    mapping(address => Bond[]) public bonderInfo; // user data

    mapping(address => uint256) public rewards; // front end operator rewards
    uint256[2] public reward; // reward to [front end operator, dao] (9 decimals)

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _depository,
        address _staking,
        address _treasury,
        address _ohm,
        address _sOHM,
        address _dao,
        address _authority
    ) OlympusAccessControlled(IOlympusAuthority(_authority)) {
        require(_depository != address(0), "Zero address: Depository");
        depository = _depository;
        require(_staking != address(0), "Zero address: Staking");
        staking = IStaking(_staking);
        require(_treasury != address(0), "Zero address: Treasury");
        treasury = ITreasury(_treasury);
        require(_ohm != address(0), "Zero address: OHM");
        ohm = IERC20(_ohm);
        require(_sOHM != address(0), "Zero address: sOHM");
        sOHM = IsOHM(_sOHM);
        require(_dao != address(0), "Zero address: DAO");
        dao = _dao;
    }

    /* ========== DEPOSITORY ========== */

    /**
     * @notice add new bond payout to user data
     * @param _payout uint256
     * @param _bid uint16
     * @param _expires uint48
     * @param _bonder address
     * @param _feo address
     * @return index_ uint16
     */
    function newBond(
        uint256 _payout,
        uint16 _bid,
        uint48 _expires,
        address _bonder,
        address _feo
    ) external override onlyDepository returns (uint16 index_) {
        uint256 toFEO = _payout.mul(reward[0]).div(1e9);
        uint256 toDAO = _payout.mul(reward[1]).div(1e9);

        treasury.mint(address(this), _payout.add(toFEO.add(toDAO)));
        ohm.approve(address(staking), _payout);
        staking.stake(address(this), _payout, true, true);

        rewards[_feo] += toFEO; // front end operator reward
        rewards[dao] += toDAO; // dao reward

        index_ = uint16(bonderInfo[_bonder].length);

        // store bond & stake payout
        bonderInfo[_bonder].push(
            Bond({
                bondId: _bid,
                payout: uint128(sOHM.toG(_payout)),
                vested: _expires,
                redeemed: 0
            })
        );
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    /**
     *  @notice redeems all redeemable bonds
     *  @param _bonder address
     *  @return uint256
     */
    function redeemAll(address _bonder) external override returns (uint256) {
        return redeem(_bonder, indexesFor(_bonder));
    }

    /**
     *  @notice redeem bonds for user
     *  @param _bonder address
     *  @param _indexes calldata uint256[]
     *  @return uint256
     */
    function redeem(address _bonder, uint16[] memory _indexes) public override returns (uint256) {
        Bond[] storage info = bonderInfo[_bonder];
        uint256 dues;
        for (uint256 i = 0; i < _indexes.length; i++) {
            if (vested(_bonder, _indexes[i])) {
                info[_indexes[i]].redeemed = uint48(block.timestamp); // mark as redeemed
                uint256 payout = info[_indexes[i]].payout;
                dues += payout;
                emit BondRedeemed(_bonder, payout);
            }
        }
        dues = sOHM.fromG(dues);
        require(dues > 0, "Teller: zero redemption");
        sOHM.safeTransfer(_bonder, dues);
        return dues;
    }

    /**
     * @notice pay reward to front end operator
     */
    function getReward() external override {
        uint256 amount = rewards[msg.sender];
        ohm.safeTransfer(msg.sender, amount);
        rewards[msg.sender] = 0;
        emit RewardClaimed(msg.sender, amount);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice all un-redeemed indexes for address
     * @param _bonder address
     * @return indexes_ uint256[] memory
     */
    function indexesFor(address _bonder) public view override returns (uint16[] memory indexes_) {
        Bond[] memory info = bonderInfo[_bonder];
        for (uint16 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0) {
                indexes_[indexes_.length - 1] = i;
            }
        }
    }

    // check if bonder's bond is claimable
    function vested(address _bonder, uint16 _index) public view override returns (bool) {
        if (bonderInfo[_bonder][_index].redeemed == 0 && bonderInfo[_bonder][_index].vested <= block.timestamp) {
            return true;
        }
        return false;
    }

    // calculate amount of OHM available for claim for array of bonds
    function pendingForIndexes(
        address _bonder,
        uint16[] memory _indexes
    ) public view override returns (uint256 pending_) {
        for (uint256 i = 0; i < _indexes.length; i++) {
            if (vested(_bonder, _indexes[i])) {
                pending_ += bonderInfo[_bonder][_indexes[i]].payout;
            }
        }
        pending_ = sOHM.fromG(pending_);
    }

    // get total ohm available for claim by bonder
    function totalPendingFor(address _bonder) public view override returns (uint256 pending_) {
        uint16[] memory indexes = indexesFor(_bonder);
        for (uint256 i = 0; i < indexes.length; i++) {
            if (vested(_bonder, indexes[i])) {
                pending_ += bonderInfo[_bonder][i].payout;
            }
        }
        pending_ = sOHM.fromG(pending_);
    }

    /* ========== OWNABLE FUNCTIONS ========== */

    // set reward for front end operator (9 decimals)
    function setReward(bool _fe, uint256 _reward) external override onlyPolicy {
        if (_fe) {
            reward[0] = _reward;
            emit FrontEndRewardChanged(_reward);
        } else {
            reward[1] = _reward;
        }
    }
}