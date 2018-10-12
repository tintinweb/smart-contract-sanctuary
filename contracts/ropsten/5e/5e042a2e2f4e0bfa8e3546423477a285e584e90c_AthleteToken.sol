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
contract AthleteToken is ERC721 {
    /****  CONSTANTS ****/
    string public constant NAME = "CryptoFantasy";
    string public constant SYMBOL = "Athlete";
    uint256 public siteFee = 5;
    uint256 public sendFee = 2;

    uint256 private constant initPrice = 0.001 ether;

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
    mapping (uint256 => address) public athleteIndexToApproved;

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cooAddress;

    /** ATHLETE DATATYPE */
    struct Athlete {
        string  athleteId;
        uint256 sellPrice;
        string  creatorId;
        address creatorAddress;
    }
    Athlete[] private athletes;

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
    constructor() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }
    /*** PUBLIC FUNCTIONS */
    function approve( address _to, uint256 _tokenId ) public {
        require(_owns(msg.sender, _tokenId));
        athleteIndexToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }
    function createOfAthleteCard(string _athleteId, string _creatorId) public payable returns (uint256 _newAthleteId) {
        require( msg.sender != cooAddress && msg.sender != ceoAddress );
        require( msg.value > 0 && msg.value >= initPrice );
        
        Athlete memory _athlete = Athlete({ athleteId: _athleteId, sellPrice: msg.value, creatorId: _creatorId, creatorAddress: msg.sender });
        uint256 newAthleteId = athletes.push(_athlete) - 1;
        
        require(newAthleteId == uint256(uint32(newAthleteId)));
        emit Birth(newAthleteId, msg.sender);
        athleteIndexToOwner[newAthleteId] = msg.sender;
        
        _transfer(address(0), msg.sender, newAthleteId);
        ceoAddress.transfer(msg.value);
        
        return newAthleteId;
    }
    function changeSellPriceForAthlete( uint256 _tokenId, uint256 _newSellPrice ) public returns( string athleteId ) {
        require(ownerOf(_tokenId)==msg.sender);
        Athlete storage athlete = athletes[_tokenId];
        athlete.sellPrice = _newSellPrice;
        athleteId     = athlete.athleteId;
    } 
    function getAthlete(uint256 _tokenId) public view returns ( string athleteId, uint256 sellPrice, string creatorId, address creatorAddress) {
        Athlete storage athlete = athletes[_tokenId];
        athleteId      = athlete.athleteId;
        sellPrice      = athlete.sellPrice;
        creatorId      = athlete.creatorId;
        creatorAddress = athlete.creatorAddress;
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
        uint256 sellPrice = msg.value;
        Athlete storage athlete = athletes[_tokenId];
        address _creatorAddress = athlete.creatorAddress;

        require(sellOwner != buyOwner);
        require(_addressNotNull(buyOwner));
        require(msg.value >= sellPrice);

        uint256 _sendFee  = uint256(SafeMath.div(SafeMath.mul(sellPrice, sendFee), 100)); // calculate actual fee
        uint256 _siteFee  = uint256(SafeMath.div(SafeMath.mul(sellPrice, siteFee), 100));   // calculate site fee
        uint256 payment   = uint256(SafeMath.sub(sellPrice, SafeMath.add(_sendFee, _siteFee)));   //payment for seller

        _transfer(sellOwner, buyOwner, _tokenId);

        //Pay previous tokenOwner if owner is not contract
        if ( sellOwner != address(this) ) {
            sellOwner.transfer(payment); // (1-(actual_fee+site_fee))*sellPrice
            _creatorAddress.transfer(sendFee);
            ceoAddress.transfer(siteFee);
            athleteIndexToOwner[_tokenId] = buyOwner;
            emit TokenSold(_tokenId, sellPrice, sellOwner, buyOwner, athletes[_tokenId].athleteId);
        }
    }
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }
    function setCOO(address _newCOO) public onlyCOO {
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
    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == athleteIndexToOwner[_tokenId];
    }
    function _payout(address _to) private {
        if (_to == address(0)) {
            ceoAddress.transfer(address(this).balance);
        }
        else {
            _to.transfer(address(this).balance);
        }
    }
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        athleteIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete athleteIndexToApproved[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }
}