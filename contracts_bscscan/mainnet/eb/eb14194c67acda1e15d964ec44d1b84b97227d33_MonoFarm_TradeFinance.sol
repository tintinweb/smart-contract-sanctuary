/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

pragma solidity 0.5.10;

// SPDX-License-Identifier: UNLICENSED

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

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;
    }
}

/**

 * @title TRC20 interface

 * @dev see https://github.com/ethereum/EIPs/issues/20

 */

interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**

 * @title SafeMath

 * @dev Unsigned math operations with safety checks that revert on error

 */

library SafeMath {
    /**

    * @dev Multiplies two unsigned integers, reverts on overflow.

    */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b);

        return c;
    }

    /**

    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.

    */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0

        require(b > 0);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**

    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).

    */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    /**

    * @dev Adds two unsigned integers, reverts on overflow.

    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    /**

    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),

    * reverts when dividing by zero.

    */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor() internal {
        _owner = _msgSender();

        emit OwnershipTransferred(address(0), _owner);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");

        _;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract MonoFarm_TradeFinance is Ownable{
    using SafeMath for uint256;
    ITRC20 public TradeFinance;

    struct userInfo {
        uint256 farmedToken;
        uint256 lastUpdated;
        uint256 lockableDays;
    }
    
    uint256 constant public minimumDeposit = 50E18;
    mapping(uint256 => uint256) public allocation;
    mapping(address => userInfo) public users;

    constructor(ITRC20 _TradeFinance) public {
        TradeFinance = _TradeFinance;
        allocation[30] = 7;
        allocation[60] = 15;
        allocation[90] = 25;
        allocation[180] = 50;
        allocation[360] = 100;
    }

    function farm(uint256 _amount, uint256 _lockableDays) public {
        userInfo storage user = users[msg.sender];
        require(user.farmedToken == 0, "Muliple farm not allowed");
        require(_amount >= minimumDeposit, "Invalid amount");
        require(allocation[_lockableDays] > 0, "Invalid day selection");
        TradeFinance.transferFrom(msg.sender, address(this), _amount);
        user.farmedToken = _amount;
        user.lastUpdated = now;
        user.lockableDays = _lockableDays;
    }

    function pendindRewards() public view returns (uint256 TradeFinanceReward) {
        userInfo storage user = users[msg.sender];
        uint256 leftout = now.sub(user.lastUpdated);
        uint256 toDays = leftout.div(1 days);
        if (users[msg.sender].lockableDays > toDays) return (0);
        else
            TradeFinanceReward = allocation[users[msg.sender].lockableDays].mul(users[msg.sender].farmedToken).div(100);
            TradeFinanceReward = TradeFinanceReward.add(users[msg.sender].farmedToken);    
            return (TradeFinanceReward);
    }

    function harvest() public {
        userInfo storage user = users[msg.sender];
        require(user.farmedToken > 0, "No staked balance found");
        (uint256 TradeFinanceReward) = pendindRewards();
        if(TradeFinanceReward > 0 ) {
            uint256 amounttoTransferred = user.farmedToken.add(TradeFinanceReward);
            safeTransferWYZ(msg.sender, amounttoTransferred);
            user.farmedToken = 0;
        }
    }

    function safeTransferWYZ(address _farmer, uint256 _amount) internal {
        uint256 tokenBal = TradeFinance.balanceOf(address(this));
        if (_amount > tokenBal) {
            TradeFinance.transfer(_farmer, tokenBal);
        } else {
            TradeFinance.transfer(_farmer, _amount);
        }
    }
   
    
    // EMERGENCY ONLY.
    function emergencyWithdraw(uint256 TradeFinanceAmount) public onlyOwner {
        safeTransferWYZ(msg.sender, TradeFinanceAmount);
    }
}