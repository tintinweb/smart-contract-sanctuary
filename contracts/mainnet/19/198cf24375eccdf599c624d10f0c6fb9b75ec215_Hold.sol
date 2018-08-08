pragma solidity ^0.4.18;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/*
 * Manager that stores permitted addresses 
 */
contract PermissionManager is Ownable {
    mapping (address => bool) permittedAddresses;

    function addAddress(address newAddress) public onlyOwner {
        permittedAddresses[newAddress] = true;
    }

    function removeAddress(address remAddress) public onlyOwner {
        permittedAddresses[remAddress] = false;
    }

    function isPermitted(address pAddress) public view returns(bool) {
        if (permittedAddresses[pAddress]) {
            return true;
        }
        return false;
    }
}

contract Registry is Ownable {

  struct ContributorData {
    bool isActive;
    uint contributionETH;
    uint contributionUSD;
    uint tokensIssued;
    uint quoteUSD;
    uint contributionRNTB;
  }
  mapping(address => ContributorData) public contributorList;
  mapping(uint => address) private contributorIndexes;

  uint private nextContributorIndex;

  /* Permission manager contract */
  PermissionManager public permissionManager;

  bool public completed;

  modifier onlyPermitted() {
    require(permissionManager.isPermitted(msg.sender));
    _;
  }

  event ContributionAdded(address _contributor, uint overallEth, uint overallUSD, uint overallToken, uint quote);
  event ContributionEdited(address _contributor, uint overallEth, uint overallUSD,  uint overallToken, uint quote);
  function Registry(address pManager) public {
    permissionManager = PermissionManager(pManager); 
    completed = false;
  }

  function setPermissionManager(address _permadr) public onlyOwner {
    require(_permadr != 0x0);
    permissionManager = PermissionManager(_permadr);
  }

  function isActiveContributor(address contributor) public view returns(bool) {
    return contributorList[contributor].isActive;
  }

  function removeContribution(address contributor) public onlyPermitted {
    contributorList[contributor].isActive = false;
  }

  function setCompleted(bool compl) public onlyPermitted {
    completed = compl;
  }

  function addContribution(address _contributor, uint _amount, uint _amusd, uint _tokens, uint _quote ) public onlyPermitted {
    
    if (contributorList[_contributor].isActive == false) {
        contributorList[_contributor].isActive = true;
        contributorList[_contributor].contributionETH = _amount;
        contributorList[_contributor].contributionUSD = _amusd;
        contributorList[_contributor].tokensIssued = _tokens;
        contributorList[_contributor].quoteUSD = _quote;

        contributorIndexes[nextContributorIndex] = _contributor;
        nextContributorIndex++;
    } else {
      contributorList[_contributor].contributionETH += _amount;
      contributorList[_contributor].contributionUSD += _amusd;
      contributorList[_contributor].tokensIssued += _tokens;
      contributorList[_contributor].quoteUSD = _quote;
    }
    ContributionAdded(_contributor, contributorList[_contributor].contributionETH, contributorList[_contributor].contributionUSD, contributorList[_contributor].tokensIssued, contributorList[_contributor].quoteUSD);
  }

  function editContribution(address _contributor, uint _amount, uint _amusd, uint _tokens, uint _quote) public onlyPermitted {
    if (contributorList[_contributor].isActive == true) {
        contributorList[_contributor].contributionETH = _amount;
        contributorList[_contributor].contributionUSD = _amusd;
        contributorList[_contributor].tokensIssued = _tokens;
        contributorList[_contributor].quoteUSD = _quote;
    }
     ContributionEdited(_contributor, contributorList[_contributor].contributionETH, contributorList[_contributor].contributionUSD, contributorList[_contributor].tokensIssued, contributorList[_contributor].quoteUSD);
  }

  function addContributor(address _contributor, uint _amount, uint _amusd, uint _tokens, uint _quote) public onlyPermitted {
    contributorList[_contributor].isActive = true;
    contributorList[_contributor].contributionETH = _amount;
    contributorList[_contributor].contributionUSD = _amusd;
    contributorList[_contributor].tokensIssued = _tokens;
    contributorList[_contributor].quoteUSD = _quote;
    contributorIndexes[nextContributorIndex] = _contributor;
    nextContributorIndex++;
    ContributionAdded(_contributor, contributorList[_contributor].contributionETH, contributorList[_contributor].contributionUSD, contributorList[_contributor].tokensIssued, contributorList[_contributor].quoteUSD);
 
  }

  function getContributionETH(address _contributor) public view returns (uint) {
      return contributorList[_contributor].contributionETH;
  }

  function getContributionUSD(address _contributor) public view returns (uint) {
      return contributorList[_contributor].contributionUSD;
  }

  function getContributionRNTB(address _contributor) public view returns (uint) {
      return contributorList[_contributor].contributionRNTB;
  }

  function getContributionTokens(address _contributor) public view returns (uint) {
      return contributorList[_contributor].tokensIssued;
  }

  function addRNTBContribution(address _contributor, uint _amount) public onlyPermitted {
    if (contributorList[_contributor].isActive == false) {
        contributorList[_contributor].isActive = true;
        contributorList[_contributor].contributionRNTB = _amount;
        contributorIndexes[nextContributorIndex] = _contributor;
        nextContributorIndex++;
    } else {
      contributorList[_contributor].contributionETH += _amount;
    }
  }

  function getContributorByIndex(uint index) public view  returns (address) {
      return contributorIndexes[index];
  }

  function getContributorAmount() public view returns(uint) {
      return nextContributorIndex;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract {

  struct TKN {
    address sender;
    uint value;
    bytes data;
    bytes4 sig;
  }

  /**
   * @dev Standard ERC223 function that will handle incoming token transfers.
   *
   * @param _from  Token sender address.
   * @param _value Amount of tokens.
   * @param _data  Transaction metadata.
   */
  function tokenFallback(address _from, uint _value, bytes _data) public pure {
    TKN memory tkn;
    tkn.sender = _from;
    tkn.value = _value;
    tkn.data = _data;
    if(_data.length > 0) {
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
    }

    /* tkn variable is analogue of msg variable of Ether transaction
    *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
    *  tkn.value the number of tokens that were sent   (analogue of msg.value)
    *  tkn.data is data of token transaction   (analogue of msg.data)
    *  tkn.sig is 4 bytes signature of function
    *  if data of token transaction is a function execution
    */
  }

}

contract ERC223Interface {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  function allowedAddressesOf(address who) public view returns (bool);
  function getTotalSupply() public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
  event TransferContract(address indexed from, address indexed to, uint value, bytes data);
}

/**
 * @title Unity Token is ERC223 token.
 * @author Vladimir Kovalchuk
 */

contract UnityToken is ERC223Interface {
  using SafeMath for uint;

  string public constant name = "Unity Token";
  string public constant symbol = "UNT";
  uint8 public constant decimals = 18;


  /* The supply is initially 100UNT to the precision of 18 decimals */
  uint public constant INITIAL_SUPPLY = 100000 * (10 ** uint(decimals));

  mapping(address => uint) balances; // List of user balances.
  mapping(address => bool) allowedAddresses;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function addAllowed(address newAddress) public onlyOwner {
    allowedAddresses[newAddress] = true;
  }

  function removeAllowed(address remAddress) public onlyOwner {
    allowedAddresses[remAddress] = false;
  }


  address public owner;

  /* Constructor initializes the owner&#39;s balance and the supply  */
  function UnityToken() public {
    owner = msg.sender;
    totalSupply = INITIAL_SUPPLY;
    balances[owner] = INITIAL_SUPPLY;
  }

  function getTotalSupply() public view returns (uint) {
    return totalSupply;
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    if (isContract(_to)) {
      require(allowedAddresses[_to]);
      if (balanceOf(msg.sender) < _value)
        revert();

      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
      TransferContract(msg.sender, _to, _value, _data);
      return true;
    }
    else {
      return transferToAddress(_to, _value, _data);
    }
  }


  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {

    if (isContract(_to)) {
      return transferToContract(_to, _value, _data);
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }

  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public returns (bool success) {
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if (isContract(_to)) {
      return transferToContract(_to, _value, empty);
    }
    else {
      return transferToAddress(_to, _value, empty);
    }
  }

  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
    //retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_addr)
    }
    return (length > 0);
  }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value)
      revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    require(allowedAddresses[_to]);
    if (balanceOf(msg.sender) < _value)
      revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    TransferContract(msg.sender, _to, _value, _data);
    return true;
  }


  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  function allowedAddressesOf(address _owner) public view returns (bool allowed) {
    return allowedAddresses[_owner];
  }
}

