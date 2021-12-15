// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./MultiManager.sol";

contract NalaDistribution is Multimanager {
    
    /* USINGS */
    using SafeMath for uint256;

    /* ENV VARIABLES */
    IERC20 private token;
    uint8 private tokenDecimals;
    uint256 private _virtualTotalSupply;
    string private _name;
    string private _symbol;
    uint256 private _deployTimeStamp;
    uint256 private _startFirstClaim;
    mapping(address => userAttributes) private _usersAmount; // variabile che memorizza l'ultimo claim e l'importo virtuale di ogni utente
    
    /* ----- STRUCTS ----- */
    struct userAttributes { 
        uint256 Amount;
        uint256 Redeem;
    }

    /* ----- EVENTS ----- */
    event UpdateUsersRewardsEvent(
        address indexed recipient, 
        uint256 amount, 
        uint256 timestamp
    );
    
    event ClaimEvent(
        address indexed sender, 
        uint256 amount, 
        uint256 timestamp
    );
    
    event RewardsCancellationEvent(
        address indexed recipient, 
        uint256 amount, 
        uint256 lastRedeem,
        uint256 timestamp
    );

    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );

    /* ----- CONSTRUCTOR ----- */
    constructor (IERC20 _token, uint8 _decimalsToken){
        token = _token;
        _deployTimeStamp = block.timestamp;
        //_startFirstClaim = block.timestamp + 60 days; // PRODUZIONE - Variabile di produzione che permette il claim solo se la data attuale è superiore ai 2 mesi dal deploy 
        _startFirstClaim = 1639573200; // DEV 15-12-2021 13.00 GMT 
        _name = "Nala Distribution";
        _symbol = "NALA";
        tokenDecimals = _decimalsToken;
    }

    /* ----- FUNCTIONS ----- */
    /* Funzioni di Lettura pubbliche */
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view returns (uint256) { // Il TOTALSUPPLY dei NALA virtualizzati agli utenti e non ancora Clammati o Azzerati
        return _virtualTotalSupply;
    }

    function decimals() public view returns (uint8) {
        return tokenDecimals; // decimali del token
    }

    function getBalance(address owner) public view returns(uint256, uint256){ // Restituisce il balance Virtuale dell'utente e la data dell'ultimo claim effettuato
        return (_usersAmount[owner].Amount, _usersAmount[owner].Redeem);
    }

    function tokenBalanceInside() public view returns(uint256){ // Restituisce il balance reale di token all'interno del contratto
        return (token.balanceOf(address(this)));
    }

    function isClaimAllowed(address account) public view returns(bool){
        uint256 dateTime = block.timestamp;
        (uint256 amount, uint256 lastRedeem) = (_usersAmount[account].Amount, _usersAmount[account].Redeem);
        if(dateTime < _startFirstClaim) return false;
        // if(dateTime < (lastRedeem + 7 days)) return false; // PRODUZIONE
        if(dateTime < (lastRedeem + 3600)) return false; // DEV ogni ora
        if(amount <= 0) return false;

        return true;
    }

    /* Funzioni di Scrittura Admin */
    function _addUserBalance(address account, uint256 amount) external onlyManager returns(uint256, uint256){
        _usersAmount[account].Amount += amount;
        _virtualTotalSupply += amount;

        emit Transfer(address(0), account, amount);
        emit UpdateUsersRewardsEvent(account, amount, block.timestamp);
        return (_usersAmount[account].Amount, _usersAmount[account].Redeem);
    }

    /* FUNZIONI DI TRASFERIMENTO DAL CONTRATTO STESSO VERSO ALTRI INDIRIZZI DI BNB, QUESTO E TUTTI GLI ALTRI TOKENS ERC20 */
    function _transferBNB(address payable _to, uint256 amount) public onlyManager{
        _to.transfer(amount);
    }

    function _transferThisToken(address payable _to, uint256 amount) public onlyManager{
        token.transfer(_to, amount);
    }

    function _transferAllTokensContracts(ERC20 _token, address payable _to, uint256 amount) public onlyManager{
        _token.transfer(_to, amount);
    }

    /* Funzioni di Scrittura Pubbliche */
    function Claim() public returns(uint256, uint256){
        uint256 dateTime = block.timestamp;
        uint256 contractBalanceOf = token.balanceOf(address(this));
        (uint256 amount, uint256 lastRedeem) = (_usersAmount[msg.sender].Amount, _usersAmount[msg.sender].Redeem);
        require(dateTime >= _startFirstClaim, "Claims cannot be executed at the moment");
        //require(dateTime >= (lastRedeem + 7 days), "You have to wait 7 days from the last Claim"); // PRODUZIONE
        require(dateTime >= (lastRedeem + 3600), "You have to wait 1 days from the last Claim"); // DEV un claim ogni ora
        require (amount > 0, "The balance must be greater than zero");
        
        // se datetime > 366 giorni dall'ultimo redeem devi farmi la cancellazione del balance utente e farmi un return
        if(NalaDistributionLib.isLastClaimOverYear(lastRedeem, dateTime, _startFirstClaim)){ // se true deve cancellare il balance
            _virtualTotalSupply -= amount;
            _usersAmount[msg.sender].Amount = 0;
            _usersAmount[msg.sender].Redeem = dateTime;

            emit Transfer(msg.sender, address(0), amount);
            emit RewardsCancellationEvent(msg.sender, amount, lastRedeem, dateTime);
            return (0, lastRedeem);
        }
        else { // se invece è negativo si puo' passare al trasferimento dei fondi
            require(contractBalanceOf >= amount, "The contract does not have enough liquidity to pay");
            _virtualTotalSupply -= amount;
            _usersAmount[msg.sender].Amount = 0;
            _usersAmount[msg.sender].Redeem = dateTime;
            
            token.transfer(msg.sender, amount);

            emit Transfer(msg.sender, address(0), amount);
            emit ClaimEvent(msg.sender, amount, dateTime);
            return (amount, lastRedeem);
        }        
    }

    
}



library NalaDistributionLib {
    using SafeMath for uint256;
    
    function isLastClaimOverYear (uint256 lastClaim, uint256 dateTimeNow, uint256 startFirstClaim) internal pure returns(bool){ // true deve cancellare i balance utente
        if (lastClaim == 0){ // se il lastClaim è 0, non è mai stato fatto, devo solo controllare che non sia passato un anno dalla prima data utile di redeem
            //if(dateTimeNow >= (startFirstClaim + 366 days) ) return true; // PRODUZIONE
            if(dateTimeNow >= (startFirstClaim + 1 days) ) return true; // DEV remove ogni giorno
            return false;
        }
        else { // se il claim è già stato fatto in precedenza, devo controllare che non siano passati 366 giorni dall'ultimo Claim
            //if(dateTimeNow >= (lastClaim + 366 days) ) return true; // PRODUZIONE
            if(dateTimeNow >= (lastClaim + 1 days) ) return true; // DEV remove ogni giorno
            return false;
        }
    }
    
}