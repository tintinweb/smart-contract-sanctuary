/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MuteGovernance {
    using SafeMath for uint256;

    mapping (address => address) internal _delegates;

    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    mapping (address => uint32) public numCheckpoints;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => uint) public nonces;

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "Gov::getPriorVotes: not yet determined");

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
        uint32 blockNumber = safe32(block.number, "Gov::_writeCheckpoint: block number exceeds 32 bits");

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

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

contract Mute is MuteGovernance {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint16 public TAX_FRACTION;
    address public taxReceiveAddress;

    bool public isTaxEnabled;
    mapping(address => bool) public nonTaxedAddresses;

    address private _owner = address(0);
    mapping (address => bool) private _minters;

    uint256 public vaultThreshold = 10000e18; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Mute::OnlyOwner: Not the owner");
        _;
    }

    modifier onlyMinter() {
        require(_minters[msg.sender] == true);
        _;
    }

    function initialize() external {
        require(_owner == address(0), "Mute::Initialize: Contract has already been initialized");
        _owner = msg.sender;
        _name = "Mute.io";
        _symbol = "MUTE";
        _decimals = 18;
    }

    function setVaultThreshold(uint256 _vaultThreshold) external onlyOwner {
        vaultThreshold = _vaultThreshold;
    }

    function addMinter(address account) external onlyOwner {
        require(account != address(0));
        _minters[account] = true;
    }

    function removeMinter(address account) external onlyOwner {
        require(account != address(0));
        _minters[account] = false;
    }

    function setTaxReceiveAddress(address _taxReceiveAddress) external onlyOwner {
        taxReceiveAddress = _taxReceiveAddress;
    }

    function setAddressTax(address _address, bool ignoreTax) external onlyOwner {
        nonTaxedAddresses[_address] = ignoreTax;
    }

    function setTaxFraction(uint16 _tax_fraction) external onlyOwner {
        TAX_FRACTION = _tax_fraction;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "Mute: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Mute: transfer from the zero address");
        require(recipient != address(0), "Mute: transfer to the zero address");

        if(nonTaxedAddresses[sender] == true || TAX_FRACTION == 0 || balanceOf(taxReceiveAddress) > vaultThreshold){
          _balances[sender] = _balances[sender].sub(amount, "Mute: transfer amount exceeds balance");
          
          if(balanceOf(taxReceiveAddress) > vaultThreshold){
              IMuteVault(taxReceiveAddress).reward();
          }

          _balances[recipient] = _balances[recipient].add(amount);

          _moveDelegates(_delegates[sender], _delegates[recipient], amount);

          emit Transfer(sender, recipient, amount);

          return;
        }

        uint256 feeAmount = amount.mul(TAX_FRACTION).div(100);
        uint256 newAmount = amount.sub(feeAmount);

        require(amount == feeAmount.add(newAmount), "Mute: math is broken");

        _balances[sender] = _balances[sender].sub(amount, "Mute: transfer amount exceeds balance");

        _balances[recipient] = _balances[recipient].add(newAmount);
        _moveDelegates(_delegates[sender], _delegates[recipient], newAmount);
        _balances[taxReceiveAddress] = _balances[taxReceiveAddress].add(feeAmount);
        _moveDelegates(_delegates[sender], _delegates[taxReceiveAddress], feeAmount);

        emit Transfer(sender, recipient, newAmount);
        emit Transfer(sender, taxReceiveAddress, feeAmount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "Mute: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "Mute: approve from the zero address");
        require(spender != address(0), "Mute: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function Burn(uint256 amount) external returns (bool) {
        require(msg.sender != address(0), "Mute: burn from the zero address");

        _moveDelegates(_delegates[msg.sender], address(0), amount);

        _balances[msg.sender] = _balances[msg.sender].sub(amount, "Mute: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function Mint(address account, uint256 amount) external onlyMinter returns (bool) {
        require(account != address(0), "Mute: mint to the zero address");

        _moveDelegates(address(0), _delegates[account], amount);

        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), account, amount);
        return true;
    }

    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Mute::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Mute::delegateBySig: invalid nonce");
        require(now <= expiry, "Mute::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }
}

interface IMuteVault {
    function reward() external returns (bool);
}