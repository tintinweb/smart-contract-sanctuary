pragma solidity 0.4.20;

contract IPXTokenBase {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    
    event Transfer( address indexed from, address indexed to, uint256 value);

    function IPXTokenBase() public {    }
    
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

contract IPXToken is IPXTokenBase {
    string  public  symbol = "IPX";
    string  public name = "InterPlanetary X";
    uint256  public  decimals = 18; 
    uint256 public freezedValue = 4*(10**8)*(10**18);
    uint256 public eachUnfreezeValue = 4*(10**7)*(10**18);
    address public owner;
    address public freezeAddress;
    bool public freezed;

    struct FreezeStruct {
        uint256 unfreezeTime;
        uint idx;
    }

    FreezeStruct[] public unfreezeTimeMap;

    function IPXToken() public {
        _supply = 2*(10**9)*(10**18);
        _balances[msg.sender] = _supply;
        owner = msg.sender;

        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1533052800, idx: 1})); // Aug/01/2018
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1535731200, idx: 2})); // Sep/01/2018
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1538323200, idx: 3})); // Oct/01/2018
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1541001600, idx: 4})); // Nov/01/2018
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1543593600, idx: 5})); // Dec/01/2018
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1546272000, idx: 6})); // Jan/01/2019
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1548950400, idx: 7})); // Feb/01/2019
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1551369600, idx: 8})); // Mar/01/2019
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1554048000, idx: 9})); // Apr/01/2019
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1556640000, idx: 10})); // May/01/2019
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        assert(checkFreezeValue(wad));
        return super.transfer(dst, wad);
    }

    function checkFreezeValue(uint256 wad) internal view returns(bool) {
        if ( msg.sender == freezeAddress ) {
            for ( uint i = 0; i<unfreezeTimeMap.length; i++ ) {
                uint idx = unfreezeTimeMap[i].idx;
                uint256 unfreezeTime = unfreezeTimeMap[i].unfreezeTime;
                if ( now<unfreezeTime ) {
                    uint256 shouldFreezedValue = freezedValue - (idx-1)*eachUnfreezeValue;
                    if (sub(_balances[msg.sender], wad) < shouldFreezedValue) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    function freeze(address freezeAddr) public returns (bool) {
        require(msg.sender == owner);
        require(freezed == false);
        freezeAddress = freezeAddr;
        freezed = true;
        return super.transfer(freezeAddr, freezedValue);
    }
}