// The version of the compiler.
pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title ETH_Silver
 * @dev The main contract of the project.
 */
contract ETH_Silver_White {

    // Using SafeMath for safe calculations.
    using SafeMath for uint;

    // A variable for address of the owner.
    address owner;

    // A variable to store deposits of investors.
    mapping (address => uint) deposit;
    // A variable to store amount of withdrawn money of investors.
    mapping (address => uint) withdrawn;
    // A variable to store reference point to count available money to withdraw.
    mapping (address => uint) lastTimeWithdraw;

    // A function to transfer ownership of the contract (available only for the owner).
    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner);
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    // A function to get key info for investors.
    function getInfo() public view returns(uint Deposit, uint Withdrawn, uint AmountToWithdraw) {
        // 1) Amount of invested money;
        Deposit = deposit[msg.sender];
        // 2) Amount of withdrawn money;
        Withdrawn = withdrawn[msg.sender];
        // 3) Amount of money which is available to withdraw;
        // Formula without SafeMath: ((Current Time - Reference Point) - ((Current Time - Reference Point) % 1 day)) * (Deposit * 3% / 100%) / 1 day
        AmountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender]).sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days))).mul(deposit[msg.sender].mul(3).div(100)).div(1 days);
    }

    // A constructor function for the contract. Being used once at the time as contract is deployed and simply set the owner of the contract.
    constructor() public {
        owner = msg.sender;
    }

    // A "fallback" function. It is automatically being called when anybody sends money to the contract. Function simply calls the "invest" function.
    function() external payable {
        invest();
    }

    // A function which accepts money of investors.
    function invest() public payable {
        // Requires amount of money to be more than 0.01 ETH. If it is less, automatically reverts the whole function.
        require(msg.value > 10000000000000000);
        // Transfers a fee to the owner of the contract. The fee is 20% of the deposit (or Deposit / 5)
        owner.transfer(msg.value.div(4));
        // The special algorithm for investors who increase their deposits:
        if (deposit[msg.sender] > 0) {
            // Amount of money which is available to withdraw;
            // Formula without SafeMath: ((Current Time - Reference Point) - ((Current Time - Reference Point) % 1 day)) * (Deposit * 3% / 100%) / 1 day
            uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender]).sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days))).mul(deposit[msg.sender].mul(3).div(100)).div(1 days);
            // The additional algorithm for investors who need to withdraw available dividends:
            if (amountToWithdraw != 0) {
                // Increasing amount withdrawn by an investor.
                withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
                // Transferring available dividends to an investor.
                msg.sender.transfer(amountToWithdraw);
            }
            // Setting the reference point to the current time.
            lastTimeWithdraw[msg.sender] = block.timestamp;
            // Increasing of the deposit of an investor.
            deposit[msg.sender] = deposit[msg.sender].add(msg.value);
            // End of the function for investors who increases their deposits.
            return;
        }
        // The algorithm for new investors:
        // Setting the reference point to the current time.
        lastTimeWithdraw[msg.sender] = block.timestamp;
        // Storing the amount of the deposit for new investors.
        deposit[msg.sender] = (msg.value);
    }

    // A function to get available dividends of an investor.
    function withdraw() public {
        // Amount of money which is available to withdraw.
        // Formula without SafeMath: ((Current Time - Reference Point) - ((Current Time - Reference Point) % 1 day)) * (Deposit * 3% / 100%) / 1 day
        uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender]).sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days))).mul(deposit[msg.sender].mul(3).div(100)).div(1 days);
        // Reverting the whole function for investors who got nothing to withdraw yet.
        if (amountToWithdraw == 0) {
            revert();
        }
        // Increasing amount withdrawn by the investor.
        withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
        // Updating the reference point.
        // Formula without SafeMath: Current Time - ((Current Time - Previous Reference Point) % 1 day)
        lastTimeWithdraw[msg.sender] = block.timestamp.sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days));
        // Transferring the available dividends to an investor.
        msg.sender.transfer(amountToWithdraw);
    }
}