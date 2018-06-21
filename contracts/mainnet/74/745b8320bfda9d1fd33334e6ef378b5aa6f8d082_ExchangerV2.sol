pragma solidity ^0.4.18;
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

/* A basic permissions hierarchy (Owner -> Admin -> Everyone else). One owner may appoint and remove any number of admins
   and may transfer ownership to another individual address */
contract Administered {
    address public creator;

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

contract ExchangerV2 is Administered, tokenRecipient {
    bool public enabled = false;    //Owner can turn off and on

    //The token which is being bought and sold
    ITradeableAsset public tokenContract;
    //The contract that does the calculations to determine buy and sell pricing
    IYeekFormula public formulaContract;
    //The reserve pct of this exchanger, expressed in ppm
    uint32 public weight;
    //The fee, in ppm
    uint32 public fee=5000; //0.5%
    //issuedSupplyRatio - for use in early offerings where a majority of the tokens have not yet been issued.
    //The issued supply is calculated as: token.totalSupply / issuedSupplyRatio
    //Example: you have minuted 2mil tokens, sold / gave away 40k in an ICO, and 10k are stored here as a liqudity reserve
    //Since only 50k total coins have been issued, the issuedSupplyRatio should be set to 40 (2mil / 40 = 50k)
    uint32 public issuedSupplyRatio=1;
    //Accounting for the fees
    uint256 public collectedFees=0;
    //If part of the ether reserve is stored offsite for security reasons this variable holds that value
    uint256 public virtualReserveBalance=0;

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
     @dev Withdraw accumulated fees, without disturbing the core reserve
     */
    function extractFees(uint amountInWei) onlyAdmin public {
        require (amountInWei <= collectedFees);
        msg.sender.transfer(amountInWei);
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
      It is highly disrecommended to do this while trading is enabled! Obviously this should 
      only be done in combination with a matching deposit or withdrawal of ether, 
      and I&#39;ll enforce it at a later point.
     */
    function setReserveWeight(uint ppm) onlyAdmin public {
        require (ppm>0 && ppm<=1000000);
        weight = uint32(ppm);
    }

    function setFee(uint ppm) onlyAdmin public {
        require (ppm >= 0 && ppm <= 1000000);
        fee = uint32(ppm);
    }

    function setissuedSupplyRatio(uint newValue) onlyAdmin public {
        require (newValue > 0);
        issuedSupplyRatio = uint32(newValue);
    }

    /**
     * The virtual reserve balance set here is added on to the actual ethereum balance of this contract
     * when calculating price for buy/sell. Note that if you have no real ether in the reserve, you will 
     * not have liquidity for sells until you have some buys first.
     */
    function setVirtualReserveBalance(uint256 amountInWei) onlyAdmin public {
        virtualReserveBalance = amountInWei;
    }

    //These methods return information about the exchanger, and the buy / sell rates offered on the Token / ETH pairing.
    //They can be called without gas from any client.

    /**  
     @dev Audit the reserve balances, in the base token and in ether
     returns: [token balance, ether balance - ledger]
     */
    function getReserveBalances() public view returns (uint256, uint256) {
        return (tokenContract.balanceOf(this), address(this).balance+virtualReserveBalance);
    }


    /**
     @dev Gets price based on a sample 1 ether BUY order
     */
     /*
    function getQuotePrice() public view returns(uint) {
        uint tokensPerEther = 
        formulaContract.calculatePurchaseReturn(
            (tokenContract.totalSupply() - tokenContract.balanceOf(this)) * issuedSupplyRatio,
            address(this).balance,
            weight,
            1 ether 
        ); 

        return tokensPerEther;
    }*/

    /**
     @dev Get the BUY price based on the order size. Returned as the number of tokens that the amountInWei will buy.
     */
    function getPurchasePrice(uint256 amountInWei) public view returns(uint) {
        uint256 purchaseReturn = formulaContract.calculatePurchaseReturn(
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
            address(this).balance + virtualReserveBalance,
            weight,
            amountInWei 
        ); 

        purchaseReturn = (purchaseReturn - ((purchaseReturn * fee) / 1000000));

        if (purchaseReturn > tokenContract.balanceOf(this)){
            return tokenContract.balanceOf(this);
        }
        return purchaseReturn;
    }

    /**
     @dev Get the SELL price based on the order size. Returned as amount (in wei) that you&#39;ll get for your tokens.
     */
    function getSalePrice(uint256 tokensToSell) public view returns(uint) {
        uint256 saleReturn = formulaContract.calculateSaleReturn(
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
            address(this).balance + virtualReserveBalance,
            weight,
            tokensToSell 
        ); 
        saleReturn = (saleReturn - ((saleReturn * fee) / 1000000));
        if (saleReturn > address(this).balance) {
            return address(this).balance;
        }
        return saleReturn;
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
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
            (address(this).balance + virtualReserveBalance) - msg.value,
            weight,
            msg.value);
        amount = (amount - ((amount * fee) / 1000000));
        
        //Now do the trade if conditions are met
        require (enabled); // ADDED SEMICOLON    
        require (amount >= minPurchaseReturn);
        require (tokenContract.balanceOf(this) >= amount);
        
        //Accounting - so we can pull the fees out without changing the balance
        collectedFees += (msg.value * fee) / 1000000;

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
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
             address(this).balance + virtualReserveBalance,
             weight,
             quantity
        );
        amountInWei = (amountInWei - ((amountInWei * fee) / 1000000));

        require (enabled); // ADDED SEMICOLON
        require (amountInWei >= minSaleReturn);
        require (amountInWei <= address(this).balance);
        require (tokenContract.transferFrom(msg.sender, this, quantity));

        collectedFees += (amountInWei * fee) / 1000000;

        emit Sell(msg.sender, quantity, amountInWei);
        msg.sender.transfer(amountInWei); //Always send ether last
    }


    //approveAndCall flow for selling entry point
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external {
        //not needed: if it was the wrong token, the tx fails anyways require(_token == address(tokenContract));
        sellOneStep(_value, 0, _from);
    }
    

    //Variant of sell for one step ordering. The seller calls approveAndCall on the token
    //which calls receiveApproval above, which calls this funciton
    function sellOneStep(uint quantity, uint minSaleReturn, address seller) public {
        uint amountInWei = formulaContract.calculateSaleReturn(
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
             address(this).balance + virtualReserveBalance,
             weight,
             quantity
        );
        amountInWei = (amountInWei - ((amountInWei * fee) / 1000000));
        
        require (enabled); // ADDED SEMICOLON
        require (amountInWei >= minSaleReturn);
        require (amountInWei <= address(this).balance);
        require (tokenContract.transferFrom(seller, this, quantity));

        collectedFees += (amountInWei * fee) / 1000000;


        emit Sell(seller, quantity, amountInWei);
        seller.transfer(amountInWei); //Always send ether last
    }

}