pragma solidity ^0.4.21;

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

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


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

contract CountryJackpot is ERC721, Ownable{
    using SafeMath for uint256;
    /// @dev The TokenSold event is fired whenever a token is sold.
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

    /// @dev Transfer event as defined in current draft of ERC721.
    event Transfer(address from, address to, uint256 tokenId);

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant NAME = "EtherCup2018"; // solhint-disable-line
    string public constant SYMBOL = "EthCup"; // solhint-disable-line

    //starting price for country token
    uint256 private startingPrice = 0.01 ether;

    //step limits to increase purchase price of token effectively
    uint256 private firstStepLimit =  1 ether;
    uint256 private secondStepLimit = 3 ether;
    uint256 private thirdStepLimit = 10 ether;

    //Final Jackpot value, when all buying/betting closes
    uint256 private finalJackpotValue = 0;

    //Flag to show if the Jackpot has completed
    bool public jackpotCompleted = false;

    /*** DATATYPES ***/
    struct Country {
        string name;
    }

    Country[] private countries;

    /// @dev A mapping from country IDs to the address that owns them. All countries have some valid owner address.
    mapping (uint256 => address) public countryIndexToOwner;
    // A mapping from country id to address to show if the Country approved for transfer
    mapping (uint256 => address) public countryIndexToApproved;
    // A mapping from country id to ranks to show what rank of the Country
    mapping (uint256 => uint256) public countryToRank;
    //A mapping from country id to price to store the last purchase price of a country
    mapping (uint256 => uint256) private countryToLastPrice;
    // A mapping from country id to boolean which checks if the user has claimed jackpot for his country token
    mapping (uint256 => bool) public  jackpotClaimedForCountry;
    // A mapping from ranks to the ether to be won from the jackpot.
    mapping (uint256 => uint256) public rankShare;

    // Counts how many tokens a user has.
    mapping (address => uint256) private ownershipTokenCount;

    // @dev A mapping from countryIds to the price of the token.
    mapping (uint256 => uint256) private countryIndexToPrice;

    //@notice Constructor that setups the share for each rank
    function CountryJackpot() public{
        rankShare[1] = 76;
        rankShare[2] = 56;
        rankShare[3] = 48;
        rankShare[4] = 44;
        rankShare[5] = 32;
        rankShare[6] = 24;
        rankShare[7] = 16;
    }

    //@notice Aprrove the transfer of token. A user must own the token to approve it
    function approve( address _to, uint256 _tokenId) public {
      // Caller must own token.
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        countryIndexToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    //@notice Get count of how many tokens an address has
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

    //@notice Create a country with a name, called only by the owner
    function createCountry(string _name) public onlyOwner{
        _createCountry(_name, startingPrice);
    }

    //@notice An address can claim his win from the jackpot after the jackpot is completed
    function getEther(uint256 _countryIndex) public {
        require(countryIndexToOwner[_countryIndex] == msg.sender);
        require(jackpotCompleted);
        require(countryToRank[_countryIndex] != 0);
        require(!jackpotClaimedForCountry[_countryIndex]);

        jackpotClaimedForCountry[_countryIndex] = true;
        uint256 _rankShare = rankShare[countryToRank[_countryIndex]];

        uint256 amount = ((finalJackpotValue).mul(_rankShare)).div(1000);
        msg.sender.transfer(amount);
    }

    //@notice Get complete information about a country token
    function getCountry(uint256 _tokenId) public view returns (
        string ,
        uint256 ,
        address ,
        uint256
    ) {
        Country storage country = countries[_tokenId];
        string memory countryName = country.name;
        uint256 sellingPrice = countryIndexToPrice[_tokenId];
        uint256 rank = countryToRank[_tokenId];
        address owner = countryIndexToOwner[_tokenId];
        return (countryName, sellingPrice, owner, rank);
    }

    //@notice Get the current balance of the contract.
    function getContractBalance() public view returns(uint256) {
        return (address(this).balance);
    }

    //@notice Get the total jackpot value, which is contract balance if the jackpot is not completed.Else
    //its retrieved from variable jackpotCompleted
    function getJackpotTotalValue() public view returns(uint256) {
        if(jackpotCompleted){
            return finalJackpotValue;
        } else{
            return address(this).balance;
        }
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }


    /// @dev Required for ERC-721 compliance.
    function name() public pure returns (string) {
        return NAME;
    }

    //@notice Get the owner of a country token
    /// For querying owner of token
    /// @param _tokenId The tokenID for owner inquiry
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address)
    {
        address owner = countryIndexToOwner[_tokenId];
        return (owner);
    }

    //@dev this function is required to recieve funds
    function () payable {
    }


    //@notice Allows someone to send ether and obtain a country token
    function purchase(uint256 _tokenId) public payable {
        require(!jackpotCompleted);
        require(msg.sender != owner);
        address oldOwner = countryIndexToOwner[_tokenId];
        address newOwner = msg.sender;

        // Making sure token owner is not sending to self
        require(oldOwner != newOwner);

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Making sure sent amount is greater than or equal to the sellingPrice
        require(msg.value >= sellingPrice);

        uint256 sellingPrice = countryIndexToPrice[_tokenId];
        uint256 lastSellingPrice = countryToLastPrice[_tokenId];

        // Update prices
        if (sellingPrice.mul(2) < firstStepLimit) {
            // first stage
            countryIndexToPrice[_tokenId] = sellingPrice.mul(2);
        } else if (sellingPrice.mul(4).div(10) < secondStepLimit) {
            // second stage
            countryIndexToPrice[_tokenId] = sellingPrice.add(sellingPrice.mul(4).div(10));
        } else if(sellingPrice.mul(2).div(10) < thirdStepLimit){
            // third stage
            countryIndexToPrice[_tokenId] = sellingPrice.add(sellingPrice.mul(2).div(10));
        }else {
            // fourth stage
            countryIndexToPrice[_tokenId] = sellingPrice.add(sellingPrice.mul(15).div(100));
        }

        _transfer(oldOwner, newOwner, _tokenId);

        //update last price to current selling price
        countryToLastPrice[_tokenId] = sellingPrice;
        // Pay previous tokenOwner if owner is not initial creator of country
        if (oldOwner != owner) {
            uint256 priceDifference = sellingPrice.sub(lastSellingPrice);
            uint256 oldOwnerPayment = lastSellingPrice.add(priceDifference.sub(priceDifference.div(2)));
            oldOwner.transfer(oldOwnerPayment);
        }

        emit TokenSold(_tokenId, sellingPrice, countryIndexToPrice[_tokenId], oldOwner, newOwner, countries[_tokenId].name);

        uint256 purchaseExcess = msg.value.sub(sellingPrice);
        msg.sender.transfer(purchaseExcess);
    }

    //@notice set country rank by providing index, country name and rank
    function setCountryRank(uint256 _tokenId, string _name, uint256 _rank) public onlyOwner{
        require(_compareStrings(countries[_tokenId].name, _name));
        countryToRank[_tokenId] = _rank;
    }

    ///@notice set jackpotComplete to true and transfer 20 percent share of jackpot to owner
    function setJackpotCompleted() public onlyOwner{
        jackpotCompleted = true;
        finalJackpotValue = address(this).balance;
        uint256 jackpotShare = ((address(this).balance).mul(20)).div(100);
        msg.sender.transfer(jackpotShare);
    }

    /// @dev Required for ERC-721 compliance.
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    /// @notice Allow pre-approved user to take ownership of a token
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = countryIndexToOwner[_tokenId];

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Making sure transfer is approved
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }


    /// @notice Get all tokens of a particular address
    function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCountries = totalSupply();
            uint256 resultIndex = 0;
            uint256 countryId;

            for (countryId = 0; countryId < totalCountries; countryId++) {
                if (countryIndexToOwner[countryId] == _owner)
                {
                    result[resultIndex] = countryId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    /// @notice Total amount of country tokens.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256 total) {
        return countries.length;
    }

    /// @notice Owner initates the transfer of the token to another account
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    ) public {
        require(!jackpotCompleted);
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Third-party initiates transfer of token from address _from to address _to
    /// @param _from The address for the token to be transferred from.
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(!jackpotCompleted);
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }

    /*** PRIVATE FUNCTIONS ***/
    /// Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    /// For checking approval of transfer for address _to
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return countryIndexToApproved[_tokenId] == _to;
    }


    /// For creating Country
    function _createCountry(string _name, uint256 _price) private {
        Country memory country = Country({
            name: _name
        });

        uint256 newCountryId = countries.push(country) - 1;

        countryIndexToPrice[newCountryId] = _price;
        countryIndexToOwner[newCountryId] = msg.sender;
        ownershipTokenCount[msg.sender] = ownershipTokenCount[msg.sender].add(1);
    }

    /// Check for token ownership
    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == countryIndexToOwner[_tokenId];
    }

    /// @dev Assigns ownership of a specific Country to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        // clear any previously approved ownership exchange
        delete countryIndexToApproved[_tokenId];

        // Since the number of countries is capped to 32 we can&#39;t overflow this
        ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
        //transfer ownership
        countryIndexToOwner[_tokenId] = _to;

        ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }

    function _compareStrings(string a, string b) private pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
}