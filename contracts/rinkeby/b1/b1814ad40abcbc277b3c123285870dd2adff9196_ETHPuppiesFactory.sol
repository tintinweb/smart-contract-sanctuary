/**
 *Submitted for verification at Etherscan.io on 2021-04-10
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

// The ERC-721 Interface to reference the Puppies factory token
interface ERC721Interface {
     function totalSupply() public view returns (uint256);
     function safeTransferFrom(address _from, address _to, uint256 _tokenId);
    
     function createPuppiesToken(address sendTo, uint tid) ;
	 function setURI(string uri) ;
     
     function balanceOf(address _owner) public view returns (uint256 _balance);
     function ownerOf(uint256 _tokenId) public view returns (address _owner);
     function transferOwnership(address _owner);
	 function isApprovedForAll(address _owner, address _operator) public constant returns (bool truefalse);
}


contract ETHPuppiesFactory is Ownable
{
    //The structure defining a single Puppies
    struct PuppiesProperties
    {
        uint id;
        string name;
        string desc;
		string attributes;
        bool upForSale;
        uint priceForSale;
        uint birthdate;
        uint assetsId;
		uint gamePoints;
		
    }
    
    using SafeMath for uint256;
 
    // The token being sold
    ERC721Interface public token;
    
    
    //sequentially generated ids for the Puppies
    uint uniquePuppiesId=0;

    //mapping to show all the Puppies properties against a single id
    mapping(uint=>PuppiesProperties)  PuppiesAgainstId;
    
    //mapping to show how many children does a single Puppies has
    mapping(uint=>uint[])  childrenIdAgainstPuppiesId;
    
    //the Puppies that have been advertised for selling
    uint[] upForSaleList;
    
    address[] memberAddresses;

    //Puppies object to be used in various functions as an intermediate variable
    PuppiesProperties  PuppiesObject;
	
    //the number of Puppies limit
    uint public totalPuppiesMax = 12000;	

	// Total free Puppies created
    uint256 public totalFreePuppiesMax=1500;

    //the number of free Puppies an address can claim
    uint public freePuppiesLimit = 1;
    
    //variable to show whether the contract has been paused or not
    bool public isContractPaused;
	
	//variable to show whether the minting has been paused or not
    bool public isMintingPaused;
	

	bool public isBuyingPaused;

	///ether means bnb here
    //rate of each Puppies
    uint256 public weiPerPuppies = 0.15 ether;
    uint public priceForBuyingAssets = 0.25 ether;
	
	//the fees for advertising an Puppies for sale and mate
    uint public priceForMateAdvertisement = 0.025 ether;
    uint public priceForSaleAdvertisement = 0.025 ether;
	uint public priceForSuccessfulSale = 0.05 ether;
	

    uint public ownerPerHundredShareForBuying = 5;

    // amount of raised money in wei
    uint256 public weiRaised;

    // Total no of Puppies created
    uint256 public totalPuppiesCreated=0;
	
	// Total no of Puppies created
    uint256 public totalFreePuppiesCreated=0;

	
	

    uint[] PuppiesIdsWithPendingAssetss;

    /**
     * event for Puppies purchase logging
     * @param purchaser who paid for the Puppies
     * @param beneficiary who got the Puppies
     * @param value weis paid for purchase
     * @param amount of Puppies purchased
    */
    event PuppiesMinted(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	event PuppiesBought(address indexed purchaser, address indexed beneficiary, uint256 value);
  
   function ETHPuppiesFactory(address _walletOwner,address _tokenAddress) public 
   { 
        require(_walletOwner != 0x0);
        owner = _walletOwner;
        isContractPaused = false;
		isMintingPaused = false;
		isBuyingPaused=false;
        priceForMateAdvertisement = 0.025 ether;
        priceForSaleAdvertisement = 0.025 ether;
        priceForBuyingAssets = 0.25 ether;
        token = ERC721Interface(_tokenAddress);
    }

    /**
     * function to get Puppies details by id
     **/ 
    
    function getPuppiesById(uint aid) public constant returns 
    (string, string,uint,uint)
    {
        
            return(PuppiesAgainstId[aid].name,
            PuppiesAgainstId[aid].desc,
            PuppiesAgainstId[aid].id,
            PuppiesAgainstId[aid].priceForSale
            );
        
    }
	
	
	
	function getPuppiesNameDescAttribById(uint aid) public constant returns 
    (string,string,string,uint)
    {
       
            return(PuppiesAgainstId[aid].name,
            PuppiesAgainstId[aid].desc,
			PuppiesAgainstId[aid].attributes,
			PuppiesAgainstId[aid].priceForSale
           
            );
        
    }
	
	
    function getPuppiesByIdVisibility(uint aid) public constant 
    returns (bool upforsale,uint birthdate, uint assetsid )
    {
        return(
            PuppiesAgainstId[aid].upForSale,
            PuppiesAgainstId[aid].birthdate,
            PuppiesAgainstId[aid].assetsId
            );
    }
    
     function getOwnerByPuppiesId(uint aid) public constant 
    returns (address)
    {
        return token.ownerOf(aid);
            
    }
    


    /**
     * claim an Puppies from Puppies factory
     **/ 
    function claimFreePuppiesFromPuppiesFactory( string PuppiesName, string PuppiesDesc) public
    {
        require(msg.sender != 0x0);
        require (!isContractPaused);
        uint gId=1;
        //owner can claim as many free Puppies as he or she wants
        if (msg.sender!=owner)
        {
            require(token.balanceOf(msg.sender)<freePuppiesLimit);            
        }
		
		if (totalPuppiesCreated >= totalPuppiesMax) throw;
		if (totalFreePuppiesCreated >= totalFreePuppiesMax) throw;

        //sequentially generated Puppies id   
        uniquePuppiesId++;
        
        //Generating an Puppies Record
        PuppiesObject = PuppiesProperties({
            id:uniquePuppiesId,
            name:PuppiesName,
            desc:PuppiesDesc,
			attributes:"",
            upForSale: false,
            priceForSale:0,
            birthdate:now,
            assetsId:0, 
			gamePoints:0
			
        });
        token.createPuppiesToken(msg.sender, uniquePuppiesId);
        
        //updating the mappings to store Puppies information  
        PuppiesAgainstId[uniquePuppiesId]=PuppiesObject;
        totalPuppiesCreated++;
		totalFreePuppiesCreated++;
    }
	
	
	function calculatePriceForToken() public view returns (uint256) 
	{
        require(totalPuppiesCreated <= totalPuppiesMax, "Sale has already ended");

        if (totalPuppiesCreated >= 10001) {
            return 0.060 ether;       
        } else if (totalPuppiesCreated >= 7500) {
            return 0.050 ether;        
        } else if (totalPuppiesCreated >= 5001) {
            return 0.040 ether;     
        } else if (totalPuppiesCreated >= 2501) {
            return 0.030 ether;       
        } else if (totalPuppiesCreated >= 1501) {
            return 0.020 ether;          
        } else {
            return 0.010 ether;          
        }
    }
  
    /**
     * Function to buy Puppies from the factory in exchange for ethers
     **/ 
    function mintPuppiesFromPuppiesFactory(string PuppiesName, string PuppiesDesc) public payable 
    {
        require (!isContractPaused);
		require (!isMintingPaused);
        require(validPurchase());
        require(msg.sender != 0x0);
		
		uint256 puppiesmintingprice = calculatePriceForToken();
		
		//everyone except owner has to pay the advertisement fees
        if (msg.sender!=owner)
        {
            require(msg.value>=puppiesmintingprice);  
        }
		
		require(msg.value>=puppiesmintingprice); 
    
		if (totalPuppiesCreated >= totalPuppiesMax) throw;	
		
		
        uint gId=1;       

    
        uint256 weiAmount = msg.value;
        
        // calculate token amount to be created
        uint256 tokens = weiAmount.div(puppiesmintingprice);
        
        // update state
        weiRaised = weiRaised.add(weiAmount);

    
        uniquePuppiesId++;
		
        //Generating Puppies Record
        PuppiesObject = PuppiesProperties({
            id:uniquePuppiesId,
            name:PuppiesName,
            desc:PuppiesDesc,
			attributes:"",
            upForSale: false,
            priceForSale:0,
            birthdate:now,
            assetsId:0,
			gamePoints:0
			
        });
          
          
        //transferring the token
        token.createPuppiesToken(msg.sender, uniquePuppiesId); 
        emit PuppiesMinted(msg.sender, owner, weiAmount, tokens);
        
        //updating the mappings to store Puppies records
        PuppiesAgainstId[uniquePuppiesId]=PuppiesObject;
        
        
        totalPuppiesCreated++;
        
        //transferring the ethers to the owner of the contract
        owner.transfer(msg.value);
    }
  
    /** 
     * Buying Puppies from a user 
     **/ 
    function buyPuppiesFromUser(uint PuppiesId) public payable 
    {
        require (!isContractPaused);
		require (!isBuyingPaused);
		
        require(msg.sender != 0x0);
        address prevOwner=token.ownerOf(PuppiesId);
		
		//Is the Puppies for sale
        require(PuppiesAgainstId[PuppiesId].upForSale==true);			
        
        //checking that a user is not trying to buy an Puppies from himself
        require(prevOwner!=msg.sender);
        
        //the price of sale
        uint price=PuppiesAgainstId[PuppiesId].priceForSale;
		
		// * (1 ether)
		uint convertedpricetoEther = msg.value;

        //the percentage of owner         
        uint OwnerPercentage=PuppiesAgainstId[PuppiesId].priceForSale.mul(ownerPerHundredShareForBuying);
        OwnerPercentage=OwnerPercentage.div(100);
		
		//Take Owner percentage from sale
        uint priceMinusOwnerPercentage = PuppiesAgainstId[PuppiesId].priceForSale.sub(OwnerPercentage);
		 
        
        //funds sent should be enough to cover the selling price plus the owner fees
        require(convertedpricetoEther>=price); 


        token.safeTransferFrom(prevOwner,msg.sender,PuppiesId);

        // change mapping in PuppiesAgainstId
        PuppiesAgainstId[PuppiesId].upForSale=false;
        PuppiesAgainstId[PuppiesId].priceForSale=0;

        //remove from for sale list
        for (uint j=0;j<upForSaleList.length;j++)
        {
          if (upForSaleList[j] == PuppiesId)
            delete upForSaleList[j];
        }      
        
        //transfer of money from buyer to beneficiary
        prevOwner.transfer(priceMinusOwnerPercentage);
        
        //transfer of percentage money to ownerWallet
        owner.transfer(OwnerPercentage);
		
		emit PuppiesBought(msg.sender, owner, price);
        
        
    }
  

    /**
     * function to transfer an Puppies to another user
     * direct token cannot be passed as we have disabled the transfer feature
     * all Puppies transfers should occur through this function
     **/ 
    function transferPuppiesToAnotherUser(uint PuppiesId,address to) public 
    {
        require (!isContractPaused);
        require(msg.sender != 0x0);
        
        //the requester of the transfer is actually the owner of the Puppies id provided
        require(token.ownerOf(PuppiesId)==msg.sender);
        
        //if an Puppies has to be transferred, it shouldnt be up for sale or mate
        require(PuppiesAgainstId[PuppiesId].upForSale == false);

        token.safeTransferFrom(msg.sender, to, PuppiesId);

    }	
	

	
	
	function saveGamePoints(uint PuppiesId, uint vote)
	{
	
		require (!isContractPaused);
		require (!isBuyingPaused);		
        require(msg.sender != 0x0);
        address isOwner=token.ownerOf(PuppiesId);
		require(msg.sender == isOwner);			
		PuppiesAgainstId[PuppiesId].gamePoints++;
	}
	
    
    /**
     * Advertise your Puppies for selling in exchange for ethers
     **/ 
    function putSaleRequest(uint PuppiesId, uint salePrice) public payable
    {
        require (!isContractPaused);		
		
		///check if approval is on
		require(token.isApprovedForAll(msg.sender,address(this)));
		
		///convert uint to ether
		
		uint convertedpricetoEther = salePrice;
		
        //everyone except owner has to pay the advertisement fees
        if (msg.sender!=owner)
        {
            require(msg.value>=priceForSaleAdvertisement);  
        }
        
        //the advertiser is actually the owner of the Puppies id provided
        require(token.ownerOf(PuppiesId)==msg.sender);
        


        // you cannot advertise an Puppies for sale which is already on sale
        require(PuppiesAgainstId[PuppiesId].upForSale==false);


        
        //putting up the flag for sale 
        PuppiesAgainstId[PuppiesId].upForSale=true;
        PuppiesAgainstId[PuppiesId].priceForSale=convertedpricetoEther;
        upForSaleList.push(PuppiesId);
        
        //transferring the sale advertisement price to the owner
        owner.transfer(msg.value);
    }
    
    /**
     * function to withdraw a sale advertisement that was put earlier
     **/ 
    function withdrawSaleRequest(uint PuppiesId) public
    {
        require (!isContractPaused);
        
        // the Puppies id actually belongs to the requester
        require(token.ownerOf(PuppiesId)==msg.sender);
        
        // the Puppies in question is still up for sale
        require(PuppiesAgainstId[PuppiesId].upForSale==true);

        // change the Puppies state to not be on sale
        PuppiesAgainstId[PuppiesId].upForSale=false;
        PuppiesAgainstId[PuppiesId].priceForSale=0;

        // remove the Puppies from sale list
        for (uint i=0;i<upForSaleList.length;i++)
        {
            if (upForSaleList[i]==PuppiesId)
                delete upForSaleList[i];     
        }
    }



    

  
    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) 
    {
        // check validity of purchase
        if(msg.value.div(weiPerPuppies)<1)
            return false;
    
        uint quotient=msg.value.div(weiPerPuppies); 
   
        uint actualVal=quotient.mul(weiPerPuppies);
   
        if(msg.value>actualVal)
            return false;
        else 
            return true;
    }

    /**
     * function to show how many Puppies does an address have
     **/
    function showMyPuppiesBalance() public view returns (uint256 tokenBalance) 
    {
        tokenBalance = token.balanceOf(msg.sender);
    }

    /**
     * function to set the new price 
     * can only be called from owner wallet
     **/ 
    function setPriceToMint(uint256 newPrice) public onlyOwner returns (bool) 
    {
		
        weiPerPuppies = newPrice;
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
     * function to set the mate advertisement price 
     * can only be called from owner wallet
     **/ 
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
     * function to change the Max Puppies minted limit
     * can only be called from owner wallet
     **/ 
    function changeMaxMintable(uint limit) public onlyOwner
    {
        totalPuppiesMax = limit;
    }
	
	
	     /**
     * function to change the Max Puppies minted limit
     * can only be called from owner wallet
     **/ 
    function changeFreeMaxMintable(uint limit) public onlyOwner
    {
        totalFreePuppiesMax = limit;
    }
	

    function changeBuyShare(uint buyshare) public onlyOwner
    {
        ownerPerHundredShareForBuying = buyshare;
    }
    

    
     /**
     * function to get all sale Puppies ids
     **/ 
    function getAllSalePuppies() public constant returns (uint[]) 
    {
        return upForSaleList;
    }
    
     /**
     * function to change the free Puppies limit for each user
     * can only be called from owner wallet
     **/ 
    function changeFreePuppiesLimit(uint limit) public onlyOwner
    {
        freePuppiesLimit = limit;
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
     * function to get all Puppies in Assets not yet approved list
     **/  
    function getPuppiesIdsWithPendingAssets() public constant returns (uint[]) 
    {
        return PuppiesIdsWithPendingAssetss;
    }
    
       /**
     * function to request to buy Assets
     **/  
    function buyAssets(uint cId, uint aId) public payable 
    {
        require(msg.value>=priceForBuyingAssets);
        require(!isContractPaused);
        require(token.ownerOf(aId)==msg.sender);
        require(PuppiesAgainstId[aId].assetsId==0);
        PuppiesAgainstId[aId].assetsId=cId;
        PuppiesIdsWithPendingAssetss.push(aId);
        // transfer the charges to owner
        owner.transfer(msg.value);
    }
    
    
    /**
     * function to approve a pending Assets
     * can be called from anyone in the member addresses list
     **/  
    function approvePendingAssets(uint PuppiesId) public
    {
        for (uint i=0;i<memberAddresses.length;i++)
        {
            if (memberAddresses[i]==msg.sender)
            {
                for (uint j=0;j<PuppiesIdsWithPendingAssetss.length;j++)
                {
                    if (PuppiesIdsWithPendingAssetss[j]==PuppiesId)
                    {
                        delete PuppiesIdsWithPendingAssetss[j];
                    }
                }
            }
        }
    }
    
 
    function addMember(address member) public onlyOwner 
    { 
        memberAddresses.push(member);
    }
  
    /**
     * function to return the members that could remove an Puppies from egg phase
     **/  
    function listMembers() public constant returns (address[]) 
    { 
        return memberAddresses;
    }
    
 
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
     * function to update an Puppies
     * can only be called from owner wallet
     **/  
    function updatePuppies(uint PuppiesId, string name, string desc, string attributes) public  
    { 
        require(msg.sender==token.ownerOf(PuppiesId));
        PuppiesAgainstId[PuppiesId].name=name;
        PuppiesAgainstId[PuppiesId].desc=desc;
		PuppiesAgainstId[PuppiesId].attributes=attributes;
      
    }
   
}