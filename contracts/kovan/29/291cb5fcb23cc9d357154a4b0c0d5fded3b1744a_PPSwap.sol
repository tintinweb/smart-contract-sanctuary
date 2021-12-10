/**
 *Submitted for verification at Etherscan.io on 2021-12-10
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
    string public constant name = "PPSwap";
    string public constant symbol = "PPS";
    uint8 public constant decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint public constant _totalSupply = 1*10**9*10**18; // one billion 
    uint public lastOfferID = 0; // the genesis orderID
    uint public ppsPrice = 5000*100;  // how many PPS can we buy with 1eth
    address payable trustAccount;
    address contractOwner;

    mapping(uint => mapping(string => address)) offers; // orderID, key, value
    mapping(uint => mapping(string => uint)) offerAmts; // orderID, key, value
    mapping(uint => int8) offerStatus; // 1: created; 2= filled; 3=cancelled.

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
    
    event MakeOffer(uint indexed offerID, address indexed accountA, address tokenA, address tokenB, uint amtA, uint amtB);
    event CancelOffer(uint indexed offerId, address indexed accountA);
    event AcceptOffer(uint indexed offerID, address indexed accountA, address indexed accountB);
    event TransferToAll(address indexed from, uint amt);
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
    

    /* 1. For a member that has 1M or more PPS, 0.0005 eth; 
     * 2. for a member that has less than PPS, 0.001 eth;
     */
 function getSwapfee(address account) 
    public 
    view
    returns (uint)
    {
        
        if(balances[account] >= 10000*10**18) return 0;
        
        if(balances[account] >=  1000*10**18) return 5*10**14; /* 0.0005 eth */
        else return 1*10**15; /* 0.001 eth */
    }
   
       
    
    /* to be called by Bob, the offer maker */
    function makeOffer(address tokenA, 
                       address tokenB, 
                       uint amtA, 
                       uint amtB)
                       external 
                       returns(uint)
                       {
         lastOfferID = lastOfferID + 1;
         offers[lastOfferID]['accountA'] = msg.sender;
         offers[lastOfferID]['tokenA'] = tokenA;
         offers[lastOfferID]['tokenB'] = tokenB;
         offerAmts[lastOfferID]['amtA'] = amtA;
         offerAmts[lastOfferID]['amtB'] = amtB;
         offerStatus[lastOfferID] = 1; // order created
         emit MakeOffer(lastOfferID, msg.sender, tokenA, tokenB, amtA, amtB);
         
         return lastOfferID;
    }

    function cancelOffer(uint offerID)
             external returns(bool)
    {
        require(offerStatus[offerID] == 1, "This offer has already been filled or canceled.");
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
        require(offerStatus[offerID] == 1, 'This order has been either canceled or filled.');
        
                            

        address accountA = getOffer(offerID, 'accountA');
        address accountB = msg.sender;
        address tokenA = getOffer(offerID, 'tokenA');
        address tokenB = getOffer(offerID, 'tokenB');
        uint amtA = getOfferAmt(offerID, 'amtA');
        uint amtB = getOfferAmt(offerID, 'amtB');
        
        offers[offerID]['accountB'] = accountB;
        uint swapfee = getSwapfee(msg.sender);

        
  
        if(swapfee > 0 ){ // Pay the swap fee by eth to the trust account 
              require(msg.value >= swapfee, "Not enough swap fee is paid.");
              trustAccount.transfer(msg.value);
        }
        
        acceptOfferImp(accountA, accountB, tokenA, tokenB, amtA, amtB);
        emit AcceptOffer(offerID, accountA, accountB);
        
        offerStatus[offerID] =  2;


        return true;
    }
        
    /* This function can only be called by this contract */
    function acceptOfferImp(address accountA, 
                        address accountB, 
                        address tokenA, 
                        address tokenB, 
                        uint amtA, 
                        uint amtB) 
                        private
                        returns(bool){
        ERC20Interface A = ERC20Interface(tokenA);
        ERC20Interface B = ERC20Interface(tokenB);

        require(A.balanceOf(accountA) >= amtA, "Not enough of tokenA balance in accontA.");
        require(A.allowance(accountA, address(this)) >= amtA, "Not enough alllowance of tokenA for this contract from accountA. ");
        A.transferFrom(accountA, accountB, amtA);

        require(B.balanceOf(accountB) >= amtB, "Not enough of tokenB balance in accontB.");
        require(B.allowance(accountB, address(this)) >= amtB, "Not enough alllowance of tokenB for this contract from accountB. ");
        B.transferFrom(accountB, accountA, amtB);
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