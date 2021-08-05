/**
 *Submitted for verification at Etherscan.io on 2020-12-23
*/

pragma solidity 0.6.2;



/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
    public
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}



/**
 * @dev Math operations with safety checks that throw on error. This contract is based on the
 * source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol.
 */
library SafeMath
{
  /**
   * List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant OVERFLOW = "008001";
  string constant SUBTRAHEND_GREATER_THEN_MINUEND = "008002";
  string constant DIVISION_BY_ZERO = "008003";

  /**
   * @dev Multiplies two numbers, reverts on overflow.
   * @param _factor1 Factor number.
   * @param _factor2 Factor number.
   * @return product The product of the two factors.
   */
  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2, OVERFLOW);
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient, reverts on division by zero.
   * @param _dividend Dividend number.
   * @param _divisor Divisor number.
   * @return quotient The quotient.
   */
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
    // Solidity automatically asserts when dividing by 0, using all gas.
    require(_divisor > 0, DIVISION_BY_ZERO);
    quotient = _dividend / _divisor;
    // assert(_dividend == _divisor * quotient + _dividend % _divisor); // There is no case in which this doesn't hold.
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param _minuend Minuend number.
   * @param _subtrahend Subtrahend number.
   * @return difference Difference.
   */
  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend, SUBTRAHEND_GREATER_THEN_MINUEND);
    difference = _minuend - _subtrahend;
  }

  /**
   * @dev Adds two numbers, reverts on overflow.
   * @param _addend1 Number.
   * @param _addend2 Number.
   * @return sum Sum.
   */
  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1, OVERFLOW);
  }

  /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when
    * dividing by zero.
    * @param _dividend Number.
    * @param _divisor Number.
    * @return remainder Remainder.
    */
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder)
  {
    require(_divisor != 0, DIVISION_BY_ZERO);
    remainder = _dividend % _divisor;
  }

}


/**
 * @dev signature of external (deployed) contract (ERC20 token)
 * only methods we will use
 */
contract ERC20Token {
 
    function totalSupply() external view returns (uint256){}
    function balanceOf(address account) external view returns (uint256){}
    function allowance(address owner, address spender) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    function decimals()  external view returns (uint8){}
  
}



