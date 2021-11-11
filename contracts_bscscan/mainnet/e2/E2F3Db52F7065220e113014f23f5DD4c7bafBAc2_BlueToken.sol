/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC777 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function granularity() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    function burn(uint256 amount, bytes calldata data) external;

    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    function authorizeOperator(address operator) external;

    function revokeOperator(address operator) external;

    function defaultOperators() external view returns (address[] memory);

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

interface IERC777Recipient {

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC777Sender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1820Registry {
    function setManager(address account, address newManager) external;

    function getManager(address account) external view returns (address);

    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    function updateERC165Cache(address account, bytes4 interfaceId) external;

    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;
    address[] private _allRoleAddresses = new address[](0);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant DEFAULT_OPERATOR_ROLE = keccak256("DEFAULT_OPERATOR_ROLE");
    bytes32 public constant PAUSER_CONTRACT_ROLE = keccak256("PAUSER_CONTRACT_ROLE");
    bytes32 public constant PAUSER_ADDRESS_ROLE = keccak256("PAUSER_ADDRESS_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FORWARDING_ROLE = keccak256("FORWARDING_ROLE");
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_OPERATOR_ROLE, msg.sender);
        _grantRole(PAUSER_CONTRACT_ROLE, msg.sender);
        _grantRole(PAUSER_ADDRESS_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(FORWARDING_ROLE, msg.sender);
    }

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
                        "Account ",
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

    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            bool foundAddress = false;
            for (uint i=0; i<_allRoleAddresses.length; i++) {
                if(_allRoleAddresses[i] == account) {
                    foundAddress = true;
                }
            }
            if(!foundAddress) {
                _allRoleAddresses.push(account);
            }
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    
    function getAddressByRole(bytes32 role) public view returns (address[] memory) {
        uint count = 0;
        for (uint i=0; i<_allRoleAddresses.length; i++) {
            if(hasRole(role, _allRoleAddresses[i])) {
                count++;
            }
        }
        address[] memory addrs = new address[](count);
        count = 0;
        for (uint i=0; i<_allRoleAddresses.length; i++) {
            if(hasRole(role, _allRoleAddresses[i])) {
                addrs[count] = _allRoleAddresses[i];
                count++;
            }
        }
        return addrs;
    }
}

abstract contract Pausable is Context, AccessControl {
    event Paused(address account);
    event Unpaused(address account);
    
    event PausedAddr(address account, address addr);
    event UnpausedAddr(address account, address addr);

    bool private _paused;
    mapping(address => bool) private adresses;

    constructor() {
        _paused = false;
    }
    
    function pausedAddress(address addr) public view virtual returns (bool)  {
        bool isPausedAddr = false;
        if (adresses[addr]) {
            isPausedAddr = true;
        }
        return isPausedAddr;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        if(!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            require(!paused(), "Pausable: paused");
            require(!pausedAddress(_msgSender()), "Pausable: paused");
        }
        _;
    }

    modifier whenPaused() {
        if(!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            require(paused(), "Pausable: not paused");
            require(pausedAddress(_msgSender()), "Pausable: not paused");
        }
        _;
    }

    function pause() public onlyRole(PAUSER_CONTRACT_ROLE) {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyRole(PAUSER_CONTRACT_ROLE) {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    
    function pauseAddress(address addr) public onlyRole(PAUSER_ADDRESS_ROLE) {
        adresses[addr] = true;
        emit PausedAddr(_msgSender(), addr);
    }

    function unpauseAddress(address addr) public onlyRole(PAUSER_ADDRESS_ROLE) {
        if (adresses[addr]) {
            delete adresses[addr];
        }
        emit UnpausedAddr(_msgSender(), addr);
    }
}

abstract contract ForwardingPayment is Context, AccessControl {
    
    event Forwarding(address addr, address to, uint256 amount);

    address private _forwardingAddress;
    mapping(address => bool) private _forwardingAdresses;
    mapping(address => uint256) private _forwardingAmount;

    constructor() {
        _forwardingAddress = _msgSender();
    }
    
    function isForwardingAddress(address addr) public view virtual returns (bool)  {
        bool isPausedAddr = false;
        if (_forwardingAdresses[addr]) {
            isPausedAddr = true;
        }
        return isPausedAddr;
    }
    
    function getForwardingAmount(address addr) public view virtual returns (uint256)  {
        return _forwardingAmount[addr];
    }
    
    function getForwardingAddress() public view virtual returns (address)  {
        return _forwardingAddress;
    }
    
    function _makeForwarding(address from, address to, uint256 amount) internal virtual returns (address) {
        if(_forwardingAdresses[to]) {
            emit Forwarding(from, to, amount);
            _forwardingAmount[to] += amount;
            return _forwardingAddress;
        } else {
            return to;
        }
    }
    
    function setForwardingAddress(address addr) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _forwardingAddress = addr;
    }

    function enableForwarding(address addr) public virtual onlyRole(FORWARDING_ROLE) {
        _forwardingAdresses[addr] = true;
        _forwardingAmount[addr] = 0;
    }

    function disableForwarding(address addr) public virtual onlyRole(FORWARDING_ROLE) {
        if (_forwardingAdresses[addr]) {
            delete _forwardingAdresses[addr];
        }
    }
}

abstract contract PaymentSplitter is Context, AccessControl {
    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account, uint256 shares);
    event FeeCollected(address account, uint256 fee);
    event FeeWhitelistAdded(address account);
    event FeeWhitelistRemoved(address account);

    uint256 private _totalRate;
    uint256 private _totalCollected;
    uint256 private _accuracyRate;
    mapping(address => uint256) private _rates;
    mapping(address => uint256) private _collected;
    mapping(address => bool) private _whiteList;
    address[] private _payees;
    
    constructor() {
        _accuracyRate = 100000;
    }
    
    function getAccuracyRate() public view returns (uint256) {
        return _accuracyRate;
    }

    function totalRate() public view returns (uint256) {
        return _totalRate;
    }

    function totalCollected() public view returns (uint256) {
        return _totalCollected;
    }
    
    function getPayeesLength() public view returns (uint256) {
        return _payees.length;
    }

    function getPayee(uint256 index) public view returns (address) {
        return _payees[index];
    }
    
    function getRate(address account) public view returns (uint256) {
        return _rates[account];
    }
    
    function setAccuracyRate(uint256 accuracyRate) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _accuracyRate = accuracyRate;
    }
    
