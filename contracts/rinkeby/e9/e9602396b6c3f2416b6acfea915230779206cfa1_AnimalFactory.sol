/**
 *Submitted for verification at Etherscan.io on 2021-04-11
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
     function createToken(address sendTo, uint tid) ;
	 function setURI(string uri);
     function balanceOf(address _owner) public view returns (uint256 _balance);
     function ownerOf(uint256 _tokenId) public view returns (address _owner);
     function transferOwnership(address _owner);
	 function isApprovedForAll(address _owner, address _operator) public constant returns (bool truefalse);
}


contract AnimalFactory is Ownable
{
    //The structure defining a single animal
    struct AnimalProperties
    {
        uint id;
        string name;
        string desc;
        bool upForSale;
        uint priceForSale;
        uint birthdate;
        uint assetsId;
		uint GamePoints;
		
    }
	
	
	struct AnimalForSale
    {
        uint id;
        uint priceForSale; 
    }
    
    using SafeMath for uint256;
 
    // The token being sold
    ERC721Interface public token;
    
    
    //sequentially generated ids for the animals
    uint uniqueAnimalId=0;

    //mapping to show all the animal properties against a single id
    mapping(uint=>AnimalProperties)  animalAgainstId; 
	
	mapping(uint=>AnimalForSale)  public animalForSaleId; 


    //the animals that have been advertised for selling
    uint[] upForSaleList;
    
    //the list of addresses that can remove animals  
    address[] memberAddresses;

    //animal object to be used in various functions as an intermediate variable
    AnimalProperties  animalObject;
	
	AnimalForSale  animalForSaleObject;
	
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
	

	
	bool public isBuyingPaused;

	///ether means bnb here
    //rate of each animal
    uint256 public weiPerAnimal = 0.15 ether;
    uint public priceForBuyingAssets = 0.25 ether;
	
	//the fees for advertising an animal for sale
    uint public priceForSaleAdvertisement = 0.025 ether;
	uint public priceForSuccessfulSale = 0.05 ether;
	
	//The owner percentages from selling transactions
    uint public ownerPerHundredShareForBuying = 50;

    // amount of raised money in wei
    uint256 public weiRaised;

    // Total no of Animals created
    uint256 public totalAnimalsCreated=0;
	uint256 public totalFreeAnimalsCreated=0;
	
    uint[] eggPhaseAnimalIds;
    uint[] animalIdsWithPendingAssetss;


    event AnimalsPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  
   function AnimalFactory(address _walletOwner,address _tokenAddress) public 
   { 
        require(_walletOwner != 0x0);
        owner = _walletOwner;
        isContractPaused = false;
		isMintingPaused = false;
		isBuyingPaused=false;
		priceForSaleAdvertisement = 0.025 ether;
        priceForBuyingAssets = 0.25 ether;
        token = ERC721Interface(_tokenAddress);
    }

    /**
     * function to get animal details by id
     **/ 
    
    function getAnimalById(uint aid) public constant returns 
    (string, string,uint,uint)
    {


            return(
			animalAgainstId[aid].name,
            animalAgainstId[aid].desc,
            animalAgainstId[aid].id,
            animalAgainstId[aid].priceForSale
             );
        
    }
	
	
	

	
	
    function getAnimalByIdVisibility(uint aid) public constant 
    returns (address owneraddress,bool upforsale, uint saleprice, string name, string desc,uint birthdate)
    {
	
	address ownersaddress = token.ownerOf(aid);
	//bool approvalon = token.isApprovedForAll(ownersaddress,address(this));
	
        return(
			ownersaddress,
            animalAgainstId[aid].upForSale,
			animalAgainstId[aid].priceForSale,
            animalAgainstId[aid].name,
            animalAgainstId[aid].desc,
			 animalAgainstId[aid].birthdate

            );
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
            require(token.balanceOf(msg.sender)<freeAnimalsLimit);
            gId=1;
        }
		
		if (totalFreeAnimalsCreated >= totalFreeAnimalsMax) throw;

        //sequentially generated animal id   
        uniqueAnimalId++;
        
        //Generating an Animal Record
        animalObject = AnimalProperties({
            id:uniqueAnimalId,
            name:animalName,
            desc:animalDesc,
            upForSale: false,
            priceForSale:0,           
            birthdate:now,
            assetsId:0,           
			GamePoints:0
			
        });
        token.createToken(msg.sender, uniqueAnimalId);
        
        //updating the mappings to store animal information  
        animalAgainstId[uniqueAnimalId]=animalObject;
        totalAnimalsCreated++;
		totalFreeAnimalsCreated++;
    }
	
	
	
	
	function calculatePriceForToken() public view returns (uint256) 
	{
        require(totalAnimalsCreated <= totalAnimalsMax, "Sale has already ended");

        if (totalAnimalsCreated >= 10001) {
            return 0.060 ether;       
        } else if (totalAnimalsCreated >= 7500) {
            return 0.050 ether;        
        } else if (totalAnimalsCreated >= 5001) {
            return 0.040 ether;     
        } else if (totalAnimalsCreated >= 2501) {
            return 0.030 ether;       
        } else if (totalAnimalsCreated >= 1501) {
            return 0.020 ether;          
        } else {
            return 0.010 ether;          
        }
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
		
		uint256 pricetobuy = calculatePriceForToken();
		
		//everyone except owner has to pay the advertisement fees
        if (msg.sender!=owner)
        {
            require(msg.value>=pricetobuy);  
        }
		
		require(msg.value>=pricetobuy); 
    
		if (totalAnimalsCreated >= totalAnimalsMax) throw;
		
		
		
        uint gId=0;
        //owner can claim as many free animals as he or she wants
        if (msg.sender!=owner)
        {
            gId=1;
        }

    
        uint256 weiAmount = msg.value;
        
        // calculate token amount to be created
        uint256 tokens = weiAmount.div(pricetobuy);
        
        // update state
        weiRaised = weiRaised.add(weiAmount);

    
        uniqueAnimalId++;
		
        //Generating Animal Record
        animalObject = AnimalProperties({
            id:uniqueAnimalId,
            name:animalName,
            desc:animalDesc,
            upForSale: false,
            priceForSale:0,          
            birthdate:now,
            assetsId:0,           
			GamePoints:0
			
        });
          
          
        //transferring the token
        token.createToken(msg.sender, uniqueAnimalId); 
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
		require (!isBuyingPaused);
		
        require(msg.sender != 0x0);
        address prevOwner=token.ownerOf(animalId);
		
		//Is the animal for sale
        require(animalAgainstId[animalId].upForSale==true);	
		
		//the price of sale
        uint price=animalAgainstId[animalId].priceForSale;
		require(price>0);			
        
        //checking that a user is not trying to buy an animal from himself
        require(prevOwner!=msg.sender);
		
		
		uint convertedpricetoEther = msg.value;

        //the percentage of owner         
        uint OwnerPercentage=animalAgainstId[animalId].priceForSale.mul(ownerPerHundredShareForBuying);
        OwnerPercentage=OwnerPercentage.div(100);
		
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

		delete animalForSaleId[animalId];
		
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
        
        //if an animal has to be transferred, it shouldnt be up for sale
        require(animalAgainstId[animalId].upForSale == false);
        token.safeTransferFrom(msg.sender, to, animalId);

    }	
	

	
	
	function submitGamePoints(uint animalId, uint points)
	{
		require(msg.sender != 0x0);
		require(token.ownerOf(animalId)==msg.sender);
		
		animalAgainstId[animalId].GamePoints++;
	}
	
    
    /**
     * Advertise your animal for selling in exchange for ethers
     **/ 
    function putSaleRequest(uint animalId, uint salePrice) public payable
    {
        require (!isContractPaused);
		
		require (salePrice>0);
		
		///check if approval is on
		require(token.isApprovedForAll(msg.sender,address(this)));
		
		///convert uint to ether
		
		uint convertedpricetoEther = salePrice;
		
        //everyone except owner has to pay the advertisement fees
        if (msg.sender!=owner)
        {
            require(msg.value>=priceForSaleAdvertisement);  
        }
        
        //the advertiser is actually the owner of the animal id provided
        require(token.ownerOf(animalId)==msg.sender);
        
      

        // you cannot advertise an animal for sale which is already on sale
        require(animalAgainstId[animalId].upForSale==false);


        
        //putting up the flag for sale 
        animalAgainstId[animalId].upForSale=true;
        animalAgainstId[animalId].priceForSale=convertedpricetoEther;
		
        upForSaleList.push(animalId);
		
		
		//Generating an Animal Record
        animalForSaleObject = AnimalForSale({
            id:uniqueAnimalId,           
            priceForSale:convertedpricetoEther
        });
		
		
		animalForSaleId[animalId]=animalForSaleObject;
        
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
		
		delete animalForSaleId[animalId];

        // remove the animal from sale list
        for (uint i=0;i<upForSaleList.length;i++)
        {
            if (upForSaleList[i]==animalId)
                delete upForSaleList[i];     
        }
    }



    

  
    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) 
    {
	
		uint256 pricetobuy=calculatePriceForToken();
        // check validity of purchase
        if(msg.value.div(pricetobuy)<1)
            return false;
    
        uint quotient=msg.value.div(pricetobuy); 
   
        uint actualVal=quotient.mul(pricetobuy);
   
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
    

	

    function setURI(string uri) public onlyOwner returns (bool) 
    {
        token.setURI(uri);
    }
	
	function transferOwnershipToken(address newowner) public onlyOwner returns (bool) 
    {
		require (!isContractPaused);
        require(msg.sender != 0x0);
        token.transferOwnership(newowner);
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
	

    function changeBuyShare(uint buyshare) public onlyOwner
    {
        ownerPerHundredShareForBuying = buyshare;
    }
    

    
     /**
     * function to get all sale animals ids
     **/ 
    function getAllSaleAnimals() public constant returns (uint[]) 
    {
        return upForSaleList;
    }
	
	     /**
     * function to get all sale animals ids
     **/ 
    function getAllSaleAnimalsStruct() public constant returns (uint[]) 
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
    function pauseBuying(bool isPaused) public onlyOwner
    {
        isBuyingPaused = isPaused;
		
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
     * function to add a member that could remove animals
     * can only be called from owner wallet
     **/  
    function addMember(address member) public onlyOwner 
    { 
        memberAddresses.push(member);
    }
  
    /**
     * function to return the members that could remove an animal 
     **/  
    function listMembers() public constant returns (address[]) 
    { 
        return memberAddresses;
    }
    
    /**
     * function to delete a member from the list that could remove an animal 
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
    function updateAnimal(uint animalId, string name, string desc) public  
    { 
        require(msg.sender==token.ownerOf(animalId));
        animalAgainstId[animalId].name=name;
        animalAgainstId[animalId].desc=desc;

      
    }
   
}