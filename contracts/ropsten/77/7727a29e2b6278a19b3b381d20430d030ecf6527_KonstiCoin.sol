/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

pragma solidity ^0.4.18;

contract KonstiCoin {
    address public admin;
	string public name = "KonstiCoin";
	string public symbol = "KONSTI";
	uint8 public decimals = 15;

	event Approval(address indexed src, address indexed guy, uint wad);
	event Deposit(address indexed dst, uint wad);
	event Transfer(address indexed src, address indexed dst, uint wad);
	event Withdrawal(address indexed src, uint wad);

	mapping (address => uint) public balanceOf;
	mapping (address => mapping (address => uint)) public allowance;

	constructor() public {
        admin = msg.sender;		
	}
	
	function() public payable {
		deposit();
	}

	function approve(address guy, uint wad) public returns (bool) {
		allowance[msg.sender][guy] = wad;
		Approval(msg.sender, guy, wad);
		return true;
	}

	function deposit() public payable {
        require(msg.sender == admin, 'only admin');
		balanceOf[msg.sender] += msg.value;
		Deposit(msg.sender, msg.value);
	}

	function totalSupply() public view returns (uint) {
		return this.balance;
	}

	function transfer(address dst, uint wad) public returns (bool) {
		return transferFrom(msg.sender, dst, wad);
	}

	function transferFrom(address src, address dst, uint wad) public returns (bool) {
		require(balanceOf[src] >= wad);
		if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
			require(allowance[src][msg.sender] >= wad);
			allowance[src][msg.sender] -= wad;
		}
		balanceOf[src] -= wad;
		balanceOf[dst] += wad;
		Transfer(src, dst, wad);
		return true;
	}

	function withdraw(uint wad) public {
		require(balanceOf[msg.sender] >= wad);
		balanceOf[msg.sender] -= wad;
		msg.sender.transfer(wad);
		Withdrawal(msg.sender, wad);
	}
}