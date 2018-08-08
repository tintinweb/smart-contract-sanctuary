pragma solidity ^0.4.23;

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
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract ERC223 is ERC20 {
  function transfer(address to, uint value, bytes data) returns (bool ok);
  function transferFrom(address from, address to, uint value, bytes data) returns (bool ok);
}



/*
Base class contracts willing to accept ERC223 token transfers must conform to.

Sender: msg.sender to the token contract, the address originating the token transfer.
          - For user originated transfers sender will be equal to tx.origin
          - For contract originated transfers, tx.origin will be the user that made the tx that produced the transfer.
Origin: the origin address from whose balance the tokens are sent
          - For transfer(), origin = msg.sender
          - For transferFrom() origin = _from to token contract
Value is the amount of tokens sent
Data is arbitrary data sent with the token transfer. Simulates ether tx.data

From, origin and value shouldn&#39;t be trusted unless the token contract is trusted.
If sender == tx.origin, it is safe to trust it regardless of the token.
*/

contract ERC223Receiver {
  function tokenFallback(address _sender, address _origin, uint _value, bytes _data) returns (bool ok);
}







/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  /*function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }*/
}


/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMath {
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  function transfer(address _to, uint _value) returns (bool success) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];
    // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract KinguinKrowns is ERC223, StandardToken {
  address public owner;  // token owner adddres
  string public constant name = "PINGUINS";
  string public constant symbol = "PGS";
  uint8 public constant decimals = 18;
  // uint256 public totalSupply; // defined in ERC20 contract
		
  function KinguinKrowns() {
	owner = msg.sender;
    totalSupply = 100000000 * (10**18); // 100 mln
    balances[msg.sender] = totalSupply;
  } 
  
  /*
  //only do if call is from owner modifier
  modifier onlyOwner() {
    if (msg.sender != owner) throw;
    _;
  }*/
  
  //function that is called when a user or another contract wants to transfer funds
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
    //filtering if the target is a contract with bytecode inside it
    if (!super.transfer(_to, _value)) throw; // do a normal token transfer
    if (isContract(_to)) return contractFallback(msg.sender, _to, _value, _data);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value, bytes _data) returns (bool success) {
    if (!super.transferFrom(_from, _to, _value)) throw; // do a normal token transfer
    if (isContract(_to)) return contractFallback(_from, _to, _value, _data);
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    return transfer(_to, _value, new bytes(0));
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    return transferFrom(_from, _to, _value, new bytes(0));
  }

  //function that is called when transaction target is a contract
  function contractFallback(address _origin, address _to, uint _value, bytes _data) private returns (bool success) {
    ERC223Receiver receiver = ERC223Receiver(_to);
    return receiver.tokenFallback(msg.sender, _origin, _value, _data);
  }

  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private returns (bool is_contract) {
    // retrieve the size of the code on target address, this needs assembly
    uint length;
    assembly { length := extcodesize(_addr) }
    return length > 0;
  }
  
  // returns krown balance of given address 	
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
	
}

