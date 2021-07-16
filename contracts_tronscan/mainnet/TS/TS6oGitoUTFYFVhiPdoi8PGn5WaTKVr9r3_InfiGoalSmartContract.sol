//SourceUnit: infigoal.sol

/**
* INFIGOAL.IO - VERIFIED SMART CONTRACT
*                                  
* 


  @@@.  @@@@@     @@@   @@@@@@@@@@@.  @@@@    @@@@@@@@@@@      @@@@@@@@@@@@         %@@@@@        @@@                @@@    @@@@@@@@@@@@    
  @@@.  @@@@@@    @@@   @@@           @@@@  @@@@       @@@    @@@        @@@       *@@@.@@@       @@@                @@@  .@@@       ,@@@   
  @@@.  @@@ /@@@  @@@   @@@@@@@@@     @@@@  @@@     %%%%%%,  @@@(        @@@&      @@@  @@@&      @@@                @@@  @@@.        @@@#  
  @@@.  @@@   @@@ @@@   @@@           @@@@  @@@      @@@@@*  @@@@        @@@*     @@@    @@@(     @@@                @@@  @@@@        @@@   
  @@@.  @@@    .@@@@@   @@@           @@@@   @@@@     @@@@*   @@@@      @@@@     @@@@@@@@@@@@,    @@@                @@@   @@@@     ,@@@@   
  @@@.  @@@      @@@@   @@@           @@@@     @@@@@@@@ @@*     @@@@@@@@@,      @@@        @@@.   @@@@@@@@@@@   @@   @@@     @@@@@@@@@      





* https://infigoal.io
* Smart Contract Matrix with Unique Plans
* Activation Cost : 200 TRX | 16 Total Phases | X3 & XS Matrix
**/

pragma solidity 0.5.9;

