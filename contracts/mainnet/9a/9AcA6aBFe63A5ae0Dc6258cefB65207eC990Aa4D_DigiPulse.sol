pragma solidity ^0.4.4;

contract DigiPulse {

	// Token data for ERC20
  string public constant name = "DigiPulse";
  string public constant symbol = "DGT";
  uint8 public constant decimals = 8;
  mapping (address => uint256) public balanceOf;

  // Max available supply is 16581633 * 1e8 (incl. 100000 presale and 2% bounties)
  uint constant tokenSupply = 16125000 * 1e8;
  uint8 constant dgtRatioToEth = 250;
  uint constant raisedInPresale = 961735343125;
  mapping (address => uint256) ethBalanceOf;
  address owner;

  // For LIVE
  uint constant startOfIco = 1501833600; // 08/04/2017 @ 8:00am (UTC)
  uint constant endOfIco = 1504223999; // 08/31/2017 @ 23:59pm (UTC)

  uint allocatedSupply = 0;
  bool icoFailed = false;
  bool icoFulfilled = false;

  // Generate public event that will notify clients
	event Transfer(address indexed from, address indexed to, uint256 value);
  event Refund(address indexed _from, uint256 _value);

  // No special actions are required upon creation, so initialiser is left empty
  function DigiPulse() {
    owner = msg.sender;
  }

  // For future transfers of DGT
  function transfer(address _to, uint256 _value) {
    require (balanceOf[msg.sender] >= _value);          // Check if the sender has enough
    require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows

    balanceOf[msg.sender] -= _value;                    // Subtract from the sender
    balanceOf[_to] += _value;                           // Add the same to the recipient

    Transfer(msg.sender, _to, _value);
  }

  // logic which converts eth to dgt and stores in allocatedSupply
  function() payable external {
    // Abort if crowdfunding has reached an end
    require (now > startOfIco);
    require (now < endOfIco);
    require (!icoFulfilled);

    // Do not allow creating 0 tokens
    require (msg.value != 0);

    // Must adjust number of decimals, so the ratio will work as expected
    // From ETH 16 decimals to DGT 8 decimals
    uint256 dgtAmount = msg.value / 1e10 * dgtRatioToEth;
    require (dgtAmount < (tokenSupply - allocatedSupply));

    // Tier bonus calculations
    uint256 dgtWithBonus;
    uint256 applicable_for_tier;

    for (uint8 i = 0; i < 4; i++) {
      // Each tier has same amount of DGT
      uint256 tier_amount = 3750000 * 1e8;
      // Every next tier has 5% less bonus pool
      uint8 tier_bonus = 115 - (i * 5);
      applicable_for_tier += tier_amount;

      // Skipping over this tier, since it is filled already
      if (allocatedSupply >= applicable_for_tier) continue;

      // Reached this tier with 0 amount, so abort
      if (dgtAmount == 0) break;

      // Cases when part of the contribution is covering two tiers
      int256 diff = int(allocatedSupply) + int(dgtAmount - applicable_for_tier);

      if (diff > 0) {
        // add bonus for current tier and strip the difference for
        // calculation in the next tier
        dgtWithBonus += (uint(int(dgtAmount) - diff) * tier_bonus / 100);
        dgtAmount = uint(diff);
      } else {
        dgtWithBonus += (dgtAmount * tier_bonus / 100);
        dgtAmount = 0;
      }
    }

    // Increase supply
    allocatedSupply += dgtWithBonus;

    // Assign new tokens to the sender and log token creation event
    ethBalanceOf[msg.sender] += msg.value;
    balanceOf[msg.sender] += dgtWithBonus;
    Transfer(0, msg.sender, dgtWithBonus);
  }

  // Decide the state of the project
  function finalise() external {
    require (!icoFailed);
    require (!icoFulfilled);
    require (now > endOfIco || allocatedSupply >= tokenSupply);

    // Min cap is 8000 ETH
    if (this.balance < 8000 ether) {
      icoFailed = true;
    } else {
      setPreSaleAmounts();
      allocateBountyTokens();
      icoFulfilled = true;
    }
  }

  // If the goal is not reached till the end of the ICO
  // allow refunds
  function refundEther() external {
  	require (icoFailed);

    var ethValue = ethBalanceOf[msg.sender];
    require (ethValue != 0);
    ethBalanceOf[msg.sender] = 0;

    // Refund original Ether amount
    msg.sender.transfer(ethValue);
    Refund(msg.sender, ethValue);
  }

  // Returns balance raised in ETH from specific address
	function getBalanceInEth(address addr) returns(uint){
		return ethBalanceOf[addr];
	}

  // Returns balance raised in DGT from specific address
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balanceOf[_owner];
  }

	// Get remaining supply of DGT
	function getRemainingSupply() returns(uint) {
		return tokenSupply - allocatedSupply;
	}

  // Get raised amount during ICO
  function totalSupply() returns (uint totalSupply) {
    return allocatedSupply;
  }

  // Upon successfull ICO
  // Allow owner to withdraw funds
  function withdrawFundsToOwner(uint256 _amount) {
    require (icoFulfilled);
    require (this.balance >= _amount);

    owner.transfer(_amount);
  }

  // Raised during Pre-sale
  // Since some of the wallets in pre-sale were on exchanges, we transfer tokens
  // to account which will send tokens manually out
	function setPreSaleAmounts() private {
    balanceOf[0x8776A6fA922e65efcEa2371692FEFE4aB7c933AB] += raisedInPresale;
    allocatedSupply += raisedInPresale;
    Transfer(0, 0x8776A6fA922e65efcEa2371692FEFE4aB7c933AB, raisedInPresale);
	}

	// Bounty pool makes up 2% from all tokens bought
	function allocateBountyTokens() private {
    uint256 bountyAmount = allocatedSupply * 100 / 98 * 2 / 100;
		balanceOf[0x663F98e9c37B9bbA460d4d80ca48ef039eAE4052] += bountyAmount;
    allocatedSupply += bountyAmount;
    Transfer(0, 0x663F98e9c37B9bbA460d4d80ca48ef039eAE4052, bountyAmount);
	}
}