pragma solidity ^0.4.22;

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyNewOwner() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner returns(bool) {
        emit OwnershipTransferred(owner, newOwner);        
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


contract Whitelist is Ownable {
    uint256 public count;
    using SafeMath for uint256;

    //mapping (uint256 => address) public whitelist;
    mapping (address => bool) public whitelist;
    mapping (uint256 => address) public indexlist;
    mapping (address => uint256) public reverseWhitelist;


    constructor() public {
        count = 0;
    }
    
    function AddWhitelist(address account) public onlyOwner returns(bool) {
        require(account != address(0));
        whitelist[account] = true;
        if( reverseWhitelist[account] == 0 ) {
            count = count.add(1);
            indexlist[count] = account;
            reverseWhitelist[account] = count;
        }
        return true;
    }

    function GetLengthofList() public view returns(uint256) {
        return count;
    }

    function RemoveWhitelist(address account) public onlyOwner {
        require( reverseWhitelist[account] != 0 );
        whitelist[account] = false;
    }

    function GetWhitelist(uint256 index) public view returns(address) {
        return indexlist[index];        
    }
    
    function IsWhite(address account) public view returns(bool) {
        return whitelist[account];
    }
}


contract Formysale is Ownable, Pausable, Whitelist {    
    uint256 public weiRaised;         // 현재까지의 Ether 모금액
    uint256 public personalMincap;    // 최소 모금 참여 가능 Ether
    uint256 public personalMaxcap;    // 최대 모금 참여 가능 Ether
    uint256 public startTime;         // 프리세일 시작시간
    uint256 public endTime;           // 프리세일 종료시간
    uint256 public exchangeRate;      // 1 Ether 당 SYNCO 교환비율
    uint256 public remainToken;       // 판매 가능한 토큰의 수량
    bool    public isFinalized;       // 종료여부

    uint256 public mtStartTime;       // 교환비율 조정 시작 시간
    uint256 public mtEndTime;         // 교환비율 조정 종료 시간


    mapping (address => uint256) public beneficiaryFunded; //구매자 : 지불한 이더
    mapping (address => uint256) public beneficiaryBought; //구매자 : 구매한 토큰

    event Buy(address indexed beneficiary, uint256 payedEther, uint256 tokenAmount);

    constructor(uint256 _rate) public { 
        startTime = 1532919600;           // 2018년 7월 30일 월요일 오후 12:00:00 KST    (2018년 7월 30일 Mon AM 3:00:00 GMT)
        endTime = 1534647600;             // 2018년 8월 19일 일요일 오후 12:00:00 KST    (2018년 8월 19일 Sun AM 3:00:00 GMT)
        remainToken = 6500000000 * 10 ** 18; // 6,500,000,000 개의 토큰 판매

        exchangeRate = _rate;
        personalMincap = (1 ether);
        personalMaxcap = (1000 ether);
        isFinalized = false;
        weiRaised = 0x00;
        mtStartTime = 28800;  //오후 5시 KST
        mtEndTime = 32400;    //오후 6시 KST
    }    

    function buyPresale() public payable whenNotPaused {
        address beneficiary = msg.sender;
        uint256 toFund = msg.value;     // 유저가 보낸 이더리움 양(펀딩 할 이더)

        // 현재 비율에서 구매하게 될 토큰의 수량
        uint256 tokenAmount = SafeMath.mul(toFund,exchangeRate);
        // check validity
        require(!isFinalized);
        require(validPurchase());       // 판매조건 검증(최소 이더량 && 판매시간 준수 && gas량 && 개인하드캡 초과)
        require(whitelist[beneficiary]);// WhitList 등록되어야만 세일에 참여 가능
        require(remainToken >= tokenAmount);// 남은 토큰이 교환해 줄 토큰의 양보다 많아야 한다.
                

        weiRaised = SafeMath.add(weiRaised, toFund);            //현재까지지 모금액에 펀딩금액 합산
        remainToken = SafeMath.sub(remainToken, tokenAmount);   //남은 판매 수량에서 구매량만큼 차감
        beneficiaryFunded[beneficiary] = SafeMath.add(beneficiaryFunded[msg.sender], toFund);
        beneficiaryBought[beneficiary] = SafeMath.add(beneficiaryBought[msg.sender], tokenAmount);

        emit Buy(beneficiary, toFund, tokenAmount);
        
    }

    function validPurchase() internal view returns (bool) {
        //보내준 이더양이 0.1 이상인지 그리고 전체 지불한 Ethere가 1,000을 넘어가는지 체크 
        bool validValue = msg.value >= personalMincap && beneficiaryFunded[msg.sender].add(msg.value) <= personalMaxcap;

        //현재 판매기간인지 체크 && 정비시간이 아닌지 체크 
        bool validTime = now >= startTime && now <= endTime && !checkMaintenanceTime();

        return validValue && validTime;
    }

    function checkMaintenanceTime() public view returns (bool){
        uint256 datetime = now % (60 * 60 * 24);
        return (datetime >= mtStartTime && datetime < mtEndTime);
    }

    function getNowTime() public view returns(uint256) {
        return now;
    }

    // Owner only Functions
    function changeStartTime( uint64 newStartTime ) public onlyOwner {
        startTime = newStartTime;
    }

    function changeEndTime( uint64 newEndTime ) public onlyOwner {
        endTime = newEndTime;
    }

    function changePersonalMincap( uint256 newpersonalMincap ) public onlyOwner {
        personalMincap = newpersonalMincap * (1 ether);
    }

    function changePersonalMaxcap( uint256 newpersonalMaxcap ) public onlyOwner {
        personalMaxcap = newpersonalMaxcap * (1 ether);
    }

    function FinishTokenSale() public onlyOwner {
        require(now > endTime || remainToken == 0);
        isFinalized = true;        
        owner.transfer(weiRaised); //현재까지의 모금액을 Owner지갑으로 전송.
    }

    function changeRate(uint256 _newRate) public onlyOwner {
        require(checkMaintenanceTime());
        exchangeRate = _newRate; 
    }

    function changeMaintenanceTime(uint256 _startTime, uint256 _endTime) public onlyOwner{
        mtStartTime = _startTime;
        mtEndTime = _endTime;
    }

    // Fallback Function. 구매자가 컨트랙트 주소로 그냥 이더를 쏜경우 바이프리세일 수행함
    function () public payable {
        buyPresale();
    }

}