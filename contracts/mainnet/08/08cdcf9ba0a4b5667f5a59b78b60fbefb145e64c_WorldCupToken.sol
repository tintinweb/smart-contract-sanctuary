pragma solidity ^0.4.18;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
contract ERC721 {
    // Required methods
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address addr);
    function takeOwnership(uint256 _tokenId) public;
    function totalSupply() public view returns (uint256 total);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract WorldCupToken is ERC721 {

    /*****------ EVENTS -----*****/
    // @dev whenever a token is sold.
    event WorldCupTokenWereSold(address indexed curOwner, uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice, address indexed prevOwner, uint256 traddingTime);//indexed
    // @dev whenever Share Bonus.
	event ShareBonus(address indexed toOwner, uint256 indexed tokenId, uint256 indexed traddingTime, uint256 remainingAmount);
	// @dev Present. 
    event Present(address indexed fromAddress, address indexed toAddress, uint256 amount, uint256 presentTime);
    // @dev Transfer event as defined in ERC721. 
    event Transfer(address from, address to, uint256 tokenId);

    /*****------- CONSTANTS -------******/
    mapping (uint256 => address) public worldCupIdToOwnerAddress;  //@dev A mapping from world cup team id to the address that owns them. 
    mapping (address => uint256) private ownerAddressToTokenCount; //@dev A mapping from owner address to count of tokens that address owns.
    mapping (uint256 => address) public worldCupIdToAddressForApproved; // @dev A mapping from token id to an address that has been approved to call.
    mapping (uint256 => uint256) private worldCupIdToPrice; // @dev A mapping from token id to the price of the token.
    //mapping (uint256 => uint256) private worldCupIdToOldPrice; // @dev A mapping from token id to the old price of the token.
    string[] private worldCupTeamDescribe;
	uint256 private SHARE_BONUS_TIME = uint256(now);
    address public ceoAddress;
    address public cooAddress;

    /*****------- MODIFIERS -------******/
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }
	
	function destroy() public onlyCEO {
		selfdestruct(ceoAddress);
    }
	
	function payAllOut() public onlyCLevel {
       ceoAddress.transfer(this.balance);
    }

    /*****------- CONSTRUCTOR -------******/
    function WorldCupToken() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
	    for (uint256 i = 0; i < 32; i++) {
		    uint256 newWorldCupTeamId = worldCupTeamDescribe.push("I love world cup!") - 1;
            worldCupIdToPrice[newWorldCupTeamId] = 0 ether;//SafeMath.sub(uint256(3.2 ether), SafeMath.mul(uint256(0.1 ether), i));
	        //worldCupIdToOldPrice[newWorldCupTeamId] = 0 ether;
            _transfer(address(0), msg.sender, newWorldCupTeamId);
	    }
    }

    /*****------- PUBLIC FUNCTIONS -------******/
    function approve(address _to, uint256 _tokenId) public {
        require(_isOwner(msg.sender, _tokenId));
        worldCupIdToAddressForApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    /// For querying balance of a particular account
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerAddressToTokenCount[_owner];
    }

    /// @notice Returns all the world cup team information by token id.
    function getWorlCupByID(uint256 _tokenId) public view returns (string wctDesc, uint256 sellingPrice, address owner) {
        wctDesc = worldCupTeamDescribe[_tokenId];
        sellingPrice = worldCupIdToPrice[_tokenId];
        owner = worldCupIdToOwnerAddress[_tokenId];
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    /// @dev Required for ERC-721 compliance.
    function name() public pure returns (string) {
        return "WorldCupToken";
    }
  
    /// @dev Required for ERC-721 compliance.
    function symbol() public pure returns (string) {
        return "WCT";
    }

    // @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = worldCupIdToOwnerAddress[_tokenId];
        require(owner != address(0));
        return owner;
    }
  
    function setWorldCupTeamDesc(uint256 _tokenId, string descOfOwner) public {
        if(ownerOf(_tokenId) == msg.sender){
	        worldCupTeamDescribe[_tokenId] = descOfOwner;
	    }
    }

	/// Allows someone to send ether and obtain the token
    ///function PresentToCEO() public payable {
	///    ceoAddress.transfer(msg.value);
	///	Present(msg.sender, ceoAddress, msg.value, uint256(now));
	///}
	
    // Allows someone to send ether and obtain the token
    function buyWorldCupTeamToken(uint256 _tokenId) public payable {
        address oldOwner = worldCupIdToOwnerAddress[_tokenId];
        address newOwner = msg.sender;
        require(oldOwner != newOwner); // Make sure token owner is not sending to self
        require(_addressNotNull(newOwner)); //Safety check to prevent against an unexpected 0x0 default.

	    uint256 oldSoldPrice = worldCupIdToPrice[_tokenId];//worldCupIdToOldPrice[_tokenId];
	    uint256 diffPrice = SafeMath.sub(msg.value, oldSoldPrice);
	    uint256 priceOfOldOwner = SafeMath.add(oldSoldPrice, SafeMath.div(diffPrice, 2));
	    uint256 priceOfDevelop = SafeMath.div(diffPrice, 4);
	    worldCupIdToPrice[_tokenId] = msg.value;//SafeMath.add(msg.value, SafeMath.div(msg.value, 10));
	    //worldCupIdToOldPrice[_tokenId] = msg.value;

        _transfer(oldOwner, newOwner, _tokenId);
        if (oldOwner != address(this)) {
	        oldOwner.transfer(priceOfOldOwner);
        }
	    ceoAddress.transfer(priceOfDevelop);
	    if(this.balance >= uint256(3.2 ether)){
            if((uint256(now) - SHARE_BONUS_TIME) >= 86400){
		        for(uint256 i=0; i<32; i++){
		            worldCupIdToOwnerAddress[i].transfer(0.1 ether);
					ShareBonus(worldCupIdToOwnerAddress[i], i, uint256(now), this.balance);
		        }
			    SHARE_BONUS_TIME = uint256(now);
			    //ShareBonus(SHARE_BONUS_TIME, this.balance);
		    }
	    }
	    WorldCupTokenWereSold(newOwner, _tokenId, oldSoldPrice, msg.value, oldOwner, uint256(now));
	}

    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return worldCupIdToPrice[_tokenId];
    }

    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = worldCupIdToOwnerAddress[_tokenId];

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Making sure transfer is approved
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCars = totalSupply();
            uint256 resultIndex = 0;

            uint256 carId;
            for (carId = 0; carId <= totalCars; carId++) {
                if (worldCupIdToOwnerAddress[carId] == _owner) {
                    result[resultIndex] = carId;
                    resultIndex++;
                }
            }
            return result;
        }
    }
  
    function getCEO() public view returns (address ceoAddr) {
        return ceoAddress;
    }

    //Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256 total) {
        return worldCupTeamDescribe.length;
    }
  
    //return BonusPool $
    function getBonusPool() public view returns (uint256) {
        return this.balance;
    }
  
    function getTimeFromPrize() public view returns (uint256) {
        return uint256(now) - SHARE_BONUS_TIME;
    }

    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId) public {
        require(_isOwner(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_isOwner(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }

    /********----------- PRIVATE FUNCTIONS ------------********/
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return worldCupIdToAddressForApproved[_tokenId] == _to;
    }

    function _isOwner(address checkAddress, uint256 _tokenId) private view returns (bool) {
        return checkAddress == worldCupIdToOwnerAddress[_tokenId];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownerAddressToTokenCount[_to]++;
        worldCupIdToOwnerAddress[_tokenId] = _to;  //transfer ownership

        if (_from != address(0)) {
            ownerAddressToTokenCount[_from]--;
            delete worldCupIdToAddressForApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }
}