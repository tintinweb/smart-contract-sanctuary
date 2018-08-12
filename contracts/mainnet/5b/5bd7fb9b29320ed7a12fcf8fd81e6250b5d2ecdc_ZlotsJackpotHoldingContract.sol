pragma solidity ^0.4.24;

/*
*
* Jackpot holding contract for Zlots.
*  
* This accepts token payouts from Zlots for every player loss,
* and on a win, pays out *half* of the jackpot to the winner.
*
* Jackpot payout should only be called from Zlots.
*
*/

contract ZethrInterface {
  function balanceOf(address who) public view returns (uint);
  function transfer(address _to, uint _value) public returns (bool);
	function withdraw(address _recipient) public;
}

// Should receive Zethr tokens
contract ERC223Receiving {
  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

// The actual contract
contract ZlotsJackpotHoldingContract is ERC223Receiving {

  // ------------------------- Modifiers

  // Require msg.sender to be owner
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  } 

  // Require msg.sender to be zlots
  modifier onlyZlots() {
    require(msg.sender == zlots);
    _;
  }

	// -------------------------- Events

  // Events
  event JackpotPayout(
    uint amountPaid,
    address winner,
    uint payoutNumber
  );

	// -------------------------- Variables

  // Configurables
  address owner;
  address zlots;
  ZethrInterface Zethr = ZethrInterface(0xD48B633045af65fF636F3c6edd744748351E020D);

  // Trackers
  uint payoutNumber = 0; // How many times we&#39;ve paid out the jackpot
  uint totalPaidOut = 0; // The total amount we&#39;ve paid out 

  // ------------------------- Functions

	// Constructor
  constructor (address zlotsAddress) public {
    owner = msg.sender;
    zlots = zlotsAddress;
  }

  // When we transfer, divs are withdraw.
  // This means we need an empty public payable.
  function () public payable { }

  // Callable only by Zlots
  // Pay a winner half of the jackpot
  function payOutWinner(address winner) public onlyZlots {
		// Calculate payout & pay out
 		uint payoutAmount = Zethr.balanceOf(address(this)) / 2;
		Zethr.transfer(winner, payoutAmount);	

		// Incremement the vars
		payoutNumber += 1;
		totalPaidOut += payoutAmount / 2;

		emit JackpotPayout(payoutAmount / 2, winner, payoutNumber);
  }

	// Admin function to pull all tokens if we need to - like upgrading this contract
	function pullTokens(address _to) public onlyOwner {
    uint balance = Zethr.balanceOf(address(this));
    Zethr.transfer(_to, balance);
	}

  // Admin function to change zlots address if we need to
  function setZlotsAddress(address zlotsAddress) public onlyOwner {
    zlots = zlotsAddress;
  }

  // Token fallback to accept jackpot payments from Zlots
  // These tokens can come from anywhere, really - why restrict?
  function tokenFallback(address /*_from*/, uint /*_amountOfTokens*/, bytes/*_data*/) public returns (bool) {
    // Do nothing, we can track the jackpot by this balance
  }

	// View function - returns the jackpot amount
  function getJackpot() public view returns (uint) {
    return Zethr.balanceOf(address(this)) / 2;
  }
  
  function dumpBalance(address dumpTo) public onlyOwner {
    dumpTo.transfer(address(this).balance);
  }
}