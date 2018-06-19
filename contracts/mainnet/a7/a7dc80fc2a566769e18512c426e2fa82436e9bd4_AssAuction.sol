pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath8
 * @dev SafeMath library implemented for uint8
 */
library SafeMath8 {

  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    if (a == 0) {
      return 0;
    }
    uint8 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint8 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    assert(b <= a);
    return a - b;
  }

  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {

	using SafeMath for uint256;
	using SafeMath32 for uint32;
	using SafeMath8 for uint8;

  address internal owner;
  address public admin;

  event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);


  constructor() public {
    owner = msg.sender;
  }



  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }


  function transferAdminship(address newAdmin) public onlyOwner {
    require(newAdmin != address(0));
    emit AdminshipTransferred(admin, newAdmin);
    admin = newAdmin;
  }

}

contract Terminable is Ownable {


		function terminate() external onlyOwner {
			selfdestruct(owner);
		}
		
		
}

contract ERC721 is Terminable {

  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalToAll(address indexed _owner, uint256 _tokenId);


  
}

contract AssFactory is ERC721 {

	
    
    struct Ass {
		string name;
		uint32 id;
		string class;
		uint cardNumber;
		uint cardType;
		uint256 priceInSzabo;
    }
	
	Ass[] public asses;
	
	
	mapping (uint => address) public assToOwner;
	mapping (address => uint) public ownerAssCount;
	
	
	modifier onlyOwnerOf(uint _id) {
    require(msg.sender == assToOwner[_id]);
    _;
    }
    
    event Withdrawal(uint256 balance);
    event AssCreated(bool done);
    
    event FeeChanged(uint _newFee);
	
    function getAssTotal() public constant returns(uint) {
    return asses.length;
    }
    
    function getAssData(uint index) public view returns(string, uint, string, uint, uint, uint) {
    return (asses[index].name, asses[index].id, asses[index].class, asses[index].cardNumber, asses[index].cardType, asses[index].priceInSzabo);
    }

    
      function getAssesByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerAssCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < asses.length; i++) {
      if (assToOwner[i.add(2536)] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }


    function _createAss(string _name, uint32 _id, string _class, uint _cardNumber, uint _cardType, uint256 _priceInSzabo) private {
		asses.push(Ass(_name, _id, _class, _cardNumber, _cardType, _priceInSzabo));
		assToOwner[_id] = msg.sender;
		ownerAssCount[msg.sender] = ownerAssCount[msg.sender].add(1);
		bool done = true;
		emit AssCreated(done);
    }
	
	function _getId() internal view returns(uint32){
		uint32 newId = uint32(asses.length.add(2536));
		return newId;
	}
	
	function startCreatingAss(string _name, string _class, uint _cardNumber, uint _cardType, uint256 _priceInSzabo) public onlyAdmin {
		uint32 newId = _getId();
		_createAss(_name, newId, _class, _cardNumber, _cardType, _priceInSzabo);
	}
	

    


	
	
}



