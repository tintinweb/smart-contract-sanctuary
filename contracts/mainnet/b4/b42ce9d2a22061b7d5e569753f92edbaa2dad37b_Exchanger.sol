interface IYeekFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) external view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) external view returns (uint256);
}

interface ITradeableAsset {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function decimals() external view returns (uint256);
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address _address) external view returns (uint256);
}

/* A basic permissions hierarchy (Owner -> Admin -> Everyone else). One owner may appoint and remove any number of admins
   and may transfer ownership to another individual address */
contract Administered {
    address public creator;
    uint public commission = 1;
    mapping (address => bool) public admins;
    
    constructor()  public {
        creator = msg.sender;
        admins[creator] = true;
    }

    //Restrict to the current owner. There may be only 1 owner at a time, but 
    //ownership can be transferred.
    modifier onlyOwner {
        require(creator == msg.sender);
        _;
    }
    
    //Restrict to any admin. Not sufficient for highly sensitive methods
    //since basic admin can be granted programatically regardless of msg.sender
    modifier onlyAdmin {
        require(admins[msg.sender] || creator == msg.sender);
        _;
    }

    //Add an admin with basic privileges. Can be done by any superuser (or the owner)
    function grantAdmin(address newAdmin) onlyOwner  public {
        _grantAdmin(newAdmin);
    }

    function _grantAdmin(address newAdmin) internal
    {
        admins[newAdmin] = true;
    }

    //Transfer ownership
    function changeOwner(address newOwner) onlyOwner public {
        creator = newOwner;
    }

    //Remove an admin
    function revokeAdminStatus(address user) onlyOwner public {
        admins[user] = false;
    }
}

/* A liqudity pool that executes buy and sell orders for an ETH / Token Pair */
/* The owner deploys it and then adds tokens / ethereum in the desired ratio */

