pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, ownership can be transferred in 2 steps (transfer-accept).
 */
contract Ownable {
    address public owner;
    address public pendingOwner;
    bool isOwnershipTransferActive = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do that.");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(isOwnershipTransferActive);
        require(msg.sender == pendingOwner, "Only nominated pretender can do that.");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        isOwnershipTransferActive = true;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function acceptOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        isOwnershipTransferActive = false;
        pendingOwner = address(0);
    }
}


/**
 * @title ERC20 Token Standard Interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * @title Aurum Services Token
 * @author Igor D&#235;min
 * @dev Token with predefined initial supply which could be reduced by owner.
 */
contract AurumToken is ERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "Aurum Services Token";
    string public constant symbol = "AURUM";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 375 * (10 ** 6) * (10 ** uint256(decimals));

    // Expected gradual reduction of total supply
    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Burn(address indexed _owner, uint256 _value);

    constructor() public {
        // Initially total and initial supply are equal
        totalSupply_ = INITIAL_SUPPLY;
        // Initially assign all tokens to the contract&#39;s creator, to rule them all :-)
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @dev Reclaim all ERC20 compatible tokens
     * @param _token ERC20 The address of the token contract
     */
    function reclaimToken(ERC20 _token) external onlyOwner {
        uint256 tokenBalance = _token.balanceOf(this);
        require(_token.transfer(owner, tokenBalance));
    }

    /**
     * @dev Transfer all Ether held by the contract to the owner.
     */
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // subtract from sender&#39;s balance
        balances[msg.sender] = balances[msg.sender].sub(_value);
        // add to recipient&#39;s balance
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Only contract owner can burns a specific amount of tokens that he owns.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public onlyOwner {
        require(_value <= balances[owner]);

        balances[owner] = balances[owner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(owner, _value);
        emit Transfer(owner, address(0), _value);
    }

}