contract AssMarket is AssFactory {

//---------Auction Variables------------------------------------------------------   
    uint public NumberOfAuctions = 0;
    uint public totalSzaboInBids = 0;
    uint public bidFeePercents = 3;
    uint public everyBidFee = 1800;
    uint public startAuctionFee = 1800;
    uint public maxDuration = 10;
    uint public minBidDifferenceInSzabo = 1000;
    
    
    
    mapping(uint => uint) public auctionEndTime;
    mapping(uint => uint) public auctionedAssId;
    mapping(uint => address) public auctionOwner;
    mapping(uint => bool) public auctionEnded;
    mapping(uint => address) public highestBidderOf;
    mapping(uint => uint) public highestBidOf;
    mapping(uint => uint) public startingBidOf;
    
    mapping(uint => uint) public assInAuction;
//---------------------------------------------------------------------------------   

    	uint256 public approveFee = 1800;
    	uint256 public takeOwnershipFeePercents = 3;
    	uint256 public cancelApproveFee = 1800;
    	
    	mapping (uint => address) public assApprovals;
    	mapping (uint => bool) public assToAllApprovals;
    	
        event PriceChanged(uint newPrice, uint assId);
        event ApprovalCancelled(uint assId);
        event AuctionReverted(uint auctionId);
    	
    	function setTakeOwnershipFeePercents(uint _newFee) public onlyAdmin {
		    takeOwnershipFeePercents = _newFee;	
		    emit FeeChanged(_newFee);
	    }
    	

	    
	    function setApproveFee(uint _newFee) public onlyAdmin {
		    approveFee = _newFee;	
		    emit FeeChanged(_newFee);
	    }
	    
	    function setCancelApproveFee(uint _newFee) public onlyAdmin {
		    cancelApproveFee = _newFee;	
		    emit FeeChanged(_newFee);
	    }
	    
    

	 function setPriceOfAss(uint256 _newPrice, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
		asses[_tokenId.sub(2536)].priceInSzabo = _newPrice;
		emit PriceChanged(_newPrice, _tokenId);
	 }
	 
	 function balanceOf(address _owner) public view returns (uint256 _balance) {
		return ownerAssCount[_owner];
	 }
	
	 function ownerOf(uint256 _tokenId) public view returns (address _owner) {
		return assToOwner[_tokenId];
	 }
	 
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
		ownerAssCount[_to] = ownerAssCount[_to].add(1);
		ownerAssCount[_from] = ownerAssCount[_from].sub(1);
		assToOwner[_tokenId] = _to;
		emit Transfer(_from, _to, _tokenId);
	}
	
	function transfer(address _to, uint256 _tokenId) public onlyAdmin onlyOwnerOf(_tokenId){
		_transfer(msg.sender, _to, _tokenId);
	}

	function approve(address _to, uint256 _tokenId) public payable onlyOwnerOf(_tokenId) {
		require(msg.value == approveFee * 1 szabo && assInAuction[ _tokenId] == 0);
		uint transferingAss = _tokenId.sub(2536);
		assApprovals[transferingAss] = _to;
		emit Approval(msg.sender, _to, _tokenId);
	}
	
	 function approveForAll(uint256 _tokenId) public payable onlyOwnerOf(_tokenId) {

	    require(msg.value == approveFee * 1 szabo && assInAuction[ _tokenId] == 0);
		uint transferingAss = _tokenId.sub(2536);
		assToAllApprovals[transferingAss] = true;
		emit ApprovalToAll(msg.sender, _tokenId);
	 }
	 
	 function cancelApproveForAll(uint256 _tokenId) public payable onlyOwnerOf(_tokenId) {
	    uint transferingAss = _tokenId.sub(2536);
	    require(msg.value == cancelApproveFee * 1 szabo && assToAllApprovals[transferingAss] == true);
		assToAllApprovals[transferingAss] = false;
		emit ApprovalCancelled(_tokenId);
	 }
	 
	 function cancelApproveForAddress(uint256 _tokenId) public payable onlyOwnerOf(_tokenId) {
		require(msg.value == cancelApproveFee * 1 szabo && assApprovals[transferingAss] != 0x0000000000000000000000000000000000000000);
		uint transferingAss = _tokenId.sub(2536);
		assApprovals[transferingAss] = 0x0000000000000000000000000000000000000000;
		emit ApprovalCancelled(_tokenId);
	 }
	 
	function getTakeOwnershipFee(uint _price) public view returns(uint) {
        uint takeOwnershipFee = (_price.div(100)).mul(takeOwnershipFeePercents);
        return(takeOwnershipFee);
    }
	 
	function takeOwnership(uint256 _tokenId) public payable {
	    uint idOfTransferingAss = _tokenId.sub(2536);
	    uint assPrice = asses[idOfTransferingAss].priceInSzabo;
	    address ownerOfAss = ownerOf(_tokenId);
	    uint sendAmount = assPrice.sub(getTakeOwnershipFee(assPrice));
	    
		require(msg.value == assPrice * 1 szabo);
		require(assApprovals[idOfTransferingAss] == msg.sender || assToAllApprovals[idOfTransferingAss] == true);
		

		
		assToAllApprovals[idOfTransferingAss] = false;
		assApprovals[idOfTransferingAss] = 0;
		_transfer(ownerOfAss, msg.sender, _tokenId);
		

		ownerOfAss.transfer(sendAmount * 1 szabo);

	}
	
	function _getPrice(uint256 _tokenId) view public returns(uint){
	      uint tokenPrice = asses[_tokenId.sub(2536)].priceInSzabo;
		  return (tokenPrice) * 1 szabo;
	}
	
	
}



