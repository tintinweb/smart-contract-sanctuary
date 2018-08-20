pragma solidity ^0.4.23;

/*
*  ██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗██╗   ██╗    
*  ██╔══██╗██║   ██║████╗  ██║████╗  ██║╚██╗ ██╔╝    
*  ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║ ╚████╔╝     
*  ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║  ╚██╔╝      
*  ██████╔╝╚██████╔╝██║ ╚████║██║ ╚████║   ██║       
*  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝   ╚═╝       
*                                                    
*   ██████╗  █████╗ ███╗   ███╗███████╗              
*  ██╔════╝ ██╔══██╗████╗ ████║██╔════╝              
*  ██║  ███╗███████║██╔████╔██║█████╗                
*  ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝                
*  ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗              
*   ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝      


* Author:  Konstantin G...
* Telegram: @bunnygame
* 
* email: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="dcb5b2bab39cbea9b2b2a5bfb3b5b2f2bfb3">[email&#160;protected]</a>
* site : http://bunnycoin.co
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/

contract Ownable {
    
    address public ownerCEO;
    address ownerMoney;  
    address ownerServer;
    address privAddress;
    
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public { 
        ownerCEO = msg.sender; 
        ownerServer = msg.sender;
        ownerMoney = msg.sender;
    }
 
  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == ownerCEO);
        _;
    }
   
    modifier onlyServer() {
        require(msg.sender == ownerServer || msg.sender == ownerCEO);
        _;
    }

    function transferOwnership(address add) public onlyOwner {
        if (add != address(0)) {
            ownerCEO = add;
        }
    }
 

    function transferOwnershipServer(address add) public onlyOwner {
        if (add != address(0)) {
            ownerServer = add;
        }
    } 
     
    function transferOwnerMoney(address _ownerMoney) public  onlyOwner {
        if (_ownerMoney != address(0)) {
            ownerMoney = _ownerMoney;
        }
    }
 
    function getOwnerMoney() public view onlyOwner returns(address) {
        return ownerMoney;
    } 
    function getOwnerServer() public view onlyOwner returns(address) {
        return ownerServer;
    }
    /**
    *  @dev private contract
     */
    function getPrivAddress() public view onlyOwner returns(address) {
        return privAddress;
    }
}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
}
 

contract BaseRabbit  is Ownable {
       


    event SendBunny(address newOwnerBunny, uint32 bunnyId);
    event StopMarket(uint32 bunnyId);
    event StartMarket(uint32 bunnyId, uint money);
    event BunnyBuy(uint32 bunnyId, uint money);  
    event EmotherCount(uint32 mother, uint summ);
    event NewBunny(uint32 bunnyId, uint dnk, uint256 blocknumber, uint breed );
    event ChengeSex(uint32 bunnyId, bool sex, uint256 price);
    event SalaryBunny(uint32 bunnyId, uint cost);
    event CreateChildren(uint32 matron, uint32 sire, uint32 child);
    event BunnyName(uint32 bunnyId, string name);
    event BunnyDescription(uint32 bunnyId, string name);
    event CoolduwnMother(uint32 bunnyId, uint num);


    event Transfer(address from, address to, uint32 tokenId);
    event Approval(address owner, address approved, uint32 tokenId);
    event OwnerBunnies(address owner, uint32  tokenId);

 

    address public  myAddr_test = 0x982a49414fD95e3268D3559540A67B03e40AcD64;

    using SafeMath for uint256;
    bool pauseSave = false;
    uint256 bigPrice = 0.0005 ether;
    
    uint public commission_system = 5;
     
    // ID the last seal
    uint32 public lastIdGen0;
    uint public totalGen0 = 0;
    // ID the last seal
    uint public lastTimeGen0;
    
    // ID the last seal
  //  uint public timeRangeCreateGen0 = 1800;
    uint public timeRangeCreateGen0 = 1;

    uint public promoGen0 = 2500;
    uint public promoMoney = 1*bigPrice;
    bool public promoPause = false;


    function setPromoGen0(uint _promoGen0) public onlyOwner {
        promoGen0 = _promoGen0;
    }

    function setPromoPause() public onlyOwner {
        promoPause = !promoPause;
    }



    function setPromoMoney(uint _promoMoney) public onlyOwner {
        promoMoney = _promoMoney;
    }
    modifier timeRange() {
        require((lastTimeGen0+timeRangeCreateGen0) < now);
        _;
    } 

    mapping(uint32 => uint) public totalSalaryBunny;
    mapping(uint32 => uint32[5]) public rabbitMother;
    
    mapping(uint32 => uint) public motherCount;
    
    // how many times did the rabbit cross
    mapping(uint32 => uint) public rabbitBreedCount;

    mapping(uint32 => uint)  public rabbitSirePrice;
    mapping(uint => uint32[]) public sireGenom;
    mapping (uint32 => uint) mapDNK;
   
    uint32[12] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(4 minutes),
        uint32(8 minutes),
        uint32(16 minutes),
        uint32(32 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days)
    ];


    struct Rabbit { 
         // parents
        uint32 mother;
        uint32 sire; 
        // block in which a rabbit was born
        uint birthblock;
         // number of births or how many times were offspring
        uint birthCount;
         // The time when Rabbit last gave birth
        uint birthLastTime;
        //the current role of the rabbit
        uint role;
        //indexGenome   
        uint genome;
    }
    /**
    * Where we will store information about rabbits
    */
    Rabbit[]  public rabbits;
     
    /**
    * who owns the rabbit
    */
    mapping (uint32 => address) public rabbitToOwner; 
    mapping(address => uint32[]) public ownerBunnies;
    //mapping (address => uint) ownerRabbitCount;
    mapping (uint32 => string) rabbitDescription;
    mapping (uint32 => string) rabbitName; 

    //giff 
    mapping (uint32 => bool) giffblock; 
    mapping (address => bool) ownerGennezise;

}



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="90f4f5e4f5d0f1e8f9fffdeaf5febef3ff">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
    // Required methods 
 

    function ownerOf(uint32 _tokenId) public view returns (address owner);
    function approve(address _to, uint32 _tokenId) public returns (bool success);
    function transfer(address _to, uint32 _tokenId) public;
    function transferFrom(address _from, address _to, uint32 _tokenId) public returns (bool);
    function totalSupply() public view returns (uint total);
    function balanceOf(address _owner) public view returns (uint balance);

}

