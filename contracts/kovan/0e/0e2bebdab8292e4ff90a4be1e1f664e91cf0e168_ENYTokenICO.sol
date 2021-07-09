/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin-solidity/contracts/math/SafeMath.sol";

//  REM :
//  timed crowdsale ?       => oui 
//  refundable ?            => oui, a partir du tokenContract par le Gnosis/admin?
//  not minted              => transfer tokens par tokenContract by gnosis/admin fin ICO
//  capped by the tokenIco supply (constructor)
//  


contract ENYTokenICO {
    address payable admin;
//    address admin;
    uint256  public tokensIcoTimeOut;   // date heure limite ( en s/01011970)
    uint256  public tokenIcoStart;      // timestamp lancement ICO 
    uint256  public tokenPrice;         // prix token 
    uint256  public tokensSold;         // tokens vendu
    uint256  public tokenLeft;          // tokens dispo pour vente
    uint256  tokenIco;                  // totalsupply
    
    uint256  public garb;   // display garbage data 

    enum icoStates {WAITING, STARTED, ENDED, STOPPED}
    icoStates public icoState = icoStates.WAITING;  // statut ICO 
    
    struct Buyers {
        address addressBuyer;
        uint256 tokenOrder;
        uint256 paid;
    }
    Buyers[] icoInvestors;                                                      // pour gnosis : transfer a la fin ICO des tokens 
    

    /*  ************************************************************************
        EVENTS  
    */
    event Sell(address _buyer, uint256 _tokens, uint256 _balance, uint256 _totalInvestor);
    // Verifier liste events à transmettre à Regis
    
    
    /*  ************************************************************************
        constructor 
    */
        constructor(uint256 _icoStart, uint256 _icoDurationDay, uint256 _tokenPrice, uint256 _tokenIcoSupply, address payable _walletSafe)   {
//        constructor(uint256 _icoStart, uint256 _icoDurationMinute, uint256 _tokenPrice, uint256 _tokenIcoSupply, address payable _walletSafe)   {    
        // voir avec Gnosis pour admin de ICO
        admin           = _walletSafe;
        tokenPrice      = _tokenPrice;
        tokenIco        = _tokenIcoSupply;
        tokensIcoTimeOut= _icoStart + multiply(_icoDurationDay,86400);
// en minutes pour les tests
//        tokensIcoTimeOut= _icoStart + multiply(_icoDurationMinute,60);
        tokenIcoStart   = _icoStart;
        tokenLeft       = tokenIco;
        
//        icoState = icoStates.WAITING;

        icoStatus();
    }


    /*  ************************************************************************
        ACHAT DE TOKEN 
    */
    function buyTokens(uint256 _numberOfTokens) payable external{
        // QQue soit la value du sender 
        // on ne donne que le nb de token demandé 
        // ou refund du delta ?
        // si demande > tokenLeft, accepter pour la partie dispo?
        // dans ce cas les require sont a tester apres et faire refund ?
        icoStatus();

        require(_numberOfTokens >0,"Sorry, no token in your basket");
        require(icoState == icoStates.STARTED, "Sorry, this ICO stage is currently closed");

        uint256 totalNet;
        totalNet = multiply(_numberOfTokens,tokenPrice);
        
        // test si sufficient funds (confiance en metamask et autres?=>non)
        require(address(msg.sender).balance >= totalNet, "Sorry, insufficient funds...");
        require(msg.value >= totalNet, "Sorry, no sufficient value ");
        require(tokenLeft >= _numberOfTokens, "Not enough token to sell !");

        icoInvestors.push(Buyers(msg.sender,_numberOfTokens, msg.value));
        
        tokensSold += _numberOfTokens;
        tokenLeft -= _numberOfTokens;
        
        
        // Voir pour faire transfer vers le Wallet directement... ?
        // mais alors gestion refoundable plus complexe.

        // Event pour le front
        emit Sell(msg.sender, _numberOfTokens, address(this).balance, icoInvestors.length );
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
        admin.transfer(address(this).balance);
        
    }
    
     /*  ************************************************************************
        Balance de l'ICO 
    */
    function getBalance() public view returns (uint) {
        require(msg.sender == admin);
        return (address(this).balance);
   }

     /*  ************************************************************************
        Investisseurs de l'ICO 
    */
    function getInvestors() public view returns (Buyers[] memory) {
        require(msg.sender == admin);
        return (icoInvestors);
   }

    /*  ************************************************************************
        MAJ status ICO 
        mettre en modifyer => buyTokens
    */
    function icoStatus () internal{
        garb = block.timestamp;
        require (icoState != icoStates.STOPPED, "ICO stage STOPPED");
        if (tokensIcoTimeOut <= block.timestamp) { icoState = icoStates.ENDED; }
        else if (tokenIcoStart <= block.timestamp) { icoState = icoStates.STARTED; }
        
    }


     /*  ************************************************************************
        Safe MULT 
    */
    function multiply(uint a, uint b) internal pure returns (uint) {
//        require(y == 0 || (z = x * y) / y == x);
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

}