contract AssFunctions is AssMarket {
    
    uint256 functionOnePrice = 1800;
    uint256 functionTwoPrice = 1800;
    uint256 functionThreePrice = 1800;
    uint256 functionFourPrice = 1800;
    uint256 functionFivePrice = 1800;
    uint256 functionSixPrice = 1800;
    uint256 functionSevenPrice = 1800;
    uint256 functionEightPrice = 1800;
    
    uint256 galleryOnePrice = 1800;
    uint256 galleryTwoPrice = 1800;
    uint256 galleryThreePrice = 1800;
    uint256 galleryFourPrice = 1800;
    uint256 galleryFivePrice = 1800;
    uint256 gallerySixPrice = 1800;
    uint256 gallerySevenPrice = 1800;
    
    event OneOfMassFunctionsLaunched(bool launched);
    event OneOfGalleryFunctionsLaunched(bool launched);
//---------------------------------------------------------------------------------   
    
            function setFunctionOnePrice(uint _newFee) public onlyAdmin {
		        functionOnePrice = _newFee;
		        emit FeeChanged(_newFee);
            }
            
            function setFunctionTwoPrice(uint _newFee) public onlyAdmin {
		        functionTwoPrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
            function setFunctionThreePrice(uint _newFee) public onlyAdmin {
		        functionThreePrice = _newFee;
		        emit FeeChanged(_newFee);
            }
            
            function setFunctionFourPrice(uint _newFee) public onlyAdmin {
		        functionFourPrice = _newFee;
		        emit FeeChanged(_newFee);
            }
            
            function setFunctionFivePrice(uint _newFee) public onlyAdmin {
		        functionFivePrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
            function setFunctionSixPrice(uint _newFee) public onlyAdmin {
		        functionSixPrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
            function setFunctionSevenPrice(uint _newFee) public onlyAdmin {
		        functionSevenPrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
            function setFunctionEightPrice(uint _newFee) public onlyAdmin {
		        functionEightPrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
//---------------------------------------------------------------------------------       
            
            
            function setGalleryOnePrice(uint _newFee) public onlyAdmin {
		        galleryOnePrice = _newFee;	
            }
            
            function setGalleryTwoPrice(uint _newFee) public onlyAdmin {
		        galleryTwoPrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
            function setGalleryThreePrice(uint _newFee) public onlyAdmin {
		        galleryThreePrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
            function setGalleryFourPrice(uint _newFee) public onlyAdmin {
		        galleryFourPrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
            function setGalleryFivePrice(uint _newFee) public onlyAdmin {
		        galleryFivePrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
            function setGallerySixPrice(uint _newFee) public onlyAdmin {
		        gallerySixPrice = _newFee;	
		        emit FeeChanged(_newFee);
            }
            
            function setGallerySevenPrice(uint _newFee) public onlyAdmin {
		        gallerySevenPrice = _newFee;
		        emit FeeChanged(_newFee);
            }
            
//-------------------------------------------------------       
            
 
 function functionOne() public payable returns(bool) {
     require( msg.value == functionOnePrice * 1 szabo);
     return(true);
     emit OneOfMassFunctionsLaunched(true);
 }
 
  function functionTwo() public payable returns(bool) {
     require( msg.value == functionTwoPrice * 1 szabo);
     return(true);
     emit OneOfMassFunctionsLaunched(true);
 }
 
  function functionThree() public payable returns(bool) {
     require( msg.value == functionThreePrice * 1 szabo);
     return(true);
     emit OneOfMassFunctionsLaunched(true);
 }
 
  function functionFour() public payable returns(bool) {
     require( msg.value == functionFourPrice * 1 szabo);
     return(true);
     emit OneOfMassFunctionsLaunched(true);
 }
 
  function functionFive() public payable returns(bool) {
     require( msg.value == functionFivePrice * 1 szabo);
     return(true);
     emit OneOfMassFunctionsLaunched(true);
 }
 
  function functionSix() public payable returns(bool) {
     require( msg.value == functionSixPrice * 1 szabo);
     return(true);
     emit OneOfMassFunctionsLaunched(true);
 }
 
  function functionSeven() public payable returns(bool) {
     require( msg.value == functionSevenPrice * 1 szabo);
     return(true);
     emit OneOfMassFunctionsLaunched(true);
 }
 
  function functionEight() public payable returns(bool) {
     require( msg.value == functionEightPrice * 1 szabo);
     return(true);
     emit OneOfMassFunctionsLaunched(true);
 }
 
 
//-------------------------------------------------------       
 
 
  function galleryOne() public payable returns(bool) {
     require( msg.value == galleryOnePrice * 1 szabo);
     return(true);
     emit OneOfGalleryFunctionsLaunched(true);
 }
 
  function galleryTwo() public payable returns(bool) {
     require( msg.value == galleryTwoPrice * 1 szabo);
     return(true);
     emit OneOfGalleryFunctionsLaunched(true);
 }
 
  function galleryThree() public payable returns(bool) {
     require( msg.value == galleryThreePrice * 1 szabo);
     return(true);
     emit OneOfGalleryFunctionsLaunched(true);
 }
 
  function galleryFour() public payable returns(bool) {
     require( msg.value == galleryFourPrice * 1 szabo);
     return(true);
     emit OneOfGalleryFunctionsLaunched(true);
 }
 
  function galleryFive() public payable returns(bool) {
     require( msg.value == galleryFivePrice * 1 szabo);
     return(true);
     emit OneOfGalleryFunctionsLaunched(true);
 }
 
  function gallerySix() public payable returns(bool) {
     require( msg.value == gallerySixPrice * 1 szabo);
     return(true);
     emit OneOfGalleryFunctionsLaunched(true);
 }
 
  function gallerySeven() public payable returns(bool) {
     require( msg.value == gallerySevenPrice * 1 szabo);
     return(true);
     emit OneOfGalleryFunctionsLaunched(true);
 }
 
 
 
 
    
}



contract AssAuction is AssFunctions {
    

    
  modifier onlyOwnerOfAuction(uint _auctionId) {
    require(msg.sender == auctionOwner[_auctionId]);
    _;
  }
    
    event HighestBidIncreased(address bidder, uint amount, uint auctionId);
    event AuctionCreated(address creator, uint auctionedAss, uint auctionId);
    event AuctionEnded(address winner, uint amount, uint auctionId, uint auctionedAss);
    
    function getRemainingTimeOf(uint _auctionId) public view returns(uint){
        uint remainingTime = auctionEndTime[_auctionId].sub(now);
        return(remainingTime);
    }
    
    function setMinBidDifferenceInSzabo(uint _newDifference) public onlyAdmin {
        minBidDifferenceInSzabo = _newDifference;
        emit FeeChanged(_newDifference);
    }
    
    function setBidFeePercents(uint _newFee) public onlyAdmin {
		    bidFeePercents = _newFee;
		    emit FeeChanged(_newFee);
	}
	
	function setEveryBidFee(uint _newFee) public onlyAdmin {
		    everyBidFee = _newFee;	
		    emit FeeChanged(_newFee);
	}
    
    function setStartAuctionFee(uint _newFee) public onlyAdmin{
        startAuctionFee = _newFee;
        emit FeeChanged(_newFee);
    }
    

    
    function setMaxDuration(uint _newMaxDuration) public onlyAdmin{
        maxDuration = _newMaxDuration;
        emit FeeChanged(_newMaxDuration);
    }
    
    function getAuctionData(uint _auctionId) public view returns(uint _endTime, uint _auctionedAssId, address _auctionOwner, bool _ended, address _highestBidder, uint _highestBid, uint _startingBid) {
    return (auctionEndTime[_auctionId], auctionedAssId[_auctionId], auctionOwner[_auctionId], auctionEnded[_auctionId], highestBidderOf[_auctionId], highestBidOf[_auctionId], startingBidOf[_auctionId]);
    }
    
    function startAuction(uint _assId, uint _duration, uint _startingBidInSzabo) public payable onlyOwnerOf(_assId){

        require(assInAuction[_assId] == 0 && assToAllApprovals[_assId.sub(2536)] != true);
        require(assApprovals[_assId.sub(2536)] == 0x0000000000000000000000000000000000000000);
        require(msg.value == startAuctionFee * 1 szabo);
        require(_duration <= maxDuration);
        
        uint auctionId = NumberOfAuctions.add(1);
        
        startingBidOf[auctionId] = _startingBidInSzabo;
        auctionEndTime[auctionId] = now + (_duration * 1 days);
        auctionedAssId[auctionId] = _assId;
        auctionOwner[auctionId] = msg.sender;
        NumberOfAuctions = NumberOfAuctions.add(1);
        assInAuction[_assId] = auctionId;
        emit AuctionCreated(msg.sender, _assId, auctionId);
    }
    
    function getBidFee(uint _bid) public view returns(uint) {
        uint bidFee = (_bid.div(100)).mul(bidFeePercents);
        return(bidFee);
    }
    
    function bid(uint _auctionId) public payable {
        require(now <= auctionEndTime[_auctionId]);
        require(msg.value >= (highestBidOf[_auctionId] * 1 szabo) + ((minBidDifferenceInSzabo + everyBidFee) * 1 szabo) && msg.value >= (startingBidOf[_auctionId] + minBidDifferenceInSzabo + everyBidFee) * 1 szabo);
        require(msg.sender != auctionOwner[_auctionId]);
        
        uint msgvalueInSzabo = (msg.value / 1000000000000);
        uint newBid = (msgvalueInSzabo).sub(everyBidFee);

        if (highestBidOf[_auctionId] != 0) {
            withdraw(_auctionId);
        }
        totalSzaboInBids = totalSzaboInBids + newBid;
        totalSzaboInBids = totalSzaboInBids - highestBidOf[_auctionId];
        
        highestBidderOf[_auctionId] = msg.sender;
        highestBidOf[_auctionId] = newBid;
        
        emit HighestBidIncreased(msg.sender, newBid, _auctionId);
    }

    /// Withdraw a bid that was overbid.
    function withdraw(uint _auctionId) internal {
        
        uint amount = highestBidOf[_auctionId];
        address highestManBidder = highestBidderOf[_auctionId];
        if (amount > 0) {
             highestManBidder.transfer(amount * 1 szabo);
            }
    }
    
        function auctionEnd(uint _auctionId) public {

        address ownerOfAuction = auctionOwner[_auctionId];
        address highestAuctionBidder = highestBidderOf[_auctionId];
        uint amount = highestBidOf[_auctionId].sub(getBidFee(highestBidOf[_auctionId]));
        uint idOfAuctionedAss = auctionedAssId[_auctionId];
        
        // 1. Conditions
        require(now >= auctionEndTime[_auctionId]);
        require(auctionEnded[_auctionId] == false);

        // 2. Effects
        highestBidOf[_auctionId] = 0;
        highestBidderOf[_auctionId] = 0x0000000000000000000000000000000000000000;
        
        auctionEnded[_auctionId] = true;
        emit AuctionEnded(highestAuctionBidder, amount, _auctionId, idOfAuctionedAss);

        // 3. Interaction
        if (highestAuctionBidder != 0x0000000000000000000000000000000000000000) {
            _transfer(ownerOfAuction, highestAuctionBidder, idOfAuctionedAss);
            assInAuction[idOfAuctionedAss] = 0;
            totalSzaboInBids = totalSzaboInBids.sub(amount);
            ownerOfAuction.transfer(amount * 1 szabo);
            }
        }
        


       
       
       function revertAuction(uint _auctionId) public onlyAdmin {
        
        address highestAuctionBidder = highestBidderOf[_auctionId];
        uint amount = highestBidOf[_auctionId];
        uint idOfAuctionedAss = auctionedAssId[_auctionId];
        
        totalSzaboInBids = totalSzaboInBids.sub(amount);        
        assInAuction[idOfAuctionedAss] = 0;
        
        auctionEndTime[_auctionId] = 0;
        auctionedAssId[_auctionId] = 0;
        auctionOwner[_auctionId] = 0x0000000000000000000000000000000000000000;
        startingBidOf[_auctionId] = 0;
        
        highestBidOf[_auctionId] = 0;
        highestBidderOf[_auctionId] = 0x0000000000000000000000000000000000000000;
                
        auctionEnded[_auctionId] = true;
                
        if (amount > 0) {
             highestAuctionBidder.transfer(amount  * 1 szabo);
            }
            
        emit AuctionReverted(_auctionId);
        }
        
        
    function getBalanceOfContractInSzabo() external view onlyOwner returns(uint256) {
    uint contractBalance = address(this).balance * 1000000;
    return (contractBalance);
    }


    function withdraw() external onlyOwner {
	    uint amountToWithdraw = address(this).balance.sub(totalSzaboInBids * 1 szabo);
        owner.transfer(amountToWithdraw);
        emit Withdrawal(amountToWithdraw);
    }
    
    
    
}