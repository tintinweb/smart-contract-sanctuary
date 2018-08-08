pragma solidity 0.4.20;

contract MOREToken {
    string  public  symbol = "MORE";
    string  public name = "MORE Token";
    uint256  public  decimals = 18; 
    uint256  _supply;
    mapping (address => uint256) _balances;
    
    event Transfer( address indexed from, address indexed to, uint256 value);

    function MOREToken() public {
        _supply = 10*(10**9)*(10**18);
        _balances[msg.sender] = _supply;
    }
    
    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    
    function transfer(address dst, uint256 wad) public {
        require(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        Transfer(msg.sender, dst, wad);
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