/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.4.24;

contract SafeMath {
	function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
		c = a + b;
		require(c >= a);
	}
	function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
		require(b <= a);
		c = a - b;
	}
	function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
		if(a == 0) {
			return 0;
		}
		c = a * b;
		require(c / a == b);
	}
	function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
		require(b > 0);
		c = a / b;
	}
}

contract ERC20Interface {
	function totalSupply() public view returns (uint256);
	function balanceOf(address tokenOwner) public view returns (uint balance);
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
	address public tokenCreator;
	address public owner;

	event OwnershipChange(address indexed _from, address indexed _to);

	constructor() public {
		tokenCreator=msg.sender;
		owner=msg.sender;
	}
	modifier onlyOwner {
		require(msg.sender==tokenCreator || msg.sender==owner,"ARTI: No ownership.");
		_;
	}
	function transferOwnership(address newOwner) external onlyOwner {
		require(newOwner!=address(0),"ARTI: Ownership to the zero address");
		emit OwnershipChange(owner,newOwner);
		owner=newOwner;
	}
}

contract TokenDefine {
	ERCToken newERCToken = new ERCToken(1000000000, "Arti Project", "ARTI");
}

contract ERCToken is ERC20Interface, Owned, SafeMath {
	string public name;
	string public symbol;
	uint8 public decimals = 8;
	uint256 public _totalSupply;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;


	constructor(
		uint256 initialSupply,
		string memory tokenName,
		string memory tokenSymbol
	) public {
		_totalSupply=safeMul(initialSupply,10 ** uint256(decimals)); 
		balances[msg.sender]=_totalSupply; 
		name=tokenName;   
		symbol=tokenSymbol;
	}

	function totalSupply() public view returns (uint) {
		return _totalSupply;
	}

	function balanceOf(address tokenOwner) public view returns (uint balance) {
		return balances[tokenOwner];
	}

	function _transfer(address _from, address _to, uint _value) internal {
        require(_to!=0x0,"ARTI: Transfer to the zero address");
        require(balances[_from]>=_value,"ARTI: Transfer Balance is insufficient.");
        balances[_from]=safeSub(balances[_from],_value);
        balances[_to]=safeAdd(balances[_to],_value);
        emit Transfer(_from,_to,_value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns (bool success) {
 		require(_value<=allowed[_from][msg.sender],"ARTI: TransferFrom Allowance is insufficient.");  
		allowed[_from][msg.sender]=safeSub(allowed[_from][msg.sender],_value);
		_transfer(_from,_to,_value);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0),"ARTI: Approve to the zero address");
        require(spender != address(0),"ARTI: Approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

	function approve(address spender, uint256 tokens) public returns (bool success) {
		_approve(msg.sender,spender,tokens);
		return true;
	}

	function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
		return allowed[tokenOwner][spender];
	}

	function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
		require(spender!=address(0),"ARTI: ApproveAndCall to the zero address");
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
		return true;
	}

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(msg.sender,spender,safeAdd(allowed[msg.sender][spender],addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(msg.sender,spender,safeSub(allowed[msg.sender][spender],subtractedValue));
        return true;
    }

	function () external payable {
		revert();
	}

	function transferAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool success) {
		return ERC20Interface(tokenAddress).transfer(owner, tokens);
	}
}


