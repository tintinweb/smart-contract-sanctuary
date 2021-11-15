// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

interface IKetherNFT {
  function ownerOf(uint256 _tokenId) external view returns (address);

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external payable;

  function publish(
    uint256 _idx,
    string calldata _link,
    string calldata _image,
    string calldata _title,
    bool _NSFW
  ) external;
}

/**
 * @title KetherNFTLoaner
 * @dev Support loaning KetherNFT plots of ad space to others over a period of time
 */
contract KetherNFTLoaner is Ownable {
  using SafeMath for uint256;

  uint256 private constant _1ETH = 1 ether;
  uint256 public loanServiceCharge = _1ETH.div(100).mul(5);
  uint256 public loanChargePerDay = _1ETH.div(1000);
  uint8 public maxLoanDurationDays = 30;
  uint8 public loanPercentageCharge = 10;
  IKetherNFT private _ketherNft;

  struct PlotOwner {
    address owner;
    uint256 overrideLoanChargePerDay;
    uint8 overrideMaxLoanDurationDays;
  }

  struct PlotLoan {
    address loaner;
    uint256 start;
    uint256 end;
  }

  struct PublishParams {
    string link;
    string image;
    string title;
    bool NSFW;
  }

  mapping(uint256 => PlotOwner) public owners;
  mapping(uint256 => PlotLoan) public loans;

  event AddPlot(
    uint256 indexed idx,
    address owner,
    uint256 overridePerDayCharge,
    uint256 overrideMaxLoanDays
  );
  event UpdatePlot(
    uint256 indexed idx,
    uint256 overridePerDayCharge,
    uint256 overrideMaxLoanDays
  );
  event RemovePlot(uint256 indexed idx);
  event LoanPlot(uint256 indexed idx, address loaner);
  event Transfer(address to, uint256 idx);

  constructor(address _ketherNFTAddress) {
    _ketherNft = IKetherNFT(_ketherNFTAddress);
  }

  function addPlot(
    uint256 _idx,
    uint256 _overridePerDayCharge,
    uint8 _overrideMaxDays
  ) external payable {
    require(
      msg.sender == _ketherNft.ownerOf(_idx),
      'You need to be the owner of the plot to loan it out.'
    );
    require(
      msg.value >= loanServiceCharge,
      'You must send the appropriate service charge to support loaning your plot.'
    );
    payable(owner()).call{ value: msg.value }('');
    _ketherNft.transferFrom(msg.sender, address(this), _idx);
    owners[_idx] = PlotOwner({
      owner: msg.sender,
      overrideLoanChargePerDay: _overridePerDayCharge,
      overrideMaxLoanDurationDays: _overrideMaxDays
    });
    emit AddPlot(_idx, msg.sender, _overridePerDayCharge, _overrideMaxDays);
  }

  function updatePlot(
    uint256 _idx,
    uint256 _overridePerDayCharge,
    uint8 _overrideMaxDays
  ) external {
    PlotOwner storage _owner = owners[_idx];
    require(
      msg.sender == _owner.owner,
      'You must be the plot owner to update information about it.'
    );
    _owner.overrideLoanChargePerDay = _overridePerDayCharge;
    _owner.overrideMaxLoanDurationDays = _overrideMaxDays;
    emit UpdatePlot(_idx, _overridePerDayCharge, _overrideMaxDays);
  }

  function removePlot(uint256 _idx) external {
    address _owner = owners[_idx].owner;
    require(
      msg.sender == _owner,
      'You must be the original owner of the plot to remove it from the loan contract.'
    );
    require(
      !hasActiveLoan(_idx),
      'There is currently an active loan on your plot that must expire before you can remove.'
    );
    _ketherNft.transferFrom(address(this), msg.sender, _idx);
    emit RemovePlot(_idx);
  }

  function loanPlot(
    uint256 _idx,
    uint8 _numDays,
    PublishParams memory _publishParams
  ) external payable {
    require(_numDays > 0, 'You must loan the plot for at least a day.');

    PlotOwner memory _plotOwner = owners[_idx];
    PlotLoan memory _loan = loans[_idx];
    require(_loan.end < block.timestamp, 'Plot is currently being loaned.');

    _ensureValidLoanDays(_plotOwner, _numDays);
    _ensureValidLoanCharge(_plotOwner, _numDays);

    uint256 _serviceCharge = msg.value.mul(uint256(loanPercentageCharge)).div(
      100
    );
    uint256 _plotOwnerCharge = msg.value.sub(_serviceCharge);

    payable(owner()).call{ value: _serviceCharge }('');
    payable(_plotOwner.owner).call{ value: _plotOwnerCharge }('');

    loans[_idx] = PlotLoan({
      loaner: msg.sender,
      start: block.timestamp,
      end: block.timestamp.add(_daysToSeconds(_numDays))
    });
    _publish(_idx, _publishParams);
    emit LoanPlot(_idx, msg.sender);
  }

  function publish(uint256 _idx, PublishParams memory _publishParams) external {
    PlotOwner memory _owner = owners[_idx];
    PlotLoan memory _loan = loans[_idx];

    bool _hasActiveLoan = hasActiveLoan(_idx);
    if (_hasActiveLoan) {
      require(
        msg.sender == _loan.loaner,
        'Must be the current loaner to update published information.'
      );
    } else {
      require(
        msg.sender == _owner.owner,
        'Must be the owner to update published information.'
      );
    }

    _publish(_idx, _publishParams);
  }

  function transfer(address _to, uint256 _idx) external {
    PlotOwner storage _owner = owners[_idx];
    require(
      msg.sender == _owner.owner,
      'You must own the current plot to transfer it.'
    );
    _owner.owner = _to;
    emit Transfer(_to, _idx);
  }

  function hasActiveLoan(uint256 _idx) public view returns (bool) {
    PlotLoan memory _loan = loans[_idx];
    if (_loan.loaner == address(0)) {
      return false;
    }
    return _loan.end > block.timestamp;
  }

  function setLoanServiceCharge(uint256 _amountWei) external onlyOwner {
    loanServiceCharge = _amountWei;
  }

  function setLoanChargePerDay(uint256 _amountWei) external onlyOwner {
    loanChargePerDay = _amountWei;
  }

  function setMaxLoanDurationDays(uint8 _numDays) external onlyOwner {
    maxLoanDurationDays = _numDays;
  }

  function setLoanPercentageCharge(uint8 _percentage) external onlyOwner {
    require(_percentage <= 100, 'Must be between 0 and 100');
    loanPercentageCharge = _percentage;
  }

  function _daysToSeconds(uint256 _days) private pure returns (uint256) {
    return _days.mul(24).mul(60).mul(60);
  }

  function _ensureValidLoanDays(PlotOwner memory _owner, uint8 _numDays)
    private
    view
  {
    uint8 _maxNumDays = _owner.overrideMaxLoanDurationDays > 0
      ? _owner.overrideMaxLoanDurationDays
      : maxLoanDurationDays;
    require(
      _numDays <= _maxNumDays,
      'You cannot loan this plot for this long.'
    );
  }

  function _ensureValidLoanCharge(PlotOwner memory _owner, uint8 _numDays)
    private
    view
  {
    uint256 _perDayCharge = _owner.overrideLoanChargePerDay > 0
      ? _owner.overrideLoanChargePerDay
      : loanChargePerDay;
    uint256 _loanCharge = _perDayCharge.mul(uint256(_numDays));
    require(
      msg.value >= _loanCharge,
      'Make sure you send the appropriate amount of ETH to process your loan.'
    );
  }

  function _publish(uint256 _idx, PublishParams memory _publishParams) private {
    _ketherNft.publish(
      _idx,
      _publishParams.link,
      _publishParams.image,
      _publishParams.title,
      _publishParams.NSFW
    );
  }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

