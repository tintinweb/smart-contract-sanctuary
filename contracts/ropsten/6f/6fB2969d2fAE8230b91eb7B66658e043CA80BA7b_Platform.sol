/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.8.0;

contract Platform {
    
    //VARIABLES
    uint256 num;
    mapping (uint256 => uint256) private idFromCode;
    mapping (uint256 => address) private summ1FromId;
    mapping (uint256 => address) private summ2FromId;
    mapping (uint256 => bool) private initiated;
    
    struct Duel {
        uint256 id;
        address summ1;
        address summ2;
        bool isStarted;
        bool isEnded;
    }
    
    Duel[] public duels;
    
    //FUNCTIONS
    function create(uint256 _code) external {
        //Definit l'id du duel (toujours un nombre pair)
        uint256 id = num;
        num += 1;
        
        //Envoie les tokens sur le contrat
        
        //Crée un duel (en attente du 2e joueur)
        duels.push(Duel(id, msg.sender, 0x000000000000000000000000000000000000dEaD, false, false));
        
        //Variables de traitement
        idFromCode[_code] = id;
        summ1FromId[id] = msg.sender;
        initiated[id] = true;
    }
    
    function subscribe(uint256 _code) external {
        //Trouve l'id du duel à partir du code
        uint256 id = idFromCode[_code];
        
        //Vérifie que le duel a bien été créé
        require(initiated[id] == true, "This duel does not exist");
        
        //Envoie les tokens sur le contrat
        
        //Inscription au duel
        duels.push(Duel(id, summ1FromId[id], msg.sender, true, false));
        
        //Variables de traitement
        summ2FromId[id] = msg.sender;
    }
    
    function close(uint256 _code) external {
        //Trouve l'id du duel à partir du code
        uint256 id = idFromCode[_code];
        
        //Vérifie que l'utilisateur est bien le créateur du duel
        require(msg.sender == summ1FromId[id], "You are not the creator of the duel");
        
        //Fermeture du duel
        duels.push(Duel(id, summ1FromId[id], summ2FromId[id], true, true));
    }
    
}