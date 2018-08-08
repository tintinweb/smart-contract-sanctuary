pragma solidity ^0.4.18;

contract HeroAccessControl {
    event ContractUpgrade(address newContract);
    address public leaderAddress;
    address public opmAddress;
    
    bool public paused = false;

    modifier onlyLeader() {
        require(msg.sender == leaderAddress);
        _;
    }
    modifier onlyOPM() {
        require(msg.sender == opmAddress);
        _;
    }

    modifier onlyMLevel() {
        require(
            msg.sender == opmAddress ||
            msg.sender == leaderAddress
        );
        _;
    }

    function setLeader(address _newLeader) public onlyLeader {
        require(_newLeader != address(0));
        leaderAddress = _newLeader;
    }

    function setOPM(address _newOPM) public onlyLeader {
        require(_newOPM != address(0));
        opmAddress = _newOPM;
    }

    function withdrawBalance() external onlyLeader {
        leaderAddress.transfer(this.balance);
    }


    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyMLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyLeader whenPaused {
        paused = false;
    }
    
    
}


contract ERC20{

bool public isERC20 = true;

function balanceOf(address who) constant returns (uint256);

function transfer(address _to, uint256 _value) returns (bool);

function transferFrom(address _from, address _to, uint256 _value) returns (bool);

function approve(address _spender, uint256 _value) returns (bool);

function allowance(address _owner, address _spender) constant returns (uint256);

}


contract HeroLedger is HeroAccessControl{
    ERC20 public erc20;
    
    mapping (address => uint256) public ownerIndexToERC20Balance;  
    mapping (address => uint256) public ownerIndexToERC20Used;  
    uint256 public totalBalance;
    uint256 public totalUsed;
    
    uint256 public totalPromo;
    uint256 public candy;
        
    function setERC20Address(address _address,uint256 _totalPromo,uint256 _candy) public onlyLeader {
        ERC20 candidateContract = ERC20(_address);
        require(candidateContract.isERC20());
        erc20 = candidateContract; 
        uint256 realTotal = erc20.balanceOf(this); 
        require(realTotal >= _totalPromo);
        totalPromo=_totalPromo;
        candy=_candy;
    }
    
    function setERC20TotalPromo(uint256 _totalPromo,uint256 _candy) public onlyLeader {
        uint256 realTotal = erc20.balanceOf(this);
        totalPromo +=_totalPromo;
        require(realTotal - totalBalance >= totalPromo); 
        
        candy=_candy;
    }
 
    function charge(uint256 amount) public {
    		if(erc20.transferFrom(msg.sender, this, amount)){
    				ownerIndexToERC20Balance[msg.sender] += amount;
    				totalBalance +=amount;
    		}
    }	
		
		function collect(uint256 amount) public {
				require(ownerIndexToERC20Balance[msg.sender] >= amount);
    		if(erc20.transfer(msg.sender, amount)){
    				ownerIndexToERC20Balance[msg.sender] -= amount;
    				totalBalance -=amount;
    		}
    }
    
    function withdrawERC20Balance(uint256 amount) external onlyLeader {
        uint256 realTotal = erc20.balanceOf(this);
     		require((realTotal -  (totalPromo  + totalBalance- totalUsed ) )  >=amount);
        erc20.transfer(leaderAddress, amount);
        totalBalance -=amount;
        totalUsed -=amount;
    }
    
    
    function withdrawOtherERC20Balance(uint256 amount, address _address) external onlyLeader {
    		require(_address != address(erc20));
    		require(_address != address(this));
        ERC20 candidateContract = ERC20(_address);
        uint256 realTotal = candidateContract.balanceOf(this);
        require( realTotal >= amount );
        candidateContract.transfer(leaderAddress, amount);
    }
    

}

