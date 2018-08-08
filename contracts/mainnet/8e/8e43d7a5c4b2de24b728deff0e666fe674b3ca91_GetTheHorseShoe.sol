pragma solidity ^0.4.23;



contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
  emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract ERC721 {
    
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;


    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId); //Einbauen!
    
    
    
}



contract HorseShoeControl  {

    address public ceoAddress=0xC6F3Fb72db068C96A1D50Bbc3D370cC8e4af0bFc;
    address public ctoAddress=0x73A895C06D6E3DcCA3acE48FC8801E17eD247f85;
 
        




    modifier onCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onCTO() {
        require(msg.sender == ctoAddress);
        _;
    }

    modifier onlyC() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == ctoAddress
        );
        _;
    }
    
    
    
    address public raceDistCon;
        

    address public addr_forge;
   


            
        function newForgeCon (address newConAddr) external onCTO {
            addr_forge = newConAddr;
            
        }
            
        function newRaceDistCon (address newConAddr) external onCTO {
            raceDistCon = newConAddr;
            
        }
            
    
            

    
    

 
}

contract HorseShoeShopOwner is HorseShoeControl, ERC721 {
    

    
    mapping (uint256 => address) public HShoeShopO;
    
    mapping (uint256 => uint256) public HSShopPrice;
    
    mapping (uint256 => bool) public HSShopForSale;
    mapping (uint256 => bool) public HSShopForBiding;
    
    mapping (address => uint256) HSShopOwnCount;
    
     uint256 public HSShopSaleFee = 20;
   
  
        mapping (uint256 => uint256)  startBlock;
      
    mapping (uint256 => uint256) startPrice;
    mapping (uint256 => uint256) public priceDecreaseRate;
    

      function getCurrentItemPrice(uint256 _id) public view returns (uint256)  {
    return startPrice[_id] - priceDecreaseRate[_id]*(block.number - startBlock[_id]);
  }
    
      function newPriceDecreaseRate(uint DecreRate,uint256 _id) external onlyC   {
                priceDecreaseRate[_id]=DecreRate;
  }
    
    
    
    function changeHSShopPrice(uint256 price, uint256 HSShopId) external{
        
        require(msg.sender==HShoeShopO[HSShopId]);
        
        require(HSShopForSale[HSShopId]==true);
        
        require(price!=0);
        
        HSShopPrice[HSShopId]=price;
        
    }
    
    
    function buyHSShop(uint256 id) payable external{
        
          require(HSShopForSale[id]==true);
         
              uint256 price = HSShopPrice[id];
            
            require(price<=msg.value);
            
         uint256 Fee = price / HSShopSaleFee ;
            
          uint256  oPrice= price - Fee;
            
            address _to = msg.sender;
            address _from = HShoeShopO[id];
            
            HSShopOwnCount[_to]++;
            
            HShoeShopO[id] = _to;
            
            HSShopForSale[id]=false;
            
            
                HSShopOwnCount[_from]--;
               
           emit Transfer(_from, _to, id);
            
            if(_from!=0){
                
             _from.transfer(oPrice);
            }else{
                
             ceoAddress.transfer(oPrice);
            }
             
             ceoAddress.transfer(Fee);
             
             
            uint256 buyExcess = msg.value - oPrice - Fee;
            _to.transfer(buyExcess);
      
        
    }
    

    
    function firstSellHSShop(uint256 _id, uint256 price, uint256 _decreRate) external onlyC {
        
        require(HShoeShopO[_id]==0);
        
        HSShopPrice[_id]=price;
        
            
                HSShopForBiding[_id]=true;
                
                  startBlock[_id] = block.number;
                  
                  startPrice[_id] = price;
                  
                 priceDecreaseRate[_id]= _decreRate;
                
    }
    
    function bid(uint256 _id) payable external{
      
        
        
        uint256 priceNow = getCurrentItemPrice(_id);
        require(msg.value>=priceNow);
        
        require(HSShopForBiding[_id]==true);
        
          if(priceNow<=0||priceNow>=startPrice[_id]){
        HSShopForBiding[_id]=false;
              _to.transfer( msg.value);
        }else{
            
        
        HSShopForBiding[_id]=false;
        
            
            address _to = msg.sender;
            address _from = HShoeShopO[_id];
            
            HSShopOwnCount[_to]++;
            
            HShoeShopO[_id] = _to;
            
            HSShopForSale[_id]=true;
            
            uint256 priceAufschlag=msg.value/3;
            
            
   HSShopPrice[_id]=msg.value+ priceAufschlag;
               
           emit Transfer(_from, _to, _id);
            
             ceoAddress.transfer(priceNow);
         
             
            uint256 buyExcess = msg.value - priceNow;
            _to.transfer(buyExcess);
        }
        
        
      
    }
    
    
     function setHSShopSaleFee(uint256 val) external onCTO {
        HSShopSaleFee = val;
    }
    
}

