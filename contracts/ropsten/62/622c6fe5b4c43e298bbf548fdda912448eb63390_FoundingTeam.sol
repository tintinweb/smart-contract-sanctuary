pragma solidity ^0.4.24;

// *-----------------------------------------------------------------------*
//       __ _    ________   __________  _____   __
//      / /| |  / / ____/  / ____/ __ \/  _/ | / /
//     / / | | / / __/    / /   / / / // //  |/ / 
//    / /__| |/ / /___   / /___/ /_/ // // /|  /  
//   /_____/___/_____/   \____/\____/___/_/ |_/  
// *-----------------------------------------------------------------------*


/**
 * @title SafeMath
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 */
contract Ownable {

    address public owner;
    
    // _from: oldOwner _to: newOwner
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public{
        owner = msg.sender;
    }

    // Modifier onlyOwner
    modifier onlyOwner {
        require(msg.sender == owner, "");
        _;
    }

    // Transfer owner
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
 * @title Pausable
 */
contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused {
        require(!paused, "");
        _;
    }
    modifier whenPaused {
        require(paused, "");
        _;
    }

    // Pause contract
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    // Unpause contract
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }

}


interface LVECoin {
    function transfer(address _to, uint256 _value) external returns(bool);
    function balanceOf(address _owner) external view returns (uint256);
}


/**
 * @title FoundingTeam
 */
