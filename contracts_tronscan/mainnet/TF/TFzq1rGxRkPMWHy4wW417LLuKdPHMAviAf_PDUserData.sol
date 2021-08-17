//SourceUnit: IPDUserData.sol

pragma solidity 0.5.17;

interface IPDUserData {
    function register(address user, address inviter) external returns (bool);

    function updateUserPower(address user,uint256 personal,uint256 teamPower) external returns(bool);

    function updateUserPledge(address user,uint256 amount30,uint256 amount90,uint256 timestamp) external returns(bool);

    function updateFinance(address user,uint256 withdraw,uint256 lastWithdrawTime,uint256 frozen,uint256 pool) external returns(bool);

    function updateUserLastSettleTime(address user,uint256 settleTime) external returns(bool);

    function updateUserLastMonthSettleData(address user, uint256 teamPower,uint256 times) external returns (bool);

    function updateNetPower(uint256 computerPower,uint256 teamPower) external returns(bool);

    function getNetPower() external view returns(uint256 computerPower,uint256 teamPower) ;

    function getUserLastMonthSettleData(address user) external view returns( uint256 teamPower,uint256 times);

    function getUserInviter(address user) external view returns(address);

    function getUserTeamMembers(address user) external view returns(address[] memory);

    function getRegisterTime(address user) external view returns(uint256);

    function getUserPower(address user) external view returns(uint256 personal, uint256 team);

    function getUserPledge(address user) external view returns(uint256 pledge30, uint256 pledge90, uint256 pledgeTime);

    function getUserFinance(address user) external view returns(uint256 withdraw,uint256 lastWithdrawTime,uint256 frozen,uint256 pool);

    function getUserLastSettleTime(address user) external view returns(uint256);
}


//SourceUnit: Ownable.sol

pragma solidity 0.5.17;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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

}


//SourceUnit: PDUserData.sol

pragma solidity 0.5.17;

import "./Ownable.sol";
import "./IPDUserData.sol";

contract PDUserData is Ownable, IPDUserData {
    address public executor;
    mapping(address => UserDataInfo) public userInfoMap;
    mapping(address => UserSettleInfo) public userSettleMap;
    NetDataInfo public netDataInfo;

    struct UserDataInfo {
        address user;
        address inviter;
        address[] members;
        uint256 registerTime;
        uint256 personalPower;
        uint256 teamPower;
        uint256 speedUp;

        uint256 pledgeTime;
        uint256 pledge30;
        uint256 pledge90;

        uint256 withdraw;
        uint256 lastWithdrawTime;
        uint256 frozen;
        uint256 pool;
        uint256 settleTime;
    }

    struct UserSettleInfo {
        uint256 lastMonthTeamPower;
        uint256 lastMonthTime;
    }

    struct NetDataInfo {
        uint256 computerPower;
        uint256 teamPower;
    }


    constructor() public {
    }

    function updateExecutor(address _executor) public onlyOwner {
        executor = _executor;
    }

    function updateNetPower(uint256 computerPower, uint256 teamPower) public returns (bool){
        require(msg.sender == executor, "CALL updateNetPower ERROR");
        netDataInfo.teamPower = teamPower;
        netDataInfo.computerPower = computerPower;
        return true;
    }

    function getNetPower() public view returns (uint256 computerPower, uint256 teamPower){
        computerPower = netDataInfo.computerPower;
        teamPower = netDataInfo.teamPower;
    }


    function updateUserLastMonthSettleData(address user, uint256 teamPower, uint256 times) public returns (bool){
        require(msg.sender == executor, "CALL updateUserLastMonthSettleData ERROR");
        UserSettleInfo storage info = userSettleMap[user];
        info.lastMonthTeamPower = teamPower;
        info.lastMonthTime = times;
        return true;
    }

    function getUserLastMonthSettleData(address user) public view returns (uint256 teamPower, uint256 times){
        UserSettleInfo memory info = userSettleMap[user];
        teamPower = info.lastMonthTeamPower;
        times = info.lastMonthTime;

    }

    function register(address user, address inviter) public returns (bool) {
        require(msg.sender == executor, "CALL ERROR:register");
        UserDataInfo storage userInfo = userInfoMap[user];
        UserSettleInfo storage userSettle = userSettleMap[user];
        if (userInfo.registerTime > 0) {
            return true;
        }
        UserDataInfo storage inviteInfo = userInfoMap[inviter];
        if (inviteInfo.registerTime <= 0) {
            inviteInfo = userInfoMap[address(0x0)];
            inviteInfo.registerTime = now;
        }
        userInfo.registerTime = now;
        userInfo.user = user;
        userInfo.inviter = inviteInfo.user;
        userSettle.lastMonthTeamPower = 0;
        userSettle.lastMonthTime = now;
        inviteInfo.members.push(user);
        return true;
    }


    function updateUserPower(address user, uint256 personal, uint256 teamPower) public returns (bool){
        require(msg.sender == executor, "CALL ERROR:updateUserPower");
        UserDataInfo storage info = userInfoMap[user];
        info.personalPower = personal;
        info.teamPower = teamPower;
        return true;
    }

    function updateUserPledge(address user, uint256 amount30, uint256 amount90, uint256 timestamp) public returns (bool){
        require(msg.sender == executor, "CALL ERROR:updateUserPledge");
        UserDataInfo storage info = userInfoMap[user];
        info.pledge30 = amount30;
        info.pledge90 = amount90;
        info.pledgeTime = timestamp;
        return true;
    }

    function updateFinance(address user, uint256 withdraw, uint256 lastWithdrawTime, uint256 frozen, uint256 pool) public returns (bool){
        require(msg.sender == executor, "CALL ERROR:updateFinance");
        UserDataInfo storage info = userInfoMap[user];
        info.withdraw = withdraw;
        info.lastWithdrawTime = lastWithdrawTime;
        info.frozen = frozen;
        info.pool = pool;
        return true;
    }

    function updateUserLastSettleTime(address user, uint256 settleTime) public returns (bool){
        require(msg.sender == executor, "CALL ERROR:updateFinance");
        UserDataInfo storage info = userInfoMap[user];
        info.settleTime = settleTime;
        return true;
    }

    function getUserTeamMembers(address user) public view returns (address[] memory){
        UserDataInfo memory info = userInfoMap[user];
        address[] memory result = info.members;
        return result;
    }

    function getUserInviter(address user) public view returns (address){
        UserDataInfo memory info = userInfoMap[user];
        return info.inviter;
    }

    function getRegisterTime(address user) public view returns (uint256){
        UserDataInfo memory info = userInfoMap[user];
        return info.registerTime;
    }

    function getUserPower(address user) public view returns (uint256 personal, uint256 team){
        UserDataInfo memory info = userInfoMap[user];
        personal = info.personalPower;
        team = info.teamPower;
    }

    function getUserPledge(address user) public view returns (uint256 pledge30, uint256 pledge90, uint256 pledgeTime){
        UserDataInfo memory info = userInfoMap[user];
        pledge30 = info.pledge30;
        pledge90 = info.pledge90;
        pledgeTime = info.pledgeTime;
    }

    function getUserFinance(address user) public view returns (uint256 withdraw, uint256 lastWithdrawTime, uint256 frozen, uint256 pool){
        UserDataInfo memory info = userInfoMap[user];
        withdraw = info.withdraw;
        lastWithdrawTime = info.lastWithdrawTime;
        frozen = info.frozen;
        pool = info.pool;
    }

    function getUserLastSettleTime(address user) public view returns (uint256){
        UserDataInfo memory info = userInfoMap[user];
        return info.settleTime;
    }
}