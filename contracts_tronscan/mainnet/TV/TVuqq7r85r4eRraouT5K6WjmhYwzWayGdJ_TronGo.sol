//SourceUnit: TronGo2.sol

pragma solidity 0.5.9;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: substraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

interface ITGO {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool);
}

interface ITGX {
    function mint(address _to, uint256 _amount) external returns (bool);
}

contract TronGo {
    using SafeMath for uint256;

    // Public
    address public TGO_ADDRESS;
    address public TGX_ADDRESS;
    address payable public OWNER_WALLET;
    uint256 public SERVICE_START_TIME = 2613952000; // Need to be changed

    uint256[] public PRICES = [
                    0,
           1000000000, // Lv 1:     1,000 TRX
           2000000000, // Lv 2:     2,000 TRX
           5000000000, // Lv 3:     5,000 TRX
          10000000000, // Lv 4:    10,000 TRX
          20000000000, // Lv 5:    20,000 TRX
          50000000000, // Lv 6:    50,000 TRX
         100000000000, // Lv 7:   100,000 TRX
         200000000000, // Lv 8:   200,000 TRX
         500000000000, // Lv 9:   500,000 TRX
        1000000000000  // Lv10: 1,000,000 TRX
    ];

    // Private
    uint256 constant MAX_MATRIX_REFERRALS = 2;
    uint256 constant MAX_TRAVERSAL_LEVEL = 4;
    uint256 constant DIRECT_REWARD_RATE = 50;
    uint256[] MATRIX_REWARD_RATES = [20, 20, 50];
    uint256 constant OWNER_REWARD_RATE = 5;
    uint256 constant TYPE_DIRECT = 1;
    uint256 constant TYPE_MATRIX = 2;
    uint256 constant TYPE_OWNER = 3;
    uint256 constant TYPE_ROLLUP = 4;
    uint256 constant HALVING_PERIOD = 60 days;
    uint256 constant POSITION_EXPIRATION = 365 days;
    uint256 constant OWNER_POSITIONS = 7;
    uint256 constant OFFERING_POSITIONS = 24;
    uint256[] UPGRADE_TGO_BONUS = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100000000000]; // 1,000 TGO
    uint256[] UPGRADE_TGX_BONUS = [
                      0,
           200000000000, // Lv 1:     2,000 TGX
           400000000000, // Lv 2:     4,000 TGX
          1000000000000, // Lv 3:    10,000 TGX
          2000000000000, // Lv 4:    20,000 TGX
          4000000000000, // Lv 5:    40,000 TGX
         10000000000000, // Lv 6:   100,000 TGX
         20000000000000, // Lv 7:   200,000 TGX
         40000000000000, // Lv 8:   400,000 TGX
        100000000000000, // Lv 9: 1,000,000 TGX
        200000000000000  // Lv10: 2,000,000 TGX
    ];

    // Structs
    struct Position {
        bool active;
        bytes3 id;
        address payable addr;
        bytes3 directRef;
        bytes3 matrixRef;
        uint256 numChildren;
        uint256 level;
        uint256 localPosition;
    }

    // Basic structure variables
    address owner;
    bytes3 public rootId;
    uint256 public numPositions;
    mapping(bytes3 => Position) public positions;
    mapping(uint256 => bytes3) public idByPosition;
    mapping(bytes3 => uint256) public balances;
    mapping(bytes3 => uint256) public lastActivities;

    event Register(address indexed userAddress, bytes3 indexed positionId, bytes3 directRef, bytes3 matrixRef);
    event Upgrade(address indexed userAddress, bytes3 indexed positionId, uint256 level, uint256 balance);
    event Reward(address indexed userAddress, bytes3 indexed positionId, uint256 reward, uint256 rewardType, uint256 level, bytes3 referal); // 1: Direct, 2: Matrix
    event Deposit(address indexed userAddress, bytes3 indexed positionId, uint256 amount, uint256 balance);
    event Withdraw(address indexed userAddress, bytes3 indexed positionId, uint256 amount, uint256 balance);
    event Transfer(bytes3 indexed positionId, address transferFrom, address transferTo);
    event Collect(bytes3 indexed positionId, uint256 amount);
    event Touch(bytes3 indexed positionId, uint256 lastActivity);

    // Modifiers
    modifier beforeServiceIn() {
        require(now < SERVICE_START_TIME, "Service not launched for public");
        _;
    }

    modifier afterServiceIn() {
        require(now >= SERVICE_START_TIME);
        _;
    }

    modifier positionNotExpired(bytes3 _id) {
        require(!isPositionExpired(_id));
        _;
    }

    modifier positionExpired(bytes3 _id) {
        require(isPositionExpired(_id));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Constructor
    constructor() public {
        owner = msg.sender;
    }

    // Before ServiceIn
    function setTGOAddress(address _tokenAddress) beforeServiceIn external onlyOwner{
        TGO_ADDRESS = _tokenAddress;
    }

    function setTGXAddress(address _tokenAddress) beforeServiceIn external onlyOwner{
        TGX_ADDRESS = _tokenAddress;
    }

    function setServiceStart() external beforeServiceIn onlyOwner returns (bool) {
        require(msg.sender == owner, "No permission");
        SERVICE_START_TIME = 1613840472;
        return true;
    }

    // Position Structure Migration
    function copyPosition(
        bytes3 id,
        address payable addr,
        bytes3 directRef,
        bytes3 matrixRef,
        uint256 numChildren,
        uint256 level,
        uint256 localPosition,
        uint256 globalPosition) beforeServiceIn external onlyOwner returns (bool) {

        require(!positions[id].active, "The position already initialized");

        // Init Position
        Position memory position;

        position = Position({
            active: true,
            id: id,
            addr: addr,
            directRef: directRef,
            matrixRef: matrixRef,
            numChildren: numChildren,
            level: level,
            localPosition: (localPosition.add(1) % 2).add(1)
        });

        positions[id] = position;
        balances[id] = 0;
        lastActivities[id] = now;
        if(id == directRef) rootId = id;
        if(globalPosition < 8)  idByPosition[globalPosition] = id;
        numPositions++;

        return true;
    }

    // After ServiceIn
    function purchaseUser(bytes3 _directRef, bytes3 _matrixRef) public payable afterServiceIn returns (bool) {
        require(positions[_directRef].active, "Invalid direct referrer");
        require(positions[_matrixRef].active, "Invalid matrix referrer");
        require(msg.value >= PRICES[1], "Insufficient amount to be sent");

        // Make a position with level 1
        bytes3 id = regUser(msg.sender, _directRef, _matrixRef, true);

        // Pay Registration Bonux (TGX)
        ITGX tgx = ITGX(TGX_ADDRESS);
        uint256 bonus = UPGRADE_TGX_BONUS[1].div(halvingFactor());
        tgx.mint(positions[id].addr, bonus);

        // Upgrade
        if(msg.value > PRICES[1]) _deposit(id, msg.value.sub(PRICES[1]));
        return true;
    }

    function deposit(bytes3 _id) external payable afterServiceIn positionNotExpired(_id) returns (bool){
        require(positions[_id].active, "User not activated");
        _deposit(_id, msg.value);
        touch(_id);
        return true;
    }

    function withdraw(bytes3 _id, uint256 _amount) external afterServiceIn positionNotExpired(_id) returns (bool) {
        // Check-Effect-Interaction
        require(balances[_id] >= _amount, "Insufficient balance");
        require(positions[_id].addr == msg.sender, "Invalid msg.sender");
        touch(_id);
        balances[_id] = balances[_id].sub(_amount);
        msg.sender.transfer(_amount);
        emit Withdraw(msg.sender, _id, _amount, balances[_id]);
        return true;
    }

    function payoutShare() external afterServiceIn returns (bool) {
        for(uint i = 1; i <= OWNER_POSITIONS; i++) {
            bytes3 id = idByPosition[i];
            if(balances[id] > 0) {
                uint256 payout = balances[id];
                balances[id] = 0;
                OWNER_WALLET.transfer(payout);
                emit Withdraw(OWNER_WALLET, id, payout, 0);
            }
        }
        return true;
    }

    function autoUpgrade(bytes3 _id) public positionNotExpired(_id) returns (bool) {
        require(positions[_id].active, "The position doesn't exist");
        uint256 level = positions[_id].level;
        for(uint256 i = level + 1; i <= 10; i++) {
            if(balances[_id] >= PRICES[i]) {
                upgrade(_id, i);
            }else{
                break;
            }
        }
        return true;
    }

    function upgrade(bytes3 _id, uint256 _level) public positionNotExpired(_id) returns (bool){
        require(_level >=2 && _level <= 10, "Invalid level");
        require(positions[_id].level + 1 == _level, "Cannot upgrade above the current level + 1");
        require(balances[_id] >= PRICES[_level], "Insufficient fund");
        balances[_id] = balances[_id].sub(PRICES[_level]);
        payReward(_level, _id);
        positions[_id].level = _level;
        payUpgradeBonus(_id, _level);
        touch(_id);

        emit Upgrade(positions[_id].addr, _id, _level, balances[_id]);
        return true;
    }

    function transferPosition(bytes3 _id, address payable _to) external positionNotExpired(_id) returns (bool) {
        require(positions[_id].addr == msg.sender, "The position is not yours");
        touch(_id);

        positions[_id].addr = _to;
        emit Transfer(_id, msg.sender, _to);
        return true;
    }

    function collectExpired(bytes3 _id) external positionExpired(_id) returns (bool) {
        uint256 collectAmount = balances[_id];
        balances[_id] = 0;
        balances[rootId] += collectAmount;
        emit Collect(_id, collectAmount);
        return true;
    }

    // Public View Funtions
    function halvingFactor() public view returns (uint256) {
        uint256 factor = 1;
        if(now > SERVICE_START_TIME) {
            factor = 2 ** (now.sub(SERVICE_START_TIME).div(HALVING_PERIOD));
        }
        return factor;
    }

    // Utilities
    function setOwnerWallet(address payable _addr) external onlyOwner returns(bool) {
        OWNER_WALLET = _addr;
        for(uint256 i = 0; i < 8; i++) {
            positions[idByPosition[i]].addr = _addr;
        }
        return true;
    }

    function setPosition(
        bytes3 _id,
        address payable _addr,
        bytes3 _directRef,
        bytes3 _matrixRef,
        uint256 _numChildren,
        uint256 _level,
        uint256 _localPosition,
        uint256 _balance) external onlyOwner returns (bool) {

        // Init Position
        Position storage p = positions[_id];

        p.addr = _addr;
        p.directRef = _directRef;
        p.matrixRef = _matrixRef;
        p.numChildren =  _numChildren;
        p.level = _level;
        p.localPosition = _localPosition;
        balances[_id] = _balance;

        return true;
    }

    function collectTGO() external onlyOwner returns (bool) {
        ITGO tgo = ITGO(TGO_ADDRESS);
        tgo.transfer(msg.sender, tgo.balanceOf(msg.sender));
        return true;
    }

    // Internal Functions
    function regUser(address payable _addr, bytes3 _directRef, bytes3 _matrixRef, bool _payReward) internal returns (bytes3 _id) {
        bytes3 directRef = _directRef;
        bytes3 matrixRef = _matrixRef;
        require(positions[_directRef].active, "Invalid direct referrer");
        require(positions[_matrixRef].active, "Invalid matrix referrer");
        require(positions[_matrixRef].numChildren < MAX_MATRIX_REFERRALS, "Max matrix referrals");

        bytes3 id = getId();
        uint256 localPosition = positions[_matrixRef].numChildren + 1;

        Position memory position;
        position = Position({
            active: true,
            id: id,
            addr: _addr,
            directRef: directRef,
            matrixRef: matrixRef,
            numChildren: 0,
            level: 1,
            localPosition: localPosition
        });

        positions[id] = position;
        positions[matrixRef].numChildren++;

        lastActivities[id] = now;

        numPositions++;
        emit Register(_addr, id, directRef, matrixRef);

        if(_payReward) payReward(1, id);

        return id;
    }

    function payReward(uint _level, bytes3 _id) internal {
        uint256 directPool = PRICES[_level].mul(DIRECT_REWARD_RATE).div(100);
        uint256 matrixPool = PRICES[_level].sub(directPool);

        // Matrix Reward
        uint256 matrixRewardPaid = 0;
        Position memory current = positions[_id];
        for(uint i = 0; i < MATRIX_REWARD_RATES.length; i++){
            Position memory matrixRefUser = positions[current.matrixRef];

            uint256 reward = matrixPool.mul(MATRIX_REWARD_RATES[i]).div(100);

            // If the matrix referrer has enough level, and not expired
            if(!isPositionExpired(matrixRefUser.id) && matrixRefUser.level >= _level) {
                balances[matrixRefUser.id] = balances[matrixRefUser.id].add(reward); // += reward
                matrixRewardPaid = matrixRewardPaid.add(reward); // += reward
                emit Reward(matrixRefUser.addr, matrixRefUser.id, reward, TYPE_MATRIX, _level, _id);

            // If the matrix referrer is expired, or doesn't have enough level
            }else{
                balances[rootId] = balances[rootId].add(reward); // += reward
                matrixRewardPaid = matrixRewardPaid.add(reward); // += reward
                emit Reward(OWNER_WALLET, rootId, reward, TYPE_ROLLUP, _level, _id);
            }
            current = matrixRefUser;
        }

        // Owner Reward
        uint256 ownerReward = matrixPool.sub(matrixRewardPaid);
        balances[rootId] = balances[rootId].add(ownerReward); // += ownerReward
        emit Reward(OWNER_WALLET, rootId, ownerReward, TYPE_OWNER, _level, _id);

        // Direct Reward
        Position memory directRefUser = positions[positions[_id].directRef];
        // If the direct referrer is expired
        if(isPositionExpired(directRefUser.id)){
            balances[rootId] = balances[rootId].add(directPool); // += directPool
            emit Reward(OWNER_WALLET, rootId, directPool, TYPE_ROLLUP, _level, _id);
        // If the direct referrer is not expired, and has enough level
        }else if(directRefUser.level >= _level){
            // Pay all the Go1 reward to the direct referrer
            balances[directRefUser.id] = balances[directRefUser.id].add(directPool); // += directPool
            emit Reward(directRefUser.addr, directRefUser.id, directPool, TYPE_DIRECT, _level, _id);
        // If the direct referrer doesn't have enough level
        }else{
            balances[rootId] = balances[rootId].add(directPool); // += directPool
            emit Reward(OWNER_WALLET, rootId, directPool, TYPE_ROLLUP, _level, _id);
        }
    }

    function payUpgradeBonus(bytes3 _id, uint256 _level) internal {
        ITGX tgx = ITGX(TGX_ADDRESS);
        uint256 bonus = UPGRADE_TGX_BONUS[_level].div(halvingFactor());
        tgx.mint(positions[_id].addr, bonus);

        if(_level == 10) {
            ITGO tgo = ITGO(TGO_ADDRESS);
            if(tgo.balanceOf(address(this)) >= UPGRADE_TGO_BONUS[_level]) {
                tgo.transfer(positions[_id].addr, UPGRADE_TGO_BONUS[_level]);
            }
        }
    }

    function _deposit(bytes3 _id, uint256 _amount) internal {
        balances[_id] = balances[_id].add(_amount);
        autoUpgrade(_id);
        emit Deposit(msg.sender, _id, _amount, balances[_id]);
    }

    function touch(bytes3 _id) public returns (bool) {
        if(!isPositionExpired(_id)) lastActivities[_id] = now;
        emit Touch(_id, now);
        return true;
    }

    function isPositionExpired(bytes3 _id) internal view returns (bool) {
        return (positions[_id].addr != OWNER_WALLET && lastActivities[_id] + POSITION_EXPIRATION < now);
    }

    function getId() internal view returns (bytes3){
        bytes3 id = 0x0;
        for(uint i = 0; i < 20; i++) {
            id = bytes3(uint24(uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 10), i))) >> 232));
            if(!positions[id].active) break;
        }
        require(id != 0x0);
        return id;
    }
}