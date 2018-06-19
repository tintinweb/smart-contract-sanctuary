pragma solidity ^0.4.18;

contract CrowdsaleParameters {
    ///////////////////////////////////////////////////////////////////////////
    // Production Config
    ///////////////////////////////////////////////////////////////////////////

    // ICO period timestamps:
    // 1524182400 = April 20, 2018.
    // 1529452800 = June 20, 2018.

    uint256 public constant generalSaleStartDate = 1524182400;
    uint256 public constant generalSaleEndDate = 1529452800;

    ///////////////////////////////////////////////////////////////////////////
    // QA Config
    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // Configuration Independent Parameters
    ///////////////////////////////////////////////////////////////////////////

    struct AddressTokenAllocation {
        address addr;
        uint256 amount;
    }

    AddressTokenAllocation internal generalSaleWallet = AddressTokenAllocation(0x5aCdaeF4fa410F38bC26003d0F441d99BB19265A, 22800000);
    AddressTokenAllocation internal bounty = AddressTokenAllocation(0xc1C77Ff863bdE913DD53fD6cfE2c68Dfd5AE4f7F, 2000000);
    AddressTokenAllocation internal partners = AddressTokenAllocation(0x307744026f34015111B04ea4D3A8dB9FdA2650bb, 3200000);
    AddressTokenAllocation internal team = AddressTokenAllocation(0xCC4271d219a2c33a92aAcB4C8D010e9FBf664D1c, 12000000);
    AddressTokenAllocation internal featureDevelopment = AddressTokenAllocation(0x06281A31e1FfaC1d3877b29150bdBE93073E043B, 0);
}


contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    *  Constructor
    *
    *  Sets contract owner to address of constructor caller
    */
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    *  Change Owner
    *
    *  Changes ownership of this contract. Only owner can call this method.
    *
    * @param newOwner - new owner&#39;s address
    */
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SBIToken is Owned, CrowdsaleParameters {
    using SafeMath for uint256;
    /* Public variables of the token */
    string public standard = &#39;ERC20/SBI&#39;;
    string public name = &#39;Subsoil Blockchain Investitions&#39;;
    string public symbol = &#39;SBI&#39;;
    uint8 public decimals = 18;

    /* Arrays of all balances */
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => mapping (address => bool)) private allowanceUsed;

    /* This generates a public event on the blockchain that will notify clients */

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Issuance(uint256 _amount); // triggered when the total supply is increased
    event Destruction(uint256 _amount); // triggered when the total supply is decreased

    event NewSBIToken(address _token);

    /* Miscellaneous */
    uint256 public totalSupply = 0; // 40000000;
    bool public transfersEnabled = true;

    /**
    *  Constructor
    *
    *  Initializes contract with initial supply tokens to the creator of the contract
    */

    function SBIToken() public {
        owner = msg.sender;
        mintToken(generalSaleWallet);
        mintToken(bounty);
        mintToken(partners);
        mintToken(team);
        NewSBIToken(address(this));
    }

    modifier transfersAllowed {
        require(transfersEnabled);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    /**
    *  1. Associate crowdsale contract address with this Token
    *  2. Allocate general sale amount
    *
    * @param _crowdsaleAddress - crowdsale contract address
    */
    function approveCrowdsale(address _crowdsaleAddress) external onlyOwner {
        approveAllocation(generalSaleWallet, _crowdsaleAddress);
    }

    function approveAllocation(AddressTokenAllocation tokenAllocation, address _crowdsaleAddress) internal {
        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint amount = tokenAllocation.amount * exponent;

        allowed[tokenAllocation.addr][_crowdsaleAddress] = amount;
        Approval(tokenAllocation.addr, _crowdsaleAddress, amount);
    }

    /**
    *  Get token balance of an address
    *
    * @param _address - address to query
    * @return Token balance of _address
    */
    function balanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address];
    }

    /**
    *  Get token amount allocated for a transaction from _owner to _spender addresses
    *
    * @param _owner - owner address, i.e. address to transfer from
    * @param _spender - spender address, i.e. address to transfer to
    * @return Remaining amount allowed to be transferred
    */

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    *  Send coins from sender&#39;s address to address specified in parameters
    *
    * @param _to - address to send to
    * @param _value - amount to send in Wei
    */

    function transfer(address _to, uint256 _value) public transfersAllowed onlyPayloadSize(2*32) returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    *  Create token and credit it to target address
    *  Created tokens need to vest
    *
    */
    function mintToken(AddressTokenAllocation tokenAllocation) internal {

        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint mintedAmount = tokenAllocation.amount * exponent;

        // Mint happens right here: Balance becomes non-zero from zero
        balances[tokenAllocation.addr] += mintedAmount;
        totalSupply += mintedAmount;

        // Emit Issue and Transfer events
        Issuance(mintedAmount);
        Transfer(address(this), tokenAllocation.addr, mintedAmount);
    }

    /**
    *  Allow another contract to spend some tokens on your behalf
    *
    * @param _spender - address to allocate tokens for
    * @param _value - number of tokens to allocate
    * @return True in case of success, otherwise false
    */
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2*32) returns (bool success) {
        require(_value == 0 || allowanceUsed[msg.sender][_spender] == false);
        allowed[msg.sender][_spender] = _value;
        allowanceUsed[msg.sender][_spender] = false;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    *  A contract attempts to get the coins. Tokens should be previously allocated
    *
    * @param _to - address to transfer tokens to
    * @param _from - address to transfer tokens from
    * @param _value - number of tokens to transfer
    * @return True in case of success, otherwise false
    */
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed onlyPayloadSize(3*32) returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
    *  Default method
    *
    *  This unnamed function is called whenever someone tries to send ether to
    *  it. Just revert transaction because there is nothing that Token can do
    *  with incoming ether.
    *
    *  Missing payable modifier prevents accidental sending of ether
    */
    function() public {}

    /**
    *  Enable or disable transfers
    *
    * @param _enable - True = enable, False = disable
    */
    function toggleTransfers(bool _enable) external onlyOwner {
        transfersEnabled = _enable;
    }
}

