/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OlympusDAO/olympus-contracts/blob/87b1bb692ddb45f881465e9521b088ca3972e3e0/contracts/interfaces/ITeller.sol


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
// File: https://github.com/OlympusDAO/olympus-contracts/blob/87b1bb692ddb45f881465e9521b088ca3972e3e0/contracts/interfaces/IOracle.sol


pragma solidity >=0.7.5;

interface IOracle { // Chainlink oracle interface
    function getLatestPrice() external view returns (uint256);
    function setPrice(uint256 _price) external;
}
// File: https://github.com/OlympusDAO/olympus-contracts/blob/87b1bb692ddb45f881465e9521b088ca3972e3e0/contracts/interfaces/ITreasury.sol


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

// File: https://github.com/OlympusDAO/olympus-contracts/blob/87b1bb692ddb45f881465e9521b088ca3972e3e0/contracts/interfaces/IERC20.sol


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

// File: https://github.com/OlympusDAO/olympus-contracts/blob/87b1bb692ddb45f881465e9521b088ca3972e3e0/contracts/interfaces/IERC20Metadata.sol


pragma solidity >=0.7.5;


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
// File: https://github.com/OlympusDAO/olympus-contracts/blob/87b1bb692ddb45f881465e9521b088ca3972e3e0/contracts/libraries/SafeERC20.sol


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
// File: https://github.com/OlympusDAO/olympus-contracts/blob/87b1bb692ddb45f881465e9521b088ca3972e3e0/contracts/libraries/Address.sol


pragma solidity ^0.7.5;


// TODO(zx): replace with OZ implementation.
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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}
// File: https://github.com/OlympusDAO/olympus-contracts/blob/87b1bb692ddb45f881465e9521b088ca3972e3e0/contracts/libraries/SafeMath.sol


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
// File: https://github.com/OlympusDAO/olympus-contracts/blob/87b1bb692ddb45f881465e9521b088ca3972e3e0/contracts/BondDepository.sol


pragma solidity ^0.7.5;
pragma abicoder v2;


