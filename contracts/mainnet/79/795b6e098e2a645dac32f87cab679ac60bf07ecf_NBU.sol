/**
 *Submitted for verification at Etherscan.io on 2020-12-21
*/

pragma solidity =0.7.6;

// ----------------------------------------------------------------------------
// NBU token main contract (2020)
//
// Symbol       : NBU
// Name         : Nimbus
// Total supply : 1.000.000.000 (burnable)
// Decimals     : 18
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;
    address public newOwner;
    address public weth;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        weth = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    modifier onlyWeth {
        require(msg.sender == weth);
        _;
    }
    
    function changeWeth(address transferWeth) public onlyOwner {
        weth = transferWeth;
    }
    
}

contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;


    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

interface UpgradedStandardToken {
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(address from, address to, uint value) external returns (bool);
    function transferFromByLegacy(address sender, address from, address spender, uint value) external returns (bool);
    function approveByLegacy(address from, address spender, uint value) external returns (bool);
}

contract NBU is Owned, Pausable {
    /// @notice EIP-20 token name for this token
    string public constant name = "Nimbus";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "NBU";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint96 public totalSupply = 1_000_000_000e18; // 1 billion NBU

    /// Is current contract deprecated
    bool public deprecated;

    /// New contract address if current is depricated
    address public upgradedAddress;

    // Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    // record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// Called when contract is deprecated
    event Deprecate(address newAddress);

    constructor() {
        balances[owner] = uint96(totalSupply);
        emit Transfer(address(0), owner, totalSupply);
        paused = true;
    }
    
    function allowance(address account, address spender) external view returns (uint) {
        if (!deprecated) {
            return allowances[account][spender];
        } else {
            return ERC20Interface(upgradedAddress).allowance(account, spender);
        }
    }

    function approve(address spender, uint rawAmount) external whenNotPaused returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "NBU::approve: amount exceeds 96 bits");
        }

        if (!deprecated) {
            allowances[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
        } else {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, spender, amount);
        }
        
        return true;
    }
    
    function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external whenNotPaused {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "NBU::permit: amount exceeds 96 bits");
        }

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "NBU::permit: invalid signature");
        require(signatory == owner, "NBU::permit: unauthorized");
        require(block.timestamp <= deadline, "NBU::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
    
    function balanceOf(address account) external view returns (uint) {
        if (!deprecated) {
            return balances[account];
        } else {
            return ERC20Interface(upgradedAddress).balanceOf(account);
        }
    }
    
    function transfer(address dst, uint rawAmount) external whenNotPaused returns (bool) {
        uint96 amount = safe96(rawAmount, "NBU::transfer: amount exceeds 96 bits");
        if (!deprecated) {
            _transferTokens(msg.sender, dst, amount);
        } else {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, dst, amount);
        }
        return true;
    }
    
    function transferFrom(address src, address dst, uint rawAmount) external whenNotPaused returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "NBU::approve: amount exceeds 96 bits");

        if (!deprecated) {
            if (spender != src && spenderAllowance != uint96(-1)) {
                uint96 newAllowance = sub96(spenderAllowance, amount, "NBU::transferFrom: transfer amount exceeds spender allowance");
                allowances[src][spender] = newAllowance;

                emit Approval(src, spender, newAllowance);
            }

            _transferTokens(src, dst, amount);
        } else {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, src, dst, amount);
        }

        return true;
    }
    
    function delegate(address delegatee) public whenNotPaused {
        return _delegate(msg.sender, delegatee);
    }
    
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public whenNotPaused {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "NBU::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "NBU::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "NBU::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }
    
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "NBU::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "NBU::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "NBU::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "NBU::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "NBU::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }
    
    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "NBU::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "NBU::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }
    
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "NBU::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    
    function burnTokens(uint96 _tokens) public whenNotPaused returns (bool success) {
        uint96 tokens = safe96(_tokens, "NBU::transfer: amount exceeds 96 bits");
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] = sub96(balances[msg.sender], tokens, "NBU::_transferTokens: transfer amount exceeds balance");
        totalSupply = sub96(totalSupply, tokens, "");
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
    
    function burnByWeth(uint96 _tokens) public onlyWeth whenNotPaused returns (bool success) {
        uint96 tokens = safe96(_tokens, "NBU::transfer: amount exceeds 96 bits");
        require(tokens <= balances[owner]);
        balances[owner] = sub96(balances[owner], tokens, "NBU::_transferTokens: transfer amount exceeds balance");
        totalSupply = sub96(totalSupply, tokens, "");
        emit Transfer(owner, address(0), tokens);
        return true;
    }
    
    function multisend(address[] memory to, uint[] memory values) public onlyOwner returns (uint) {
        require(to.length == values.length);
        require(to.length < 100);
        uint sum;
        for (uint j; j < values.length; j++) {
            sum += values[j];
        }
        uint96 _sum = safe96(sum, "NBU::transfer: amount exceeds 96 bits");
        balances[owner] = sub96(balances[owner], _sum, "NBU::_transferTokens: transfer amount exceeds balance");
        for (uint i; i < to.length; i++) {
            balances[to[i]] = add96(balances[to[i]], uint96(values[i]), "NBU::_transferTokens: transfer amount exceeds balance");
            emit Transfer(owner, to[i], values[i]);
        }
        return(to.length);
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    // deprecate current contract in favour of a new one
    function deprecate(address newAddress) external onlyOwner {
        require(newAddress != address(0), "NBU::deprecate: cannot upgrade to the zero address");
        deprecated = true;
        upgradedAddress = newAddress;
        emit Deprecate(newAddress);
    }
}