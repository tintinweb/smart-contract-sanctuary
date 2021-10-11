//SourceUnit: smart20.sol

// SPDX-License-Identifier: MIT
/*####################################################################################################################################
#   
#   Welcome to Smart20 Community
#
#
#     @@@@@@@@@      @@@      @@@@         @@@         @@@@@@@@@    @@@@@@@@@@    @@@@@@@@@      @@@@@@
#    @@@@   @@@@     @@@@     @@@@        @@@@@        @@@    @@@      @@@        @@@   @@@     @@@  @@@
#     @@@            @@@@@   @@@@@        @@ @@        @@@    @@@      @@@             %@@#     @@@  @@@
#      @@@@@@@       @@@@@@ @@@@@@       @@@ @@@       @@@@@@@@@       @@@            @@@/      @@@  @@@
#           @@@      @@@ @@@@@ @@@      @@@   @@       @@@  @@@        @@@           @@@        @@@  @@@
#           @@@@     @@@  @@@  @@@      @@@@@@@@@      @@@  @@@        @@@         .@@@         @@@  @@@
#    @@@@   @@@      @@@       @@@     @@@     @@@     @@@   @@@       @@@        @@@@          @@@  @@@
#     @@@@@@@@       @@@       @@@     @@@     @@@     @@@    @@@      @@@        @@@@@@@@@      @@@@@@ 
#
#
#   
#####################################################################################################################################
#
#   Website : smart20.io
#   Developed by hustydesigns.com (support@hustydesigns.com)
#
#####################################################################################################################################*/
pragma solidity ^0.6.12;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Smart20 {
    
    using SafeMath for uint256;
    
    //User to store the position owner address and upline
    struct User {
        uint256 id;
        address influencer;
        uint256 referralsCount;
    }
    
    //Hold all IDs in the system
    struct Position {
        address owner;
        uint256 upline; //Spot which was decided by system
        uint256 expiration;
        uint256 registered;
        uint256[] downline; //Maximum 2
    }
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    
    mapping(uint256 => Position) public positions;
    
    //Set Whitelisted Addresses for Leaders
    mapping(address => bool) public whitelistAddresses;
    
    uint public lastPositionId = 1;
    uint public lastCompanyPosition = 1;
    
    address public owner;
    bool public smart20Launched = false;
    bool private isRenewalProcess = false;
    
    //Configuration
    uint8 public constant TOTAL_DEEP = 20;
    uint public constant TOTALCOST = 490;
    uint public constant BREAKDOWN_DISTRIBUTION = 12; //Mul by 10 to handle decimals
    uint public constant BREAKDOWN_DIRECTREF = 250; //Mul by 10 to handle decimals
    uint public SUBSCRIPTION_TIME = 2592000; //30 Days
    uint public MAX_POSITIONS_CAN_BUY = 10;
    
    uint256 public USD_RATE = 10000; //FORMULA : Current TRON price * 100000
    
    //Events for communication
    event registerUser(uint indexed user_id, uint influencer_id, address userAddress);
    event registerPosition(uint indexed id, uint upline, uint owner, uint registered,  uint expiration);
    event renewPosition(uint indexed position_id, uint user_id, uint newExpiration);
    
    event recordPositionPayment(uint indexed payerPosition, uint receiverPosition, uint payerOwner, uint receiverOwner, uint level, bool giftandMissed);
    event recordMissedPositionPayment(uint indexed payerPosition, uint receiverPosition, uint payerOwner, uint receiverOwner, uint level);
    
    event recordRefRewardPayment(uint indexed payerPosition, uint receiverPosition, uint payerOwner, bool giftandMissed);
    event recordMissedRefRewardPayment(uint indexed payerPosition, uint receiverPosition, uint payerOwner);
    
    event recordMissedPayment(uint indexed payerPosition, uint receiverPosition, uint level);
    event updateUSDRate(uint256 rate);
    
    //MULTIPLE ADMINISTRATORS
    mapping (address => bool) public admins;
    mapping (address => bool) public mods;
    
    constructor(address ownerAddress) public {
        
        admins[ownerAddress] = true;
        mods[ownerAddress] = true;
        admins[msg.sender] = true;
        mods[msg.sender] = true;
        
        owner = ownerAddress;

        User memory user = User({
            id: 1,
            influencer: ownerAddress,
            referralsCount: 0
        });
        
        users[ownerAddress] = user;
        
        Position memory position = Position({
            owner: ownerAddress,
            upline: lastCompanyPosition,
            expiration: block.timestamp.add(9999999999),
            registered: block.timestamp,
            downline: new uint256[](0)
        });
        
        positions[lastPositionId] = position;

        for (uint8 i = 1; i <= TOTAL_DEEP; i++) {
            emit recordPositionPayment(lastPositionId, lastPositionId, users[ownerAddress].id, users[ownerAddress].id, i, false);
        }
        emit registerPosition(lastPositionId,  lastCompanyPosition, users[ownerAddress].id, positions[lastPositionId].registered, positions[lastPositionId].expiration);
        
        lastPositionId++;
        
        idToAddress[1] = ownerAddress;
        userIds[1] = ownerAddress;
        
        emit registerUser(users[ownerAddress].id, users[ownerAddress].id, ownerAddress);
        
    }
    
    fallback() external payable {
        require(true, "Denied");
    }
    receive() external payable {
        require(true, "Denied");
    }

    function buyPositions(address influencerAddress, uint256 totalPositionsToBuy) external payable {
        
        //Pre entry whitelist
        if(!smart20Launched) {
            require(totalPositionsToBuy == 1, "Only one position allowed");
            require(whitelistAddresses[msg.sender], "Please wait for Smart20 to launch");
            require(!isUserExists(msg.sender), "Only one position allowed");
        }
        
        require(totalPositionsToBuy <= MAX_POSITIONS_CAN_BUY, "Maximum positions to buy limit reached!");
        address userAddress = msg.sender;
        
        uint256 activationCost = convertDollarToTRX(TOTALCOST);
        require(msg.value == activationCost.mul(totalPositionsToBuy), "Invalid cost");
        
        require(isUserExists(influencerAddress), "influencer doesnt exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "Cannot be a contract");
        
        if(!isUserExists(userAddress)) {
            User memory user = User({
                id: lastPositionId,
                influencer: influencerAddress,
                referralsCount: 0
            });
            
            users[userAddress] = user;
            
            idToAddress[lastPositionId] = userAddress;
            userIds[lastPositionId] = userAddress;
            
            users[influencerAddress].referralsCount++;
                
            emit registerUser(users[userAddress].id,  users[influencerAddress].id, userAddress);
        }
        
        for(uint256 loop = 1; loop <= totalPositionsToBuy; loop++) {
            Position memory position = Position({
                owner: userAddress,
                upline: lastCompanyPosition,
                expiration: block.timestamp.add(SUBSCRIPTION_TIME),
                registered: block.timestamp,
                downline: new uint256[](0)
            });
            
            positions[lastPositionId] = position;
            emit registerPosition(lastPositionId,  lastCompanyPosition, users[userAddress].id, positions[lastPositionId].registered, positions[lastPositionId].expiration);
            
            positions[lastCompanyPosition].downline.push(lastPositionId);
            
            buyProcess(userAddress, lastPositionId, lastCompanyPosition);
            
        }

    }
    
    function renewSubscriptions(uint256[] memory subscribePositions) external payable {
        
        require(subscribePositions.length <= MAX_POSITIONS_CAN_BUY, "Maximum Positions limit reached!");
        address userAddress = msg.sender;
        
        require(isUserExists(msg.sender), "Register First");
        require(msg.value == convertDollarToTRX(TOTALCOST).mul(subscribePositions.length), "Invalid Cost");
        
        for(uint256 loop = 0; loop < subscribePositions.length; loop++) {
            
            require(userAddress == positions[subscribePositions[loop]].owner, "Position not owned");
            
            //Add Subscription expiration 
            if(positions[subscribePositions[loop]].expiration > block.timestamp) {
                positions[subscribePositions[loop]].expiration = positions[subscribePositions[loop]].expiration + SUBSCRIPTION_TIME;
            } else {
                positions[subscribePositions[loop]].expiration = block.timestamp + SUBSCRIPTION_TIME;
            }
            emit renewPosition(subscribePositions[loop], users[positions[subscribePositions[loop]].owner].id, positions[subscribePositions[loop]].expiration);
            
            isRenewalProcess = true;
            buyProcess(userAddress, subscribePositions[loop], positions[subscribePositions[loop]].upline);
        }
        
    }
    
    function buyProcess(address userAddress, uint256 payerPosition, uint256 uplinePosition)  private {
        
        uint256 receiverPosition = 1;
        
        //Store user uplines
        uint256 tempUpline = uplinePosition;
        bool missedTxn = false;
        for (uint8 i = 1; i <= TOTAL_DEEP; i++) {
            
            //Decide receiver based on expiration
            (receiverPosition, missedTxn) = decideReceiverPosition(payerPosition, tempUpline, i, false);
            
            emit recordPositionPayment(payerPosition, receiverPosition, users[positions[payerPosition].owner].id, users[positions[receiverPosition].owner].id, i, missedTxn);

            //UPLINE PAYMNET
            if(!address(uint160(positions[receiverPosition].owner)).send(convertDollarToTRX(BREAKDOWN_DISTRIBUTION))) {
                address(uint160(positions[receiverPosition].owner)).transfer(convertDollarToTRX(BREAKDOWN_DISTRIBUTION));
            }
            tempUpline = positions[tempUpline].upline;
        }
        
        //Direct Referral reward receiver
        (address directReferralReceiver, bool giftandMissed)  = decideActiveSponsorPosition(payerPosition, users[userAddress].influencer, false);
        
        //REFERRALS REWARD PAYMENT
        if(!address(uint160(directReferralReceiver)).send(convertDollarToTRX(BREAKDOWN_DIRECTREF))) {
            address(uint160(directReferralReceiver)).transfer(convertDollarToTRX(BREAKDOWN_DIRECTREF));
        }
        
        emit recordRefRewardPayment(payerPosition, users[directReferralReceiver].id, users[positions[payerPosition].owner].id, giftandMissed);
        
        if(!isRenewalProcess) {
            lastPositionId++;
            
            if(positions[lastCompanyPosition].downline.length >= 2) {
                lastCompanyPosition++;
            }
        }
        isRenewalProcess = false;
        
    }
    
    //Decide if receiver's subscription is expired or not.
    function decideReceiverPosition(uint256 payerPosition, uint256 uplinePosition, uint level, bool isGift) private returns(uint256, bool) {
        
        if(positions[uplinePosition].expiration > block.timestamp) {
            return (uplinePosition, isGift);
        } else {
            if(uplinePosition == 1) {
                return (uplinePosition, isGift);
            }
            emit recordMissedPositionPayment(payerPosition, uplinePosition, users[positions[payerPosition].owner].id, users[positions[uplinePosition].owner].id, level);
            return decideReceiverPosition(payerPosition, positions[uplinePosition].upline, level, true);
        }
        
    }
    
    //Get Next active sponsor in the system till reaches owner.
    function decideActiveSponsorPosition(uint256 payerPosition, address influencer, bool isGift) private returns(address, bool) {
        
        if(positions[users[influencer].id].expiration > block.timestamp) {
            return (influencer, isGift);
        } else {
            if(influencer == owner) {
                return (owner, isGift);
            }
            emit recordMissedRefRewardPayment(payerPosition, users[influencer].id, users[positions[payerPosition].owner].id);
            return decideActiveSponsorPosition(payerPosition, users[influencer].influencer, true);
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
    function positionDownlines(uint256 positionID) public view returns(uint256[] memory) {
        return positions[positionID].downline;
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    //Get TRX value
    function convertDollarToTRX(uint256 dollarVal) public view returns(uint256) {
       return (((dollarVal*100000)/USD_RATE)  * 1 trx)/10;
    }
    
    //Dynamically adjust USD value
    function adjustUSD(uint256 rate) external {
        require(admins[msg.sender] || mods[msg.sender], "Access Denied");
        USD_RATE = rate;
        emit updateUSDRate(USD_RATE);
    }
    
    //Enable/Disable Admin
    function setAdmin(address adminAddress, bool status) external {
        require(admins[msg.sender], "Access Denied");
        admins[adminAddress] = status;
    }
    
    //Enable/Disable Admin
    function setMods(address modAddress, bool status) external {
        require(admins[msg.sender], "Access Denied");
        mods[modAddress] = status;
    }
    
    //Withdraw excessive airdrop funds from contract to owner wallet
    function withdrawContractBalance() external payable {
        require(admins[msg.sender], "Access Denied");
        if(!address(uint160(msg.sender)).send(address(this).balance)) {
            address(uint160(msg.sender)).transfer(address(this).balance);
        }
        return;
    }
    
    //Set whitelistAddresses
    function setWhitelistAddress(address[] calldata addresses, bool excluded) external {
        require(admins[msg.sender], "Access Denied");
        for(uint256 i = 0; i < addresses.length; i++) {
            whitelistAddresses[addresses[i]] = excluded;
        }
    }
    
    function launchSmart20(bool _launchValue) external {
        require(admins[msg.sender], "Access Denied");
        smart20Launched = _launchValue;
    }
    
    function config(uint _subscription_time, uint _max_positions_can_buy) external {
        require(admins[msg.sender], "Access Denied");
        SUBSCRIPTION_TIME = _subscription_time;
        MAX_POSITIONS_CAN_BUY = _max_positions_can_buy;
    }
    
}