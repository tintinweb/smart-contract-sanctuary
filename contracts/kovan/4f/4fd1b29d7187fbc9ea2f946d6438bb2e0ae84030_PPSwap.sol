/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

pragma solidity ^0.5.17;


// ERC Token Standard #20 Interface

contract ERC20Interface { // five  functions and four implicit getters
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint rawAmt) public returns (bool success);
    function approve(address spender, uint rawAmt) public returns (bool success);
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint rawAmt);
    event Approval(address indexed tokenOwner, address indexed spender, uint rawAmt);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    } 
        
    function safeMul(uint a, uint b) internal pure returns (uint c) { 
        c = a * b; 
        require(a == 0 || c / a == b); 
    } 
        
    function safeDiv(uint a, uint b) internal pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}

contract PPSwap is ERC20Interface, SafeMath{
    string public constant name = "PPSwapTesting1";
    string public constant symbol = "PPS";
    uint8 public constant decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint public constant _totalSupply = 1*10**9*10**18; // one billion 
    uint public lastOfferID = 0; // the genesis orderID
    uint public ppsPrice = 5000*100;  // how many PPS can we buy with 1eth
    address payable trustAccount;
    address contractOwner;

    mapping(uint => mapping(string => address)) offers; // orderID, key, value
    mapping(uint => address payable) offerMakers;
    mapping(uint => mapping(string => uint)) offerAmts; // orderID, key, value
    mapping(uint => int8) offerStatus; // 1: created; 2= filled; 3=cancelled.

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
    
    event MakeOffer(uint indexed offerID, address indexed accountA, address indexed tokenA,  uint price, uint maxbuy);
    event CancelOffer(uint indexed offerId, address indexed accountA);
    event AcceptOffer(uint indexed offerID, address indexed accountA, address indexed accountB, uint amt);
    event BuyPPS(uint ETHAmt, uint PPSAmt);
    event SellPPS(uint PPSAmt, uint ETHAmt);
    event RenounceOwnership(address oldOwner, address newOwner);
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(address payable trustAcc) public { 
        contractOwner = msg.sender;
        trustAccount = trustAcc;
        balances[trustAccount] = _totalSupply; // The trustAccount has all PPS initially 
        emit Transfer(address(0), trustAccount, _totalSupply);
    }
    
    modifier onlyContractOwner(){
       require(msg.sender == contractOwner, "only the contract owner can call this function. ");
       _;
    }
    
    
    function renounceCwnership()
    onlyContractOwner()
    public 
    {
        address oldOwner = contractOwner;
        contractOwner = address(this);
        emit RenounceOwnership(oldOwner, address(this));
    
    }


    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

  
    
    // The contract does not accept ETH
    function () external payable  {
        revert();
    }  

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];

    }
    
            

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // called by the owner
    function approve(address spender, uint rawAmt) public returns (bool success) {
        
        allowed[msg.sender][spender] = rawAmt;
        emit Approval(msg.sender, spender, rawAmt);
        return true;
    }

    function transfer(address to, uint rawAmt) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(msg.sender, to, rawAmt);
        return true;
    }

    
    // ERC the allowence function should be more specic +-
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], rawAmt); // this will ensure the spender indeed has the authorization
        balances[from] = safeSub(balances[from], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(from, to, rawAmt);
        return true;
    }    
    
    
    
 
    function setPPSPrice(uint newPPSPrice)     
    onlyContractOwner()
    public returns (bool success){
        ppsPrice = newPPSPrice;
        
        return true;
    }
    
 function PPSPrice() 
    public
    view
    returns (uint PPSAmt)
    {
          
        return ppsPrice;
    }
       
    
    /* to be called by Bob, the offer maker */
    function makeOffer(address tokenA,
                       uint price,
                       uint maxbuy 
                       )
                       external 
                       returns(uint)
                       {
         lastOfferID = lastOfferID + 1;
         offerMakers[lastOfferID] =  msg.sender;
         offers[lastOfferID]['tokenA'] = tokenA;
         offerAmts[lastOfferID]['price'] = price;
         offerAmts[lastOfferID]['maxbuy'] = maxbuy;

         offerStatus[lastOfferID] = 1; // order created
         emit MakeOffer(lastOfferID, msg.sender, tokenA,  price, maxbuy);
         
         return lastOfferID;
    }

    function cancelOffer(uint offerID)
             external returns(bool)
    {
        require(offers[offerID]['accountA'] == msg.sender, "Ony the offer maker can cancel this offer.");
        
        offerStatus[offerID] = 3;
        emit CancelOffer(offerID, msg.sender);
        return true;
    }
             

    function getOffer(uint offerID, string memory key)
    public view returns (address)
    {
         return offers[offerID][key];
    }
    
    function getOfferAmt(uint offerID, string memory key)
    public view returns (uint)
    {
        return offerAmts[offerID][key];
    }

    function getOfferStatus(uint offerID)
    public view returns (int8)
    {
        return offerStatus[offerID];
    }
     
    /* to be called by Kathy, the offer acceptor */
    function acceptOffer(uint offerID)
                        external
                        payable 
                        returns(bool)
                        {
        require(offerStatus[offerID] == 1, 'This order has been either canceled.');
        
                            

        address payable accountA =  offerMakers[offerID];
        address  accountB = msg.sender;
        address tokenA = getOffer(offerID, 'tokenA');
    
        uint maxbuy = getOfferAmt(offerID, 'maxbuy');
        uint price = getOfferAmt(offerID, 'price');
        uint buyAmt = safeDiv(safeMul(price, msg.value), 10**18); /* the price tokens/weth */
        require(buyAmt <= maxbuy, "The amount you buy exceeds the buy limit.");
        
        ERC20Interface A = ERC20Interface(tokenA);
        /* transfer tokanA to accountB */
        require(A.balanceOf(accountA) >= buyAmt, "Not enough of tokenA balance in accontA.");
        require(A.allowance(accountA, address(this)) >= buyAmt, "Not enough alllowance of tokenA for this contract from accountA. ");
        A.transferFrom(accountA, accountB, buyAmt);

        /* transfer weth to the trust account and accountA */
        accountA.transfer(safeDiv(safeMul(msg.value, 95), 100));
        trustAccount.transfer(safeDiv(safeMul(msg.value, 5), 100)); // 5 perncent of sale tax 
        return true;
    }

    
    function buyPPS()
    public
    payable 
    returns (bool)
    {      
        require(msg.value <= 5*10**17, "Maximum buy: 0.5 eth. ");
     
        uint rawPPSAmt = ppsPrice*msg.value; 
        balances[address(this)] = safeSub(balances[address(this)], rawPPSAmt);
        balances[msg.sender] = safeAdd(balances[msg.sender], rawPPSAmt);
        
        emit Transfer(address(this), msg.sender, rawPPSAmt);
        emit BuyPPS(msg.value, rawPPSAmt);
        return true;
    }
    
    function sellPPS (uint amtPPS)
    public 
    returns(bool)
    {
        uint amtETH = safeDiv(amtPPS, ppsPrice);
        balances[msg.sender] =  safeSub(balances[msg.sender], amtPPS);
        balances[address(this)] = safeAdd(balances[address(this)], amtPPS);
        msg.sender.transfer(amtETH);
        emit Transfer(msg.sender, address(this), amtPPS);
        emit SellPPS(amtPPS, amtETH);
        return true;
    }

function withdrawPPS(uint amtPPS)
    onlyContractOwner()
    public returns (bool success){
        balances[address(this)] = safeSub(balances[address(this)], amtPPS);
        balances[trustAccount] = safeAdd(balances[trustAccount], amtPPS);
        emit Transfer(address(this), trustAccount, amtPPS);
        
        return true;
    }

function withdrawETH(uint amtETH)
    onlyContractOwner()
    public returns (bool success){
        trustAccount.transfer(amtETH);        
        return true;
    }    
}