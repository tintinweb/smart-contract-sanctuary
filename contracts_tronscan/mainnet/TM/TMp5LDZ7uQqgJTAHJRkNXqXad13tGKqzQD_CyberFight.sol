//SourceUnit: CF.sol

/*! cyberfight.sol | (c) 2020 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | SPDX-License-Identifier: MIT License */

pragma solidity 0.5.12;

interface ICyberFight {
    enum Status { NEW, CANCEL, REJECTED, ACCEPTED, WIN, DEFEAT, DRAW }
    enum Action { HEAD, BODY, FOOT }

    function register() external;
    function challenge(address payable _enemy) external payable;
    function accept(uint256 _fight) external payable;
    function reject(uint256 _fight) external;
    // Debug
    function step(uint256 _fight, Action _attack, Action _protection) external;
    function points(uint8[] calldata _types, uint256[] calldata _amounts) external;

    function calcDamage(uint256 _fight) external view returns(uint256 user_damage, uint256 enemy_damage, bool last_enemy);
    function user(address _addr) external view returns(uint256 power, uint256 agility, uint256 intuition, uint256 stamina, uint256 experience, uint256 level, uint256 _points);
    function userStat(address _addr) external view returns(uint256 fight, uint256 _fights, uint256 wins, uint256 defeats, uint256 draws);
    function getFight(uint256 _fight) external view returns(address _user, address enemy, uint256 bet, Status status);
    function userFights(address _addr, Status _status, uint256 _offset, uint256 _limit) external view returns(uint256 matches, uint256[] memory id, address[] memory _user, address[] memory enemy, uint256[] memory bet);
}

contract Destructible {
    address payable public grand_owner;
    bool public grand_block;

    modifier onlyGrandOwner() {
        require(msg.sender == grand_owner, "Access denied (only grand owner)");
        _;
    }

    modifier notGrandBlock() {
        require(!grand_block, "Contract is blocked");
        _;
    }

    constructor() public {
        grand_owner = msg.sender;
    }

    function transferGrandOwnership(address payable _to) external onlyGrandOwner {
        grand_owner = _to;
    }

    function reGrandBlock() external onlyGrandOwner {
        grand_block = !grand_block;
    }

    function destruct() external onlyGrandOwner {
        selfdestruct(grand_owner);
    }
}

