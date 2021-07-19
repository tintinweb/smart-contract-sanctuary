/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: MIT
// JUL BLOCKTEAM PACA 2021 
pragma solidity ^0.8.0;

//  REM :
//  timed crowdsale ?       => oui 
//  refundable ?            => oui, a partir du tokenContract par le Gnosis/admin?
//  not minted              => 
//  capped by the tokenIco supply (constructor)
//  Ajouter FallBack sur receive qui call buyTokens

/*
    USAGE
        * deploy a ERC20Token 
        * create / launch Safe Wallet for putting ICO Token supply and ICO funds 
        * send ICO Token supply to this Wallet Safe (using setIcoSupply() )
        * deploy ENYTokenICO
        * Wallet Safe must approve ICO Contract for supply amount
        * use launchIco function 
            => 
*/


// Interface ERC20
interface IToken {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function decimals() external returns (uint256);
}



contract ENYTokenICO_test {
    address payable admin;              // Wallet Safe

    uint256  public tokensIcoTimeOut;   // date heure limite ( en s/01011970)
    uint256  public tokenIcoStart;      // timestamp lancement ICO 
    uint256  public tokenPrice;         // prix token 
    uint256  public tokensSold;         // tokens vendu
    uint256  public tokenLeft;          // tokens dispo pour vente
    uint256  public tokenIcoSupply;     // totalsupply pour info
    address  public tokenContract;      // Token Contract address
    uint256  public tokenDecimals;      // Token Contract decimals
    uint256  public IcoBalance;        // ICO balance
    
    
    

    
//    mapping(address => uint) public  IcoBalance;                                 // Getter for ICO balance (?)
    
    
//    uint256  public garb;                                                     // display garbage data for testing purpose

    enum icoStates {WAITING, STARTED, ENDED, STOPPED}
    icoStates public icoState = icoStates.WAITING;  // statut ICO 
    
    struct Buyers {
        address addressBuyer;
        uint256 tokenOrder;
        uint256 totalPaid;
    }
    Buyers[] icoInvestors;                                                      // investors data 
    
    address payable refundBuyer;
    

    /*  ************************************************************************
        EVENTS For the Front
    */
    event Sell(address _buyer, uint256 _tokens, uint256 _totalBalance, uint256 _totalInvestor, uint256 _tokenLeft);

    /*  ************************************************************************
        modifyer 
    */
    modifier onlyAdmin {                                                        // Function that can be actioned only by the admin
        require(msg.sender == admin," Contract Admin use Only");
        _;
    }


    /*  ************************************************************************
        Launching ICO 
    */
        function launchIco (uint256 _icoStart, 
                            //uint256 _icoDurationMinute,                        // test only
                            uint256 _icoDurationDay,
                            uint256 _tokenPrice, uint256 _tokenIcoSupply, 
                            address payable _walletSafe, address _tokenContract)  external {   
                        
        require(icoState == icoStates.WAITING, "Sorry, this ICO stage already started");                                
        // voir avec Gnosis pour admin de ICO
        admin           = _walletSafe;
        tokenPrice      = _tokenPrice;
        tokenIcoSupply        = _tokenIcoSupply;
        tokensIcoTimeOut= _icoStart + multiply(_icoDurationDay,86400);
        //tokensIcoTimeOut= _icoStart + multiply(_icoDurationMinute,60);         // en minutes pour les tests
        tokenIcoStart   = _icoStart;
        tokenLeft       = tokenIcoSupply;
        tokenContract   = _tokenContract;
        tokenDecimals   = decimalsToken(_tokenContract);

        setIcoStatus();
    }


    /*  ************************************************************************
        ACHAT DE TOKEN par saisie nb de Token
    */
/*    
    function buyTokens(uint256 _numberOfTokens) payable external{

        setIcoStatus();

        require(_numberOfTokens >0,"Sorry, no token in your basket");
        require(icoState == icoStates.STARTED, "Sorry, this ICO stage is currently closed");

        uint256 totalNet;
        totalNet = multiply(_numberOfTokens,tokenPrice);
        
        // test si sufficient funds (confiance en metamask et autres?=>non)
        require(address(msg.sender).balance >= totalNet, "Sorry, insufficient funds...");
        require(msg.value >= totalNet, "Sorry, no sufficient value ");
        
        // liraison du total demandé seulement ou du max disponible si demande > ?
        require(tokenLeft >= _numberOfTokens, "Not enough token to sell !");

        icoInvestors.push(Buyers(msg.sender, _numberOfTokens, msg.value));
        tokensSold += _numberOfTokens;
        tokenLeft -= _numberOfTokens;
        
        
        // transfer vers le buyer (non remboursable)
        withDraw(_numberOfTokens);
        

        // Event pour le front
        emit Sell(msg.sender, _numberOfTokens, address(this).balance, icoInvestors.length, tokenLeft);
    }
*/    
    /*  ************************************************************************
        ACHAT DE TOKEN par la value
    */
    function buyAmountTokens() payable public{
        uint256 numberOfTokens;
        uint256 totalNet;
        uint256 tropPercu;
        
        setIcoStatus();                                                                                 // ctrl et upate ico status
        require(icoState == icoStates.STARTED, "Sorry, this ICO stage is currently closed");
        require(tokenLeft > 0, "No more token to sell !");
        
        numberOfTokens = msg.value / tokenPrice;                                                        // calcul nb de token en fonction de la value
        if (numberOfTokens > tokenLeft) { numberOfTokens = tokenLeft;}                                  // livraison des tokens disponibles
        
        totalNet = multiply(numberOfTokens,tokenPrice);                                                 // calcul du totalNet reel -> rbst du trop percu
        require(msg.value >= totalNet, "Sorry, no sufficient funds ");
        tropPercu = msg.value - totalNet;
        if (tropPercu > 0) {                                                                            // trop percu : refund de la difference
            refundBuyer = payable(msg.sender);
            refundBuyer.transfer(tropPercu); 
        }

        icoInvestors.push(Buyers(msg.sender,numberOfTokens, msg.value));
        tokensSold += numberOfTokens;
        tokenLeft -= numberOfTokens;
        
        withDraw(numberOfTokens);                                                                       // transfer vers le buyer (non remboursable)
        IcoBalance += totalNet;
        
        emit Sell(msg.sender, numberOfTokens, address(this).balance, icoInvestors.length, tokenLeft );  // Event pour le front
    }


    

    /*  ************************************************************************
        withdraw
    */
        function withDraw(uint256 _numberOfTokens) internal{
//            garb =  IToken(tokenContract).balanceOf(msg.sender);
            transferTokenFrom(tokenContract, admin, msg.sender, _numberOfTokens*(10**18));
    }

    /*  ************************************************************************
        MAJ status ICO 
        mettre en modifyer => buyTokens
    */
    function setIcoStatus () internal{
        require (icoState != icoStates.STOPPED, "ICO stage STOPPED");
        if (tokensIcoTimeOut <= block.timestamp) { icoState = icoStates.ENDED; }
        else if (tokenIcoStart <= block.timestamp) { icoState = icoStates.STARTED; }
    }

     /*  ************************************************************************
        appel interface sur Token ERC20 
    */
    function transferTokenFrom(address _tokenContract, address _from, address _to, uint256 _amount) internal returns (bool){
            IcoBalance = balanceToken(_tokenContract);
            return IToken(_tokenContract).transferFrom(_from, _to, _amount);
    }
    function transferToken(address _tokenContract, address _to, uint256 _amount) internal returns (bool){
            return IToken(_tokenContract).transfer(_to, _amount);
    }
    function balanceToken(address _tokenContract) internal view returns (uint256){
            return IToken(_tokenContract).balanceOf(address(this));
    }
    function decimalsToken(address _tokenContract) internal returns (uint256){
            return IToken(_tokenContract).decimals();
    }


    /*  ************************************************************************
        FORCE FIN ICO (MANUELLEMENT)
    */
    function endSale() public payable{
        require(msg.sender == admin);
        require(icoState != icoStates.STOPPED, " ICO already STOPPED ...");

        // change state before transfer (anti re entrance)
        // Just transfer the balance to the admin
        // on peut modifier le TimeOut a block.timestamp
        icoState = icoStates.STOPPED;
        admin.transfer(address(this).balance);                                      // transfer de la balance vers le Wallet Safe
        IcoBalance = address(this).balance;                          // update balance ICO contract
                                                                                    // AJOUTER EVENT SUR ENDSALE        
    }

     /*  ************************************************************************
        Investisseurs de l'ICO 
    */
    function getInvestors() public view onlyAdmin returns (Buyers[] memory) {
        return (icoInvestors);
   }

     /*  ************************************************************************
        Safe MULT 
    */
    function multiply(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /*  ************************************************************************
        FallBack & receive
    */
    fallback() external payable { 
        buyAmountTokens(); 
    }
    receive() external payable { 
        buyAmountTokens(); 
    }
 
    
}