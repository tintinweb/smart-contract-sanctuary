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
    event Approval(address owner, address approved, uint256 tokenId); 
    
    
    
}



contract SaddleControl  {

    address public ceoAddress=0xC87959bbafD5cDCbC5E29C92E3161f59f51d5794;
    
    address public ctoAddress=0x6c2324c462184058C6ce28339C39FF04b9d9bEf1;
 
        

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
        

    address public addr_Saddlery;
   


            
        function newSaddleryCon (address newConAddr) external onCTO {
            addr_Saddlery = newConAddr;
            
        }
            
        function newRaceDistCon (address newConAddr) external onCTO {
            raceDistCon = newConAddr;
            
        }
            
    
            

    
    

 
}

contract SaddleShopOwner is SaddleControl, ERC721 {
    

    
    mapping (uint256 => address) public SaddleShopO;
    
    mapping (uint256 => uint256) public SaddleShopPrice;
    
    mapping (uint256 => bool) public SaddleShopForSale;
    mapping (uint256 => bool) public SaddleShopForBiding;
    
    mapping (address => uint256) SaddleShopOwnCount;
    
     uint256 public SaddleShopSaleFee = 20;
   
  
        mapping (uint256 => uint256)  startBlock;
      
    mapping (uint256 => uint256) startPrice;
    mapping (uint256 => uint256) public shopPriceDecreaseRate;
    

      function getCurrentItemPrice(uint256 _id) public view returns (uint256)  {
          
        uint256  currentPrice =startPrice[_id] - shopPriceDecreaseRate[_id]*(block.number - startBlock[_id]);
          
           if(currentPrice <=0 ){
      return 0;
  }else if(currentPrice>startPrice[_id]){
      
      return 0;
  }else{
      
    return currentPrice;
  }
  
  
  }
    
      function newPriceDecreaseRate(uint DecreRate,uint256 _id) external onlyC   {
                shopPriceDecreaseRate[_id]=DecreRate;
  }
    
    
    
    function changeSaddleShopPrice(uint256 price, uint256 SadShopId) external{
        
        require(msg.sender==SaddleShopO[SadShopId]);
        
        require(SaddleShopForSale[SadShopId]==true);
        
        require(price!=0);
        
        SaddleShopPrice[SadShopId]=price;
        
    }
    
    
    function buySaddleShop(uint256 id) payable external{
        
          require(SaddleShopForSale[id]==true);
         
              uint256 price = SaddleShopPrice[id];
            
            require(price<=msg.value);
            
         uint256 Fee = price / SaddleShopSaleFee ;
            
          uint256  oPrice= price - Fee;
            
            address _to = msg.sender;
            address _from = SaddleShopO[id];
            
            SaddleShopOwnCount[_to]++;
            
            SaddleShopO[id] = _to;
            
            SaddleShopForSale[id]=false;
            
            
                SaddleShopOwnCount[_from]--;
               
           emit Transfer(_from, _to, id);
           
             ceoAddress.transfer(Fee);
            
            if(_from!=0){
                
             _from.transfer(oPrice);
            }else{
                
             ceoAddress.transfer(oPrice);
            }
             
             
             
            uint256 buyExcess = msg.value - oPrice - Fee;
            _to.transfer(buyExcess);
      
        
    }
    

    
    function firstSellSaddleShop(uint256 _id, uint256 price, uint256 _decreRate) external onlyC {
        
        require(SaddleShopO[_id]==0);
        
        SaddleShopPrice[_id]=price;
        
            
                SaddleShopForBiding[_id]=true;
                
                  startBlock[_id] = block.number;
                  
                  startPrice[_id] = price;
                  
                 shopPriceDecreaseRate[_id]= _decreRate;
                
    }
    
    function bid(uint256 _id) payable external{
      
        
        
        uint256 priceNow = getCurrentItemPrice(_id);
        require(msg.value>=priceNow);
        
        require(SaddleShopForBiding[_id]==true);
        
          if(priceNow<=0||priceNow>=startPrice[_id]){
        SaddleShopForBiding[_id]=false;
              _to.transfer( msg.value);
              
              //besser regeln!!
        }else{
            
        
        SaddleShopForBiding[_id]=false;
        
            
            address _to = msg.sender;
            address _from = SaddleShopO[_id];
            
            SaddleShopOwnCount[_to]++;
            
            SaddleShopO[_id] = _to;
            
            SaddleShopForSale[_id]=true;
            
            uint256 priceAufschlag=msg.value/3;
            
            
   SaddleShopPrice[_id]=msg.value+ priceAufschlag;
               
           emit Transfer(_from, _to, _id);
            
             ceoAddress.transfer(priceNow);
         
             
            uint256 buyExcess = msg.value - priceNow;
            _to.transfer(buyExcess);
        }
        
        
      
    }
    
    
     function setSaddleShopSaleFee(uint256 val) external onCTO {
        SaddleShopSaleFee = val;
    }
    
}

