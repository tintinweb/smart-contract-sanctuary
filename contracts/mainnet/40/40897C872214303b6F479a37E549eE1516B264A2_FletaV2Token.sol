/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity 0.5.17;

// ----------------------------------------------------------------------------
// 'FLETA' 'Fleta Token' token contract
//
// Symbol	  : FLETA
// Name		: Fleta Token
// Total supply: 2,000,000,000 (Same as 0x7788D759F21F53533051A9AE657fA05A1E068fc6)
// Decimals	: 18
//
// Enjoy.
//
// (c) Sam Jeong / SendSquare Co. 2021. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
	function add(uint a, uint b) internal pure returns (uint c) {
		c = a + b;
		require(c >= a);
	}
	function sub(uint a, uint b) internal pure returns (uint c) {
		require(b <= a);
		c = a - b;
	}
	function mul(uint a, uint b) internal pure returns (uint c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}
	function div(uint a, uint b) internal pure returns (uint c) {
		require(b > 0);
		c = a / b;
	}
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
	function totalSupply() public view returns (uint);
	function balanceOf(address tokenOwner) public view returns (uint balance);
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Fletav2Gateway {
	function isGatewayAddress(address gatewayAddress) public view returns (bool);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner, "only owner");
		_;
	}
}


// ----------------------------------------------------------------------------
// Manager contract
// ----------------------------------------------------------------------------
contract Managed is Owned {
	address public manager;

	constructor() public {
		manager = msg.sender;
	}

	modifier onlyManager {
		require(msg.sender == manager, "only manager");
		_;
	}
	
	// ------------------------------------------------------------------------
	// Change gateway manager
	// ------------------------------------------------------------------------
	function setGatewayManager(address addr) public onlyOwner {
		require(addr > address(0), "cannot setGatewayManager to 0x0");
		manager = addr;
	}
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract FletaV2Token is ERC20Interface, Owned, Managed {
	using SafeMath for uint;

	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;
	bool _stopTrade;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;

	//Changes v2
	address public v1Address;
	mapping(address => bool) mswap;
	mapping(address => bool) mgatewayAddress;

	// ------------------------------------------------------------------------
	// Constructor
	// The parameters of the constructor were added in v2.
	// ------------------------------------------------------------------------
	constructor(address v1Addr) public {
		symbol = "FLETA";
		name = "Fleta Token";
		decimals = 18;
// 		_stopTrade = false;

		//blow Changes v2
//  	balances[owner] = 0;

		_totalSupply = ERC20Interface(v1Addr).totalSupply();
		v1Address = v1Addr;
	}


	// ------------------------------------------------------------------------
	// Total supply
	// ------------------------------------------------------------------------
	function totalSupply() public view returns (uint) {
		return _totalSupply.sub(balances[address(0)]);
	}


	// ------------------------------------------------------------------------
	// Stop Trade
	// ------------------------------------------------------------------------
	function stopTrade() public onlyOwner {
		require(!_stopTrade, "already stop trade");
		_stopTrade = true;
	}


	// ------------------------------------------------------------------------
	// Start Trade
	// ------------------------------------------------------------------------
	function startTrade() public onlyOwner {
		require(_stopTrade, "already start trade");
		_stopTrade = false;
	}

	// ------------------------------------------------------------------------
	// Get the token balance for account `tokenOwner`
	// Changes in v2 
	// - before swap, use V1 + V2 balance
	// - after swap, use V2 balance
	// ------------------------------------------------------------------------
	function balanceOf(address tokenOwner) public view returns (uint) {
		if (mswap[tokenOwner]) {
			return balances[tokenOwner];
		}
		return ERC20Interface(v1Address).balanceOf(tokenOwner).add(balances[tokenOwner]);
	}


	// ------------------------------------------------------------------------
	// Transfer the balance from token owner's account to `to` account
	// - Owner's account must have sufficient balance to transfer
	// - 0 value transfers are allowed
	// Changes in v2 
	// - insection _swap function See {_swap}
	// ------------------------------------------------------------------------
	function transfer(address to, uint tokens) public returns (bool) {
		require(!_stopTrade, "stop trade");
		_swap(msg.sender);
		require(to > address(0), "cannot transfer to 0x0");

		balances[msg.sender] = balances[msg.sender].sub(tokens);

		if (mgatewayAddress[to]) {
			//balances[to] = balances[to].add(tokens);
			//balances[to] = balances[to].sub(tokens);
			_totalSupply = _totalSupply.sub(tokens);
			emit Transfer(to, address(0), tokens);
		} else {
			balances[to] = balances[to].add(tokens);
		}
		emit Transfer(msg.sender, to, tokens);

		return true;
	}


	// ------------------------------------------------------------------------
	// Token owner can approve for `spender` to transferFrom(...) `tokens`
	// from the token owner's account
	//
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
	// recommends that there are no checks for the approval double-spend attack
	// as this should be implemented in user interfaces
	// ------------------------------------------------------------------------
	function approve(address spender, uint tokens) public returns (bool) {
		require(!_stopTrade, "stop trade");
		_swap(msg.sender);

		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}


	// ------------------------------------------------------------------------
	// Transfer `tokens` from the `from` account to the `to` account
	//
	// The calling account must already have sufficient tokens approve(...)-d
	// for spending from the `from` account and
	// - From account must have sufficient balance to transfer
	// - Spender must have sufficient allowance to transfer
	// - 0 value transfers are allowed
	// ------------------------------------------------------------------------
	function transferFrom(address from, address to, uint tokens) public returns (bool) {
		require(!_stopTrade, "stop trade");
		_swap(msg.sender);
		require(from > address(0), "cannot transfer from 0x0");
		require(to > address(0), "cannot transfer to 0x0");

		balances[from] = balances[from].sub(tokens);
		if(from != to && from != msg.sender) {
			allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		}

		if (mgatewayAddress[to]) {
			//balances[to] = balances[to].add(tokens);
			//balances[to] = balances[to].sub(tokens);
			_totalSupply = _totalSupply.sub(tokens);
			emit Transfer(to, address(0), tokens);
		} else {
			balances[to] = balances[to].add(tokens);
		}
		emit Transfer(from, to, tokens);

		return true;
	}


	// ------------------------------------------------------------------------
	// Returns the amount of tokens approved by the owner that can be
	// transferred to the spender's account
	// ------------------------------------------------------------------------
	function allowance(address tokenOwner, address spender) public view returns (uint) {
		require(!_stopTrade, "stop trade");
		return allowed[tokenOwner][spender];
	}


	// ------------------------------------------------------------------------
	// Token owner can approve for `spender` to transferFrom(...) `tokens`
	// from the token owner's account. The `spender` contract function
	// `receiveApproval(...)` is then executed
	// ------------------------------------------------------------------------
	function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool) {
		require(msg.sender != spender, "msg.sender == spender");

		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
		return true;
	}


	// ------------------------------------------------------------------------
	// Don't accept ETH
	// ------------------------------------------------------------------------
	function () external payable {
		revert();
	}


	// ------------------------------------------------------------------------
	// Owner can transfer out any accidentally sent ERC20 tokens
	// ------------------------------------------------------------------------
	function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool) {
		return ERC20Interface(tokenAddress).transfer(owner, tokens);
	}

