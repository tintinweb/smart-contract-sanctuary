pragma solidity 0.4.21;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) view public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address  owner;

    function Ownable() public{
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public{
        assert(newOwner != address(0));
        owner = newOwner;
    }
}


contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool){
        // require(0 < _value); -- REMOVED AS REQUESTED BY AUDIT
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the balance of. 
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) view public returns (uint256 balance){
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        uint256 _allowance = allowed[_from][msg.sender];
        require (balances[_from] >= _value);
        require (_allowance >= _value);
        // require (_value > 0); // NOTE: Removed due to audit demand (transfer of 0 should be authorized)
        // require ( balances[_to] + _value > balances[_to]);
        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool){
        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_spender, 0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifing the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) view public returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
}


contract  Ammbr is StandardToken, Ownable {
    string public name = &#39;&#39;;
    string public symbol = &#39;&#39;;
    uint8 public  decimals = 0;
    uint256 public maxMintBlock = 0;

    event Mint(address indexed to, uint256 amount);

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner  public returns (bool){
        require(maxMintBlock == 0);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(0,  _to, _amount); // ADDED AS REQUESTED BY AUDIT
        maxMintBlock = 1;
        return true;
    }

    /**
     * @dev Function is used to perform a multi-transfer operation. This could play a significant role in the Ammbr Mesh Routing protocol.
     *  
     * Mechanics:
     * Sends tokens from Sender to destinations[0..n] the amount tokens[0..n]. Both arrays
     * must have the same size, and must have a greater-than-zero length. Max array size is 127.
     * 
     * IMPORTANT: ANTIPATTERN
     * This function performs a loop over arrays. Unless executed in a controlled environment,
     * it has the potential of failing due to gas running out. This is not dangerous, yet care
     * must be taken to prevent quality being affected.
     * 
     * @param destinations An array of destinations we would be sending tokens to
     * @param tokens An array of tokens, sent to destinations (index is used for destination->token match)
     */
    function multiTransfer(address[] destinations, uint256[] tokens) public returns (bool success){
        // Two variables must match in length, and must contain elements
        // Plus, a maximum of 127 transfers are supported
        require(destinations.length > 0);
        require(destinations.length < 128);
        require(destinations.length == tokens.length);
        // Check total requested balance
        uint8 i = 0;
        uint256 totalTokensToTransfer = 0;
        for (i = 0; i < destinations.length; i++){
            require(tokens[i] > 0);            
            // Prevent Integer-Overflow by using Safe-Math
            totalTokensToTransfer = totalTokensToTransfer.add(tokens[i]);
        }
        // Do we have enough tokens in hand?
        // Note: Although we are testing this here, the .sub() function of 
        //       SafeMath would fail if the operation produces a negative result
        require (balances[msg.sender] > totalTokensToTransfer);        
        // We have enough tokens, execute the transfer
        balances[msg.sender] = balances[msg.sender].sub(totalTokensToTransfer);
        for (i = 0; i < destinations.length; i++){
            // Add the token to the intended destination
            balances[destinations[i]] = balances[destinations[i]].add(tokens[i]);
            // Call the event...
            emit Transfer(msg.sender, destinations[i], tokens[i]);
        }
        return true;
    }

    function Ammbr(string _name , string _symbol , uint8 _decimals) public{
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}