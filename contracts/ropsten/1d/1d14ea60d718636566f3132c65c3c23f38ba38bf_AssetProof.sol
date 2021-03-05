pragma solidity  0.8.1;
/**
 * Smart contract for asset proof
 * version 1.0.0
 * kevin
 * 2021.2.20
 */
 
import "./SafeMath.sol";
import "./TetherUSDT.sol";
import "./DataStructureAndState.sol";

contract AssetProof is StateConst,DataStructure{
    
    using SafeMath for uint256;
    
    //erc20 contract instantiate object
    IERC20 usdt;
    
    //owner Record contract issuer account
    address  owner;
    
    //Constructor, initialize erc20 contract address, administrator accounts address, and important parameters
    constructor(address _usdtConAddr,AdminSetup memory _adminSetupInfo) public {
        usdt = IERC20(_usdtConAddr);
        owner = msg.sender;
        adminSetupInfo = _adminSetupInfo;
    }
    
    //The given address is in an admin?
    function addrInAdmins(address _addr) internal returns(bool) {
        for(uint8 i=0;i<5;i++){
            if(_addr == adminSetupInfo.admins[i]){
                return true;
            }
        }
        return false;
    }
    
    //start sync assets snapshots
    function startSyncSnapshot() public returns (bool success){
        require(adminSetupInfo.assetSnapshotSyncAddress == msg.sender,"Only the account assetSnapshotSyncAddress can do this.");
        snapshotState.syncState = ASSETS_SNAPSHOT_IS_SYNCING;
        snapshotState.tempSnapshotTotalAssets = 0;
        snapshotState.syncCounter = 0;
        snapshotState.tempCurrentSnapshotVersion++;
        success = true;
    }
    
    //Insert datas to snapshots
    function insertSingleSnapshot(address userAddress,uint256 balance) public returns(bool success) {
        require(adminSetupInfo.assetSnapshotSyncAddress == msg.sender,"Only the account assetSnapshotSyncAddress can do this");
        require(snapshotState.syncState == ASSETS_SNAPSHOT_IS_SYNCING,"Synchronization has not yet started or has ended");
        if(!userSnapShots[userAddress][snapshotState.tempCurrentSnapshotVersion].isExist){
            userSnapShots[userAddress][snapshotState.tempCurrentSnapshotVersion].isExist = true;
            snapshotState.syncCounter++;
            snapshotState.tempSnapshotTotalAssets = snapshotState.tempSnapshotTotalAssets.add(balance);
        }else{
        
            uint256 oldBalance = userSnapShots[userAddress][snapshotState.tempCurrentSnapshotVersion].balance;
            snapshotState.tempSnapshotTotalAssets = snapshotState.tempSnapshotTotalAssets.sub(oldBalance);
            snapshotState.tempSnapshotTotalAssets = snapshotState.tempSnapshotTotalAssets.add(balance);
        }
        userSnapShots[userAddress][snapshotState.tempCurrentSnapshotVersion].balance = balance;
        success = true;
    }
    
    //Delete single user snapshot  from snapshots
    function deleteSingleSnapshot(address userAddress) public returns(bool success) {
        require(adminSetupInfo.assetSnapshotSyncAddress == msg.sender,"Only the account assetSnapshotSyncAddress can do this.");
        require(snapshotState.syncState == ASSETS_SNAPSHOT_IS_SYNCING,"Synchronization has not yet started or has ended");
        require(userSnapShots[userAddress][snapshotState.tempCurrentSnapshotVersion].isExist,"The data to be deleted does not exist.");
        uint256 oldBalance = userSnapShots[userAddress][snapshotState.tempCurrentSnapshotVersion].balance;
        snapshotState.tempSnapshotTotalAssets = snapshotState.tempSnapshotTotalAssets.sub(oldBalance);
        snapshotState.syncCounter--;
        delete userSnapShots[userAddress][snapshotState.tempCurrentSnapshotVersion];
        success = true;
    }
    
    //Replace the old official snapshot with a new temporary snapshot 
    function replaceSnapshot(uint256 snapshotDatetime) public returns(bool success) {
        require(adminSetupInfo.assetSnapshotSyncAddress == msg.sender,"Only the account assetSnapshotSyncAddress can do this");
        require(usdt.balanceOf(address(this))>=snapshotState.tempSnapshotTotalAssets,"The asset proof contract address does not have enough reserve funds, please deposit USDT asset reserve funds.");
        require(snapshotState.syncState == ASSETS_SNAPSHOT_IS_SYNCING,"The sync status is wrong.");
        
        //record history
        snapshotHistories[snapshotState.tempCurrentSnapshotVersion].usersNum = snapshotState.syncCounter;
        snapshotHistories[snapshotState.tempCurrentSnapshotVersion].totalsAsset = snapshotState.tempSnapshotTotalAssets;
        snapshotHistories[snapshotState.tempCurrentSnapshotVersion].snapshotDatetime = snapshotDatetime;
        
        //Set syncState set to 0，syncCounter set to 0,needSyncNum set to 0,snapshotAssets set to tempAssets,tempAssets set to 0.
        snapshotState.syncState = ASSETS_SNAPSHOT_IS_NOT_SYNCING;
        snapshotState.syncCounter = 0;
        snapshotState.snapshotTotalAssets = snapshotState.tempSnapshotTotalAssets;
        snapshotState.tempSnapshotTotalAssets = 0;
        //Use tempSnpsotVer replace currSnpsotVer version.
        snapshotState.currentSnapshotVersion = snapshotState.tempCurrentSnapshotVersion;
        success = true;
        
    }
    
    //Get current snapshot version
    function getCurrentSnapshotVersion() public view returns (uint64 retCurrentSnapshotVersion) {
        retCurrentSnapshotVersion = snapshotState.currentSnapshotVersion;
    }
    
    //Get current temp snapshot version
    function getTempCurrentSnapshotVersion() public view returns (uint64 retTempCurrentSnapshotVersion) {
        retTempCurrentSnapshotVersion = snapshotState.tempCurrentSnapshotVersion;
    }
    
    //Get a user's asset snapshot by address and versoin.
    function queryAssets(address userAddress,uint64 version) public view returns (uint256 balance,uint256 datetime) {
        
        balance = userSnapShots[userAddress][version].balance;
        datetime = snapshotHistories[version].snapshotDatetime;
        
    }
    
    //Official asset snapshots by totals.
    function getSnapshotTotalAssetsByVersion(uint64 version) public view returns (uint32 userNum,uint256 totalsAsset,uint256 datetime) {
        
        userNum = snapshotHistories[version].usersNum;
        totalsAsset = snapshotHistories[version].totalsAsset;
        datetime = snapshotHistories[version].snapshotDatetime;
    }
    
    //Get the USDT balance on the contract address
    function getbalanceForUSDT() public view returns (uint256) {
       return usdt.balanceOf(address(this));
    }
    
    
    //Reserves withdraw by exchange
    function reservesWithdraw(uint256 amount) public returns(bool success) {
        require(msg.sender == adminSetupInfo.reservesWithdrawAddrSender,"Only account reservesWithdrawAddrSender can do this.");
        require(getbalanceForUSDT() >= snapshotState.snapshotTotalAssets.add(amount),"The asset proof contract address does not have enough reserve funds.");
        usdt.transfer(adminSetupInfo.reservesWithdrawAddrReceiver, amount);
        success = true;
    }
    
    // Users apply for withdraw,generate withdraw orders.
    function userApplyForWithdraw() public returns(bool success,uint64 currentId){
        require(userSnapShots[msg.sender][snapshotState.currentSnapshotVersion].isExist,"The user is not in the current snapshot list");
        require(userSnapShots[msg.sender][snapshotState.currentSnapshotVersion].balance > 0,"Snapshot asset balance is 0.");
        require(userSnapShots[msg.sender][snapshotState.currentSnapshotVersion].withdrawFlag == USER_WITHDRAW_SNAPSHOT_NOTHING,"The snapshot balance of this account address is being withdrawn...");
        
        //wirte to order
        lastOrderId++;
        withdrawOrders[lastOrderId].orderId = lastOrderId;
        withdrawOrders[lastOrderId].withdrawAddress = msg.sender;
        withdrawOrders[lastOrderId].orderAmount = userSnapShots[msg.sender][snapshotState.currentSnapshotVersion].balance;
        withdrawOrders[lastOrderId].orderBlockHight = block.number;
        withdrawOrders[lastOrderId].orderState = USER_WITHDRAW_ORDER_PENGING;
        withdrawOrders[lastOrderId].orderVersion = snapshotState.currentSnapshotVersion;
        withdrawOrders[lastOrderId].orderDatetime = block.timestamp;
        userSnapShots[msg.sender][snapshotState.currentSnapshotVersion].withdrawFlag == USER_WITHDRAW_SNAPSHOT_PENDING;

        addressOrdersIds[msg.sender].push(lastOrderId);
        //retrun data
        currentId = lastOrderId;
        success = true;
    }
    
    // User cancel withdraw order byself.
    function userCancelWithdrawOrder(uint64 orderId) public returns(bool success) {
        require(msg.sender == withdrawOrders[orderId].withdrawAddress,"The caller does not have permission to cancel this order.");
        require(withdrawOrders[orderId].orderState == USER_WITHDRAW_ORDER_PENGING,"Incorrect order status.");
        withdrawOrders[orderId].orderState = USER_WITHDRAW_ORDER_CANCELED;
        userSnapShots[msg.sender][snapshotState.currentSnapshotVersion].withdrawFlag == USER_WITHDRAW_SNAPSHOT_NOTHING;
        success =  true;
    }
    
    //If time has exceeded withdrawTime days, users can directly withdraw successfully.
    function userWithdraw(uint64 orderId) public returns(bool success) {
        require(msg.sender == withdrawOrders[orderId].withdrawAddress,"The caller does not have permission to operate this order.");
        require(withdrawOrders[orderId].orderState == USER_WITHDRAW_ORDER_PENGING,"Incorrect order status.");
        require(userSnapShots[msg.sender][snapshotState.currentSnapshotVersion].balance > 0,"The balance of this snapshot has been withdrawn.");
        uint256 howManyBlockNums = block.number - withdrawOrders[orderId].orderBlockHight;
        require(howManyBlockNums > adminSetupInfo.blockNumsFromWithdrawInitToSucc,"The withdrawal order has not reached the withdrawal time.");
        require(withdrawOrders[orderId].orderVersion == snapshotState.currentSnapshotVersion,"The order version must match the current snapshot version.");
        withdrawOrders[orderId].orderState = USER_WITHDRAW_ORDER_SUCCEED;
        userSnapShots[msg.sender][snapshotState.currentSnapshotVersion].balance = 0;
        snapshotState.snapshotTotalAssets = snapshotState.snapshotTotalAssets.sub(withdrawOrders[orderId].orderAmount);
        userSnapShots[msg.sender][snapshotState.currentSnapshotVersion].withdrawFlag == USER_WITHDRAW_SNAPSHOT_SUCCEED;
        usdt.transfer(msg.sender,withdrawOrders[orderId].orderAmount);
        success = true;

    }
    
    //Get withdraw order by address.
    function getUserWithdrawOrderIdByAddress(address userAddress) public view returns(uint64[] memory retOrderIds) {
        retOrderIds = addressOrdersIds[userAddress];
    }
    
    //Get a withdraw order by orderid.
    function getUserWithdrawOrderById(uint64 orderId) public view returns(WithdrawOrder memory retWithdrawOrder){

        retWithdrawOrder = withdrawOrders[orderId];
    }
    
    //administrator initiate a proposal for modify setup info.
    function initiateProposal(
        address withdrawAddrSender,
        address withdrawAddrReceiver,
        address snapshotSyncAddress,
        uint256 blockNumsFromWithdrawInitToSucc,
        uint256 proposalExpiredBlocks
    ) public returns(uint64 proposalNum) {
                                  
        require(addrInAdmins(msg.sender),"Non-administrator accounts are not allowed to initiate proposals");
                                  
        //Process the previous proposal's state
        uint64 currPlId = addressCurrentProposalId[msg.sender];
        if(currPlId != 0){
            if(proposals[msg.sender][currPlId].plState == PROPOSAL_STATE_PENGING){
                if(block.number >= proposals[msg.sender][currPlId].plBlockHight + adminSetupInfo.proposalExpiredBlocks){
                    proposals[msg.sender][currPlId].plState = PROPOSAL_STATE_EXPIRED; // Expired
                }else{
                    proposals[msg.sender][currPlId].plState = PROPOSAL_STATE_CANCELED; // cancel previous proposal byself
                }
            }
        }                              
                                  
        //Initiate a new proposal
        currPlId++;
        //proposalSt memory prost = proposals[msg.sender][currPlId];
        proposals[msg.sender][currPlId].plId = currPlId;
        proposals[msg.sender][currPlId].sponsor = msg.sender;
        proposals[msg.sender][currPlId].withdrawAddrSender = withdrawAddrSender;
        proposals[msg.sender][currPlId].withdrawAddrReceiver = withdrawAddrReceiver;
        proposals[msg.sender][currPlId].snapshotSyncAddress = snapshotSyncAddress;
        proposals[msg.sender][currPlId].bokNumsFromWithdrawInitToSucc = blockNumsFromWithdrawInitToSucc;
        proposals[msg.sender][currPlId].proposalExpiredBlocks = proposalExpiredBlocks;
        proposals[msg.sender][currPlId].plState = PROPOSAL_STATE_PENGING;
        proposals[msg.sender][currPlId].plBlockHight = block.number;
        proposals[msg.sender][currPlId].plDatetime = block.timestamp;
        addressCurrentProposalId[msg.sender]++;
        proposalNum = currPlId;
                                  
    }
    
    function proposalIsValid(address sponsor,uint64 proposalId) internal returns(bool){
        if(proposals[sponsor][proposalId].plState == PROPOSAL_STATE_PENGING && block.number < proposals[sponsor][proposalId].plBlockHight + adminSetupInfo.proposalExpiredBlocks){
            return true;
        }else{
            return false;
        }
    }
    
    //administrator vote for proposal
    function voteForProposal(address sponsor,uint64 proposalId) public returns(bool success){
        require(addrInAdmins(msg.sender),"Non-administrator accounts are not allowed to vote");
        require(proposalIsValid(sponsor,proposalId),"Can only vote on the valid proposal");
        require(voteProposalState[msg.sender][sponsor][proposalId] == 0,"Repeat voting");
       
        //voting
        voteProposalState[msg.sender][sponsor][proposalId] = VOTE_STATE_VOTED;
        proposals[sponsor][proposalId].supporters.push(msg.sender);
        
        //If vote success
        if(voteMoreThanTree(sponsor,proposalId)){
            adminSetupInfo.reservesWithdrawAddrSender = proposals[sponsor][proposalId].withdrawAddrSender;
            adminSetupInfo.reservesWithdrawAddrReceiver = proposals[sponsor][proposalId].withdrawAddrReceiver;
            adminSetupInfo.assetSnapshotSyncAddress = proposals[sponsor][proposalId].snapshotSyncAddress;
            adminSetupInfo.blockNumsFromWithdrawInitToSucc = proposals[sponsor][proposalId].bokNumsFromWithdrawInitToSucc;
            adminSetupInfo.proposalExpiredBlocks = proposals[sponsor][proposalId].proposalExpiredBlocks;
            proposals[sponsor][proposalId].plState = PROPOSAL_STATE_PASSED; //proposal passed
        }
        success = true;
    }
    
    //Query a proposal info
    function queryProposal(address sponsor,uint64 proposalId) public view returns(ProposalInfo memory proposlInfo){
           
        proposlInfo = proposals[sponsor][proposalId];
        
    }
    
    //Query vote info about a proposal
    function queryCurrVoting(address sponsor,uint64 proposalId) public view returns(address[] memory supporters,uint256 voteNumber) {
       
       supporters = proposals[sponsor][proposalId].supporters;
       voteNumber = supporters.length;
    }
    
    //Are there currently three different administrators voting
    function voteMoreThanTree(address sponsor, uint64 proposalId) internal returns(bool){
        uint8 voteNum = 0;
        for(uint8 i=0;i<5;i++){
            voteNum += voteProposalState[adminSetupInfo.admins[i]][sponsor][proposalId];
        }
        if(voteNum >=3){
            return true;
        }else{
            return false;
        }
        
    }
    
    //Get snapshot syncCounter
    function getSnapshotSyncCounter() public view returns(uint32 syncCounter){
        syncCounter = snapshotState.syncCounter;
    }
    
    //Get datas about asset snapshot sync.
    function getSnapShotStates() public view returns(SnapshotState memory retSnapshotState){
        retSnapshotState = snapshotState;
    }
    
    //Get admins setup info
    function getAdminSetupInfo() public view returns (AdminSetup memory retAdminSetupInfo) {
        retAdminSetupInfo = adminSetupInfo;                                          
    }
    
}