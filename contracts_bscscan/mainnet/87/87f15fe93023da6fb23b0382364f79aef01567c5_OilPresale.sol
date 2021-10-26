/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

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

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

interface IAccessControlEnumerable is IAccessControl {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;

        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

contract OilPresale is ReentrancyGuard, Pausable, AccessControlEnumerable {
    
    IERC20 public token;
    address payable public wallet;
    bool public startRefund = false;
    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    uint256 public refundStartDate;
    uint256 public availableTokensPresale;
    uint256 public endPresale;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public weiRaised;
    uint256 public rate;
    
    mapping (address => uint256) public contributions;
    mapping (address => uint256) public tokensBack;
    
    event TokensPurchased(address purchaser, address beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);
    
    error RevertTokenPurchase(string);
    
    constructor(uint256 _rate, address payable _wallet, IERC20 _token) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        
        rate = _rate;
        wallet = _wallet;
        token = _token;
    }
    
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role to pause");
        _;
    }
    
    modifier presaleIsActive() {
        uint256 weiAmount = msg.value;
        address beneficiary = msg.sender;
        
        if (endPresale == 0 || block.timestamp > endPresale || availableTokensPresale == 0) {
            revert RevertTokenPurchase("Pre-sale is over");
        }
        
        if (weiAmount == 0) {
            revert RevertTokenPurchase("weiAmount is 0");
        }
        
        if (weiAmount < minPurchase) {
            revert RevertTokenPurchase("have to send at least: 0.1 BNB / 200 OIL");
        }
        
        if ((contributions[beneficiary] + weiAmount) > maxPurchase) {
            revert RevertTokenPurchase("cannot buy more than: 1 BNB / 2000 OIL");
        }
        
        if ((weiRaised + weiAmount) > hardCap) {
            revert RevertTokenPurchase("Hard Cap reached");
        }
        
        if (beneficiary == address(this)) {
            revert RevertTokenPurchase("beneficiary is the contract address");
        }
        
        _;
    }
    
    function setWalletReceiver(address payable newWallet) external onlyOwner {
        wallet = newWallet;
    }
    
    function setHardCap(uint256 value) external onlyOwner {
        hardCap = value;
    }
    
    function setSoftCap(uint256 value) external onlyOwner {
        softCap = value;
    }
    
    function setMaxPurchase(uint256 value) external onlyOwner {
        maxPurchase = value;
    }
    
     function setMinPurchase(uint256 value) external onlyOwner {
        minPurchase = value;
    }
    
    function setRate(uint256 newRate) external onlyOwner {
        rate = newRate;
    }
    
    function setEndPresale(uint256 newEndPresale) external onlyOwner {
        endPresale = newEndPresale;
    }
    
    function setAvailableTokens(uint256 amount) public onlyOwner {
        if(amount == 0) {
            availableTokensPresale = token.balanceOf(address(this));
        }
        else {
            availableTokensPresale = amount;
        }
    }
    
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender), "must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender), "must have pauser role to unpause");
        _unpause();
    }
    
    function startPresale(uint _endDate, uint _minPurchase, uint _maxPurchase, uint _softCap, uint _hardCap) external onlyOwner {
        
        availableTokensPresale = token.balanceOf(address(this));
        
        require(_endDate > block.timestamp, 'duration should be > 0');
        require(_softCap < _hardCap, "Softcap must be lower than 1000 BNB");
        require(_minPurchase < _maxPurchase, "minPurchase must be lower than 1 BNB");
        require(availableTokensPresale > 0 , 'availableTokens must be > 0');
        require(_minPurchase > 0, 'minPurchase should > 0');
        
        startRefund = false;
        refundStartDate = 0;
        weiRaised = 0;
        
        endPresale = _endDate; 
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
    }
    
    function stopPresale() external onlyOwner {
        endPresale = 0;
        
        if(weiRaised >= softCap) {
            wallet.transfer(address(this).balance);
        }
        else{
            startRefund = true;
            refundStartDate = block.timestamp;
        }
    }
    
    function takeCoins() external onlyOwner {
         require(endPresale < block.timestamp, 'Presale should not be active');
         require(startRefund == true && (refundStartDate + 3 days) < block.timestamp, "cannot retrieve funds yet");
         require(address(this).balance > 0, 'Contract has no money');
         wallet.transfer(address(this).balance);    
    }
    
    function takeTokens() external onlyOwner {
        require(endPresale < block.timestamp, 'Presale should not be active');
        require(startRefund == true, "cannot retrieve funds yet");
        require(availableTokensPresale > 0, 'BEP-20 balance is 0');
        token.transfer(wallet, availableTokensPresale);
    }
    
    function takeTokensEmergency() external onlyOwner {
        require(token.balanceOf(address(this)) > 0, 'BEP-20 balance is 0');
        token.transfer(wallet, token.balanceOf(address(this)));
    }
    
    function buyTokens() external nonReentrant whenNotPaused presaleIsActive payable {
        
        uint256 weiAmount = msg.value;
        address beneficiary = msg.sender;
        uint256 tokens = (weiAmount/rate)*10**18;
        
        weiRaised = weiRaised+weiAmount;
        availableTokensPresale = availableTokensPresale - tokens;
        contributions[beneficiary] = contributions[beneficiary]+weiAmount;
        tokensBack[beneficiary] = tokensBack[beneficiary]+tokens;
        
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }
    
    function claimTokens() external nonReentrant whenNotPaused {
        require(endPresale < block.timestamp, 'Presale should not be active');
        require(startRefund == false, 'refund is currently active');
        require(contributions[msg.sender] > 0, 'you didnt purchased any tokens');
        require(tokensBack[msg.sender] > 0, 'you didnt purchased any tokens');
        
        uint256 amt = tokensBack[msg.sender];
        
        contributions[msg.sender] = 0;
        tokensBack[msg.sender] = 0;
        
        token.transfer(msg.sender, amt);
    }
    
    function refundMe() external nonReentrant whenNotPaused {
        require(endPresale < block.timestamp, 'Presale should not be active');
        require(startRefund == true, 'no refund available');
        require(contributions[msg.sender] > 0, 'you have no BNB to claim');
        require(address(this).balance >= contributions[msg.sender], 'contract have no BNB to claim');
        
        uint256 amount = contributions[msg.sender];
        
		if (address(this).balance >= amount) {
			contributions[msg.sender] = 0;
            tokensBack[msg.sender] = 0;
            
			if (amount > 0) {
			    address payable recipient = payable(msg.sender);
				recipient.transfer(amount);
				
				emit Refund(msg.sender, amount);
			}
		}
    }
}