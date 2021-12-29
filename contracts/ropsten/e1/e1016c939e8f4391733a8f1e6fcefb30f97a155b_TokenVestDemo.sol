/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}
contract TokenVestDemo{
    using SafeMath for uint256;
    IERC20 public investedToken;
    uint256 public releaseInterval;
    uint256 public lockingPeriod;
    uint256 public releasePer;
    IERC20 public token3;

    address payable public owner;

    uint256 public totalAddedToken;
    uint256 public totalReleasedToken;
    uint256 public RemainToken;
    uint256 public totalInvestor;
    uint256 public percentDivider;
    uint256 public minimumLimit;

    struct InvestToken {
        uint256 lockedtilltime;
        uint256 investtime;
        uint256 amount;
        uint256 completewithdrawtill;
        uint256 persecondLimit;
        uint256 lastWithdrawalTime;
        uint256 totalWithdrawal;
        uint256 remainWithdrawal;
        uint256 releaseinterval;
        uint256 releaseperperinterval;
        bool withdrawan;
    }

    struct User {
        uint256 totalInvestedTokenUser;
        uint256 totalWithdrawedTokenUser;
        uint256 investCount;
        bool alreadyExists;
    }

    mapping(address => User) public Investors;
    mapping(uint256 => address) public InvesterID;
    mapping(address => mapping(uint256 => InvestToken)) public investorRecord;

    event INVEST(address Investors, uint256 amount);
    event RELEASE(address Investors, uint256 amount);


    modifier onlyowner() {
        require(owner == msg.sender, "only owner");
        _;
    }
    constructor(address payable _owner, address token1) {
        owner = _owner;
        investedToken = IERC20(token1);
        lockingPeriod = 365 days;
        releaseInterval = 30 days;
        releasePer = 50;
        percentDivider = 1000;
        minimumLimit = 1e20;
    }

    function invest(uint256 amount) public {
       
        require(amount >= minimumLimit, "invest more than minimum amount");
    
        if (!Investors[msg.sender].alreadyExists) {
            Investors[msg.sender].alreadyExists = true;
            InvesterID[totalInvestor] = msg.sender;
            totalInvestor++;
        }

        investedToken.transferFrom(msg.sender, address(this), amount);

        uint256 index = Investors[msg.sender].investCount;
        Investors[msg.sender].totalInvestedTokenUser = Investors[msg.sender]
            .totalInvestedTokenUser
            .add(amount);
        totalAddedToken = totalAddedToken.add(amount);
        RemainToken = RemainToken.add(amount);
        investorRecord[msg.sender][index].lockedtilltime = block.timestamp.add(
            lockingPeriod
        );
        investorRecord[msg.sender][index].investtime = block.timestamp;
        investorRecord[msg.sender][index].amount = amount;
        investorRecord[msg.sender][index].completewithdrawtill = investorRecord[msg.sender][index].lockedtilltime.add((percentDivider.div(releasePer)).mul(releaseInterval));
        investorRecord[msg.sender][index].lastWithdrawalTime = 0;
        investorRecord[msg.sender][index].totalWithdrawal = 0;
        investorRecord[msg.sender][index].remainWithdrawal = amount;

        investorRecord[msg.sender][index].releaseinterval = releaseInterval;
        investorRecord[msg.sender][index].releaseperperinterval = releasePer;

        investorRecord[msg.sender][index].persecondLimit = amount.div((percentDivider.div(releasePer)).mul(releaseInterval));

        Investors[msg.sender].investCount++;

        emit INVEST(msg.sender, amount);
    }

    function releaseToken(uint256 index) public {
        require(
            !investorRecord[msg.sender][index].withdrawan,
            "already withdrawan"
        );
        require(
            investorRecord[msg.sender][index].lockedtilltime < block.timestamp,
            "cannot release token before locked duration"
        );

        uint256 releaseLimitTillNow;
        uint256 commontimestamp;
        (releaseLimitTillNow,commontimestamp) = realtimeReleasePerBlock(msg.sender , index);
        
        investedToken.transfer(
            msg.sender,
            releaseLimitTillNow
        );

        totalReleasedToken = totalReleasedToken.add(
            releaseLimitTillNow
        );
        RemainToken = RemainToken.sub(releaseLimitTillNow);
        
        investorRecord[msg.sender][index].lastWithdrawalTime =  commontimestamp;
        
        investorRecord[msg.sender][index].totalWithdrawal = investorRecord[msg.sender][index].totalWithdrawal.add(releaseLimitTillNow);

        investorRecord[msg.sender][index].remainWithdrawal = investorRecord[msg.sender][index].remainWithdrawal.sub(releaseLimitTillNow);

        Investors[msg.sender].totalWithdrawedTokenUser = Investors[msg.sender].totalWithdrawedTokenUser.sub(releaseLimitTillNow);

        if(investorRecord[msg.sender][index].remainWithdrawal == investorRecord[msg.sender][index].amount){
            investorRecord[msg.sender][index].withdrawan = true;

        }

        emit RELEASE(
            msg.sender,
            releaseLimitTillNow
        );
    }

    function realtimeReleasePerBlock(address user, uint256 blockno) public view returns (uint256,uint256) {

        uint256 ret;
        uint256 commontimestamp;
            if (
                !investorRecord[user][blockno].withdrawan &&
                investorRecord[user][blockno].lockedtilltime < block.timestamp
            ) {
                uint256 val;
                uint256 tempwithdrawaltime = investorRecord[user][blockno].lastWithdrawalTime;
                commontimestamp = block.timestamp;
                if(tempwithdrawaltime == 0){
                    tempwithdrawaltime = investorRecord[user][blockno].lockedtilltime;
                }
                val = commontimestamp - tempwithdrawaltime;
                val = val.mul(investorRecord[user][blockno].persecondLimit);
                if (val < investorRecord[user][blockno].remainWithdrawal) {
                    ret += val;
                } else {
                    ret += investorRecord[user][blockno].remainWithdrawal;
                }
            }
        return (ret,commontimestamp);
    }


    function SetReleaseInterval(uint256 val) external onlyowner {
        releaseInterval = val;
    }
    function SetReleasePercentage(uint256 val) external onlyowner {
        releasePer = val;
    }
    function SetLockingPeriod(uint256 val) external onlyowner {
        lockingPeriod = val;
    }

    function withdrawBaseCurrency() public onlyowner {
        uint256 balance = address(this).balance;
        require(balance > 0, "does not have any balance");
        payable(msg.sender).transfer(balance);
    }

    function initToken(address addr) public onlyowner{
        token3 = IERC20(addr);
    }
    function withdrawToken(uint256 amount) public onlyowner {
        token3.transfer(msg.sender
        , amount);
    }

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}