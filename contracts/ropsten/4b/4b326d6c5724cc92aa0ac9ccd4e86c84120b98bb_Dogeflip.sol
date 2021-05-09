/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
abstract contract ERC20Interface {
    function getTotalSupply() virtual public view returns (uint);
    function getBalanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    function mint(address receiver, uint tokens) virtual public returns (bool success);
    function getOwner() virtual public view returns(address);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event Status(string _msg, address user, uint amount,bool winner);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Dogeflip is SafeMath, ERC20Interface {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;

    // Hash table of balances
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    // Contract Ownership
    address public owner;
    address public newOwner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        symbol = "DFLP";
        name = "Dogeflip";
        decimals = 18;
        _totalSupply = 50000000000000000000000000000;
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
        owner = msg.sender;
    }

	// Get the number of games that have been played so far
	function getOwner() public view override returns(address) {
		return owner;
	}
    
    // ------------------------------------------------------------------------
    // Incase we need to transfer ownership
    // ------------------------------------------------------------------------
    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    // ------------------------------------------------------------------------
    // DogefLip Game
    // ------------------------------------------------------------------------    
    uint payPercentage = 100; // 100%, but we could change this to whatever we want. It's nice to have it here for transaprency
	// Maximum amount to bet in WEIs
	uint public MaxAmountToBet = 200000000000000000000000; //Max bet is currently 20,000 Dogeflip (We can make it variable- to be discussed)
	
	struct Game {
		address addr;
		uint blocknumber;
		uint blocktimestamp;
        uint bet;
		uint prize;
        bool winner;
    }
    
	Game[] lastPlayedGames;
	Game newGame;
    
    // The main play logic
    function Play(uint tokens) public {
		if (tokens > MaxAmountToBet) {
			revert();
			// To add an emit/event here back to the Website?
		} else {
		    // Logic to check if player is winner. Even wins. Odds lose.
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
			if ((block.timestamp % 2) == 0) {
				uint _prize = tokens * (100 + payPercentage) / 100;
				emit Status('Congratulations, you win!', msg.sender, _prize, true);
				mint(msg.sender, _prize);
				newGame = Game({
					addr: msg.sender,
					blocknumber: block.number,
					blocktimestamp: block.timestamp,
					bet: tokens,
					prize: _prize,
					winner: true
				});
				lastPlayedGames.push(newGame);
			} else {
			    // player loses
			    // TODO: WE NOW NEED TO BURN THE PRIZE VALUE
				emit Status('Sorry, you loose!', msg.sender, tokens, false);
				newGame = Game({
					addr: msg.sender,
					blocknumber: block.number,
					blocktimestamp: block.timestamp,
					bet: tokens,
					prize: 0,
					winner: false
				});
				lastPlayedGames.push(newGame);
			}
		}
    }
	
	// Get the number of games that have been played so far
	function getGameCount() public view returns(uint) {
		return lastPlayedGames.length;
	}

    // Get the current game number
	function getGameEntry(uint index) public view returns(address addr, uint blocknumber, uint blocktimestamp, uint bet, uint prize, bool winner) {
		return (lastPlayedGames[index].addr, lastPlayedGames[index].blocknumber, lastPlayedGames[index].blocktimestamp, lastPlayedGames[index].bet, lastPlayedGames[index].prize, lastPlayedGames[index].winner);
	}
	
	// Get the maximum bet size
	function getMaxAmountToBet() public view returns (uint) {
        return MaxAmountToBet;
    }

    // Get Total supply
    function getTotalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    // Get the token balance for account tokenOwner
    function getBalanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }
    
	// Set the maximum bet size
	function setMaxAmountToBet(uint amount) public onlyOwner returns (uint) {
		MaxAmountToBet = amount;
        return MaxAmountToBet;
    }

    // Destroy the contract and send balance to owner
    function Kill() public onlyOwner {
        emit Status('Contract was killed, contract balance will be sent to the owner!', msg.sender, address(this).balance, true);
        selfdestruct(payable(owner));
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
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
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
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
    // MUST BE APPROVED by approve function
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Allow CoinFlip Contract to Mint Doge Flip
    // Sends an amount of newly created coins to an address
    // Can only be called by the contract owner
    // ------------------------------------------------------------------------
    function mint(address receiver, uint tokens) public override returns (bool success) {
        require(msg.sender == owner);
        require(tokens < 1e60);
        //balances[receiver] += amount;
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    // function () external payable {
    //     revert();
    // }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddrs, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddrs).transfer(owner, tokens);
    }
}