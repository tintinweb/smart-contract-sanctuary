/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity >=0.5.0;

// File: hbtcmaker.sol

contract HBTC {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    string  public  name = "Herdius BTC";
    string  public  symbol = "HBTC";
    uint256  public  decimals = 18;
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;
    constructor(uint supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }
    function totalSupply() public view returns (uint) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }
    function transfer(address dst, uint wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad) public
    {
        if (src != msg.sender) {
            require(_approvals[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }
        require(_balances[src] >= wad, "ds-token-insufficient-balance");
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);
        emit Transfer(src, dst, wad);
    }
    function approve(address guy, uint wad) public {
        _approvals[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
    }
}