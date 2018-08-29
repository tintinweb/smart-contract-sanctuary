//TheEthadams&#39;s Prod Ready.
//https://rinkeby.etherscan.io/address/0x8d4665fe98968707da5042be347060e673da98f1#code

pragma solidity ^0.4.22;


interface tokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
 }


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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


contract TokenERC20 {

    using SafeMath for uint256;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals
    uint256 public totalSupply = 500000000 * 10 ** uint256(decimals);

    //Address founder
    address public owner;

    //Address Development.
    address public development = 0x23556CF8E8997f723d48Ab113DAbed619E7a9786;

    //Start timestamp
    //End timestamp
    uint public startTime;
    uint public icoDays;
    uint public stopTime;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = totalSupply;  // Update total supply.
        balanceOf[msg.sender] = 150000000 * 10 ** uint256(decimals);
        //Give this contract some token balances.
        balanceOf[this] = 350000000 * 10 ** uint256(decimals);
        //Set the name for display purposes
        name = tokenName;
        //Set the symbol for display purposes
        symbol = tokenSymbol;
        //Assign owner.
        owner = msg.sender;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    modifier onlyDeveloper() {
      require(msg.sender == development);
      _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
      require(now >= stopTime);//Transfer only after ICO.
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        if(now < stopTime){
          require(_from == owner);//Only owner can move the tokens before ICO is over.
          _transfer(_from, _to, _value);
        } else {
        _transfer(_from, _to, _value);
        }
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract OffGridParadise is TokenERC20 {

    uint256 public buyPrice;
    bool private isKilled; //Changed to true if the contract is killed.

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);


    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (
        string tokenName,
        string tokenSymbol
    ) TokenERC20(tokenName, tokenSymbol) public {
      //Initializes the timestamps
      startTime = now;
      isKilled  = false;
      //This is the PRE-ICO price.Assuming the price of ethereum is $600per Ether.
      setPrice(13300);
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address(Number greater than Zero).
        require (balanceOf[_from] >= _value);               // Check if the sender has enough //Use burn() instead
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }


    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyDeveloper public {
        require(target != development);
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    //Buy tokens from the contract by sending ethers.
    function buyTokens () payable public {
      require(isKilled == false);
      require(msg.sender != development);
      require(msg.sender != owner);
      uint amount = msg.value * buyPrice;
      owner.transfer(msg.value);
      _transfer(this, msg.sender, amount);
    }

    //Buy tokens from the contract by sending ethers(Fall Back Function).
    function () payable public {
      require(isKilled == false);
      require(msg.sender != development);
      require(msg.sender != owner);
      uint amount = msg.value * buyPrice;
      owner.transfer(msg.value);
      if(balanceOf[this] > amount){
      _transfer(this, msg.sender, amount);
      } else {
      _transfer(owner,msg.sender,amount);
      }
    }

    function setPrice(uint256 newBuyingPrice) onlyOwner public {
      buyPrice = newBuyingPrice;
    }

    function setStopTime(uint icodays) onlyOwner public {
      //Minutes in a day is 1440
      icoDays = icodays * 1 days;//Production Purposes.
      stopTime = startTime + icoDays;
    }

    //Transfer transferOwnership
    function transferOwnership(address newOwner) onlyOwner public  {
      owner = newOwner;
  }
    //Stop the contract.
  function killContract() onlyOwner public {
      isKilled = true;
  }

}