contract KinguinIco is SafeMath, ERC223Receiver {
  address constant public superOwner = 0xcEbb7454429830C92606836350569A17207dA857;
  address public owner;             // contract owner address
  address public api;               // address of api manager
  KinguinKrowns public krs;     // handler to KRS token contract
  
  // rounds data storage:
  struct IcoRoundData {
    uint rMinEthPayment;            // set minimum ETH payment
    uint rKrsUsdFixed;              // set KRS/USD fixed ratio for calculation of krown amount to be sent, 
    uint rKycTreshold;              // KYC treshold in EUR (needed for check whether incoming payment requires KYC/AML verified address)
    uint rMinKrsCap;                // minimum amount of KRS to be sent during a round
    uint rMaxKrsCap;                // maximum amount of KRS to be sent during a round
    uint rStartBlock;               // number of blockchain start block for a round
    uint rEndBlock;                 // number of blockchain end block for a round
    uint rEthPaymentsAmount;        // sum of ETH tokens received from participants during a round
    uint rEthPaymentsCount;         // counter of ETH payments during a round 
    uint rSentKrownsAmount;         // sum of ETH tokens received from participants during a round
    uint rSentKrownsCount;          // counter of KRS transactions during a round
    bool roundCompleted;            // flag whether a round has finished
  }
  mapping(uint => IcoRoundData) public icoRounds;  // table of rounds data: ico number, ico record
  
  mapping(address => bool) public allowedAdresses; // list of KYC/AML approved wallets: participant address, allowed/not allowed
  
  struct RoundPayments {            // structure for storing sum of payments
    uint round;
    uint amount;
  }
  // amount of payments from the same address during each round 
  //  (to catch multiple payments to check KYC/AML approvance): participant address, payments record
  mapping(address => RoundPayments) public paymentsFromAddress; 

  uint public ethEur;               // current EUR/ETH exchange rate (for AML check)
  uint public ethUsd;               // current ETH/USD exchange rate (sending KRS for ETH calc) 
  uint public krsUsd;               // current KRS/USD exchange rate (sending KRS for ETH calc)
  uint public rNo;                  // counter for rounds
  bool public icoInProgress;        // ico status flag
  bool public apiAccessDisabled;    // api access security flag
  
  event LogReceivedEth(address from, uint value, uint block); // publish an event about incoming ETH
  event LogSentKrs(address to, uint value, uint block); // publish an event about sent KRS

  // execution allowed only for contract superowner
  modifier onlySuperOwner() {
	require(msg.sender == superOwner);
    _;
  }

  // execution allowed only for contract owner
  modifier onlyOwner() {
	require(msg.sender == owner);
    _;
  }
  
  // execution allowed only for contract owner or api address
  modifier onlyOwnerOrApi() {
	require(msg.sender == owner || msg.sender == api);
    if (msg.sender == api && api != owner) {
      require(!apiAccessDisabled);
	}
    _;
  }
 
  function KinguinIco() {
    owner = msg.sender; // this contract owner
    api = msg.sender; // initially api address is the contract owner&#39;s address 
    krs = KinguinKrowns(0xdfb410994b66778bd6cc2c82e8ffe4f7b2870006); // KRS token 
  } 
 
  // receiving ETH and sending KRS
  function () payable {
    if(msg.sender != owner) { // if ETH comes from other than the contract owner address
      if(block.number >= icoRounds[rNo].rStartBlock && block.number <= icoRounds[rNo].rEndBlock && !icoInProgress) {
        icoInProgress = true;
      }  
      require(block.number >= icoRounds[rNo].rStartBlock && block.number <= icoRounds[rNo].rEndBlock && !icoRounds[rNo].roundCompleted); // allow payments only during the ico round
      require(msg.value >= icoRounds[rNo].rMinEthPayment); // minimum eth payment
	  require(ethEur > 0); // ETH/EUR rate for AML must be set earlier
	  require(ethUsd > 0); // ETH/USD rate for conversion to KRS
	  uint krowns4eth;
	  if(icoRounds[rNo].rKrsUsdFixed > 0) { // KRS has fixed ratio to USD
        krowns4eth = safeDiv(safeMul(safeMul(msg.value, ethUsd), uint(100)), icoRounds[rNo].rKrsUsdFixed);
	  } else { // KRS/USD is traded on exchanges
		require(krsUsd > 0); // KRS/USD rate for conversion to KRS
        krowns4eth = safeDiv(safeMul(safeMul(msg.value, ethUsd), uint(100)), krsUsd);
  	  }
      require(safeAdd(icoRounds[rNo].rSentKrownsAmount, krowns4eth) <= icoRounds[rNo].rMaxKrsCap); // krs cap per round

      if(paymentsFromAddress[msg.sender].round != rNo) { // on mappings all keys are possible, so there is no checking for its existence
        paymentsFromAddress[msg.sender].round = rNo; // on new round set to current round
        paymentsFromAddress[msg.sender].amount = 0; // zeroing amount on new round
      }   
      if(safeMul(ethEur, safeDiv(msg.value, 10**18)) >= icoRounds[rNo].rKycTreshold || // if payment from this sender requires to be from KYC/AML approved address
        // if sum of payments from this sender address requires to be from KYC/AML approved address
        safeMul(ethEur, safeDiv(safeAdd(paymentsFromAddress[msg.sender].amount, msg.value), 10**18)) >= icoRounds[rNo].rKycTreshold) { 
		require(allowedAdresses[msg.sender]); // only KYC/AML allowed address
      }

      icoRounds[rNo].rEthPaymentsAmount = safeAdd(icoRounds[rNo].rEthPaymentsAmount, msg.value);
      icoRounds[rNo].rEthPaymentsCount += 1; 
      paymentsFromAddress[msg.sender].amount = safeAdd(paymentsFromAddress[msg.sender].amount, msg.value);
      LogReceivedEth(msg.sender, msg.value, block.number);
      icoRounds[rNo].rSentKrownsAmount = safeAdd(icoRounds[rNo].rSentKrownsAmount, krowns4eth);
      icoRounds[rNo].rSentKrownsCount += 1;
      krs.transfer(msg.sender, krowns4eth);
      LogSentKrs(msg.sender, krowns4eth, block.number);
    } else { // owner can always pay-in (and trigger round start/stop)
	    if(block.number >= icoRounds[rNo].rStartBlock && block.number <= icoRounds[rNo].rEndBlock && !icoInProgress) {
          icoInProgress = true;
        }
        if(block.number > icoRounds[rNo].rEndBlock && icoInProgress) {
          endIcoRound();
        }
    }
  }

  // receiving tokens other than ETH
  
  // ERC223 receiver implementation - https://github.com/aragon/ERC23/blob/master/contracts/implementation/Standard223Receiver.sol
  Tkn tkn;

  struct Tkn {
    address addr;
    address sender;
    address origin;
    uint256 value;
    bytes data;
    bytes4 sig;
  }

  function tokenFallback(address _sender, address _origin, uint _value, bytes _data) returns (bool ok) {
    if (!supportsToken(msg.sender)) return false;
    return true;
  }

  function getSig(bytes _data) private returns (bytes4 sig) {
    uint l = _data.length < 4 ? _data.length : 4;
    for (uint i = 0; i < l; i++) {
      sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (l - 1 - i))));
    }
  }

  bool __isTokenFallback;

  modifier tokenPayable {
    if (!__isTokenFallback) throw;
    _;
  }
  
  function supportsToken(address token) returns (bool) {
    if (token == address(krs)) {
	  return true; 
    } else {
      revert();
	}
  }
  // end of ERC223 receiver implementation ------------------------------------


  // set up a new ico round  
  function newIcoRound(uint _rMinEthPayment, uint _rKrsUsdFixed, uint _rKycTreshold,
    uint _rMinKrsCap, uint _rMaxKrsCap, uint _rStartBlock, uint _rEndBlock) public onlyOwner {
    require(!icoInProgress);            // new round can be set up only after finished/cancelled the active one
    require(rNo < 25);                  // limit of 25 rounds (with pre-ico)
	rNo += 1;                           // increment round number, pre-ico has number 1
	icoRounds[rNo] = IcoRoundData(_rMinEthPayment, _rKrsUsdFixed, _rKycTreshold, _rMinKrsCap, _rMaxKrsCap, 
	  _rStartBlock, _rEndBlock, 0, 0, 0, 0, false); // rEthPaymentsAmount, rEthPaymentsCount, rSentKrownsAmount, rSentKrownsCount); 
  }
  
  // remove current round, params only - it does not refund any ETH!
  function removeCurrentIcoRound() public onlyOwner {
    require(icoRounds[rNo].rEthPaymentsAmount == 0); // only if there was no payment already
	require(!icoRounds[rNo].roundCompleted); // only current round can be removed
    icoInProgress = false;
    icoRounds[rNo].rMinEthPayment = 0;
    icoRounds[rNo].rKrsUsdFixed = 0;
    icoRounds[rNo].rKycTreshold = 0;
    icoRounds[rNo].rMinKrsCap = 0;
    icoRounds[rNo].rMaxKrsCap = 0;
    icoRounds[rNo].rStartBlock = 0;
    icoRounds[rNo].rEndBlock = 0;
    icoRounds[rNo].rEthPaymentsAmount = 0;
    icoRounds[rNo].rEthPaymentsCount = 0;
    icoRounds[rNo].rSentKrownsAmount = 0;
    icoRounds[rNo].rSentKrownsCount = 0;
    if(rNo > 0) rNo -= 1;
  }

  function changeIcoRoundEnding(uint _rEndBlock) public onlyOwner {
    require(icoRounds[rNo].rStartBlock > 0); // round must be set up earlier
    icoRounds[rNo].rEndBlock = _rEndBlock;  
  }
 
  // closes round automatically
  function endIcoRound() private {
    icoInProgress = false;
	icoRounds[rNo].rEndBlock = block.number;
	icoRounds[rNo].roundCompleted = true;
  }

  // close round manually - if needed  
  function endIcoRoundManually() public onlyOwner {
    endIcoRound();
  }
  
  // add a verified KYC/AML address
  function addAllowedAddress(address _address) public onlyOwnerOrApi {
    allowedAdresses[_address] = true;
  }
  function removeAllowedAddress(address _address) public onlyOwnerOrApi {
    delete allowedAdresses[_address];
  }

  // set exchange rate for ETH/EUR - needed for check whether incoming payment
  //  is more than xxxx EUR (thus requires KYC/AML verified address)
  function setEthEurRate(uint _ethEur) public onlyOwnerOrApi {
    ethEur = _ethEur;
  }

  // set exchange rate for ETH/USD
  function setEthUsdRate(uint _ethUsd) public onlyOwnerOrApi {
    ethUsd = _ethUsd;
  }

  // set exchange rate for KRS/USD
  function setKrsUsdRate(uint _krsUsd) public onlyOwnerOrApi {
    krsUsd = _krsUsd;
  }
  
  // set all three exchange rates: ETH/EUR, ETH/USD, KRS/USD
  function setAllRates(uint _ethEur, uint _ethUsd, uint _krsUsd) public onlyOwnerOrApi {
    ethEur = _ethEur;
    ethUsd = _ethUsd;
	  krsUsd = _krsUsd;
  }
  
  // send KRS from the contract to a given address (for BTC and FIAT payments)
  function sendKrs(address _receiver, uint _amount) public onlyOwnerOrApi {
    krs.transfer(_receiver, _amount);
  }

  // transfer KRS from other holder, up to amount allowed through krs.approve() function
  function getKrsFromApproved(address _from, uint _amount) public onlyOwnerOrApi {
    krs.transferFrom(_from, address(this), _amount);
  }
  
  // send ETH from the contract to a given address
  function sendEth(address _receiver, uint _amount) public onlyOwner {
    _receiver.transfer(_amount);
  }
 
  // disable/enable access from API - for security reasons
  function disableApiAccess(bool _disabled) public onlyOwner {
    apiAccessDisabled = _disabled;
  }
  
  // change API wallet address - for security reasons
  function changeApi(address _address) public onlyOwner {
    api = _address;
  }

  // change owner address
  function changeOwner(address _address) public onlySuperOwner {
    owner = _address;
  }
  
}

