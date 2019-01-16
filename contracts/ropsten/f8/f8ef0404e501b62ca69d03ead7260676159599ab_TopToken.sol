pragma solidity 0.4.20;

contract TopTokenBase {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    
    event Transfer( address indexed from, address indexed to, uint256 value);

    function TopTokenBase() public {    }
    
    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    
    function transfer(address dst, uint256 wad) public returns (bool) {
        require(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        Transfer(msg.sender, dst, wad);
        
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

contract TopToken is TopTokenBase {
    string  public  symbol = "TOP";
    string  public name = "Top.One Coin";
    uint256  public  decimals = 18; 
    uint256 public freezedValue = 640000000*(10**18);
    uint256 public eachUnfreezeValue = 160000000*(10**18);
    uint256 public releaseTime = 1525017600; 
    uint256 public latestReleaseTime = 1525017600; // Apr/30/2018
    address public owner;

    struct FreezeStruct {
        uint256 unfreezeTime;
        bool freezed;
    }

    FreezeStruct[] public unfreezeTimeMap;

    function TopToken() public {
        _supply = 20*(10**8)*(10**18);
        _balances[0x01] = freezedValue;
        _balances[msg.sender] = sub(_supply,freezedValue);
        owner = msg.sender;

        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1554048000, freezed: true})); // Apr/01/2019
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1585670400, freezed: true})); // Apr/01/2020
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1617206400, freezed: true})); // Apr/01/2021
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1648742400, freezed: true})); // Apr/01/2022
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        require (now >= releaseTime || now >= latestReleaseTime);

        return super.transfer(dst, wad);
    }

    function distribute(address dst, uint256 wad) public returns (bool) {
        require(msg.sender == owner);

        return super.transfer(dst, wad);
    }

    function setRelease(uint256 _release) public {
        require(msg.sender == owner);
        require(_release <= latestReleaseTime);

        releaseTime = _release;
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

        Transfer(0x01, owner, eachUnfreezeValue);
    }
}