contract HeroBase is  HeroLedger{
    event Recruitment(address indexed owner, uint256 heroId, uint256 yinId, uint256 yangId, uint256 talent);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ItmesChange(uint256 indexed tokenId, uint256 items);
    
    address public magicStore;

    struct Hero {
        uint256 talent;
        uint64 recruitmentTime;
        uint64 cooldownEndTime;
        uint32 yinId;
        uint32 yangId;
        uint16 cooldownIndex;
        uint16 generation;        
        uint256 belongings;       
        uint32 items;
    }    
    
    uint32[14] public cooldowns = [
    
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];
        
    uint128 public cdFee = 118102796674000; 

    Hero[] heroes;
    mapping (uint256 => address) public heroIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;

    mapping (uint256 => address) public heroIndexToApproved;   
    mapping (uint256 => uint32) public heroIndexToWin;   
    mapping (uint256 => uint32) public heroIndexToLoss;
  
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        heroIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete heroIndexToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

    function _createHero(
        uint256 _yinId,
        uint256 _yangId,
        uint256 _generation,
        uint256 _talent,
        address _owner
	)
        internal
        returns (uint)
    {
        require(_generation <= 65535);
       
        
        uint16 _cooldownIndex = uint16(_generation/2);
        if(_cooldownIndex > 13){
        	_cooldownIndex =13;
        }   
        Hero memory _hero = Hero({
            talent: _talent,
            recruitmentTime: uint64(now),
            cooldownEndTime: 0,
            yinId: uint32(_yinId),
            yangId: uint32(_yangId),
            cooldownIndex: _cooldownIndex,
            generation: uint16(_generation),
            belongings: _talent,
            items: uint32(0)
        });
        uint256 newHeroId = heroes.push(_hero) - 1;
        require(newHeroId <= 4294967295);
        Recruitment(
            _owner,
            newHeroId,
            uint256(_hero.yinId),
            uint256(_hero.yangId),
            _hero.talent
        );
        _transfer(0, _owner, newHeroId);

        return newHeroId;
    } 
    
    function setMagicStore(address _address) public onlyOPM{
       magicStore = _address;
    }
 
}

contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}

contract HeroOwnership is HeroBase, ERC721 {

    string public name = "MyHero";
    string public symbol = "MH";

    function implementsERC721() public pure returns (bool)
    {
        return true;
    }
    
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return heroIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return heroIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        heroIndexToApproved[_tokenId] = _approved;
    }

    function rescueLostHero(uint256 _heroId, address _recipient) public onlyOPM whenNotPaused {
        require(_owns(this, _heroId));
        _transfer(this, _recipient, _heroId);
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
    {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
    {
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return heroes.length - 1;
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = heroIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    function tokensOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 tokenId)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (heroIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }

}

contract MasterRecruitmentInterface {
    function isMasterRecruitment() public pure returns (bool);   
    function fightMix(uint256 belongings1, uint256 belongings2) public returns (bool,uint256,uint256,uint256);    
}


contract HeroFighting is HeroOwnership {
  
    MasterRecruitmentInterface public masterRecruitment;
    function setMasterRecruitmentAddress(address _address) public onlyLeader {
        MasterRecruitmentInterface candidateContract = MasterRecruitmentInterface(_address);
        require(candidateContract.isMasterRecruitment());
        masterRecruitment = candidateContract;
    }

    function _triggerCooldown(Hero storage _newHero) internal {
        _newHero.cooldownEndTime = uint64(now + cooldowns[_newHero.cooldownIndex]);
        if (_newHero.cooldownIndex < 13) {
            _newHero.cooldownIndex += 1;
        }
    }

    function isReadyToFight(uint256 _heroId)
        public
        view
        returns (bool)
    {
        require(_heroId > 0);
	      Hero memory hero = heroes[_heroId];
        return (hero.cooldownEndTime <= now);
    }

    function _fight(uint32 _yinId, uint32 _yangId)
        internal 
        whenNotPaused
        returns(uint256)
    {
        Hero storage yin = heroes[_yinId];
        require(yin.recruitmentTime != 0);
        Hero storage yang = heroes[_yangId];
        uint16 parentGen = yin.generation;
        if (yang.generation > yin.generation) {
            parentGen = yang.generation;
        }        
        var (flag, childTalent, belongings1,  belongings2) = masterRecruitment.fightMix(yin.belongings,yang.belongings);
        yin.belongings = belongings1;
        yang.belongings = belongings2;                
	      if(!flag){      
           (_yinId,_yangId) = (_yangId,_yinId);
        }    
        address owner = heroIndexToOwner[_yinId];
        heroIndexToWin[_yinId] +=1;
        heroIndexToLoss[_yangId] +=1;
        uint256 newHeroId = _createHero(_yinId, _yangId, parentGen + 1, childTalent, owner); 
        _triggerCooldown(yang);
        _triggerCooldown(yin);
        return (newHeroId );
    }
    
    
   
    
     function reduceCDFee(uint256 heroId) 
         public 
         view 
         returns (uint256 fee)
    {
    		Hero memory hero = heroes[heroId];
    		require(hero.cooldownEndTime > now);
    		uint64 cdTime = uint64(hero.cooldownEndTime-now);
    		fee= uint256(cdTime * cdFee * (hero.cooldownIndex+1));
    		
    }
    
    
    
}


contract ClockAuction {
    //bool public isClockAuction = true;
    
    function withdrawBalance() external ;
      
    function order(uint256 _tokenId, uint256 orderAmount ,address buyer)
        public  returns (bool);
    
     function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _startingPriceEth,
        uint256 _endingPriceEth,
        uint256 _duration,
        address _seller
    )
        public;
    
    function getSeller(uint256 _tokenId)
        public
        returns
    (
        address seller
    ); 
    
     function getCurrentPrice(uint256 _tokenId, uint8 ccy)
        public
        view
        returns (uint256);
        
}

