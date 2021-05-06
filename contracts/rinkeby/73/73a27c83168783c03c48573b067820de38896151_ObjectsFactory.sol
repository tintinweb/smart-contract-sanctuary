/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-13
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

// The ERC-721 Interface to reference the Objects factory token
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


contract ObjectsFactory is Ownable
{
    //The structure defining a single Objects
    struct ObjectsProperties
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
	
	struct ForSaleObjects {
        uint objectId;
        uint index;
		address currentowner;
    }

	mapping (uint => ForSaleObjects) private forSaleObjectsList;

    //the Objects that have been advertised for selling
    uint[] upForSaleList;
	uint[] upForSaleListPrice;
    
    using SafeMath for uint256;
 
    // The token being sold
    ERC721Interface public token;
    
    
    //sequentially generated ids for the Objects
    uint uniqueObjectsId=0;

    //mapping to show all the Objects properties against a single id
    mapping(uint=>ObjectsProperties)  ObjectsAgainstId;
    

    



    
    //the list of addresses that can remove Objects  
    address[] memberAddresses;

    //Objects object to be used in various functions as an intermediate variable
    ObjectsProperties  ObjectsObject;
	
    //the number of Objects limit
    uint public totalObjectsMax = 10000;
	

	// Total free Objects created
    uint256 public totalFreeObjectsMax=1500;

    //the number of free Objects an address can claim
    uint public freeObjectsLimit = 1;
    
    //variable to show whether the contract has been paused or not
    bool public isContractPaused;
	
	//variable to show whether the minting has been paused or not
    bool public isMintingPaused;
	

	
	bool public isBuyingPaused;

	///ether means bnb here
    //rate of each Objects

    uint priceForBuyingAssets = 0.25 ether;
	
	
	uint256 price1 = 0.02 ether;
	uint256 price2 = 0.04 ether;
	uint256 price3 = 0.06 ether;
	uint256 price4 = 0.08 ether;
    uint256 price5 = 0.10 ether;
	uint256 price6 = 0.12 ether;
	
	uint256 pricePack1 = 0.08 ether;
	uint256 pricePack2 = 0.16 ether;
	uint256 pricePack3 = 0.24 ether;
	uint256 pricePack4 = 0.32 ether;
    uint256 pricePack5 = 0.40 ether;
	uint256 pricePack6 = 0.48 ether;
	
	uint256 packscanbuy = 5;
	
	//the fees for advertising an Objects for sale
    uint public priceForSaleAdvertisement = 0.005 ether;

	
	//The owner percentages from selling transactions
    uint public ownerPerHundredShareForBuying = 5;

    // amount of raised money in wei
    uint256 public weiRaised;

    // Total no of Objects created
    uint256 public totalObjectsCreated=0;
	uint256 public totalFreeObjectsCreated=0;
	
    uint[] eggPhaseObjectsIds;
    uint[] ObjectsIdsWithPendingAssetss;


    event ObjectsPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	event ObjectsPurchasedFromExchange(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	
	event ObjectsListedForSale(address indexed purchaser, uint256 value, uint256 amount);
	event ObjectsRemovedFromSale(address indexed owner, uint256 value);
  
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
     * function to get Objects details by id
     **/ 
    
    function getObjectsById(uint aid) public constant returns 
    (string, string,uint,uint)
    {


            return(
			ObjectsAgainstId[aid].name,
            ObjectsAgainstId[aid].desc,
            ObjectsAgainstId[aid].id,
            ObjectsAgainstId[aid].priceForSale
             );
        
    }
	
	
	

	
	
    function getObjectsByIdVisibility(uint aid) public constant 
    returns (address owneraddress,bool upforsale, uint saleprice, string name, string desc,uint birthdate)
    {
	
	address ownersaddress = token.ownerOf(aid);
	//bool approvalon = token.isApprovedForAll(ownersaddress,address(this));
	
        return(
			ownersaddress,
            ObjectsAgainstId[aid].upForSale,
			ObjectsAgainstId[aid].priceForSale,
            ObjectsAgainstId[aid].name,
            ObjectsAgainstId[aid].desc,
			ObjectsAgainstId[aid].birthdate

            );
    }
    
   


    function claimFreeObjectsFromObjectsFactory( string ObjectsName, string ObjectsDesc) public
    {
        require(msg.sender != 0x0);
        require (!isContractPaused);
        uint gId=0;
        //owner can claim as many free Objects as he or she wants
        if (msg.sender!=owner)
        {
            require(token.balanceOf(msg.sender)<freeObjectsLimit);
            gId=1;
        }
		
		if (totalFreeObjectsCreated >= totalFreeObjectsMax) revert();

        //sequentially generated Objects id   
        uniqueObjectsId++;
        
        //Generating an Objects Record
        ObjectsObject = ObjectsProperties({
            id:uniqueObjectsId,
            name:ObjectsName,
            desc:ObjectsDesc,
            upForSale: false,
            priceForSale:0,           
            birthdate:now,
            assetsId:0,           
			GamePoints:""
		
			
        });
        token.createToken(msg.sender, uniqueObjectsId);
        
        //updating the mappings to store Objects information  
        ObjectsAgainstId[uniqueObjectsId]=ObjectsObject;
        totalObjectsCreated++;
		totalFreeObjectsCreated++;
    }
	
	
	
	
	function calculatePriceForToken() public view returns (uint256) 
	{
        require(totalObjectsCreated <= totalObjectsMax, "Sale has already ended");

        if (totalObjectsCreated >= 10001) {
            return price6;       
        } else if (totalObjectsCreated >= 7501) {
            return price5;        
        } else if (totalObjectsCreated >= 5001) {
            return price4;     
        } else if (totalObjectsCreated >= 2501) {
            return price3;       
        } else if (totalObjectsCreated >= 1501) {
            return price2;          
        } else {
            return price1;          
        }
    }
	
	
	function calculatePriceForPack() public view returns (uint256) 
	{
        require(totalObjectsCreated <= totalObjectsMax, "Sale has already ended");

        if (totalObjectsCreated >= 10001) {
            return pricePack6;       
        } else if (totalObjectsCreated >= 7501) {
            return pricePack5;        
        } else if (totalObjectsCreated >= 5001) {
            return pricePack4;     
        } else if (totalObjectsCreated >= 2501) {
            return pricePack3;       
        } else if (totalObjectsCreated >= 1501) {
            return pricePack2;          
        } else {
            return pricePack1;          
        }
    }
	
	
	function mintObjectsFromObjectsFactoryAsPack() public payable 
	{
		require (!isContractPaused);
		require (!isMintingPaused);
        require(validPurchase());
        require(msg.sender != 0x0);
		
		
		
	    if (totalObjectsCreated >= totalObjectsMax) revert();
		
		//everyone except owner has to pay fees
        if (msg.sender!=owner)
        {
            require(msg.value>=calculatePriceForPack());  
        }
		
		uint256 weiAmount = msg.value;
        
        // calculate token amount to be created
        uint256 tokens = weiAmount.div(calculatePriceForPack());
        
        // update state
        weiRaised = weiRaised.add(weiAmount);
		
		for (uint i = 0; i < packscanbuy; i++) 
		{

			uniqueObjectsId++;	
			
			if (totalObjectsCreated >= totalObjectsMax)
			{
				owner.transfer(msg.value);				
				revert();
			}
			

			ObjectsObject = ObjectsProperties({
				id:uniqueObjectsId,
				name:"",
				desc:"",
				upForSale: false,
				priceForSale:0,          
				birthdate:now,
				assetsId:0,           
				GamePoints:""
	
				
				});				
				
			
			token.createToken(msg.sender, uniqueObjectsId); 
			emit ObjectsPurchased(msg.sender, owner, weiAmount, tokens);        
			//updating the mappings to store Objects records
			ObjectsAgainstId[uniqueObjectsId]=ObjectsObject;      
			
			totalObjectsCreated++;
	
        }
		
		//transferring the ethers to the owner of the contract
        owner.transfer(msg.value);
	
	}
  

    function mintObjectsFromObjectsFactory(string ObjectsName, string ObjectsDesc) public payable 
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
		
    
		if (totalObjectsCreated >= totalObjectsMax) revert();
		
		
		
        uint gId=0;
        //owner can claim as many free Objects as he or she wants
        if (msg.sender!=owner)
        {
            gId=1;
        }

    
        uint256 weiAmount = msg.value;
        
        // calculate token amount to be created
        uint256 tokens = weiAmount.div(pricetobuy);
        
        // update state
        weiRaised = weiRaised.add(weiAmount);

    
        uniqueObjectsId++;
		
        //Generating Objects Record
        ObjectsObject = ObjectsProperties({
            id:uniqueObjectsId,
            name:ObjectsName,
            desc:ObjectsDesc,
            upForSale: false,
            priceForSale:0,          
            birthdate:now,
            assetsId:0,           
			GamePoints:""

			
        });
          
          
        //transferring the token
        token.createToken(msg.sender, uniqueObjectsId); 
        emit ObjectsPurchased(msg.sender, owner, weiAmount, tokens);
        
        //updating the mappings to store Objects records
        ObjectsAgainstId[uniqueObjectsId]=ObjectsObject;
        
        
        totalObjectsCreated++;
        
        //transferring the ethers to the owner of the contract
        owner.transfer(msg.value);
    }
  
 
    function buyObjectsFromUser(uint ObjectsId) public payable 
    {
		require (!isBuyingPaused);
		
        require(msg.sender != 0x0);
        address prevOwner=token.ownerOf(ObjectsId);
		
		//Is the Objects for sale
        require(ObjectsAgainstId[ObjectsId].upForSale==true);	
		
		//the price of sale
        uint price=ObjectsAgainstId[ObjectsId].priceForSale;
		
		require(price>0);			
        
        //checking that a user is not trying to buy an Objects from himself
        require(prevOwner!=msg.sender);
		
		//make sure the owner on contract is similar to real one
		require(prevOwner==forSaleObjectsList[ObjectsId].currentowner);
		
		
		uint convertedPricetoEther = msg.value;

        //the percentage of owner         
        uint ownerPercentage=ObjectsAgainstId[ObjectsId].priceForSale.mul(ownerPerHundredShareForBuying);
        ownerPercentage=ownerPercentage.div(100);
		
		//Take Owner percentage from sale
        uint priceMinusOwnerPercentage = ObjectsAgainstId[ObjectsId].priceForSale.sub(ownerPercentage);
		 
        
        //funds sent should be enough to cover the selling price plus the owner fees
        require(convertedPricetoEther>=price); 

        // transfer token only
       // token.mint(prevOwner,msg.sender,1); 
		// transfer token here
        token.safeTransferFrom(prevOwner,msg.sender,ObjectsId);

        // change mapping in ObjectsAgainstId
        ObjectsAgainstId[ObjectsId].upForSale=false;
        ObjectsAgainstId[ObjectsId].priceForSale=0;

		removeObjectFromSale(ObjectsId);
        
        //transfer of money from buyer to beneficiary
        prevOwner.transfer(priceMinusOwnerPercentage);
        
        //transfer of percentage money to ownerWallet
        owner.transfer(ownerPercentage);
		
		emit ObjectsPurchasedFromExchange(msg.sender, prevOwner, ObjectsId,convertedPricetoEther);
        
        
    }
  


    function transferObjectsToAnotherUser(uint ObjectsId,address to) public 
    {
        require (!isContractPaused);
        require(msg.sender != 0x0);
        
        //the requester of the transfer is actually the owner of the Objects id provided
        require(token.ownerOf(ObjectsId)==msg.sender);
        
        //if an Objects has to be transferred, it shouldnt be up for sale
        require(ObjectsAgainstId[ObjectsId].upForSale == false);
        token.safeTransferFrom(msg.sender, to, ObjectsId);

    }	
	

	
	
	function submitGamePoints(uint ObjectsId, string points) public
	{
		require(msg.sender != 0x0);
		require(token.ownerOf(ObjectsId)==msg.sender);		
		ObjectsAgainstId[ObjectsId].GamePoints=points;
	}
	
    

    function putSaleRequest(uint ObjectsId, uint salePrice) public payable
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
        
        //the advertiser is actually the owner of the Objects id provided
        require(token.ownerOf(ObjectsId)==msg.sender);
        
      

        // you cannot advertise an Objects for sale which is already on sale
        require(ObjectsAgainstId[ObjectsId].upForSale==false);


        
        //putting up the flag for sale 
        ObjectsAgainstId[ObjectsId].upForSale=true;
        ObjectsAgainstId[ObjectsId].priceForSale=convertedpricetoEther;
		
		forSaleObjectsList[ObjectsId].objectId = ObjectsId;
        forSaleObjectsList[ObjectsId].index = upForSaleList.push(ObjectsId)-1;
		forSaleObjectsList[ObjectsId].currentowner = msg.sender;
		

		upForSaleListPrice.push(convertedpricetoEther);
        
        //transferring the sale advertisement price to the owner
        owner.transfer(msg.value);
		
		emit ObjectsListedForSale(msg.sender,ObjectsId,convertedpricetoEther);
        
    }
    
	
	
	function removeObjectFromSale(uint objectsId) public
	{
	
		require (!isContractPaused);
        
        // the Objects id actually belongs to the requester
        require(token.ownerOf(objectsId)==msg.sender);
        
		ObjectsAgainstId[objectsId].upForSale=false;
        ObjectsAgainstId[objectsId].priceForSale=0;	
      	
		
	    uint toDelete = forSaleObjectsList[objectsId].index;
        uint lastIndex = upForSaleList[upForSaleList.length-1];
        upForSaleList[toDelete] = lastIndex;
		upForSaleListPrice[toDelete] = lastIndex;
        forSaleObjectsList[lastIndex].index = toDelete; 
		

		
        upForSaleList.length--;
		upForSaleListPrice.length--;
		
		emit ObjectsRemovedFromSale(msg.sender,objectsId);
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
	
	function setPackBuyPrice(uint256 packs) public onlyOwner returns (bool) 
    {		
      
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
	
	
	function setPackBuyPrice(uint256 p1, uint256 p2,uint256 p3, uint256 p4,uint256 p5, uint256 p6) public onlyOwner returns (bool) 
    {		
        pricePack1=p1;
		pricePack2=p2;
		pricePack3=p3;
		pricePack4=p4;
		pricePack5=p5;
		pricePack6=p6;		
    }
	
	
    
	
 
    function changeMaxMintable(uint limit) public onlyOwner
    {
        totalObjectsMax = limit;
    }
	
	

    function changeFreeMaxMintable(uint limit) public onlyOwner
    {
        totalFreeObjectsMax = limit;
    }
	

    function changeBuyShare(uint buyshare) public onlyOwner
    {
        ownerPerHundredShareForBuying = buyshare;
    }
    
    

    function getAllSaleObjects() public constant returns (uint[]) 
    {
        return upForSaleList;
    }
	
	function getAllSaleObjectsPrice() public constant returns (uint[]) 
    {
        return upForSaleListPrice;
    }
    
  
    function changeFreeObjectsLimit(uint limit) public onlyOwner
    {
        freeObjectsLimit = limit;
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

    
    

    function getObjectsIdsWithPendingAssets() public constant returns (uint[]) 
    {
        return ObjectsIdsWithPendingAssetss;
    }
    
 
    function buyAssets(uint cId, uint aId) public payable 
    {
        require(msg.value>=priceForBuyingAssets);
        require(!isContractPaused);
        require(token.ownerOf(aId)==msg.sender);
        require(ObjectsAgainstId[aId].assetsId==0);
        ObjectsAgainstId[aId].assetsId=cId;
        ObjectsIdsWithPendingAssetss.push(aId);
        owner.transfer(msg.value);
    }
    
    
  
    function approvePendingAssets(uint ObjectsId) public
    {
        for (uint i=0;i<memberAddresses.length;i++)
        {
            if (memberAddresses[i]==msg.sender)
            {
                for (uint j=0;j<ObjectsIdsWithPendingAssetss.length;j++)
                {
                    if (ObjectsIdsWithPendingAssetss[j]==ObjectsId)
                    {
                        delete ObjectsIdsWithPendingAssetss[j];
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
 
    function updateObjects(uint ObjectsId, string name, string desc) public  
    { 
        require(msg.sender==token.ownerOf(ObjectsId));
        ObjectsAgainstId[ObjectsId].name=name;
        ObjectsAgainstId[ObjectsId].desc=desc;

      
    }
   
}