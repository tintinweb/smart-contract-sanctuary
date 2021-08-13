/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

//pragma solidity ^0.4.23;

 
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

// The ERC-721 Interface to reference the Dogs Publisher token
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


contract asfasdfsdf is Ownable
{
    


    using SafeMath for uint256;
 
    // The token being sold
    ERC721Interface public token;
    
    
    //sequentially generated ids for the Dogs
    uint uniqueDogsId=1;
	
    // Total no of Dogs created
    uint256 public totalDogsCreated=1;
	uint256 public totalFreeDogsCreated=1;

	
    //the number of Dogs limit
    uint public totalDogsMax = 15000;
	

    //variable to show whether the contract has been paused or not
    bool public isContractPaused;
	
	//variable to show whether the minting has been paused or not
    bool public isMintingPaused;

	
	bool public isBuyingPaused;

    //rate of each Dogs
	
	uint256 price1 = 0.01 ether;
	uint256 price2 = 0.025 ether;
	uint256 price3 = 0.055 ether;
	uint256 price4 = 0.075 ether;
    uint256 price5 = 0.10 ether;
	uint256 price6 = 0.125 ether;
	uint256 price7 = 0.15 ether;
	
	uint256 public packscanbuy = 20;

    // amount of raised money in wei
    uint256 public weiRaised;


	



   event DogsPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  
   constructor(address _walletOwner,address _tokenAddress) public 
   { 
        require(_walletOwner != 0x0);
        owner = _walletOwner;
        isContractPaused = false;
		isMintingPaused = false;
		isBuyingPaused=false;
        token = ERC721Interface(_tokenAddress);
    }


	
	function calculatePriceForToken(uint totalcreated) public view returns (uint256) 
	{
        require(totalcreated <= totalDogsMax, "Sale has already ended");

		if (totalcreated >= 12501) {
            return price7; 
		    
		}
		else if (totalcreated >= 10001) {
            return price6; 
		    
		}
		else if (totalcreated >= 7501) {
            return price5;  
		    
		}
		else if (totalcreated >= 5001) {
            return price4; 
		    
		}
		else if (totalcreated >= 2501) {
            return price3;          
        } 
		else if (totalcreated >= 1001) {
            return price2;          
        } 
		else {
            return price1;          
        }
    }
	
	
	
	

	
	function mintDogsFromDogsPublisherAsPack(uint noofnft) public payable 
	{
		require (!isContractPaused);
		require (!isMintingPaused);
        require(validPurchase());
		require(noofnft>0);
        require(msg.sender != 0x0);
		
		uint256 priceforpack = calculatePriceForToken(totalDogsCreated);
		
		priceforpack = priceforpack.mul(noofnft);
		
	    if (totalDogsCreated >= totalDogsMax) revert();
		
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
		
		require(noofnft<=packscanbuy);		
		
		
		for (uint i = 0; i < noofnft; i++) 
		{

			
			
			if (totalDogsCreated >= totalDogsMax)
			{
				owner.transfer(msg.value);				
				revert();
			}
			
			uniqueDogsId++;	
			
			token.createToken(msg.sender, uniqueDogsId); 
			emit DogsPurchased(msg.sender, owner, weiAmount, tokens);       
	
			
			totalDogsCreated++;
	
        }
		
		//transferring the ethers to the owner of the contract
        owner.transfer(msg.value);
	
	}
  


  
    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) 
    {
	
		uint256 pricetobuy=calculatePriceForToken(totalDogsCreated);
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
  
	
	function setPackBuyNo(uint256 packs) public onlyOwner returns (bool) 
    {      
		packscanbuy=packs;
    }
	
	function setMintPrice(uint256 p1, uint256 p2,uint256 p3,uint256 p4, uint256 p5,uint256 p6,uint256 p7) public onlyOwner returns (bool) 
    {		
        price1=p1;
		price2=p2;
		price3=p3;
		price4=p4;
		price5=p5;
		price6=p6;
		price7=p7;
			
    }
	
	
	
 
    function changeMaxMintable(uint limit) public onlyOwner
    {
        totalDogsMax = limit;
    }
	

 
    

    function pauseContract(bool isPaused) public onlyOwner
    {
        isContractPaused = isPaused;
    }
	
	
 
    function pauseMinting(bool isPaused) public onlyOwner
    {
        isMintingPaused = isPaused;
    } 

    


   
}