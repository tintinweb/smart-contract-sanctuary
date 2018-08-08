/**
 * @title GradusInvestmentPlatform
*/


pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
*/
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
     * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

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
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
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
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
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
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
      public
      returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract GRADtoken is StandardToken {
    string public constant name = "Gradus";
    string public constant symbol = "GRAD";
    uint32 public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public tokenBuyRate = 10000;
    
    mapping(address => bool   ) isInvestor;
    address[] public arrInvestors;
    
    address public CrowdsaleAddress;
    bool public lockTransfers = false;

    event Mint (address indexed to, uint256  amount);
    event Burn(address indexed burner, uint256 value);
    
    constructor(address _CrowdsaleAddress) public {
        CrowdsaleAddress = _CrowdsaleAddress;
    }
  
    modifier onlyOwner() {
        /**
         * only Crowdsale contract can run it
         */
        require(msg.sender == CrowdsaleAddress);
        _;
    }   

    function setTokenBuyRate(uint256 _newValue) public onlyOwner {
        tokenBuyRate = _newValue;
    }

    function addInvestor(address _newInvestor) internal {
        if (!isInvestor[_newInvestor]){
            isInvestor[_newInvestor] = true;
            arrInvestors.push(_newInvestor);
        }  
    }

    function getInvestorAddress(uint256 _num) public view returns(address) {
        return arrInvestors[_num];
    }

    function getInvestorsCount() public view returns(uint256) {
        return arrInvestors.length;
    }

     // Override
    function transfer(address _to, uint256 _value) public returns(bool){
        if (msg.sender != CrowdsaleAddress){
            require(!lockTransfers, "Transfers are prohibited");
        }
        addInvestor(_to);
        return super.transfer(_to,_value);
    }

     // Override
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
        if (msg.sender != CrowdsaleAddress){
            require(!lockTransfers, "Transfers are prohibited");
        }
        addInvestor(_to);
        return super.transferFrom(_from,_to,_value);
    }
     
    function mint(address _to, uint256 _value) public onlyOwner returns (bool){
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        addInvestor(_to);
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
    
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    
    function lockTransfer(bool _lock) public onlyOwner {
        lockTransfers = _lock;
    }

    /**
     * function buys tokens from investors and burn it
     */
    function ReturnToken(uint256 _amount) public payable {
        require (_amount > 0);
        require (msg.sender != address(0));
        
        uint256 weiAmount = _amount.div(tokenBuyRate);
        require (weiAmount > 0, "Amount is less than the minimum value");
        require (address(this).balance >= weiAmount, "Contract balance is empty");
        _burn(msg.sender, _amount);
        msg.sender.transfer(weiAmount);
    }

    function() external payable {
        // The token contract can receive ether for buy-back tokens
    }  

}

contract Ownable {
    address public owner;
    address candidate;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        candidate = newOwner;
    }

    function confirmOwnership() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }

}

contract Dividend {
    /**
     * @title Contract receive ether, calculate profit and distributed it to investors
     */
    using SafeMath for uint256;

    uint256 public receivedDividends;
    address public crowdsaleAddress;
    GRADtoken public token;
    CrowdSale public crowdSaleContract;
    mapping (address => uint256) public divmap;
    event PayDividends(address indexed investor, uint256 amount);

    constructor(address _crowdsaleAddress, address _tokenAddress) public {
        crowdsaleAddress = _crowdsaleAddress;
        token = GRADtoken(_tokenAddress);
        crowdSaleContract = CrowdSale(crowdsaleAddress);
    }

    modifier onlyOwner() {
        /**
         * only Crowdsale contract can run it
         */
        require(msg.sender == crowdsaleAddress);
        _;
    }  

    /** 
     * @dev function calculate dividends and store result in mapping divmap
     * @dev stop all transfer before calculations
     * k - coefficient
     */    
    function _CalcDiv() internal {
        uint256 myAround = 1 ether;
        uint256 i;
        uint256 k;
        address invAddress;
        receivedDividends = receivedDividends.add(msg.value);

        if (receivedDividends >= crowdSaleContract.hardCapDividends()){
            uint256 lengthArrInvesotrs = token.getInvestorsCount();
            crowdSaleContract.lockTransfer(true); 
            k = receivedDividends.mul(myAround).div(token.totalSupply());
            uint256 myProfit;
            
            for (i = 0;  i < lengthArrInvesotrs; i++) {
                invAddress = token.getInvestorAddress(i);
                myProfit = token.balanceOf(invAddress).mul(k).div(myAround);
                divmap[invAddress] = divmap[invAddress].add(myProfit);
            }
            crowdSaleContract.lockTransfer(false); 
            receivedDividends = 0;
        }
    }
    
    /**
     * function pay dividends to investors
     */
    function Pay() public {
        uint256 dividends = divmap[msg.sender];
        require (dividends > 0);
        require (dividends <= address(this).balance);
        divmap[msg.sender] = 0;
        msg.sender.transfer(dividends);
        emit PayDividends(msg.sender, dividends);
    } 
    
    function killContract(address _profitOwner) public onlyOwner {
        selfdestruct(_profitOwner);
    }

    /**
     * fallback function can be used to receive funds and calculate dividends
     */
    function () external payable {
        _CalcDiv();
    }  

}


    /**
     * @title CrowdSale contract for Gradus token
     * https://github.com/chelbukhov/Gradus-smart-contract.git
     */
