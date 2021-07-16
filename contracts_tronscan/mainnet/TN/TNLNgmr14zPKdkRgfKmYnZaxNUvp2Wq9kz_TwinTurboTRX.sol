//SourceUnit: TwinTurboTRX.sol

/*####################################################################################################################################
#
#
#                                                   - WELCOME TO TWIN TURBOTRX-
#                                                                                                                        
#   @@@@@@@@@@    @@@     @@@     @@@@@@@@       @@@@@@@@         @@@@@@      @@@@@@@@@@@    @@@@@@@@      @@@,    @@@  
#      (@@        @@@     @@@     @@    /@@@     @@@   *@@%     @@@    @@@        @@@        @@@    @@@      @@@  @@@   
#      (@@        @@@     @@@     @@     @@@     @@@@@@@@@     @@@      @@@       @@@        @@@    @@@       @@@@@     
#      (@@        @@@     @@@     @@@@@@@@       @@@   @@@@    @@@      @@@       @@@        @@@@@@@@@        @@@@@     
#      (@@        /@@@   ,@@@     @@    @@@      @@@    @@@     @@@    @@@        @@@        @@@   @@@       @@@ #@@    
#      (@@          *@@@@@&       @@    #@@&     @@@@@@@@         @@@@@@          @@@        @@@    @@@    @@@     @@@  
#
#
#     Twin TurboTrx - The Smartest Smart Contract Ever Created!
#     
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#---------------------------------------------------- Join Now : www.turbotrx.io ----------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
#     Developed by hustydesigns.com (support@hustydesigns.com)
#
#####################################################################################################################################*/
pragma solidity ^0.5.9;

