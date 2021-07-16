//SourceUnit: topiaRaffle.sol

pragma solidity ^0.5.8;  /*


    
    ___________________________________________________________________
      _      _                                        ______           
      |  |  /          /                                /              
    --|-/|-/-----__---/----__----__---_--_----__-------/-------__------
      |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
    __/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
        
        




████████╗ ██████╗ ██████╗ ██╗ █████╗     ██████╗  █████╗ ███████╗███████╗██╗     ███████╗
╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗    ██╔══██╗██╔══██╗██╔════╝██╔════╝██║     ██╔════╝
   ██║   ██║   ██║██████╔╝██║███████║    ██████╔╝███████║█████╗  █████╗  ██║     █████╗  
   ██║   ██║   ██║██╔═══╝ ██║██╔══██║    ██╔══██╗██╔══██║██╔══╝  ██╔══╝  ██║     ██╔══╝  
   ██║   ╚██████╔╝██║     ██║██║  ██║    ██║  ██║██║  ██║██║     ██║     ███████╗███████╗
   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚══════╝
                                                                                         


  
                                                                                     
                                                                                     


----------------------------------------------------------------------------------------------------

=== MAIN FEATURES ===
    => Higher degree of control by owner - safeGuard functionality
    => SafeMath implementation 
    => Earning on Raffle Game

------------------------------------------------------------------------------------------------------
 Copyright (c) 2019 onwards topia Inc. ( https://Raffletopia.io )
 Contract designed with ❤ by EtherAuthority  ( https://EtherAuthority.io )
------------------------------------------------------------------------------------------------------
*/

/* Safemath library */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// Owner Handler
contract ownerShip    // Auction Contract Owner and OwherShip change
{
    //Global storage declaration
    address payable public owner;
    address payable public dev;

    address payable public newOwner;
    address payable public newDev;

    bool public safeGuard ; // To hault all non owner functions in case of imergency

    //Event defined for ownership transfered
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    //Event defined for dev transfered
    event DevTransferredEv(address indexed previousDev, address indexed newDev);

    //Sets owner only on first run
    constructor() public 
    {
        //Set contract owner
        owner = msg.sender;
        dev = msg.sender;
        // Disabled global hault on first deploy
        safeGuard = false;



    }

    //This will restrict function only for owner where attached
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }

    //This will restrict function only for owner where attached
    modifier onlyDev() 
    {
        require(msg.sender == dev);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner
    {
        newOwner = _newOwner;
    }

    function changeDev(address payable _newDev) public onlyDev
    {
        newDev = _newDev;
    }


    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptDevChange() public 
    {
        require(msg.sender == newDev);
        emit DevTransferredEv(dev, newDev);
        dev = newDev;
        newDev = address(0);
    }

    function changesafeGuardStatus() onlyOwner public
    {
        if (safeGuard == false)
        {
            safeGuard = true;
        }
        else
        {
            safeGuard = false;    
        }
    }

}




