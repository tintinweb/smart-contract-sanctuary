/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

pragma solidity 0.6.12;

/*
Presale for testing.finance
*/

interface IToken {
    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);
}

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract HedgehogBSCPresale {
    using SafeMath for uint256;

    struct Participant {
        uint256 contribution;
        bool exists;
    }

    address payable private _owner;
    IToken public tokenContract;
    uint256 public maxPerWallet;
    uint256 public tokensPerBnb;
    uint256 public bnbRaised;
    bool public isActive;
    mapping (uint256 => bool) public allowedContributions;
    mapping (address => Participant) private participants;
    // We use whitelist for our project advisors, as a thank you they can enter the presale earlier.
    mapping (address => bool) private whitelisted;

    constructor(address _tokenAddress) public { 
        _owner = msg.sender;
        isActive = true;
        maxPerWallet = 5 ether;
        tokensPerBnb = 4000000000;
        bnbRaised = 0;

        tokenContract = IToken(_tokenAddress);
        allowedContributions[0.1 ether] = true;
        allowedContributions[0.2 ether] = true;
        allowedContributions[0.3 ether] = true;
        allowedContributions[0.4 ether] = true;
        allowedContributions[0.5 ether] = true;
    }

    function getBnbRaised() external view returns (uint256) {
        return bnbRaised;
    }

    function burnTheRest() public {
        require(msg.sender == _owner, "Not owner!");
        require(!isActive, "Presale can't be active while burning.");
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "Nothing to burn");
        tokenContract.transfer(address(0x000000000000000000000000000000000000dEaD), balance);
    }

    function setActive(bool status) public {
        require(msg.sender == _owner, "Not owner!");
        isActive = status;
    }

    function addWhitelist(address addr) public {
        require(msg.sender == _owner, "Not owner!");
        whitelisted[addr] = true;
    }

    function removeWhitelist(address addr) public {
        require(msg.sender == _owner, "Not owner!");
        whitelisted[addr] = false;
    }

    function buy() external payable {
        uint256 valueInEther = msg.value/(1 ether);
        uint256 tokensToSend = valueInEther.mul(tokensPerBnb)*(1 ether);

        if (!isActive) {
            require(whitelisted[msg.sender], "Presale not active");
        }
        require(allowedContributions[msg.value], 'Round numbers only!');
        require(tokenContract.balanceOf(address(this)) >= tokensToSend, 'Sold out!');
        address sender = msg.sender;
        _owner.transfer(msg.value);
        bnbRaised = bnbRaised.add(valueInEther);
        if (participants[sender].exists) {
            require(participants[sender].contribution.add(msg.value) <= maxPerWallet, 'Max per wallet reached');
            participants[sender].contribution = participants[sender].contribution.add(msg.value);
        } else {
            participants[sender].contribution = msg.value;
            participants[sender].exists = true;
        }
        tokenContract.transfer(sender, tokensToSend);
    }

    function contributionLeft() external view returns (uint256) {
        address sender = msg.sender;
        if (participants[sender].exists) {
            return maxPerWallet.sub(participants[sender].contribution);
        } else {
            return maxPerWallet;
        }
    }
}