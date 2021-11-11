//SourceUnit: TBoxPay.sol

pragma solidity 0.6.12;

contract Ownable {
    address public owner;

    constructor () public{
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

interface TetherToken {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract TBoxPay is Ownable {
    
    TetherToken public c_usdt = TetherToken(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

    struct User {
        uint64 id;
        uint64 bonus;
        address upline;
      
        uint80 totalPayAmount;
        uint80 totalStakeAmount;
        uint64 adaptAmount;
        uint32 lastAdaptTime;

        uint256 withdrawnAmount;
        uint256 withdrawnPay;
        uint256 userPay13;
    }

    mapping(address => User) public users; 
    mapping(uint64 => address) public id2Address;
    uint64 private next_userid = 2;

    address private projectAddress;

    uint32 private uplineRate = 87;
    uint32 private projectRate = 5;
    uint32 private dayReleaseRate = 30;

    mapping (uint8 => uint8) public refBonus;
    mapping (address => uint256) private _balances;

    uint256 totalPayIn;
    
    constructor(address _projectAddr, address firstAddr) public {
        refBonus[1] = 30;
        refBonus[2] = 10;
        refBonus[3] = 7;
        refBonus[4] = 5;
        refBonus[5] = 5;
        refBonus[6] = 5;
        refBonus[7] = 5;
        refBonus[8] = 5;
        refBonus[9] = 5;
        refBonus[10] = 5;
        refBonus[11] = 3;
        refBonus[12] = 3;
        refBonus[13] = 3;
        refBonus[14] = 3;
        refBonus[15] = 3;
        refBonus[16] = 2;
        refBonus[17] = 2;
        refBonus[18] = 2;
        refBonus[19] = 2;
        refBonus[20] = 2;

        projectAddress = _projectAddr;
        users[firstAddr].id = 1;
        id2Address[1] = firstAddr;
    }
    
    function register(address referrer) public {
        _register(msg.sender, referrer);
    }

    function _register(address addr, address referrer) private {
        require(!isUserExists(addr), "user already exist");
        require(isUserExists(referrer), "referrer not exists");
        users[addr].id = next_userid;
        users[addr].upline = referrer;
        users[addr].lastAdaptTime = uint32(block.timestamp);
        id2Address[next_userid] = addr;
        next_userid++;
    }
    
    function isUserExists(address addr) public view returns (bool) {
        return (users[addr].id != 0);
    }

    function pay(address addr, uint64 amount) public {
        require(isUserExists(addr), "addr not exists");
        c_usdt.transferFrom(msg.sender, address(this), amount); 

        uint256 uplineAmount = amount * uplineRate/100;
        _balances[addr] += uplineAmount;
        _balances[projectAddress] += amount * projectRate/100;

        uint64 interval = uint64((block.timestamp - users[addr].lastAdaptTime)/1 minutes);
        uint64 adaptAmount = getReleaseAmount(interval, users[addr].totalStakeAmount);
        users[addr].adaptAmount += adaptAmount;
        
        users[addr].totalStakeAmount = uint80(users[addr].totalStakeAmount - adaptAmount + amount - uplineAmount);
        users[addr].lastAdaptTime = uint32(block.timestamp);
        users[addr].userPay13 += amount - uplineAmount;

        
        if (!isUserExists(msg.sender)) {
            _register(msg.sender, addr);
        }
        
        interval = uint64((block.timestamp - users[msg.sender].lastAdaptTime)/1 minutes);
        adaptAmount = getReleaseAmount(interval, users[msg.sender].totalStakeAmount);
        users[msg.sender].adaptAmount += adaptAmount;
        
        users[msg.sender].totalStakeAmount = uint80(users[msg.sender].totalStakeAmount - adaptAmount + amount);
        users[msg.sender].lastAdaptTime = uint32(block.timestamp);
        users[msg.sender].totalPayAmount += amount;

        totalPayIn += amount;
    }

    function getReleaseAmount(uint64 intervalMinutes, uint80 stakeAmount) public view returns(uint64) {
        if (intervalMinutes == 0 || stakeAmount == 0) {
            return 0;
        }
        uint64 intervalDays = intervalMinutes/(24*60);
        if (intervalDays == 0) {
            return uint64(stakeAmount * dayReleaseRate * intervalMinutes/(100000*24*60));
        }

        uint64 amount = 0;
        for (uint64 i = 0; i < intervalDays; i++) {
            uint64 oneReleaseAmount = uint64(stakeAmount * dayReleaseRate/100000);
            amount += oneReleaseAmount;
            stakeAmount -= oneReleaseAmount;
        }

        amount += uint64((intervalMinutes-24*60*intervalDays)*stakeAmount*dayReleaseRate/(100000*24*60));
        return amount;
    }
    
    function withdraw() public {
        require(isUserExists(msg.sender), "addr not exists");
        uint64 interval = uint64((block.timestamp - users[msg.sender].lastAdaptTime)/1 minutes);
        uint64 adaptAmount = getReleaseAmount(interval, users[msg.sender].totalStakeAmount);

        uint64 withdrawableAmount = users[msg.sender].adaptAmount + adaptAmount;
        users[msg.sender].adaptAmount = 0;
        users[msg.sender].totalStakeAmount -= adaptAmount;
        users[msg.sender].lastAdaptTime = uint32(block.timestamp);

        _refPayout(msg.sender, withdrawableAmount);

        withdrawableAmount += users[msg.sender].bonus;
        c_usdt.transfer(msg.sender, withdrawableAmount);
        users[msg.sender].bonus = 0;

        users[msg.sender].withdrawnAmount += withdrawableAmount;
    }

    function _refPayout(address addr, uint64 amount) private {
        address up = users[addr].upline;
        for(uint8 i = 1; i < 21; i++) {
            if(up == address(0)) break;
            uint256 totalPay = users[up].totalPayAmount + users[up].userPay13;
            if( totalPay >= i*10**8) {
                users[up].bonus += amount * refBonus[i] / 100;
            }
            up = users[up].upline;
        }
    }

    function redeem() public {
        c_usdt.transfer(msg.sender, _balances[msg.sender]);
        users[msg.sender].withdrawnPay += _balances[msg.sender]; 
        _balances[msg.sender] = 0;
    }

    function setRefBonus(uint8 id, uint8 bonusRate) public onlyOwner() {
        refBonus[id] = bonusRate;
    }

    function setProjectAddress(address newProjectAddress) public onlyOwner() {
        projectAddress = newProjectAddress;
    }

    function setUSDTRate(uint32 newUplineRate, uint32 newProjectRate) public onlyOwner() {
        uplineRate = newUplineRate;
        projectRate = newProjectRate;
    }

    function setDayReleaseRate(uint32 newDayReleaseRate) public onlyOwner() {
        dayReleaseRate = newDayReleaseRate;
    }

    function migrateUser(address user, address upline, uint256 stakeAmount, uint256 reward, uint256 payAmount) public onlyOwner() {
        _register(user, upline);
        users[user].totalStakeAmount = uint80(stakeAmount);
        users[user].adaptAmount = uint64(reward);
        users[user].totalPayAmount = uint80(payAmount);
    }
    
    function contractInfo() public view returns(uint256, uint256, address, uint32, uint32, uint32, uint256) {
        return (c_usdt.balanceOf(address(this)), next_userid, projectAddress, uplineRate, projectRate, dayReleaseRate, totalPayIn);
    }

    function userInfo(address addr) public view returns(uint80, uint80, uint64, uint64, uint256, uint256) {
        uint64 interval;
        uint64 adaptAmount;
        if (users[addr].lastAdaptTime != 0){
            interval = uint64((block.timestamp - users[addr].lastAdaptTime)/1 minutes);
            adaptAmount = getReleaseAmount(interval, users[addr].totalStakeAmount);
        }
        return (users[addr].totalPayAmount, users[addr].totalStakeAmount, users[addr].adaptAmount+adaptAmount, users[addr].bonus, _balances[addr], users[addr].withdrawnAmount);
    }

    function userInfo2(address addr) public view returns(uint256, uint256) {
        return (users[addr].withdrawnPay, users[addr].userPay13);
    }
}