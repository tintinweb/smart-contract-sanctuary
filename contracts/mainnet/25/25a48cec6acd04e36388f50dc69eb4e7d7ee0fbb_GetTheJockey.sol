pragma solidity ^0.4.20;


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
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
    function ownerOf(uint256 _tokenId) external view returns (address owner, uint256 tokenId);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;


    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
    
    
    
}



contract JockeyControl  {

    address public ceoAddress=0xf75Da6b04108394fDD349f47d58452A6c8Aeb236;
    address public ctoAddress=0x833184cE7DF8E56a716B7738548BfC488E428Da5;
 

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

 
}





contract HoresBasis is  JockeyControl {
   
    event Birth(address owner, uint256 JockeyId);
   
    event Transfer(address from, address to, uint256 tokenId);

    struct Jockey {
        uint64 birthTime;
        uint256 dna1;
        uint256 dna2;
        uint256 dna3;
        uint256 dna4;
        uint256 dna5;
        uint256 dna6;
        uint256 dna7;
        uint256 dna8;
        
    }


    Jockey[] jockeys;

    mapping (uint256 => address) jockeyOwnerIndex;
    
    mapping (uint256 => uint256) public jockeyIndexPrice;
    
    mapping (uint256 => uint256) public jockeyHair;
    
    mapping (uint256 => uint256) public jockeySkin;
    
    mapping (uint256 => uint256) public jockeyHLength;
    
    mapping (uint256 => bool)  jockeyIndexForSale;

    mapping (address => uint256) tokenOwnershipCount;


   uint256 public saleFee = 20;

   
   
 
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        tokenOwnershipCount[_to]++;
        jockeyOwnerIndex[_tokenId] = _to;
        
        if (_from != address(0)) {
            tokenOwnershipCount[_from]--;
         
        }
       emit Transfer(_from, _to, _tokenId);
       
    }
    
    
    function _sell(address _from,  uint256 _tokenId, uint256 value) internal {
     
     if(jockeyIndexForSale[_tokenId]==true){
         
              uint256 price = jockeyIndexPrice[_tokenId];
            
            require(price<=value);
            
         uint256 Fee = price / saleFee;
            
          uint256  oPrice= price - Fee;
            
            address _to = msg.sender;
            
            tokenOwnershipCount[_to]++;
            jockeyOwnerIndex[_tokenId] = _to;
            
            jockeyIndexForSale[_tokenId]=false;
            
            
            if (_from != address(0)) {
                tokenOwnershipCount[_from]--;
               
            }
                 
           emit Transfer(_from, _to, _tokenId);
             
             _from.transfer(oPrice);
             
             ceoAddress.transfer(Fee);
             
            uint256 bidExcess = value - oPrice - Fee;
            _to.transfer(bidExcess);
            
            
     }else{
          _to.transfer(value);
     }
      
    }
    
    
	
    function _newJockey(
        uint256 _genes1,
        uint256 _genes2,
        uint256 _genes3,
        uint256 _genes4,
        uint256 _genes5,
        uint256 _genes6,
        uint256 _genes7,
        uint256 _genes8,
        address _owner
    )
        internal
        returns (uint)
    {
   
   
   
   
        Jockey memory _jockey = Jockey({
           birthTime: uint64(now),
           
             
        dna1:_genes1,
        dna2: _genes2,
        dna3 : _genes3,
        dna4 : _genes4,
        dna5 : _genes5,
        dna6 : _genes6,
        dna7:_genes7,
        dna8: _genes8
            
        });
       
       
        
       uint256 newJockeyId;
	   
     newJockeyId = jockeys.push(_jockey)-1;
     
  
        require(newJockeyId == uint256(uint32(newJockeyId)));


        
        
       emit Birth(_owner, newJockeyId);

        _transfer(0, _owner, newJockeyId);

        return newJockeyId;  
    }



}


