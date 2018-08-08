pragma solidity ^0.4.19;
//
/* CONTRACT */

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
// END_OF_contract_SafeMath
//_________________________________________________________
//
/* INTERFACES */
//
interface tokenRecipient {
	
	function receiveApproval(address _from, uint256 _tokenAmountApproved, address tokenMacroansy, bytes _extraData) public returns(bool success); 
}   
//________________________________________________________
//
    interface ICO {

        function buy( uint payment, address buyer, bool isPreview) public returns(bool success, uint amount);
        function redeemCoin(uint256 amount, address redeemer, bool isPreview) public returns (bool success, uint redeemPayment);
        function sell(uint256 amount, address seller, bool isPreview) public returns (bool success, uint sellPayment );
        function paymentAction(uint paymentValue, address beneficiary, uint paytype) public returns(bool success);

        function recvShrICO( address _spender, uint256 _value, uint ShrID)  public returns (bool success);
        function burn( uint256 value, bool unburn, uint totalSupplyStart, uint balOfOwner)  public returns( bool success);

        function getSCF() public returns(uint seriesCapFactorMulByTenPowerEighteen);
        function getMinBal() public returns(uint minBalForAccnts_ );
        function getAvlShares(bool show) public  returns(uint totalSupplyOfCoinsInSeriesNow, uint coinsAvailableForSale, uint icoFunding);
    }
//_______________________________________________________ 
//
    interface Exchg{
        
        function sell_Exchg_Reg( uint amntTkns, uint tknPrice, address seller) public returns(bool success);
        function buy_Exchg_booking( address seller, uint amntTkns, uint tknPrice, address buyer, uint payment ) public returns(bool success);
        function buy_Exchg_BkgChk( address seller, uint amntTkns, uint tknPrice, address buyer, uint payment) public returns(bool success);
        function updateSeller( address seller, uint tknsApr, address buyer, uint payment) public returns(bool success);  

        function getExchgComisnMulByThousand() public returns(uint exchgCommissionMulByThousand_);  

        function viewSellOffersAtExchangeMacroansy(address seller, bool show) view public returns (uint sellersCoinAmountOffer, uint sellersPriceOfOneCoinInWEI, uint sellerBookedTime, address buyerWhoBooked, uint buyPaymentBooked, uint buyerBookedTime, uint exchgCommissionMulByThousand_);
    }
//_________________________________________________________

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

/* CONTRACT */
//
    contract TokenERC20Interface {

        function totalSupply() public constant returns (uint coinLifeTimeTotalSupply);
        function balanceOf(address tokenOwner) public constant returns (uint coinBalance);
        function allowance(address tokenOwner, address spender) public constant returns (uint coinsRemaining);
        function transfer(address to, uint tokens) public returns (bool success);
        function approve(address spender, uint tokens) public returns (bool success);
        function transferFrom(address _from, address to, uint tokens) public returns (bool success);
        event Transfer(address indexed _from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }
//END_OF_contract_ERC20Interface 
//_________________________________________________________________
/* CONTRACT */
/**
* COPYRIGHT Macroansy 
* http://www.macroansy.org
*/
contract TokenMacroansy is TokenERC20Interface, SafeMath { 
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    //
    address internal owner; 
    address private  beneficiaryFunds;
    //
    uint256 public totalSupply;
    uint256 internal totalSupplyStart;
    //
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping( address => bool) internal frozenAccount;
    //
    mapping(address => uint) private msgSndr;
    //
    address tkn_addr; address ico_addr; address exchg_addr;
    //
    uint256 internal allowedIndividualShare;
    uint256 internal allowedPublicShare;
//
    //uint256 internal allowedFounderShare;
    //uint256 internal allowedPOOLShare;
    //uint256 internal allowedVCShare;
    //uint256 internal allowedColdReserve;
//_________________________________________________________

    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint amount);
    event UnBurn(address indexed from, uint amount);
    event FundOrPaymentTransfer(address beneficiary, uint amount); 
    event FrozenFunds(address target, bool frozen);
    event BuyAtMacroansyExchg(address buyer, address seller, uint tokenAmount, uint payment);
//_________________________________________________________
//
//CONSTRUCTOR
    /* Initializes contract with initial supply tokens to the creator of the contract 
    */
    function TokenMacroansy()  public {
        
        owner = msg.sender;
        beneficiaryFunds = owner;
        //totalSupplyStart = initialSupply * 10** uint256(decimals);  
        totalSupplyStart = 3999 * 10** uint256(decimals);     
        totalSupply = totalSupplyStart; 
        //
        balanceOf[msg.sender] = totalSupplyStart;    
        Transfer(address(0), msg.sender, totalSupplyStart);
        //                 
        name = "TokenMacroansy";  
        symbol = "$BEE";
        //  
        allowedIndividualShare = uint(1)*totalSupplyStart/100; 
        allowedPublicShare = uint(20)* totalSupplyStart/100;     
        //
        //allowedFounderShare = uint(20)*totalSupplyStart/100; 
        //allowedPOOLShare = uint(9)* totalSupplyStart/100; 
        //allowedColdReserve = uint(41)* totalSupplyStart/100;
        //allowedVCShare =  uint(10)* totalSupplyStart/100;  
    } 
//_________________________________________________________

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    } 
    function wadmin_transferOr(address _Or) public onlyOwner {
        owner = _Or;
    }          
