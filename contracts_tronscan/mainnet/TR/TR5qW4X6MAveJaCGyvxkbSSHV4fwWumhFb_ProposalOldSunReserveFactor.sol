//SourceUnit: ProposalOldSunReserveFactor.sol

pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

interface GovernorAlphaInterface {
    struct Proposal {
        mapping(address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    function state(uint proposalId) external view returns (uint8);

    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory);

    function propose(address[] calldata targets, uint[] calldata values, string[] calldata signatures, bytes[] calldata calldatas, string calldata description) external returns (uint);
}

interface IWJST {
    function deposit(uint256) external;

    function withdraw(uint256) external;
}

interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ProposalOldSunReserveFactor {
    using SafeMath for uint256;

    address public _owner;
    address public _cfo = msg.sender;
    address public jstAddress;
    address public wjstAddress;
    bool public onlyOnce = false;

    GovernorAlphaInterface public governorAlpha;

    struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    event OwnershipTransferred(address  indexed previousOwner, address  indexed newOwner);
    event Withdraw_token(address _caller, address _recievor, uint256 _amount);

    function() external payable {
    }

    constructor(address governorAlpha_, address jst_, address wjst_, address newOwner_) public{
        governorAlpha = GovernorAlphaInterface(governorAlpha_);
        _owner = newOwner_;
        jstAddress = jst_;
        wjstAddress = wjst_;
    }

    modifier  onlyOwner()  {
        require(msg.sender == _owner);
        _;
    }

    modifier  onlyCFO()  {
        require(msg.sender == _cfo);
        _;
    }

    function createPropose() public returns (bool){
        require(onlyOnce == false, "onlyOnce");
        uint256 balance = ITRC20(jstAddress).balanceOf(address(this));
        if (balance > 200000000e18) {
            ITRC20(jstAddress).approve(wjstAddress, balance);
            IWJST(wjstAddress).deposit(balance);
            _createPropose();
            onlyOnce = true;
            return true;
        }
        return false;
    }

    function _createPropose() internal {
        address[] memory targets = new address[](1);
        //mainnet jOLDSUN 0x4434BECA3Ac7D96E2b4eeF1974CF9bDdCb7A328B TGBr8uh9jBVHJhhkwSJvQN2ZAKzVkxDmno
        //nile jOLDSUN 0xB6c0b3189aE3D5775eC09Ac939041a3813A814eC TSdWpyV2Z8YdJmsLcwX3udZTTafohxZcVJ

        targets[0] = (0x4434BECA3Ac7D96E2b4eeF1974CF9bDdCb7A328B);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        string[] memory signatures = new string[](1);
        signatures[0] = ("_setReserveFactor(uint256)");

        bytes[] memory calldatas = new bytes[](1);
        // nile Delegator sunold :0xB6c0b3189aE3D5775eC09Ac939041a3813A814eC
        calldatas[0] = abi.encode(1e18);

        string memory description = "set jSUNOLD _setReserveFactor";
        governorAlpha.propose(targets, values, signatures, calldatas, description);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
        emit  OwnershipTransferred(_owner, newOwner);
    }

    function withdrawToken() public onlyOwner {
        _withdrawToken();
    }

    function withdrawTokenCFO() public onlyCFO {
        _withdrawToken();
    }

    function _withdrawToken() internal {
        uint256 wjstAmount = ITRC20(wjstAddress).balanceOf(address(this));
        if (wjstAmount > 0) {
            IWJST(wjstAddress).withdraw(wjstAmount);
        }
        uint256 jstAmount = ITRC20(jstAddress).balanceOf(address(this));
        if (jstAmount > 0) {
            ITRC20(jstAddress).transfer(_owner, jstAmount);
        }
        if (address(this).balance > 0) {
            address(uint160(_owner)).transfer(address(this).balance);
        }
        emit Withdraw_token(msg.sender, _owner, jstAmount);
    }

}




//SourceUnit: SafeMath.sol

pragma solidity ^0.5.12;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}