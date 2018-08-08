pragma solidity ^0.4.23;

/**
 * @title ERC20 interface
 * @dev Implements ERC20 Token Standard: https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(y != 0);
        uint256 z = x / y;
        assert(x == y * z + x % y);
        return z;
    }
}


/// @title Contract that will work with ERC223 tokens.
contract ERC223ReceivingContract { 
    /*
    * @dev Standard ERC223 function that will handle incoming token transfers.
    * @param _from Token sender address.
    * @param _value Amount of tokens.
    * @param _data Transaction metadata.
    */
    function tokenFallback(address _from, uint _value, bytes _data) external;
}


/**
 * @title Ownable contract
 * @dev The Ownable contract has an owner address, and provides basic authorization control functions.
 */
contract Ownable {
    address public owner;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    // Events
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor(address _owner) public validAddress(_owner) {
        owner = _owner;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param _newOwner The address to transfer ownership to.
    function transferOwnership(address _newOwner) public onlyOwner validAddress(_newOwner) {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}










contract ERC223 is ERC20 {
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}




contract StandardToken is ERC223 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    // Modifiers
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    /*
    * @dev ERC20 method to transfer token to a specified address.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        bytes memory empty;
        transfer(_to, _value, empty);
    }

    /*
    * @dev ERC223 method to transfer token to a specified address with data.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data Transaction metadata.
    */
    function transfer(address _to, uint256 _value, bytes _data) public validAddress(_to) returns (bool success) {
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        // Call token fallback function if _to is a contract. Rejects if not implemented.
        if (codeLength > 0) {
            ERC223ReceivingContract(_to).tokenFallback(msg.sender, _value, _data);
        }

        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    /*
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public validAddress(_to) returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /*
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /*
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}



contract MintableToken is StandardToken, Ownable {
    // Events
    event Mint(uint256 supply, address indexed to, uint256 amount);

    function tokenTotalSupply() public pure returns (uint256);

    /// @dev Allows the owner to mint new tokens
    /// @param _to Address to mint the tokens to
    /// @param _amount Amount of tokens that will be minted
    /// @return Boolean to signify successful minting
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        require(totalSupply.add(_amount) <= tokenTotalSupply());

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Mint(totalSupply, _to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }
}


contract BodhiEthereum is MintableToken {
    // Token configurations
    string public constant name = "Bodhi Ethereum";
    string public constant symbol = "BOE";
    uint256 public constant decimals = 8;

    constructor() Ownable(msg.sender) public {
    }

    // 100 million BOE ever created
    function tokenTotalSupply() public pure returns (uint256) {
        return 100 * (10**6) * (10**decimals);
    }
}