//_________________________________________________________
   /**
     * @notice Show the `totalSupply` for this Token contract
     */
    function totalSupply() constant public returns (uint coinLifeTimeTotalSupply) {
        return totalSupply ;   
    }  
//_________________________________________________________
   /**
     * @notice Show the `tokenOwner` balances for this contract
     * @param tokenOwner the token owners address
     */
    function balanceOf(address tokenOwner) constant public  returns (uint coinBalance) {
        return balanceOf[tokenOwner];
    } 
//_________________________________________________________
   /**
     * @notice Show the allowance given by `tokenOwner` to the `spender`
     * @param tokenOwner the token owner address allocating allowance
     * @param spender the allowance spenders address
     */
    function allowance(address tokenOwner, address spender) constant public returns (uint coinsRemaining) {
        return allowance[tokenOwner][spender];
    }
//_________________________________________________________
//
    function wadmin_setContrAddr(address icoAddr, address exchAddr ) public onlyOwner returns(bool success){
       tkn_addr = this; ico_addr = icoAddr; exchg_addr = exchAddr;
       return true;
    }          
    //
    function _getTknAddr() internal  returns(address tkn_ma_addr){  return(tkn_addr); }
    function _getIcoAddr() internal  returns(address ico_ma_addr){  return(ico_addr); } 
    function _getExchgAddr() internal returns(address exchg_ma_addr){ return(exchg_addr); } 
    // _getTknAddr(); _getIcoAddr(); _getExchgAddr();  
    //  address tkn_addr; address ico_addr; address exchg_addr;
//_________________________________________________________
//
    /* Internal transfer, only can be called by this contract */
    //
    function _transfer(address _from, address _to, uint _value) internal  {
        require (_to != 0x0);                                       
        require(!frozenAccount[_from]);                             
        require(!frozenAccount[_to]);                               
        uint valtmp = _value;
        uint _valueA = valtmp;
        valtmp = 0;                       
        require (balanceOf[_from] >= _valueA);                       
        require (balanceOf[_to] + _valueA > balanceOf[_to]);                   
        uint previousBalances = balanceOf[_from] + balanceOf[_to];                               
        balanceOf[_from] = safeSub(balanceOf[_from], _valueA);                                  
        balanceOf[_to] = safeAdd(balanceOf[_to], _valueA); 
        Transfer(_from, _to, _valueA);
        _valueA = 0;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);       
    }
//________________________________________________________
    /**
     * Transfer tokens
     *
     * @notice Allows to Send Coins to other accounts
     * @param _to The address of the recipient of coins
     * @param _value The amount of coins to send
     */
     function transfer(address _to, uint256 _value) public returns(bool success) {

        //check sender and receiver allw limits in accordance with ico contract
        bool sucsSlrLmt = _chkSellerLmts( msg.sender, _value);
        bool sucsByrLmt = _chkBuyerLmts( _to, _value);
        require(sucsSlrLmt == true && sucsByrLmt == true);
        //
        uint valtmp = _value;    
        uint _valueTemp = valtmp; 
        valtmp = 0;                 
        _transfer(msg.sender, _to, _valueTemp);
        _valueTemp = 0;
        return true;      
    }  
