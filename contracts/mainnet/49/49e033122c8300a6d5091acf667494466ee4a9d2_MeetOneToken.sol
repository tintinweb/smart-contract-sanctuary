pragma solidity 0.4.21;

contract MeetOneTokenBase {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    
    event Transfer( address indexed from, address indexed to, uint256 value);

    function MeetOneTokenBase() public {    }
    
    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    
    function transfer(address dst, uint256 wad) public returns (bool) {
        require(dst != address(0));
        require(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        emit Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x && z>=y);
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x - y;
        require(x >= y && z <= x);
        return z;
    }
}

contract MeetOneToken is MeetOneTokenBase {
    string  public  symbol = "MEET.ONE";
    string  public name = "MEET.ONE";
    uint256  public  decimals = 18; 
    uint256 public freezedValue = 25*(10**8)*(10**18);
    uint256 public eachUnfreezeValue = 625000000*(10**18);
    address public owner;

    struct FreezeStruct {
        uint256 unfreezeTime;
        bool freezed;
    }

    FreezeStruct[] public unfreezeTimeMap;

    function MeetOneToken() public {
        _supply = 100*(10**8)*(10**18);
        _balances[0x01] = freezedValue;
        _balances[msg.sender] = sub(_supply,freezedValue);
        owner = msg.sender;

        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1559318400, freezed: true})); // JUN/01/2019
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1590940800, freezed: true})); // JUN/01/2020
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1622476800, freezed: true})); // JUN/01/2021
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1654012800, freezed: true})); // JUN/01/2022
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return super.transfer(dst, wad);
    }

    function unfreeze(uint256 i) public {
        require(msg.sender == owner);
        require(i>=0 && i<unfreezeTimeMap.length);
        require(now >= unfreezeTimeMap[i].unfreezeTime && unfreezeTimeMap[i].freezed);
        require(_balances[0x01] >= eachUnfreezeValue);

        _balances[0x01] = sub(_balances[0x01], eachUnfreezeValue);
        _balances[owner] = add(_balances[owner], eachUnfreezeValue);

        freezedValue = sub(freezedValue, eachUnfreezeValue);
        unfreezeTimeMap[i].freezed = false;

        emit Transfer(0x01, owner, eachUnfreezeValue);
    }
}