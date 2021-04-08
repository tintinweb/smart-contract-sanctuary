import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 275000000000;
		name = "Take My Muffin";
		decimals = 6;
		symbol = "TMM";
		version = "1.3";
		balances[msg.sender] = totalSupply;
	}
}