pragma solidity ^0.4.24;

/**
 * @title AddressUtils
 * @dev Utility library of inline functions on addresses
 */
library AddressUtils {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param addr address to check
     * @return whether the target address is a contract
     */
    function isContract(address addr) 
        internal 
        view 
        returns (bool) 
    {
        uint256 size;
        /// @dev XXX Currently there is no better way to check if there is 
        // a contract in an address than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

/**
 * @title Owned
 */
contract Owned {
    address public owner;
    address public newOwner;
    mapping (address => bool) public admins;

    event OwnershipTransferred(
        address indexed _from, 
        address indexed _to
    );

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmins {
        require(admins[msg.sender]);
        _;
    }

    function transferOwnership(address _newOwner) 
        public 
        onlyOwner 
    {
        newOwner = _newOwner;
    }

    function acceptOwnership() 
        public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function addAdmin(address _admin) 
        onlyOwner 
        public 
    {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) 
        onlyOwner 
        public 
    {
        delete admins[_admin];
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() 
        onlyAdmins 
        whenNotPaused 
        public 
    {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() 
        onlyAdmins 
        whenPaused 
        public 
    {
        paused = false;
        emit Unpause();
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title ERC20Interface
 * @dev https: *github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


/**
 * @dev Contract function to receive approval and execute function in one call
 */
contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes data
    )
        public;
}


/**
 * @title Leblock
 * @dev ERC20 Token, with the addition of symbol, name and decimals and an initial supply
 */
contract Leblock is ERC20Interface, Pausable {
    using SafeMath for uint256;
    using AddressUtils for address;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    /**
     * @dev 1 eth this token = price other token which in address,
     * @notice the decimals of price
     */
    mapping(address => uint256) price;

    /**
     * @dev Constructor
     */
    constructor(string _symbol, string _name, uint256 _totalSupply) public {
        owner = msg.sender;
        admins[msg.sender] = true;

        symbol = _symbol;
        name = _name;
        decimals = 18;
        totalSupply = _totalSupply * 10**uint(decimals);
        balances[owner] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _tokenOwner) public view returns (uint256 balance) {
        return balances[_tokenOwner];
    }

    /**
     * Transfer the balance from token owner&#39;s account to `to` account
     * - Owner&#39;s account must have sufficient balance to transfer
     * - 0 value transfers are allowed
     */
    function transfer(address _to, uint256 _tokens) public whenNotPaused returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }

    /**
     * Token owner can approve for `spender` to transferFrom(...) `tokens`
     * from the token owner&#39;s account
     *
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
     * recommends that there are no checks for the approval double-spend attack
     * as this should be implemented in user interfaces
     */
    function approve(address _spender, uint256 _tokens) public whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    /**
     * Transfer `tokens` from the `from` account to the `to` account
     *
     * The calling account must already have sufficient tokens approve(...)-d
     * for spending from the `from` account and
     * - From account must have sufficient balance to transfer
     * - Spender must have sufficient allowance to transfer
     * - 0 value transfers are allowed
     */
    function transferFrom(address _from, address _to, uint256 _tokens) public whenNotPaused returns (bool success) {
        balances[_from] = balances[_from].sub(_tokens);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(_from, _to, _tokens);
        return true;
    }

    /**
     * Returns the amount of tokens approved by the owner that can be
     * transferred to the spender&#39;s account
     */
    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining) {
        return allowed[_tokenOwner][_spender];
    }

    /**
     * Token owner can approve for `spender` to transferFrom(...) `tokens`
     * from the token owner&#39;s account. The `spender` contract function
     * `receiveApproval(...)` is then executed
     */
    function approveAndCall(address _spender, uint256 _tokens, bytes _data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _tokens, this, _data);
        return true;
    }

    function mintToken(address _target, uint256 _mintedAmount) onlyAdmins whenNotPaused public {
        require(totalSupply <= 21 * 10**25);
        balances[_target] = balances[_target].add(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        emit Transfer(0, owner, _mintedAmount);
        emit Transfer(owner, _target, _mintedAmount);
    }

    /*
     * Don&#39;t accept ETH
     **/
    function () public payable {
        revert();
    }

    /**
     * @dev Owner can transfer out any accidentally sent ERC20 tokens
     */
    function withDrawAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        require(tokenAddress.isContract());
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}