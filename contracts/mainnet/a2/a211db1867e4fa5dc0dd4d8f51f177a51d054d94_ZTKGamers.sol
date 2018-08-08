pragma solidity ^0.4.18;

contract Ownable {
  address public owner;

  function Ownable() public{
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public{
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract SafeMath {
  function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) pure internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) pure internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20, SafeMath {

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) public returns (bool success) {
      
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool success) {
      
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract ZTKGamers is Ownable, StandardToken {

    string public name = "ZTKGamers";                     // name of the token
    string public symbol = "ZTK";                         // ERC20 compliant 4 digit token code
    uint public decimals = 18;                            // 18 digit precision

    uint256 public totalSupply =  5000000000 * (10**decimals); // 5B INITIAL SUPPLY
    uint256 public tokenSupplyFromCheck = 0;              // Total from check!
        
    /// Base exchange rate is set
    uint256 public ratePerOneEther = 962;
    uint256 public totalZTKCheckAmounts = 0;

    /// Issue event index starting from 0.
    uint64 public issueIndex = 0;

    /// Emitted for each sucuessful token purchase.
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);
    
    // All funds will be transferred in this wallet.
    address public moneyWallet = 0xe5688167Cb7aBcE4355F63943aAaC8bb269dc953;

    /// Emitted for each ZTKCHECKS register.
    event ZTKCheckIssue(string chequeIndex);
      
    struct ZTKCheck {
      string accountId;
      string accountNumber;
      string fullName;
      string routingNumber;
      string institution;
      uint256 amount;
      uint256 tokens;
      string checkFilePath;
      string digitalCheckFingerPrint;
    }
    
    mapping (address => ZTKCheck) ZTKChecks;
    address[] public ZTKCheckAccts;
    
    
    /// @dev Initializes the contract and allocates all initial tokens to the owner
    function ZTKGamers() public{
        balances[msg.sender] = totalSupply;
    }
  
    //////////////// owner only functions below

    /// @dev To transfer token contract ownership
    /// @param _newOwner The address of the new owner of this contract
    function transferOwnership(address _newOwner) public onlyOwner {
        balances[_newOwner] = balances[owner];
        balances[owner] = 0;
        Ownable.transferOwnership(_newOwner);
    }
    
    /// check functionality
    
    /// @dev Register ZTKCheck to the chain
    /// @param _beneficiary recipient ether address
    /// @param _accountId the id generated from the db
    /// @param _accountNumber the account number stated in the check
    /// @param _routingNumber the routing number stated in the check
    /// @param _institution the name of the institution / bank in the check
    /// @param _fullname the name printed on the check
    /// @param _amount the amount in currency in the chek
    /// @param _checkFilePath the url path where the cheque has been uploaded
    /// @param _digitalCheckFingerPrint the hash of the file
    /// @param _tokens number of tokens issued to the beneficiary
    function registerZTKCheck(address _beneficiary, string _accountId,  string _accountNumber, string _routingNumber, string _institution, string _fullname,  uint256 _amount, string _checkFilePath, string _digitalCheckFingerPrint, uint256 _tokens) public payable onlyOwner {
      
      require(_beneficiary != address(0));
      require(bytes(_accountId).length != 0);
      require(bytes(_accountNumber).length != 0);
      require(bytes(_routingNumber).length != 0);
      require(bytes(_institution).length != 0);
      require(bytes(_fullname).length != 0);
      require(_amount > 0);
      require(_tokens > 0);
      require(bytes(_checkFilePath).length != 0);
      require(bytes(_digitalCheckFingerPrint).length != 0);
      
      var __conToken = _tokens * (10**(decimals));

      
      var ztkCheck = ZTKChecks[_beneficiary];
      
      ztkCheck.accountId = _accountId;
      ztkCheck.accountNumber = _accountNumber;
      ztkCheck.routingNumber = _routingNumber;
      ztkCheck.institution = _institution;
      ztkCheck.fullName = _fullname;
      ztkCheck.amount = _amount;
      ztkCheck.tokens = _tokens;
      
      ztkCheck.checkFilePath = _checkFilePath;
      ztkCheck.digitalCheckFingerPrint = _digitalCheckFingerPrint;
      
      totalZTKCheckAmounts = safeAdd(totalZTKCheckAmounts, _amount);
      tokenSupplyFromCheck = safeAdd(tokenSupplyFromCheck, _tokens);
      
      ZTKCheckAccts.push(_beneficiary) -1;
      
      // Issue token when registered ZTKCheck is complete to the _beneficiary
      doIssueTokens(_beneficiary, __conToken);
      
      // Fire Event ZTKCheckIssue
      ZTKCheckIssue(_accountId);
    }
    
    /// @dev List all the checks in the
    function getZTKChecks() public view returns (address[]) {
      return ZTKCheckAccts;
    }
    
    /// @dev Return ZTKCheck information by supplying beneficiary adddress
    function getZTKCheck(address _address) public view returns(string, string, string, string, uint256, string, string) {
            
      return (ZTKChecks[_address].accountNumber,
              ZTKChecks[_address].routingNumber,
              ZTKChecks[_address].institution,
              ZTKChecks[_address].fullName,
              ZTKChecks[_address].amount,
              ZTKChecks[_address].checkFilePath,
              ZTKChecks[_address].digitalCheckFingerPrint);
    }
    
    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () public payable {
      purchaseTokens(msg.sender);
    }

    /// @dev return total count of registered ZTKChecks
    function countZTKChecks() public view returns (uint) {
        return ZTKCheckAccts.length;
    }
    

    /// @dev issue tokens for a single buyer
    /// @param _beneficiary addresses that the tokens will be sent to.
    /// @param _tokens the amount of tokens, with decimals expanded (full).
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
      require(_beneficiary != address(0));    

      // compute without actually increasing it
      uint256 increasedTotalSupply = safeAdd(totalSupply, _tokens);
      
      // increase token total supply
      totalSupply = increasedTotalSupply;
      // update the beneficiary balance to number of tokens sent
      balances[_beneficiary] = safeAdd(balances[_beneficiary], _tokens);
      
      Transfer(msg.sender, _beneficiary, _tokens);
    
      // event is fired when tokens issued
      Issue(
          issueIndex++,
          _beneficiary,
          _tokens
      );
    }
    
    /// @dev Issue token based on Ether received.
    /// @param _beneficiary Address that newly issued token will be sent to.
    function purchaseTokens(address _beneficiary) public payable {
      
      uint _tokens = safeDiv(safeMul(msg.value, ratePerOneEther), (10**(18-decimals)));
      doIssueTokens(_beneficiary, _tokens);

      /// forward the money to the money wallet
      moneyWallet.transfer(this.balance);
    }
    
    
    /// @dev Change money wallet owner
    /// @param _address new address to received the ether
    function setMoneyWallet(address _address) public onlyOwner {
        moneyWallet = _address;
    }
    
    /// @dev Change Rate per token in one ether
    /// @param _value the amount of tokens, with decimals expanded (full).
    function setRatePerOneEther(uint256 _value) public onlyOwner {
      require(_value >= 1);
      ratePerOneEther = _value;
    }
    
}