/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

// SPDX-License-Identifier: TBD
pragma solidity 0.7.4;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowances(address _owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);    
}

interface ICoinSwapGovERC20 is IERC20 {
    function owner() external view returns (address payable);
    function nonces(address account) external view returns (uint);
    function permit(address _from, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function DOMAIN_TYPEHASH() external pure returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function DELEGATION_TYPEHASH() external pure returns (bytes32);
    function renounceOwner() external;
    function setNewOwner(address payable newOwner) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

contract CoinSwapGovERC20 is ICoinSwapGovERC20 {
    using SafeMath for uint256;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowances;
    address payable public override owner;
    uint256 public override totalSupply;
    string public constant override name = 'CoinSwap Governance';
    string public constant override symbol= 'CSWP';
    uint8 public constant override decimals = 18;
    bytes32 public constant override DOMAIN_TYPEHASH = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
    bytes32 public constant override PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
    bytes32 public override DOMAIN_SEPARATOR;
    mapping (address => uint) public override nonces;

    constructor() {
        uint chainId;
        assembly { chainId := chainid() }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes('1')), chainId, address(this))
        );
    }

    function renounceOwner() public override {
        require(owner == msg.sender, 'ERC20: requires owner');
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));
    }
    function setNewOwner(address payable newOwner) public override {
        require((owner == msg.sender) && (newOwner != address(0)), 'ERC20: requires owner or new owner is zero');
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender].sub(amount, 'ERC20: transfer amount > allowance'));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender,
            allowances[msg.sender][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero'));
        return true;
    }
    function _transfer(address sender,address recipient,uint256 amount) internal {
        require((sender != address(0)) && (recipient != address(0)), 'ERC20: transfer with zero address');
        balanceOf[sender] = balanceOf[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: mint to zero address');
        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: burn from the zero address');
        balanceOf[account] = balanceOf[account].sub(amount, 'ERC20: burn amount exceeds balance');
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address _owner,address spender,uint256 amount) internal {
        require((_owner != address(0)) &&( spender != address(0)), 'ERC20: approve with zero address');
        allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account,msg.sender,allowances[account][msg.sender].sub(amount, 'ERC20: burn amount exceeds allowance'));
    }

    function permit(address sender, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'ERC20: expired');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[sender]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, 'ERC20: wrong signature');
        _approve(sender, spender, value);
    }
}

contract CSWPToken is CoinSwapGovERC20 {
    using SafeMath for uint256;
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    constructor() {owner = tx.origin;}

    mapping (address => address) internal _delegates;
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;

    function mint(address _to, uint256 _amount) public {
        require(owner == msg.sender, 'ERC20: not owner');
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee,uint nonce,uint expiry,uint8 v,bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH,delegatee,nonce,expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR,structHash));
        address deletator = ecrecover(digest, v, r, s);
        require(deletator != address(0), "CSWP: invalid signature");
        require(nonce == nonces[deletator]++, "CSWP: invalid nonce");
        require(block.timestamp <= expiry, "CSWP: signature expired");
        return _delegate(deletator, delegatee);
    }

    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "CSWP: too early");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) { return 0; }

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
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf[delegator]; 
        _delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint blockNumber = block.number;
        require(blockNumber<2**32, 'block.number overflow');
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(uint32(blockNumber), newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

}