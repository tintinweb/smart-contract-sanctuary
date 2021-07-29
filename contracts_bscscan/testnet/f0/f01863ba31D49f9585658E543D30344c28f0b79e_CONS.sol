/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function getOwner() external view returns (address);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Ownable {
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

contract CONS is Ownable, Pausable {
    string public constant name = "Cons";
    string public constant symbol = "CONS";
    uint8 public constant decimals = 18;
    uint96 public totalSupply = 10_000e18;
    mapping (address => mapping (address => uint96)) internal allowances;

    mapping (address => uint96) private balances;

    mapping (address => address) public delegates;
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    mapping (address => uint) public nonces;
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Unvest(address indexed user, uint amount);

    constructor() {
        balances[owner] = uint96(totalSupply);
        emit Transfer(address(0), owner, totalSupply);
    }

    receive() payable external {
        revert();
    }

    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint rawAmount) external whenNotPaused returns (bool) {
        require(spender != address(0), "CONS::approve: approve to the zero address");

        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, "CONS::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external whenNotPaused {
        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, "CONS::permit: amount exceeds 96 bits");
        }

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CONS::permit: invalid signature");
        require(signatory == owner, "CONS::permit: unauthorized");
        require(block.timestamp <= deadline, "CONS::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
       
    function balanceOf(address account) public view returns (uint) {
        return balances[account];
    }

    function transfer(address dst, uint rawAmount) external whenNotPaused returns (bool) {
        uint96 amount = safe96(rawAmount, "CONS::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }
    
    function transferFrom(address src, address dst, uint rawAmount) external whenNotPaused returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "CONS::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "CONS::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
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
        require(signatory != address(0), "CONS::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CONS::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "CONS::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }
    
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "CONS::getPriorVotes: not yet determined");

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
        require(src != address(0), "CONS::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "CONS::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "CONS::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "CONS::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }
    
    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "CONS::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "CONS::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }
    
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "CONS::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }


    function mint(address account, uint256 rawAmount) external onlyOwner { 
        uint96 amount = safe96(rawAmount, "CONS::burnTokens: amount exceeds 96 bits");
        _mint(account, amount);
    }

    function burnTokens(uint rawAmount) public onlyOwner returns (bool success) {
        uint96 amount = safe96(rawAmount, "CONS::burnTokens: amount exceeds 96 bits");
        require(amount <= balances[owner]);
        balances[owner] = sub96(balances[owner], amount, "CONS::burnTokens: transfer amount exceeds balance");
        totalSupply = sub96(totalSupply, amount, "CONS::burnTokens: transfer amount exceeds total supply");
        emit Transfer(owner, address(0), amount);
        return true;
    }
    
   
    function multisend(address[] memory to, uint[] memory values) public onlyOwner returns (uint) {
        require(to.length == values.length);
        require(to.length < 100);
        uint sum;
        for (uint j; j < values.length; j++) {
            sum += values[j];
        }
        uint96 _sum = safe96(sum, "CONS::transfer: amount exceeds 96 bits");
        balances[owner] = sub96(balances[owner], _sum, "CONS::_transferTokens: transfer amount exceeds balance");
        for (uint i; i < to.length; i++) {
            balances[to[i]] = add96(balances[to[i]], uint96(values[i]), "CONS::_transferTokens: transfer amount exceeds balance");
            emit Transfer(owner, to[i], values[i]);
        }
        return(to.length);
    }
    
    function transferAnyBEP20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return IBEP20(tokenAddress).transfer(owner, tokens);
    }

    function acceptOwnership() public override {
        require(msg.sender == newOwner);
        uint96 amount = balances[owner];
        _transferTokens(owner, newOwner, amount);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function _mint(address account, uint96 amount) internal virtual {
        require(account != address(0), "CONS::_mint: mint to the zero address");

        totalSupply = add96(totalSupply, amount, "CONS::_mint: sum overflow");
        balances[account] = add96(balances[account], amount, "CONS::_mint: sum overflow");
        emit Transfer(address(0), account, amount);
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

    function getChainId() internal view returns (uint) {
        return block.chainid;
    }

        
    function mul96(uint96 a, uint96 b) internal pure returns (uint96) {
        if (a == 0) {
            return 0;
        }
        uint96 c = a * b;
        require(c / a == b, "CONS:mul96: multiplication overflow");
        return c;
    }

    function mul96(uint256 a, uint96 b) internal pure returns (uint96) {
        uint96 _a = safe96(a, "CONS:mul96: amount exceeds uint96");
        if (_a == 0) {
            return 0;
        }
        uint96 c = _a * b;
        require(c / _a == b, "CONS:mul96: multiplication overflow");
        return c;
    }
}