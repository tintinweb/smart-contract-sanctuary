/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

//Audit report available at https://www.tkd-coop.com/files/audit.pdf

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract ITACData {
    function transfer(address recipient, uint256 amount) public virtual returns (bool) ;
}

 //Control who can access various functions.
contract AccessControl {
    address payable public creatorAddress;
    uint16 public totalDirectors = 0;
    mapping (address => bool) public directors;

   modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, "You are not the creator of the contract.");
        _;
    }

   // Constructor
    constructor()  {
        creatorAddress = 0x813dd04A76A716634968822f4D30Dfe359641194;
    }
}

//Interface to TAC Contract
abstract contract ITAC {
     function awardTAC(address winner, address loser, address referee) public virtual;
     function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);
     function balanceOf(address account) external virtual view returns (uint256);
}

contract TACLockup is AccessControl  {

     /////////////////////////////////////////////////DATA STRUCTURES AND GLOBAL VARIABLES ///////////////////////////////////////////////////////////////////////

    // Lockup duration in seconds for each time period
    uint64 public lockupDuration = 604800;

    // Hardcoded limits that cannot be changed by admin. 
    // Time is in seconds. 
    uint64 public minLockupDuration = 1;
    uint64 public maxLockupDuration = 2592000;

    // 100/removalFactor = % of TAC that can be removed each time.
    uint64 public removalFactor = 10;

    // minimum amount of a removal if they have that much balance
    uint256 public minRemovalAmount = 5000000000000000000;

    uint64 public minRemovalFactor = 1; //100% removal, no limit 
    uint64 public maxRemovalFactor = 100; //1% removal

    mapping (address => uint256) public lockedTACForUser;
    mapping (address => uint64) public lastRemovalTime;

    address TACContract = address(0); //Will be changed by admin once TACContract is deployed.

    //This function is separate from setParameters to lower the chance of accidental override. 
    function setTACAddress(address _TACContract) public onlyCREATOR {
        TACContract = _TACContract;
    }

    //Admin function to adjust the lockup duration. Adjustments must stay within pre-defined limits. 
    function setParameters(uint64 _lockupDuration, uint64 _removalFactor, uint256 _minRemovalAmount) public onlyCREATOR {
        if ((_lockupDuration <= maxLockupDuration) && (_lockupDuration >= minLockupDuration)) {
        lockupDuration = _lockupDuration;
        }

        if ((_removalFactor <= maxRemovalFactor) && (_removalFactor >= minRemovalFactor)) {
         removalFactor = _removalFactor;
        }
        minRemovalAmount = _minRemovalAmount;
    }

    //Returns current valued
    function getValues() public view returns (uint64 _lockupDuration, uint64 _removalFactor) {
        _lockupDuration = lockupDuration;
        _removalFactor = removalFactor;
    }

    //Function called by the TAC contract to adjust the locked up balance of a user.
    function adjustBalance(address user, uint256 amount) public  {
        require(msg.sender == TACContract, "Only the TAC Contract can call this function");
        lockedTACForUser[user] += amount;
        //If the user has no balance, we need to set this as the current last removal time. 
        if (lastRemovalTime[user] == 0) {
            lastRemovalTime[user] = uint64(block.timestamp);
        }
    }
    //Function to lock your own TAC. 
    //Users must have previously approved this contract.
    function lockMyTAC(uint256 amount) public {
        ITAC TAC = ITAC(TACContract);
        TAC.transferFrom(msg.sender, address(this), amount);
        lockedTACForUser[msg.sender] += amount;
        //If the user has no balance, we need to set this as the current last removal time. 
        if (lastRemovalTime[msg.sender] == 0) {
            lastRemovalTime[msg.sender] = uint64(block.timestamp);
        }
    }

    // Returns returns the amount of TAC a user has locked as well as the last removal time.
    function getUserInfo(address user) public view returns (uint256 lockedAmount , uint64 time) {
        lockedAmount = lockedTACForUser[user];
        time = lastRemovalTime[user];
    }

    // Returns the amount of locked TAC a user has
    function getTACLocked(address user) public view returns (uint256 lockedAmount) {
          lockedAmount = lockedTACForUser[user];
    }
    
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

// Function any user can call to receive their TAC allocation. 
    function claimTAC() public  {
      require(lockedTACForUser[msg.sender] > 0, "You need to have received some TAC first");
      require(block.timestamp > lastRemovalTime[msg.sender] + lockupDuration, "You need to wait a bit longer");
      ITACData TAC = ITACData(TACContract);

      //Calculate amount to transfer and adjust removal time
      uint256 transferAmount = div(lockedTACForUser[msg.sender], removalFactor);
      lastRemovalTime[msg.sender] = uint64(block.timestamp);
      
      //If they have enough balance but the transfer amount is small, transfer the min amount. 
      if ((transferAmount <= minRemovalAmount) && (lockedTACForUser[msg.sender] > minRemovalAmount)) {
          transferAmount = minRemovalAmount;
      }

      //Transfer entire balance if min transfer amount is greater than their balance. 
      if (minRemovalAmount > lockedTACForUser[msg.sender]) {
        transferAmount = lockedTACForUser[msg.sender];
      }
      //Decrement user's balance and transfer
      lockedTACForUser[msg.sender] = lockedTACForUser[msg.sender] - transferAmount;
      TAC.transfer(msg.sender, transferAmount);
    }

}