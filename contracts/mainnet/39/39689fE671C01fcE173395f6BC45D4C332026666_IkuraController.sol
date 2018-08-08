contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) constant returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        assert(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }

    function assert(bool x) internal {
        if (!x) throw;
    }
}





contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract DSMath {
    

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }



    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }



    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
        
        
        
        
        
        
        
        
        
        
        
        
        
        

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

contract IkuraStorage is DSMath, DSAuth {
  
  address[] ownerAddresses;

  
  mapping(address => uint) coinBalances;

  
  mapping(address => uint) tokenBalances;

  
  mapping(address => mapping (address => uint)) coinAllowances;

  
  uint _totalSupply = 0;

  
  
  
  uint _transferFeeRate = 500;

  
  
  
  uint8 _transferMinimumFee = 5;

  address tokenAddress;
  address multiSigAddress;
  address authorityAddress;

  
  
  
  function IkuraStorage() DSAuth() {
    /*address controllerAddress = 0x34c5605A4Ef1C98575DB6542179E55eE1f77A188;
    owner = controllerAddress;
    LogSetOwner(controllerAddress);*/
  }

  function changeToken(address tokenAddress_) auth {
    tokenAddress = tokenAddress_;
  }

  function changeAssociation(address multiSigAddress_) auth {
    multiSigAddress = multiSigAddress_;
  }

  function changeAuthority(address authorityAddress_) auth {
    authorityAddress = authorityAddress_;
  }

  function totalSupply() auth returns (uint) {
    return _totalSupply;
  }
  function addTotalSupply(uint amount) auth {
    _totalSupply = add(_totalSupply, amount);
  }
  function subTotalSupply(uint amount) auth {
    _totalSupply = sub(_totalSupply, amount);
  }
  function transferFeeRate() auth returns (uint) {
    return _transferFeeRate;
  }

  function setTransferFeeRate(uint newTransferFeeRate) auth returns (bool) {
    _transferFeeRate = newTransferFeeRate;

    return true;
  }

  
  
  

  function transferMinimumFee() auth returns (uint8) {
    return _transferMinimumFee;
  }

  function setTransferMinimumFee(uint8 newTransferMinimumFee) auth {
    _transferMinimumFee = newTransferMinimumFee;
  }

  function addOwnerAddress(address addr) internal returns (bool) {
    ownerAddresses.push(addr);

    return true;
  }

  function removeOwnerAddress(address addr) internal returns (bool) {
    uint i = 0;

    while (ownerAddresses[i] != addr) { i++; }

    while (i < ownerAddresses.length - 1) {
      ownerAddresses[i] = ownerAddresses[i + 1];
      i++;
    }

    ownerAddresses.length--;

    return true;
  }

  function primaryOwner() auth returns (address) {
    return ownerAddresses[0];
  }

  function isOwnerAddress(address addr) auth returns (bool) {
    for (uint i = 0; i < ownerAddresses.length; i++) {
      if (ownerAddresses[i] == addr) return true;
    }

    return false;
  }

  function numOwnerAddress() auth constant returns (uint) {
    return ownerAddresses.length;
  }

  
  
  

  function coinBalance(address addr) auth returns (uint) {
    return coinBalances[addr];
  }

  function addCoinBalance(address addr, uint amount) auth returns (bool) {
    coinBalances[addr] = add(coinBalances[addr], amount);

    return true;
  }

  function subCoinBalance(address addr, uint amount) auth returns (bool) {
    coinBalances[addr] = sub(coinBalances[addr], amount);

    return true;
  }

  
  
  

  function tokenBalance(address addr) auth returns (uint) {
    return tokenBalances[addr];
  }

  function addTokenBalance(address addr, uint amount) auth returns (bool) {
    tokenBalances[addr] = add(tokenBalances[addr], amount);

    if (tokenBalances[addr] > 0 && !isOwnerAddress(addr)) {
      addOwnerAddress(addr);
    }

    return true;
  }

  function subTokenBalance(address addr, uint amount) auth returns (bool) {
    tokenBalances[addr] = sub(tokenBalances[addr], amount);

    if (tokenBalances[addr] <= 0) {
      removeOwnerAddress(addr);
    }

    return true;
  }

  
  
  

  function coinAllowance(address owner_, address spender) auth returns (uint) {
    return coinAllowances[owner_][spender];
  }

  function addCoinAllowance(address owner_, address spender, uint amount) auth returns (bool) {
    coinAllowances[owner_][spender] = add(coinAllowances[owner_][spender], amount);

    return true;
  }

  function subCoinAllowance(address owner_, address spender, uint amount) auth returns (bool) {
    coinAllowances[owner_][spender] = sub(coinAllowances[owner_][spender], amount);

    return true;
  }

  function setCoinAllowance(address owner_, address spender, uint amount) auth returns (bool) {
    coinAllowances[owner_][spender] = amount;

    return true;
  }

  function isAuthorized(address src, bytes4 sig) internal returns (bool) {
    sig; 

    return  src == address(this) ||
            src == owner ||
            src == tokenAddress ||
            src == authorityAddress ||
            src == multiSigAddress;
  }
}

