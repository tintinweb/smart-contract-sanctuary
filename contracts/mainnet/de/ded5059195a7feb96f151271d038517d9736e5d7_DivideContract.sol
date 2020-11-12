// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/DivideContract.sol

pragma solidity >=0.5.10 <0.6.0;



contract DivideContract {
  using SafeMath for uint256;

  address owner;
  mapping(address => bool) operators;
  uint256 public NUM_RECIPIENTS = 2;
  uint256 public PRECISION = 10000;
  RecipientList recipientList;
  address public nftAddress;

  struct RecipientList {
    address payable[] available_recipients;
    uint256[] ratios;
  }

  event OperatorChanged(
    address indexed operator,
    bool action
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 amount,
    uint256 totalAmount
  );

  event RecipientsInfoChanged(
    bool action,
    address payable[] recipients,
    uint256[] ratios
  );

  modifier isOwner() {
    require(msg.sender == owner, 'No permissions');
    _;
  }

  modifier isOperator() {
    require(operators[msg.sender] || msg.sender == owner, 'No permissions');
    _;
  }

  constructor(address _nftAddress) public {
    require(_nftAddress != address(0)); // Do not allow 0 addresses
    owner = msg.sender;
    nftAddress = _nftAddress;
  }

  // Calculate the sum of an array
  function arraySum(uint256[] memory data) private pure returns (uint256) {
    uint256 res;
    for (uint256 i; i < data.length; i++) {
      res = res.add(data[i]);
    }
    return res;
  }

  function getOwner() public view returns (address) {
    return owner;
  }

  // Check if operator is in mapping for js tests
  function operatorExists (address entity) public view returns (bool) {
    return operators[entity];
  }

  function assignOperator (address entity) public isOwner() {
    require(entity != address(0), 'Target is invalid addresses');
    require(!operatorExists(entity), 'Target is already an operator');
    emit OperatorChanged(entity, true);
    operators[entity] = true;
  }

  function removeOperator (address entity) public isOwner() {
    require(entity != address(0), 'Target is invalid addresses');
    require(operatorExists(entity), 'Target is not an operator');
    emit OperatorChanged(entity, false);
    operators[entity] = false;
  }

  // Save all recipients and their corresponding ratios
  // In: array of recipients, integer array of ratios
  function registerRecipientsInfo (address payable[] memory recipients, uint256[] memory ratio) public isOperator() returns (bool) {
    require(arraySum(ratio) == PRECISION, 'Total sum of ratio must be 100%');
    require(recipients.length == ratio.length, 'Incorrect data size');
    require(recipients.length == NUM_RECIPIENTS, 'Incorrect number of recipients');

    recipientList = RecipientList(recipients, ratio);
    emit RecipientsInfoChanged(true, recipients, ratio);
    return true;
  }

  // Get info about nft platform recipients
  // Out: nft platfor address, available recipients, ratios
  function getRecipientsInfo() public view isOperator() returns (address, address payable[] memory, uint256[] memory) {
    return (nftAddress, recipientList.available_recipients, recipientList.ratios);
  }

  function deleteRecipientsInfo () public isOperator() {
    require(recipientList.available_recipients.length > 0, 'No recipients registered');
    emit RecipientsInfoChanged(false, recipientList.available_recipients, recipientList.ratios);
    delete recipientList;
  }

  function calculateAmount(uint256 fee_received, uint256 ratio) private view returns (uint256) {
    return (fee_received.mul(ratio).div(PRECISION));
  }


  // Divides any ether coming to this contract by their ratios and send the amounts to each recipient.
  // Last recipient gets also everything that was left by division errors
  function () external payable {
    require(recipientList.available_recipients.length == NUM_RECIPIENTS, 'No recipients registered');

    uint256 amount1 = calculateAmount(msg.value, recipientList.ratios[0]);
    address payable toWallet1 = recipientList.available_recipients[0];
    toWallet1.transfer(amount1);
    emit Transfer(msg.sender, toWallet1, amount1, msg.value);

    // Send all what is left to last recipient to avoid stuck ether
    uint256 amount2 = address(this).balance;
    address payable toWallet2 = recipientList.available_recipients[1];
    toWallet2.transfer(amount2);
    emit Transfer(msg.sender, toWallet2, amount2, msg.value);
  }
}