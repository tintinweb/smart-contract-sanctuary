//SourceUnit: SmartMatrixForsage.sol

pragma solidity >=0.4.23 <0.6.0;

contract SmartDapp {

    struct User {
        uint id;
        address referrer; // 推荐人地址
        uint mFeeTime; //月费时间
        uint8 level;
        address currentReferrer;
    }

    uint8 public constant LAST_LEVEL = 20;

    mapping(address => User) public users;
    mapping(address => address[2]) public childs;
    mapping(address => uint8) public partnersCount;
    mapping(address => uint8) public partnersCount10;
    mapping(address => uint8) public partnersCount20;
    mapping(address => uint) public income;
    mapping(address => uint) public burn;
    mapping(uint => address) public idToAddress;

    mapping(address => address[]) public tmplist;
    mapping(address => uint) public tmplen;

    uint public lastUserId = 2;
    address public owner;

    uint public reward = 0;

    address[10] public rank;

    uint public lotteryStart = now;
    uint public lotteryTime = 10 * 24 * 60 *60;
    uint public feeTime = 30 * 24 * 60 * 60;
    uint8[] award_list = [25,20,15,10,5,5,5,5,5,5];
 
    uint public limit1 = 20000 trx;
    uint public limit2 = 6000 trx;

    uint public levelPrice = 100 trx;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    // event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    // event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);

    constructor() public {
        owner = address(0x4151cfc0f99199bf97b26531f64efe1acfe1a0e9dd);
        User memory user = User({
            id: 1,
            referrer: address(0),
            mFeeTime: now + 864000000,
            level: 20,
            currentReferrer: address(0)
        });
        users[owner] = user;
        idToAddress[1] = owner;
    }

    function checkParam(uint index, uint value) public {
        require(msg.sender == owner);
        if(index == 1) {
            limit1 = value;
        }else if(index == 2) {
            limit2 = value;
        }else if(index == 3) {
            lotteryTime = value;
        }else if(index == 4) {
            feeTime = value;
        }else if(index == 5) {
            levelPrice = value;
        }
    }

    function fee() external payable {
        require(msg.value == 50 trx, "invalid price");
        reward += 50000000 * 3 / 10;
        address(uint160(owner)).transfer(50000000 * 7 / 10);
        users[msg.sender].mFeeTime += 30 * 24 * 60 * 60;
    }

    function rankList() external view returns(address,address,address,address,address,address,address,address,address,address) {
        return (rank[0],rank[1],rank[2],rank[3],rank[4],rank[5],rank[6],rank[7],rank[8],rank[9]);
    }

    function doRankSort(address recommender) private {
        address tmp = address(0);
        address tmp2 = recommender;
        for(uint i=0;i<10;i++) {
            if(rank[i] == tmp2) {
                break;
            }
            if(rank[i] == address(0)) {
                rank[i] = recommender;
                break;
            }
            if( partnersCount20[rank[i]] < partnersCount20[recommender] ) {
                tmp = rank[i];
                rank[i] = recommender;
                recommender = tmp;
            }
        }
    }

    function buyNewLevel() external payable {
        require(isUserExists(msg.sender));
        require(msg.value == levelPrice);
        require(users[msg.sender].level < LAST_LEVEL);

        users[msg.sender].level += 1;
       
        if(users[msg.sender].level == 10) {
            partnersCount10[users[msg.sender].referrer] += 1;
        }
        if(users[msg.sender].level == 20) {
            partnersCount20[users[msg.sender].referrer] += 1;
            doRankSort(users[msg.sender].referrer);
        }
        findLevel(users[msg.sender].currentReferrer, 1, users[msg.sender].level, 0);
        emit Upgrade(msg.sender, users[msg.sender].referrer, users[msg.sender].level);
    }

    function findLevel(address addr, uint8 hight, uint8 level, uint8 dep) private {
        if(dep > 60 || addr == address(0)) {
            income[owner] += levelPrice;
            address(uint160(owner)).transfer(levelPrice);
        }else if(hight < level) {
            findLevel(users[addr].currentReferrer, hight + 1, level, dep + 1);
        }else if( users[addr].level < level || users[addr].mFeeTime + 30*24*60*60 < now || (income[addr] >= limit2 && partnersCount10[addr] < 3) ) {  //等级   月费   
            burn[addr] += levelPrice;
            findLevel(users[addr].currentReferrer, hight, level, dep + 1);
        }else{
            income[addr] += levelPrice;
            if(income[addr] == limit1 ) {
                users[addr].level = 0;
            }
            address(uint160(addr)).transfer(levelPrice);
        }
    }

    function award() public {
        if(lotteryStart + lotteryTime < now) {
            lotteryStart = now;
            uint reward_tmp = reward;
            reward = 0;
            for(uint8 i=0;i<10;i++) {
                address addr = rank[i];
                rank[i] = address(0);
                uint award_tmp = reward_tmp * award_list[i] / 100;
                if(addr != address(0)) {
                    if(address(this).balance >= award_tmp) {
                        address(uint160(addr)).transfer(award_tmp);
                    }else{
                        address(uint160(addr)).transfer(address(this).balance);
                    }
                }
            }
        }
    }

    function getRefer(address addr) public returns(address, uint8) {
        address tmp = addr;
        uint8 i;
        for(i=0;i<20;i++) {
            if(childs[tmp][0] == address(0)) {
                return (tmp, 0);
            }
            tmp = childs[tmp][0];
        }
        tmp = addr;
        for(i=0;i<20;i++) {
            if(childs[tmp][1] == address(0)) {
                return (tmp, 1);
            }
            tmp = childs[tmp][1];
        } 
        if(tmplist[addr].length == 0) {
            tmplist[addr].push(childs[addr][0]);
            tmplist[addr].push(childs[addr][1]);
        }
        for(uint j=tmplen[addr];j<tmplist[addr].length;j++) {
            tmp = tmplist[addr][j];
            if(childs[tmp][0] == address(0)) {
                tmplen[addr]=j;
                return (tmp, 0);
            }
            if(childs[tmp][1] == address(0)) {
                tmplen[addr]=j;
                return (tmp, 1);
            }
            tmplist[addr].push(childs[tmp][0]);
            tmplist[addr].push(childs[tmp][1]);
        }
    }

    // 新用户注册：新用户地址、推荐人地址
    function registrationExt (address referrerAddress) external payable {
        require(msg.value == 150000000);
        require(!isUserExists(msg.sender));
        require(isUserExists(referrerAddress));
        // require(line == 0 || line == 1);
        // require(childs[freeX3Referrer][line] == address(0));
        address freeX3Referrer;
        uint8 line;
        (freeX3Referrer, line) = getRefer(referrerAddress);
        
        //费用处理
        reward += 50000000 * 3 / 10;
        address(uint160(owner)).transfer(50000000 * 7 / 10);
        // 创建新用户对象
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            mFeeTime: now,
            level: 1,
            currentReferrer: freeX3Referrer
        });
        users[msg.sender] = user;
        idToAddress[lastUserId] = msg.sender;
        lastUserId++;
        partnersCount[referrerAddress]++;
        childs[freeX3Referrer][line] = msg.sender;    
        income[referrerAddress] += levelPrice;
        if(income[referrerAddress] == limit1 ) {
            users[referrerAddress].level = 0;
        }
        address(uint160(referrerAddress)).transfer(levelPrice);
        emit Registration(msg.sender, referrerAddress, users[msg.sender].id, users[referrerAddress].id);
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
}