/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity ^0.5.0;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * Counterpart to Solidity&#39;s `-` operator.
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
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
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

// File: contracts/MultisigVaultETH.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract MultisigVaultETH {

    using SafeMath for uint256;

    struct Approval {
        bool transfered;
        uint256 coincieded;
        mapping(address => bool) coinciedeParties;
    }

    uint256 private participantsAmount;
    uint256 private signatureMinThreshold;
    address payable private serviceAddress;
    uint256 private serviceFeeMicro;

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

    event ConfirmationReceived(address indexed from, address indexed destination, address currency, uint256 amount);
    event ConsensusAchived(address indexed destination, address currency, uint256 amount);

    /**
      * @dev Construcor.
      *
      * Requirements:
      * - `_signatureMinThreshold` .
      * - `_parties`.
      * - `_serviceAddress`.
      * - `_serviceFeeMicro` represented by integer amount of million&#39;th fractions.
      */
    constructor(
        uint256 _signatureMinThreshold,
        address[] memory _parties,
        address payable _serviceAddress,
        uint256 _serviceFeeMicro
    ) public {
        require(_parties.length > 0 && _parties.length <= 10);
        require(_signatureMinThreshold > 0 && _signatureMinThreshold <= _parties.length);

        signatureMinThreshold = _signatureMinThreshold;
        serviceAddress = _serviceAddress;
        serviceFeeMicro = _serviceFeeMicro;

        _symbol = "ETH";
        _decimals = 18;

        for (uint256 i = 0; i < _parties.length; i++) parties[_parties[i]] = true;
    }

    modifier isMember() {
        require(parties[msg.sender]);
        _;
    }

    modifier sufficient(uint256 _amount) {
        require(address(this).balance >= _amount);
        _;
    }

    function partyCoincieded(
        address _destination,
        uint256 _amount,
        address _partyAddress
    ) public view returns (bool) {
        Approval storage approval = approvals[_destination][_amount];
        return approval.coinciedeParties[_partyAddress];
    }

    // https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage
    function approve(
        address payable _destination,
        uint256 _amount
    ) public isMember sufficient(_amount) returns (bool) {
        Approval storage approval  = approvals[_destination][_amount]; // Create new project

        if (!approval.coinciedeParties[msg.sender]) {
            approval.coinciedeParties[msg.sender] = true;
            approval.coincieded += 1;

            emit ConfirmationReceived(msg.sender, _destination, ETHER_ADDRESS, _amount);

            if (
                approval.coincieded >= signatureMinThreshold &&
                !approval.transfered
            ) {
                approval.transfered = true;

                uint256 _amountToWithhold = _amount.mul(serviceFeeMicro).div(1000000);
                uint256 _amountToRelease = _amount.sub(_amountToWithhold);

                _destination.transfer(_amountToRelease);    // Release funds
                serviceAddress.transfer(_amountToWithhold); // Take service margin

                emit ConsensusAchived(_destination, ETHER_ADDRESS, _amount);
            }

            return true;
        } else {
            // Raise will eat rest of gas. Lets not waist it. Just record this approval instead
            return false;
        }
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function() external payable { }
}