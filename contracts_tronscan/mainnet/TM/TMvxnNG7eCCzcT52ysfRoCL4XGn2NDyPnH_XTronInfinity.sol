//SourceUnit: XtronInfinity.sol

pragma solidity ^0.5.4;

contract XTronInfinity {

    address payable public adminWallet;
    address payable public xTronWallet;
    address payable public insuranceWallet;
    address payable public devWallet;
    
    uint constant public MAX_CYCLE = 3; 
    uint constant public WAIT_TIME = 1 hours;

    uint public pool1CurrUserID = 0;
    uint public pool1ActiveUserID = 0;
    uint public pool1WaitCurrID = 0;
    uint public pool1WaitActiveID = 1;

    uint public totalUsers = 0;
    uint public totalSlots = 0;

    struct PoolUserStruct {
        uint64 totalPaid;
        uint32 slots;
        uint24 referrals;
        uint24 refIncome;
        address payable referrer;
    }
    
    struct UserSlot{
        uint32 checkpoint;
        address payable id;
        uint8 counter;
    }

    mapping(address => PoolUserStruct) public pool1Users;
    UserSlot[] public pool1UserIds;
    UserSlot[] public pool1WaitedIds;

    constructor(address payable adminAddr, address payable xTronAddr, address payable insuranceAddr, address payable devAddr) public {
        adminWallet = adminAddr;
        xTronWallet = xTronAddr;
        insuranceWallet = insuranceAddr;
        devWallet = devAddr;

        PoolUserStruct memory poolUser;

        //==============
        // Defaut Account Pools Initalization
        //==============
        poolUser = PoolUserStruct({
            totalPaid : 0,
            slots : 1,
            referrals: 0,
            refIncome: 0,
            referrer: address(0)
        });
        
        pool1Users[xTronWallet] = poolUser;
        pool1UserIds.push(UserSlot(0,address(0),0));
        pool1WaitedIds.push(UserSlot(0,address(0),0));
        pool1UserIds.push(UserSlot(uint32(now), xTronWallet, 0));
        
        pool1CurrUserID++;
        pool1ActiveUserID = pool1CurrUserID;
        
        totalUsers = 1;
    }

    function() external payable {}

    function payFees() private {
        adminWallet.transfer(75e5);// 7.5 trx
        xTronWallet.transfer(20 trx);
        insuranceWallet.transfer(10 trx);
        devWallet.transfer(25e5);// 2.5 trx
    }

    function buyPool1(address payable _referrer) external payable {
        
        require(msg.value == 120 trx, "Invalid amount");
        
        if(pool1Users[msg.sender].referrer == address(0)){
            require(_referrer != address(0) && _referrer != msg.sender && pool1Users[_referrer].slots > 0, "Invalid address");
            pool1Users[msg.sender].referrer = _referrer;
            pool1Users[_referrer].referrals++;
        }
        
        if (pool1Users[msg.sender].slots == 0) {
            totalUsers++;
        }
        pool1Users[msg.sender].slots++;
        totalSlots++;

        pool1UserIds.push(UserSlot(uint32(now), msg.sender, 0));
        address payable pool1ActiveUser = pool1UserIds[pool1ActiveUserID].id;
        
        //Move activeUser to the wait q
        if(pool1UserIds[pool1ActiveUserID].counter + 1 < MAX_CYCLE){
            pool1WaitCurrID++;
            pool1WaitedIds.push(UserSlot(uint32(now), pool1ActiveUser, pool1UserIds[pool1ActiveUserID].counter + 1));
        }
        //Move a wiating user into the main q
        if(pool1WaitActiveID <= pool1WaitCurrID && block.timestamp - pool1WaitedIds[pool1WaitActiveID].checkpoint > WAIT_TIME){
            pool1UserIds.push(pool1WaitedIds[pool1WaitActiveID]);
            pool1WaitActiveID += 1;
            pool1CurrUserID += 2;
        }else{
            pool1CurrUserID += 1;
        }
        pool1ActiveUserID++;
        
        //Pay Referrer
        pool1Users[pool1Users[msg.sender].referrer].refIncome++;
		pool1Users[msg.sender].referrer.transfer(20 trx);
		
		pool1Users[pool1ActiveUser].totalPaid++;
		//Transfer Fees
        pool1ActiveUser.transfer(60 trx);
        payFees();
    }
    
    function getStats() public view returns(
        uint statsTotalUsers,
        uint statsTotalSlots, 
        uint userTotalPaid,
        uint userReferrals,
        uint userRefIncome,
        uint userSlots,
        address userReferrer,
        uint statsPool1ActiveUserID,
        uint statsPool1CurrUserID,
        address statsCurrentAddress,
        address statsActiveAddress){
            return (
                totalUsers, 
                totalSlots,
                pool1Users[msg.sender].totalPaid,
                pool1Users[msg.sender].referrals,
                pool1Users[msg.sender].refIncome,
                pool1Users[msg.sender].slots,
                pool1Users[msg.sender].referrer,
                pool1ActiveUserID,
                pool1CurrUserID,
                pool1UserIds[pool1CurrUserID].id,
                pool1UserIds[pool1ActiveUserID].id);
        }
}