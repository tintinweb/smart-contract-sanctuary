pragma solidity ^0.5.0;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Roles.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
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
     * @dev Transfer token to a specified address.
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
        _approve(msg.sender, spender, value);
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
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
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
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
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
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


contract ERC20Burnable is ERC20 {
    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance.
     * @param from address The account whose tokens will be burned.
     * @param value uint256 The amount of token to be burned.
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */

    uint256 public maxSupply;
    uint256 public tokensMinted;

    constructor  (uint256 _maxSupply) public {
        require(_maxSupply > 0);
        maxSupply = _maxSupply;
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        require(tokensMinted.add(value) <= maxSupply);
        tokensMinted = tokensMinted.add(value);
        _mint(to, value);
        return true;
    }

}


contract LPToken is ERC20Burnable, ERC20Mintable {

    string public constant name = "LP";
    string public constant symbol = "LPStaking";
    uint8 public constant decimals = 18;

    struct FreezeParams {
        uint256 timestamp;
        uint256 value;
        bool subsequentUnlock;
    }

    mapping (address => FreezeParams) private _freezed;

    constructor () public ERC20Mintable(1000000000 * 1e18) {
    }

    function freezeOf(address owner) public view returns (uint256) {
        if (_freezed[owner].timestamp <= now){
            if (_freezed[owner].subsequentUnlock){
                uint256  monthsPassed;
                monthsPassed = now.sub(_freezed[owner].timestamp).div(30 days);
                if (monthsPassed >= 10)
                {
                    return 0;
                }
                else
                {
                    return _freezed[owner].value.mul(10-monthsPassed).div(10);
                }
            }
            else {
                return 0;
            }
        }
        else
        {
            return _freezed[owner].value;
        }
    }

    function freezeFor(address owner) public view returns (uint256) {
        return _freezed[owner].timestamp;
    }

    function getAvailableBalance(address from) public view returns (uint256) {

        return balanceOf(from).sub(freezeOf(from));
    }

    function mintWithFreeze(address _to, uint256 _value, uint256 _unfreezeTimestamp, bool _subsequentUnlock) public onlyMinter returns (bool) {
        require(now < _unfreezeTimestamp);
        _setHold(_to, _value, _unfreezeTimestamp, _subsequentUnlock);
        mint(_to, _value);
        return true;
    }

    function _setHold(address to, uint256 value, uint256 unfreezeTimestamp, bool subsequentUnlock) private {
        FreezeParams memory freezeData;
        freezeData = _freezed[to];
        // freeze timestamp is unchangable
        if (freezeData.timestamp == 0) {
            freezeData.timestamp = unfreezeTimestamp;
            freezeData.subsequentUnlock = subsequentUnlock;
        }
        freezeData.value = freezeData.value.add(value);
        _freezed[to] = freezeData;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(getAvailableBalance(msg.sender) >= value);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(getAvailableBalance(from) >= value);
        return super.transferFrom(from, to, value);
    }

    function burn(uint256 value) public {
        require(getAvailableBalance(msg.sender) >= value);
        super.burn(value);
    }

    function burnFrom(address from, uint256 value) public  {
        require(getAvailableBalance(from) >= value);
        super.burnFrom(from, value);
    }

    function approveAndCall(address _spender, uint256 _value, string memory _extraData
    ) public returns (bool success) {
        approve(_spender, _value);

        // This portion is copied from ConsenSys's Standard Token Contract. It
        //  calls the approvalFallback function that is part of the contract that
        //  is being approved (`_spender`). The function should look like:
        //  `approvalFallback(address _from, uint256 _value, address
        //  _token, string memory _extraData)` It is assumed that the call
        //  *should* succeed, otherwise the plain vanilla approve would be used
        CallReceiver(_spender).approvalFallback(
           msg.sender,
           _value,
           address(this),
           _extraData
        );
        return true;
    }

}

contract CallReceiver {
    function approvalFallback(address _from, uint256 _value, address _token, string memory _extraData) public ;
}