//SourceUnit: TurboTrxSmartContract.sol

/*####################################################################################################################################
#
#
#                                                           - WELCOME TO -
#                                                                                                                        
#   @@@@@@@@@@    @@@     @@@     @@@@@@@@       @@@@@@@@         @@@@@@      @@@@@@@@@@@    @@@@@@@@      @@@,    @@@  
#      (@@        @@@     @@@     @@    /@@@     @@@   *@@%     @@@    @@@        @@@        @@@    @@@      @@@  @@@   
#      (@@        @@@     @@@     @@     @@@     @@@@@@@@@     @@@      @@@       @@@        @@@    @@@       @@@@@     
#      (@@        @@@     @@@     @@@@@@@@       @@@   @@@@    @@@      @@@       @@@        @@@@@@@@@        @@@@@     
#      (@@        /@@@   ,@@@     @@    @@@      @@@    @@@     @@@    @@@        @@@        @@@   @@@       @@@ #@@    
#      (@@          *@@@@@&       @@    #@@&     @@@@@@@@         @@@@@@          @@@        @@@    @@@    @@@     @@@  
#
#
#     TurboTrx Is The Most Genius System
#     With Our Unique Turbocharge System - Nobody Gets Left Behind.     
#     
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#---------------------------------------------------- Join Now : www.turbotrx.io ----------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
#     Developed by hustydesigns.com (support@hustydesigns.com)
#
#####################################################################################################################################*/
pragma solidity ^0.5.9;