    function getCollected(address account) public view returns (uint256) {
        return _collected[account];
    }

    function removePayee(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(_rates[account] != 0, "PaymentSplitter: account not has rate");
        for (uint i = 0; i<_payees.length; i++){
            if(_payees[i] == account) {
                delete _payees[i];
            }
        }
        uint256 rate = _rates[account];
        _totalRate = _totalRate - rate;
        delete _rates[account];
        emit PayeeRemoved(account, rate);
    }
    
    function addPayee(address account, uint256 rate) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(rate > 0, "PaymentSplitter: rate are 0");
        require(_rates[account] == 0, "PaymentSplitter: account already has rate");

        _payees.push(account);
        _rates[account] = rate;
        _totalRate = _totalRate + rate;
        emit PayeeAdded(account, rate);
    }
    
    function removeFeeWhitelist(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _whiteList[account];
        emit FeeWhitelistRemoved(account);
    }
    
    function addFeeWhitelist(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _whiteList[account] = true;
        emit FeeWhitelistAdded(account);
    }

    function _newFeeCollected(address account, uint256 fee) internal virtual {
        require(fee >= 0, "PaymentSplitter: fee is less than 0");
        _collected[account] = _collected[account] + fee;
        _totalCollected = _totalCollected + fee;
        emit FeeCollected(account, fee);
    }
    
    function isWhitelistAddress(address account) public view returns (bool) {
        return _whiteList[account];
    }

}