contract CyberFight is Destructible, ICyberFight {
    struct Fight {
        address payable user;
        address payable enemy;
        uint256 bet;
        Status status;
        Action[] attacks;
        Action[] protections;
    }

    struct User {
        uint256 power;
        uint256 agility;
        uint256 intuition;
        uint256 stamina;

        uint256 experience;
        uint256 level;
        uint256 points;

        uint256 wins;
        uint256 defeats;
        uint256 draws;

        uint256 fight;
        uint256[] fights;
    }

    uint8 public constant MAX_HEALTH = 20;

    address public croupier;
    
    mapping(address => User) public users;
    Fight[] public fights;
    
    modifier onlyRegister() {
        require(users[msg.sender].power > 0, "User not register");
        _;
    }

    modifier onlyCroupier() {
        require(msg.sender == croupier, "Only croupier");
        _;
    }

    modifier notInFight() {
        require(users[msg.sender].fight == 0, "User in fight");
        _;
    }
    
    constructor(address _croupier) public {
        croupier = _croupier;
    }

    function() payable external {
        revert();
    }
    
    function _send(address payable _addr, uint256 _value) private {
        if(_addr == address(0) || !_addr.send(_value)) {
            grand_owner.transfer(_value);
        }
    }

    function _experience(address _addr, uint256 _exp) private {
        users[_addr].experience += _exp;

        if(users[_addr].experience >= 500) {
            users[_addr].experience -= 500;
            users[_addr].level++;
            users[_addr].points += 5;
        }
    }

    function _finish(uint256 _fight) private returns(bool) {
        Fight storage fight = fights[_fight];

        (uint256 user_damage, uint256 enemy_damage,) = this.calcDamage(_fight);

        if(user_damage < MAX_HEALTH && enemy_damage < MAX_HEALTH) return false;

        users[fight.user].fight = 0;
        users[fight.enemy].fight = 0;

        if(user_damage >= MAX_HEALTH && enemy_damage >= MAX_HEALTH) {
            fight.status = Status.DRAW;

            users[fight.user].draws++;
            users[fight.enemy].draws++;

            _experience(fight.user, 100);
            _experience(fight.enemy, 100);

            _send(fight.user, fight.bet);
            _send(fight.enemy, fight.bet);
        }
        else if(user_damage >= MAX_HEALTH) {
            fight.status = Status.DEFEAT;
            
            users[fight.user].defeats++;
            users[fight.enemy].wins++;

            _experience(fight.enemy, 250);
            
            _send(fight.enemy, fight.bet * 2);
        }
        else {
            fight.status = Status.WIN;
            
            users[fight.user].wins++;
            users[fight.enemy].defeats++;

            _experience(fight.user, 250);

            _send(fight.user, fight.bet * 2);
        }

        return true;
    }

    function register() external notGrandBlock {
        require(users[msg.sender].power == 0, "User already exists");

        users[msg.sender].power = 5;
        users[msg.sender].agility = 5;
        users[msg.sender].intuition = 5;
        users[msg.sender].stamina = 5;
    }

    function challenge(address payable _enemy) external payable onlyRegister notInFight notGrandBlock {
        require(users[_enemy].power > 0, "Enemy not register");
        require(msg.value > 0, "Zero bet");

        Action[] memory attacks;
        Action[] memory protections;

        fights.push(Fight({
            user: msg.sender,
            enemy: _enemy,
            bet: msg.value,
            status: Status.NEW,
            attacks: attacks,
            protections: protections
        }));

        users[msg.sender].fights.push(fights.length - 1);
        users[_enemy].fights.push(fights.length - 1);
    }

    function accept(uint256 _fight) external payable onlyRegister notInFight notGrandBlock {
        Fight storage fight = fights[_fight];

        require(fight.status == Status.NEW, "Fight already start");
        require(fight.enemy == msg.sender, "This fight is not available to you");
        require(users[fight.user].fight == 0, "Enemy in fight");
        require(fight.bet == msg.value, "Invalid amount");
        
        fight.status = Status.ACCEPTED;
        
        users[fight.user].fight = _fight;
        users[fight.enemy].fight = _fight;
    }

    function reject(uint256 _fight) external onlyRegister {
        Fight storage fight = fights[_fight];

        require(fight.status == Status.NEW, "Fight already start");
        require(fight.user == msg.sender || fight.enemy == msg.sender, "This fight is not available to you");
        
        if(fight.user == msg.sender) {
            fight.status = Status.CANCEL;
            
            _send(msg.sender, fight.bet);
        }
        else {
            fight.status = Status.REJECTED;
        }
    }

    // Only debug
    function step(uint256 _fight, Action _attack, Action _protection) external onlyRegister {
        Fight storage fight = fights[_fight];

        require(fight.status == Status.ACCEPTED, "Fight is not accepted");
        require(fight.user == msg.sender || fight.enemy == msg.sender, "This fight is not available to you");
        
        bool is_enemy = msg.sender == fight.enemy;

        require((!is_enemy && fight.attacks.length % 2 == 0) || (is_enemy && fight.attacks.length % 2 == 1), "You have already made a move");

        fight.attacks.push(_attack);
        fight.protections.push(_protection);

        if(is_enemy) {
            _finish(_fight);
        }
    }

    function points(uint8[] calldata _types, uint256[] calldata _amounts) external onlyRegister notInFight {
        require(_types.length > 0 && _types.length == _amounts.length, "Bad data");

        for(uint256 i = 0; i < _types.length; i++) {
            require(_types[i] >= 0 && _types[i] <= 3, "Invalid type");
            require(_amounts[i] > 0 && users[msg.sender].points >= _amounts[i], "Invalid points amount");

            users[msg.sender].points -= _amounts[i];

            if(_types[i] == 0) users[msg.sender].power += _amounts[i];
            else if(_types[i] == 1) users[msg.sender].agility += _amounts[i];
            else if(_types[i] == 2) users[msg.sender].intuition += _amounts[i];
            else if(_types[i] == 3) users[msg.sender].stamina += _amounts[i];
        }
    }

    function playOut(uint256 _fight, Action[] calldata _attack, Action[] calldata _protection) external onlyCroupier {
        Fight storage fight = fights[_fight];

        require(fight.status == Status.ACCEPTED, "Fight is not accepted");
        require(_attack.length >= 2 && _attack.length % 2 == 0 && _attack.length == _protection.length, "Bad data");

        for(uint256 i = 0; i < _attack.length; i++) {
            fight.attacks.push(_attack[i]);
            fight.protections.push(_protection[i]);
        }

        require(_finish(_fight), "Bad data");
    }

    function calcDamage(uint256 _fight) external view returns(uint256 user_damage, uint256 enemy_damage, bool last_enemy) {
        Fight storage fight = fights[_fight];
        User storage user = users[fight.user];
        User storage enemy = users[fight.enemy];

        for(uint256 i = 0; i < fight.attacks.length; i++) {
            if(i % 2 == 0) {
                if(fight.attacks[i] != fight.protections[i + 1]) {
                    enemy_damage += user.power;
                }

                last_enemy = false;
            }
            else {
                if(fight.attacks[i] != fight.protections[i - 1]) {
                    user_damage += enemy.power;
                }

                last_enemy = true;
            }
        }
    }

    /*
        Only external call
    */
    function user(address _addr) external view returns(uint256 power, uint256 agility, uint256 intuition, uint256 stamina, uint256 experience, uint256 level, uint256 _points) {
        return (users[_addr].power, users[_addr].agility, users[_addr].intuition, users[_addr].stamina, users[_addr].experience, users[_addr].level, users[_addr].points);
    }

    function userStat(address _addr) external view returns(uint256 fight, uint256 _fights, uint256 wins, uint256 defeats, uint256 draws) {
        return (users[_addr].fight, users[_addr].fights.length, users[_addr].wins, users[_addr].defeats, users[_addr].draws);
    }

    function getFight(uint256 _fight) external view returns(address _user, address enemy, uint256 bet, Status status) {
        return (fights[_fight].user, fights[_fight].enemy, fights[_fight].bet, fights[_fight].status);
    }

    function userFights(address _addr, Status _status, uint256 _offset, uint256 _limit) external view returns(uint256 matches, uint256[] memory id, address[] memory _user, address[] memory enemy, uint256[] memory bet) {
        id = new uint256[](_limit);
        _user = new address[](_limit);
        enemy = new address[](_limit);
        bet = new uint256[](_limit);

        for(uint256 i = _offset; i < users[_addr].fights.length && i < _offset + _limit; i++) {
            if(fights[users[_addr].fights[i]].status == _status) {
                id[matches] = users[_addr].fights[i];
                _user[matches] = fights[users[_addr].fights[i]].user;
                enemy[matches] = fights[users[_addr].fights[i]].enemy;
                bet[matches++] = fights[users[_addr].fights[i]].bet;
            }
        }
    }
}