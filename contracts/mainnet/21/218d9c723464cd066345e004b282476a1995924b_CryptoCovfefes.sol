pragma solidity 0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint a, uint b) internal pure returns(uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }
    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint a, uint b) internal pure returns(uint) {
        assert(b <= a);
        return a - b;
    }
    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="81e5e4f5e4c1e0f9e8eeecfbe4efafe2ee">[email&#160;protected]</a>> (https://github.com/dete)

contract ERC721 {
    // Required methods
    function approve(address _to, uint _tokenId) public;
    function balanceOf(address _owner) public view returns(uint balance);
    function implementsERC721() public pure returns(bool);
    function ownerOf(uint _tokenId) public view returns(address addr);
    function takeOwnership(uint _tokenId) public;
    function totalSupply() public view returns(uint total);
    function transferFrom(address _from, address _to, uint _tokenId) public;
    function transfer(address _to, uint _tokenId) public;

    //event Transfer(uint tokenId, address indexed from, address indexed to);
    event Approval(uint tokenId, address indexed owner, address indexed approved);
    
    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint tokenId);
    // function tokenMetadata(uint _tokenId) public view returns (string infoUrl);
}
contract CryptoCovfefes is ERC721 {
    /*** CONSTANTS ***/
    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant NAME = "CryptoCovfefes";
    string public constant SYMBOL = "Covfefe Token";
    
    uint private constant startingPrice = 0.001 ether;
    
    uint private constant PROMO_CREATION_LIMIT = 5000;
    uint private constant CONTRACT_CREATION_LIMIT = 45000;
    uint private constant SaleCooldownTime = 12 hours;
    
    uint private randNonce = 0;
    uint private constant duelVictoryProbability = 51;
    uint private constant duelFee = .001 ether;
    
    uint private addMeaningFee = .001 ether;

    /*** EVENTS ***/
        /// @dev The Creation event is fired whenever a new Covfefe comes into existence.
    event NewCovfefeCreated(uint tokenId, string term, string meaning, uint generation, address owner);
    
    /// @dev The Meaning added event is fired whenever a Covfefe is defined
    event CovfefeMeaningAdded(uint tokenId, string term, string meaning);
    
    /// @dev The CovfefeSold event is fired whenever a token is bought and sold.
    event CovfefeSold(uint tokenId, string term, string meaning, uint generation, uint sellingpPice, uint currentPrice, address buyer, address seller);
    
     /// @dev The Add Value To Covfefe event is fired whenever value is added to the Covfefe token
    event AddedValueToCovfefe(uint tokenId, string term, string meaning, uint generation, uint currentPrice);
    
     /// @dev The Transfer Covfefe event is fired whenever a Covfefe token is transferred
     event CovfefeTransferred(uint tokenId, address from, address to);
     
    /// @dev The ChallengerWinsCovfefeDuel event is fired whenever the Challenging Covfefe wins a duel
    event ChallengerWinsCovfefeDuel(uint tokenIdChallenger, string termChallenger, uint tokenIdDefender, string termDefender);
    
    /// @dev The DefenderWinsCovfefeDuel event is fired whenever the Challenging Covfefe wins a duel
    event DefenderWinsCovfefeDuel(uint tokenIdDefender, string termDefender, uint tokenIdChallenger, string termChallenger);

    /*** STORAGE ***/
    /// @dev A mapping from covfefe IDs to the address that owns them. All covfefes have
    ///  some valid owner address.
    mapping(uint => address) public covfefeIndexToOwner;
    
    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping(address => uint) private ownershipTokenCount;
    
    /// @dev A mapping from CovfefeIDs to an address that has been approved to call
    ///  transferFrom(). Each Covfefe can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping(uint => address) public covfefeIndexToApproved;
    
    // @dev A mapping from CovfefeIDs to the price of the token.
    mapping(uint => uint) private covfefeIndexToPrice;
    
    // @dev A mapping from CovfefeIDs to the price of the token.
    mapping(uint => uint) private covfefeIndexToLastPrice;
    
    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public covmanAddress;
    address public covmanagerAddress;
    uint public promoCreatedCount;
    uint public contractCreatedCount;
    
    /*** DATATYPES ***/
    struct Covfefe {
        string term;
        string meaning;
        uint16 generation;
        uint16 winCount;
        uint16 lossCount;
        uint64 saleReadyTime;
    }
    
    Covfefe[] private covfefes;
    /*** ACCESS MODIFIERS ***/
    /// @dev Access modifier for Covman-only functionality
    modifier onlyCovman() {
        require(msg.sender == covmanAddress);
        _;
    }
    /// @dev Access modifier for Covmanager-only functionality
    modifier onlyCovmanager() {
        require(msg.sender == covmanagerAddress);
        _;
    }
    /// Access modifier for contract owner only functionality
    modifier onlyCovDwellers() {
        require(msg.sender == covmanAddress || msg.sender == covmanagerAddress);
        _;
    }
    
    /*** CONSTRUCTOR ***/
    function CryptoCovfefes() public {
        covmanAddress = msg.sender;
        covmanagerAddress = msg.sender;
    }
    /*** PUBLIC FUNCTIONS ***/
    /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint _tokenId) public {
        // Caller must own token.
        require(_owns(msg.sender, _tokenId));
        covfefeIndexToApproved[_tokenId] = _to;
        emit Approval(_tokenId, msg.sender, _to);
    }
    
    /// For querying balance of a particular account
    /// @param _owner The address for balance query
    /// @dev Required for ERC-721 compliance.
    function balanceOf(address _owner) public view returns(uint balance) {
        return ownershipTokenCount[_owner];
    }
    ///////////////////Create Covfefe///////////////////////////

    /// @dev Creates a new promo Covfefe with the given term, with given _price and assignes it to an address.
    function createPromoCovfefe(address _owner, string _term, string _meaning, uint16 _generation, uint _price) public onlyCovmanager {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);
        address covfefeOwner = _owner;
        if (covfefeOwner == address(0)) {
            covfefeOwner = covmanagerAddress;
        }
        if (_price <= 0) {
            _price = startingPrice;
        }
        promoCreatedCount++;
        _createCovfefe(_term, _meaning, _generation, covfefeOwner, _price);
    }
    
    /// @dev Creates a new Covfefe with the given term.
    function createContractCovfefe(string _term, string _meaning, uint16 _generation) public onlyCovmanager {
        require(contractCreatedCount < CONTRACT_CREATION_LIMIT);
        contractCreatedCount++;
        _createCovfefe(_term, _meaning, _generation, address(this), startingPrice);
    }

    function _triggerSaleCooldown(Covfefe storage _covfefe) internal {
        _covfefe.saleReadyTime = uint64(now + SaleCooldownTime);
    }

    function _ripeForSale(Covfefe storage _covfefe) internal view returns(bool) {
        return (_covfefe.saleReadyTime <= now);
    }
    /// @notice Returns all the relevant information about a specific covfefe.
    /// @param _tokenId The tokenId of the covfefe of interest.
    function getCovfefe(uint _tokenId) public view returns(string Term, string Meaning, uint Generation, uint ReadyTime, uint WinCount, uint LossCount, uint CurrentPrice, uint LastPrice, address Owner) {
        Covfefe storage covfefe = covfefes[_tokenId];
        Term = covfefe.term;
        Meaning = covfefe.meaning;
        Generation = covfefe.generation;
        ReadyTime = covfefe.saleReadyTime;
        WinCount = covfefe.winCount;
        LossCount = covfefe.lossCount;
        CurrentPrice = covfefeIndexToPrice[_tokenId];
        LastPrice = covfefeIndexToLastPrice[_tokenId];
        Owner = covfefeIndexToOwner[_tokenId];
    }

    function implementsERC721() public pure returns(bool) {
        return true;
    }
    /// @dev Required for ERC-721 compliance.
    function name() public pure returns(string) {
        return NAME;
    }
    
    /// For querying owner of token
    /// @param _tokenId The tokenID for owner inquiry
    /// @dev Required for ERC-721 compliance.
    
    function ownerOf(uint _tokenId)
    public
    view
    returns(address owner) {
        owner = covfefeIndexToOwner[_tokenId];
        require(owner != address(0));
    }
    modifier onlyOwnerOf(uint _tokenId) {
        require(msg.sender == covfefeIndexToOwner[_tokenId]);
        _;
    }
    
    ///////////////////Add Meaning /////////////////////
    
    function addMeaningToCovfefe(uint _tokenId, string _newMeaning) external payable onlyOwnerOf(_tokenId) {
        
        /// Making sure the transaction is not from another smart contract
        require(!isContract(msg.sender));
        
        /// Making sure the addMeaningFee is included
        require(msg.value == addMeaningFee);
        
        /// Add the new meaning
        covfefes[_tokenId].meaning = _newMeaning;
    
        /// Emit the term meaning added event.
        emit CovfefeMeaningAdded(_tokenId, covfefes[_tokenId].term, _newMeaning);
    }

    function payout(address _to) public onlyCovDwellers {
        _payout(_to);
    }
    /////////////////Buy Token ////////////////////
    
    // Allows someone to send ether and obtain the token
    function buyCovfefe(uint _tokenId) public payable {
        address oldOwner = covfefeIndexToOwner[_tokenId];
        address newOwner = msg.sender;
        
        // Making sure sale cooldown is not in effect
        Covfefe storage myCovfefe = covfefes[_tokenId];
        require(_ripeForSale(myCovfefe));
        
        // Making sure the transaction is not from another smart contract
        require(!isContract(msg.sender));
        
        covfefeIndexToLastPrice[_tokenId] = covfefeIndexToPrice[_tokenId];
        uint sellingPrice = covfefeIndexToPrice[_tokenId];
        
        // Making sure token owner is not sending to self
        require(oldOwner != newOwner);
        
        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));
        
        // Making sure sent amount is greater than or equal to the sellingPrice
        require(msg.value >= sellingPrice);
        uint payment = uint(SafeMath.div(SafeMath.mul(sellingPrice, 95), 100));
        uint purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
        
        // Update prices
        covfefeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 95);
        _transfer(oldOwner, newOwner, _tokenId);
        
        ///Trigger Sale cooldown
        _triggerSaleCooldown(myCovfefe);
        
        // Pay previous tokenOwner if owner is not contract
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment); //(1-0.05)
        }
        
        emit CovfefeSold(_tokenId, covfefes[_tokenId].term, covfefes[_tokenId].meaning, covfefes[_tokenId].generation, covfefeIndexToLastPrice[_tokenId], covfefeIndexToPrice[_tokenId], newOwner, oldOwner);
        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint _tokenId) public view returns(uint price) {
        return covfefeIndexToPrice[_tokenId];
    }

    function lastPriceOf(uint _tokenId) public view returns(uint price) {
        return covfefeIndexToLastPrice[_tokenId];
    }
    
    /// @dev Assigns a new address to act as the Covman. Only available to the current Covman
    /// @param _newCovman The address of the new Covman
    function setCovman(address _newCovman) public onlyCovman {
        require(_newCovman != address(0));
        covmanAddress = _newCovman;
    }
    
    /// @dev Assigns a new address to act as the Covmanager. Only available to the current Covman
    /// @param _newCovmanager The address of the new Covmanager
    function setCovmanager(address _newCovmanager) public onlyCovman {
        require(_newCovmanager != address(0));
        covmanagerAddress = _newCovmanager;
    }
    
    /// @dev Required for ERC-721 compliance.
    function symbol() public pure returns(string) {
        return SYMBOL;
    }
    
    /// @notice Allow pre-approved user to take ownership of a token
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = covfefeIndexToOwner[_tokenId];
        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));
        // Making sure transfer is approved
        require(_approved(newOwner, _tokenId));
        _transfer(oldOwner, newOwner, _tokenId);
    }
    
    ///////////////////Add Value to Covfefe/////////////////////////////
    //////////////There&#39;s no fee for adding value//////////////////////

    function addValueToCovfefe(uint _tokenId) external payable onlyOwnerOf(_tokenId) {
        
        // Making sure the transaction is not from another smart contract
        require(!isContract(msg.sender));
        
        //Making sure amount is within the min and max range
        require(msg.value >= 0.001 ether);
        require(msg.value <= 9999.000 ether);
        
        //Keeping a record of lastprice before updating price
        covfefeIndexToLastPrice[_tokenId] = covfefeIndexToPrice[_tokenId];
        
        uint newValue = msg.value;

        // Update prices
        newValue = SafeMath.div(SafeMath.mul(newValue, 115), 100);
        covfefeIndexToPrice[_tokenId] = SafeMath.add(newValue, covfefeIndexToPrice[_tokenId]);
        
        ///Emit the AddValueToCovfefe event
        emit AddedValueToCovfefe(_tokenId, covfefes[_tokenId].term, covfefes[_tokenId].meaning, covfefes[_tokenId].generation, covfefeIndexToPrice[_tokenId]);
    }
    
    /// @param _owner The owner whose covfefe tokens we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire Covfefes array looking for covfefes belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    
    function getTokensOfOwner(address _owner) external view returns(uint[] ownerTokens) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint totalCovfefes = totalSupply();
            uint resultIndex = 0;
            uint covfefeId;
            for (covfefeId = 0; covfefeId <= totalCovfefes; covfefeId++) {
                if (covfefeIndexToOwner[covfefeId] == _owner) {
                    result[resultIndex] = covfefeId;
                    resultIndex++;
                }
            }
            return result;
        }
    }
    
    /// For querying totalSupply of token
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns(uint total) {
        return covfefes.length;
    }
    /// Owner initates the transfer of the token to another account
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));
        _transfer(msg.sender, _to, _tokenId);
    }
    /// Third-party initiates transfer of token from address _from to address _to
    /// @param _from The address for the token to be transferred from.
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));
        _transfer(_from, _to, _tokenId);
    }
    /*** PRIVATE FUNCTIONS ***/
    /// Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) private pure returns(bool) {
        return _to != address(0);
    }
    /// For checking approval of transfer for address _to
    function _approved(address _to, uint _tokenId) private view returns(bool) {
        return covfefeIndexToApproved[_tokenId] == _to;
    }
    
    /////////////Covfefe Creation////////////
    
    function _createCovfefe(string _term, string _meaning, uint16 _generation, address _owner, uint _price) private {
        Covfefe memory _covfefe = Covfefe({
            term: _term,
            meaning: _meaning,
            generation: _generation,
            saleReadyTime: uint64(now),
            winCount: 0,
            lossCount: 0
        });
        
        uint newCovfefeId = covfefes.push(_covfefe) - 1;
        // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
        // let&#39;s just be 100% sure we never let this happen.
        require(newCovfefeId == uint(uint32(newCovfefeId)));
        
        //Emit the Covfefe creation event
        emit NewCovfefeCreated(newCovfefeId, _term, _meaning, _generation, _owner);
        
        covfefeIndexToPrice[newCovfefeId] = _price;
        
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(address(0), _owner, newCovfefeId);
    }
    
    /// Check for token ownership
    function _owns(address claimant, uint _tokenId) private view returns(bool) {
        return claimant == covfefeIndexToOwner[_tokenId];
    }
    
    /// For paying out balance on contract
    function _payout(address _to) private {
        if (_to == address(0)) {
            covmanAddress.transfer(address(this).balance);
        } else {
            _to.transfer(address(this).balance);
        }
    }
    
    /////////////////////Transfer//////////////////////
    /// @dev Transfer event as defined in current draft of ERC721. 
    ///  ownership is assigned, including births.
    
    /// @dev Assigns ownership of a specific Covfefe to an address.
    function _transfer(address _from, address _to, uint _tokenId) private {
        // Since the number of covfefes is capped to 2^32 we can&#39;t overflow this
        ownershipTokenCount[_to]++;
        //transfer ownership
        covfefeIndexToOwner[_tokenId] = _to;
        // When creating new covfefes _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete covfefeIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        emit CovfefeTransferred(_tokenId, _from, _to);
    }
    
    ///////////////////Covfefe Duel System//////////////////////
    
    //Simple Randomizer for the covfefe duelling system
    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(now, msg.sender, randNonce)) % _modulus;
    }
    
    function duelAnotherCovfefe(uint _tokenId, uint _targetId) external payable onlyOwnerOf(_tokenId) {
        //Load the covfefes from storage
        Covfefe storage myCovfefe = covfefes[_tokenId];
        
        // Making sure the transaction is not from another smart contract
        require(!isContract(msg.sender));
        
        //Making sure the duelling fee is included
        require(msg.value == duelFee);
        
        //
        Covfefe storage enemyCovfefe = covfefes[_targetId];
        uint rand = randMod(100);
        
        if (rand <= duelVictoryProbability) {
            myCovfefe.winCount++;
            enemyCovfefe.lossCount++;
        
        ///Emit the ChallengerWins event
            emit ChallengerWinsCovfefeDuel(_tokenId, covfefes[_tokenId].term, _targetId, covfefes[_targetId].term);
            
        } else {
        
            myCovfefe.lossCount++;
            enemyCovfefe.winCount++;
        
            ///Emit the DefenderWins event
            emit DefenderWinsCovfefeDuel(_targetId, covfefes[_targetId].term, _tokenId, covfefes[_tokenId].term);
        }
    }
    
    ////////////////// Utility //////////////////
    
    function isContract(address addr) internal view returns(bool) {
        uint size;
        assembly {
            size: = extcodesize(addr)
        }
        return size > 0;
    }
}