contract SaddleBasis is  SaddleShopOwner {
    
    
   
    event Birth(address owner, uint256 SaddleId);
   
    event Transfer(address from, address to, uint256 tokenId);

    struct SaddleAttr {
        
        uint256 dna1; 
        uint256 dna2; 
        uint256 dna3;

        bool dna4; 
        
        
    }


    SaddleAttr[] Saddles;

    mapping (uint256 => address) SaddleOwnerIndex;
    
    mapping (uint256 => uint256) public saddleIndexPrice;
    
    mapping (uint256 => uint256) public saddleQuality;
    
    
    
    mapping (uint256 => bool) SaddleIndexForSale;

    mapping (address => uint256) tokenOwnershipCount;
    
    mapping (uint256 => bool)  raceListed;
    
    mapping (uint256 => bool) public DutchAListed;
    
    mapping (uint256 => uint256)  startDutchABlock;
      
    mapping (uint256 => uint256) startDutchAPrice;
    
    mapping (uint256 => uint256) public DutchADecreaseRate;
    
    


  uint256 public saleFee = 20;
   


 
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        tokenOwnershipCount[_to]++;
        SaddleOwnerIndex[_tokenId] = _to;
        
        if (_from != address(0)) {
            tokenOwnershipCount[_from]--;
         
        }
       emit Transfer(_from, _to, _tokenId);
       
    }
    
    
 
    function transfer10( address _to, uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3, uint256 _tokenId4, uint256 _tokenId5, uint256 _tokenId6, uint256 _tokenId7, uint256 _tokenId8, uint256 _tokenId9, uint256 _tokenId10  ) external onlyC {
     
       require(_to != address(0));
		
        require(_to != address(this));
     
     require( SaddleOwnerIndex[_tokenId1] == msg.sender );
     require( SaddleOwnerIndex[_tokenId2] == msg.sender );
     require( SaddleOwnerIndex[_tokenId3] == msg.sender );
     require( SaddleOwnerIndex[_tokenId4] == msg.sender );
     require( SaddleOwnerIndex[_tokenId5] == msg.sender );
     require( SaddleOwnerIndex[_tokenId6] == msg.sender );
     require( SaddleOwnerIndex[_tokenId7] == msg.sender );
     require( SaddleOwnerIndex[_tokenId8] == msg.sender );
     require( SaddleOwnerIndex[_tokenId9] == msg.sender );
     require( SaddleOwnerIndex[_tokenId10] == msg.sender );
      
      
      
      _transfer(msg.sender,  _to,  _tokenId1);
        
   
      _transfer(msg.sender,  _to,  _tokenId2);
     
      _transfer(msg.sender,  _to,  _tokenId3);
       
      _transfer(msg.sender,  _to,  _tokenId4);
  
      _transfer(msg.sender,  _to,  _tokenId5);
       
      _transfer(msg.sender,  _to,  _tokenId6);
        
      _transfer(msg.sender,  _to,  _tokenId7);
       
      _transfer(msg.sender,  _to,  _tokenId8);
      
      
      _transfer(msg.sender,  _to,  _tokenId9);
      _transfer(msg.sender,  _to,  _tokenId10);
       
    }
    
    function _sell(address _from,  uint256 _tokenId, uint256 value) internal {
     
           uint256 price;
            
            
         if(DutchAListed[_tokenId]==true){
             
        price  = getCurrentSaddlePrice(_tokenId);
                
         }else{
             
        price  = saddleIndexPrice[_tokenId];
             
         }
         
         if(price==0){
             SaddleIndexForSale[_tokenId]=false;
         }
         
     if(SaddleIndexForSale[_tokenId]==true){
          
            require(price<=value);
            
            
            
         uint256 Fee = price / saleFee /2;
            
          uint256  oPrice= price - Fee - Fee;
            
            address _to = msg.sender;
            
            tokenOwnershipCount[_to]++;
            SaddleOwnerIndex[_tokenId] = _to;
            
            SaddleIndexForSale[_tokenId]=false;
         DutchAListed[_tokenId]=false;
            
            
            if (_from != address(0)) {
                tokenOwnershipCount[_from]--;
               
            }
                 
           emit Transfer(_from, _to, _tokenId);
            
            uint256 saddleQ = saddleQuality[_tokenId]/10;
             address SaddleSOwner;
             
              if(saddleQ>=0&&saddleQ<=2){
              SaddleSOwner= SaddleShopO[5];
                 
             }else  if(saddleQ>=2&&saddleQ<=4){
              SaddleSOwner= SaddleShopO[4];
                 
             } else  if(saddleQ>=4&&saddleQ<=6){
             SaddleSOwner=  SaddleShopO[3];
                 
             } else  if(saddleQ>=6&&saddleQ<=8){
             SaddleSOwner=  SaddleShopO[2];
                 
             }else  if(saddleQ>=8&&saddleQ<=10){
             SaddleSOwner=  SaddleShopO[1];
                 
             }else{
                 
             SaddleSOwner= ceoAddress;
             }
             
            
             
             _from.transfer(oPrice);
             
            uint256 bidExcess = value - oPrice - Fee - Fee;
            _to.transfer(bidExcess);
             
             ceoAddress.transfer(Fee);
             
             if(SaddleSOwner!=0){
                 
             SaddleSOwner.transfer(Fee);
             }else {
             ceoAddress.transfer(Fee);
                 
             }
            
            
     }else{
          _to.transfer(value);
     }
      
    }
    
    
    
    
    
    

      function getCurrentSaddlePrice(uint256 _id) public view returns (uint256)  {
          
      uint256     currentPrice= startDutchAPrice[_id] - DutchADecreaseRate[_id]*(block.number - startDutchABlock[_id]);
  if(currentPrice <=0 ){
      return 0;
  }else if(currentPrice>startDutchAPrice[_id]){
      
      return 0;
  }else{
      
    return currentPrice;
  }
  }
    
      function newDutchPriceRate(uint DecreRate,uint256 _id) external  {
               
               require(msg.sender==SaddleOwnerIndex[_id]);
               
               require(DutchAListed[_id]==true);
               
                DutchADecreaseRate[_id]=DecreRate;
  }
    
    
    
    
       
    function setForDutchSale(uint256 _id, uint256 price, uint256 _decreRate) external {
        
               require(msg.sender==SaddleOwnerIndex[_id]);
        
                 require(raceListed[_id]==false);
                 
        SaddleShopPrice[_id]=price;
        
            
                DutchAListed[_id]=true;
                
                  startDutchABlock[_id] = block.number;
                  
                  startDutchAPrice[_id] = price;
                  
                 DutchADecreaseRate[_id]= _decreRate;
                 
                SaddleIndexForSale[_id]=true;
    }
    
  
    
    
    
    
	
    function _newSaddle(
        uint256 _genes1,
        uint256 _genes2,
        uint256 _genes3,
        bool _genes4,
        address _owner
    )
        internal
        returns (uint)
    {
   
   
   
   
        SaddleAttr memory _saddle = SaddleAttr({
          dna1:_genes1,  
        dna2: _genes2,
        dna3 : _genes3,
        dna4: _genes4
            
        });
       
       
        
       uint256 newSaddleId;
	   
     newSaddleId = Saddles.push(_saddle)-1;
     
  
        require(newSaddleId == uint256(uint32(newSaddleId)));


        
       saddleQuality[newSaddleId]= (_genes1 +_genes2 + _genes3)/3;
        
        raceListed[newSaddleId]=false;
        
       emit Birth(_owner, newSaddleId);

        _transfer(0, _owner, newSaddleId);

        return newSaddleId;  
    }



}


