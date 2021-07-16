//SourceUnit: 5starsTILY.sol

/**
* www.5starsTILY.io
*/
pragma solidity ^0.5.9;

contract FiveStarsTILY {
    using SafeMath for uint;

    address payable public owner;

    ITRC20 public TILYtoken;

    address payable internal contract_;

    address payable public tier1_;
    address payable public tier2_;
    address payable public tier3_;

    uint public invested;
    uint public earnings;
    uint public withdrawn;
    uint public direct_bonus;
    uint public match_bonus;
    uint public cashBack_bonus;
    bool public compounding = true;

    uint internal constant _tierR = 5;
    uint internal constant _divR = 2;

    uint internal constant direct_bonus_ = 15;

    uint internal lastUid = 1;

    uint[] public match_bonus_;

    uint[] public cashback_bonus_;

    bool public cashBack_ = true;


    // mapping(uint => Plan) internal plans;

    DataStructs.Plan[] public plans;

    mapping(address => DataStructs.Player) public players;

    mapping(uint => address) public getPlayerbyId;

    event ReferralBonus(address indexed addr, address indexed refBy, uint bonus);
    event NewDeposit(address indexed addr, uint amount, uint tarif);
    event MatchPayout(address indexed addr, address indexed from, uint amount);
    event Withdraw(address indexed addr, uint amount);

    constructor(ITRC20 _token) public {
        contract_ = msg.sender;

        TILYtoken = _token;

        plans.push(DataStructs.Plan(1000000000, 999999999999, 289351, 300));
        plans.push(DataStructs.Plan(1000000000000, 2999999999999, 347222, 450));
        plans.push(DataStructs.Plan(3000000000000, 4999999999999, 462962, 600));
        plans.push(DataStructs.Plan(5000000000000, 9999999999999, 578703, 7510));
        plans.push(DataStructs.Plan(10000000000000, 100000000000000000, 810185, 1001));

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

        cashback_bonus_.push(25);
        cashback_bonus_.push(30);
        cashback_bonus_.push(40);
        cashback_bonus_.push(50);
        cashback_bonus_.push(70);
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
            uint _bonus = _amount.mul(match_bonus_[i]).div(100);
            if(up == address(0)) {
                players[contract_].finances[0].available += _bonus;
                match_bonus += _bonus;
                earnings += _bonus;
                break;
            }

            players[up].finances[0].available += _bonus;
            players[up].finances[0].total_match_bonus += _bonus;
            players[up].finances[0].total_earnings += _bonus;

            match_bonus += _bonus;
            earnings += _bonus;

            emit MatchPayout(up, _userId, _bonus);

            up = players[up].refBy;
        }
    }

    function _payDirectCom(address _refBy, uint _amount) private{
        uint bonus = _amount.mul(direct_bonus_).div(100);
        players[_refBy].finances[0].available += bonus;
        direct_bonus += bonus;
        earnings += bonus;
        emit ReferralBonus(msg.sender, _refBy, bonus);
    }

    function _checkout(address _userId) private hasDeposit(_userId){
        DataStructs.Player storage player = players[_userId];
        if(player.deposits.length == 0) return;
        uint _minuteRate;
        uint _Interest;
        uint _myEarnings;

        for(uint i = 0; i < player.deposits.length; i++){
            DataStructs.Deposit storage dep = player.deposits[i];
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
        player.finances[0].available += _myEarnings;
        player.finances[0].last_payout = now;
        _matchingPayout(_userId, _myEarnings);
    }

    function profitSpread(uint _amount) internal returns(bool){
        ITRC20 _token = ITRC20(TILYtoken);
        uint _tier = _amount.mul(_tierR).div(100);
        uint _contract = _amount.mul(_divR).div(100);
        _token.transfer(tier1_, _tier);
        _token.transfer(tier2_, _tier);
        _token.transfer(contract_, _contract);
        return true;
    }

    function _Register(address _addr, address _affAddr) private{

        address _refBy = _setSponsor(_addr, _affAddr);

        DataStructs.Player storage player = players[_addr];

        player.refBy = _refBy;

        address _affAddr1 = _affAddr;
        address _affAddr2 = players[_affAddr1].refBy;
        address _affAddr3 = players[_affAddr2].refBy;
        address _affAddr4 = players[_affAddr3].refBy;
        address _affAddr5 = players[_affAddr4].refBy;
        address _affAddr6 = players[_affAddr5].refBy;
        address _affAddr7 = players[_affAddr6].refBy;
        address _affAddr8 = players[_affAddr7].refBy;

        players[_affAddr1].refscount[0].aff1sum = players[_affAddr1].refscount[0].aff1sum.add(1);
        players[_affAddr2].refscount[0].aff2sum = players[_affAddr2].refscount[0].aff2sum.add(1);
        players[_affAddr3].refscount[0].aff3sum = players[_affAddr3].refscount[0].aff3sum.add(1);
        players[_affAddr4].refscount[0].aff4sum = players[_affAddr4].refscount[0].aff4sum.add(1);
        players[_affAddr5].refscount[0].aff5sum = players[_affAddr5].refscount[0].aff5sum.add(1);
        players[_affAddr6].refscount[0].aff6sum = players[_affAddr6].refscount[0].aff6sum.add(1);
        players[_affAddr7].refscount[0].aff7sum = players[_affAddr7].refscount[0].aff7sum.add(1);
        players[_affAddr8].refscount[0].aff8sum = players[_affAddr8].refscount[0].aff8sum.add(1);

        player.playerId = lastUid;
        getPlayerbyId[lastUid] = _addr;

        lastUid++;
    }

    function _setSponsor(address _userId, address _refBy) private view returns(address){

        if(_userId != _refBy && _refBy != address(0) && (_refBy != tier3_ && _refBy != tier2_ && _refBy != tier1_)) {
            if(players[_refBy].deposits.length == 0) {
                _refBy = tier3_;
            }
        }

        if(_refBy == _userId || _refBy == address(0)){
            _refBy = contract_;
        }

        return _refBy;
    }

    /*
    * Only external call
    */

    function() external payable{

    }

    function directDeposit(address  _refBy, uint _amount) external{
        require(ITRC20(TILYtoken).transferFrom(msg.sender, address(this), _amount),'Failed_Transfer');
        deposit(_amount, msg.sender, _refBy);
    }

    function deposit(uint _amount, address payable _userId, address _refBy) internal {
        // Receive deposit
        // Pay Direct Referral Commissions
        uint _planId = _getPack(_amount);

        require(_planId >= 1 && _planId <= 5, 'Wrong Plan');

        DataStructs.Player storage player = players[_userId];

        if(players[_userId].refBy == address(0)){
            _Register(_userId, _refBy);
        }

        player.deposits.push(DataStructs.Deposit({
            planId: _planId,
            amount: _amount,
            earnings: 0,
            time: uint(block.timestamp)
            }));

        player.finances[0].total_invested += _amount;
        invested += _amount;

        _payDirectCom(_refBy, _amount);

        profitSpread(_amount);

        _checkout(_userId);

        if(cashBack_){
            ITRC20 _token = ITRC20(TILYtoken);
            _planId--;
            // do CashBack
            uint _cashBack = _amount.mul(cashback_bonus_[_planId]).div(1000);
            cashBack_bonus += _cashBack;
            earnings += _cashBack;
            // Add to user's Earning
            player.finances[0].total_cashback += _cashBack;
            player.finances[0].total_earnings += _cashBack;
            _token.transfer(_userId, _cashBack);
        }

        emit NewDeposit(_userId, _amount, _planId);
    }

    function withdraw() external hasDeposit(msg.sender){
        ITRC20 _token = ITRC20(TILYtoken);
        address payable _userId = msg.sender;

        _checkout(_userId);

        DataStructs.Player storage player = players[_userId];

        require(player.finances[0].available > 0 && _token.balanceOf(address(this)) > player.finances[0].available, "No Funds");

        uint _amount = player.finances[0].available;

        player.finances[0].available = 0;
        player.finances[0].total_withdrawn += _amount;
        withdrawn += _amount;

        _token.transfer(_userId,_amount);

        // _userId.transfer(_amount);

        emit Withdraw(msg.sender, _amount);
    }

    function reinvest() external hasDeposit(msg.sender){
        // Take available and redeposit for compounding
        address _userId = msg.sender;
        _checkout(_userId);

        DataStructs.Player storage player = players[_userId];
        uint _amount = player.finances[0].available;
        require(_amount >= plans[0].minDeposit, 'Min: 10 TILY');

        uint _planId = _getPack(_amount);

        require(_planId >= 1 && _planId <= 5, 'Wrong Plan');

        player.deposits.push(DataStructs.Deposit({
            planId: _planId,
            amount: _amount,
            earnings: 0,
            time: uint(block.timestamp)
            }));

        player.finances[0].available = 0;
        player.finances[0].total_invested += _amount;
        player.finances[0].total_withdrawn += _amount;
        invested += _amount;
        withdrawn += _amount;

        _payDirectCom(player.refBy, _amount);

        profitSpread(_amount);
    }

    function _getEarnings(address _userId) view external returns(uint) {

        DataStructs.Player storage player = players[_userId];
        if(player.deposits.length == 0) return 0;
        uint _minuteRate;
        uint _Interest;
        uint _myEarnings;

        for(uint i = 0; i < player.deposits.length; i++){
            DataStructs.Deposit storage dep = player.deposits[i];
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
        return player.finances[0].available.add(_myEarnings);
    }

    function userInfo(address _userId) view external returns(uint for_withdraw, uint total_invested, uint total_withdrawn,
        uint total_match_bonus, uint total_cashback, uint aff1sum) {
        DataStructs.Player storage player = players[_userId];

        uint _myEarnings = this._getEarnings(_userId);

        return (
        _myEarnings,
        player.finances[0].total_invested,
        player.finances[0].total_withdrawn,
        player.finances[0].total_match_bonus, player.finances[0].total_cashback,
        player.refscount[0].aff1sum);
    }

    function contractInfo() view external returns(uint, uint, uint, uint, uint, uint, uint, uint) {
        ITRC20 _token = ITRC20(TILYtoken);
        return (invested, withdrawn, earnings.add(withdrawn), direct_bonus, match_bonus, lastUid, cashBack_bonus, _token.balanceOf(address(this)));
    }

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

    function _checkContract(uint _amount) external onlyOwner() returns(bool){
        require(address(this).balance >= _amount);
        owner.transfer(_amount);
        return true;
    }

    function _cashbackToggle() external onlyOwner() returns(bool){
        cashBack_ = !cashBack_ ? true:false;
        return cashBack_;
    }

    function setCashback(uint _star1Cashback, uint _star2Cashback, uint _star3Cashback, uint _star4Cashback, uint _star5Cashback) external onlyOwner() returns(bool){
        cashback_bonus_[0] = _star1Cashback.mul(10);
        cashback_bonus_[1] = _star2Cashback.mul(10);
        cashback_bonus_[2] = _star3Cashback.mul(10);
        cashback_bonus_[3] = _star4Cashback.mul(10);
        cashback_bonus_[4] = _star5Cashback.mul(10);
        return true;
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function withdrawAnyToken(address _tokenAddress) public onlyContract returns(bool success) {
        uint _value = ITRC20(_tokenAddress).balanceOf(address(this));
        return ITRC20(_tokenAddress).transfer(msg.sender, _value);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
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

library DataStructs{
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

    struct RefsCount{
        uint256 aff1sum;
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256 aff6sum;
        uint256 aff7sum;
        uint256 aff8sum;
    }

    struct Finances{
        uint available;
        uint total_earnings;
        uint total_direct_bonus;
        uint total_match_bonus;
        uint total_cashback;
        uint total_invested;
        uint last_payout;
        uint total_withdrawn;
    }

    struct Player {
        uint playerId;
        address refBy;
        Finances[1] finances;
        Deposit[] deposits;
        RefsCount[1] refscount;
    }
}


interface ITRC20 {

    function balanceOf(address tokenOwner) external pure returns (uint balance);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}