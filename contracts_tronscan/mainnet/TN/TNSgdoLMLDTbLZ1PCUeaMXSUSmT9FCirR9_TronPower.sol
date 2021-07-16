//SourceUnit: TronPower.sol

pragma solidity 0.5.9;

contract TronPower {
    using SafeMath for uint256;

    struct Generator {
        uint256 cost;
        uint32 per_day;
    }

    struct Storage {
        uint256 cost;
        uint256 space;
    }

    struct Packages {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

    struct Player {
        address referral;
        uint256 last_withdraw;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 powr;

        uint256 storage_addon;

        // Referrals
        uint256 available_referral_rewards;

        mapping(uint8 => uint256) referral_rewards;
        mapping(uint8 => uint16) referral_count;

        mapping(uint8 => uint16) player_generators;
        mapping(uint8 => uint16) player_storages;
    }

    event NewGenerator(address indexed addr, uint8 generator_id, uint256 amount);
    event NewStorage(address indexed addr, uint8 storage_id, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    address payable owner;

    mapping(address => Player) public players;
    mapping(uint8 => Generator) public generators;
    mapping(uint8 => Storage) public storages;

    uint8[] referral_bonuses;

    uint256 global_total_investors;
    uint256 global_total_invested;
    uint256 global_total_withdrawn;
    uint256 global_referral_payout;
    uint256 global_powr_per_day;

    constructor() public {
        owner = msg.sender;

        generators[0] = Generator(25000000, 1000);
        generators[1] = Generator(100000000, 5000);
        generators[2] = Generator(250000000, 15000);
        generators[3] = Generator(1000000000, 80000);
        generators[4] = Generator(5000000000, 500000);
        generators[5] = Generator(12000000000, 1500000);

        storages[0] = Storage(91900000, 1000);
        storages[1] = Storage(600000000, 10000);
        storages[2] = Storage(2000000000, 100000);
        storages[3] = Storage(10000000000, 999999999999);

        referral_bonuses.push(80);
        referral_bonuses.push(50);
        referral_bonuses.push(30);
        referral_bonuses.push(20);
        referral_bonuses.push(10);
        referral_bonuses.push(10);
    }

    function buyGenerator(uint8 _generator, address _referral) external payable {
        require(msg.value >= 1e7, "Zero amount");
        require(_generator <= 5, "Unknown Generator");
        Player storage player = players[msg.sender];
        uint256 generator_cost = generatorCost(_generator, player.player_generators[_generator]);
        require(msg.value >= generator_cost, "Not enough TRX");

        _registerPlayer(msg.sender);
        _setReferral(msg.sender, _referral);
        _doInvestment(msg.sender, msg.value);
        player.player_generators[_generator]++;

        global_powr_per_day += generators[_generator].per_day;

        emit NewGenerator(msg.sender, _generator, msg.value);
    }

    function buyStorage(uint8 _storage, address _referral) external payable {
        require(msg.value >= 1e7, "Zero amount");
        require(_storage <= 3, "Unknown Storage");
        Player storage player = players[msg.sender];
        uint256 storage_cost = storageCost(_storage, player.player_storages[_storage]);
        require(msg.value >= storage_cost, "Not enough TRX");

        _registerPlayer(msg.sender);
        _setReferral(msg.sender, _referral);
        _doInvestment(msg.sender, msg.value);
        player.player_storages[_storage]++;

        emit NewStorage(msg.sender, _storage, msg.value);
    }

    function _registerPlayer(address _player) private {
        Player storage player = players[_player];
        if(player.player_storages[0] == 0){
            player.player_storages[0]++;
            player.last_withdraw = block.timestamp;
            global_total_investors += 1;
        }
    }

    function _doInvestment(address _player, uint256 _amount) private {
        _referralPayout(_player, _amount);
        _rolloverEarnings(_player);
        players[_player].total_invested += _amount;
        global_total_invested += _amount;
    }

    function _rolloverEarnings(address _player) private {
        Player storage player = players[_player];
        player.powr += playerEarnings(_player);
        if(player.powr > playerStorage(_player)){
            player.powr = playerStorage(_player);
        }
        player.last_withdraw = block.timestamp;
    }

    function _setReferral(address _addr, address _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;

            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                players[_referral].referral_count[i]++;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }

    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;
        if(_amount >= 5000000000){
            owner.transfer(_amount.mul(25).div(100));
        } else {
            owner.transfer(_amount.mul(10).div(100));
        }
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;
            uint256 bonus = _amount * referral_bonuses[i] / 1000;
            players[ref].referral_rewards[i] += bonus;
            players[ref].available_referral_rewards += bonus;
            ref = players[ref].referral;
        }
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _rolloverEarnings(msg.sender);
        require(player.powr > 0, "Zero amount");

        uint256 _withdraw = player.powr;
        if(_withdraw >= 100000000000){
            _withdraw = 100000000000;
            player.powr -= 100000000000;
        } else {
            player.powr = 0;
        }

        uint256 amount = _withdraw.mul(address(this).balance.div(10000000)).div(1000000);
        player.total_withdrawn += amount;
        global_total_withdrawn += amount;

        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function exchange() payable external {
        _rolloverEarnings(msg.sender);
        Player storage player = players[msg.sender];
        require(player.powr > 0, "Zero amount");

        player.storage_addon += ceil(player.powr.div(5), 1000000);
        player.powr = 0;
    }

    function withdrawReferral() payable external {
        Player storage player = players[msg.sender];
        require(player.available_referral_rewards > 0, "Zero amount");
        uint256 amount = player.available_referral_rewards;
        player.available_referral_rewards = 0;
        player.total_withdrawn += amount;
        global_total_withdrawn += amount;
        global_referral_payout += amount;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function contractInfo() view external returns(uint256 _investors, uint256 _invested, uint256 _withdrawn, uint256 _referral_payout, uint256 _powr_value){
        return (global_total_investors, global_total_invested, global_total_withdrawn, global_referral_payout, (address(this).balance.div(10000000)));
    }

    function playerInfo(address _player) view external returns(uint256 _total_invested, uint256 _total_withdrawn, uint16[] memory _referral_count, uint256[] memory _referral_rewards, uint256 _storage, uint256 _per_day) {
        Player storage player = players[_player];
        uint16[] memory __referral_count = new uint16[](6);
        uint256[] memory __referral_rewards = new uint256[](6);
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            __referral_count[i] = player.referral_count[i];
            __referral_rewards[i] = player.referral_rewards[i];
        }
        return (
            player.total_invested,
            player.total_withdrawn,
            __referral_count,
            __referral_rewards,
            playerStorage(_player),
            playerPerDay(_player)
        );
    }

    function playerPowr(address _player) view external returns(uint256 _powr) {
        return playerFullEarnings(_player);
    }

    function playerAvailableReferralRewards(address _player) view external returns(uint256 _earnings){
        return players[_player].available_referral_rewards;
    }

    function playerList(address _player) view external returns(uint16[] memory _generators, uint256[] memory _generators_cost, uint16[] memory _storages, uint256[] memory _storages_cost){
        Player storage player = players[_player];
        uint16[] memory __generators = new uint16[](6);
        uint256[] memory __generators_cost = new uint256[](6);
        uint16[] memory __storages = new uint16[](4);
        uint256[] memory __storages_cost = new uint256[](4);
        for(uint8 i = 0; i < 6; i++){
            __generators_cost[i] = generatorCost(i, player.player_generators[i]);
            __generators[i] = player.player_generators[i];
            if(i < 4){
                __storages_cost[i] = storageCost(i, player.player_storages[i]);
                __storages[i] = player.player_storages[i];
            }
        }
        return (__generators, __generators_cost, __storages, __storages_cost);
    }

    function contractStats() view external returns(uint256 _balance, uint256 _powr_per_day){
        return (
            address(this).balance,
            global_powr_per_day
        );
    }

    function generatorCost(uint8 _generator, uint16 _generator_count) private view returns(uint256 value) {
        uint256 _cost = generators[_generator].cost;
        for(uint16 i = 0; i < _generator_count; i++){
            _cost = _cost + _cost.div(10);
        }
        return ceil(_cost, 1000000);
    }

    function storageCost(uint8 _storage, uint16 _storage_count) private view returns(uint256 value) {
        uint256 _cost = storages[_storage].cost;
        for(uint16 i = 0; i < _storage_count; i++){
            _cost = _cost + _cost.div(10);
        }
        return ceil(_cost, 1000000);
    }

    function playerEarnings(address _player) private view returns(uint256 value) {
        return playerPerDay(_player).mul(1000000).mul(block.timestamp - players[_player].last_withdraw).div(86400);
    }

    function playerFullEarnings(address _player) private view returns(uint256 value) {
        uint256 earnings = players[_player].powr + playerEarnings(_player);
        uint256 max_storage = playerStorage(_player);
        if(earnings > max_storage){
            earnings = max_storage;
        }
        return earnings;
    }

    function playerPerDay(address _player) private view returns(uint256 value){
        uint256 _per_day;
        for(uint8 i = 0; i < 6; i++) {
            _per_day += (players[_player].player_generators[i] * generators[i].per_day);
        }
        return _per_day;
    }

    function playerStorage(address _player) private view returns(uint256 value) {
        uint256 _storage = players[_player].storage_addon;
        for(uint8 i = 0; i < 4; i++){
            _storage += (players[_player].player_storages[i] * (storages[i].space * 1000000));
        }
        return _storage;
    }

    function ceil(uint a, uint m) private pure returns (uint ) {
        return (a + m - 1) / m * m;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
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