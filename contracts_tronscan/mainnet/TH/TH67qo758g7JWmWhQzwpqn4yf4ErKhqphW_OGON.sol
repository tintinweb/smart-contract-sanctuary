//SourceUnit: OgonCash.sol

pragma solidity ^0.5.11;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IUSDT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function decimals() external view returns(uint8);
}

contract OGON is Ownable {

    using SafeMath for uint256;

    constructor(address _USDT, address payable _Boss) public Ownable(msg.sender){
        USDT = IUSDT(_USDT);
        state = State.startGame;
        Boss = _Boss;
    }

    struct User {
        uint256 rate;
    }

    modifier onlyBoss() {
        require(msg.sender == Boss, "You do not have access");
        _;
    }

    mapping (address => User) users;

    enum State { startGame, stopGame }

    IUSDT public USDT;

    address public last_investor;
    address public Boss;

    string public name = "OGON Cash";
    string public symbol = "OGON";

    uint256 public prize_fund;
    uint256 public last_invest_time;
    uint256 public betAmount = 5 * 1e6;
    uint256 public referralBalance;
    uint256 public timestop = 240 minutes;
    uint256 public ref_bonus = 20;
    uint256 public refstake = 0;

    bool launch;
    bool with;

    State public state;

    event Invested(address indexed user, uint256 amount);
    event PrizeWithdrawn(address indexed user, uint256 amount);
    event BossWasChanged(address Boss, address user);
    event SetParameters(uint betAmount, uint timestop, uint ref_bonus, uint refstake);
    event USDTWithdrawn(address Boss, uint amount);
    event AddFund(address sender, uint amount);

    function fund(uint256 _value) public {

        require(USDT.allowance(msg.sender, address(this)) >= betAmount, "Approve this token amount first");

        USDT.transferFrom(msg.sender, address(this), _value);

        prize_fund += _value;

        emit AddFund(msg.sender, _value);
    }

    function bet(address _ref) public {

        if(now > last_invest_time.add(timestop) && launch && !with){
            state = State.stopGame;
        }

        require(state == State.startGame, "State must be startGame");
        require(USDT.allowance(msg.sender, address(this)) >= betAmount, "Approve this token amount first");
        require(_ref != msg.sender, "You cannot list yourself as a referrer");

        if(_ref != address(0)){
            if(users[_ref].rate >= refstake){
                uint256 refAmount = betAmount.mul(ref_bonus).div(100);
                uint256 invAmount = betAmount.sub(refAmount);

                USDT.transferFrom(msg.sender, address(this), invAmount);
                USDT.transferFrom(msg.sender, _ref, refAmount);

                referralBalance += invAmount;
                last_investor = msg.sender;
                last_invest_time = now;

            } else {

                USDT.transferFrom(msg.sender, address(this), betAmount);

                referralBalance += betAmount;
                last_investor = msg.sender;
                last_invest_time = now;
            }

        } else if(_ref == address(0)) {

                uint256 refAmount = betAmount.mul(ref_bonus).div(100);
                uint256 invAmount = betAmount.sub(refAmount);

                USDT.transferFrom(msg.sender, address(this), invAmount);
                USDT.transferFrom(msg.sender, Boss, refAmount);

                referralBalance += invAmount;
                last_investor = msg.sender;
                last_invest_time = now;
        }

        users[msg.sender].rate += 1;
        launch = true;
        with = false;
        emit Invested(msg.sender, betAmount);

    }

    function getPrize() public {

        require(msg.sender == last_investor, "You must be the last investor");
        require(now > last_invest_time + timestop, "Timestop must pass");

        uint amount = prize_fund;

        USDT.transfer(msg.sender, amount);
        emit PrizeWithdrawn(msg.sender, prize_fund);

        prize_fund = 0;
        last_investor = address(0);
        last_invest_time = now;

        if(state == State.stopGame){
           state = State.startGame;
        }

        with = true;
    }

    function Switch() public onlyBoss {

        if(state == State.startGame){
            state = State.stopGame;
        } else {
            state = State.startGame;
        }
    }

    function deputeBoss(address _Boss) public {

        require(msg.sender == Boss || msg.sender == _owner, "You must be Boss");
        emit BossWasChanged(Boss, _Boss);

        Boss = _Boss;
    }

    function withdrawUSDT(uint256 _value) public onlyBoss {

        require(_value <= referralBalance);

        USDT.transfer(msg.sender, _value);

        referralBalance -= _value;
        emit USDTWithdrawn(Boss, _value);
    }

    function reFund(uint256 _value) public onlyBoss {

        require(_value <= referralBalance, "The value must be less than referralBalance");

        referralBalance -= _value;
        prize_fund += _value;
    }

    function setName(string memory _name) public onlyBoss returns(string memory){

        name = _name;

        return name;
    }

    function setSymbol(string memory _symbol) public onlyBoss returns(string memory){

        symbol = _symbol;

        return symbol;
    }

    function setParameters(uint256 _betAmount, uint256 _timestop, uint256 _ref_bonus, uint256 _refstake) public {

        require(msg.sender == _owner || msg.sender == Boss, "You must be Boss");
        require(_ref_bonus <= 100, "Referrer percentage must be less than 100");

        betAmount = _betAmount * 1e6;
        timestop = _timestop * 1 minutes;
        ref_bonus = _ref_bonus;
        refstake = _refstake;
        emit SetParameters(_betAmount, _timestop, _ref_bonus, _refstake);
    }

    function lastInvestor() public view returns(address) {

        return last_investor;
    }

    function prizeFund() public view returns(uint256) {

        return prize_fund;
    }

    function getLastInvestTime() public view returns(uint256) {

        return last_invest_time;
    }

    function getBetAmount() public view returns(uint256) {

        return betAmount;
    }

    function getRefstake() public view returns(uint256) {

        return refstake;
    }

    function getTimestop() public view returns(uint256) {

        return timestop;
    }

    function getRefbonus() public view returns(uint256) {

        return ref_bonus;
    }
}