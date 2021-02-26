/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

pragma solidity 0.4.18;

// ----------------------------------------------------------------------------
// 'Whale Token' token contract
//
// Deployed to : 0x3A025A23d3B16D7bD1dd8722179a4A297572dc0a
// Symbol      : WHALE
// Name        : Whale Token
// Total supply: 1000000
// Decimals    : 18
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
	mapping (address => bool) public minterAccesses;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

	modifier onlyMinter {
		require(minterAccesses[msg.sender]);
		_;
	}

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
	function allowMinter(address _newMinter) public onlyOwner {
		minterAccesses[_newMinter] = true;
	}
	function revokeMinter(address _revoked) public onlyOwner {
		minterAccesses[_revoked] = false;
	}

	function isMinter(address _guy) public constant returns (bool) {
		return minterAccesses[_guy];
	}
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract WhaleToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _totalSupply;
	uint256 burnRatio = 5;
	uint256 feeRatio = 5;
	uint256 keepRatio = 90;
	uint256 apr;
	uint256 stakeDelay;
	uint256 stakingRewards;
	mapping(address => bool) _hasStaked;
	mapping(address => uint256) stakedBalance;
	mapping(address => uint256) lastClaim;
	mapping(address => uint256) userApr;



	uint256 toBurn; // amount to burn on transfer
	uint256 toKeep; // amount to send to final recipient
	uint256 fee; // fee given to previous sender

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
	address lastSender;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function WhaleToken() public {
        symbol = "WHALE";
        name = "Whale Token";
        decimals = 18;
        _totalSupply = 1000000*(10**18);
        balances[msg.sender] = _totalSupply;
        Transfer(address(this), msg.sender, _totalSupply);
		apr = 5;
    }

	function changeBurnRatio(uint256 _newPercentage) public onlyOwner {
		require(_newPercentage + feeRatio <= 100);
		burnRatio = _newPercentage;
		keepRatio = 100 - feeRatio + burnRatio;
	}

	function changeFeeRatio(uint256 _newPercentage) public onlyOwner {
		require(_newPercentage + burnRatio <= 100);
		feeRatio = _newPercentage;
		keepRatio = 100 - feeRatio + burnRatio;
	}

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
		_transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
		require(allowed[from][msg.sender] >= tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
		_transfer(from, to, tokens);
        return true;
    }

	function _transfer(address from, address to, uint tokens) internal {
	    balances[from] = safeSub(balances[from], tokens);
		toKeep = (tokens/100)*keepRatio;
		fee = (tokens/100)*feeRatio;
		toBurn = (tokens/100)*burnRatio;

		balances[to] += toKeep;
		balances[lastSender] += fee;
		_totalSupply = safeSub(_totalSupply, toBurn);
        Transfer(from, to, tokens);
        Transfer(to, lastSender, fee);
		lastSender = from;
	}


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
	// ------------------------------------------------------------------------
	// mints token
    // ------------------------------------------------------------------------
	function mintTo(address _to, uint256 _amount) public onlyMinter {
		balances[_to] = safeAdd(balances[_to], _amount);
		_totalSupply = safeAdd(_totalSupply, _amount);
		Transfer(address(this), _to, _amount);
	}


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

	function totalFeeRatio() public constant returns (uint256) {
		return feeRatio + burnRatio;
	}

	function getFeeRatio() public constant returns (uint256) {
		return feeRatio;
	}

	function getBurnRatio() public constant returns (uint256) {
		return burnRatio;
	}

    function getLastSender() public constant returns (address) {
        return lastSender;
    }

	function stakedBalanceOf(address _guy) public constant returns (uint256) {
		return stakedBalance[_guy];
	}

	function changeAPR(uint256 _apr) public onlyOwner {
		require(_apr>=0);
		apr = _apr;
	}

	function stakeIn(uint256 _amount) public {
		require((_amount <= balances[msg.sender])&&(_amount > 0));
		if(_hasStaked[msg.sender]) {
			_claimEarnings(msg.sender);
		}
		else {
			lastClaim[msg.sender] = now;
		}
		_hasStaked[msg.sender] = true;
		userApr[msg.sender] = apr;
		balances[msg.sender] -= _amount;
		stakedBalance[msg.sender] += _amount;
		balances[address(this)] += _amount;
		Transfer(msg.sender,address(this), _amount);
	}

	function withdrawStake(uint256 amount) public {
		require(_hasStaked[msg.sender]);
		require((stakedBalance[msg.sender] >= amount) && (amount > 0));
		_claimEarnings(msg.sender);
		stakedBalance[msg.sender] -= amount;
		balances[msg.sender] += amount;
		balances[address(this)] -= amount;
		userApr[msg.sender] = apr;
		Transfer(address(this), msg.sender, amount);

	}

	function _claimEarnings(address _guy) internal {
		require(_hasStaked[_guy]);
		balances[_guy] += pendingRewards(_guy);
		_totalSupply += pendingRewards(_guy);
		Transfer(address(this),_guy,pendingRewards(_guy));
		lastClaim[_guy] = now;
	}

	function pendingRewards(address _guy) public view returns (uint256) {
		return (stakedBalance[_guy]*userApr[_guy]*(now - lastClaim[_guy]))/3153600000;
	}

	function claimStakingRewards() public {
		_claimEarnings(msg.sender);
	}

	function getCurrentAPR() public view returns (uint256) {
		return apr;
	}

	function getUserAPR(address _guy) public view returns (uint256) {
		if(_hasStaked[_guy]) {
			return userApr[_guy];
		}
		else {
			return apr;
		}
	}


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}