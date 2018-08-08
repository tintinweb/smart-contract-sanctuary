pragma solidity ^0.4.17;

contract ERC20Basic {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {
    
    address public owner;

    /**
     * The address whcih deploys this contrcat is automatically assgined ownership.
     * */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * Functions with this modifier can only be executed by the owner of the contract. 
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
    * Transfers ownership to new Ethereum address. This function can only be called by the 
    * owner.
    * @param _newOwner the address to be granted ownership.
    **/
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract BasicToken is ERC20Basic, Ownable {

    using SafeMath for uint256;

    mapping (address => uint256) balances;

    /**
     * Transfers tokens from the sender&#39;s account to another given account.
     * 
     * @param _to The address of the recipient.
     * @param _amount The amount of tokens to send.
     * */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * Returns the balance of a given address.
     * 
     * @param _addr The address of the balance to query.
     **/
    function balanceOf(address _addr) public constant returns (uint256) {
        return balances[_addr];
    }
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract AdvancedToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint256)) allowances;

    /**
     * Transfers tokens from the account of the owner by an approved spender. 
     * The spender cannot spend more than the approved amount. 
     * 
     * @param _from The address of the owners account.
     * @param _amount The amount of tokens to transfer.
     * */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(allowances[_from][msg.sender] >= _amount && balances[_from] >= _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

    /**
     * Allows another account to spend a given amount of tokens on behalf of the 
     * sender&#39;s account.
     * 
     * @param _spender The address of the spenders account.
     * @param _amount The amount of tokens the spender is allowed to spend.
     * */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowances[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * Increases the amount a given account can spend on behalf of the sender&#39;s 
     * account.
     * 
     * @param _spender The address of the spenders account.
     * @param _amount The amount of tokens the spender is allowed to spend.
     * */
    function increaseApproval(address _spender, uint256 _amount) public returns (bool) {
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].add(_amount);
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * Decreases the amount of tokens a given account can spend on behalf of the 
     * sender&#39;s account.
     * 
     * @param _spender The address of the spenders account.
     * @param _amount The amount of tokens the spender is allowed to spend.
     * */
    function decreaseApproval(address _spender, uint256 _amount) public returns (bool) {
        require(allowances[msg.sender][_spender] != 0);
        if (_amount >= allowances[msg.sender][_spender]) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = allowances[msg.sender][_spender].sub(_amount);
            Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        }
    }

    /**
     * Returns the approved allowance from an owners account to a spenders account.
     * 
     * @param _owner The address of the owners account.
     * @param _spender The address of the spenders account.
     **/
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }

}


contract BurnableToken is AdvancedToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0 && _value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
    }
}


contract UKW is BurnableToken {

    function UKW() public {
        name = "Ubuntukingdomwealth";
        symbol = "UKW";
        decimals = 18;
        totalSupply = 200000000e18;
        balances[msg.sender] = totalSupply;
    }
}