abstract contract ERC777 is Context, IERC777, IERC20, AccessControl, Pausable {
    using Address for address;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    function totalSupply() public view virtual override(IERC20, IERC777) returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenHolder) public view virtual override(IERC20, IERC777) returns (uint256) {
        return _balances[tokenHolder];
    }

    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");

        address from = _msgSender();

        _callTokensToSend(from, from, recipient, amount, "", "");

        _move(from, from, recipient, amount, "", "");

        _callTokensReceived(from, from, recipient, amount, "", "", false);

        return true;
    }

    function burn(uint256 amount, bytes memory data) public virtual override {
        _burn(_msgSender(), amount, data, "");
    }

    function isOperatorFor(address operator, address tokenHolder) public view virtual override returns (bool) {
        return
            operator == tokenHolder ||
            _operators[tokenHolder][operator] ||
            hasRole(DEFAULT_OPERATOR_ROLE, _msgSender());
    }

    function authorizeOperator(address operator) public virtual override {
        require(_msgSender() != operator, "ERC777: authorizing self as operator");
        _operators[_msgSender()][operator] = true;
        emit AuthorizedOperator(operator, _msgSender());
    }

    function revokeOperator(address operator) public virtual override {
        require(operator != _msgSender(), "ERC777: revoking self as operator");
        delete _operators[_msgSender()][operator];
        emit RevokedOperator(operator, _msgSender());
    }

    function defaultOperators() public view virtual override returns (address[] memory) {
        return getAddressByRole(DEFAULT_OPERATOR_ROLE);
    }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");
        _send(sender, recipient, amount, data, operatorData, true);
    }

    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
        _burn(account, amount, data, operatorData);
    }

    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address holder = _msgSender();
        _approve(holder, spender, value);
        return true;
    }

    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");
        require(holder != address(0), "ERC777: transfer from the zero address");

        address spender = _msgSender();

        _callTokensToSend(spender, holder, recipient, amount, "", "");

        _move(spender, holder, recipient, amount, "", "");

        uint256 currentAllowance = _allowances[holder][spender];
        require(currentAllowance >= amount, "ERC777: transfer amount exceeds allowance");
        _approve(holder, spender, currentAllowance - amount);

        _callTokensReceived(spender, holder, recipient, amount, "", "", false);

        return true;
    }

    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual whenNotPaused {
        require(account != address(0), "ERC777: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _totalSupply += amount;
        _balances[account] += amount;

        _callTokensReceived(operator, address(0), account, amount, userData, operatorData, requireReceptionAck);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(from != address(0), "ERC777: send from the zero address");
        require(to != address(0), "ERC777: send to the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    function _burn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual whenNotPaused {
        require(from != address(0), "ERC777: burn from the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, address(0), amount, data, operatorData);

        _beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _totalSupply -= amount;

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {
        _beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    function _approve(
        address holder,
        address spender,
        uint256 value
    ) private {
        require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(from, _TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(to, _TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual whenNotPaused {}
}

contract BlueToken is ERC777, ForwardingPayment, PaymentSplitter {
    
    constructor() ERC777("Blue Token", "BLUE") {
    }

    function mint(address to, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(to, amount, data, "");
    }

    function distribute(address[] memory to, uint256[] memory amount, bytes memory data) public virtual onlyRole(MINTER_ROLE) {
        for(uint256 i = 0;i<to.length;i++) {
            _mint(to[i], amount[i], data, "");
        }
    }

    function transferTo(address[] memory to, uint256[] memory amount) public virtual {
        for(uint256 i = 0;i<to.length;i++) {
            _send(_msgSender(), to[i], amount[i], "", "", true);
        }
    }

    function _move(address operator, address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) internal virtual override {
        require(amount > 0, "PaymentSplitter: amount are 0");
        to = _makeForwarding(from, to, amount);
        if(isWhitelistAddress(from)) {
            super._move(operator, from, to, amount, userData, operatorData);
        } else {
            uint256 totalFee = 0;
            if(amount >= getAccuracyRate()) {
                (bool success, uint256 each) = SafeMath.tryDiv(amount, getAccuracyRate());
                if(success) {
                    for (uint i = 0; i<getPayeesLength(); i++) {
                        address payeeAccount = getPayee(i);
                        uint256 rate = getRate(payeeAccount);
                        uint256 fee = rate * each;
                        if(fee > 0) {
                            totalFee = totalFee + fee;
                            _newFeeCollected(payeeAccount, fee);
                            super._move(operator, from, payeeAccount, fee, "", "");
                        }
                    }
                }
            }
            uint256 amountFinal = amount - totalFee;
            require(amountFinal <= amount, "PaymentSplitter: Err calc - 1");
            require(amountFinal >= 0, "PaymentSplitter: Err calc - 2");
            require(totalFee >= 0, "PaymentSplitter: Err calc - 3");
            require(amountFinal + totalFee == amount, "PaymentSplitter: Err calc - 4");
            
            super._move(operator, from, to, amountFinal, userData, operatorData);
        }
    }

}