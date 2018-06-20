pragma solidity ^0.4.11;

contract LOTT {
    string public name = &#39;LOTT&#39;;
    string public symbol = &#39;LOTT&#39;;
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    address public owner;
    uint public price = 10000000000000000000;
    uint public fee = 256000000000000000000;
    uint public currentRound = 0;
    uint8 public placesSold;
    uint[] public places = [
        768000000000000000000,
        614400000000000000000,
        460800000000000000000,
        307200000000000000000,
        153600000000000000000
    ];
    uint public rand1;
    uint8 public rand2;
    
    mapping (uint => mapping (uint8 => address)) public map;
    mapping (address => uint256) public gameBalanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event BalanceChange(address receiver, uint newBalance);
    event RoundChange(uint newRound);
    event Place(uint round, uint8 place, address backer);
    event Finish(uint round, uint8 place1, uint8 place2, uint8 place3, uint8 place4, uint8 place5);
    
    function LOTT() public {
        balanceOf[msg.sender] = totalSupply;
        
        owner = msg.sender;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) external {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function withdraw() external {
        require(gameBalanceOf[msg.sender] > 0);
        
        _transfer(this, msg.sender, gameBalanceOf[msg.sender]);
        
        gameBalanceOf[msg.sender] = 0;
        BalanceChange(msg.sender, 0);
    }
    
    function place(uint8 cell) external {
        require(map[currentRound][cell] == 0x0);
        _transfer(msg.sender, this, price);
        
        map[currentRound][cell] = msg.sender;
        Place(currentRound, cell, msg.sender);
        rand1 += uint(msg.sender) + block.timestamp;
        rand2 -= uint8(msg.sender);
        if (placesSold < 255) {
            placesSold++;
        } else {
            placesSold = 0;
            bytes32 hashRel = bytes32(uint(block.blockhash(block.number - rand2 - 1)) + block.timestamp + rand1);
            
            uint8 place1 = uint8(hashRel[31]);
            uint8 place2 = uint8(hashRel[30]);
            uint8 place3 = uint8(hashRel[29]);
            uint8 place4 = uint8(hashRel[28]);
            uint8 place5 = uint8(hashRel[27]);
            
            if (place2 == place1) {
                place2++;
            }
            
            if (place3 == place1) {
                place3++;
            }
            if (place3 == place2) {
                place3++;
            }
            
            if (place4 == place1) {
                place4++;
            }
            if (place4 == place2) {
                place4++;
            }
            if (place4 == place3) {
                place4++;
            }
            
            if (place5 == place1) {
                place5++;
            }
            if (place5 == place2) {
                place5++;
            }
            if (place5 == place3) {
                place5++;
            }
            if (place5 == place4) {
                place5++;
            }
            
            gameBalanceOf[map[currentRound][place1]] += places[0];
            gameBalanceOf[map[currentRound][place2]] += places[1];
            gameBalanceOf[map[currentRound][place3]] += places[2];
            gameBalanceOf[map[currentRound][place4]] += places[3];
            gameBalanceOf[map[currentRound][place5]] += places[4];
            gameBalanceOf[owner] += fee;
            
            BalanceChange(map[currentRound][place1], gameBalanceOf[map[currentRound][place1]]);
            BalanceChange(map[currentRound][place2], gameBalanceOf[map[currentRound][place2]]);
            BalanceChange(map[currentRound][place3], gameBalanceOf[map[currentRound][place3]]);
            BalanceChange(map[currentRound][place4], gameBalanceOf[map[currentRound][place4]]);
            BalanceChange(map[currentRound][place5], gameBalanceOf[map[currentRound][place5]]);
            BalanceChange(owner, gameBalanceOf[owner]);
            
            Finish(currentRound, place1, place2, place3, place4, place5);
            
            currentRound++;
            RoundChange(currentRound);
        }
    }
}