contract Exchanger is Administered {
    bool public enabled = false;    //Owner can turn off and on

    //The token which is being bought and sold
    ITradeableAsset public tokenContract;
    //The contract that does the calculations to determine buy and sell pricing
    IYeekFormula public formulaContract;
    //The reserve pct of this exchanger, expressed in ppm
    uint32 public weight;

    /** 
        @dev Deploys an exchanger contract for a given token / Ether pairing
        @param _token An ERC20 token
        @param _weight The reserve fraction of this exchanger, in ppm
        @param _formulaContract The contract with the algorithms to calculate price
     */

    constructor(address _token, 
                uint32 _weight,
                address _formulaContract) {
        require (_weight > 0 && weight <= 1000000);
        
        weight = _weight;
        tokenContract = ITradeableAsset(_token);
        formulaContract = IYeekFormula(_formulaContract);
    }

    //Events raised on completion of buy and sell orders. 
    //The web client can use this info to provide users with their trading history for a given token
    //and also to notify when a trade has completed.

    event Buy(address indexed purchaser, uint256 amountInWei, uint256 amountInToken);
    event Sell(address indexed seller, uint256 amountInToken, uint256 amountInWei);


    // The following methods are for the owner and admins to manage the Exchanger
    
    /**
     @dev Deposit tokens to the reserve.
     */
    function depositTokens(uint amount) onlyOwner public {
        tokenContract.transferFrom(msg.sender, this, amount);
    }
        
    /**
     @dev Deposit ether to the reserve
     */
     function depositEther() onlyOwner public payable {
        //return getQuotePrice(); 
     }

    /**  
     @dev Withdraw tokens from the reserve
     */
    function withdrawTokens(uint amount) onlyOwner public {
        tokenContract.transfer(msg.sender, amount);
    }

    /**  
     @dev Withdraw ether from the reserve
     */
    function withdrawEther(uint amountInWei) onlyOwner public {
        msg.sender.transfer(amountInWei); //Transfers in wei
    }

    /**
     @dev Enable trading
     */
     function enable() onlyAdmin public {
         enabled = true;
     }

     /**
      @dev Disable trading
     */
     function disable() onlyAdmin public {
         enabled = false;
     }

     /**
      @dev Play central banker and set the fractional reserve ratio, from 1 to 1000000 ppm.
      It is highly disrecommended to do this while trading is enabled! If you don&#39;t know what 
      a fractional reserve is, please put this contract away and go work for your local government.
     */
     function setReserveWeight(uint32 ppm) onlyAdmin public {
         require (ppm>0 && ppm<=1000000);
         weight = ppm;
     }

    //These methods return information about the exchanger, and the buy / sell rates offered on the Token / ETH pairing.
    //They can be called without gas from any client.

    /**  
     @dev Audit the reserve balances, in the base token and in ether
     */
    function getReserveBalances() public view returns (uint256, uint256) {
        return (tokenContract.balanceOf(this), address(this).balance);
    }


    /**
     @dev Gets price based on a sample 1 ether BUY order
     */
    function getQuotePrice() public view returns(uint) {
        uint tokensPerEther = 
        formulaContract.calculatePurchaseReturn(
            tokenContract.totalSupply(),
            address(this).balance,
            weight,
            1 ether 
        ); 

        return tokensPerEther;
    }

    /**
     @dev Get the BUY price based on the order size. Returned as the number of tokens that the amountInWei will buy.
     */
    function getPurchasePrice(uint256 amountInWei) public view returns(uint) {
        uint tokensPerEther =  formulaContract.calculatePurchaseReturn(
            tokenContract.totalSupply(),
            address(this).balance,
            weight,
            amountInWei 
        ); 
        
        return tokensPerEther - (tokensPerEther * commission / 100);
    }

    /**
     @dev Get the SELL price based on the order size. Returned as amount (in wei) that you&#39;ll get for your tokens.
     */
    function getSalePrice(uint256 tokensToSell) public view returns(uint) {
        uint weiRaw= formulaContract.calculateSaleReturn(
            tokenContract.totalSupply(),
            address(this).balance,
            weight,
            tokensToSell 
        ); 
        
        return weiRaw - (weiRaw * commission / 100);
    }

    //buy and sell execute live trades against the exchanger. For either method, 
    //you must specify your minimum return (in total tokens or ether that you expect to receive for your trade)
    //this protects the trader against slippage due to other orders that make it into earlier blocks after they 
    //place their order. 
    //
    //With buy, send the amount of ether you want to spend on the token - you&#39;ll get it back immediately if minPurchaseReturn
    //is not met or if this Exchanger is not in a condition to service your order (usually this happens when there is not a full 
    //reserve of tokens to satisfy the stated weight)
    //
    //With sell, first approve the exchanger to spend the number of tokens you want to sell
    //Then call sell with that number and your minSaleReturn. The token transfer will not happen 
    //if the minSaleReturn is not met.
    //
    //Sales always go through, as long as there is any ether in the reserve... but those dumping massive quantities of tokens
    //will naturally be given the shittest rates.

    /**
     @dev Buy tokens with ether. 
     @param minPurchaseReturn The minimum number of tokens you will accept.
     */
    function buy(uint minPurchaseReturn) public payable {
        uint amount = formulaContract.calculatePurchaseReturn(
            tokenContract.totalSupply(),
            address(this).balance - msg.value,
            weight,
            msg.value);
        require (enabled);
        require (amount >= minPurchaseReturn);
        require (tokenContract.balanceOf(this) >= amount);
        emit Buy(msg.sender, msg.value, amount);
        tokenContract.transfer(msg.sender, amount);
    }
    /**
     @dev Sell tokens for ether
     @param quantity Number of tokens to sell
     @param minSaleReturn Minimum amount of ether (in wei) you will accept for your tokens
     */
     function sell(uint quantity, uint minSaleReturn) public {
         uint amountInWei = formulaContract.calculateSaleReturn(
             tokenContract.totalSupply(),
             address(this).balance,
             weight,
             quantity
         );
         require (enabled);
         require (amountInWei >= minSaleReturn);
         require (amountInWei <= address(this).balance);
         require (tokenContract.transferFrom(msg.sender, this, quantity));
         emit Sell(msg.sender, quantity, amountInWei);
         msg.sender.transfer(amountInWei); //Always send ether last
     }
}