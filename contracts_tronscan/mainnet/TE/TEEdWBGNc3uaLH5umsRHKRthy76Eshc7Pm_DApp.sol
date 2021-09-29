//SourceUnit: DApp.sol

pragma solidity 0.5.17;

import "./IDAppData.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";


contract DApp is Ownable {
    using SafeMath for uint256;
    //腾讯会议发币操作地址
    address private TENCENT_ADDRESS;

    IERC20 private LP_GAF;
    IERC20 private LP_OLPC;
    IERC20 private OLPC;
    IDAppData private DAPP_DATA;
    //可以领取收益的时间
    mapping(address => bool) private registerMap;

    uint256 private START_TIME = 1632833520;
    uint256 private GET_COIN_TIME = 1637931120;

    constructor() public {
        //主网
        OLPC = IERC20(0x412efca6cf6aa205609b81db8d4dcb8e9632e895b7);
        LP_OLPC = IERC20(0x418b1c51fc2b7f537b00c7873a6af1368bcfe40e3a);
        LP_GAF = IERC20(0x413eaae1dd8043fdabdfe504edc4b441d6f10bf52f);

        //shasta
        //        OLPC = IERC20(0x41facc8d83d3142dacc8bc84fd913a7d10b2beb2ab);
        //        LP_OLPC = IERC20(0x410ccec3fb1583ee4b9fee3b6bd57ef189fa0c710a);
        //        LP_GAF = IERC20(0x41c7a6ea7f1c33e5f797585060ebd2e006f6be778e);

        TENCENT_ADDRESS = address(msg.sender);
    }

    function setActivityTime(uint256 start, uint256 end) public onlyOwner returns (bool){
        if (start > 0) {
            START_TIME = start;
        }
        if (end > 0) {
            GET_COIN_TIME = end;
        }
        return true;
    }

    modifier needSignUp() {
        address user = address(msg.sender);
        if (!registerMap[user]) {
            uint256 time = DAPP_DATA.getUserSignUpTime(user);
            require(time > 0, "not sign up");
            registerMap[user] = true;
        }
        _;
    }

    function setDataAddress(address data) public onlyOwner returns (bool){
        DAPP_DATA = IDAppData(data);
        return true;
    }

    function updateGetCoinTime(uint256 time) public onlyOwner returns (bool){
        GET_COIN_TIME = time;
        return true;
    }

    //升级合约 转出里面的币到新的合约
    function gradeUp(uint8 _type, uint256 amount, address to) public onlyOwner returns (bool){
        if (_type == 1) {
            OLPC.transfer(to, amount);
        } else if (_type == 3) {
            LP_GAF.transfer(to, amount);
        } else if (_type == 2) {
            LP_OLPC.transfer(to, amount);
        } else {
            return false;
        }
        return true;
    }

    //获取用户的质押数量
    function getUserPledge(address user) public view returns (uint256 two, uint256 olpc, uint256 gaf){
        (two, olpc, gaf) = DAPP_DATA.getUserPledge(user);
    }


    //获取用户推荐数据
    function getTeamPowerData(address user) public view returns (uint256 power, uint256 teamPower){
        teamPower = DAPP_DATA.getNetTeamPower();
        power = DAPP_DATA.getUserTeamPower(user);
    }

    //赎回
    function release(uint8 poolType, uint256 amount) public payable needSignUp returns (bool){
        require(poolType > 0 && poolType <= 3, "type error");
        require(amount > 0, "amount error");
        address user = address(msg.sender);
        DAPP_DATA.settle(user, poolType);
        DAPP_DATA.getUserData(user);
        if (poolType == 1) {
            uint256 temp = amount.mul(3);
            LP_OLPC.transfer(user, temp);
            LP_GAF.transfer(user, amount);
        } else if (poolType == 2) {
            uint256 temp = amount.div(3);
            amount = temp.mul(3);
            LP_OLPC.transfer(user, amount);
        } else if (poolType == 3) {
            LP_GAF.transfer(user, amount);
        }
        DAPP_DATA.handleUserRelease(user, poolType, amount);
        return true;
    }

    //质押
    function pledge(uint8 poolType, uint256 amount) public payable needSignUp returns (bool){
        require(poolType > 0 && poolType <= 3, "type error");
        require(amount > 0, "amount error");
        require(now > START_TIME && now < GET_COIN_TIME, "not open or end");
        address user = address(msg.sender);
        DAPP_DATA.settle(user, poolType);
        address c = address(this);
        if (poolType == 1) {
            uint256 temp = amount.mul(3);
            LP_OLPC.transferFrom(user, c, temp);
            LP_GAF.transferFrom(user, c, amount);
            DAPP_DATA.handleUserPledge(user, poolType, amount);
        } else if (poolType == 2) {
            uint256 temp = amount.div(3);
            amount = temp.mul(3);
            LP_OLPC.transferFrom(user, c, amount);
            DAPP_DATA.handleUserPledge(user, poolType, amount);
        } else if (poolType == 3) {
            LP_GAF.transferFrom(user, c, amount);
            DAPP_DATA.handleUserPledge(user, poolType, amount);
        }
        return true;
    }

    //增加会议token
    function addTencentGain(address user, uint256 amount) public returns (bool){
        require(address(msg.sender) == TENCENT_ADDRESS, "RUN ERROR");
        uint256 a = DAPP_DATA.getTencentToken(user);
        a = a.add(amount);
        DAPP_DATA.updateUserTencentToken(user, a);
        return true;
    }

    function updateTencAddress(address addr) public onlyOwner returns (bool){
        TENCENT_ADDRESS = addr;
        return true;
    }
    //获取用户可以领取的数量
    function getUserToken(address user) public view returns (uint256 team, uint256 two, uint256 olpc, uint256 gaf, uint256 tenc){
        (team, two, olpc, gaf, tenc) = DAPP_DATA.getCurrentToken(user);
    }

    //项目方提取手续费
    function teamAddressWithdrawFee(address payable teamAddress, uint256 amount) public onlyOwner returns (bool){
        teamAddress.transfer(amount);
        return true;
    }

    //领取token
    function gainToken() public payable needSignUp returns (bool){
        uint256 t;
        uint256 o;
        uint256 g;
        uint256 meeting;
        address user = address(msg.sender);
        DAPP_DATA.settle(user, uint8(0));
        DAPP_DATA.settle(user, uint8(1));
        DAPP_DATA.settle(user, uint8(2));
        DAPP_DATA.settle(user, uint8(3));
        (t, o, g) = DAPP_DATA.getUserData(user);
        meeting = DAPP_DATA.getTencentToken(user);
        meeting = t.add(o).add(g).add(meeting);
        if (meeting > 0) {
            OLPC.transfer(user, meeting);
        }
        DAPP_DATA.handleGetCoin(user);
        return true;
    }


    function signUp(address inviter) public returns (bool){
        return DAPP_DATA.signUp(address(msg.sender), inviter);
    }
}


