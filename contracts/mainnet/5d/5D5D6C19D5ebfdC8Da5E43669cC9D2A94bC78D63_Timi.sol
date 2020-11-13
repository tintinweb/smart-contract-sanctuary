pragma solidity ^0.6.6;

//SPDX-License-Identifier: UNLICENSED

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
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

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

	/**
	* @dev Allows the current owner to transfer control of the contract to a newOwner.
	* @param newOwner The address to transfer ownership to.
	*/
	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			owner = newOwner;
			emit OwnershipTransferred(owner, newOwner);
		}
	}
}

// ----------------------------------------------------------------------------
//Tokenlock trade
// ----------------------------------------------------------------------------
contract Tokenlock is Owned {
  uint8 isLocked = 0;
  event Freezed();
  event UnFreezed();
  modifier validLock {
    require(isLocked == 0);
    _;
  }
  function freeze() public onlyOwner {
    isLocked = 1;
    emit Freezed();
  }
  function unfreeze() public onlyOwner {
    isLocked = 0;
    emit UnFreezed();
  }


  mapping(address => bool) blacklist;
  event LockUser(address indexed who);
  event UnlockUser(address indexed who);

  modifier permissionCheck {
    require(!blacklist[msg.sender]);
    _;
  }

  function lockUser(address who) public onlyOwner {
    blacklist[who] = true;
    emit LockUser(who);
  }

  function unlockUser(address who) public onlyOwner {
    blacklist[who] = false;
    emit UnlockUser(who);
  }

}


contract Timi is Tokenlock {

    using SafeMath for uint;
    string public name = "Timi Finance";
    string public symbol = "Timi";
    uint8  public decimals = 18;
    uint  internal _rate=100;
    uint  internal _amount;
    uint256  public totalSupply;

    //bank
    mapping(address => uint)  bank_balances;
    //eth
    mapping(address => uint) activeBalances;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    event Burn(address indexed _from, uint256 value);
	// Called when new token are issued
	event Issue(uint amount);
	// Called when tokens are redeemed
	event Redeem(uint amount);
    //Called when sent
    event Sent(address from, address to, uint amount);
    event FallbackCalled(address sent, uint amount);

    	/**
	* @dev Fix for the ERC20 short address attack.
	*/
	modifier onlyPayloadSize(uint size) {
		require(!(msg.data.length < size + 4));
		_;
	}

    constructor (uint totalAmount) public{
        totalSupply =  totalAmount * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
/*    function totalSupply() public  view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }*/

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOfBank(address tokenOwner) public  view returns (uint balance) {
        return bank_balances[tokenOwner];
    }

    function balanceOfReg(address tokenOwner) public  view returns (uint balance) {
        return activeBalances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public  view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public   view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


	// ------------------------------------------------------------------------
	// Issue a new amount of tokens
	// these tokens are deposited into the owner address
	// @param _amount Number of tokens to be issued
	// ------------------------------------------------------------------------
	function issue(uint amount) public onlyOwner {
		require(totalSupply + amount > totalSupply);
		require(balances[owner] + amount > balances[owner]);

		balances[owner] += amount;
		totalSupply += amount;
		emit Issue(amount);
	}
	// ------------------------------------------------------------------------
	// Redeem tokens.
	// These tokens are withdrawn from the owner address
	// if the balance must be enough to cover the redeem
	// or the call will fail.
	// @param _amount Number of tokens to be issued
	// ------------------------------------------------------------------------
	function redeem(uint amount) public onlyOwner {
		require(totalSupply >= amount);
		require(balances[owner] >= amount);

		totalSupply -= amount;
		balances[owner] -= amount;
		emit Redeem(amount);
	}

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public  validLock permissionCheck onlyPayloadSize(2 * 32) returns (bool success) {
        require(to != address(0));
        require(balances[msg.sender] >= tokens && tokens > 0);
        require(balances[to] + tokens >= balances[to]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
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
    function approve(address spender, uint tokens) public returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) public  validLock permissionCheck onlyPayloadSize(3 * 32) returns (bool success) {
        require(to != address(0));

        require(balances[from] >= tokens && tokens > 0);
        require(balances[to] + tokens >= balances[to]);


        balances[from] = balances[from].sub(tokens);
        if(allowed[from][msg.sender] > 0)
        {
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        }
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
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
    function transferStore(address from, address to, uint tokens) public  validLock permissionCheck onlyPayloadSize(3 * 32) returns (bool success) {
        require(to != address(0));

        require(balances[from] >= tokens && tokens > 0);
        require(balances[to] + tokens >= balances[to]);


        balances[from] = balances[from].sub(tokens);
        if(allowed[from][msg.sender] > 0)
        {
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        }
        balances[to] = balances[to].add(tokens);


        bank_balances[from] = bank_balances[from].add(tokens);


        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public  onlyOwner {
        // return ERC20Interface(tokenAddress).transfer(owner, tokens);
        address(uint160(tokenAddress)).transfer(tokens);
        emit Sent(owner,tokenAddress,tokens);
    }

    // ------------------------------------------------------------------------
    //  ERC20 withdraw
    // -----------------------------------------
    function withdraw() onlyOwner public {
        msg.sender.transfer(address(this).balance);
        _amount = 0;
    }

    function showAmount() onlyOwner public view returns (uint) {
        return _amount;
    }

    function showBalance() onlyOwner public view returns (uint) {
        return owner.balance;
    }

    // ------------------------------------------------------------------------
    //  ERC20 set rate
    // -----------------------------------------
    function set_rate(uint _vlue) public onlyOwner{
        require(_vlue > 0);
        _rate = _vlue;
    }

    // ------------------------------------------------------------------------
    //  ERC20 tokens
    // -----------------------------------------
    receive() external  payable{
        /* require(balances[owner] >= msg.value && msg.value > 0);
        balances[msg.sender] = balances[msg.sender].add(msg.value * _rate);
		balances[owner] = balances[owner].sub(msg.value * _rate); */
        _amount=_amount.add(msg.value);
        activeBalances[msg.sender] = activeBalances[msg.sender].add(msg.value);
    }

    // ------------------------------------------------------------------------
    //  ERC20 recharge
    // -----------------------------------------
    function recharge() public payable{
        _amount=_amount.add(msg.value);
        activeBalances[msg.sender] = activeBalances[msg.sender].add(msg.value);
    }

}