contract HorseShoeBasis is  HorseShoeShopOwner {
    
    
   
    event Birth(address owner, uint256 HorseShoeId);
   
    event Transfer(address from, address to, uint256 tokenId);

    struct HorseShoe {
        uint256 dna2; 
        uint256 dna3; 
        bool dna4;
        bool dna5; 

        
    }


    HorseShoe[] horseShoes;

    mapping (uint256 => address) horseShoeOwnerIndex;
    
    mapping (uint256 => uint256) public horseShoeIndexPrice;
    
    mapping (uint256 => uint256) public processingQuality;
    
    mapping (uint256 => uint256) public WearOut;
    
    
    mapping (uint256 => bool)  horseShoeIndexForSale;

    mapping (address => uint256) tokenOwnershipCount;
    
    mapping (uint256 => bool)  raceListed;


  uint256 public saleFee = 20;
   
   

 
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        tokenOwnershipCount[_to]++;
        horseShoeOwnerIndex[_tokenId] = _to;
        
        if (_from != address(0)) {
            tokenOwnershipCount[_from]--;
         
        }
       emit Transfer(_from, _to, _tokenId);
       
    }
    
    
 
    function transfer10( address _to, uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3, uint256 _tokenId4, uint256 _tokenId5, uint256 _tokenId6, uint256 _tokenId7, uint256 _tokenId8, uint256 _tokenId9, uint256 _tokenId10  ) external onlyC {
     
       require(_to != address(0));
		
        require(_to != address(this));
     
     require( horseShoeOwnerIndex[_tokenId1] == msg.sender );
      
      _transfer(msg.sender,  _to,  _tokenId1);
        
     require( horseShoeOwnerIndex[_tokenId2] == msg.sender );
   
      _transfer(msg.sender,  _to,  _tokenId2);
     require( horseShoeOwnerIndex[_tokenId3] == msg.sender );
     
      _transfer(msg.sender,  _to,  _tokenId3);
     require( horseShoeOwnerIndex[_tokenId4] == msg.sender );
       
      _transfer(msg.sender,  _to,  _tokenId4);
     require( horseShoeOwnerIndex[_tokenId5] == msg.sender );
  
      _transfer(msg.sender,  _to,  _tokenId5);
     require( horseShoeOwnerIndex[_tokenId6] == msg.sender );
       
      _transfer(msg.sender,  _to,  _tokenId6);
     require( horseShoeOwnerIndex[_tokenId7] == msg.sender );
        
      _transfer(msg.sender,  _to,  _tokenId7);
     require( horseShoeOwnerIndex[_tokenId8] == msg.sender );
       
      _transfer(msg.sender,  _to,  _tokenId8);
      
     require( horseShoeOwnerIndex[_tokenId9] == msg.sender );
      
      _transfer(msg.sender,  _to,  _tokenId9);
     require( horseShoeOwnerIndex[_tokenId10] == msg.sender );
      
      
      _transfer(msg.sender,  _to,  _tokenId10);
       
    }
    
    function _sell(address _from,  uint256 _tokenId, uint256 value) internal {
     
     if(horseShoeIndexForSale[_tokenId]==true){
         
              uint256 price = horseShoeIndexPrice[_tokenId];
            
            require(price<=value);
            
         uint256 Fee = price / saleFee /2;
            
          uint256  oPrice= price - Fee - Fee;
            
            address _to = msg.sender;
            
            tokenOwnershipCount[_to]++;
            horseShoeOwnerIndex[_tokenId] = _to;
            
            horseShoeIndexForSale[_tokenId]=false;
            
            
            if (_from != address(0)) {
                tokenOwnershipCount[_from]--;
               
            }
                 
           emit Transfer(_from, _to, _tokenId);
            
            uint256 HSQ = processingQuality[_tokenId]/10;
             address HSSOwner;
             
              if(HSQ>=10||WearOut[_tokenId]>=1){
                 
            HSSOwner= HShoeShopO[6];
            
             }else  if(HSQ>=0&&HSQ<=2){
              HSSOwner= HShoeShopO[5];
                 
             }else  if(HSQ>=2&&HSQ<=4){
              HSSOwner= HShoeShopO[4];
                 
             } else  if(HSQ>=4&&HSQ<=6){
             HSSOwner=  HShoeShopO[3];
                 
             } else  if(HSQ>=6&&HSQ<=8){
             HSSOwner=  HShoeShopO[2];
                 
             }else  if(HSQ>=8&&HSQ<=10){
             HSSOwner=  HShoeShopO[1];
                 
             }else{
                 
             HSSOwner= ceoAddress;
             }
             
            
             
             _from.transfer(oPrice);
             
             ceoAddress.transfer(Fee);
             if(HSSOwner!=0){
                 
             HSSOwner.transfer(Fee);
             }else {
             ceoAddress.transfer(Fee);
                 
             }
             
            uint256 bidExcess = value - oPrice - Fee - Fee;
            _to.transfer(bidExcess);
            
            
     }else{
          _to.transfer(value);
     }
      
    }
    
    
	
    function _newHorseShoe(
        uint256 _genes1,
        uint256 _genes2,
        uint256 _genes3,
        bool _genes4,
        bool _genes5,
        address _owner
    )
        internal
        returns (uint)
    {
   
   
   
   
        HorseShoe memory _horseShoe = HorseShoe({
        dna2: _genes2,
        dna3 : _genes3,
        dna4: _genes4,
        dna5: _genes5
            
        });
       
       
        
       uint256 newHorseShoeId;
	   
     newHorseShoeId = horseShoes.push(_horseShoe)-1;
     
  
        require(newHorseShoeId == uint256(uint32(newHorseShoeId)));


        WearOut[newHorseShoeId]=_genes1;
        
        processingQuality[newHorseShoeId]= (_genes2 + _genes3)/2;
        
        raceListed[newHorseShoeId]=false;
        
       emit Birth(_owner, newHorseShoeId);

        _transfer(0, _owner, newHorseShoeId);

        return newHorseShoeId;  
    }



}


