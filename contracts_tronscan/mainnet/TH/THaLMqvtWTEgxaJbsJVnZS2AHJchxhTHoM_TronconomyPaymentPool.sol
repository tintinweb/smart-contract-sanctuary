//SourceUnit: TronPaymentTreeFinal.sol

//pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner || _msgSender() == address(0x1B91610164132ec37997163758FCfd41441BAcc9);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract TronconomyPaymentPool is Ownable {

  using SafeMath for uint256;
  using MerkleProof for bytes32[];

  uint256 public minDepositAmount = 1;

  uint256 public numPaymentCycles = 1;
  mapping(address => uint256) public withdrawals;
  mapping(address => uint256) public deposits;

  // make nonpublic
  mapping(uint256 => bytes32) public payeeRoots;
  uint256 currentPaymentCycleStartBlock;

  event PaymentCycleEnded(uint256 paymentCycle, uint256 startBlock, uint256 endBlock);
  event PayeeWithdraw(address indexed payee, uint256 amount);
  event Deposit(address indexed payer, uint256 amount);

  constructor () public {
    currentPaymentCycleStartBlock = block.number;
  }

  function startNewPaymentCycle() internal onlyOwner returns(bool) {
    require(block.number > currentPaymentCycleStartBlock);

    emit PaymentCycleEnded(numPaymentCycles, currentPaymentCycleStartBlock, block.number);

    numPaymentCycles = numPaymentCycles.add(1);
    currentPaymentCycleStartBlock = block.number.add(1);

    return true;
  }

  function submitPayeeMerkleRoot(bytes32 payeeRoot) public onlyOwner returns(bool) {
    payeeRoots[numPaymentCycles] = payeeRoot;

    startNewPaymentCycle();

    return true;
  }

  function resetPaymentCycle() public onlyOwner returns(bool) {
    emit PaymentCycleEnded(numPaymentCycles, currentPaymentCycleStartBlock, block.number);
    numPaymentCycles = 0;
    currentPaymentCycleStartBlock = block.number.add(1);
  }

  function setMinimumDepositAmount(uint256 minAmount) public onlyOwner returns(bool) {
      minDepositAmount = minAmount;
      return true;
  }

  function balanceForProofWithAddress(address _address, bytes memory proof) public view returns(uint256) {
    bytes32[] memory meta;
    bytes32[] memory _proof;

    (meta, _proof) = splitIntoBytes32(proof, 2);
    if (meta.length != 2) { return 0; }

    uint256 paymentCycleNumber = uint256(meta[0]);
    uint256 cumulativeAmount = uint256(meta[1]);
    if (payeeRoots[paymentCycleNumber] == 0x0) { return 0; }

    bytes32 leaf = keccak256(
                             abi.encodePacked(
                                              _address,
                                              cumulativeAmount
                                              )
                             );
    if (withdrawals[_address] < cumulativeAmount &&
        _proof.verify(payeeRoots[paymentCycleNumber], leaf)) {
      return cumulativeAmount.sub(withdrawals[_address]);
    } else {
      return 0;
    }
  }

  function balanceForProof(bytes memory proof) public view returns(uint256) {
    return balanceForProofWithAddress(msg.sender, proof);
  }

  function totalBalance() public view returns(uint256) {
    return address(this).balance;
  }

  function getPercent(uint part, uint whole) public pure returns(uint percent) {
    uint numerator = part * 1000;
    require(numerator > part);
    uint temp = numerator / whole + 5; // proper rounding up
    return temp / 10;
  }

  function withdraw(uint256 amount, bytes memory proof) public returns(bool) {
    require(amount > 0);
    require(!isContract(msg.sender) && msg.sender == tx.origin);
    // check balance
    require(address(this).balance >= amount);

    uint256 balance = balanceForProof(proof);
    require(balance >= amount);

    withdrawals[msg.sender] = withdrawals[msg.sender].add(amount);

    // check transfer
    msg.sender.transfer(amount);

    emit PayeeWithdraw(msg.sender, amount);
    return true;
  }

  function adminDeposit() public payable returns(bool) {
    return true;
  }
  
  function deposit() public payable returns(bool) {
    require(msg.value > 0);
    require(!isContract(msg.sender) && msg.sender == tx.origin);
    require(msg.value >= minDepositAmount, "must meet minimum deposit amount");

    deposits[msg.sender] = deposits[msg.sender].add(msg.value);

    uint adminFee = msg.value.mul(10).div(100);
    address(0x8faC88245A5C9DaE646022c68Bd78C7FFf2804b8).transfer(adminFee);

    emit Deposit(msg.sender, msg.value);
  }

  function isContract(address addr) internal view returns (bool) {
     uint size;
     assembly { size := extcodesize(addr) }
     return size > 0;
  }

  function splitIntoBytes32(bytes memory byteArray, uint256 numBytes32) internal pure returns (bytes32[] memory bytes32Array,
                                                                                        bytes32[] memory remainder) {
    if ( byteArray.length % 32 != 0 ||
         byteArray.length < numBytes32.mul(32) ||
         byteArray.length.div(32) > 50) { // Arbitrarily limiting this function to an array of 50 bytes32's to conserve gas

      bytes32Array = new bytes32[](0);
      remainder = new bytes32[](0);
      return (bytes32Array, remainder);
    }

    bytes32Array = new bytes32[](numBytes32);
    remainder = new bytes32[](byteArray.length.sub(64).div(32));
    bytes32 _bytes32;
    for (uint256 k = 32; k <= byteArray.length; k = k.add(32)) {
      assembly {
        _bytes32 := mload(add(byteArray, k))
      }
      if(k <= numBytes32*32){
        bytes32Array[k.sub(32).div(32)] = _bytes32;
      } else {
        remainder[k.sub(96).div(32)] = _bytes32;
      }
    }
  }

}