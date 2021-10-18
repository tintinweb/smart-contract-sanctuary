/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

pragma solidity ^0.5.7;

contract GAZ_ERC20 {
	 // --- Math ---
    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function sub(uint x, int y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
	
	
    uint256                                           public  totalSupply = 63000000 * 10 ** 18;
    mapping (address => uint256)                      public  balanceOf;
    mapping (address => mapping (address => uint))    public  allowance;
    bytes32                                           public  symbol = "GAZ";
    bytes32                                           public  name = "gazelle";     // Optional token name
    uint256                                           public  decimals = 18; // standard token precision. override to customize

	constructor() public{
       balanceOf[msg.sender] = totalSupply;
    }

	function approve(address guy) external returns (bool) {
        return approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public  returns (bool){
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) external  returns (bool){
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public  returns (bool)
    {
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "gaz/insufficient-approval");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        require(balanceOf[src] >= wad, "gaz/insuff-balance");
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);
}