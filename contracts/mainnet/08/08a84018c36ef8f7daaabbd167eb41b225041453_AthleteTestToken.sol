pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>= a);
        return c;
    }
}
contract ERC721 {
    function approve( address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address addr);
    function takeOwnership(uint256 _tokenId) public;
    function totalSupply() public view returns (uint256 supply);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract AthleteTestToken is ERC721 {
    /****  CONSTANTS ****/
    string public constant NAME = "CryptoFantasy";
    string public constant SYMBOL = "Athlete";

    uint256 private constant initPrice = 0.001 ether;
    uint256 private constant PROMO_CREATION_LIMIT = 50000;

    /*** EVENTS  */
    event Birth(uint256 tokenId, address owner);
    event TokenSold(uint256 tokenId, uint256 sellPrice, address sellOwner, address buyOwner, string athleteId);
    event Transfer(address from, address to, uint256 tokenId);

    /*** STORAGE */
    // A mapping from athlete IDs to the address that owns them. All athletes have some valid owner address.
    mapping (uint256 => address) public athleteIndexToOwner;

    // A mapping from owner address to count of tokens that address owns.
    // Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) private ownershipTokenCount;

    /**
        *** A mapping from athleteIDs to an address that has been approved to call transferFrom(). 
        *** Each athlete can only have one approved address for transfer at any time.
        *** A ZERO value means no approval is outstanding.
     */
    mapping (uint256 => address) public athleteIndexToApproved;

    // A mapping from athleteIDs to the price of the token.
    mapping (uint256 => uint256) private athleteIndexToPrice;

    // A mapping from athleteIDs to the actual fee of the token.
    mapping (uint256 => uint256) private athleteIndexToActualFee;

    // A mapping from athleteIDs to the site fee of the token.
    mapping (uint256 => uint256) private athleteIndexToSiteFee;

    // A mapping from athleteIDs to the actual wallet address of the token
    mapping (uint256 => address) private athleteIndexToActualWalletId;

    // A mapping of athleteIDs
    mapping (uint256 => string) private athleteIndexToAthleteID;


    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cooAddress;

    uint256 public promoCreatedCount;

    /** ATHLETE DATATYPE */
    struct Athlete {
        string  athleteId;
        address actualAddress;
        uint256 actualFee;
        uint256 siteFee;
        uint256 sellPrice;
    }
    Athlete[] private athletes;

    mapping (uint256 => Athlete) private athleteIndexToAthlete;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }
    modifier onlyCLevel() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    /** CONSTRUCTOR */
    function AthleteTestToken() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    /*** PUBLIC FUNCTIONS */
    function approve( address _to, uint256 _tokenId ) public {
        require(_owns(msg.sender, _tokenId));
        athleteIndexToApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }


    function createPromoAthlete(address _owner, string _athleteId, address _actualAddress, uint256 _actualFee, uint256 _siteFee, uint _sellPrice) public onlyCOO {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        address athleteOwner = _owner;
        if ( athleteOwner == address(0) ) {
            athleteOwner = cooAddress;
        }
        if ( _sellPrice <= 0 ) {
            _sellPrice = initPrice;
        }
        promoCreatedCount++;

        _createOfAthlete(athleteOwner, _athleteId, _actualAddress, _actualFee, _siteFee, _sellPrice);
    }


    function createContractOfAthlete(string _athleteId, address _actualAddress, uint256 _actualFee, uint256 _siteFee, uint256 _sellPrice) public onlyCOO{
        _createOfAthlete(address(this), _athleteId, _actualAddress, _actualFee, _siteFee, _sellPrice);
    }

    function getAthlete(uint256 _tokenId) public view returns ( string athleteId, address actualAddress, uint256 actualFee, uint256 siteFee, uint256 sellPrice, address owner) {
        Athlete storage athlete = athletes[_tokenId];
        athleteId     = athlete.athleteId;
        actualAddress = athlete.actualAddress;
        actualFee     = athlete.actualFee;
        siteFee       = athlete.siteFee;
        sellPrice     = priceOf(_tokenId);
        owner         = ownerOf(_tokenId);
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }
    function name() public pure returns (string) {
        return NAME;
    }
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = athleteIndexToOwner[_tokenId];
        require(owner != address(0));
    }
    function payout(address _to) public onlyCLevel {
        _payout(_to);
    }
    function purchase(uint256 _tokenId) public payable {
        address sellOwner = athleteIndexToOwner[_tokenId];
        address buyOwner = msg.sender;

        uint256 sellPrice = priceOf(_tokenId);

        //make sure token owner is not sending to self
        require(sellOwner != buyOwner);
        //safely check to prevent against an unexpected 0x0 default
        require(_addressNotNull(buyOwner));

        //make sure sent amount is greater than or equal to the sellPrice
        require(msg.value >= sellPrice);

        uint256 actualFee = uint256(SafeMath.div(SafeMath.mul(sellPrice, athleteIndexToActualFee[_tokenId]), 100)); // calculate actual fee
        uint256 siteFee   = uint256(SafeMath.div(SafeMath.mul(sellPrice, athleteIndexToSiteFee[_tokenId]), 100));   // calculate site fee
        uint256 payment   = uint256(SafeMath.sub(sellPrice, SafeMath.add(actualFee, siteFee)));   //payment for seller

        _transfer(sellOwner, buyOwner, _tokenId);

        //Pay previous tokenOwner if owner is not contract
        if ( sellOwner != address(this) ) {
            sellOwner.transfer(payment); // (1-(actual_fee+site_fee))*sellPrice
        }

        TokenSold(_tokenId, sellPrice, sellOwner, buyOwner, athletes[_tokenId].athleteId);
        msg.sender.transfer(siteFee);

        address actualWallet = athleteIndexToActualWalletId[_tokenId];
        actualWallet.transfer(actualFee);

        ceoAddress.transfer(siteFee);

    }

    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return athleteIndexToPrice[_tokenId];
    }
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }
    function symbol() public pure returns (string) {
        return SYMBOL;
    }
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = athleteIndexToOwner[_tokenId];
        
        require(_addressNotNull(newOwner));
        require(_approved(newOwner, _tokenId));
        _transfer(oldOwner, newOwner, _tokenId);
    }

    function tokenOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if ( tokenCount == 0 ) {
            return new uint256[](0);
        }
        else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalAthletes = totalSupply();
            uint256 resultIndex = 0;
            uint256 athleteId;

            for(athleteId = 0; athleteId <= totalAthletes; athleteId++) {
                if (athleteIndexToOwner[athleteId] == _owner) {
                    result[resultIndex] = athleteId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function totalSupply() public view returns (uint256 total) {
        return athletes.length;
    }

    function transfer( address _to, uint256 _tokenId ) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom( address _from, address _to, uint256 _tokenId ) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }

    /** PRIVATE FUNCTIONS */
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return athleteIndexToApproved[_tokenId] == _to;
    }

    //TODO -----------------------------------------------------------------------------------------------------------------------------------------
    function _createOfAthlete(address _athleteOwner, string _athleteId, address _actualAddress, uint256 _actualFee, uint256 _siteFee, uint256 _sellPrice) private {
        
        Athlete memory _athlete = Athlete({ athleteId: _athleteId, actualAddress: _actualAddress, actualFee: _actualFee,  siteFee: _siteFee, sellPrice: _sellPrice });
        
        uint256 newAthleteId = athletes.push(_athlete) - 1;
 
        if ( _sellPrice <= 0 ) {
            _sellPrice = initPrice;
        }
        require(newAthleteId == uint256(uint32(newAthleteId)));
        Birth(newAthleteId, _athleteOwner);
        
        athleteIndexToPrice[newAthleteId] = _sellPrice;
        athleteIndexToActualFee[newAthleteId] = _actualFee;
        athleteIndexToSiteFee[newAthleteId] = _siteFee;
        athleteIndexToActualWalletId[newAthleteId] = _actualAddress;
        athleteIndexToAthleteID[newAthleteId] = _athleteId;
        athleteIndexToAthlete[newAthleteId] = _athlete;

        _transfer(address(0), _athleteOwner, newAthleteId);

    }

    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == athleteIndexToOwner[_tokenId];
    }
    function _payout(address _to) private {
        if (_to == address(0)) {
            ceoAddress.transfer(this.balance);
        }
        else {
            _to.transfer(this.balance);
        }
    }
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        athleteIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete athleteIndexToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

}