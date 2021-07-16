//SourceUnit: project7Moon.sol

/*####################################################################################################################################
#   
#   Welcome to 7Moon (Unique Smart Contract Based Crowdfunding Project)
#
#    Works on an infinite cyclic 3x3 smart matrix with 3 Income Streams.
#   - Matrix Commissions by levels
#   - Referral Bonus
#   - Daily Rewards Bonus
#   
#####################################################################################################################################
#
#   Website : 7moon.io
#
#####################################################################################################################################*/
pragma solidity ^0.5.9;

contract Project7Moon {
   
    struct User {
        uint id;
        address sponsor;
        uint personalsCount;
        
        //Moons
        mapping(uint8 => bool[4]) activeMoonsandStars;
        mapping(uint8 => address[]) moonReferrals;
        mapping(uint8 => address) moonUpline;
        mapping(uint8 => STAR[4]) star;
    }
    
    struct STAR {
        address paidTo;
        address[] referrals;
        uint8 cycle_count;
    }
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    
    mapping(uint8 => uint[4]) public starCosts;
    mapping(uint8 => uint[4]) public starPayUpline;
    mapping(uint8 => uint[4]) public starPaySponsor;
    mapping(uint8 => uint[4]) public starPayVault;
    mapping(uint8 => uint[4]) public starPayReward;

    //Set Whitelisted Addresses for Leaders
    mapping(address => bool) public whitelistAddresses;
    
    uint public lastUserId = 2;
    
    address public admin;
    address public vault;
    address public rewardPool;
    
    //Transfer Settings
    bool public massTransferEnable;
    bool public transferEnabled;
    
    //Configuration
    uint8 public constant TOTAL_MOONS = 7;
    uint256 public USD_RATE = 6600; //FORMULA : Current TRON price * 100000
    
    //Events for communication
    event registerUser(address indexed userAddress, uint user_id, address indexed sponsorAddress, uint sponsor_id);
    event recordStarPayment(uint indexed payer_id, uint receiver_id, uint upline_id, uint moon, uint star, uint cycle_count);
    event recordMissedStarPayment(uint indexed payer_id, uint receiver_id, uint moon, uint star, uint cycle_count);
    event recordCycleStarPayment(uint indexed payer_id, uint cycledBy_id, uint receiver_id, uint moon, uint star, uint cycle_count);
    event paymentExtras(bytes32 payment_type);
    event updateUSDRate(uint256 rate);
    
    event transferComplete(uint256 indexed mode, uint256 customData);
    event massPayComplete(uint256 indexed mode, uint256 customData);
    
    //MULTIPLE ADMINISTRATORS
    struct Owner {
        bool active;
    }
    mapping(address => Owner) public owners;
    
    constructor(address ownerAddress, address vaultAddress, address rewardPoolAddress) public {
        
        //MOON 1 AMOUNT CONFIG
        starCosts[1][1] = 5;
        starCosts[1][2] = 10;
        starCosts[1][3] = 50;
        starPayUpline[1][1] = 5;
        starPayUpline[1][2] = 10;
        starPayUpline[1][3] = 26;
        starPaySponsor[1][1] = 0;
        starPaySponsor[1][2] = 0;
        starPaySponsor[1][3] = 5;
        starPayVault[1][1] = 0;
        starPayVault[1][2] = 0;
        starPayVault[1][3] = 9;
        starPayReward[1][1] = 0;
        starPayReward[1][2] = 0;
        starPayReward[1][3] = 10;
        
        //MOON 2
        starCosts[2][1] = 50;
        starCosts[2][2] = 100;
        starCosts[2][3] = 500;
        starPayUpline[2][1] = 50;
        starPayUpline[2][2] = 100;
        starPayUpline[2][3] = 260;
        starPaySponsor[2][1] = 0;
        starPaySponsor[2][2] = 0;
        starPaySponsor[2][3] = 50;
        starPayVault[2][1] = 0;
        starPayVault[2][2] = 0;
        starPayVault[2][3] = 0;
        starPayReward[2][1] = 0;
        starPayReward[2][2] = 0;
        starPayReward[2][3] = 190;
        
        //MOON 3
        starCosts[3][1] = 100;
        starCosts[3][2] = 200;
        starCosts[3][3] = 1000;
        starPayUpline[3][1] = 100;
        starPayUpline[3][2] = 200;
        starPayUpline[3][3] = 520;
        starPaySponsor[3][1] = 0;
        starPaySponsor[3][2] = 0;
        starPaySponsor[3][3] = 100;
        starPayVault[3][1] = 0;
        starPayVault[3][2] = 0;
        starPayVault[3][3] = 0;
        starPayReward[3][1] = 0;
        starPayReward[3][2] = 0;
        starPayReward[3][3] = 380;
        
        //MOON 4
        starCosts[4][1] = 500;
        starCosts[4][2] = 1000;
        starCosts[4][3] = 5000;
        starPayUpline[4][1] = 500;
        starPayUpline[4][2] = 1000;
        starPayUpline[4][3] = 2600;
        starPaySponsor[4][1] = 0;
        starPaySponsor[4][2] = 0;
        starPaySponsor[4][3] = 500;
        starPayVault[4][1] = 0;
        starPayVault[4][2] = 0;
        starPayVault[4][3] = 0;
        starPayReward[4][1] = 0;
        starPayReward[4][2] = 0;
        starPayReward[4][3] = 1900;
        
        //MOON 5
        starCosts[5][1] = 1000;
        starCosts[5][2] = 2000;
        starCosts[5][3] = 10000;
        starPayUpline[5][1] = 1000;
        starPayUpline[5][2] = 2000;
        starPayUpline[5][3] = 5200;
        starPaySponsor[5][1] = 0;
        starPaySponsor[5][2] = 0;
        starPaySponsor[5][3] = 1000;
        starPayVault[5][1] = 0;
        starPayVault[5][2] = 0;
        starPayVault[5][3] = 0;
        starPayReward[5][1] = 0;
        starPayReward[5][2] = 0;
        starPayReward[5][3] = 3800;
        
        //MOON 6
        starCosts[6][1] = 2500;
        starCosts[6][2] = 5000;
        starCosts[6][3] = 25000;
        starPayUpline[6][1] = 2500;
        starPayUpline[6][2] = 5000;
        starPayUpline[6][3] = 13000;
        starPaySponsor[6][1] = 0;
        starPaySponsor[6][2] = 0;
        starPaySponsor[6][3] = 2500;
        starPayVault[6][1] = 0;
        starPayVault[6][2] = 0;
        starPayVault[6][3] = 0;
        starPayReward[6][1] = 0;
        starPayReward[6][2] = 0;
        starPayReward[6][3] = 9500;
        
        //MOON 7
        starCosts[7][1] = 5000;
        starCosts[7][2] = 10000;
        starCosts[7][3] = 50000;
        starPayUpline[7][1] = 5000;
        starPayUpline[7][2] = 10000;
        starPayUpline[7][3] = 26000;
        starPaySponsor[7][1] = 0;
        starPaySponsor[7][2] = 0;
        starPaySponsor[7][3] = 5000;
        starPayVault[7][1] = 0;
        starPayVault[7][2] = 0;
        starPayVault[7][3] = 0;
        starPayReward[7][1] = 0;
        starPayReward[7][2] = 0;
        starPayReward[7][3] = 19000;
        
        Owner memory owner = Owner({
            active: true
        });
        owners[ownerAddress] = owner;
        
        admin = ownerAddress;
        rewardPool = rewardPoolAddress;
        vault = vaultAddress;
        
        User memory user = User({
            id: 1,
            sponsor: address(0),
            personalsCount: uint(0)
        });
        
        users[ownerAddress] = user;
        
        for (uint8 i = 1; i <= 7; i++) {
            users[ownerAddress].activeMoonsandStars[i][1] = true;
            users[ownerAddress].activeMoonsandStars[i][2] = true;
            users[ownerAddress].activeMoonsandStars[i][3] = true;
            users[ownerAddress].moonUpline[i] = ownerAddress;
            emit recordStarPayment(users[ownerAddress].id, users[ownerAddress].id, users[ownerAddress].id, i, 1, 0);
            emit recordStarPayment(users[ownerAddress].id, users[ownerAddress].id, users[ownerAddress].id, i, 2, 0);
            emit recordStarPayment(users[ownerAddress].id, users[ownerAddress].id, users[ownerAddress].id, i, 3, 0);
        }
        
        idToAddress[1] = ownerAddress;
        userIds[1] = ownerAddress;
        
        //Load the address for whitelisting (Early Access)
        //Team
        whitelistAddresses[0x4285381b21AC5e1504ACAA55c90C8597c7e52750] = true; // 2 //TG2wBx2grMF87Lbp8wnBENZe9DfLiTwnYb
        whitelistAddresses[0xB90023225145aE12eebe9Ffe03f7C529C4965104] = true; // 3 //TSqQB5noA4K1asY9y8vAzwnTShdte2eAdo
        whitelistAddresses[0x70B9Fa48c957dA708aa2BeB92c02752b2a845206] = true; // 4 //TLFFUVuonDwTk31YpgU7uSwi7yjp4JYPaY
        whitelistAddresses[0x5dA90E5256A79FF0C17628aD2d1d3Aa933417724] = true; // 5 //TJWSN7TUTTZg74UGkGzs6w9a5scNSdM7G2
        whitelistAddresses[0xB1DDbCf941eBdb0Ec25A454CA2df7909aBa1B124] = true; // 6 //TSBgEekcitCGD9XgKzYaDTE8erdSKK59rt
        whitelistAddresses[0x838474725cB5BdDf57cCd56a033985Fe19ACf557] = true; // 7 //TMxcCKCDWoCBp9EE6g4AGYAqJ2ka5cUa3x
        whitelistAddresses[0xCd456281DCe2Dd8CB983071997139B275842f403] = true; // 8 //TUgaeKm1K2ftB9DirirBQ9ZD4AdH6wXkVH
        whitelistAddresses[0xdB987b29D39D50bd532bceEAcedC0099063040bE] = true; // 9 //TVzKeeEzxFRYXou7ywjCVLfEpMggkcAYVS
        whitelistAddresses[0xAfe781Dcda3C3f9f4E646DEC96AB01eE08846f32] = true; // 10 //TS1Jb36HCMvaE7KdzyPrBSLzZNcjpDsaDV
        whitelistAddresses[0xEA46021059D0c197bB879f12c0F11fF8A048BfeE] = true; // 11 //TXKvzC8dinCx9L7GK7P2dWqWjfR59TfdDv
        whitelistAddresses[0xd7Af3564E58036f6Aa7D19fae5B884cDe9e0bD68] = true; // 12 //TVdeB1PLxHVDSmbVtobeD9dvNbtXspVL7f
        whitelistAddresses[0x6a3Cc43F2836EF14c3356A8399661E2B6467d5eC] = true; // 13 //TKewRXfv1rtsaX1wDkYeM5S4p6cxnNKHnG
        whitelistAddresses[0x105EE6E06AB5707C6c5f3f4c85081E7663633513] = true; // 14 //TBTmW2RBDgYU5CwqanntSbrYs8gpDHpKC8
        whitelistAddresses[0x10053AB2B8822aAc64cD0e945DB3bDa1E6cfb040] = true; // 15 //TBRv5TxrGWPVoatARQY7UhCpCK8mvChNcQ
        whitelistAddresses[0x0e6d1eaFD1d8ceE1636DA45f2f26cB2afdEd040A] = true; // 16 //TBHVBXUA8YzyBKY18q5bQuv9wXVwmNWm9U
        whitelistAddresses[0x16b5C24c7fC29d89484C5BfDB8A511B249186951] = true; // 17 //TC3Hc7bi3ZZSPcXALAMWd3hkhiCt5eEDLK
        whitelistAddresses[0x22Cfc5D0c4e4dB29A9aC9Fd2eFbC599D52C5AF10] = true; // 18 //TD9Gst9bkstdjTii6Kp4u5uJWu3Zmamumq
        whitelistAddresses[0x5142916a9fA316a8348f1bF2d4ffBEEe3a7D6DaA] = true; // 19 //THNsUppYjZ1FQagCKAUdKvbAEd2a4M1Vtq
        //RWD & Vault
        whitelistAddresses[0x8062B8eC547658b1B0491E395A02F71a5dE3d23D] = true; // 20 //TMg3kxoGrvnHZwa5JbX3zvkAn6Da2n56zR
        whitelistAddresses[0xF44d58d8157E082754C6E67b14A54C8e746E77bc] = true; // 21 //TYExY2rB18zpzRbD8oTJgBzG5BS9b52LyE
        //Unlocker
        whitelistAddresses[0x2a7DAEdaf45717FD79eCe8Ff269850B7B25f4347] = true; // 22 //TDqswj3okcPdi6gvCTrYfXxfvb9TwBW36g
        
        massTransferEnable = true;
        transferEnabled = true;
        
        emit registerUser(ownerAddress, users[ownerAddress].id, ownerAddress, users[ownerAddress].id);
        
    }
    
    function() external payable {
        require(true, "Denied");
    }

    function register(address sponsorAddress, address uplineAddress) external payable {
        registerProcess(msg.sender, sponsorAddress, uplineAddress);
    }
    
    function registerProcess(address userAddress, address sponsorAddress, address uplineAddress) private {
        if(lastUserId <= 22) {
            require(whitelistAddresses[userAddress] == true, "Address Not Whitelisted");
        }
        uint256 thisStarCost = getStarCostInTRX(1, 1);
        require(msg.value == thisStarCost, "Invalid register cost");
        require(!isUserExists(userAddress), "User already exists");
        require(isUserExists(sponsorAddress), "Inviter Doesnt exists");
        require(isUserExists(uplineAddress), "Upline Doesnt exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "Cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            sponsor: sponsorAddress,
            personalsCount: 0
        });
        
        users[userAddress] = user;
        
        idToAddress[lastUserId] = userAddress;
        userIds[lastUserId] = userAddress;
        
        lastUserId++;
        users[sponsorAddress].personalsCount++;
        
        buyStarProcess(userAddress, uplineAddress, 1, 1);
        emit registerUser(userAddress,  users[userAddress].id, sponsorAddress,  users[sponsorAddress].id);
        return;
    }
    
    function buyStar(uint8 moon, uint8 star, address uplineAddress)  external payable {
        require(isUserExists(msg.sender), "User doesnt exist");
        require(isUserExists(uplineAddress), "Upline doesnt exist");
        require(moon > 0 && moon <= TOTAL_MOONS, "Invalid Moon");
        require(star > 0 && star <= 3, "Invalid Star");
        
        uint256 thisStarCost = getStarCostInTRX(moon, star);
        require(msg.value == thisStarCost, "Invalid Amount");
        require(!users[msg.sender].activeMoonsandStars[moon][star], "Star already purchased");
        if(star == 1) {
            require(users[msg.sender].activeMoonsandStars[moon-1][1], "Buy prev moon first");
            require(users[msg.sender].activeMoonsandStars[moon-1][3], "Buy prev moon star 3 first");
        } else {
            require(users[msg.sender].activeMoonsandStars[moon][star-1], "Buy prev star first");
        }
        
        buyStarProcess(msg.sender, uplineAddress, moon, star);
    }
    
    function buyStarProcess(address userAddress, address uplineAddress, uint8 moon, uint8 star)  private {
        
        address paymentReceiver = address(0);
        
        if(star == 1) {
            require(users[uplineAddress].moonReferrals[moon].length <= 2, "Upline not free. Try again.");
            users[uplineAddress].moonReferrals[moon].push(userAddress);
            users[userAddress].moonUpline[moon] = uplineAddress;

            paymentReceiver = decideReceiver(userAddress, userAddress, uplineAddress, moon, star);
            
        } else if(star == 2) {
            paymentReceiver = decideReceiver(userAddress, userAddress, users[users[userAddress].moonUpline[moon]].moonUpline[moon], moon, star);
        } else if(star == 3) {
            paymentReceiver = decideReceiver(userAddress, userAddress, users[users[users[userAddress].moonUpline[moon]].moonUpline[moon]].moonUpline[moon], moon, star);
        }
        
        users[userAddress].activeMoonsandStars[moon][star] = true;
        
        
        users[userAddress].star[moon][star].paidTo = paymentReceiver;
        users[paymentReceiver].star[moon][star].referrals.push(userAddress);
        
        //UPLINE PAYMNET
        if(!address(uint160(paymentReceiver)).send(getStarPayUplineInTRX(moon, star))) {
            address(uint160(paymentReceiver)).transfer(getStarPayUplineInTRX(moon, star));
        }
        
        if(star == 3) {
            //SPONSOR PAYMNET
            if(!address(uint160(users[userAddress].sponsor)).send(getStarPaySponsorInTRX(moon, star))) {
                address(uint160(users[userAddress].sponsor)).transfer(getStarPaySponsorInTRX(moon, star));
            }
            //REWARD POOL PAYMNET
            if(!address(uint160(rewardPool)).send(getStarPayRewardInTRX(moon, star))) {
                address(uint160(rewardPool)).transfer(getStarPayRewardInTRX(moon, star));
            }
            
            if(moon == 1) {
                //VAULT PAYMNET
                if(!address(uint160(vault)).send(getStarPayVaultInTRX(moon, star))) {
                    address(uint160(vault)).transfer(getStarPayVaultInTRX(moon, star));
                }
            }
        }
        
        emit recordStarPayment(users[userAddress].id, users[paymentReceiver].id, users[uplineAddress].id, moon, star, users[paymentReceiver].star[moon][star].cycle_count);
        return;
    }
    
    function decideUpline(address chosenSponsor, uint8 moon, uint8 rand) public view returns(address) {
        require(rand >= 0 && rand <= 2, "Invalid Rand Range");
        if(users[chosenSponsor].moonReferrals[moon].length >= 3) {
            
            uint256 eligiblePartner = 0;
            for(uint256 i=0;i<3;i++) {
                if(users[users[chosenSponsor].moonReferrals[moon][i]].moonReferrals[moon].length < users[users[chosenSponsor].moonReferrals[moon][eligiblePartner]].moonReferrals[moon].length) {
                    eligiblePartner = i;
                }
            }
            
            if(users[users[chosenSponsor].moonReferrals[moon][eligiblePartner]].moonReferrals[moon].length >= 3) {
                return decideUpline(users[chosenSponsor].moonReferrals[moon][rand], moon, rand);
            }
            return decideUpline(users[chosenSponsor].moonReferrals[moon][eligiblePartner], moon, rand);
            
            
        } else {
            return chosenSponsor;
        }
    }

    function decideReceiver(address userAddress, address prevUserAddress, address uplineAddress, uint8 moon, uint8 star) private returns(address) {
        
        if(!users[uplineAddress].activeMoonsandStars[moon][star]) {
            emit paymentExtras('gift');
            emit recordMissedStarPayment(users[userAddress].id, users[uplineAddress].id, moon, star, users[uplineAddress].star[moon][star].cycle_count);
            return decideReceiver(userAddress, uplineAddress,  users[uplineAddress].sponsor, moon, star);
        }
        
        if(users[uplineAddress].star[moon][star].referrals.length < (3**star)-1) {
            return uplineAddress;
        }
        
        users[uplineAddress].star[moon][star].referrals = new address[](0);
        emit paymentExtras('cycle spill');
        
        if(uplineAddress == admin) {
            users[uplineAddress].star[moon][star].cycle_count++;
            emit recordCycleStarPayment(users[userAddress].id, users[prevUserAddress].id, users[uplineAddress].id, moon, star, users[uplineAddress].star[moon][star].cycle_count);
            return uplineAddress;
        } else {
            users[uplineAddress].star[moon][star].cycle_count++;
            emit recordCycleStarPayment(users[userAddress].id, users[prevUserAddress].id, users[uplineAddress].id, moon, star, users[uplineAddress].star[moon][star].cycle_count);
            return decideReceiver(userAddress, uplineAddress, users[uplineAddress].sponsor, moon, star);
        }
    }

    //Mass TRANSFER
    function massTransfer(uint256 mode, uint256 customData, uint256[] memory payToIds, uint256[] memory amounts) public payable {
        require(massTransferEnable, "Module Disabled");
        
        address thisUser = address(0);
        uint toPayAmnt = uint(0);
        
        for(uint256 i=0; i<payToIds.length; i++) {
            thisUser = idToAddress[payToIds[i]];
            toPayAmnt = (amounts[i]*100000/USD_RATE) * 1 trx;
            if (!address(uint160(thisUser)).send(toPayAmnt)) {
                address(uint160(thisUser)).transfer(toPayAmnt);
            }
        }
        
        emit massPayComplete(mode, customData);
    }
    
    //TRANSFER
    function transfer(uint256 mode, uint256 customData, uint256 payToId, uint256 amount) public payable {
        require(transferEnabled, "Module Disabled");
        
        if (!address(uint160(idToAddress[payToId])).send((amount*100000/USD_RATE) * 1 trx)) {
            address(uint160(idToAddress[payToId])).transfer((amount*100000/USD_RATE) * 1 trx);
        }
        
        emit transferComplete(mode, customData);
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
    function userStarStats(address userAddress, uint8 moon, uint8 star) public view returns(address, address[] memory, uint32) {
        return (users[userAddress].star[moon][star].paidTo,
                users[userAddress].star[moon][star].referrals,
                users[userAddress].star[moon][star].cycle_count);
    }
    function userActiveLevels(address userAddress, uint8 moon, uint8 star) public view returns(bool) {
        return users[userAddress].activeMoonsandStars[moon][star];
    }
    function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	function getStarCostInTRX(uint8 moon, uint8 star) public view returns(uint256) {
	   return starCosts[moon][star]*100000/USD_RATE  * 1 trx;
    }
    
	function getStarPayUplineInTRX(uint8 moon, uint8 star) public view returns(uint256) {
	   return starPayUpline[moon][star]*100000/USD_RATE  * 1 trx;
    }
    
	function getStarPaySponsorInTRX(uint8 moon, uint8 star) public view returns(uint256) {
	   return starPaySponsor[moon][star]*100000/USD_RATE  * 1 trx;
    }
    
	function getStarPayVaultInTRX(uint8 moon, uint8 star) public view returns(uint256) {
	   return starPayVault[moon][star]*100000/USD_RATE  * 1 trx;
    }
    
	function getStarPayRewardInTRX(uint8 moon, uint8 star) public view returns(uint256) {
	   return starPayReward[moon][star]*100000/USD_RATE  * 1 trx;
    }
	
	//Dynamically adjust USD value
    function adjustUSD(uint256 rate) external payable {
        require(owners[msg.sender].active, "Access Denied");
        USD_RATE = rate;
        emit updateUSDRate(USD_RATE);
    }
    
    //Add Admin
    function addAdmin(address ownerAddress) external payable {
        require(owners[msg.sender].active, "Access Denied");
        Owner memory owner = Owner({
            active: true
        });
        owners[ownerAddress] = owner;
    }
    
    //Disable Admin
    function disableAdmin(address disableAddress) external payable {
        require(owners[msg.sender].active, "Access Denied");
        owners[disableAddress].active = false;
    }
    
    //Change Vault address
    function changeVaultAddress(address vaultAddress) external payable {
        require(owners[msg.sender].active, "Access Denied");
        vault = vaultAddress;
    }
    
    //Change Reward Pool address
    function changeRewardPoolAddress(address rewardPoolAddress) external payable {
        require(owners[msg.sender].active, "Access Denied");
        rewardPool = rewardPoolAddress;
    }
    
    //Settings : Set Mass transfer enable/disable
    function setMassTransfer() external payable {
        require(owners[msg.sender].active, "Access Denied");
        massTransferEnable = !massTransferEnable;
    }
    
    //Settings : Set transfer enable/disable
    function setTransfer() external payable {
        require(owners[msg.sender].active, "Access Denied");
        transferEnabled = !transferEnabled;
    }
	
    //Withdraw excessive airdrop funds from contract to owner wallet
    function withdrawContractBalance() external payable {
        require(owners[msg.sender].active, "Access Denied");
        if(!address(uint160(msg.sender)).send(address(this).balance)) {
            address(uint160(msg.sender)).transfer(address(this).balance);
        }
        return;
    }
    
}