contract SaddleOwnership is SaddleBasis{

  string public constant  name = "CryptoSaddle";
    string public constant symbol = "CSD";
     uint8 public constant decimals = 0; 

    function SaddleForSale(uint256 _tokenId, uint256 price) external { 
  
     address  ownerof =  SaddleOwnerIndex[_tokenId];
        require(ownerof == msg.sender);
        
                 require(raceListed[_tokenId]==false);
                 
       uint256 forDutch =  getCurrentSaddlePrice(_tokenId);
  
      require(forDutch==0||DutchAListed[_tokenId]==false);
                 
        saddleIndexPrice[_tokenId] = price;
       SaddleIndexForSale[_tokenId]= true;
       DutchAListed[_tokenId]=false;
       
       
		}
		

		
 function changePrice(uint256 _tokenId, uint256 price) external {
  
     address  ownerof =  SaddleOwnerIndex[_tokenId];
        require(ownerof == msg.sender);
        require(SaddleIndexForSale[_tokenId] == true);
  
  
      require(DutchAListed[_tokenId]==false);
          
             saddleIndexPrice[_tokenId] = price;
      
             
         
		}

 function SaddleNotForSale(uint256 _tokenId) external {
         address  ownerof =  SaddleOwnerIndex[_tokenId];
            require(ownerof == msg.sender);
       SaddleIndexForSale[_tokenId]= false;
         DutchAListed[_tokenId]=false;

    }


    function _owns(address _applicant, uint256 _tokenId) internal view returns (bool) {
        return SaddleOwnerIndex[_tokenId] == _applicant;
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
                 
                require(_from==SaddleOwnerIndex[_tokenId]);
        
               _sell(_from,  _tokenId, msg.value);
            
        }else{
            
          _to.transfer(msg.value);
        }
 
    }

    function totalSupply() public view returns (uint) {
        return Saddles.length;
    }

    function ownerOf(uint256 _tokenId)  external view returns (address owner)  {
        owner = SaddleOwnerIndex[_tokenId];

       return;
       
    }
    
    function ownerOfID(uint256 _tokenId)  external view returns (address owner, uint256 tokenId)  {
        owner = SaddleOwnerIndex[_tokenId];
tokenId=_tokenId;
       return;
       
    }

       function SaddleFS(uint256 _tokenId) external view  returns (bool buyable, uint256 tokenId) {
      
	bool	forDutchSale=DutchAListed[_tokenId];
	uint256 price;
	
		if(	forDutchSale==true){
		    	price = getCurrentSaddlePrice(_tokenId);
		}else{
		    	price = saddleIndexPrice[_tokenId];
		}	
		if(price==0){
		    buyable=false;
		}else{
		    
        buyable = SaddleIndexForSale[_tokenId];
		}
		
        tokenId=_tokenId;
       return;
       
    }
	
	function SaddlePr(uint256 _tokenId) external view  returns (uint256 price, uint256 tokenId) {
        price = saddleIndexPrice[_tokenId];
        tokenId=_tokenId;
       return;
       
    }

 function setSaleFee(uint256 val) external onCTO {
        saleFee = val;
    }


