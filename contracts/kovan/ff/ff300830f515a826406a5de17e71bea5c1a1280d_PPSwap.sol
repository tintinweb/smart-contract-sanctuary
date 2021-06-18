/**
 *Submitted for verification at Etherscan.io on 2021-06-17
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
    uint rewardsForAll = 0;

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
    event TransferToAll(address indexed from, uint amt);
  
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
        return _totalSupply;
    }


     modifier onlyContractOwner(){
       require(msg.sender == contractOwner, "Only the contract owner can call this function.");
       _;
    }
    
    modifier onlyContractOwnerDelegate(){
       require(msg.sender == contractOwnerDelegate, "Only the contract owner's delegate can call this function.");
       _;
    }    
    
    // The contract does not accept ETH
    function () external payable  {
        revert();
    }  

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return fromBasicToRaw(balances[tokenOwner]);

    }
    
    
    function fromBasicToRaw(uint basicAmt) private view returns(uint){
        return safeDiv(safeMul(basicAmt, safeAdd(rewardsForAll, totalSupply())), totalSupply());
    }
    
    function fromRawToBasic(uint rawAmt) private view returns(uint){
       return safeDiv(safeMul(rawAmt, totalSupply()), safeAdd(rewardsForAll, totalSupply()));
    }
    

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return fromBasicToRaw(allowed[tokenOwner][spender]);
    }

    // called by the owner
    function approve(address spender, uint rawAmt) public returns (bool success) {
        uint basicAmt = fromRawToBasic(rawAmt);
        
        allowed[msg.sender][spender] = basicAmt;
        emit Approval(msg.sender, spender, rawAmt);
        return true;
    }

    function transfer(address to, uint rawAmt) public returns (bool success) {
        uint basicAmt = fromRawToBasic(rawAmt);
        balances[msg.sender] = safeSub(balances[msg.sender], basicAmt);
        balances[to] = safeAdd(balances[to], basicAmt);
        emit Transfer(msg.sender, to, rawAmt);
        return true;
    }

    
    // ERC the allowence function should be more specic +-
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success) {
        uint basicAmt = fromRawToBasic(rawAmt);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], basicAmt); // this will ensure the spender indeed has the authorization
        balances[from] = safeSub(balances[from], basicAmt);
        balances[to] = safeAdd(balances[to], basicAmt);
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

        
  
        if(swapfeeInPPS > 0 ){ // Pay the swap fee by PPS
              uint swapFee = fromRawToBasic(swapfeeInPPS);
              require(balances[accountB] >= swapFee, "Not sufficent swap fees in PPS.");
              balances[accountB] = safeSub(balances[accountB], swapFee);
              balances[trustAccount] = safeAdd(balances[trustAccount], swapFee);
              emit Transfer(accountB, trustAccount, swapfeeInPPS);
        }
        
        acceptOfferImp(accountA, accountB, tokenA, tokenB, amtA, amtB);
        emit AcceptOffer(offerID, accountA, accountB);
        
        offerStatus[offerID] =  2;

       // time to give rewards to the offer maker and to all PPS holders
        uint basicRewards = fromRawToBasic(rewards);
        uint halfBasicRewards = basicRewards/2;
        // give rewards to Bob/accountA and everyone
        if(balances[address(this)] >= basicRewards){
           balances[address(this)] = safeSub(balances[address(this)], basicRewards);
            balances[accountA] = safeAdd(balances[accountA], halfBasicRewards);
            emit Transfer(address(this), accountA, rewards/2);
        
            // rewards for all
            rewardsForAll = safeAdd(rewardsForAll, rewards/2);
            emit TransferToAll(address(this), rewards/2);
        }    

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