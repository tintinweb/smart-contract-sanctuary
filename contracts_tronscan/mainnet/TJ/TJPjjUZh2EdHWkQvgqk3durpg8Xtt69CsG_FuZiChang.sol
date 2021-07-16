//SourceUnit: Logic_trx_v4.sol

pragma solidity ^ 0.5 .8;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "math error");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0, "math error"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(a >= b, "math error");

        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "math error");

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0, "math error");
        return a % b;
    }
}

contract Ownership {
    address private owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner error");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function contractOwner() public returns(address) {
        return owner;
    }    
}

contract FuZiChang is Ownership {
    using SafeMath
    for uint256;

    event FrozenFunds(address _target, bool _frozen);
    mapping(address => bool) forzeAccount;

    uint256 public mininvest; //
    uint256 public maxinvest; //
    uint64 public outrate; //
    uint64 public timestep; //

    uint64[15] public freerate; //

    uint8 public rewardLevel; //
    uint64 public staticRate; //

    //
    uint256 public totalCount; //
    uint256 public totalInvest; //
    uint256 public totalFree; //
    uint256 public totalReward; //
    uint256 public totalWithdraw; //

    //
    uint64 public rewardRate; //
    address[10] public raddress; //
    uint64[10] public rrates; //
    mapping(address => uint256) public rbalances; //
    uint256 public allReward; //
    uint256 public validReward; //

    uint8 public onoff; //

    //
    uint64 public commissionrate; //

    address public toperaddr;

    struct UData {
        address uper;
        uint32 id;
        uint32 valid;
        uint32 level; //
        uint32 ucount; //
        uint32 vcount; //
        uint256 validinvest; //
        uint256 amount; //
        uint256 reward; //
        uint256 validmoney; //
    }

    struct UDExt {
        uint256 invest; //
        uint256 teaminvest; //
        uint256 dynamicreward; //
        uint256 staticreward; //
        uint256 withdraw; //
    }

    uint256[] public freetime; //
    uint64 public lastid; //

    mapping(uint64 => address) public uidmap; //

    mapping(address => UData) public users; //
    mapping(address => UDExt) public uexts; //

    uint64 public withdrawfee; //
    address payable public feeaddress; //

    uint64 public currentid;
    mapping(uint64 => address) public addrmap; //

    constructor(address toper, address payable drawaddress) public {
        mininvest = 1000 trx;
        maxinvest = 100000 trx;
        outrate = 3000;
        timestep = 1440 minutes;

        freerate = [300, 300, 200, 100, 100, 80, 80, 80, 80, 80, 50, 50, 50, 100, 100];

        rewardRate = 50;

        rrates = [100, 100, 100, 100, 100, 100, 100, 100, 100, 100];

        onoff = 1;

        rewardLevel = 15;

        staticRate = 10;

        toperaddr = toper;

        users[toper] = UData(address(0), 0, 0, 1, 0, 0, 0, 0, 0, 0);
        uexts[toper] = UDExt(0, 0, 0, 0, 0);

        lastid = 0;
        freetime.push(0);

        commissionrate = 15;
        withdrawfee = 50;
        feeaddress = drawaddress;

        currentid = 1;
    }

    function migrateContract(address token) public payable onlyOwner
    {
        FuZiChang old = FuZiChang(token);

        mininvest = old.mininvest(); //
        maxinvest = old.maxinvest(); //
        outrate = old.outrate(); //
        timestep = old.timestep(); //

        rewardLevel = old.rewardLevel(); //
        staticRate = old.staticRate(); //

        //
        totalCount = old.totalCount(); //
        totalInvest = old.totalInvest(); //
        totalFree = old.totalFree(); //
        totalReward = old.totalReward(); //
        totalWithdraw = old.totalWithdraw(); //

        //
        rewardRate = old.rewardRate(); //
        allReward = old.allReward(); //
        validReward = old.validReward(); //
        //
        commissionrate = old.commissionrate(); //

        toperaddr = old.toperaddr();

        lastid = old.lastid(); //
    }

    function syncraddress(address token) public payable onlyOwner
    {
        FuZiChang old = FuZiChang(token);

        address addr = address(0);
        uint256 balance = 0;
        for(uint8 i = 0; i < 10; i++){
            addr = old.raddress(i);
            balance = old.rbalances(addr);
            raddress[i] = addr;
            rbalances[addr] = balance;
        }
    }

    function syncFreetime(uint64 len) public payable onlyOwner  returns(uint256)
    {
        uint256 istart = freetime.length;
        while(istart < len){
            freetime.push(now + timestep);
            istart ++;
        }

        return istart;
    }    

    function syncUData(address uaddr, address uper,uint32 id,uint32 valid,uint32 level,uint32 ucount,uint32 vcount,uint256 validinvest,uint256 amount,uint256 reward,uint256 validmoney,uint256 ftime) public payable onlyOwner  returns(address)
    {
        if(users[uaddr].level == 0)
        {
            addrmap[currentid] = uaddr; 
            currentid++;
        }
        users[uaddr] = UData(uper, id, valid, level, ucount, vcount, validinvest, amount, reward, validmoney);    
        if(id > 0){
            uidmap[id] = uaddr;
            freetime[id] = ftime;
        }
        return uaddr;
    }

    function syncUDExt(address uaddr, uint256 d1, uint256 d2, uint256 d3, uint256 d4, uint256 d5) public payable onlyOwner  returns(address)
    {
        uexts[uaddr] = UDExt(d1, d2, d3, d4, d5);

        totalWithdraw = totalWithdraw.add(d5);
        return uaddr;
    }

    function setUData(address uaddr, uint256 validinvest,uint256 amount,uint256 reward) public payable onlyOwner  returns(address)
    {
        users[uaddr].validinvest = validinvest;        
        users[uaddr].amount = amount;        
        users[uaddr].reward = reward;        
        //users[uaddr].validmoney = validmoney;
        return uaddr;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // function destroyContract() external onlyOwner {
    //     selfdestruct(msg.sender);
    // }

    function setInvest(uint256 min, uint256 max, uint64 rate) external onlyOwner  returns(uint64){
        mininvest = min * 1 trx;
        maxinvest = max * 1 trx;
        outrate = rate;
        return outrate;
    }

    function freezeAccount(address _target, bool _frozen) external onlyOwner {
        forzeAccount[_target] = _frozen;
        emit FrozenFunds(_target, _frozen);
    }

    function setStaticRate(uint64 rate) external onlyOwner returns(uint64) {
        staticRate = rate;
        return staticRate;
    }

    function setRewardLevel(uint8 level) external onlyOwner returns(uint8) {
        rewardLevel = level;
        return rewardLevel;
    }

    modifier isOn() {
        require(onoff == 1, "contract is off");
        _;
    }

    function setTimestep(uint64 step) external onlyOwner  returns(uint64){
        timestep = step * 1 minutes;
        return timestep;
    }

    function setCommissionRate(uint64 rate) external onlyOwner returns(uint64) {
        commissionrate = rate;
        return commissionrate;
    }

    function setWithdraw(address payable addr) external onlyOwner returns(uint64){
        feeaddress = addr;
        return withdrawfee;
    }

    function timeLength() external returns(uint256) {
        return freetime.length;
    }

    function reset() external onlyOwner returns(uint64 ret) {
        uint64 i = 0;
        address user;
        for (i = 1; i < freetime.length; i++) {
            freetime[i] = 0;
            user = uidmap[i];
            users[user].valid  = 0;
            users[user].ucount = 0;
            users[user].vcount = 0;
            users[user].validinvest = 0;
            users[user].amount = 0;
            users[user].reward = 0;
            users[user].validmoney = 0;

            uexts[user].invest = 0;
            uexts[user].teaminvest = 0;
            uexts[user].dynamicreward = 0;
            uexts[user].staticreward = 0;
            uexts[user].withdraw = 0;
        }

        totalCount = 0; //
        totalInvest = 0; //
        totalFree = 0; //
        totalReward = 0; //
        totalWithdraw = 0; //

        for(uint8 y = 0; y < 10; y++){
            user = raddress[y];
            if(user != address(0)){
                rbalances[user] = 0;
            }
        }
        allReward = 0; //
        validReward = 0; //

        return i;
    }

    function getall() public view returns(uint256 money) {
        money = address(this).balance;
    }

    //
    function setRewardRate(uint64 rate) public onlyOwner  returns(uint64){
        rewardRate = rate;
        return rewardRate;
    }

    //
    function setAddress(address token, uint8 index) external onlyOwner returns(address) {
        require(index >= 0 && index < 10, "index is out range");
        raddress[index] = token;
        return raddress[index];
    }

    function register(address _uper) public returns(bool) {
        require(users[_uper].level > 0 && users[_uper].valid > 0, "upper is not valid");
        require(users[msg.sender].level == 0, "user repeat register");

        users[msg.sender] = UData(_uper, 0, 0, users[_uper].level + 1, 0, 0, 0, 0, 0, 0);
        uexts[msg.sender] = UDExt(0, 0, 0, 0, 0);

        addrmap[currentid] = msg.sender;
        currentid++;
        return true;
    }

    //
    function invest() public payable isOn returns(uint256) {
        address user = msg.sender;
        uint256 _amount = msg.value;
        require(users[user].level > 0, "user is not register");
        require(_amount.mod(1000 trx) == 0, "1000 integral times");

        UData storage uInfo = users[user];
        require(
            _amount.add(uInfo.validinvest) >= mininvest && _amount.add(uInfo.validinvest) <= maxinvest,
            "invest is out of range"
        );

        totalInvest = totalInvest.add(_amount);
        if (uInfo.valid == 0) {
            totalCount++;
        }

        uint32 ovalid = uInfo.valid;
        if (uInfo.valid == 0) {
            uInfo.id = uint32(freetime.length);
            uidmap[uInfo.id] = user;
            freetime.push(now + timestep);
        } else {
            freetime[uInfo.id] = now + timestep;
        }
        uInfo.valid = 1;
        uInfo.validinvest = uInfo.validinvest.add(_amount);
        uInfo.amount = uInfo.amount.add(_amount.mul(outrate).div(1000));

        uexts[user].invest = uexts[user].invest.add(_amount);

        address upaddr = uInfo.uper;

        for (uint8 i = 1; i <= 15; i++) {
            if (upaddr == address(0)) {
                break;
            }

            if (ovalid != 1) {
                if (i == 1) {
                    users[upaddr].vcount = users[upaddr].vcount + 1;
                }

                if (ovalid == 0) {
                    users[upaddr].ucount = users[upaddr].ucount + 1;
                }
            }

            uexts[upaddr].teaminvest = uexts[upaddr].teaminvest.add(_amount);

            upaddr = users[upaddr].uper;
        }

        //
        users[toperaddr].validmoney = users[toperaddr].validmoney.add(_amount.mul(commissionrate).div(1000));

        //
        uint256 _allreward = _amount.mul(rewardRate).div(1000);
        uint64 rate = 0;
        uint256 reward = 0;
        address addr;

        allReward = allReward.add(_allreward);
        validReward = validReward.add(_allreward);

        for (uint8 i = 0; i < 10; i++) {
            rate = rrates[i];
            addr = raddress[i];
            if (rate > 0 && addr != address(0)) {
                reward = _allreward.mul(rate).div(1000);
                rbalances[addr] = rbalances[addr].add(reward);
            }
        }

        return _amount;
    }

    function isfree() view public returns(uint64 ret) {
        uint64 id = 0;
        uint64 i = lastid + 1;
        uint256 utime = 0;
        for (; i < freetime.length; i++) {
            utime = freetime[i];
            if (utime > 0 && utime < now) {
                id = i;
                break;
            }
        }

        if (id == 0) {
            for (i = 1; i <= lastid; i++) {
                utime = freetime[i];
                if (utime > 0 && utime < now) {
                    id = i;
                    break;
                }
            }
        }

        ret = id;
        return ret;
    }

    function freeUpdate(address user, uint256 money, uint8 fromtype, bool isout) internal returns(bool) {
        UData storage uInfo = users[user];
        uInfo.reward = uInfo.reward.add(money);
        uInfo.validmoney = uInfo.validmoney.add(money);
        if (fromtype == 1) {
            freetime[uInfo.id] = now + timestep;
            uexts[user].staticreward = uexts[user].staticreward.add(money); //
        } else {
            uexts[user].dynamicreward = uexts[user].dynamicreward.add(money); //
        }

        if (isout) {
            freetime[uInfo.id] = 0;
            uInfo.validinvest = 0;
            uInfo.valid = 2;
            uInfo.amount = 0;
            uInfo.reward = 0;
            if (uInfo.uper != address(0) && users[uInfo.uper].vcount > 0) {
                users[uInfo.uper].vcount = users[uInfo.uper].vcount - 1;
            }
        }
    }

    function freeUserReward(address user) internal isOn returns(bool) {
        uint64 rate = 0;

        uint256 freereward = 0;
        uint256 free = 0;

        bool isout = false;

        UData storage uInfo = users[user];


        require(uInfo.valid == 1, "invalid user");

        isout = false;
        if (uInfo.amount < uInfo.reward) {
            free = 0;
            isout = true;
        } else {
            free = uInfo.validinvest.mul(staticRate).div(1000);
            if (free > uInfo.amount.sub(uInfo.reward)) {
                free = uInfo.amount.sub(uInfo.reward);
                isout = true;
            }
        }

        freeUpdate(user, free, 1, isout);

        totalFree = totalFree.add(free);

        if (free > 0) {
            uint8 i = 1;
            do {
                user = uInfo.uper;
                if (user == address(0)) {
                    break;
                }

                rate = freerate[i - 1];

                uInfo = users[user];
                freereward = 0;
                isout = false;

                if (uInfo.valid == 1) {
                    //推荐几人拿几代
                    if (uInfo.vcount >= i) {
                        if (uInfo.amount < uInfo.reward) {
                            freereward = 0;
                            isout = true;
                        } else {
                            freereward = free.mul(rate).div(1000);
                            if (freereward > uInfo.amount.sub(uInfo.reward)) {
                                freereward = uInfo.amount.sub(uInfo.reward);
                                isout = true;
                            }
                        }

                        freeUpdate(user, freereward, 2, isout);
                        totalReward = totalReward.add(freereward);
                    }
                    i++;
                }
            } while (i <= rewardLevel);
        }
        return true;
    }

    function freeReward(uint64 _id) public payable isOn returns(bool) {
        require(freetime[_id] > 0 && freetime[_id] < now, "Time is not up");

        return freeUserReward(uidmap[_id]);
    }

    function freeUser() public payable isOn returns(bool) {
        address user = msg.sender;
        UData storage uInfo = users[user];
        require(freetime[uInfo.id] > 0 && freetime[uInfo.id] < now, "Time is not up");

        return freeUserReward(user);
    }

    function withdraw(uint256 money) external isOn returns(uint256) {
        uint256 min = 100 trx;
        require(address(this).balance >= money.add(validReward).add(min), "balance not enough");
        require(!forzeAccount[msg.sender], "address freeze");

        address user = msg.sender;
        UData storage uInfo = users[user];
        uint256 wmoney = money;
        uint256 wmoneyx = 0;
        uint256 fee = 0;

        if (uInfo.level != 1) {
            wmoney = uInfo.validmoney;
        }

        wmoneyx = wmoney;
        require(uInfo.validmoney >= wmoney, "balance is not enough");

        if (wmoney > 0) {
            totalWithdraw = totalWithdraw.add(wmoney);
            uInfo.validmoney = uInfo.validmoney.sub(wmoney);
            uexts[user].withdraw = uexts[user].withdraw.add(wmoney);

            fee = wmoney.mul(withdrawfee).div(1000);
            if (fee > 0) {
                feeaddress.transfer(fee);
                wmoney = wmoney.sub(fee);
            }
            msg.sender.transfer(wmoney);
            return wmoneyx;
        }

        return 0;
    }

    function getReward(uint256 money) external returns(uint256) {
        address user = msg.sender;
        require(money > 0 && address(this).balance > money, "balance not enough");
        require(money <= rbalances[user], "balance not enough");

        rbalances[user] = rbalances[user].sub(money);

        validReward = validReward.sub(money);

        msg.sender.transfer(money);

        return money;
    }

    function getUser() external view returns(uint32[6] memory i32, uint256[11] memory i256, uint256[8] memory i2565, address up) {
        address user = msg.sender;

        up = users[user].uper;
        i32[0] = users[user].id;
        i32[1] = users[user].valid;
        i32[2] = 0;
        i32[3] = users[user].level;
        i32[4] = users[user].ucount;
        i32[5] = users[user].vcount;

        i256[0] = uexts[user].invest;
        i256[1] = users[user].validinvest;
        i256[2] = users[user].amount;
        i256[3] = users[user].reward;
        i256[4] = users[user].validmoney;

        i256[5] = uexts[user].teaminvest; //
        i256[6] = uexts[user].dynamicreward; //
        i256[7] = 0; //
        i256[8] = uexts[user].staticreward; //
        i256[9] = uexts[user].withdraw; //
        i256[10] = 0;
        if (users[user].id > 0) {
            i256[10] = freetime[users[user].id];
        }
        
        i2565[0] = totalCount; //
        i2565[1] = totalInvest; //
        i2565[2] = totalFree; //
        i2565[3] = totalReward; //
        i2565[4] = 0; //

        i2565[5] = totalWithdraw; //
        i2565[6] = address(this).balance; //
        i2565[7] = rbalances[user]; //
    }
}