/**
 * @title Hold  contract.
 * @author Vladimir Kovalchuk
 */
contract Hold is Ownable {

    uint8 stages = 5;
    uint8 public percentage;
    uint8 public currentStage;
    uint public initialBalance;
    uint public withdrawed;
    
    address public multisig;
    Registry registry;

    PermissionManager public permissionManager;
    uint nextContributorToTransferEth;
    address public observer;
    uint dateDeployed;
    mapping(address => bool) private hasWithdrawedEth;

    event InitialBalanceChanged(uint balance);
    event EthReleased(uint ethreleased);
    event EthRefunded(address contributor, uint ethrefunded);
    event StageChanged(uint8 newStage);
    event EthReturnedToOwner(address owner, uint balance);

    modifier onlyPermitted() {
        require(permissionManager.isPermitted(msg.sender) || msg.sender == owner);
        _;
    }

    modifier onlyObserver() {
        require(msg.sender == observer || msg.sender == owner);
        _;
    }

    function Hold(address _multisig, uint cap, address pm, address registryAddress, address observerAddr) public {
        percentage = 100 / stages;
        currentStage = 0;
        multisig = _multisig;
        initialBalance = cap;
        dateDeployed = now;
        permissionManager = PermissionManager(pm);
        registry = Registry(registryAddress);
        observer = observerAddr;
    }

    function setPermissionManager(address _permadr) public onlyOwner {
        require(_permadr != 0x0);
        permissionManager = PermissionManager(_permadr);
    }

    function setObserver(address observerAddr) public onlyOwner {
        require(observerAddr != 0x0);
        observer = observerAddr;
    }

    function setInitialBalance(uint inBal) public {
        initialBalance = inBal;
        InitialBalanceChanged(inBal);
    }

    function releaseAllETH() onlyPermitted public {
        uint balReleased = getBalanceReleased();
        require(balReleased > 0);
        require(this.balance >= balReleased);
        multisig.transfer(balReleased);
        withdrawed += balReleased;
        EthReleased(balReleased);
    }

    function releaseETH(uint n) onlyPermitted public {
        require(this.balance >= n);
        require(getBalanceReleased() >= n);
        multisig.transfer(n);
        withdrawed += n;
        EthReleased(n);
    } 

    function getBalance() public view returns (uint) {
        return this.balance;
    }

    function changeStageAndReleaseETH() public onlyObserver {
        uint8 newStage = currentStage + 1;
        require(newStage <= stages);
        currentStage = newStage;
        StageChanged(newStage);
        releaseAllETH();
    }

    function changeStage() public onlyObserver {
        uint8 newStage = currentStage + 1;
        require(newStage <= stages);
        currentStage = newStage;
        StageChanged(newStage);
    }

    function getBalanceReleased() public view returns (uint) {
        return initialBalance * percentage * currentStage / 100 - withdrawed ;
    }

    function returnETHByOwner() public onlyOwner {
        require(now > dateDeployed + 183 days);
        uint balance = getBalance();
        owner.transfer(getBalance());
        EthReturnedToOwner(owner, balance);
    }

    function refund(uint _numberOfReturns) public onlyOwner {
        require(_numberOfReturns > 0);
        address currentParticipantAddress;

        for (uint cnt = 0; cnt < _numberOfReturns; cnt++) {
            currentParticipantAddress = registry.getContributorByIndex(nextContributorToTransferEth);
            if (currentParticipantAddress == 0x0) 
                return;

            if (!hasWithdrawedEth[currentParticipantAddress]) {
                uint EthAmount = registry.getContributionETH(currentParticipantAddress);
                EthAmount -=  EthAmount * (percentage / 100 * currentStage);

                currentParticipantAddress.transfer(EthAmount);
                EthRefunded(currentParticipantAddress, EthAmount);
                hasWithdrawedEth[currentParticipantAddress] = true;
            }
            nextContributorToTransferEth += 1;
        }
        
    }  

    function() public payable {

    }

  function getWithdrawed(address contrib) public onlyPermitted view returns (bool) {
    return hasWithdrawedEth[contrib];
  }
}