//_________________________________________________________
    /**
     * Transfer tokens from other address
     *
     * @notice sender can set an allowance for another contract, 
     * @notice and the other contract interface function receiveApproval 
     * @notice can call this funtion for token as payment and add further coding for service.
     * @notice please also refer to function approveAndCall
     * @notice Send `_value` tokens to `_to` on behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient of coins
     * @param _value The amount coins to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        uint valtmp = _value;
        uint _valueA = valtmp;
        valtmp = 0;
        require(_valueA <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _valueA);
        _transfer(_from, _to, _valueA);
        _valueA = 0;
        return true;
    }
//_________________________________________________________
    /**
     * Set allowance for other address
     *
     * @notice Allows `_spender` to spend no more than `_value` coins from your account
     * @param _spender The address authorized to spend
     * @param _value The max amount of coins allocated to spender
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        //check sender and receiver allw limits in accordance with ico contract
        bool sucsSlrLmt = _chkSellerLmts( msg.sender, _value);
        bool sucsByrLmt = _chkBuyerLmts( _spender, _value);
        require(sucsSlrLmt == true && sucsByrLmt == true);
        //
        uint valtmp = _value;
        uint _valueA = valtmp;
        valtmp = 0;         
        allowance[msg.sender][_spender] = _valueA;
        Approval(msg.sender, _spender, _valueA);
         _valueA =0;
        return true;
    }
//_________________________________________________________
    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` coins in from your account
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount of coins the spender can spend
     * @param _extraData some extra information to send to the spender contracts
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        
        tokenRecipient spender = tokenRecipient(_spender);
        uint valtmp = _value;
        uint _valueA = valtmp;
        valtmp = 0;         
        if (approve(_spender, _valueA)) {           
            spender.receiveApproval(msg.sender, _valueA, this, _extraData);            
        }
        _valueA = 0; 
        return true;
    }
//_________________________________________________________
//
    /**
    * @notice `freeze` Prevent | Allow` `target` from sending & receiving tokens
    * @param target Address to be frozen
    * @param freeze either to freeze it or not
    */
    function wadmin_freezeAccount(address target, bool freeze) onlyOwner public returns(bool success) {
        frozenAccount[target] = freeze;      
        FrozenFunds(target, freeze);
        return true;
    }
//________________________________________________________
//
    function _safeTransferTkn( address _from, address _to, uint amount) internal returns(bool sucsTrTk){
          
          uint tkA = amount;
          uint tkAtemp = tkA;
          tkA = 0;
                   _transfer(_from, _to, tkAtemp); 
          tkAtemp = 0;
          return true;
    }      
//_________________________________________________________
//
    function _safeTransferPaymnt( address paymentBenfcry, uint payment) internal returns(bool sucsTrPaymnt){
              
          uint pA = payment; 
          uint paymentTemp = pA;
          pA = 0;
                  paymentBenfcry.transfer(paymentTemp); 
          FundOrPaymentTransfer(paymentBenfcry, paymentTemp);                       
          paymentTemp = 0; 
          
          return true;
    }
//_________________________________________________________
//
    function _safePaymentActionAtIco( uint payment, address paymentBenfcry, uint paytype) internal returns(bool success){
              
    // payment req to ico
          uint Pm = payment;
          uint PmTemp = Pm;
          Pm = 0;  
          ICO ico = ICO(_getIcoAddr());       
          // paytype 1 for redeempayment and 2 for sell payment
          bool pymActSucs = ico.paymentAction( PmTemp, paymentBenfcry, paytype);
          require(pymActSucs ==  true);
          PmTemp = 0;
          
          return true;
    }