contract IkuraTokenEvent {
  /** オーナーがdJPYを鋳造した際に発火するイベント */
  event IkuraMint(address indexed owner, uint);

  /** オーナーがdJPYを消却した際に発火するイベント */
  event IkuraBurn(address indexed owner, uint);

  /** トークンの移動時に発火するイベント */
  event IkuraTransferToken(address indexed from, address indexed to, uint value);

  /** 手数料が発生したときに発火するイベント */
  event IkuraTransferFee(address indexed from, address indexed to, address indexed owner, uint value);

  event IkuraTransfer(address indexed from, address indexed to, uint value);

  /** 送金許可イベント */
  event IkuraApproval(address indexed owner, address indexed spender, uint value);
}

contract IkuraAssociation is DSMath, DSAuth {
  
  
  

  
  uint public confirmTotalTokenThreshold = 50;

  
  
  

  
  IkuraStorage _storage;
  IkuraToken _token;

  
  Proposal[] mintProposals;
  Proposal[] burnProposals;
  Proposal[] transferMinimumFeeProposals;
  Proposal[] transferFeeRateProposals;

  mapping (bytes32 => Proposal[]) proposals;

  struct Proposal {
    address proposer;                     
    bytes32 digest;                       
    bool executed;                        
    uint createdAt;                       
    uint expireAt;                        
    address[] confirmers;                 
    uint amount;                          
    uint8 transferMinimumFee;             
    uint transferFeeRate;                 
  }

  
  
  

  event MintProposalAdded(uint proposalId, address proposer, uint amount);
  event MintConfirmed(uint proposalId, address confirmer, uint amount);
  event MintExecuted(uint proposalId, address proposer, uint amount);

  event BurnProposalAdded(uint proposalId, address proposer, uint amount);
  event BurnConfirmed(uint proposalId, address confirmer, uint amount);
  event BurnExecuted(uint proposalId, address proposer, uint amount);

  event TransferMinimumFeeProposalAdded(uint proposalId, address proposer, uint8 transferMinimumFee);
  event TransferMinimumFeeConfirmed(uint proposalId, address confirmer, uint8 transferMinimumFee);
  event TransferMinimumFeeExecuted(uint proposalId, address proposer, uint8 transferMinimumFee);

  event TransferFeeRateProposalAdded(uint proposalId, address proposer, uint transferFeeRate);
  event TransferFeeRateConfirmed(uint proposalId, address confirmer, uint transferFeeRate);
  event TransferFeeRateExecuted(uint proposalId, address proposer, uint transferFeeRate);

  function IkuraAssociation() {
    proposals[sha3(&#39;mint&#39;)] = mintProposals;
    proposals[sha3(&#39;burn&#39;)] = burnProposals;
    proposals[sha3(&#39;transferMinimumFee&#39;)] = transferMinimumFeeProposals;
    proposals[sha3(&#39;transferFeeRate&#39;)] = transferFeeRateProposals;

  }

  function changeStorage(IkuraStorage newStorage) auth returns (bool) {
    _storage = newStorage;

    return true;
  }

  function changeToken(IkuraToken token_) auth returns (bool) {
    _token = token_;

    return true;
  }

  function newProposal(bytes32 type_, address proposer, uint amount, uint8 transferMinimumFee, uint transferFeeRate, bytes transationBytecode) returns (uint) {
    uint proposalId = proposals[type_].length++;
    Proposal proposal = proposals[type_][proposalId];
    proposal.proposer = proposer;
    proposal.amount = amount;
    proposal.transferMinimumFee = transferMinimumFee;
    proposal.transferFeeRate = transferFeeRate;
    proposal.digest = sha3(proposer, amount, transationBytecode);
    proposal.executed = false;
    proposal.createdAt = now;
    proposal.expireAt = proposal.createdAt + 86400;

    
    
    if (type_ == sha3(&#39;mint&#39;)) MintProposalAdded(proposalId, proposer, amount);
    if (type_ == sha3(&#39;burn&#39;)) BurnProposalAdded(proposalId, proposer, amount);
    if (type_ == sha3(&#39;transferMinimumFee&#39;)) TransferMinimumFeeProposalAdded(proposalId, proposer, transferMinimumFee);
    if (type_ == sha3(&#39;transferFeeRate&#39;)) TransferFeeRateProposalAdded(proposalId, proposer, transferFeeRate);

    
    confirmProposal(type_, proposer, proposalId);

    return proposalId;
  }

  function confirmProposal(bytes32 type_, address confirmer, uint proposalId) {
    Proposal proposal = proposals[type_][proposalId];

    
    if (hasConfirmed(type_, confirmer, proposalId)) throw;

    
    proposal.confirmers.push(confirmer);

    
    
    if (type_ == sha3(&#39;mint&#39;)) MintConfirmed(proposalId, confirmer, proposal.amount);
    if (type_ == sha3(&#39;burn&#39;)) BurnConfirmed(proposalId, confirmer, proposal.amount);
    if (type_ == sha3(&#39;transferMinimumFee&#39;)) TransferMinimumFeeConfirmed(proposalId, confirmer, proposal.transferMinimumFee);
    if (type_ == sha3(&#39;transferFeeRate&#39;)) TransferFeeRateConfirmed(proposalId, confirmer, proposal.transferFeeRate);

    if (isProposalExecutable(type_, proposalId, proposal.proposer, &#39;&#39;)) {
      proposal.executed = true;

      
      
      if (type_ == sha3(&#39;mint&#39;)) executeMintProposal(proposalId);
      if (type_ == sha3(&#39;burn&#39;)) executeBurnProposal(proposalId);
      if (type_ == sha3(&#39;transferMinimumFee&#39;)) executeUpdateTransferMinimumFeeProposal(proposalId);
      if (type_ == sha3(&#39;transferFeeRate&#39;)) executeUpdateTransferFeeRateProposal(proposalId);
    }
  }

  function hasConfirmed(bytes32 type_, address addr, uint proposalId) returns (bool) {
    Proposal proposal = proposals[type_][proposalId];
    uint length = proposal.confirmers.length;

    for (uint i = 0; i < length; i++) {
      if (proposal.confirmers[i] == addr) return true;
    }

    return false;
  }

  function confirmedTotalToken(bytes32 type_, uint proposalId) returns (uint) {
    Proposal proposal = proposals[type_][proposalId];
    uint length = proposal.confirmers.length;
    uint total = 0;

    for (uint i = 0; i < length; i++) {
      total = add(total, _storage.tokenBalance(proposal.confirmers[i]));
    }

    return total;
  }

  function proposalExpireAt(bytes32 type_, uint proposalId) returns (uint) {
    Proposal proposal = proposals[type_][proposalId];
    return proposal.expireAt;
  }

  function isProposalExecutable(bytes32 type_, uint proposalId, address proposer, bytes transactionBytecode) returns (bool) {
    Proposal proposal = proposals[type_][proposalId];

    
    if (_storage.numOwnerAddress() < 2) {
      return true;
    }

    return  proposal.digest == sha3(proposer, proposal.amount, transactionBytecode) &&
            isProposalNotExpired(type_, proposalId) &&
            div(mul(100, confirmedTotalToken(type_, proposalId)), _storage.totalSupply()) > confirmTotalTokenThreshold;
  }

  function numberOfProposals(bytes32 type_) constant returns (uint) {
    return proposals[type_].length;
  }

  function numberOfActiveProposals(bytes32 type_) constant returns (uint) {
    uint numActiveProposal = 0;

    for(uint i = 0; i < proposals[type_].length; i++) {
      Proposal proposal = proposals[type_][i];

      if (isProposalNotExpired(type_, i)) {
        numActiveProposal++;
      }
    }

    return numActiveProposal;
  }

  function isProposalNotExpired(bytes32 type_, uint proposalId) internal returns (bool) {
    Proposal proposal = proposals[type_][proposalId];

    return  !proposal.executed &&
            now < proposal.expireAt;
  }

  function executeMintProposal(uint proposalId) internal {
    Proposal proposal = proposals[sha3(&#39;mint&#39;)][proposalId];

    
    if (proposal.amount <= 0) throw;

    MintExecuted(proposalId, proposal.proposer, proposal.amount);

    
    _storage.addTotalSupply(proposal.amount);
    _storage.addCoinBalance(proposal.proposer, proposal.amount);
    _storage.addTokenBalance(proposal.proposer, proposal.amount);
  }

  function executeBurnProposal(uint proposalId) internal {
    Proposal proposal = proposals[sha3(&#39;burn&#39;)][proposalId];

    
    if (proposal.amount <= 0) throw;
    if (_storage.coinBalance(proposal.proposer) < proposal.amount) throw;
    if (_storage.tokenBalance(proposal.proposer) < proposal.amount) throw;

    BurnExecuted(proposalId, proposal.proposer, proposal.amount);

    
    _storage.subTotalSupply(proposal.amount);
    _storage.subCoinBalance(proposal.proposer, proposal.amount);
    _storage.subTokenBalance(proposal.proposer, proposal.amount);
  }

  function executeUpdateTransferMinimumFeeProposal(uint proposalId) internal {
    Proposal proposal = proposals[sha3(&#39;transferMinimumFee&#39;)][proposalId];

    if (proposal.transferMinimumFee < 0) throw;

    TransferMinimumFeeExecuted(proposalId, proposal.proposer, proposal.transferMinimumFee);

    _storage.setTransferMinimumFee(proposal.transferMinimumFee);
  }

  function executeUpdateTransferFeeRateProposal(uint proposalId) internal {
    Proposal proposal = proposals[sha3(&#39;transferFeeRate&#39;)][proposalId];

    if (proposal.transferFeeRate < 0) throw;

    TransferFeeRateExecuted(proposalId, proposal.proposer, proposal.transferFeeRate);

    _storage.setTransferFeeRate(proposal.transferFeeRate);
  }

  function isAuthorized(address src, bytes4 sig) internal returns (bool) {
    sig; 

    return  src == address(this) ||
            src == owner ||
            src == address(_token);
  }
}
library ProposalLibrary {
  
  
  

  
  struct Entity {
    IkuraStorage _storage;
    IkuraAssociation _association;
  }

  function changeStorage(Entity storage self, address storage_) internal {
    self._storage = IkuraStorage(storage_);
  }

  function changeAssociation(Entity storage self, address association_) internal {
    self._association = IkuraAssociation(association_);
  }

  function updateTransferMinimumFee(Entity storage self, address sender, uint8 fee) returns (bool) {
    if (fee < 0) throw;

    self._association.newProposal(sha3(&#39;transferMinimumFee&#39;), sender, 0, fee, 0, &#39;&#39;);

    return true;
  }

  function updateTransferFeeRate(Entity storage self, address sender, uint rate) returns (bool) {
    if (rate < 0) throw;

    self._association.newProposal(sha3(&#39;transferFeeRate&#39;), sender, 0, 0, rate, &#39;&#39;);

    return true;
  }

  function mint(Entity storage self, address sender, uint amount) returns (bool) {
    if (amount <= 0) throw;

    self._association.newProposal(sha3(&#39;mint&#39;), sender, amount, 0, 0, &#39;&#39;);

    return true;
  }

  function burn(Entity storage self, address sender, uint amount) returns (bool) {
    if (amount <= 0) throw;
    if (self._storage.coinBalance(sender) < amount) throw;
    if (self._storage.tokenBalance(sender) < amount) throw;

    self._association.newProposal(sha3(&#39;burn&#39;), sender, amount, 0, 0, &#39;&#39;);

    return true;
  }

  function confirmProposal(Entity storage self, address sender, bytes32 type_, uint proposalId) {
    self._association.confirmProposal(type_, sender, proposalId);
  }

  function numberOfProposals(Entity storage self, bytes32 type_) constant returns (uint) {
    return self._association.numberOfProposals(type_);
  }
}

contract IkuraToken is IkuraTokenEvent, DSMath, DSAuth {
  
  
  

  /*using ProposalLibrary for ProposalLibrary.Entity;
  ProposalLibrary.Entity proposalEntity;*/

  
  
  

  
  IkuraStorage _storage;
  IkuraAssociation _association;

  function IkuraToken() DSAuth() {
    
    
    
    /*address controllerAddress = 0x34c5605A4Ef1C98575DB6542179E55eE1f77A188;
    owner = controllerAddress;
    LogSetOwner(controllerAddress);*/
  }

  function totalSupply(address sender) auth constant returns (uint) {
    sender; 

    return _storage.totalSupply();
  }

  function balanceOf(address sender, address addr) auth constant returns (uint) {
    sender; 

    return _storage.coinBalance(addr);
  }

  function transfer(address sender, address to, uint amount) auth returns (bool success) {
    uint fee = transferFee(sender, sender, to, amount);

    if (_storage.coinBalance(sender) < add(amount, fee)) throw;
    if (amount <= 0) throw;

    
    address owner = selectOwnerAddressForTransactionFee(sender);

    
    _storage.subCoinBalance(sender, add(amount, fee));

    
    _storage.addCoinBalance(to, amount);

    
    _storage.addCoinBalance(owner, fee);

    
    IkuraTransfer(sender, to, amount);
    IkuraTransferFee(sender, to, owner, fee);

    return true;
  }

  function transferFrom(address sender, address from, address to, uint amount) auth returns (bool success) {
    uint fee = transferFee(sender, from, to, amount);

    if (_storage.coinBalance(from) < amount) throw;
    if (_storage.coinAllowance(from, sender) < amount) throw;
    if (amount <= 0) throw;
    if (add(_storage.coinBalance(to), amount) <= _storage.coinBalance(to)) throw;
    if (_storage.coinBalance(sender) < fee) throw;

    
    address owner = selectOwnerAddressForTransactionFee(sender);

    
    _storage.subCoinBalance(sender, fee);

    
    _storage.subCoinBalance(from, amount);

    
    _storage.subCoinAllowance(from, sender, amount);

    
    _storage.addCoinBalance(to, amount);

    
    _storage.addCoinBalance(owner, fee);

    
    IkuraTransfer(from, to, amount);

    return true;
  }

  function approve(address sender, address spender, uint amount) auth returns (bool success) {
    _storage.setCoinAllowance(sender, spender, amount);

    
    IkuraApproval(sender, spender, amount);

    return true;
  }


  function allowance(address sender, address owner, address spender) auth constant returns (uint remaining) {
    sender; 

    return _storage.coinAllowance(owner, spender);
  }

  
  
  


  function tokenBalanceOf(address sender, address owner) auth constant returns (uint balance) {
    sender; 

    return _storage.tokenBalance(owner);
  }


  function transferToken(address sender, address to, uint amount) auth returns (bool success) {
    if (_storage.tokenBalance(sender) < amount ) throw;
    if (amount <= 0) throw;
    if (add(_storage.tokenBalance(to), amount) <= _storage.tokenBalance(to)) throw;

    _storage.subTokenBalance(sender, amount);
    _storage.addTokenBalance(to, amount);

    IkuraTransferToken(sender, to, amount);

    return true;
  }


  function transferFeeRate(address sender) auth constant returns (uint) {
    sender; 

    return _storage.transferFeeRate();
  }


  function transferMinimumFee(address sender) auth constant returns (uint8) {
    sender; 

    return _storage.transferMinimumFee();
  }


  function transferFee(address sender, address from, address to, uint amount) auth returns (uint) {
    from; to; 

    uint rate = transferFeeRate(sender);
    uint denominator = 1000000; 
    uint numerator = mul(amount, rate);

    uint fee = div(numerator, denominator);
    uint remainder = sub(numerator, mul(denominator, fee));

    
    if (remainder > 0) {
      fee++;
    }

    if (fee < transferMinimumFee(sender)) {
      fee = transferMinimumFee(sender);
    }

    return fee;
  }


  function updateTransferMinimumFee(address sender, uint8 fee) auth returns (bool) {
    if (fee < 0) throw;

    _association.newProposal(sha3(&#39;transferMinimumFee&#39;), sender, 0, fee, 0, &#39;&#39;);
    return true;

    /*return proposalEntity.updateTransferMinimumFee(sender, fee);*/
  }


  function updateTransferFeeRate(address sender, uint rate) auth returns (bool) {
    if (rate < 0) throw;

    _association.newProposal(sha3(&#39;transferFeeRate&#39;), sender, 0, 0, rate, &#39;&#39;);
    return true;

    /*return proposalEntity.updateTransferFeeRate(sender, rate);*/
  }


  function selectOwnerAddressForTransactionFee(address sender) auth returns (address) {
    sender; 

    return _storage.primaryOwner();
  }

  function mint(address sender, uint amount) auth returns (bool) {
    if (amount <= 0) throw;

    _association.newProposal(sha3(&#39;mint&#39;), sender, amount, 0, 0, &#39;&#39;);

    /*return proposalEntity.mint(sender, amount);*/
  }


  function burn(address sender, uint amount) auth returns (bool) {
    if (amount <= 0) throw;
    if (_storage.coinBalance(sender) < amount) throw;
    if (_storage.tokenBalance(sender) < amount) throw;

    _association.newProposal(sha3(&#39;burn&#39;), sender, amount, 0, 0, &#39;&#39;);
    /*return proposalEntity.burn(sender, amount);*/
  }

  function confirmProposal(address sender, bytes32 type_, uint proposalId) auth {
    _association.confirmProposal(type_, sender, proposalId);
    /*proposalEntity.confirmProposal(sender, type_, proposalId);*/
  }


  function numberOfProposals(bytes32 type_) constant returns (uint) {
    return _association.numberOfProposals(type_);
    /*return proposalEntity.numberOfProposals(type_);*/
  }


  function changeAssociation(address association_) auth returns (bool) {
    _association = IkuraAssociation(association_);
    /*proposalEntity.changeAssociation(_association);*/

    return true;
  }


  function changeStorage(address storage_) auth returns (bool) {
    _storage = IkuraStorage(storage_);
    /*proposalEntity.changeStorage(_storage);*/

    return true;
  }


  function logicVersion(address sender) auth constant returns (uint) {
    sender; 

    return 1;
  }
}


contract IkuraAuthority is DSAuthority, DSAuth {
  
  IkuraStorage tokenStorage;

  
  
  mapping(bytes4 => bool) actionsWithToken;

  
  mapping(bytes4 => bool) actionsForbidden;

  
  
  
  function IkuraAuthority() DSAuth() {
    /*address controllerAddress = 0x34c5605A4Ef1C98575DB6542179E55eE1f77A188;
    owner = controllerAddress;
    LogSetOwner(controllerAddress);*/
  }


  function changeStorage(address storage_) auth {
    tokenStorage = IkuraStorage(storage_);

    
    actionsWithToken[stringToSig(&#39;mint(uint256)&#39;)] = true;
    actionsWithToken[stringToSig(&#39;burn(uint256)&#39;)] = true;
    actionsWithToken[stringToSig(&#39;updateTransferMinimumFee(uint8)&#39;)] = true;
    actionsWithToken[stringToSig(&#39;updateTransferFeeRate(uint256)&#39;)] = true;
    actionsWithToken[stringToSig(&#39;confirmProposal(string, uint256)&#39;)] = true;
    actionsWithToken[stringToSig(&#39;numberOfProposals(string)&#39;)] = true;

    
    actionsForbidden[stringToSig(&#39;forbiddenAction()&#39;)] = true;
  }

  function canCall(address src, address dst, bytes4 sig) constant returns (bool) {
    
    if (actionsWithToken[sig]) return canCallWithAssociation(src, dst);

    
    if (actionsForbidden[sig]) return canCallWithNoOne();

    
    return canCallDefault(src);
  }

  function canCallDefault(address src) internal constant returns (bool) {
    return tokenStorage.isOwnerAddress(src);
  }


  function canCallWithAssociation(address src, address dst) internal returns (bool) {
    
    dst;

    return tokenStorage.isOwnerAddress(src) &&
           (tokenStorage.numOwnerAddress() == 1 || tokenStorage.tokenBalance(src) > 0);
  }


  function canCallWithNoOne() internal constant returns (bool) {
    return false;
  }


  function stringToSig(string str) internal constant returns (bytes4) {
    return bytes4(sha3(str));
  }
}


contract IkuraController is ERC20, DSAuth {
  
  
  

  
  string public name = "XJP 0.6.0";

  
  string public constant symbol = "XJP";

  
  uint8 public constant decimals = 0;

  
  
  

  
  
  IkuraToken private token;

  
  IkuraStorage private tokenStorage;

  
  IkuraAuthority private authority;

  
  IkuraAssociation private association;

  
  
  

  function totalSupply() constant returns (uint) {
    return token.totalSupply(msg.sender);
  }

  function balanceOf(address addr) constant returns (uint) {
    return token.balanceOf(msg.sender, addr);
  }

  function transfer(address to, uint amount) returns (bool) {
    if (token.transfer(msg.sender, to, amount)) {
      Transfer(msg.sender, to, amount);

      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address from, address to, uint amount) returns (bool) {
    if (token.transferFrom(msg.sender, from, to, amount)) {
      Transfer(from, to, amount);

      return true;
    } else {
      return false;
    }
  }

  function approve(address spender, uint amount) returns (bool) {
    if (token.approve(msg.sender, spender, amount)) {
      Approval(msg.sender, spender, amount);

      return true;
    } else {
      return false;
    }
  }

  function allowance(address addr, address spender) constant returns (uint) {
    return token.allowance(msg.sender, addr, spender);
  }

  
  
  

  function tokenBalanceOf(address addr) constant returns (uint) {
    return token.tokenBalanceOf(msg.sender, addr);
  }

  function transferToken(address to, uint amount) returns (bool) {
    return token.transferToken(msg.sender, to, amount);
  }

  function transferFeeRate() constant returns (uint) {
    return token.transferFeeRate(msg.sender);
  }

  function transferMinimumFee() constant returns (uint8) {
    return token.transferMinimumFee(msg.sender);
  }

  function transferFee(address from, address to, uint amount) returns (uint) {
    return token.transferFee(msg.sender, from, to, amount);
  }

  

  function updateTransferMinimumFee(uint8 minimumFee) auth returns (bool) {
    return token.updateTransferMinimumFee(msg.sender, minimumFee);
  }

  function updateTransferFeeRate(uint feeRate) auth returns (bool) {
    return token.updateTransferFeeRate(msg.sender, feeRate);
  }

  function mint(uint amount) auth returns (bool) {
    return token.mint(msg.sender, amount);
  }

  function burn(uint amount) auth returns (bool) {
    return token.burn(msg.sender, amount);
  }

  function isOwner(address addr) auth returns (bool) {
    return tokenStorage.isOwnerAddress(addr);
  }


  function confirmProposal(string type_, uint proposalId) auth {
    token.confirmProposal(msg.sender, sha3(type_), proposalId);
  }

  function numOwnerAddress() auth constant returns (uint) {
    return tokenStorage.numOwnerAddress();
  }


  function numberOfProposals(string type_) auth constant returns (uint) {
    return token.numberOfProposals(sha3(type_));
  }

  
  
  


  function setup(address storageAddress, address tokenAddress, address authorityAddress, address associationAddress) auth {
    changeStorage(storageAddress);
    changeToken(tokenAddress);
    changeAuthority(authorityAddress);
    changeAssociation(associationAddress);
  }


  function changeToken(address tokenAddress) auth {
    
    token = IkuraToken(tokenAddress);

    
    tokenStorage.changeToken(token);
    token.changeStorage(tokenStorage);

    
    if (association != address(0)) {
      association.changeToken(token);
      token.changeAssociation(association);
    }
  }

  function changeStorage(address storageAddress) auth {
    
    tokenStorage = IkuraStorage(storageAddress);
  }


  function changeAuthority(address authorityAddress) auth {
    
    authority = IkuraAuthority(authorityAddress);
    setAuthority(authority);

    
    authority.changeStorage(tokenStorage);
    tokenStorage.changeAuthority(authority);
  }

  function changeAssociation(address associationAddress) auth {
    
    association = IkuraAssociation(associationAddress);

    
    association.changeStorage(tokenStorage);
    tokenStorage.changeAssociation(association);

    
    if (token != address(0)) {
      association.changeToken(token);
      token.changeAssociation(association);
    }
  }


  function forbiddenAction() auth returns (bool) {
    return true;
  }

 
  function logicVersion() constant returns (uint) {
    return token.logicVersion(msg.sender);
  }


  function isAuthorized(address src, bytes4 sig) internal returns (bool) {
    return  src == address(this) ||
            src == owner ||
            authority.canCall(src, this, sig);
  }
}