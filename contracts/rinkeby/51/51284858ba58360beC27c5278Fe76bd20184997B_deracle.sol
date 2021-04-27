/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
// SPDX-License-Identifier: Unlicensed
interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract deracle is Ownable{

    struct User{
        int32 Id;
        int8 ReferCount;
        int8 Level;
        int32 UplineId;
        int32 LeftId;
        int32 RightId;
        int32 Position;
        int32 ReferralId;
        address OwnerAddress;
        bool IsPayout;
        bool IsEndGamePayout;
        uint CreatedBlock;
        uint CreatedTime;
    }
    
    mapping(uint32 => User) userlistbypos;
    mapping(uint32 => User) userlistbyid;
    mapping(address => int32[]) public userids;
    
    int8 public currentLevel;
    int public userCounter = 0;
    int idcounter = 3;
    uint32 public nextPosition = 1;
    address public token;
    address public owner;
    address private keeper;
    address public maintainer;
    uint public ExpiryInvestmentTimestamp;
    bool public IsExpired;
    uint public PayoutAmount;
    uint public MainterPayoutAmount;
    int public UnpaidUserCount;
    int public nextUnpaidUser = 3;
    
    IERC20 public ERC20Interface;

    struct Transfer {
        address contract_;
        address to_;
        uint256 amount_;
        bool failed_;
    }
    
    /**
     * @dev Event to notify if transfer successful or failed * after account approval verified */
    event TransferSuccessful(
        address indexed from_,
        address indexed to_,
        uint256 amount_
    );

    event TransferFailed(
        address indexed from_,
        address indexed to_,
        uint256 amount_
    );
    
    /**
     * @dev a list of all transfers successful or unsuccessful */
    Transfer public transaction;
    
    // uint public investamt = 500000000;
    // uint public referralamt = 250000000;
    // uint public maintaineramt = 50000000;
    
    uint public investamt = 100000;
    uint public referralamt = 50000;
    uint public maintaineramt = 10000;

    constructor() public {
        owner = msg.sender;
    }
    
    function Invest(int8 quantity, uint32 uplineId) public returns (bool){
        require(quantity > 0, "Minimum Investment Quantity Is 1");
        require(isUserExists(uplineId), "Referral Id Does Not Exist");
        require(isContractAlive(), "Contract terminated. Investment was helt for more than 365 days");
        for(int32 j =0; j < quantity; j++){
            //Pay the platform
            require(!IsExpired, "Contract terminated. Investment was helt for more than 365 days");
            require(depositTokens(uplineId));
            
            
            User memory user;
            int32[] memory array = new int32[](1);
            array[0] = 1;
            if(nextPosition == 1){
                
                user.Id = 1;
                user.ReferCount = 0;
                user.Level = 0;
                user.UplineId = -1;
                user.LeftId = -1;
                user.RightId = -1;
                user.Position = 1;
                user.ReferralId = -1;
                user.OwnerAddress = msg.sender;
                user.IsPayout = true;
                user.IsEndGamePayout = true;
                user.CreatedBlock = 0;
                user.CreatedTime = 0;
                
                userlistbyid[1] = user;
                userlistbypos[1] = user;
                
                nextPosition = 2;
            }
            userCounter += idcounter;
            
            //GET UPLINE
            User memory upline = userlistbyid[uint32(uplineId)];
            
            
            //CHECK WHICH SLOT UPLINE MADE
            int32 connectedUplineId = 0;
            int32 uplinereferred = upline.ReferCount;
            if (uplinereferred < 2) //1st / 2nd leg
            {
                connectedUplineId = insertNext(uplineId);
            }
            else //3rd LEG , RESET , FIND THE SUITABLE NODE
            {
                connectedUplineId = insertThird(uplineId);
            }
                
            int isrightleg = 0;
            if (userlistbyid[uint32(connectedUplineId)].LeftId != -1) {
                isrightleg = 1;
                userlistbyid[uint32(connectedUplineId)].RightId = int32(userCounter);
            }
            else
            {
                userlistbyid[uint32(connectedUplineId)].LeftId = int32(userCounter);
            }
                
            user.Id = int32(userCounter);
            user.ReferCount = 0;
            user.Level = userlistbyid[uint32(connectedUplineId)].Level + 1;
            user.UplineId = int32(connectedUplineId);
            user.LeftId = -1;
            user.RightId = -1;
            user.Position = int32((userlistbyid[uint32(connectedUplineId)].Position * 2) + isrightleg);
            user.OwnerAddress = msg.sender;
            user.ReferralId  = int32(uplineId);
            user.IsPayout = false;
            user.IsEndGamePayout = false;
            user.CreatedBlock = block_call();
            user.CreatedTime = time_call();
    
            if(user.Level > currentLevel){
                currentLevel = user.Level;
            }
            userlistbyid[uint32(userCounter)] = user;
            userlistbypos[uint32(user.Position)] = user;
            userids[msg.sender].push(int32(user.Id));
            ExpiryInvestmentTimestamp = time_call() + 365 days;
        }
        return true;
    }
    
    function isUserExists(uint32 userid) view internal returns (bool) {
        if(nextPosition == 1){
            return true;
        }
        
        if(userid == 1){
            return false;
        }
        
        return (userlistbyid[uint32(userid)].Id != 0);
    }
    
    function isContractAlive() view internal returns (bool){
        if(nextPosition == 1){
            return true;
        }
        
        if(time_call() < ExpiryInvestmentTimestamp){
            return true;
        }
        else{
            return false;
        }
    }
    
    function block_call() view internal returns (uint256 blocknumber){
        return block.number; 
    }
    
    function time_call() view internal returns (uint256 timestamp){
        return now;
    }
    
    function insertNext(uint32 uplineId) internal returns (int32 connectedUplineId){
        
        while(true){
            if(userlistbypos[uint32(nextPosition)].Id != 0){
                nextPosition++;
            }
            else{
                break;
            }
        }
        
        int32 previouslevelfirstuplineid = -1;
        
        if (nextPosition % 2 == 0)
        {
            previouslevelfirstuplineid = int32((nextPosition) / 2);
        }
        else
        {
            previouslevelfirstuplineid = int32((nextPosition - 1) / 2);
        }
        connectedUplineId = userlistbypos[uint32(previouslevelfirstuplineid)].Id;
        userlistbyid[uint32(uplineId)].ReferCount++;
        nextPosition++;
        
        while(true){
            if(userlistbypos[uint32(nextPosition)].Id != 0){
                nextPosition++;
            }
            else{
                break;
            }
        }
        
    }
    
    function insertThird(uint32 uplineId) internal returns (int32 connectedUplineId){
        //RESET THE UPLINE COUNT
        userlistbyid[uint32(uplineId)].ReferCount = 0;

        //FIND SUITABLE NODE
        // get the left if empty direct use , if not empty then compare global position value , 
        // if global position more then most right then move next level , until global position is in the middle of left and right then v just loop that particular level
        uint32 leftposition = uint32(userlistbyid[uint32(uplineId)].Position);
        uint32 rightposition = uint32(userlistbyid[uint32(uplineId)].Position);
        
        while(true){
            leftposition = uint32(leftposition * 2);
            rightposition = uint32(rightposition * 2 + 1);
            
            if(nextPosition < leftposition){
                //Find empty node between left to rightposition
                uint32 tempPosition = leftposition;
                uint32 count = rightposition - leftposition + 1;
                for(uint32 i = 0; i < count; i++){
                    if(userlistbypos[tempPosition + i].Id == 0){
                        connectedUplineId = userlistbypos[(tempPosition + i) / 2].Id;
                        return connectedUplineId;
                    }
                }
                
            }
            
            if(leftposition == nextPosition){
                connectedUplineId = userlistbypos[nextPosition / 2].Id;
                return connectedUplineId;
            }
            
            if(rightposition == nextPosition){
                connectedUplineId = userlistbypos[(nextPosition - 1) / 2].Id;
                return connectedUplineId;
            }
            
            if(nextPosition > leftposition && nextPosition < rightposition){
                //Inset at next Postion
                if(nextPosition % 2 == 0){
                    connectedUplineId = userlistbypos[nextPosition / 2].Id;
                    return connectedUplineId;
                }
                else{
                    connectedUplineId = userlistbypos[(nextPosition - 1) / 2].Id;
                    return connectedUplineId;
                }
            }
        }
    }
    
    
    function depositTokens(
        uint32 uplineId
    )  internal returns (bool success){
        require(token != 0x0);

        address contract_ = token;
        address from_ = msg.sender;

        ERC20Interface = IERC20(contract_);

        //Transfer to contract
        if (investamt > ERC20Interface.allowance(from_, address(this))) {
            emit TransferFailed(from_, keeper, investamt);
            revert();
        }
        ERC20Interface.transferFrom(from_, address(this), investamt);
        emit TransferSuccessful(from_, address(this), investamt);
        
        if(nextPosition != 1){
            //Transfer to referral
            ERC20Interface.transfer(userlistbyid[uplineId].OwnerAddress , referralamt);
        }
         //Maintainer payout
        MainterPayoutAmount = MainterPayoutAmount + maintaineramt;
        UnpaidUserCount++;

        return true;
    }
    
    function Payout3XReward(uint32 UserId) public{
        require(!IsExpired, "Contract has expired.");
        require(msg.sender == userlistbyid[UserId].OwnerAddress, "Only owner of the investment can claim 3X payment");
        
        if(checkPayoutTree(UserId)){
            Payout(UserId); 
        }
        
    }
    
    function checkPayoutTree(uint32 UserId) view public returns(bool){
        
        if(userlistbyid[UserId].IsPayout){
            return false;
        }
        
        int32[] memory list = new int32[](2);
        User memory user;
        
        if(userlistbyid[uint32(UserId)].LeftId != -1){
            user = userlistbyid[uint32(userlistbyid[UserId].LeftId)];
            if(user.LeftId != -1 && user.RightId != 1){
                list[0] = user.LeftId;
                list[1] = user.RightId;
                
                for(uint i = 0; i < list.length; i++){
                    user = userlistbyid[uint32(list[i])];
                    if(user.LeftId == -1 || user.RightId == -1){
                        return false;
                    }
                }
            }
            else{
                return false;
            }
        }
        else{
            return false;
        }
            
        if(userlistbyid[uint32(UserId)].RightId != -1){
            user = userlistbyid[uint32(userlistbyid[uint32(UserId)].RightId)];
            if(user.LeftId != -1 && user.RightId != 1){
                list[0] = user.LeftId;
                list[1] = user.RightId;
                
                i = 0;
                for(i = 0; i < list.length; i++){
                    user = userlistbyid[uint32(list[i])];
                    if(user.LeftId == -1 || user.RightId == -1){
                        return false;
                    }
                }
                return true;
            }
            else{
                return false;
            }
        }
        else{
            return false;
        }
        
        return false;
    }
    
    
    
    function Payout(uint32 UserId) internal{
        require(userlistbyid[UserId].IsPayout == false, "User already received 3x payout");
        if(userlistbyid[UserId].IsPayout == false){
            userlistbyid[UserId].IsPayout = true;
            ERC20Interface.transfer(userlistbyid[UserId].OwnerAddress, investamt*3);
            UnpaidUserCount--;
        }
    }
    
    function PayoutMaintainer() public onlyOwner{
        require(maintainer != 0x0, "No mainter account set for payout");
        require(MainterPayoutAmount > 0, "Mainter payout balance is 0");
        
        if(MainterPayoutAmount != 0){
            
            address contract_ = token;
            ERC20Interface = IERC20(contract_);

            if(nextPosition != 1){
                //Transfer to maintainer
                ERC20Interface.transfer(maintainer , MainterPayoutAmount);
                MainterPayoutAmount = 0;
            }
        }
    }
    
    function getUserByAddress(address userAddress) view public returns (int32[] useridlist){
        return userids[userAddress];
    }
    
    function getUserIds(address userAddress) view public returns (int32[]){
        return userids[userAddress];
    }
    
    
    function GetTreeByUserId(uint32 UserId, bool report) view public returns (User[]){
        //Get Position
        uint32 userposition = uint32(userlistbyid[uint32(UserId)].Position);
        //Try to return all data base on position
        uint userCount = 0;
        if(report){
            userCount = uint((2 ** (uint(currentLevel) + 1)) - 1);
        }
        else{
            userCount = 15;
        }
        User[] memory userlist = new User[](userCount);
        uint counter = 0;
        uint32 availablenodes = 2;
        int8 userlevel = 2;
        
        userlist[counter] = userlistbyid[uint32(userlistbypos[userposition].Id)];
        counter++;
        
        while(true){
            userposition = userposition * 2;
            
            for(uint32 i = 0; i < availablenodes; i++){
                userlist[counter] = userlistbyid[uint32(userlistbypos[userposition + i].Id)];
                counter++;
            }
            
            availablenodes = availablenodes * 2;
            userlevel++;
            if(report == false){
                if(availablenodes > 8){
                    break;
                }
            }
            else{
                if(userlevel > currentLevel){
                    break;
                }
            }
        }
        return userlist;
    }
    
    function GetUserById(uint32 userId) view public returns(User user){
        user = userlistbyid[userId];
    }
    
    function CheckInvestmentExpiry() public onlyOwner{
        require(!isContractAlive(), "Contract is alive.");
        require(PayoutAmount == 0, "Contract balance is already calculated.");
        
        if(MainterPayoutAmount != 0){
            PayoutMaintainer();
        }
        
        //Current Date - last Investment Date >= 365 days from last investment date timestamp
        if(!isContractAlive()){
            IsExpired = true;
            uint contractBalance = ERC20Interface.balanceOf(address(this));
            PayoutAmount = uint(contractBalance / uint(UnpaidUserCount));
        }
    }
    
    function RemainingInvestorPayout(uint quantity) public onlyOwner returns (bool){
        require(IsExpired, "Contract Is Still Alive");
        require(userCounter >= nextUnpaidUser, "All users are paid");
        
        for(uint32 i = 0; i < quantity; i++){
            if(userlistbyid[uint32(nextUnpaidUser)].IsPayout == false && userlistbyid[uint32(nextUnpaidUser)].IsEndGamePayout == false){
                userlistbyid[uint32(nextUnpaidUser)].IsEndGamePayout = true;
                ERC20Interface.transfer(userlistbyid[uint32(nextUnpaidUser)].OwnerAddress, PayoutAmount);
                UnpaidUserCount--;
            }
            nextUnpaidUser += idcounter;
            if(nextUnpaidUser > userCounter){
                return true;
            }
        }
        return true;
    }
    
    function GetContractBalance() view public returns(uint){
        return ERC20Interface.balanceOf(address(this)) - MainterPayoutAmount;
    }
    
    function GetMaintainerAmount() view public returns(uint){
        return MainterPayoutAmount;
    }
        
    function GetExpiryInvestmentTimestamp() view public returns(uint){
        return ExpiryInvestmentTimestamp;
    }
    
    function GetIsExpired() view public returns (bool){
        return IsExpired;
    }
    
    function GetUnpaidUserCount() view public returns (int){
        return UnpaidUserCount;
    }
    
    function setMaintainer(address address_)
        public
        onlyOwner
        returns (bool)
    {
        require(address_ != 0x0);
        maintainer = address_;
        return true;
    }
    
    function setToken(address address_)
        public
        onlyOwner
        returns (bool)
    {
        require(address_ != 0x0);
        token = address_;
        return true;
    }
    
    function testSetExpiryTrue() public{
        ExpiryInvestmentTimestamp = time_call() - 366 days;
    }
    
    function testSetExpiryFalse() public{
        ExpiryInvestmentTimestamp = time_call();
        IsExpired = false;
        PayoutAmount = 0;
    }
    
    // function clearRemaingBalance() public onlyOwner{
    //     require(IsExpired);
    //     require(PayoutAmount > 0);
    //     require(UnpaidUserCount == 0);
    //     ERC20Interface.transfer(maintainer , GetContractBalance());
    // }
    
    function sosPayout() public onlyOwner{
        ERC20Interface.transfer(msg.sender , GetContractBalance());
        ERC20Interface.transfer(msg.sender , GetMaintainerAmount());
        IsExpired = true;
    }
    
}