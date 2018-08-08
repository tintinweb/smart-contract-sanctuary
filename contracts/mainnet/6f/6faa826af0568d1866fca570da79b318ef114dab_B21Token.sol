pragma solidity 0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


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
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
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
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
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

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, 0x0, _value);
    }
}

contract B21Token is BurnableToken {
    string public constant name = "B21 Token";
    string public constant symbol = "B21";
    uint8 public constant decimals = 18;

    /// Maximum tokens to be allocated (500 million)
    uint256 public constant HARD_CAP = 500000000 * 10**uint256(decimals);

    /// The owner of this address are the B21 team
    address public b21TeamTokensAddress;

    /// This address is used to keep the bounty tokens
    address public bountyTokensAddress;

    /// This address is used to keep the tokens for sale
    address public saleTokensVault;

    /// This address is used to distribute the tokens for sale
    address public saleDistributorAddress;

    /// This address is used to distribute the bounty tokens
    address public bountyDistributorAddress;

    /// This address which deployed the token contract
    address public owner;

    /// when the token sale is closed, the trading is open
    bool public saleClosed = false;

    /// Only allowed to execute before the token sale is closed
    modifier beforeSaleClosed {
        require(!saleClosed);
        _;
    }

    /// Limiting functions to the admins of the token only
    modifier onlyAdmin {
        require(msg.sender == owner || msg.sender == saleTokensVault);
        _;
    }

    function B21Token(address _b21TeamTokensAddress, address _bountyTokensAddress,
    address _saleTokensVault, address _saleDistributorAddress, address _bountyDistributorAddress) public {
        require(_b21TeamTokensAddress != address(0));
        require(_bountyTokensAddress != address(0));
        require(_saleTokensVault != address(0));
        require(_saleDistributorAddress != address(0));
        require(_bountyDistributorAddress != address(0));

        owner = msg.sender;

        b21TeamTokensAddress = _b21TeamTokensAddress;
        bountyTokensAddress = _bountyTokensAddress;
        saleTokensVault = _saleTokensVault;
        saleDistributorAddress = _saleDistributorAddress;
        bountyDistributorAddress = _bountyDistributorAddress;

        /// Maximum tokens to be allocated on the sale
        /// 250M B21
        uint256 saleTokens = 250000000 * 10**uint256(decimals);
        totalSupply = saleTokens;
        balances[saleTokensVault] = saleTokens;
        emit Transfer(0x0, saleTokensVault, saleTokens);

        /// Team tokens - 200M B21
        uint256 teamTokens = 200000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(teamTokens);
        balances[b21TeamTokensAddress] = teamTokens;
        emit Transfer(0x0, b21TeamTokensAddress, teamTokens);

        /// Bounty tokens - 50M B21
        uint256 bountyTokens = 50000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(bountyTokens);
        balances[bountyTokensAddress] = bountyTokens;
        emit Transfer(0x0, bountyTokensAddress, bountyTokens);

        require(totalSupply <= HARD_CAP);
    }

    /// @dev Close the token sale
    function closeSale() public onlyAdmin beforeSaleClosed {
        saleClosed = true;
    }

    /// @dev Trading limited - requires the token sale to have closed
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(saleClosed) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

    /// @dev Trading limited - requires the token sale to have closed
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(saleClosed || msg.sender == saleDistributorAddress || msg.sender == bountyDistributorAddress
        || (msg.sender == saleTokensVault && _to == saleDistributorAddress)
        || (msg.sender == bountyTokensAddress && _to == bountyDistributorAddress)) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}