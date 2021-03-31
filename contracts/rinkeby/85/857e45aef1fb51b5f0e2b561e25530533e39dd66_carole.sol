/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//*****************************************************************************//
//                        Coin Name : CAROLE                                   //
//                           Symbol : CAROLE                                   //
//                     Total Supply : 1,000,000                                //
//                         Decimals : 18                                       //
//                    Functionality : Burn, Mint                               //
//          change oracle address for eth/usd/gold & token details             //
//*****************************************************************************//

 /**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    if (a == 0){
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b,"Calculation error");
    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256){
    // Solidity only automatically asserts when dividing by 0
    require(b > 0,"Calculation error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256){
    require(b <= a,"Calculation error");
    uint256 c = a - b;
    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a + b;
    require(c >= a,"Calculation error");
    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256){
    require(b != 0,"Calculation error");
    return a % b;
  }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  
  function latestAnswer() external view returns (int256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function isOwner() public view returns (bool) {
      return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @title Carole Contract For ERC20 Tokens
* @dev Carole tokens as per ERC20 Standards
*/
contract carole is IERC20, Ownable {

  using SafeMath for uint256;
  
 //0x23F73885630B4934FaaB6578074b372656a11776
 // Network: Rinkeby
 // Aggregator: ETH/USD
 // Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
 // Mainnet Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
  AggregatorV3Interface internal priceFeedETH;
  
 // Network: Rinkeby
 // Aggregator: XAU/USD
 // Address: 0x81570059A0cb83888f1459Ec66Aad1Ac16730243
 // Mainnet Address: 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6
  AggregatorV3Interface internal priceFeedXAU;
  
  
  string  private _name;                          // Name of the token.
  string  private _symbol;                        // symbol of the token.
  uint8   private _decimals;                      // variable to maintain decimal precision of the token.
  uint256 private _totalSupply;                   // total supply of token.
  uint256 private _transactionFees = 2;           // transaction fees set by admin fo buying
  uint256 public airdropcount = 0;                // Variable to keep track on number of airdrop
    

  
  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;
  



  event BuyTokens(address indexed buyer, uint256 value, uint256 tokenPrice, uint256 paidEther, uint256 timestamp);
  
  event SellTokens(address indexed seller, uint256 value, uint256 tokenPrice, uint256 paidEther, uint256 timestamp);


//   constructor (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, uint256 tokenTotalSupply) {
//     _name = tokenName;
//     _symbol = tokenSymbol;
//     _decimals = tokenDecimals;
//     _totalSupply = tokenTotalSupply*(10**uint256(tokenDecimals));
//     _balances[msg.sender] = _totalSupply;
//     priceFeedETH = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
//     priceFeedXAU = AggregatorV3Interface(0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6);
//   }

  constructor () {
    _name = 'CAROLE';
    _symbol = 'CRL';
    _decimals = 18;
    _totalSupply = 100000*(10**uint256(18));
    _balances[msg.sender] = _totalSupply;
    priceFeedETH = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    priceFeedXAU = AggregatorV3Interface(0x81570059A0cb83888f1459Ec66Aad1Ac16730243);
    
  }
 

  /*
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   * View only functions
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   */
  
  /**
    * @return the name of the token.
    */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
    * @return the symbol of the token.
    */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
    * @return the number of decimals of the token.
    */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
    * @dev Total number of tokens in existence.
    */
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
  function balanceOf(address owner) public view override returns (uint256) {
    return _balances[owner];
  }

  /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowed[owner][spender];
  }

  /*
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   * Transfer, allow, mint and burn functions
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   */

  /*
   * @dev Transfer token to a specified address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) public override returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
    * @dev Transfer tokens from one address to another.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /**
    * @dev Transfer token for a specified addresses.
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
  */
   function _transfer(address from, address to, uint256 value) internal {
    //require(from != address(0),"Invalid from Address");
    require(to != address(0),"Invalid to Address");
    require(value > 0, "Invalid Amount");
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public override returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Approve an address to spend another addresses' tokens.
   * @param owner The address that owns the tokens.
   * @param spender The address that will spend the tokens.
   * @param value The number of tokens that can be spent.
   */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0),"Invalid address");
    require(owner != address(0),"Invalid address");
    require(value > 0, "Invalid Amount");
    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }
    
  /**
    * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
    * @param _addresses array of address in serial order
    * @param _amount amount in serial order with respect to address array
    */
  function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
    require(_addresses.length == _amount.length,"Invalid Array");
    uint256 count = _addresses.length;
    for (uint256 i = 0; i < count; i++){
      _transfer(msg.sender, _addresses[i], _amount[i]);
      airdropcount = airdropcount + 1;
      }
    return true;
   }

  /**
   * @dev Internal function that burns an amount of the token of a given account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0),"Invalid account");
    require(value > 0, "Invalid Amount");
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public onlyOwner {
    _burn(msg.sender, _value);
  }

  /**
    * Function to mint tokens
    * @param _value The amount of tokens to mint.
    */
  function mint(uint256 _value) public onlyOwner returns(bool){
    require(_value > 0,"The amount should be greater than 0");
    _mint(_value,msg.sender);
    return true;
  }

  function _mint(uint256 _value,address _tokenOwner) internal returns(bool){
    _balances[_tokenOwner] = _balances[_tokenOwner].add(_value);
    _totalSupply = _totalSupply.add(_value);
    emit Transfer(address(0), _tokenOwner, _value);
    return true;
  }
  
  
  /////////////////////////////////////////////////////////////
  //                            fees                         //
  /////////////////////////////////////////////////////////////
  
  
  /**
   * @dev Function for setting transaction fees by owner
   * @param transactionFees for transaction fees
   */
  function setTransactionFees(uint256 transactionFees) public onlyOwner returns(bool){
    require(transactionFees > 0, "Invalid fees");
    _transactionFees = transactionFees;
    return true;
  }

  /**
   * @dev Function for getting transaction fees set by owner
   */
  function getTransactionFees() public view returns(uint256){
    return _transactionFees;
  }
  
  
  
  
  /////////////////////////////////////////////////////////////
  //                    Oracle to get prices                 //
  /////////////////////////////////////////////////////////////
  
  


    
    /**
     * Returns the latest price for eth / usd
     */
    function getLatestPriceETH() public view returns (int) {
        (
            int price
        ) = priceFeedETH.latestAnswer();
        return price;
    }

    
    /**
     * Returns the latest price for xau / usd
     */
    function getLatestPriceGold() public view returns (int) {
        (
            int price
        ) = priceFeedXAU.latestAnswer();
        return price;
    }
    
    /**
     * get token price
     */
     function getTokenPrice() public view returns (uint256){
         int ethusd = getLatestPriceETH();
         int xauusd = getLatestPriceGold();
         uint256 tokenPrice = (uint256(xauusd).mul(10**uint256(_decimals))/(uint256(ethusd).mul(2835).div(100)));
         return tokenPrice;
     }
     
     /**
     * get total ethers to be paid for entered amount of tokens
     */
     function calculateEthToBePaid(uint256 tokenAmount) public view returns (uint256){
         uint256 tokenPrice = getTokenPrice();
         return (tokenAmount.mul(tokenPrice).mul(100).div((10**_decimals).mul(98)));
     }
     
     /**
     * get total tokens which will be sent to you for the entered amount of ethers
     */
     function calculateTokenToBeRecieved(uint256 etherAmount) public view returns (uint256){
         uint256 tokenPrice = getTokenPrice();
         return (etherAmount.mul(10**_decimals).mul(98)).div(tokenPrice * 100);
     }
     
    
    ///////////////////////////////////////////////////
    //                      Invest                   //
    ///////////////////////////////////////////////////
    
    /**
     * buy tokens by sending ethers value
     */
    function buy() public payable returns(bool){
        require(msg.value>0, "0 ethers sent, send funds");
        uint256 paidEther = msg.value;
        uint256 fees = (msg.value).mul(_transactionFees).div(100);
        address payable _owner = payable(owner());
        _owner.transfer(fees);
        uint256 tokenPrice = getTokenPrice();
        uint256 tokens = (paidEther-fees).mul(10**_decimals)/tokenPrice;
        if(_balances[_owner]<tokens){
            _mint(tokens, msg.sender);
        } else {
            _transfer(_owner, msg.sender, tokens);
        }

        emit BuyTokens(msg.sender, tokens, tokenPrice, paidEther, block.timestamp);
        return true;
    }
    
    
    /**
     * sell token by sending the storage fees
     */
    function sell(uint256 token) public payable returns(bool){
        require(_balances[msg.sender] >= token, "balance of token less than selling amount");
        // uint256 tokenValue = token;
        require(address(this).balance >= token*getTokenPrice()/(10**18), "Insufficient eth in contract");
        // address payable buyer = payable(msg.sender);
        payable(msg.sender).transfer(token*getTokenPrice()/(10 ** 18));
        transferFrom(msg.sender, owner(), token);
        emit SellTokens(msg.sender, token, getTokenPrice(), msg.value, block.timestamp);
        return true;
    }

    function buySellP2P(address from) public payable returns(bool){
        require(msg.value>0, "0 ethers sent, send funds");
        uint256 paidEther = msg.value;
        uint256 tokenPrice = getTokenPrice();
        uint256 fees = (msg.value).mul(_transactionFees).div(100);
        address payable _owner = payable(owner());
        _owner.transfer(fees.div(2));
        payable(from).transfer(fees.div(2));
        uint256 tokens = (paidEther-fees).mul(10**_decimals)/tokenPrice;
        require(_balances[from] >= tokens, "seller has insufficient amount of tokens to sell");
        transferFrom(from, msg.sender, tokens);
        emit BuyTokens(msg.sender, tokens, tokenPrice, paidEther, block.timestamp);
        return true;
    }    


  /**
   * Get ETH balance from this contract
   */
  function getContractETHBalance() public view returns(uint256){
    return(address(this).balance);
  }

  /**
   * @dev Function to withdraw Funds by owner only
   */
  function withdrawETH() external onlyOwner returns(bool){
    payable(msg.sender).transfer(address(this).balance);
    return true;
  }

}