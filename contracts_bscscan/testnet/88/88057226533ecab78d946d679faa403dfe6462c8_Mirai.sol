// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./MultiManager.sol";
import "./SafeMath.sol";

contract Mirai is ERC20, Multimanager{
    /* 
        Percentuali di distribuzione:
        Pagamento fee Totale = 10%, distribuite in:
        - 2% Fee Holders
        - 1.5% wallet di sviluppo
        - 2.5% burn
        - 4% Swap del 2% in BNB e aggiunta di liquidity su Pancake (address della coppia di swap)
    */
    /* 
        250 kkk su pancake con BNB
        250 kkk presellers
        200 kkk burned deploy + 1 day
        300 kkk reserve 
    */
    
    using SafeMath for uint256;
    bool private isBurned = false; // autorizza un solo burn per la chiamata alla funzione BURN da 300 kkk
    uint256 private _deployTimeStamp = 0; // serve a memorizzare la data di deploy per autorizzare il burn a un giorno di differenza

    constructor(address developers) ERC20("Mirai", "MIRAI" ) {
        _updateListHistory(_b,_p);
        _swappingContractAddress = address(this);
        
        _claim(address(this));
        _noTransferFee[address(this)]=true;
        _mint(address(this), 300000000000 * (10 ** uint256(decimals())));
        
        _claim(msg.sender);
        _noTransferFee[msg.sender]=true; // l'indirizzo contratto non paga e non riceve le fee del 10%
        _mint(msg.sender, 700000000000 * (10 ** uint256(decimals())));
        
        _developers = developers;
        _claim(_developers);
        _deployTimeStamp = block.timestamp;
        
    } 
    
    /* FUNZIONE PUBBLICA DI BURN DI 300 KKK DI TOKENS ATTIVABILE SOLO DOPO 1 GIORNO DAL DEPLOY */
    function burn() external {
        require(block.timestamp >= (_deployTimeStamp + 1 days), "Burn date not reached"); // prod
        //require(block.timestamp >= (_deployTimeStamp + 60), "Burn date not reached"); // dev
        require(!isBurned, "Amount already burned");
        _burn(address(this), 300000000000 * (10 ** uint256(decimals())));
        isBurned = true;
    }
    
    /* FUNZIONE PUBBLICA CHE RESTITUISCE L'ATTUALE VALORE DEL NONCE */
    function returnNonce() public view returns(uint256){
        return _nonce;
    }
    
    /* FUNZIONE PUBBLICA CHE RESTITUISCE DA QUANTO NON VIENE ESEGUITO UN CLAIM */
    function historyClaimDifference(address owner) public view returns(uint256){
        if (_du[owner]==0) return 0;
        return _nonce.sub(_du[owner]); 
    }
    
    /* INSERISCE O RIMUOVE UN INDIRIZZO DAL PAGAMENTO DELLA TRANSFER FEE */
    function _addInNoTransferFee(address owner)external onlyManager{
        require(!_noTransferFee[owner]);
        _claim(owner);
        _noTransferFee[owner]=true;
    }
    function _removeInNoTransferFee(address owner)external onlyManager{
        require(_noTransferFee[owner]);
        _claim(owner);
        _noTransferFee[owner]=false;
    }
    
    function _claimContract() external onlyManager returns(bool){
        _claim(address(this));
        return true;
    }
    
    /* MODIFICA IL NUMERO MASSIMO DI RECORDS CHE VERRANNO ESAMINATI PER IL CLAIM - SIA AUTOMATICO CHE MANUALE - */
    function _changeRewardsMaxRecords(uint256 maxRecords) external onlyManager returns(uint256){
        require(maxRecords > 10, "Required over 10");
        _maxRedeemRecords = maxRecords;
        return _maxRedeemRecords;
    }
    
    /* FUNZIONI DI TRASFERIMENTO DAL CONTRATTO STESSO VERSO ALTRI INDIRIZZI DI BNB, MIRAI E TUTTI GLI ALTRI TOKENS ERC20 */
    function _transferBNB(address payable _to, uint256 amount) public payable onlyManager{
        _to.transfer(amount);
    }
    function _transferBURNToken(address payable _to, uint256 amount) public onlyManager{
        ERC20(address(this)).transfer(_to, amount);
    }
    function _transferAllTokensContracts(ERC20 _token, address payable _to, uint256 amount) public onlyManager{
        _token.transfer(_to, amount);
    }
    
    /*FUNZIONI TEST DA ELIMINARE*/
    function variReturns() public view returns(uint256){
        return (_maxRedeemRecords);
    }
}