contract FoundingTeam is Pausable {

    using SafeMath for uint256;

    // token contract
    LVECoin private tokenContract;
    // token issue all amount
    uint256 private totalToken              = 2000000000 * (10 ** 18);
    // token supply amount
    uint256 public  tokenSupplyQuota        = totalToken.mul(50).div(1000);
    // lock end time
    uint256 public tokenLockEndTime;
    // alreary sold token
    uint256 public tokensSold               = 0;


    // Investor list
    struct Investor{
        uint256 endTime;        // token locked end time
        address addr;           // locked address
        bool isLocked;          // is lock address
        uint256 lockAmount;     // locked token amount
        uint256 investAmount;   // invest token amount
    }
    // investor mapping
    mapping(address => Investor) public investorMap;
    // freeze account mapping
    mapping(address => bool) public freezeAccountMap;
    // investor address list
    address[] public investorsList;

    // _to: _locker
    event Lock(address indexed _to, uint256 _amount, uint _endTime);
    // _to: _unlocker
    event UnLock(address indexed _to, uint256 _amount);
     // _to: _freezeAddr
    event Freeze(address indexed _to);
    // _to: _unfreezeAddr
    event Unfreeze(address indexed _to);
    event WithdrawalToken(address indexed _to, uint256 _amount);
    event WithdrawalEther(address indexed _to, uint256 _amount);

    constructor(address _tokenAddr, uint256 _tokenLockEndTime) public{
        require(_tokenAddr != address(0), "");
        require(_tokenLockEndTime > now, "");
        tokenLockEndTime = _tokenLockEndTime;
        tokenContract = LVECoin(_tokenAddr);
    }

    
    // is token on sale
    modifier isOnSale() {
        // 供給總Token額度 > 目前已售出token數量 => true, 販售中
        require(tokenSupplyQuota > tokensSold, "");
        _;
    }
    // is freezeable account
    modifier freezeable(address _addr) {
        require(_addr != address(0), "");
        require(!freezeAccountMap[_addr], "");
        _;
    }


    // get contract own token amount
    function getContractTokenBalance() public view returns(uint256 _rContractTokenAmount){
        return tokenContract.balanceOf(address(this));
    }

   
    // transfer token and lock
    function transferTokenAndLock(address _beneficiary, uint256 _amount) public onlyOwner isOnSale freezeable(_beneficiary){
        require(_beneficiary != address(0), "");
        // 目前已售出token數量
        tokensSold = tokensSold.add(_amount);
        // 判斷是否有超過總供給Token額度
        require(tokenSupplyQuota >= tokensSold, "");
        // add investor token locktime
        addlockAccount(_beneficiary, tokenLockEndTime, _amount);
    }


    // locked warehouse function 
    function addlockAccount(address _lockAddr, uint256 _endTime, uint256 _lockAmount) internal returns(bool){
        require(_lockAddr != address(0), "");
        require(_endTime >= now, "");
        require(_lockAmount > 0, "");
        if(investorMap[_lockAddr].addr != _lockAddr){
            investorsList.push(_lockAddr);
        }
        Investor memory investor;
        investor.endTime = _endTime;
        investor.addr = _lockAddr;
        investor.isLocked = true;
        investor.lockAmount = investorMap[_lockAddr].lockAmount.add(_lockAmount);
        investor.investAmount = investorMap[_lockAddr].investAmount.add(_lockAmount);
        investorMap[_lockAddr] = investor;

        emit Lock(_lockAddr, _lockAmount, _endTime);
        return true;
    }

    // freeze account
    function freezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0), "");
        freezeAccountMap[_freezeAddr] = true;
        emit Freeze(_freezeAddr);
        return true;
    }
    
    // unfreeze account
    function unfreezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0), "");
        freezeAccountMap[_freezeAddr] = false;
        emit Unfreeze(_freezeAddr);
        return true;
    }



    // get single investor invest information
    function getSingleInvestor(address _addr) public view returns(uint256 _rEndTime, address _rAddr, bool _rIsLocked, uint256 _rLockAmount, uint256 _rInvestAmount){
        require(_addr != address(0), "");
        Investor memory investor = investorMap[_addr];
        return(investor.endTime, investor.addr, investor.isLocked, investor.lockAmount, investor.investAmount);
    }

    // get investor count
    function getInvestorCount() public view returns(uint256 _rInvestorCount){
        return investorsList.length;
    }

    // get investor address
    function getInvestorAddr(uint256 _index) public view returns(address _rInvestorAddr){
        return investorsList[_index];
    }

    // after tokenLockEndTime owner Token
    function withdrawTokenToInvestorOwner(address _investorAddr) public onlyOwner returns(bool){
        require(_investorAddr != address(0), "");
        require(now > tokenLockEndTime, "");
        Investor memory investor = investorMap[_investorAddr];
        if(investor.isLocked && now > investor.endTime && !freezeAccountMap[investor.addr]){
            require(tokenContract.transfer(investor.addr, investor.lockAmount), "");
            emit WithdrawalToken(investor.addr, investor.lockAmount);
            investor.endTime = 0;
            investor.isLocked = false;
            investor.lockAmount = 0;
            investorMap[investor.addr] = investor;
            emit UnLock(investor.addr, investor.lockAmount);
        }
        return true;
    }

    // after tokenLockEndTime batch Token
    function withdrawBatchTokenToInvestor() public onlyOwner returns(bool){
        require(now > tokenLockEndTime, "");
        // count investor nums
        uint256 investorCount = getInvestorCount();
        require(investorCount > 0, "");
        for (uint256 i = 0; i < investorCount; i++) {
            address investorAddr = investorsList[i];
            Investor memory investor = investorMap[investorAddr];
            if(investor.isLocked && now > investor.endTime && !freezeAccountMap[investor.addr]){

                require(tokenContract.transfer(investor.addr, investor.lockAmount), "");
                emit WithdrawalToken(investor.addr, investor.lockAmount);
                investor.endTime = 0;
                investor.isLocked = false;
                investor.lockAmount = 0;
                investorMap[investor.addr] = investor;
                emit UnLock(investor.addr, investor.lockAmount);
            }
        }
        return true;
    }

    // recycling Remain Token to wallet address
    function recyclingRemainToken() public onlyOwner whenNotPaused returns(bool){
        require(now > tokenLockEndTime, "");
        uint256 remainToken = tokenSupplyQuota.sub(tokensSold);
        require(remainToken > 0, "");
        require (tokenContract.transfer(msg.sender, remainToken), "");
        pause();
        return true;   
    }

}