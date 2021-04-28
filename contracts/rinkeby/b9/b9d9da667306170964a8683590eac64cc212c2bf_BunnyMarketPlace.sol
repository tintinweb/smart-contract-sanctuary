/**
 *Submitted for verification at Etherscan.io on 2021-04-27
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

// The ERC-721 Interface to reference the Bunny MarketPlace token
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


contract BunnyMarketPlace is Ownable
{
    
	
	struct ForSaleBunny {
        uint bunnyId;
        uint index;
		uint priceForSale;
		bool upForSale;
    }

	mapping (uint => ForSaleBunny) private forSaleBunnyList;

    //the Bunny that have been advertised for selling
    uint[] upForSaleList;
	uint[] upForSaleListPrice;
    
    using SafeMath for uint256;
 
    // The token being sold
    ERC721Interface public token;
    
    
   
	

    
    //variable to show whether the contract has been paused or not
    bool public isContractPaused;
	

	

	
	bool public isBuyingPaused;

	
	//the fees for advertising an Bunny for sale
    uint public priceForSaleAdvertisement = 0.005 ether;

	
	//The owner percentages from selling transactions
    uint public ownerPerHundredShareForBuying = 5;

   


	event BunnyPurchasedFromExchange(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	
	event BunnyListedForSale(address indexed purchaser, uint256 value, uint256 amount);
	event BunnyRemovedFromSale(address indexed owner, uint256 value);
  
   constructor(address _walletOwner,address _tokenAddress) public 
   { 
        require(_walletOwner != 0x0);
        owner = _walletOwner;
        isContractPaused = false;
		isBuyingPaused=false;
		priceForSaleAdvertisement = 0.025 ether;
        
        token = ERC721Interface(_tokenAddress);
    }

    
	
	
	

    function putSaleRequest(uint bunnyId, uint salePrice) public payable
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
        
        //the advertiser is actually the owner of the Bunny id provided
        require(token.ownerOf(bunnyId)==msg.sender);

        // you cannot advertise an Bunny for sale which is already on sale
        require(forSaleBunnyList[bunnyId].upForSale==false);
        
        //putting up the flag for sale 
        forSaleBunnyList[bunnyId].upForSale=true;
        forSaleBunnyList[bunnyId].priceForSale=convertedpricetoEther;
		
		forSaleBunnyList[bunnyId].bunnyId = bunnyId;
        forSaleBunnyList[bunnyId].index = upForSaleList.push(bunnyId)-1;	

		upForSaleListPrice.push(convertedpricetoEther);
        
        //transferring the sale advertisement price to the owner
        owner.transfer(msg.value);
		
		emit BunnyListedForSale(msg.sender,bunnyId,convertedpricetoEther);
        
    }
    
	
	
	function removeBunnyFromSale(uint bunnyId) public
	{
	
		require (!isContractPaused);
        
        // the Bunny id actually belongs to the requester
        require(token.ownerOf(bunnyId)==msg.sender);
        
		forSaleBunnyList[bunnyId].upForSale=false;
        forSaleBunnyList[bunnyId].priceForSale=0;
	    uint toDelete = forSaleBunnyList[bunnyId].index;
        uint lastIndex = upForSaleList[upForSaleList.length-1];
        upForSaleList[toDelete] = lastIndex;
		upForSaleListPrice[toDelete] = lastIndex;
        forSaleBunnyList[lastIndex].index = toDelete;
        upForSaleList.length--;
		upForSaleListPrice.length--;
		
		emit BunnyRemovedFromSale(msg.sender,bunnyId);
	}  
	
	
	
 
    function buyBunnyFromUser(uint bunnyId) public payable 
    {
		require (!isBuyingPaused);
		
        require(msg.sender != 0x0);
        address prevOwner=token.ownerOf(bunnyId);
	

		//Is the Bunny for sale
        require(forSaleBunnyList[bunnyId].upForSale==true);	
		
		//the price of sale
        uint price=forSaleBunnyList[bunnyId].priceForSale;
        
        require(price>0);	
		
        
        //checking that a user is not trying to buy an Bunny from himself
        require(prevOwner!=msg.sender);
		
		
		uint convertedPricetoEther = msg.value;

        //the percentage of owner         
        uint ownerPercentage=forSaleBunnyList[bunnyId].priceForSale.mul(ownerPerHundredShareForBuying);
        ownerPercentage=ownerPercentage.div(100);
		
		//Take Owner percentage from sale
        uint priceMinusOwnerPercentage = forSaleBunnyList[bunnyId].priceForSale.sub(ownerPercentage);
		 
        
        //funds sent should be enough to cover the selling price plus the owner fees
        require(convertedPricetoEther>=price); 

        // transfer token only
       // token.mint(prevOwner,msg.sender,1); 
		// transfer token here
        token.safeTransferFrom(prevOwner,msg.sender,bunnyId);

        // change mapping in BunnyAgainstId
        forSaleBunnyList[bunnyId].upForSale=false;
        forSaleBunnyList[bunnyId].priceForSale=0;

		removeBunnyFromSale(bunnyId);
        
        //transfer of money from buyer to beneficiary
        prevOwner.transfer(priceMinusOwnerPercentage);
        
        //transfer of percentage money to ownerWallet
        owner.transfer(ownerPercentage);
		
		emit BunnyPurchasedFromExchange(msg.sender, prevOwner, bunnyId,convertedPricetoEther);
        
        
    }
    

    function setSaleAdvertisementRate(uint256 newPrice) public onlyOwner returns (bool) 
    {		
        priceForSaleAdvertisement = newPrice;
    }
    
    
    

    function getAllSaleBunny() public constant returns (uint[]) 
    {
        return upForSaleList;
    }
	
	function getAllSaleBunnyPrice() public constant returns (uint[]) 
    {
        return upForSaleListPrice;
    }
 
    function pauseBuying(bool isPaused) public onlyOwner
    {
        isBuyingPaused = isPaused;
		
    }
    

    function pauseContract(bool isPaused) public onlyOwner
    {
        isContractPaused = isPaused;
    }
	
	
 

    
    
   
}