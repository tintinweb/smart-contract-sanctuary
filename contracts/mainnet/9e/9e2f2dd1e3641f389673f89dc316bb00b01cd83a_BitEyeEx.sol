pragma solidity ^0.4.19;

//ERC20 Token
contract Token {
  function totalSupply() constant returns (uint) {}
  function balanceOf(address _owner) constant returns (uint) {}
  function transfer(address _to, uint _value) returns (bool) {}
  function transferFrom(address _from, address _to, uint _value) returns (bool) {}
  function approve(address _spender, uint _value) returns (bool) {}
  function allowance(address _owner, address _spender) constant returns (uint) {}
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint256) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint256) {
    uint c = a / b;
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint256) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BitEyeEx is SafeMath {
  mapping (address => mapping (address => uint256)) public balances;
  mapping (bytes32 => bool) public traded;
  mapping (bytes32 => uint256) public orderFills;
  address public owner;
  address public feeAccount;
  mapping (address => bool) public signers;
  mapping (address => uint256) public cancels;
  mapping (bytes32 => bool) public withdraws;

  uint256 public teamLocked = 300000000 * 1e18;
  uint256 public teamClaimed = 0;
  uint256 public totalForMining = 600000000 * 1e18;
  uint256 public unmined = 600000000 * 1e18;
  mapping (address => uint256) public mined;
  address public BEY;
  mapping (address => uint256) public miningRate;
  bool public paused = false;
  

  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);
  event Cancel(address user, bytes32 orderHash, uint256 nonce);
  event Mine(address user, uint256 amount);
  event Release(address user, uint256 amount);

  function BitEyeEx(address _feeAccount) public {
    owner = msg.sender;
    feeAccount = _feeAccount;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    if (_newOwner != address(0)) {
      owner = _newOwner;
    }
  }

  function setFeeAccount(address _newFeeAccount) public onlyOwner {
    feeAccount = _newFeeAccount;
  }

  function addSigner(address _signer) public onlyOwner {
    signers[_signer] = true;
  }

  function removeSigner(address _signer) public onlyOwner {
    signers[_signer] = false;
  }

  function setBEY(address _addr) public onlyOwner {
    BEY = _addr;
  }

  function setMiningRate(address _quoteToken, uint256 _rate) public onlyOwner {
    miningRate[_quoteToken] = _rate;
  }

  function setPaused(bool _paused) public onlyOwner {
    paused = _paused;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlySigner() {
    require(signers[msg.sender]);
    _; 
  }

  modifier onlyNotPaused() {
    require(!paused);
    _;
  }

  function() external {
    revert();
  }

  function depositToken(address token, uint amount) public {
    balances[token][msg.sender] = safeAdd(balances[token][msg.sender], amount);
    require(Token(token).transferFrom(msg.sender, this, amount));
    Deposit(token, msg.sender, amount, balances[token][msg.sender]);
  }

  function deposit() public payable {
    balances[address(0)][msg.sender] = safeAdd(balances[address(0)][msg.sender], msg.value);
    Deposit(address(0), msg.sender, msg.value, balances[address(0)][msg.sender]);
  }

  function withdraw(address token, uint amount, uint nonce, address _signer, uint8 v, bytes32 r, bytes32 s) public {
    require(balances[token][msg.sender] >= amount);
    require(signers[_signer]);
    bytes32 hash = keccak256(this, msg.sender, token, amount, nonce);
    require(isValidSignature(_signer, hash, v, r, s));
    require(!withdraws[hash]);
    withdraws[hash] = true;

    balances[token][msg.sender] = safeSub(balances[token][msg.sender], amount);
    if (token == address(0)) {
      require(msg.sender.send(amount));
    } else {
      require(Token(token).transfer(msg.sender, amount));
    }
    Withdraw(token, msg.sender, amount, balances[token][msg.sender]);
  }

  function balanceOf(address token, address user) public view returns(uint) {
    return balances[token][user];
  }

  function updateCancels(address user, uint256 nonce) public onlySigner {
    require(nonce > cancels[user]);
    cancels[user] = nonce;
  }

  function getMiningRate(address _quoteToken) public view returns(uint256) {
    uint256 initialRate = miningRate[_quoteToken];
    if (unmined > 500000000e18){
      return initialRate;
    } else if (unmined > 400000000e18 && unmined <= 500000000e18){
      return initialRate * 9e17 / 1e18;
    } else if (unmined > 300000000e18 && unmined <= 400000000e18){
      return initialRate * 8e17 / 1e18;
    } else if (unmined > 200000000e18 && unmined <= 300000000e18){
      return initialRate * 7e17 / 1e18;
    } else if (unmined > 100000000e18 && unmined <= 200000000e18){
      return initialRate * 6e17 / 1e18;
    } else if(unmined <= 100000000e18) {
      return initialRate * 5e17 / 1e18;
    }
  }

  function trade(
      address[5] addrs,
      uint[11] vals,
      uint8[3] v,
      bytes32[6] rs
    ) public onlyNotPaused
    returns (bool)
  {
    require(signers[addrs[4]]);
    require(cancels[addrs[2]] < vals[2]);
    require(cancels[addrs[3]] < vals[5]);

    require(vals[6] > 0 && vals[7] > 0 && vals[8] > 0);
    require(vals[1] >= vals[7] && vals[4] >= vals[7]);
    require(msg.sender == addrs[2] || msg.sender == addrs[3] || msg.sender == addrs[4]);

    bytes32 buyHash = keccak256(address(this), addrs[0], addrs[1], addrs[2], vals[0], vals[1], vals[2]);
    bytes32 sellHash = keccak256(address(this), addrs[0], addrs[1], addrs[3], vals[3], vals[4], vals[5]);

    require(isValidSignature(addrs[2], buyHash, v[0], rs[0], rs[1]));
    require(isValidSignature(addrs[3], sellHash, v[1], rs[2], rs[3]));

    bytes32 tradeHash = keccak256(this, buyHash, sellHash, addrs[4], vals[6], vals[7], vals[8], vals[9], vals[10]);
    require(isValidSignature(addrs[4], tradeHash, v[2], rs[4], rs[5]));
    
    require(!traded[tradeHash]);
    traded[tradeHash] = true;
    
    require(safeAdd(orderFills[buyHash], vals[6]) <= vals[0]);
    require(safeAdd(orderFills[sellHash], vals[6]) <= vals[3]);
    require(balances[addrs[1]][addrs[2]] >= vals[7]);

    balances[addrs[1]][addrs[2]] = safeSub(balances[addrs[1]][addrs[2]], vals[7]);
    require(balances[addrs[0]][addrs[3]] >= vals[6]);
    balances[addrs[0]][addrs[3]] = safeSub(balances[addrs[0]][addrs[3]], vals[6]);
    balances[addrs[0]][addrs[2]] = safeAdd(balances[addrs[0]][addrs[2]], safeSub(vals[6], (safeMul(vals[6], vals[9]) / 1 ether)));
    balances[addrs[1]][addrs[3]] = safeAdd(balances[addrs[1]][addrs[3]], safeSub(vals[7], (safeMul(vals[7], vals[10]) / 1 ether)));
    
    balances[addrs[0]][feeAccount] = safeAdd(balances[addrs[0]][feeAccount], safeMul(vals[6], vals[9]) / 1 ether);
    balances[addrs[1]][feeAccount] = safeAdd(balances[addrs[1]][feeAccount], safeMul(vals[7], vals[10]) / 1 ether);

    orderFills[buyHash] = safeAdd(orderFills[buyHash], vals[6]);
    orderFills[sellHash] = safeAdd(orderFills[sellHash], vals[6]);

    // mining BEYs
    if(unmined > 0) {
      if(miningRate[addrs[1]] > 0){
        uint256 minedBEY = safeMul(safeMul(vals[7], getMiningRate(addrs[1])), 2) / 1 ether;
        if(unmined > minedBEY) {
          mined[addrs[2]] = safeAdd(mined[addrs[2]], minedBEY / 2);
          mined[addrs[3]] = safeAdd(mined[addrs[3]], minedBEY / 2);
          unmined = safeSub(unmined, minedBEY);
        } else {
          mined[addrs[2]] = safeAdd(mined[addrs[2]], unmined / 2);
          mined[addrs[3]] = safeAdd(mined[addrs[3]], safeSub(unmined, unmined / 2));
          unmined = 0;
        }
      }
    }
    return true;
  }

  function claim() public returns(bool) {
    require(mined[msg.sender] > 0);
    require(BEY != address(0));
    uint256 amount = mined[msg.sender];
    mined[msg.sender] = 0;
    require(Token(BEY).transfer(msg.sender, amount));
    Mine(msg.sender, amount);
    return true;
  }

  function claimByTeam() public onlyOwner returns(bool) {
    uint256 totalMined = safeSub(totalForMining, unmined);
    require(totalMined > 0);
    uint256 released = safeMul(teamLocked, totalMined) / totalForMining;
    uint256 amount = safeSub(released, teamClaimed);
    require(amount > 0);
    teamClaimed = released;
    require(Token(BEY).transfer(msg.sender, amount));
    Release(msg.sender, amount);
    return true;
  }

  function cancel(
    address baseToken, 
    address quoteToken, 
    address user,
    uint volume,
    uint fund,
    uint nonce,
    uint8 v,
    bytes32 r,
    bytes32 s) public onlySigner returns(bool)
  {

    bytes32 hash = keccak256(this, baseToken, quoteToken, user, volume, fund, nonce);
    require(isValidSignature(user, hash, v, r, s));
    orderFills[hash] = volume;
    Cancel(user, hash, nonce);
    return true;
  }
  
  function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
        pure
        returns (bool)
  {
    return signer == ecrecover(
      keccak256("\x19Ethereum Signed Message:\n32", hash),
      v,
      r,
      s
    );
  }
}