/// @title Interface new rabbits address
contract PrivateRabbitInterface {
    function getNewRabbit(address from)  public view returns (uint);
    function mixDNK(uint dnkmother, uint dnksire, uint genome)  public view returns (uint);
    function isUIntPrivate() public pure returns (bool);
    
  //  function mixGenesRabbits(uint256 genes1, uint256 genes2, uint256 targetBlock) public returns (uint256);
}




contract BodyRabbit is BaseRabbit, ERC721 {
     
    uint public totalBunny = 0;
    string public constant name = "CryptoRabbits";
    string public constant symbol = "CRB";


    PrivateRabbitInterface privateContract;

    /**
    * @dev setting up a new address for a private contract
    */
    function setPriv(address _privAddress) public returns(bool) {
        privAddress = _privAddress;
        privateContract = PrivateRabbitInterface(_privAddress);
    } 

    bool public fcontr = false;
 
    
    constructor() public { 
        setPriv(myAddr_test);
        fcontr = true;
    }

    function isPriv() public view returns(bool) {
        return privateContract.isUIntPrivate();
    }

    modifier checkPrivate() {
        require(isPriv());
        _;
    }

    function ownerOf(uint32 _tokenId) public view returns (address owner) {
        return rabbitToOwner[_tokenId];
    }

    function approve(address _to, uint32 _tokenId) public returns (bool) { 
        _to;
        _tokenId;
        return false;
    }


    function removeTokenList(address _owner, uint32 _tokenId) internal { 
        uint count = ownerBunnies[_owner].length;
        for (uint256 i = 0; i < count; i++) {
            if(ownerBunnies[_owner][i] == _tokenId)
            { 
                delete ownerBunnies[_owner][i];
                if(count > 0 && count != (i-1)){
                    ownerBunnies[_owner][i] = ownerBunnies[_owner][(count-1)];
                    delete ownerBunnies[_owner][(count-1)];
                } 
                ownerBunnies[_owner].length--;
                return;
            } 
        }
    }
    /**
    * Get the cost of the reward for pairing
    * @param _tokenId - rabbit that mates
     */
    function getSirePrice(uint32 _tokenId) public view returns(uint) {
        if(rabbits[(_tokenId-1)].role == 1){
            uint procent = (rabbitSirePrice[_tokenId] / 100);
            uint res = procent.mul(25);
            uint system  = procent.mul(commission_system);

            res = res.add(rabbitSirePrice[_tokenId]);
            return res.add(system); 
        } else {
            return 0;
        }
    }

 
    function addTokenList(address owner,  uint32 _tokenId) internal {
        ownerBunnies[owner].push( _tokenId);
        emit OwnerBunnies(owner, _tokenId);
        rabbitToOwner[_tokenId] = owner; 
    }
 

    function transfer(address _to, uint32 _tokenId) public {
        address currentOwner = msg.sender;
        address oldOwner = rabbitToOwner[_tokenId];
        require(rabbitToOwner[_tokenId] == msg.sender);
        require(currentOwner != _to);
        require(_to != address(0));
        removeTokenList(oldOwner, _tokenId);
        addTokenList(_to, _tokenId);
        emit Transfer(oldOwner, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint32 _tokenId) public returns(bool) {
        address oldOwner = rabbitToOwner[_tokenId];
        require(oldOwner == _from);
        require(oldOwner != _to);
        require(_to != address(0));
        removeTokenList(oldOwner, _tokenId);
        addTokenList(_to, _tokenId); 
        emit Transfer (oldOwner, _to, _tokenId);
        return true;
    }  
    
    function setTimeRangeGen0(uint _sec) public onlyOwner {
        timeRangeCreateGen0 = _sec;
    }


    function isPauseSave() public view returns(bool) {
        return !pauseSave;
    }
    function isPromoPause() public view returns(bool) {
        if(msg.sender == ownerServer || msg.sender == ownerCEO){
            return true;
        }else{
            return !promoPause;
        } 
    }

    function setPauseSave() public onlyOwner  returns(bool) {
        return pauseSave = !pauseSave;
    }

    /**
    * for check
    *
    */
    function isUIntPublic() public pure returns(bool) {
        return true;
    }


    function getTokenOwner(address owner) public view returns(uint total, uint32[] list) {
        total = ownerBunnies[owner].length;
        list = ownerBunnies[owner];
    } 



    function setRabbitMother(uint32 children, uint32 mother) internal { 
        require(children != mother);
        if (mother == 0 )
        {
            return;
        }
        uint32[11] memory pullMother;
        uint start = 0;
        for (uint i = 0; i < 5; i++) {
            if (rabbitMother[mother][i] != 0) {
              pullMother[start] = uint32(rabbitMother[mother][i]);
              rabbitMother[mother][i] = 0;
              start++;
            } 
        }
        pullMother[start] = mother;
        start++;
        for (uint m = 0; m < 5; m++) {
             if(start >  5){
                    rabbitMother[children][m] = pullMother[(m+1)];
             }else{
                    rabbitMother[children][m] = pullMother[m];
             }
        } 
        setMotherCount(mother);
    }

      

    function setMotherCount(uint32 _mother) internal returns(uint)  { //internal
        motherCount[_mother] = motherCount[_mother].add(1);
        emit EmotherCount(_mother, motherCount[_mother]);
        return motherCount[_mother];
    }


     function getMotherCount(uint32 _mother) public view returns(uint) { //internal
        return  motherCount[_mother];
    }


     function getTotalSalaryBunny(uint32 _bunny) public view returns(uint) { //internal
        return  totalSalaryBunny[_bunny];
    }
 
 
    function getRabbitMother( uint32 mother) public view returns(uint32[5]){
        return rabbitMother[mother];
    }

     function getRabbitMotherSumm(uint32 mother) public view returns(uint count) { //internal
        for (uint m = 0; m < 5 ; m++) {
            if(rabbitMother[mother][m] != 0 ) { 
                count++;
            }
        }
    }



    function getRabbitDNK(uint32 bunnyid) public view returns(uint) { 
        return mapDNK[bunnyid];
    }
     
    function bytes32ToString(bytes32 x)internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    function uintToBytes(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = &#39;0&#39;;
        } else {
        while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function totalSupply() public view returns (uint total) {
        return totalBunny;
    }

    function balanceOf(address _owner) public view returns (uint) {
      //  _owner;
        return ownerBunnies[_owner].length;
    }

    function sendMoney(address _to, uint256 _money) internal { 
        _to.transfer((_money/100)*95);
        ownerMoney.transfer((_money/100)*5); 
    }

    function getGiffBlock(uint32 _bunnyid) public view returns(bool) { 
        return !giffblock[_bunnyid];
    }

    function getOwnerGennezise(address _to) public view returns(bool) { 
        return ownerGennezise[_to];
    }
    

    function getBunny(uint32 _bunny) public view returns(
        uint32 mother,
        uint32 sire,
        uint birthblock,
        uint birthCount,
        uint birthLastTime,
        uint role, 
        uint genome,
        bool interbreed,
        uint leftTime,
        uint lastTime,
        uint price,
        uint motherSumm
        )
        {
            price = getSirePrice(_bunny);
            _bunny = _bunny - 1;

            mother = rabbits[_bunny].mother;
            sire = rabbits[_bunny].sire;
            birthblock = rabbits[_bunny].birthblock;
            birthCount = rabbits[_bunny].birthCount;
            birthLastTime = rabbits[_bunny].birthLastTime;
            role = rabbits[_bunny].role;
            genome = rabbits[_bunny].genome;
                     
            if(birthCount > 14) {
                birthCount = 14;
            }

            motherSumm = motherCount[_bunny];

            lastTime = uint(cooldowns[birthCount]);
            lastTime = lastTime.add(birthLastTime);
            if(lastTime <= now) {
                interbreed = true;
            } else {
                leftTime = lastTime.sub(now);
            }
    }


    function getBreed(uint32 _bunny) public view returns(
        bool interbreed
        )
        {
        _bunny = _bunny - 1;
        if(_bunny == 0) {
            return;
        }
        uint birtTime = rabbits[_bunny].birthLastTime;
        uint birthCount = rabbits[_bunny].birthCount;

        uint  lastTime = uint(cooldowns[birthCount]);
        lastTime = lastTime.add(birtTime);

        if(lastTime <= now && rabbits[_bunny].role == 0 ) {
            interbreed = true;
        } 
    }
    /**
     *  we get cooldown
     */
    function getcoolduwn(uint32 _mother) public view returns(uint lastTime, uint cd, uint lefttime) {
        cd = rabbits[(_mother-1)].birthCount;
        if(cd > 14) {
            cd = 14;
        }
        // time when I can give birth
        lastTime = (cooldowns[cd] + rabbits[(_mother-1)].birthLastTime);
        if(lastTime > now) {
            // I can not give birth, it remains until delivery
            lefttime = lastTime.sub(now);
        }
    }

}

/**
* sale and bye Rabbits
*/
contract RabbitMarket is BodyRabbit {
 
 // Long time
    uint stepMoney = 2*60*60;
           
    function setStepMoney(uint money) public onlyOwner {
        stepMoney = money;
    }
    /**
    * @dev number of rabbits participating in the auction
    */
    uint marketCount = 0; 

    uint daysperiod = 1;
    uint sec = 1;
    // how many last sales to take into account in the contract before the formation of the price
    uint8 middlelast = 20;
    
   
     
    // those who currently participate in the sale
    mapping(uint32 => uint256[]) internal marketRabbits;
     
     
    uint256 middlePriceMoney = 1; 
    uint256 middleSaleTime = 0;  
    uint moneyRange;
 
    function setMoneyRange(uint _money) public onlyOwner {
        moneyRange = _money;
    }
     
    // the last cost of a sold seal
    uint lastmoney = 0;  
    // the time which was spent on the sale of the cat
    uint lastTimeGen0;

    //how many closed auctions
    uint public totalClosedBID = 0;
    mapping (uint32 => uint) bunnyCost; 
    mapping(uint32 => uint) bidsIndex;
 

    /**
    * @dev get rabbit price
    */
    function currentPrice(uint32 _bunnyid) public view returns(uint) {

        uint money = bunnyCost[_bunnyid];
        if (money > 0) {
            uint moneyComs = money.div(100);
            moneyComs = moneyComs.mul(5);
            return money.add(moneyComs);
        }
    }
    /**
    * @dev We are selling rabbit for sale
    * @param _bunnyid - whose rabbit we exhibit 
    * @param _money - sale amount 
    */
  function startMarket(uint32 _bunnyid, uint _money) public returns (uint) {
        require(isPauseSave());
        require(_money >= bigPrice);
        require(rabbitToOwner[_bunnyid] ==  msg.sender);
        bunnyCost[_bunnyid] = _money;
        emit StartMarket(_bunnyid, _money);
        return marketCount++;
    }


    /**
    * @dev remove from sale rabbit
    * @param _bunnyid - a rabbit that is removed from sale 
    */
    function stopMarket(uint32 _bunnyid) public returns(uint) {
        require(isPauseSave());
        require(rabbitToOwner[_bunnyid] == msg.sender);  
        bunnyCost[_bunnyid] = 0;
        emit StopMarket(_bunnyid);
        return marketCount--;
    }

    /**
    * @dev Acquisition of a rabbit from another user
    * @param _bunnyid  Bunny
     */
    function buyBunny(uint32 _bunnyid) public payable {
        require(isPauseSave());
        require(rabbitToOwner[_bunnyid] != msg.sender);
        uint price = currentPrice(_bunnyid);

        require(msg.value >= price && 0 != price);
        // stop trading on the current rabbit
        totalClosedBID++;
        // Sending money to the old user
        sendMoney(rabbitToOwner[_bunnyid], msg.value);
        // is sent to the new owner of the bought rabbit
        transferFrom(rabbitToOwner[_bunnyid], msg.sender, _bunnyid); 
        stopMarket(_bunnyid); 

        emit BunnyBuy(_bunnyid, price);
        emit SendBunny (msg.sender, _bunnyid);
    } 

    /**
    * @dev give a rabbit to a specific user
    * @param add new address owner rabbits
    */
    function giff(uint32 bunnyid, address add) public {
        require(rabbitToOwner[bunnyid] == msg.sender);
        // a rabbit taken for free can not be given
        require(!(giffblock[bunnyid]));
        transferFrom(msg.sender, add, bunnyid);
    }

    function getMarketCount() public view returns(uint) {
        return marketCount;
    }
}


/**
* Basic actions for the transfer of rights of rabbits
*/
contract BunnyGame is RabbitMarket {    
  
    function transferNewBunny(address _to, uint32 _bunnyid, uint localdnk, uint breed, uint32 matron, uint32 sire) internal {
        emit NewBunny(_bunnyid, localdnk, block.number, breed);
        emit CreateChildren(matron, sire, _bunnyid);
        addTokenList(_to, _bunnyid);
        totalSalaryBunny[_bunnyid] = 0;
        motherCount[_bunnyid] = 0;
        totalBunny++;
    }

    /***
    * @dev create a new gene and put it up for sale, this operation takes place on the server
    */
    function createGennezise(uint32 _matron) public {
         
        bool promo = false;
        require(isPriv());
        require(isPauseSave());
        require(isPromoPause());
 
        if (totalGen0 > promoGen0) { 
            require(msg.sender == ownerServer || msg.sender == ownerCEO);
        } else if (!(msg.sender == ownerServer || msg.sender == ownerCEO)) {
            // promo action
                require(!ownerGennezise[msg.sender]);
                ownerGennezise[msg.sender] = true;
                promo = true;
        }
        
        uint  localdnk = privateContract.getNewRabbit(msg.sender);
        Rabbit memory _Rabbit =  Rabbit( 0, 0, block.number, 0, 0, 0, 0);
        uint32 _bunnyid =  uint32(rabbits.push(_Rabbit));
        mapDNK[_bunnyid] = localdnk;
       
        transferNewBunny(msg.sender, _bunnyid, localdnk, 0, 0, 0);  
        
        lastTimeGen0 = now;
        lastIdGen0 = _bunnyid; 
        totalGen0++; 

        setRabbitMother(_bunnyid, _matron);

        if (promo) {
            giffblock[_bunnyid] = true;
        }
    }

    function getGenomeChildren(uint32 _matron, uint32 _sire) internal view returns(uint) {
        uint genome;
        if (rabbits[(_matron-1)].genome >= rabbits[(_sire-1)].genome) {
            genome = rabbits[(_matron-1)].genome;
        } else {
            genome = rabbits[(_sire-1)].genome;
        }
        return genome.add(1);
    }
    
    /**
    * create a new rabbit, according to the cooldown
    * @param _matron - mother who takes into account the cooldown
    * @param _sire - the father who is rewarded for mating for the fusion of genes
     */
    function createChildren(uint32 _matron, uint32 _sire) public  payable returns(uint32) {

        require(isPriv());
        require(isPauseSave());
        require(rabbitToOwner[_matron] == msg.sender);
        // Checking for the role
        require(rabbits[(_sire-1)].role == 1);
        require(_matron != _sire);

        require(getBreed(_matron));
        // Checking the money 
        
        require(msg.value >= getSirePrice(_sire));
        
        uint genome = getGenomeChildren(_matron, _sire);

        uint localdnk =  privateContract.mixDNK(mapDNK[_matron], mapDNK[_sire], genome);
        Rabbit memory rabbit =  Rabbit(_matron, _sire, block.number, 0, 0, 0, genome);

        uint32 bunnyid =  uint32(rabbits.push(rabbit));
        mapDNK[bunnyid] = localdnk;


        uint _moneyMother = rabbitSirePrice[_sire].div(4);

        _transferMoneyMother(_matron, _moneyMother);

        rabbitToOwner[_sire].transfer(rabbitSirePrice[_sire]);

        uint system = rabbitSirePrice[_sire].div(100);
        system = system.mul(commission_system);
        ownerMoney.transfer(system); // refund previous bidder
  
        coolduwnUP(_matron);
        // we transfer the rabbit to the new owner
        transferNewBunny(rabbitToOwner[_matron], bunnyid, localdnk, genome, _matron, _sire);   
        // we establish parents for the child
        setRabbitMother(bunnyid, _matron);
        return bunnyid;
    } 
  
    /**
     *  Set the cooldown for childbirth
     * @param _mother - mother for which cooldown
     */
    function coolduwnUP(uint32 _mother) internal { 
        require(isPauseSave());
        rabbits[(_mother-1)].birthCount = rabbits[(_mother-1)].birthCount.add(1);
        rabbits[(_mother-1)].birthLastTime = now;
        emit CoolduwnMother(_mother, rabbits[(_mother-1)].birthCount);
    }


    /**
     * @param _mother - matron send money for parrent
     * @param _valueMoney - current sale
     */
    function _transferMoneyMother(uint32 _mother, uint _valueMoney) internal {
        require(isPauseSave());
        require(_valueMoney > 0);
        if (getRabbitMotherSumm(_mother) > 0) {
            uint pastMoney = _valueMoney/getRabbitMotherSumm(_mother);
            for (uint i=0; i < getRabbitMotherSumm(_mother); i++) {
                if (rabbitMother[_mother][i] != 0) { 
                    uint32 _parrentMother = rabbitMother[_mother][i];
                    address add = rabbitToOwner[_parrentMother];
                    // pay salaries
                    setMotherCount(_parrentMother);
                    totalSalaryBunny[_parrentMother] += pastMoney;

                    emit SalaryBunny(_parrentMother, totalSalaryBunny[_parrentMother]);

                    add.transfer(pastMoney); // refund previous bidder
                }
            } 
        }
    }
    
    /**
    * @dev We set the cost of renting our genes
    * @param price rent price
     */
    function setRabbitSirePrice(uint32 _rabbitid, uint price) public returns(bool) {
        require(isPauseSave());
        require(rabbitToOwner[_rabbitid] == msg.sender);
        require(price > bigPrice);

        uint lastTime;
        (lastTime,,) = getcoolduwn(_rabbitid);
        require(now >= lastTime);

        if (rabbits[(_rabbitid-1)].role == 1 && rabbitSirePrice[_rabbitid] == price) {
            return false;
        }

        rabbits[(_rabbitid-1)].role = 1;
        rabbitSirePrice[_rabbitid] = price;
        uint gen = rabbits[(_rabbitid-1)].genome;
        sireGenom[gen].push(_rabbitid);
        emit ChengeSex(_rabbitid, true, getSirePrice(_rabbitid));
        return true;
    }
 
    /**
    * @dev We set the cost of renting our genes
     */
    function setSireStop(uint32 _rabbitid) public returns(bool) {
        require(isPauseSave());
        require(rabbitToOwner[_rabbitid] == msg.sender);
     //   require(rabbits[(_rabbitid-1)].role == 0);

        rabbits[(_rabbitid-1)].role = 0;
        rabbitSirePrice[_rabbitid] = 0;
        deleteSire(_rabbitid);
        return true;
    }
    
      function deleteSire(uint32 _tokenId) internal { 
        uint gen = rabbits[(_tokenId-1)].genome;

        uint count = sireGenom[gen].length;
        for (uint i = 0; i < count; i++) {
            if(sireGenom[gen][i] == _tokenId)
            { 
                delete sireGenom[gen][i];
                if(count > 0 && count != (i-1)){
                    sireGenom[gen][i] = sireGenom[gen][(count-1)];
                    delete sireGenom[gen][(count-1)];
                } 
                sireGenom[gen].length--;
                emit ChengeSex(_tokenId, false, 0);
                return;
            } 
        }
    } 

    function getMoney(uint _value) public onlyOwner {
        require(address(this).balance >= _value);
        ownerMoney.transfer(_value);
    }
}