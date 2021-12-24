// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;
pragma abicoder v2;

import "./interfaces/IDepository.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IgOHM.sol";
import "./interfaces/IStaking.sol";
import "./libraries/Address.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./types/OlympusAccessControlled.sol";
import "./interfaces/IDirectory.sol";

contract OlympusBondDepository is OlympusAccessControlled, IDepository {
/* ======== DEPENDENCIES ======== */

  using SafeMath for uint256;
  using SafeMath for uint48;
  using SafeMath for uint64;
  using SafeERC20 for IERC20;
  using SafeERC20 for IOHM;
  using SafeERC20 for IgOHM;

/* ======== EVENTS ======== */

  event BeforeBond(uint256 id, uint256 internalPrice, uint256 debtRatio);
  event CreateBond(uint256 id, uint256 amount, uint256 payout, uint256 expires);
  event Redeemed(address indexed bonder, uint256 payout);

/* ======== STRUCTS ======== */

  // Info about each type of bond
  struct Bond {
    uint256 capacity; // capacity remaining
    uint256 totalDebt; // total debt from bond
    uint256 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
    IERC20 quoteToken; // token to accept as payment
    bool capacityInQuote; // capacity limit is in payment token (true) or in OHM (false, default)
    uint48 lastTune; // last timestamp when control variable was tuned
    uint48 lastDecay; // last timestamp when bond was created and debt was decayed
    uint48 length; // time from creation to conclusion. used as speed to decay debt.
  }

  // Info for creating new bonds
  struct Terms {
    bool fixedTerm; // fixed term or fixed expiration
    uint64 controlVariable; // scaling variable for price
    uint48 vestingTerm; // length of time from deposit to maturity if fixed-term
    uint48 conclusion; // timestamp when bond no longer offered (doubles as time when bond matures if fixed-expiry)
    uint64 maxDebt; // 9 decimal debt maximum in OHM
  }

  // Info for bond note
  struct Note {
    uint256 payout; // gOHM remaining to be paid
    uint48 created; // time bond was created
    uint48 matured; // timestamp when bond is matured
    uint48 redeemed; // time bond was redeemed
  }

/* ======== STATE VARIABLES ======== */

  // Constants
  uint256 internal immutable tuneInterval = 360; // One hour between tuning
  uint256 internal immutable targetDepositInterval = 14400; // target four hours between deposits

  // Addresses
  ITreasury internal immutable treasury; // the purchaser of quote tokens
  IStaking internal immutable staking; // contract to stake payout
  IOHM internal immutable ohm; // the payment token for bonds
  IgOHM internal immutable gOHM; // payment token
  address internal immutable dao; // receives fees on each bond

  // Storage
  Bond[] public bonds;
  Terms[] public terms;
  mapping(address => Note[]) public notes; // user deposit data

  // Front end incentive
  uint256[2] public rewardRate; // % reward for [operator, dao] (5 decimals)
  mapping(address => uint256) public rewards; // front end operator rewards
  mapping(address => bool) public whitelisted; // whitelisted status for operators

/* ======== CONSTRUCTOR ======== */

  constructor(
    IOlympusDirectory _directory, 
    IOlympusAuthority _authority
  ) OlympusAccessControlled(_authority) {
    ohm = _directory.ohm();
    treasury = _directory.treasury();
    staking = _directory.staking();
    gOHM = _directory.gOHM();
    dao = _directory.dao();
  }

/* ======== MUTABLE ======== */

  /**
   * @notice deposit bond
   * @param _bid uint256
   * @param _amount uint256
   * @param _maxPrice uint256
   * @param _depositor address
   * @param _referral address
   * @return payout_ uint256
   * @return index_ uint256
   */
  function deposit(
    uint256 _bid,
    uint256 _amount,
    uint256 _maxPrice,
    address _depositor,
    address _referral
  ) external override returns (uint256 payout_, uint256 index_) {
    Bond storage bond = bonds[_bid];
    Terms memory term = terms[_bid];

    // some basic sanity checks
    require(_depositor != address(0), "Depository: invalid address");
    require(block.timestamp < term.conclusion, "Depository: bond concluded");

    // decrement debt to create time decay
    bond.totalDebt = bond.totalDebt.sub(debtDecay(_bid));
    bond.lastDecay = uint48(block.timestamp);

    // checks that are dependent on totalDebt being up-to-date
    uint256 price = bondPrice(_bid);
    require(bond.totalDebt <= term.maxDebt, "Depository: max debt exceeded");
    require(price <= _maxPrice, "Depository: more than max price"); // slippage protection
    emit BeforeBond(_bid, price, bond.totalDebt.mul(1e9).div(treasury.baseSupply()));

    // compute the users' payout in OHM for amount of quote token deposited
    payout_ = _amount.div(price); // and ensure it is within bounds
    require(payout_ <= bond.maxPayout, "Depository: max size exceeded");
    
    // ensure the contract can buy or sell this many tokens
    if (bond.capacityInQuote) { // can it buy this many -- use amount of quote token
      require(_amount <= bond.capacity, "Depository: capacity exceeded");
      bond.capacity = bond.capacity.sub(_amount);
    } else { // can it sell this many -- use amount of base token (OHM)
      require(payout_ <= bond.capacity, "Depository: capacity exceeded");
      bond.capacity = bond.capacity.sub(payout_);
    }    

    // get the timestamp when bond will mature
    uint48 maturation; // a fixed term bond matures at deposit + an interval (the vesting term)
    if (!term.fixedTerm) maturation = term.conclusion;  // otherwise, its a set timestamp
    else maturation = uint48(term.vestingTerm.add(block.timestamp)); // <-- fixed term

    // store the users data
    index_ = newBond(_depositor, payout_, maturation, _referral);
    emit CreateBond(_bid, _amount, payout_, maturation);

    // transfer the deposited tokens to the treasury
    bond.quoteToken.safeTransferFrom(msg.sender, address(treasury), _amount);

    // increment total debt
    bond.totalDebt = bond.totalDebt.add(payout_);

    // shut off future deposits if max debt is breached
    if (term.maxDebt < bond.totalDebt) bond.capacity = 0;

    // tune the control variable to hit target on time
    _tune(_bid);
  }

  /**
   * @notice trigger tuning without depositing
   * @param _bid uint256
   */
  function tune(uint256 _bid) external override {
    // as the external version of _tune, we first need to update debt
    bonds[_bid].totalDebt = bonds[_bid].totalDebt.sub(debtDecay(_bid));
    bonds[_bid].lastDecay = uint48(block.timestamp);
    // then we can call the function
    _tune(_bid);
  }

  // testing function to jump forward by a number of seconds
  function jump(uint256 _bid, uint256 _by) external {
    Bond storage bond = bonds[_bid];
    Terms storage term = terms[_bid];
    bond.lastDecay = uint48(bond.lastDecay.sub(_by));
    bond.lastTune = uint48(bond.lastTune.sub(_by));
    term.conclusion = uint48(term.conclusion.sub(_by));
    if (!term.fixedTerm) term.vestingTerm = uint48(term.vestingTerm.sub(_by));
  }

  /**
   *  @notice redeem bond for user
   *  @param _bonder address
   *  @param _indexes calldata uint256[]
   *  @return uint256
   */
  function redeem(address _bonder, uint256[] memory _indexes) public override returns (uint256) {
      uint256 dues;
      for (uint256 i = 0; i < _indexes.length; i++) {
          Note memory info = notes[_bonder][_indexes[i]];
          if (pendingFor(_bonder, _indexes[i]) != 0) {
              notes[_bonder][_indexes[i]].redeemed = uint48(block.timestamp); // mark as redeemed
              dues += info.payout;
          }
      }
      emit Redeemed(_bonder, dues);
      gOHM.safeTransfer(_bonder, dues);
      return dues;
  }

  // redeem all redeemable bonds for user
  function redeemAll(address _bonder) external override returns (uint256) {
      return redeem(_bonder, indexesFor(_bonder));
  }

  // pay reward to front end operator
  function getReward() external override {
      ohm.safeTransfer(msg.sender, rewards[msg.sender]);
      rewards[msg.sender] = 0;
  }

/* ======== INTERNAL ======== */

  /** 
    * @notice add new bond payout to user data
    * @param _bonder address
    * @param _payout uint256
    * @param _matures uint256
    * @param _referral address
    * @return index_ uint256
    */
  function newBond(
      address _bonder,
      uint256 _payout,
      uint48 _matures,
      address _referral
  ) internal returns (uint256 index_) {
      // first we calculate rewards paid to the DAO and to the front end operator (referrer)
      uint256 toDAO = _payout.mul(rewardRate[1]).div(1e4);
      uint256 toReferrer = _payout.mul(rewardRate[0]).div(1e4);

      // and store them in our rewards mapping
      if (whitelisted[_referral]) {
          rewards[_referral] = rewards[_referral].add(toReferrer);
          rewards[dao] = rewards[dao].add(toDAO);
      } else { // the DAO receives both rewards if referrer is not whitelisted
          rewards[dao] = rewards[dao].add(toDAO.add(toReferrer));
      }

      // we mint the payout for the depositor, plus rewards above
      treasury.mint(address(this), _payout.add(toDAO).add(toReferrer));
      // note that we stake only what is given to the depositor
      staking.stake(address(this), _payout, false, true);

      // finally, we store the data as a new Note in the users' array
      index_ = notes[_bonder].length;
      notes[_bonder].push(
          Note({
              payout: gOHM.balanceTo(_payout),
              created: uint48(block.timestamp),
              matured: _matures,
              redeemed: 0
          })
      );
  }

  // auto-adjust control variable to hit capacity/spend target
  function _tune(uint256 _bid) internal {
    Bond memory bond = bonds[_bid];
    if (block.timestamp >= bond.lastTune.add(tuneInterval)) {
      // compute seconds until bond will conclude
      uint256 timeRemaining = terms[_bid].conclusion.sub(block.timestamp);
      // standardize capacity into an OHM amount to compute target debt
      uint256 capacity = bond.capacity;
      if (bond.capacityInQuote) {
        capacity = standardDecimals(capacity, _bid).div(bondPrice(_bid));
      }
      // calculate max payout for four hour intervals 
      bonds[_bid].maxPayout = capacity.mul(targetDepositInterval).div(timeRemaining);
      // calculate target debt to complete offering at conclusion
      uint256 targetDebt = capacity.mul(bond.length).div(timeRemaining);
      // derive a new control variable from the target debt
      uint256 newControlVariable = bondPrice(_bid).mul(treasury.baseSupply()).div(targetDebt);
      // prevent control variable by decrementing price by more than 2% at a time
      uint256 minNewControlVariable = terms[_bid].controlVariable.mul(98).div(100);
      if (minNewControlVariable < newControlVariable) {
        terms[_bid].controlVariable = uint64(newControlVariable);
      } else {
        terms[_bid].controlVariable = uint64(minNewControlVariable);
      }
    }
  }

  // convert an amount to standard 18 decimal format
  function standardDecimals(uint256 _amount, uint256 _bid) internal view returns (uint256) {
    uint256 decimals = IERC20Metadata(address(bonds[_bid].quoteToken)).decimals();
    return _amount.mul(1e18).div(10 ** decimals);
  }

/* ======== VIEW ======== */

  // DEPOSITS

  /**
   * @notice payout due for amount of treasury value
   * @param _amount uint256
   * @param _bid uint256
   * @return uint256
   */
  function payoutFor(uint256 _amount, uint256 _bid) public view override returns (uint256) {
    return standardDecimals(_amount, _bid).div((bondPrice(_bid)));
  }

  /**
   * @notice calculate current bond price of quote token in OHM
   * @param _bid uint256
   * @return uint256
   */
  function bondPrice(uint256 _bid) public view override returns (uint256) {
    return terms[_bid].controlVariable.mul(debtRatio(_bid)).div(1e9);
  }

  /**
   * @notice calculate debt factoring in decay
   * @param _bid uint256
   * @return uint256
   */
  function currentDebt(uint256 _bid) public view override returns (uint256) {
    return bonds[_bid].totalDebt.sub(debtDecay(_bid));
  }

  /**
   * @notice calculate current ratio of debt to OHM supply
   * @param _bid uint256
   * @return uint256
   */
  function debtRatio(uint256 _bid) public view override returns (uint256) {
    return currentDebt(_bid).mul(1e9).div(treasury.baseSupply()); 
  }

  /**
   * @notice amount to decay total debt by
   * @param _bid uint256
   * @return decay_ uint256
   */
  function debtDecay(uint256 _bid) public view override returns (uint256 decay_) {
    uint256 totalDebt = bonds[_bid].totalDebt;
    uint256 secondsSinceLast = block.timestamp.sub(bonds[_bid].lastDecay);
    decay_ = totalDebt.mul(secondsSinceLast).div(bonds[_bid].length);
    if (decay_ > totalDebt) decay_ = totalDebt;
  }

  // REDEMPTIONS

  // all pending indexes for bonder
  function indexesFor(address _bonder) public view override returns (uint256[] memory) {
      uint256 length;
      for (uint256 i = 0; i < notes[_bonder].length; i++) {
          if (notes[_bonder][i].redeemed == 0) {
              length++;
          }
      }
      uint256[] memory array = new uint256[](length);
      uint256 position;
      for (uint256 i = 0; i < notes[_bonder].length; i++) {
          if (notes[_bonder][i].redeemed == 0) {
              array[position] = i;
              position++;
          }
      }
      return array;
  }

  /**
    * @notice calculate amount of OHM available for claim for single bond
    * @param _bonder address
    * @param _index uint256
    * @return uint256
    */
  function pendingFor(address _bonder, uint256 _index) public view override returns (uint256) {
      if (notes[_bonder][_index].redeemed == 0 && notes[_bonder][_index].matured <= block.timestamp) {
          return notes[_bonder][_index].payout;
      }
      return 0;
  }

  /**
    * @notice calculate amount of OHM available for claim for array of bonds
    * @param _bonder address
    * @param _indexes uint256[]
    * @return pending_ uint256
    */
  function pendingForIndexes(address _bonder, uint256[] memory _indexes) public view override returns (uint256 pending_) {
      for (uint256 i = 0; i < _indexes.length; i++) {
          pending_ += pendingFor(_bonder, i);
      }
  }

  /**
    *  @notice total pending on all bonds for bonder
    *  @param _bonder address
    *  @return pending_ uint256
    */
  function totalPendingFor(address _bonder) public view override returns (uint256 pending_) {
      uint256[] memory indexes = indexesFor(_bonder);
      for (uint256 i = 0; i < indexes.length; i++) {
          pending_ += pendingFor(_bonder, indexes[i]);
      }
  }

/* ======== POLICY ======== */

  /**
   * @notice creates a new bond type
   * @param _quoteToken IERC20
   * @param _capacity uint256
   * @param _capacityInQuote bool
   * @param _fixedTerm bool
   * @param _vestingTerm uint256
   * @param _conclusion uint256
   * @param _currentPrice uint256
   * @return id_ uint256
   */
  function addBond(
    IERC20 _quoteToken,
    uint256 _capacity,
    bool _capacityInQuote,
    bool _fixedTerm,
    uint256 _vestingTerm,
    uint256 _conclusion,
    uint256 _currentPrice // 9 decimals, price of ohm in quote
  ) external override onlyPolicy returns (uint256 id_) {
    uint256 targetDebt = _capacity;
    if (_capacityInQuote) {
      uint256 decimals = IERC20Metadata(address(_quoteToken)).decimals();
      targetDebt = targetDebt.mul(1e18).div(10 ** decimals).div(_currentPrice);
    }
    uint256 length = _conclusion.sub(block.timestamp);
    uint256 maxPayout = targetDebt.mul(targetDepositInterval).div(length);
    uint256 controlVariable = _currentPrice.mul(treasury.baseSupply()).div(targetDebt);

    id_ = bonds.length;

    bonds.push(Bond({
      capacity: _capacity,
      totalDebt: targetDebt, 
      maxPayout: maxPayout,
      quoteToken: _quoteToken, 
      capacityInQuote: _capacityInQuote,
      lastTune: uint48(block.timestamp),
      lastDecay: uint48(block.timestamp),
      length: uint48(length)
    }));

    terms.push(Terms({
      fixedTerm: _fixedTerm, 
      controlVariable: uint64(controlVariable),
      vestingTerm: uint48(_vestingTerm), 
      conclusion: uint48(_conclusion), 
      maxDebt: uint64(targetDebt.mul(3)) // 3x buffer. exists to hedge tail risk.
    }));
  }

  /**
   * @notice disable existing bond
   * @param _id uint
   */
  function deprecateBond(uint256 _id) external override onlyPolicy {
    bonds[_id].capacity = 0;
  }

  // set reward for front end operator (4 decimals. 100 = 1%)
  function setRewards(uint256 _toFrontEnd, uint256 _toDAO) external override onlyPolicy {
      rewardRate[0] = _toFrontEnd;
      rewardRate[1] = _toDAO;
  }

  // add or remove address from the whitelist
  // whitelisted addresses can earn referral fees by operating a front end
  function whitelist(address _operator) external override onlyPolicy {
      require(_operator != dao, "Can not blacklist DAO");
      whitelisted[_operator] = !whitelisted[_operator];
  }

  function approve() external override onlyPolicy {
    ohm.approve(address(staking), 1e18);
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IOHM.sol";
import "./IsOHM.sol";
import "./IgOHM.sol";
import "./ITreasury.sol";
import "./IStaking.sol";
import "./IDistributor.sol";
import "./IDepository.sol";

interface IOlympusDirectory {
    function ohm() external view returns (IOHM);
    function sOHM() external view returns (IsOHM);
    function gOHM() external view returns (IgOHM);
    function treasury() external view returns (ITreasury);
    function staking() external view returns (IStaking);
    function distributor() external view returns (IDistributor);
    function depository() external view returns (IDepository);
    function dao() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IOlympusAuthority.sol";

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

// SPDX-License-Identifier: AGPL-3.0-or-later
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IgOHM is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function index() external view returns (uint256);

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

  function migrate( address _staking, address _sOHM ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IDepository {
  function deposit(
    uint256 _bid,
    uint256 _amount,
    uint256 _maxPrice,
    address _depositor,
    address _referral
  ) external returns (uint256 payout_, uint256 index_);
  function redeem(address _bonder, uint256[] memory _indexes) external returns (uint256);
  function redeemAll(address _bonder) external returns (uint256);
  function getReward() external;
  function tune(uint256 _bid) external;
  function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
  function bondPrice(uint256 _bid) external view returns (uint256);
  function currentDebt(uint256 _bid) external view returns (uint256);
  function debtRatio(uint256 _bid) external view returns (uint256);
  function debtDecay(uint256 _bid) external view returns (uint256 decay_);
  function indexesFor(address _bonder) external view returns (uint256[] memory);
  function pendingFor(address _bonder, uint256 _index) external view returns (uint256);
  function pendingForIndexes(address _bonder, uint256[] memory _indexes) external view returns (uint256 pending_);
  function totalPendingFor(address _bonder) external view returns (uint256 pending_);

  function addBond(
    IERC20 _quoteToken,
    uint256 _capacity,
    bool _capacityInQuote,
    bool _fixedTerm,
    uint256 _vestingTerm,
    uint256 _conclusion,
    uint256 _currentPrice
  ) external returns (uint256 id_);
  function deprecateBond(uint256 _id) external;
  function setRewards(uint256 _toFrontEnd, uint256 _toDAO) external;
  function whitelist(address _operator) external;
  function approve() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
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

// SPDX-License-Identifier: AGPL-3.0-or-later
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "./IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IOHM is IERC20 {
  function mint(address account_, uint256 amount_) external;

  function burn(uint256 amount) external;

  function burnFrom(address account_, uint256 amount_) external;
}