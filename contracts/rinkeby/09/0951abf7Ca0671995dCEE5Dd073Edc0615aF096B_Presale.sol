// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IVesting.sol";
import './interfaces/IStripToken.sol';

contract Presale {
    using SafeMath for uint256;

    address private owner;

    struct PresaleBuyer {
        uint256 amountDepositedWei; // Funds token amount per recipient.
        uint256 amountStrip; // Rewards token that needs to be vested.
    }

    mapping(address => PresaleBuyer) public recipients; // Presale Buyers

    uint256 public constant MAX_ALLOC_STRIP = 2e8 * 1e18; // 200,000,000 STRIP is the max allocation for each presale buyer
    uint256 public constant MAX_ALLOC_WEI = 505e15; // 0.5 ETH + 1% tax is the max allocation for each presale buyer
    uint256 public constant IDS = 120e27; // Total StripToken amount for presale : 120b
    
    uint256 public startTime; // Presale start time
    uint256 public PERIOD; // Presale Period
    address payable public multiSigAdmin; // MultiSig contract address : The address where to withdraw funds token to after presale

    bool private isPresaleStarted;
    uint256 public soldStripAmount;

    IStripToken public stripToken; // Rewards Token : Token for distribution as rewards.
    IVesting private vestingContract; // Vesting Contract

    event PrevParticipantsRegistered(address[], uint256[],  uint256[]);
    event PresaleRegistered(address _registeredAddress, uint256 _weiAmount, uint256 _stripAmount);
    event PresaleStarted(uint256 _startTime);
    event PresalePaused(uint256 _endTime);
    event PresalePeriodUpdated(uint256 _newPeriod);
    event MultiSigAdminUpdated(address _multiSigAdmin);

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    modifier whileOnGoing() {
        require(block.timestamp >= startTime, "Presale has not started yet");
        require(block.timestamp <= startTime + PERIOD, "Presale has ended");
        require(isPresaleStarted, "Presale has ended or paused");
        _;
    }

    modifier whileFinished() {
        require(block.timestamp > startTime + PERIOD, "Presale has not ended yet!");
        _;
    }

    modifier whileDeposited() {
        require(getDepositedStrip() >= IDS, "Deposit enough Strip tokens to the vesting contract first!");
        _;
    }

    constructor(address _stripToken, address payable _multiSigAdmin) {
        owner = msg.sender;

        stripToken = IStripToken(_stripToken);
        multiSigAdmin = _multiSigAdmin;
        PERIOD = 2 weeks;

        isPresaleStarted = false;
    }

    /********************** Internal ***********************/
    
    /**
     * @dev Get the StripToken amount of vesting contract
     */
    function getDepositedStrip() internal view returns (uint256) {
        address addrVesting = address(vestingContract);
        return stripToken.balanceOf(addrVesting);
    }

    /**
     * @dev Get remaining StripToken amount of vesting contract
     */
    function getUnsoldStrip() internal view returns (uint256) {
        uint256 totalDepositedStrip = getDepositedStrip();
        return totalDepositedStrip.sub(soldStripAmount);
    }

    /********************** External ***********************/
    
    function remainingStrip() external view returns (uint256) {
        return getUnsoldStrip();
    }

    function isPresaleGoing() external view returns (bool) {
        return isPresaleStarted && block.timestamp >= startTime && block.timestamp <= startTime + PERIOD;
    }

    /**
     * @dev Start presale after checking if there's enough strip in vesting contract
     */
    function startPresale() external whileDeposited onlyOwner {
        require(!isPresaleStarted, "StartPresale: Presale has already started!");
        isPresaleStarted = true;
        startTime = block.timestamp;
        emit PresaleStarted(startTime);
    }

    /**
     * @dev Update Presale period
     */
    function setPresalePeriod(uint256 _newPeriod) external whileDeposited onlyOwner {
        PERIOD = _newPeriod;
        emit PresalePeriodUpdated(PERIOD);
    }

    /**
     * @dev Pause the ongoing presale by emergency
     */
    function pausePresaleByEmergency() external onlyOwner {
        isPresaleStarted = false;
        emit PresalePaused(block.timestamp);
    }

    /**
     * @dev All remaining funds will be sent to multiSig admin  
     */
    function setMultiSigAdminAddress(address payable _multiSigAdmin) external onlyOwner {
        require (_multiSigAdmin != address(0x00));
        multiSigAdmin = _multiSigAdmin;
        emit MultiSigAdminUpdated(multiSigAdmin);
    }

    function setStripTokenAddress(address _stripToken) external onlyOwner {
        require (_stripToken != address(0x00));
        stripToken = IStripToken(_stripToken);
    }

    function setVestingContractAddress(address _vestingContract) external onlyOwner {
        require (_vestingContract != address(0x00));
        vestingContract = IVesting(_vestingContract);
    }

    /** 
     * @dev After presale ends, we withdraw funds to the multiSig admin
     */ 
    function withdrawRemainingFunds() external whileFinished onlyOwner returns (uint256) {
        require(multiSigAdmin != address(0x00), "Withdraw: Project Owner address hasn't been set!");

        uint256 weiBalance = address(this).balance;
        require(weiBalance > 0, "Withdraw: No ETH balance to withdraw");

        (bool sent, ) = multiSigAdmin.call{value: weiBalance}("");
        require(sent, "Withdraw: Failed to withdraw remaining funds");
       
        return weiBalance;
    }

    /**
     * @dev After presale ends, we withdraw unsold StripToken to multisig
     */ 
    function withdrawUnsoldStripToken() external whileFinished onlyOwner returns (uint256) {
        require(multiSigAdmin != address(0x00), "Withdraw: Project Owner address hasn't been set!");
        require(address(vestingContract) != address(0x00), "Withdraw: Set vesting contract!");

        uint256 unsoldStrip = getUnsoldStrip();

        require(
            stripToken.transferFrom(address(vestingContract), multiSigAdmin, unsoldStrip),
            "Withdraw: can't withdraw Strip tokens"
        );

        return unsoldStrip;
    }

    /**
     * @dev Receive Wei from presale buyers
     */ 
    function deposit(address sender) external payable whileOnGoing returns (uint256) {
        require(sender != address(0x00), "Deposit: Sender should be valid address");
        require(multiSigAdmin != address(0x00), "Deposit: Project Owner address hasn't been set!");
        require(address(vestingContract) != address(0x00), "Withdraw: Set vesting contract!");
        
        uint256 weiAmount = msg.value;
        uint256 newDepositedWei = recipients[sender].amountDepositedWei.add(weiAmount);
        uint256 weiWithoutTax = weiAmount.mul(100).div(101);   // 1% of tax for each purchase

        require(MAX_ALLOC_WEI >= newDepositedWei, "Deposit: Can't exceed the MAX_ALLOC!");

        uint256 newStripAmount = weiWithoutTax.mul(MAX_ALLOC_STRIP).div(5e17);
        require(soldStripAmount + newStripAmount <= IDS, "Deposit: All sold out");

        recipients[sender].amountDepositedWei = newDepositedWei;
        soldStripAmount = soldStripAmount.add(newStripAmount);

        recipients[sender].amountStrip = recipients[sender].amountStrip.add(newStripAmount);
        vestingContract.addNewRecipient(sender, recipients[sender].amountStrip, true);

        require(weiAmount > 0, "Deposit: No ETH balance to withdraw");

        (bool sent, ) = multiSigAdmin.call{value: weiAmount}("");
        require(sent, "Deposit: Failed to send Ether");

        emit PresaleRegistered(sender, weiAmount, recipients[sender].amountStrip);

        return recipients[sender].amountStrip;
    }


    /**
     * @dev Update the data of participants who participated in presale before 
     * @param _oldRecipients the addresses to be added
     * @param _weiAmounts integer array to indicate wei amount of participants
     * @param _tokenAmounts integer array to indicate strip amount of participants
     */

    function addPreviousParticipants(address[] memory _oldRecipients, uint256[] memory _weiAmounts, uint256[] memory _tokenAmounts) external onlyOwner {
        require(!isPresaleStarted, "addPreviousParticipants: Presale already started");

        for (uint256 i = 0; i < _oldRecipients.length; i++) {
            require(_weiAmounts[i] <= MAX_ALLOC_WEI, "addPreviousParticipants: Wei amount exceeds limit");
            require(_tokenAmounts[i] <= MAX_ALLOC_STRIP, "addPreviousParticipants: Token amount exceeds limit");
            recipients[_oldRecipients[i]].amountDepositedWei = recipients[_oldRecipients[i]].amountDepositedWei.add(_weiAmounts[i]);
            recipients[_oldRecipients[i]].amountStrip = recipients[_oldRecipients[i]].amountStrip.add(_tokenAmounts[i]);
            soldStripAmount = soldStripAmount.add(_tokenAmounts[i]);
        }

        emit PrevParticipantsRegistered(_oldRecipients, _weiAmounts, _tokenAmounts);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVesting {
    function setVestingAllocation(uint256) external;
    function addNewRecipient(address, uint256, bool) external;
    function addNewRecipients(address[] memory, uint256[] memory, bool) external;
    function startVesting(uint256) external;
    function getLocked(address) external view returns (uint256);
    function getWithdrawable(address) external view returns (uint256);
    function withdrawToken(address) external returns (uint256);
    function getVested(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStripToken is IERC20 {
    function decimals() external view returns (uint256);
    function setMultiSigAdminAddress(address) external;
    function recoverERC20(address, uint256) external;
}

// SPDX-License-Identifier: MIT

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