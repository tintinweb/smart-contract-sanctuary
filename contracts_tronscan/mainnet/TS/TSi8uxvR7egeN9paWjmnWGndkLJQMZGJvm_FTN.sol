//SourceUnit: FTN.sol

pragma solidity >=0.4.23 <0.6.0;

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
}

contract FTN {

    using SafeMath for uint256;

    struct Level {
        uint id;
        uint256 price;
        uint256 directIncome;
        uint256 levelIncome;
        uint256 autopoolIncome;
        bool active;
    }

    struct User {
        uint id;
        address payable account;
        uint sponsor;
        uint256 totalInvestment;
        uint256 totalEarning;
        uint8 currentLevel;
        uint32 referralCount;
        string referralCode;
    }

    struct Income {
        uint user_id;
        uint256 amount;
    }

    struct UserIncome {
        mapping(uint8 => Income[]) directIncomes;
        mapping(uint8 => Income[]) levelIncomes;
        mapping(uint8 => Income[]) sponsorIncomes;
        mapping(uint8 => Income[]) autopoolIncomes;
    }

    mapping(address => User) public investors;
    mapping(uint8 => Level) public levels;
    mapping(uint => address) public addressIds;
    mapping(string => uint) public userReferralCodes; // code => userid

    mapping(uint => UserIncome) private userIncomes;
    mapping(uint8 => uint8) private levelAutopoolIndex; // current AP position
    mapping(uint8 => uint) private levelAutopoolCount; // total AP count
    mapping(uint8 => uint[]) levelUserPriorities;

    uint private lastUserId = 2;
    uint private lastLevel = 14;
    address private readOnlyOwner;
    address private _owner;
    uint256 public totalInvestments = 0;
    string public name;

    // Event Logger
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DirectIncome(uint from_user_id, uint to_user_id, uint256 amount);
    event LevelIncome(uint from_user_id, uint to_user_id, uint256 amount);
    event AutopoolIncome(uint from_user_id, uint to_user_id, uint256 amount);
    event AdminAddressChanged(address prev, address current);

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyReadOwner() {
        require(_msgSender() == readOnlyOwner, "not allowed!");
        _;
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    constructor() public {
        _owner = _msgSender();
        readOnlyOwner = _msgSender();
        name = 'FTN';
        uint _price = 0 trx;
        uint _price_factor = 0 trx;
        for(uint8 i = 1; i <= uint8(14); i++) {
            if(i <= 2) {
                _price = _price + 90 trx;
            }else if(i > 2 && i <= 12) {
                if(i == 3) _price = 0 trx;
                _price = _price + 300 trx;
            }else{
                _price = _price + 3000 trx;
            }
            _price_factor = _price/3;
            levels[i] = Level(i, _price, _price_factor, _price_factor, _price_factor, true);
            // initiating level autopool variables
            levelAutopoolCount[i] = 0;
            levelAutopoolIndex[i] = 1;
        }

        User memory user = User(1, _msgSender(), uint(0), uint256(0), uint256(0), uint8(14), uint32(0), 'FASTRACK90');
        investors[_owner] = user;
        userReferralCodes["FASTRACK90"] = 1;
        addressIds[1] = _owner;
        UserIncome memory _income = UserIncome();
        userIncomes[1] = _income;
    }

    function updateAdminAddress(address payable _address) external onlyOwner {
        require(_address != address(0), "Ownable: new owner is the zero address");
        require(!isContract(_address), "E4 - contract not allowed");
        address prev = investors[addressIds[1]].account;
        emit AdminAddressChanged(prev, _address);
        User memory _user = investors[addressIds[1]];
        _user.account = _address;
        investors[_address] = _user;
        addressIds[1] = _address;
    }

    function() external payable {
        revert("Direct payment not allowed!");
        //initInvestment(_msgSender(), bytes32ToString(_msgData()));
    }

    function investInLevelX(uint8 levelId, string calldata sponsorCode, string calldata referralCode) external payable {
        require(levelId <= lastLevel, "E5 - invalid level");
        if(levelId == 1) {
            initInvestment(_msgSender(), sponsorCode, referralCode);
        }else{
            upgradeToLevelX(_msgSender(), levelId);
        }
    }

    function initInvestment(address payable investor, string memory sponsorCode, string memory referralCode) private {
        require(msg.value == 90 trx, "E1 - Min. investment start with 90 TRX");
        require(!isInvestorExist(investor), "E2 - Exist already, try upgrading level");
        require(isReferralCodeExist(sponsorCode), "E3 - invalid referral code");
        require(!isReferralCodeExist(referralCode), "E3 - referral code exit");
        require(!isContract(investor), "E4 - contract not allowed");

        uint sponsorId = userReferralCodes[sponsorCode];
        uint investmentAmount = uint256(msg.value);
        User memory user = User(lastUserId, investor, sponsorId, investmentAmount, uint256(0), uint8(1), uint32(0), referralCode);
        investors[investor] = user;
        addressIds[lastUserId] = investor;
        uint userId = lastUserId;
        //userAutopool[1][userId] = Autopool(0, false, 0);
        userReferralCodes[referralCode] = userId;
        UserIncome memory _income = UserIncome();
        userIncomes[userId] = _income;

        lastUserId++;
        Level memory _level = levels[1];

        // init user level AP FIFO
        levelUserPriorities[1].push(userId);
        investors[addressIds[sponsorId]].referralCount++;

        // send direct income to sponsor
        sendDirectIncome(investor, uint8(1), _level.directIncome);
        sendLevelIncome(userId, uint8(1),  _level.levelIncome);
        runAutoPool(uint8(1),  _level.autopoolIncome);
        totalInvestments = totalInvestments.add(_level.price);
    }

    function upgradeToLevelX(address investor, uint8 levelId) private {
        require(isInvestorExist(investor), "E6 - user not found. Register first");
        require(investors[investor].currentLevel == (levelId-1), "E7 - first upgrade previous levels");
        require(investors[investor].currentLevel < levelId, "E8 - already upgraded");
        Level memory _level = levels[levelId];
        require(_level.active, "E9 - this level is inactive");
        uint investmentAmount = uint256(msg.value);
        require(investmentAmount == _level.price, "E10 - invalid level price");

        uint userId = investors[investor].id;
        investors[investor].currentLevel = levelId;
        investors[investor].totalInvestment = investors[investor].totalInvestment.add(investmentAmount);
        //userAutopool[levelId][userId] = Autopool(0, false, 0);
        levelUserPriorities[levelId].push(userId);

        // update incomes
        sendDirectIncome(investor, levelId, _level.directIncome);
        sendLevelIncome(userId, levelId, _level.levelIncome);
        runAutoPool(levelId, _level.autopoolIncome);
        totalInvestments = totalInvestments.add(_level.price);
    }

    function runAutoPool(uint8 levelId, uint256 amount) private {
        uint8 currentAPIndex = levelAutopoolIndex[levelId];
        uint userId = levelUserPriorities[levelId][levelAutopoolCount[levelId]];
        uint payableId = 0;
        Income memory _income = Income(lastUserId-1, amount);
        if(currentAPIndex == 1 || currentAPIndex == 5 || currentAPIndex == 9 || currentAPIndex == 13) {
            // AP for Admin
            //userIncomes[1].autopoolIncomes.push(_income);
            userIncomes[1].autopoolIncomes[levelId].push(_income);
            investors[addressIds[1]].totalEarning = investors[addressIds[1]].totalEarning.add(amount);
            payableId = 1;
        }else if(currentAPIndex == 3 || currentAPIndex == 7 || currentAPIndex == 11 || currentAPIndex == 15) {
            // AP for sponsor
            uint sponsorId = investors[addressIds[userId]].sponsor;
            if(investors[addressIds[sponsorId]].currentLevel >= levelId) {
                //userIncomes[sponsorId].autopoolIncomes.push(_income);
                userIncomes[sponsorId].autopoolIncomes[levelId].push(_income);
                investors[addressIds[sponsorId]].totalEarning = investors[addressIds[sponsorId]].totalEarning.add(amount);
            }else{
                sponsorId = 2;
                //userIncomes[2].sponsorIncomes.push(_income);
                userIncomes[2].sponsorIncomes[levelId].push(_income);
                investors[addressIds[2]].totalEarning = investors[addressIds[2]].totalEarning.add(amount);
            }
            payableId = sponsorId;
        }else{
            // AP for user
            if(investors[addressIds[userId]].currentLevel >= levelId) {
                //userIncomes[userId].autopoolIncomes.push(_income);
                userIncomes[userId].autopoolIncomes[levelId].push(_income);
                investors[addressIds[userId]].totalEarning = investors[addressIds[userId]].totalEarning.add(amount);
                payableId = userId;
            }else{
                //userIncomes[2].sponsorIncomes.push(_income);
                userIncomes[2].sponsorIncomes[levelId].push(_income);
                investors[addressIds[2]].totalEarning = investors[addressIds[2]].totalEarning.add(amount);
                payableId = 2;
            }
        }
        // update auto pool count
        updateAutopoolStatus(levelId, currentAPIndex);
        emit AutopoolIncome(lastUserId-1, payableId, amount);
        transferEarning(payableId, amount);
    }

    function updateAutopoolStatus(uint8 levelId, uint8 currentAPIndex) private {
        if(currentAPIndex == 16) {
            levelAutopoolIndex[levelId] = 1;
            levelAutopoolCount[levelId]++;
        }else{
            levelAutopoolIndex[levelId]++;
        }
    }

    function sendLevelIncome(uint userId, uint8 levelId, uint amount) private {
        uint levelSponsorId = userId;
        for(uint i = levelId; i > 0; i--) {
            levelSponsorId = investors[addressIds[levelSponsorId]].sponsor;
            if(levelSponsorId == 0) {
                levelSponsorId = 1;
                break;
            }
        }
        address levelSponsorAddress = addressIds[levelSponsorId];
        uint payableId = levelSponsorId;
        Income memory _income = Income(userId, amount);
        if(levelSponsorId != 1 && investors[levelSponsorAddress].currentLevel >= levelId) {
            investors[levelSponsorAddress].totalEarning = investors[levelSponsorAddress].totalEarning.add(amount);
        }else{
            levelSponsorAddress = addressIds[2];
            payableId = 2;
            investors[levelSponsorAddress].totalEarning = investors[levelSponsorAddress].totalEarning.add(amount);
        }
        userIncomes[payableId].levelIncomes[levelId].push(_income);
        emit LevelIncome(userId, payableId, amount);
        transferEarning(payableId, amount);
    }

    function sendDirectIncome(address userAddress, uint8 levelId, uint amount) private {
        address sponsor = addressIds[investors[userAddress].sponsor];
        uint partnerId = investors[userAddress].id;
        uint payableId = investors[sponsor].id;
        Income memory _income = Income(partnerId, amount);
        if(investors[sponsor].currentLevel >= levelId) {
            //userIncomes[payableId].directIncomes.push(_income);
            investors[sponsor].totalEarning = investors[sponsor].totalEarning.add(amount);
        }else{
            sponsor = addressIds[2];
            payableId = 2;
            //userIncomes[payableId].directIncomes.push(_income);
            investors[sponsor].totalEarning = investors[sponsor].totalEarning.add(amount);
        }
        userIncomes[payableId].directIncomes[levelId].push(_income);
        emit DirectIncome(partnerId, payableId, amount);
        transferEarning(payableId, amount);
    }

    function transferEarning(uint payableId, uint amount) internal{
        investors[addressIds[payableId]].account.transfer(amount);
    }

    function updateReadOnlyAddress(address account) public onlyOwner {
        readOnlyOwner = account;
    }

    function isInvestorExist(address investor) public view returns (bool) {
        return investors[investor].id != 0;
    }

    function isReferralCodeExist(string memory sponsorCode) public view returns (bool) {
        return userReferralCodes[sponsorCode] != 0;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function stringLength(string memory str) internal pure returns (uint) {
        bytes memory bytesString = bytes(str);
        return bytesString.length;
    }

    function fetchDirectIncome(address _address, uint8 levelId, uint _index) public view returns(uint[] memory, uint256[] memory) {
        uint userId = investors[_address].id;
        uint _len = uint(userIncomes[userId].directIncomes[levelId].length);
        uint[] memory _users = new uint[](_len - _index);
        uint256[] memory _amount = new uint256[](_len - _index);
        for(uint i = _index; i < _len; i++) {
            _users[i - _index] = userIncomes[userId].directIncomes[levelId][i].user_id;
            _amount[i - _index] = userIncomes[userId].directIncomes[levelId][i].amount;
        }
        return (_users, _amount);
    }

    function fetchLevelIncome(address _address, uint8 levelId, uint _index) public view returns(uint[] memory, uint256[] memory) {
        uint userId = investors[_address].id;
        uint _len = uint(userIncomes[userId].levelIncomes[levelId].length);
        uint[] memory _users = new uint[](_len - _index);
        uint256[] memory _amount = new uint256[](_len - _index);
        for(uint i = _index; i < _len; i++) {
            _users[i - _index] = userIncomes[userId].levelIncomes[levelId][i].user_id;
            _amount[i - _index] = userIncomes[userId].levelIncomes[levelId][i].amount;
        }
        return (_users, _amount);
    }

    function fetchAPMIncome(address _address, uint8 levelId, uint _index) public view returns(uint[] memory, uint256[] memory) {
        uint userId = investors[_address].id;
        uint _len = uint(userIncomes[userId].autopoolIncomes[levelId].length);
        uint[] memory _users = new uint[](_len - _index);
        uint256[] memory _amount = new uint256[](_len - _index);
        for(uint i = _index; i < _len; i++) {
            _users[i - _index] = userIncomes[userId].autopoolIncomes[levelId][i].user_id;
            _amount[i - _index] = userIncomes[userId].autopoolIncomes[levelId][i].amount;
        }
        return (_users, _amount);
    }

    function fetchAPSIncome(address _address, uint8 levelId, uint _index) public view returns(uint[] memory, uint256[] memory) {
        uint userId = investors[_address].id;
        uint _len = uint(userIncomes[userId].sponsorIncomes[levelId].length);
        uint[] memory _users = new uint[](_len - _index);
        uint256[] memory _amount = new uint256[](_len - _index);
        for(uint i = _index; i < _len; i++) {
            _users[i - _index] = userIncomes[userId].sponsorIncomes[levelId][i].user_id;
            _amount[i - _index] = userIncomes[userId].sponsorIncomes[levelId][i].amount;
        }
        return (_users, _amount);
    }

    function fetchAPStatus(uint8 levelId) public view returns (uint8, uint) {
        return (levelAutopoolIndex[levelId], levelAutopoolCount[levelId]);
    }

    function addLevel(uint8 id, uint256 p, uint256 d, uint256 l, uint256 a) external onlyOwner {
        if(levels[id].id == 0) {
            levels[id] = Level(id, p, d, l, a, true);
        }else{
            levels[id].price = p;
            levels[id].levelIncome = l;
            levels[id].directIncome = d;
            levels[id].autopoolIncome = a;
        }
    }

    function adminInvestment(address payable _address, uint8 levelId, string calldata sponsorCode, string calldata referralCode) external payable onlyOwner{
        require(levelId <= lastLevel, "E5 - invalid level");
        if(levelId == 1) {
            initInvestment(_address, sponsorCode, referralCode);
        }else{
            upgradeToLevelX(_address, levelId);
        }
    }

}