contract TwinTurboTRX {
    
    struct User {
        uint id;
        address inviter; //Person who invited this user.
        uint usersReferred; //All personal referrals count the user brought to platform.
        
        mapping(uint8 => bool) activeTiers;
        mapping(uint8 => TIER) matrixTier;
    }
    
    struct TIER {
        address paidto;
        address[] matrixSlots; //Maximum 3 and then cycle/reinvest happens
        uint32 cycleCount;
        uint8 airdropsReceived; //Starts from 0 and if 3 referrals or 3 airdrops, no more airdrops thereafter. (Which ever happens first)
    }
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    //Configuration
    mapping(uint8 => uint) public tiersCost;
    
    uint public lastUserId = 2;
    
    mapping(uint => uint) public lastAirdroppedID;
    
    address public owner;
    
    uint8 public TOTAL_TIERS = 5;
    uint256 public USD_RATE = 4900; //FORMULA : Current TRON price * 100000
    
    //Set Whitelisted Addresses for Leaders
    mapping(address => bool) public whitelistAddresses;
    
    //Events for communication  //ATTENTION
    event registerUser(address indexed userAddress, uint user_id, address indexed inviterAddress, uint inviter_id);
    event recordTierPayment(uint indexed payer_id, uint receiver_id, uint tier, uint cycle_count);
    event recordMissedPayment(uint indexed payer_id, uint receiver_id, uint tier, uint cycle_count);
    event recordCyclePayment(uint indexed payer_id, uint receiver_id, uint tier, uint cycle_count);
    event recordAirdropPayment(uint indexed payer_id, uint receiver_id, uint tier, uint cycle_count);
    event paymentExtras(bytes32 payment_type);
    event updateUSDRate(uint256 rate);
    
    event airdropTransferComplete();
    event genericTransferFundsComplete(uint256 indexed mode, uint256 customData);
    
    constructor(address ownerAddress) public {
        
        //Set Tiers Cost in USD
        tiersCost[1] = 40;
        tiersCost[2] = 100;
        tiersCost[3] = 250;
        tiersCost[4] = 500;
        tiersCost[5] = 1000;
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            inviter: address(0),
            usersReferred: uint(0)
        });
        
        users[ownerAddress] = user;
        
        for (uint8 i = 1; i <= 5; i++) {
            users[ownerAddress].activeTiers[i] = true;
            lastAirdroppedID[i] = 1;
            emit recordTierPayment(users[ownerAddress].id, users[ownerAddress].id, i, 0);
        }
        
        idToAddress[1] = ownerAddress;
        userIds[1] = ownerAddress;
        
        //Load the address for whitelisting (Early Access)
        //Creators
        whitelistAddresses[0x99e83DD8C88F9e06d1155A4f0F75C94DD37eA77e] = true; // 2 //TPzzbqXnhku56aHZAATX2TpahkUHuVHFct
        whitelistAddresses[0x7315E8b7675Ed57310fF876dE1629B73464B8630] = true; // 3 //TLTixPPhoQCwrvt3Y6YcMqsefoeYS2HSKQ
        whitelistAddresses[0x82f7560b3efc79A403FB5099608543dEcfB2465C] = true; // 4 //TMuh9DCN7RmVks9Kh6iifFS8tfVZFmfMRR
        whitelistAddresses[0xAfe781Dcda3C3f9f4E646DEC96AB01eE08846f32] = true; // 5 //TS1Jb36HCMvaE7KdzyPrBSLzZNcjpDsaDV
        whitelistAddresses[0x0FDF654BAFb0a4df72aD1c1cbD9bb91Dac7296b9] = true; // 6 //TBR8kjvT8q5NMM9sJSyYRoXhKPXFxTazRn
        whitelistAddresses[0x1F7788Ec924036A0118580604247C107d9D61da7] = true; // 7 //TCqb9S6E7CS2vASpKres1CupPhwW9csBX1
        whitelistAddresses[0xA825a3796774c9E4a99dE5257De81CC8f0941B2c] = true; // 8 //TRJHcTeezHdsuvqHoUtX4xK41KpGVftfxR
        whitelistAddresses[0xdB987b29D39D50bd532bceEAcedC0099063040bE] = true; // 9 //TVzKeeEzxFRYXou7ywjCVLfEpMggkcAYVS
        whitelistAddresses[0xB6021ba719A662C2ddf3969d36d8DD808e7Fa965] = true; // 10 //TSZaWSTqWeMt6JF9RzAM3rbk5fCQYpFWH2
        whitelistAddresses[0x0e6d1eaFD1d8ceE1636DA45f2f26cB2afdEd040A] = true; // 11 //TBHVBXUA8YzyBKY18q5bQuv9wXVwmNWm9U
        whitelistAddresses[0x105EE6E06AB5707C6c5f3f4c85081E7663633513] = true; // 12 //TBTmW2RBDgYU5CwqanntSbrYs8gpDHpKC8
        whitelistAddresses[0x838474725cB5BdDf57cCd56a033985Fe19ACf557] = true; // 13 //TMxcCKCDWoCBp9EE6g4AGYAqJ2ka5cUa3x
        whitelistAddresses[0x4e9FD4bEFD48855d7A476C460bA4AA30537845C1] = true; // 14 //TH8wBH2K4rTzBn1Ek7wkBP2aiVH7xRdGxC
        whitelistAddresses[0x5142916a9fA316a8348f1bF2d4ffBEEe3a7D6DaA] = true; // 15 //THNsUppYjZ1FQagCKAUdKvbAEd2a4M1Vtq
        whitelistAddresses[0xc8bDcB0Ad048444BA28EB5Ed5851d5Df03E37D10] = true; // 16 //TUGdWUyjzfAguL72fHYregk3gF9nmg397H
        whitelistAddresses[0xfAD776f5e69560322171A6972BE857BE2aFEF8d7] = true; // 17 //TYqY3mN47LpuDZeCLKdGF6w4eJtaxrAmus
        //Leaders
        whitelistAddresses[0x739907DBC4f6DAabF64F5f61c325Efc329944916] = true; // 18 //TLWS2svLfTS4pS1bXE84YGBG2eiQyc2RYP
        whitelistAddresses[0x28B4eb67cab9e0Fe09240c4363672065f4cfD4B7] = true; // 19 //TDgSmF43BeaMFq69DkZg3yUYPZSvaKgypD
        whitelistAddresses[0xe7f1331aE041022f95E0B8adAcE6D8C7A95df12f] = true; // 20 //TX7c3DULnQ3fRxGHmHrMPpkxNzZVJzuEmY
        whitelistAddresses[0xe3ea26d44b66641ad7ce31a7330522aBC5EdBa2D] = true; // 21 //TWkJtkMJJdosRPeEW8wDbrwQ9T23qpe1wt
        whitelistAddresses[0x323d48E93C0F7B1C55EdB4Bc527b55317Bb1ae6B] = true; // 22 //TEYrCnzEPcQAACkAiCCwizNHqAoQZZmBq4
        whitelistAddresses[0x12e9d92E79eeCa1A87B8ddDD6608973fE9f70b36] = true; // 23 //TBhDJafVVLnCjf6SWfJHAnYxoQsmJJa6Lg
        whitelistAddresses[0x16b5C24c7fC29d89484C5BfDB8A511B249186951] = true; // 24 //TC3Hc7bi3ZZSPcXALAMWd3hkhiCt5eEDLK
        whitelistAddresses[0x046b63AdF867D6e06255FD37D3d7daA252680d47] = true; // 25 //TANaMNTb8ru27gfF9Mdrc7rnc8R1LYhhKw
        whitelistAddresses[0xaE68Ad49a224bAd6fBfa77161B8487BC6FF31310] = true; // 26 //TRsPyWuEZrvvnSSVLeAr96C8pVRfjvRtef
        whitelistAddresses[0x31D076D951579d776C5a913d54e3fFE19ea0De48] = true; // 27 //TEWbqosZkpjsbhagfejcQ7Vti2HY6Ef9mj
        whitelistAddresses[0xC161C5247463ae3Dc409AC7471457844c9c294AE] = true; // 28 //TTbiYGSatfdnTHRPhWuw2MxudNnupg4uv9
        whitelistAddresses[0x609c5748bD7299A24fde0004672F02C8b8857005] = true; // 29 //TJn3AEZWShmYQECH9v13fofQ2yYu2AQxYQ
        whitelistAddresses[0xEbf642A8B4C4f7Ffe31518591AAe3ECa1D5E8033] = true; // 30 //TXUrocNwNx6S3BrtUyEQFEPFEAoCqgQByq
        whitelistAddresses[0x51A2ea5e589F55305B573fc46c64d727C9a7AD73] = true; // 31 //THQruAWdBtajyHzDj6zorFdt2XcHvzkapV
        whitelistAddresses[0xA0aF8976346acc11b102Fb508aeB50A273Ad7428] = true; // 32 //TQcqQGpr85WUuBaTfZeitUmnjMtyNfZbC6
        whitelistAddresses[0x455766cD4572324b730efa401FA16669FECf941D] = true; // 33 //TGHrL4bbEP9pww28LDeHTt3yjSEb38ctT6
        whitelistAddresses[0x3bA299e456F9A80349aA4bDD30E7617cDB8B449E] = true; // 34 //TFQXf6tNVQgcLyxrq8x8i2hCnZRYNhxVJa
        whitelistAddresses[0x006784825345a06E145799d614263eeaDFf8c189] = true; // 35 //TA1M1b7GSHRZCEeLVsvyF6oGj1efMNm9fe
        whitelistAddresses[0xF4FB98297c0610c86CdD38b1A6A96Eaf04495804] = true; // 36 //TYJZGx3SKRhuoTq3sXE1nKZG3LtKqmG24Q
        //Launcher
        whitelistAddresses[0x2a7DAEdaf45717FD79eCe8Ff269850B7B25f4347] = true; // 37 //TDqswj3okcPdi6gvCTrYfXxfvb9TwBW36g
        
        emit registerUser(ownerAddress, users[ownerAddress].id, ownerAddress, users[ownerAddress].id);
        
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registerTier(msg.sender, owner);
        }
        registerTier(msg.sender, bytesToAddress(msg.data));
    }

    function activateTwinTurbo(address inviterAddress) external payable {
        registerTier(msg.sender, inviterAddress);
    }
    
    function registerTier(address userAddress, address inviterAddress) private {
        if(lastUserId <= 37) {
            require(whitelistAddresses[userAddress] == true, "Address Not Whitelisted");
        }
        uint256 thisTierCost = getTierCostinTRX(1);
        require(msg.value == thisTierCost, "Invalid activation cost"); //ATTENTION
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
            usersReferred: 0
        });
        
        users[userAddress] = user;
        
        idToAddress[lastUserId] = userAddress;
        userIds[lastUserId] = userAddress;
        
        lastUserId++;
        users[inviterAddress].usersReferred++;
        
        processTier(userAddress, 1);
        emit registerUser(userAddress,  users[userAddress].id, inviterAddress,  users[inviterAddress].id);
        return;
    }
    
    function upgradeTier(uint8 tier)  external payable {
        require(isUserExists(msg.sender), "User doesnt exist");
        require(tier > 1 && tier <= TOTAL_TIERS, "Invalid Tier");
        
        uint256 thisTierCost = getTierCostinTRX(tier);
        require(msg.value == thisTierCost, "Invalid Amount");
        require(!users[msg.sender].activeTiers[tier], "Tier already purchased");
        require(users[msg.sender].activeTiers[tier-1], "Purchase prev tier first");
        processTier(msg.sender, tier);
    }
    
    function processTier(address userAddress, uint8 tier)  private {
        users[userAddress].activeTiers[tier] = true;
    
        address paymentReceiver = decideReceiver(userAddress, tier);
        users[userAddress].matrixTier[tier].paidto = paymentReceiver;
        users[paymentReceiver].matrixTier[tier].matrixSlots.push(userAddress);
        
        
        uint256 thisTierCost = getTierCostinTRX(tier);
        
        //50% DIRECT PAYMNET
        if(!address(uint160(paymentReceiver)).send(thisTierCost/2)) {
            address(uint160(paymentReceiver)).transfer(thisTierCost/2);
        }
        //50% TO ESCROW WALLET
        if(!address(uint160(owner)).send(thisTierCost/2)) {
            address(uint160(owner)).transfer(thisTierCost/2);
        }
        
        emit recordTierPayment(users[userAddress].id, users[paymentReceiver].id, tier, users[paymentReceiver].matrixTier[tier].cycleCount);
        return;
    }
    
    function decideReceiver(address userAddress, uint8 tier) private returns(address) {
        
        if(!users[users[userAddress].inviter].activeTiers[tier]) {
            emit paymentExtras('gift');
            emit recordMissedPayment(users[userAddress].id, users[users[userAddress].inviter].id, tier, users[users[userAddress].inviter].matrixTier[tier].cycleCount);
            return decideReceiver(users[userAddress].inviter, tier);
        }
        
        if(users[users[userAddress].inviter].matrixTier[tier].matrixSlots.length < 2) {
            return users[userAddress].inviter;
        }
        
        users[users[userAddress].inviter].matrixTier[tier].matrixSlots = new address[](0);
        emit paymentExtras('cycle spill');
        
        if(users[userAddress].inviter == owner) {
            users[users[userAddress].inviter].matrixTier[tier].cycleCount++;
            emit recordCyclePayment(users[userAddress].id, users[users[userAddress].inviter].id, tier, users[users[userAddress].inviter].matrixTier[tier].cycleCount);
            return users[userAddress].inviter;
        } else {
            users[users[userAddress].inviter].matrixTier[tier].cycleCount++;
            emit recordCyclePayment(users[userAddress].id, users[users[userAddress].inviter].id, tier, users[users[userAddress].inviter].matrixTier[tier].cycleCount);
            return decideReceiver(users[userAddress].inviter, tier);
        }
    }
    
    //AIRDROP FUNCTIONS
    //Incentive Program Air Drop (By escrow wallet only)
    function performAirDrop(uint256 positions, uint8 tier) external payable {
        
        uint256 thisTierCost = getTierCostinTRX(tier)/2;
        require(msg.value == positions * thisTierCost, "Invalid Amount");
        require(msg.sender == owner, "Restricted to Admin only!");
    
        address airdropPerformer = msg.sender;
        
        uint32 size;
        assembly {
            size := extcodesize(airdropPerformer)
        }
        require(size == 0, "Cannot be a contract");
        
        for(uint256 i=1;i<=positions; i++) {
            
            address lastAirdroppedAddress = idToAddress[lastAirdroppedID[tier]];
            
            if(users[lastAirdroppedAddress].activeTiers[tier] && users[lastAirdroppedAddress].matrixTier[tier].cycleCount == 0 && users[lastAirdroppedAddress].matrixTier[tier].matrixSlots.length < 3) {
                
                address paymentReceiver = decideAirdropReceiver(lastAirdroppedAddress, tier);
                users[paymentReceiver].matrixTier[tier].matrixSlots.push(airdropPerformer);
                
                users[lastAirdroppedAddress].matrixTier[tier].airdropsReceived++;
                
                //50% DIRECT PAYMNET
                if(!address(uint160(paymentReceiver)).send(thisTierCost)) {
                    address(uint160(paymentReceiver)).transfer(thisTierCost);
                }
                emit recordAirdropPayment(users[airdropPerformer].id, users[paymentReceiver].id, tier, users[paymentReceiver].matrixTier[tier].cycleCount);
            } else {
                lastAirdroppedID[tier]++;
                i--;
                
                if(lastAirdroppedID[tier] >= lastUserId) {
                    break;
                }
            }
            
        }
        emit airdropTransferComplete();
        
    }
    
    function decideAirdropReceiver(address userAddress, uint8 tier) private returns(address) {
        
        if(!users[userAddress].activeTiers[tier]) {
            emit paymentExtras('gift');
            emit recordMissedPayment(users[owner].id, users[userAddress].id, tier, users[userAddress].matrixTier[tier].cycleCount);
            return decideAirdropReceiver(users[userAddress].inviter, tier);
        }
        
        if(users[userAddress].matrixTier[tier].matrixSlots.length < 2) {
            return userAddress;
        }
        
        users[userAddress].matrixTier[tier].matrixSlots = new address[](0);
        emit paymentExtras('cycle spill');
        
        if(userAddress == owner) {
            users[userAddress].matrixTier[tier].cycleCount++;
            emit recordCyclePayment(users[owner].id, users[userAddress].id, tier, users[userAddress].matrixTier[tier].cycleCount);
            return userAddress;
        } else {
            users[userAddress].matrixTier[tier].cycleCount++;
            emit recordCyclePayment(users[owner].id, users[userAddress].id, tier, users[userAddress].matrixTier[tier].cycleCount);
            return decideAirdropReceiver(users[userAddress].inviter, tier);
        }
    }
    
     //Generic Transfer Funds Module for incentive Bonus transfers and contest winners funds transfer (By escrow wallet only)
    function genericTransferFunds(uint256 mode, uint256 customData, uint256[] memory payToIds, uint256[] memory amounts) public payable {
        require(msg.sender == owner, "Restricted to Admin only!");
        
        address thisUser = address(0);
        uint toPayAmnt = uint(0);
        
        for(uint256 i=0; i<payToIds.length; i++) {
            thisUser = idToAddress[payToIds[i]];
            toPayAmnt = (amounts[i]*100000/USD_RATE) * 1 trx;
            if (!address(uint160(thisUser)).send(toPayAmnt)) {
                address(uint160(thisUser)).transfer(toPayAmnt);
            }
        }
        
        emit genericTransferFundsComplete(mode, customData);
    }
    
    function programFreeSlots(uint8 tier) public view returns (uint256) {
        uint256 emptySlots = 0;
        for(uint256 i=1; i<lastUserId; i++) {
            address thisUser = idToAddress[i];
            if(users[thisUser].activeTiers[tier] && users[thisUser].matrixTier[tier].cycleCount == 0 && users[thisUser].matrixTier[tier].matrixSlots.length < 3) {
                emptySlots = emptySlots + (3- users[thisUser].matrixTier[tier].matrixSlots.length);
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
    function userMatrix(address userAddress, uint8 tier) public view returns(address, address[] memory, uint32, uint8) {
        return (users[userAddress].matrixTier[tier].paidto,
                users[userAddress].matrixTier[tier].matrixSlots,
                users[userAddress].matrixTier[tier].cycleCount,
                users[userAddress].matrixTier[tier].airdropsReceived);
    }
    function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	function getTierCostinTRX(uint8 tier) public view returns(uint256) {
        return tiersCost[tier]*100000/USD_RATE  * 1 trx;
    }
	
	//Dynamically adjust USD value
    function adjustUSD(uint256 rate) external payable {
        require(msg.sender == owner, "Restricted to Admin only!");
        USD_RATE = rate;
        
        //Update in DAPP
        emit updateUSDRate(USD_RATE);
    }
	
	//Dynamically add new boards
    function addNewBoard(uint tierCost) external payable {
        require(msg.sender == owner, "Restricted to Admin only!");
        
        TOTAL_TIERS++;
        tiersCost[TOTAL_TIERS] = tierCost;
        users[owner].activeTiers[TOTAL_TIERS] = true;
        lastAirdroppedID[TOTAL_TIERS] = 1;
        
        //Auto upgrade owner to new board
        emit recordTierPayment(users[owner].id, users[owner].id, TOTAL_TIERS, 0);
        
        return;
    }
    
    //Withdraw excessive airdrop funds from contract to owner wallet
    function withdrawContractBalance() external payable {
        require(msg.sender == owner, "Restricted to Admin only!");
        if(!address(uint160(owner)).send(address(this).balance)) {
            address(uint160(owner)).transfer(address(this).balance);
        }
        return;
    }
    
}