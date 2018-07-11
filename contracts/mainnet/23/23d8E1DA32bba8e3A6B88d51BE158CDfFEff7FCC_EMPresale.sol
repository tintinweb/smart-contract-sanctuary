pragma solidity ^0.4.18;

contract EMPresale {
    
    bool public inMaintainance;
    
    // Data -----------------------------
    
    struct Player {
        uint32 id;  // if 0, then player don&#39;t exist
        mapping(uint8 => uint8) bought;
        uint256 weiSpent;
        bool hasSpent;
    }
    
    struct Sale {
        uint8 bought;
        uint8 maxBought;
        uint32 cardTypeID;
        uint256 price;
        uint256 saleEndTime;
    }
    
    address admin;
    address[] approverArr; // for display purpose only
    mapping(address => bool) approvers;
    
    address[] playerAddrs;      // 0 index not used
    uint32[] playerRefCounts;   // 0 index not used
    
    mapping(address => Player) players;
    mapping(uint8 => Sale) sales;   // use from 1 onwards
    uint256 refPrize;
    
    
    // CONSTRUCTOR =======================
    
    function EMPresale() public {
        admin = msg.sender;
        approverArr.push(admin);
        approvers[admin] = true;
        
        playerAddrs.length = 1;
        playerRefCounts.length = 1;
    }
    
    // ADMIN FUNCTIONS =======================
    
    function setSaleType(uint8 saleID, uint8 maxBought, uint32 cardTypeID, uint256 price, uint256 saleEndTime) external onlyAdmin {
        Sale storage sale = sales[saleID];
        
        // assign sale type
        sale.bought = 0;
        sale.maxBought = maxBought;
        sale.cardTypeID = cardTypeID;
        sale.price = price;
        sale.saleEndTime = saleEndTime;
    }
    
    function stopSaleType(uint8 saleID) external onlyAdmin {
        delete sales[saleID].saleEndTime;
    }
    
    function redeemCards(address playerAddr, uint8 saleID) external onlyApprover returns(uint8) {
        Player storage player = players[playerAddr];
        uint8 owned = player.bought[saleID];
        player.bought[saleID] = 0;
        return owned;
    }
    
    function refund(address playerAddr) public onlyAdmin {
        Player storage player = players[playerAddr];
        uint256 spent = player.weiSpent;
        player.weiSpent = 0;
        playerAddr.transfer(spent);
    }
    
    function refundAll() external onlyAdmin {
        for(uint256 i=0; i<playerAddrs.length; i++)
            refund(playerAddrs[i]);
    }
    
    // PLAYER FUNCTIONS ========================
    
    function buySaleNonReferral(uint8 saleID) external payable {
        buySale(saleID, address(0));
    }
    
    function buySaleReferred(uint8 saleID, address referral) external payable {
        buySale(saleID, referral);
    }
    
    function buySale(uint8 saleID, address referral) private {
        
        require(!inMaintainance);
        require(msg.sender != address(0));
        
        // check that sale is still on
        Sale storage sale = sales[saleID];
        require(sale.saleEndTime > now);
        
        // check ether is paid
        require(msg.value >= sale.price);

        // check not all is bought
        require(sale.bought < sale.maxBought);
        sale.bought++;
        
        bool toRegisterPlayer = false;
        bool toRegisterReferral = false;
        
        // register player if unregistered
        Player storage player = players[msg.sender];
        if(player.id == 0)
            toRegisterPlayer = true;
        
        // give ownership
        player.bought[saleID]++;
        player.weiSpent += msg.value;
        
        // if hasn&#39;t referred, add referral
        if(!player.hasSpent) {
            player.hasSpent = true;
            if(referral != address(0) && referral != msg.sender) {
                Player storage referredPlayer = players[referral];
                if(referredPlayer.id == 0) {    // add referred player if unregistered
                    toRegisterReferral = true;
                } else {                        // if already registered, just up ref count
                    playerRefCounts[referredPlayer.id]++;
                }
            }
        }
        
        // register player(s)
        if(toRegisterPlayer && toRegisterReferral) {
            uint256 length = (uint32)(playerAddrs.length);
            player.id = (uint32)(length);
            referredPlayer.id = (uint32)(length+1);
            playerAddrs.length = length+2;
            playerRefCounts.length = length+2;
            playerAddrs[length] = msg.sender;
            playerAddrs[length+1] = referral;
            playerRefCounts[length+1] = 1;
            
        } else if(toRegisterPlayer) {
            player.id = (uint32)(playerAddrs.length);
            playerAddrs.push(msg.sender);
            playerRefCounts.push(0);
            
        } else if(toRegisterReferral) {
            referredPlayer.id = (uint32)(playerAddrs.length);
            playerAddrs.push(referral);
            playerRefCounts.push(1);
        }
        
        // referral prize
        refPrize += msg.value/40;    // 2.5% added to prize money
    }
    
    function GetSaleInfo(uint8 saleID) external view returns (uint8, uint8, uint8, uint32, uint256, uint256) {
        uint8 playerOwned = 0;
        if(msg.sender != address(0))
            playerOwned = players[msg.sender].bought[saleID];
        
        Sale storage sale = sales[saleID];
        return (playerOwned, sale.bought, sale.maxBought, sale.cardTypeID, sale.price, sale.saleEndTime);
    }
    
    function GetReferralInfo() external view returns(uint256, uint32) {
        uint32 refCount = 0;
        uint32 id = players[msg.sender].id;
        if(id != 0)
            refCount = playerRefCounts[id];
        return (refPrize, refCount);
    }
    
    function GetPlayer_FromAddr(address playerAddr, uint8 saleID) external view returns(uint32, uint8, uint256, bool, uint32) {
        Player storage player = players[playerAddr];
        return (player.id, player.bought[saleID], player.weiSpent, player.hasSpent, playerRefCounts[player.id]);
    }
    
    function GetPlayer_FromID(uint32 id, uint8 saleID) external view returns(address, uint8, uint256, bool, uint32) {
        address playerAddr = playerAddrs[id];
        Player storage player = players[playerAddr];
        return (playerAddr, player.bought[saleID], player.weiSpent, player.hasSpent, playerRefCounts[id]);
    }
    
    function getAddressesCount() external view returns(uint) {
        return playerAddrs.length;
    }
    
    function getAddresses() external view returns(address[]) {
        return playerAddrs;
    }
    
    function getAddress(uint256 id) external view returns(address) {
        return playerAddrs[id];
    }
    
    function getReferralCounts() external view returns(uint32[]) {
        return playerRefCounts;
    }
    
    function getReferralCount(uint256 playerID) external view returns(uint32) {
        return playerRefCounts[playerID];
    }
    
    function GetNow() external view returns (uint256) {
        return now;
    }

    // PAYMENT FUNCTIONS =======================
    
    function getEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function depositEtherBalance() external payable {
    }
    
    function withdrawEtherBalance(uint256 amt) external onlyAdmin {
        admin.transfer(amt);
    }
    
    // RIGHTS FUNCTIONS =======================
    
    function setMaintainance(bool maintaining) external onlyAdmin {
        inMaintainance = maintaining;
    }
    
    function isInMaintainance() external view returns(bool) {
        return inMaintainance;
    }
    
    function getApprovers() external view returns(address[]) {
        return approverArr;
    }
    
    // change admin
    // only admin can perform this function
    function switchAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    // add a new approver
    // only admin can perform this function
    function addApprover(address newApprover) external onlyAdmin {
        require(!approvers[newApprover]);
        approvers[newApprover] = true;
        approverArr.push(newApprover);
    }

    // remove an approver
    // only admin can perform this function
    function removeApprover(address oldApprover) external onlyAdmin {
        require(approvers[oldApprover]);
        delete approvers[oldApprover];
        
        // swap last address with deleted address (for array)
        uint256 length = approverArr.length;
        address swapAddr = approverArr[length - 1];
        for(uint8 i=0; i<length; i++) {
            if(approverArr[i] == oldApprover) {
                approverArr[i] = swapAddr;
                break;
            }
        }
        approverArr.length--;
    }
    
    // MODIFIERS =======================
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    modifier onlyApprover() {
        require(approvers[msg.sender]);
        _;
    }
}