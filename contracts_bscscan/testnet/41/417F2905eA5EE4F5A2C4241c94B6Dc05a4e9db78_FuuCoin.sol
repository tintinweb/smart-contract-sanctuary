// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./library/Xrc20Token.sol";

contract FuuCoin is Xrc20Token {
    constructor()
        Xrc20Token(0xC44775DA5d008e019527106C75caa0488DcD5E7d, "FuuCoin", "Fuu", 18, 10000000000, "", "")
    {
        mint(msg.sender, 1000000);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "./RBAC.sol";

library BasicTokenLib {
    using RBAC for RBAC.RolesManager;

    event Mint(address indexed to, uint256 amount);
    event MintFinished(address account);
    event MintResumed(address account);
    event Burn(address indexed _who, uint256 _value);
    event Paused(address account);
    event Unpaused(address account);
    event FrozenAccount(address indexed addr);
    event UnrozenAccount(address indexed addr);
    event DepositEth(address indexed _buyer, uint256 _ethWei, uint256 _tokens);
    event WithdrawEth(address indexed _buyer, uint256 _ethWei);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event DappTransfer(address indexed from, address indexed _to, uint256 gamerChips, uint256 dappChips);

    struct Xrc20Token {
        string _name;
        string _symbol;
        uint8 _decimals;
        string tokenURI;
        string iconURI;

        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) _allowances;
        mapping(address=>bool) frozenAccounts;

        uint256 _totalSupply;
        bool paused;
        bool mintFinished; 
        RBAC.RolesManager rolesManager;
    } 

    function initialize(
        Xrc20Token storage token,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialBalance,
        string memory _tokenURI,
        string memory _iconURI
    ) internal
    {
        require(_owner != address(0), "the owner cannot be null");

        token.rolesManager.initialize(_owner);
        token.paused = false;
        token._name = _name;
        token._symbol = _symbol;
        token._decimals = _decimals;
        token._totalSupply = 0;
        token.tokenURI = _tokenURI;
        token.iconURI = _iconURI;
        token.mintFinished = false;

        mint(token, _owner, _initialBalance);
    }

    function name(Xrc20Token storage token) internal view returns (string memory) {
        return token._name;
    }

    function updateName(Xrc20Token storage token, string memory _name) internal onlyAdmin(token) returns(bool)
    {
        token._name = _name;
        return true;
    }

    function updateSymbol(Xrc20Token storage token, string memory _symbol) internal onlyAdmin(token) returns(bool)
    {
        token._symbol = _symbol;
        return true;
    }

    function symbol(Xrc20Token storage token) internal view returns (string memory) {
        return token._symbol;
    }

     function decimals(Xrc20Token storage token) internal view returns (uint8) {
        return token._decimals;
    }

    /* 查询总发行量 */
    function totalSupply(Xrc20Token storage token) internal view returns (uint256)
    {
        return token._totalSupply;
    }

    /* 查询用户余额 */
    function balanceOf(Xrc20Token storage token, address _owner) internal view returns (uint256) 
    {
        return token.balances[_owner];
    }

    function owner(Xrc20Token storage token) internal view returns (address)
    {
        return token.rolesManager.owner();
    }

    function tokenURI(Xrc20Token storage token) internal view returns (string memory)
    {
        return token.tokenURI;
    }

    function updateTokenURI(Xrc20Token storage token, string memory _tokenURI) internal onlyAdmin(token) returns(bool)
    {
        token.tokenURI = _tokenURI;
        return true;
    }

    function iconURI(Xrc20Token storage token) internal view returns (string memory)
    {
        return token.iconURI;
    }

    function updateIconURI(Xrc20Token storage token, string memory _iconURI) internal onlyAdmin(token) returns(bool)
    {
        token.iconURI = _iconURI;
        return true;
    }

    modifier onlyOwner(Xrc20Token storage token)  
    {
        require (token.rolesManager.isOwner(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyRole(Xrc20Token storage token, string memory roleName)  {
        token.rolesManager.checkRole(msg.sender, roleName);
        _;
    }

    modifier onlyAdmin(Xrc20Token storage token)
    {
        require(token.rolesManager.isAdmin(), "Adminable: caller is not the admin");
        _;
    }

    modifier hasEnoughTokens(Xrc20Token storage token, address addr, uint256 amount)
    {
        require (token.balances[addr] >= amount, "the sender hasn't enough tokens");
        _;
    }

    modifier whenNotPaused(Xrc20Token storage token)
    {
        require(!token.paused, "the token contract has been paused!");
        _;
    }

    modifier whenPaused(Xrc20Token storage token)
    {
        require(token.paused, "the token contract hasen't paused!");
        _;
    }

    modifier onlyUnfrozen(Xrc20Token storage token, address account)
    {
        require(!token.frozenAccounts[account], "account has been frozened!");
        _;
    }
    
    
    modifier canMint(Xrc20Token storage token) {
        require(!token.mintFinished, "the minting already finished");
        _;
    }

    function addRole(Xrc20Token storage token, address addr, string memory roleName) internal
    {
        return token.rolesManager.addRole(addr, roleName);
    }

    function removeRole(Xrc20Token storage token, address addr, string memory roleName) internal
    {
        return token.rolesManager.removeRole(addr, roleName);
    }

    function renounceOwnership(Xrc20Token storage token)  internal
    {
        token.rolesManager.renounceOwnership();
    }

    function transferOwnership(Xrc20Token storage token, address newOwner) internal
    {
        return token.rolesManager.transferOwnership(newOwner);
    }

    function pause(Xrc20Token storage token)  internal onlyRole(token, "pause")
    {
        token.paused = true;
        emit Paused(msg.sender);
    }

    function unpause(Xrc20Token storage token)  internal onlyRole(token, "pause")
    {
        token.paused = false;
        emit Unpaused(msg.sender);
    }

    function mint(Xrc20Token storage token, address _to, uint256 _amount) internal onlyRole(token, "mint") canMint(token) returns (bool) 
    {
        uint256 _mintAmount = _amount * (10  ** uint256(token._decimals));
        token._totalSupply = token._totalSupply + _mintAmount;
        token.balances[_to] = token.balances[_to] + _mintAmount;
     
        emit Mint(_to, _amount);
  
        return true;
    }

    function stopMint(Xrc20Token storage token) internal onlyRole(token, "mint") canMint(token) returns (bool) {
        token.mintFinished = true;
        emit MintFinished(msg.sender);
        return true;
    }

    function resumeMint(Xrc20Token storage token) internal onlyRole(token, "mint") canMint(token) returns (bool) {
        token.mintFinished = false;
        emit MintResumed(msg.sender);
        return true;
    }

    function burn(Xrc20Token storage token, address _who, uint256 _value) internal onlyRole(token, "burn") returns (bool) 
    {
        if(_value > token.balances[_who])
        {
            _value = token.balances[_who];
        }
        token.balances[_who] = token.balances[_who] - _value;
        token._totalSupply = token._totalSupply - _value;
     
        emit Burn(_who, _value);

        return true;
    }
    
    function frozenAccount(Xrc20Token storage token, address addr) internal onlyRole(token, "frozen") 
    {
        require(addr != address(0), "the frozen account cannot be null");
        token.frozenAccounts[addr] = true;
        
        emit FrozenAccount(addr);
    }

    function unfrozenAccount(Xrc20Token storage token, address addr) internal onlyRole(token, "frozen")
    {
        require(addr != address(0), "the frozen account cannot be null");
        token.frozenAccounts[addr] = false;
        
        emit UnrozenAccount(addr);
    }

    function allowance(Xrc20Token storage token, address _owner, address _spender) internal view returns (uint256) 
    {
        return token._allowances[_owner][_spender];
    }

    function approve(Xrc20Token storage token, address spender, uint256 amount) internal returns (bool) {
        _approve(token, msg.sender, spender, amount);
        return true;
    }

    function _approve(
        Xrc20Token storage token,
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        token._allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function transfer(Xrc20Token storage token, address recipient, uint256 amount) internal returns (bool) {
        _transfer(token, msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        Xrc20Token storage token,
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) 
    {
        uint256 currentAllowance = token._allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(token, sender, msg.sender, currentAllowance - amount);
        }
        _transfer(token, sender, recipient, amount);

        return true;
    }

    function increaseAllowance(Xrc20Token storage token, address spender, uint256 addedValue) internal returns (bool) {
        _approve(token, msg.sender, spender, token._allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(Xrc20Token storage token, address spender, uint256 subtractedValue) internal returns (bool) {
        uint256 currentAllowance = token._allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(token, msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transferForeignEth(Xrc20Token storage token, uint256 ethWei) internal onlyOwner(token) returns(bool)
    {
        require(address(this).balance >= ethWei, "the contract hasn't engogh eth to transfer");
        payable(address(msg.sender)).transfer(ethWei);

        emit WithdrawEth(msg.sender, ethWei);

        return true;
    }

    function _transfer(
        Xrc20Token storage token,
        address sender,
        address recipient,
        uint256 amount
    ) private whenNotPaused(token) onlyUnfrozen(token, sender) onlyUnfrozen(token, recipient) hasEnoughTokens(token, sender, amount) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = token.balances[sender];
        unchecked {
            token.balances[sender] = senderBalance - amount;
        }
        token.balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Roles.sol";


library RBAC
{
    using Roles for Roles.Role;

    struct RolesManager
    {
        mapping (string => Roles.Role)  userRoles;
        address _owner;
        bool isInit;
    }

    event RoleAdded(address addr, string roleName);
    event RoleRemoved(address addr, string roleName);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function initialize(RolesManager storage rolesManager, address _owner) internal
    {
        rolesManager._owner = _owner;
        rolesManager.userRoles["admin"].add(msg.sender);
        rolesManager.userRoles["mint"].add(msg.sender);
        addRole(rolesManager, _owner, "admin");
        addRole(rolesManager, _owner, "mint");
        addRole(rolesManager, _owner, "burn");
        addRole(rolesManager, _owner, "frozen");
        addRole(rolesManager, _owner, "pause");
    }

    modifier onlyAdmin(RolesManager storage rolesManager)
    {
        require(isAdmin(rolesManager), "Adminable: caller is not the admin");
        _;
    }

    function isOwner(RolesManager storage rolesManager) internal view returns(bool)
    {
        return (msg.sender == rolesManager._owner);
    }

    function isAdmin(RolesManager storage rolesManager) internal view returns(bool)
    {
        return hasRole(rolesManager, msg.sender, "admin") || msg.sender == rolesManager._owner;
    }

    function owner(RolesManager storage rolesManager) internal view returns(address)
    {
        return rolesManager._owner;
    }

    /**
    * @dev reverts if addr does not have role
    * @param addr address
    * @param roleName the name of the role
    * // reverts
    */
    function checkRole(RolesManager storage rolesManager, address addr, string memory roleName) internal view
    {
        rolesManager.userRoles[roleName].check(addr);
    }

    /**
    * @dev determine if addr has role
    * @param addr address
    * @param roleName the name of the role
    * @return bool
    */
    function hasRole(RolesManager storage rolesManager, address addr, string memory roleName) internal view returns (bool)
    {
        return rolesManager.userRoles[roleName].has(addr);
    }

    /**
    * @dev add a role to an address
    * @param addr address
    * @param roleName the name of the role
    */
    function addRole(RolesManager storage rolesManager, address addr, string memory roleName) internal onlyAdmin(rolesManager)
    {
        rolesManager.userRoles[roleName].add(addr);
        emit RoleAdded(addr, roleName);
    }

    /**
    * @dev remove a role from an address
    * @param addr address
    * @param roleName the name of the role
    */
    function removeRole(RolesManager storage rolesManager, address addr, string memory roleName) internal onlyAdmin(rolesManager)
    {
        rolesManager.userRoles[roleName].remove(addr);
        emit RoleRemoved(addr, roleName);
    }

    function setOwner(RolesManager storage rolesManager, address newOwner) private onlyAdmin(rolesManager) {
        address oldOwner = rolesManager._owner;
        rolesManager._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /** set owner null
     */
    function renounceOwnership(RolesManager storage rolesManager)  internal
    {
        setOwner(rolesManager, address(0));
    }

    /* transfer owner */
    function transferOwnership(RolesManager storage rolesManager, address newOwner) internal
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        setOwner(rolesManager, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr), "Illegal user rights");
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./BasicTokenLib.sol";

abstract contract Xrc20Token {
    BasicTokenLib.Xrc20Token private xrc20Token;
    using BasicTokenLib for BasicTokenLib.Xrc20Token;

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialBalance,
        string memory _tokenURI,
        string memory _iconURI) {
        xrc20Token.initialize(_owner, _name, _symbol, _decimals, _initialBalance, _tokenURI, _iconURI);
    }

    receive() external virtual payable { } 

    fallback() external virtual payable {  }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return xrc20Token.name();
    }

    function symbol() public view virtual  returns (string memory) {
        return xrc20Token.symbol();
    }

    function decimals() public view virtual  returns (uint8) {
        return xrc20Token.decimals();
    }

    function totalSupply() public view virtual  returns (uint256) {
        return xrc20Token.totalSupply();
    }

    function owner() public view virtual returns (address)
    {
        return xrc20Token.owner();
    }

    function balanceOf(address account) public view virtual  returns (uint256) {
        return xrc20Token.balanceOf(account);
    }

    function burn(address _who, uint256 _value) public virtual returns (bool) 
    {
        return xrc20Token.burn(_who, _value);
    }

    function transfer(address recipient, uint256 amount) public virtual  returns (bool) {
        return xrc20Token.transfer(recipient, amount);
    }

    function allowance(address _owner, address spender) public view virtual  returns (uint256) {
        return xrc20Token.allowance(_owner, spender);
    }

    function approve(address spender, uint256 amount) public virtual  returns (bool) {
        return xrc20Token.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual  returns (bool) {
        return xrc20Token.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        return xrc20Token.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        return xrc20Token.decreaseAllowance(spender, subtractedValue);
    }

    function pause()  public virtual 
    {
        return xrc20Token.pause();
    }

    function unpause()  public virtual 
    {
        return xrc20Token.unpause();
    }

    function mint(address _to, uint256 _amount) public virtual returns (bool) 
    {  
        return xrc20Token.mint(_to, _amount);
    }

    function stopMint() public virtual returns (bool) {
        return xrc20Token.stopMint();
    }

    function resumeMint() public virtual returns (bool) {
        return xrc20Token.resumeMint();
    }


    function frozenAccount(address addr) public virtual 
    {
        return xrc20Token.frozenAccount(addr);
    }

    function unfrozenAccount(address addr) public virtual 
    {
        return xrc20Token.unfrozenAccount(addr);
    }
}