contract CrowdSale is Ownable{
    using SafeMath for uint256;

    // The token being sold
    address myAddress = this;
    
    GRADtoken public token = new GRADtoken(myAddress);
    Dividend public dividendContract = new Dividend(myAddress, address(token));
    
    // address where funds are collected
    address public wallet = 0x0;

    //tokenSaleRate don&#39;t change
    uint256 public tokenSaleRate; 

    // limit for activate function calcucate dividends
    uint256 public hardCapDividends;
    
    /**
     * Current funds during this period of sale
     * and the upper limit for this period of sales
     */
    uint256 public currentFunds = 0;
    uint256 public hardCapCrowdSale = 0;
    bool private isSaleActive;

    /**
    * event for token purchase logging
    * @param _to who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenSale(address indexed _to, uint256 value, uint256 amount);

    constructor() public {
        /**
         * @dev tokenRate is rate tokens per 1 ether. don&#39;t change.
         */
        tokenSaleRate = 10000;

        /**
         * @dev limits in ether for contracts CrowdSale and Dividends
         */
        hardCapCrowdSale = 10 * (1 ether);
        hardCapDividends = 10 * (1 ether);

        /**
         * @dev At start stage profit wallet is owner wallet. Must be changed after owner contract change
         */
        wallet = msg.sender;
    }


    modifier restricted(){
        require(msg.sender == owner || msg.sender == address(dividendContract));
        _;
    }

    function setNewDividendContract(address _newContract) public onlyOwner {
        dividendContract = Dividend(_newContract);
    }


    /**
     * function set upper limit to receive funds
     * value entered in whole ether. 10 = 10 ether
    */
    function setHardCapCrowdSale(uint256 _newValue) public onlyOwner {
        hardCapCrowdSale = _newValue.mul(1 ether);
        currentFunds = 0;
    }


    /**
     * Enter Amount in whole ether. 1 = 1 ether
     */
    function setHardCapDividends(uint256 _newValue) public onlyOwner {
        hardCapDividends = _newValue.mul(1 ether);
    }
    
    function setTokenBuyRate(uint256 _newValue) public onlyOwner {
        token.setTokenBuyRate(_newValue);
    }

    function setProfitAddress(address _newWallet) public onlyOwner {
        require(_newWallet != address(0),"Invalid address");
        wallet = _newWallet;
    }

    /**
     * function sale token to investor
    */
    function _saleTokens() internal {
        require(msg.value >= 10**16, "Minimum value is 0.01 ether");
        require(hardCapCrowdSale >= currentFunds.add(msg.value), "Upper limit on fund raising exceeded");      
        require(msg.sender != address(0), "Address sender is empty");
        require(wallet != address(0),"Enter address profit wallet");
        require(isSaleActive, "Set saleStatus in true");

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(tokenSaleRate);

        token.mint(msg.sender, tokens);
        emit TokenSale(msg.sender, weiAmount, tokens);
        currentFunds = currentFunds.add(msg.value);
        wallet.transfer(msg.value);
    }

  
    function lockTransfer(bool _lock) public restricted {
        /**
         * @dev This function may be started from owner or dividendContract
         */
        token.lockTransfer(_lock);
    }

  //disable if enabled
    function disableSale() onlyOwner() public returns (bool) {
        require(isSaleActive == true);
        isSaleActive = false;
        return true;
    }

  // enable if diabled
    function enableSale()  onlyOwner() public returns (bool) {
        require(isSaleActive == false);
        isSaleActive = true;
        return true;
    }

  // retruns true if sale is currently active
    function saleStatus() public view returns (bool){
        return isSaleActive;
    }

    /**
     * @dev  function kill Dividend contract and withdraw all funds to wallet
     */
    function killDividentContract(uint256 _kod) public onlyOwner {
        require(_kod == 666);
        dividendContract.killContract(wallet);
    }

  // fallback function can be used to sale tokens
    function () external payable {
        _saleTokens();
    }

}