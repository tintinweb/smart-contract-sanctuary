//SourceUnit: NB_Mining.sol

pragma solidity ^0.4.23;

contract TRC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract TRC20 is TRC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NB_Mining {

    using SafeMath for uint256;

    modifier canMine() {
        require(openMining == true, "mining paused!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "owner calls only!");
        _;
    }

    modifier canWithdraw() {
      require(openWithdraw == true, "withdraw  paused!");
      require(blacklist[msg.sender] == false, "withdraw  blacklisted!");
      _;
    }

    event Withdraw(address who, uint256 amount, uint256 time);
    event Active(address who, uint256 refcode, uint256 time);

    struct Player {
      uint256 uid;
      uint256 time;
      uint256 refCode;
      uint256 affCount;
      uint256 repairTime;
      uint256 interestProfit;
      address affFrom;
    }

    struct Rank {
      address addr;
      uint256 affCount;
    }

    uint256 constant private TRON = 1000000;
    uint256 constant private repairPeriod = 1 days; //1 days
    uint256 public totalPlayers;
    uint256 public totalPayout;
    uint256 public baseRate = 694; //2.5 NB / hour
    uint256 public rateMultiplier = 5; //5%
    uint256 public REF_CODE = 88888;
    uint256 public dividends = 0;
    uint256 public minWithdrawAmount = 0;

    TRC20 public nbToken_;

    uint256 private transactionFee = 5 * TRON;

    bool private openMining = true;
    bool private openWithdraw = true;

    address private owner;

    mapping(address => Player) public address2player;
    mapping(uint256 => address) public uid2address;
    mapping(address => bool) public blacklist;

    constructor(TRC20  _nbToken) public {
      nbToken_ = _nbToken;
      owner = msg.sender;
      uid2address[REF_CODE] = owner;
      address2player[owner] = Player(REF_CODE,now, REF_CODE, 0, now, 0,owner);
    }

    function register(address _addr, uint256 _refCode) private{
      REF_CODE = REF_CODE.add(8);
      address _affAddr = uid2address[_refCode];

      address2player[_addr] = Player(REF_CODE,now, _refCode, 0, now, 0, _affAddr);

      collect(_affAddr);
      address2player[_affAddr].affCount = address2player[_affAddr].affCount.add(1);
      uid2address[REF_CODE] = _addr;
    }

    function () external payable {

    }

    function activate(uint256 _refCode) public payable canMine() {
        require(msg.value == transactionFee, "incorrect transactionFee!");
        require(address2player[msg.sender].time == 0, "already registered!");

        dividends = dividends.add(transactionFee);
        totalPlayers++;
        if(_refCode <= REF_CODE  && address2player[uid2address[_refCode]].uid > 0){
          register(msg.sender, _refCode);
        }
        else{
          _refCode = 88888;
          register(msg.sender, _refCode);
        }

        if(totalPlayers >= 10000) {
          baseRate = 347;
        }
        if(totalPlayers >= 50000) {
          baseRate = 174;
        }
        if(totalPlayers >= 250000) {
          baseRate = 87;
        }
        if(totalPlayers >= 1250000) {
          baseRate = 44;
        }
        if(totalPlayers >= 10000000) {
          openMining = false;
          baseRate = 0;
        }

        emit Active(msg.sender, _refCode, now);
    }

    function withdraw() public payable canWithdraw(){
      require(msg.value == transactionFee, "incorrect transactionFee!");
      dividends = dividends.add(transactionFee);

      collect(msg.sender);
      require(address2player[msg.sender].interestProfit >= minWithdrawAmount, "have not reached minWithdrawAmount!");

      transferPayout(msg.sender, address2player[msg.sender].interestProfit);

    }

    function repair() public payable canMine() returns (bool){
      require(msg.value == transactionFee, "incorrect transactionFee!");
      dividends = dividends.add(transactionFee);

      collect(msg.sender);
      Player storage player = address2player[msg.sender];
      player.repairTime = now;
      return true;
    }


    function collect(address _addr) internal {
        Player storage player = address2player[_addr];
        require(player.repairTime <= player.time &&  now >= player.time, "Error: computing time wrong!");
        uint256 secPassed = 0;
        if(player.repairTime > 0 && player.repairTime.add(repairPeriod) >= now){
            secPassed=now.sub(player.time);
        }
        else if(player.repairTime > 0 && player.repairTime.add(repairPeriod) >= player.time){
            secPassed=(player.repairTime.add(repairPeriod)).sub(player.time);
        }
        else{
            secPassed = 0;
        }

        uint256 rate = baseRate.add((player.affCount).mul(baseRate).div(20));
        uint256 collectProfit = secPassed.mul(rate);
        player.interestProfit = player.interestProfit.add(collectProfit);
        player.time = now;
    }

    function transferPayout(address _receiver, uint256 _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint256 contractBalance = nbToken_.balanceOf(address(this));
            if (contractBalance > 0) {
                uint256 payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = address2player[_receiver];
                player.interestProfit = player.interestProfit.sub(payout);

                nbToken_.transfer(_receiver, payout);

                if(totalPayout >= 21000000000000){
                  openMining = false;
                  openWithdraw = false;
                }

                emit Withdraw(_receiver,payout, now);
            }
        }
    }

    function getProfit(address _addr) public view returns (uint256, bool) {
      Player storage player = address2player[_addr];
      require(player.repairTime <= player.time &&  now >= player.time, "Error: computing time wrong!");
      uint256 secPassed = 0;
      if(player.repairTime > 0 && player.repairTime.add(repairPeriod) >= now){
          secPassed=now.sub(player.time);
      }
      else if(player.repairTime > 0 && player.repairTime.add(repairPeriod) >= player.time){
          secPassed=(player.repairTime.add(repairPeriod)).sub(player.time);
      }
      else{
          secPassed = 0;
      }

      uint256 rate = baseRate.add((player.affCount).mul(baseRate).div(20));
      uint256 collectProfit = secPassed.mul(rate);

      return (collectProfit.add(player.interestProfit), player.repairTime.add(repairPeriod) >= now);
    }

    function contractBalance() public view returns (uint256, uint256) {
      return (address(this).balance, nbToken_.balanceOf(address(this)));
    }

    function validateReferrer(uint256 refCode) public view returns (bool) {
      return address2player[uid2address[refCode]].uid > 0;
    }

    /*************************************
    ******** OWNER FUNCTION CALLS ********
    *************************************/

    function setMinWithdrawAmount(uint256 amount) public onlyOwner returns (bool){
      minWithdrawAmount = amount;
      return true;
    }

    function setContractStatus(bool status) public onlyOwner returns (bool){
      openMining = status;
      return true;
    }

    function setWithdrawStatus(bool status) public onlyOwner returns (bool){
      openWithdraw = status;
      return true;
    }

    function setTransactionFee(uint256 amount) public onlyOwner returns (bool){
      transactionFee = amount;
      return true;
    }

    function distributeDividends(uint256 amount) public onlyOwner returns (bool){
      require(address(this).balance >= amount, "!invalid withdraw amount");
      owner.transfer(amount);
      if(amount >= dividends){
        dividends = 0;
      }
      else{
        dividends = dividends.sub(amount);
      }
      return true;
    }

    function withdrawToken(uint256 amount) public onlyOwner returns (bool){
      require(nbToken_.balanceOf(address(this)) >= amount, "!invalid NB withdraw amount");
      nbToken_.transfer(owner, amount);
      return true;
    }

    function exit() public onlyOwner returns (bool) {
      nbToken_.transfer(owner, nbToken_.balanceOf(address(this)));
      owner.transfer(address(this).balance);
      return true;
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