pragma solidity ^0.4.15;

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

contract Ownable {
    address public owner;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
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
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    
    
}



contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferByInternal(address from, address to, uint256 value) internal returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event MintedToken(address indexed target, uint256 value);
}

contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 maxSupply_;
    uint256 totalSupply_;

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    } 

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function maxSupply() public view returns (uint256) {
        return maxSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferByInternal(address _from, address _to, uint256 _value) internal returns (bool) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0));
        // Check value more than 0
        require(_value > 0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] = balances[_from].sub(_value);
        // Add the same to the recipient
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
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

    function mintToken(address _target, uint256 _mintedAmount) onlyOwner public {
        require(_target != address(0));
        require(_mintedAmount > 0);
        require(maxSupply_ > 0 && totalSupply_.add(_mintedAmount) <= maxSupply_);
        balances[_target] = balances[_target].add(_mintedAmount);
        totalSupply_ = totalSupply_.add(_mintedAmount);
        Transfer(0, _target, _mintedAmount);
        MintedToken(_target, _mintedAmount);
    }
}

contract CanReclaimToken is Ownable {
    using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
  }
}



contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
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
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) onlyPayloadSize(2) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) onlyPayloadSize(2) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract CBS is StandardToken, CanReclaimToken {
    using SafeMath for uint;

    event BuyToken(address indexed from, uint256 value);
    event SellToken(address indexed from, uint256 value, uint256 sellEth);
    event TransferContractEth(address indexed to, uint256 value);


    string public symbol;
    string public name;
    string public version = "2.0";

    uint8 public decimals;
    uint256 INITIAL_SUPPLY;
    uint256 tokens;

    uint256 public buyPrice;
    uint256 public sellPrice;
    uint256 public contractEth;
    bool public allowBuy;
    bool public allowSell;

    // constructor
    function CBS(
        string _symbol,
        string _name,
        uint8 _decimals, 
        uint256 _INITIAL_SUPPLY,
        uint256 _buyPrice,
        uint256 _sellPrice,
        bool _allowBuy,
        bool _allowSell
    ) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        INITIAL_SUPPLY = _INITIAL_SUPPLY * 10 ** uint256(decimals);
        setBuyPrices(_buyPrice);
        setSellPrices(_sellPrice);

        totalSupply_ = INITIAL_SUPPLY;
        maxSupply_ = INITIAL_SUPPLY;
        balances[owner] = totalSupply_;
        allowBuy = _allowBuy;
        allowSell = _allowSell;
    }

    function setAllowBuy(bool _allowBuy) public onlyOwner {
        allowBuy = _allowBuy;
    }

    function setBuyPrices(uint256 _newBuyPrice) public onlyOwner {
        buyPrice = _newBuyPrice;
    }

    function setAllowSell(bool _allowSell) public onlyOwner {
        allowSell = _allowSell;
    }

    function setSellPrices(uint256 _newSellPrice) public onlyOwner {
        sellPrice = _newSellPrice;
    }

    function () public payable {
        BuyTokens(msg.value);
    }

    function BuyTokens(uint256 _value)  internal {
        tokens = _value.div(buyPrice).mul(100);
        require(allowBuy);
        require(_value > 0 && _value >= buyPrice && tokens > 0);
        require(balances[owner] >= tokens);

        super.transferByInternal(owner, msg.sender, tokens);
        contractEth = contractEth.add(_value);
        BuyToken(msg.sender, _value);
    }

    function transferEther(address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_value <= contractEth);
        _to.transfer(_value);
        contractEth = contractEth.sub(_value);
        TransferContractEth(_to, _value);
        return true;
    }

    

    function sellTokens(uint256 _value) public returns (bool) {
        uint256 sellEth;
        require(allowSell);
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        if (sellPrice == 0){
            sellEth = 0;
        }
        else
        {
            sellEth = _value.mul(sellPrice).div(100);
        }

        super.transferByInternal(msg.sender, owner, _value);
        SellToken(msg.sender, _value, sellEth);
        msg.sender.transfer(sellEth);
        contractEth = contractEth.sub(sellEth);
    }

}