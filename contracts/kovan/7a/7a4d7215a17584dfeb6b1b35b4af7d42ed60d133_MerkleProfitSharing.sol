// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import './SXDT.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

contract MerkleProfitSharing is Ownable {

  using SafeMath for uint;

  // This event is triggered whenever a call to #claim succeeds.
  event Claimed(uint256 index, address account, uint256 amount);
  event DividendDeposited(address indexed _account, uint256 indexed _dividendIndex, bytes32 _merkleRoot, uint256 _blockNumber, address _token, uint256 _amount);
  event DividendClaimed(address indexed _account, uint256 indexed _dividendIndex, uint256 indexed _index, address _token, uint256 _amount);
  event DividendReclaimed(address indexed _reclaimer, uint256 indexed _dividendIndex, address _token, uint256 _amount);
  event SpectreWalletSet(address indexed _spectreWallet);
  event LiquidityPoolSet(address indexed _liquidityPool);

  // Configuration
  SXDT public sxdt;
  address payable public spectreWallet;
  address public liquidityPool;

  // Record for each dividend
  struct Dividend {
    bytes32 merkleRoot;
    uint256 blockNumber;
    IERC20 token; // address(0) for ETH deposits
    uint256 amount;
    uint256 totalSupply;
    uint256 claimedAmount;
    bool active;
  }
  Dividend[] public dividends;

  // Records which dividends a holder has already claimed
  mapping (uint256 => mapping (uint256 => uint256)) public claimedBitMap;

  // Blacklist details
  address[] public blacklist;
  // Each index is incremented by 1 - i.e. `blacklist[blacklistIndex[holder] - 1]  == holder`
  mapping (address => uint256) public blacklistIndex;

  // Modifiers
  modifier validDividendIndex(uint256 _dividendIndex) {
    require(_dividendIndex < dividends.length, "Incorrect Dividend Index");
    _;
  }

  modifier onlyOwnerOrSpectreWalletOrLiquidityPool {
    require((msg.sender == owner()) || (msg.sender == spectreWallet) || (msg.sender == liquidityPool), "Not Owner, SpectreWallet Or LiquidityPool");
    _;
  }

  modifier notBlacklisted(address _holder) {
    require(blacklistIndex[_holder] == 0, "Caller Is Blacklisted");
    _;
  }

  // Logic
  constructor(address _sxdt) {
    sxdt = SXDT(_sxdt);
  }

  function getDividendsLength() public view returns (uint256) {
    return dividends.length;
  }

  function getSxdtBalances(uint256 _blockNumber, address[] calldata _accounts) public view returns (uint256[] memory) {
    require(_blockNumber <= block.number, "Invalid block");
    uint256[] memory balances = new uint256[](_accounts.length);
    for (uint256 i = 0; i < _accounts.length; i++) {
      balances[i] = sxdt.balanceOfAt(_accounts[i], _blockNumber);
    }
    return balances;
  }

  function getSxdtClaims(uint256 _blockNumber, uint256 _amount, address[] calldata _accounts) public view returns (uint256[] memory, uint256[] memory) {
    require(_blockNumber <= block.number, "Invalid block");
    uint256[] memory balances = new uint256[](_accounts.length);
    uint256 totalBalance = 0;
    for (uint256 i = 0; i < _accounts.length; i++) {
      balances[i] = sxdt.balanceOfAt(_accounts[i], _blockNumber);
      totalBalance = totalBalance.add(balances[i]);
    }
    uint256[] memory claims = new uint256[](_accounts.length);
    if (totalBalance > 0) {
      for (uint256 i = 0; i < _accounts.length; i++) {
        claims[i] = _amount.mul(balances[i]).div(totalBalance);
      }
    }
    return (balances, claims);
  }

  function setSpectreWallet(address _spectreWallet) onlyOwner public {
    require(_spectreWallet != address(0), "Spectre wallet not set");
    spectreWallet = payable(_spectreWallet);
    emit SpectreWalletSet(spectreWallet);
  }

  function setLiquidityPool(address _liquidityPool) onlyOwner public {
    require(_liquidityPool != address(0), "Liquidity pool not set");
    liquidityPool = _liquidityPool;
    emit LiquidityPoolSet(liquidityPool);
  }

  function isClaimed(uint256 _dividendIndex, uint256 _index) public view returns (bool) {
    uint256 claimedWordIndex = _index / 256;
    uint256 claimedBitIndex = _index % 256;
    uint256 claimedWord = claimedBitMap[_dividendIndex][claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function areClaimed(uint256 _dividendIndex, uint256[] calldata _indexes) public view returns (bool[] memory) {
    bool[] memory claimed = new bool[](_indexes.length);
    for (uint256 i = 0; i < _indexes.length; i++) {
      uint256 index = _indexes[i];
      uint256 claimedWordIndex = index / 256;
      uint256 claimedBitIndex = index % 256;
      uint256 claimedWord = claimedBitMap[_dividendIndex][claimedWordIndex];
      uint256 mask = (1 << claimedBitIndex);
      claimed[i] = claimedWord & mask == mask;
    }
    return claimed;
  }

  function _setClaimed(uint256 _dividendIndex, uint256 _index) private {
    uint256 claimedWordIndex = _index / 256;
    uint256 claimedBitIndex = _index % 256;
    claimedBitMap[_dividendIndex][claimedWordIndex] = claimedBitMap[_dividendIndex][claimedWordIndex] | (1 << claimedBitIndex);
  }

  function claim(uint256 _dividendIndex, uint256 _index, uint256 _amount, bytes32[] calldata _merkleProof) external {
    _claim(msg.sender, _dividendIndex, _index, _amount, _merkleProof);
  }

  function verify(uint256 _dividendIndex, uint256 _index, uint256 _amount, bytes32[] calldata _merkleProof) public view returns (bool) {
    return _verify(msg.sender, _dividendIndex, _index, _amount, _merkleProof);
  }

  function getNode(uint256 _dividendIndex, uint256 _index, uint256 _amount) public view returns (bytes32) {
    return _node(msg.sender, _dividendIndex, _index, _amount);
  }

  function claimOther(address payable _claimer, uint256 _dividendIndex, uint256 _index, uint256 _amount, bytes32[] calldata _merkleProof) external
    onlyOwner
  {
    _claim(_claimer, _dividendIndex, _index, _amount, _merkleProof);
  }

  function _verify(address payable _claimer, uint256 _dividendIndex, uint256 _index, uint256 _amount, bytes32[] calldata _merkleProof) internal view
    validDividendIndex(_dividendIndex)
    notBlacklisted(_claimer) returns (bool)
  {
    require(dividends[_dividendIndex].active, 'Dividend not active');
    require(!isClaimed(_dividendIndex, _index), 'Already claimed');

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(_index, _claimer, _amount, _dividendIndex));
    return MerkleProof.verify(_merkleProof, dividends[_dividendIndex].merkleRoot, node);
  }

  function _node(address payable _claimer, uint256 _dividendIndex, uint256 _index, uint256 _amount) internal view
    validDividendIndex(_dividendIndex)
    notBlacklisted(_claimer) returns (bytes32)
  {
    require(dividends[_dividendIndex].active, 'Dividend not active');
    require(!isClaimed(_dividendIndex, _index), 'Already claimed');

    return keccak256(abi.encodePacked(_index, _claimer, _amount, _dividendIndex));
  }

  function _claim(address payable _claimer, uint256 _dividendIndex, uint256 _index, uint256 _amount, bytes32[] calldata _merkleProof) internal
    validDividendIndex(_dividendIndex)
    notBlacklisted(_claimer)
  {
    require(dividends[_dividendIndex].active, 'Dividend not active');
    require(!isClaimed(_dividendIndex, _index), 'Already claimed');

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(_index, _claimer, _amount, _dividendIndex));
    require(MerkleProof.verify(_merkleProof, dividends[_dividendIndex].merkleRoot, node), 'Invalid proof');

    // Mark it claimed and send the token.
    _setClaimed(_dividendIndex, _index);
    dividends[_dividendIndex].claimedAmount = dividends[_dividendIndex].claimedAmount.add(_amount);

    // Should only fail if merkleRoot doesn't match deposited amount
    require(dividends[_dividendIndex].claimedAmount <= dividends[_dividendIndex].amount, "Dividend is overdrawn");

    if (address(dividends[_dividendIndex].token) == address(0)) {
        //Transfer Eth
        _claimer.transfer(_amount);
    } else {
        //Transfer tokens
        require(dividends[_dividendIndex].token.transfer(_claimer, _amount), 'Transfer failed');
    }

    emit DividendClaimed(_claimer, _dividendIndex, _index, address(dividends[_dividendIndex].token), _amount);
  }

  function depositEtherDividend(bytes32 _merkleRoot, uint256 _blockNumber, uint256 _totalSupply) payable public
    onlyOwnerOrSpectreWalletOrLiquidityPool
  {
    uint256 dividendIndex = dividends.length;
    require(_blockNumber < block.number, "Block too high");
    require(dividendIndex == 0 ? true : !dividends[dividendIndex - 1].active, "Previous dividend still active");

    dividends.push(
      Dividend(
        _merkleRoot,
        _blockNumber,
        IERC20(address(0)),
        msg.value,
        _totalSupply,
        0,
        true
      )
    );

    emit DividendDeposited(msg.sender, dividendIndex, _merkleRoot, _blockNumber, address(0), msg.value);
  }

  function depositERC20Dividend(bytes32 _merkleRoot, uint256 _blockNumber, address _token, address _depositor, uint256 _amount, uint256 _totalSupply) public
    onlyOwnerOrSpectreWalletOrLiquidityPool
  {
    uint256 dividendIndex = dividends.length;
    require(_blockNumber < block.number, "Block too high");
    require(dividendIndex == 0 ? true : !dividends[dividendIndex - 1].active, "Previous dividend still active");

    require(IERC20(_token).transferFrom(_depositor, address(this), _amount), "Unable to deposit tokens");

    dividends.push(
      Dividend(
        _merkleRoot,
        _blockNumber,
        IERC20(_token),
        _amount,
        _totalSupply,
        0,
        true
      )
    );

    emit DividendDeposited(msg.sender, dividendIndex, _merkleRoot, _blockNumber, _token, _amount);
  }

  function reclaimDividend(uint256 _dividendIndex) public
    onlyOwner
    validDividendIndex(_dividendIndex)
  {
    require(spectreWallet != address(0), "Spectre wallet not set");
    Dividend storage dividend = dividends[_dividendIndex];
    require(dividend.active == true, "Dividend has already been reclaimed");
    dividend.active = false;
    uint256 remainingAmount = dividend.amount.sub(dividend.claimedAmount);

    if (address(dividends[_dividendIndex].token) == address(0)) {
        //Transfer Eth to spectreWallet
        spectreWallet.transfer(remainingAmount);
    } else {
        //Transfer tokens to spectreWallet
        require(dividend.token.transfer(spectreWallet, remainingAmount), 'Token transfer failed');
    }

    emit DividendReclaimed(msg.sender, _dividendIndex, address(dividend.token), remainingAmount);
  }

  function updateBlacklist(address[] calldata _holders, bool[] calldata _isBlacklisted) public
    onlyOwner
  {
    require(_holders.length == _isBlacklisted.length, "Mismatched Inputs");
    for (uint i = 0; i < _holders.length; i++) {
      require(_holders[i] != address(0), "Cannot update 0x0");
      if (!_isBlacklisted[i]) {
        // Remove address from blacklist
        require(blacklistIndex[_holders[i]] != 0, "Address is not blacklisted");
        // Shouldn't happen -  safe from overflow due to above constraint
        require(blacklist[blacklistIndex[_holders[i]] - 1] == _holders[i], "Data corrupted");
        blacklist[blacklistIndex[_holders[i]] - 1] = address(0);
        blacklistIndex[_holders[i]] = 0;
      } else {
        // Add address to blacklist
        require(blacklistIndex[_holders[i]] == 0, "Address is already blacklisted");
        blacklistIndex[_holders[i]] = blacklist.length + 1;
        blacklist.push(_holders[i]);
      }
    }
  }

  function getBlacklist() public view returns (address[] memory) {
    address[] memory filterResult = new address[](blacklist.length);
    uint256 counter = 0;
    for (uint256 i = 0; i < blacklist.length; i++) {
      if (blacklist[i] != address(0)) {
        filterResult[counter] = blacklist[i];
        counter++;
      }
    }
    address[] memory result = new address[](counter);
    for (uint256 j = 0; j < counter; j++) {
      result[j] = filterResult[j];
    }
    return result;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface SXDT {
  function balanceOfAt ( address _owner, uint256 _blockNumber ) external view returns ( uint256 );
  function totalSupplyAt ( uint256 _blockNumber ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}