contract JockeyOwnership is HoresBasis, ERC721{

  string public constant  name = "CryptoJockey";
    string public constant symbol = "CHJ";
     uint8 public constant decimals = 0; 

    function jockeyForSale(uint256 _tokenId, uint256 price) external {
  
     address  ownerof =  jockeyOwnerIndex[_tokenId];
        require(ownerof == msg.sender);
        jockeyIndexPrice[_tokenId] = price;
        jockeyIndexForSale[_tokenId]= true;
		}
		
 function changePrice(uint256 _tokenId, uint256 price) external {
  
     address  ownerof =  jockeyOwnerIndex[_tokenId];
        require(ownerof == msg.sender);
        require(jockeyIndexForSale[_tokenId] == true);
       
             
              jockeyIndexPrice[_tokenId] = price;
         
		}

 function jockeyNotForSale(uint256 _tokenId) external {
         address  ownerof =  jockeyOwnerIndex[_tokenId];
            require(ownerof == msg.sender);
        jockeyIndexForSale[_tokenId]= false;

    }


    function _owns(address _applicant, uint256 _tokenId) internal view returns (bool) {
        return jockeyOwnerIndex[_tokenId] == _applicant;
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
                 
                require(_from==jockeyOwnerIndex[_tokenId]);
        
               _sell(_from,  _tokenId, msg.value);
            
        }else{
            
          _to.transfer(msg.value);
        }
 
    }

    function totalSupply() public view returns (uint) {
        return jockeys.length;
    }

    function ownerOf(uint256 _tokenId)  external view returns (address owner, uint256 tokenId)  {
        owner = jockeyOwnerIndex[_tokenId];
        tokenId=_tokenId;
       
       return;
       
    }

       function jockeyFS(uint256 _tokenId) external view  returns (bool buyable, uint256 tokenId) {
        buyable = jockeyIndexForSale[_tokenId];
        tokenId=_tokenId;
       return;
       
    }
	
	function jockeyPr(uint256 _tokenId) external view  returns (uint256 price, uint256 tokenId) {
        price = jockeyIndexPrice[_tokenId];
        tokenId=_tokenId;
       return;
       
    }

 function setSaleFee(uint256 val) external onCTO {
        saleFee = val;
    }

    
}


contract JockeyMinting is JockeyOwnership {

    uint256 public  JOCKEY_LIMIT = 20000;


    function createJockey(uint256 _genes1,uint256 _genes2,uint256 _genes3,uint256 _genes4,uint256 _genes5,uint256 _genes6,uint256 _genes7,uint256 _genes8,uint256 jHair,uint256 jHLenth,uint256 jSkin, address _owner) external onlyC {
        address jockeyOwner = _owner;
        
   require(jockeys.length < JOCKEY_LIMIT);

            
              _newJockey(  _genes1, _genes2, _genes3, _genes4, _genes5, _genes6,_genes7, _genes8,  jockeyOwner);
            
            
        uint256   jId=jockeys.length;
            
        jockeyHair[jId] = jHair;
        jockeyHLength[jId] = jHLenth;
        jockeySkin[jId] = jSkin;
            
        
    }

   
}


contract GetTheJockey is JockeyMinting {


    function getJockey(uint256 _id)
        external
        view
        returns (
        uint256 price,
        uint256 id,
        bool forSale,
        uint256 birthTime,
        uint256 _genes1,
        uint256 _genes2,
        uint256 _genes3,
        uint256 _genes4,
        uint256 _genes5,
        uint256 _genes6,
        uint256 _genes7,
        uint256 _genes8
		
    ) {
		price = jockeyIndexPrice[_id];
        id = uint256(_id);
		forSale = jockeyIndexForSale[_id];
        Jockey storage horseman = jockeys[_id];
        birthTime = uint256(horseman.birthTime);
        _genes1 = horseman.dna1;
        _genes2 = horseman.dna2;
        _genes3 = horseman.dna3;
        _genes4 = horseman.dna4;
        _genes5 = horseman.dna5;
        _genes6 = horseman.dna6;  
        _genes7 = horseman.dna7;
        _genes8 = horseman.dna8;

    }

  

}