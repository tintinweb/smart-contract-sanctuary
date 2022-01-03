// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(
      data
    );
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

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function addressToString(address _address)
    internal
    pure
    returns (string memory)
  {
    bytes32 _bytes = bytes32(uint256(uint160(_address)));
    bytes memory HEX = "0123456789abcdef";
    bytes memory _addr = new bytes(42);

    _addr[0] = "0";
    _addr[1] = "x";

    for (uint256 i = 0; i < 20; i++) {
      _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
      _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
    }

    return string(_addr);
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./libraries/0.8/SafeMath.sol";
import "./libraries/0.8/Ownable.sol";
import "./libraries/0.8/Address.sol";
import "./Tangible/interfaces/ITangibleNFT.sol";
import "./Tangible/interfaces/IMarketplace.sol";

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

library FullMath {
  function fullMul(uint256 x, uint256 y)
    private
    pure
    returns (uint256 l, uint256 h)
  {
    uint256 mm = mulmod(x, y, type(uint256).max);
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }

  function fullDiv(
    uint256 l,
    uint256 h,
    uint256 d
  ) private pure returns (uint256) {
    uint256 pow2 = d & (type(uint256).max - d + 1);
    d /= pow2;
    l /= pow2;
    l += h * ((type(uint256).max - pow2 + 1) / pow2 + 1);
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }

  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);
    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;
    require(h < d, "FullMath::mulDiv: overflow");
    return fullDiv(l, h, d);
  }
}

library FixedPoint {
  struct uq112x112 {
    uint224 _x;
  }

  struct uq144x112 {
    uint256 _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = 0x10000000000000000000000000000;
  uint256 private constant Q224 =
    0x100000000000000000000000000000000000000000000000000000000;
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  function decode112with18(uq112x112 memory self)
    internal
    pure
    returns (uint256)
  {
    return uint256(self._x) / 5192296858534827;
  }

  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= type(uint256).max) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= type(uint256).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= type(uint256).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }
}

interface ITreasury {
  function deposit(address _token, uint256 _tokenId) external returns (bool);

  function valueOfNFT(address _token) external view returns (uint256 value_);

  function depositNFT(
    address _token,
    uint256 _tokenId,
    bool _isAllProfit
  ) external returns (uint256 send_);
}

interface IStaking {
  function stake(uint256 _amount, address _recipient) external returns (bool);
}