contract RaffleTopia is ownerShip
{

    using SafeMath for uint256;

    uint256 public totalTicketSaleValueOfAllRaffleSession;   // Total deposited trx after ticket sale of all session
    //uint256 public totalAvailableTrxBalance; // Total available trx balance of this contract
    uint256 public totalDevComission;  //Total collected comission.
    uint256 public totalAdminComission; //total admin comission
    uint256 public withdrawnByAdmin;  //Total withdrawn TRX by admin
    uint256 public emergencyWithdrawnByAdmin;  //Total withdrawn TRX by admin
    uint256 public withdrawnByDev;  // Total withdrawn TRX by dev


    uint256[10] public winnerRewardPercent;  // 123 = 1.23%, admin can set this as required, total sum must be equal to 10000 (=100%)

    
    struct RaffleMode    // struct for keeping different Dev percent with Dev name
    {
        uint256 DevPercent; // % deduction for this Dev will be forwarded to contract address
        uint256 adminPercent; // % deduction for this Dev for admin comission
        uint256 entryPeriod;     // Raffle session will end after this seconds 
        uint256 startTicketNo;  // Starting number of the ticket, next all ticket will be next no up to max ticket count reached
        uint256 maxTicketCount;     // maximum ticket (count) open to sale for current session
        uint256 ticketPrice;        //Price of each ticket, user must paid to buy
        bool active;               // if false can not be used
    }

    RaffleMode[] public RaffleModes;


    struct RaffleInfo
    {
        uint256 totalTrxCollected;    // Total TRX on Raffle for the given ID
        uint256 lastSoldTicketNo;      // Last ticket no which sold
        uint256 startTime;          // Starting time of Raffle, to check participant can buy ticket up to certain given seconds for a session
        uint256[10] winningNo;             // the ticket no which declared as winner
        uint256 devComission;     // comission paid to house for this RaffleID till claim reward it is used for loop control
        uint256 adminComission;     // comission paid to house for this RaffleID
        uint256 winningAmount;      // winningAmount of winners after comission of house and admin
        uint256 raffleMode;        // Dev percent info for this RaffleID
        bool winnerDeclared;        // winner declared or not if not then false
        bool rewardDistributed;     // true if distributed
        uint256 thisBlockNo;   // current block number will be used later in selectWinner to predict winner ticket no
    }

    RaffleInfo[] public RaffleInfos;  //Its index is the RaffleID


    // first uint256 is raffleInfoID and 2nd is ticket no and stored address is ticket owner
    mapping (uint256 => mapping( uint256 => address payable)) public ticketOwner;
    // addrress => raffleInfoID => ticketNo[] , all tickets owned by a user
    mapping (address => mapping( uint256 => uint256[])) public ticketsBought;    
    // first uint256 is raffleID and 2nd is ticket no and bool=>true means selected as winner
    mapping(uint256 => mapping( uint256 => bool)) winnerTracker;  // this is temporary to avoid costly loop 



    function () payable external {
        revert();
    }



    //Sets owner only on first run
    constructor() public 
    {
        //Set default Dev category Dev category no 0
        RaffleMode memory temp;
        temp.DevPercent = 250;   // 4% comission to contract address
        temp.adminPercent = 250;  // 1% comission to admin
        temp.ticketPrice = 100;   // Trx required to buy one ticket
        temp.entryPeriod = 300;   // 180 second 3 minute of betting time
        temp.startTicketNo = 9999;  // default is 8 players for category RaffleModes[0]
        temp.maxTicketCount = 99999999;  //15 seconds of grace period to increase bet amount
        temp.active =  true ;  // this Dev is active gambler can use
        RaffleModes.push(temp); 
        uint256 i;
        for (i=0;i<10;i++)
        {
            winnerRewardPercent[i] = 1000;
        }     
    }

    //Event for trx paid and withdraw (if any)
    event ticketBoughtEv(address paidAmount, address user, uint ticketNo );
    event trxWithdrawEv(address user, uint amount, uint remainingBalance);


    function updateWinnerDistPercent(uint256[10] memory _winnerRewardPercent) public onlyOwner returns(bool)
    {
        uint256 sumOfAll;
        uint256 i;
        for (i=0;i<10;i++)
        {
            winnerRewardPercent[i] = _winnerRewardPercent[i];
            sumOfAll += _winnerRewardPercent[i];
        }
        require(sumOfAll == 10000, "sum of all is not 10000 (100%)");
        return true;
    }

    //Calculate percent and return result
    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256) 
    {
        uint256 factor = 10000;
        //require(percentTo <= factor);
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    } 


    event createRaffleModeEv(uint256 nowTime,uint256 _DevPercent,uint256 _entryPeriod,bool _active, uint256 raffleModeID);
    //To create different Dev category
    function createRaffleMode(uint256 _DevPercent,uint256 _adminPercent, uint256 _entryPeriod,uint256 _startTicketNo, uint256 _maxTicketCount,uint256 _ticketPrice, bool _active) public onlyOwner returns(bool)
    {
        require(_startTicketNo > 0, "invalid start ticket no");
        require(_maxTicketCount > 9, "invalid max ticket count");

        RaffleMode memory temp;
        temp.DevPercent = _DevPercent;
        temp.adminPercent = _adminPercent;
        temp.entryPeriod = _entryPeriod;
        temp.startTicketNo = _startTicketNo;
        temp.maxTicketCount = _maxTicketCount;
        temp.ticketPrice = _ticketPrice;
        temp.active = _active;
        RaffleModes.push(temp);
        emit createRaffleModeEv(now,_DevPercent,_entryPeriod,_active, RaffleModes.length -1);
        return true;
    }

    event changeRaffleModeEv(uint256 nowTime,uint256 RaffleModeID,uint256 _DevPercent,uint256 _entryPeriod,bool _active);
    function changeRaffleMode(uint256 RaffleModeID, uint256 _DevPercent,uint256 _adminPercent, uint256 _entryPeriod,uint256 _startTicketNo, uint256 _maxTicketCount,uint256 _ticketPrice, bool _active) public onlyOwner returns(bool)
    {
        require(RaffleModeID < RaffleModes.length, "Invalid Raffle ID");
        require(_startTicketNo > 0, "invalid start ticket no");
        require(_maxTicketCount > 9, "invalid max ticket count");        
        RaffleModes[RaffleModeID].DevPercent = _DevPercent;
        RaffleModes[RaffleModeID].adminPercent = _adminPercent;
        RaffleModes[RaffleModeID].entryPeriod = _entryPeriod;
        RaffleModes[RaffleModeID].startTicketNo = _startTicketNo;
        RaffleModes[RaffleModeID].maxTicketCount = _maxTicketCount;
        RaffleModes[RaffleModeID].ticketPrice = _ticketPrice;
        RaffleModes[RaffleModeID].active = _active;
        emit changeRaffleModeEv(now,RaffleModeID,_DevPercent,_entryPeriod,_active);
        return true;
    }

    function changeActiveRaffleMode(uint256 _RaffleModeID, bool _status) public onlyOwner returns (bool)
    {
        RaffleModes[_RaffleModeID].active = _status;
        return true;
    }


    event emergencySweepAllTrxAdminEv(uint256 timeNow, uint256 amount);
    /**
     * Just in rare case, owner wants to transfer TRX from contract to owner address
     */
    function emergencySweepAllTrxAdmin() public onlyOwner returns (bool){
        uint256 Amount = address(this).balance;
        address(owner).transfer(Amount);
        emergencyWithdrawnByAdmin = emergencyWithdrawnByAdmin.add(Amount);
        emit emergencySweepAllTrxAdminEv(now, Amount);
        return true;
    }

    /**
     * Just in rare case, owner wants to transfer TRX from contract to owner address
     */
    function manualWithdrawTrxAdmin(uint256 Amount) public onlyOwner returns (bool){
        require (totalAdminComission.sub(withdrawnByAdmin) >= Amount);
        address(owner).transfer(Amount);
        withdrawnByAdmin = withdrawnByAdmin.add(Amount);
        return true;
    }

    /**
     * Just in rare case, owner wants to transfer TRX from contract to owner address
     */
    function manualWithdrawTrxDev(uint256 Amount) public onlyDev returns (bool){
        require (totalDevComission.sub(withdrawnByDev) >= Amount);
        address(owner).transfer(Amount);
        withdrawnByDev = withdrawnByDev.add(Amount);
        return true;
    }


    event buyRaffleTicketEv(uint256 timeNow, address buyer, uint256 lastTicketNo, uint256 noOfTicketBought, uint256 amountPaid, uint256 raffleModeID, uint256 raffleInfoID);

    function buyRaffleTicket(uint256 _noOfTicketToBuy, uint256 _RaffleModeID) public payable returns(bool)
    {
        require(!safeGuard,"System Paused by Admin");
        require(_RaffleModeID < RaffleModes.length , "undefined raffle mode");
        require(RaffleModes[_RaffleModeID].active = true,"this raffle mode is locked by admin");
        address payable caller = msg.sender;
        require(caller != address(0),"invalid caller address(0)");
        uint256 ticketPrice = RaffleModes[_RaffleModeID].ticketPrice;
        uint256 paidValue = msg.value;
        require(paidValue == _noOfTicketToBuy * ticketPrice, "Paid Amount is less than required" );
        
        totalTicketSaleValueOfAllRaffleSession += paidValue;

        uint256 raffleInfoID = RaffleInfos.length;
        uint256 i ;
        if (raffleInfoID == 0 || RaffleInfos[raffleInfoID -1 ].winnerDeclared )
        {
            RaffleInfo memory temp;
            temp.totalTrxCollected = paidValue;
            i = RaffleModes[_RaffleModeID].startTicketNo;
            temp.lastSoldTicketNo = RaffleModes[_RaffleModeID].startTicketNo + _noOfTicketToBuy - 1 ;
            temp.startTime = now;
            temp.winnerDeclared = false;
            temp.rewardDistributed = false;
            temp.raffleMode = _RaffleModeID;
            temp.thisBlockNo = block.number;
            RaffleInfos.push(temp);
        }
        else
        {
            raffleInfoID -= 1;
            require(now <= RaffleInfos[raffleInfoID].startTime.add(RaffleModes[RaffleInfos[raffleInfoID].raffleMode].entryPeriod), "sorry period is over");
            RaffleInfos[raffleInfoID].totalTrxCollected += paidValue;
            i = RaffleInfos[raffleInfoID].lastSoldTicketNo + 1; 
            RaffleInfos[raffleInfoID].lastSoldTicketNo = i +  _noOfTicketToBuy -1;           
            RaffleInfos[raffleInfoID].thisBlockNo = block.number;          
        }
        uint256 range = i + _noOfTicketToBuy;
        for (i; i< range; i++)
        {
           ticketOwner[raffleInfoID][i] = caller; 
           ticketsBought[caller][raffleInfoID].push(i);
        }

        uint256 DevPart = calculatePercentage(paidValue,RaffleModes[RaffleInfos[raffleInfoID].raffleMode].DevPercent);  // This is comission for admin
        uint256 adminPart = calculatePercentage(paidValue,RaffleModes[RaffleInfos[raffleInfoID].raffleMode].adminPercent); // This is comission for dev
        RaffleInfos[raffleInfoID].devComission += DevPart;
        RaffleInfos[raffleInfoID].adminComission += adminPart;
        totalDevComission += DevPart;
        totalAdminComission += adminPart;

        emit buyRaffleTicketEv(now, caller, RaffleInfos[raffleInfoID].lastSoldTicketNo, _noOfTicketToBuy, paidValue,_RaffleModeID, raffleInfoID);        
        return true;
    }

    event selectWinnerEv(uint256 nowTime,uint256 startingNoRef, uint256 RaffleID,uint256 blockNo, bytes32 blockHashValue,uint256[10] winnerNo );
    function selectWinner(uint256 raffleInfoID, bytes32 blockHashValue ) public onlyOwner returns(bool)
    {
        require(RaffleInfos[raffleInfoID].winnerDeclared == false, "winner is already declared"); 
        require(now > RaffleInfos[raffleInfoID].startTime.add(RaffleModes[RaffleInfos[raffleInfoID].raffleMode].entryPeriod), "sorry period is not over");      
        //require(now > RaffleInfos[raffleInfoID].startTime.add(RaffleModes[RaffleInfos[raffleInfoID].raffleMode].entryPeriod), "entry period is not over");
        //bytes32 blockHashValue = bytes32(blockHashValueAsHex);
        uint256 lastBetBlockNo = RaffleInfos[raffleInfoID].thisBlockNo;

        if(block.number < 255 + lastBetBlockNo )
        {
            blockHashValue = blockhash(lastBetBlockNo);
        }
        require(blockHashValue != 0x0, "invalid blockhash" );

         // In blow line house comission is just a temporary value of upper bound of range 0-99 , this house comission will assigned a real value when reqard distribution
        uint256[10] memory winnerTicketNo;

        uint256 startTicketNo = RaffleModes[RaffleInfos[raffleInfoID].raffleMode].startTicketNo;
        uint256 rangeFromZero = RaffleInfos[raffleInfoID].lastSoldTicketNo - startTicketNo + 1;
        winnerTicketNo[0] = uint256(blockHashValue) % rangeFromZero ;
        RaffleInfos[raffleInfoID].winningNo[0] = winnerTicketNo[0] + startTicketNo;
        winnerTracker[raffleInfoID][winnerTicketNo[0]] = true;
        blockHashValue = keccak256(abi.encodePacked(blockHashValue,now));
        uint256 i;
        for (i=1;i<10;i++)
        {
            winnerTicketNo[i] = uint256(keccak256(abi.encodePacked(blockHashValue, winnerTicketNo[i-1]))) % rangeFromZero;
            if (winnerTracker[raffleInfoID][winnerTicketNo[i]]== true)
            {
                i=i-1;
            }
            else
            {
                RaffleInfos[raffleInfoID].winningNo[i] = winnerTicketNo[i] + startTicketNo;
                winnerTracker[raffleInfoID][winnerTicketNo[i]] = true;
            }
            blockHashValue = keccak256(abi.encodePacked(blockHashValue,now));
        }

        RaffleInfos[raffleInfoID].winnerDeclared = true;

        emit selectWinnerEv(now,startTicketNo,raffleInfoID , lastBetBlockNo, blockHashValue, winnerTicketNo );
        return true;
    }

    event  claimWinnerRewardEv(uint256 timeNow,uint256 DevPart,uint256 adminPart,uint256 winningAmountDistributed );
    function claimWinnerReward(uint256 raffleInfoID) public returns (bool)
    {
            require(RaffleInfos[raffleInfoID].winnerDeclared == true, "winner is not declared"); 
            require(RaffleInfos[raffleInfoID].rewardDistributed == false, "reward is already distributed"); 
            uint256 totalTrx = RaffleInfos[raffleInfoID].totalTrxCollected;  // A is total bet here 
            uint256 DevPart = calculatePercentage(totalTrx,RaffleModes[RaffleInfos[raffleInfoID].raffleMode].DevPercent);  // B is comission for system
            uint256 adminPart = calculatePercentage(totalTrx,RaffleModes[RaffleInfos[raffleInfoID].raffleMode].adminPercent); // D is comission for admin

            uint256 remainingPart;

            remainingPart = totalTrx.sub(DevPart.add(adminPart));  // C is net reward here
            uint256 i;
            // transfering winning prize from 1st to 10th winner as assigned percent
            for (i=0; i < 10; i++)
            {    
                ticketOwner[raffleInfoID][RaffleInfos[raffleInfoID].winningNo[i]].transfer(calculatePercentage(remainingPart, winnerRewardPercent[i]));
            }

            RaffleInfos[raffleInfoID].winningAmount = remainingPart; 
            RaffleInfos[raffleInfoID].rewardDistributed = true;

            emit  claimWinnerRewardEv(now, DevPart, adminPart, remainingPart );
        return true;
    }

    function viewWinnerList(uint256 raffleInfoID) public view returns(uint256[10] memory winnerTicket, address[10] memory winner)
    {
        uint256 i;
        for (i=0; i < 10; i++)
        {
            winnerTicket[i] = RaffleInfos[raffleInfoID].winningNo[i];
            winner[i] = ticketOwner[raffleInfoID][winnerTicket[i]];
        }
        return (winnerTicket, winner);       
    }

    function viewMyWinningAmount(uint256 raffleInfoID) public view returns (uint256)
    {
        uint256 winningAmount;
        uint256 winnerTicket;
        address winner;
        uint256 i;
        uint256 totalTrx = RaffleInfos[raffleInfoID].totalTrxCollected;  // A is total bet here 
        uint256 DevPart = calculatePercentage(totalTrx,RaffleModes[RaffleInfos[raffleInfoID].raffleMode].DevPercent);  // B is comission for system
        uint256 adminPart = calculatePercentage(totalTrx,RaffleModes[RaffleInfos[raffleInfoID].raffleMode].adminPercent); // D is comission for admin
        uint256 remainingPart;
        remainingPart = totalTrx.sub(DevPart.add(adminPart));  // C is net reward here

        for (i=0; i < 10; i++)
        {
            winnerTicket = RaffleInfos[raffleInfoID].winningNo[i];
            winner = ticketOwner[raffleInfoID][winnerTicket];
            if (winner == msg.sender)
            {
                winningAmount = calculatePercentage(remainingPart, winnerRewardPercent[i]);
                return winningAmount;
                break;
            }
        } 
        return 0;      
    }


}