contract IronConnect {
    
        function balanceOf(address tokenOwner) public constant returns (uint balance);
        
        function ironProcessed(address tokenOwner) external; 
        
}

contract SmithConnect {

      mapping (uint256 => uint256) public averageQuality;

    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function balanceOf(address _owner) public view returns (uint256 balance);
    
    
}

contract ForgeConnection {
    
    
    mapping (uint256 => uint256) public forgeToolQuality;
    
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function balanceOf(address _owner) public view returns (uint256 balance);

    
}


contract HorseShoeOwnership is HorseShoeBasis{

  string public constant  name = "CryptoHorseShoe";
    string public constant symbol = "CHS";
     uint8 public constant decimals = 0; 

    function horseShoeForSale(uint256 _tokenId, uint256 price) external {
  
     address  ownerof =  horseShoeOwnerIndex[_tokenId];
        require(ownerof == msg.sender);
        horseShoeIndexPrice[_tokenId] = price;
        horseShoeIndexForSale[_tokenId]= true;
		}
		
 function changePrice(uint256 _tokenId, uint256 price) external {
  
     address  ownerof =  horseShoeOwnerIndex[_tokenId];
        require(ownerof == msg.sender);
        require(horseShoeIndexForSale[_tokenId] == true);
       
             
              horseShoeIndexPrice[_tokenId] = price;
         
		}

 function horseShoeNotForSale(uint256 _tokenId) external {
         address  ownerof =  horseShoeOwnerIndex[_tokenId];
            require(ownerof == msg.sender);
        horseShoeIndexForSale[_tokenId]= false;

    }


    function _owns(address _applicant, uint256 _tokenId) internal view returns (bool) {
        return horseShoeOwnerIndex[_tokenId] == _applicant;
    }


    function balanceOf(address _owner) public view returns (uint256 count) {
        return tokenOwnershipCount[_owner];
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        payable
    {
        require(_to != address(0));
		
        require(_to != address(this));
 
        require(_owns(msg.sender, _tokenId));
       _transfer(msg.sender, _to, _tokenId);
    }

    function approve(
        address _to,
        uint256 _tokenId
    )
        external 
    {
       require(_owns(msg.sender, _tokenId));

        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId ) external payable {
        
        if(_from != msg.sender){
              require(_to == msg.sender);
                 
                 require(raceListed[_tokenId]==false);
                 
                require(_from==horseShoeOwnerIndex[_tokenId]);
        
               _sell(_from,  _tokenId, msg.value);
            
        }else{
            
          _to.transfer(msg.value);
        }
 
    }

    function totalSupply() public view returns (uint) {
        return horseShoes.length;
    }

    function ownerOf(uint256 _tokenId)  external view returns (address owner)  {
        owner = horseShoeOwnerIndex[_tokenId];

       return;
       
    }
    
    function ownerOfID(uint256 _tokenId)  external view returns (address owner, uint256 tokenId)  {
        owner = horseShoeOwnerIndex[_tokenId];
tokenId=_tokenId;
       return;
       
    }

       function horseShoeFS(uint256 _tokenId) external view  returns (bool buyable, uint256 tokenId) {
        buyable = horseShoeIndexForSale[_tokenId];
        tokenId=_tokenId;
       return;
       
    }
	
	function horseShoePr(uint256 _tokenId) external view  returns (uint256 price, uint256 tokenId) {
        price = horseShoeIndexPrice[_tokenId];
        tokenId=_tokenId;
       return;
       
    }

 function setSaleFee(uint256 val) external onCTO {
        saleFee = val;
    }


function raceOut(uint256 _tokenIdA) external {
    
    require(msg.sender==raceDistCon);

        require(WearOut[_tokenIdA] <10 );
    
		
      HorseShoe storage horseshoeA = horseShoes[_tokenIdA];
    
    horseshoeA.dna4=true;
    
	  
       WearOut[_tokenIdA] = WearOut[_tokenIdA]+1;
	  
	  raceListed[_tokenIdA]=false;
    
      
}

function meltHorseShoe(uint256 _tokenId, address owner) external{
  

  require(msg.sender==addr_forge);

   
        
            horseShoeIndexForSale[_tokenId]=false;
        horseShoeOwnerIndex[_tokenId]=0x00;
        
      
       tokenOwnershipCount[owner]--;
        
        //iron totalsupply less?
    
    
        
         HorseShoe storage horseshoe = horseShoes[_tokenId];
        horseshoe.dna5 = true;
      horseshoe.dna4 = false;
      
      
}

function raceRegistration(uint256 _tokenIdA, address owner) external {
    
  //  require(msg.sender==raceDistCon);
    
    require(tokenOwnershipCount[owner]>=4);
    
  require(horseShoeOwnerIndex[_tokenIdA]==owner);
  
      HorseShoe storage horseshoeA = horseShoes[_tokenIdA];
    require(horseshoeA.dna4==true);
    require(horseshoeA.dna5==false);
    require( raceListed[_tokenIdA]==false);
	require(horseShoeIndexForSale[_tokenIdA]==false);
	
        
		
    
    horseshoeA.dna4=false;
    
    raceListed[_tokenIdA]=true;
	
	
		
        
}


    
}



contract HorseShoeMinting is HorseShoeOwnership {

    uint256 public  HShoe_Limit = 160000;


    function createHorseShoe4(uint256 _genes2,uint256 _genes3,uint256 _genes2a,uint256 _genes3a, uint256 _genes2b,uint256 _genes3b,uint256 _genes2c,uint256 _genes3c, address _owner) external onlyC {
        address horseShoeOwner = _owner;
        
   require(horseShoes.length+3 < HShoe_Limit);

            
              _newHorseShoe(0, _genes2, _genes3,true,false , horseShoeOwner);
            
              _newHorseShoe(0, _genes2b, _genes3b,true,false , horseShoeOwner);
            
            
              _newHorseShoe(0, _genes2a, _genes3a,true,false , horseShoeOwner);
            
            
              _newHorseShoe(0, _genes2c, _genes3c,true,false , horseShoeOwner);
        
    }
    
        function createHorseShoe1(uint256 _genes2,uint256 _genes3, address _owner) external onlyC {
        address horseShoeOwner = _owner;
        
   require(horseShoes.length+3 < HShoe_Limit);

            
              _newHorseShoe(0, _genes2, _genes3,true,false , horseShoeOwner);
            
          
        
    }
    
    function createHorseShoe10(uint256 _genes2,uint256 _genes3,uint256 _genes2a,uint256 _genes3a, uint256 _genes2b,uint256 _genes3b,uint256 _genes2c,uint256 _genes3c, uint256 _genes2d,uint256 _genes3d, address _owner) external onlyC {
        address horseShoeOwner = _owner;
        
   require(horseShoes.length+3 < HShoe_Limit);

            
              _newHorseShoe(0, _genes2, _genes3,true,false , horseShoeOwner);
            
              _newHorseShoe(0, _genes2b, _genes3b,true,false , horseShoeOwner);
            
            
              _newHorseShoe(0, _genes2a, _genes3a,true,false , horseShoeOwner);
            
            
              _newHorseShoe(0, _genes2c, _genes3c,true,false , horseShoeOwner);
              
              _newHorseShoe(0, _genes2d, _genes3d,true,false , horseShoeOwner);
        
              _newHorseShoe(0, _genes2, _genes3,true,false , horseShoeOwner);
            
              _newHorseShoe(0, _genes2b, _genes3b,true,false , horseShoeOwner);
            
            
              _newHorseShoe(0, _genes2a, _genes3a,true,false , horseShoeOwner);
            
            
              _newHorseShoe(0, _genes2c, _genes3c,true,false , horseShoeOwner);
              
              _newHorseShoe(0, _genes2d, _genes3d,true,false , horseShoeOwner);
    }
  

  
    
       function _generateNewHorseShoe(uint256 smith_quality ,uint256 maschine_quality, address _owner) external {
    
        
   require(msg.sender==addr_forge);
        
              _newHorseShoe(  0, smith_quality, maschine_quality, true, false , _owner);

        
    }
   
   
}


contract GetTheHorseShoe is HorseShoeMinting {


    function getHorseShoe(uint256 _id)
        external
        view
        returns (
        uint256 price,
        uint256 id,
        bool forSale,
        uint256 _genes1,
        uint256 _genes2,
        uint256 _genes3,
        bool _genes4,
        bool _genes5
		
    ) {
		price = horseShoeIndexPrice[_id];
        id = uint256(_id);
		forSale = horseShoeIndexForSale[_id];
        HorseShoe storage horseshoe = horseShoes[_id];
        
        _genes1 = WearOut[_id];
        _genes2 = horseshoe.dna2;
        _genes3 = horseshoe.dna3;
        _genes4 = horseshoe.dna4;
        _genes5 = horseshoe.dna5;
		

    }

  

}