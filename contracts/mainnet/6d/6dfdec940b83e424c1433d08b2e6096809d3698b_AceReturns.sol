pragma solidity ^0.4.24;

/**
*
Get Paid 50 Percent daily for 3 days... You can withdraw your dividend every minute...
*/
contract AceReturns {

    using SafeMath for uint256;

    mapping(address => uint256) investments;
    mapping(address => uint256) recentinvestment;
    mapping(address => uint256) joined;
    mapping(address => uint256) withdrawals;
    mapping(address => uint256) referrer;
    
    uint256 public step = 50;
    uint256 public minimum = 10 finney;
    uint256 public stakingRequirement = 0.25 ether;
    address public ownerWallet;
    address public owner;
    
    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Bounty(address hunter, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor() public {
        owner = msg.sender;
        ownerWallet = msg.sender;
    }

    /**
     * @dev Modifiers
     */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     * @param newOwnerWallet The address to transfer ownership to.
     */
    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        ownerWallet = newOwnerWallet;
    }

    /**
     * @dev Investments
     */
    function () public payable {
        buy(0x0);
    }

    function buy(address _referredBy) public payable {
        require(msg.value >= minimum);
        address _customerAddress = msg.sender;

        if(
           // is this referred by someone?
           _referredBy != 0x0000000000000000000000000000000000000000 &&

           // no cheating!
           _referredBy != _customerAddress &&

           // has the referrer invested a minimum of X tokens?
          investments[_referredBy] >= stakingRequirement
       ){
           // referral commission
           referrer[_referredBy] = referrer[_referredBy].add(msg.value.mul(5).div(100));
       }

       if (investments[msg.sender] > 0){
           if (withdraw()){
               withdrawals[msg.sender] = 0;
           }
       }
       investments[msg.sender] = investments[msg.sender].add(msg.value);
       recentinvestment[msg.sender] = (msg.value);
       joined[msg.sender] = block.timestamp;
       ownerWallet.transfer(msg.value.mul(5).div(100));
       emit Invest(msg.sender, msg.value);
    }

    /**
    * Evaluate current balance
    * _address Address of investor
    */
    function getBalance(address _address) view public returns (uint256) {
        uint256 minutesCount = now.sub(joined[_address]).div(1 minutes);
        if (minutesCount < 4321) {
        uint256 percent = recentinvestment[_address].mul(step).div(100);
        uint256 different = percent.mul(minutesCount).div(1440);
        uint256 balance = different.sub(withdrawals[_address]);
        return balance;
       }  else {
        uint256 percentfinal = recentinvestment[_address].mul(150).div(100);
        uint256 balancefinal = percentfinal.sub(withdrawals[_address]);
        return balancefinal;
        }
      }

function getMinutes(address _address) view public returns (uint256) {
         uint256 minutesCount = now.sub(joined[_address]).div(1 minutes);
         return minutesCount;
 }
    /**
    * Users Withdraw dividends from the contract
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
    * Referral Commission
    */
    function bounty() public {
        uint256 refBalance = checkReferral(msg.sender);
        if(refBalance >= minimum) {
             if (address(this).balance > refBalance) {
                referrer[msg.sender] = 0;
                msg.sender.transfer(refBalance);
                emit Bounty(msg.sender, refBalance);
             }
        }
    }

    /**
    * Gets the balance of the sender&#39;s address
    */
    function checkBalance() public view returns (uint256) {
        return getBalance(msg.sender);
    }

    /**
    * Gets the total withdrawals of the specified address after the recent investment
    */
    function checkWithdrawals(address _investor) public view returns (uint256) {
        return withdrawals[_investor];
    }

    /**
    * Gets the total investments of the specified address
    */
    function checkInvestments(address _investor) public view returns (uint256) {
        return investments[_investor];
    }
    
    /**
    * Gets the recent investment of the specified address
    */
    function checkRecentInvestment(address _investor) public view returns (uint256) {
        return recentinvestment[_investor];
    }
    
    /**
    * Gets the referral balance of the specified address
    */
    function checkReferral(address _hunter) public view returns (uint256) {
        return referrer[_hunter];
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