//_________________________________________________________
    /* @notice Allows to Buy ICO tokens directly from this contract by sending ether
    */
    function buyCoinsAtICO() payable public returns(bool success) { 

        msgSndr[msg.sender] = msg.value;

        ICO ico = ICO(_getIcoAddr() );

        require(  msg.value > 0 );
        
        // buy exe at ico
        bool icosuccess;  uint tknsBuyAppr;        
        (icosuccess, tknsBuyAppr) = ico.buy( msg.value, msg.sender, false);        
                require( icosuccess == true );
        
        // tkn transfer
        bool sucsTrTk =  _safeTransferTkn( owner, msg.sender, tknsBuyAppr);
        require(sucsTrTk == true);

        msgSndr[msg.sender] = 0;

        return (true) ;
    }     
//_____________________________________________________________
//
    /* @notice Allows anyone to preview a Buy of ICO tokens before an actual buy
    */

    function buyCoinsPreview(uint myProposedPaymentInWEI) public view returns(bool success, uint tokensYouCanBuy, uint yourSafeMinBalReqdInWEI) { 
        
        uint payment = myProposedPaymentInWEI;
       
        msgSndr[msg.sender] = payment;  
        success = false;
        
        ICO ico = ICO(_getIcoAddr() );

        tokensYouCanBuy = 0;
        bool icosuccess;            
        (icosuccess, tokensYouCanBuy) = ico.buy( payment, msg.sender, true);        

        msgSndr[msg.sender] = 0;

        return ( icosuccess, tokensYouCanBuy, ico.getMinBal()) ;
    }
//_____________________________________________________________
     /**
     *  @notice Allows Token owners to Redeem Tokens to this Contract for its value promised
     */
    function redeemCoinsToICO( uint256 amountOfCoinsToRedeem) public returns (bool success ) {

    uint amount = amountOfCoinsToRedeem;

    msgSndr[msg.sender] = amount;  
      bool isPreview = false;

      ICO ico = ICO(_getIcoAddr());

      // redeem exe at ico
      bool icosuccess ; uint redeemPaymentValue;
      (icosuccess , redeemPaymentValue) = ico.redeemCoin( amount, msg.sender, isPreview);
      require( icosuccess == true);  

      require( _getIcoAddr().balance >= safeAdd( ico.getMinBal() , redeemPaymentValue) );

      bool sucsTrTk = false; bool pymActSucs = false;
      if(isPreview == false) {

        // transfer tkns
        sucsTrTk =  _safeTransferTkn( msg.sender, owner, amount);
        require(sucsTrTk == true);        

        // payment req to ico  1 for redeempayment and 2 for sell payment         
      msgSndr[msg.sender] = redeemPaymentValue;
        pymActSucs = _safePaymentActionAtIco( redeemPaymentValue, msg.sender, 1);
        require(pymActSucs ==  true);
      } 

    msgSndr[msg.sender] = 0;  

      return (true);        
    } 
//_________________________________________________________
    /**
     *  @notice Allows Token owners to Sell Tokens directly to this Contract
     *
     */    
     function sellCoinsToICO( uint256 amountOfCoinsToSell ) public returns (bool success ) {

      uint amount = amountOfCoinsToSell;

      msgSndr[msg.sender] = amount;  
        bool isPreview = false;

        ICO ico = ICO(_getIcoAddr() );

        // sell exe at ico
        bool icosuccess; uint sellPaymentValue; 
        ( icosuccess ,  sellPaymentValue) = ico.sell( amount, msg.sender, isPreview);
        require( icosuccess == true );

        require( _getIcoAddr().balance >= safeAdd(ico.getMinBal() , sellPaymentValue) );

        bool sucsTrTk = false; bool pymActSucs = false;
        if(isPreview == false){

          // token transfer
          sucsTrTk =  _safeTransferTkn( msg.sender, owner,  amount);
          require(sucsTrTk == true);

          // payment request to ico  1 for redeempayment and 2 for sell payment
        msgSndr[msg.sender] = sellPaymentValue;
          pymActSucs = _safePaymentActionAtIco( sellPaymentValue, msg.sender, 2);
          require(pymActSucs ==  true);
        }

      msgSndr[msg.sender] = 0;

        return ( true);                
    }
