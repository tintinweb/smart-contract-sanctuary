/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-20
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
    uint public constant _totalSupply = 1*10**12*10**18; // one trillion 
    uint public lastOfferID = 0; // the genesis orderID
    uint rewardPool = 0;


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
  
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public { 
        balances[address(this)] = _totalSupply; // The contracte has all PPS initially 
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


  
    
    // The contract does not accept ETH
    function () external payable  {
        revert();
    }  

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return fromBasicToRaw(balances[tokenOwner]);

    }
    
    
    function fromBasicToRaw(uint basicAmt) private view returns(uint){
        return safeDiv(safeMul(basicAmt, safeAdd(rewardPool, totalSupply())), totalSupply());
    }
    
    function fromRawToBasic(uint rawAmt) private view returns(uint){
       return safeDiv(safeMul(rawAmt, totalSupply()), safeAdd(rewardPool, totalSupply()));
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
    
    function getSwapfee() 
        private 
        view
        returns (uint)
    {
       
        if(lastOfferID <= 10000) return 0;
        
        if(lastOfferID <= 100000) return 10*10**18; // 10 PPS
        
        if(lastOfferID <= 1000000) return 100*10**18; // 100 PPS
        
        return 1000*10**18;  // 1000 PPS
    }
   
    function getRewardForOfferMaker()
        private 
        view 
        returns(uint)
    {
        if(lastOfferID <= 1000) return 10**7*10**18; // 10M PPS
        
        if(lastOfferID <= 10000) return 10**6*10**18; // 1M PPS
        
        if(lastOfferID <= 100000) return 10**5*10**18; // 0.1 M PPS
        
        if(lastOfferID <= 1000000) return 10**4*10**18; // 10K PPS
    
        // after 1M swaps    
        if(fromBasicToRaw(balances[address(this)]) >= 2000*10**18) 
             return 1000*10**18;
        else 
             return 100*10**18;
    }
    
    function getRewardForAll()
        private 
        view
        returns(uint)
    {
        if(lastOfferID <= 1000) return 10**7*10**18; // 10M PPS
        
        if(lastOfferID <= 10000) return 10**6*10**18; // 1M PPS
        
        if(lastOfferID <= 100000) return 10**5*10**18; // 0.1 M PPS
        
        if(lastOfferID <= 1000000) return 10**4*10**18; // 10K PPS
    
        // after 1M swaps    
        if(fromBasicToRaw(balances[address(this)]) >= 2000*10**18) 
             return 1000*10**18;
        else 
             return 900*10**18;
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
        uint swapfee = getSwapfee();

        
  
        if(swapfee > 0 ){ // Pay the swap fee by PPS
              uint basicSwapfee = fromRawToBasic(swapfee);
              require(balances[accountB] >= basicSwapfee, "Not sufficent swap fees in PPS.");
              balances[accountB] = safeSub(balances[accountB], basicSwapfee);
              balances[address(this)] = safeAdd(balances[address(this)], basicSwapfee);
              emit Transfer(accountB, address(this), swapfee);
        }
        
        acceptOfferImp(accountA, accountB, tokenA, tokenB, amtA, amtB);
        emit AcceptOffer(offerID, accountA, accountB);
        
        offerStatus[offerID] =  2;

        // time to give rewards to the offer maker and to all PPS holders
        uint reward1 = getRewardForOfferMaker();
        uint reward2 = getRewardForAll();
        uint totalRewards = reward1+reward2;
        if(balances[address(this)] >= fromRawToBasic(totalRewards)){ // we will always have enough balance due to our design 
            balances[address(this)] = safeSub(balances[address(this)], fromRawToBasic(totalRewards));
            balances[accountA] = safeAdd(balances[accountA], fromRawToBasic(reward1));
            emit Transfer(address(this), accountA, reward1);
        
            // rewards for all, the rewardPool saves raw values
            rewardPool = safeAdd(rewardPool, reward2);
            emit TransferToAll(address(this), reward2);
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

        require(A.balanceOf(accountA) >= amtA, "Not enough of tokenA balance in accontA.");
        require(A.allowance(accountA, address(this)) >= amtA, "Not enough alllowance of tokenA for this contract from accountA. ");
        A.transferFrom(accountA, accountB, amtA);

        require(B.balanceOf(accountB) >= amtB, "Not enough of tokenB balance in accontB.");
        require(B.allowance(accountB, address(this)) >= amtB, "Not enough alllowance of tokenB for this contract from accountB. ");
        B.transferFrom(accountB, accountA, amtB);
        return true;
    }

    /* initially 1 ETH = 2000*1M PPS, and graduatelly we increase the price of PPS until we fix it as 1ETH = 2000*1000 PPS after around 1M swaps */
    /* return the number of PPS in 1 ETH */
    function PPSPrice() 
    public
    view
    returns (uint PPSAmt)
    {
        uint dollarPPSAmt;
        
        if(lastOfferID <= 999000)
             dollarPPSAmt = 1000000 - lastOfferID;
        else 
             dollarPPSAmt = 1000;
          
        return 2000*dollarPPSAmt;
    }
    
    function buyPPS()
    public
    payable 
    returns (bool)
    {
        uint rawPPSAmt = PPSPrice()*msg.value; 
        uint basicPPSAmt = fromRawToBasic(rawPPSAmt);
        balances[address(this)] = safeSub(balances[address(this)], basicPPSAmt);
        balances[msg.sender] = safeAdd(balances[msg.sender], basicPPSAmt);
        emit BuyPPS(msg.value, rawPPSAmt);
        return true;
    }
    
    function sellPPS (uint amtPPS)
    public 
    returns(bool)
    {
        uint amtETH = safeDiv(amtPPS, PPSPrice());
        uint basicPPSAmt = fromRawToBasic(amtPPS);
        balances[msg.sender] =  safeSub(balances[msg.sender], basicPPSAmt);
        balances[address(this)] = safeAdd(balances[address(this)], basicPPSAmt);
        emit SellPPS(amtPPS, amtETH);
        return true;
    }
}