// ------------------------------------------------------------------------
// Below functions added to v2 
// ------------------------------------------------------------------------
	// ------------------------------------------------------------------------
	// Swap the token in v1 to v2.
	// ------------------------------------------------------------------------
	function swap(address swapAddr) public returns (bool) {
		require(!mswap[swapAddr], "already swap");
		_swap(swapAddr);
		return true;
	}
	function _swap(address swapAddr) private {
		if (!mswap[swapAddr]) {
			mswap[swapAddr] = true;
			uint _value = ERC20Interface(v1Address).balanceOf(swapAddr);
			balances[swapAddr] = balances[swapAddr].add(_value);
		}
	}

	function isGatewayAddress(address gAddr) public view returns (bool) {
		return mgatewayAddress[gAddr];
	}

	// ------------------------------------------------------------------------
	// Burns a specific amount of tokens
	// ------------------------------------------------------------------------
	function _burn(address burner, uint256 _value) private {
		_swap(burner);

		balances[burner] = balances[burner].sub(_value);
		_totalSupply = _totalSupply.sub(_value);

		emit Transfer(burner, address(0), _value);
	}

	// ------------------------------------------------------------------------
	// Minting a specific amount of tokens
	// ------------------------------------------------------------------------
	function mint(address minter, uint256 _value) public onlyManager {
		require(!_stopTrade, "stop trade");
		_swap(minter);
		balances[minter] = balances[minter].add(_value);
		_totalSupply = _totalSupply.add(_value);

		emit Transfer(address(0), minter, _value);
	}

	// ------------------------------------------------------------------------
	// The gateway address is the eth address connected to the FLETA mainnet.
	// The transferred amount to this address is burned and minted to the FLETA mainnet address associated with this address.
	// ------------------------------------------------------------------------
	function depositGatewayAdd(address gatewayAddr) public onlyManager {
		require(!_stopTrade, "stop trade");
		mgatewayAddress[gatewayAddr] = true;
		if (balanceOf(gatewayAddr) > 0) {
			_burn(gatewayAddr, balanceOf(gatewayAddr));
		}
	}

	// ------------------------------------------------------------------------
	// Remove gateway address map, revert normal address
	// ------------------------------------------------------------------------
	function depositGatewayRemove(address gatewayAddr) public onlyManager {
		require(!_stopTrade, "stop trade");
		mgatewayAddress[gatewayAddr] = false;
	}

}