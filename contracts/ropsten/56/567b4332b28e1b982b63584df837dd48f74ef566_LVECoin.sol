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
    
    // _from => oldOwner
    // _to => newOwner
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public{
        owner = msg.sender;
    }

    // Modifier onlyOwner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Transfer owner
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
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
        require(!paused);
        _;
    }
    modifier whenPaused {
        require(paused);
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


/**
 * @title Dealershipable
 */
contract Dealershipable is Ownable {

    mapping(address => bool) public dealerships;
    // _to => add new dealer address
    event TrustDealer(address _to);
    // _to => remove dealer address
    event DistrustDealer(address _to);

    // Different contract onlyDealer
    modifier onlyDealers() {
        require(dealerships[msg.sender]);
        _;
    }

    // Add new dealer address dealer
    function trustDealer(address _newDealer) public onlyOwner {
        require(_newDealer != address(0));
        require(!dealerships[_newDealer]);
        dealerships[_newDealer] = true;
        emit TrustDealer(_newDealer);
    }

    // Remove dealer address dealer
    function disTrustDealer(address _dealer) public onlyOwner {
        require(_dealer != address(0));
        require(dealerships[_dealer]);
        dealerships[_dealer] = false;
        emit DistrustDealer(_dealer);
    }

}


/**
 * @title ERC20 interface
 */
contract ERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    // _from => _owner
    // _to   => _spender
    event Approval(address indexed _from, address indexed _to, uint256 _amount);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}


/**
 * @title ERC20Token
 */
contract ERC20Token is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 public totalToken;

    function totalSupply() public view returns (uint256) {
        return totalToken;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // Transfer token by internal
    function _transfer(address _from, address _to, uint256 _value) internal {
        // not invalid address
        require(_from != address(0));
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        // not invalid address 
        require(_from != address(0));
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool){
        // not invalid address
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        // not invalid address
        require(_owner != address(0));
        require(_spender != address(0));
        return allowed[_owner][_spender];
    }

}


/**
 * @title LVECoin
 */
