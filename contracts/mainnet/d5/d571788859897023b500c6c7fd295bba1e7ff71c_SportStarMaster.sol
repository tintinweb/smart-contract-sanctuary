pragma solidity ^0.4.18; // solhint-disable-line



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4a2e2f3e2f0a2b32232527302f24642925">[email&#160;protected]</a>> (https://github.com/dete)
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


contract SportStarToken is ERC721 {

    // ***** EVENTS

    // @dev Transfer event as defined in current draft of ERC721.
    //  ownership is assigned, including births.
    event Transfer(address from, address to, uint256 tokenId);



    // ***** STORAGE

    // @dev A mapping from token IDs to the address that owns them. All tokens have
    //  some valid owner address.
    mapping (uint256 => address) public tokenIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) private ownershipTokenCount;

    // @dev A mapping from TokenIDs to an address that has been approved to call
    //  transferFrom(). Each Token can only have one approved address for transfer
    //  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public tokenIndexToApproved;

    // Additional token data
    mapping (uint256 => bytes32) public tokenIndexToData;

    address public ceoAddress;
    address public masterContractAddress;

    uint256 public promoCreatedCount;



    // ***** DATATYPES

    struct Token {
        string name;
    }

    Token[] private tokens;



    // ***** ACCESS MODIFIERS

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyMasterContract() {
        require(msg.sender == masterContractAddress);
        _;
    }



    // ***** CONSTRUCTOR

    function SportStarToken() public {
        ceoAddress = msg.sender;
    }



    // ***** PRIVILEGES SETTING FUNCTIONS

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setMasterContract(address _newMasterContract) public onlyCEO {
        require(_newMasterContract != address(0));

        masterContractAddress = _newMasterContract;
    }



    // ***** PUBLIC FUNCTIONS

    // @notice Returns all the relevant information about a specific token.
    // @param _tokenId The tokenId of the token of interest.
    function getToken(uint256 _tokenId) public view returns (
        string tokenName,
        address owner
    ) {
        Token storage token = tokens[_tokenId];
        tokenName = token.name;
        owner = tokenIndexToOwner[_tokenId];
    }

    // @param _owner The owner whose sport star tokens we are interested in.
    // @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    //  expensive (it walks the entire Tokens array looking for tokens belonging to owner),
    //  but it also returns a dynamic array, which is only supported for web3 calls, and
    //  not contract-to-contract calls.
    function tokensOfOwner(address _owner) public view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;

            uint256 tokenId;
            for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
                if (tokenIndexToOwner[tokenId] == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function getTokenData(uint256 _tokenId) public view returns (bytes32 tokenData) {
        return tokenIndexToData[_tokenId];
    }



    // ***** ERC-721 FUNCTIONS

    // @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
    // @param _to The address to be granted transfer approval. Pass address(0) to
    //  clear all approvals.
    // @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    function approve(address _to, uint256 _tokenId) public {
        // Caller must own token.
        require(_owns(msg.sender, _tokenId));

        tokenIndexToApproved[_tokenId] = _to;

        Approval(msg.sender, _to, _tokenId);
    }

    // For querying balance of a particular account
    // @param _owner The address for balance query
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

    function name() public pure returns (string) {
        return "CryptoSportStars";
    }

    function symbol() public pure returns (string) {
        return "SportStarToken";
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    // For querying owner of token
    // @param _tokenId The tokenID for owner inquiry
    function ownerOf(uint256 _tokenId) public view returns (address owner)
    {
        owner = tokenIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    // @notice Allow pre-approved user to take ownership of a token
    // @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = tokenIndexToOwner[_tokenId];

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Making sure transfer is approved
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

    // For querying totalSupply of token
    function totalSupply() public view returns (uint256 total) {
        return tokens.length;
    }

    // Owner initates the transfer of the token to another account
    // @param _to The address for the token to be transferred to.
    // @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    function transfer(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

    // Third-party initiates transfer of token from address _from to address _to
    // @param _from The address for the token to be transferred from.
    // @param _to The address for the token to be transferred to.
    // @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }



    // ONLY MASTER CONTRACT FUNCTIONS

    function createToken(string _name, address _owner) public onlyMasterContract returns (uint256 _tokenId) {
        return _createToken(_name, _owner);
    }

    function updateOwner(address _from, address _to, uint256 _tokenId) public onlyMasterContract {
        _transfer(_from, _to, _tokenId);
    }

    function setTokenData(uint256 _tokenId, bytes32 tokenData) public onlyMasterContract {
        tokenIndexToData[_tokenId] = tokenData;
    }



    // PRIVATE FUNCTIONS

    // Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    // For checking approval of transfer for address _to
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return tokenIndexToApproved[_tokenId] == _to;
    }

    // For creating Token
    function _createToken(string _name, address _owner) private returns (uint256 _tokenId) {
        Token memory _token = Token({
            name: _name
            });
        uint256 newTokenId = tokens.push(_token) - 1;

        // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
        // let&#39;s just be 100% sure we never let this happen.
        require(newTokenId == uint256(uint32(newTokenId)));

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(address(0), _owner, newTokenId);

        return newTokenId;
    }

    // Check for token ownership
    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == tokenIndexToOwner[_tokenId];
    }

    // @dev Assigns ownership of a specific Token to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        // Since the number of tokens is capped to 2^32 we can&#39;t overflow this
        ownershipTokenCount[_to]++;
        //transfer ownership
        tokenIndexToOwner[_tokenId] = _to;

        // When creating new tokens _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete tokenIndexToApproved[_tokenId];
        }

        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }
}



