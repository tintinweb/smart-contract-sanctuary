//SourceUnit: DAppData.sol

pragma solidity 0.5.17;

import "./IDAppData.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract DAppData is Ownable, IDAppData {
    using SafeMath for uint256;
    mapping(address => bool) private executors;
    address private SUPER_ADDRESS;
    uint256 private TWO_COIN_POOL;
    uint256 private GAF_POOL;
    uint256 private OLPC_POOL;
    uint256 private NET_POWER;
    mapping(address => UserData) userDataMap;
    NetData[] private TEAM_RECORD;
    NetData[] private TWO_RECORD;
    NetData[] private OLPC_RECORD;
    NetData[] private GAF_RECORD;

    uint256 private HOUR_COIN_TEAM = 988113830;
    uint256 private HOUR_COIN_TWO = 6422739900;
    uint256 private HOUR_COIN_OLPC = 988113830;
    uint256 private HOUR_COIN_GAF = 988113830;

    uint256 private END_TIME = 1637931120;

    uint256 private PRODUCT_TIME = 3600;


    struct NetData {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
    }

    struct UserData {
        address user;
        address inviter;
        uint256 signUpTime;
        uint256 tencentToken;
        address[] members;

        //已产数量
        uint256 teamToken;
        uint256 twoToken;
        uint256 gafToken;
        uint256 olpcToken;

        //当前质押量
        uint256 team;
        uint256 two;
        uint256 gaf;
        uint256 olpc;

        uint256 teamIndex;
        uint256 twoIndex;
        uint256 gafIndex;
        uint256 olpcIndex;
    }

    constructor() public {
        SUPER_ADDRESS = address(msg.sender);
        UserData storage dt = userDataMap[SUPER_ADDRESS];
        dt.inviter = address(0x0);
        dt.signUpTime = now;

        NetData memory teamData;
        teamData.startTime = now;
        teamData.endTime = now + PRODUCT_TIME;
        TEAM_RECORD.push(teamData);

        NetData memory twoData;
        twoData.startTime = now;
        twoData.endTime = now + PRODUCT_TIME;
        TWO_RECORD.push(twoData);

        NetData memory olpcData;
        olpcData.startTime = now;
        olpcData.endTime = now + PRODUCT_TIME;
        OLPC_RECORD.push(olpcData);

        NetData memory gafData;
        gafData.startTime = now;
        gafData.endTime = now + PRODUCT_TIME;
        GAF_RECORD.push(gafData);
    }

    function updateEndTime(uint256 time) public onlyOwner returns (bool){
        if (time > 0) {
            END_TIME = time;
        } else {
            END_TIME = now;
        }
        return true;
    }

    function updateExecutor(address _executor) public onlyOwner returns (bool){
        executors[_executor] = true;
        return true;
    }

    function removeExecutor(address _executor) public onlyOwner returns (bool){
        executors[_executor] = false;
        return true;
    }

    modifier onlyExecutor() {
        require(executors[msg.sender], "net data only executor error");
        _;
    }

    //获取用户数据
    function getUserData(address user) public view returns (uint256 twoCoin, uint256 olpc, uint256 gaf){
        UserData memory data = userDataMap[user];
        twoCoin = data.two;
        olpc = data.olpc;
        gaf = data.gaf;
    }

    function getCurrentToken(address user) public view returns (uint256 team, uint256 two, uint256 olpc, uint256 gaf, uint256 tenc){
        UserData memory data = userDataMap[user];
        tenc = data.tencentToken;
        team = _getTeamToken(data);
        two = _getTwoToken(data);
        olpc = _getOlpcToken(data);
        gaf = _getGafToken(data);

    }

    function _getTeamToken(UserData memory user) internal view returns (uint256){
        if (user.team <= 0) {
            return user.teamToken;
        }
        uint256 gain = user.teamToken;
        uint256 minPro = HOUR_COIN_TEAM.div(60);
        uint256 t = now;
        if (t >= END_TIME) {
            t = END_TIME;
        }
        uint256 temp;
        uint256 size = TEAM_RECORD.length - 1;
        for (uint256 i = user.teamIndex; i < size; i++) {
            NetData memory netData = TEAM_RECORD[i];
            if (netData.endTime > t) {
                break;
            }
            if (netData.amount <= 0) {
                continue;
            }
            temp = netData.endTime - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = user.team.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        NetData memory netData = TEAM_RECORD[size];
        if (netData.endTime < t) {
            temp = t - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = user.team.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        return gain;
    }

    function _getTwoToken(UserData memory user) internal view returns (uint256){
        if (user.two <= 0) {
            return user.twoToken;
        }
        uint256 gain = user.twoToken;
        uint256 minPro = HOUR_COIN_TWO.div(60);
        uint256 t = now;
        if (t >= END_TIME) {
            t = END_TIME;
        }
        uint256 temp;
        uint256 size = TWO_RECORD.length - 1;
        for (uint256 i = user.twoIndex; i < size; i++) {
            NetData memory netData = TWO_RECORD[i];
            if (netData.endTime > t) {
                break;
            }
            if (netData.amount <= 0) {
                continue;
            }
            temp = netData.endTime - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = user.two.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        NetData memory netData = TWO_RECORD[size];
        if (netData.endTime < t) {
            temp = t - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = user.two.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        return gain;
    }

    function _getOlpcToken(UserData memory user) internal view returns (uint256){
        if (user.olpc <= 0) {
            return user.olpcToken;
        }
        uint256 gain = user.olpcToken;
        uint256 minPro = HOUR_COIN_OLPC.div(60);
        uint256 t = now;
        if (t >= END_TIME) {
            t = END_TIME;
        }
        uint256 temp;
        uint256 size = OLPC_RECORD.length - 1;
        for (uint256 i = user.olpcIndex; i < size; i++) {
            NetData memory netData = OLPC_RECORD[i];
            if (netData.endTime > t) {
                break;
            }
            if (netData.amount <= 0) {
                continue;
            }
            temp = netData.endTime - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = user.olpc.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        NetData memory netData = OLPC_RECORD[size];
        if (netData.endTime < t) {
            temp = t - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = user.olpc.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        return gain;
    }

    function _getGafToken(UserData memory user) internal view returns (uint256){
        if (user.gaf <= 0) {
            return user.gafToken;
        }
        uint256 gain = user.gafToken;
        uint256 minPro = HOUR_COIN_GAF.div(60);
        uint256 t = now;
        if (t >= END_TIME) {
            t = END_TIME;
        }
        uint256 temp;
        uint256 size = GAF_RECORD.length - 1;
        for (uint256 i = user.gafIndex; i < size; i++) {
            NetData memory netData = GAF_RECORD[i];
            if (netData.endTime > t) {
                break;
            }
            if (netData.amount <= 0) {
                continue;
            }
            temp = netData.endTime - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = user.gaf.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        NetData memory netData = GAF_RECORD[size];
        if (netData.endTime < t) {
            temp = t - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = user.gaf.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        return gain;
    }

    function getUserPledge(address user) public view returns (uint256 two, uint256 olpc, uint256 gaf){
        UserData memory data = userDataMap[user];
        two = data.two;
        olpc = data.olpc;
        gaf = data.gaf;
    }

    function getUserTeamToken(address user) public view returns (uint256){
        UserData memory data = userDataMap[user];
        return data.teamToken;
    }

    //获取用户的邀请人
    function getUserInviter(address user) public view returns (address){
        UserData memory data = userDataMap[user];
        return data.inviter;
    }

    //获取注册时间
    function getUserSignUpTime(address user) public view returns (uint256){
        UserData memory data = userDataMap[user];
        return data.signUpTime;
    }

    //获取团队的算力
    function getUserTeamPower(address user) public view returns (uint256){
        UserData memory data = userDataMap[user];
        return data.team;
    }


    //获取团队成员
    function getUserTeamMembers(address user) public view returns (address[] memory){
        UserData memory data = userDataMap[user];
        return data.members;
    }

    //获取全网池子数据
    function getNetPoolData() public view returns (uint256 twoCoin, uint256 olpc, uint256 gaf){
        twoCoin = TWO_COIN_POOL;
        olpc = OLPC_POOL;
        gaf = GAF_POOL;
    }

    //获取全网邀请算力
    function getNetTeamPower() public view returns (uint256){
        return NET_POWER;
    }

    function getTencentToken(address user) public view returns (uint256){
        UserData memory dt = userDataMap[user];
        return dt.tencentToken;
    }

    function handleGetCoin(address user) public onlyExecutor returns (bool){
        UserData storage dt = userDataMap[user];
        dt.tencentToken = 0;
        dt.teamToken = 0;
        dt.twoToken = 0;
        dt.olpcToken = 0;
        dt.gafToken = 0;
        return true;
    }

    function updateUserTencentToken(address user, uint256 amount) public onlyExecutor returns (uint256){
        UserData storage dt = userDataMap[user];
        dt.tencentToken = amount;
        return dt.tencentToken;
    }

    //增加用户团队算力
    function addUserTeamPower(address user, uint256 add) public onlyExecutor returns (bool){
        UserData storage dt = userDataMap[user];
        dt.team = dt.team.add(add);
        return true;
    }

    //减少用户团队算力
    function subUserTeamPower(address user, uint256 sub) public onlyExecutor returns (bool){
        UserData storage dt = userDataMap[user];
        if (dt.team >= sub) {
            dt.team = dt.team.sub(sub);
        } else {
            dt.team = 0;
        }
        return true;
    }

    //添加全网团队算力
    function addNetTeamPower(uint256 add) public onlyExecutor returns (bool){
        NET_POWER = NET_POWER.add(add);
        return true;
    }

    //增加全网团队算力
    function subtractNetTeamPower(uint256 sub) public onlyExecutor returns (bool){
        if (NET_POWER >= sub) {
            NET_POWER = NET_POWER.sub(sub);
        } else {
            NET_POWER = 0;
        }
        return true;
    }

    //修改池子数据
    function updateNetPoolData(uint8 poolType, uint256 amount) public onlyExecutor returns (bool){
        require(poolType > 0 && poolType <= 3, "POOL TYPE ERROR");
        if (poolType == 1) {
            TWO_COIN_POOL = amount;
        } else if (poolType == 2) {
            OLPC_POOL = amount;
        } else {
            GAF_POOL = amount;
        }
        return true;
    }

    //更新用户池子数据
    function updatePool(address user, uint8 poolType, uint256 amount) public onlyExecutor returns (bool){
        require(poolType >= 0 && poolType <= 3, "POOL TYPE ERROR");
        UserData storage data = userDataMap[user];
        if (poolType == 0) {
            data.team = amount;
        } else if (poolType == 1) {
            data.two = amount;
        } else if (poolType == 2) {
            data.olpc = amount;
        } else {
            data.gaf = amount;
        }
        return true;
    }


    //注册
    function signUp(address user, address inviter) public onlyExecutor returns (bool){
        UserData storage dt = userDataMap[user];
        if (dt.signUpTime > 0) {
            return true;
        }
        UserData storage inviterUser = userDataMap[inviter];
        if (inviterUser.signUpTime <= 0) {
            inviter = SUPER_ADDRESS;
        }
        dt.signUpTime = now;
        dt.inviter = inviter;

        dt.twoIndex = TWO_RECORD.length;
        dt.olpcIndex = OLPC_RECORD.length;
        dt.gafIndex = GAF_RECORD.length;
        dt.teamIndex = TEAM_RECORD.length;

        inviterUser.members.push(user);
        return true;
    }

    function settleTeam(address user) internal {
        UserData storage dt = userDataMap[user];
        if (dt.team <= 0) {
            dt.teamIndex = TEAM_RECORD.length;
            return;
        }
        uint256 t = now;
        if (t > END_TIME) {
            t = END_TIME;
        }
        uint256 gain = 0;
        uint256 temp;
        uint256 minPro = HOUR_COIN_TEAM.div(60);
        NetData storage ndt = TEAM_RECORD[TEAM_RECORD.length - 1];
        if (ndt.endTime < t) {
            ndt.endTime = t;
        }
        for (uint256 i = dt.teamIndex; i < TEAM_RECORD.length; i++) {
            NetData memory netData = TEAM_RECORD[i];
            if (netData.endTime > t) {
                break;
            }
            if (netData.amount <= 0) {
                continue;
            }
            temp = netData.endTime - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = dt.team.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        dt.teamIndex = TEAM_RECORD.length;
        dt.teamToken = dt.teamToken.add(gain);
    }

    function settleTWO(address user) internal {
        UserData storage dt = userDataMap[user];
        if (dt.two <= 0) {
            dt.twoIndex = TWO_RECORD.length;
            return;
        }
        uint256 t = now;
        if (t > END_TIME) {
            t = END_TIME;
        }
        uint256 gain = 0;
        uint256 temp;
        uint256 minPro = HOUR_COIN_TWO.div(60);
        NetData storage ndt = TWO_RECORD[TWO_RECORD.length - 1];
        if (ndt.endTime < t) {
            ndt.endTime = t;
        }
        for (uint256 i = dt.twoIndex; i < TWO_RECORD.length; i++) {
            NetData memory netData = TWO_RECORD[i];
            if (netData.endTime > t) {
                break;
            }
            if (netData.amount <= 0) {
                continue;
            }
            temp = netData.endTime - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = dt.two.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        dt.twoIndex = TWO_RECORD.length;
        dt.twoToken = dt.twoToken.add(gain);
    }

    function settleOLPC(address user) internal {
        UserData storage dt = userDataMap[user];
        if (dt.olpc <= 0) {
            dt.olpcIndex = OLPC_RECORD.length;
            return;
        }
        uint256 t = now;
        if (t > END_TIME) {
            t = END_TIME;
        }
        uint256 gain = 0;
        uint256 temp;
        uint256 minPro = HOUR_COIN_OLPC.div(60);
        NetData storage ndt = OLPC_RECORD[OLPC_RECORD.length - 1];
        if (ndt.endTime < t) {
            ndt.endTime = t;
        }
        for (uint256 i = dt.olpcIndex; i < OLPC_RECORD.length; i++) {
            NetData memory netData = OLPC_RECORD[i];
            if (netData.endTime > t) {
                break;
            }
            if (netData.amount <= 0) {
                continue;
            }
            temp = netData.endTime - netData.startTime;
            temp = temp.div(60);
            temp = temp.mul(minPro);
            temp = dt.olpc.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        dt.olpcIndex = OLPC_RECORD.length;
        dt.olpcToken = dt.olpcToken.add(gain);
    }

    function settleGAF(address user) internal {
        UserData storage dt = userDataMap[user];
        if (dt.gaf <= 0) {
            dt.gafIndex = GAF_RECORD.length;
            return;
        }
        uint256 t = now;
        if (t > END_TIME) {
            t = END_TIME;
        }
        uint256 gain = 0;
        uint256 temp;
        uint256 minPro = HOUR_COIN_GAF.div(60);
        NetData storage ndt = GAF_RECORD[GAF_RECORD.length - 1];
        if (ndt.endTime < now) {
            ndt.endTime = now;
        }

        for (uint256 i = dt.gafIndex; i < GAF_RECORD.length; i++) {
            NetData memory netData = GAF_RECORD[i];
            if (netData.endTime > t) {
                break;
            }
            if (netData.amount <= 0) {
                continue;
            }
            temp = netData.endTime - netData.startTime;
            temp = temp.div(60);
            if (temp <= 0) {
                continue;
            }
            temp = temp.mul(minPro);
            temp = dt.gaf.mul(temp).div(netData.amount);
            gain = gain.add(temp);
        }
        dt.gafIndex = GAF_RECORD.length;
        dt.gafToken = dt.gafToken.add(gain);
    }

    function settle(address user, uint8 poolType) public onlyExecutor returns (bool){
        if (poolType == 0) {
            settleTeam(user);
        } else if (poolType == 1) {
            settleTWO(user);
        } else if (poolType == 2) {
            settleOLPC(user);
        } else if (poolType == 3) {
            settleGAF(user);
        }
        return true;
    }

    function handleTeamPower(address user, uint256 power, bool isAdd) internal {
        UserData storage dt = userDataMap[user];
        NetData storage ndt = TEAM_RECORD[TEAM_RECORD.length - 1];
        if (isAdd) {
            NET_POWER = NET_POWER.add(power);
        } else {
            if (NET_POWER >= power) {
                NET_POWER = NET_POWER.sub(power);
            } else {
                NET_POWER = 0;
            }
        }
        if (ndt.endTime > now) {
            ndt.amount = NET_POWER;
        } else {
            ndt.endTime = now - 1;
            NetData memory newTP;
            newTP.amount = NET_POWER;
            newTP.startTime = now;
            newTP.endTime = now + PRODUCT_TIME;
            if (newTP.endTime > END_TIME) {
                newTP.endTime = END_TIME;
            }
            if (now < END_TIME) {
                TEAM_RECORD.push(newTP);
            }
        }
        if (dt.inviter == address(0x0) || dt.inviter == user) {
            return;
        }
        settleTeam(dt.inviter);
        UserData storage inviterData = userDataMap[dt.inviter];
        if (isAdd) {
            inviterData.team = inviterData.team.add(power);
        } else {
            if (inviterData.team >= power) {
                inviterData.team = inviterData.team.sub(power);
            } else {
                inviterData.team = 0;
            }
        }
    }


    //用户质押处理
    function handleUserPledge(address user, uint8 poolType, uint256 amount) public onlyExecutor returns (bool){
        //1、更新用户质押数据
        //2、更新全网质押数据
        //3、更新邀请人团队算力数据
        //4、更新全网邀请算力数据
        require(now < END_TIME, "run error");
        UserData storage userData = userDataMap[user];
        uint256 power = amount;
        if (poolType == 1) {
            power = amount.mul(2);
            userData.two = userData.two.add(amount);
            TWO_COIN_POOL = TWO_COIN_POOL.add(amount);
            NetData storage dt = TWO_RECORD[TWO_RECORD.length - 1];
            if (dt.endTime > now) {
                dt.amount = TWO_COIN_POOL;
            } else {
                dt.endTime = now - 1;
                NetData memory newDT;
                newDT.amount = TWO_COIN_POOL;
                newDT.startTime = now;
                newDT.endTime = now + PRODUCT_TIME;
                if (newDT.endTime > END_TIME) {
                    newDT.endTime = END_TIME;
                }
                TWO_RECORD.push(newDT);
            }
        } else if (poolType == 2) {
            userData.olpc = userData.olpc.add(amount);
            power = amount.div(3);
            OLPC_POOL = OLPC_POOL.add(amount);
            NetData storage dt = OLPC_RECORD[OLPC_RECORD.length - 1];
            if (dt.endTime > now) {
                dt.amount = OLPC_POOL;
            } else {
                dt.endTime = now - 1;
                NetData memory newDT;
                newDT.amount = OLPC_POOL;
                newDT.startTime = now;
                newDT.endTime = now + PRODUCT_TIME;
                if (newDT.endTime > END_TIME) {
                    newDT.endTime = END_TIME;
                }
                OLPC_RECORD.push(newDT);
            }

        } else if (poolType == 3) {
            userData.gaf = userData.gaf.add(amount);
            GAF_POOL = GAF_POOL.add(amount);
            NetData storage dt = GAF_RECORD[GAF_RECORD.length - 1];
            if (dt.endTime > now) {
                dt.amount = GAF_POOL;
            } else {
                dt.endTime = now - 1;
                NetData memory newDT;
                newDT.amount = GAF_POOL;
                newDT.startTime = now;
                newDT.endTime = now + PRODUCT_TIME;
                if (newDT.endTime > END_TIME) {
                    newDT.endTime = END_TIME;
                }
                GAF_RECORD.push(newDT);
            }
        }

        handleTeamPower(user, power, true);
        return true;
    }


    //用户赎回处理
    function handleUserRelease(address user, uint8 poolType, uint256 amount) public onlyExecutor returns (bool){
        //1、更新用户质押数据
        //2、更新全网质押数据
        //3、更新邀请人团队算力数据
        //4、更新全网邀请算力数据
        UserData storage userData = userDataMap[user];
        uint256 power = amount;
        if (poolType == 1) {
            userData.two = userData.two.sub(amount);
            TWO_COIN_POOL = TWO_COIN_POOL.sub(amount);
            NetData storage dt = TWO_RECORD[TWO_RECORD.length - 1];
            if (dt.endTime > now) {
                dt.amount = TWO_COIN_POOL;
            } else {
                dt.endTime = now - 1;
                NetData memory newDT;
                newDT.amount = TWO_COIN_POOL;
                newDT.startTime = now;
                newDT.endTime = now + PRODUCT_TIME;
                if (newDT.endTime > END_TIME) {
                    newDT.endTime = END_TIME;
                }
                if (now < END_TIME) {
                    TWO_RECORD.push(newDT);
                }
            }
        } else if (poolType == 2) {
            userData.olpc = userData.olpc.sub(amount);
            power = amount.div(3);
            OLPC_POOL = OLPC_POOL.sub(amount);
            NetData storage dt = OLPC_RECORD[OLPC_RECORD.length - 1];
            if (dt.endTime > now) {
                dt.amount = OLPC_POOL;
            } else {
                dt.endTime = now - 1;
                NetData memory newDT;
                newDT.amount = OLPC_POOL;
                newDT.startTime = now;
                newDT.endTime = now + PRODUCT_TIME;
                if (newDT.endTime > END_TIME) {
                    newDT.endTime = END_TIME;
                }
                if (now < END_TIME) {
                    OLPC_RECORD.push(newDT);
                }
            }
        } else if (poolType == 3) {
            userData.gaf = userData.gaf.sub(amount);
            GAF_POOL = GAF_POOL.sub(amount);
            NetData storage dt = GAF_RECORD[GAF_RECORD.length - 1];
            if (dt.endTime > now) {
                dt.amount = GAF_POOL;
            } else {
                dt.endTime = now - 1;
                NetData memory newDT;
                newDT.amount = GAF_POOL;
                newDT.startTime = now;
                newDT.endTime = now + PRODUCT_TIME;
                if (newDT.endTime > END_TIME) {
                    newDT.endTime = END_TIME;
                }
                if (now < END_TIME) {
                    GAF_RECORD.push(newDT);
                }
            }
        }
        handleTeamPower(user, power, false);
        return true;
    }

    function canGetToken() public view returns (uint8){
        if (END_TIME < now) {
            return 1;
        }
        return 0;
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