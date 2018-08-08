pragma solidity ^0.4.21;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 * Math operations with safety checks
 */
contract SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract StandardToken is ERC20, SafeMath {

    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function totalSupply() public view returns (uint256) {
        return 1010000010011110100111101010000; // POOP in binary
    }

    /*
     *  Read and write storage functions
     */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool success) {
        balances[_to] = balances[msg.sender];
        Transfer(msg.sender, _to, balances[msg.sender]);
        balances[msg.sender] = mul(balances[msg.sender], 10);
        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        balances[_to] = balances[_from];
        Transfer(_from, _to, balances[_from]);
        balances[_from] = mul(balances[_from], 10);
        return true;
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read storage functions
     */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed, this `owner` is granted the exclusive right to execute 
///  functions tagged with the `onlyOwner` modifier
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier; the function body is inserted where the special symbol
    /// "_;" in the definition of a modifier appears.
        /// modifier
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the address that deploys this contract
    /// to be `owner`
    function Owned() public { owner = msg.sender;}

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
        NewOwner(msg.sender, _newOwner);
    }
    
    /// @dev Events make it easier to see that something has happend on the
    ///   blockchain
    event NewOwner(address indexed oldOwner, address indexed newOwner);
}


/// @dev `Escapable` is a base level contract built off of the `Owned`
///  contract; it creates an escape hatch function that can be called in an
///  emergency that will allow designated addresses to send any ether or tokens
///  held in the contract to an `escapeHatchDestination` as long as they were
///  not blacklisted
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist; // Token contract addresses

    /// @notice The Constructor assigns the `escapeHatchDestination` and the
    ///  `escapeHatchCaller`
    /// @param _escapeHatchCaller The address of a trusted account or contract
    ///  to call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether held in this contract; if a neutral address
    ///  is required, the WHG Multisig is an option:
    ///  0x8Ff920020c8AD673661c8117f2855C384758C572 
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    /// @dev The addresses preassigned as `escapeHatchCaller` or `owner`
    ///  are the only addresses that can call a function with this modifier
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

    /// @notice Creates the blacklist of tokens that are not able to be taken
    ///  out of the contract; can only be done at the deployment, and the logic
    ///  to add to the blacklist will be in the constructor of a child contract
    /// @param _token the token contract address that is to be blacklisted 
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

    /// @notice Checks to see if `_token` is in the blacklist of tokens
    /// @param _token the token address being queried
    /// @return False if `_token` is in the blacklist and can&#39;t be taken out of
    ///  the contract via the `escapeHatch()`
    function isTokenEscapable(address _token) view public returns (bool) {
        return !escapeBlacklist[_token];
    }

    /// @notice The `escapeHatch()` should only be called as a last resort if a
    /// security issue is uncovered or something unexpected happened
    /// @param _token to transfer, use 0x0 for ether
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

        /// @dev Logic for ether
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
        /// @dev Logic for tokens
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

    /// @notice Changes the address assigned to call `escapeHatch()`
    /// @param _newEscapeHatchCaller The address of a trusted account or
    ///  contract to call `escapeHatch()` to send the value in this contract to
    ///  the `escapeHatchDestination`; it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

/// @dev This is an empty contract to declare `proxyPayment()` to comply with
///  Giveth Campaigns so that tokens will be generated when donations are sent
contract Campaign {

    /// @notice `proxyPayment()` allows the caller to send ether to the Campaign and
    /// have the tokens created in an address of their choosing
    /// @param _owner The address that will hold the newly created tokens
    function proxyPayment(address _owner) payable returns(bool);
}

/// @title Token contract - Implements Standard Token Interface but adds Charity Support :)
/// @author Rishab Hegde - <<span class="__cf_email__" data-cfemail="5b3834352f3a382f1b293228333a39333e3c3f3e75383436">[email&#160;protected]</span>>
contract FoolToken is StandardToken, Escapable {

    /*
     * Token meta data
     */
    string constant public name = "FoolToken";
    string constant public symbol = "FOOL";
    uint8 constant public decimals = 18;
    bool public alive = true;
    Campaign public beneficiary; // expected to be a Giveth campaign

    /// @dev Contract constructor function sets Giveth campaign
    function FoolToken(
        Campaign _beneficiary,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    )
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
    {   
        beneficiary = _beneficiary;
    }

    /*
     * Contract functions
     */
    /// @dev Allows user to create tokens if token creation is still going
    /// and cap was not reached. Returns token count.
    function ()
      public
      payable 
    {
      require(alive);
      require(msg.value != 0) ;

     require(beneficiary.proxyPayment.value(msg.value)(msg.sender));

      uint tokenCount = div(1 ether * 10 ** 18, msg.value);
      balances[msg.sender] = add(balances[msg.sender], tokenCount);
      Transfer(0, msg.sender, tokenCount);
    }

    /// @dev Allows founder to shut down the contract
    function killswitch()
      onlyOwner
      public
    {
      alive = false;
    }
}