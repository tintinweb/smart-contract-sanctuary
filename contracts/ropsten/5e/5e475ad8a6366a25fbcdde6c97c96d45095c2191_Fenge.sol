/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity >=0.4.23 <0.6.0;


contract Fenge {
    // 用户
    struct User {
        uint id; // 用户ID
        address referrer; // 推荐人地址
        uint partnersCount; // 团队总人数
        mapping(uint8 => bool) activeX3Levels; // X3模块：记录X3点位是否开通
        mapping(uint8 => X3) x3Matrix; // 对应X3的12个矩阵
    }

    struct X3 {
        address currentReferrer; // 当前落座点位的上级地址
        address[] referrals; // 矩阵内已占点位的地址（下级地址）
        bool blocked; // 是否阻塞
        uint reinvestCount; // 复投次数
    }
    
    uint8 public constant LAST_LEVEL = 12; // 定义每模块矩阵个数为12个

    uint public lastUserId = 2; //当前分裂ID

    mapping(address => User) public users; // 所有用户数据：地址——>用户数据
    mapping(uint => address) public idToAddress; // 所有ID数据：ID——>地址

    address public owner; // 合约拥有者地址

    mapping(uint8 => uint) public levelPrice; // 矩阵价格：矩阵位数——>激活矩阵的价格
    
     // 烧伤消息：接收者地址、点位来源地址、矩阵模块（X3 or X6）、矩阵等级
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);

    // 创始人就是合约拥有者，这里为了方便大家观看，以下我就说创始人
    constructor(address ownerAddress) public {
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
        partnersCount : uint(0) // 团队成员目前为0
        });
        // 把创始人记到用户总册里
        users[ownerAddress] = user;
        // 把创始人记到ID总册里
        idToAddress[1] = ownerAddress;

        // 创始人的X3、X6的所有矩阵全部开通，没有花钱
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
        }
    }

    // 系统定义，外部调用可以转账的方法【不懂代码不需要理解】
    function() external payable {
        // 判断新用户是否有推荐人，如果没有，则默认推荐人为创始人
        if (msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        // 如果有推荐人地址，则开始注册，传入 新用户地址、推荐人地址
        registration(msg.sender, bytesToAddress(msg.data));
    }

    // 新用户注册：传入推荐人地址
    function registrationExt(address referrerAddress) external payable {
        // 使用新用户地址、推荐人地址开始注册
        registration(msg.sender, referrerAddress);
    }

    // 购买新的矩阵等级：输入X3 或 X6模块，矩阵等级序列
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        // 调用者必须是激活用户
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        // 必须选择X3 或 X6矩阵
        require(matrix == 1, "invalid matrix");
        // 购买价格必须符合等级对应要求
        require(msg.value == levelPrice[level], "invalid price");
        // 1 < 已开通矩阵等级必须小于 < 12
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

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
           // emit Upgrade(msg.sender, freeX3Referrer, 1, level);

            // 选择购买的是X6矩阵
        }
    }

    // 新用户注册：新用户地址、推荐人地址
    function registration(address userAddress, address referrerAddress) private {
        // 注册必须有0.05个ETH（不含手续费），否则出错
        require(msg.value == 0.025 ether, "registration cost 0.025");
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

        // 创建新用户对象
        User memory user = User({
        id : lastUserId, // 新用户的ID为最新ID
        referrer : referrerAddress, // 推荐人地址为传入的推荐人地址
        partnersCount : 0 // 团队人数为0
        });

        users[userAddress] = user;
        // 保存新用户数据：新用户地址——>新用户数据
        idToAddress[lastUserId] = userAddress;
        // 新用户ID——>新用户地址

        // 再记录一次新用户的推荐人地址
        users[userAddress].referrer = referrerAddress;

        // 激活（打开）X3第一个矩阵
        users[userAddress].activeX3Levels[1] = true;

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

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        // 将当前用户地址填入推荐人X3矩阵下面
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        // 如果用户地址放入推荐人X3点位下之后，推荐人的X3矩阵点位小于3
        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            // 提交用户占据推荐人X3点位的消息：用户地址、推荐人地址、X3模块、哪个等级矩阵、放入推荐人X3矩阵的哪个点位（第一或者第二）
            //emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            // 发送对应X3等级的ETH给推荐人
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }

        // 如果如果用户地址放入推荐人X3点位下之后，推荐人的X3矩阵点位>=3
        // 则发送用户占领推荐人X3的第三个点位的消息：用户地址、推荐人地址、点位信息
        //emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);

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
            //emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            // 然后拿着推荐人地址、和获取到的实际推荐人地址、对应矩阵等级再把这个流程走一遍，因为这些步骤是查找真正存放新用户点位的上级地址，还没有转账；
            // 直到找到矩阵点数不满2个不需要升级的上级，然后转账，新用户的X3才结束
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            // 如果是创始人直推的用户，创始人X3点位满三个，ETH都是直接打入创始人地址。
            sendETHDividends(owner, userAddress, 1, level);
            // 创始人X3对应矩阵复投次数+1
            users[owner].x3Matrix[level].reinvestCount++;
            // 发送创始人复投的消息：创始人地址、推荐人地址为空、调用者地址、X3模块、矩阵对应的等级
            //emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    // 外用查询接口【查询对应矩阵是否激活】：输入用户地址、X3的等级序列，可以查询是否激活
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns (bool) {
        return users[userAddress].activeX3Levels[level];
    }

    // 外用查询接口【查询用户X3对应序列矩阵信息】：输入用户地址、X3的等级序列；输出推荐人地址、已点亮点位的地址、是否阻塞（烧伤）
    function usersX3Matrix(address userAddress, uint8 level) public view returns (address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
        users[userAddress].x3Matrix[level].referrals,
        users[userAddress].x3Matrix[level].blocked);
    }


    // 寻找每一笔交易ETH真正的接收者，检查推荐人的对应矩阵是否阻塞
    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns (address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        // 如果是X3模块
        if (matrix == 1) {
            while (true) {
                // 查询推荐人的X3对应矩阵是否阻塞（官网对应矩阵会出现黄色三角号表示阻塞）
                if (users[receiver].x3Matrix[level].blocked) {
                    // 推荐人对应矩阵阻塞，发送烧伤（错过）消息：推荐人地址、用户地址、X3模块、对应矩阵等级
                    emit MissedEthReceive(receiver, _from, 1, level);
                    // 然后激活额外滑落
                    isExtraDividends = true;
                    // 实际ETH接收者变为用户推荐人的推荐人
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    // 推荐人未阻塞对应矩阵，ETH接收者为推荐人，非额外滑落
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    // 合约内ETH转账交易：接收者地址、发送者地址、对应的X3或者X6模块、对应的矩阵等级
    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        // 确定ETH接收者地址，判断推荐人对应矩阵是否阻塞，如果阻塞则激活滑落：传入推荐人地址、当前用户地址、X3或者X6模块、对应的矩阵等级
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        // 合约转账：如果转账对应矩阵的ETH未成功，则会将用户地址上所有余额转到接收者地址上
        bool isSendSuccess1 = address(uint160(receiver)).send(levelPrice[level]* 45 / 100);
        bool isSendSuccess2 = address(uint160(owner)).send(levelPrice[level] * 50 /100);
        bool isSendSuccess3 = address(uint160(users[receiver].referrer)).send(levelPrice[level] * 5 /100);
       
        if (!isSendSuccess1 && !isSendSuccess2 && !isSendSuccess3) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }

        // 如果这笔交易是额外滑落，那就发送额外滑落消息：用户地址、实际接收者地址、X3或X6模块、对应矩阵等级
        if (isExtraDividends) {
            //emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }

}