contract FightClockAuction is ClockAuction {
    bool public isFightClockAuction = true;
}

contract SaleClockAuction is ClockAuction {
    bool public isSaleClockAuction = true;
    function averageGen0SalePrice() public view returns (uint256);
}

contract HeroAuction is HeroFighting {

		SaleClockAuction public saleAuction;
    FightClockAuction public fightAuction;
    uint256 public ownerCut =500;    
    
    function setSaleAuctionAddress(address _address) public onlyLeader {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

    function setFightAuctionAddress(address _address) public onlyLeader {
        FightClockAuction candidateContract = FightClockAuction(_address);
        require(candidateContract.isFightClockAuction());
        fightAuction = candidateContract;
    }
    

    function createSaleAuction(
        uint256 _heroId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _startingPriceEth,
        uint256 _endingPriceEth,
        uint256 _duration
    )
        public
    {
        require(_owns(msg.sender, _heroId));
        _approve(_heroId, saleAuction);
        saleAuction.createAuction(
            _heroId,
            _startingPrice,
            _endingPrice,
            _startingPriceEth,
            _endingPriceEth,
            _duration,
            msg.sender
        );
    }
    
    function orderOnSaleAuction(
        uint256 _heroId,
        uint256 orderAmount
    )
        public
    {
        require(ownerIndexToERC20Balance[msg.sender] >= orderAmount); 
        address saller = saleAuction.getSeller(_heroId);
        uint256 price = saleAuction.getCurrentPrice(_heroId,1);
        require( price <= orderAmount && saller != address(0));
       
        if(saleAuction.order(_heroId, orderAmount, msg.sender)  &&orderAmount >0 ){
         
	          ownerIndexToERC20Balance[msg.sender] -= orderAmount;
	    		  ownerIndexToERC20Used[msg.sender] += orderAmount;  
	    		  
	    		  if( saller == address(this)){
	    		     totalUsed +=orderAmount;
	    		  }else{
	    		     uint256 cut = _computeCut(price);
	    		     totalUsed += (orderAmount - price +cut);
	    		     ownerIndexToERC20Balance[saller] += price -cut;
	    		  }	
         } 
          
        
    }
    

    function createFightAuction(
        uint256 _heroId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _heroId));
        require(isReadyToFight(_heroId));
        _approve(_heroId, fightAuction);
        fightAuction.createAuction(
            _heroId,
            _startingPrice,
            _endingPrice,
            0,
            0,
            _duration,
            msg.sender
        );
    }    

    function orderOnFightAuction(
        uint256 _yangId,
        uint256 _yinId,
        uint256 orderAmount
    )
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _yinId));
        require(isReadyToFight(_yinId));
        require(_yinId !=_yangId);
        require(ownerIndexToERC20Balance[msg.sender] >= orderAmount);
        
        address saller= fightAuction.getSeller(_yangId);
        uint256 price = fightAuction.getCurrentPrice(_yangId,1);
      
        require( price <= orderAmount && saller != address(0));
        
        if(fightAuction.order(_yangId, orderAmount, msg.sender)){
	         _fight(uint32(_yinId), uint32(_yangId));
	        ownerIndexToERC20Balance[msg.sender] -= orderAmount;
	    		ownerIndexToERC20Used[msg.sender] += orderAmount;  
	    		
    		  if( saller == address(this)){
    		     totalUsed +=orderAmount;
    		  }else{
    		     uint256 cut = _computeCut(price);
    		     totalUsed += (orderAmount - price+cut);
    		     ownerIndexToERC20Balance[saller] += price-cut;
    		  }	  
	        
        }
    }

    function withdrawAuctionBalances() external onlyOPM {
        saleAuction.withdrawBalance();
        fightAuction.withdrawBalance();
    }
    
    function setCut(uint256 newCut) public onlyOPM{
        ownerCut = newCut;
    }
    
    
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }  
    
    
    function promoBun(address _address) public {
        require(msg.sender == address(saleAuction));
        if(totalPromo >= candy && candy > 0){
          ownerIndexToERC20Balance[_address] += candy;
          totalPromo -=candy;
         }
    } 

}

