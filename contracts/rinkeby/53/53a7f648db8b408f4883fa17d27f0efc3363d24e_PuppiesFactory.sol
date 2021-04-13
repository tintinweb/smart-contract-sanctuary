/**
 *Submitted for verification at Etherscan.io on 2021-04-12
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
  constructor() public {
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
     function publictotalSupply() external view returns (uint256);
     function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
     function burnToken(address tokenOwner, uint256 tid) external;
     function createToken(address sendTo, uint tid) external;
	 function setURI(string uri) external;
     function balanceOf(address _owner) external view returns (uint256 _balance);
     function ownerOf(uint256 _tokenId) external view returns (address _owner);
     function transferOwnership(address _owner) external;
	 function isApprovedForAll(address _owner, address _operator) external constant returns (bool truefalse);
}


contract PuppiesFactory is Ownable
{
    //The structure defining a single Puppies
    struct PuppiesProperties
    {
        uint id;
        string name;
        string desc;
        bool upForSale;
        uint priceForSale;
        uint birthdate;
        uint assetsId;
		string GamePoints;
		
    }

    
    using SafeMath for uint256;
 
    // The token being sold
    ERC721Interface public token;
    
    
    //sequentially generated ids for the Puppies
    uint uniquePuppiesId=0;

    //mapping to show all the Puppies properties against a single id
    mapping(uint=>PuppiesProperties)  PuppiesAgainstId;
    

    


    //the Puppies that have been advertised for selling
    uint[] upForSaleList;
    
    //the list of addresses that can remove Puppies  
    address[] memberAddresses;

    //Puppies object to be used in various functions as an intermediate variable
    PuppiesProperties  PuppiesObject;
	
    //the number of Puppies limit
    uint public totalPuppiesMax = 10000;
	

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
    uint256 weiPerPuppies = 0.15 ether;
    uint priceForBuyingAssets = 0.25 ether;
	
	
	uint256 price1 = 0.02 ether;
	uint256 price2 = 0.04 ether;
	uint256 price3 = 0.06 ether;
	uint256 price4 = 0.08 ether;
    uint256 price5 = 0.10 ether;
	uint256 price6 = 0.12 ether;
	
	uint256 priceforpack = 0.40 ether;
	uint256 packscanbuy = 5;
	
	//the fees for advertising an Puppies for sale
    uint public priceForSaleAdvertisement = 0.005 ether;

	
	//The owner percentages from selling transactions
    uint public ownerPerHundredShareForBuying = 5;

    // amount of raised money in wei
    uint256 public weiRaised;

    // Total no of Puppies created
    uint256 public totalPuppiesCreated=0;
	uint256 public totalFreePuppiesCreated=0;
	
    uint[] eggPhasePuppiesIds;
    uint[] PuppiesIdsWithPendingAssetss;


    event PuppiesPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	event PuppiesPurchasedFromExchange(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
   constructor(address _walletOwner,address _tokenAddress) public 
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
     * function to get Puppies details by id
     **/ 
    
    function getPuppiesById(uint aid) public constant returns 
    (string, string,uint,uint)
    {


            return(
			PuppiesAgainstId[aid].name,
            PuppiesAgainstId[aid].desc,
            PuppiesAgainstId[aid].id,
            PuppiesAgainstId[aid].priceForSale
             );
        
    }
	
	
	

	
	
    function getPuppiesByIdVisibility(uint aid) public constant 
    returns (address owneraddress,bool upforsale, uint saleprice, string name, string desc,uint birthdate)
    {
	
	address ownersaddress = token.ownerOf(aid);
	//bool approvalon = token.isApprovedForAll(ownersaddress,address(this));
	
        return(
			ownersaddress,
            PuppiesAgainstId[aid].upForSale,
			PuppiesAgainstId[aid].priceForSale,
            PuppiesAgainstId[aid].name,
            PuppiesAgainstId[aid].desc,
			 PuppiesAgainstId[aid].birthdate

            );
    }
    
   


    function claimFreePuppiesFromPuppiesFactory( string PuppiesName, string PuppiesDesc) public
    {
        require(msg.sender != 0x0);
        require (!isContractPaused);
        uint gId=0;
        //owner can claim as many free Puppies as he or she wants
        if (msg.sender!=owner)
        {
            require(token.balanceOf(msg.sender)<freePuppiesLimit);
            gId=1;
        }
		
		if (totalFreePuppiesCreated >= totalFreePuppiesMax) revert();

        //sequentially generated Puppies id   
        uniquePuppiesId++;
        
        //Generating an Puppies Record
        PuppiesObject = PuppiesProperties({
            id:uniquePuppiesId,
            name:PuppiesName,
            desc:PuppiesDesc,
            upForSale: false,
            priceForSale:0,           
            birthdate:now,
            assetsId:0,           
			GamePoints:""
			
        });
        token.createToken(msg.sender, uniquePuppiesId);
        
        //updating the mappings to store Puppies information  
        PuppiesAgainstId[uniquePuppiesId]=PuppiesObject;
        totalPuppiesCreated++;
		totalFreePuppiesCreated++;
    }
	
	
	
	
	function calculatePriceForToken() public view returns (uint256) 
	{
        require(totalPuppiesCreated <= totalPuppiesMax, "Sale has already ended");

        if (totalPuppiesCreated >= 10001) {
            return price6;       
        } else if (totalPuppiesCreated >= 7501) {
            return price5;        
        } else if (totalPuppiesCreated >= 5001) {
            return price4;     
        } else if (totalPuppiesCreated >= 2501) {
            return price3;       
        } else if (totalPuppiesCreated >= 1501) {
            return price2;          
        } else {
            return price1;          
        }
    }
	
	
	function mintPuppiesFromPuppiesFactoryAsPack() public payable 
	{
		require (!isContractPaused);
		require (!isMintingPaused);
        require(validPurchase());
        require(msg.sender != 0x0);
		
		
		
	    if (totalPuppiesCreated >= totalPuppiesMax) revert();
		
		//everyone except owner has to pay fees
        if (msg.sender!=owner)
        {
            require(msg.value>=priceforpack);  
        }
		
		uint256 weiAmount = msg.value;
        
        // calculate token amount to be created
        uint256 tokens = weiAmount.div(priceforpack);
        
        // update state
        weiRaised = weiRaised.add(weiAmount);
		
		for (uint i = 0; i < packscanbuy; i++) 
		{

			uniquePuppiesId++;	
			
			if (totalPuppiesCreated >= totalPuppiesMax)
			{
				owner.transfer(msg.value);
				
				revert();
			}
			

			PuppiesObject = PuppiesProperties({
				id:uniquePuppiesId,
				name:"",
				desc:"",
				upForSale: false,
				priceForSale:0,          
				birthdate:now,
				assetsId:0,           
				GamePoints:""
				
				});				
				
			
			token.createToken(msg.sender, uniquePuppiesId); 
			emit PuppiesPurchased(msg.sender, owner, weiAmount, tokens);        
			//updating the mappings to store Puppies records
			PuppiesAgainstId[uniquePuppiesId]=PuppiesObject;      
			
			totalPuppiesCreated++;
	
        }
		
		//transferring the ethers to the owner of the contract
        owner.transfer(msg.value);
	
	}
  

    function mintPuppiesFromPuppiesFactory(string PuppiesName, string PuppiesDesc) public payable 
    {
        require (!isContractPaused);
		require (!isMintingPaused);
        require(validPurchase());
        require(msg.sender != 0x0);
		
		uint256 pricetobuy = calculatePriceForToken();
		
		//everyone except owner has to pay fees
        if (msg.sender!=owner)
        {
            require(msg.value>=pricetobuy);  
        }
		
    
		if (totalPuppiesCreated >= totalPuppiesMax) revert();
		
		
		
        uint gId=0;
        //owner can claim as many free Puppies as he or she wants
        if (msg.sender!=owner)
        {
            gId=1;
        }

    
        uint256 weiAmount = msg.value;
        
        // calculate token amount to be created
        uint256 tokens = weiAmount.div(pricetobuy);
        
        // update state
        weiRaised = weiRaised.add(weiAmount);

    
        uniquePuppiesId++;
		
        //Generating Puppies Record
        PuppiesObject = PuppiesProperties({
            id:uniquePuppiesId,
            name:PuppiesName,
            desc:PuppiesDesc,
            upForSale: false,
            priceForSale:0,          
            birthdate:now,
            assetsId:0,           
			GamePoints:""
			
        });
          
          
        //transferring the token
        token.createToken(msg.sender, uniquePuppiesId); 
        emit PuppiesPurchased(msg.sender, owner, weiAmount, tokens);
        
        //updating the mappings to store Puppies records
        PuppiesAgainstId[uniquePuppiesId]=PuppiesObject;
        
        
        totalPuppiesCreated++;
        
        //transferring the ethers to the owner of the contract
        owner.transfer(msg.value);
    }
  
 
    function buyPuppiesFromUser(uint PuppiesId) public payable 
    {
		require (!isBuyingPaused);
		
        require(msg.sender != 0x0);
        address prevOwner=token.ownerOf(PuppiesId);
		
		//Is the Puppies for sale
        require(PuppiesAgainstId[PuppiesId].upForSale==true);	
		
		//the price of sale
        uint price=PuppiesAgainstId[PuppiesId].priceForSale;
		
		require(price>0);			
        
        //checking that a user is not trying to buy an Puppies from himself
        require(prevOwner!=msg.sender);
		
		
		uint convertedPricetoEther = msg.value;

        //the percentage of owner         
        uint ownerPercentage=PuppiesAgainstId[PuppiesId].priceForSale.mul(ownerPerHundredShareForBuying);
        ownerPercentage=ownerPercentage.div(100);
		
		//Take Owner percentage from sale
        uint priceMinusOwnerPercentage = PuppiesAgainstId[PuppiesId].priceForSale.sub(ownerPercentage);
		 
        
        //funds sent should be enough to cover the selling price plus the owner fees
        require(convertedPricetoEther>=price); 

        // transfer token only
       // token.mint(prevOwner,msg.sender,1); 
		// transfer token here
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
        owner.transfer(ownerPercentage);
		
		emit PuppiesPurchasedFromExchange(msg.sender, prevOwner, PuppiesId,convertedPricetoEther);
        
        
    }
  


    function transferPuppiesToAnotherUser(uint PuppiesId,address to) public 
    {
        require (!isContractPaused);
        require(msg.sender != 0x0);
        
        //the requester of the transfer is actually the owner of the Puppies id provided
        require(token.ownerOf(PuppiesId)==msg.sender);
        
        //if an Puppies has to be transferred, it shouldnt be up for sale
        require(PuppiesAgainstId[PuppiesId].upForSale == false);
        token.safeTransferFrom(msg.sender, to, PuppiesId);

    }	
	

	
	
	function submitGamePoints(uint PuppiesId, string points) public
	{
		require(msg.sender != 0x0);
		require(token.ownerOf(PuppiesId)==msg.sender);		
		PuppiesAgainstId[PuppiesId].GamePoints=points;
	}
	
    

    function putSaleRequest(uint PuppiesId, uint salePrice) public payable
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


    function showMyPuppiesBalance() public view returns (uint256 tokenBalance) 
    {
        tokenBalance = token.balanceOf(msg.sender);
    }

 
    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) 
    {
		
        weiPerPuppies = newPrice;
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
    

    function setSaleAdvertisementRate(uint256 newPrice) public onlyOwner returns (bool) 
    {		
        priceForSaleAdvertisement = newPrice;
    }
    
 
    function setBuyingAssetsRate(uint256 newPrice) public onlyOwner returns (bool) 
    {		
        priceForBuyingAssets = newPrice;
    }
	
	function setPackBuyPrice(uint256 newPrice, uint256 packs) public onlyOwner returns (bool) 
    {		
        priceforpack = newPrice;
		packscanbuy=packs;
    }
	
	function setMintPrice(uint256 p1, uint256 p2,uint256 p3, uint256 p4,uint256 p5, uint256 p6) public onlyOwner returns (bool) 
    {		
        price1=p1;
		price2=p2;
		price3=p3;
		price4=p4;
		price5=p5;
		price6=p6;		
    }
	
	
    
	
 
    function changeMaxMintable(uint limit) public onlyOwner
    {
        totalPuppiesMax = limit;
    }
	
	

    function changeFreeMaxMintable(uint limit) public onlyOwner
    {
        totalFreePuppiesMax = limit;
    }
	

    function changeBuyShare(uint buyshare) public onlyOwner
    {
        ownerPerHundredShareForBuying = buyshare;
    }
    

    

    function getAllSalePuppies() public constant returns (uint[]) 
    {
        return upForSaleList;
    }
    
  
    function changeFreePuppiesLimit(uint limit) public onlyOwner
    {
        freePuppiesLimit = limit;
    }

	
	

	
 
    function pauseBuying(bool isPaused) public onlyOwner
    {
        isBuyingPaused = isPaused;
		
    }
    

    function pauseContract(bool isPaused) public onlyOwner
    {
        isContractPaused = isPaused;
    }
	
	
 
    function pauseMinting(bool isPaused) public onlyOwner
    {
        isMintingPaused = isPaused;
    } 

    
    

    function getPuppiesIdsWithPendingAssets() public constant returns (uint[]) 
    {
        return PuppiesIdsWithPendingAssetss;
    }
    
 
    function buyAssets(uint cId, uint aId) public payable 
    {
        require(msg.value>=priceForBuyingAssets);
        require(!isContractPaused);
        require(token.ownerOf(aId)==msg.sender);
        require(PuppiesAgainstId[aId].assetsId==0);
        PuppiesAgainstId[aId].assetsId=cId;
        PuppiesIdsWithPendingAssetss.push(aId);
        owner.transfer(msg.value);
    }
    
    
  
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
 
    function updatePuppies(uint PuppiesId, string name, string desc) public  
    { 
        require(msg.sender==token.ownerOf(PuppiesId));
        PuppiesAgainstId[PuppiesId].name=name;
        PuppiesAgainstId[PuppiesId].desc=desc;

      
    }
   
}