contract OlympusBondDepository {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /* ======== EVENTS ======== */

  event BeforeBond(uint256 index, uint256 price, uint256 internalPrice, uint256 debtRatio);
  event CreateBond(uint256 index, uint256 payout, uint256 expires);
  event BondAdded(uint16 bid);
  event BondEnabled(uint16 bid);
  event BondDeprecated(uint16 bid);
  event GlobalSet(uint256 decayRate, uint256 maxPayout);
  event FeedSet(address oracle);
  event ControllerSet(address controller);

  modifier onlyController() {
    require(msg.sender == controller, "Only controller");
    _;
  }

  /* ======== STRUCTS ======== */

  // Info about each type of bond
  struct BondMetadata {
    Terms terms; // terms of bond
    bool enabled; // must be enabled before accepts deposits
    uint256 totalDebt; // total debt from bond (in OHM)
    uint256 capacity; // capacity in ohm or principal
    IERC20 principal; // token to accept as payment
    uint48 last; // timestamp of last bond
    bool capacityInPrincipal; // capacity limit is in payout or principal terms
  }

  // Info for creating new bonds
  struct Terms {
    uint256 minDebt; // minimum OHM debt at a time
    uint256 maxDebt; // max OHM debt accrued at a time
    bool fixedTerm; // fixed term or fixed expiration
    uint48 controlVariable; // scaling variable for price
    uint48 conclusion; // timestamp when bond no longer offered
    uint48 vesting; // term in seconds if fixedTerm == true, expiration timestamp if not
  }

  struct Global {
    uint48 decayRate; // time in seconds to decay debt to zero.
    uint48 maxPayout; // percentage total supply. 9 decimals.
  }

  /* ======== STATE VARIABLES ======== */

  ITeller public teller; // handles payment
  address public controller; // adds or deprecated bonds
  ITreasury internal immutable treasury;
  IERC20 internal immutable ohm;
  IOracle public feed; // OHM-USD price feed for view function

  mapping(uint16 => BondMetadata) public bonds;
  address[] public ids; // bond IDs

  Global public global;

  /* ======== CONSTRUCTOR ======== */

  constructor(address _ohm, address _treasury) {
    require(_ohm != address(0), "Zero address: OHM");
    ohm = IERC20(_ohm);
    require(_treasury != address(0), "Zero address: Treasury");
    treasury = ITreasury(_treasury);
    controller = msg.sender;
  }

  /* ======== MUTABLE FUNCTIONS ======== */

  /**
   * @notice deposit bond
   * @param _depositor address
   * @param _bid uint256
   * @param _amount uint256
   * @param _maxPrice uint256
   * @param _feo address
   * @return payout_ uint256
   * @return index_ uint256
   */
  function deposit(
    address _depositor,
    uint16 _bid,
    uint256 _amount,
    uint256 _maxPrice,
    address _feo
  ) external returns (uint256 payout_, uint16 index_) {
    require(_depositor != address(0), "Invalid address");
    require(_maxPrice >= bondPrice(_bid), "Slippage limit: more than max price");

    BondMetadata memory info = bonds[_bid];
    _beforeBond(info, _bid);

    payout_ = in18Decimals(_amount, _bid) / bondPrice(_bid); 

    uint256 cap = payout_;
    if (info.capacityInPrincipal) { // capacity is in principal terms
      cap = _amount; 
    } 
    require(info.capacity >= cap, "Amount exceeds capacity"); // ensure there is remaining capacity
    bonds[_bid].capacity -= cap;

    _payoutWithinBounds(payout_);

    if (info.totalDebt < info.terms.minDebt || info.totalDebt + payout_ > info.terms.maxDebt) {
      bonds[_bid].capacity = 0; // disable bond if debt above max or below min bound
    }
    info.totalDebt += payout_; // increase total debt

    uint256 expiration = info.terms.vesting;
    if (info.terms.fixedTerm) {
      expiration += block.timestamp;
    }

    emit CreateBond(_bid, payout_, expiration);
    // user info stored with teller
    index_ = teller.newBond(payout_, _bid, uint48(expiration), _depositor, _feo);
    info.principal.safeTransferFrom(msg.sender, address(treasury), _amount);
  }

  /* ======== INTERNAL FUNCTIONS ======== */

  // checks and event before bond
  function _beforeBond(BondMetadata memory _info, uint16 _bid) internal {
    require(block.timestamp < _info.terms.conclusion, "Bond concluded");
    require(_info.enabled, "bond not enabled");
    _decayDebt(_bid);
    emit BeforeBond(_bid, bondPriceInUSD(_bid), bondPrice(_bid), debtRatio(_bid));
  }

  // reduce total debt based on time passed
  function _decayDebt(uint16 _bid) internal {
    bonds[_bid].totalDebt -= debtDecay(_bid);
    bonds[_bid].last = uint48(block.timestamp);
  }

  // ensure payout is not too large or small
  function _payoutWithinBounds(uint256 _payout) public view {
    require(_payout >= 1e7, "Bond too small"); // must be > 0.01 OHM ( underflow protection )
    require(_payout <= maxPayout(), "Bond too large"); // global max bond size
  }

  /* ======== VIEW FUNCTIONS ======== */

  // maximum ohm paid in single bond
  function maxPayout() public view returns (uint256) {
    return ohm.totalSupply() * global.maxPayout / 1e9;
  }

  // payout for principal of given bond id
  function payoutFor(uint256 _amount, uint16 _bid) external view returns (uint256) {
    return in18Decimals(_amount, _bid) / bondPrice(_bid);
  }

  // internal price of bond principal token in ohm
  function bondPrice(uint16 _bid) public view returns (uint256) {
    return bonds[_bid].terms.controlVariable * debtRatio(_bid) / 1e9;
  }

  // internal bond price converted to USD. note relies on oracle. view only.
  function bondPriceInUSD(uint16 _bid) public view returns (uint256) {
    return bondPrice(_bid) * feed.getLatestPrice() / 1e8;
  }

  // undecayed debt for bond divided by ohm total supply
  function debtRatio(uint16 _bid) public view returns (uint256) {
    return currentDebt(_bid) * 1e9 / ohm.totalSupply();
  }

  // debt including decay since last bond
  function currentDebt(uint16 _bid) public view returns (uint256) {
    return bonds[_bid].totalDebt - debtDecay(_bid);
  }

  // amount of debt decayed since last bond
  function debtDecay(uint16 _bid) public view returns (uint256 decay_) {
    BondMetadata memory bond = bonds[_bid];
    uint48 timeSinceLast = uint48(block.timestamp) - bond.last;

    decay_ = bond.totalDebt * timeSinceLast / global.decayRate;

    if (decay_ > bond.totalDebt) {
      decay_ = bond.totalDebt;
    }
  }

  // terms for bond ID
  function bondTerms(uint16 _bid) external view
  returns (uint256[] memory terms_, bool fixedTerm_) {
    Terms memory terms = bonds[_bid].terms;
    terms_[0] = terms.controlVariable;
    terms_[1] = terms.conclusion;
    terms_[2] = terms.vesting;
    terms_[3] = terms.maxDebt;
    fixedTerm_ = terms.fixedTerm;
  }

  /* ======== POLICY FUNCTIONS ======== */

  /**
   * @notice set global variables
   * @param _decayRate uint256
   * @param _maxPayout uint256
   */
  function setGlobal(uint48 _decayRate, uint48 _maxPayout) external onlyController {
    global.decayRate = _decayRate;
    global.maxPayout = _maxPayout;
    emit GlobalSet(_decayRate, _maxPayout);
  }

  /**
   * @notice sets address that creates/disables bonds
   * @param _controller address
   */
  function setController(address _controller) external onlyController {
    require(_controller != address(0), "Zero address: Controller");
    controller = _controller;
    emit ControllerSet(_controller);
  }

  /**
   * @notice set price feed for USD conversion
   */
  function setFeed(address _oracle) external onlyController {
    require(_oracle != address(0), "Zero address: Oracle");
    feed = IOracle(_oracle);
    emit FeedSet(_oracle);
  }

  /**
   * On creating bonds: New bond is created with a principal token to purchase,
   * an oracle quoting an 8 decimal price of that token in OHM, a budget capacity
   * (specified as in OHM or in principal token terms), a timestamp when the
   * bond concludes, and a vesting term or expiration timestamp dictated by
   * _fixedTerm being true or false, respectively.
   * 
   * The contract computes a BCV based on the amount of OHM to spend or principal
   * to buy, and the intended time to do it in (time from initialization to conclusion).
   * The bond is initialized with an amount of initial debt, which should start it
   * at the oracle price. Debt will decay from there to open discounts.
   */

  /**
   * @notice enable bond
   * @dev only necessary if safe mode enabled when bond added
   * @param _bid uint256
   */
  function enableBond(uint16 _bid) external onlyController {
    bonds[_bid].enabled = true;
    bonds[_bid].last = uint48(block.timestamp);
    emit BondEnabled(_bid);
  }

  /**
   * @notice disable existing bond
   * @param _bid uint
   */
  function deprecateBond(uint16 _bid) external onlyController {
    bonds[_bid].capacity = 0;
    emit BondDeprecated(_bid);
  }

  /**
   * @notice creates a new bond type
   * @dev note that oracle should feed 8-decimal price of principal in OHM
   * @param _principal address
   * @param _oracle address
   * @param _capacity uint256
   * @param _inPrincipal bool
   * @param _length uint256
   * @param _fixedTerm bool
   * @param _vesting uint256
   * @return id_ uint256
   */
  function addBond(
    IERC20 _principal,
    IOracle _oracle,
    uint128 _capacity,
    bool _inPrincipal,
    uint48 _length,
    bool _fixedTerm,
    uint48 _vesting
  ) external onlyController returns (uint16 id_) {
    (uint256 targetDebt, uint48 bcv) = _compute(_capacity, _inPrincipal, _length, _oracle);
    
    _checkLengths(_length, _vesting, _fixedTerm);

    Terms memory terms = Terms({
      controlVariable: bcv, 
      conclusion: uint48(block.timestamp) + _length,
      fixedTerm: _fixedTerm, 
      vesting: _vesting,
      maxDebt: targetDebt * 2, // these hedge tail risk by keeping debt in a range
      minDebt: targetDebt / 2 // wide spread given (-50%, +100%) to avoid impeding functionality
    });
    
    BondMetadata memory bond = BondMetadata({
      terms: terms,
      enabled: false,
      totalDebt: targetDebt,
      capacity: _capacity, 
      principal: _principal,   
      last: uint48(block.timestamp), 
      capacityInPrincipal: _inPrincipal
    });
    
    id_ = uint16(ids.length);
    bonds[id_] = bond;
    ids.push(address(_principal));
    emit BondAdded(id_);
  }

  /**
   * @notice set teller contract
   * @dev initialization function
   * @param _teller address
   */
  function setTeller(address _teller) external onlyController {
    require(address(teller) == address(0), "Teller is set");
    require(_teller != address(0), "Zero address: Teller");
    teller = ITeller(_teller);
  }

  /* ========== INTERNAL VIEW ========== */

  /**
   * @notice compute target debt and BCV for bond
   * @return targetDebt_ uint256
   * @return bcv_ uint64
   */
  function _compute(
    uint256 _capacity, 
    bool _inPrincipal, 
    uint256 _length, 
    IOracle _oracle
  ) internal view returns (uint256 targetDebt_, uint48 bcv_) {
    uint256 capacity = _capacity;
    if (_inPrincipal) {
      capacity = _capacity * _oracle.getLatestPrice() / 1e8;
    }

    targetDebt_ = capacity * global.decayRate / _length;
    uint256 discountedPrice = _oracle.getLatestPrice() * 98 / 100; // assume average discount of 2%
    bcv_ = uint48(discountedPrice * ohm.totalSupply() / targetDebt_);
    targetDebt_ = targetDebt_ * 102 / 100; // adjust back up to start at market price
  }
  
  // ensure bond times are appropriate
  function _checkLengths(uint48 _length, uint48 _vesting, bool _fixedTerm) internal pure {
    require(_length >= 5e5, "Program must run longer than 6 days");
    if (!_fixedTerm) {
      require(_vesting >= _length, "Bond must conclude before expiration");
    } else {
      require(_vesting >= 432_000, "Bond must vest longer than 5 days");
    }
  }
  
  /**
   * @notice amount converted to 18 decimal balance
   * @param _amount uint256
   * @param _bid uint16
   * @return uint256
   */
  function in18Decimals(uint256 _amount, uint16 _bid) internal view returns (uint256) {
    uint8 ohmDecimals = IERC20Metadata(address(ohm)).decimals();
    uint8 principalDecimals = IERC20Metadata(address(bonds[_bid].principal)).decimals();
    return _amount * 1e9 * (10 ** ohmDecimals) / (10 ** principalDecimals);
  }
}