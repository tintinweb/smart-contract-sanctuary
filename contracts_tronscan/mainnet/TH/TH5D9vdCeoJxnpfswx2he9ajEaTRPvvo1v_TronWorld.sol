//SourceUnit: TronWorld.sol

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}
library DataStructs {
    struct DailyRound {
        uint256 startTime;
        uint256 endTime;
        bool ended; 
        uint256 pool; 
    }
    struct Player 
    {
        uint256 totalInvestment;
        uint256 totalVolumeTrx; 
        uint256 time;
        uint256 referralCount;
        uint256 interestProfit;
        uint256 overrideIncome;
        uint256 totalWithdraw;
        address payable referrer;
    }
    struct PlayerDailyRounds {
        uint256 selfInvestment; 
    }
    struct Leaderboard {
        uint256 amt;
        address addr;
    }
}
contract StorageStructure {
    using SafeMath for *;
    address public implementation;
    address payable public owner;
    address payable public houseFeeholder;
    address public roundStarter;
    uint256 public poolTime = 3 hours;
    

    uint public houseFee = 10;
    uint public companyPool = 2;
    uint public commissionDivisor = 100;
    uint public minuteRate = 1157408;
    uint public interestRateDivisor = 1000000000000;

    uint256 public totalOverDeposit = 0;
    uint256 public totalOverWithdraw = 0;
    uint256 public totalCommunity = 0;
    uint256 public roundID;

    mapping (address => bool) public playerExist;
    mapping (uint256 => DataStructs.DailyRound) public round;
    mapping (address => DataStructs.Player) public player;
    mapping (address => mapping (uint256 => DataStructs.PlayerDailyRounds)) public plyrRnds_; 
    
    uint public Levels = 6;
    uint public totalLevelIncome = 16;
    mapping(uint => uint) public levelIncome;
    
    
    uint public OverrideLevel = 5;
    uint public totalOverrideIncome = 24;
    mapping(uint => uint) public overrideIncome;

    DataStructs.Leaderboard public topInvestors;
    DataStructs.Leaderboard public lastTopInvestors;

    /****************************  EVENTS   *****************************************/

    event registerUserEvent(address indexed _playerAddress, address indexed _referrer, uint256 timeStamp);
    event investmentEvent(address indexed _playerAddress, uint256 indexed _amount, uint256 timeStamp);
    event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount,uint level, uint256 timeStamp, bool isExtra);
    event overrideRoiIncomeEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount,uint level, uint256 timeStamp, bool isExtra);
    event roundAwardsEvent(address indexed _playerAddress, uint256 indexed _amount, uint round);
    event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
    event ownershipTransferred(address indexed owner, address indexed newOwner);
}

contract TronWorld is StorageStructure {
    using SafeMath for *;
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    constructor(address _roundStarter, address payable _owner, address payable _feeHolder) public {
        
        levelIncome[1] = 10;
        levelIncome[2] = 2;
        levelIncome[3] = 1;
        levelIncome[4] = 1;
        levelIncome[5] = 1;
        levelIncome[6] = 1;

        overrideIncome[1] = 15;
        overrideIncome[2] = 5;
        overrideIncome[3] = 2;
        overrideIncome[4] = 1;
        overrideIncome[5] = 1;

        owner = _owner;
        houseFeeholder = _feeHolder;
        roundStarter = _roundStarter;

        roundID = 1;

        round[1].startTime = now;
        round[1].endTime = now + poolTime;

        playerExist[houseFeeholder] = true;
        player[houseFeeholder].time = now;
    }
    
    /**
     * @dev Upgrades the implementation address
     * @param _newImplementation address of the new implementation
     */
    function upgradeTo(address _newImplementation) 
        external onlyOwner 
    {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
    function getProfit(address _addr) public view returns (uint256) {
        uint secPassed = now.sub(player[_addr].time);
        if(secPassed > 0 && player[_addr].time > 0)
        {
            uint collectProfitGross = (player[_addr].totalInvestment.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
            uint256 collectProfitNet = collectProfitGross.add(player[_addr].interestProfit);

            return collectProfitNet;
        }
        else
        {
            return 0;
        }
    }
    function getRoundPendingTime() public view returns(uint) {
        uint remainingTimeForPayout = 0;
        if(round[roundID].endTime >= now) {
            remainingTimeForPayout = round[roundID].endTime.sub(now);
        }
        return remainingTimeForPayout;
    }
    /**
     * @dev Fallback function allowing to perform a delegatecall 
     * to the given implementation. This function will return 
     * whatever the implementation call returns
     */
    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    
    /**
     * @dev Sets the address of the current implementation
     * @param _newImp address of the new implementation
     */
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
    function transferOwnership(address payable newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address payable newOwner) private {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }
    function changeFeeHolder(address payable _newfeeHolder) external onlyOwner {
        require(_newfeeHolder != address(0), "New Feeholder cannot be the zero address");
        houseFeeholder = _newfeeHolder;
    }
    function changeRoundStarter(address payable _newRoundStarted) external onlyOwner {
        require(_newRoundStarted != address(0), "New Round Starter cannot be the zero address");
        roundStarter = _newRoundStarted;
    }
    
}