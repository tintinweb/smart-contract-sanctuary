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

        function buy( uint payment, address buyer, bool isPreview) public returns(bool success, uint amount, uint retPayment);
        function redeemCoin(uint256 amount, address redeemer, bool isPreview) public returns (bool success, uint redeemPayment);
        function sell(uint256 amount, address seller, bool isPreview) public returns (bool success, uint sellPayment );
        function paymentAction(uint paymentValue, address beneficiary, uint paytype) public returns(bool success);

        function recvShrICO( address _spender, uint256 _value, uint ShrID)  public returns (bool success);
        function burn( uint256 value, bool unburn, uint totalSupplyStart, uint balOfOwner)  public returns( bool success);

        function getSCF() public returns(uint seriesCapFactorMulByTenPowerEighteen);
        function getMinBal() public returns(uint minBalForAccnts_ );
        function getAvlShares(bool show) public  returns(uint totalSupplyOfCoinsInSeriesNow, uint coinsAvailableForSale, uint icoFunding);
    }
//_________________________________________________________
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
//
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
contract TokenMacroansyPower is TokenERC20Interface, SafeMath { 
    
    string public name;
    string public symbol;
    uint8 public decimals = 3;
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
    address internal tkn_addr; address internal ico_addr; address internal exchg_addr;
    address internal cs_addr;  
    //
    uint256 internal allowedIndividualShare;
    uint256 internal allowedPublicShare;
    //
    bool public crowdSaleOpen;
//_________________________________________________________

    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event BurnOrUnBurn(address indexed from, uint amount, uint burnOrUnburn);
    event FundOrPaymentTransfer(address beneficiary, uint amount); 
    // event FrozenFunds(address target, bool frozen);
    //event BuyAtMacroansyExchg(address buyer, address seller, uint tokenAmount, uint payment);
//_________________________________________________________
//
//CONSTRUCTOR
    /* Initializes contract with initial supply tokens to the creator of the contract 
    */
    function TokenMacroansyPower()  public {
        
        owner = msg.sender;
        beneficiaryFunds = owner; 
        totalSupplyStart = 270000000 * 10** uint256(decimals);     
        totalSupply = totalSupplyStart; 
        //
        balanceOf[msg.sender] = totalSupplyStart;    
        Transfer(address(0), msg.sender, totalSupplyStart);
        //                 
        name = "TokenMacroansyPower";  
        symbol = "$BEEPower";
        //  
        allowedIndividualShare = uint(1)*totalSupplyStart/100; 
        allowedPublicShare = uint(20)* totalSupplyStart/100;     
        //
        crowdSaleOpen = false;
    } 
//_________________________________________________________

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    } 
    function transferOr(address _Or) public onlyOwner {
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
    function setContrAddrAndCrwSale(bool setAddress,  address icoAddr, address exchAddr, address csAddr, bool setCrowdSale, bool crowdSaleOpen_ ) public onlyOwner returns(bool success){

       if(setAddress == true){
       		ico_addr = icoAddr; exchg_addr = exchAddr; cs_addr = csAddr;       		
       }
       //
       if( setCrowdSale == true )crowdSaleOpen = crowdSaleOpen_;
       
       return true;   
    }          
    //
    function _getIcoAddr() internal  returns(address ico_ma_addr){  return(ico_addr); } 
    function _getExchgAddr() internal returns(address exchg_ma_addr){ return(exchg_addr); } 
    function _getCsAddr() internal returns(address cs_ma_addr){ return(cs_addr); } 
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
     */
     function transfer(address _to, uint256 _value) public returns(bool success) {

        //check sender and receiver allw limits in accordance with ico contract
        if(msg.sender != owner){
	        bool sucsSlrLmt = _chkSellerLmts( msg.sender, _value);    
	        bool sucsByrLmt = _chkBuyerLmts( _to, _value);
	        require(sucsSlrLmt == true && sucsByrLmt == true);
        }
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
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        //check sender and receiver allw limits in accordance with ico contract
        if(msg.sender != owner){
	        bool sucsSlrLmt = _chkSellerLmts( msg.sender, _value);          
	        bool sucsByrLmt = _chkBuyerLmts( _spender, _value);
	        require(sucsSlrLmt == true && sucsByrLmt == true);
        }
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
    function freezeAccount(address target, bool freeze) onlyOwner public returns(bool success) {
        frozenAccount[target] = freeze;      
        //FrozenFunds(target, freeze);
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
//_____________________________________________________________
//

	function buyCoinsCrowdSale(address buyer, uint payment, address crowdSaleContr) public returns(bool success, uint retPayment) { 
		
		require(crowdSaleOpen == true && crowdSaleContr == _getCsAddr());

		success = false;
		(success , retPayment) = _buyCoins( buyer, payment);
		require(success == true);
		return (success, retPayment);
	}
//_____________________________________________________________
//
    function _buyCoins(address buyer, uint payment) internal returns(bool success, uint retPayment) { 

        msgSndr[buyer] = payment;

        ICO ico = ICO(_getIcoAddr() );

        require(  payment > 0 );
        
        bool icosuccess;  uint tknsBuyAppr;  
        (icosuccess, tknsBuyAppr, retPayment ) = ico.buy( payment, buyer, false);         
        require( icosuccess == true );
        
        if(crowdSaleOpen == false) {
        // return payment to buyer 
	        if( retPayment > 0 ) {
	                
	          bool sucsTrPaymnt;
	          sucsTrPaymnt = _safeTransferPaymnt( buyer, retPayment );
	          require(sucsTrPaymnt == true );
	        }
        }
        // tkn transfer
        bool sucsTrTk =  _safeTransferTkn( owner, buyer, tknsBuyAppr);
        require(sucsTrTk == true);

        msgSndr[buyer] = 0;

        return (true, retPayment);
    }   
//_____________________________________________________________
  
    function redeemOrSellCoinsToICO(uint enter1forRedeemOR2forSell, uint256 amountOfCoinPartsToRedeemOrSell) public returns (bool success ) {

    require(crowdSaleOpen == false);

    uint amount = amountOfCoinPartsToRedeemOrSell;

    msgSndr[msg.sender] = amount;  
      bool isPreview = false;

      ICO ico = ICO(_getIcoAddr());

      // redeem exe at ico
        bool icosuccess ; uint redeemOrSellPaymentValue;
      
	      if(enter1forRedeemOR2forSell == 1){

	      	(icosuccess , redeemOrSellPaymentValue) = ico.redeemCoin( amount, msg.sender, isPreview);
	      }
	      if(enter1forRedeemOR2forSell == 2){

	      	(icosuccess , redeemOrSellPaymentValue) = ico.sell( amount, msg.sender, isPreview);
	      }	      

      require( icosuccess == true);  

        require( _getIcoAddr().balance >= safeAdd( ico.getMinBal() , redeemOrSellPaymentValue) );

      bool sucsTrTk = false; bool pymActSucs = false;
      if(isPreview == false) {

        // transfer tkns
        sucsTrTk =  _safeTransferTkn( msg.sender, owner, amount);
        require(sucsTrTk == true);        

        // payment req to ico  1 for redeempayment and 2 for sell payment         
      msgSndr[msg.sender] = redeemOrSellPaymentValue;
        pymActSucs = _safePaymentActionAtIco( redeemOrSellPaymentValue, msg.sender, enter1forRedeemOR2forSell);
        require(pymActSucs ==  true);
      } 
     
    msgSndr[msg.sender] = 0;  

      return (true);        
    } 
//________________________________________________________

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
//___________________________________________________________

    function () public payable {
       
        if(msg.sender != owner){

            require(crowdSaleOpen == false);
            bool success = false;
            uint retPayment;
			(success , retPayment) = _buyCoins( msg.sender, msg.value);
			require(success == true);    
        }
    }
//_________________________________________________________

		    function burn( uint256 value, bool unburn) onlyOwner public returns( bool success ) { 

		    	require(crowdSaleOpen == false);

		        msgSndr[msg.sender] = value;
		         ICO ico = ICO( _getIcoAddr() );
		            if( unburn == false) {

		                balanceOf[owner] = safeSub( balanceOf[owner] , value);
		                totalSupply = safeSub( totalSupply, value);
		                BurnOrUnBurn(owner, value, 1);

		            }
		            if( unburn == true) {

		                balanceOf[owner] = safeAdd( balanceOf[owner] , value);
		                totalSupply = safeAdd( totalSupply , value);
		                BurnOrUnBurn(owner, value, 2);

		            }
		        
		        bool icosuccess = ico.burn( value, unburn, totalSupplyStart, balanceOf[owner] );
		        require( icosuccess == true);             
		        
		        return true;   
	                    
           }
//_________________________________________________________

    function withdrawFund(uint withdrawAmount) onlyOwner public returns(bool success) {
      
        success = _withdraw(withdrawAmount);          
        return success;      
    }   
//_________________________________________________________

    function _withdraw(uint _withdrawAmount) internal returns(bool success) {

        bool sucsTrPaymnt = _safeTransferPaymnt( beneficiaryFunds, _withdrawAmount); 
        require(sucsTrPaymnt == true);         
        return true;     
    }
//_________________________________________________________

    function receiveICOcoins( uint256 amountOfCoinsToReceive, uint ShrID )  public returns (bool success){ 

      require(crowdSaleOpen == false);

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
//___________________________________________________________________

      function sellBkgAtExchg( uint sellerCoinPartsForSale, uint sellerPricePerCoinPartInWEI) public returns(bool success){
        
        require(crowdSaleOpen == false);

        uint amntTkns = sellerCoinPartsForSale;
        uint tknPrice = sellerPricePerCoinPartInWEI;
      
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
      function buyBkgAtExchg( address seller, uint sellerCoinPartsForSale, uint sellerPricePerCoinPartInWEI, uint myProposedPaymentInWEI) public returns(bool success){ 

        require(crowdSaleOpen == false);

        uint amountTkns = sellerCoinPartsForSale;
        uint priceOfr = sellerPricePerCoinPartInWEI;
        uint payment = myProposedPaymentInWEI;   

		// calc tokens that can be bought         
        uint tknsBuyAppr = 0;    
        if( amountTkns > 2 &&  payment >=  (2 * priceOfr) &&  payment <= (amountTkns * priceOfr) ) {

        	tknsBuyAppr = safeDiv( payment , priceOfr );
        }
        require(tknsBuyAppr > 0);

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

    function buyCoinsAtExchg( address seller, uint sellerCoinPartsForSale, uint sellerPricePerCoinPartInWEI) payable public returns(bool success) {
        
        require(crowdSaleOpen == false);

        uint amountTkns = sellerCoinPartsForSale;
        uint priceOfr = sellerPricePerCoinPartInWEI;	  
		
		// calc tokens that can be bought         
        uint tknsBuyAppr = 0;  // this var as used as the indicator to update buyerbkg and seller update for ok or no txn.

        if( amountTkns > 2 &&  msg.value >=  (2 * priceOfr) &&  msg.value <= (amountTkns * priceOfr) ) {

        	tknsBuyAppr = safeDiv( msg.value , priceOfr );
        }
        // calc return payment to buyer
        uint retPayment = 0;
        if(  msg.value > 0 ){
            retPayment = safeSub( msg.value , tknsBuyAppr * priceOfr);
        }

      msgSndr[msg.sender] = amountTkns;               
        
        // check buyer booking at exchange
        Exchg em = Exchg(_getExchgAddr()); 

        bool sucsBkgChk = false;
        if(tknsBuyAppr > 0){
	        sucsBkgChk = em.buy_Exchg_BkgChk(seller, amountTkns, priceOfr, msg.sender, msg.value); 
        }
        if(sucsBkgChk == false) tknsBuyAppr = 0;
        //

			msgSndr[msg.sender] = tknsBuyAppr;  
 
        	bool emUpdateSuccess;
       		(emUpdateSuccess) = em.updateSeller(seller, tknsBuyAppr, msg.sender, msg.value); 
        	require( emUpdateSuccess == true );
        
        //
        if(sucsBkgChk == true && tknsBuyAppr > 0){
      
	       // token transfer in this token contract

	        bool sucsTrTkn = _safeTransferTkn( seller, msg.sender, tknsBuyAppr);
	        require(sucsTrTkn == true);

	        // payment to seller        
	        bool sucsTrPaymnt;
	        sucsTrPaymnt = _safeTransferPaymnt( seller,  safeSub( msg.value , safeDiv(msg.value*em.getExchgComisnMulByThousand(),1000) ) );
	        require(sucsTrPaymnt == true );        
        }
    	// return payment to buyer 
        if( retPayment > 0 ) {
                
          bool sucsTrRetPaymnt;
          sucsTrRetPaymnt = _safeTransferPaymnt( msg.sender, retPayment );
          require(sucsTrRetPaymnt == true );
        }         
      msgSndr[msg.sender] = 0; 
        
        return true;
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
       
        require( caller == _getIcoAddr() || caller == _getExchgAddr() || caller == _getCsAddr() ); 
          //require(origin == tx.origin);          
        return(true, msgSndr[origin]);  
    }
//_________________________________________________________
//
    function viewSellOffersAtExchangeMacroansy(address seller, bool show) view public returns (uint sellersCoinAmountOffer, uint sellersPriceOfOneCoinInWEI, uint sellerBookedTime, address buyerWhoBooked, uint buyPaymentBooked, uint buyerBookedTime){

      if(show == true){

        Exchg em = Exchg(_getExchgAddr()); 
       
        ( sellersCoinAmountOffer,  sellersPriceOfOneCoinInWEI,  sellerBookedTime,  buyerWhoBooked,  buyPaymentBooked,  buyerBookedTime, ) = em.viewSellOffersAtExchangeMacroansy( seller, show) ; 

        return ( sellersCoinAmountOffer,  sellersPriceOfOneCoinInWEI,  sellerBookedTime,  buyerWhoBooked,  buyPaymentBooked,  buyerBookedTime);
      }
    }
//_________________________________________________________
//
		function viewCoinSupplyAndFunding(bool show) public view returns(uint totalSupplyOfCoinsInSeriesNow, uint coinsAvailableForSale, uint icoFunding){

		    if(show == true){
		      ICO ico = ICO( _getIcoAddr() );

		      ( totalSupplyOfCoinsInSeriesNow, coinsAvailableForSale, icoFunding) = ico.getAvlShares(show);

		      return( totalSupplyOfCoinsInSeriesNow, coinsAvailableForSale, icoFunding);
		    }
		}
//_________________________________________________________
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