pragma solidity ^0.4.2;



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


interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;}

contract ERC20Token {

    using SafeMath for uint256;


    string public name = "TRIPAL TOKEN";
    string public symbol = "TRIPAL";
    string public standard = "TRIPAL v1.0";
    uint256 public totalSupply;
    uint8 public decimals = 18;


    address checker;

    mapping(address => uint256) public balance_;
    mapping(address => mapping(address => uint256)) public allowance;

    //Approval
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);



    constructor(uint256 _initialSupply) public{
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balance_[msg.sender] = totalSupply;
        //allocate the initial supply
        checker = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }


    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balance_[tokenOwner];
    }

    function getAddress() public view returns (address) {
        return checker;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balance_[_from] >= _value);
        // Check for overflows
        require(balance_[_to].add(_value) > balance_[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balance_[_from].add(balance_[_to]);
        // Subtract from the sender
        balance_[_from] = balance_[_from].sub(_value);
        // Add the same to the recipient
        balance_[_to] = balance_[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balance_[_from].add(balance_[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
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
        require(_value <= allowance[_from][msg.sender] && balance_[_from] >= _value && _value > 0);

        // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
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
        emit Approval(msg.sender, _spender, _value);
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

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }



    /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balance_[_account]);

        totalSupply = totalSupply.sub(_amount);
        balance_[_account] = balance_[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
        emit Burn(_account, _amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender&#39;s allowance for said account. Uses the
     * internal _burn function.
     * @param _account The account whose tokens will be burnt.
     * @param _amount The amount that will be burnt.
     */
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowance[_account][msg.sender]);

        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        allowance[_account][msg.sender] = allowance[_account][msg.sender].sub(
            _amount);
        _burn(_account, _amount);
    }

    /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0);
        totalSupply = totalSupply.add(_amount);
        balance_[_account] = balance_[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

}


contract Owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
    }
}


contract MedallionChainToken is Owned, ERC20Token {

    using SafeMath for uint256;

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    constructor(uint256 _initialSupply) ERC20Token(_initialSupply) public{
        owner = msg.sender;
    }


    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(balance_[_from] >= _value);
        // Check if the sender has enough
        require(balance_[_to].add(_value) >= balance_[_to]);
        // Check for overflows
        require(!frozenAccount[_from]);
        // Check if sender is frozen
        require(!frozenAccount[_to]);
        // Check if recipient is frozen
        balance_[_from] = balance_[_from].sub(_value);
        // Subtract from the sender
        balance_[_to] = balance_[_to].add(_value);
        // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    //mint new tokens
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balance_[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, owner, mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public returns (uint amount){
        amount = msg.value / buyPrice;
        // calculates the amount
        _transfer(this, msg.sender, amount);
        return amount;
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);
        // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);
        // makes the transfers
        msg.sender.transfer(amount * sellPrice);
        // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }



}