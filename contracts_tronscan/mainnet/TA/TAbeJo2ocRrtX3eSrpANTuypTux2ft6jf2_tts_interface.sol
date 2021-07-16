//SourceUnit: tts_interface.sol

pragma solidity ^0.5.4;



contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner; 
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Accessible is Ownable {

    mapping (address => bool) private hasAccess;

    event AddToAccessList (address addr);

    function giveAccess(address addr) public onlyOwner {
        hasAccess[addr] = true;
        emit AddToAccessList(addr);
    }

    function deleteAccess(address addr) public onlyOwner {
        hasAccess[addr] = false;
    }


    modifier onlyAccessor() {
        require(hasAccess[msg.sender], "caller cannot access this function!");
        _;
    }
}

contract TrustTron {
    function getInvestsStat(address addr) public view returns (uint256[] memory, uint256[] memory, uint256[] memory,bool[] memory,uint256);
}

contract TTS{
    function mint(address account, uint256 value) public;
}

contract tts_interface is Accessible{
    using SafeMath for uint256;


    address public TrustTronAddress;
    address public TokenContract;
    address private DWallet;
    address private MainWallet;

    constructor (address trustTronAddress, address TokenContractAddress, address devWallet, address mainWallet) public {
        TrustTronAddress = trustTronAddress;
        MainWallet = mainWallet;
        DWallet = devWallet;
        TokenContract = TokenContractAddress;
    }

    uint256 private decimals = 12;

    uint256 private startTime = 1601510478;
    uint256 private intervals = 15 days;

    uint256[] private Percets = [35 , 30 , 25 , 20 , 15 , 10];
    uint256 private ReinvestPercent = 50;

    uint256 public totalCalculatedInvest;
    uint256 public totalCalculatedReInvest;

    struct user{
        uint256 lastGetTokenTime;
        uint256 totalMintTokens;
        uint256 totalMintTokensWithDeposits;
        uint256 totalMintTokensWithReinvests;
        uint256 totalCalcualtedDeposits;
        uint256 totalCalcualtedReinvest;
        uint256 lastIndex;
    }

    mapping (address => user) private users;
    address[] private usersList;


    event Mint(address reciever , uint256 amount);

    function _calculateTokens(address addr ,uint256[] memory investedMoney, uint256[] memory startedTime, uint256 reinvestedMoney) private returns(uint256 userAmount){
        uint256 lastIndex = users[addr].lastIndex;
        uint256 totalDeposted = 0;
        uint256 i = 0;
        for (; lastIndex < investedMoney.length; lastIndex++) {
            i = 0;
            if (startedTime[lastIndex] > startTime)
                i = startedTime[lastIndex].sub(startTime).div(intervals);
            if (i > 5)
                i = 5;
            
            totalDeposted = totalDeposted.add(investedMoney[lastIndex]);
            userAmount = userAmount.add(investedMoney[lastIndex].mul(10**decimals).mul(Percets[i]).div(100));

        }

        users[addr].lastIndex = lastIndex;
        users[addr].totalCalcualtedDeposits = users[addr].totalCalcualtedDeposits.add(totalDeposted);
        totalCalculatedInvest = totalCalculatedInvest.add(totalDeposted);

        uint256 difAmount = reinvestedMoney.sub(users[addr].totalCalcualtedReinvest);
        users[addr].totalMintTokensWithDeposits = users[addr].totalMintTokensWithDeposits.add(userAmount);

        if(users[addr].totalCalcualtedDeposits.mul(6) <= users[addr].totalCalcualtedReinvest || difAmount == 0){
            return userAmount;
        }

        if(reinvestedMoney > users[addr].totalCalcualtedDeposits.mul(6)){
            reinvestedMoney = users[addr].totalCalcualtedDeposits.mul(6);
        }

        difAmount = reinvestedMoney.sub(users[addr].totalCalcualtedReinvest);
        users[addr].totalCalcualtedReinvest = users[addr].totalCalcualtedReinvest.add(difAmount);
        totalCalculatedReInvest = totalCalculatedReInvest.add(difAmount);

        uint256 userAmountReinvest = difAmount.mul(10**decimals).mul(ReinvestPercent).div(100);
        users[addr].totalMintTokensWithReinvests = users[addr].totalMintTokensWithReinvests.add(userAmountReinvest);

        return userAmount.add(userAmountReinvest);

    }

    function GetToken() public returns (uint256) {
        if(users[msg.sender].lastGetTokenTime == 0){
            usersList.push(msg.sender);
        }
        users[msg.sender].lastGetTokenTime = now;
        TrustTron t = TrustTron(TrustTronAddress);
        (uint256[] memory investedMoney, ,uint256[] memory startedTime , ,uint256 reinvestedMoney) = t.getInvestsStat(msg.sender);
        require(investedMoney.length > 0, "First invest in TrustTron!");

        uint256 userAmount = _calculateTokens(msg.sender ,investedMoney, startedTime ,reinvestedMoney);

        if(userAmount > 0){
            uint256 mainAmount = userAmount.mul(3).div(100);
            uint256 DAmount =  userAmount.mul(1).div(100);

            users[msg.sender].totalMintTokens = users[msg.sender].totalMintTokens.add(userAmount);
            users[DWallet].totalMintTokens = users[DWallet].totalMintTokens.add(DAmount);
            users[MainWallet].totalMintTokens = users[MainWallet].totalMintTokens.add(mainAmount);

            TTS tokenContract = TTS(TokenContract);
            tokenContract.mint(msg.sender, userAmount);
            tokenContract.mint(DWallet, DAmount);
            tokenContract.mint(MainWallet, mainAmount);

            emit Mint(msg.sender, userAmount);
            emit Mint(DWallet, DAmount);
            emit Mint(MainWallet, mainAmount);
        }

        return userAmount;
    }   

    function getStat(address addr) public view returns(uint256 lastGetTokenTime, uint256 totalMintTokens,uint256 reinvestTokens,uint256 depositTokens, uint256 totalCalcualtedDeposits, uint256 totalCalcualtedReinvest, uint256 calculatedDeposits) {
        return (users[addr].lastGetTokenTime ,users[addr].totalMintTokens , users[addr].totalMintTokensWithReinvests, users[addr].totalMintTokensWithDeposits,users[addr].totalCalcualtedDeposits ,users[addr].totalCalcualtedReinvest ,users[addr].lastIndex);
    }

    function getUsersList() public view onlyAccessor returns (address[] memory){
        return usersList;
    }
}