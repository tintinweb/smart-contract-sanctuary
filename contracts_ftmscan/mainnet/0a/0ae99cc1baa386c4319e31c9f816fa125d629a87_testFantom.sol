/**
 *Submitted for verification at FtmScan.com on 2022-01-18
*/

// SPDX-License-Identifier: UNLICENSED

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */

/*--------------------------------------------------------------------------------------------------
====================================================================================================



====================================================================================================
--------------------------------------------------------------------------------------------------*/

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint) { return _balances[account]; }
    function transfer(address recipient, uint amount) public virtual override returns (bool) { 
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
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');
        _beforeTokenTransfer(sender, recipient, amount);
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), 'ERC20: mint to the zero address');
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), 'ERC20: burn from the zero address');
        _beforeTokenTransfer(account, address(0), amount);
        uint accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint amount) internal virtual {}
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) { return '0'; }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint value) internal pure returns (string memory) {
        if (value == 0) { return '0x00'; }
        uint temp = value;
        uint length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint value, uint length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }
}

interface IERC165 { function supportsInterface(bytes4 interfaceId) external view returns (bool); }

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {  mapping(address => bool) members; bytes32 adminRole; }
    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
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
            revert(string(abi.encodePacked(
                'AccessControl: account ', Strings.toHexString(uint160(account), 20),
                ' is missing role ', Strings.toHexString(uint(role), 32)))
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) { return _roles[role].adminRole; }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), 'AccessControl: can only renounce roles for self');
        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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

// ----------------------------------------------
//       
// ----------------------------------------------

contract testFantom is ERC20('testFantom', 'TESTFTM'), AccessControl {

    address public supreme;     // supreme divine
    bytes32 public anunnaki;   // admin role
    bytes32 public thoth;     // minter role

    bytes32 public constant DOMAIN_TYPEHASH = // EIP-712 typehash for the contract's domain
        keccak256('EIP712Domain(string name,uint chainId,address verifyingContract)');
    bytes32 public constant DELEGATION_TYPEHASH = // EIP-712 typehash for the delegation struct used by the contract
        keccak256('Delegation(address delegatee,uint nonce,uint expiry)'); 

    // mappings for user accounts (address)
    mapping(address => mapping(uint => Checkpoint)) public checkpoints;     // vote checkpoints
    mapping(address => uint) public numCheckpoints;                       // checkpoint count
    mapping(address => uint) public nonces;                             // signing / validating states
    mapping(address => address) internal _delegates;                  // each accounts' delegate

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
    constructor(address _supreme) {
        supreme = _supreme;
        anunnaki = keccak256('anunnaki'); // alpha supreme
        thoth = keccak256('thoth');      // god of wisdom and magic

        _divinationRitual(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE, supreme); // supreme as root admin
        _divinationRitual(anunnaki, anunnaki, supreme);                    // anunnaki as admin of anunnaki
        _divinationRitual(thoth, anunnaki, supreme);                      // anunnaki as admin of thoth
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

    // mints as the house of thoth so wills (public thoth)
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