library MicroWalletLib {

    //change to production token address
    KinguinKrowns constant token = KinguinKrowns(0xdfb410994b66778bd6cc2c82e8ffe4f7b2870006);

    struct MicroWalletStorage {
        uint krsAmount ;
        address owner;
    }

    function toBytes(address a) private pure returns (bytes b){
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function processPayment(MicroWalletStorage storage self, address _sender) public {
        require(msg.sender == address(token));

        if (self.owner == _sender) {    //closing MicroWallet
            self.krsAmount = 0;
            return;
        }

        require(self.krsAmount > 0);
        
        uint256 currentBalance = token.balanceOf(address(this));

        require(currentBalance >= self.krsAmount);

        if(currentBalance > self.krsAmount) {
            //return rest of the token
            require(token.transfer(_sender, currentBalance - self.krsAmount));
        }

        require(token.transfer(self.owner, self.krsAmount, toBytes(_sender)));

        self.krsAmount = 0;
    }
}

contract KinguinVault is Ownable, ERC223Receiver {
    
    mapping(uint=>address) public microWalletPayments;
    mapping(uint=>address) public microWalletsAddrs;
    mapping(address=>uint) public microWalletsIDs;
    mapping(uint=>uint) public microWalletPaymentBlockNr;

    KinguinKrowns public token;
    uint public uncleSafeNr = 5;
    address public withdrawAddress;

    modifier onlyWithdraw() {
        require(withdrawAddress == msg.sender);
        _;
    }

    constructor(KinguinKrowns _token) public {
        token = _token;
        withdrawAddress = owner;
    }
    
    function createMicroWallet(uint productOrderID, uint krsAmount) onlyOwner public {
        require(productOrderID != 0 && microWalletsAddrs[productOrderID] == address(0x0));
        microWalletsAddrs[productOrderID] = new MicroWallet(krsAmount);
        microWalletsIDs[microWalletsAddrs[productOrderID]] = productOrderID;
    }

    function getMicroWalletAddress(uint productOrderID) public view returns(address) {
        return microWalletsAddrs[productOrderID];
    }

    function closeMicroWallet(uint productOrderID) onlyOwner public {
        token.transfer(microWalletsAddrs[productOrderID], 0);
    }

    function checkIfOnUncle(uint currentBlockNr, uint transBlockNr) private view returns (bool) {
        if((currentBlockNr - transBlockNr) < uncleSafeNr) {
            return true;
        }
        return false;
    }

    function setUncleSafeNr(uint newUncleSafeNr) onlyOwner public {
        uncleSafeNr = newUncleSafeNr;
    }

    function getProductOrderPayer(uint productOrderID) public view returns (address) {
        if (checkIfOnUncle(block.number, microWalletPaymentBlockNr[productOrderID])) {
            return 0;    
        }
        return microWalletPayments[productOrderID];
    }

    function tokenFallback(address _sender, address _origin, uint _value, bytes _data) public returns (bool)  {
        require(msg.sender == address(token));
        if(microWalletsIDs[_sender] > 0) {
            microWalletPayments[microWalletsIDs[_sender]] = bytesToAddr(_data);
            microWalletPaymentBlockNr[microWalletsIDs[_sender]] = block.number;
        }
        return true;
    }

    function setWithdrawAccount(address _addr) onlyWithdraw public {
        withdrawAddress = _addr;
    } 

    function withdrawKrowns(address wallet, uint amount) onlyWithdraw public {
        require(wallet != address(0x0));
        token.transfer(wallet, amount);
    }

    function bytesToAddr (bytes b) private pure returns (address) {
        uint result = 0;
        for (uint i = b.length-1; i+1 > 0; i--) {
            uint c = uint(b[i]);
            uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
            result += to_inc;
        }
        return address(result);
    }
}

contract MicroWallet is ERC223Receiver {
    
    MicroWalletLib.MicroWalletStorage private mwStorage;

    constructor(uint _krsAmount) public {
        mwStorage.krsAmount = _krsAmount;
        mwStorage.owner = msg.sender;
    }

    function tokenFallback(address _sender, address _origin, uint _value, bytes _data) public returns (bool)  {
        MicroWalletLib.processPayment(mwStorage, _sender);
        
        return true;
    }
}