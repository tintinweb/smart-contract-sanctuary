/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BattleRoyale{
    uint256 public SIZE;
    address owner;

    enum Direction {North, East, South, West}

    modifier onlyInitialisedPlayers {
        require(players[msg.sender].initialised, "Must be playing");
        _;
    }

    event PlayerSpawned(address _player, uint256 _x, uint256 _y);
    event PlayerKilled(address _victim, address _killer);
    event PlayerAttacked(address _victim, uint256 health);
    event PlayerExited(address _player);
    event PlayerMoved(address _player, uint256 _x, uint256 _y);
    event PlayerCollected(address _player, uint256 _x, uint256 _y);
    event lootDropped(uint256 amount, uint256 _x, uint256 _y);

    struct Player {
        uint256 x;
        uint256 y;
        bool initialised;
        Direction facing;
        uint256 health;
        uint256 wealth;
    }

    mapping(address => Player) public players;
    mapping(uint => uint) public drops;

    constructor(uint16 _size){
        SIZE = _size;
        owner = msg.sender;
    }

    function move(Direction _d)
    public 
    onlyInitialisedPlayers {
        if(_d == Direction.North){
            require(players[msg.sender].y < SIZE - 1);
            players[msg.sender].y += 1;
            players[msg.sender].facing = Direction.North;
        }
        if(_d == Direction.South){
            require(players[msg.sender].y > 0);
            players[msg.sender].y -= 1;
            players[msg.sender].facing = Direction.South;
        }
        if(_d == Direction.East){
            require(players[msg.sender].x < SIZE - 1);
            players[msg.sender].x += 1;
            players[msg.sender].facing = Direction.East;
        }
        if(_d == Direction.West){
            require(players[msg.sender].x > 0);
            players[msg.sender].x -= 1;
            players[msg.sender].facing = Direction.West;
        }
        emit PlayerMoved(msg.sender, players[msg.sender].x, players[msg.sender].y);
    }

    function exit(address payable _to)
    public
    onlyInitialisedPlayers {
        //Require player is at an exit
        require((players[msg.sender].x == SIZE/2 && players[msg.sender].y == 0) ||
                (players[msg.sender].x == SIZE/2 && players[msg.sender].y == SIZE - 1) ||
                (players[msg.sender].y == SIZE/2 && players[msg.sender].x == 0) ||
                (players[msg.sender].y == SIZE/2 && players[msg.sender].x == SIZE - 1));
        _to.transfer(players[msg.sender].wealth);
        players[msg.sender].initialised = false;
        emit PlayerExited(msg.sender);

    }

    function spawn()
    public
    payable {
        require(players[msg.sender].initialised == false, "Cannot already be playing");
        require(msg.value == 0.001 ether);
        players[msg.sender] = _getRandomLocation();
        emit PlayerSpawned(msg.sender, players[msg.sender].x, players[msg.sender].y);
    }

    function attack(address victim)
    public
    onlyInitialisedPlayers {
        //Require player is facing the victim
        require((players[msg.sender].x == players[victim].x &&
                players[msg.sender].y + 1 == players[victim].y &&
                players[msg.sender].facing == Direction.North) ||
                (players[msg.sender].x == players[victim].x &&
                players[msg.sender].y == players[victim].y + 1 &&
                players[msg.sender].facing == Direction.South) ||
                (players[msg.sender].x + 1 == players[victim].x &&
                players[msg.sender].y == players[victim].y &&
                players[msg.sender].facing == Direction.East) ||
                (players[msg.sender].x == players[victim].x + 1 &&
                players[msg.sender].y == players[victim].y &&
                players[msg.sender].facing == Direction.West));

        players[victim].health -= 5;
        emit PlayerAttacked(victim, players[victim].health);
        if(players[victim].health <= 0){
            _spread(players[victim].wealth);
            players[victim].initialised = false;
            emit PlayerKilled(victim, msg.sender);
        }
    }

    function collect()
    public
    onlyInitialisedPlayers {
        uint256 location = players[msg.sender].x + (players[msg.sender].y * SIZE);
        players[msg.sender].wealth += drops[location];
        drops[location] = 0;
        emit PlayerCollected(msg.sender, players[msg.sender].x, players[msg.sender].y);

    }

    function _spread(uint256 amount)
    private {
        uint256 seed = uint256(blockhash(block.number - 1));
        uint256 numberofdrops = SIZE / 10;
        for(uint256 i; i < numberofdrops; i++){
            uint256 location = uint256(keccak256(abi.encode(seed, i))) % (SIZE ** 2);
            drops[location] += amount / numberofdrops;
            emit lootDropped(amount/numberofdrops, location % SIZE, location / SIZE);
        }
    }

    function _getRandomLocation()
    private
    view
    returns(Player memory p){
        uint256 position = uint256(blockhash(block.number - 1)) % (SIZE ** 2);
        p = Player(position % SIZE, position / SIZE, true, Direction.North, 10, 0.001 ether);
    }

    function withdraw(address payable _to) public {
        require(msg.sender == owner);
        _to.transfer(address(this).balance);
    }


}