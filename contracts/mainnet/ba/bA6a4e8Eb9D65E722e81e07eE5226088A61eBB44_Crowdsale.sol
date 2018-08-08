pragma solidity ^0.4.13;

contract Crowdsale {
    using SafeMath for uint256;

    // Address of the owner
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Token being sold
    Token public token;

    // start and end timestamps where investments are allowed (both inclusive)
    //  uint256 public startTime = 1524245400;
    uint256 public startTime = 1523842200;
    uint256 public endTime = 1525973400;

    // Crowdsale cap (how much can be raised total)
    uint256 public cap = 25000 ether;

    // Address where funds are collected
    address public wallet = 0xff2A97D65E486cA7Bd209f55Fa1dA38B6D5Bf260;

    // Predefined rate of token to Ethereum (1/rate = crowdsale price)
    uint256 public rate = 200000;

    // Min/max purchase
    uint256 public minSale = 0.0001 ether;
    uint256 public maxSale = 1000 ether;

    // amount of raised money in wei
    uint256 public weiRaised;
    mapping(address => uint256) public contributions;

    // Finalization flag for when we want to withdraw the remaining tokens after the end
    bool public finished = false;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(address _token) public {
        require(_token != address(0));
        owner = msg.sender;
        token = Token(_token);
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }


    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);

        // update total and individual contributions
        weiRaised = weiRaised.add(weiAmount);
        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);

        // Send tokens
        token.transfer(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        // Send funds
        wallet.transfer(msg.value);
    }

    // Returns true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = weiRaised >= cap;
        bool endTimeReached = now > endTime;
        return capReached || endTimeReached || finished;
    }

    // Bonuses for larger purchases (in hundredths of percent)
    function bonusPercentForWeiAmount(uint256 weiAmount) public pure returns (uint256) {
        if (weiAmount >= 500 ether) return 1000;
        // 10%
        if (weiAmount >= 250 ether) return 750;
        // 7.5%
        if (weiAmount >= 100 ether) return 500;
        // 5%
        if (weiAmount >= 50 ether) return 375;
        // 3.75%
        if (weiAmount >= 15 ether) return 250;
        // 2.5%
        if (weiAmount >= 5 ether) return 125;
        // 1.25%
        return 0;
        // 0% bonus if lower than 5 eth
    }

    // Returns you how much tokens do you get for the wei passed
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 tokens = weiAmount.mul(rate);
        uint256 bonus = bonusPercentForWeiAmount(weiAmount);
        tokens = tokens.mul(10000 + bonus).div(10000);
        return tokens;
    }

    // Returns true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool moreThanMinPurchase = msg.value >= minSale;
        bool lessThanMaxPurchase = contributions[msg.sender] + msg.value <= maxSale;
        bool withinCap = weiRaised.add(msg.value) <= cap;

        return withinPeriod && moreThanMinPurchase && lessThanMaxPurchase && withinCap && !finished;
    }

    // Escape hatch in case the sale needs to be urgently stopped
    function endSale() public onlyOwner {
        finished = true;
        // send remaining tokens back to the owner
        uint256 tokensLeft = token.balanceOf(this);
        token.transfer(owner, tokensLeft);
    }

    // set rate for gray so we can handle time based sales rates
    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    // set start time
    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    // set end time
    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    // set finalized time so contract can be paused
    function setFinished(bool _finished) public onlyOwner {
        finished = _finished;
    }

    // set cap time so contract cap can be adjusted as bonus vary
    function setCap(uint256 _cap) public onlyOwner {
        cap = _cap * 1 ether;
    }

    // set Min Contribution
    function setMinSale(uint256 _min) public onlyOwner {
        minSale = _min * 1 ether;
    }

    // set Max Contribution
    function setMaxSale(uint256 _max) public onlyOwner {
        maxSale = _max * 1 ether;
    }


}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Token {
    // Public variables of the token
    string public name = "VoxelX GRAY";
    string public symbol = "GRAY";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * 10 ** uint256(decimals); // 10 billion tokens;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function Token() public {
        balanceOf[msg.sender] = totalSupply;
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

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
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
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
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