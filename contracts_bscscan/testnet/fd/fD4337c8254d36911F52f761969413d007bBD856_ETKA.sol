// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./vendors/contracts/access/Ownable.sol";
import "./vendors/contracts/DelegableToken.sol";
import "./vendors/interfaces/IDelegableERC20.sol";

contract ETKA is IDelegableERC20, DelegableToken, Ownable
{

    using SafeMath for uint256;

    constructor() ERC20("Ecosystem Tokkea Token", "ETKA", 1000000000e18) public {}

    function mint(address account, uint amount) external onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(uint amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    mapping (address => bool) private _allowedBridges;
    address[] private _bridgesList;
    event BridgeRegistration(address indexed newBridge);
    event BridgeDisable(address indexed newBridge);
    function bridgesList() public view virtual returns (address[] memory) {
        return _bridgesList;
    }
    modifier onlyBridge() {
        require(_allowedBridges[_msgSender()], "ETKA: caller is not the bridge");
        _;
    }
    function bridgeRegistration(address newBridge) public virtual onlyOwner {
        require(newBridge != address(0), "ETKA: new bridge is the zero address");
        _allowedBridges[newBridge] = true;
        _bridgesList.push(newBridge);
        emit BridgeRegistration(newBridge);
    }
    function bridgeDisable(address oldBridge) public virtual onlyOwner {
        require(_allowedBridges[oldBridge], "ETKA: bridge is disabled");
        emit BridgeRegistration(oldBridge);
        _allowedBridges[oldBridge] = false;
    }
    function mintByBridge(address account, uint amount) external onlyBridge returns (bool) {
        _mint(account, amount);
        return true;
    }
    function burnByBridge(address account, uint amount) external onlyBridge returns (bool) {
        _burn(account, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath32 {
    function safe32(uint a, string memory errorMessage) internal pure returns (uint32 c) {
        require(a <= 2**32, errorMessage);// "SafeMath: exceeds 32 bits"
        c = uint32(a);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, "SafeMath: Add Overflow");
    }
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);// "SafeMath: Add Overflow"

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: Underflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;// "SafeMath: Underflow"

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b, "SafeMath: Mul Overflow");
    }
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);// "SafeMath: Mul Overflow"

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IERC20WithMaxTotalSupply is IERC20 {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Mint(address indexed account, uint tokens);
    event Burn(address indexed account, uint tokens);
    function maxTotalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IDelegable.sol";
import "./IERC20WithMaxTotalSupply.sol";

interface IDelegableERC20 is IDelegable, IERC20WithMaxTotalSupply {}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IDelegable {
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function getCurrentVotes(address account) external view returns (uint256);
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Copied from OpenZeppelin code:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../utils/Context.sol";

// Copied from OpenZeppelin code:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/IERC20WithMaxTotalSupply.sol";
import "./utils/Context.sol";

import "../libraries/SafeMath.sol";


// Copied and modified from OpenZeppelin code:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
contract ERC20 is Context, IERC20WithMaxTotalSupply {
    using SafeMath for uint256;

    string _name;
    string _symbol;
    uint256 _totalSupply;
    uint256 _maxTotalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    constructor(string memory name_, string memory symbol_, uint maxTotalSupply_) public {
        _name = name_;
        _symbol = symbol_;
        _maxTotalSupply = maxTotalSupply_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply;
    }

    function maxTotalSupply() public view virtual override returns (uint) {
        return _maxTotalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public override virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        address spender = _msgSender();
        if (spender != sender) {
            uint256 newAllowance = _allowances[sender][spender].sub(amount, "ERC20ForUint256::transferFrom: amount - exceeds spender allowance");
            _approve(sender, spender, newAllowance);
        }

        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20ForUint256::transfer: from -  the zero address");
        require(recipient != address(0), "ERC20ForUint256::transfer: to -  the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20ForUint256::_transfer: amount - exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount, "ERC20ForUint256::_transfer - Add Overflow");

        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20ForUint256::_mint: account - the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _balances[account] = _balances[account].add(amount, "ERC20ForUint256::_mint: amount - exceeds balance");
        _totalSupply = _totalSupply.add(amount, "ERC20ForUint256::_mint: totalSupply - exceeds amount");
        require(_totalSupply <= _maxTotalSupply, "ERC20ForUint256::_mint: maxTotalSupply limit");

        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20ForUint256::_burn: account - the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20ForUint256::_burn: amount - exceeds balance");
        _totalSupply = _totalSupply.sub(amount, "ERC20ForUint256::_burn: totalSupply - exceeds amount");

        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20ForUint256::_approve: owner - the zero address");
        require(spender != address(0), "ERC20ForUint256::_approve: spender - the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";
import "../interfaces/IDelegable.sol";

import "../libraries/SafeMath32.sol";
import "../libraries/SafeMath.sol";

// Copied and modified from Compound code:
// https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/DelegableToken.sol
abstract contract DelegableToken is IDelegable, ERC20{
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    /// @notice A record of each accounts delegate
    mapping (address => address) public _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public _checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public _numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public _nonces;

    function delegate(address delegatee) public override {
        return _delegate(_msgSender(), delegatee);
    }

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public override {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DelegableToken::delegateBySig: invalid signature");
        require(nonce == _nonces[signatory]++, "DelegableToken::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "DelegableToken::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    function getCurrentVotes(address account) external override view returns (uint256) {
        uint32 nCheckpoints = _numCheckpoints[account];
        return nCheckpoints > 0 ? _checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber) public override view returns (uint256) {
        require(blockNumber <= block.number, "DelegableToken::getPriorVotes: not yet determined");

        uint32 nCheckpoints = _numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (_checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return _checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (_checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = _checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = _balances[delegator];
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveDelegates(_delegates[from], _delegates[to], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = _numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? _checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount, "DelegableToken::_moveVotes: vote amount - underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = _numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? _checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount, "DelegableToken::_moveVotes: vote amount - overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = SafeMath32.safe32(block.number, "DelegableToken::_writeCheckpoint: block number - exceeds 32 bits");

        if (nCheckpoints > 0 && _checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            _checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            _checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            _numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}