interface IStakingHelper {
  function stake(uint256 _amount, address _recipient) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

contract NidhiGoldNFTBondDepository is Ownable, IERC721Receiver {
  using FixedPoint for *;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /* ======== EVENTS ======== */

  event BondCreated(
    address token,
    uint256 tokenId,
    uint256 indexed payout,
    uint256 indexed expires,
    uint256 indexed priceInUSD
  );
  event BondRedeemed(
    address indexed recipient,
    uint256 payout,
    uint256 remaining
  );
  event BondPriceChanged(
    uint256 indexed priceInUSD,
    uint256 indexed internalPrice,
    uint256 indexed debtRatio
  );
  event ControlVariableAdjustment(
    uint256 initialBCV,
    uint256 newBCV,
    uint256 adjustment,
    bool addition
  );

  uint256 public immutable GOLD_TROY_OUNCE_IN_GRAMS = 3110347680;

  /* ======== STATE VARIABLES ======== */

  address public immutable GURU; // token given as payment for bond
  ITangibleNFT public immutable principle; // token used to create bond
  address public immutable treasury; // mints GURU when receives principle
  address public immutable DAO; // receives profit share from bond

  IMarketplace internal marketplace;

  address public staking; // to auto-stake payout
  address public stakingHelper; // to stake and claim if no staking warmup
  bool public useHelper;

  Terms public terms; // stores terms for new bonds
  Adjust public adjustment; // stores adjustment to BCV data

  mapping(address => Bond) public bondInfo; // stores bond information for depositors

  uint256 public totalDebt; // total value of outstanding bonds; used for pricing
  uint256 public lastDecay; // reference block for debt decay

  /* ======== STRUCTS ======== */

  // Info for creating new bonds
  struct Terms {
    uint256 controlVariable; // scaling variable for price
    uint256 vestingTerm; // in blocks
    uint256 minimumPrice; // vs principle value
    uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
    uint256 fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
    uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
  }

  // Info for bond holder
  struct Bond {
    uint256 payout; // GURU remaining to be paid
    uint256 vesting; // Blocks left to vest
    uint256 lastBlock; // Last interaction
    uint256 pricePaid; // In DAI, for front end viewing
  }

  // Info for incremental adjustments to control variable
  struct Adjust {
    bool add; // addition or subtraction
    uint256 rate; // increment
    uint256 target; // BCV when adjustment finished
    uint256 buffer; // minimum length (in blocks) between adjustments
    uint256 lastBlock; // block when last adjustment made
  }

  /* ======== INITIALIZATION ======== */

  constructor(
    address _GURU,
    ITangibleNFT _principle,
    address _treasury,
    address _DAO,
    IMarketplace _marketplace
  ) {
    require(_GURU != address(0));
    GURU = _GURU;
    require(address(_principle) != address(0));
    principle = _principle;
    require(_treasury != address(0));
    treasury = _treasury;
    require(_DAO != address(0));
    DAO = _DAO;
    require(address(_marketplace) != address(0));
    marketplace = _marketplace;
  }

  /**
   *  @notice initializes bond parameters
   *  @param _controlVariable uint
   *  @param _vestingTerm uint
   *  @param _minimumPrice uint
   *  @param _maxPayout uint
   *  @param _maxDebt uint
   *  @param _initialDebt uint
   */
  function initializeBondTerms(
    uint256 _controlVariable,
    uint256 _vestingTerm,
    uint256 _minimumPrice,
    uint256 _maxPayout,
    uint256 _fee,
    uint256 _maxDebt,
    uint256 _initialDebt
  ) external onlyPolicy {
    require(terms.controlVariable == 0, "Bonds must be initialized from 0");
    terms = Terms({
      controlVariable: _controlVariable,
      vestingTerm: _vestingTerm,
      minimumPrice: _minimumPrice,
      maxPayout: _maxPayout,
      fee: _fee,
      maxDebt: _maxDebt
    });
    totalDebt = _initialDebt;
    lastDecay = block.number;
  }

  /* ======== POLICY FUNCTIONS ======== */

  enum PARAMETER {
    VESTING,
    PAYOUT,
    FEE,
    DEBT,
    MINPRICE,
    BONDCONTROLVARIABLE
  }

  /**
   *  @notice set parameters for new bonds
   *  @param _parameter PARAMETER
   *  @param _input uint
   */
  function setBondTerms(PARAMETER _parameter, uint256 _input)
    external
    onlyPolicy
  {
    if (_parameter == PARAMETER.VESTING) {
      // 0
      require(_input >= 10000, "Vesting must be longer than 36 hours");
      terms.vestingTerm = _input;
    } else if (_parameter == PARAMETER.PAYOUT) {
      // 1
      require(_input <= 1000, "Payout cannot be above 1 percent");
      terms.maxPayout = _input;
    } else if (_parameter == PARAMETER.FEE) {
      // 2
      require(_input <= 10000, "DAO fee cannot exceed payout");
      terms.fee = _input;
    } else if (_parameter == PARAMETER.DEBT) {
      // 3
      terms.maxDebt = _input;
    } else if (_parameter == PARAMETER.MINPRICE) {
      // 4
      terms.minimumPrice = _input;
    } else if (_parameter == PARAMETER.BONDCONTROLVARIABLE) {
      terms.controlVariable = _input;
    }
  }

  /**
   *  @notice set control variable adjustment
   *  @param _addition bool
   *  @param _increment uint
   *  @param _target uint
   *  @param _buffer uint
   */
  function setAdjustment(
    bool _addition,
    uint256 _increment,
    uint256 _target,
    uint256 _buffer
  ) external onlyPolicy {
    adjustment = Adjust({
      add: _addition,
      rate: _increment,
      target: _target,
      buffer: _buffer,
      lastBlock: block.number
    });
  }

  /**
   *  @notice set contract for auto stake
   *  @param _staking address
   *  @param _helper bool
   */
  function setStaking(address _staking, bool _helper) external onlyPolicy {
    require(_staking != address(0));
    if (_helper) {
      useHelper = true;
      stakingHelper = _staking;
    } else {
      useHelper = false;
      staking = _staking;
    }
  }

  /* ======== USER FUNCTIONS ======== */

  /**
   *  @notice deposit bond
   *  @param _token address
   *  @param _tokenId uint
   *  @param _maxPrice uint
   *  @param _depositor address
   *  @return uint
   */
  function deposit(
    address _token,
    uint256 _tokenId,
    uint256 _maxPrice,
    address _depositor
  ) external returns (uint256) {
    require(_depositor != address(0), "Invalid address");
    require(_token == address(principle), "Invalid principle address");

    decayDebt();
    require(totalDebt <= terms.maxDebt, "Max capacity reached");

    uint256 priceInUSD = bondPriceInUSD(); // Stored in bond info
    uint256 nativePrice = _bondPrice();

    require(_maxPrice >= nativePrice, "Slippage limit: more than max price"); // slippage protection

    uint256 value = ITreasury(treasury).valueOfNFT(_token);
    uint256 payout = payoutFor(value); // payout to bonder is computed

    require(payout >= 10000000, "Bond too small"); // must be > 0.01 GURU ( underflow protection )
    require(payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

    // profits are calculated
    uint256 fee = payout.mul(terms.fee).div(10000);

    IERC721(principle).safeTransferFrom(
      msg.sender,
      address(this),
      _tokenId,
      new bytes(0)
    );
    IERC721(principle).approve(address(treasury), _tokenId);
    ITreasury(treasury).depositNFT(address(principle), _tokenId, false);

    if (fee != 0) {
      // fee is transferred to dao
      IERC20(GURU).safeTransfer(DAO, fee);
    }

    // total debt is increased
    totalDebt = totalDebt.add(value);

    // depositor info is stored
    bondInfo[_depositor] = Bond({
      payout: bondInfo[_depositor].payout.add(payout),
      vesting: terms.vestingTerm,
      lastBlock: block.number,
      pricePaid: priceInUSD
    });

    // indexed events are emitted
    emit BondCreated(
      _token,
      _tokenId,
      payout,
      block.number.add(terms.vestingTerm),
      priceInUSD
    );
    emit BondPriceChanged(bondPriceInUSD(), _bondPrice(), debtRatio());

    adjust(); // control variable is adjusted
    return payout;
  }

  /**
   *  @notice redeem bond for user
   *  @param _recipient address
   *  @param _stake bool
   *  @return uint
   */
  function redeem(address _recipient, bool _stake) external returns (uint256) {
    Bond memory info = bondInfo[_recipient];
    uint256 percentVested = percentVestedFor(_recipient); // (blocks since last interaction / vesting term remaining)

    if (percentVested >= 10000) {
      // if fully vested
      delete bondInfo[_recipient]; // delete user info
      emit BondRedeemed(_recipient, info.payout, 0); // emit bond data
      return stakeOrSend(_recipient, _stake, info.payout); // pay user everything due
    } else {
      // if unfinished
      // calculate payout vested
      uint256 payout = info.payout.mul(percentVested).div(10000);

      // store updated deposit info
      bondInfo[_recipient] = Bond({
        payout: info.payout.sub(payout),
        vesting: info.vesting.sub(block.number.sub(info.lastBlock)),
        lastBlock: block.number,
        pricePaid: info.pricePaid
      });

      emit BondRedeemed(_recipient, payout, bondInfo[_recipient].payout);
      return stakeOrSend(_recipient, _stake, payout);
    }
  }

  /* ======== INTERNAL HELPER FUNCTIONS ======== */

  /**
   *  @notice allow user to stake payout automatically
   *  @param _stake bool
   *  @param _amount uint
   *  @return uint
   */
  function stakeOrSend(
    address _recipient,
    bool _stake,
    uint256 _amount
  ) internal returns (uint256) {
    if (!_stake) {
      // if user does not want to stake
      IERC20(GURU).transfer(_recipient, _amount); // send payout
    } else {
      // if user wants to stake
      if (useHelper) {
        // use if staking warmup is 0
        IERC20(GURU).approve(stakingHelper, _amount);
        IStakingHelper(stakingHelper).stake(_amount, _recipient);
      } else {
        IERC20(GURU).approve(staking, _amount);
        IStaking(staking).stake(_amount, _recipient);
      }
    }
    return _amount;
  }

  /**
   *  @notice makes incremental adjustment to control variable
   */
  function adjust() internal {
    uint256 blockCanAdjust = adjustment.lastBlock.add(adjustment.buffer);
    if (adjustment.rate != 0 && block.number >= blockCanAdjust) {
      uint256 initial = terms.controlVariable;
      if (adjustment.add) {
        terms.controlVariable = terms.controlVariable.add(adjustment.rate);
        if (terms.controlVariable >= adjustment.target) {
          adjustment.rate = 0;
        }
      } else {
        terms.controlVariable = terms.controlVariable.sub(adjustment.rate);
        if (terms.controlVariable <= adjustment.target) {
          adjustment.rate = 0;
        }
      }
      adjustment.lastBlock = block.number;
      emit ControlVariableAdjustment(
        initial,
        terms.controlVariable,
        adjustment.rate,
        adjustment.add
      );
    }
  }

  /**
   *  @notice reduce total debt
   */
  function decayDebt() internal {
    totalDebt = totalDebt.sub(debtDecay());
    lastDecay = block.number;
  }

  /* ======== VIEW FUNCTIONS ======== */

  /**
   *  @notice determine maximum bond size
   *  @return uint
   */
  function maxPayout() public view returns (uint256) {
    return IERC20(GURU).totalSupply().mul(terms.maxPayout).div(100000);
  }

  /**
   *  @notice calculate interest due for new bond
   *  @param _value uint
   *  @return uint
   */
  function payoutFor(uint256 _value) public view returns (uint256) {
    return FixedPoint.fraction(_value, bondPrice()).decode112with18().div(1e16);
  }

  /**
   *  @notice calculate current bond premium
   *  @return price_ uint
   */
  function bondPrice() public view returns (uint256 price_) {
    price_ = terms.controlVariable.mul(debtRatio()).add(1000000000).div(1e7);
    if (price_ < terms.minimumPrice) {
      price_ = terms.minimumPrice;
    }
  }

  /**
   *  @notice calculate current bond price and remove floor if above
   *  @return price_ uint
   */
  function _bondPrice() internal returns (uint256 price_) {
    price_ = terms.controlVariable.mul(debtRatio()).add(1000000000).div(1e7);
    if (price_ < terms.minimumPrice) {
      price_ = terms.minimumPrice;
    } else if (terms.minimumPrice != 0) {
      terms.minimumPrice = 0;
    }
  }

  /**
   *  @notice get asset price from chainlink
   */
  function assetPrice() public view returns (uint256) {
    return marketplace.priceFromOracle(principle);
  }

  /**
   *  @notice converts bond price to DAI value
   *  @return price_ uint
   */
  function bondPriceInUSD() public view returns (uint256 price_) {
    price_ = bondPrice().mul(uint256(assetPrice())).mul(1e4);
  }

  /**
   *  @notice calculate current ratio of debt to GURU supply
   *  @return debtRatio_ uint
   */
  function debtRatio() public view returns (uint256 debtRatio_) {
    uint256 supply = IERC20(GURU).totalSupply();
    debtRatio_ = FixedPoint
      .fraction(currentDebt().mul(1e9), supply)
      .decode112with18()
      .div(1e18);
  }

  /**
   *  @notice debt ratio in same terms as reserve bonds
   *  @return uint
   */
  function standardizedDebtRatio() external view returns (uint256) {
    return debtRatio().mul(uint256(assetPrice())).div(1e8);
  }

  /**
   *  @notice calculate debt factoring in decay
   *  @return uint
   */
  function currentDebt() public view returns (uint256) {
    return totalDebt.sub(debtDecay());
  }

  /**
   *  @notice amount to decay total debt by
   *  @return decay_ uint
   */
  function debtDecay() public view returns (uint256 decay_) {
    uint256 blocksSinceLast = block.number.sub(lastDecay);
    decay_ = totalDebt.mul(blocksSinceLast).div(terms.vestingTerm);
    if (decay_ > totalDebt) {
      decay_ = totalDebt;
    }
  }

  /**
   *  @notice calculate how far into vesting a depositor is
   *  @param _depositor address
   *  @return percentVested_ uint
   */
  function percentVestedFor(address _depositor)
    public
    view
    returns (uint256 percentVested_)
  {
    Bond memory bond = bondInfo[_depositor];
    uint256 blocksSinceLast = block.number.sub(bond.lastBlock);
    uint256 vesting = bond.vesting;

    if (vesting > 0) {
      percentVested_ = blocksSinceLast.mul(10000).div(vesting);
    } else {
      percentVested_ = 0;
    }
  }

  /**
   *  @notice calculate amount of GURU available for claim by depositor
   *  @param _depositor address
   *  @return pendingPayout_ uint
   */
  function pendingPayoutFor(address _depositor)
    external
    view
    returns (uint256 pendingPayout_)
  {
    uint256 percentVested = percentVestedFor(_depositor);
    uint256 payout = bondInfo[_depositor].payout;

    if (percentVested >= 10000) {
      pendingPayout_ = payout;
    } else {
      pendingPayout_ = payout.mul(percentVested).div(10000);
    }
  }

  /* ======= AUXILLIARY ======= */

  /**
   *  @notice allow anyone to send lost tokens (GURU) to the DAO
   *  @return bool
   */
  function recoverLostToken(address _token) external returns (bool) {
    require(_token != GURU);
    IERC20(_token).safeTransfer(DAO, IERC20(_token).balanceOf(address(this)));
    return true;
  }

  function onERC721Received(
    address operator,
    address,
    uint256 tokenId,
    bytes calldata
  ) external override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  function sqrrt(uint256 a) internal pure returns (uint256 c) {
    if (a > 3) {
      c = a;
      uint256 b = add(div(a, 2), 1);
      while (b < c) {
        c = b;
        b = div(add(div(a, b), b), 2);
      }
    } else if (a != 0) {
      c = 1;
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;

  function pushManagement(address newOwner_) external;

  function pullManagement() external;
}

contract Ownable is IOwnable {
  address internal _owner;
  address internal _newOwner;

  event OwnershipPushed(
    address indexed previousOwner,
    address indexed newOwner
  );
  event OwnershipPulled(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = msg.sender;
    emit OwnershipPushed(address(0), _owner);
  }

  function policy() public view override returns (address) {
    return _owner;
  }

  modifier onlyPolicy() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceManagement() public virtual override onlyPolicy {
    emit OwnershipPushed(_owner, address(0));
    _owner = address(0);
  }

  function pushManagement(address newOwner_)
    public
    virtual
    override
    onlyPolicy
  {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipPushed(_owner, newOwner_);
    _newOwner = newOwner_;
  }

  function pullManagement() public virtual override {
    require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
    emit OwnershipPulled(_owner, _newOwner);
    _owner = _newOwner;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title ITangibleNFT interface defines the interface of the TangibleNFT
interface ITangibleNFT is IERC721, IERC721Metadata, IERC721Enumerable {
    event StoragePricePerYearSet(uint256 oldPrice, uint256 newPrice);
    event StoragePercentagePricePerYearSet(
        uint256 oldPercentage,
        uint256 newPercentage
    );
    event StorageFeeToPay(
        uint256 indexed tokenId,
        uint256 _years,
        uint256 amount
    );
    event ProducedTNFT(uint256 tokenId);
    event ProducedTNFTs(uint256[] tokenId);

    // /// @dev Function allows a Factory to mint tokenId for provided vendorId to the given address(stock storage, usualy marketplace).
    // function produceTNFTtoStock(uint128 vendorId, address toStock, string calldata brandName) external returns (uint256);

    /// @dev Function allows a Factory to mint multiple tokenIds for provided vendorId to the given address(stock storage, usualy marketplace)
    /// with provided count.
    function produceMultipleTNFTtoStock(
        uint128 vendorId,
        uint256 count,
        address toStock,
        string calldata brandName
    ) external returns (uint256[] memory);

    /// @dev Function that provides info of how much TNFTs has the vendor produced(minted)
    function vendorProducedTNFTs(uint128 vendorId)
        external
        view
        returns (uint256);

    /// @dev Function that provides lists all TNFTs that vendor ever produced for this category
    function listTNFTsByVendor(uint128 vendorId)
        external
        view
        returns (uint256[] memory);

    /// @dev Function allows the Factory to burn all requested token IDs.
    function destroyTNFTs(uint256[] memory tokenId, address burningFrom)
        external;

    /// @dev The function returns whether storage fee is paid for the current time.
    function isStorageFeePaid(uint256 tokenId) external view returns (bool);

    /// @dev The function returns what is the last timestamp of the paid storage.
    function storageEndTime(uint256 tokenId) external view returns (uint256);

    /// @dev The function returns the price per year for storage.
    function storagePricePerYear() external view returns (uint256);

    /// @dev The function returns the percentage of item price that is used for calculating storage.
    function storagePercentagePricePerYear() external view returns (uint256);

    /// @dev The function returns whether storage for the TNFT is paid in fixed amount or in percentage from price
    function storagePriceFixed() external view returns (bool);

    /// @dev The function accepts takes tokenId, its price and years sets storage and returns amount to pay for.
    function adjustStorageAndGetAmount(
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) external returns (uint256);

    /// @dev The function sets the brand name for the token
    function setBrand(uint256 tokenId, string calldata brand) external;

    /// @dev The function approved brands for the nft
    function addApprovedBrand(string calldata brand) external;

    //returns approved brands
    function getApprovedBrands() external view returns (string[] memory);

    /// @dev The function returns the brand name for the token
    function tokenBrand(uint256 tokenId) external returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFactory.sol";

/// @title IMarketplace interface defines the interface of the Marketplace
interface IMarketplace is IVoucher {
    struct Lot {
        ITangibleNFT nft;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool minted;
    }

    event Selling(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price
    );
    event StopSelling(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId
    );
    event Bought(
        address indexed buyer,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    event SellFeeAddressSet(address indexed oldFee, address indexed newFee);
    event SellFeeChanged(uint256 indexed oldFee, uint256 indexed newFee);
    event SetFactory(address indexed oldFactory, address indexed newFactory);
    event StorageFeePaid(
        uint256 indexed tokenId,
        uint256 _years,
        uint256 amount
    );

    /// @dev The function allows anyone to put on sale the TangibleNFT they own
    /// if price is 0 - use oracle when selling
    function sell(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 price
    ) external;

    /// @dev The function allows the owner of the minted TangibleNFT item to remove it from the Marketplace
    function stopSale(ITangibleNFT nft, uint256 tokenId) external;

    /// @dev The function allows the user to buy any TangibleNFT from the Marketplace for USDC
    function buy(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years
    ) external;

    /// @dev The function allows the user to buy any TangibleNFT from the Marketplace for USDC
    function buyUnminted(
        ITangibleNFT nft,
        address _vendor,
        string calldata _brand,
        uint256 _years
    ) external;

    /// @dev The function returns the address of the fee storage.
    function sellFeeAddress() external view returns (address);

    /// @dev The function which buys additional storage to token.
    function payStorage(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years
    ) external;

    ///@dev Function to take price from oracle
    function priceFromOracle(ITangibleNFT nft) external view returns (uint256);

    ///@dev Function to convert oracle price with provided decimals to usdc
    function convertPriceToUSDC(uint256 price, uint8 decimals)
        external
        pure
        returns (uint256);

    ///@dev Function that returns decimals from oracle
    function decimalsFromOracle(ITangibleNFT nft) external view returns (uint8);

    ///@dev Function that returns latest timestamp from oracle
    function latestTimeStampFromOracle(ITangibleNFT nft)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./IVoucher.sol";
import "./ITangiblePriceManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IFactory interface defines the interface of the Factory which creates NFTs.
interface IFactory is IVoucher {
    event FeeStorageAddressSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event PriceManagerSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event DeployerAddressSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event MarketplaceAddressSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event MintedTokens(address indexed nft, uint256[] tokenIds);
    event ApprovedVendor(address vendorId, bool approved);
    event ApprovedStorageOperator(address storageOperatorId, bool approved);
    event NewCategoryDeployed(address tnftCategory);

    /// @dev The function which does lazy minting.
    function mint(MintVoucher calldata voucher)
        external
        returns (uint256[] memory);

    /// @dev The function lazy-burns tokens.
    function burn(BurnVoucher calldata voucher) external;

    /// @dev The function returns the address of the fee storage.
    function feeStorageAddress() external view returns (address);

    /// @dev The function returns the address of the marketplace.
    function marketplace() external view returns (address);

    /// @dev The function returns the address of the tnft deployer.
    function deployer() external view returns (address);

    /// @dev The function returns the address of the priceManager.
    function priceManager() external view returns (ITangiblePriceManager);

    /// @dev The function returns the address of the USDC token.
    function USDC() external view returns (IERC20);

    /// @dev The function creates new category and returns an address of newly created contract.
    function newCategory(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bool isStoragePriceFixedAmount,
        address priceOracle
    ) external returns (ITangibleNFT);

    /// @dev The function returns an address of category NFT.
    function category(string calldata name)
        external
        view
        returns (ITangibleNFT);

    /// @dev The function returns if address is operator in Factory
    function isFactoryOperator(address operator) external view returns (bool);

    /// @dev The function returns if address is vendor in Factory
    function isFactoryAdmin(address admin) external view returns (bool);

    /// @dev The function pays for storage, called only by marketplace
    function adjustStorageAndGetAmount(
        ITangibleNFT tnft,
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) external returns (uint256);

    /// @dev return list of all vendors
    function getVendors() external view returns (address[] memory);

    /// @dev adds brand to the provided nft
    function approveBrandForTnft(ITangibleNFT nft, string calldata brand)
        external;

    /// @dev returns vendor for provided vendorId
    function idToVendor(uint128 vendorId) external view returns (address);

    /// @dev updates oracle for already deployed tnft
    function updateOracleForTnft(string calldata name, address priceOracle)
        external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleNFT.sol";

interface IVoucher {
    /// @dev Voucher for lazy-minting
    struct MintVoucher {
        ITangibleNFT token;
        uint256 mintCount;
        uint256 price;
        address vendor;
        address buyer;
        string brand;
    }

    /// @dev Voucher for lazy-burning
    struct BurnVoucher {
        ITangibleNFT token;
        uint256[] tokenIds;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleNFT.sol";
import "./IPriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ITangiblePriceManager interface gives prices for categories added in TangiblePriceManager.
interface ITangiblePriceManager {
    event CategoryPriceOracleAdded(
        address indexed category,
        address indexed priceOracle
    );

    /// @dev The function returns contract oracle for category.
    function getPriceOracleForCategory(ITangibleNFT category)
        external
        view
        returns (IPriceOracle);

    /// @dev The function returns current price from oracle for provided category.
    function setOracleForCategory(ITangibleNFT category, IPriceOracle oracle)
        external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITangibleNFT.sol";

/// @title ITangiblePriceManager interface gives prices for categories added in TangiblePriceManager.
interface IPriceOracle {
    /// @dev The function latest price and latest timestamp when price was updated from oracle.
    function latestAnswer(ITangibleNFT nft) external view returns (uint256);

    /// @dev The function latest price and latest timestamp when price was updated from oracle.
    function latestTimeStamp(ITangibleNFT nft) external view returns (uint256);

    /// @dev The function that returns price decimals from oracle.
    function decimals() external view returns (uint8);

    /// @dev The function that returns rescription for oracle.
    function description() external view returns (string memory desc);

    /// @dev The function that returns version of the oracle.
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./interfaces/IMarketplace.sol";
import "./abstract/Exchange.sol";
import "./interfaces/IWETH9.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Marketplace is AdminAndTangibleAccess, IMarketplace, IERC721Receiver {
    using SafeERC20 for IERC20;
    IFactory public factory;

    mapping(address => mapping(uint256 => Lot)) marketplace;

    mapping(address => mapping(address => uint256))
        public remainingMintsForVendor;

    IWETH9 public WETH9;
    address public override sellFeeAddress;

    // Default sell fee is 2.5%
    uint256 public sellFee = 250;

    constructor(
        address _factory,
        address _WETH9,
        address _sellFeeAddress
    ) {
        require(_factory != address(0), "ZFA");
        require(_WETH9 != address(0), "ZWETH");
        require(_sellFeeAddress != address(0), "SFAZ");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        WETH9 = IWETH9(_WETH9);
        sellFeeAddress = _sellFeeAddress;

        factory = IFactory(_factory);
        emit SellFeeChanged(0, sellFee);
        emit SellFeeAddressSet(address(0), _sellFeeAddress);
    }

    receive() external payable {
        require(msg.sender == address(WETH9), "!WETH");
    }

    fallback() external payable {
        require(msg.sender == address(WETH9), "!WETH");
    }

    /// @inheritdoc IMarketplace
    function sell(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 price
    ) external override {
        IERC721(nft).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            abi.encode(price)
        );
    }

    function setFactory(address _factory) external onlyAdmin {
        require(
            (_factory != address(0x0)) && (_factory != address(factory)),
            "WFA"
        );

        _setupRole(FACTORY_ROLE, _factory);
        _revokeRole(FACTORY_ROLE, address(factory));
        emit SetFactory(address(factory), _factory);
        factory = IFactory(_factory);
    }

    /// @inheritdoc IMarketplace
    function stopSale(ITangibleNFT nft, uint256 tokenId) external override {
        address seller = msg.sender;
        // gas saving
        Lot memory _lot = marketplace[address(nft)][tokenId];
        require(_lot.seller == seller, "Not a seller");

        emit StopSelling(seller, address(nft), tokenId);
        delete marketplace[address(nft)][tokenId];
        IERC721(nft).safeTransferFrom(address(this), _lot.seller, _lot.tokenId);
    }

    /// @inheritdoc IMarketplace
    function buy(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years
    ) external override {
        Lot memory _lot = marketplace[address(nft)][tokenId];
        uint256 tokenPrice = _lot.price == 0
            ? _convertPriceToUSDC(
                factory
                    .priceManager()
                    .getPriceOracleForCategory(nft)
                    .latestAnswer(nft),
                factory.priceManager().getPriceOracleForCategory(nft).decimals()
            )
            : _lot.price;
        //pay for storage
        if (!nft.isStorageFeePaid(tokenId) || _years > 0) {
            require(_years > 0, "YZ");
            _payStorage(nft, tokenId, _years, tokenPrice);
        }
        //buy the token
        _buy(nft, tokenId, msg.sender);
    }

    function payStorage(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years
    ) external override {
        uint256 tokenPrice = _convertPriceToUSDC(
            factory.priceManager().getPriceOracleForCategory(nft).latestAnswer(
                nft
            ),
            factory.priceManager().getPriceOracleForCategory(nft).decimals()
        );
        _payStorage(nft, tokenId, _years, tokenPrice);
    }

    function _payStorage(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) internal {
        require(_years > 0, "YZ");

        uint256 amount = factory.adjustStorageAndGetAmount(
            nft,
            tokenId,
            _years,
            tokenPrice
        );

        IFactory(factory).USDC().safeTransferFrom(
            msg.sender,
            IFactory(factory).feeStorageAddress(),
            amount
        );
        emit StorageFeePaid(tokenId, _years, amount);
    }

    /// @inheritdoc IMarketplace
    function buyUnminted(
        ITangibleNFT nft,
        address _vendor,
        string calldata _brand,
        uint256 _years
    ) external override {
        require(remainingMintsForVendor[address(nft)][_vendor] > 0, "No more");
        uint256 tokenPrice = _convertPriceToUSDC(
            factory.priceManager().getPriceOracleForCategory(nft).latestAnswer(
                nft
            ),
            factory.priceManager().getPriceOracleForCategory(nft).decimals()
        );
        require(tokenPrice > 0, "tnft !exist");

        MintVoucher memory voucher = MintVoucher({
            token: nft,
            mintCount: 1,
            price: 0,
            vendor: _vendor,
            buyer: msg.sender,
            brand: _brand
        });
        uint256[] memory tokenIds = factory.mint(voucher);
        //pay for storage
        _payStorage(nft, tokenIds[0], _years, tokenPrice);
        //pricing should be handled from oracle
        _buy(voucher.token, tokenIds[0], msg.sender);

        remainingMintsForVendor[address(nft)][_vendor]--;
    }

    function lot(address nft, uint256 tokenId)
        external
        view
        returns (Lot memory)
    {
        return marketplace[nft][tokenId];
    }

    function priceFromOracle(ITangibleNFT nft)
        external
        view
        override
        returns (uint256)
    {
        return
            factory.priceManager().getPriceOracleForCategory(nft).latestAnswer(
                nft
            );
    }

    function convertPriceToUSDC(uint256 price, uint8 decimals)
        external
        pure
        override
        returns (uint256)
    {
        return _convertPriceToUSDC(price, decimals);
    }

    function _convertPriceToUSDC(uint256 price, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        require(
            decimals > uint8(0) && decimals <= uint8(18),
            "Invalid _decimals"
        );
        if (uint256(decimals) > 6) {
            return price / (10**(uint256(decimals) - 6));
        } else if (uint256(decimals) < 6) {
            return price * (10**(6 - uint256(decimals)));
        }
        return price;
    }

    function decimalsFromOracle(ITangibleNFT nft)
        external
        view
        override
        returns (uint8)
    {
        return factory.priceManager().getPriceOracleForCategory(nft).decimals();
    }

    function latestTimeStampFromOracle(ITangibleNFT nft)
        external
        view
        override
        returns (uint256)
    {
        return
            factory
                .priceManager()
                .getPriceOracleForCategory(nft)
                .latestTimeStamp(nft);
    }

    function increaseMints(
        ITangibleNFT nft,
        address vendor,
        uint256 amount
    ) external onlyAdmin {
        remainingMintsForVendor[address(nft)][vendor] += amount;
    }

    function decreaseMints(
        ITangibleNFT nft,
        address vendor,
        uint256 amount
    ) external onlyAdmin {
        if (amount > remainingMintsForVendor[address(nft)][vendor]) {
            remainingMintsForVendor[address(nft)][vendor] = 0;
        } else {
            remainingMintsForVendor[address(nft)][vendor] -= amount;
        }
    }

    function _buy(
        ITangibleNFT nft,
        uint256 tokenId,
        address payer
    ) internal {
        // gas saving
        address buyer = msg.sender;

        Lot memory _lot = marketplace[address(nft)][tokenId];
        require(_lot.seller != address(0), "No lot");
        // require(_lot.amount >= amount, "Not enough");

        // if lot.price == 0 it means vendor minted it, we must take price from oracle
        // if lot.price != 0 means some seller posted it and didn't want to use oracle
        uint256 cost = _lot.price == 0
            ? _convertPriceToUSDC(
                factory
                    .priceManager()
                    .getPriceOracleForCategory(nft)
                    .latestAnswer(nft),
                factory.priceManager().getPriceOracleForCategory(nft).decimals()
            )
            : _lot.price;
        require(cost != 0, "Price 0");

        //take the fee
        uint256 toPayVendor = cost;
        if (sellFee > 0) {
            // if there is fee set, decrease amount by the fee and send fee
            uint256 fee = ((toPayVendor * sellFee) / 10000);
            toPayVendor = toPayVendor - fee;
            factory.USDC().transferFrom(payer, sellFeeAddress, fee);
        }

        factory.USDC().safeTransferFrom(payer, _lot.seller, toPayVendor);

        emit Bought(buyer, address(nft), tokenId, _lot.seller, cost);
        delete marketplace[address(nft)][tokenId];

        IERC721(nft).safeTransferFrom(address(this), buyer, tokenId, "");
    }

    /// @notice Sets the feeStorageAddress
    /// @dev Will emit SellFeeAddressSet on change.
    /// @param _sellFeeAddress A new address for fee storage.
    function setSellFeeAddress(address _sellFeeAddress) external onlyAdmin {
        require(_sellFeeAddress != address(0), "SFAZ");
        if (sellFeeAddress != _sellFeeAddress) {
            emit SellFeeAddressSet(sellFeeAddress, _sellFeeAddress);
            sellFeeAddress = _sellFeeAddress;
        }
    }

    function withdrawTokens(IERC20 token) external onlyAdmin {
        require(address(token) != address(factory.USDC()), "USDC");

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Zero");

        token.transfer(msg.sender, balance);
    }

    function withdrawMatic() public onlyAdmin {
        uint256 amountToTransferMatic = address(this).balance;
        payable(msg.sender).transfer(amountToTransferMatic);
    }

    function setSellFee(uint256 _sellFee) external onlyAdmin {
        require(sellFee != _sellFee, "SSF");
        emit SellFeeChanged(sellFee, _sellFee);
        sellFee = _sellFee;
    }

    function onERC721Received(
        address operator,
        address seller,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return _onERC721Received(operator, seller, tokenId, data);
    }

    function _onERC721Received(
        address operator,
        address seller,
        uint256 tokenId,
        bytes calldata data
    ) private returns (bytes4) {
        address nft = msg.sender;
        uint256 price = abi.decode(data, (uint256));

        marketplace[nft][tokenId] = Lot(
            ITangibleNFT(nft),
            tokenId,
            seller,
            price,
            true
        );

        emit Selling(seller, nft, tokenId, price);
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWETH9.sol";
import "./AdminAndTangibleAccess.sol";

abstract contract Exchange is AdminAndTangibleAccess {
    using SafeERC20 for IERC20;

    IQuoter public quoter;
    address public router;
    bool public isUniswapV3;
    IWETH9 public WETH9;

    event NewRouterSet(
        address indexed oldRouter,
        address indexed newRouter,
        bool isUniswapV3
    );
    event NewUniswapV3Quoter(
        address indexed oldQuoter,
        address indexed newQuoter
    );
    event NewWETH9(address indexed oldWETH9, address indexed newWETH9);

    constructor(address _uniswapV3Quoter, address _WETH9) {
        quoter = IQuoter(_uniswapV3Quoter);
        WETH9 = IWETH9(_WETH9);
    }

    function setQuoter(address _quoter) external onlyAdmin {
        require(_quoter != address(0), "ZUSQ");
        require(_quoter != address(quoter), "SUSQ");

        emit NewUniswapV3Quoter(address(quoter), _quoter);
        quoter = IQuoter(_quoter);
    }

    function setWETH9(address _WETH9) external onlyAdmin {
        require(_WETH9 != address(0), "ZWETH");
        require(_WETH9 != address(WETH9), "SWETH");

        emit NewUniswapV3Quoter(address(quoter), _WETH9);
        quoter = IQuoter(_WETH9);
    }

    function setRouter(address _router, bool _isUniswapV3) external onlyAdmin {
        require(_router != address(0), "ZUSR");
        require(_router != router || _isUniswapV3 != isUniswapV3, "SUSR");

        emit NewRouterSet(router, _router, _isUniswapV3);
        router = _router;
        isUniswapV3 = _isUniswapV3;
    }

    function exchange(
        address tokenIn,
        address tokenOut,
        uint256 amountToReceive,
        uint256 maxAmountIn
    ) internal returns (uint256) {
        if (isUniswapV3) {
            return exchangeV3(tokenIn, tokenOut, amountToReceive, maxAmountIn);
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = IUniswapV2Router01(router)
            .swapTokensForExactTokens(
                amountToReceive,
                maxAmountIn,
                path,
                address(this),
                block.timestamp + 15
            );
        return amounts[0];
    }

    function exchangeV3(
        address tokenIn,
        address tokenOut,
        uint256 amountToReceive,
        uint256 maxAmountIn
    ) internal returns (uint256) {
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams(
                tokenIn,
                tokenOut,
                3000,
                address(this),
                block.timestamp + 15,
                amountToReceive,
                maxAmountIn,
                0
            );

        return ISwapRouter(router).exactOutputSingle(params);
    }

    function quoteIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) public returns (uint256) {
        if (isUniswapV3) {
            return
                quoter.quoteExactOutputSingle(
                    tokenIn,
                    tokenOut,
                    300,
                    amountOut,
                    0
                );
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = IUniswapV2Router01(router).getAmountsIn(
            amountOut,
            path
        );
        return amounts[0];
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./AdminAccess.sol";

abstract contract AdminAndTangibleAccess is AdminAccess {
    bytes32 public constant VENDOR_ROLE = keccak256("VENDOR");
    bytes32 public constant STORAGE_OPERATOR_ROLE =
        keccak256("STORAGE_OPERATOR");
    bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE");

    /// @dev Restricted to members of the vendor role.
    modifier onlyVendorOrMarketplace() {
        require(isVendor(msg.sender) || isMarketplace(msg.sender), "NVMR");
        _;
    }

    /// @dev Return `true` if the account belongs to the vendor role.
    function isVendor(address account) internal view returns (bool) {
        return hasRole(VENDOR_ROLE, account);
    }

    /// @dev Restricted to members of the storage operator role.
    modifier onlyStorageOperator() {
        require(isStorageOperator(msg.sender), "NSOR");
        _;
    }

    /// @dev Return `true` if the account belongs to the storage operator role.
    function isStorageOperator(address account) internal view returns (bool) {
        return hasRole(STORAGE_OPERATOR_ROLE, account);
    }

    /// @dev Restricted to members of the marketplace role.
    modifier onlyMarketplace() {
        require(isMarketplace(msg.sender), "NMR!");
        _;
    }

    /// @dev Return `true` if the account belongs to the marketplace role.
    function isMarketplace(address account) internal view returns (bool) {
        return hasRole(MARKETPLACE_ROLE, account);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AdminAccess is AccessControl {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY");
    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not admin");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Restricted to members of the factory role.
    modifier onlyFactory() {
        require(isFactory(msg.sender), "Not in Factory role!");
        _;
    }

    /// @dev Return `true` if the account belongs to the factory role.
    function isFactory(address account) internal view returns (bool) {
        return hasRole(FACTORY_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the factory role or admin role.
    function isAdminOrFactory(address account) internal view returns (bool) {
        return isFactory(account) || isAdmin(account);
    }

    modifier onlyFactoryOrAdmin() {
        require(isAdminOrFactory(msg.sender), "NFAR");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./interfaces/ITangibleNFT.sol";
import "./interfaces/IFactory.sol";
import "./abstract/AdminAccess.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TangibleNFT is
    AdminAccess,
    ERC721,
    ERC721Enumerable,
    ERC721Pausable,
    ITangibleNFT
{
    using SafeERC20 for IERC20;
    using Strings for uint256;

    mapping(uint256 => uint256) public override storageEndTime;
    mapping(uint256 => string) public override tokenBrand;
    // map to keep track of vendor minted tokens
    mapping(uint128 => uint128) private _lastVendorsTokenId;
    mapping(uint256 => address) private _originalTokenOwners;

    mapping(uint256 => bool) public blackListedTokens;

    string[] private approvedBrands;
    mapping(string => bool) approvedBrandsMap;

    uint256 public override storagePricePerYear;
    uint256 public override storagePercentagePricePerYear; //max percent precision is 2 decimals 100% is 10000 0.01% is 1
    bool public override storagePriceFixed;
    address public factory;

    string private _baseUriLink;

    modifier onlyFactoryAdmin() {
        require(IFactory(factory).isFactoryAdmin(msg.sender), "NFA");
        _;
    }

    modifier onlyFactoryOrFactoryAdmin() {
        require(
            IFactory(factory).isFactoryAdmin(msg.sender) ||
                isFactory(msg.sender),
            "NFFA"
        );
        _;
    }

    constructor(
        address _factory,
        string memory category,
        string memory symbol,
        string memory uri,
        bool _storagePriceFixed
    ) ERC721(category, symbol) {
        require(_factory != address(0), "FZ");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FACTORY_ROLE, _factory);

        factory = _factory;
        _baseUriLink = uri;

        storagePriceFixed = _storagePriceFixed;
        storagePricePerYear = 20000000; // 20$ in USDC
        storagePercentagePricePerYear = 100; //1 percent
    }

    function baseSymbolURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseUriLink, "/", symbol(), "/"));
    }

    function setBaseURI(string calldata uri) external onlyFactoryAdmin {
        _baseUriLink = uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, IERC721Metadata)
        returns (string memory)
    {
        require(_exists(tokenId), "NT");

        string memory _uri = _baseUriLink;
        return
            bytes(_uri).length > 0
                ? string(
                    abi.encodePacked(
                        _baseUriLink,
                        "/",
                        symbol(),
                        "/",
                        tokenId.toString()
                    )
                )
                : "";
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        return
            operator == factory || ERC721.isApprovedForAll(account, operator);
    }

    /// @inheritdoc ITangibleNFT
    function produceMultipleTNFTtoStock(
        uint128 vendorId,
        uint256 count,
        address toStock,
        string calldata brandName
    ) external override onlyFactory returns (uint256[] memory) {
        uint256[] memory mintedTnfts = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            mintedTnfts[i] = _produceTNFTtoStock(vendorId, toStock, brandName);
        }
        emit ProducedTNFTs(mintedTnfts);
        return mintedTnfts;
    }

    function _produceTNFTtoStock(
        uint128 vendorId,
        address toStock,
        string calldata brandName
    ) internal returns (uint256) {
        //create vendor token id
        uint128 lastVendorProducedTNFT = _lastVendorsTokenId[vendorId];
        require(lastVendorProducedTNFT < type(uint128).max, "MID");
        require(approvedBrandsMap[brandName], "BNA");

        uint256 tokenToMint = (uint256(vendorId) << 128) |
            ++lastVendorProducedTNFT;

        //create new tnft and update last produced tnft in map
        _mint(toStock, tokenToMint);
        _lastVendorsTokenId[vendorId] = lastVendorProducedTNFT;
        //store brand name
        tokenBrand[tokenToMint] = brandName;
        _originalTokenOwners[tokenToMint] = toStock;

        return tokenToMint;
    }

    /// @inheritdoc ITangibleNFT
    function vendorProducedTNFTs(uint128 vendorId)
        external
        view
        override
        returns (uint256)
    {
        //returns how much vendor has minted so far, 0 is never minted
        return uint256(_lastVendorsTokenId[vendorId]);
    }

    /// @inheritdoc ITangibleNFT
    function listTNFTsByVendor(uint128 vendorId)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds;
        uint128 lastVendorTokenId = _lastVendorsTokenId[vendorId];
        for (uint256 i = 0; i <= lastVendorTokenId; i++) {
            tokenIds[i] = (vendorId << 128) | i;
        }
        return tokenIds;
    }

    /// @inheritdoc ITangibleNFT
    function destroyTNFTs(uint256[] calldata tokenIds, address burningFrom)
        external
        override
        onlyFactoryOrFactoryAdmin
    {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _destroyTNFT(tokenIds[i], burningFrom);
        }
    }

    function _destroyTNFT(uint256 tokenId, address burningFrom) internal {
        address tokenOwner = ownerOf(tokenId);
        // check if admin or factory are owners or tokenOwner approved msg.sender or
        // storage fee is not paid in more than a year burn if yes and minter is not tokenOwner

        if (
            ((IFactory(factory).isFactoryOperator(tokenOwner) ||
                (!isStorageFeePaid(tokenId) &&
                    (storageEndTime[tokenId] + 365 days) < block.timestamp &&
                    IFactory(factory).isFactoryOperator(burningFrom))) &&
                !_isTokenMinter(tokenOwner, tokenId)) ||
            IFactory(factory).isFactoryAdmin(burningFrom)
        ) {
            _burn(tokenId);
            delete _originalTokenOwners[tokenId];
            delete tokenBrand[tokenId];
        } else {
            revert("NBR");
        }
    }

    /// @inheritdoc ITangibleNFT
    function isStorageFeePaid(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        return storageEndTime[tokenId] > block.timestamp;
    }

    function setStoragePricePerYear(uint256 _storagePricePerYear)
        external
        onlyFactoryAdmin
    {
        // price should be higher than 1$ at least in usdc
        require(_storagePricePerYear >= 1000000, "SPL");
        if (storagePricePerYear != _storagePricePerYear) {
            emit StoragePricePerYearSet(
                storagePricePerYear,
                _storagePricePerYear
            );
            storagePricePerYear = _storagePricePerYear;
        }
    }

    function setStoragePercentPricePerYear(
        uint256 _storagePercentagePricePerYear
    ) external onlyFactoryAdmin {
        // price should be higher than 1$ at least in usdc
        require(_storagePercentagePricePerYear >= 50, "SPRL");
        if (storagePercentagePricePerYear != _storagePercentagePricePerYear) {
            emit StoragePercentagePricePerYearSet(
                storagePricePerYear,
                _storagePercentagePricePerYear
            );
            storagePercentagePricePerYear = _storagePercentagePricePerYear;
        }
    }

    /// @inheritdoc ITangibleNFT
    function adjustStorageAndGetAmount(
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) external override onlyFactory returns (uint256) {
        uint256 lastPaidDate = storageEndTime[tokenId];
        if (lastPaidDate == 0) {
            lastPaidDate = block.timestamp;
        }

        //calculate to which point storage will last
        lastPaidDate += _years * 365 days;
        storageEndTime[tokenId] = lastPaidDate;

        //amount in usdc to pay
        uint256 amount;
        if (storagePriceFixed) {
            amount = storagePricePerYear * _years;
        } else {
            require(tokenPrice > 0, "Price 0");
            amount =
                (tokenPrice * storagePercentagePricePerYear * _years) /
                10000;
        }

        emit StorageFeeToPay(tokenId, _years, amount);

        return amount;
    }

    function toggleStorageFee(bool value) external onlyFactoryAdmin {
        storagePriceFixed = value;
    }

    /// @inheritdoc ITangibleNFT
    function setBrand(uint256 tokenId, string calldata brand)
        external
        override
        onlyFactoryOrFactoryAdmin
    {
        require(approvedBrandsMap[brand], "BNA");
        tokenBrand[tokenId] = brand;
    }

    function addApprovedBrand(string calldata brand)
        external
        override
        onlyFactoryOrFactoryAdmin
    {
        require(!approvedBrandsMap[brand], "BAA");
        approvedBrands.push(brand);
        approvedBrandsMap[brand] = true;
    }

    function getApprovedBrands()
        external
        view
        override
        returns (string[] memory)
    {
        return approvedBrands;
    }

    function blacklistToken(uint256 tokenId, bool blacklisted)
        external
        onlyFactoryAdmin
    {
        blackListedTokens[tokenId] = blacklisted;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _isTokenMinter(address from, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        if (_originalTokenOwners[tokenId] == from) {
            return true;
        }
        return false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Allow operations if admin, factory or 0 address
        if (
            IFactory(factory).isFactoryAdmin(from) ||
            (factory == from) ||
            from == address(0) ||
            to == address(0)
        ) {
            return;
        }

        // we prevent transfers if storage is not paid and if from is not minter(vendor essentially)
        if (blackListedTokens[tokenId]) {
            revert("BL");
        }
        if (!isStorageFeePaid(tokenId) && !_isTokenMinter(from, tokenId)) {
            revert("CT");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./TangibleNFT.sol";
import "./interfaces/ITangibleNFTDeployer.sol";
import "./abstract/AdminAndTangibleAccess.sol";

contract TangibleNFTDeployer is ITangibleNFTDeployer, AdminAndTangibleAccess {
    address public factory;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setFactory(address _factory) external onlyAdmin {
        require(
            (_factory != address(0x0)) && (_factory != address(factory)),
            "Wrong factory"
        );

        _setupRole(FACTORY_ROLE, _factory);
        _revokeRole(FACTORY_ROLE, address(factory));
        emit SetFactoryDeployer(address(factory), _factory);
        factory = _factory;
    }

    function deployTnft(
        address admin,
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bool isStoragePriceFixedAmount
    ) external override onlyFactory returns (ITangibleNFT) {
        TangibleNFT tangibleNFT = new TangibleNFT(
            msg.sender,
            name,
            symbol,
            uri,
            isStoragePriceFixedAmount
        );
        tangibleNFT.grantRole(DEFAULT_ADMIN_ROLE, admin);
        tangibleNFT.grantRole(FACTORY_ROLE, admin);
        tangibleNFT.revokeRole(DEFAULT_ADMIN_ROLE, address(this));
        // category[name] = tangibleNFT;
        // _tnfts.push(tangibleNFT);

        // //set the oracle
        // ITangiblePriceManager(priceManager).setOracleForCategory(tangibleNFT, IPriceOracle(priceOracle));

        // emit NewCategoryDeployed(address(tangibleNFT));

        return tangibleNFT;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleNFT.sol";

interface ITangibleNFTDeployer {
    event SetFactoryDeployer(
        address indexed oldFactory,
        address indexed newFactory
    );

    function deployTnft(
        address admin,
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bool isStoragePriceFixedAmount
    ) external returns (ITangibleNFT);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./abstract/AdminAndTangibleAccess.sol";
import "./interfaces/ITangiblePriceManager.sol";

contract TangiblePriceManager is ITangiblePriceManager, AdminAndTangibleAccess {
    mapping(ITangibleNFT => IPriceOracle) public oracleForCategory;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev The function returns contract oracle for category.
    function getPriceOracleForCategory(ITangibleNFT category)
        external
        view
        override
        returns (IPriceOracle)
    {
        return oracleForCategory[category];
    }

    /// @dev The function returns current price from oracle for provided category.
    function setOracleForCategory(ITangibleNFT category, IPriceOracle oracle)
        external
        override
        onlyFactoryOrAdmin
    {
        require(address(category) != address(0), "Zero category");
        require(address(oracle) != address(0), "Zero oracle");
        oracleForCategory[category] = oracle;
        emit CategoryPriceOracleAdded(address(category), address(oracle));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./abstract/AdminAndTangibleAccess.sol";
import "./interfaces/IFactory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITangiblePriceManager.sol";
import "./interfaces/ITangibleNFTDeployer.sol";
import "./interfaces/IPriceOracle.sol";

contract Factory is AdminAndTangibleAccess, IFactory {
    using SafeERC20 for IERC20;

    IERC20 public immutable override USDC;
    address public override feeStorageAddress;
    address public override marketplace;
    address public override deployer;

    struct Vendor {
        uint128 vendorId;
        address[] categories;
    }

    mapping(string => ITangibleNFT) public override category;
    mapping(address => Vendor) public approvedVendor;
    mapping(uint128 => address) public override idToVendor;

    address[] private vendors;

    ITangibleNFT[] private _tnfts;
    ITangiblePriceManager public override priceManager;

    uint128 public _lastVendorId = 0;
    //to be used in contract upgrades
    uint128 public immutable version = 0;

    /// @dev Restricted to members of the admin role.
    constructor(
        address _usdc,
        address _feeStorageAddress,
        address _priceManager
    ) {
        require(_feeStorageAddress != address(0), "FESZ");
        require(_usdc != address(0), "UZ");
        require(_priceManager != address(0), "ZPM");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VENDOR_ROLE, msg.sender);
        _setupRole(STORAGE_OPERATOR_ROLE, msg.sender);
        // maybe add to marketplace role also?
        // adding Id for admin-vendor
        address[] memory empty;
        approvedVendor[msg.sender] = Vendor({
            vendorId: ++_lastVendorId,
            categories: empty
        });
        vendors.push(msg.sender);
        idToVendor[_lastVendorId] = msg.sender;

        USDC = IERC20(_usdc);

        feeStorageAddress = _feeStorageAddress;
        priceManager = ITangiblePriceManager(_priceManager);
        emit FeeStorageAddressSet(address(0), _feeStorageAddress);
        emit PriceManagerSet(address(0), _priceManager);
        emit ApprovedVendor(msg.sender, true);
    }

    /// @notice Sets the feeStorageAddress
    /// @dev Will emit FeeStorageAddressSet on change.
    /// @param _feeStorageAddress A new address for fee storage.
    function setFeeStorageAddress(address _feeStorageAddress)
        external
        onlyAdmin
    {
        require(_feeStorageAddress != address(0), "ZFSA");
        if (feeStorageAddress != _feeStorageAddress) {
            emit FeeStorageAddressSet(feeStorageAddress, _feeStorageAddress);
            feeStorageAddress = _feeStorageAddress;
        }
    }

    /// @notice Sets the priceManager
    /// @dev Will emit PriceManagerSet on change.
    /// @param _priceManager A new address for priceManager.
    function setPriceManager(address _priceManager) external onlyAdmin {
        require(_priceManager != address(0), "ZFSA");
        if (address(priceManager) != _priceManager) {
            emit PriceManagerSet(address(priceManager), _priceManager);
            priceManager = ITangiblePriceManager(_priceManager);
        }
    }

    /// @notice Sets the IMarketplace address
    /// @dev Will emit MarketplaceAddressSet on change.
    /// @param _marketplace A new address of the Marketplace
    function setMarketplace(address _marketplace) external onlyAdmin {
        require(_marketplace != address(0), "ZMA");
        if (marketplace != _marketplace) {
            emit MarketplaceAddressSet(marketplace, _marketplace);
            marketplace = _marketplace;
            grantRole(MARKETPLACE_ROLE, marketplace);
        }
    }

    /// @notice Sets the ITangibleNFTDeployer address
    /// @dev Will emit DeployerAddressSet on change.
    /// @param _deployer new address of the TangibleNFTDeployer
    function setDeployer(address _deployer) external onlyAdmin {
        require(
            (_deployer != address(0x0)) && (_deployer != address(deployer)),
            "Wrong deployer"
        );

        emit DeployerAddressSet(address(deployer), _deployer);
        deployer = _deployer;
    }

    function getApprovedVendorInfo(address vendor)
        external
        view
        returns (Vendor memory)
    {
        return approvedVendor[vendor];
    }

    function getCategories() external view returns (ITangibleNFT[] memory) {
        return _tnfts;
    }

    /// @inheritdoc IFactory
    function isFactoryOperator(address operator)
        external
        view
        override
        returns (bool)
    {
        return isStorageOperator(operator);
    }

    /// @inheritdoc IFactory
    function isFactoryAdmin(address admin)
        external
        view
        override
        returns (bool)
    {
        return isAdmin(admin);
    }

    function adjustStorageAndGetAmount(
        ITangibleNFT tnft,
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) external override onlyMarketplace returns (uint256) {
        return tnft.adjustStorageAndGetAmount(tokenId, _years, tokenPrice);
    }

    /// @notice Mints the TangibleNFT token from the given MintVoucher
    /// @dev Will revert if the signature is invalid.
    /// @param voucher An MintVoucher describing an unminted TangibleNFT.
    function mint(MintVoucher calldata voucher)
        external
        override
        onlyVendorOrMarketplace
        returns (uint256[] memory)
    {
        // make sure signature is valid and get the address of the vendor
        require(marketplace != address(0), "MZ");
        //make sure that vendor(who is not admin nor marketplace) is minting just for himself
        if (!isAdmin(msg.sender) && !isMarketplace(msg.sender)) {
            require(voucher.vendor == msg.sender, "MFSE");
        } else if (isMarketplace(msg.sender)) {
            require(voucher.buyer != address(0), "BMNBZ");
        }

        // first assign the token to the vendor, to establish provenance on-chain
        uint256 mintCount = isMarketplace(msg.sender) ? 1 : voucher.mintCount;

        uint256[] memory tokenIds = voucher.token.produceMultipleTNFTtoStock(
            approvedVendor[voucher.vendor].vendorId,
            mintCount,
            voucher.vendor,
            voucher.brand
        );
        emit MintedTokens(address(voucher.token), tokenIds);

        // send minted tokens to marketplace. when price is 0 - use oracle
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            IERC721(voucher.token).safeTransferFrom(
                voucher.vendor,
                marketplace,
                tokenIds[i],
                abi.encode(voucher.price)
            );
        }

        //set Vendor struct
        if (
            !_hasVendorMintedInCategory(voucher.vendor, address(voucher.token))
        ) {
            //push to array
            approvedVendor[voucher.vendor].categories.push(
                address(voucher.token)
            );
        }

        return tokenIds;
    }

    /// @notice Burns the TangibleNFT token from the given BurnVoucher
    /// @dev Will revert if the signature is invalid.
    /// @param voucher An BurnVoucher describing an minted TangibleNFT.
    function burn(BurnVoucher calldata voucher)
        external
        override
        onlyStorageOperator
    {
        // need to add some checks for revert
        voucher.token.destroyTNFTs(voucher.tokenIds, msg.sender);
    }

    function getVendors() external view override returns (address[] memory) {
        return vendors;
    }

    function approveBrandForTnft(ITangibleNFT nft, string calldata brand)
        external
        override
        onlyAdmin
    {
        nft.addApprovedBrand(brand);
    }

    function newCategory(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bool isStoragePriceFixedAmount,
        address priceOracle
    ) external override onlyAdmin returns (ITangibleNFT) {
        require(address(category[name]) == address(0), "CE");
        require(deployer != address(0), "Deployer zero");
        ITangibleNFT tangibleNFT = ITangibleNFTDeployer(deployer).deployTnft(
            msg.sender,
            name,
            symbol,
            uri,
            isStoragePriceFixedAmount
        );
        category[name] = tangibleNFT;
        _tnfts.push(tangibleNFT);

        //set the oracle
        ITangiblePriceManager(priceManager).setOracleForCategory(
            tangibleNFT,
            IPriceOracle(priceOracle)
        );

        emit NewCategoryDeployed(address(tangibleNFT));
        return tangibleNFT;
    }

    function updateOracleForTnft(string calldata name, address priceOracle)
        external
        override
        onlyAdmin
    {
        require(address(category[name]) != address(0), "CNE");
        ITangiblePriceManager(priceManager).setOracleForCategory(
            category[name],
            IPriceOracle(priceOracle)
        );
    }

    function approveVendor(address vendor, bool approved) external onlyAdmin {
        if ((approvedVendor[vendor].vendorId == 0) && approved) {
            //new vendor set new struct
            address[] memory empty;
            approvedVendor[vendor] = Vendor({
                vendorId: ++_lastVendorId,
                categories: empty
            });
            vendors.push(vendor);
            idToVendor[_lastVendorId] = vendor;
        }

        approved
            ? grantRole(VENDOR_ROLE, vendor)
            : revokeRole(VENDOR_ROLE, vendor);
        emit ApprovedVendor(vendor, approved);
    }

    function approveStorageOperator(address storageOperator, bool approved)
        external
        onlyAdmin
    {
        approved
            ? grantRole(STORAGE_OPERATOR_ROLE, storageOperator)
            : revokeRole(STORAGE_OPERATOR_ROLE, storageOperator);
        emit ApprovedStorageOperator(storageOperator, approved);
    }

    function _hasVendorMintedInCategory(address vendor, address _category)
        internal
        view
        returns (bool)
    {
        Vendor memory v = approvedVendor[vendor];
        uint256 vendorCategoriesLength = v.categories.length;
        for (uint256 i = 0; i < vendorCategoriesLength; i++) {
            if (v.categories[i] == _category) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "../helpers/Ownable.sol";
import "../interfaces/IPriceOracle.sol";

contract WineOracle is Ownable, IPriceOracle {
    /// @dev The function latest price from oracle.
    function latestAnswer(ITangibleNFT nft)
        external
        view
        override
        returns (uint256)
    {
        return 68396510000;
    }

    /// @dev The function latest price from oracle.
    uint8 public override decimals = 8;

    /// @dev The function latest price from oracle.
    string public override description = "Wine/USD";

    /// @dev The function latest price from oracle.
    uint256 public override version = 1;

    function latestTimeStamp(ITangibleNFT nft)
        external
        view
        override
        returns (uint256)
    {
        return 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IOwnable {
    function contractOwner() external view returns (address);

    function renounceOwnership() external;

    function pushOwnership(address newOwner_) external;

    function pullOwnership() external;
}

contract Ownable is IOwnable {
    address internal _contractOwner;
    address internal _newContractOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _contractOwner = msg.sender;
        emit OwnershipPushed(address(0), _contractOwner);
    }

    function contractOwner() public view override returns (address) {
        return _contractOwner;
    }

    modifier onlyOwner() {
        require(
            _contractOwner == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipPushed(_contractOwner, address(0));
        _contractOwner = address(0);
    }

    function pushOwnership(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipPushed(_contractOwner, newOwner_);
        _newContractOwner = newOwner_;
    }

    function pullOwnership() public virtual override {
        require(
            msg.sender == _newContractOwner,
            "Ownable: must be new owner to pull"
        );
        emit OwnershipPulled(_contractOwner, _newContractOwner);
        _contractOwner = _newContractOwner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "../abstract/AdminAccess.sol";
import "../interfaces/IPriceOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import "hardhat/console.sol";

contract GoldOracleTangible is AdminAccess, IPriceOracle {
    AggregatorV3Interface internal priceFeed;
    struct GoldBar {
        uint256 grams;
        uint256 premiumPercentage; //in percentage: 1234 -> 1.234 %;  50 -> 0.005 USD
    }

    event GoldBarAdded(string barName, uint256 grams, uint256 premiumPrice);

    mapping(string => GoldBar) public goldBars;

    uint256 public unz = 311034768; // 7 decimals 31.1034768gr

    constructor(address goldOracle) {
        require(goldOracle != address(0), "Empty address");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        priceFeed = AggregatorV3Interface(goldOracle);
    }

    /// @inheritdoc IPriceOracle
    function latestAnswer(ITangibleNFT nft)
        external
        view
        override
        returns (uint256)
    {
        require(goldBars[nft.name()].grams > 0, "No data for tnft");
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        if (price < 0) {
            price = 0;
        }

        uint256 priceForGrams = ((convertToOracleDecimals(
            goldBars[nft.name()].grams,
            0
        ) * uint256(price)) / convertToOracleDecimals(unz, uint8(7)));

        uint256 premium = calculatePremium(
            priceForGrams,
            goldBars[nft.name()].premiumPercentage
        );

        return priceForGrams + premium;
    }

    /// @inheritdoc IPriceOracle
    function latestTimeStamp(ITangibleNFT nft)
        external
        view
        override
        returns (uint256)
    {
        require(goldBars[nft.name()].grams > 0, "No data for tnft");
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return timeStamp;
    }

    /// @inheritdoc IPriceOracle
    function decimals() external view override returns (uint8) {
        return _decimals();
    }

    function _decimals() internal view returns (uint8) {
        return priceFeed.decimals();
    }

    /// @inheritdoc IPriceOracle
    function description() external view override returns (string memory desc) {
        return priceFeed.description();
    }

    function version() external view override returns (uint256) {
        return priceFeed.version();
    }

    function calculatePremium(uint256 price, uint256 percentage)
        internal
        view
        returns (uint256)
    {
        //percentage can have 3 decimal places
        //for example 1234 is 1.234%
        return (price * percentage) / 100000;
    }

    function convertToOracleDecimals(uint256 price, uint8 priceDecimals)
        internal
        view
        returns (uint256)
    {
        if (uint256(priceDecimals) > _decimals()) {
            return price / (10**(uint256(priceDecimals) - _decimals()));
        } else if (uint256(priceDecimals) < _decimals()) {
            return price * (10**(_decimals() - uint256(priceDecimals)));
        }
        return price;
    }

    // function pricePerGram(uint256 price) internal view returns (uint256) {
    //     uint256 alignedUnz = convertToOracleDecimals(unz, uint8(7));
    //     return price / 31;
    // }

    function addGoldBar(
        ITangibleNFT nft,
        uint256 grams,
        uint256 premiumPercentage
    ) external onlyAdmin {
        require(address(nft) != address(0), "Zero nft");
        require(grams > 0, "Zero grams");
        if (goldBars[nft.name()].grams > 0) {
            //we update
            goldBars[nft.name()].grams = grams;
            goldBars[nft.name()].premiumPercentage = premiumPercentage;
        } else {
            //we add new
            GoldBar memory gb = GoldBar({
                grams: grams,
                premiumPercentage: premiumPercentage
            });
            goldBars[nft.name()] = gb;
        }

        emit GoldBarAdded(nft.name(), grams, premiumPercentage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDCMock is ERC20("USDC", "USDC") {
    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./SafeMath.sol";
import "./Address.sol";

interface IERC20 {
  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./SafeMath.sol";

library Counters {
  using SafeMath for uint256;

  struct Counter {
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    counter._value += 1;
  }

  function decrement(Counter storage counter) internal {
    counter._value = counter._value.sub(1);
  }
}