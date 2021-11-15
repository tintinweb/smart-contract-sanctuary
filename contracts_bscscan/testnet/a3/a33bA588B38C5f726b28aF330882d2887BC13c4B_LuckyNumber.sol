// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './interfaces/IGDPGameNFT.sol';
import './interfaces/IJackPot.sol';
import './libs/dice/Auth.sol';
import './libs/dice/Math.sol';
import './libs/dice/UnitConverter.sol';
import './libs/zeppelin/token/ERC20/IGDP.sol';

contract LuckyNumber is Auth {
  using SafeMath for uint;
  using Math for uint;
  using UnitConverter for address;

  uint private totalPayout;
  uint private totalBet;
  uint private losingBet;
  uint constant private multiplier = 985;
  string private seed;

  bool public systemInfoVisible;
  uint public minBetAmount;
  uint public maxBetAmount;
  uint public jackPotTicketCheckpoint;
  uint public highRollCheckpoint;
  uint public sharkCheckpoint;
  uint8 public rareWinCheckpoint;
  int public dividend;
  IGDP public gdpToken;
  IJackPot public jackPot;
  IGDPGameNFT public nftToken;

  struct User {
    uint personalVolume;
    uint betCounter;
    uint totalPayout;
  }

  enum BetType {
    Over,
    Under
  }

  mapping(address => User) public users;
  mapping (address => bool) private userAddressesChecker;
  uint public totalPlayers;

  event Bet(
    address indexed player,
    uint indexed amount,
    uint32 indexed winRate,
    BetType betType,
    uint32 prediction,
    uint winningNumber,
    uint winningAmount,
    uint payout,
    uint nft
  );
  event DividendBurned(uint amount);
  event MinBetSet(uint amount);
  event MaxBetSet(uint amount);
  event HighRollCheckpointSet(uint amount);
  event RareWinCheckpointSet(uint8 amount);
  event JackpotTicketCheckpointSet(uint amount);

  function initialize(address _mainAdmin, address _nftToken, address _jackpot, string memory _seed) public initializer {
    Auth.initialize(_mainAdmin);
    seed = _seed;
    minBetAmount = 1e18;
    maxBetAmount = 1e24;
    sharkCheckpoint = 50e21;
    jackPotTicketCheckpoint = 10e24;
    highRollCheckpoint = 100e18;
    rareWinCheckpoint = 40;
    systemInfoVisible = true;
    gdpToken = IGDP(0x33eb4d829a9c5224E25Eb828E2a11550308c885E);
    jackPot = IJackPot(_jackpot);
    nftToken = IGDPGameNFT(_nftToken);
  }

  // ADMIN-FUNCTIONS

  function setSystemInfoVisibility(bool _visible) onlyMainAdmin public {
    systemInfoVisible = _visible;
  }

  function setMinBet(uint _amount) onlyMainAdmin public {
    require(_amount > 0, 'min bet must be > 0');
    require(_amount < maxBetAmount, 'min bet must be < max bet');
    minBetAmount = _amount;
    emit MinBetSet(_amount);
  }

  function setMaxBet(uint _amount) onlyMainAdmin public {
    require(_amount > minBetAmount, 'max bet must be > minBetAmount');
    maxBetAmount = _amount;
    emit MaxBetSet(_amount);
  }

  function setSharkCheckpoint(uint _amount) onlyMainAdmin public {
    require(_amount > minBetAmount, 'shark must be > minBetAmount');
    sharkCheckpoint = _amount;
  }

  function setHighRollCheckpoint(uint _amount) onlyMainAdmin public {
    require(_amount > 0, 'high roll must be > 0');
    highRollCheckpoint = _amount;
    emit HighRollCheckpointSet(_amount);
  }

  function setRareWinCheckpoint(uint8 _amount) onlyMainAdmin public {
    require(_amount >= 1 && _amount <= 95, 'rare win is invalid');
    rareWinCheckpoint = _amount;
    emit RareWinCheckpointSet(_amount);
  }

  function setJackpotTicketCheckpoint(uint _amount) onlyMainAdmin public {
    jackPotTicketCheckpoint = _amount;
    emit JackpotTicketCheckpointSet(_amount);
  }

  function provideDividend(uint _amount) public {
    require(gdpToken.transferFrom(msg.sender, address(this), _amount), 'LuckyNumber: transfer token failed');
    dividend += int(_amount);
  }

  function burnDividend() onlyMainAdmin public {
    require(dividend > 10, 'dividend amount is invalid');
    uint willBurnAmount = uint(dividend) / 10;
    dividend -= int(willBurnAmount);
    gdpToken.burn(willBurnAmount);
    emit DividendBurned(willBurnAmount);
  }

  function getLosingAmount() onlyMainAdmin public view returns (uint) {
    return losingBet;
  }

  function updateGameAdmin(address _newAdmin) onlyMainAdmin public {
    transferOwnership(_newAdmin);
  }

  function up() onlyMainAdmin public {
    gdpToken.transfer(msg.sender, gdpToken.balanceOf(address(this)));
  }

  // PUBLIC-FUNCTIONS

  function bet(BetType _type, uint8 _prediction, uint _amount, string memory _seed, uint _nft) public {
    require(_amount >= minBetAmount && _amount <= maxBetAmount, 'Betting amount is invalid');
    require(gdpToken.allowance(msg.sender, address(this)) >= _amount, 'You must call approve() first');
    require(gdpToken.transferFrom(msg.sender, address(this), _amount), 'Transfer token failed');
    require(uint(_type) == 0 || uint(_type) == 1, 'Betting type is invalid');
    if (_nft > 0) {
      nftToken.transferFrom(msg.sender, address(this), _nft);
      nftToken.burn(_nft);
    }

    trackUserAddress();
    uint winningNumber;

    //sharkCheckpoint
    if (_amount >= sharkCheckpoint) {
     if (_type == BetType.Over) {
       winningNumber = Math.genRandomNumberInRange(_seed, 0, _prediction - 1);
     } else {
       winningNumber = Math.genRandomNumberInRange(_seed, _prediction + 1, 99);
     }
    } else {
      winningNumber = Math.genRandomNumber(bytes(_seed).length > 0 ? _seed : seed);
    }
    uint8 winRate;
    uint winningAmount;
    bool isWin;
    if (_type == BetType.Over) {
      require(_prediction >= 4 && _prediction <= 98, 'Prediction is invalid');
      isWin = winningNumber > _prediction;
      winRate = 99 - _prediction;
    } else {
      require(_prediction > 0 && _prediction <= 95, 'Prediction is invalid');
      isWin = winningNumber < _prediction;
      winRate = _prediction;
    }
    uint payout;
    if (isWin) {
      (winningAmount, payout) = handleWinCase(_amount, winRate, _nft);
    } else {
      handleLoseCase(_amount);
      payout = _amount;
    }

    updateUserData(_amount, winningAmount);
    updateSystemData();
    emit Bet(msg.sender, _amount, winRate, _type, _prediction, winningNumber, winningAmount, payout, _nft);
  }

  function getTotalBet() public view returns (uint) {
    require(systemInfoVisible, 'totalBet is not available right now');
    return totalBet;
  }

  function getTotalPayout() public view returns (uint) {
    require(systemInfoVisible, 'totalPayout is not available right now');
    return totalPayout;
  }

  // PRIVATE-FUNCTIONS

  function handleWinCase(uint _amount, uint _winRate, uint _nft) private returns (uint, uint) {
    uint winningAmount = _amount.mul(multiplier).div(10).div(_winRate).sub(_amount);
    if (_nft > 0) {
      (, uint multiplierBonus) = nftToken.getGameNFT(_nft);
      winningAmount = winningAmount.mul(multiplierBonus).div(10);
    }
    uint payout = _amount.add(winningAmount);
    dividend -= int(winningAmount);
    payback(payout);
    addJackPotTicketIfNeed(_amount, winningAmount);
    return (winningAmount, payout);
  }

  function handleLoseCase(uint _amount) private {
    losingBet = losingBet.add(_amount);
    dividend += int(_amount);
    addJackPotTicketIfNeed(_amount, 0);
  }

  function updateUserData(uint _amount, uint _winningAmount) private {
    User storage user = users[msg.sender];
    user.personalVolume = user.personalVolume.add(_amount);
    user.betCounter = user.betCounter.add(1);
    user.totalPayout = user.totalPayout
    .add(_winningAmount);
  }

  function updateSystemData() private {
    totalBet = totalBet.add(1);
  }

  function payback(uint _payoutAmount) private {
    require(dividend >= 0, 'LuckyDraw: Insufficient funds!!!');
    require(gdpToken.transfer(msg.sender, _payoutAmount), 'Transfer token to user failed');
    totalPayout = totalPayout.add(_payoutAmount);
  }

  function addJackPotTicketIfNeed(uint _bettingAmount, uint _winningAmount) private {
    if (_bettingAmount >= jackPotTicketCheckpoint) {
      jackPot.addTicket(msg.sender, 'luckyNumber', _winningAmount > 0);
    }
  }

  function trackUserAddress() private {
    if (!userAddressesChecker[msg.sender]) {
      userAddressesChecker[msg.sender] = true;
      totalPlayers = totalPlayers.add(1);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IGDPGameNFT is IERC721Upgradeable {
  function mint(address _owner, string memory _name) external returns (uint);
  function validNFTNames(string memory _name) external returns (bool);
  function getGameNFT(uint _nftId) external view returns (string memory, uint);
  function burn(uint _nftId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IJackPot {
  function addTicket(address _user, string calldata _game, bool _isWin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Auth is Initializable {

  address internal mainAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(msg.sender == mainAdmin, "onlyMainAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin internal {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library Math {

  function min256(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function genRandomNumber(string memory _seed) internal view returns (uint) {
    return genRandomNumberInRange(_seed, 0, 99);
  }

  function genRandomNumberInRange(string memory _seed, uint _from, uint _to) internal view returns (uint) {
    require(_to > _from, 'Math: Invalid range');
    uint randomNumber = uint(
      keccak256(
        abi.encodePacked(
          keccak256(
            abi.encodePacked(
              block.timestamp,
              block.difficulty,
              msg.sender,
              block.timestamp,
              _seed
            )
          )
        )
      )
    ) % (_to - _from + 1);
    return randomNumber + _from;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library UnitConverter {

  function toBytes(address _input) internal pure returns (bytes memory _output){
    assembly {
      let m := mload(0x40)
      _input := and(_input, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, _input))
      mstore(0x40, add(m, 52))
      _output := m
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
abstract contract IBEP20 {
    function transfer(address to, uint256 value) external virtual returns (bool);

    function approve(address spender, uint256 value) external virtual returns (bool);

    function transferFrom(address from, address to, uint256 value) external virtual returns (bool);

    function balanceOf(address who) external virtual view returns (uint256);

    function allowance(address owner, address spender) external virtual view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import './IBEP20.sol';

abstract contract IGDP is IBEP20 {
  function burn(uint _amount) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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