contract TokenSale is
  Ownable
{
    using SafeMath for uint256;
   
    modifier onlyPriceManager() {
      require(
          msg.sender == price_manager,
          "only price manager can call this function"
          );
          _;
    }
  
   
   
    ERC20Token token;
    
    /**
    * @dev some non-working address from the start to ensure owner will set correct one
    */
   
    address ERC20Contract = 0x0000000000000000000000000000000000000000;
    address price_manager = 0x0000000000000000000000000000000000000000;
    
    /**
    * @dev 10**18 for tokens with 18 digits, need to be changed accordingly (setter/getter)
    */
    uint256 adj_constant = 1000000000000000000; 
    
    //initial in wei
    uint256  sell_price = 2000000000000000; 
    
    //initial in wei
    uint256  buyout_price = 1; 
    
    //events
    event Bought(uint256 amount, address wallet);
    event Sold(uint256 amount, address wallet);
    event TokensDeposited(uint256 amount, address wallet);
    event FinneyDeposited(uint256 amount, address wallet);
    event Withdrawn(uint256 amount, address wallet);
    event TokensWithdrawn(uint256 amount, address wallet);
   
    /**
    * @dev set price_manager == owner in the beginning, but could be changed by setter, below
    */
    constructor() public {
        price_manager = owner;
    }
    
    
    function setPriceManagerRight(address newPriceManager) external onlyOwner{
          price_manager = newPriceManager;
    }
      
      
    function getPriceManager() public view returns(address){
        return price_manager;
    }
    
    
    /**
    * @dev setter/getter for ERC20 linked to exchange (current) smartcontract
    */
    function setERC20(address newERC20Contract) external onlyOwner returns(bool){
        
        ERC20Contract = newERC20Contract;
        token = ERC20Token(ERC20Contract); 
    }
    
    
    function getERC20() external view returns(address){
        return ERC20Contract;
    }

    /**
    * @dev setter/getter for digits constant (current 10**18)
    */
    function setAdjConstant(uint256 new_adj_constant) external onlyOwner{
        adj_constant = new_adj_constant;
    }
    
    function getAdjConstant() external view returns(uint256){  
        return adj_constant;
    }
 
    /**
    * @dev setters/getters for prices 
    */
    function setSellPrice(uint256 new_sell_price) external onlyPriceManager{
        sell_price = new_sell_price;
    }
    
    function setBuyOutPrice(uint256 new_buyout_price) external onlyPriceManager{
        buyout_price = new_buyout_price;
    }
    
    function getSellPrice() external view returns(uint256){  
        return sell_price;
    }
    
    function getBuyOutPrice() external view returns(uint256){  
        return buyout_price;
    }
    
    
    /**
    * @dev two functions below are to assess 'value' of buy/sell
    */
    
    //number of tokens I can buy for amount (in wei), "user" view
    function calcCanBuy(uint256 forWeiAmount) external view returns(uint256){
        require(forWeiAmount > 0,"forWeiAmount should be > 0");
        uint256 amountTobuy = forWeiAmount.div(sell_price);
       
        //not adjusted [10 ** decimals]), i.e. for frontend
        return amountTobuy; 
    }
    
     
    //cash I will get for tokens ("user" view)
    function calcCanGet(uint256 tokensNum) external view returns(uint256){
        require(tokensNum > 0,"tokensNum should be > 0"); //it is "frontend" tokens
        uint256 amountToGet = tokensNum.mul(buyout_price);
        return amountToGet; //wei
    }
    
    
    /**
    * @dev user buys tokens - number of tokens calc. based on value sent
    */
    function buy() payable external notContract returns (bool) {
        uint256 amountSent = msg.value; //in wei..
        require(amountSent > 0, "You need to send some Ether");
         uint256 dexBalance = token.balanceOf(address(this));
        //calc number of tokens (real ones, not converted based on decimals..)
        uint256 amountTobuy = amountSent.div(sell_price); //tokens as user see them
       
        uint256 realAmountTobuy = amountTobuy.mul(adj_constant); //tokens adjusted to real ones
        
       
        
        require(realAmountTobuy > 0, "not enough ether to buy any feasible amount of tokens");
        require(realAmountTobuy <= dexBalance, "Not enough tokens in the reserve");
        
    
        
        try token.transfer(msg.sender, realAmountTobuy) { //ensure we revert in case of failure
            emit Bought(amountTobuy, msg.sender);
            return true;
        } catch {
            revert();
        }
        
    }
    
    
    receive() external payable {// called when ether is send

        uint256 amountSent = msg.value; //in wei..
        require(amountSent > 0, "You need to send some Ether");
        uint256 dexBalance = token.balanceOf(address(this));
        //calc number of tokens (real ones, not converted based on decimals..)
        uint256 amountTobuy = amountSent.div(sell_price); //tokens as user see them
       
        uint256 realAmountTobuy = amountTobuy.mul(adj_constant); //tokens adjusted to real ones
        
       
        
        require(realAmountTobuy > 0, "not enough ether to buy any feasible amount of tokens");
        require(realAmountTobuy <= dexBalance, "Not enough tokens in the reserve");
        
        try token.transfer(msg.sender, realAmountTobuy) { //ensure we revert in case of failure
            emit Bought(amountTobuy, msg.sender);
            return;
        } catch {
            revert();
        }
        
    }
    
    
    /**
    * @dev user sells tokens
    */
    function sell(uint256 amount_tokens) external notContract returns(bool) {
        uint256 amount_wei = 0;
        require(amount_tokens > 0, "You need to sell at least some tokens");
        uint256 realAmountTokens = amount_tokens.mul(adj_constant);
        
        uint256 token_bal = token.balanceOf(msg.sender);
        require(token_bal >= realAmountTokens, "Check the token balance on your wallet");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= realAmountTokens, "Check the token allowance");
       
        amount_wei = amount_tokens.mul(buyout_price); //convert to wei
        
        
        require(address(this).balance > amount_wei, "unsufficient funds");
        bool success = false;
       
        //ensure we revert in case of failure 
        try token.transferFrom(msg.sender, address(this), realAmountTokens) { 
            //just continue if all good..
        } catch {
            require(false,"tokens transfer failed");
            return false;
        }
        
        
        // **   msg.sender.transfer(amount_wei); .** 
       
        (success, ) = msg.sender.call.value(amount_wei)("");
        require(success, "Transfer failed.");
        // ** end **
        
      
            // all done..
        emit Sold(amount_tokens, msg.sender);
        return true; //normal completion
       
    }


    
    /**
    * @dev returns contract balance, in wei
    */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
    * @dev returns contract tokens balance
    */
    function getContractTokensBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
   
    
    /**
    * @dev - four functions below are for owner to 
    * deposit/withdraw eth/tokens to exchange contract
    */
    function withdraw(address payable sendTo, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "unsufficient funds");
        bool success = false;
        // ** sendTo.transfer(amount);** 
        (success, ) = sendTo.call.value(amount)("");
        require(success, "Transfer failed.");
        // ** end **
        emit Withdrawn(amount, sendTo); //wei
    }
  
    
    function deposit(uint256 amount) payable external onlyOwner { //amount in finney
        require(amount*(1 finney) == msg.value,"please provide value in finney");
        emit FinneyDeposited(amount, owner); //in finney
    }

    function depositTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "You need to deposit at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        
        emit TokensDeposited(amount.div(adj_constant), owner);
    }
    
  
    function withdrawTokens(address to_wallet, uint256 amount_tokens) external onlyOwner{
        require(amount_tokens > 0, "You need to withdraw at least some tokens");
        uint256 realAmountTokens = amount_tokens.mul(adj_constant);
        uint256 contractTokenBalance = token.balanceOf(address(this));
        
        require(contractTokenBalance > realAmountTokens, "unsufficient funds");
      
       
        
        //ensure we revert in case of failure 
        try token.transfer(to_wallet, realAmountTokens) { 
            //just continue if all good..
        } catch {
            require(false,"tokens transfer failed");
           
        }
        
    
        // all done..
        emit TokensWithdrawn(amount_tokens, to_wallet);
    }
    
    
    /**
    * @dev service function to check tokens on wallet and allowance of wallet
    */
    function walletTokenBalance(address wallet) external view returns(uint256){
        return token.balanceOf(wallet);
    }
    
    /**
    * @dev service function to check allowance of wallet for tokens
    */
    function walletTokenAllowance(address wallet) external view returns (uint256){
        return  token.allowance(wallet, address(this)); 
    }
    
    
    /**
    * @dev not bullet-proof check, but additional measure, not to allow buy & sell from contracts
    */
    function isContract(address _addr) internal view returns (bool){
      uint32 size;
      assembly {
          size := extcodesize(_addr)
      }
      
      return (size > 0);
    }
    
    modifier notContract(){
      require(
          (!isContract(msg.sender)),
          "external contracts are not allowed"
          );
          _;
    }
}