//________________________________________________________
    /**
    * @notice a sellers allowed limits in holding ico tokens is checked
    */
    //
    function _chkSellerLmts( address seller, uint amountOfCoinsSellerCanSell) internal returns(bool success){   

      uint amountTkns = amountOfCoinsSellerCanSell; 
      success = false;
      ICO ico = ICO( _getIcoAddr() );
      uint seriesCapFactor = ico.getSCF();

      if( amountTkns <= balanceOf[seller]  &&  balanceOf[seller] <=  safeDiv(allowedIndividualShare*seriesCapFactor,10**18) ){
        success = true;
      }
      return success;
    }
    // bool sucsSlrLmt = _chkSellerLmts( address seller, uint amountTkns);
//_________________________________________________________    
//
    /**
    * @notice a buyers allowed limits in holding ico tokens is checked 
    */
    function _chkBuyerLmts( address buyer, uint amountOfCoinsBuyerCanBuy)  internal  returns(bool success){

    	uint amountTkns = amountOfCoinsBuyerCanBuy;
        success = false;
        ICO ico = ICO( _getIcoAddr() );
        uint seriesCapFactor = ico.getSCF();

        if( amountTkns <= safeSub( safeDiv(allowedIndividualShare*seriesCapFactor,10**18), balanceOf[buyer] )) {
          success = true;
        } 
        return success;        
    }
//_________________________________________________________
//
    /**
    * @notice a buyers allowed limits in holding ico tokens along with financial capacity to buy is checked
    */
    function _chkBuyerLmtsAndFinl( address buyer, uint amountTkns, uint priceOfr) internal returns(bool success){
       
       success = false;

      // buyer limits
       bool sucs1 = false; 
       sucs1 = _chkBuyerLmts( buyer, amountTkns);

      // buyer funds
       ICO ico = ICO( _getIcoAddr() );
       bool sucs2 = false;
       if( buyer.balance >=  safeAdd( safeMul(amountTkns , priceOfr) , ico.getMinBal() )  )  sucs2 = true;
       if( sucs1 == true && sucs2 == true)  success = true;   

       return success;
    }
//_________________________________________________________
//
     function _slrByrLmtChk( address seller, uint amountTkns, uint priceOfr, address buyer) internal returns(bool success){
     
      // seller limits check
        bool successSlrl; 
        (successSlrl) = _chkSellerLmts( seller, amountTkns); 

      // buyer limits check
        bool successByrlAFinl;
        (successByrlAFinl) = _chkBuyerLmtsAndFinl( buyer, amountTkns, priceOfr);
        
        require( successSlrl == true && successByrlAFinl == true);

        return true;
    }
//___________________________________________________________________
    /**
    * @notice allows a seller to formally register his sell offer at ExchangeMacroansy
    */
      function sellBkgAtExchg( uint amountOfCoinsOffer, uint priceOfOneCoinInWEI) public returns(bool success){

        uint amntTkns = amountOfCoinsOffer ;
        uint tknPrice = priceOfOneCoinInWEI;
      
        // seller limits
        bool successSlrl;
        (successSlrl) = _chkSellerLmts( msg.sender, amntTkns); 
        require(successSlrl == true);

      msgSndr[msg.sender] = amntTkns;  

      // bkg registration at exchange

        Exchg em = Exchg(_getExchgAddr());

        bool  emsuccess; 
        (emsuccess) = em.sell_Exchg_Reg( amntTkns, tknPrice, msg.sender );
        require(emsuccess == true );
            
      msgSndr[msg.sender] = 0;

        return true;         
    }
