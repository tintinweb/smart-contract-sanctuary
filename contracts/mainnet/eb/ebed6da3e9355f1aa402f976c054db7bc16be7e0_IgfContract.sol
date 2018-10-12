pragma solidity 0.4.23;

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
    constructor() public {
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
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract IgfContract is Ownable
{

using SafeMath for uint256;
    //INVESTOR REPOSITORY
    mapping(address => uint256) internal balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    mapping (address => uint256) internal totalAllowed;

    /**
    * @dev total number of tokens in existence
    */
    uint256 internal totSupply;

    //COMMON
    function totalSupply() view public returns(uint256)
    {
        return totSupply;
    }
    
    function getTotalAllowed(address _owner) view public returns(uint256)
    {
        return totalAllowed[_owner];
    }

    function setTotalAllowed(address _owner, uint256 _newValue) internal
    {
        totalAllowed[_owner]=_newValue;
    }


    function setTotalSupply(uint256 _newValue) internal
    {
        totSupply=_newValue;
    }


    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */

    function balanceOf(address _owner) view public returns(uint256)
    {
        return balances[_owner];
    }

    function setBalanceOf(address _investor, uint256 _newValue) internal
    {
        require(_investor!=0x0000000000000000000000000000000000000000);
        balances[_investor]=_newValue;
    }


    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */

    function allowance(address _owner, address _spender) view public returns(uint256)
    {
        require(msg.sender==_owner || msg.sender == _spender || msg.sender==getOwner());
        return allowed[_owner][_spender];
    }

    function setAllowance(address _owner, address _spender, uint256 _newValue) internal
    {
        require(_spender!=0x0000000000000000000000000000000000000000);
        uint256 newTotal = getTotalAllowed(_owner).sub(allowance(_owner, _spender)).add(_newValue);
        require(newTotal <= balanceOf(_owner));
        allowed[_owner][_spender]=_newValue;
        setTotalAllowed(_owner,newTotal);
    }



// TOKEN 
   constructor(uint256 _rate, uint256 _minPurchase,uint256 _cap) public
    {
        require(_minPurchase>0);
        require(_rate > 0);
        require(_cap > 0);
        rate=_rate;
        minPurchase=_minPurchase;
        cap = _cap;
    }

    bytes32 public constant name = "IGFToken";

    bytes3 public constant symbol = "IGF";

    uint8 public constant decimals = 8;

    uint256 public cap;

    bool internal mintingFinished;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Mint(address indexed to, uint256 amount);

    event MintFinished();
    
    event Burn(address indexed _owner, uint256 _value);

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function getName() view public returns(bytes32)
    {
        return name;
    }

    function getSymbol() view public returns(bytes3)
    {
        return symbol;
    }

    function getTokenDecimals() view public returns(uint256)
    {
        return decimals;
    }
    
    function getMintingFinished() view public returns(bool)
    {
        return mintingFinished;
    }

    function getTokenCap() view public returns(uint256)
    {
        return cap;
    }

    function setTokenCap(uint256 _newCap) external onlyOwner
    {
        cap=_newCap;
    }


    /**
    * @dev Burns the tokens of the specified address.
    * @param _owner The holder of tokens.
    * @param _value The amount of tokens burned
    */

  function burn(address _owner,uint256 _value) external  {
    require(_value <= balanceOf(_owner));
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    setBalanceOf(_owner, balanceOf(_owner).sub(_value));
    setTotalSupply(totalSupply().sub(_value));
    emit Burn(_owner, _value);
  }

    

    function updateTokenInvestorBalance(address _investor, uint256 _newValue) onlyOwner external
    {
        addTokens(_investor,_newValue);
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
    */

    function transfer(address _to, uint256 _value) external{
        require(msg.sender!=_to);
        require(_value <= balanceOf(msg.sender));

        // SafeMath.sub will throw if there is not enough balance.
        setBalanceOf(msg.sender, balanceOf(msg.sender).sub(_value));
        setBalanceOf(_to, balanceOf(_to).add(_value));

        emit Transfer(msg.sender, _to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) external {
        require(_value <= balanceOf(_from));
        require(_value <= allowance(_from,_to));
        setBalanceOf(_from, balanceOf(_from).sub(_value));
        setBalanceOf(_to, balanceOf(_to).add(_value));
        setAllowance(_from,_to,allowance(_from,_to).sub(_value));
        emit Transfer(_from, _to, _value);
    }

    /**
 * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
 *
 * Beware that changing an allowance with this method brings the risk that someone may use both the old
 * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
 * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 * @param _owner The address of the owner which allows tokens to a spender
 * @param _spender The address which will spend the funds.
 * @param _value The amount of tokens to be spent.
 */
    function approve(address _owner,address _spender, uint256 _value) external {
        require(msg.sender ==_owner);
        setAllowance(msg.sender,_spender, _value);
        emit Approval(msg.sender, _spender, _value);
    }


    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _owner The address of the owner which allows tokens to a spender
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _owner, address _spender, uint _addedValue) external{
        require(msg.sender==_owner);
        setAllowance(_owner,_spender,allowance(_owner,_spender).add(_addedValue));
        emit Approval(_owner, _spender, allowance(_owner,_spender));
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _owner The address of the owner which allows tokens to a spender
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _owner,address _spender, uint _subtractedValue) external{
        require(msg.sender==_owner);

        uint oldValue = allowance(_owner,_spender);
        if (_subtractedValue > oldValue) {
            setAllowance(_owner,_spender, 0);
        } else {
            setAllowance(_owner,_spender, oldValue.sub(_subtractedValue));
        }
        emit Approval(_owner, _spender, allowance(_owner,_spender));
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */


    function mint(address _to, uint256 _amount) canMint internal{
        require(totalSupply().add(_amount) <= getTokenCap());
        setTotalSupply(totalSupply().add(_amount));
        setBalanceOf(_to, balanceOf(_to).add(_amount));
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }
    
    function addTokens(address _to, uint256 _amount) canMint internal{
        require( totalSupply().add(_amount) <= getTokenCap());
        setTotalSupply(totalSupply().add(_amount));
        setBalanceOf(_to, balanceOf(_to).add(_amount));
        emit Transfer(address(0), _to, _amount);
    }    

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() canMint onlyOwner external{
        mintingFinished = true;
        emit MintFinished();
    }

    //Crowdsale
    
        // what is minimal purchase of tokens
    uint256 internal minPurchase;

    // how many token units a buyer gets per wei
    uint256 internal rate;

    // amount of raised money in wei
    uint256 internal weiRaised;
    
    /**
     * event for token purchase logging
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

    event InvestmentsWithdrawn(uint indexed amount, uint indexed timestamp);

    function () external payable {
    }

    function getTokenRate() view public returns(uint256)
    {
        return rate;
    }

    function getMinimumPurchase() view public returns(uint256)
    {
        return minPurchase;
    }

    function setTokenRate(uint256 _newRate) external onlyOwner
    {
        rate = _newRate;
    }
    
    function setMinPurchase(uint256 _newMin) external onlyOwner
    {
        minPurchase = _newMin;
    }

    function getWeiRaised() view external returns(uint256)
    {
        return weiRaised;
    }

    // low level token purchase function
    function buyTokens() external payable{
        require(msg.value > 0);
        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);
        require(validPurchase(tokens));

        // update state
        weiRaised = weiRaised.add(weiAmount);
        mint(msg.sender, tokens);
        emit TokenPurchase(msg.sender, weiAmount, tokens);
    }

    // Override this method to have a way to add business logic to your crowdsale when buying
    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.div(getTokenRate());
    }

    // get all rised wei
    function withdrawInvestments() external onlyOwner{
        uint  amount = address(this).balance;
        getOwner().transfer(amount * 1 wei);
        emit InvestmentsWithdrawn(amount, block.timestamp);
    }
    
    function getCurrentInvestments() view external onlyOwner returns(uint256)
    {
        return address(this).balance;
    }

    function getOwner() view internal returns(address)
    {
        return owner;
    }

    // @return true if the transaction can buy tokens
    function validPurchase(uint256 tokensAmount) internal view returns (bool) {
        bool nonZeroPurchase = tokensAmount != 0;
        bool acceptableAmount = tokensAmount >= getMinimumPurchase();
        return nonZeroPurchase && acceptableAmount;
    }
    
    // CASHIER
    uint256 internal dividendsPaid;

    event DividendsPayment(uint256 amount, address beneficiary);

    function getTotalDividendsPaid() view external onlyOwner returns (uint256)
    {
        return dividendsPaid;
    }

    function getBalance() view public onlyOwner returns (uint256)
    {
        return address(this).balance;
    }

    function payDividends(address beneficiary,uint256 amount) external onlyOwner returns(bool)
    {
        require(amount > 0);
        validBeneficiary(beneficiary);
        beneficiary.transfer(amount);
        dividendsPaid.add(amount);
        emit DividendsPayment(amount, beneficiary);
        return true;
    }

    function depositDividends() payable external onlyOwner
    {
       address(this).transfer(msg.value);
    }
    
    function validBeneficiary(address beneficiary) view internal
    {
        require(balanceOf(beneficiary)>0);
    }
    
    
    //duplicates
    
    function getInvestorBalance(address _address) view external returns(uint256)
    {
        return balanceOf(_address);
    }
}