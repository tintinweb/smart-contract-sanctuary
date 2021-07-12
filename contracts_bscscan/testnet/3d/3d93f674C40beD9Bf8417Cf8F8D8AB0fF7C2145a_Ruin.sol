// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../extensions/ERC20Pausable.sol";
import "../extensions/ERC20Capped.sol";
import "../access/AccessControl.sol";

contract Ruin is AccessControl, ERC20Pausable, ERC20Capped {
    bytes32 constant public MINTER_ROLE = keccak256(abi.encodePacked("MINTER_ROLE"));
    bytes32 constant public BURNER_ROLE = keccak256(abi.encodePacked("BURNER_ROLE"));
    
    constructor(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals, 
        uint256 _cap
    ) ERC20(_name, _symbol, _decimals) ERC20Capped(_cap) {
        _setupRole(_msgSender(), ADMIN_ROLE);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address _account, uint256 _amount) internal override(ERC20, ERC20Capped) {
        super._mint(_account, _amount);
    }
    
    function burn(address _account, uint256 _amount) public onlyRole(BURNER_ROLE) {
        _burn(_account, _amount);
    }

    function mint(address _account, uint256 _amount) public onlyRole(MINTER_ROLE) {
        super._mint(_account, _amount);
    }

    function isMinter(address _account) public view returns(bool) {
        return hasRole(_account, MINTER_ROLE);
    }

    function isBurner(address _account) public view returns(bool) {
        return hasRole(_account, BURNER_ROLE);
    }

    function pause() public whenNotPaused onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public whenPaused onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../tokens/ERC20.sol";
import "../utils/Pausable.sol";

abstract contract ERC20Pausable is ERC20, Pausable {
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../tokens/ERC20.sol";

abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;
    
    constructor(uint256 cap_) {
        _cap = cap_;
    }
    
    function cap() public view returns(uint256) {
        return _cap;
    }
    
    function _mint(address _account, uint256 _amount) internal virtual override {
        require(totalSupply() + _amount <= cap(), "ERC20Capped::You mint exceeds your cap");
        super._mint(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AccessControl {
    bytes32 public constant ADMIN_ROLE = 0x00;
    
    mapping(bytes32 => mapping(address => bool)) roles;
    
    event GrantRole(address account, bytes32 role);
    event RevokeRole(address account, bytes32 role);
    event RenounceRole(address account, bytes32 role);
    
    modifier onlyRole(bytes32 role) {
        require(roles[role][msg.sender], "AccessControl::Your role is not able to do this");
        _;
    }
    
    function getAdminRole() public pure returns(bytes32) {
        return ADMIN_ROLE;
    }
    
    function hasRole(address _address, bytes32 _role) public view returns(bool) {
        return roles[_role][_address];
    }
    
    function grantRole(address _account, bytes32 _role) public onlyRole(getAdminRole()) {
       _grantRole(_account, _role);
    }
    
     function revokeRole(address _account, bytes32 _role) public onlyRole(getAdminRole()) {
       _revokeRole(_account, _role);
    }
    
    function renounceRole(address _account, bytes32 _role) public {
        require(_account == msg.sender, "AccessControl::You can only renounce roles for self");
        _revokeRole(msg.sender, _role);
    }
    
    function _setupRole(address _account, bytes32 _role) internal {
        _grantRole(_account, _role);
    }
    
    function _grantRole(address _account, bytes32 _role) private {
        require(!hasRole(_account, _role), "AccessControl::User already granted for this role");
        roles[_role][_account] = true;
        
        emit GrantRole(_account, _role); 
    }
    
    function _revokeRole(address _account, bytes32 _role) private {
        require(hasRole(_account, _role), "AccessControl::User not granted for this role yet");
        roles[_role][_account] = false;
        
        emit RevokeRole(_account, _role); 
    }
    
    // function _renounceRole(address _account, bytes32 _role) private {
    //     require(hasRole(_account, _role), "AccessControl::User not granted for this role yet");
    //     roles[_role][_account] = false;
        
    //     emit RenounceRole(_account, _role); 
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../utils/Context.sol";

contract ERC20 is IERC20, Context {
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    uint256 private _totalSupply;
    
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
     
    function name() external view returns(string memory) {
        return _name;
    }
    
    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns(uint256) {
        return _totalSupply;
    }
     
     
    function balanceOf(address account) public view override returns (uint256) {
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Ruin::Transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }


    function _transfer(
        address _sender, 
        address _recipient, 
        uint256 _amount
    ) private {
        _beforeTokenTransfer(_sender, _recipient, _amount);
        
        require(_recipient != address(0), "Ruin::Address of recipient is ilegal");
        require(_sender != address(0), "Ruin::Address of sender is ilegal");
        require(_amount <= _balances[_sender], "Ruin::Transfer amount exceeds account balance");
        
        _balances[_sender] -= _amount;
        _balances[_recipient] += _amount;
        
        emit Transfer(_sender, _recipient, _amount);
    }
    
    function _approve(
        address _approver, 
        address _spender, 
        uint256 _amount
    ) private {
        require(_approver != address(0), "Ruin::Address of approver is illegal");
        require(_spender != address(0), "Ruin::Address of spender is illegal");
        
        _allowances[_approver][_spender] = _amount;
        
        emit Approval(_approver, _spender, _amount);
    }
    
    function _mint(address _receiver, uint256 _amount) internal virtual {
        require(_receiver != address(0), "Ruin::Address of receiver is illegal");
        
        _totalSupply += _amount;
        _balances[_receiver] += _amount;
        
        emit Transfer(address(0), _receiver, _amount);
    }
    
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "Ruin::Address is illegal"); 
        require(_balances[_account] >= _amount, "Ruin::Burning amount exceeds account balance");
        
        _totalSupply -= _amount;
        _balances[_account] -= _amount;
        
        emit Transfer(_account, address(0), _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual  {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Pausable {
    bool private _paused;

    event Paused(address account);
    event UnPaused(address account);

    constructor() {
        _paused = false;
    }

    function _pause() internal virtual {
        _paused = true;
        emit Paused(msg.sender);
    } 

    function _unpause() internal virtual {
        _paused = false;
        emit UnPaused(msg.sender);
    }

    function paused() public view virtual returns(bool) {
        return _paused;
    }

    modifier whenPaused() {
        require(paused(), "Pausable::Contract is already paused!");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable::Contract is not paused!");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
contract Context {
    function _msgSender() internal view returns(address) {
        return msg.sender;
    }
}