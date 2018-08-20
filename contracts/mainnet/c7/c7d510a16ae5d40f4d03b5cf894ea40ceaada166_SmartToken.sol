pragma solidity ^0.4.24;
pragma experimental "v0.5.0";
pragma experimental ABIEncoderV2;

library AddressExtension {

  function isValid(address _address) internal pure returns (bool) {
    return 0 != _address;
  }

  function isAccount(address _address) internal view returns (bool result) {
    assembly {
      result := iszero(extcodesize(_address))
    }
  }

  function toBytes(address _address) internal pure returns (bytes b) {
   assembly {
      let m := mload(0x40)
      mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, _address))
      mstore(0x40, add(m, 52))
      b := m
    }
  }
}

library Math {

  struct Fraction {
    uint256 numerator;
    uint256 denominator;
  }

  function isPositive(Fraction memory fraction) internal pure returns (bool) {
    return fraction.numerator > 0 && fraction.denominator > 0;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 r) {
    r = a * b;
    require((a == 0) || (r / a == b));
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 r) {
    r = a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 r) {
    require((r = a - b) <= a);
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 r) {
    require((r = a + b) >= a);
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 r) {
    return x <= y ? x : y;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256 r) {
    return x >= y ? x : y;
  }

  function mulDiv(uint256 value, uint256 m, uint256 d) internal pure returns (uint256 r) {
    r = value * m;
    if (r / value == m) {
      r /= d;
    } else {
      r = mul(value / d, m);
    }
  }

  function mulDivCeil(uint256 value, uint256 m, uint256 d) internal pure returns (uint256 r) {
    r = value * m;
    if (r / value == m) {
      if (r % d == 0) {
        r /= d;
      } else {
        r = (r / d) + 1;
      }
    } else {
      r = mul(value / d, m);
      if (value % d != 0) {
        r += 1;
      }
    }
  }

  function mul(uint256 x, Fraction memory f) internal pure returns (uint256) {
    return mulDiv(x, f.numerator, f.denominator);
  }

  function mulCeil(uint256 x, Fraction memory f) internal pure returns (uint256) {
    return mulDivCeil(x, f.numerator, f.denominator);
  }

  function div(uint256 x, Fraction memory f) internal pure returns (uint256) {
    return mulDiv(x, f.denominator, f.numerator);
  }

  function divCeil(uint256 x, Fraction memory f) internal pure returns (uint256) {
    return mulDivCeil(x, f.denominator, f.numerator);
  }

  function mul(Fraction memory x, Fraction memory y) internal pure returns (Math.Fraction) {
    return Math.Fraction({
      numerator: mul(x.numerator, y.numerator),
      denominator: mul(x.denominator, y.denominator)
    });
  }
}

contract FsTKAuthority {

  function isAuthorized(address sender, address _contract, bytes data) public view returns (bool);
  function isApproved(bytes32 hash, uint256 approveTime, bytes approveToken) public view returns (bool);
  function validate() public pure returns (bytes4);
}

contract Authorizable {

  event SetFsTKAuthority(FsTKAuthority indexed _address);

  modifier onlyFsTKAuthorized {
    require(fstkAuthority.isAuthorized(msg.sender, this, msg.data));
    _;
  }
  modifier onlyFsTKApproved(bytes32 hash, uint256 approveTime, bytes approveToken) {
    require(fstkAuthority.isApproved(hash, approveTime, approveToken));
    _;
  }

  FsTKAuthority internal fstkAuthority;

  constructor(FsTKAuthority _fstkAuthority) internal {
    fstkAuthority = _fstkAuthority;
  }

  function setFsTKAuthority(FsTKAuthority _fstkAuthority) public onlyFsTKAuthorized {
    require(_fstkAuthority.validate() == _fstkAuthority.validate.selector);
    emit SetFsTKAuthority(fstkAuthority = _fstkAuthority);
  }
}

contract IssuerContract {
  using AddressExtension for address;

  event SetIssuer(address indexed _address);

  modifier onlyIssuer {
    require(issuer == msg.sender);
    _;
  }

  address public issuer;
  address public newIssuer;

  constructor(address _issuer) internal {
    issuer = _issuer;
  }

  function setIssuer(address _address) public onlyIssuer {
    newIssuer = _address;
  }

  function confirmSetIssuer() public {
    require(newIssuer == msg.sender);
    emit SetIssuer(issuer = newIssuer);
    delete newIssuer;
  }
}

contract ERC20 {

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function balanceOf(address owner) public view returns (uint256);
  function allowance(address owner, address spender) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
}