/**
 * @title SBIBank
 * @dev Bank contract that supports voting to withdraw money, cancel or refund
 * multiple payees claiming funds sent to this contract
 * according to the sbi tokens proportions they own and result of voting.
 */

contract SBIBank is Owned, CrowdsaleParameters {
    using SafeMath for uint256;
    string public name = &#39;Subsoil Blockchain Investitions Bank&#39;;
    SBIToken private token;
    uint256 public currentVotingDate = 0;
    uint public currentVotingAmount = 0;
    uint public allowedWithdraw = 0;
    uint public allowedRefund = 0;

    uint256 public toAllow = 0;
    uint256 public toCancel = 0;
    uint256 public toRefund = 0;

    // result of a voiting
    uint8 result = 0;

    address sbiBank = this;

    // investors votes
    mapping(address => uint8) public votes;
    // investors votes dates
    mapping(address => uint256) public voteDates;
    // investors refunded amounts of voting
    mapping(address => uint256) public alreadyRefunded;

    event NewIncomingFunds(uint indexed amount, address indexed sender);
    event NewVoting(uint256 indexed date, uint indexed amount);
    event NewVote(address indexed voter, uint256 indexed date, uint8 indexed proposal);
    event CancelVote(uint256 indexed date, uint indexed amount);
    event AllowVote(uint256 indexed date, uint indexed amount);
    event RefundVote(uint256 indexed date, uint indexed amount);
    event Refund(uint256 indexed date, uint256 indexed amount, address indexed investor);
    event Withdraw(uint256 indexed date, uint indexed amount);
  /**
   * @dev Constructor
   */
  function SBIBank(address _tokenAddress) public payable {
     token = SBIToken(_tokenAddress);
  }

  /**
   * @dev Start a new voting.
   * @param _amount The amount of the funds requested to transfer.
   */
  function addVoting(uint _amount) public onlyOwner {
    require(sbiBank.balance >= _amount);
    // can add only if previouse voiting closed
    require(currentVotingDate == 0 && currentVotingAmount == 0);
    currentVotingDate = now;
    currentVotingAmount = _amount;
    NewVoting(now, _amount);
  }
  /*
    returns current vote of investor
  */
  function voteOf(address voter) public constant returns (uint8 vote) {
    return votes[voter];
  }

   /**
   * @dev vote for only sbi tokens owners
   */
  function vote(uint8 proposal) public returns(uint8 prop) {
      require(token.balanceOf(msg.sender) > 0);
      require(now >= currentVotingDate && now <= currentVotingDate + 3 days);
      require(proposal == 1 || proposal == 2 || proposal == 3);
      // you can vote only once for current voiting
      require(voteDates[msg.sender] != currentVotingDate);

      alreadyRefunded[msg.sender] = 0;
      votes[msg.sender] = proposal;
      voteDates[msg.sender] = currentVotingDate;

      if(proposal == 1) {
          toAllow = toAllow + token.balanceOf(msg.sender);
      }
      if(proposal == 2) {
          toCancel = toCancel + token.balanceOf(msg.sender);
      }
      if(proposal == 3) {
          toRefund = toRefund + token.balanceOf(msg.sender);
      }
      NewVote(msg.sender, now, proposal);
      return proposal;
  }

  /**
   * @dev End current voting with 3 scenarios - toAllow, toCancel or toRefund
   */
  function endVoting() public onlyOwner {
      require(currentVotingDate > 0 && now >= currentVotingDate + 3 days);
      if (toAllow > toCancel && toAllow > toRefund) {
          // toAllow withdraw
          AllowVote(currentVotingDate, toAllow);
          allowedWithdraw = currentVotingAmount;
          allowedRefund = 0;
      }
      if (toCancel > toAllow && toCancel > toRefund) {
          // toCancel voiting
          CancelVote(currentVotingDate, toCancel);
          allowedWithdraw = 0;
          allowedRefund = 0;
      }
      if (toRefund > toAllow && toRefund > toCancel) {
          // toCancel voiting
          RefundVote(currentVotingDate, toRefund);
          allowedRefund = currentVotingAmount;
          allowedWithdraw = 0;
      }
      currentVotingDate = 0;
      currentVotingAmount = 0;
      toAllow = 0;
      toCancel = 0;
      toRefund = 0;
  }

  /**
   * @dev Withdraw the current voiting amount
   */
  function withdraw() public onlyOwner {
      require(currentVotingDate == 0);
      require(allowedWithdraw > 0);
      owner.transfer(allowedWithdraw);
      Withdraw(now, allowedWithdraw);
      allowedWithdraw = 0;
  }

  /**
   * @dev End current voting with 3 scenarios - toAllow, toCancel or refund
   */
  function refund() public {
      require(allowedRefund > 0);
      // allows refund only once thrue the voiting
      require(alreadyRefunded[msg.sender] == 0);
      require(token.balanceOf(msg.sender) > 0);
      // total supply tokens is 40 000 000
      uint256 tokensPercent = token.balanceOf(msg.sender).div(40000000).div(1000000000000000);
      uint256 refundedAmount = tokensPercent.mul(sbiBank.balance).div(1000);
      address sender = msg.sender;
      alreadyRefunded[msg.sender] = refundedAmount;
      token.transferFrom(msg.sender, featureDevelopment.addr, token.balanceOf(msg.sender));
      sender.transfer(refundedAmount);
      Refund(now, refundedAmount, msg.sender);
  }

  /**
   * @dev payable fallback
   */
  function () external payable {
      NewIncomingFunds(msg.value, msg.sender);
  }
}