function raceOut(uint256 _tokenIdA) external {
    
    require(msg.sender==raceDistCon);

    
		
      SaddleAttr storage saddleA = Saddles[_tokenIdA];
    
    saddleA.dna4=true;
    
	  
	  raceListed[_tokenIdA]=false;
    
      
}


function raceRegistration(uint256 _tokenIdA, address owner) external {
    
   require(msg.sender==raceDistCon);
    
    
  require(SaddleOwnerIndex[_tokenIdA]==owner);
  
      SaddleAttr storage saddleA = Saddles[_tokenIdA];
    require(saddleA.dna4==true);
    
    require( raceListed[_tokenIdA]==false);
    
          
	bool forDutchSale=DutchAListed[_tokenIdA];
	uint256 price;
	
		if(	forDutchSale==true){
		    	price = getCurrentSaddlePrice(_tokenIdA);
		}else{
		    	price = saddleIndexPrice[_tokenIdA];
		}
    
    bool buyable;
    
    if(price==0){
		    buyable=false;
		}else{
		    
        buyable = SaddleIndexForSale[_tokenIdA];
		}
		
		
	require(buyable==false);
	
        
		
    
    saddleA.dna4=false;
    
    raceListed[_tokenIdA]=true;
	
	
		
        
}


    
}



contract SaddleMinting is SaddleOwnership {

    uint256 public  Saddle_Limit = 20000;


    
        function createSaddle1(   uint256 _genes1, uint256 _genes2,uint256 _genes3, address _owner) external onlyC {
        address SaddleOwner = _owner;
        
   require(Saddles.length+1 < Saddle_Limit);

              _newSaddle(_genes1, _genes2, _genes3,true, SaddleOwner);
            
          
        
    }
    
    function createSaddle6(
    uint256 _genes1, 
    uint256 _genes2,
    uint256 _genes3,
    uint256 _genes1a, 
    uint256 _genes2a,
    uint256 _genes3a,
    uint256 _genes1b, 
    uint256 _genes2b,
    uint256 _genes3b,
    address _owner
    ) external onlyC {
        address SaddleOwner = _owner;
        
   require(Saddles.length+6 < Saddle_Limit);


             
              _newSaddle(_genes1, _genes2, _genes3,true, SaddleOwner);
              _newSaddle(_genes1a, _genes2a, _genes3a,true, SaddleOwner); 
              _newSaddle(_genes1b, _genes2b, _genes3b,true, SaddleOwner);
              _newSaddle(_genes1, _genes2, _genes3,true, SaddleOwner);
              _newSaddle(_genes1a, _genes2a, _genes3a,true, SaddleOwner); 
              _newSaddle(_genes1b, _genes2b, _genes3b,true, SaddleOwner);
    }
  

  
    
       function _generateNewSaddle(uint256 saddleM_quality ,uint256 maschine_quality, uint256 leader_qual, address _owner) external {
    
        
   require(msg.sender==addr_Saddlery);
        
              _newSaddle(leader_qual, saddleM_quality, maschine_quality,true, _owner);

        
    }
   
   
}


contract GetTheSaddle is SaddleMinting {


    function getSaddle(uint256 _id)
        external
        view
        returns (
        uint256 price,
        uint256 id,
        bool forSale,
        bool forDutchSale,
        uint256 _genes1,
        uint256 _genes2,
        uint256 _genes3,
        bool _genes4
		
    ) {
        id = uint256(_id);
		forDutchSale=DutchAListed[_id];
		
		if(	forDutchSale==true){
		    	price = getCurrentSaddlePrice(_id);
		}else{
		    	price = saddleIndexPrice[_id];
		}	
		       
    
    if(price==0){
		    forSale=false;
		forDutchSale=false;
		    
		}else{
		    
        forSale = SaddleIndexForSale[_id];
		}
		
		
		
        SaddleAttr storage saddle = Saddles[_id];
        
        _genes1 = saddle.dna1;
        _genes2 = saddle.dna2;
        _genes3 = saddle.dna3;
        _genes4 = saddle.dna4;
		

    }

  

}