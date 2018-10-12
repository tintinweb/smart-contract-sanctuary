pragma solidity ^0.4.25;
 
/**
 *
 * Easy Investment 2 Contract
 *  - GAIN 2% PER 24 HOURS (every 5900 blocks)
 * 
 * RECOMMENDED GAS LIMIT: 70000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 * Contract reviewed and approved by pros!
 *
 */
contract EthLong{
   
    using SafeMath for uint256;
 
    mapping(address => uint256) investments;
    mapping(address => uint256) joined;
    mapping(address => uint256) withdrawals;
 
    uint256 public minimum = 10000000000000000;
    uint256 public step = 33;
    address public ownerWallet;
    address public owner;
    address public bountyManager;
    address promoter = 0xA4410DF42dFFa99053B4159696757da2B757A29d;
 
    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Bounty(address hunter, uint256 amount);
   
    /**
     * @dev Сonstructor Sets the original roles of the contract
     */
     
    constructor(address _bountyManager) public {
        owner = msg.sender;
        ownerWallet = msg.sender;
        bountyManager = _bountyManager;
    }
 
    /**
     * @dev Modifiers
     */
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
 
    modifier onlyBountyManager() {
        require(msg.sender == bountyManager);
        _;
    }
 
    /**
     * @dev Allows current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     * @param newOwnerWallet The address to transfer ownership to.
     */
 
    /**
     * @dev Investments
     */
    function () external payable {
        require(msg.value >= minimum);
        if (investments[msg.sender] > 0){
            if (withdraw()){
                withdrawals[msg.sender] = 0;
            }
        }
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        joined[msg.sender] = block.timestamp;
        ownerWallet.transfer(msg.value.div(100).mul(5));
        promoter.transfer(msg.value.div(100).mul(5));
        emit Invest(msg.sender, msg.value);
    }
 
    /**
    * @dev Evaluate current balance
    * @param _address Address of investor
    */
    function getBalance(address _address) view public returns (uint256) {
        uint256 minutesCount = now.sub(joined[_address]).div(1 minutes);
        uint256 percent = investments[_address].mul(step).div(100);
        uint256 different = percent.mul(minutesCount).div(72000);
        uint256 balance = different.sub(withdrawals[_address]);
 
        return balance;
    }
 
    /**
    * @dev Withdraw dividends from contract
    */
    function withdraw() public returns (bool){
        require(joined[msg.sender] > 0);
        uint256 balance = getBalance(msg.sender);
        if (address(this).balance > balance){
            if (balance > 0){
                withdrawals[msg.sender] = withdrawals[msg.sender].add(balance);
                msg.sender.transfer(balance);
                emit Withdraw(msg.sender, balance);
            }
            return true;
        } else {
            return false;
        }
    }
   
 
    /**
    * @dev Gets balance of the sender address.
    * @return An uint256 representing the amount owned by the msg.sender.
    */
    function checkBalance() public view returns (uint256) {
        return getBalance(msg.sender);
    }
 
    /**
    * @dev Gets withdrawals of the specified address.
    * @param _investor The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function checkWithdrawals(address _investor) public view returns (uint256) {
        return withdrawals[_investor];
    }
 
    /**
    * @dev Gets investments of the specified address.
    * @param _investor The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function checkInvestments(address _investor) public view returns (uint256) {
        return investments[_investor];
    }
       
}
 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}