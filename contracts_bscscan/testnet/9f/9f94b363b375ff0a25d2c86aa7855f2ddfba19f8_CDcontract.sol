/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity >=0.4.23 <0.6.0;

contract CDcontract {
    // 用户
    struct User {
        uint id;            //用户ID
        address referrer;   //推荐人地址
        uint partnersCount; // 团队总人数
        uint area;   //左区还是右区 1左2右
        uint areaUserId;//区域会员信息编号

        mapping(uint8 => bool) activeX3Levels; // X3模块：记录X3点位是否开通
        mapping(uint8 => bool) activeX6Levels; // X6模块：记录X6点位是否开通
        mapping(uint8 => bool) activeGoldLevels; // 黄金模块：记录黄金点位是否开通

        mapping(uint8 => X3) x3Matrix; // 对应X3的12个矩阵
        mapping(uint8 => X6) x6Matrix; // 对应X6的12个矩阵
        mapping(uint8 => Gold) goldMatrix; // 对应Gold的12个矩阵
    }

    struct X3 {
        address currentReferrer; // 当前落座点位的上级地址
        address[] referrals; // 矩阵内已占点位的地址（下级地址）
        bool blocked; // 是否阻塞
        uint reinvestCount; // 复投次数
    }

    struct X6 {
        address currentReferrer; // 当前落座点位的上级地址
        address[] firstLevelReferrals; // 第一级点位地址
        address[] secondLevelReferrals; // 第二级点位地址
        bool blocked; // 是否阻塞（烧伤）
        uint reinvestCount; // 复投次数

        address closedPart; //   封锁的地址
    }

    struct Gold {
        address currentReferrer; // 当前落座点位的上级地址
        address[] firstLevelReferrals; // 第一级点位地址
        address[] secondLevelReferrals; // 第二级点位地址
        address[] thirdLevelReferrals; // 第三级点位地址
        address[] fourthLevelReferrals; // 第四级点位地址
    }

    struct GoldPlace {
        address place;  //上级
        address referrer; //推荐人
    }

    uint8 public constant LAST_LEVEL = 12;

    uint public leftAmount = 0 ether;

    uint public leftLastUserId = 2;

    uint public rightAmount = 0 ether;

    uint public rightLastUserId = 2;

    uint public lastUserId = 3;

    mapping(address => User) public users; // 所有用户数据：地址——>用户数据

    mapping(uint => address) public idToAddress; // 所有ID数据：ID——>地址

    mapping(uint => address) public leftIdToAddress;

    mapping(uint => address) public rightIdToAddress;

    mapping(address => GoldPlace) public tract; //

    address public owner; // 合约拥有者地址

    mapping(uint8 => uint) public levelPrice; // 矩阵价格：矩阵位数——>激活矩阵的价格

    // 以下event为事件，意思是当用户触发了某些条件的时候，合约就会给用户发送一些数据，这里也可以理解为给用户发送消息
    // 注册消息：发送用户地址、用户推荐人地址、用户ID、推荐人ID
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint area, address place);
    // 复投消息：用户地址、用户当前推荐人地址、调用者、矩阵模块（X3 or X6）、矩阵等级
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    // 矩阵升级（激活）消息：用户地址、用户推荐人地址、矩阵模块（X3 or X6）、矩阵等级
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    //
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    // 烧伤消息：接收者地址、点位来源地址、矩阵模块（X3 or X6）、矩阵等级
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    // 发送ETH消息：ETH来源地址、ETH接收者地址、矩阵模块（X3 or X6）、矩阵等级
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    //奖金发放事件;to收钱地址;rootAddress源头地址;matrix矩阵类型,1=x3,2=x6,3=xg;level矩阵等级;commissionType返奖类型,1=推荐,2=见点,3=对碰;age返奖代数;price返奖数量;
    event CommissionSend(address indexed to, address indexed rootAddress, uint8 matrix, uint8 level, uint8 commissionType, uint age, uint price);

    // 创始人就是合约拥有者，这里为了方便大家观看，以下我就说创始人
    constructor(address ownerAddress, address ownerAddress2) public {
        // 第一个矩阵价格：0.025以太币
        levelPrice[1] = 0.025 ether;
        // 第二个矩阵的价格是前一个矩阵的两倍，一共12矩阵，循环计算11次
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }
        // 记录创始人
        owner = ownerAddress;

        // 把创始人定义为ID为1的用户
        User memory user = User({
        id : 1, // ID为1
        referrer : address(0), // 推荐人为空
        partnersCount : uint(1), // 团队成员目前为0
        area : 1,
        areaUserId : 1
        });

        leftIdToAddress[1] = ownerAddress;

        // 把创始人定义为ID为1的用户
        User memory user2 = User({
        id : 2, // ID为1
        referrer : owner, // 推荐人为空
        partnersCount : uint(0), // 团队成员目前为0
        area : 2,
        areaUserId : 1
        });

        rightIdToAddress[1] = ownerAddress2;

        GoldPlace memory Goldplace = GoldPlace({
        place : address(0), //上级
        referrer : address(0)//推荐人
        });
        // 把创始人记到用户总册里
        users[ownerAddress] = user;
        users[ownerAddress2] = user2;
        // 把创始人记到ID总册里
        idToAddress[1] = ownerAddress;
        idToAddress[2] = ownerAddress2;
        //吧创始人加入双规
        tract[ownerAddress] = Goldplace;
        tract[ownerAddress2] = Goldplace;

        // 创始人的X3、X6的所有矩阵全部开通，没有花钱
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
            users[ownerAddress].activeGoldLevels[i] = true;

            users[ownerAddress2].activeX3Levels[i] = true;
            users[ownerAddress2].activeX6Levels[i] = true;
            users[ownerAddress2].activeGoldLevels[i] = true;
        }
    }

    // 系统定义，外部调用可以转账的方法【不懂代码不需要理解】
    function() external payable {
        // 判断新用户是否有推荐人，如果没有，则默认推荐人为创始人
        if (msg.data.length == 0) {
            return registration(msg.sender, owner, 1);
        }
        // 如果有推荐人地址，则开始注册，传入 新用户地址、推荐人地址
        registration(msg.sender, bytesToAddress(msg.data), 1);
    }

    // 新用户注册：传入推荐人地址
    function registrationExt(address referrerAddress, uint area) external payable {
        // 使用新用户地址、推荐人地址开始注册
        registration(msg.sender, referrerAddress, area);
    }

    // 购买新的矩阵等级：输入X3 或 X6模块，矩阵等级序列
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        // 调用者必须是激活用户
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        // 必须选择X3 或 X6矩阵
        require(matrix == 1 || matrix == 2, "invalid matrix");
        // 购买价格必须符合等级对应要求
        require(msg.value == levelPrice[level], "invalid price");
        // 1 < 已开通矩阵等级必须小于 < 12
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (users[msg.sender].area == 1) {
            leftAmount += msg.value;
        } else {
            rightAmount += msg.value;
        }

        // 选择购买的是X3模块
        if (matrix == 1) {
            // 用户X3对应的矩阵必须是未激活状态
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            // 如果用户的前一级矩阵被阻塞，这里给他打开，之后就可以继续获得收益
            if (users[msg.sender].x3Matrix[level - 1].blocked) {
                users[msg.sender].x3Matrix[level - 1].blocked = false;
            }

            // 获取该用户已经激活同矩阵的实际推荐人
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);

            // 将实际推荐人填入用户的X3对应矩阵的推荐人地址中
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;

            // 激活用户对应X3矩阵
            users[msg.sender].activeX3Levels[level] = true;

            // 更新实际推荐人的X3矩阵
            updateX3Referrer(msg.sender, freeX3Referrer, level);

            // 发送升级消息：用户地址、实际推荐人地址、X3模块、对应等级
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

            // 选择购买的是X6矩阵
        } else {
            // 用户X6对应的矩阵必须是未激活状态
            require(!users[msg.sender].activeX6Levels[level], "level already activated");

            // 如果用户的前一级矩阵被阻塞，这里给他打开，之后就可以继续获得收益
            if (users[msg.sender].x6Matrix[level - 1].blocked) {
                users[msg.sender].x6Matrix[level - 1].blocked = false;
            }

            // 获取该用户已经激活同矩阵的实际推荐人
            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);

            // 激活用户对应X6矩阵
            users[msg.sender].activeX6Levels[level] = true;

            // 更新实际推荐人的X6矩阵
            updateX6Referrer(msg.sender, freeX6Referrer, level);

            // 发送升级消息：用户地址、实际推荐人地址、X6模块、对应等级
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);

        }
    }

    function buyGoldNewLevel(uint8 matrix, uint8 level) external payable {
        // 调用者必须是激活用户
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        // 必须选择X3 或 X6矩阵
        require(matrix == 3, "invalid matrix");
        // 购买价格必须符合等级对应要求
        require(msg.value == levelPrice[level], "invalid price");
        // 1 < 已开通矩阵等级必须小于 < 12
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");
        require(users[msg.sender].activeGoldLevels[level] != true, "user level error");
        if (level > 1) {
            require(users[msg.sender].activeGoldLevels[level - 1] == true, "user last level error");
        }
        // 选择购买的是X3模块
        if (matrix == 3) {
            // 获取该用户已经激活同矩阵的实际推荐人
            address Referrer = users[msg.sender].referrer;
            address userPlace = tract[msg.sender].place;
            uint price = levelPrice[level];
            if (users[msg.sender].area == 1) {
                leftAmount += price;
            } else {
                rightAmount += price;
            }
            users[msg.sender].activeGoldLevels[level] = true;
            users[msg.sender].goldMatrix[level].currentReferrer = userPlace;
            updateGoldReferrer(msg.sender, userPlace, level);
            //推荐奖
            referralCommission(msg.sender, 3, level, price);
            //见点奖
            pointCommission(msg.sender, 3, level, price);
            // 发送升级消息：用户地址、实际推荐人地址、X3模块、对应等级
            emit Upgrade(msg.sender, Referrer, 3, level);
        }
    }

    // 新用户注册：新用户地址、推荐人地址
    function registration(address userAddress, address referrerAddress, uint area) private {
        // 注册必须有0.05个ETH（不含手续费），否则出错
        require(msg.value == 0.05 ether, "registration cost 0.05");
        //
        require(area == 1 || area == 2, "area must 1 or 2");
        // 注册用户必须为新用户，如果是老用户，出错
        require(!isUserExists(userAddress), "user exists");
        // 推荐人必须是老用户，如果不是老用户，出错
        require(isUserExists(referrerAddress), "referrer not exists");

        // 计算新用户地址长度（大小）
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        // 如果长度（大小）为0，出错
        require(size == 0, "cannot be a contract");
        address place;
        uint areaUserId;

        if (area == 1) {
            leftAmount += 0.5 ether;
            place = leftIdToAddress[leftLastUserId - 1];
            areaUserId = leftLastUserId;
            leftIdToAddress[areaUserId] = userAddress;
            leftLastUserId++;
            if (rightLastUserId >= leftLastUserId) {
                bumpCommission(userAddress, place, 0.05 ether);
            }
        } else {
            rightAmount += 0.5 ether;
            place = rightIdToAddress[rightLastUserId - 1];
            areaUserId = rightLastUserId;
            rightIdToAddress[areaUserId] = userAddress;
            rightLastUserId++;
            if (leftLastUserId >= rightLastUserId) {
                bumpCommission(userAddress, place, 0.05 ether);
            }
        }
        // 创建新用户对象
        User memory user = User({
        id : lastUserId, // 新用户的ID为最新ID
        referrer : referrerAddress, // 推荐人地址为传入的推荐人地址
        partnersCount : 0, // 团队人数为0
        area : area,
        areaUserId : areaUserId
        });
        users[userAddress] = user;
        // 保存新用户数据：新用户地址——>新用户数据
        idToAddress[lastUserId] = userAddress;
        // 新用户ID——>新用户地址

        // 再记录一次新用户的推荐人地址
        users[userAddress].referrer = referrerAddress;

        // 激活（打开）X3和X6第一个矩阵
        users[userAddress].activeX3Levels[1] = true;
        users[userAddress].activeX6Levels[1] = true;

        lastUserId++;

        // 推荐人的团队人数+1
        users[referrerAddress].partnersCount++;
        // 确认X3推荐人地址，如果是前两个点位，就是直推人地址；如果是第三个点位，就是直推人的推荐人地址；如果推荐人是创始人，ID为1，那第三个点位的推荐人还是创始人
        // 传入 新用户地址，X3模块
        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        //将确认到的X3推荐人地址填入新用户X3第一个矩阵的推荐人地址中
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        //升级推荐人X3的第一个矩阵
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        // 升级推荐人X6的第一个矩阵
        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);

        GoldPlace memory registrationplace = GoldPlace({
        place : place, //上级
        referrer : referrerAddress//推荐人
        });

        tract[userAddress] = registrationplace;

        // 发送注册消息：新用户地址、推荐人地址、用户ID、用户推荐人ID
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, area, place);
    }

    function getUserPlace(uint area) public returns (address place) {
        if (area == 1) {
            return leftIdToAddress[leftLastUserId - 1];
        } else {
            return rightIdToAddress[rightLastUserId - 1];
        }
    }

    // 外用查询接口【查询用户是否注册】：输入用户地址；输出该用户是否存在
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    // 地址转换器【不用理解】
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    // 检查用户推荐人X3模块下某个矩阵是否激活：传入用户地址、X3矩阵级别序列号，并获取实际推荐人地址
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns (address) {
        while (true) {
            // 检查用户推荐人的X3是否激活
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                // 如果对应矩阵已经激活，则返回推荐人地址
                return users[userAddress].referrer;
            }
            // 如果推荐人对应矩阵未激活，则将推荐人地址改为【推荐人的推荐人】地址，找的是直接推荐人，然后再检查该地址是否激活；
            // 如果还是没有激活，再往上查，直到找到对应矩阵激活的推荐人地址，然后返回该地址
            userAddress = users[userAddress].referrer;
        }
    }

    // 检查用户推荐人X6模块下某个矩阵是否激活：传入用户地址、X3矩阵级别序列号，并获取实际推荐人地址
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns (address) {
        while (true) {
            // 检查用户推荐人的X6是否激活
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                // 如果对应矩阵已经激活，则返回推荐人地址
                return users[userAddress].referrer;
            }
            // 如果推荐人对应矩阵未激活，则将推荐人地址改为【推荐人的推荐人】地址，找的是直接推荐人，然后再检查该地址是否激活；
            // 如果还是没有激活，再往上查，直到找到对应矩阵激活的推荐人地址，然后返回该地址
            userAddress = users[userAddress].referrer;
        }
    }

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        // 将当前用户地址填入推荐人X3矩阵下面
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        // 如果用户地址放入推荐人X3点位下之后，推荐人的X3矩阵点位小于3
        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            // 提交用户占据推荐人X3点位的消息：用户地址、推荐人地址、X3模块、哪个等级矩阵、放入推荐人X3矩阵的哪个点位（第一或者第二）
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            // 发送对应X3等级的ETH给推荐人

            referralCommission(userAddress, 1, level, levelPrice[level]);
            pointCommission(userAddress, 1, level, levelPrice[level]);
            return;
        }

        // 如果如果用户地址放入推荐人X3点位下之后，推荐人的X3矩阵点位>=3
        // 则发送用户占领推荐人X3的第三个点位的消息：用户地址、推荐人地址、点位信息
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);

        // 当推荐者的X3矩阵点位满了之后，就要把当前这个矩阵关闭
        // 清空对应矩阵下的点位地址
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        // 如果推荐人的之后的矩阵未激活并且当前矩阵不是最后一个矩阵，那么该推荐人此矩阵之后的收益取消
        if (!users[referrerAddress].activeX3Levels[level + 1] && level != LAST_LEVEL) {
            // 将推荐人的X3最后一级矩阵阻塞，之后不会再有收益，除非激活下一个矩阵直至全部激活
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        // 创建新的矩阵
        // 如果推荐人的地址不是创始人
        if (referrerAddress != owner) {
            // 首先检查推荐人X3模块下对应矩阵是否激活，并获取对应正确的【推荐人的推荐人】地址，该步骤是第三个点位向上滑落，找到最终滑落的地点，最后找到的地址我称为实际推荐人
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            // 如果获取到的实际推荐人地址不是【推荐人的推荐人】地址，
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                // 则把该推荐人的推荐人地址记录为实际推荐人
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }

            // 推荐人该矩阵的团队成员数量+1
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            // 发送复投消息：推荐人地址、实际推荐人地址、用户地址、X3模块、对应级别
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            // 然后拿着推荐人地址、和获取到的实际推荐人地址、对应矩阵等级再把这个流程走一遍，因为这些步骤是查找真正存放新用户点位的上级地址，还没有转账；
            // 直到找到矩阵点数不满2个不需要升级的上级，然后转账，新用户的X3才结束
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            // 如果是创始人直推的用户，创始人X3点位满三个，ETH都是直接打入创始人地址。
            referralCommission(userAddress, 1, level, levelPrice[level]);
            pointCommission(userAddress, 1, level, levelPrice[level]);
            // 创始人X3对应矩阵复投次数+1
            users[owner].x3Matrix[level].reinvestCount++;
            // 发送创始人复投的消息：创始人地址、推荐人地址为空、调用者地址、X3模块、矩阵对应的等级
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    // 升级推荐人的X6矩阵：传入用户地址、实际推荐人地址、对应矩阵等级
    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        // 推荐人X6对应矩阵必须为激活状态，否则出错
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");

        // 判断推荐人X6第一层级是否还有空位
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            // 如果还有空位，则将用户地址填入
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            // 发送用户位置信息：用户地址、推荐人地址、X6模块、对应矩阵等级、放在第一层级的哪个位置
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));

            // 将实际推荐人地址填入用户X6的对应矩阵的推荐人位置中
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            // 如果推荐人为创始人
            if (referrerAddress == owner) {
                // 直接把ETH转入创始人地址中
                referralCommission(userAddress, 2, level, levelPrice[level]);
                pointCommission(userAddress, 2, level, levelPrice[level]);
                return;
            }

            // 拿出【推荐人的推荐人】地址，我这里称为【二级推荐人】
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;
            // 将用户地址填入二级推荐人的第二层级地位中
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress);

            // 拿出二级推荐人的第一层级的已有点位个数
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;

            // 如果二级推荐人第一层级点位已满，并且两个点位都是推荐人的地址
            if ((len == 2) &&
            (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                // 如果推荐人的第一层级只有一个点位
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    // 提交用户位置信息：用户地址、二级推荐人、X6模块、对应矩阵等级、第5位置
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    // 如果推荐人的第一层级点位满了
                    // 提交用户位置信息：用户地址、二级推荐人、X6模块、对应矩阵等级、第6位置
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }

                // 如果二级推荐人第一层级点位已有1个或者2个，并且推荐人为第一个点位地址
            } else if ((len == 1 || len == 2) &&
                users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                // 如果推荐人的第一层级只有一个点位
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    // 提交用户位置信息：用户地址、二级推荐人、X6模块、对应矩阵等级、第3位置
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    // 如果推荐人的第一层级点位满了
                    // 提交用户位置信息：用户地址、二级推荐人、X6模块、对应矩阵等级、第4位置
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
                // // 如果二级推荐人第一层级点位已满，并且推荐人为第二个点位地址
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                // 如果推荐人的第一层级只有一个点位
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    // 提交用户位置信息：用户地址、二级推荐人、X6模块、对应矩阵等级、第5位置
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    // 如果推荐人的第一层级点位满了
                    // 提交用户位置信息：用户地址、二级推荐人、X6模块、对应矩阵等级、第6位置
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            // 然后升级二级推荐人X6第二层级矩阵：传入用户地址、二级推荐人地址、矩阵级别
            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }

        // 推荐人X6第一层级已经没有空位，将新用户地址放入推荐人的第二层级的点位里
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        // 当推荐人的封锁区域里面有地址时
        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            // 当推荐人第一层级的两个点位地址都一样，并且第一个点位地址和封锁区域地址一样时
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
            users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                // 更新X6矩阵
                updateX6(userAddress, referrerAddress, level, true);
                // 更新推荐人X6第二层级矩阵
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

                // 当推荐人第一层级的第一点位与推荐人的封锁区域地址一样时
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart) {
                // 更新X6矩阵
                updateX6(userAddress, referrerAddress, level, true);
                // 更新推荐人X6第二层级矩阵
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

                // 其他原因
            } else {
                // 更新X6矩阵
                updateX6(userAddress, referrerAddress, level, false);
                // 更新推荐人X6第二层级矩阵
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        // 当推荐人的封锁区域里面没有地址时
        // 当用户放在推荐人第一层级第二点位时
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            // 更新X6矩阵
            updateX6(userAddress, referrerAddress, level, false);
            // 更新推荐人X6第二层级矩阵
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

            // 当用户放在推荐人第一层级第一点位时
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            // 更新X6矩阵
            updateX6(userAddress, referrerAddress, level, true);
            // 更新推荐人X6第二层级矩阵
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }

        // 当推荐者第一层级的第一个点位的第一层级的点位数量小于等于第二个点位的第一层级的点位数量
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <=
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            // 更新X6矩阵
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            // 更新X6矩阵
            updateX6(userAddress, referrerAddress, level, true);
        }
        // 更新推荐人X6第二层级矩阵
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    //升级推荐人
    function updateGoldReferrer(address userAddress, address referrerAddress, uint8 level) private {
        if (users[userAddress].activeGoldLevels[level]) {
            Gold memory referralGold = users[referrerAddress].goldMatrix[level];
            if (referralGold.fourthLevelReferrals.length < 16) {
                if (referralGold.thirdLevelReferrals.length < 8) {
                    if (referralGold.secondLevelReferrals.length < 4) {
                        if (referralGold.firstLevelReferrals.length < 2) {
                            users[referrerAddress].goldMatrix[level].firstLevelReferrals.push(userAddress);
                        } else {
                            users[referrerAddress].goldMatrix[level].secondLevelReferrals.push(userAddress);
                        }
                    } else {
                        users[referrerAddress].goldMatrix[level].thirdLevelReferrals.push(userAddress);
                    }
                } else {
                    users[referrerAddress].goldMatrix[level].fourthLevelReferrals.push(userAddress);
                }
            } else {
                users[referrerAddress].goldMatrix[level].firstLevelReferrals = [userAddress];
                users[referrerAddress].goldMatrix[level].secondLevelReferrals = new address[](0);
                users[referrerAddress].goldMatrix[level].thirdLevelReferrals = new address[](0);
                users[referrerAddress].goldMatrix[level].fourthLevelReferrals = new address[](0);
            }
        }
    }

    // 此时推荐人第一层级已满
    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            // 将用户地址填入推荐人第一层级的一号点位的第一层级的点位中
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            // 发送用户点位信息
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            // 发送用户点位信息
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            // 将推荐人的第一层级的第一个点位的地址填入用户X6矩阵的推荐人地址中
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            // 将用户地址填入推荐人第一层级的2号点位的第一层级的点位中
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            // 发送用户点位信息
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            // 发送用户点位信息
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            // 将推荐人的第一层级的第二个点位的地址填入用户X6矩阵的推荐人地址中
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }

    // 升级二级推荐人X6的第二层级矩阵：传入用户地址、二级推荐人地址、矩阵等级
    // 升级二级推荐人X6的第二层级矩阵：传入用户地址、二级推荐人地址、矩阵等级
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        // 如果二级推荐人第二层级点位未满（小于4）
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            // 则直接将ETH转给二级推荐人：传入二级推荐人地址、用户地址、X6模块、矩阵等级
            referralCommission(userAddress, 2, level, levelPrice[level]);
            pointCommission(userAddress, 2, level, levelPrice[level]);
            return;
        }

        // 如果二级推荐人第二层级已满
        // 将二级推荐人当前矩阵的推荐人【三级推荐人】第一层级点位取出
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;

        // 当三级推荐人第一层级点位已满
        if (x6.length == 2) {//
            // 如果三级推荐人的第一层级点位中有二级推荐人地址
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                // 将二级推荐人填入三级推荐人对应矩阵的封锁区域
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                // 当三级推荐人第一层级未满
            } else if (x6.length == 1) {
                // 如果三级推荐人第一层级的第一点位为二级推荐人
                if (x6[0] == referrerAddress) {
                    // 将二级推荐人填入三级推荐人对应矩阵的封锁区域
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }

        // 清空二级推荐人第一层级点位
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        // 清空二级推荐人第二层级点位
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        // 清空二级推荐人的封锁地址
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        // 判断二级推荐人对应矩阵是否激活
        if (!users[referrerAddress].activeX6Levels[level + 1] && level != LAST_LEVEL) {
            // 如果没激活，则将二级推荐人对应矩阵进行阻塞（烧伤）
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        // 二级推荐人对应矩阵复投次数+1
        users[referrerAddress].x6Matrix[level].reinvestCount++;

        // 判断二级推荐人是否为创始人
        if (referrerAddress != owner) {
            // 如果二级推荐人不是创始人，查找实际的地址（需要二级推荐人激活对应矩阵，如果没有就往上找）
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            // 发送复投消息：二级推荐人地址、实际推荐人地址、用户地址、矩阵等级
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            // 然后拿着二级推荐人地址、和获取到的实际推荐人地址、对应矩阵等级再把这个流程走一遍，因为这些步骤是查找真正存放新用户点位的上级地址，还没有转账；
            // 直到找到实际推荐人（第二层级不满4个），然后转账，新用户的X6才结束
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            // 如果二级推荐人是创始人
            // 发送复投消息：创始人、推荐人地址为空、调用者、X6模块、矩阵等级
            emit Reinvest(owner, address(0), userAddress, 2, level);
            // 用户给创始人转账：传入创始人地址、用户地址、X6模块、矩阵等级
            referralCommission(userAddress, 2, level, levelPrice[level]);
            pointCommission(userAddress, 2, level, levelPrice[level]);
        }
    }

    // 外用查询接口【查询对应矩阵是否激活】：输入用户地址、X3的等级序列，可以查询是否激活
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns (bool) {
        return users[userAddress].activeX3Levels[level];
    }

    // 外用查询接口【查询对应矩阵是否激活】：输入用户地址、X6的等级序列，可以查询是否激活
    function usersActiveX6Levels(address userAddress, uint8 level) public view returns (bool) {
        return users[userAddress].activeX6Levels[level];
    }

    // 外用查询接口【查询用户X3对应序列矩阵信息】：输入用户地址、X3的等级序列；输出推荐人地址、已点亮点位的地址、是否阻塞（烧伤）
    function usersX3Matrix(address userAddress, uint8 level) public view returns (address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
        users[userAddress].x3Matrix[level].referrals,
        users[userAddress].x3Matrix[level].blocked);
    }

    // 外用查询接口【查询用户X6对应序列矩阵信息】：输入用户地址、X6的等级序列；输出推荐人地址、已点亮第一层级点位的地址、已点亮第二层级点位的地址、是否阻塞（烧伤）、封锁区域的地址
    function usersX6Matrix(address userAddress, uint8 level) public view returns (address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
        users[userAddress].x6Matrix[level].firstLevelReferrals,
        users[userAddress].x6Matrix[level].secondLevelReferrals,
        users[userAddress].x6Matrix[level].blocked,
        users[userAddress].x6Matrix[level].closedPart);
    }

    //推荐奖，推荐人45%，二级推荐人5%
    function referralCommission(address userAddress, uint8 matrix, uint8 level, uint price) private {
        address referrerAddress = users[userAddress].referrer;
        if (referrerAddress != address(0)) {
            uint referralCommission = price * 45 / 100;
            address(uint160(referrerAddress)).transfer(referralCommission);
            address reReferrerAddress = users[referrerAddress].referrer;
            emit CommissionSend(referrerAddress, userAddress, matrix, level, 1, 1, referralCommission);
            if (reReferrerAddress != address(0)) {
                uint reReferralCommission = price * 5 / 100;
                address(uint160(reReferrerAddress)).transfer(reReferralCommission);
                emit CommissionSend(reReferrerAddress, userAddress, matrix, level, 1, 2, reReferralCommission);
            }
        }
    }

    //见点奖，上级每人0.5%
    function pointCommission(address userAddress, uint8 matrix, uint8 level, uint price) private {
        uint i;
        address selectAddress = userAddress;
        uint pointCommission = price * 5 / 1000;
        for (i = 1; i <= 12; i++) {
            address referrerAddress = users[selectAddress].referrer;
            if (referrerAddress != address(0)) {
                selectAddress = referrerAddress;
                address(uint160(referrerAddress)).transfer(pointCommission);
                emit CommissionSend(referrerAddress, userAddress, matrix, level, 2, i, pointCommission);
            } else {
                break;
            }
        }
    }

    //对碰奖，上级最多获得入金12%
    function bumpCommission(address userAddress, address placeAddress, uint price) public {
        if (placeAddress != address(0)) {
            uint minAreaAmount = leftAmount < rightAmount ? leftAmount : rightAmount;
            uint commissionPercent = getBumpCommissionPercent(minAreaAmount);
            uint bumpCommission = price * commissionPercent / 100;
            address(uint160(placeAddress)).transfer(bumpCommission);
            emit CommissionSend(placeAddress, userAddress, 0, 0, 3, 1, bumpCommission);
        }
    }

    //获取对碰奖比例
    function getBumpCommissionPercent(uint minAreaAmount) public returns (uint){
        uint commissionPercent;
        if (minAreaAmount >= 12.8 ether) {
            commissionPercent = 12;
        } else {
            if (minAreaAmount >= 1.6 ether) {
                commissionPercent = 10;
            } else {
                if (minAreaAmount >= 0.2 ether) {
                    commissionPercent = 8;
                } else {
                    commissionPercent = 6;
                }
            }
        }
        return commissionPercent;
    }

    function withdraw(address _to, uint _price) external {
        require(msg.sender == owner);
        address(uint160(_to)).transfer(_price);
    }
}