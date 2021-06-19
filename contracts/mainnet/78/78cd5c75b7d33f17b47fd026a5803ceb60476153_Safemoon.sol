/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity >=0.4.21 <0.6.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    uint8 private _burnRateReciprocal = 10;
    address private _owner;
    address private _burnAddr;

    constructor() public {
        _owner  = msg.sender;
        _burnAddr = msg.sender;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev set burn rate reciprocal.
     * @param burnRateReciprocal burn rate reciprocal.
     */
    function setBurnRateReciprocal(uint8 burnRateReciprocal) public onlyOwner {
        _burnRateReciprocal = burnRateReciprocal;
    }

    /**
     * @dev get burn rate reciprocal.
     * @return burn rate reciprocal.
     */
    function getBurnRateReciprocal() public view returns (uint8) {
        return _burnRateReciprocal;
    }

    /**
     * @dev setBurnAddress(address burnAddr) public onlyOwner
     * @param burnAddr burn TRC20 pool address
     */
    function setBurnAddress(address burnAddr) public onlyOwner {
        _burnAddr = burnAddr;
    }

    /**
     * @dev get burn pool address.
     * @return burn pool address
     */
    function getBurnAddress() public onlyOwner view returns (address) {
        return _burnAddr;
    }

    modifier onlyOwner(){
        require(msg.sender == _owner, "No authority");
        _;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        uint256 burnValue = value/_burnRateReciprocal;
        uint256 actualTransferValue = value - burnValue;

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(actualTransferValue);
        _balances[_burnAddr] = _balances[_burnAddr].add(burnValue);
        emit Transfer(from, to, actualTransferValue);
        emit Transfer(from, _burnAddr, burnValue);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

contract SimpleWhitelist is WhitelistedRole {

    bool private _whitelistEnable;

    event RequestedMembership(address indexed account);
    event RemovedMembershipRequest(address indexed account, address indexed whitelistAdmin);

    mapping(address => uint256) private _whitelistAdminsIndex;
    address[] private _adminMembers;

    mapping(address => uint256) private _whitelistedsIndex;
    address[] private _members;

    mapping(address => uint256) private _pendingRequestsIndex;
    address[] private _pendingWhitelistRequests;

    constructor () public {
        _adminMembers.push(msg.sender);
        _members.push(msg.sender);
        _whitelistAdminsIndex[msg.sender] = _adminMembers.length;
        _whitelistedsIndex[msg.sender] = _members.length;
        _whitelistEnable = true;

        super._addWhitelisted(msg.sender);
    }

    function setWhitelistEnable(uint8 enable) public onlyWhitelistAdmin {
        if(enable == 0) {
            _whitelistEnable = false;
        } else {
            _whitelistEnable = true;
        }
    }

    function getWhitelistEnable() public view returns (bool) {
        return _whitelistEnable;
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _adminMembers.push(account);
        _whitelistAdminsIndex[account] = _adminMembers.length;
        super._addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        uint256 index = _whitelistAdminsIndex[msg.sender];
        require(index > 0);
        delete _adminMembers[index-1];
        // _adminMembers[index-1] = address(0);
        super._removeWhitelistAdmin(msg.sender);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _members.push(account);
        _whitelistedsIndex[account] = _members.length;
        super._addWhitelisted(account);
        if (_pendingRequestsIndex[account] > 0) {
            revokeMembershipRequest(account);
        }
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        uint256 index = _whitelistedsIndex[account];
        require(index > 0);
        delete _members[index-1];
        // _members[index-1] = address(0);
        super._removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        uint256 index = _whitelistedsIndex[msg.sender];
        require(index > 0);
        delete _members[index-1];
        super._removeWhitelisted(msg.sender);
    }

    function requestMembership() public {
        require(_pendingRequestsIndex[msg.sender] == 0);
        require(!isWhitelisted(msg.sender));
        _pendingWhitelistRequests.push(msg.sender);
        _pendingRequestsIndex[msg.sender] = _pendingWhitelistRequests.length;
        emit RequestedMembership(msg.sender);
    }

    function revokeMembershipRequest(address account) public onlyWhitelistAdmin {
        uint256 index = _pendingRequestsIndex[account];
        require(index > 0);
        delete _pendingWhitelistRequests[index-1];
        emit RemovedMembershipRequest(account, msg.sender);
    }

    function pendingWhitelistRequests() public view returns(address[] memory addresses) {
        return _pendingWhitelistRequests;
    }

    function members() public view returns(address[] memory addresses) {
        return _members;
    }

    function adminMembers() public view returns(address[] memory addresses) {
        return _adminMembers;
    }
}
contract Safemoon is ERC20, ERC20Detailed, SimpleWhitelist {

    using SafeMath for uint256;

    constructor (
        uint256 supply,
        string memory name,
        string memory symbol,
        uint8 decimals)
    public
    ERC20Detailed (
        name,
        symbol,
        decimals
    )
    {
        //        uint256 _supply = supply.mul(1 ether);
        uint256 _supply = supply*(10**uint256(decimals));
        _mint(msg.sender, _supply);
    }

    /**
    * @dev Transfer token for a specified address if the sender is whitelisted
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        if (getWhitelistEnable() == true) {
            require(isWhitelisted(to));
        }
        super.transfer(to, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another if the sender is whitelisted
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (getWhitelistEnable() == true) {
            require(isWhitelisted(to));
        }
        super.transferFrom(from, to, value);
        return true;
    }
}