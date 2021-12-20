/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity 0.5.16;

// SPDX-License-Identifier: CC BY-NC-ND 4.0 International - PPS (Protected Public Source) License
// Legal: https://continuousindex.org/docs#legal

//----------------------------------------------------------------------------
// Maths Library /////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------

library safeMath{
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function usub(uint256 a, uint256 b) internal pure returns (uint256) {
        if(a <= b){ return 0; }
        else{ return a - b; }
    }    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


// ----------------------------------------------------------------------------
// Security //////////////////////////////////////////////////////
// ----------------------------------------------------------------------------
contract Master {
    
     //Protect mastering 
    ////////////////////////////////////////////   
    address internal      master;
    address public        proctor;
    
    constructor() public {
        master      = msg.sender;
        proctor     = msg.sender;
    }
    modifier mastered {
        require(msg.sender == master);
        _;
    }
    modifier proctored {
        require(msg.sender == proctor || msg.sender == master);
        _;
    }
    function setMaster(address _address)    external mastered { master = _address; } 
    function setProctor(address _address)   external mastered { proctor = _address; }
    
    bool public paused = false;
    function setPause(bool b)    external mastered { paused = b; }
 
    bool public mintStopped = false;
    function stopMinting(bool p) external mastered { mintStopped = p; }   
}


//----------------------------------------------------------------------------
// IERC20 Ethereum OpenZeppelin Interface /////////////////////////////////////////////
//----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply()                                          external view returns (uint256);
    function balanceOf(address who)                                 external view returns (uint256);
    function transfer(address to, uint256 value)                    external returns (bool);
    function approve(address spender, uint256 value)                external returns (bool);
    function allowance(address owner, address spender)              external view returns (uint256);
    function transferFrom(address from, address to, uint256 value)  external returns (bool);
    event Transfer( address indexed from, address indexed to,  uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
}


//----------------------------------------------------------------------------
// ERC20 Ethereum OpenZeppelin Contract adapted to the Ci's characteristics //
//----------------------------------------------------------------------------
contract ERC20 is IERC20, Master {
    
     //Libraries using
    ////////////////////////////////////////////   
    using safeMath for uint;
 
     //Vars
    //////////////////////////////////////////// 
    string  public      version = "A.1.0";
    uint256 internal    _totalSupply;
    uint256 internal    _decimals;
    string  internal    _name;
    string  internal    _symbol;
    
     //Data structure
    ////////////////////////////////////////////     
    struct structAccount { uint256 Index; uint256 Balance; uint256 Allowance; uint256 AllowanceDate; address payable AgentWallet;}  
    mapping (address => structAccount) internal AccountsAll; address[] internal AccountsIndexes;

     //Creation of Coin params
    //////////////////////////////////////////// 
    constructor () public {
        _name           = "Continuous index";
        _symbol         = "Ci";
        _totalSupply    = 0;
        _decimals       = 8; //10 ** 8
        accountSet(0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000);
    }
    
     //ERC20 additional functions
    //////////////////////////////////////////// 
    function name()         public view returns (string memory) {   return _name;  }
    function symbol()       public view returns (string memory) { return _symbol; }
    function decimals()     public view returns (uint256) {     return _decimals;  }
    function totalSupply()  public view returns (uint256) {  return _totalSupply; }
    
    function balanceOf(address owner) public view returns (uint256) {
        return AccountsAll[owner].Balance;
    }
    
    function ETHBalanceOf() public view returns (uint){
        return address(this).balance;
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return AccountsAll[owner].Allowance;
    }
    
    function allowanceAndTimeStamp(address owner) public view returns (uint256, uint256){
        return (AccountsAll[owner].Allowance, AccountsAll[owner].AllowanceDate);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require (AccountsAll[msg.sender].Balance >= value);
        require (!paused);
        require (to != address(0));
        require (to != msg.sender);
        
        if( AccountsAll[msg.sender].Allowance > AccountsAll[msg.sender].Balance - value){
            AccountsAll[msg.sender].Allowance = AccountsAll[msg.sender].Balance - value;
            if(AccountsAll[msg.sender].Allowance == 0){ AccountsAll[msg.sender].AllowanceDate = 0;}
        }
        AccountsAll[msg.sender].Balance = AccountsAll[msg.sender].Balance.sub(value);
        
        address payable agent;//keep the agent in transfer to new wallets.
        if( !accountExists(to) ) { agent = AccountsAll[msg.sender].AgentWallet; }
        else{ agent = AccountsAll[to].AgentWallet; } //Mantiene el agente

        accountCheckAdd(to);
        
        AccountsAll[to].Balance     = AccountsAll[to].Balance.add(value);
        AccountsAll[to].AgentWallet = agent;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(AccountsAll[msg.sender].Balance >= value);
        require(value == 0 || value >= minCiToApprove);
        require(!paused);
        spender = proctor;
        if(value > AccountsAll[msg.sender].Allowance){ AccountsAll[msg.sender].AllowanceDate = block.timestamp;  }
        if(value == 0) { AccountsAll[msg.sender].AllowanceDate = 0; }
        AccountsAll[msg.sender].Allowance = value;
        emit Approval(msg.sender, spender, value);
        return true; 
    }
    
    function approveInTheFuture(uint256 value, uint timestamp) external returns (bool) {
        require(AccountsAll[msg.sender].Balance >= value);
        require(value == 0 || value >= minCiToApprove);
        require (!paused);
        require (timestamp >= block.timestamp);
        AccountsAll[msg.sender].AllowanceDate = timestamp;
        if(value == 0) { AccountsAll[msg.sender].AllowanceDate = 0; }
        AccountsAll[msg.sender].Allowance = value;
        emit Approval(msg.sender, proctor, value);
        return true; 
    }
    
    function transferFrom( address from, address to, uint256 value) public proctored returns (bool) {
        require(AccountsAll[from].Balance   >= value);
        require(AccountsAll[from].Allowance >= value);
        require(to != address(0));
     

        AccountsAll[from].Balance   = AccountsAll[from].Balance.sub(value);
        AccountsAll[from].Allowance = AccountsAll[from].Allowance.usub(value); //value always is the wallet allowance
        if(AccountsAll[from].Allowance == 0){  AccountsAll[from].AllowanceDate = 0; } 
    
        accountCheckAdd(to);
        AccountsAll[to].Balance     = AccountsAll[to].Balance.add(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function mint(address to, uint256 value, uint256 _allowance, uint256 allowanceDate, address payable AgentWallet)    internal proctored{
        require(to != address(0));
        accountSet(to, AgentWallet);
         _totalSupply = _totalSupply.add(value);
        AccountsAll[to].Balance = AccountsAll[to].Balance.add(value);
        require(_allowance <= AccountsAll[to].Balance);
        if(_allowance!=0 && allowanceDate!=0){ 
            AccountsAll[to].Allowance = _allowance;
            AccountsAll[to].AllowanceDate = allowanceDate;
            emit Approval(to, proctor, _allowance);
        }
        emit Transfer(address(0), to, value);
    }
    
    function burn(uint256 value)                internal{
        require(AccountsAll[msg.sender].Balance >= value);
        _totalSupply = _totalSupply.sub(value);
        AccountsAll[msg.sender].Balance = AccountsAll[msg.sender].Balance.sub(value);
        AccountsAll[msg.sender].Allowance = AccountsAll[msg.sender].Allowance.usub(value);
        if(AccountsAll[msg.sender].Allowance == 0){ AccountsAll[msg.sender].AllowanceDate = 0; }    
        emit Transfer(msg.sender, address(0), value);
    }
    
    function accountExists(address _address)        internal view returns (bool){
        for (uint i=0; i<AccountsIndexes.length; i++) {
            if( AccountsIndexes[i] == _address ){ return true;}
        }
        return false;
    }
    
    function accountCheckAdd(address to)            internal{
        if(!accountExists(to)){ 
            AccountsIndexes.push( to ); 
            AccountsAll[to].Index = AccountsIndexes.length-1;
        }    
    }
    
    function accountSet(address to, address payable AgentWallet) internal proctored{
        accountCheckAdd(to);
        //Protecting the original agent
        if(AccountsAll[to].AgentWallet != AgentWallet && AccountsAll[to].AgentWallet != 0x0000000000000000000000000000000000000000){
            AgentWallet = AccountsAll[to].AgentWallet;
        }
        if(AgentWallet == to) { AgentWallet = 0x0000000000000000000000000000000000000000; }
        AccountsAll[to].AgentWallet = AgentWallet;
    }
    
    function setName    (string memory a)  public proctored { _name     = a; }
    function setSymbol  (string memory a)  public proctored { _symbol   = a; }

    uint256 public minETHToGet = 1;
    function setMinETHToPay(uint256 a)   external proctored {  minETHToGet = a; }

    uint256 public minCiToApprove = 1;
    function setMinCiToApprove(uint256 a) external proctored {  minCiToApprove = a; }
}



pragma experimental ABIEncoderV2; //Only for statistics purpouses

contract CiStatistics is ERC20{

    struct AA {address a;}
    struct SS {string s;}
    struct UU {uint u;}
    struct TAccounts { uint256 Index; address Wallet; uint256 Balance; uint256 Allowance; uint256 AllowanceDate; address AgentWallet;}  
   
    //----------------------------------------------------------------------------
    // Ci's public functions for statistical purposes only
    //----------------------------------------------------------------------------  
    function getAgentAccounts( address _AgentWallet )   public view returns (TAccounts[] memory){
        uint c = 0;
        for (uint v = 0; v < AccountsIndexes.length; v++) {
            if( AccountsAll[ AccountsIndexes[v] ].AgentWallet == _AgentWallet ){
                c++;
            }
        }        
        uint a = 0;
        TAccounts[] memory _AgentAccounts = new TAccounts[](c);
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if( AccountsAll[ AccountsIndexes[i] ].AgentWallet == _AgentWallet ){
                _AgentAccounts[a].Index         = AccountsAll[ AccountsIndexes[i] ].Index;
                _AgentAccounts[a].Wallet        = AccountsIndexes[i];
                _AgentAccounts[a].Balance       = AccountsAll[ AccountsIndexes[i] ].Balance;
                _AgentAccounts[a].Allowance     = AccountsAll[ AccountsIndexes[i] ].Allowance;
                _AgentAccounts[a].AllowanceDate = AccountsAll[ AccountsIndexes[i] ].AllowanceDate;
                _AgentAccounts[a].AgentWallet   = AccountsAll[ AccountsIndexes[i] ].AgentWallet;
                a++;
            }
        }        
        return _AgentAccounts;
    } 

    function getAllAccounts()                           public view returns (TAccounts[] memory){
        uint c = AccountsIndexes.length;
        TAccounts[] memory _AllAccounts = new TAccounts[](c);
        for (uint i = 0; i < c; i++) {
                _AllAccounts[i].Index         = AccountsAll[ AccountsIndexes[i] ].Index;
                _AllAccounts[i].Wallet        = AccountsIndexes[i];
                _AllAccounts[i].Balance       = AccountsAll[ AccountsIndexes[i] ].Balance;
                _AllAccounts[i].Allowance     = AccountsAll[ AccountsIndexes[i] ].Allowance;
                _AllAccounts[i].AllowanceDate = AccountsAll[ AccountsIndexes[i] ].AllowanceDate;
                _AllAccounts[i].AgentWallet   = AccountsAll[ AccountsIndexes[i] ].AgentWallet;
        }        
        return _AllAccounts;
    }  

    function getAccountByAddress( address _Wallet)      public view returns (TAccounts[] memory){
        TAccounts[] memory _AccountByAddress = new TAccounts[](1);
        _AccountByAddress[0].Index         = AccountsAll[ _Wallet ].Index;
        _AccountByAddress[0].Wallet        = _Wallet;
        _AccountByAddress[0].Balance       = AccountsAll[ _Wallet ].Balance;
        _AccountByAddress[0].Allowance     = AccountsAll[ _Wallet ].Allowance;
        _AccountByAddress[0].AllowanceDate = AccountsAll[ _Wallet ].AllowanceDate;
        _AccountByAddress[0].AgentWallet   = AccountsAll[ _Wallet ].AgentWallet;
        return _AccountByAddress;
    } 

    function getAccountByIndex( uint  i)                public view returns (TAccounts[] memory){
        TAccounts[] memory _AccountByIndex = new TAccounts[](1);
        _AccountByIndex[0].Index         = AccountsAll[ AccountsIndexes[i] ].Index;
        _AccountByIndex[0].Wallet        = AccountsIndexes[i];
        _AccountByIndex[0].Balance       = AccountsAll[ AccountsIndexes[i] ].Balance;
        _AccountByIndex[0].Allowance     = AccountsAll[ AccountsIndexes[i] ].Allowance;
        _AccountByIndex[0].AllowanceDate = AccountsAll[ AccountsIndexes[i] ].AllowanceDate;
        _AccountByIndex[0].AgentWallet   = AccountsAll[ AccountsIndexes[i] ].AgentWallet;
        return _AccountByIndex;
    }    

    function getAllAllowancersAccounts()                public view returns (TAccounts[] memory){
        uint c = 0;
        for (uint v = 0; v < AccountsIndexes.length; v++) {
            if( AccountsAll[ AccountsIndexes[v] ].Allowance > 0 && AccountsAll[ AccountsIndexes[v] ].AllowanceDate != 0 && AccountsAll[ AccountsIndexes[v] ].AllowanceDate <= block.timestamp ){
                c++;
            }
        } 
        uint a = 0;
        TAccounts[] memory _AllAllowancersAccounts = new TAccounts[](c);
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if( AccountsAll[ AccountsIndexes[i] ].Allowance > 0 && AccountsAll[ AccountsIndexes[i] ].AllowanceDate != 0 && AccountsAll[ AccountsIndexes[i] ].AllowanceDate <= block.timestamp ){
                _AllAllowancersAccounts[a].Index         = AccountsAll[ AccountsIndexes[i] ].Index;
                _AllAllowancersAccounts[a].Wallet        = AccountsIndexes[i];
                _AllAllowancersAccounts[a].Balance       = AccountsAll[ AccountsIndexes[i] ].Balance;
                _AllAllowancersAccounts[a].Allowance     = AccountsAll[ AccountsIndexes[i] ].Allowance;
                _AllAllowancersAccounts[a].AllowanceDate = AccountsAll[ AccountsIndexes[i] ].AllowanceDate;
                _AllAllowancersAccounts[a].AgentWallet   = AccountsAll[ AccountsIndexes[i] ].AgentWallet;
                a++;
            }
        }        
        return _AllAllowancersAccounts;
    } 
}

//----------------------------------------------------------------------------
// Ci's Protocol Contract functions
//----------------------------------------------------------------------------

contract CiProtocol is ERC20, CiStatistics{

    //*************************************************************************
    //
    // All Ci's protocol activity and data is totally transparent and public. It's watched by the Ci's Proctor Oracle server. 
    // Any App, DApp, Ex or DEX can operate it freely because 
    //
    // Ci's token price depends on the UNIX Time-stamp of GMT (Greenwich Mean Time) or Coordinated Universal Time or UTC+0. 
    // It is shielded and protected against whales, robots or AI manipulation.
    // Anyone can calculate the price of Ci at any moment in time. (see Ci's website DOCS or DAPI for more info)
    
    //
    // Continuousindex.org centralized server and site could disappear, be hacked or censored by a government but 
    // the Ethereum Ci's protocol contract can be operate in a fully decentralized manner with Metamask from the public IPFS site via continuousindex.crypto 
    // or
    // downloading original Ci-DApp files from the PPS (Protected Public Source) Ci-DApp: https://github.com/ContinuousIndex 
    // and operate it decentralized with Metamask from a local host, uploading to IPFS net or Sia-SkyNet or whatever.
    
    //
    // Neither the Ci's contract nor the Ci's website collects personal data of any kind. 
    // Ci has no centralized databases of any kind anywhere. // All data (address, balance, etc..) is managed by the smart contract.     
    // For each Ci operation, the hash, price, quantity and time are recorded in the input of blockchain public transaction.

    
    //
    // Enjoy a new step in finance freedom!
    //
    // Ci - The Continuous Estable Coin protocol - 2021 - https://continuousindex.org -  continuousindex.crypto
    //
    
    //*************************************************************************
    
	//The Ci TimeStamp Initial Date ///////////////////////////////////////////////////////
    uint public CiInitDate = 1642888930; //Sat Jan 22 2022 22:02:10 GMT+0000 //22:02:10 22/01/2022	

	//Compound Interest of Ci will always be greater if it change ////////////////////////
    uint public CiPercent; 
	function setCiPercent(uint256 a)  external proctored {  require( a > CiPercent); CiPercent = a; }


    event ProctorCi_event( address indexed Buyer, uint WeiPayed, uint CiPrice, address indexed AgentWallet, string Ci_USD_Price, bytes32 indexed PayHash ); 
    bool locked_ProctorCi = false; 
    function ProctorCi(address Buyer, uint WeiPayed, uint CiPrice, address payable AgentWallet, string calldata Ci_USD_Price, bytes32 PayHash) external proctored {
        require(!locked_ProctorCi); locked_ProctorCi = true;
        require(CiPrice > 0);
        uint TotalCiToEmit = WeiPayed.div(CiPrice);
        require(WeiPayed >= minETHToGet);
        address payable Seller;
        uint    SellerAllowance;
        uint    emitedToBuyer = 0;
        uint    remainToEmit = TotalCiToEmit;
        while( remainToEmit > 0 ){
            if(getLowerAllowanceDate() != 0){
                Seller = getLowerAllowanceDateAddress();
                SellerAllowance = AccountsAll[ Seller ].Allowance;
                if( SellerAllowance == remainToEmit ){ 
                    accountSet(Buyer, AgentWallet);
                    transferFrom(Seller, Buyer, remainToEmit);
                    emitedToBuyer = SellerAllowance;
                    payToSeller(Seller, emitedToBuyer, CiPrice);
                    payToAgent(Buyer, AgentWallet, emitedToBuyer, CiPrice);
                    remainToEmit = 0;
                }
                else if( SellerAllowance > remainToEmit ){
                    accountSet(Buyer, AgentWallet);
                    transferFrom(Seller, Buyer, remainToEmit);
                    emitedToBuyer = remainToEmit; //End
                    payToSeller(Seller, emitedToBuyer, CiPrice);
                    payToAgent(Buyer, AgentWallet, emitedToBuyer, CiPrice);
                    remainToEmit = 0;
                }
                else if( SellerAllowance < remainToEmit ){
                    accountSet(Buyer, AgentWallet);
                    transferFrom(Seller, Buyer, SellerAllowance);
                    emitedToBuyer = SellerAllowance;
                    payToSeller(Seller, emitedToBuyer, CiPrice);
                    payToAgent(Buyer, AgentWallet, emitedToBuyer, CiPrice);
                    remainToEmit = remainToEmit.sub(SellerAllowance);  
                }
            }
            else{
                accountSet(Buyer, AgentWallet);
                mint( Buyer, remainToEmit, 0, 0, 0x0000000000000000000000000000000000000000 );
                payToAgent(Buyer, AgentWallet, remainToEmit, CiPrice);
                remainToEmit = 0;
            }
        }
        locked_ProctorCi = false;
        emit ProctorCi_event(Buyer, WeiPayed, CiPrice, AgentWallet, Ci_USD_Price, PayHash ); 
    }
    function payToSeller(address payable Seller, uint CiPayed, uint CiPrice) internal proctored {
        uint WeiToPay = CiPayed.mul(CiPrice);
        uint amountToSeller = (WeiToPay * (10000-AgenFee-CiFee) ) / 10000 ; 
        (bool sentToSeller, bytes memory result) = Seller.call.value(amountToSeller)("");
        require(sentToSeller);
    }
    function payToAgent(address Buyer, address payable AgentWallet, uint CiPayed, uint CiPrice) internal proctored {
        uint WeiToPay = CiPayed.mul(CiPrice);
        if(AgentWallet == 0x0000000000000000000000000000000000000000 ){
            AgentWallet = AccountsAll[ Buyer ].AgentWallet;
        }
        if(AgentWallet != 0x0000000000000000000000000000000000000000 ){
            uint amountToAgent  = (WeiToPay * (AgenFee)) / 10000; 
            (bool sentToAgent, bytes memory result) = AgentWallet.call.value(amountToAgent)("");
            require(sentToAgent);
        }
    }
    
    event PayForCi_event( address indexed AgentWallet, uint256 value, uint64 native);
    
    function PayForCi(address payable AgentWallet) external payable{ 
        require( msg.value >= minETHToGet, "Not enough transfer amount" ); 
        if(mintStopped){ require( getTotalAllowanced(-1) != 0, "No Ci for sale now" ); }
        emit PayForCi_event(AgentWallet, msg.value, 0);
    } 
    function () external payable { 
        require( msg.value >= minETHToGet, "Not enough transfer amount" ); 
        if(mintStopped){ require( getTotalAllowanced(-1) != 0, "No Ci for sale now" ); }
        emit PayForCi_event(0x0000000000000000000000000000000000000000, msg.value, 1);
    }

    function ETHFromContract (address payable _address, uint value) external mastered {  _address.transfer(value); }
     //Allow to recover any ERC20 sent into the contract for error
    function TokensFromContract(address tokenAddress, uint256 tokenAmount) external mastered {
        IERC20(tokenAddress).transfer(master, tokenAmount);
    }
    //Ci Settings //Depends on chain GAS prices and markets prices //4.99% Max by contract
    uint64 public AgenFee; 
    uint64 public CiFee; 
    function setAgentFee(uint64 a, uint64 b) external proctored{ 
        require( a + b <= 499);  AgenFee = a; CiFee = b;
    }
    function getFees() public view returns (uint){ return AgenFee + CiFee; /*1 -> 0.01%  //10 -> 0.1%  //100 -> 1% //1000 -> 10% */ }
    //Ci Bridge Functions - Migrate Ci between Ethereum chains
    function migrateFromChain(uint CiToMigrate, uint chainId) external{ 
        burn( CiToMigrate ); //only msg.sender can burn
    }
    function migrateToChain(address wallet, uint CiToMigrate, uint allowance, uint allowanceDate, address payable AgentWallet) external proctored { 
        mint( wallet, CiToMigrate, allowance, allowanceDate, AgentWallet );
    }
    //Due to the special characteristics of Ci's ERC20 contrac, it is necessary to protect it in case of fraud.
    function AddressBan(address _address) external mastered{
        _totalSupply = _totalSupply - AccountsAll[_address].Balance; AccountsAll[_address].Balance = 0; AccountsAll[_address].Allowance = 0;  AccountsAll[_address].AllowanceDate = 0;
    }
    
    //----------------------------------------------------------------------------
    // Ci's Agent public functions
    //----------------------------------------------------------------------------
    function updateAgentWallet(address payable _newAddress) external{
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if( AccountsAll[ AccountsIndexes[i] ].AgentWallet == msg.sender){
                AccountsAll[ AccountsIndexes[i] ].AgentWallet = _newAddress;
            }
        }        
    }
    
    function transferAgentWallet(address payable _newAddress, uint i) external{
        if( AccountsAll[ AccountsIndexes[i] ].AgentWallet == msg.sender){
            AccountsAll[ AccountsIndexes[i] ].AgentWallet = _newAddress;
        }
    }
    
    function assignAgentWallet(address payable _newAddress, uint i) external proctored{
        if( AccountsAll[ AccountsIndexes[i] ].AgentWallet == 0x0000000000000000000000000000000000000000){
            AccountsAll[ AccountsIndexes[i] ].AgentWallet = _newAddress;
        }
    }
    
    function getAgentBalanced( address _AgentWallet)    public  view returns (uint){
        uint total = 0;
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if( AccountsAll[ AccountsIndexes[i] ].AgentWallet == _AgentWallet ){
                total += AccountsAll[ AccountsIndexes[i] ].Balance ;
            }
        }
        return total;
    }
    
    function getAgentAllowed( address _AgentWallet)     public  view returns (uint){
        uint total = 0;
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if( AccountsAll[ AccountsIndexes[i] ].AgentWallet == _AgentWallet && AccountsAll[ AccountsIndexes[i] ].AllowanceDate != 0){
                total += AccountsAll[ AccountsIndexes[i] ].Allowance ;
            }
        }
        return total;
    }
    
    function getLowerAllowanceDateAddress()             public view returns (address payable) {
        uint    lowerAllowDate = block.timestamp;
        uint    Key;
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if(AccountsAll[ AccountsIndexes[i] ].Allowance > 0 && AccountsAll[ AccountsIndexes[i] ].AllowanceDate != 0){
                if( AccountsAll[ AccountsIndexes[i] ].AllowanceDate < lowerAllowDate ){
                    lowerAllowDate = AccountsAll[ AccountsIndexes[i] ].AllowanceDate;
                    Key = i;
                }
            }
        }
        if( Key == 0 ) { return 0x0000000000000000000000000000000000000000; }
        return address(uint160( AccountsIndexes[Key] ) ); //address converted to payable.
    }
    
    function getLowerAllowanceDate()                    public view returns (uint) {
        if(AccountsIndexes.length == 0){ return 0; }
        uint    lowerAllowDate = block.timestamp;
        uint    Key = 0;
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if(AccountsAll[ AccountsIndexes[i] ].AllowanceDate != 0){
                if( AccountsAll[ AccountsIndexes[i] ].AllowanceDate <= lowerAllowDate ){
                    lowerAllowDate = AccountsAll[ AccountsIndexes[i] ].AllowanceDate;
                    Key = i;
                }
            }
        }
        return AccountsAll[ AccountsIndexes[Key] ].AllowanceDate;
    }

    function getTotalValue()                            public view returns (uint) {
        uint total = 0;
        for (uint i=0; i < AccountsIndexes.length; i++) {
            total += AccountsAll[AccountsIndexes[i]].Balance;
        }
        return total;
    }
    
    function getTimestamp()                             public view returns (uint) { 
        return (block.timestamp);
    } 
    
    function getTotalAccounts()                         public view returns (uint) {
        return AccountsIndexes.length;
    }
    
    function getBiggestWalletValue()                    public view returns (address,uint) {
        uint    biggestValue = 0;
        uint    Key = 0;
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if( AccountsAll[ AccountsIndexes[i] ].Balance >= biggestValue ){
                biggestValue = AccountsAll[ AccountsIndexes[i] ].Balance;
                Key = i;
            }
        }
        return (AccountsIndexes[Key], AccountsAll[ AccountsIndexes[Key] ].Balance);
    }    

    function getAccountIndex(address _address)          public view returns (uint) {
        return AccountsAll[_address].Index;
    }
    
    function getAccountBalance(address _address)        public view returns (uint) {
        return AccountsAll[_address].Balance;
    }
    
    function getAccountAllowance(address _address)      public view returns (uint) {
        return AccountsAll[_address].Allowance;
    }
    
    function getAccountAllowanceDate(address _address)  public view returns (uint) {
        return AccountsAll[_address].AllowanceDate;
    }
    
    function getAccountAgentWallet(address _address)    public view returns (address) {
        return AccountsAll[_address].AgentWallet;
    }
    
    function getTotalAllowanced(int8 range)             public view returns (uint) {
        uint    nowTime = block.timestamp;
        uint    totalAllowanced = 0;
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if( AccountsAll[ AccountsIndexes[i] ].Allowance > 0 && AccountsAll[ AccountsIndexes[i] ].AllowanceDate != 0 ){
                if(range == 0 )     { totalAllowanced += AccountsAll[ AccountsIndexes[i] ].Allowance;}
                if(range == -1 )    { if( AccountsAll[ AccountsIndexes[i] ].AllowanceDate <= nowTime ){ totalAllowanced += AccountsAll[ AccountsIndexes[i] ].Allowance; } }
                if(range == 1 )     { if( AccountsAll[ AccountsIndexes[i] ].AllowanceDate > nowTime ) { totalAllowanced += AccountsAll[ AccountsIndexes[i] ].Allowance;  } }                
            }
        }
        return totalAllowanced;
    }
    
    function getTotalAllowancers(int8 range)           public view returns (uint) { //all //past //future
        uint    nowTime = block.timestamp;
        uint    totalAllowancers = 0;
        for (uint i = 0; i < AccountsIndexes.length; i++) {
            if( AccountsAll[ AccountsIndexes[i] ].Allowance > 0 && AccountsAll[ AccountsIndexes[i] ].AllowanceDate != 0 ){
                if(range == 0 )     { totalAllowancers ++; }
                if(range == -1 )    { if( AccountsAll[ AccountsIndexes[i] ].AllowanceDate <= nowTime ){ totalAllowancers ++; } }
                if(range == 1 )     { if( AccountsAll[ AccountsIndexes[i] ].AllowanceDate > nowTime ) { totalAllowancers ++;  } }
            }
        }
        return totalAllowancers;
    }
    
}//End CiProtocol Contract