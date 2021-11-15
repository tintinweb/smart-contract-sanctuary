// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./KICharacter.sol";

import "./Knowledge.sol";

import "./KiToken.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TrainingFarm is Ownable {
    using SafeMath for uint256; 

    constructor(KICharacter _KICharacter,Knowledge  _knowledgeContract,KiToken  _kiTokenContract){
        characterContract=_KICharacter;
        knowledgeContract=_knowledgeContract;
        kiTokenContract=_kiTokenContract;
    }

    KICharacter characterContract;
    Knowledge knowledgeContract;
    KiToken kiTokenContract;

    address devAddress;
    // cost for Defrost the technique;
    uint256 payDefrost;

    //LVL => Amount Characters
    mapping (uint256=>uint256) private countCharacterByLevel;
    
    // LVL most  higth   
    uint256 private HIGHEST_LEVEL;
    // Level with most Characters
    uint256 private LEVEL_WITH_MORE_CHARACTERS;



    struct CharacterPool{
        uint256[] idTechniques;
        uint256 numberBlock;
    }

    struct InfoTechnique{
        uint256 startFrozen;
        uint256 startFarm;
        uint256 countUses;
    }
    //idCharacter
    mapping (uint256=>CharacterPool) characterPool;
    //id Techniques => count uses
    mapping (uint256=>InfoTechnique) infoTechniques;
    //idCharacter => owner
    mapping (uint256=>address) ownerCharacter;
    //idTechnique => owner
    mapping (uint256=>address) ownerTechnique;
    //id Technique => id character
    mapping (address=>uint256[]) ownerOfCharacters;
    mapping (uint256=>uint256) characterByTechniques;
    
    function addPool( 
        uint256 idCharacter,
        uint256[] memory idTechniques) public returns(uint256 success) {
        CharacterPool memory cPool;
        uint256 bNumber=block.number;
        success=0;

        if(ownerCharacter[idCharacter] == address(0) ){
            characterContract.transferFrom(_msgSender(),address(this),idCharacter);
            ownerCharacter[idCharacter]=_msgSender();
            ownerOfCharacters[_msgSender()].push(idCharacter);
            uint256 lvl=characterContract.getCurrentLevel(idCharacter);
            countCharacterByLevel[lvl]++;
            if((countCharacterByLevel[LEVEL_WITH_MORE_CHARACTERS] < countCharacterByLevel[lvl])){
                LEVEL_WITH_MORE_CHARACTERS=lvl;
            }
        }

        if((idTechniques.length > 0)){
            uint256 amountUses=0;
            cPool.idTechniques= new uint256[](idTechniques.length);
            for (uint256 index = 0; index < idTechniques.length; index++) {
                knowledgeContract.transferFrom(_msgSender(),address(this),idTechniques[index]);
                cPool.idTechniques[index]=(idTechniques[index]);
                characterByTechniques[idCharacter]=idTechniques[index];
                ownerTechnique[idTechniques[index]]=_msgSender(); 
                amountUses=knowledgeContract.getAmountUses(idTechniques[index]);
                success++;
                if(amountUses > infoTechniques[idTechniques[index]].countUses){
                    infoTechniques[idTechniques[index]].startFarm=bNumber;
                }                           
            }
        }
        //hacer un metodo que calcule si tiene recompensa y actualice los atributos del pool llamarlo aca
        cPool.numberBlock=bNumber;
        characterPool[idCharacter]=(cPool);

        return success;
    }

    function withdrawPool(uint256 idCharacter,uint256[] memory idTechniques) public {
        claimPool(idCharacter);
        emergencyWithdraw(idCharacter, idTechniques);            
    }

    //withdraw NFT without reward
    function emergencyWithdraw(uint256 idCharacter,uint256[] memory idTechniques) public {
        
         if(idCharacter > 0){
             require(ownerCharacter[idCharacter] == _msgSender());
            _blankValuePool(idCharacter);

            ownerCharacter[idCharacter]=address(0);
            characterContract.transferFrom(address(this),_msgSender(),idCharacter);

            for (uint256 j = 0; j < ownerOfCharacters[_msgSender()].length; j++) {
                if(ownerOfCharacters[_msgSender()][j] == idCharacter){
                    ownerOfCharacters[_msgSender()][j]=ownerOfCharacters[_msgSender()][ ownerOfCharacters[_msgSender()].length-1];
                    ownerOfCharacters[_msgSender()].pop();
                    break;
                }
            }
            idTechniques= new uint256[](characterPool[idCharacter].idTechniques.length);
             for (uint256 j = 0; j < idTechniques.length; j++) {
                 idTechniques[j]=characterPool[idCharacter].idTechniques[j];
            }            
        }

            for (uint256 index = 0; index < idTechniques.length; index++) {
                if(_msgSender() == ownerTechnique[idTechniques[index]]){
                    knowledgeContract.transferFrom(address(this),_msgSender(),idTechniques[index]);
                    ownerTechnique[idTechniques[index]]=address(0);

                    for (uint256 j = 0; j < characterPool[characterByTechniques[idTechniques[index]]].idTechniques.length; j++) {
                        if(characterPool[characterByTechniques[idTechniques[index]]].idTechniques[j] == idTechniques[index]){
                            characterPool[characterByTechniques[idTechniques[index]]].idTechniques[j]=characterPool[characterByTechniques[idTechniques[index]]].idTechniques[characterPool[characterByTechniques[idTechniques[index]]].idTechniques.length -1];
                            characterPool[characterByTechniques[idTechniques[index]]].idTechniques.pop();
                        }
                    }
                    characterByTechniques[idTechniques[index]]=0;
                }
            }
    }
    //antes de quitar un personaje 
    function _blankValuePool(uint256 idCharacter) internal{
        if(ownerCharacter[idCharacter] != address(0)){
            uint256 lvl=characterContract.getCurrentLevel(idCharacter);
            uint256 countMaxCharacter=0;
            uint256 lvlMaxCharacter=0;

            countCharacterByLevel[lvl]--;
            
        
            //encuentro el nuevo nivel de piso 
           for (uint256 index = 0; index <= HIGHEST_LEVEL; index++) {
               if(countCharacterByLevel[index] > countMaxCharacter){
                   countMaxCharacter=countCharacterByLevel[index];
                   lvlMaxCharacter=index;
               }
           }
            LEVEL_WITH_MORE_CHARACTERS=lvlMaxCharacter;

            //asigno el nuevo nivel maximo
            if((HIGHEST_LEVEL <= lvl) ){
                while((countCharacterByLevel[lvl] == 0)&&(lvl > 0 )){
                    lvl--;
                }
                HIGHEST_LEVEL=lvl;
            }
            
        }
       
    }


    function claimPool(uint256 idCharacter) public returns(uint256){
        //si dejo comentado cualquier puede reclamar pero el token siempre recibe el dueño del NFT
        // require(ownerCharacter[idCharacter] == _msgSender());

        (uint256 reward,uint256 kiRest,uint256[] memory usesTechnique) = pendingReward(idCharacter);

        kiTokenContract.mint(ownerCharacter[idCharacter],reward);
        //solo quema el KI si es menor al nivel mas algo o si el nivel mas alto tiene mas de 10 NFT Character.
        if((characterContract.getCurrentLevel(idCharacter)< HIGHEST_LEVEL ) || ( countCharacterByLevel[HIGHEST_LEVEL] > 10)){
             characterContract.spendKi(idCharacter,kiRest);
        }
        
        uint256 blockNumber=block.number;
        uint256 amountFinish=0;
        for (uint256 index = 0; index < usesTechnique.length; index++) {

            if(usesTechnique[index]>0){
                uint256 idTech=characterPool[idCharacter].idTechniques[index];
                uint256 amountUses=knowledgeContract.getAmountUses(idTech);

                if(amountUses <= infoTechniques[idTech].countUses.add(usesTechnique[index])){
                    infoTechniques[idTech].countUses=amountUses;
                    infoTechniques[idTech].startFrozen=blockNumber;

                }else{
                    amountFinish=knowledgeContract.getAmountFinish(idTech);
                    infoTechniques[idTech].countUses=infoTechniques[idTech].countUses.add(usesTechnique[index]);
                    //new block started equals the amount for farm finish  multiplicate the amount repeat.
                    infoTechniques[idTech].startFarm=infoTechniques[idTech].startFarm.add(usesTechnique[index].mul(amountFinish));
                }
                
                
            }
        }
        return reward;
    }




    //quitar el quemado de  KI por BLocque, no tiene el ca clulo se complica
    //auxRepeat the amount repeat the NFT Technical by  INDEX;
    function pendingReward(uint256 idCharacter) view public returns (uint256 reward,uint256 kiRest,uint256[] memory auxRepeat) {
        uint256 lengthTech=characterPool[idCharacter].idTechniques.length;
        //use to the code finish

        if(lengthTech == 0){
            return  (0,0,auxRepeat);
        }   
         uint256 kiNow= kiCurrent(idCharacter);
        
        if(kiNow == 0){
            return  (0,0,auxRepeat);
        }
        
        uint256 __id=idCharacter;
        (uint256 currentLevel,
        ,,,uint256 baseReward,,,)=characterContract.getCharacterFull(__id);
        
        uint256[] memory profitArray = new uint256[](lengthTech);
        uint256[] memory repeatArray =new uint256[](lengthTech);
        uint256[] memory burnKiArray=new uint256[](lengthTech);
        uint256 kiResta=kiNow;
        uint256 totalRepeat=0;

        for (uint256 index = 0; index < lengthTech; index++) {
            (uint256 startFrozen,uint256 amountUses)=isFronzen(characterPool[__id].idTechniques[index]);
            // if((infoTechniques[characterPool[__id].idTechniques[index]].startFrozen.add(knowledgeContract.getAmountFronzen(characterPool[__id].idTechniques[index])) >= bNumber )){
            if((startFrozen > 0 ) && (startFrozen <= infoTechniques[characterPool[__id].idTechniques[index]].startFarm )){
            profitArray[index]=0;repeatArray[index]=0;burnKiArray[index]=0;
            }else{
            //nuevo
            repeatArray[index]=amountUses;
            //farmeó antes de congelarse.
            (profitArray[index],/*repeatArray[index],*/burnKiArray[index])=profitByTechnique(characterPool[__id].idTechniques[index]);             
             if((kiNow < burnKiArray[index])||(profitArray[index] == 0)){
                profitArray[index]=0;repeatArray[index]=0;burnKiArray[index]=0;
             }else{
                kiNow=kiNow.sub(burnKiArray[index]);
                totalRepeat=totalRepeat.add(repeatArray[index]);
             }
            }
          
          
           
        }
        uint256 reward2=0;
        kiNow=kiResta;
        //controlar si anda
        //calcula la cantidad exacta de recompensa que se optiene gastando KI
        auxRepeat= new uint256[](repeatArray.length);
        while((kiNow>0) && (totalRepeat>0)){
            for (uint256 index = 0; index < profitArray.length; index++) {
                if((repeatArray[index] > 0)&&(kiNow >= burnKiArray[index] )){
                    reward2= reward2.add(baseReward.mul(profitArray[index]));
                    kiNow= kiNow.sub(burnKiArray[index]);
                    repeatArray[index]--;
                    auxRepeat[index]++;
                    totalRepeat--;
                }
                
            }
        }

        reward2=reward2.div(knowledgeContract.getDiv());
        if(currentLevel < LEVEL_WITH_MORE_CHARACTERS){
            reward2= reward2.div(2);
        }
    return (reward2,kiResta.sub(kiNow),auxRepeat);
    }
    //reward= 
    function profitByTechnique(uint256 idTechnique/*,uint256 startFrozen*/) view public returns (uint256 profit,/*uint256 repeat,*/uint256 burnKi) {
    
        // uint256 currentBlock=block.number;
        // uint256 _amountUsesTechniques=0;

           (,
            ,
            ,
            uint256 _burnKi,
            uint256 _profit,
            /*uint256 amountUses*/,
            ,
            /*uint256 amountFinish*/,)= knowledgeContract.getTechnique(idTechnique);
            
            // if(amountUses <=  infoTechniques[idTechnique].countUses){
            //     return (0,0,0);
            // }
            // uint256 id=idTechnique;
            // uint256 count=currentBlock.sub(infoTechniques[id].startFarm);
            // //primero se farmeo y despues se congelo (tiene que pagar para descongelar)
            // if((startFrozen >= infoTechniques[idTechnique].startFarm) || ( startFrozen==0)){
            //     count= startFrozen.sub(infoTechniques[idTechnique].startFarm);                    
            // }else{
            //     //quiso farmear pero la tecnica esta congelada.
            //     return  (0,0,0);
            // }

            // while(count >= amountFinish ){
            //     count-=amountFinish;
            //     _amountUsesTechniques++;
            // }
        return (_profit,/*_amountUsesTechniques,*/_burnKi);
    }

    function kiCurrent(uint256 idCharacter) view public returns (uint256 ki) {
         ki=characterContract.getCurrentKi(idCharacter);
        return ki;
    }

    function upKi(uint256 idCharacter,uint256 amount,bool levelUp) public  returns(uint256 newAmountKi){
        require(ownerCharacter[idCharacter] == _msgSender());
        claimPool(idCharacter);
        //dificultad para subir de nivel segun las distancias que hay en la piramide calcular
        // es usado para calcular le porcentaje que hay que sumasr al costo total para subir de nivel.
        uint256 dificultEx=0;
       uint256 lvl=characterContract.getCurrentLevel(idCharacter);
       uint256 value=characterContract.getValueBaseKiBurnNewLevel(idCharacter);
       uint256 medLvl=HIGHEST_LEVEL.div(2);
       if(lvl>medLvl){ 
            if(HIGHEST_LEVEL.sub(lvl) == 0){
                dificultEx=value.mul(20).div(100);
            }else{
                dificultEx= value.mul(10).div(100);
            }
       }
       newAmountKi= characterContract.upKi(idCharacter,amount,dificultEx,levelUp);
       //se quema solo la cantidad que se usó.
       kiTokenContract.burnFrom(_msgSender(),newAmountKi);
        
    }

    //
    function isFronzen(uint256 idTechnique) public view returns(uint256 startFrozen,uint256 uses) {
        if(infoTechniques[idTechnique].startFrozen > 0){
            return (infoTechniques[idTechnique].startFrozen ,infoTechniques[idTechnique].countUses);
        }
        
        uses=infoTechniques[idTechnique].countUses;
        uint256 amountFinish=knowledgeContract.getAmountFinish(idTechnique);
        uint256 amountUses=knowledgeContract.getAmountUses(idTechnique);
        startFrozen=0;
        uint256 farmCurrent = block.number.sub(infoTechniques[idTechnique].startFarm);
        while((uses < amountUses) && (farmCurrent > 0)){
            if(farmCurrent >= amountFinish ){
                farmCurrent=farmCurrent.sub(amountFinish);
                //acumula la cantidad de bloques que se recorrieron.
                startFrozen=startFrozen.add(amountFinish);
            }else{
                farmCurrent=0;
            }
            uses=uses.add(1);
        }
        //el start comienza en un momento cuando se farmeaba y nuca se retiró cuando se congeló.
        //se supero la cantidad de usos que podia teener la tecnica
        if((uses >= amountUses)){
            //se obtiene exactamente el numero de bloque que empezo el startFrozen;
            startFrozen=startFrozen.add(infoTechniques[idTechnique].startFarm);
        }else{
            startFrozen=0;
        }
        return (startFrozen,uses);
    }

        function reduceFrozen(uint256 payment,uint256 idTechnique) public {
            require(payment == payDefrost);
            require(infoTechniques[idTechnique].startFrozen > 0);
            infoTechniques[idTechnique].startFrozen=  0;
            infoTechniques[idTechnique].countUses=0;
            infoTechniques[idTechnique].startFarm=  block.number;
            kiTokenContract.transferFrom(_msgSender(),devAddress,payment);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Operator.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Knowledge is ERC721Enumerable , ERC721Burnable, Operator {
    using SafeMath for uint256; 
    constructor () ERC721("KiTechnique","KIT")  {
       idToken=1;
    }
    
    uint256 DIV = 10**18;
    
    struct Technique{
        uint256 idRarity;
        string name;
        string description;
        // KI necessary for Farm;
        uint256 burnKi;
        // Charcater Reward*profit / DIV;
        uint256 profit;
        //amount uses before frozen it;
        uint256 amountUses;
        //amount blocks for frozen
        uint256 amountFronzen;
        // the amount block for finish and you can claim;
        uint256 amountFinish;
        // if permanen NFT is 0, only used for temporal NFT
        uint256 deadLine;
    }

    uint256 private idToken;
    //Index Technique => Technique
    Technique[] private techniques;
    // ID Token ==> Index Technique;
    mapping (uint256=>uint256)  private idTechniqueByTokenId;

    string[] private raritys;

    function getDiv() view public returns (uint256) {
        return DIV;
    }
    function getIdToken() view public returns (uint256) {
        return idToken;
    }

    function getRarity(uint256 _index) view public returns (string memory) {
        return raritys[_index];
    }
    function getLengthRaritys() view public returns (uint256) {
        return raritys.length;
    }

    function getIdTechniqueByTokenId(uint256 _idToken) view public returns (uint256) {
        return idTechniqueByTokenId[_idToken];
    }

      function getLengthTechniques() view public returns (uint256) {
        return techniques.length;
    }


    function getTechnique(uint256 id) view public returns ( 
        uint256 idRarity,
        string memory name,
        string memory description,
        uint256 burnKi,
        uint256 profit,
        uint256 amountUses,
        uint256 amountFronzen,
        uint256 amountFinish,
        uint256 deadLine ) {

        idRarity=techniques[id].idRarity;
        name=techniques[id].name;
        description=techniques[id].description;

        burnKi=techniques[id].burnKi;
        profit=techniques[id].profit;
        amountUses=techniques[id].amountUses;
        amountFronzen=techniques[id].amountFronzen;

        amountFinish=techniques[id].amountFinish;
        deadLine=techniques[id].deadLine;
    }

    function getTechniqueProfit(uint256 _id) view public returns (uint256 profit) {
        return techniques[_id].profit;
    }
    
    function getAmountUses(uint256 _id) view public returns (uint256 amountUses) {
        return techniques[_id].amountUses;
    }
    function getAmountFinish(uint256 _id) view public returns (uint256 amountFinish) {
        return techniques[_id].amountFinish;
    }
    function getAmountFronzen(uint256 _id) view public returns (uint256 amountFronzen) {
        return techniques[_id].amountFronzen;
    }

    function addRarity(string memory _name) public onlyOwner{
        bool exist=false;
        
        for (uint256 index = 0; index < raritys.length; index++) {
            if(keccak256(bytes(_name)) == keccak256(bytes(raritys[index]))){
                exist=true;
                break;
            }
        }
        require(!exist);
        raritys.push(_name);
    }

    function addTechnique(uint256 idRarity,
        string memory name,
        string memory description,
        uint256 burnKi,
        uint256 profit,
        uint256 amountUses,
        uint256 amountFronzen,
        uint256 amountFinish,
        uint256 deadLine) public onlyOwner {
        Technique memory _technique= Technique(idRarity,name,description,burnKi,profit,amountUses,amountFronzen,amountFinish,deadLine);
       techniques.push(_technique);
    }

    function mint(address _to,uint256 _idTechnique,uint256 _amount) public onlyOwner{
        require(_idTechnique < techniques.length );
        for (uint256 index = 0; index < _amount; index++) {
            _safeMint(_to,idToken);
            idTechniqueByTokenId[idToken]=_idTechnique;
            idToken++;
        }
    }



    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable,ERC721) {
        super._beforeTokenTransfer(from,to,tokenId);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable,ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KiToken is ERC20Burnable,Ownable {

constructor () ERC20("KI Token","KI")  {
    
}    

function mint(address _to, uint256 _amount) public onlyOwner {
  _mint(_to,_amount);  
}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Operator.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract KICharacter is ERC721Enumerable , ERC721Burnable, Operator {
    using SafeMath for uint256; 


    constructor() ERC721("KICharacter","KIC"){
        CharacterRule memory cr;
        charactersRules.push(cr);
        operators[_msgSender()]=true;
        Character memory c;
        characters.push(c);
    } 



    uint256 private DIV= 10**18;

    struct CharacterRule{
        uint256 idRarity;
        string name;
        uint256 baseReward;
        //inner power that  KI expends; +innerPower == -KI expends
        // es un numero que ayuda a calcular la resistencia que tiene para gastar su ki
        // este numero ayuda que el ki del personaje no se gaste tan rapido, (mas raro mas resistencia tiene asi nos e gasta su KI rapido)
        uint256 innerPower;
        // for you can level up and calculate the new level cost  
        uint256 valueBaseKiBurnNewLevel;
        // KI Burn for seconds;
        uint256 kiBurnByBlock;

    }

    struct Character{
        uint256 idCharacterRule;
        //the size array is the level and the amount storage in each index is te KI Burn;
        uint256 currentLevel;
        // amount KI for you can FARM; if KI == 0 you can't FARM
        //KI is spend for the timestamp (time) and the NFT Training
        uint256 ki;
        //timestamp, the last rechargue the KI;
        uint256 lastUpKi;
    }

    string[] private raritys; 
    uint256 private valueKiBurnByTime;    

    CharacterRule[] private charactersRules;
    Character[] private characters;

    function getRaritys(uint256 _index) public view returns(string memory ) {
        return raritys[_index];
    }
    function getLengthRaritys() public view returns(uint256 ) {
        return raritys.length;
    }

    function getValueKiBurnByTime() public view returns(uint256 ) {
       return valueKiBurnByTime;
    }

    function getCharacterRule(uint256 _id) public view returns(uint256 idRarity,string memory name,uint256 baseReward,
        uint256 innerPower,uint256 valueBaseKiBurnNewLevel,uint256 kiBurnByBlock) {
       idRarity=charactersRules[_id].idRarity;
       name=charactersRules[_id].name;
       baseReward=charactersRules[_id].baseReward;
       innerPower=charactersRules[_id].innerPower;
       valueBaseKiBurnNewLevel=charactersRules[_id].valueBaseKiBurnNewLevel;
       kiBurnByBlock=charactersRules[_id].kiBurnByBlock;
    }

    function getLengthCharactersRules() public view returns(uint256 ) {
        return charactersRules.length;
    }
    

    function getBaseReward(uint256 _idCharacter) public view returns(uint256 baseReward) {
       return charactersRules[characters[_idCharacter].idCharacterRule].baseReward;
    }
    function getCurrentKi(uint256 _idCharacter) public view returns(uint256) {
       return characters[_idCharacter].ki;
    }
    function getCurrentLevel(uint256 _idCharacter) public view returns(uint256 currentLevel) {
       return characters[_idCharacter].currentLevel;
    }
    //valor para subir de nivel y valor para almacenar energia en el personaje
    function getValueBaseKiBurnNewLevel(uint256 _idCharacter) public view returns(uint256 valueBaseKiBurnNewLevel) {
       return charactersRules[characters[_idCharacter].idCharacterRule].valueBaseKiBurnNewLevel;
    }
    
    function getCharacterFull(uint256 _idCharacter) public view returns( uint256 currentLevel,
       uint256 ki,uint256 lastUpKi,string memory rarity,uint256 baseReward,uint256 innerPower,
        uint256 valueBaseKiBurnNewLevel,uint256 kiBurnByBlock) {

      CharacterRule memory _characterRule= charactersRules[characters[_idCharacter].idCharacterRule];
      Character memory _character= characters[_idCharacter];
       return (_character.currentLevel,_character.ki,_character.lastUpKi,raritys[_characterRule.idRarity],_characterRule.baseReward,_characterRule.innerPower,
       _characterRule.valueBaseKiBurnNewLevel,_characterRule.kiBurnByBlock  );
       
       }
       
    function getCharacter(uint256 _id) public view returns(   uint256 idCharacterRule,uint256 currentLevel,uint256 ki,uint256 lastUpKi) {
       idCharacterRule=characters[_id].idCharacterRule;
       currentLevel=characters[_id].currentLevel;
       ki=characters[_id].ki;
       lastUpKi=characters[_id].lastUpKi;
    }

      function getLengthCharacters() public view returns(uint256 ) {
        return characters.length;
    }



    function addRarity(string memory _name ) public onlyOperator {
        raritys.push(_name);
    }
    
    function editRarity(uint256 _index,string memory _name ) public onlyOperator {
        raritys[_index]=_name;
    }

    function editValueKiBurnByTime(uint256 _value) onlyOwner public {
        valueKiBurnByTime=_value;
    }

    function addCharacterRule(uint256 idRarity,string memory name, uint256 baseReward,
        uint256 innerPower,uint256 valueBaseKiBurnNewLevel,uint256 kiBurnByBlock) public onlyOperator {
        require(idRarity < raritys.length);
        charactersRules.push(CharacterRule( idRarity,name, baseReward,
         innerPower,  valueBaseKiBurnNewLevel, kiBurnByBlock));
    }

    function _addCharacter( Character memory _character) internal {
        require(_character.idCharacterRule < charactersRules.length );
        characters.push(_character);
    }



    //dificultad extra para subir de nivel.
    //retorna la cantidad de ki que no se uso.
    function upKi(uint256 idCharacter,uint256 newAmountKi,uint256 dificultEx,bool levelUp) public onlyOperator returns(uint256 ki) {
    uint256 restKi=newAmountKi;
    uint256 lvl=characters[idCharacter].currentLevel;
    uint256 valueBaseKiBurnNewLevel= charactersRules[characters[idCharacter].idCharacterRule].valueBaseKiBurnNewLevel;
       if(levelUp){
           uint256 kiTotal=characters[idCharacter].ki;
         
        while(newAmountKi != 0){
            if(valueBaseKiBurnNewLevel.sub(kiTotal) <= newAmountKi ){
                lvl++;
                valueBaseKiBurnNewLevel= valueBaseKiBurnNewLevel.add(valueBaseKiBurnNewLevel.mul(dificultEx).div(DIV));
                newAmountKi=newAmountKi.sub(valueBaseKiBurnNewLevel.sub(kiTotal));
                kiTotal=0;
            }else{
                kiTotal=newAmountKi;
                newAmountKi=0;
            }
        }
        characters[idCharacter].ki=kiTotal;
        characters[idCharacter].currentLevel=lvl;
       }else{
           if(lvl == 0){lvl=1;}
           if(lvl.mul(valueBaseKiBurnNewLevel) < characters[idCharacter].ki.add(newAmountKi) ){
               //la cantidad de Ki que se puede usar para llenar el limite
               newAmountKi= lvl.mul(valueBaseKiBurnNewLevel).sub(characters[idCharacter].ki);
               //cantidad de ki que sobra porque o sino supera el limite del nivel
               restKi=restKi.sub(newAmountKi);
           }
           //lleno la barra di ki con la cantidad pedidoa
                characters[idCharacter].ki= characters[idCharacter].ki.add(newAmountKi);
       }
       // devuelve la cantidad de KI que se usó.
        return restKi;
    }
//obtener la cantidad de ki que puede almacenar el personaje sin subir de nivel.
    function getLimitKi(uint256 idCharacter) view public returns(uint256) {
        uint256 valueBaseKiBurnNewLevel= charactersRules[characters[idCharacter].idCharacterRule].valueBaseKiBurnNewLevel;
        uint256 lvl=characters[idCharacter].currentLevel;
        if(lvl == 0){
            lvl=1;
        }
        return lvl.mul(valueBaseKiBurnNewLevel);
    }

    function spendKi(uint256 idCharacter,uint256 spend) public onlyOperator  returns(uint256 newKi) {
        if(characters[idCharacter].ki <= spend){
           characters[idCharacter].ki=0; 
           return 0;
        }
        spend= spend.sub((spend.mul(charactersRules[characters[idCharacter].idCharacterRule].innerPower)).div(DIV));
        characters[idCharacter].ki-= characters[idCharacter].ki.sub(spend);
        return characters[idCharacter].ki;
    }

    // crear un token copiando los atributos del otro
    function mintCopy(address _to, uint256 _characterId,uint256 _amount) public onlyOperator {
        require(ownerOf(_characterId) == address(this));
        Character storage _character= characters[_characterId] ;
        mint(_character.idCharacterRule,_to,_amount);
    }

    function mint( uint256 idCharacterRule, address _to,uint256 _amount) public onlyOperator {
        Character memory _character= Character(idCharacterRule,0,0,block.number);

        require(charactersRules[_character.idCharacterRule].innerPower <= DIV);
        for (uint256 index = 0; index < _amount; index++) {
           uint256 _id=characters.length; 
           _addCharacter(_character);
        //    _beforeTokenTransfer(address(0),_to,_character.id);
           _safeMint(_to,_id);
        }
    }

     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable,ERC721) {
        super._beforeTokenTransfer(from,to,tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable,ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Ownable {
        modifier onlyOperator() {
        require(operators[_msgSender()]);
        _;
    }

    event _isOperator(address indexed _operator, bool indexed _isOperator);

    mapping (address=>bool) operators;

    function isOperator(address _operator) view public returns (bool) {
        
        return operators[_operator];
    }

    function setOperator(address _operator,bool _is) onlyOwner public {
        emit _isOperator(_operator,_is);
        operators[_operator]=_is;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