contract InfiGoalSmartContract {
    
    struct User {
        uint id;
        address inviter;
        uint partnersCount;
        
        //X3 Tables
        mapping(uint8 => bool) activeX3Phases;
        mapping(uint8 => X3) x3Matrix;
        
        //XS Tables
        mapping(uint8 => bool) activeXSPhases;
        mapping(uint8 => address[]) usersXSDirectRefs;
        mapping(uint8 => bool[]) usersXSSpillAssigned;
        mapping(uint8 => address) XSUpline;
        mapping(uint8 => XSL1) XSL1Matrix;
        mapping(uint8 => XSL2) XSL2Matrix;
    }
    
    struct X3 {
        address paidto;
        address[] referrals;
        uint8 reinvestCount;
    }
    
    struct XSL1 {
        address paidto;
        address[] referrals;
        uint8 reinvestCount;
    }
    
    struct XSL2 {
        address paidto;
        address[] referrals;
        uint8 reinvestCount;
    }
    
    uint8 public constant TOTAL_PHASES = 16;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public X3PhaseCost;
    
    mapping(uint8 => uint) public XSL1Cost;
    mapping(uint8 => uint) public XSL2Cost;
    
    event activationComplete(address indexed userAddress, address indexed inviterAddress, uint id, uint inviter_id);
    event phaseUpgraded(uint indexed payer_id, address payerAddress, uint indexed receiver_id, address receiverAddress, uint reinvestCount, uint phase_id, uint level_id);
    event upgradeExtras(uint phase_id, uint level_id, bytes32 txntype);
    event infoPayment(uint indexed payer_id, address payerAddress, uint indexed receiver_id, address receiverAddress, uint reinvestCount, uint phase_id, uint level_id, bytes32 info);
    event upgradeComplete(uint indexed payer_id, uint indexed inviter_id, uint phase_id, uint level_id);
    
    constructor(address ownerAddress) public {
        X3PhaseCost[1] = 50 * 1e6;
        XSL1Cost[1] = 50 * 1e6;
        XSL2Cost[1] = XSL1Cost[1] * 2;
        
        for (uint8 i = 2; i <= TOTAL_PHASES; i++) {
            X3PhaseCost[i] = X3PhaseCost[i-1] * 2;
            XSL1Cost[i] = XSL1Cost[i-1] * 2;
            XSL2Cost[i] = XSL2Cost[i-1] * 2;
        }
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            inviter: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= TOTAL_PHASES; i++) {
            users[ownerAddress].activeX3Phases[i] = true;
            users[ownerAddress].activeXSPhases[i] = true;
            users[ownerAddress].XSUpline[i] = ownerAddress;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return activateProcess(msg.sender, owner);
        }
        activateProcess(msg.sender, bytesToAddress(msg.data));
    }

    function activatePlatform(address inviterAddress) external payable {
        activateProcess(msg.sender, inviterAddress);
    }
    
    function activateProcess(address userAddress, address inviterAddress) private {
        require(msg.value == 200 * 1e6, "Activation cost 200 TRX");
        require(!isUserExists(userAddress), "User already exists");
        require(isUserExists(inviterAddress), "Inviter Doesnt exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "Cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            inviter: inviterAddress,
            partnersCount: 0
        });
        
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        userIds[lastUserId] = userAddress;
        
        users[userAddress].inviter = inviterAddress;
        
        lastUserId++;
        users[inviterAddress].partnersCount++;
    
        processX3(userAddress, 1);
        processXS(userAddress, 1);
        emit activationComplete(userAddress, inviterAddress, users[userAddress].id, users[inviterAddress].id);
    }
    
    function purchasePhase(uint8 plan, uint8 phase_id)  external payable {
        require(isUserExists(msg.sender), "User doesnt exist");
        require(phase_id > 1 && phase_id <= TOTAL_PHASES, "Invalid Phase");
        require(phase_id != 1, "Register first");
        require(plan >= 1 && plan <= 2, "Invalid Plan");
        
        if(plan == 1) {
            
            require(msg.value == X3PhaseCost[phase_id], "Invalid Amount");
            require(!users[msg.sender].activeX3Phases[phase_id], "Phase already purchased");
            require(users[msg.sender].activeX3Phases[phase_id-1], "Previous phase invalid");
            processX3(msg.sender, phase_id);
            
            emit upgradeComplete(users[msg.sender].id, users[users[msg.sender].inviter].id, phase_id, 0);
        
        } else if(plan == 2) {
            
            require(msg.value == XSL1Cost[phase_id]+XSL2Cost[phase_id], "Invalid Amountd");
            require(!users[msg.sender].activeXSPhases[phase_id], "Phase already purchased");
            require(users[msg.sender].activeXSPhases[phase_id-1], "Previous phase invalid");
            processXS(msg.sender, phase_id);
            
            emit upgradeComplete(users[msg.sender].id, users[users[msg.sender].inviter].id, phase_id, 1);
            
        }
        
    }
    
    function processX3(address userAddress, uint8 phase_id)  private {
        users[userAddress].activeX3Phases[phase_id] = true;
    
        address X3Receiver = decideX3Receiver(userAddress, phase_id);
        users[userAddress].x3Matrix[phase_id].paidto = X3Receiver;
        users[X3Receiver].x3Matrix[phase_id].referrals.push(userAddress);
        
        if (!address(uint160(X3Receiver)).send(X3PhaseCost[phase_id])) {
            address(uint160(X3Receiver)).transfer(X3PhaseCost[phase_id]);
        }
        
        emit phaseUpgraded(users[userAddress].id, userAddress, users[X3Receiver].id, X3Receiver, users[X3Receiver].x3Matrix[phase_id].reinvestCount, phase_id, 0);
        return;
    }
    
    function processXS(address userAddress, uint8 phase_id)  private {
        users[userAddress].activeXSPhases[phase_id] = true;
        address sponsor = decideXSSponsor(users[userAddress].inviter, 1);
        
        users[sponsor].usersXSDirectRefs[phase_id].push(userAddress);
        users[sponsor].usersXSSpillAssigned[phase_id].push(false);
        users[userAddress].XSUpline[phase_id] = sponsor;
        
        address XSL1Receiver = decideXSReceiver(userAddress, phase_id, 1);
        address XSL2Receiver = decideXSReceiver(userAddress, phase_id, 2);
        
        users[userAddress].XSL1Matrix[phase_id].paidto = XSL1Receiver;
        users[userAddress].XSL2Matrix[phase_id].paidto = XSL2Receiver;
        users[XSL1Receiver].XSL1Matrix[phase_id].referrals.push(userAddress);
        users[XSL2Receiver].XSL2Matrix[phase_id].referrals.push(userAddress);
        
        if (!address(uint160(XSL1Receiver)).send(XSL1Cost[phase_id])) {
            address(uint160(XSL1Receiver)).transfer(XSL1Cost[phase_id]);
        }
        if (!address(uint160(XSL2Receiver)).send(XSL2Cost[phase_id])) {
            address(uint160(XSL2Receiver)).transfer(XSL1Cost[phase_id]);
        }
        
        emit phaseUpgraded(users[userAddress].id, userAddress, users[XSL1Receiver].id, XSL1Receiver, users[XSL1Receiver].XSL1Matrix[phase_id].reinvestCount, phase_id, 1);
        emit phaseUpgraded(users[userAddress].id, userAddress, users[XSL2Receiver].id, XSL2Receiver, users[XSL2Receiver].XSL2Matrix[phase_id].reinvestCount, phase_id, 2);
        
        return;
    }
    
    function decideX3Receiver(address userAddress, uint8 phase_id) private returns(address) {
    
        if(!users[users[userAddress].inviter].activeX3Phases[phase_id]) {
            emit infoPayment(users[userAddress].id, userAddress, users[users[userAddress].inviter].id, users[userAddress].inviter, 0,  phase_id, 0, 'missed');
            emit upgradeExtras(phase_id, 0, 'gift');
            return decideX3Receiver(users[userAddress].inviter, phase_id);
        }
        
        if (users[users[userAddress].inviter].x3Matrix[phase_id].referrals.length < 2) {
            return users[userAddress].inviter;
        }
        emit upgradeExtras(phase_id, 0, 'bot overflow');

        users[users[userAddress].inviter].x3Matrix[phase_id].referrals = new address[](0);
        
        if(users[userAddress].inviter == owner) {
            users[users[userAddress].inviter].x3Matrix[phase_id].reinvestCount++;
            return users[userAddress].inviter;
        } else {
            emit infoPayment(users[userAddress].id, userAddress, users[users[userAddress].inviter].id, users[userAddress].inviter, users[users[userAddress].inviter].x3Matrix[phase_id].reinvestCount, phase_id, 0, 'reinvest');
            users[users[userAddress].inviter].x3Matrix[phase_id].reinvestCount++;
            return decideX3Receiver(users[userAddress].inviter, phase_id);
        }
    }
    
    function decideXSSponsor(address chosenSponsor, uint8 phase_id) private returns(address) {
        
        if(!users[chosenSponsor].activeXSPhases[phase_id]) {
            address nextSponsor = users[chosenSponsor].inviter;
            return decideXSSponsor(nextSponsor, phase_id);
        }
        
        if(users[chosenSponsor].usersXSDirectRefs[phase_id].length >= 3) {
            
            uint256[] memory eachRefReferrals = new uint256[](3);
            
            eachRefReferrals[0] = users[users[chosenSponsor].usersXSDirectRefs[phase_id][0]].usersXSDirectRefs[phase_id].length;
            eachRefReferrals[1] = users[users[chosenSponsor].usersXSDirectRefs[phase_id][1]].usersXSDirectRefs[phase_id].length;
            eachRefReferrals[2] = users[users[chosenSponsor].usersXSDirectRefs[phase_id][2]].usersXSDirectRefs[phase_id].length;
            
            uint256 eligiblePartner = 0;
            for(uint256 i=0;i<3;i++) {
                if(eachRefReferrals[i] < eachRefReferrals[eligiblePartner]) {
                    eligiblePartner = i;
                }
            }
            
            if(eachRefReferrals[eligiblePartner] >= 3) {
                
                emit upgradeExtras(phase_id, 1, 'top overflow');
                emit upgradeExtras(phase_id, 2, 'top overflow');
                
                uint8 drilledSponsor = 0;
                if(!users[chosenSponsor].usersXSSpillAssigned[phase_id][0]) {
                    drilledSponsor = 1;
                } else if(!users[chosenSponsor].usersXSSpillAssigned[phase_id][1]) {
                    drilledSponsor = 2;
                } else if(!users[chosenSponsor].usersXSSpillAssigned[phase_id][2]) {
                    drilledSponsor = 3;
                }
                
                if(drilledSponsor == 0) {
                    users[chosenSponsor].usersXSSpillAssigned[phase_id][0] = true;
                    users[chosenSponsor].usersXSSpillAssigned[phase_id][1] = false;
                    users[chosenSponsor].usersXSSpillAssigned[phase_id][2] = false;
                    drilledSponsor = 1;
                } else {
                    users[chosenSponsor].usersXSSpillAssigned[phase_id][drilledSponsor-1] = true;
                }
                return decideXSSponsor(users[chosenSponsor].usersXSDirectRefs[phase_id][drilledSponsor-1], phase_id);
            }
            return decideXSSponsor(users[chosenSponsor].usersXSDirectRefs[phase_id][eligiblePartner], phase_id);
            
            
        } else {
            return chosenSponsor;
        }
    }
    
    function decideXSReceiver(address userAddress, uint8 phase_id, uint8 level_id) private returns(address) {
        
        if(level_id == 1) {
            address sponsorAddress = users[userAddress].XSUpline[phase_id];
            
            if(!users[sponsorAddress].activeXSPhases[phase_id]) {
                emit infoPayment(users[userAddress].id, userAddress, users[sponsorAddress].id, sponsorAddress, 0, phase_id, 1, 'missed');
                emit upgradeExtras(phase_id, level_id, 'gift');
                return decideXSReceiver(sponsorAddress, phase_id, level_id);
            }
            
            if(users[sponsorAddress].XSL1Matrix[phase_id].referrals.length < 2) {
                return sponsorAddress;
            }
            emit upgradeExtras(phase_id, level_id, 'bot overflow');
            users[sponsorAddress].XSL1Matrix[phase_id].referrals = new address[](0);
            
            if(sponsorAddress == owner) {
                users[sponsorAddress].XSL1Matrix[phase_id].reinvestCount++;
                return sponsorAddress;
            } else {
                emit infoPayment(users[userAddress].id, userAddress, users[sponsorAddress].id, sponsorAddress, users[sponsorAddress].XSL1Matrix[phase_id].reinvestCount, phase_id, 1, 'reinvest');
                users[sponsorAddress].XSL1Matrix[phase_id].reinvestCount++;
                return decideXSReceiver(sponsorAddress, phase_id, level_id);
            }
            
        } else if(level_id == 2) {
            
            address sponsorAddress = users[userAddress].XSUpline[phase_id];
            sponsorAddress = users[sponsorAddress].XSUpline[phase_id];
            
            if(!users[sponsorAddress].activeXSPhases[phase_id]) {
                emit infoPayment(users[userAddress].id, userAddress, users[sponsorAddress].id, sponsorAddress, 0, phase_id, 2, 'missed');
                emit upgradeExtras(phase_id, level_id, 'gift');
                return decideXSReceiver(sponsorAddress, phase_id, level_id);
            }
            
            if(users[sponsorAddress].XSL2Matrix[phase_id].referrals.length < 9) {
                return sponsorAddress;
            }
            emit upgradeExtras(phase_id, level_id, 'bot overflow');
            users[sponsorAddress].XSL2Matrix[phase_id].referrals = new address[](0);
            
            if(sponsorAddress == owner) {
                users[sponsorAddress].XSL2Matrix[phase_id].reinvestCount++;
                return sponsorAddress;
            } else {
                emit infoPayment(users[userAddress].id, userAddress, users[sponsorAddress].id, sponsorAddress, users[sponsorAddress].XSL2Matrix[phase_id].reinvestCount, phase_id, 2, 'reinvest');
                users[sponsorAddress].XSL2Matrix[phase_id].reinvestCount++;
                return decideXSReceiver(sponsorAddress, phase_id, level_id);
            }
            
            
        }
        
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    //Output Functions
    function usersX3Matrix(address userAddress, uint8 phase_id) public view returns(address, address[] memory, uint8) {
        return (users[userAddress].x3Matrix[phase_id].paidto,
                users[userAddress].x3Matrix[phase_id].referrals,
                users[userAddress].x3Matrix[phase_id].reinvestCount);
    }
    function usersXSMatrix(address userAddress, uint8 phase_id) public view returns(address[] memory, uint8, address[] memory, uint8) {
        return (users[userAddress].XSL1Matrix[phase_id].referrals,
                users[userAddress].XSL1Matrix[phase_id].reinvestCount,
                users[userAddress].XSL2Matrix[phase_id].referrals,
                users[userAddress].XSL2Matrix[phase_id].reinvestCount);
    }
}