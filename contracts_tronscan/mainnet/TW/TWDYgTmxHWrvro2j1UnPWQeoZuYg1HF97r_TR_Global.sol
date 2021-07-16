//SourceUnit: TR_Global.sol

pragma solidity 0.5.10;

/**
 *  _______ _____   ____  _   _ _____  _    _  _____ _    _   _____ ____      
 * |__   __|  __ \ / __ \| \ | |  __ \| |  | |/ ____| |  | | |_   _/ __ \     
 *    | |  | |__) | |  | |  \| | |__) | |  | | (___ | |__| |   | || |  | |    
 *    | |  |  _  /| |  | | . ` |  _  /| |  | |\___ \|  __  |   | || |  | |    
 *    | |  | | \ \| |__| | |\  | | \ \| |__| |____) | |  | |_ _| || |__| |    
 *    |_|  |_|  \_\\____/|_| \_|_|  \_\\____/|_____/|_|  |_(_)_____\____/     
 *
 *       The World's 1st Hybrid New Generation Smart Contract Platform.
 *   
 *  Visit Us: https://app.tronrush.io/
 *  telegram official: https://t.me/TronRushOfficial
 *  telegram community: https://t.me/TronRushOfficialCommunity
 *  email: support[at]tronorush.io
 */

contract TR_Global {

    struct User {
        uint256 id;
        address referrer;
        address[] referrals;
        mapping(address => Infinity) infinityPool;
        mapping(address => GlobalPool) matrixPool;
    }

    struct Infinity {
        uint8 level;
        uint256 levelIncome;
        uint256 directIncome;
        address referrer;
        address[] referrals;
        uint[8] levelEarning;
    }

    struct GlobalPool {
        uint8 level;
        uint256 poolIncome;
        mapping(uint8 => Matrix) globalMatrix;
    }

    struct Matrix {
        uint256 matrixId;
        address referrer;
        address[] referrals;
        uint256 poolEarning;
    }


    address public creator;
    address public owner;
    uint256 public lastId;
    mapping(uint8 => uint256) public matrixHeads;
    mapping(uint8 => uint256) public matrixIds;
    mapping (uint8 => uint256) public levels;
    mapping (uint8 => uint256) public pools;
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint8 => mapping(uint256 => address)) public matrixIdToAddress;
    
    event Registration(address indexed user, address referrer, uint256 userId);
    event Purchase(address indexed user, uint8 level, string matrix);
    event EarnedProfit(address indexed user, address referral, string matrix, uint8 level, uint256 amount);
    event LostProfit(address indexed user, address referral, uint8 level, uint256 amount);
    event ReferralPlaced(address indexed referral, address direct, address infinity);
    event GlobalReferralPlaced(address indexed referral, address referrer, uint8 pool);
    
    modifier isOwner(address _account) {
        require(creator == _account, "Restricted Access!");
        _;
    }

    constructor (address _owner) public {
        
        levels[1] = 100 trx;
        levels[2] = 150 trx;
        levels[3] = 300 trx;
        levels[4] = 600 trx;
        levels[5] = 2000 trx;
        levels[6] = 6000 trx;
        levels[7] = 15000 trx;
        levels[8] = 50000 trx;
        
        pools[1] = 3000 trx;
        pools[2] = 5000 trx;
        pools[3] = 7000 trx;
        pools[4] = 10000 trx;
        pools[5] = 15000 trx;
        pools[6] = 20000 trx;
        pools[7] = 30000 trx;
        pools[8] = 40000 trx;
        pools[9] = 60000 trx;
        pools[10] = 100000 trx;
        pools[11] = 150000 trx;
        pools[12] = 200000 trx;
        pools[13] = 250000 trx;
        pools[14] = 350000 trx;
        pools[15] = 500000 trx;

        creator = msg.sender;
        owner = _owner;
        
        lastId++;

        User memory account = User({
            id: lastId,
            referrer: address(0),
            referrals: new address[](0)
        });

        users[owner] = account;
        idToAddress[lastId] = owner;

        users[owner].infinityPool[owner].level = 8;
        users[owner].infinityPool[owner].referrer = address(0);
        users[owner].infinityPool[owner].referrals = new address[](0);
        
        users[owner].matrixPool[owner].level = 15;
        for (uint8 i = 1; i <= 15; i++) {
            matrixHeads[i] = lastId;
            matrixIds[i] = lastId;
            matrixIdToAddress[i][lastId] = owner;
            users[owner].matrixPool[owner].globalMatrix[i].matrixId = lastId; 
            users[owner].matrixPool[owner].globalMatrix[i].referrer = address(0);
            users[owner].matrixPool[owner].globalMatrix[i].referrals = new address[](0);
        }
    }
    
    function() external payable {
        revert();
    }

    function signup(address _referrer) external payable {
        require(!isUserExists(msg.sender), "User registered");
        require(isUserExists(_referrer), "Invalid referrer");
        require(msg.value == levels[1], "Invalid amount");
        _createAccount(msg.sender, _referrer);
    }

    function upgradeLevel(uint8 _level) external payable {
        require(isUserExists(msg.sender), "User not registered!");
        require(_level > 1 && _level <= 8, "Invalid Level");
        require(msg.value == levels[_level], "Invalid amount!");
        require(_level == users[msg.sender].infinityPool[msg.sender].level + 1, "Invalid Level");
        users[msg.sender].infinityPool[msg.sender].level = _level;
        _sendLevelDividends(_level, msg.sender);
        emit Purchase(msg.sender, _level, 'infinity');
    }

    function purchaseMatrix(uint8 _pool) external payable {
        require(isUserExists(msg.sender), "User not registered!");
        require(_pool >= 1 && _pool <= 15, "Invalid Level");
        require(msg.value == pools[_pool], "Invalid amount!");
        require(_pool == users[msg.sender].matrixPool[msg.sender].level + 1, "Invalid Pool");
        require(users[msg.sender].referrals.length >= 2, "Atleast 2 referrals required");
        require(users[msg.sender].infinityPool[msg.sender].level >= 4, "Infinity L4 required");
        
        matrixIds[_pool]++;
        users[msg.sender].matrixPool[msg.sender].level = _pool;
        users[msg.sender].matrixPool[msg.sender].globalMatrix[_pool].matrixId = matrixIds[_pool];
        matrixIdToAddress[_pool][matrixIds[_pool]] = msg.sender;

        address _referrer = _findGlobalReferrer(matrixHeads[_pool], _pool);
        users[msg.sender].matrixPool[msg.sender].globalMatrix[_pool].referrer = _referrer;
        users[_referrer].matrixPool[_referrer].globalMatrix[_pool].referrals.push(msg.sender);
        emit GlobalReferralPlaced(msg.sender, _referrer, _pool);

        _processPayout(_referrer, msg.value);
        users[_referrer].matrixPool[_referrer].poolIncome += msg.value;
        users[_referrer].matrixPool[_referrer].globalMatrix[_pool].poolEarning += msg.value;
        emit EarnedProfit(_referrer, msg.sender, 'pool', _pool, msg.value);
        emit Purchase(msg.sender, _pool, 'pool');
    }

    function failSafe(address payable _addr, uint _amount) external isOwner(msg.sender) {
        require(_addr != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_addr).transfer(_amount);
    }

    function _createAccount(address _addr, address _referrer) internal {
        address _freeReferrer;
        _freeReferrer = findFreeReferrer(_referrer);
        
        lastId++;
        User memory account = User({
            id: lastId,
            referrer: _referrer,
            referrals: new address[](0)
        });
        
        users[_addr] = account;
        idToAddress[lastId] = _addr;
        
        users[_addr].infinityPool[_addr].level = 1;
        users[_addr].infinityPool[_addr].referrer = _freeReferrer;
        users[_addr].infinityPool[_addr].referrals = new address[](0);
        users[_freeReferrer].infinityPool[_freeReferrer].referrals.push(_addr);
        users[_referrer].referrals.push(_addr);
        emit ReferralPlaced(_addr, _referrer, _freeReferrer);
        
        _sendLevelDividends(1, _addr);
        emit Registration(_addr, _referrer, lastId);
    }
    
    function _sendLevelDividends(uint8 _level, address _addr) internal {
        address _referrer;
        uint256 _profit;
        uint256 _direct;
        
        if (_level == 1) {
            _profit = levels[_level];
            _direct = 0;
        }
        else {
            _profit = levels[_level] * 75 / 100;
            _direct = levels[_level] * 25 / 100;
        }
        
        if (_direct > 0) {
            _processPayout(users[_addr].referrer, _direct);
            users[users[_addr].referrer].infinityPool[users[_addr].referrer].directIncome += _direct;
            emit EarnedProfit(users[_addr].referrer, _addr, 'direct', _level, _direct);
        }
 
        _referrer = getReferrrers(_level, _addr);
        if (users[_referrer].infinityPool[_referrer].level >= _level) {
            users[_referrer].infinityPool[_referrer].levelEarning[_level] += 1;
            users[_referrer].infinityPool[_referrer].levelIncome += _profit;
            _processPayout(_referrer, _profit);
            emit EarnedProfit(_referrer, _addr, 'infinity', _level, _profit);
        }
        else {
            if (_referrer != address(0)) {
                emit LostProfit(_referrer, _addr, _level, _profit);
            }
            for (uint8 i = 1; i <= 8; i++) {
                _referrer = getReferrrers(i, _referrer);
                if (_referrer == address(0)) {
                    _processPayout(owner, _profit);
                    break;
                }
                if (users[_referrer].infinityPool[_referrer].level >= _level) {
                    uint256 maxSize = 2 ** uint256(_level);
                   if (users[_referrer].infinityPool[_referrer].levelEarning[_level] <=  maxSize ) {
                       users[_referrer].infinityPool[_referrer].levelIncome += _profit;
                       users[_referrer].infinityPool[_referrer].levelEarning[_level] += 1;
                        _processPayout(_referrer, _profit);
                        emit EarnedProfit(_referrer, _addr, 'infinity', _level, _profit);
                        break;
                   }
                }
            }
        }
    }

    function _findGlobalReferrer(uint256 _head, uint8 _pool) internal returns(address) {
        address _top = matrixIdToAddress[_pool][_head];
        if (users[_top].matrixPool[_top].globalMatrix[_pool].referrals.length < 2) {
            matrixHeads[_pool] = users[_top].matrixPool[_top].globalMatrix[_pool].matrixId;
            return _top;
        }
		return _findGlobalReferrer(matrixHeads[_pool] + 1, _pool);
    }

    function getReferrrers(uint8 height, address _addr) public view returns (address) {
        if (height <= 0 || _addr == address(0)) {
            return _addr;
        }
        return getReferrrers(height - 1, users[_addr].infinityPool[_addr].referrer);    
    }

    function findFreeReferrer(address _addr) public view returns(address) {
        if (users[_addr].infinityPool[_addr].referrals.length < 2) {
            return _addr;
        }
        bool noReferrer = true;
        address referrer;
        address[] memory referrals = new address[](510);
        referrals[0] = users[_addr].infinityPool[_addr].referrals[0];
        referrals[1] = users[_addr].infinityPool[_addr].referrals[1];

        for(uint i = 0; i < 510; i++) {
            if(users[referrals[i]].infinityPool[referrals[i]].referrals.length == 2) {
                if( i < 254) {
                    referrals[(i+1)*2] = users[referrals[i]].infinityPool[referrals[i]].referrals[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].infinityPool[referrals[i]].referrals[1];
                }
            } 
            else {
                noReferrer = false;
                referrer = referrals[i];
                break;
            }
        }
        require(!noReferrer, "No Free Referrer");
        return referrer;
    }

    function getUserDetails(address _addr) public view returns (uint256, uint8[2] memory, uint256[3] memory, address[2] memory, address[] memory, address[] memory) {
        User storage account = users[_addr];
        Infinity storage infinity = users[_addr].infinityPool[_addr];
        GlobalPool storage matrix = users[_addr].matrixPool[_addr];

        return(
            account.id,
            [infinity.level, matrix.level],
            [infinity.levelIncome, matrix.poolIncome, infinity.directIncome],
            [infinity.referrer, account.referrer],
            account.referrals,
            infinity.referrals
        );
    }
    
    function isUserExists(address _addr) public view returns (bool) {
        return (users[_addr].id != 0);
    }

    function _processPayout(address _addr, uint _amount) private {
        if (!address(uint160(_addr)).send(_amount)) {
            address(uint160(owner)).transfer(_amount);
            return;
        }
    }
}