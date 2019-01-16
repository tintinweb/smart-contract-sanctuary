pragma solidity ^0.4.25;


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


contract Ownable {
    
    address public owner;

    /**
     * The address whcih deploys this contrcat is automatically assgined ownership.
     * */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * Functions with this modifier can only be executed by the owner of the contract. 
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
    * Transfers ownership to new Ethereum address. This function can only be called by the 
    * owner.
    * @param _newOwner the address to be granted ownership.
    **/
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract ErcInterface {
    function transferFrom(address _from, address _to, uint256 _value) public;
    function transfer(address _to, uint256 _value) public;
    function balanceOf(address _who) public returns(uint256);
}


contract FoxtWidget is Ownable {
    
    using SafeMath for uint256;
    
    ErcInterface public constant FOXT = ErcInterface(0x1bd601De3eF243148F9441FC75Da12f796AB3823); 
    
    bool public contractFrozen;
    
    uint256 private rate;
    uint256 private purchaseTimeLimit;
    uint256 private txFee;

    mapping (address => uint256) private purchaseDeadlines;
    mapping (address => uint256) private maxPurchase;
    mapping (address => bool) private isBotAddress;
    
    
    address[] private botsOwedTxFees;
    uint256 private indexOfOwedTxFees;
    
    event TokensPurchased(address indexed by, address indexed recipient, uint256 total, uint256 value);
    event RateUpdated(uint256 latestRate);
    
    constructor() public {
        purchaseTimeLimit = 30 minutes;
        txFee = 23e14; //same as 0.0023 ETH.
        contractFrozen = false;
        indexOfOwedTxFees = 0;
    }
    
    
    function toggleFreeze() public onlyOwner {
        contractFrozen = !contractFrozen;
    }
    
    
    function addBotAddress(address _botAddress) public onlyOwner returns(bool) {
        require(!isBotAddress[_botAddress]);
        isBotAddress[_botAddress] = true;
        return true;
    }
    
    
    function removeBotAddress(address _botAddress) public onlyOwner returns(bool) {
        require(isBotAddress[_botAddress]);
        isBotAddress[_botAddress] = false;
        return true;
    }
    
    
    /**
     * Allows the owner to change the time limit which buyers will have once they
     * have been permitted to buy tokens with the contract update. 
     * 
     * @param _newPurchaseTimeLimit The new time limit which buyers will have to 
     * make a purchase. 
     * 
     * @return true if the function exeutes successfully, false otherwise
     * */
    function changeTimeLimitMinutes(uint256 _newPurchaseTimeLimit) public onlyOwner returns(bool) {
        require(_newPurchaseTimeLimit > 0 && _newPurchaseTimeLimit != purchaseTimeLimit);
        purchaseTimeLimit = _newPurchaseTimeLimit;
        return true;
    }
    
    
    /**
     * Allows the owner to change the fixed transaction fee which will be charged 
     * to the buyers. 
     * 
     * @param _newTxFee The new transaction fee which will be charged to the buyers. 
     * 
     * @return true if the function exeutes successfully, false otherwise
     * */
    function changeTxFee(uint256 _newTxFee) public onlyOwner returns(bool) {
        require(_newTxFee != txFee);
        txFee = _newTxFee;
        return true;
    }
    
    
    /**
     * Functions with this modifier can only be invoked by either one of the bot  
     * addresses or the owner of the contract. 
     * */
    modifier restricted {
        require(isBotAddress[msg.sender] || msg.sender == owner);
        _;
    }
    
    
    /**
     * Allows the bot or the owner of the contract to update the contract (will 
     * usuall by invoked right before a buyer will make a purchase). 
     * 
     * @param _rate The rate at which the FOXT tokens are shwon on Coin Market Cap.
     * @param _purchaser The address of the buyer.
     * @param _ethInvestment The total amoun of ETH the buyer has specified he 
     * or she will send to the contract. 
     * 
     * @return true if the function exeutes successfully, false otherwise
     * */
    function updateContract(uint256 _rate, address _purchaser, uint256 _ethInvestment) public restricted returns(bool){
        require(!contractFrozen);
        require(_purchaser != address(0x0));
        require(_ethInvestment > 0);
        require(_rate != 0);
        if(_rate != rate) {
            rate = _rate;
        }
        maxPurchase[_purchaser] = _ethInvestment;
        purchaseDeadlines[_purchaser] = now.add(purchaseTimeLimit);
        botsOwedTxFees.push(msg.sender);
        emit RateUpdated(rate);
        return true;
    }
    
    
    /**
     * @return The current rate shown on Coin Market Cap. 
     * */
    function getRate() public view returns(uint256) {
        return rate;
    }
    
    
    /**
     * Checks if a purchaser is permitted to make a purchase by checking 
     * the following conditions. 1st condition is that the bot updated the contract 
     * with the purcahser&#39;s address no longer than the purchase deadline ago. 2nd 
     * condition is that the purchaser is allowed to make an investment which is 
     * greater than 0. 
     * 
     * @return true if the purchaser is permitted to make a purchase, false 
     * otherwise.
     * */
    function addrCanPurchase(address _purchaser) public view returns(bool) {
        return now < purchaseDeadlines[_purchaser] && maxPurchase[_purchaser] > 0;
    }
    

    /**
     * Allows users to buy FOXT tokens. For the function to execute successfully
     * the following conditions must be met: 1st the purchaser must purcahse the 
     * tokens before the time limit is up (time limit is set when the bot updates
     * the contract). 2nd the purchaser must send at least enough ETH to cover the 
     * txFee to cover the cost of the update, however, if the purchaser sends more 
     * ETH than specified in the update, the purchaser will still get FOXT tokens 
     * but also the remaining ETH will be refunded. 
     * 
     * @param _purchaser The address of the buyer
     * 
     * @return true if the function exeutes successfully, false otherwise
     * */
    function buyTokens(address _purchaser) public payable returns(bool){
        require(!contractFrozen);
        require(addrCanPurchase(_purchaser));
        require(msg.value > txFee);
        uint256 msgVal = msg.value;
        if(msgVal > maxPurchase[_purchaser]) {
            msg.sender.transfer(msg.value.sub(maxPurchase[_purchaser]));
            msgVal = msgVal.sub(maxPurchase[_purchaser]);
        }
        maxPurchase[_purchaser] = 0;
        msgVal = msgVal.sub(txFee);
        botsOwedTxFees[indexOfOwedTxFees].transfer(txFee);
        indexOfOwedTxFees = indexOfOwedTxFees.add(1);
        uint256 toSend = msgVal.mul(rate);
        FOXT.transfer(_purchaser, toSend);
        emit TokensPurchased(msg.sender, _purchaser, toSend, msg.value);
    }
    
    
    /**
     * Fallback function invokes the buyTokens function. 
     * */
    function() public payable {
        buyTokens(msg.sender);
    }
    
    
    /**
     * Allows the owner of the contract to withdraw all ETH.
     * */
    function withdrawETH() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    
    /**
     * Allows the owner of the contract to withdraw FOXT tokens.
     * 
     * @param _recipient The address of the receiver.
     * @param _totalTokens The number of FOXT tokens to send. 
     * */
    function withdrawFoxt(address _recipient, uint256 _totalTokens) public onlyOwner {
        FOXT.transfer(_recipient, _totalTokens);
    }
    
    
    /**
     * Allows the owner of the contract to withdraw any ERC20 token.
     * 
     * @param _tokenAddr The contract address of the ERC20 token.
     * @param _recipient The address of the receiver.
     * @param _totalTokens The number of tokens to send
     * */
    function withdrawAnyERC20(address _tokenAddr, address _recipient, uint256 _totalTokens) public onlyOwner {
        ErcInterface token = ErcInterface(_tokenAddr);
        token.transfer(_recipient, _totalTokens);
    }
    
}