pragma solidity 0.4.21;


library SafeMath {
    function mul(uint a, uint b) internal pure  returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure  returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure  returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }

}

contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


// The token
contract Token is ERC20, Ownable {

    using SafeMath for uint;

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals; // How many decimals to show.
    string public version = "v0.1";
    uint public totalSupply;
    bool public locked;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public crowdSaleAddress;


    // Lock transfer for contributors during the ICO
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && msg.sender != owner && locked)
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != crowdSaleAddress)
            revert();
        _;
    }

    // @notice The Token contract
    function Token(address _crowdsaleAddress) public {

        require(_crowdsaleAddress != address(0));
        locked = true; // Lock the transfer of tokens during the crowdsale
        totalSupply = 2600000000e8;
        name = "Kripton";                           // Set the name for display purposes
        symbol = "LPK";                             // Set the symbol for display purposes
        decimals = 8;                               // Amount of decimals
        crowdSaleAddress = _crowdsaleAddress;
        balances[_crowdsaleAddress] = totalSupply;
    }

    // @notice unlock token for trading
    function unlock() public onlyAuthorized {
        locked = false;
    }

    // @lock token from trading during ICO
    function lock() public onlyAuthorized {
        locked = true;
    }

    // @notice transfer tokens to given address
    // @param _to {address} address or recipient
    // @param _value {uint} amount to transfer
    // @return  {bool} true if successful
    function transfer(address _to, uint _value) public onlyUnlocked returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // @notice transfer tokens from given address to another address
    // @param _from {address} from whom tokens are transferred
    // @param _to {address} to whom tokens are transferred
    // @parm _value {uint} amount of tokens to transfer
    // @return  {bool} true if successful
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns(bool success) {
        require(balances[_from] >= _value); // Check if the sender has enough
        require(_value <= allowed[_from][msg.sender]); // Check if allowed is greater or equal
        balances[_from] = balances[_from].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value); // Add the same to the recipient
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // @notice to query balance of account
    // @return _owner {address} address of user to query balance
    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // @notice to query of allowance of one user to the other
    // @param _owner {address} of the owner of the account
    // @param _spender {address} of the spender of the account
    // @return remaining {uint} amount of remaining allowance
    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}