//SourceUnit: IDAppData.sol

pragma solidity 0.5.17;

interface IDAppData {
    //用户数据 池子1:双币质押 池子2:OLPC质押 池子3:GRF质押

    //获取用户数据
    function getUserData(address user) external view returns (uint256 pool1, uint256 pool2, uint256 pool3);

    function getCurrentToken(address user) external view returns(uint256 team,uint256 two,uint256 olpc,uint256 gaf,uint256 tenc);


    function getUserPledge(address user) external view returns (uint256 two, uint256 olpc, uint256 gaf);

    function getUserTeamToken(address user) external view returns (uint256);

    //获取用户的邀请人
    function getUserInviter(address user) external view returns (address);

    //获取注册时间
    function getUserSignUpTime(address user) external view returns (uint256);

    //获取团队的算力
    function getUserTeamPower(address user) external view returns (uint256);

    //获取团队成员
    function getUserTeamMembers(address user) external view returns (address[] memory);

    //获取全网池子数据
    function getNetPoolData() external view returns (uint256 pool1, uint256 pool2, uint256 pool3);

    //获取全网邀请算力
    function getNetTeamPower() external view returns (uint256);

    function getTencentToken(address user) external view returns (uint256);

    function handleGetCoin(address user) external returns (bool);

    function updateUserTencentToken(address user, uint256 amount) external returns (uint256);

    function settle(address user, uint8 poolType) external returns (bool);

    function handleUserPledge(address user, uint8 poolType, uint256 amount) external returns (bool);

    function handleUserRelease(address user, uint8 poolType, uint256 amount) external returns (bool);

    //增加用户团队算力
    function addUserTeamPower(address user, uint256 add) external returns (bool);

    //减少用户团队算力
    function subUserTeamPower(address user, uint256 sub) external returns (bool);

    //添加全网团队算力
    function addNetTeamPower(uint256 add) external returns (bool);

    //增加全网团队算力
    function subtractNetTeamPower(uint256 sub) external returns (bool);

    //修改池子数据
    function updateNetPoolData(uint8 poolType, uint256 amount) external returns (bool);

    //更新用户池子数据
    function updatePool(address user, uint8 poolType, uint256 amount) external returns (bool);

    //注册
    function signUp(address user, address inviter) external returns (bool);

}


//SourceUnit: IERC20.sol

pragma solidity 0.5.17;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: Ownable.sol

pragma solidity 0.5.17;

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


//SourceUnit: SafeMath.sol

pragma solidity 0.5.17;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}