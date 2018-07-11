pragma solidity ^0.4.23;

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() public view returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public view returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer  tokens
  /// @param _value The amount of wei to be approved for transferthe
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract TrustyPoll is SafeMath {
  address public admin; //the admin address
  address public feeAccount; //the account that will receive fees
  address public tokenAddress; // the address of the TRP Token
  uint public fee; // fee for creating polls in TRP Tokens
  uint private optionId;
  uint private pollId;

  constructor(address admin_, address feeAccount_, address tokenAddress_, uint fee_) public {
    admin = admin_;
    feeAccount = feeAccount_;
    tokenAddress = tokenAddress_;
    fee = fee_;
  }
  
  struct Poll {
      uint id;
      bytes32 title;
    }

 struct Option {
      uint id;
      bytes32 title;
    }
    
    mapping(uint => mapping(address => uint)) public votes; //poll -> (user -> option)
    mapping(uint => mapping(uint => uint)) public pollVotesCount; //poll -> (option -> votesCount)
    mapping(uint => Option[]) public pollOptions; //poll -> options[]
    mapping(uint => address) public pollAuthors; //poll -> author
    mapping(uint => bytes32) public polls; // pollId -> pollTitle
  
  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  } 

  function changeAdmin(address admin_) onlyAdmin public {
    admin = admin_;
  }
  
  function changeFeeAccount(address feeAccount_) onlyAdmin public {
    feeAccount = feeAccount_;
  }  

  function changeFee(uint fee_) onlyAdmin public {
    require (fee_ < fee);
    fee = fee_;
  }
  
  function createPoll(bytes32 title) public {
      require(title != &#39;&#39;);

    //ensure approve() method of TRP Token is called before creating poll or this contract will not be able to do the transfer on your behalf.
    require(Token(tokenAddress).transferFrom(msg.sender, this, fee));

      pollId = safeAdd(pollId, 1);
      polls[pollId] = title;
      pollAuthors[pollId] = msg.sender;
  }
  
  function createOption(uint poll, bytes32 title) public {
      require(title != &#39;&#39;);
      require(pollAuthors[poll] == msg.sender);
      optionId  = safeAdd(optionId, 1);
      pollOptions[poll].push(Option(optionId, title));
  }
  
  function vote(uint poll, uint option) public {
    require(pollAuthors[poll] != msg.sender); // authors cannot vote
    require(option > 0);
    require(poll > 0);
    
    // if user already vote, remove the old vote;
    if (votes[poll][msg.sender] != 0) {
      pollVotesCount[poll][votes[poll][msg.sender]] = safeSub(pollVotesCount[poll][votes[poll][msg.sender]], 1);
    }
    
    pollVotesCount[poll][option] = safeAdd(pollVotesCount[poll][option], 1);
    
    // override previous response
    votes[poll][msg.sender] = option;
  }

  function getOptionTitleForPoll(uint poll, uint optionIndex) public view returns(bytes32){
       return pollOptions[poll][optionIndex].title;
  }

  function getOptionIdForPoll(uint poll, uint optionIndex) public view returns(uint){
       return pollOptions[poll][optionIndex].id;
  }
}