contract LVECoin is ERC20Token, Pausable, Dealershipable {

    string public  constant name        = &quot;LVECoin&quot;;
    string public  constant symbol      = &quot;LVE&quot;;
    uint256 public constant decimals    = 18;
    // issue all token(20億)
    uint256 private initialToken        = 2000000000 * (10 ** decimals);
    
    // _to => _locker
    event Lock(address indexed _to, uint256 _amount, uint _endTime);
    // _to => _unlocker
    event UnLock(address indexed _to, uint256 _amount);
    // _to => _freezeAddr
    event Freeze(address indexed _to);
    // _to => _unfreezeAddr
    event Unfreeze(address indexed _to);
    event WithdrawalEther(address indexed _to, uint256 _amount);


    // Locked accouonts
    struct LockedAccount{
        uint256 endTime;    // token locked end time
        address addr;       // locked address
        bool isLocked;      // is lock address
        uint256 lockAmount; // locked token amount
    }

    // locked address struct mapping
    mapping(address => LockedAccount) public lockedAccountMap;
    // freeze account mapping
    mapping(address => bool) public freezeAccountMap;
    // investor address list
    address[] public lockerList;
    

    // FoundingTeam Percent(10%)
    uint256 private foundingTeamToken;
    // Company Percent(90%)
    uint256 private companyToken;
    
    // FoundingTeam Address
    address private foundingTeamAddr;
    // Company Address
    address private companyAddr;
    // wallet Address
    address private walletAddr;


    constructor() public{
        totalToken = initialToken;
        
        // FoundingTeam Percent(10%)
        foundingTeamToken = totalToken.mul(100).div(1000);
        // Company Percent(90%)
        companyToken = totalToken.mul(900).div(1000);

        // FoundingTeam Address
        foundingTeamAddr = 0xbfdF7e215ff6e5aC382bebAd3406527933cE56E7;
        // Company Address
        companyAddr = msg.sender;
        walletAddr = msg.sender;

        // FoundingTeam Token
        balances[foundingTeamAddr] = foundingTeamToken;
        // Company Token
        balances[companyAddr] = companyToken;

        // Locked warehouse
        uint256 endTime = now + 30 minutes;
        addlockAccount(foundingTeamAddr, endTime, foundingTeamToken);

        emit Transfer(0x0, foundingTeamAddr, foundingTeamToken);
        emit Transfer(0x0, companyAddr, companyToken);
    }



    // distribution token
    function distributeToken(address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0);
        _transfer(msg.sender, _to, _amount);
    }


    // is exceed lockEnd time
    modifier transferable(address _addr) {
        //is can release
        LockedAccount memory lockedAccount = lockedAccountMap[_addr];
        //  lock
        if (lockedAccount.isLocked && now > lockedAccount.endTime) {
            lockedAccount.endTime = 0;
            lockedAccount.isLocked = false;
            lockedAccount.lockAmount = 0;
            lockedAccountMap[_addr] = lockedAccount;
        }
        require(!lockedAccount.isLocked);
        _;
    }
    // is exceed lockEnd time
    modifier freezeable(address _addr) {
        require(!freezeAccountMap[_addr]);
        _;
    }


    // locked warehouse function 
    function addlockAccount(address _lockAddr, uint256 _endTime, uint256 _lockAmount) internal returns(bool){
        require(_lockAddr != address(0));
        require(_endTime >= now);
        require(_lockAmount > 0);
        if(lockedAccountMap[_lockAddr].addr != _lockAddr){
            lockerList.push(_lockAddr);
        }
        LockedAccount memory lockedAccount;
        lockedAccount.endTime = _endTime;
        lockedAccount.addr = _lockAddr;
        lockedAccount.isLocked = true;
        lockedAccount.lockAmount = lockedAccountMap[_lockAddr].lockAmount.add(_lockAmount);
        lockedAccountMap[_lockAddr] = lockedAccount;
        emit Lock(_lockAddr, _lockAmount, _endTime);
        return true;
    }


    function transfer(address _to, uint256 _value) public whenNotPaused transferable(msg.sender) freezeable(msg.sender) returns (bool) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public transferable(msg.sender) freezeable(msg.sender) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) public whenNotPaused transferable(msg.sender) freezeable(msg.sender) returns (bool) {
        return super.approve(_spender, _value);
    }


    // freeze account
    function freezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0));
        freezeAccountMap[_freezeAddr] = true;
        emit Freeze(_freezeAddr);
        return true;
    }
    
    // unfreeze account
    function unfreezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0));
        freezeAccountMap[_freezeAddr] = false;
        emit Unfreeze(_freezeAddr);
        return true;
    }

    // get single locker information
    function getSingleLocker(address _addr) public view returns(uint256 _rEndTime, address _rAddr, bool _rIsLocked, uint256 _rLockAmount){
        require(_addr != address(0));
        LockedAccount memory locker = lockedAccountMap[_addr];
        return(locker.endTime, locker.addr, locker.isLocked, locker.lockAmount);
    }

    // unlock address
    function unLockBatchAddr() public onlyOwner returns (bool){   
        // count locker nums
        uint256 lockerCount = lockerList.length;
        require(lockerCount > 0);
        for (uint256 i = 0; i < lockerCount; i++) {
            address lockerAddr = lockerList[i];
            LockedAccount memory locker = lockedAccountMap[lockerAddr];
            if(locker.isLocked && now > locker.endTime && !freezeAccountMap[locker.addr]){
                locker.endTime = 0;
                locker.isLocked = false;
                locker.lockAmount = 0;
                lockedAccountMap[locker.addr] = locker;
                emit UnLock(locker.addr, locker.lockAmount);
            }
        }
        return true;
    }

    // if send ether then send ether to owner
    function() public payable {
        require(msg.value > 0);
        walletAddr.transfer(msg.value);
        emit WithdrawalEther(walletAddr, msg.value);
    }

}