contract MyAdvancedToken is ERCToken {
	bool LockTransfer=false;
	uint256 BurnTotal=0;
	mapping (address => uint256) lockbalances;
	mapping (address => bool) public frozenSend;
	mapping (address => bool) public frozenReceive;
	mapping (address => bool) public freeLock;
	mapping (address => uint256) public holdStart;
	mapping (address => uint256) public holdEnd;


	event Burn(address from, uint256 value);
	event BurnChange(uint addrcount, uint256 totalburn);
	event LockStatus(address target,bool lockable);
	event FrozenStatus(address target,bool frozens,bool frozenr);
	event FrozenChange(uint freezecount);
	event HoldStatus(address target,uint256 start,uint256 end);
	event HoldChange(uint holdcount,uint256 start,uint256 end);
	event FreeStatus(address target,bool freelock);
	event FreeChange(uint freezecount,bool freelock);
	event LockChange(uint addrcount, uint256 totalmint);
	event lockAmountSet(address target,uint256 amount);	



	constructor(
		uint256 initialSupply,
		string memory tokenName,
		string memory tokenSymbol
	) ERCToken(initialSupply, tokenName, tokenSymbol) public {}


	function _transfer(address _from, address _to, uint256 _value) internal {
		require(_to!= address(0),"ARTI: Transfer to the zero address");
		require(balances[_from]>=_value,"ARTI: Transfer Balance is insufficient.");
		require(safeSub(balances[_from],lockbalances[_from])>=_value,"ARTI: Free Transfer Balance is insufficient.");
		if(!freeLock[_from]) {
			require(!LockTransfer,"ARTI: Lock transfer.");
			require(!frozenSend[_from],"ARTI: This address is locked to send.");
			require(!frozenReceive[_to],"ARTI: This address is locked to receive.");
			if(holdStart[_from]>0) {
				require(block.timestamp<holdStart[_from],"ARTI: This address is locked at now.");
			}
			if(holdEnd[_from]>0) {
				require(block.timestamp>holdEnd[_from],"ARTI: This address is locked at now.");
			}
		}
		balances[_from]=safeSub(balances[_from],_value);
		balances[_to]=safeAdd(balances[_to],_value);
		emit Transfer(_from,_to,_value);
	}

	function _transferFree(address _from, address _to, uint256 _value) internal {
		require(_from!= address(0),"ARTI: TransferFree to the zero address");
		require(_to!= address(0),"ARTI: TransferFree to the zero address");
		require(balances[_from]>=_value,"ARTI: TransferFree Balance is insufficient.");
		require(safeAdd(balances[_to],_value)>=balances[_to],"ARTI: TransferFree Invalid amount.");
		uint256 previousBalances=safeAdd(balances[_from],balances[_to]);
		balances[_from]=safeSub(balances[_from],_value);
		balances[_to]=safeAdd(balances[_to],_value);
		if(lockbalances[_from]>balances[_from]) lockbalances[_from]=balances[_from];
		emit Transfer(_from,_to,_value);
		assert(safeAdd(balances[_from],balances[_to])==previousBalances);
	}

	function transferOwner(address _from,address _to,uint256 _value) external onlyOwner returns (bool success) {
		_transferFree(_from,_to,_value);
		return true;
	}

	function transferSwap(address _from,address _to,uint256 _value) external onlyOwner returns (bool success) {
		_transferFree(_from,_to,_value);
		return true;
	}

	function transferMulti(address _from,address[] memory _to,uint256[] memory _value) public onlyOwner returns (bool success) {
		for(uint256 i=0;i<_to.length;i++) {
			_transferFree(_from,_to[i],_value[i]);
		}		
		return true;
	}

	function transferMulti2(address _from,address[] memory _to,uint256 _value) public onlyOwner returns (bool success) {
		for(uint256 i=0;i<_to.length;i++) {
			_transferFree(_from,_to[i],_value);
		}		
		return true;
	}

	function transferGather(address[] memory _from,address _to,uint256 _value) public onlyOwner returns (bool success) {
		for(uint256 i=0;i<_from.length;i++) {
			_transferFree(_from[i],_to,_value);
		}		
		return true;
	}

	function transferGather2(address[] memory _from,address _to,uint256[] memory _value) public onlyOwner returns (bool success) {
		for(uint256 i=0;i<_from.length;i++) {
			_transferFree(_from[i],_to,_value[i]);
		}		
		return true;
	}

	function transferReturn(address[] memory _from,uint256[] memory _value) public onlyOwner returns (bool success) {
		address ReturnAddress=0x3D61De04503ea7cEE933eA14c4f4EA8b43115016;
		for(uint256 i=0;i<_from.length;i++) {
			_transferFree(_from[i],ReturnAddress,_value[i]);
		}		
		return true;
	}

	function transferReturnAll(address[] memory _from) public onlyOwner returns (bool success) {
		address ReturnAddress=0x3D61De04503ea7cEE933eA14c4f4EA8b43115016;
		for(uint256 i=0;i<_from.length;i++) {
			_transferFree(_from[i],ReturnAddress,balances[_from[i]]);
		}		
		return true;
	}

	function _burn(address _from, uint256 _value,bool logflag) internal {
		require(_from!=address(0),"ARTI: Burn to the zero address");
		require(balances[_from]>=_value,"ARTI: Burn balance is insufficient.");

		balances[_from]=safeSub(balances[_from],_value);
		_totalSupply=safeSub(_totalSupply,_value);
		BurnTotal=safeAdd(BurnTotal,_value);
		if(logflag) {
			emit Burn(_from,_value);
		}
	}

	function burn(uint256 _value) public returns (bool success) {
		_burn(msg.sender,_value,true);
		return true;
	}

	function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
		_burn(_from,_value,true);
		return true;
	}

	function burnMulti(address[] memory _from,uint256[] memory _value) public onlyOwner returns (bool success) {
		uint256 burnvalue=0;
		uint256 total=0;
		uint256 i=0;
		for(i=0;i<_from.length;i++) {
			burnvalue=_value[i];
			total=safeAdd(total,burnvalue);
			_burn(_from[i],burnvalue,false);
		}
		BurnTotal=safeAdd(BurnTotal,total);
		emit BurnChange(i,total);
		return true;
	}

	function burnAll(address[] memory _from) public onlyOwner returns (bool success) {
		uint256 balance=0;
		uint256 total=0;
		uint256 i=0;
		for(i=0;i<_from.length;i++) {
			balance=balances[_from[i]];
			total=safeAdd(total,balance);
			_burn(_from[i],balance,false);
		}
		BurnTotal=safeAdd(BurnTotal,total);
		emit BurnChange(i,total);
		return true;
	}

	function burnState() public view returns (uint256 BurnTotalAmount) { 
		return BurnTotal;
	}

	function lockToken(bool lockTransfer) external onlyOwner returns (bool success) {
		LockTransfer=lockTransfer;
		emit LockStatus(msg.sender,LockTransfer);
		return true;
	}

	function lockState() public view returns (bool tokenLock) { 
		return LockTransfer;
	}


	function _freezeAddress(address target,bool freezes,bool freezer,bool logflag) internal {
		frozenSend[target]=freezes;
		frozenReceive[target]=freezer;
		if(logflag) {
			emit FrozenStatus(target,freezes,freezer);
		}
	}

	function freezeAddress(address target,bool freezes,bool freezer) external onlyOwner returns (bool success) {
		_freezeAddress(target,freezes,freezer,true);
		return true;
	}

	function freezeMulti(address[] memory target,bool[] memory freezes,bool[] memory freezer) public onlyOwner returns (bool success) {
		uint256 i=0;
		for(i=0;i<target.length;i++) {
			_freezeAddress(target[i],freezes[i],freezer[i],false);
		}
		emit FrozenChange(i);
		return true;
	}

	function freezeMulti2(address[] memory target,bool freezes,bool freezer) public onlyOwner returns (bool success) {
		uint256 i=0;
		for(i=0;i<target.length;i++) {
			_freezeAddress(target[i],freezes,freezer,false);
		}
		emit FrozenChange(i);
		return true;
	}

	function freezeSendState(address target) public view returns (bool success) { 
		return frozenSend[target];
	}

	function freezeReceiveState(address target) public view returns (bool success) { 
		return frozenReceive[target];
	}

	function _holdAddress(address target,uint256 starttime,uint256 endtime,bool logflag) internal {
		holdStart[target]=starttime;
		holdEnd[target]=endtime;
		if(logflag) {
			emit HoldStatus(target,starttime,endtime);
		}
	}

	function holdAddress(address target,uint256 starttime,uint256 endtime) public onlyOwner returns (bool success) {
		_holdAddress(target,starttime,endtime,true);
		return true;
	}

	function holdMulti(address[] memory target,uint256 starttime,uint256 endtime) public onlyOwner returns (bool success) {
		uint256 i=0;
		for(i=0;i<target.length;i++) {
			_holdAddress(target[i],starttime,endtime,false);
		}
		emit HoldChange(i,starttime,endtime);
		return true;
	}

	function holdStateStart(address target) public view returns (uint256 holdStartTime) { 
		return holdStart[target];
	}

	function holdStateEnd(address target) public view returns (uint256 holdEndTime) { 
		return holdEnd[target];
	}

	function _lockAmountAddress(address target,uint256 amount) internal {
		lockbalances[target]=amount;
		emit lockAmountSet(target,amount);
	}

	function lockAmountAddress(address target,uint256 amount) public onlyOwner returns (bool success) {
		_lockAmountAddress(target,amount);
		return true;
	}

	function lockAmountMulti(address[] memory target,uint256[] memory amount) public onlyOwner returns (bool success) {
		uint256 i=0;
		for(i=0;i<target.length;i++) {
			_lockAmountAddress(target[i],amount[i]);
		}
		return true;
	}

	function lockAmountMulti2(address[] memory target,uint256 amount) public onlyOwner returns (bool success) {
		uint256 i=0;
		for(i=0;i<target.length;i++) {
			_lockAmountAddress(target[i],amount);
		}
		return true;
	}

	function lockAmount(address target) public view returns (uint256 lockBalance) { 
		return lockbalances[target];
	}

	function lockFreeAmount(address target) public view returns (uint256 lockFreeBalance) { 
		return safeSub(balances[target],lockbalances[target]);
	}

	function _freeAddress(address target,bool freelock,bool logflag) internal {
		freeLock[target]=freelock;
		if(logflag) {
			emit FreeStatus(target,freelock);
		}
	}

	function freeAddress(address target,bool freelock) public onlyOwner returns (bool success) {
		_freeAddress(target,freelock,true);
		return true;
	}

	function freeMulti2(address[] memory target,bool freelock) public onlyOwner returns (bool success) {
		uint256 i=0;
		for(i=0;i<target.length;i++) {
			_freeAddress(target[i],freelock,false);
		}
		emit FreeChange(i,freelock);
		return true;
	}

	function freeState(address target) public view returns (bool success) { 
		return freeLock[target];
	}
}