pragma solidity ^0.4.18;

/**
 *  @title Smart City Token https://www.smartcitycoin.io
 *  @dev ERC20 standard compliant / https://github.com/ethereum/EIPs/issues/20 /
 *  @dev Amount not sold during Crowdsale is burned
 */

contract SmartCityToken {
    using SafeMath for uint256;

    address public owner;  // address of Token Owner
    address public crowdsale; // address of Crowdsale contract

    string constant public standard = "ERC20"; // token standard
    string constant public name = "Smart City"; // token name
    string constant public symbol = "CITY"; // token symbol

    uint256 constant public decimals = 5; // 1 CITY = 100000 tokens
    uint256 public totalSupply = 252862966307692; // total token provision

    uint256 constant public amountForSale = 164360928100000; // amount that might be sold during ICO - 65% of total token supply
    uint256 constant public amountReserved = 88502038207692; // amount reserved for founders / loyalty / bounties / etc. - 35% of total token supply
    uint256 constant public amountLocked = 61951426745384; // the amount of tokens Owner cannot spend within first 2 years after Crowdsale - 70% of the reserved amount

    uint256 public startTime; // from this time on transfer and transferFrom functions are available to anyone except of token Owner
    uint256 public unlockOwnerDate; // from this time on transfer and transferFrom functions are available to token Owner

    mapping(address => uint256) public balances; // balances array
    mapping(address => mapping(address => uint256)) public allowances; // allowances array

    bool public burned; // indicates whether excess tokens have already been burned

    event Transfer(address indexed from, address indexed to, uint256 value); // Transfer event
    event Approval(address indexed _owner, address indexed spender, uint256 value); // Approval event
    event Burned(uint256 amount); // Burned event

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    /**
     *  @dev Contract initialization
     *  @param _ownerAddress address Token owner address
     *  @param _startTime uint256 Crowdsale end time
     *
     */
    function SmartCityToken(address _ownerAddress, uint256 _startTime) public {
        owner = _ownerAddress; // token Owner
        startTime = _startTime; // token Start Time
        unlockOwnerDate = startTime + 2 years;
        balances[owner] = totalSupply; // all tokens are initially allocated to token owner
    }

    /**
     * @dev Transfers token for a specified address
     * @param _to address The address to transfer to
     * @param _value uint256 The amount to be transferred
     */
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns(bool success) {
        require(now >= startTime);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        if (msg.sender == owner && now < unlockOwnerDate)
            require(balances[msg.sender].sub(_value) >= amountLocked);

        balances[msg.sender] = balances[msg.sender].sub(_value); // subtract requested amount from the sender address
        balances[_to] = balances[_to].add(_value); // send requested amount to the target address

        //Transfer(msg.sender, _to, _value); // trigger Transfer event
        return true;
    }

    /**
     * @dev Transfers tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns(bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowances[_from][msg.sender]);

        if (now < startTime)
            require(_from == owner);

        if (_from == owner && now < unlockOwnerDate)
            require(balances[_from].sub(_value) >= amountLocked);

        uint256 _allowance = allowances[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value); // subtract requested amount from the sender address
        balances[_to] = balances[_to].add(_value); // send requested amount to the target address
        allowances[_from][msg.sender] = _allowance.sub(_value); // reduce sender allowance by transferred amount

        //Transfer(_from, _to, _value); // trigger Transfer event
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _addr address The address to query the balance of.
     * @return uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _addr) public view returns (uint256 balance) {
        return balances[_addr];
    }

    /**
     *  @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *  @param _spender address The address which will spend the funds
     *  @param _value uint256 The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) public returns(bool success) {
        return _approve(_spender, _value);
    }

    /**
     *  @dev Workaround for vulnerability described here: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
     */
    function _approve(address _spender, uint256 _value) internal returns(bool success) {
        require((_value == 0) || (allowances[msg.sender][_spender] == 0));

        allowances[msg.sender][_spender] = _value; // Set spender allowance

        Approval(msg.sender, _spender, _value); // Trigger Approval event
        return true;
    }

    /**
     *  @dev Burns all the tokens which has not been sold during ICO
     */
    function burn() public {
        if (!burned && now > startTime) {
            uint256 diff = balances[owner].sub(amountReserved); // Get the amount of unsold tokens

            balances[owner] = amountReserved;
            totalSupply = totalSupply.sub(diff); // Reduce total provision number

            burned = true;
            Burned(diff); // Trigger Burned event
        }
    }

    /**
     *  @dev Sets Corwdsale contract address & allowance
     *  @param _crowdsaleAddress address The address of the Crowdsale contract
     */
    function setCrowdsale(address _crowdsaleAddress) public {
        require(msg.sender == owner);
        require(crowdsale == address(0));

        crowdsale = _crowdsaleAddress;
        assert(_approve(crowdsale, amountForSale));
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    uint256 c = a / b;
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


    /**
    *            CITY 2.0 token by www.SmartCityCoin.io
    * 
    *          .ossssss:                      `+sssss`      
    *         ` +ssssss+` `.://++++++//:.`  .osssss+       
    *            /sssssssssssssssssssssssss+ssssso`        
    *             -sssssssssssssssssssssssssssss+`         
    *            .+sssssssss+:--....--:/ossssssss+.        
    *          `/ssssssssssso`         .sssssssssss/`      
    *         .ossssss+sssssss-       :sssss+:ossssso.     
    *        `ossssso. .ossssss:    `/sssss/  `/ssssss.    
    *        ossssso`   `+ssssss+` .osssss:     /ssssss`   
    *       :ssssss`      /sssssso:ssssso.       +o+/:-`   
    *       osssss+        -sssssssssss+`                  
    *       ssssss:         .ossssssss/                    
    *       osssss/          `+ssssss-                     
    *       /ssssso           :ssssss                      
    *       .ssssss-          :ssssss                      
    *        :ssssss-         :ssssss          `           
    *         /ssssss/`       :ssssss        `/s+:`        
    *          :sssssso:.     :ssssss      ./ssssss+`      
    *           .+ssssssso/-.`:ssssss``.-/osssssss+.       
    *             .+ssssssssssssssssssssssssssss+-         
    *               `:+ssssssssssssssssssssss+:`           
    *                  `.:+osssssssssssso+:.`              
    *                        `/ssssss.`                    
    *                         :ssssss                      
    */