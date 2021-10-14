pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EthereansInterface.sol";
import "./InvasionTokenInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Etherean Empire utility system
/// @author inexplicable.eth
/// @notice Etherean holders must interface through this contract to mint Invasion utility tokens

contract EthereanEmpire is Ownable {

using SafeMath for uint256;

event EmpireCreated(address owner, string name, string motto);
event EmpireNameChanged(address owner, string newName);
event EmpireMottoChanged(address owner, string newMotto);
event RewardClaimed(address claimer, uint amount);

struct Empire {
    string name;
    string motto;
    bool exists;
    uint lastUpdated;
}

uint public EMPIRE_CREATION_FEE = 50000000000000000; //.05E
uint public ETHEREAN_MIN = 3;
uint public EMPIRE_EDIT_FEE = 200 ether;
address public ETHEREANS_CONTRACT_ADDRESS;
address public INVASION_CONTRACT_ADDRESS;
uint constant public END_REWARDS = 1664472750; //Thursday, September 29, 2022 17:32:30 GMT
EthereansInterface private ethereanContract;
InvasionTokenInterface private invasionContract;

mapping(address => Empire) public empires;
address[] private empireAddresses;

/// @notice Initializes the smart contract with reference to the official Ethereans ERC721 contract & utility token
constructor(address _ethereansAddress, address _invasionAddress) {
    ETHEREANS_CONTRACT_ADDRESS = _ethereansAddress;
    ethereanContract = EthereansInterface(_ethereansAddress);

    INVASION_CONTRACT_ADDRESS = _invasionAddress;
    invasionContract = InvasionTokenInterface(_invasionAddress);
}

function setEthereansContractAddress(address _contractAddress) external onlyOwner() {
    ETHEREANS_CONTRACT_ADDRESS = _contractAddress;
    ethereanContract = EthereansInterface(_contractAddress);
}

/// @notice Creates a new empire if minimum etherean balance in wallet is met as well as creation fee
function newEmpire(string memory _name, string memory _motto) public payable {
    require(empires[msg.sender].exists == false);
    require(msg.value == EMPIRE_CREATION_FEE);
    require(ethereanContract.balanceOf(msg.sender) >= ETHEREAN_MIN, "Did not meet minimum ethereans requirement.");
    //TODO: Interface with Ethereans contract to check for min requirement.
    Empire storage e = empires[msg.sender];
    e.name = _name;
    e.motto = _motto;
    e.exists = true;
    e.lastUpdated = block.timestamp;
    empireAddresses.push(msg.sender);
    emit EmpireCreated(msg.sender, _name, _motto);
}

function getEmpireAddresses() public view returns (address[] memory) {
    return empireAddresses;
}

function setEmpireCreationFee(uint _newFee) external onlyOwner(){
    EMPIRE_CREATION_FEE = _newFee;
}

function setEmpireEditFee(uint _newFee) external onlyOwner(){
    EMPIRE_EDIT_FEE = _newFee;
}

modifier hasEmpire {
    require(empires[msg.sender].exists == true);
    _;
}

function changeName(string memory _newName) external hasEmpire(){
    invasionContract.burnFrom(msg.sender, EMPIRE_EDIT_FEE);
    empires[msg.sender].name = _newName;
    emit EmpireNameChanged(msg.sender, _newName);
}

function changeMotto(string memory _newMotto) external hasEmpire(){
    invasionContract.burnFrom(msg.sender, EMPIRE_EDIT_FEE);
    empires[msg.sender].motto = _newMotto;
    emit EmpireMottoChanged(msg.sender, _newMotto);
}

/// @dev Claim function is only available for wallets who have created an empire and have maintained minimum etherean balance requirement at time of claim. The claim amount is determined by: elapsed time (since last claim or empire creation) x ethereans balance x multiplier bonus. Users can claim past the END_REWARDS timestamp if pending rewards are available, but will not be able to claim additional tokens after that last action.
function claimReward() external hasEmpire() {
    uint ethereanBalance = ethereanContract.balanceOf(msg.sender);
    require(ethereanBalance >= ETHEREAN_MIN, "Did not meet minimum ethereans requirement to claim rewards.");
    uint rewardsPerEtherean = getRewardsPerEtherean(ethereanBalance);
    uint currentTime = min(block.timestamp, END_REWARDS);
    Empire storage e = empires[msg.sender];
    uint elapsedTime = currentTime.sub(e.lastUpdated);
    require(elapsedTime > 0, "No rewards available.");
    uint rewardAmount = elapsedTime.mul(ethereanBalance).mul(rewardsPerEtherean).mul(10**18).div(86400);
    invasionContract.claimReward(msg.sender, rewardAmount);
    e.lastUpdated = currentTime;
    emit RewardClaimed(msg.sender, rewardAmount);
}

function min(uint a, uint b) internal pure returns (uint) {
		return a < b ? a : b;
	}

/// @notice Returns the multiplier based on ethereans held in wallet. The base yield per day for an etherean is 10, so a return value of 11 is treated as 1.1x multiplier.
function getRewardsPerEtherean(uint ethereanBalance) internal pure returns (uint) {
    if (ethereanBalance < 6) 
        return 10;
    if (ethereanBalance < 18)
        return 11;
    if (ethereanBalance < 72)
        return 12;
    return 13;
}

function withdraw() public onlyOwner() {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
}

}

pragma solidity ^0.8.0;

interface InvasionTokenInterface {
    function claimReward(address owner, uint amount) external;

    function burnFrom(address from, uint amount) external;
}

pragma solidity ^0.8.0;

interface EthereansInterface {
    function balanceOf(address owner) external view returns (uint256 balance);
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