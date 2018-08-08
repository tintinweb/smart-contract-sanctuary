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
    constructor() public{
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // TODO:新增各種不同的方案擁有者

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

    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }
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

    mapping(address => bool) public dealership;

    event Trust(address dealer);
    event Distrust(address dealer);

    // 不同方案合約呼叫使用
    modifier onlyDealers() {
        require(dealership[msg.sender]);
        _;
    }

    function trust(address _newDealer) public onlyOwner {
        require(_newDealer != address(0));
        require(!dealership[_newDealer]);
        dealership[_newDealer] = true;
        emit Trust(_newDealer);
    }

    function disTrust(address _dealer) public onlyOwner {
        require(dealership[_dealer]);
        dealership[_dealer] = false;
        emit Distrust(_dealer);
    }

}





/**
 * @title ERC20
 */
contract ERC20 {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);

    // [自行轉帳]
    function transfer(address _to, uint256 _value) public returns (bool);
    // [代理轉帳]
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    // [授權用]
    function approve(address _spender, uint256 _value) public returns (bool);
    // [查詢剩餘的授權金額]
    function allowance(address _owner, address _spender) public view returns (uint256);

}


/**
 * @title ERC20Token
 */
contract ERC20Token is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalToken;

    function totalSupply() public view returns (uint256){
        return totalToken;
    }
    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool){
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }
}


/**
 * @title LVECoin
 */
contract LVECoinDemo is ERC20Token, Pausable, Dealershipable {

    // Token name
    string public  constant name                = "LVECoinDemo";
    // Token symbol
    string public  constant symbol              = "LVEDemo";
    // 位數
    uint256 public constant decimals            = 18;
    // 總Token發行量(20億)
    uint256 public initialToken                 = 2000000000 * (10 ** decimals);


    event Mint(address indexed dealer, address indexed to, uint256 value);
    event Burn(address indexed _burner, uint256 _value);
    event Lock(address indexed locker, uint256 value, uint releaseTime);
    event UnLock(address indexed unlocker, uint256 value);
    


    // 鎖倉結束時間
    mapping(address => uint256) public releaseTimes;
    // 鎖倉Address
    mapping(address => bool) public lockAddresses;
    // 鎖倉狀態
    struct LockStatus{
        uint256 releaseTime;
        address lockAddr;
        bool isLock;
    }
    LockStatus[] public lockStatus;

    // 比例分配
    // *----------- 非公開發行(私募) -----------*
    // 私人配售(Private sale) - 40%
    uint256 public privatePlacingToken  = initialToken * 400 / 1000;
    // 創始團隊 - 20%
    uint256 public foundingTeamToken    = initialToken * 200 / 1000;
    // *----------- 公開發行(公募) -----------*
    // 公開發售(Crowdsale) - 40%
    uint256 public crowdsaleToken        = initialToken * 400 / 1000;


    
    // 持有人地址
    // *----------- 非公開發行(私募) -----------*
    // 私人配售Address
    address public  privatePlacingAddr  = 0x9089612b984A1eC4B34EefF78B9Df5fC955130CF;
    // 創始團隊Address
    address public  foundingTeamAddr    = 0x708ce7c6d547Cbd4C7fD889619c50e9d55471ED7;
    // *----------- 公開發行(公募) -----------*
    // 公開發售(Crowdsale)Address
    address public  crowdsaleAddr       = 0xC1903bA9032F5C163Fe0881Ed360c499F226975b;



    constructor() public{
        // 發行量
        totalToken = initialToken;
        // init transfer all token to owner
        balances[msg.sender] = totalToken;

        // *----------- 非公開發行(私募) -----------*
        // 創始團隊
        // 持有量
        balances[foundingTeamAddr] = foundingTeamToken;
        // 鎖倉
        lockAddresses[foundingTeamAddr] = true;
        // 解鎖時間
        releaseTimes[foundingTeamAddr] = 1531728000; // 2018-07-16 16:00:00

        LockStatus memory lockPerson;
        lockPerson.releaseTime = 1531728000;
        lockPerson.lockAddr = foundingTeamAddr;
        lockPerson.isLock = true;
        lockStatus.push(lockPerson);

        // 私人配售(Private sale)
        balances[privatePlacingAddr] = privatePlacingToken;

        // *----------- 公開發行(公募) -----------*
        // 公開發售(Crowdsale)Address
        balances[crowdsaleAddr] = crowdsaleToken;

        emit Transfer(0x0, foundingTeamAddr, foundingTeamToken);
        emit Transfer(0x0, privatePlacingAddr, privatePlacingToken);
        emit Transfer(0x0, crowdsaleAddr, crowdsaleToken);

    }


    // 是否過閉鎖期
    modifier transferable(address _addr) {
        require(!lockAddresses[_addr]);
        _;
    }


    // |----------------------------------
    // | @ERC20標準
    // |----------------------------------
    function transfer(address _to, uint256 _value) public whenNotPaused transferable(msg.sender) returns (bool) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public transferable(msg.sender) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) public whenNotPaused transferable(msg.sender) returns (bool) {
        return super.approve(_spender, _value);
    }



    // |----------------------------------
    // | @ custom function
    // |----------------------------------
    // 不同方案調用
    function mintLVE(address _to, uint256 _amount, uint256 _releaseTime) public whenNotPaused onlyDealers returns(bool){

        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        // 鎖倉
        lockAddresses[_to] = true;
        // 解鎖時間
        releaseTimes[_to] = _releaseTime;

        // set new strct
        LockStatus memory lockPerson;
        lockPerson.releaseTime = _releaseTime;
        lockPerson.lockAddr = _to;
        lockPerson.isLock = true;
        // push array
        lockStatus.push(lockPerson);

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    //取得解鎖時間
    function getUnlockTime(address _addr) public view returns (uint256) {
        return releaseTimes[_addr];
    }


    // 解倉
    function unlockAddr() public onlyOwner {
        //  取得目前所有鎖倉struct
        uint256 lockStatusLength = lockStatus.length;
        for (uint i = 0; i < lockStatusLength; i++) {
              LockStatus memory lockPerson = lockStatus[i];
              if (now > lockPerson.releaseTime) {
                  lockPerson.isLock = false;
                  lockAddresses[lockPerson.lockAddr] = false;
                  releaseTimes[lockPerson.lockAddr] = 0;
              }
        }
    }

}