contract SecureERC20 is ERC20 {

  event SetERC20ApproveChecking(bool approveChecking);

  function approve(address spender, uint256 expectedValue, uint256 newValue) public returns (bool);
  function increaseAllowance(address spender, uint256 value) public returns (bool);
  function decreaseAllowance(address spender, uint256 value, bool strict) public returns (bool);
  function setERC20ApproveChecking(bool approveChecking) public;
}

contract FsTKToken {

  enum DelegateMode { PublicMsgSender, PublicTxOrigin, PrivateMsgSender, PrivateTxOrigin }

  event Consume(address indexed from, uint256 value, bytes32 challenge);
  event IncreaseNonce(address indexed from, uint256 nonce);
  event SetupDirectDebit(address indexed debtor, address indexed receiver, DirectDebitInfo info);
  event TerminateDirectDebit(address indexed debtor, address indexed receiver);
  event WithdrawDirectDebitFailure(address indexed debtor, address indexed receiver);

  event SetMetadata(string metadata);
  event SetLiquid(bool liquidity);
  event SetDelegate(bool isDelegateEnable);
  event SetDirectDebit(bool isDirectDebitEnable);

  struct DirectDebitInfo {
    uint256 amount;
    uint256 startTime;
    uint256 interval;
  }
  struct DirectDebit {
    DirectDebitInfo info;
    uint256 epoch;
  }
  struct Instrument {
    uint256 allowance;
    DirectDebit directDebit;
  }
  struct Account {
    uint256 balance;
    uint256 nonce;
    mapping (address => Instrument) instruments;
  }

  function spendableAllowance(address owner, address spender) public view returns (uint256);
  function transfer(uint256[] data) public returns (bool);
  function transferAndCall(address to, uint256 value, bytes data) public payable returns (bool);

  function nonceOf(address owner) public view returns (uint256);
  function increaseNonce() public returns (bool);
  function delegateTransferAndCall(
    uint256 nonce,
    uint256 fee,
    uint256 gasAmount,
    address to,
    uint256 value,
    bytes data,
    DelegateMode mode,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public returns (bool);

  function directDebit(address debtor, address receiver) public view returns (DirectDebit);
  function setupDirectDebit(address receiver, DirectDebitInfo info) public returns (bool);
  function terminateDirectDebit(address receiver) public returns (bool);
  function withdrawDirectDebit(address debtor) public returns (bool);
  function withdrawDirectDebit(address[] debtors, bool strict) public returns (bool);
}

contract ERC20Like is SecureERC20, FsTKToken {
  using AddressExtension for address;
  using Math for uint256;

  modifier liquid {
    require(isLiquid);
     _;
  }
  modifier canUseDirectDebit {
    require(isDirectDebitEnable);
     _;
  }
  modifier canDelegate {
    require(isDelegateEnable);
     _;
  }

  bool public erc20ApproveChecking;
  bool public isLiquid = true;
  bool public isDelegateEnable;
  bool public isDirectDebitEnable;
  string public metadata;
  mapping(address => Account) internal accounts;

  constructor(string _metadata) public {
    metadata = _metadata;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return accounts[owner].balance;
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return accounts[owner].instruments[spender].allowance;
  }

  function transfer(address to, uint256 value) public liquid returns (bool) {
    Account storage senderAccount = accounts[msg.sender];

    senderAccount.balance = senderAccount.balance.sub(value);
    accounts[to].balance += value;

    emit Transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public liquid returns (bool) {
    Account storage fromAccount = accounts[from];
    Instrument storage senderInstrument = fromAccount.instruments[msg.sender];

    fromAccount.balance = fromAccount.balance.sub(value);
    senderInstrument.allowance = senderInstrument.allowance.sub(value);
    accounts[to].balance += value;

    emit Transfer(from, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    Instrument storage spenderInstrument = accounts[msg.sender].instruments[spender];
    if (erc20ApproveChecking) {
      require((value == 0) || (spenderInstrument.allowance == 0));
    }

    emit Approval(
      msg.sender,
      spender,
      spenderInstrument.allowance = value
    );
    return true;
  }

  function setERC20ApproveChecking(bool approveChecking) public {
    emit SetERC20ApproveChecking(erc20ApproveChecking = approveChecking);
  }

  function approve(address spender, uint256 expectedValue, uint256 newValue) public returns (bool) {
    Instrument storage spenderInstrument = accounts[msg.sender].instruments[spender];
    require(spenderInstrument.allowance == expectedValue);

    emit Approval(
      msg.sender,
      spender,
      spenderInstrument.allowance = newValue
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 value) public returns (bool) {
    Instrument storage spenderInstrument = accounts[msg.sender].instruments[spender];

    emit Approval(
      msg.sender,
      spender,
      spenderInstrument.allowance = spenderInstrument.allowance.add(value)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 value, bool strict) public returns (bool) {
    Instrument storage spenderInstrument = accounts[msg.sender].instruments[spender];

    uint256 currentValue = spenderInstrument.allowance;
    uint256 newValue;
    if (strict) {
      newValue = currentValue.sub(value);
    } else if (value < currentValue) {
      newValue = currentValue - value;
    }

    emit Approval(
      msg.sender,
      spender,
      spenderInstrument.allowance = newValue
    );
    return true;
  }

  function setMetadata0(string _metadata) internal {
    emit SetMetadata(metadata = _metadata);
  }

  function setLiquid0(bool liquidity) internal {
    emit SetLiquid(isLiquid = liquidity);
  }

  function setDelegate(bool delegate) public {
    emit SetDelegate(isDelegateEnable = delegate);
  }

  function setDirectDebit(bool directDebit) public {
    emit SetDirectDebit(isDirectDebitEnable = directDebit);
  }

  function spendableAllowance(address owner, address spender) public view returns (uint256) {
    Account storage ownerAccount = accounts[owner];
    return Math.min(
      ownerAccount.instruments[spender].allowance,
      ownerAccount.balance
    );
  }

  function transfer(uint256[] data) public liquid returns (bool) {
    Account storage senderAccount = accounts[msg.sender];
    uint256 totalValue;

    for (uint256 i = 0; i < data.length; i++) {
      address receiver = address(data[i] >> 96);
      uint256 value = data[i] & 0xffffffffffffffffffffffff;

      totalValue = totalValue.add(value);
      accounts[receiver].balance += value;

      emit Transfer(msg.sender, receiver, value);
    }

    senderAccount.balance = senderAccount.balance.sub(totalValue);

    return true;
  }

  function transferAndCall(
    address to,
    uint256 value,
    bytes data
  )
    public
    payable
    liquid
    returns (bool)
  {
    require(
      to != address(this) &&
      data.length >= 68 &&
      transfer(to, value)
    );
    assembly {
        mstore(add(data, 36), value)
        mstore(add(data, 68), caller)
    }
    require(to.call.value(msg.value)(data));
    return true;
  }

  function nonceOf(address owner) public view returns (uint256) {
    return accounts[owner].nonce;
  }

  function increaseNonce() public returns (bool) {
    emit IncreaseNonce(msg.sender, accounts[msg.sender].nonce += 1);
  }

  function delegateTransferAndCall(
    uint256 nonce,
    uint256 fee,
    uint256 gasAmount,
    address to,
    uint256 value,
    bytes data,
    DelegateMode mode,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
    liquid
    canDelegate
    returns (bool)
  {
    require(to != address(this));
    address signer;
    address relayer;
    if (mode == DelegateMode.PublicMsgSender) {
      signer = ecrecover(
        keccak256(abi.encodePacked(this, nonce, fee, gasAmount, to, value, data, mode, address(0))),
        v,
        r,
        s
      );
      relayer = msg.sender;
    } else if (mode == DelegateMode.PublicTxOrigin) {
      signer = ecrecover(
        keccak256(abi.encodePacked(this, nonce, fee, gasAmount, to, value, data, mode, address(0))),
        v,
        r,
        s
      );
      relayer = tx.origin;
    } else if (mode == DelegateMode.PrivateMsgSender) {
      signer = ecrecover(
        keccak256(abi.encodePacked(this, nonce, fee, gasAmount, to, value, data, mode, msg.sender)),
        v,
        r,
        s
      );
      relayer = msg.sender;
    } else if (mode == DelegateMode.PrivateTxOrigin) {
      signer = ecrecover(
        keccak256(abi.encodePacked(this, nonce, fee, gasAmount, to, value, data, mode, tx.origin)),
        v,
        r,
        s
      );
      relayer = tx.origin;
    } else {
      revert();
    }

    Account storage signerAccount = accounts[signer];
    require(nonce == signerAccount.nonce);
    emit IncreaseNonce(signer, signerAccount.nonce += 1);

    signerAccount.balance = signerAccount.balance.sub(value.add(fee));
    accounts[to].balance += value;
    if (fee != 0) {
      accounts[relayer].balance += fee;
      emit Transfer(signer, relayer, fee);
    }

    if (!to.isAccount() && data.length >= 68) {
      assembly {
        mstore(add(data, 36), value)
        mstore(add(data, 68), signer)
      }
      if (to.call.gas(gasAmount)(data)) {
        emit Transfer(signer, to, value);
      } else {
        signerAccount.balance += value;
        accounts[to].balance -= value;
      }
    } else {
      emit Transfer(signer, to, value);
    }

    return true;
  }

  function directDebit(address debtor, address receiver) public view returns (DirectDebit) {
    return accounts[debtor].instruments[receiver].directDebit;
  }

  function setupDirectDebit(
    address receiver,
    DirectDebitInfo info
  )
    public
    returns (bool)
  {
    accounts[msg.sender].instruments[receiver].directDebit = DirectDebit({
      info: info,
      epoch: 0
    });

    emit SetupDirectDebit(msg.sender, receiver, info);
    return true;
  }

  function terminateDirectDebit(address receiver) public returns (bool) {
    delete accounts[msg.sender].instruments[receiver].directDebit;

    emit TerminateDirectDebit(msg.sender, receiver);
    return true;
  }

  function withdrawDirectDebit(address debtor) public liquid canUseDirectDebit returns (bool) {
    Account storage debtorAccount = accounts[debtor];
    DirectDebit storage debit = debtorAccount.instruments[msg.sender].directDebit;
    uint256 epoch = (block.timestamp.sub(debit.info.startTime) / debit.info.interval).add(1);
    uint256 amount = epoch.sub(debit.epoch).mul(debit.info.amount);
    require(amount > 0);
    debtorAccount.balance = debtorAccount.balance.sub(amount);
    accounts[msg.sender].balance += amount;
    debit.epoch = epoch;

    emit Transfer(debtor, msg.sender, amount);
    return true;
  }

  function withdrawDirectDebit(address[] debtors, bool strict) public liquid canUseDirectDebit returns (bool result) {
    Account storage receiverAccount = accounts[msg.sender];
    result = true;
    uint256 total;

    for (uint256 i = 0; i < debtors.length; i++) {
      address debtor = debtors[i];
      Account storage debtorAccount = accounts[debtor];
      DirectDebit storage debit = debtorAccount.instruments[msg.sender].directDebit;
      uint256 epoch = (block.timestamp.sub(debit.info.startTime) / debit.info.interval).add(1);
      uint256 amount = epoch.sub(debit.epoch).mul(debit.info.amount);
      require(amount > 0);
      uint256 debtorBalance = debtorAccount.balance;

      if (amount > debtorBalance) {
        if (strict) {
          revert();
        }
        result = false;
        emit WithdrawDirectDebitFailure(debtor, msg.sender);
      } else {
        debtorAccount.balance = debtorBalance - amount;
        total += amount;
        debit.epoch = epoch;

        emit Transfer(debtor, msg.sender, amount);
      }
    }

    receiverAccount.balance += total;
  }
}

contract SmartToken is Authorizable, IssuerContract, ERC20Like {

  string public name;
  string public symbol;
  uint256 public totalSupply;
  uint8 public constant decimals = 18;

  constructor(
    address _issuer,
    FsTKAuthority _fstkAuthority,
    string _name,
    string _symbol,
    uint256 _totalSupply,
    string _metadata
  )
    Authorizable(_fstkAuthority)
    IssuerContract(_issuer)
    ERC20Like(_metadata)
    public
  {
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;

    accounts[_issuer].balance = _totalSupply;
    emit Transfer(address(0), _issuer, _totalSupply);
  }

  function setERC20ApproveChecking(bool approveChecking) public onlyIssuer {
    super.setERC20ApproveChecking(approveChecking);
  }

  function setDelegate(bool delegate) public onlyIssuer {
    super.setDelegate(delegate);
  }

  function setDirectDebit(bool directDebit) public onlyIssuer {
    super.setDirectDebit(directDebit);
  }

  function setMetadata(
    string infoUrl,
    uint256 approveTime,
    bytes approveToken
  )
    public
    onlyIssuer
    onlyFsTKApproved(keccak256(abi.encodePacked(approveTime, this, msg.sig, infoUrl)), approveTime, approveToken)
  {
    setMetadata0(infoUrl);
  }

  function setLiquid(
    bool liquidity,
    uint256 approveTime,
    bytes approveToken
  )
    public
    onlyIssuer
    onlyFsTKApproved(keccak256(abi.encodePacked(approveTime, this, msg.sig, liquidity)), approveTime, approveToken)
  {
    setLiquid0(liquidity);
  }
}