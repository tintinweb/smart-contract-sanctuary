/**
 *Submitted for verification at arbiscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract Long {
  string public constant name = "LongTerm";

  string public constant symbol = "LONG";

  uint8 public constant decimals = 18;

  uint256 public totalSupply = 10000000e18;

  address public minter;

  uint256 public mintingAllowedAfter;

  uint32 public constant minimumTimeBetweenMints = 1 days * 365;

  uint8 public constant mintCap = 2;

  mapping(address => mapping(address => uint96)) internal allowances;

  mapping(address => uint96) internal balances;

  mapping(address => address) public delegates;

  struct Checkpoint {
    uint32 fromBlock;
    uint96 votes;
  }

  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  mapping(address => uint32) public numCheckpoints;

  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

  bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

  mapping(address => uint256) public nonces;

  event MinterChanged(address minter, address newMinter);

  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  constructor(
    address account,
    address minter_,
    uint256 mintingAllowedAfter_
  ) {
    require(
      mintingAllowedAfter_ >= block.timestamp,
      "Long::constructor: minting can only begin after deployment"
    );

    balances[account] = uint96(totalSupply);
    emit Transfer(address(0), account, totalSupply);
    minter = minter_;
    emit MinterChanged(address(0), minter);
    mintingAllowedAfter = mintingAllowedAfter_;
  }

  function setMinter(address minter_) external {
    require(
      msg.sender == minter,
      "Long::setMinter: only the minter can change the minter address"
    );
    emit MinterChanged(minter, minter_);
    minter = minter_;
  }

  function mint(address dst, uint256 rawAmount) external {
    require(msg.sender == minter, "Long::mint: only the minter can mint");
    require(
      block.timestamp >= mintingAllowedAfter,
      "Long::mint: minting not allowed yet"
    );
    require(
      dst != address(0),
      "Long::mint: cannot transfer to the zero address"
    );
    require(
      dst != address(this),
      "Long::mint: cannot transfer to the Long address"
    );

    mintingAllowedAfter = SafeMath.add(
      block.timestamp,
      minimumTimeBetweenMints
    );

    uint96 amount = safe96(rawAmount, "Long::mint: amount exceeds 96 bits");
    require(
      amount <= SafeMath.div(SafeMath.mul(totalSupply, mintCap), 100),
      "Long::mint: exceeded mint cap"
    );
    totalSupply = safe96(
      SafeMath.add(totalSupply, amount),
      "Long::mint: totalSupply exceeds 96 bits"
    );

    balances[dst] = add96(
      balances[dst],
      amount,
      "Long::mint: transfer amount overflows"
    );
    emit Transfer(address(0), dst, amount);

    _moveDelegates(address(0), delegates[dst], amount);
  }

  function allowance(address account, address spender)
    external
    view
    returns (uint256)
  {
    return allowances[account][spender];
  }

  function _approve(
    address owner,
    address spender,
    uint96 amount
  ) internal virtual {
    require(
      owner != address(0),
      "Long::_approve: approve from the zero address"
    );
    require(
      spender != address(0),
      "Long::_approve: approve to the zero address"
    );

    allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function approve(address spender, uint256 rawAmount) external returns (bool) {
    uint96 amount;
    if (rawAmount == uint256(-1)) {
      amount = uint96(-1);
    } else {
      amount = safe96(rawAmount, "Long::approve: amount exceeds 96 bits");
    }
    _approve(msg.sender, spender, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    uint96 amount;
    if (addedValue == uint256(-1)) {
      amount = uint96(-1);
    } else {
      amount = safe96(
        addedValue,
        "Long::increaseAllowance: amount exceeds 96 bits"
      );
    }
    _approve(
      msg.sender,
      spender,
      add96(
        allowances[msg.sender][spender],
        amount,
        "Long::increaseAllowance: transfer amount overflows"
      )
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint96 amount;
    if (subtractedValue == uint256(-1)) {
      amount = uint96(-1);
    } else {
      amount = safe96(
        subtractedValue,
        "Long::decreaseAllowance: amount exceeds 96 bits"
      );
    }

    _approve(
      msg.sender,
      spender,
      sub96(
        allowances[msg.sender][spender],
        amount,
        "Long::decreaseAllowance: decreased allowance below zero"
      )
    );
    return true;
  }

  function permit(
    address owner,
    address spender,
    uint256 rawAmount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    uint96 amount;
    if (rawAmount == uint256(-1)) {
      amount = uint96(-1);
    } else {
      amount = safe96(rawAmount, "Long::permit: amount exceeds 96 bits");
    }

    bytes32 domainSeparator =
      keccak256(
        abi.encode(
          DOMAIN_TYPEHASH,
          keccak256(bytes(name)),
          getChainId(),
          address(this)
        )
      );
    bytes32 structHash =
      keccak256(
        abi.encode(
          PERMIT_TYPEHASH,
          owner,
          spender,
          rawAmount,
          nonces[owner]++,
          deadline
        )
      );
    bytes32 digest =
      keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Long::permit: invalid signature");
    require(signatory == owner, "Long::permit: unauthorized");
    require(block.timestamp <= deadline, "Long::permit: signature expired");

    allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  function transfer(address dst, uint256 rawAmount) external returns (bool) {
    uint96 amount = safe96(rawAmount, "Long::transfer: amount exceeds 96 bits");
    _transferTokens(msg.sender, dst, amount);
    return true;
  }

  function transferFrom(
    address src,
    address dst,
    uint256 rawAmount
  ) external returns (bool) {
    address spender = msg.sender;
    uint96 spenderAllowance = allowances[src][spender];
    uint96 amount = safe96(rawAmount, "Long::approve: amount exceeds 96 bits");

    if (spender != src && spenderAllowance != uint96(-1)) {
      uint96 newAllowance =
        sub96(
          spenderAllowance,
          amount,
          "Long::transferFrom: transfer amount exceeds spender allowance"
        );
      allowances[src][spender] = newAllowance;

      emit Approval(src, spender, newAllowance);
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 domainSeparator =
      keccak256(
        abi.encode(
          DOMAIN_TYPEHASH,
          keccak256(bytes(name)),
          getChainId(),
          address(this)
        )
      );
    bytes32 structHash =
      keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest =
      keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Long::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "Long::delegateBySig: invalid nonce");
    require(block.timestamp <= expiry, "Long::delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  function getCurrentVotes(address account) external view returns (uint96) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  function getPriorVotes(address account, uint256 blockNumber)
    public
    view
    returns (uint96)
  {
    require(
      blockNumber < block.number,
      "Long::getPriorVotes: not yet determined"
    );

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; 
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint96 delegatorBalance = balances[delegator];
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _transferTokens(
    address src,
    address dst,
    uint96 amount
  ) internal {
    require(
      src != address(0),
      "Long::_transferTokens: cannot transfer from the zero address"
    );
    require(
      dst != address(0),
      "Long::_transferTokens: cannot transfer to the zero address"
    );
    require(
      dst != address(this),
      "Long::_transferTokens: cannot transfer to the Long address"
    );

    balances[src] = sub96(
      balances[src],
      amount,
      "Long::_transferTokens: transfer amount exceeds balance"
    );
    balances[dst] = add96(
      balances[dst],
      amount,
      "Long::_transferTokens: transfer amount overflows"
    );
    emit Transfer(src, dst, amount);

    _moveDelegates(delegates[src], delegates[dst], amount);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint96 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld =
          srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint96 srcRepNew =
          sub96(srcRepOld, amount, "Long::_moveVotes: vote amount underflows");
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld =
          dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew =
          add96(dstRepOld, amount, "Long::_moveVotes: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint96 oldVotes,
    uint96 newVotes
  ) internal {
    uint32 blockNumber =
      safe32(
        block.number,
        "Long::_writeCheckpoint: block number exceeds 32 bits"
      );

    if (
      nCheckpoints > 0 &&
      checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
    ) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function safe96(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint96)
  {
    require(n < 2**96, errorMessage);
    return uint96(n);
  }

  function add96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function getChainId() internal pure returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}