contract TurboTrxSmartContract {
    
    struct User {
        uint id;
        address inviter; //Person who invited this user.
        uint usersReferred; //All personal referrals-count the user brought to platform.
        uint recycles; //Total times user recycled.
        address[] paymentSlots; //Max 2 and then recycles happen.
        address[] matrixSlots; //Max 2 and then spillover happen.
        bool[] spillAssigned;
        address sponsor; //Programmed sponsor assigned to this user.
        address[] incentiveSlots; //Max 2 and then spilled.
    }
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    //Configuration
    uint public constant activationCost = 1333 trx;
    uint public constant incentiveCost = 333 trx;
    uint public constant inviterCost = 333 trx;
    uint public constant sponsorCost = 667 trx;
    
    uint public lastUserId = 2;
    address public owner;
    
    //Events for communication
    event recordPayments(address indexed payerAddress, uint indexed payer_id, uint inviter_id, uint sponsor_id, uint receiver_id, uint cycle_count);
    event recordAirdropPayment(uint sponsor_id, uint paymentReceiver, uint cycle_count);
    event paymentExtras(bytes32 payment_type);
    event cyclePayment(uint indexed payer_id, uint receiver_id, uint cycle_count);
    event airdropTransferComplete(uint256 indexed rowID);
    event bonusTransferComplete(uint256 indexed rowID);

    //Set Whitelisted Addresses for Leaders
    address[] public leaderAddresses;
    
    constructor(address ownerAddress) public {
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            inviter: owner,
            usersReferred: 0,
            recycles: 0,
            paymentSlots: new address[](0),
            matrixSlots: new address[](0),
            spillAssigned: new bool[](0),
            sponsor: owner,
            incentiveSlots: new address[](0)
        });
        
        users[ownerAddress] = user;
        
        users[ownerAddress].spillAssigned.push(false);
        users[ownerAddress].spillAssigned.push(false);
        
        idToAddress[1] = ownerAddress;
        userIds[1] = ownerAddress;
        
        //Save Leaders Addresses
        leaderAddresses.push(0x99e83DD8C88F9e06d1155A4f0F75C94DD37eA77e); // ID 2 //TPzzbqXnhku56aHZAATX2TpahkUHuVHFct
        leaderAddresses.push(0x7315E8b7675Ed57310fF876dE1629B73464B8630); // ID 3 //TLTixPPhoQCwrvt3Y6YcMqsefoeYS2HSKQ
        leaderAddresses.push(0xAfe781Dcda3C3f9f4E646DEC96AB01eE08846f32); // ID 4 //TS1Jb36HCMvaE7KdzyPrBSLzZNcjpDsaDV
        leaderAddresses.push(0x0FDF654BAFb0a4df72aD1c1cbD9bb91Dac7296b9); // ID 5 //TBR8kjvT8q5NMM9sJSyYRoXhKPXFxTazRn
        leaderAddresses.push(0x1F7788Ec924036A0118580604247C107d9D61da7); // ID 6 //TCqb9S6E7CS2vASpKres1CupPhwW9csBX1
        leaderAddresses.push(0xA825a3796774c9E4a99dE5257De81CC8f0941B2c); // ID 7 //TRJHcTeezHdsuvqHoUtX4xK41KpGVftfxR
        leaderAddresses.push(0xdB987b29D39D50bd532bceEAcedC0099063040bE); // ID 8 //TVzKeeEzxFRYXou7ywjCVLfEpMggkcAYVS
        leaderAddresses.push(0xB6021ba719A662C2ddf3969d36d8DD808e7Fa965); // ID 9 //TSZaWSTqWeMt6JF9RzAM3rbk5fCQYpFWH2
        leaderAddresses.push(0x0e6d1eaFD1d8ceE1636DA45f2f26cB2afdEd040A); // ID 10 //TBHVBXUA8YzyBKY18q5bQuv9wXVwmNWm9U
        leaderAddresses.push(0x105EE6E06AB5707C6c5f3f4c85081E7663633513); // ID 11 //TBTmW2RBDgYU5CwqanntSbrYs8gpDHpKC8
        leaderAddresses.push(0x838474725cB5BdDf57cCd56a033985Fe19ACf557); // ID 12 //TMxcCKCDWoCBp9EE6g4AGYAqJ2ka5cUa3x
        leaderAddresses.push(0x4e9FD4bEFD48855d7A476C460bA4AA30537845C1); // ID 13 //TH8wBH2K4rTzBn1Ek7wkBP2aiVH7xRdGxC
        leaderAddresses.push(0x5142916a9fA316a8348f1bF2d4ffBEEe3a7D6DaA); // ID 14 //THNsUppYjZ1FQagCKAUdKvbAEd2a4M1Vtq
        leaderAddresses.push(0xc8bDcB0Ad048444BA28EB5Ed5851d5Df03E37D10); // ID 15 //TUGdWUyjzfAguL72fHYregk3gF9nmg397H
        leaderAddresses.push(0xfAD776f5e69560322171A6972BE857BE2aFEF8d7); // ID 16 //TYqY3mN47LpuDZeCLKdGF6w4eJtaxrAmus
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
        if(lastUserId <= 16) {
            require(checkLeaderWhiteList(lastUserId-2) == msg.sender, "Address Not Whitelisted");
        }
        require(msg.value == 1333 trx, "Activation cost 1333 TRX");
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
            usersReferred: 0,
            recycles: 0,
            paymentSlots: new address[](0),
            matrixSlots: new address[](0),
            spillAssigned: new bool[](0),
            sponsor: address(0),
            incentiveSlots: new address[](0)
        });
        
        users[userAddress] = user;
        
        users[userAddress].spillAssigned.push(false);
        users[userAddress].spillAssigned.push(false);
        
        idToAddress[lastUserId] = userAddress;
        userIds[lastUserId] = userAddress;
        
        lastUserId++;
        users[inviterAddress].usersReferred++;

        address sponsor = decideSponsor(users[userAddress].inviter);
        users[userAddress].sponsor = sponsor;
        users[sponsor].matrixSlots.push(userAddress);

        address paymentReceiver = decideReceiver(userAddress, sponsor);
        
        //Divide payment between each receiver.
        
        //Payment to Inviter
        if (!address(uint160(inviterAddress)).send(inviterCost)) {
            address(uint160(inviterAddress)).transfer(inviterCost);
        }
        //Payment to Admin incentive program
        if (!address(uint160(owner)).send(incentiveCost)) {
            address(uint160(owner)).transfer(incentiveCost);
        }
        //Payment to Sponsor
        if (!address(uint160(paymentReceiver)).send(sponsorCost)) {
            address(uint160(paymentReceiver)).transfer(sponsorCost);
        }
        emit recordPayments(userAddress, users[userAddress].id, users[inviterAddress].id, users[sponsor].id, users[paymentReceiver].id, users[paymentReceiver].recycles);
        return;
    }
    
    function decideSponsor(address chosenSponsor) private returns(address) {
        
        if(users[chosenSponsor].matrixSlots.length >= 2) {
            
            emit paymentExtras('top spill');
            
            if(users[users[chosenSponsor].matrixSlots[0]].matrixSlots.length < users[users[chosenSponsor].matrixSlots[1]].matrixSlots.length) {
                return users[chosenSponsor].matrixSlots[0];
            } else if(users[users[chosenSponsor].matrixSlots[0]].matrixSlots.length > users[users[chosenSponsor].matrixSlots[1]].matrixSlots.length) {
                return users[chosenSponsor].matrixSlots[1];
            } else if(users[users[chosenSponsor].matrixSlots[0]].matrixSlots.length >= 2 &&  users[users[chosenSponsor].matrixSlots[1]].matrixSlots.length >= 2) {
                
                if(users[chosenSponsor].spillAssigned[0] == false) {
                    users[chosenSponsor].spillAssigned[0] = true;
                    return decideSponsor(users[chosenSponsor].matrixSlots[0]);
                } else if(users[chosenSponsor].spillAssigned[1] == false) {
                    users[chosenSponsor].spillAssigned[1] = false;
                    users[chosenSponsor].spillAssigned[0] = false;
                    return decideSponsor(users[chosenSponsor].matrixSlots[1]);
                }
                
            } else {
                return users[chosenSponsor].matrixSlots[0];
            }
            
        } else {
            return chosenSponsor;
        }
    }
    
    function decideReceiver(address userAddress, address sponsor) private returns(address) {
    
        if(users[sponsor].paymentSlots.length < 1) {
            users[sponsor].paymentSlots.push(userAddress);
            return sponsor;
        }
        
        //Reset the paymentSlots Object to 0 payments
        users[sponsor].paymentSlots = new address[](0);
        emit paymentExtras('cycle spill');
        
        if(sponsor == owner) {
            users[sponsor].recycles++;
            return sponsor;
        } else {
            users[sponsor].recycles++;
            emit cyclePayment(users[userAddress].id, users[sponsor].id, users[sponsor].recycles);
            return decideReceiver(userAddress, users[sponsor].sponsor);
        }
    }
    
    //Incentive Bonus Crediter Fn (By escrow wallet only)
    function performBonusTransfer(uint256 lastID, uint256[] memory payToIds, uint256[] memory amounts) public payable {
        require(msg.sender == owner, "Restricted to Admin only!");
        
        for(uint256 i=0; i<payToIds.length; i++) {
            address thisUser = idToAddress[payToIds[i]];
            if (!address(uint160(thisUser)).send(amounts[i]*1000000)) {
                address(uint160(thisUser)).transfer(amounts[i]*1000000);
            }
        }
        
        emit bonusTransferComplete(lastID);
    }
    
    //Incentive Program Air Drop (By escrow wallet only)
    function performAirDrop(uint256 lastID, uint256 positions) external payable {
        require(msg.value == 667 trx * positions, "Required 667 x POS TRX");
        require(msg.sender == owner, "Restricted to Admin only!");
    
        address airdropPerformer = msg.sender;
        
        uint32 size;
        assembly {
            size := extcodesize(airdropPerformer)
        }
        require(size == 0, "Cannot be a contract");
        
        
        for(uint256 i=1;i<=positions; i++) {
            address sponsor = decideAirdropSponsor(users[airdropPerformer].inviter);
            users[sponsor].incentiveSlots.push(airdropPerformer);
            
            address paymentReceiver = decideReceiver(airdropPerformer, sponsor);

            //Divide payment between each receiver.
            
            //Payment to Sponsor
            if (!address(uint160(paymentReceiver)).send(sponsorCost)) {
                address(uint160(paymentReceiver)).transfer(sponsorCost);
            }
            
            emit recordAirdropPayment(users[sponsor].id, users[paymentReceiver].id, users[paymentReceiver].recycles);
            
        }
        
        emit airdropTransferComplete(lastID);
    }
    
    function decideAirdropSponsor(address chosenSponsor) private returns(address) {
        
        if((users[chosenSponsor].matrixSlots.length + users[chosenSponsor].incentiveSlots.length) >= 2) {
            
            if(users[chosenSponsor].matrixSlots.length >= 2) {
                emit paymentExtras('top spill');
                uint256 user1Slots = users[users[chosenSponsor].matrixSlots[0]].matrixSlots.length + users[users[chosenSponsor].matrixSlots[0]].incentiveSlots.length;
                uint256 user2Slots = users[users[chosenSponsor].matrixSlots[1]].matrixSlots.length + users[users[chosenSponsor].matrixSlots[1]].incentiveSlots.length;
                
                if(user1Slots < user2Slots) {
                    return users[chosenSponsor].matrixSlots[0];
                } else if(user1Slots > user2Slots) {
                    return users[chosenSponsor].matrixSlots[1];
                } else if(user1Slots >= 2 &&  user2Slots >= 2) {
                    
                    if(users[chosenSponsor].spillAssigned[0] == false) {
                        users[chosenSponsor].spillAssigned[0] = true;
                        return decideAirdropSponsor(users[chosenSponsor].matrixSlots[0]);
                    } else if(users[chosenSponsor].spillAssigned[1] == false) {
                        users[chosenSponsor].spillAssigned[1] = false;
                        users[chosenSponsor].spillAssigned[0] = false;
                        return decideAirdropSponsor(users[chosenSponsor].matrixSlots[1]);
                    }
                    
                } else {
                    return users[chosenSponsor].matrixSlots[0];
                }
                
            } else if(users[chosenSponsor].matrixSlots.length == 1) {
                return decideAirdropSponsor(users[chosenSponsor].matrixSlots[0]);
            } else {
                return decideAirdropSponsor(owner);
            }
            
        } else {
            return chosenSponsor;
        }
        
    }
    
    function programFreeSlots() public view returns (uint256) {
        uint256 emptySlots = 0;
        for(uint256 i=1; i<lastUserId; i++) {
            address thisUser = idToAddress[i];
            if((users[thisUser].matrixSlots.length + users[thisUser].incentiveSlots.length) < 2) {
                if(users[thisUser].matrixSlots.length + users[thisUser].incentiveSlots.length == 1) {
                    emptySlots = emptySlots + 1;
                } else {
                    emptySlots = emptySlots + 2;
                }
            }
        }
        return emptySlots;
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
    function userMatrixSlots(address userAddress) public view returns(address[] memory) {
        return (users[userAddress].matrixSlots);
    }
    function userPaymentSlots(address userAddress) public view returns(address[] memory) {
        return (users[userAddress].paymentSlots);
    }
    function userIncentiveSlots(address userAddress) public view returns(address[] memory) {
        return (users[userAddress].incentiveSlots);
    }
    function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	//Leaders Signup Whitelist Function
	function checkLeaderWhiteList(uint256 userID) private view returns (address) {
	    return leaderAddresses[userID];
	}
}