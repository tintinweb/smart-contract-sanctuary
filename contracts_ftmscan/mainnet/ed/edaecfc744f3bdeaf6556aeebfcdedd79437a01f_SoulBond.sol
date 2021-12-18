/**
 *Submitted for verification at FtmScan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/access/IAccessControl.sol
pragma solidity ^0.8.0;

interface IAccessControl {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }


    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }


    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// File: contracts/libraries/ERC20.sol

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/SoulPower.sol

contract SoulPower is ERC20('SoulPower', 'SOUL'), AccessControl {

    address public supreme;     // supreme divine
    bytes32 public anunnaki;   // admin role
    bytes32 public thoth;     // minter role

    bytes32 public constant DOMAIN_TYPEHASH = // EIP-712 typehash for the contract's domain
        keccak256('EIP712Domain(string name,uint chainId,address verifyingContract)');
    bytes32 public constant DELEGATION_TYPEHASH = // EIP-712 typehash for the delegation struct used by the contract
        keccak256('Delegation(address delegatee,uint nonce,uint expiry)'); 

    // mappings for user accounts (address)
    mapping(address => mapping(uint => Checkpoint)) public checkpoints;   // vote checkpoints
    mapping(address => uint) public numCheckpoints;                      // checkpoint count
    mapping(address => uint) public nonces;                             // signing / validating states
    mapping(address => address) internal _delegates;                      // each accounts' delegate

    struct Checkpoint {  // checkpoint for marking number of votes from a given timestamp
        uint fromTime;
        uint votes;
    }

    event NewSupreme(address supreme);
    event Rethroned(bytes32 role, address oldAccount, address newAccount);
    event DelegateChanged( // emitted when an account changes its delegate
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );
    event DelegateVotesChanged( // emitted when a delegate account's vote balance changes
        address indexed delegate,
        uint previousBalance,
        uint newBalance
    );

    // restricted to the house of the role passed as an object to obey
    modifier obey(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    // channels the authority vested in anunnaki and thoth to the supreme
    constructor() {
        supreme = msg.sender;              // WARNING: set to multi-sig when deploying
        anunnaki = keccak256('anunnaki'); // alpha supreme
        thoth = keccak256('thoth');      // god of wisdom and magic

        _divinationRitual(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE, supreme); // supreme as root admin
        _divinationRitual(anunnaki, anunnaki, supreme);                    // anunnaki as admin of anunnaki
        _divinationRitual(thoth, anunnaki, supreme);                      // anunnaki as admin of thoth

        mint(supreme, 50_000_000 * 1e18); // mints initial supply of 50M
    }

    // solidifies roles (internal)
    function _divinationRitual(bytes32 _role, bytes32 _adminRole, address _account) internal {
        _setupRole(_role, _account);
        _setRoleAdmin(_role, _adminRole);
    }

    // grants `role` to `newAccount` && renounces `role` from `oldAccount` (public role)
    function rethroneRitual(bytes32 role, address oldAccount, address newAccount) public obey(role) {
        require(oldAccount != newAccount, 'must be a new address');
        grantRole(role, newAccount);     // grants new account
        renounceRole(role, oldAccount); //  removes old account of role
        
        emit Rethroned(role, oldAccount, newAccount);
    }

    // updates supreme address (public anunnaki)
    function newSupreme(address _supreme) public obey(anunnaki) {
        require(supreme != _supreme, 'make a change, be the change');  //  prevents self-destruct
        rethroneRitual(DEFAULT_ADMIN_ROLE, supreme, _supreme);        //   empowers new supreme
        supreme = _supreme;
        
        emit NewSupreme(supreme);
    }

    // checks whether sender has divine role (public view)
    function hasDivineRole(bytes32 role) public view returns (bool) {
        return hasRole(role, msg.sender);
    }

    // mints soul power as the house of thoth so wills (public thoth)
    function mint(address _to, uint _amount) public obey(thoth) {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // destroys `amount` tokens from the caller (public)
    function burn(uint amount) public {
        _burn(_msgSender(), amount);
        _moveDelegates(_delegates[_msgSender()], address(0), amount);
    }

    // destroys `amount` tokens from the `account` (public)
    function burnFrom(address account, uint amount) public {
        uint currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, 'burn amount exceeds allowance');

        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
        _moveDelegates(_delegates[account], address(0), amount);
    }

    // returns the address delegated by a given delegator (external view)
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    // delegates to the `delegatee` (external)
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    // delegates votes from signatory to `delegatee` (external)
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );

        bytes32 digest = keccak256(
            abi.encodePacked('\x19\x01', domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'delegateBySig: invalid signature');
        require(nonce == nonces[signatory]++, 'delegateBySig: invalid nonce');
        require(block.timestamp <= expiry, 'delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    // returns current votes balance for `account` (external view)
    function getCurrentVotes(address account) external view returns (uint) {
        uint nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    // returns an account's prior vote count as of a given timestamp (external view)
    function getPriorVotes(address account, uint blockTimestamp) external view returns (uint) {
        require(blockTimestamp < block.timestamp, 'getPriorVotes: not yet determined');
        
        uint nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) { return 0; }

        // checks most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromTime <= blockTimestamp) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // checks implicit zero balance
        if (checkpoints[account][0].fromTime > blockTimestamp) {
            return 0;
        }

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // avoids overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromTime == blockTimestamp) {
                return cp.votes;
            } else if (cp.fromTime < blockTimestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }

        return checkpoints[account][lower].votes;
    }

    function safe256(uint n, string memory errorMessage) internal pure returns (uint) {
        require(n < type(uint).max, errorMessage);
        return uint(n);
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint delegatorBalance = balanceOf(delegator); // balance of underlying SOUL (not scaled)
        _delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decreases old representative
                uint srcRepNum = numCheckpoints[srcRep];
                uint srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increases new representative
                uint dstRepNum = numCheckpoints[dstRep];
                uint dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint nCheckpoints,
        uint oldVotes,
        uint newVotes
    ) internal {
        uint blockTimestamp = safe256(block.timestamp, 'block timestamp exceeds 256 bits');

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromTime == blockTimestamp) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else { 
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockTimestamp, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}

// File: contracts/libraries/Operable.sol

abstract contract Operable is Context, Ownable {

    address[] public operators;
    mapping(address => bool) public operator;

    event OperatorUpdated(address indexed operator, bool indexed access);
    constructor () {
        address msgSender = _msgSender();
        operator[msgSender] = true;
        operators.push(msgSender);
        emit OperatorUpdated(msgSender, true);
    }

    modifier onlyOperator() {
        address msgSender = _msgSender();
        require(operator[msgSender], "Operator: caller is not an operator");
        _;
    }

    function removeOperator(address removingOperator) public virtual onlyOperator {
        require(operator[removingOperator], 'Operable: address is not an operator');
        operator[removingOperator] = false;
        for (uint8 i; i < operators.length; i++) {
            if (operators[i] == removingOperator) {
                operators[i] = operators[i+1];
                operators.pop();
                emit OperatorUpdated(removingOperator, false);
                return;
            }
        }
    }

    function addOperator(address newOperator) public virtual onlyOperator {
        require(newOperator != address(0), "Operable: new operator is the zero address");
        require(!operator[newOperator], 'Operable: address is already an operator');
        operator[newOperator] = true;
        operators.push(newOperator);
        emit OperatorUpdated(newOperator, true);
    }
}

// File: contracts/SeanceCircle.sol

// SeanceCircle with Governance.
contract SeanceCircle is ERC20('SeanceCircle', 'SEANCE'), Ownable, Operable {

    SoulPower public soul;
    bool isInitialized;

    function mint(address _to, uint256 _amount) public onlyOperator {
        require(isInitialized, 'the circle has not yet begun');
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    function burn(address _from ,uint256 _amount) public onlyOperator {
        _burn(_from, _amount);
        _moveDelegates(_delegates[_from], address(0), _amount);
    }

    function initialize(SoulPower _soul) external onlyOwner {
        require(!isInitialized, 'the circle has already begun');
        soul = _soul;
        isInitialized = true;
    }

    // safe soul transfer function, just in case if rounding error causes pool to not have enough SOUL.
    function safeSoulTransfer(address _to, uint256 _amount) public onlyOperator {
        uint256 soulBal = soul.balanceOf(address(this));
        if (_amount > soulBal) {
            soul.transfer(_to, soulBal);
        } else {
            soul.transfer(_to, _amount);
        }
    }

    // record of each accounts delegate
    mapping (address => address) internal _delegates;

    // checkpoint for marking number of votes from a given block timestamp
    struct Checkpoint {
        uint256 fromTime;
        uint256 votes;
    }

    // record of votes checkpoints for each account, by index
    mapping (address => mapping (uint256 => Checkpoint)) public checkpoints;

    // number of checkpoints for each account
    mapping (address => uint256) public numCheckpoints;

    // EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH 
        = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH 
        = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    // emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    // returns the address delegated by a given delegator (external view)
    function delegates(address delegator) external view returns (address) { return _delegates[delegator]; }

    // delegates to the `delegatee` (external)
    function delegate(address delegatee) external { return _delegate(msg.sender, delegatee); }

    // delegates votes from signatory to `delegatee` (external)
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SOUL::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "SOUL::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "SOUL::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    // returns current votes balance for `account` (external view)
    function getCurrentVotes(address account) external view returns (uint) {
        uint nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    // returns an account's prior vote count as of a given timestamp (external view)
    function getPriorVotes(address account, uint blockTimestamp) external view returns (uint256) {
        require(blockTimestamp < block.timestamp, "SOUL::getPriorVotes: not yet determined");

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // checks most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromTime <= blockTimestamp) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // checks implicit zero balance
        if (checkpoints[account][0].fromTime > blockTimestamp) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromTime == blockTimestamp) {
                return cp.votes;
            } else if (cp.fromTime < blockTimestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SOUL (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint256 blockTimestamp = safe256(block.timestamp, "SOUL::_writeCheckpoint: block timestamp exceeds 256 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromTime == blockTimestamp) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockTimestamp, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe256(uint n, string memory errorMessage) internal pure returns (uint256) {
        require(n < type(uint256).max, errorMessage);
        return uint256(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function newSoul(SoulPower _soul) external onlyOperator {
        require(soul != _soul, 'must be a new address');
        soul = _soul;
    }

}

// File: contracts/SoulBond.sol

// the bonder of souls | ownership transferred to a governance smart contract 
// upon sufficient distribution + the community's desire to self-govern.

contract SoulBond is AccessControl, ReentrancyGuard {

    // user info
    struct Users {
        uint amount;           // total tokens user has provided.
        uint rewardDebt;       // reward debt (see below).
        uint depositTime; // the last time a user deposited at.
        uint lastDepositTime;  // most recent deposit time.

        //   pending reward = (user.amount * pool.accSoulPerShare) - user.rewardDebt

        // the following occurs when a user +/- tokens to a pool:
        //   1. pool: `accSoulPerShare` and `lastRewardTime` update.
        //   2. user: receives pending reward.
        //   3. user: `amount` updates(+/-).
        //   4. user: `rewardDebt` updates (+/-).
    }

    // pool info
    struct Pools {
        IERC20 lpToken;       // lp token ierc20 contract.
        uint allocPoint;      // allocation points assigned to this pool | SOULs to distribute per second.
        uint lastRewardTime;  // most recent UNIX timestamp during which SOULs distribution occurred in the pool.
        uint accSoulPerShare; // accumulated SOULs per share, times 1e12.
    }

    // soul power: our native utility token
    address private soulAddress;
    SoulPower public soul;
    
    // seance circle: our governance token
    address private seanceAddress;
    SeanceCircle public seance;

    address public team; // receives 1/8 soul supply
    address public dao; // recieves 1/8 soul supply
    address public supreme; // has supreme role

    // blockchain variables accounting for share of overall emissions
    uint public totalWeight;
    uint public weight;

    // soul x day x this.chain
    uint public dailySoul; // = weight * 250K * 1e18;

    // soul x second x this.chain
    uint public soulPerSecond; // = dailySoul / 86400;

    // bonus muliplier for early soul summoners
    uint public bonusMultiplier = 1;

    // timestamp when soul rewards began (initialized)
    uint public startTime;

    // ttl allocation points | must be the sum of all allocation points
    uint public totalAllocPoint;

    // summoner initialized state.
    bool public isInitialized;

    // fee state.
    bool public isBondMode;

    Pools[] public poolInfo; // pool info
    mapping (uint => mapping (address => Users)) public userInfo; // user data

    // divinated roles
    bytes32 public isis; // soul summoning goddess of magic
    bytes32 public maat; // goddess of cosmic order

    event RoleDivinated(bytes32 role, bytes32 supreme);

    // restricted to the council of the role passed as an object to obey (role)
    modifier obey(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    // prevents: early reward distribution
    modifier isSummoned {
        require(isInitialized, 'rewards have not yet begun');
        _;
    }

    event Deposit(address indexed user, uint indexed pid, uint amount);
    event Bonded(address indexed user, uint indexed pid, uint amount, uint timeStamp);

    event Initialized(address team, address dao, address soul, address seance, uint totalAllocPoint, uint weight);
    event PoolAdded(uint pid, uint allocPoint, IERC20 lpToken, uint totalAllocPoint);
    event PoolSet(uint pid, uint allocPoint);

    event WeightUpdated(uint weight, uint totalWeight);
    event RewardsUpdated(uint dailySoul, uint soulPerSecond);
    event EmergencyFeeUpdated(bool isBondMode);

    event AccountsUpdated(address dao, address team, address admin);
    event TokensUpdated(address soul, address seance);
    event DepositRevised(uint _pid, address _user, uint _time);

    // validates: pool exists
    modifier validatePoolByPid(uint pid) {
        require(pid < poolInfo.length, 'pool does not exist');
        _;
    }

    // channels the power of the isis and ma'at to the deployer (deployer)
    constructor() {
        supreme = 0x221cAc060A2257C8F77B6eb1b03e36ea85A1675A;    // multi-sig safe
        team = 0x221cAc060A2257C8F77B6eb1b03e36ea85A1675A;      // team wallet
        dao = 0x221cAc060A2257C8F77B6eb1b03e36ea85A1675A;      // dao treasury (multi-sig)

        isis = keccak256("isis"); // goddess of magic who creates pools
        maat = keccak256("maat"); // goddess of cosmic order who allocates emissions

        _divinationCeremony(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE, supreme);
        _divinationCeremony(isis, isis, supreme); // isis role created -- supreme divined admin
        _divinationCeremony(maat, isis, dao); // maat role created -- isis divined admin
    } 

    function _divinationCeremony(bytes32 _role, bytes32 _adminRole, address _account) 
        internal returns (bool) {
            _setupRole(_role, _account);
            _setRoleAdmin(_role, _adminRole);
        return true;
    }

    // validate: pool uniqueness to eliminate duplication risk (internal view)
    function checkPoolDuplicate(IERC20 _token) internal view {
        uint length = poolInfo.length;

        for (uint pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].lpToken != _token, 'duplicated pool');
        }
    }

    // activates: rewards (owner)
    function initialize() external obey(isis) {
        require(!isInitialized, 'already initialized');

        soulAddress = 0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07;
        seanceAddress = 0x124B06C5ce47De7A6e9EFDA71a946717130079E6;

        // [required]: update global constants
        startTime = block.timestamp;
        totalWeight = 1000;
        weight = 250;
        isBondMode = true;
        soul  = SoulPower(soulAddress);
        seance = SeanceCircle(seanceAddress);

        // updates: dailySoul and soulPerSecond
        updateRewards(weight, totalWeight); 

        // triggers: initialize state
        isInitialized = true;          

        emit Initialized(team, dao, soulAddress, seanceAddress, totalAllocPoint, weight);
    }

    // returns: amount of pools
    function poolLength() external view returns (uint) { return poolInfo.length; }

    // add: new pool (isis)
    function addPool(uint _allocPoint, IERC20 _lpToken, bool _withUpdate) 
        public isSummoned obey(isis) { // isis: the soul summoning goddess whose power transcends them all
            checkPoolDuplicate(_lpToken);
            _addPool(_allocPoint, _lpToken, _withUpdate);
    }

    // add: new pool (internal)
    function _addPool(uint _allocPoint, IERC20 _lpToken, bool _withUpdate) internal {
        if (_withUpdate) { massUpdatePools(); }

        totalAllocPoint += _allocPoint;
        
        poolInfo.push(
        Pools({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardTime: block.timestamp > startTime ? block.timestamp : startTime,
            accSoulPerShare: 0
        }));
        
        uint pid = poolInfo.length;

        emit PoolAdded(pid, _allocPoint, _lpToken, totalAllocPoint);
    }

    // set: allocation points (maat)
    function set(uint pid, uint allocPoint, bool withUpdate) 
        external isSummoned validatePoolByPid(pid) obey(maat) {
            if (withUpdate) { massUpdatePools(); } // updates all pools
            
            uint prevAllocPoint = poolInfo[pid].allocPoint;
            poolInfo[pid].allocPoint = allocPoint;
            
            if (prevAllocPoint != allocPoint) {
                totalAllocPoint = totalAllocPoint - prevAllocPoint + allocPoint;
        }

        emit PoolSet(pid, allocPoint);
    }

    // view: bonus multiplier (public view)
    function getMultiplier(uint from, uint to) public view returns (uint) {
        return (to - from) * bonusMultiplier; // todo: minus parens
    }

    // view: pending soul rewards (external)
    function pendingSoul(uint pid, address _user) external view returns (uint pendingAmount) {
        Pools storage pool = poolInfo[pid];
        Users storage user = userInfo[pid][_user];

        uint accSoulPerShare = pool.accSoulPerShare;
        uint lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint soulReward = multiplier * soulPerSecond * pool.allocPoint / totalAllocPoint;
            accSoulPerShare = accSoulPerShare + soulReward * 1e12 / lpSupply;
        }

        return user.amount * accSoulPerShare / 1e12 - user.rewardDebt;
    }

    // update: rewards for all pools (public)
    function massUpdatePools() public {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) { updatePool(pid); }
    }

    // update: rewards for a given pool id (public)
    function updatePool(uint pid) public validatePoolByPid(pid) {
        Pools storage pool = poolInfo[pid];

        if (block.timestamp <= pool.lastRewardTime) { return; }
        uint lpSupply = pool.lpToken.balanceOf(address(this));

        if (lpSupply == 0) { pool.lastRewardTime = block.timestamp; return; } // first user in pool

        uint multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint soulReward = multiplier * soulPerSecond * pool.allocPoint / totalAllocPoint;
        
        uint divi = soulReward * 1e12 / 8e12;   // 12.5% rewards
        
        soul.mint(team, divi);
        soul.mint(dao, divi);

        soul.mint(address(seance), soulReward); // note: updated calc

        pool.accSoulPerShare = pool.accSoulPerShare + (soulReward * 1e12 / lpSupply);
        pool.lastRewardTime = block.timestamp;
    }

    // deposit: lp tokens (lp owner)
    function deposit(uint pid, uint amount) external nonReentrant validatePoolByPid(pid) {
        Pools storage pool = poolInfo[pid];
        Users storage user = userInfo[pid][msg.sender];
        require(amount > 0, 'must deposit more than 0');
        require(user.amount == 0, 'must bond first');
        
        updatePool(pid);

        // transfer lpToken to the summoner
        pool.lpToken.transferFrom(address(msg.sender), address(this), amount);
        user.amount += amount;

        user.rewardDebt = user.amount * pool.accSoulPerShare / 1e12;

        // marks deposit time
        user.depositTime = block.timestamp;

        emit Deposit(msg.sender, pid, amount);
    }

    // bond: lp tokens (external bonders)
    function bond(uint pid) external nonReentrant validatePoolByPid(pid) {
        Pools storage pool = poolInfo[pid];
        Users storage user = userInfo[pid][msg.sender];
        uint amountStaked = user.amount;

        require(amountStaked != 0, 'must have a bonded amount');
        updatePool(pid);

        uint pending = user.amount * pool.accSoulPerShare / 1e12 - user.rewardDebt;

        if(pending > 0) { safeSoulTransfer(msg.sender, pending); }

        user.amount = user.amount - amountStaked; // remove all
    
        isBondMode == true ?
              pool.lpToken.transfer(address(dao), amountStaked)           // sends LP to DAO [true]
            : pool.lpToken.transfer(address(msg.sender), amountStaked);   // sends LP to USER [false]

        user.rewardDebt = user.amount * pool.accSoulPerShare / 1e12;      // updates reward debt to 0

        emit Bonded(msg.sender, pid, amountStaked, block.timestamp);
    }

    // bond: lp tokens (external farmers)
    function marketValue(uint pid, address user) public view returns (uint) {

    }

    // bond: lp tokens (external farmers)
    function mintValue(uint pid, address user) public view returns (uint) {

    }
    
    // transfer: seance (internal)
    function safeSoulTransfer(address account, uint amount) internal {
        seance.safeSoulTransfer(account, amount);
    }

    // ** UPDATE FUNCTIONS ** // 

    // update: weight (maat)
    function updateWeights(uint _weight, uint _totalWeight) external obey(maat) {
        require(weight != _weight || totalWeight != _totalWeight, 'must be at least one new value');
        require(_totalWeight >= _weight, 'weight cannot exceed totalWeight');

        weight = _weight;     
        totalWeight = _totalWeight;

        updateRewards(weight, totalWeight);

        emit WeightUpdated(weight, totalWeight);
    }

    // update: multiplier (maat)
    function updateMultiplier(uint _bonusMultiplier) external obey(maat) {
        bonusMultiplier = _bonusMultiplier;
    }

    // update: rewards (internal)
    function updateRewards(uint _weight, uint _totalWeight) internal {
        uint share = enWei(_weight) / _totalWeight; // share of ttl emissions for chain (chain % ttl emissions)
        
        dailySoul = share * (250_000); // dailySoul (for this.chain) = share (%) x 250K (soul emissions constant)
        soulPerSecond = dailySoul / 1 days; // updates: daily rewards expressed in seconds (1 days = 86,400 secs)

        emit RewardsUpdated(dailySoul, soulPerSecond);
    }

    // update: feeRate (maat)
    function toggleBondMode() public obey(maat) {
        isBondMode == true ? isBondMode = false : isBondMode = true;
        
        emit EmergencyFeeUpdated(false);
    }

    // update accounts: dao, team, and supreme addresses (isis)
    function updateAccounts(address _dao, address _team, address _supreme) external obey(isis) {
        require(dao != _dao || team != _team || supreme != _supreme, 'must be a new account');

        dao = _dao;
        team = _team;
        supreme = _supreme;

        emit AccountsUpdated(dao, team, supreme);
    }

    // update tokens: soul and seance addresses (isis)
    function updateTokens(address _soul, address _seance) external obey(isis) {
        require(soul != IERC20(_soul) || seance != IERC20(_seance), 'must be a new token address');

        soul = SoulPower(_soul);
        seance = SeanceCircle(_seance);

        emit TokensUpdated(_soul, _seance);
    }

    // ** HELPER FUNCTIONS ** //

    // helper functions to convert to wei and 1/100th
    function enWei(uint amount) public pure returns (uint) {  return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}