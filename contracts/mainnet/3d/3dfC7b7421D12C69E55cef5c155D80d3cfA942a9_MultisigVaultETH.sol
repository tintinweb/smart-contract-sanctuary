/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract MultisigVaultETH {

    using SafeMath for uint256;

    struct Approval {
        uint256 nonce;
        uint256 coincieded;
        address[] coinciedeParties;
    }

    uint256 private participantsAmount;
    uint256 private signatureMinThreshold;
    uint256 private nonce;

    string  private _symbol;
    uint8   private _decimals;

    address constant public ETHER_ADDRESS = address(0x1);

    mapping(address => bool) public parties;

    mapping(
        // Destination
        address => mapping(
            // Amount
            uint256 => Approval
        )
    ) public approvals;

    mapping(uint256 => bool) public finished;

    event ConfirmationReceived(address indexed from, address indexed destination, address currency, uint256 amount);
    event ConsensusAchived(address indexed destination, address currency, uint256 amount);

    /**
      * @dev Construcor.
      *
      * Requirements:
      * - `_signatureMinThreshold` .
      * - `_parties`.
      */
    constructor(
        uint256 _signatureMinThreshold,
        address[] memory _parties
    ) public {
        require(_parties.length > 0 && _parties.length <= 10);
        require(_signatureMinThreshold > 0 && _signatureMinThreshold <= _parties.length);

        signatureMinThreshold = _signatureMinThreshold;

        _symbol = "ETH";
        _decimals = 18;

        for (uint256 i = 0; i < _parties.length; i++) parties[_parties[i]] = true;
    }

    modifier isMember() {
        require(parties[msg.sender]);
        _;
    }

    modifier sufficient(uint256 _amount) {
        // https://biboknow.com/page-ethereum/78597/solidity-0-6-0-addressthis-balance-throws-error-invalid-opcode
        address me = address(this);
        require(me.balance >= _amount);
        _;
    }

    function getNonce(
        address _destination,
        uint256 _amount
    ) public view returns (uint256) {
        Approval storage approval = approvals[_destination][_amount];

        return approval.nonce;
    }

    function partyCoincieded(
        address _destination,
        uint256 _amount,
        uint256 _nonce,
        address _partyAddress
    ) public view returns (bool) {
        if ( finished[_nonce] ) {
          return true;
        } else {
          Approval storage approval = approvals[_destination][_amount];

          for (uint i=0; i<approval.coinciedeParties.length; i++) {
             if (approval.coinciedeParties[i] == _partyAddress) return true;
          }

          return false;
        }
    }

    // https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage
    function approve(
        address payable _destination,
        uint256 _amount
    ) public isMember sufficient(_amount) returns (bool) {
        Approval storage approval = approvals[_destination][_amount]; // Create new project

        bool coinciedeParties = false;
        for (uint i=0; i<approval.coinciedeParties.length; i++) {
           if (approval.coinciedeParties[i] == msg.sender) coinciedeParties = true;
        }

        require(!coinciedeParties);

        if (approval.coincieded == 0) {
            nonce += 1;
            approval.nonce = nonce;
        }

        approval.coinciedeParties.push(msg.sender);
        approval.coincieded += 1;

        emit ConfirmationReceived(msg.sender, _destination, ETHER_ADDRESS, _amount);

        if ( approval.coincieded >= signatureMinThreshold ) {
            _destination.transfer(_amount);    // Release

            finished[approval.nonce] = true;
            delete approvals[_destination][_amount];

            emit ConsensusAchived(_destination, ETHER_ADDRESS, _amount);
        }

        return true;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function() external payable { }
}