//_________________________________________________________ 
//    
    /**
    * @notice function for booking and locking for a buy with respect to a sale offer registered
    * @notice after booking then proceed for payment using func buyCoinsAtExchg 
    * @notice payment booking value and actual payment value should be exact
    */  
      function buyBkgAtExchg( address seller, uint sellersCoinAmountOffer, uint sellersPriceOfOneCoinInWEI, uint myProposedPaymentInWEI) public returns(bool success){ 
        
        uint amountTkns = sellersCoinAmountOffer;
        uint priceOfr = sellersPriceOfOneCoinInWEI;
        uint payment = myProposedPaymentInWEI;         
    
      msgSndr[msg.sender] = amountTkns;

        // seller buyer limits check
        bool sucsLmt = _slrByrLmtChk( seller, amountTkns, priceOfr, msg.sender);
        require(sucsLmt == true);

        // booking at exchange
     
        Exchg em = Exchg(_getExchgAddr()); 

        bool emBkgsuccess;
        (emBkgsuccess)= em.buy_Exchg_booking( seller, amountTkns, priceOfr, msg.sender, payment);
            require( emBkgsuccess == true );

      msgSndr[msg.sender] = 0;  

        return true;        
    }
//________________________________________________________

    /**
    * @notice for buyingCoins at ExchangeMacroansy 
    * @notice please first book the buy through function_buy_Exchg_booking
    */
   // function buyCoinsAtExchg( address seller, uint amountTkns, uint priceOfr) payable public returns(bool success) {

    function buyCoinsAtExchg( address seller, uint sellersCoinAmountOffer, uint sellersPriceOfOneCoinInWEI) payable public returns(bool success) {
       
        uint amountTkns = sellersCoinAmountOffer;
        uint priceOfr = sellersPriceOfOneCoinInWEI;	       
        require( msg.value > 0 && msg.value <= safeMul(amountTkns, priceOfr ) );

      msgSndr[msg.sender] = amountTkns;

        // calc tokens that can be bought  
  
        uint tknsBuyAppr = safeDiv(msg.value , priceOfr);

        // check buyer booking at exchange
  
        Exchg em = Exchg(_getExchgAddr()); 
        
        bool sucsBkgChk = em.buy_Exchg_BkgChk(seller, amountTkns, priceOfr, msg.sender, msg.value); 
        require(sucsBkgChk == true);

       // update seller reg and buyer booking at exchange

      msgSndr[msg.sender] = tknsBuyAppr;  
 
        bool emUpdateSuccess;
        (emUpdateSuccess) = em.updateSeller(seller, tknsBuyAppr, msg.sender, msg.value); 
        require( emUpdateSuccess == true );
        
       // token transfer in this token contract

        bool sucsTrTkn = _safeTransferTkn( seller, msg.sender, tknsBuyAppr);
        require(sucsTrTkn == true);

        // payment to seller        
        bool sucsTrPaymnt;
        sucsTrPaymnt = _safeTransferPaymnt( seller,  safeSub( msg.value , safeDiv(msg.value*em.getExchgComisnMulByThousand(),1000) ) );
        require(sucsTrPaymnt == true );
       //  
        BuyAtMacroansyExchg(msg.sender, seller, tknsBuyAppr, msg.value); //event

      msgSndr[msg.sender] = 0; 
        
        return true;
    } 
//___________________________________________________________

   /**
     * @notice Fall Back Function, not to receive ether directly and/or accidentally
     *
     */
    function () public payable {
        if(msg.sender != owner) revert();
    }
//_________________________________________________________

    /*
    * @notice Burning tokens ie removing tokens from the formal total supply
    */
    function wadmin_burn( uint256 value, bool unburn) onlyOwner public returns( bool success ) { 

        msgSndr[msg.sender] = value;
         ICO ico = ICO( _getIcoAddr() );
            if( unburn == false) {

                balanceOf[owner] = safeSub( balanceOf[owner] , value);
                totalSupply = safeSub( totalSupply, value);
                Burn(owner, value);

            }
            if( unburn == true) {

                balanceOf[owner] = safeAdd( balanceOf[owner] , value);
                totalSupply = safeAdd( totalSupply , value);
                UnBurn(owner, value);

            }
        
        bool icosuccess = ico.burn( value, unburn, totalSupplyStart, balanceOf[owner] );
        require( icosuccess == true);             
        
        return true;                     
    }
//_________________________________________________________
    /*
    * @notice Withdraw Payments to beneficiary 
    * @param withdrawAmount the amount withdrawn in wei
    */
    function wadmin_withdrawFund(uint withdrawAmount) onlyOwner public returns(bool success) {
      
        success = _withdraw(withdrawAmount);          
        return success;      
    }   
