/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.5.17;

// -----------------------------------------------------------------------------------------------------------------------------------------------
// Pinnned:  all later annoucements might invalidate the earlier models and ideas. We keep all records so that the public
//           will know how the ideas and bussness model grow over time. 
// PPSwap020: 6/17/2021.  The swap fee can only be paid in PPS. For the first 10,000 users, there will be no swap fee. 
// PPSwap019: 6/16/2021.  For each swap, we will burn PPS in the amount of *rewards*, the same amount that is given to the offer maker. This is 
//                        the reward to all existing holders. 
// PPSwap018: 06/2/2021.  We will lock all PPS in the smart contract. The dev team will hold zero tokens. The only way to earn tokens is via swap
//                       which is around 10% of the total swap fee. 
// PPSwap017: 5/31/2021. For each swap, Bob will be rewarded PPS worhty of 10% of the swap fee, Kathy will not be rewarded as Bob as the market maker. 
//                       Kathy will pay the Swap fee either with in ETH or in PPS, but not both. A 10% discount will be applied
//                       if Kathy pays the swap fee with PPS.  
//                      
// PPSwap016: 5/28/2021. We will set the swap fee intially at $1 (0.0004ETH). We will make the swap fee as low as possible. 
// PPSwap015: 5/27/2021. Bob can cancel an offer before it is accepted. Bob cannot modify an existing offer, he can only 
//                       cancel it. An offer cannot be canceled after it has been accepted. After an offer is canceled, 
//                       the offer cannot be accepted anymore. 
// PPSwap014: 5/27/2021. Bob will make an offer with an orderID, the information of which will be stored in 
//                       the blockchain, and then Kathy will accept the offer with that orderID.
// PPSwap013: 5/26/2021. We will charge swap fees by ETH not by PPS. Both swap parties will be rewardsed with some PPS! The swap fees are 
//                       paid by Kathy not by Bob as Bob is a market maker. 
// PPSwap012: 5/15/2021: Only the contract owner or its delegate can call the safeSwap function. Only the delegate can set swapfeePerTrans, 
//            which is initally set to zero.  
// PPSwap011: 5/6/2021, the swap fee per transaction is defined by swapfeePerTrans.  
// PPSwap010: 5/6/2021, we combine PPSwap with PPS so that a user can buy PPS via sending ETH to the contract address.
//            We fixed the exchangeRate between PPS and ETH with the understanding that eventually the market will take over. 
// PPSwap009: 5/5/2021, now we can exchange two arbitrary ERC20 tokens. 
// ---------------------------------------------------------------------------
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
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    } 
        
    function safeMul(uint a, uint b) public pure returns (uint c) { 
        c = a * b; 
        require(a == 0 || c / a == b); 
    } 
        
    function safeDiv(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}

contract PPSwap is ERC20Interface, SafeMath{
    string public constant name = "PPSwap";
    string public constant symbol = "PPS";
    uint8 public constant decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint public constant _totalSupply = 1*10**12*10**18; // one trillion 
    uint public swapfeeInPPS = 0; // initially 0 
    uint public rewards = 20000000*10**18; // 10 M for the offer maker and 10M for burning.
    uint public lastOfferID = 1000000000; // the genesis orderID

    address public trustAccount; // where the PPS swap fee will be stored
    address  public contractOwner;
    address public contractOwnerDelegate;

    mapping(uint => mapping(string => address)) offers; // orderID, key, value
    mapping(uint => mapping(string => uint)) offerAmts; // orderID, key, value
    mapping(uint => int8) offerStatus; // 1: created; 2= filled; 3=cancelled.

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
    
    event MakeOffer(uint indexed offerID, address indexed accountA, address tokenA, address tokenB, uint amtA, uint amtB);
    event CancelOffer(uint indexed offerId, address indexed accountA);
    event AcceptOffer(uint indexed offerID, address indexed accountA, address indexed accountB);
    
  
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(address payable newTrustAccount) public { 
        trustAccount = newTrustAccount;
        contractOwner = msg.sender;
        contractOwnerDelegate = msg.sender; // default delegate
        balances[address(this)] = _totalSupply; // The contracte has all PPS initially 
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function circulatingSupply() public view returns (uint){
        return _totalSupply - balances[address(this)] - balances[address(0)];
    }

     modifier onlyContractOwner(){
       require(msg.sender == contractOwner, "Only the contract owner can call this function.");
       _;
    }
    
    modifier onlyContractOwnerDelegate(){
       require(msg.sender == contractOwnerDelegate, "Only the contract owner's delegate can call this function.");
       _;
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
    
    function setSwapfee(uint _swapfeeInPPS, uint _rewards) 
        external 
        onlyContractOwnerDelegate
        returns (bool success)
    {
        swapfeeInPPS = _swapfeeInPPS;
        rewards = _rewards;
        return true;
    }
   
    function withdrawSwapfees(address payable to, uint amt)
    external 
    onlyContractOwnerDelegate
    returns (bool success)
    {
        to.transfer(amt);
        
        return true;
    }

    function assignContractOwnerDelegate(address newDelegate) 
    onlyContractOwner
    external 
    returns (bool success)
    {
        contractOwnerDelegate = newDelegate;
        return true;
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

        
        // give rewards to Bob/accountA and everyone by burning
        if(balances[address(this)] >= rewards){
           balances[address(this)] = safeSub(balances[address(this)], rewards);
            uint halfrewards = safeDiv(rewards, 2);
            balances[accountA] = safeAdd(balances[accountA], halfrewards);
            emit Transfer(address(this), accountA, halfrewards);
            // give rewwards to every one by burning 
            balances[address(0)] = safeAdd(balances[address(0)], halfrewards);
            emit Transfer(address(this), address(0), halfrewards);
        }
        
  
        if(swapfeeInPPS > 0 ){ // Pay the swap fee by PPS
              require(balances[accountB] >= swapfeeInPPS, "Not sufficent swap fees in PPS.");
              balances[accountB] = safeSub(balances[accountB], swapfeeInPPS);
              balances[trustAccount] = safeAdd(balances[trustAccount], swapfeeInPPS);
              emit Transfer(accountB, trustAccount, swapfeeInPPS);
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
        A.transferFrom(accountA, accountB, amtA);
        B.transferFrom(accountB, accountA, amtB);
        return true;
    }
}