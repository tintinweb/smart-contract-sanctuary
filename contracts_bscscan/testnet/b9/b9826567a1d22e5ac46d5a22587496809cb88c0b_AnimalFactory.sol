/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-05
*/

/**
 *Submitted for verification at Etherscan.io on 2018-05-29
*/


 
pragma solidity ^0.4.23;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// The ERC-721 Interface to reference the animal factory token
interface ERC721Interface {
     function totalSupply() public view returns (uint256);
     function safeTransferFrom(address _from, address _to, uint256 _tokenId);
     function burnToken(address tokenOwner, uint256 tid) ;
     function sendToken(address sendTo, uint tid, string tmeta) ;
     function getTotalTokensAgainstAddress(address ownerAddress) public constant returns (uint totalAnimals);
     function getAnimalIdAgainstAddress(address ownerAddress) public constant returns (uint[] listAnimals);
     function balanceOf(address _owner) public view returns (uint256 _balance);
     function ownerOf(uint256 _tokenId) public view returns (address _owner);
     function setAnimalMeta(uint tid, string tmeta);
}


contract AnimalFactory is Ownable
{
    //The structure defining a single animal
    struct AnimalProperties
    {
        uint id;
        string name;
        string desc;
		string attributes;
        bool upForSale;
        uint priceForSale;
        bool upForMating;
        bool eggPhase;
        uint priceForMating;
        bool isBornByMating;
        uint parentId1;
        uint parentId2;
        uint birthdate;
        uint assetsId;
        uint generationId;
		uint cuteVotes;
		
    }
    
    using SafeMath for uint256;
 
    // The token being sold
    ERC721Interface public token;
    
    
    //sequentially generated ids for the animals
    uint uniqueAnimalId=0;

    //mapping to show all the animal properties against a single id
    mapping(uint=>AnimalProperties)  animalAgainstId;
    
    //mapping to show how many children does a single animal has
    mapping(uint=>uint[])  childrenIdAgainstAnimalId;
    
    //the animals that have been advertised for mating
    uint[] upForMatingList;

    //the animals that have been advertised for selling
    uint[] upForSaleList;
    
    //the list of addresses that can remove animals from egg phase 
    address[] memberAddresses;

    //animal object to be used in various functions as an intermediate variable
    AnimalProperties  animalObject;
	
    //the number of animals limit
    uint public totalAnimalsMax = 10000;

	// Total free Animals created
    uint256 public totalFreeAnimalsMax=1500;

    //the number of free animals an address can claim
    uint public freeAnimalsLimit = 1;
    
    //variable to show whether the contract has been paused or not
    bool public isContractPaused;
	
	//variable to show whether the minting has been paused or not
    bool public isMintingPaused;
	
	//variable to show if mating is paused
	bool public isMatingPaused;

	///ether means bnb here
    //rate of each animal
    uint256 public weiPerAnimal = 0.15 ether;
    uint public priceForBuyingAssets = 0.25 ether;
	
	//the fees for advertising an animal for sale and mate
    uint public priceForMateAdvertisement = 0.025 ether;
    uint public priceForSaleAdvertisement = 0.025 ether;
	uint public priceForSuccessfulSale = 0.05 ether;
	
	//The owner percentages from mating and selling transactions
    uint public ownerPerThousandShareForMating = 2;
    uint public ownerPerThousandShareForBuying = 5;

    // amount of raised money in wei
    uint256 public weiRaised;

    // Total no of Animals created
    uint256 public totalAnimalsCreated=0;
	



	

	
	
    uint[] eggPhaseAnimalIds;
    uint[] animalIdsWithPendingAssetss;

    /**
     * event for animals purchase logging
     * @param purchaser who paid for the animals
     * @param beneficiary who got the animals
     * @param value weis paid for purchase
     * @param amount of animals purchased
    */
    event AnimalsPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  
   function AnimalFactory(address _walletOwner,address _tokenAddress) public 
   { 
        require(_walletOwner != 0x0);
        owner = _walletOwner;
        isContractPaused = false;
		isMintingPaused = false;
		isMatingPaused = true;
        priceForMateAdvertisement = 0.025 ether;
        priceForSaleAdvertisement = 0.025 ether;
        priceForBuyingAssets = 0.25 ether;
        token = ERC721Interface(_tokenAddress);
    }

    /**
     * function to get animal details by id
     **/ 
    
    function getAnimalById(uint aid) public constant returns 
    (string, string,uint,uint ,uint, uint,uint)
    {
        if(animalAgainstId[aid].eggPhase==true)
        {
            return(animalAgainstId[aid].name,
            animalAgainstId[aid].desc,
            2**256 - 1,
            animalAgainstId[aid].priceForSale,
            animalAgainstId[aid].priceForMating,
            animalAgainstId[aid].parentId1,
            animalAgainstId[aid].parentId2
            );
        }
        else 
        {
            return(animalAgainstId[aid].name,
            animalAgainstId[aid].desc,
            animalAgainstId[aid].id,
            animalAgainstId[aid].priceForSale,
            animalAgainstId[aid].priceForMating,
            animalAgainstId[aid].parentId1,
            animalAgainstId[aid].parentId2
            );
        }
    }
	
	
	
	function getAnimalNameDescAttribById(uint aid) public constant returns 
    (string,string,string,uint)
    {
       
            return(animalAgainstId[aid].name,
            animalAgainstId[aid].desc,
			animalAgainstId[aid].attributes,
			animalAgainstId[aid].priceForSale
           
            );
        
    }
	
	
    function getAnimalByIdVisibility(uint aid) public constant 
    returns (bool upforsale,bool upformating,bool eggphase,bool isbornbymating, 
    uint birthdate, uint assetsid, uint generationid )
    {
        return(
            animalAgainstId[aid].upForSale,
            animalAgainstId[aid].upForMating,
            animalAgainstId[aid].eggPhase,
            animalAgainstId[aid].isBornByMating,
            animalAgainstId[aid].birthdate,
            animalAgainstId[aid].assetsId,
            animalAgainstId[aid].generationId
            );
    }
    
     function getOwnerByAnimalId(uint aid) public constant 
    returns (address)
    {
        return token.ownerOf(aid);
            
    }
    
    /**
     * function to get all animals against an address
     **/ 
    function getAllAnimalsByAddress(address ad) public constant returns (uint[] listAnimals)
    {
        require (!isContractPaused);
        return token.getAnimalIdAgainstAddress(ad);
    }

    /**
     * claim an animal from animal factory
     **/ 
    function claimFreeAnimalFromAnimalFactory( string animalName, string animalDesc) public
    {
        require(msg.sender != 0x0);
        require (!isContractPaused);
        uint gId=0;
        //owner can claim as many free animals as he or she wants
        if (msg.sender!=owner)
        {
            require(token.getTotalTokensAgainstAddress(msg.sender)<freeAnimalsLimit);
            gId=1;
        }
		
		if (totalAnimalsCreated >= totalFreeAnimalsMax) throw;

        //sequentially generated animal id   
        uniqueAnimalId++;
        
        //Generating an Animal Record
        animalObject = AnimalProperties({
            id:uniqueAnimalId,
            name:animalName,
            desc:animalDesc,
			attributes:"",
            upForSale: false,
            eggPhase: false,
            priceForSale:0,
            upForMating: false,
            priceForMating:0,
            isBornByMating: false,
            parentId1:0,
            parentId2:0,
            birthdate:now,
            assetsId:0, 
            generationId:gId,
			cuteVotes:0
			
        });
        token.sendToken(msg.sender, uniqueAnimalId,animalName);
        
        //updating the mappings to store animal information  
        animalAgainstId[uniqueAnimalId]=animalObject;
        totalAnimalsCreated++;
    }
  
    /**
     * Function to buy animals from the factory in exchange for ethers
     **/ 
    function MintAnimalsFromAnimalFactory(string animalName, string animalDesc) public payable 
    {
        require (!isContractPaused);
		require (!isMintingPaused);
        require(validPurchase());
        require(msg.sender != 0x0);
		

		
		//everyone except owner has to pay the advertisement fees
        if (msg.sender!=owner)
        {
            require(msg.value>=weiPerAnimal);  
        }
		
		require(msg.value>=weiPerAnimal); 
    
		if (totalAnimalsCreated >= totalAnimalsMax) throw;
		
		
		
        uint gId=0;
        //owner can claim as many free animals as he or she wants
        if (msg.sender!=owner)
        {
            gId=1;
        }

    
        uint256 weiAmount = msg.value;
        
        // calculate token amount to be created
        uint256 tokens = weiAmount.div(weiPerAnimal);
        
        // update state
        weiRaised = weiRaised.add(weiAmount);

    
        uniqueAnimalId++;
        //Generating Animal Record
        animalObject = AnimalProperties({
            id:uniqueAnimalId,
            name:animalName,
            desc:animalDesc,
			attributes:"",
            upForSale: false,
            priceForSale:0,
            upForMating: false,
            eggPhase: false,
            priceForMating:0,
            isBornByMating:false,
            parentId1:0,
            parentId2:0,
            birthdate:now,
            assetsId:0,
            generationId:gId,
			cuteVotes:0
			
        });
          
          
        //transferring the token
        token.sendToken(msg.sender, uniqueAnimalId,animalName); 
        emit AnimalsPurchased(msg.sender, owner, weiAmount, tokens);
        
        //updating the mappings to store animal records
        animalAgainstId[uniqueAnimalId]=animalObject;
        
        
        totalAnimalsCreated++;
        
        //transferring the ethers to the owner of the contract
        owner.transfer(msg.value);
    }
  
    /** 
     * Buying animals from a user 
     **/ 
    function buyAnimalsFromUser(uint animalId) public payable 
    {
        require (!isContractPaused);
        require(msg.sender != 0x0);
        address prevOwner=token.ownerOf(animalId);
        
        //checking that a user is not trying to buy an animal from himself
        require(prevOwner!=msg.sender);
        
        //the price of sale
        uint price=animalAgainstId[animalId].priceForSale;
		
		// * (1 ether)
		uint convertedpricetoEther = msg.value;

        //the percentage of owner         
        uint OwnerPercentage=animalAgainstId[animalId].priceForSale.mul(ownerPerThousandShareForBuying);
        OwnerPercentage=OwnerPercentage.div(1000);
		
		//Take Owner percentage from sale
        uint priceMinusOwnerPercentage = animalAgainstId[animalId].priceForSale.sub(OwnerPercentage);
		 
        
        //funds sent should be enough to cover the selling price plus the owner fees
        require(convertedpricetoEther>=price); 

        // transfer token only
       // token.mint(prevOwner,msg.sender,1); 
		// transfer token here
        token.safeTransferFrom(prevOwner,msg.sender,animalId);

        // change mapping in animalAgainstId
        animalAgainstId[animalId].upForSale=false;
        animalAgainstId[animalId].priceForSale=0;

        //remove from for sale list
        for (uint j=0;j<upForSaleList.length;j++)
        {
          if (upForSaleList[j] == animalId)
            delete upForSaleList[j];
        }      
        
        //transfer of money from buyer to beneficiary
        prevOwner.transfer(priceMinusOwnerPercentage);
        
        //transfer of percentage money to ownerWallet
        owner.transfer(OwnerPercentage);
        
        
    }
  
    /**
     * function to accept a mate offer by offering one of your own animals 
     * and paying ethers ofcourse
     **/ 
    function mateAnimal(uint parent1Id, uint parent2Id, string animalName,string animalDesc) public payable 
    {
        require (!isContractPaused);
		require(!isMatingPaused);
        require(msg.sender != 0x0);
        
        //the requester is actually the owner of the animal which he or she is offering for mating
        require (token.ownerOf(parent2Id) == msg.sender);
        
        //a user cannot mate two of his own animals
        require(token.ownerOf(parent2Id)!=token.ownerOf(parent1Id));
        
        //the animal id given was actually advertised for mating
        require(animalAgainstId[parent1Id].upForMating==true);
		
		uint convertedpricetoEther = msg.value;

        // the price requested for mating
        uint price=animalAgainstId[parent1Id].priceForMating;
        
        // the owner fees 
        uint OwnerPercentage=animalAgainstId[parent1Id].priceForMating.mul(ownerPerThousandShareForMating);
        OwnerPercentage=OwnerPercentage.div(1000);
        
        uint priceMinusOwnerPercentage = animalAgainstId[parent1Id].priceForMating.sub(OwnerPercentage);
        
        // the ethers sent should be enough to cover the mating price and the owner fees
        require(convertedpricetoEther>=price);
        uint generationnum = 1;

        if(animalAgainstId[parent1Id].generationId >= animalAgainstId[parent2Id].generationId)
        {
        generationnum = animalAgainstId[parent1Id].generationId+1;
        }
        else{
        generationnum = animalAgainstId[parent2Id].generationId+1;
        
        }
        // sequentially generated id for animal
         uniqueAnimalId++;

        //Adding Saving Animal Record
        animalObject = AnimalProperties({
            id:uniqueAnimalId,
            name:animalName,
            desc:animalDesc,
			attributes:"",
            upForSale: false,
            priceForSale:0,
            upForMating: false,
            eggPhase: true,     
            priceForMating:0,
            isBornByMating:true,
            parentId1: parent1Id,
            parentId2: parent2Id,
            birthdate:now,
            assetsId:0,
            generationId:generationnum,
			cuteVotes:0
			
          });
        // transfer token only
        token.sendToken(msg.sender,uniqueAnimalId,animalName);
        //updating the mappings to store animal information
        animalAgainstId[uniqueAnimalId]=animalObject;
        //adding the generated animal to egg phase list
        eggPhaseAnimalIds.push(uniqueAnimalId);
        
        //adding this animal as a child to the parents who mated to produce this offspring
        childrenIdAgainstAnimalId[parent1Id].push(uniqueAnimalId);
        childrenIdAgainstAnimalId[parent2Id].push(uniqueAnimalId);

        //remove from for mate list
        for (uint i=0;i<upForMatingList.length;i++)
        {
            if (upForMatingList[i]==parent1Id)
                delete upForMatingList[i];   
        }
        
        //remove the parent animal from mating advertisment      
        animalAgainstId[parent1Id].upForMating = false;
        animalAgainstId[parent1Id].priceForMating = 0;
        
        //transfer of money from beneficiary to mate owner
        token.ownerOf(parent1Id).transfer(priceMinusOwnerPercentage);
        
        //transfer of percentage money to ownerWallet
        owner.transfer(OwnerPercentage);
        
        
        
    }

    /**
     * function to transfer an animal to another user
     * direct token cannot be passed as we have disabled the transfer feature
     * all animal transfers should occur through this function
     **/ 
    function TransferAnimalToAnotherUser(uint animalId,address to) public 
    {
        require (!isContractPaused);
        require(msg.sender != 0x0);
        
        //the requester of the transfer is actually the owner of the animal id provided
        require(token.ownerOf(animalId)==msg.sender);
        
        //if an animal has to be transferred, it shouldnt be up for sale or mate
        require(animalAgainstId[animalId].upForSale == false);
        require(animalAgainstId[animalId].upForMating == false);
        token.safeTransferFrom(msg.sender, to, animalId);

    }	
	

	
	
	function voteCuteness(uint animalId, uint vote)
	{
		require(msg.sender != 0x0);
		animalAgainstId[animalId].cuteVotes++;
	}
	
    
    /**
     * Advertise your animal for selling in exchange for ethers
     **/ 
    function putSaleRequest(uint animalId, uint salePrice) public payable
    {
        require (!isContractPaused);
		
		///convert uint to ether
		
		uint convertedpricetoEther = salePrice;
		
        //everyone except owner has to pay the advertisement fees
        if (msg.sender!=owner)
        {
            require(msg.value>=priceForSaleAdvertisement);  
        }
        
        //the advertiser is actually the owner of the animal id provided
        require(token.ownerOf(animalId)==msg.sender);
        
        //you cannot advertise an animal for sale which is in egg phase
        require(animalAgainstId[animalId].eggPhase==false);

        // you cannot advertise an animal for sale which is already on sale
        require(animalAgainstId[animalId].upForSale==false);

        //you cannot put an animal for sale and mate simultaneously
        require(animalAgainstId[animalId].upForMating==false);
        
        //putting up the flag for sale 
        animalAgainstId[animalId].upForSale=true;
        animalAgainstId[animalId].priceForSale=convertedpricetoEther;
        upForSaleList.push(animalId);
        
        //transferring the sale advertisement price to the owner
        owner.transfer(msg.value);
    }
    
    /**
     * function to withdraw a sale advertisement that was put earlier
     **/ 
    function withdrawSaleRequest(uint animalId) public
    {
        require (!isContractPaused);
        
        // the animal id actually belongs to the requester
        require(token.ownerOf(animalId)==msg.sender);
        
        // the animal in question is still up for sale
        require(animalAgainstId[animalId].upForSale==true);

        // change the animal state to not be on sale
        animalAgainstId[animalId].upForSale=false;
        animalAgainstId[animalId].priceForSale=0;

        // remove the animal from sale list
        for (uint i=0;i<upForSaleList.length;i++)
        {
            if (upForSaleList[i]==animalId)
                delete upForSaleList[i];     
        }
    }

    /**
     * function to put mating request in exchange for ethers
     **/ 
    function putMatingRequest(uint animalId, uint matePrice) public payable
    {
        require(!isContractPaused);
		require(!isMatingPaused);

        // the owner of the contract does not need to pay the mate advertisement fees
        if (msg.sender!=owner)
        {
            require(msg.value>=priceForMateAdvertisement);
        }
		//* (1 ether)
		uint convertedpricetoEther = matePrice;
    
        require(token.ownerOf(animalId)==msg.sender);

        // an animal in egg phase cannot be put for mating
        require(animalAgainstId[animalId].eggPhase==false);
        
        // an animal on sale cannot be put for mating
        require(animalAgainstId[animalId].upForSale==false);
        
        // an animal already up for mating cannot be put for mating again
        require(animalAgainstId[animalId].upForMating==false);
        animalAgainstId[animalId].upForMating=true;
        animalAgainstId[animalId].priceForMating=convertedpricetoEther;
        upForMatingList.push(animalId);

        // transfer the mating advertisement charges to owner
        owner.transfer(msg.value);
    }
    
    /**
     * withdraw the mating request that was put earlier
     **/ 
    function withdrawMatingRequest(uint animalId) public
    {
        require(!isContractPaused);
		require(!isMatingPaused);
        require(token.ownerOf(animalId)==msg.sender);
        require(animalAgainstId[animalId].upForMating==true);
        animalAgainstId[animalId].upForMating=false;
        animalAgainstId[animalId].priceForMating=0;
        for (uint i=0;i<upForMatingList.length;i++)
        {
            if (upForMatingList[i]==animalId)
                delete upForMatingList[i];    
        }
    }
  
    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) 
    {
        // check validity of purchase
        if(msg.value.div(weiPerAnimal)<1)
            return false;
    
        uint quotient=msg.value.div(weiPerAnimal); 
   
        uint actualVal=quotient.mul(weiPerAnimal);
   
        if(msg.value>actualVal)
            return false;
        else 
            return true;
    }

    /**
     * function to show how many animals does an address have
     **/
    function showMyAnimalBalance() public view returns (uint256 tokenBalance) 
    {
        tokenBalance = token.balanceOf(msg.sender);
    }

    /**
     * function to set the new price 
     * can only be called from owner wallet
     **/ 
    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) 
    {
		
        weiPerAnimal = newPrice;
    }
    
     /**
     * function to set the mate advertisement price 
     * can only be called from owner wallet
     **/ 
    function setMateAdvertisementRate(uint256 newPrice) public onlyOwner returns (bool) 
    {
        priceForMateAdvertisement = newPrice;
    }
    
     /**
     * function to set the sale advertisement price
     * can only be called from owner wallet
     **/ 
    function setSaleAdvertisementRate(uint256 newPrice) public onlyOwner returns (bool) 
    {		
        priceForSaleAdvertisement = newPrice;
    }
    
     /**
     * function to set the sale advertisement price
     * can only be called from owner wallet
     **/ 
    function setBuyingAssetsRate(uint256 newPrice) public onlyOwner returns (bool) 
    {		
        priceForBuyingAssets = newPrice;
    }
    
	
     /**
     * function to change the Max animals minted limit
     * can only be called from owner wallet
     **/ 
    function changeMaxMintable(uint limit) public onlyOwner
    {
        totalAnimalsMax = limit;
    }
	
	
	     /**
     * function to change the Max animals minted limit
     * can only be called from owner wallet
     **/ 
    function changeFreeMaxMintable(uint limit) public onlyOwner
    {
        totalFreeAnimalsMax = limit;
    }
	
	

    
     /**
     * function to get all mating animal ids
     **/ 
    function getAllMatingAnimals() public constant returns (uint[]) 
    {
        return upForMatingList;
    }
    
     /**
     * function to get all sale animals ids
     **/ 
    function getAllSaleAnimals() public constant returns (uint[]) 
    {
        return upForSaleList;
    }
    
     /**
     * function to change the free animals limit for each user
     * can only be called from owner wallet
     **/ 
    function changeFreeAnimalsLimit(uint limit) public onlyOwner
    {
        freeAnimalsLimit = limit;
    }

	
	
	    /**
     * function to pause the contract
     * can only be called from owner wallet
     **/  
    function pauseMating(bool isPaused) public onlyOwner
    {
        isMatingPaused = isPaused;
		isMintingPaused = true;
    }
    
    /**
     * function to pause the contract
     * can only be called from owner wallet
     **/  
    function pauseContract(bool isPaused) public onlyOwner
    {
        isContractPaused = isPaused;
    }
	
	
	/**
     * function to pause the contract
     * can only be called from owner wallet
    **/  
    function pauseMinting(bool isPaused) public onlyOwner
    {
        isMintingPaused = isPaused;
    }
  
  
    /**
     * function to remove an animal from egg phase
     * can be called from anyone in the member addresses list
     **/  
    function removeFromEggPhase(uint animalId) public
    {
        for (uint i=0;i<memberAddresses.length;i++)
        {
            if (memberAddresses[i]==msg.sender)
            {
                for (uint j=0;j<eggPhaseAnimalIds.length;j++)
                {
                    if (eggPhaseAnimalIds[j]==animalId)
                    {
                        delete eggPhaseAnimalIds[j];
                    }
                }
                animalAgainstId[animalId].eggPhase = false;
            }
        }
    }
    
    /**
     * function to get all children ids of an animal
     **/  
    function getChildrenAgainstAnimalId(uint id) public constant returns (uint[]) 
    {
        return childrenIdAgainstAnimalId[id];
    }
    
    /**
     * function to get all animals in the egg phase list
     **/  
    function getEggPhaseList() public constant returns (uint[]) 
    {
        return eggPhaseAnimalIds;
    }
    
    
     /**
     * function to get all animals in Assets not yet approved list
     **/  
    function getAnimalIdsWithPendingAssets() public constant returns (uint[]) 
    {
        return animalIdsWithPendingAssetss;
    }
    
       /**
     * function to request to buy Assets
     **/  
    function buyAssets(uint cId, uint aId) public payable 
    {
        require(msg.value>=priceForBuyingAssets);
        require(!isContractPaused);
        require(token.ownerOf(aId)==msg.sender);
        require(animalAgainstId[aId].assetsId==0);
        animalAgainstId[aId].assetsId=cId;
        animalIdsWithPendingAssetss.push(aId);
        // transfer the mating advertisement charges to owner
        owner.transfer(msg.value);
    }
    
    
    /**
     * function to approve a pending Assets
     * can be called from anyone in the member addresses list
     **/  
    function approvePendingAssets(uint animalId) public
    {
        for (uint i=0;i<memberAddresses.length;i++)
        {
            if (memberAddresses[i]==msg.sender)
            {
                for (uint j=0;j<animalIdsWithPendingAssetss.length;j++)
                {
                    if (animalIdsWithPendingAssetss[j]==animalId)
                    {
                        delete animalIdsWithPendingAssetss[j];
                    }
                }
            }
        }
    }
    
    /**
     * function to add a member that could remove animals from egg phase
     * can only be called from owner wallet
     **/  
    function addMember(address member) public onlyOwner 
    { 
        memberAddresses.push(member);
    }
  
    /**
     * function to return the members that could remove an animal from egg phase
     **/  
    function listMembers() public constant returns (address[]) 
    { 
        return memberAddresses;
    }
    
    /**
     * function to delete a member from the list that could remove an animal from egg phase
     * can only be called from owner wallet
     **/  
    function deleteMember(address member) public onlyOwner 
    { 
        for (uint i=0;i<memberAddresses.length;i++)
        {
            if (memberAddresses[i]==member)
            {
                delete memberAddresses[i];
            }
        }
    }
    /**
     * function to update an animal
     * can only be called from owner wallet
     **/  
    function updateAnimal(uint animalId, string name, string desc, string attributes) public  
    { 
        require(msg.sender==token.ownerOf(animalId));
        animalAgainstId[animalId].name=name;
        animalAgainstId[animalId].desc=desc;
		animalAgainstId[animalId].attributes=attributes;
        token.setAnimalMeta(animalId, name);
    }
   
}