contract SportStarMaster {

    // ***** EVENTS ***/

    // @dev The Birth event is fired whenever a new token comes into existence.
    event Birth(uint256 tokenId, string name, address owner);

    // @dev The TokenSold event is fired whenever a token is sold.
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner);

    // @dev Transfer event as defined in current draft of ERC721.
    //  ownership is assigned, including births.
    event Transfer(address from, address to, uint256 tokenId);



    // ***** CONSTANTS ***/

    uint256 private startingPrice = 0.001 ether;
    uint256 private firstStepLimit = 0.053613 ether;
    uint256 private secondStepLimit = 0.564957 ether;



    // ***** STORAGE ***/

    // @dev A mapping from TokenIDs to the price of the token.
    mapping(uint256 => uint256) private tokenIndexToPrice;

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cooAddress;

    // The address of tokens contract
    SportStarToken public tokensContract;

    uint256 public promoCreatedCount;


    uint256 private increaseLimit1 = 0.05 ether;
    uint256 private increaseLimit2 = 0.5 ether;
    uint256 private increaseLimit3 = 2.0 ether;
    uint256 private increaseLimit4 = 5.0 ether;



    // ***** ACCESS MODIFIERS ***/

    // @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    // @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    // Access modifier for contract owner only functionality
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        _;
    }



    // ***** CONSTRUCTOR ***/

    function SportStarMaster() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;

        //Old prices
        tokenIndexToPrice[0]=198056585936481135;
        tokenIndexToPrice[1]=198056585936481135;
        tokenIndexToPrice[2]=198056585936481135;
        tokenIndexToPrice[3]=76833314470700771;
        tokenIndexToPrice[4]=76833314470700771;
        tokenIndexToPrice[5]=76833314470700771;
        tokenIndexToPrice[6]=76833314470700771;
        tokenIndexToPrice[7]=76833314470700771;
        tokenIndexToPrice[8]=76833314470700771;
        tokenIndexToPrice[9]=76833314470700771;
        tokenIndexToPrice[10]=76833314470700771;
        tokenIndexToPrice[11]=76833314470700771;
        tokenIndexToPrice[12]=76833314470700771;
        tokenIndexToPrice[13]=76833314470700771;
        tokenIndexToPrice[14]=37264157518289874;
        tokenIndexToPrice[15]=76833314470700771;
        tokenIndexToPrice[16]=144447284479990001;
        tokenIndexToPrice[17]=144447284479990001;
        tokenIndexToPrice[18]=37264157518289874;
        tokenIndexToPrice[19]=76833314470700771;
        tokenIndexToPrice[20]=37264157518289874;
        tokenIndexToPrice[21]=76833314470700771;
        tokenIndexToPrice[22]=105348771387661881;
        tokenIndexToPrice[23]=144447284479990001;
        tokenIndexToPrice[24]=105348771387661881;
        tokenIndexToPrice[25]=37264157518289874;
        tokenIndexToPrice[26]=37264157518289874;
        tokenIndexToPrice[27]=37264157518289874;
        tokenIndexToPrice[28]=76833314470700771;
        tokenIndexToPrice[29]=105348771387661881;
        tokenIndexToPrice[30]=76833314470700771;
        tokenIndexToPrice[31]=37264157518289874;
        tokenIndexToPrice[32]=76833314470700771;
        tokenIndexToPrice[33]=37264157518289874;
        tokenIndexToPrice[34]=76833314470700771;
        tokenIndexToPrice[35]=37264157518289874;
        tokenIndexToPrice[36]=37264157518289874;
        tokenIndexToPrice[37]=76833314470700771;
        tokenIndexToPrice[38]=76833314470700771;
        tokenIndexToPrice[39]=37264157518289874;
        tokenIndexToPrice[40]=37264157518289874;
        tokenIndexToPrice[41]=37264157518289874;
        tokenIndexToPrice[42]=76833314470700771;
        tokenIndexToPrice[43]=37264157518289874;
        tokenIndexToPrice[44]=37264157518289874;
        tokenIndexToPrice[45]=76833314470700771;
        tokenIndexToPrice[46]=37264157518289874;
        tokenIndexToPrice[47]=37264157518289874;
        tokenIndexToPrice[48]=76833314470700771;
    }


    function setTokensContract(address _newTokensContract) public onlyCEO {
        require(_newTokensContract != address(0));

        tokensContract = SportStarToken(_newTokensContract);
    }



    // ***** PRIVILEGES SETTING FUNCTIONS

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }



    // ***** PUBLIC FUNCTIONS ***/
    function getTokenInfo(uint256 _tokenId) public view returns (
        address owner,
        uint256 price,
        bytes32 tokenData
    ) {
        owner = tokensContract.ownerOf(_tokenId);
        price = tokenIndexToPrice[_tokenId];
        tokenData = tokensContract.getTokenData(_tokenId);
    }

    // @dev Creates a new promo Token with the given name, with given _price and assignes it to an address.
    function createPromoToken(address _owner, string _name, uint256 _price) public onlyCOO {
        address tokenOwner = _owner;
        if (tokenOwner == address(0)) {
            tokenOwner = cooAddress;
        }

        if (_price <= 0) {
            _price = startingPrice;
        }

        promoCreatedCount++;
        uint256 newTokenId = tokensContract.createToken(_name, tokenOwner);
        tokenIndexToPrice[newTokenId] = _price;

        Birth(newTokenId, _name, _owner);
    }

    // @dev Creates a new Token with the given name.
    function createContractToken(string _name) public onlyCOO {
        uint256 newTokenId = tokensContract.createToken(_name, address(this));
        tokenIndexToPrice[newTokenId] = startingPrice;

        Birth(newTokenId, _name, address(this));
    }

    function createContractTokenWithPrice(string _name, uint256 _price) public onlyCOO {
        uint256 newTokenId = tokensContract.createToken(_name, address(this));
        tokenIndexToPrice[newTokenId] = _price;

        Birth(newTokenId, _name, address(this));
    }

    function setGamblingFee(uint256 _tokenId, uint256 _fee) public {
        require(msg.sender == tokensContract.ownerOf(_tokenId));
        require(_fee >= 0 && _fee <= 100);

        bytes32 tokenData = byte(_fee);
        tokensContract.setTokenData(_tokenId, tokenData);
    }

    // Allows someone to send ether and obtain the token
    function purchase(uint256 _tokenId) public payable {
        address oldOwner = tokensContract.ownerOf(_tokenId);
        address newOwner = msg.sender;

        uint256 sellingPrice = tokenIndexToPrice[_tokenId];

        // Making sure token owner is not sending to self
        require(oldOwner != newOwner);

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Making sure sent amount is greater than or equal to the sellingPrice
        require(msg.value >= sellingPrice);

        uint256 devCut = calculateDevCut(sellingPrice);
        uint256 payment = SafeMath.sub(sellingPrice, devCut);
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

        tokenIndexToPrice[_tokenId] = calculateNextPrice(sellingPrice);

        tokensContract.updateOwner(oldOwner, newOwner, _tokenId);

        // Pay previous tokenOwner if owner is not contract
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

        TokenSold(_tokenId, sellingPrice, tokenIndexToPrice[_tokenId], oldOwner, newOwner);

        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return tokenIndexToPrice[_tokenId];
    }

    function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
        if (_price < increaseLimit1) {
            return SafeMath.div(SafeMath.mul(_price, 3), 100); // 3%
        } else if (_price < increaseLimit2) {
            return SafeMath.div(SafeMath.mul(_price, 3), 100); // 3%
        } else if (_price < increaseLimit3) {
            return SafeMath.div(SafeMath.mul(_price, 3), 100); // 3%
        } else if (_price < increaseLimit4) {
            return SafeMath.div(SafeMath.mul(_price, 3), 100); // 3%
        } else {
            return SafeMath.div(SafeMath.mul(_price, 2), 100); // 2%
        }
    }

    function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
        if (_price < increaseLimit1) {
            return SafeMath.div(SafeMath.mul(_price, 200), 97);
        } else if (_price < increaseLimit2) {
            return SafeMath.div(SafeMath.mul(_price, 133), 97);
        } else if (_price < increaseLimit3) {
            return SafeMath.div(SafeMath.mul(_price, 125), 97);
        } else if (_price < increaseLimit4) {
            return SafeMath.div(SafeMath.mul(_price, 115), 97);
        } else {
            return SafeMath.div(SafeMath.mul(_price, 113), 98);
        }
    }

    function payout(address _to) public onlyCEO {
        if (_to == address(0)) {
            ceoAddress.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }



    // PRIVATE FUNCTIONS

    // Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
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