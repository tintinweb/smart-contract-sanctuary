/**
 *Submitted for verification at FtmScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// A modification of OpenZeppelin ERC20
// Original can be found here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

contract eERC {
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	event BulkTransfer(address indexed from, address[] indexed recipients, uint[] amounts);

	mapping (address => mapping (address => bool)) private _allowances;
	mapping (address => uint) private _balances;

	string private _name;
	string private _symbol;
	bool private _init;
    uint public treasuryFees;
    uint public epochBlock;
    address public pool;
    
	function init() public {
	    require(_init == false);
		_init = true;
		//_treasury = 0x6B51c705d1E78DF8f92317130a0FC1DbbF780a5A;
		//_founding = 0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc;
		//_staking = 0x0FaCF0D846892a10b1aea9Ee000d7700992B64f8;
		_balances[0x5C8403A2617aca5C86946E32E14148776E37f72A] = 0;
		_balances[0x6B51c705d1E78DF8f92317130a0FC1DbbF780a5A] = 29e23;
	}
	
	function genesis(uint b, address p) public {
		require(msg.sender == 0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc);//founding
		epochBlock = b;
		pool = p;
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function totalSupply() public view returns (uint) {//subtract balance of treasury
		return 3e24-_balances[0x6B51c705d1E78DF8f92317130a0FC1DbbF780a5A];
	}

	function decimals() public pure returns (uint) {
		return 18;
	}

	function balanceOf(address a) public view returns (uint) {
		return _balances[a];
	}

	function transfer(address recipient, uint amount) public returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function disallow(address spender) public returns (bool) {
		delete _allowances[msg.sender][spender];
		emit Approval(msg.sender, spender, 0);
		return true;
	}

	function approve(address spender, uint amount) public returns (bool) { // hardcoded spookyswap router, also spirit
		if (spender == 0xF491e7B69E4244ad4002BC14e878a34207E38c29||spender == 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52) {
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
		else {
			_allowances[msg.sender][spender] = true; //boolean is cheaper for trading
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
	}

	function allowance(address owner, address spender) public view returns (uint) { // hardcoded spookyswap router, also spirit
		if (spender == 0xF491e7B69E4244ad4002BC14e878a34207E38c29||spender == 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52||_allowances[owner][spender] == true) {
			return 2**256 - 1;
		} else {
			return 0;
		}
	}

	function transferFrom(address sender, address recipient, uint amount) public returns (bool) { // hardcoded spookyswap router, also spirit
		require(msg.sender == 0xF491e7B69E4244ad4002BC14e878a34207E38c29||msg.sender == 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52||_allowances[sender][msg.sender] == true);
		_transfer(sender, recipient, amount);
		return true;
	}

// burns some tokens in the pool on liquidity unstake
	function burn(uint amount) public {
		require(msg.sender == 0x844D4992375368Ce4Bd03D19307258216D0dd147); //staking
		_burn(amount);
	}

	function _burn(uint amount) internal {
		_balances[pool] -= amount;
		_balances[0x6B51c705d1E78DF8f92317130a0FC1DbbF780a5A]+=amount;//treasury
	}

	function _transfer(address sender, address recipient, uint amount) internal {
	    uint senderBalance = _balances[sender];
		require(sender != address(0)&&senderBalance >= amount);
		_beforeTokenTransfer(sender, amount);
		_balances[sender] = senderBalance - amount;
		if(recipient==pool){
		    uint genesis = epochBlock;
		    require(genesis!=0);
		    uint blocksPassed = block.number - genesis;
		    uint maxBlocks = genesis + 31536000;
		    if(blocksPassed<maxBlocks){
		        uint toBurn = (100 - blocksPassed*100/maxBlocks);// percent
		        if(toBurn>0&&toBurn<=10){
		            uint treasuryShare = amount*toBurn/1000;//10% is max burn
	            	amount -= treasuryShare;
            		_balances[0x6B51c705d1E78DF8f92317130a0FC1DbbF780a5A] += treasuryShare;//treasury
        			treasuryFees+=treasuryShare;
		        }
		    }
		}
		_balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);
	}

	function bulkTransfer(address[] memory recipients, uint[] memory amounts) public returns (bool) { // will be used by the contract, or anybody who wants to use it
		require(recipients.length == amounts.length && amounts.length < 100,"human error");
		uint senderBalance = _balances[msg.sender];
		uint total;
		for(uint i = 0;i<amounts.length;i++) {
		    total += amounts[i];
		    _balances[recipients[i]] += amounts[i];
		}
		require(senderBalance >= total,"balance is low");
		if (msg.sender == 0x6B51c705d1E78DF8f92317130a0FC1DbbF780a5A){//treasury
			_beforeTokenTransfer(msg.sender, total);
		}
		_balances[msg.sender] = senderBalance - total; //only records sender balance once, cheaper
		emit BulkTransfer(msg.sender, recipients, amounts);
		return true;
	}

	function _beforeTokenTransfer(address from, uint amount) internal {
//is not required with latest changes and proxies not being locked
//emission safety check, treasury can't dump more than allowed. but with limits all over treasury might not be required anymore
//and with fee on transfer can't be useful without modifying the state, so again becomes expensive
//even on ftm it can easily become a substantial amount of fees to pay the nodes, so better remove it and make sure that other safety checks are enough
		if(from == 0x6B51c705d1E78DF8f92317130a0FC1DbbF780a5A) {//from treasury
			require(epochBlock != 0);
//			uint w = withdrawn;
//			uint max = (block.number - epochBlock)*31e15;
//			require(max>=w+amount);
//			uint allowed = max - w;
//			require(_balances[0x6B51c705d1E78DF8f92317130a0FC1DbbF780a5A] >= amount);
//			if (withdrawn>2e24){//this can be more complex and balanced in future upgrades, can for example depend on the token price. will take 4 years at least though
//				withdrawn = 0;
//				epochBlock = block.number-5e5;
//			} else {
//				withdrawn+=amount;
//			}
		}
	}
}