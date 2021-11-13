pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

// The contract has not been gas optimized and is intended only for demo purposes.
contract NameRegistry {
    using SafeMath for uint256;

    enum RegistrationStatus {
        UNUSED,
        REQUESTED,
        REGISTERED
    }

    enum RegistrationState {
        UNUSED,
        REQUESTED,
        REGISTERED,
        EXPIRED
    }

    struct NameRegistration {
        bool preImageExists;
        string image; // using string for ease of reviewer to view everything on etherscan/polygonscan easily. bytes are preferred
        uint256 expiry;
        RegistrationStatus status;
        address owner;
    }

    uint256 public constant maxNameLength = 100; // length of name is set to max 100 (for easier calculation)
    uint256 public constant registrationCostPerCharacter = 10000000000000000; // 0.01 ETH/MATIC
    uint256 public constant lockInAmount = 250000000000000000; // 0.25 ETH/MATIC

    // the number has not been declared as constant for reviewers to avoid confusion. It can ideally be declared as constant to save gas
    uint256 public amountRequiredToInitiateRegistration = lockInAmount.add(maxNameLength.mul(registrationCostPerCharacter));

    uint256 public constant registrationTime = 1 days;
    uint256 public constant renewTime = 2 hours; // use can start renewing registration 2 hours before expiry

    mapping(bytes32 => NameRegistration) public nameRegistry;
    mapping(address => uint256) public claimableAmount; // amount that can be claimed in case there is a ownership transfer, This is done to avoid push to transfer to external address

    event InitiateRegistration(bytes32 indexed preImage, address indexed owner);
    event ConfirmRegistration(bytes32 indexed preImage);
    event RegistrationRenewed(bytes32 indexed preImage);
    event TransferOwnership(bytes32 indexed preImage);

    // time dependent function that returns the state of
    function getState(bytes32 preImage) public view returns (RegistrationState) {
        if (!nameRegistry[preImage].preImageExists) {
            return RegistrationState.UNUSED;
        } else if (nameRegistry[preImage].status == RegistrationStatus.REQUESTED) {
            return RegistrationState.REQUESTED;
        } else if (nameRegistry[preImage].status == RegistrationStatus.REGISTERED && nameRegistry[preImage].expiry > block.timestamp) {
            return RegistrationState.REGISTERED;
        } else {
            return RegistrationState.EXPIRED;
        }
    }
    
    function requestRegistration(bytes32 preImage) public payable {
        require(getState(preImage) == RegistrationState.UNUSED, 'NameRegistry: Only unused image can be requested for registration');
        nameRegistry[preImage].status = RegistrationStatus.REQUESTED;
        nameRegistry[preImage].owner = msg.sender;
        nameRegistry[preImage].preImageExists = true;
        require(
            msg.value >= amountRequiredToInitiateRegistration,
            'NameRegistry: User should send minimum fund for requesting registration'
        );
        uint256 remainingAmount = msg.value.sub(amountRequiredToInitiateRegistration);

        if (remainingAmount != 0) {
            (bool remainingFeeTransfer, ) = payable(msg.sender).call{value: remainingAmount}('');
            require(remainingFeeTransfer, 'NameRegistry: Remaining Fee should be successfully sent back to user');
        }

        emit InitiateRegistration(preImage, msg.sender);
    }

    function confirmRegistration(bytes32 preImage, string memory image) public onlyOwner(preImage) {
        require(bytes(image).length <= maxNameLength, 'NameRegistry: cannt exceed the max name length defined as per contract');
        require(getState(preImage) == RegistrationState.REQUESTED, 'NameRegistry: Only requested registration can be confirmed');
        require(keccak256(abi.encodePacked(image)) == preImage, 'NameRegistry: image and preImage dont not match');

        nameRegistry[preImage].image = image;
        nameRegistry[preImage].expiry = block.timestamp.add(registrationTime);
        nameRegistry[preImage].status = RegistrationStatus.REGISTERED;

        uint256 nameLengthRefund = (maxNameLength.sub(bytes(image).length)).mul(registrationCostPerCharacter);
        if (nameLengthRefund != 0) {
            (bool remainingFeeTransfer, ) = payable(msg.sender).call{value: nameLengthRefund}('');
            require(remainingFeeTransfer, 'NameRegistry: Remaining Fee should be successfully sent back to user');
        }
        emit ConfirmRegistration(preImage);
    }

    function renewRegistration(bytes32 preImage) public onlyOwner(preImage) {
        require(
            getState(preImage) == RegistrationState.REGISTERED || getState(preImage) == RegistrationState.EXPIRED,
            'NameRegistry: only registered or expired names can be renewed'
        );
        require(block.timestamp > nameRegistry[preImage].expiry.sub(renewTime), 'Nameregistry: renewal time for name has not started');
        nameRegistry[preImage].expiry = block.timestamp.add(registrationTime);
        emit RegistrationRenewed(preImage);
    }

    function claimOwnershipForExpiredName(bytes32 preImage) public payable {
        require(getState(preImage) == RegistrationState.EXPIRED, 'NameRegistry: Only Expired names can be claimed transfered to new user');
        require(msg.sender != nameRegistry[preImage].owner, 'NameRegistry: owner cannt claim ownership if expired.');
        require(msg.value >= lockInAmount, 'NameRegistry: User should send atleast locking fee for ownership transfer');
        uint256 remainingAmount = msg.value.sub(lockInAmount);

        if (remainingAmount != 0) {
            (bool remainingFeeTransfer, ) = payable(msg.sender).call{value: remainingAmount}('');
            require(remainingFeeTransfer, 'NameRegistry: Remaining Fee should be successfully sent back to user');
        }

        claimableAmount[nameRegistry[preImage].owner] = claimableAmount[nameRegistry[preImage].owner].add(lockInAmount);
        nameRegistry[preImage].owner = msg.sender;
        emit TransferOwnership(preImage);
    }

    function claimPendingAmount(address to) external {
        require(claimableAmount[msg.sender] != 0, 'NameRegistry: No balance left to claim');
        (bool claimLockinTransfer, ) = payable(to).call{value: claimableAmount[msg.sender]}('');
        require(claimLockinTransfer, "NameRegistry: Can't claim lock in amount");
        claimableAmount[msg.sender] = 0;
    }

    function getKeccak256(string memory data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    modifier onlyOwner(bytes32 preImage) {
        require(
            nameRegistry[preImage].owner == msg.sender,
            'NameRegistry: Only user who has submited the preImage can register the name against it'
        );
        _;
    }
}


// image------------preImage
// www.google.com - 0x5e0070dcafd8b3a1e7e48c39cbb2f97475f8243815b0c55973ac39a1299a5f39
// www.facebook.com - 0x2b360476c3ea2c9e40c80a2d6a1ca659a7f4651d00c5006c5c78a4bd0e9765e6
// tryThisOut - 0xc393ba55727ab04fb12051168235da4307db42cb8f5bbc115a1d937ccfc1aea2

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