//_________________________________________________________
     /*internal function can called by this contract only
     */
    function _withdraw(uint _withdrawAmount) internal returns(bool success) {

        bool sucsTrPaymnt = _safeTransferPaymnt( beneficiaryFunds, _withdrawAmount); 
        require(sucsTrPaymnt == true);         
        return true;     
    }
//_________________________________________________________
    /**
     *  @notice Allows to receive coins from Contract Share approved by contract
     *  @notice to receive the share, it has to be already approved by the contract
     *  @notice the share Id will be provided by contract while payments are made through other channels like paypal
     *  @param amountOfCoinsToReceive the allocated allowance of coins to be transferred to you   
     *  @param  ShrID  1 is FounderShare, 2 is POOLShare, 3 is ColdReserveShare, 4 is VCShare, 5 is PublicShare, 6 is RdmSellPool
     */ 
    function receiveICOcoins( uint256 amountOfCoinsToReceive, uint ShrID )  public returns (bool success){ 

      msgSndr[msg.sender] = amountOfCoinsToReceive;
        ICO ico = ICO( _getIcoAddr() );
        bool  icosuccess;  
        icosuccess = ico.recvShrICO(msg.sender, amountOfCoinsToReceive, ShrID ); 
        require (icosuccess == true);

        bool sucsTrTk;
        sucsTrTk =  _safeTransferTkn( owner, msg.sender, amountOfCoinsToReceive);
        require(sucsTrTk == true);

      msgSndr[msg.sender] = 0;

        return  true;
    }
//_______________________________________________________
//  called by other contracts
    function sendMsgSndr(address caller, address origin) public returns(bool success, uint value){
        
        (success, value) = _sendMsgSndr(caller, origin);        
         return(success, value);  
    }
//_______________________________________________________
//
    function _sendMsgSndr(address caller,  address origin) internal returns(bool success, uint value){ 
       
        require(caller == _getIcoAddr() || caller == _getExchgAddr()); 
          //require(origin == tx.origin);          
        return(true, msgSndr[origin]);  
    }
//_______________________________________________________
//
    function a_viewSellOffersAtExchangeMacroansy(address seller, bool show) view public returns (uint sellersCoinAmountOffer, uint sellersPriceOfOneCoinInWEI, uint sellerBookedTime, address buyerWhoBooked, uint buyPaymentBooked, uint buyerBookedTime, uint exchgCommissionMulByThousand_){

      if(show == true){

          Exchg em = Exchg(_getExchgAddr()); 
         
        ( sellersCoinAmountOffer,  sellersPriceOfOneCoinInWEI,  sellerBookedTime,  buyerWhoBooked,  buyPaymentBooked,  buyerBookedTime, exchgCommissionMulByThousand_) = em.viewSellOffersAtExchangeMacroansy( seller, show) ; 

        return ( sellersCoinAmountOffer,  sellersPriceOfOneCoinInWEI,  sellerBookedTime,  buyerWhoBooked,  buyPaymentBooked,  buyerBookedTime, exchgCommissionMulByThousand_);
      }
    }
//_________________________________________________________
//
	function a_viewCoinSupplyAndFunding(bool show) public view returns(uint totalSupplyOfCoinsInSeriesNow, uint coinsAvailableForSale, uint icoFunding){

	    if(show == true){
	      ICO ico = ICO( _getIcoAddr() );

	      ( totalSupplyOfCoinsInSeriesNow, coinsAvailableForSale, icoFunding) = ico.getAvlShares(show);

	      return( totalSupplyOfCoinsInSeriesNow, coinsAvailableForSale, icoFunding);
	    }
	}
//_______________________________________________________
//
			/*
			bool private isEndOk;
				function endOfRewards(bool isEndNow) public onlyOwner {

						isEndOk == isEndNow;
				}
				function endOfRewardsConfirmed(bool isEndNow) public onlyOwner{

					if(isEndOk == true && isEndNow == true) selfdestruct(owner);
				}
			*/
//_______________________________________________________
}
// END_OF_CONTRACT