contract HeroMinting is HeroAuction {

    uint256 public promoCreationLimit = 5000;
    uint256 public gen0CreationLimit = 50000;
    
    uint256 public gen0StartingPrice = 100000000000000000;
    uint256 public gen0AuctionDuration = 1 days;

    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    function createPromoHero(uint256 _talent, address _owner) public onlyOPM {
        if (_owner == address(0)) {
             _owner = opmAddress;
        }
        require(promoCreatedCount < promoCreationLimit);
        require(gen0CreatedCount < gen0CreationLimit);

        promoCreatedCount++;
        gen0CreatedCount++;
        _createHero(0, 0, 0, _talent, _owner);
    }

    function createGen0Auction(uint256 _talent,uint256 price) public onlyOPM {
        require(gen0CreatedCount < gen0CreationLimit);
        require(price < 340282366920938463463374607431768211455);

        uint256 heroId = _createHero(0, 0, 0, _talent, address(this));
        _approve(heroId, saleAuction);
				if(price == 0 ){
				     price = _computeNextGen0Price();
				}
				
        saleAuction.createAuction(
            heroId,
            price *1000,
            0,
            price,
            0,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        require(avePrice < 340282366920938463463374607431768211455);

        uint256 nextPrice = avePrice + (avePrice / 2);

        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
    
    
}

contract HeroCore is HeroMinting {

    address public newContractAddress;

    function HeroCore() public {

        paused = true;

        leaderAddress = msg.sender;

        opmAddress = msg.sender;

        _createHero(0, 0, 0, uint256(-1), address(0));
    }

    function setNewAddress(address _v2Address) public onlyLeader whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    function() external payable {
        require(
            msg.sender != address(0)
        );
    }
    
    function getHero(uint256 _id)
        public
        view
        returns (
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 recruitmentTime,
        uint256 yinId,
        uint256 yangId,
        uint256 generation,
	      uint256 talent,
	      uint256 belongings,
	      uint32 items
	    
    ) {
        Hero storage her = heroes[_id];
        isReady = (her.cooldownEndTime <= now);
        cooldownIndex = uint256(her.cooldownIndex);
        nextActionAt = uint256(her.cooldownEndTime);
        recruitmentTime = uint256(her.recruitmentTime);
        yinId = uint256(her.yinId);
        yangId = uint256(her.yangId);
        generation = uint256(her.generation);
	      talent = her.talent;
	      belongings = her.belongings;
	      items = her.items;
    }

    function unpause() public onlyLeader whenPaused {
        require(saleAuction != address(0));
        require(fightAuction != address(0));
        require(masterRecruitment != address(0));
        require(erc20 != address(0));
        require(newContractAddress == address(0));

        super.unpause();
    }
    
    
     function setNewCdFee(uint128 _cdFee) public onlyOPM {
        cdFee = _cdFee;
    }
     
    function reduceCD(uint256 heroId,uint256 reduceAmount) 
         public  
         whenNotPaused 
    {
    		Hero storage hero = heroes[heroId];
    		require(hero.cooldownEndTime > now);
    		require(ownerIndexToERC20Balance[msg.sender] >= reduceAmount);
    		
    		uint64 cdTime = uint64(hero.cooldownEndTime-now);
    		require(reduceAmount >= uint256(cdTime * cdFee * (hero.cooldownIndex+1)));
    		
    		ownerIndexToERC20Balance[msg.sender] -= reduceAmount;
    		ownerIndexToERC20Used[msg.sender] += reduceAmount;  
        totalUsed +=reduceAmount;
    		hero.cooldownEndTime = uint64(now);
    }
    
    function useItems(uint32 _items, uint256 tokenId, address owner, uint256 fee) public returns (bool flag){
      require(msg.sender == magicStore);
      require(owner == heroIndexToOwner[tokenId]);        
         heroes[tokenId].items=_items;
         ItmesChange(tokenId,_items);      
      ownerIndexToERC20Balance[owner] -= fee;
    	ownerIndexToERC20Used[owner] += fee;  
      totalUsed +=fee;
      
      flag = true;
    }

}