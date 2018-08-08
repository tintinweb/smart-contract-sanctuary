pragma solidity 0.4.24;


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Admin is Ownable {

    using SafeMath for uint256;

    struct Tier {
        uint256 amountInCenter;
        uint256 amountInOuter;
        uint256 priceInCenter;
        uint256 priceInOuter;
        uint256 soldInCenter;
        uint256 soldInOuter;
        bool filledInCenter;
        bool filledInOuter;
    }

    Tier[] public tiers;

    bool public halted;
    uint256 public logoPrice = 0;
    uint256 public logoId;
    address public platformWallet;

    uint256 public feeForFirstArtWorkChangeRequest = 0 ether;
    uint256 public feeForArtWorkChangeRequest = 0.2 ether;
    uint256 public minResalePercentage = 15;

    mapping(address => bool) public globalAdmins;
    mapping(address => bool) public admins;
    mapping(address => bool) public signers;

    event Halted(bool _halted);

    modifier onlyAdmin() {
        require(true == admins[msg.sender] || true == globalAdmins[msg.sender]);
        _;
    }

    modifier onlyGlobalAdmin() {
        require(true == globalAdmins[msg.sender]);
        _;
    }

    modifier notHalted() {
        require(halted == false);
        _;
    }

    function addGlobalAdmin(address _address) public onlyOwner() {
        globalAdmins[_address] = true;
    }

    function removeGlobalAdmin(address _address) public onlyOwner() {
        globalAdmins[_address] = false;
    }

    function addAdmin(address _address) public onlyGlobalAdmin() {
        admins[_address] = true;
    }

    function removeAdmin(address _address) public onlyGlobalAdmin() {
        admins[_address] = true;
    }

    function setSigner(address _address, bool status) public onlyGlobalAdmin() {
        signers[_address] = status;
    }

    function setLogoPrice(uint256 _price) public onlyGlobalAdmin() {
        logoPrice = _price;
    }

    function setFeeForFirstArtWorkChangeRequest(uint256 _fee) public onlyGlobalAdmin() {
        feeForFirstArtWorkChangeRequest = _fee;
    }

    function setFeeForArtWorkChangeRequest(uint256 _fee) public onlyGlobalAdmin() {
        feeForArtWorkChangeRequest = _fee;
    }

    /// @notice global Admin update tier data
    function setTierData(
        uint256 _index,
        uint256 _priceInCenter,
        uint256 _priceInOuter) public onlyGlobalAdmin() {
        Tier memory tier = tiers[_index];
        tier.priceInCenter = _priceInCenter;
        tier.priceInOuter = _priceInOuter;
        tiers[_index] = tier;
    }

    function setMinResalePercentage(uint256 _minResalePercentage) public onlyGlobalAdmin() {
        minResalePercentage = _minResalePercentage;
    }

    function isAdmin(address _address) public view returns (bool isAdmin_) {
        return (true == admins[_address] || true == globalAdmins[_address]);
    }

    function setHalted(bool _halted) public onlyGlobalAdmin {
        halted = _halted;

        emit Halted(_halted);
    }

    function verify(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = &#39;\x19Ethereum Signed Message:\n32&#39;;

        return ecrecover(keccak256(abi.encodePacked(prefix, _hash)), _v, _r, _s);
    }

    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function setPlatformWallet(address _addresss) public onlyGlobalAdmin() {
        platformWallet = _addresss;
    }
}

contract BigIoAdSpace is Ownable {
    using SafeMath for uint256;

    /// @notice Token
    struct Token {
        uint256 id;
        uint256 x; // position X on map
        uint256 y; // position Y on map
        uint256 sizeA;
        uint256 sizeB;
        uint256 soldPrice; // price that user paid to buy token
        uint256 actualPrice;
        uint256 timesSold; // how many times token was sold
        uint256 timesUpdated; // how many times artwork has been changed by current owner
        uint256 soldAt; // when token was sold
        uint256 inner;
        uint256 outer;
        uint256 soldNearby;
    }

    struct MetaData {
        string meta;
    }

    struct InnerScope {
        uint256 x1; // left top
        uint256 y1;
        uint256 x2; // right top
        uint256 y2;
        uint256 x3; // left bottom
        uint256 y3;
        uint256 x4; // right bottom
        uint256 y4;
    }

    InnerScope public innerScope;

    /// @notice mapping for token URIs
    mapping(uint256 => MetaData) public metadata;

    /// @notice Mapping from token ID to owner
    mapping(uint256 => address) public tokenOwner;

    mapping(uint256 => mapping(uint256 => bool)) public neighbours;
    mapping(uint256 => uint256[]) public neighboursArea;

    /// @notice Here different from base class we store the token not an id
    /// Array with all token, used for enumeration
    Token[] public allMinedTokens;

    /// @notice Mapping from token id to position in the allMinedTokens array
    mapping(uint256 => uint256) public allTokensIndex;

    // store sold units and not-sold but generated units
//    mapping(uint256 => mapping(uint256 => bool)) public soldUnits;
    mapping(uint256 => mapping(uint256 => uint256)) public soldUnits;

    address public platform;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event TokenPriceIncreased(uint256 _tokenId, uint256 _newPrice, uint256 _boughtTokenId, uint256 time);

    constructor () public {
        innerScope = InnerScope(
            12, 11, // left top
            67, 11, // right top
            12, 34, // left bottom
            67, 34
        );
    }

    modifier onlyPlatform() {
        require(msg.sender == platform);
        _;
    }

    modifier exists(uint256 _tokenId) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        _;
    }

    function setPlatform(address _platform) public onlyOwner() {
        platform = _platform;
    }

    function totalSupply() public view returns (uint256) {
        return allMinedTokens.length;
    }

    /// @notice Check whether token is minted
    function tokenExists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    /// @notice Check whether exist Unit with same x any y coordinates
    /// and it was sold already
    /// in order to prevent over writing
    function unitExists(uint x, uint y) public view returns (bool) {
        return (soldUnits[x][y] != 0);
    }

    function getOwner(uint256 _tokenId) public view returns (address) {
        return tokenOwner[_tokenId];
    }

    /// @return token metadata
    function getMetadata(uint256 _tokenId) public exists(_tokenId) view returns (string) {
        return metadata[_tokenId].meta;
    }

    /// @notice update metadata for token
    function setTokenMetadata(uint256 _tokenId, string meta) public  onlyPlatform exists(_tokenId) {
        metadata[_tokenId] = MetaData(meta);
    }

    function increaseUpdateMetadataCounter(uint256 _tokenId) public onlyPlatform {
        allMinedTokens[allTokensIndex[_tokenId]].timesUpdated = allMinedTokens[allTokensIndex[_tokenId]].timesUpdated.add(1);
    }

    /// @notice remove metadata for token
    function removeTokenMetadata(uint256 _tokenId) public onlyPlatform exists(_tokenId) {
        delete metadata[_tokenId];
    }

    // @return return the current price
    function getCurrentPriceForToken(uint256 _tokenId) public exists(_tokenId) view returns (uint256) {
        return allMinedTokens[allTokensIndex[_tokenId]].actualPrice;
    }

    /// @return tokenId, x, y, sizeA, sizeB, price, inner, outer
    function getTokenData(uint256 _tokenId) public exists(_tokenId) view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        Token memory token = allMinedTokens[allTokensIndex[_tokenId]];
        return (_tokenId, token.x, token.y, token.sizeA, token.sizeB, token.actualPrice, token.soldPrice, token.inner, token.outer);
    }

    function getTokenSoldPrice(uint256 _tokenId) public exists(_tokenId) view returns (uint256) {
        Token memory token = allMinedTokens[allTokensIndex[_tokenId]];
        return token.soldPrice;
    }

    function getTokenUpdatedCounter(uint256 _tokenId) public exists(_tokenId) view returns (uint256) {
        return allMinedTokens[allTokensIndex[_tokenId]].timesUpdated;
    }

    // @return return token sizes
    function getTokenSizes(uint256 _tokenId) public exists(_tokenId) view returns (uint256, uint256) {
        Token memory token = allMinedTokens[allTokensIndex[_tokenId]];
        return (token.sizeA, token.sizeB);
    }

    // @return return token scopes
    function getTokenScope(uint256 _tokenId) public exists(_tokenId) view returns (bool, bool) {
        Token memory token = allMinedTokens[allTokensIndex[_tokenId]];
        return (token.inner > 0, token.outer > 0);
    }

    // @return return token scope counters
    function getTokenCounters(uint256 _tokenId) public exists(_tokenId) view returns (uint256, uint256, uint256, uint256) {
        Token memory token = allMinedTokens[allTokensIndex[_tokenId]];
        return (token.inner, token.outer, token.timesSold, token.soldNearby);
    }

    /// @notice Mint new token, not sell new token
    /// BE sends: owner, x coordinate, y coordinate, price
    /// @param to new owner
    /// @param x coordinate
    /// @param y coordinate
    /// @param totalPrice calculated price for all units + % for siblings
    function mint(
        address to,
        uint x,
        uint y,
        uint sizeA,
        uint sizeB,
        uint256 totalPrice,
        uint256 actualPrice
    ) public onlyPlatform() returns (uint256) {

        // 1.
        require(to != address(0));
        require(sizeA.mul(sizeB) <= 100);

        // 2. check area
        uint256 inner;
        uint256 total;

        (total, inner) = calculateCounters(x, y, sizeA, sizeB);

        // we avoid zero because we later compare against zero
        uint256 tokenId = (allMinedTokens.length).add(1);

        // @TODO: ACHTUNG - soldAt equals 0 during minting
        Token memory minted = Token(tokenId, x, y, sizeA, sizeB, totalPrice, actualPrice, 0, 0, 0, inner, total.sub(inner), 0);

        // 3. copy units and create siblings
        copyToAllUnits(x, y, sizeA, sizeB, tokenId);

        // 4. update state
        updateInternalState(minted, to);

        return tokenId;
    }

    function updateTokensState(uint256 _tokenId, uint256 newPrice) public onlyPlatform exists(_tokenId) {
        uint256 index = allTokensIndex[_tokenId];
        allMinedTokens[index].timesSold += 1;
        allMinedTokens[index].timesUpdated = 0;
        allMinedTokens[index].soldNearby = 0;
        allMinedTokens[index].soldPrice = newPrice;
        allMinedTokens[index].actualPrice = newPrice;
        allMinedTokens[index].soldAt = now;
    }

    function updateOwner(uint256 _tokenId, address newOwner, address prevOwner) public onlyPlatform exists(_tokenId) {
        require(newOwner != address(0));
        require(prevOwner != address(0));
        require(prevOwner == tokenOwner[_tokenId]);

        // update data for new owner
        tokenOwner[_tokenId] = newOwner;
    }

    function inInnerScope(uint256 x, uint256 y) public view returns (bool) {
        // x should be between left top and right top corner
        // y should be between left top and left bottom corner
        if ((x >= innerScope.x1) && (x <= innerScope.x2) && (y >= innerScope.y1) && (y <= innerScope.y3)) {
            return true;
        }

        return false;
    }

    function calculateCounters(uint256 x, uint256 y, uint256 sizeA, uint256 sizeB) public view returns (uint256 total, uint256 inner) {
        uint256 upX = x.add(sizeA);
        uint256 upY = y.add(sizeB);

        // check for boundaries
        require(x >= 1);
        require(y >= 1);
        require(upX <= 79);
        require(upY <= 45);
        require(sizeA > 0);
        require(sizeB > 0);

        uint256 i;
        uint256 j;

        for (i = x; i < upX; i++) {
            for (j = y; j < upY; j++) {
                require(soldUnits[i][j] == 0);

                if (inInnerScope(i, j)) {
                    inner = inner.add(1);
                }

                total = total.add(1);
            }
        }
    }

    function increasePriceForNeighbours(uint256 tokenId) public onlyPlatform {

        Token memory token = allMinedTokens[allTokensIndex[tokenId]];

        uint256 upX = token.x.add(token.sizeA);
        uint256 upY = token.y.add(token.sizeB);

        uint256 i;
        uint256 j;
        uint256 k;
        uint256 _tokenId;


        if (neighboursArea[tokenId].length == 0) {

            for (i = token.x; i < upX; i++) {
                // check neighbors on top of area
                _tokenId = soldUnits[i][token.y - 1];

                if (_tokenId != 0) {
                    if (!neighbours[tokenId][_tokenId]) {
                        neighbours[tokenId][_tokenId] = true;
                        neighboursArea[tokenId].push(_tokenId);
                    }
                    if (!neighbours[_tokenId][tokenId]) {
                        neighbours[_tokenId][tokenId] = true;
                        neighboursArea[_tokenId].push(tokenId);
                    }
                }

                // check neighbors on bottom of area
                _tokenId = soldUnits[i][upY];
                if (_tokenId != 0) {
                    if (!neighbours[tokenId][_tokenId]) {
                        neighbours[tokenId][_tokenId] = true;
                        neighboursArea[tokenId].push(_tokenId);
                    }
                    if (!neighbours[_tokenId][tokenId]) {
                        neighbours[_tokenId][tokenId] = true;
                        neighboursArea[_tokenId].push(tokenId);
                    }
                }
            }

            for (j = token.y; j < upY; j++) {
                // check neighbors on left of area of area
                _tokenId = soldUnits[token.x - 1][j];
                if (_tokenId != 0) {
                    if (!neighbours[tokenId][_tokenId]) {
                        neighbours[tokenId][_tokenId] = true;
                        neighboursArea[tokenId].push(_tokenId);
                    }
                    if (!neighbours[_tokenId][tokenId]) {
                        neighbours[_tokenId][tokenId] = true;
                        neighboursArea[_tokenId].push(tokenId);
                    }
                }

                // check neighbors on right of area of area
                _tokenId = soldUnits[upX][j];
                if (_tokenId != 0) {
                    if (!neighbours[tokenId][_tokenId]) {
                        neighbours[tokenId][_tokenId] = true;
                        neighboursArea[tokenId].push(_tokenId);
                    }
                    if (!neighbours[_tokenId][tokenId]) {
                        neighbours[_tokenId][tokenId] = true;
                        neighboursArea[_tokenId].push(tokenId);
                    }
                }
            }
        }

        // increase price
        for (k = 0; k < neighboursArea[tokenId].length; k++) {
            Token storage _token = allMinedTokens[allTokensIndex[neighboursArea[tokenId][k]]];
            _token.soldNearby = _token.soldNearby.add(1);
            _token.actualPrice = _token.actualPrice.add((_token.actualPrice.div(100)));
            emit TokenPriceIncreased(_token.id, _token.actualPrice, _tokenId, now);
        }
    }

    // move generated Units to sold array
    // generate siblings and put it there
    function copyToAllUnits(uint256 x, uint256 y, uint256 width, uint256 height, uint256 tokenId) internal {
        uint256 upX = x + width; // 5
        uint256 upY = y + height; // 3

        uint256 i; // 1
        uint256 j; // 1

        for (i = x; i < upX; i++) {
            for (j = y; j < upY; j++) {
                soldUnits[i][j] = tokenId;
            }
        }
    }

    function updateInternalState(Token minted, address _to) internal {
        uint256 lengthT = allMinedTokens.length;
        allMinedTokens.push(minted);
        allTokensIndex[minted.id] = lengthT;
        tokenOwner[minted.id] = _to;
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BigIOERC20token is StandardToken, Ownable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public maxSupply;

    bool public allowedMinting;

    mapping(address => bool) public mintingAgents;
    mapping(address => bool) public stateChangeAgents;

    event MintERC20(address indexed _holder, uint256 _tokens);
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    modifier onlyMintingAgents () {
        require(mintingAgents[msg.sender]);
        _;
    }

    constructor (string _name, string _symbol, uint8 _decimals, uint256 _maxSupply) public StandardToken() {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        maxSupply = _maxSupply;

        allowedMinting = true;

        mintingAgents[msg.sender] = true;
    }

    /// @notice update minting agent
    function updateMintingAgent(address _agent, bool _status) public onlyOwner {
        mintingAgents[_agent] = _status;
    }

    /// @notice allow to mint tokens
    function mint(address _holder, uint256 _tokens) public onlyMintingAgents() {
        require(allowedMinting == true && totalSupply_.add(_tokens) <= maxSupply);

        totalSupply_ = totalSupply_.add(_tokens);

        balances[_holder] = balanceOf(_holder).add(_tokens);

        if (totalSupply_ == maxSupply) {
            allowedMinting = false;
        }
        emit MintERC20(_holder, _tokens);
        emit Transfer(0x0, _holder, _tokens);
    }

}

contract PricingStrategy {
    using SafeMath for uint256;

    function calculateMinPriceForNextRound(uint256 _tokenPrice, uint256 _minResalePercentage) public pure returns (uint256) {
        return _tokenPrice.add(_tokenPrice.div(100).mul(_minResalePercentage));
    }

    function calculateSharesInTheRevenue(uint256 _prevTokenPrice, uint256 _newTokenPrice) public pure returns (uint256, uint256) {
        uint256 revenue = _newTokenPrice.sub(_prevTokenPrice);
        uint256 platformShare = revenue.mul(40).div(100);
        uint256 forPrevOwner = revenue.sub(platformShare);
        return (platformShare, forPrevOwner);
    }
}
/// @title Platform
/// @author Applicature
/// @notice It is front contract which is used to sell, re-sell tokens and initiate paying dividends
contract Platform is Admin {

    using SafeMath for uint256;

    struct Offer {
        uint256 tokenId;
        uint256 offerId;
        address from;
        uint256 offeredPrice;
        uint256 tokenPrice;
        bool accepted;
        uint256 timestamp;
    }

    struct ArtWorkChangeRequest {
        address fromUser;
        uint256 tokenId;
        uint256 changeId;
        string meta;
        uint256 timestamp;
        bool isReviewed;
    }

    BigIoAdSpace public token;
    BigIOERC20token public erc20token;

    PricingStrategy public pricingStrategy;
    ArtWorkChangeRequest[] public artWorkChangeRequests;

    bool public isLogoInitied;

    uint256 public logoX = 35;
    uint256 public logoY = 18;

    Offer[] public offers;

    mapping(address => uint256) public pendingReturns;

    event Minted(address indexed _owner, uint256 _tokenId, uint256 _x, uint256 _y, uint256 _sizeA, uint256 _sizeB, uint256 _price, uint256 _platformTransfer, uint256 _timestamp);

    event Purchased(address indexed _from, address indexed _to, uint256 _tokenId, uint256 _price, uint256 _prevPrice, uint256 _prevOwnerTransfer, uint256 _platformTransfer, uint256 _timestamp);

    event OfferMade(address indexed _fromUser, uint256 _tokenId, uint256 _offerId, uint256 _offeredPrice, uint256 _timestamp);

    event OfferApproved(address indexed _owner, uint256 _tokenId, uint256 _offerId, uint256 _offeredPrice, uint256 _timestamp);

    event OfferDeclined(address indexed _fromUser, uint256 _tokenId, uint256 _offerId, uint256 _offeredPrice, uint256 _timestamp);

    event ArtWorkChangeRequestMade(
        address indexed _fromUser,
        uint256 _tokenId,
        uint256 _changeId,
        string _meta,
        uint256 _platformTransfer,
        uint256 _timestamp);

    event ArtWorkChangeRequestApproved(
        address indexed _fromUser,
        uint256 _tokenId,
        uint256 _changeId,
        string _meta,
        uint256 _timestamp);

    event ArtWorkChangeRequestDeclined(
        address indexed _fromUser,
        uint256 _tokenId,
        uint256 _changeId,
        string _meta,
        uint256 _timestamp);

    event RemovedMetaData(uint256 _tokenId, address _admin, string _meta, uint256 _timestamp);
    event ChangedOwnership(uint256 _tokenId, address _prevOwner, address _newOwner, uint256 _timestamp);

    constructor(
        address _platformWallet, // owner collects money
        address _token,
        address _erc20token,
        address _pricingStrategy,
        address _signer
    ) public {

        token = BigIoAdSpace(_token);
        erc20token = BigIOERC20token(_erc20token);

        platformWallet = _platformWallet;

        pricingStrategy = PricingStrategy(_pricingStrategy);

        signers[_signer] = true;

        // 30%
        tiers.push(
            Tier(
                400, // amountInCenter
                600, // amountInOuter
                1 ether, // priceInCenter
                0.4 ether, // priceInOuter
                0, // soldInCenter
                0, // soldInOuter
                false, // filledInCenter
                false // filledInOuter
            )
        );
        // 30%
        tiers.push(
            Tier(
                400, 600, 1.2 ether, 0.6 ether, 0, 0, false, false
            )
        );
        // 30%
        tiers.push(
            Tier(
                400, 600, 1.4 ether, 0.8 ether, 0, 0, false, false
            )
        );
        // 10%
        tiers.push(
            Tier(
                144, 288, 1.6 ether, 1.0 ether, 0, 0, false, false
            )
        );
    }

    /// @notice init logo, call it as soon as possible
    /// call it after setting platform in the token
    /// Logo is BigIOToken which has 10*10 size and position in the center of map
    function initLogo() public onlyOwner {
        require(isLogoInitied == false);

        isLogoInitied = true;

        logoId = token.mint(platformWallet, logoX, logoY, 10, 10, 0 ether, 0 ether);

        token.setTokenMetadata(logoId, "");

        updateTierStatus(100, 0);

        emit Minted(msg.sender, logoId, logoX, logoY, 10, 10, 0 ether, 0 ether, now);
    }

    function getPriceFor(uint256 x, uint256 y, uint256 sizeA, uint256 sizeB) public view returns(uint256 totalPrice, uint256 inner, uint256 outer) {
        (inner, outer) = preMinting(x, y, sizeA, sizeB);

        totalPrice = calculateTokenPrice(inner, outer);

        return (totalPrice, inner, outer);
    }

    /// @notice sell new tokens during the round 0
    /// all except logo
    function buy(
        uint256 x, // top left coordinates
        uint256 y, // top left coordinates
        uint256 sizeA, // size/width of a square
        uint256 sizeB, // size/height of a square,
        uint8 _v,  // component of signature
        bytes32 _r, // component of signature
        bytes32 _s // component of signature
    ) public notHalted() payable {
        address recoveredSigner = verify(keccak256(msg.sender), _v, _r, _s);

        require(signers[recoveredSigner] == true);
        require(msg.value > 0);

        internalBuy(x, y, sizeA, sizeB);
    }

    function internalBuy(
        uint256 x, // top left coordinates
        uint256 y, // top left coordinates
        uint256 sizeA, // size/width of a square
        uint256 sizeB // size/height of a square,
    ) internal {
        // get and validate current tier
        uint256 inner = 0;
        uint256 outer = 0;
        uint256 totalPrice = 0;

        (inner, outer) = preMinting(x, y, sizeA, sizeB);
        totalPrice = calculateTokenPrice(inner, outer);

        require(totalPrice <= msg.value);

        //         try to mint and update current tier
        updateTierStatus(inner, outer);

        uint256 actualPrice = inner.mul(tiers[3].priceInCenter).add(outer.mul(tiers[3].priceInOuter));

        if (msg.value > actualPrice) {
            actualPrice = msg.value;
        }

        uint256 tokenId = token.mint(msg.sender, x, y, sizeA, sizeB, msg.value, actualPrice);
        erc20token.mint(msg.sender, inner.add(outer));

        transferEthers(platformWallet, msg.value);

        emit Minted(msg.sender, tokenId, x, y, sizeA, sizeB, msg.value, msg.value, now);
    }

    /// @notice allow user to make an offer after initial phase(re-sale)
    /// any offer minResalePercentage is accepted automatically
    function makeOffer(
        uint256 _tokenId,
        uint8 _v,  // component of signature
        bytes32 _r, // component of signature
        bytes32 _s // component of signature
    ) public notHalted() payable {

        address recoveredSigner = verify(keccak256(msg.sender), _v, _r, _s);

        require(signers[recoveredSigner] == true);

        require(msg.sender != address(0));
        require(msg.value > 0);

        uint256 currentPrice = getTokenPrice(_tokenId);
        require(currentPrice > 0);

        // special case for first sell of logo
        if (_tokenId == logoId && token.getCurrentPriceForToken(_tokenId) == 0) {
            require(msg.value >= logoPrice);

            //update token&#39;s state
            token.updateTokensState(logoId, msg.value);

            // mint erc20 tokens
            erc20token.mint(msg.sender, 100);

            transferEthers(platformWallet, msg.value);

            emit Purchased(0, msg.sender, _tokenId, msg.value, 0, 0, msg.value, now);

            return;
        }

        uint256 minPrice = pricingStrategy.calculateMinPriceForNextRound(currentPrice, minResalePercentage);

        require(msg.value >= minPrice);

        uint256 offerCounter = offers.length;

        offers.push(Offer(_tokenId, offerCounter, msg.sender, msg.value, currentPrice, false, now));
        emit OfferMade(msg.sender, _tokenId, offerCounter, msg.value, now);

        // 2. check condition for approve and do it
        approve(offerCounter, _tokenId);
    }

    function getTokenPrice(uint256 _tokenId) public view returns (uint256 price) {

        uint256 actualPrice = token.getCurrentPriceForToken(_tokenId);

        // special case for first sell of logo
        if (_tokenId == logoId && actualPrice == 0) {
            require(logoPrice > 0);

            return logoPrice;
        } else {
            uint256 indexInner = 0;
            uint256 indexOuter = 0;

            bool hasInner;
            bool hasOuter;

            (hasInner, hasOuter) = token.getTokenScope(_tokenId);
            (indexInner, indexOuter) = getCurrentTierIndex();

            if (_tokenId != logoId && hasInner) {
                require(indexInner == 100000);
            }

            if (hasOuter) {
                require(indexOuter == 100000);
            }

            return actualPrice;
        }
    }

    function getArtWorkChangeFee(uint256 _tokenId) public view returns (uint256 fee) {

        uint256 counter = token.getTokenUpdatedCounter(_tokenId);

        if (counter > 0) {
            return feeForArtWorkChangeRequest;
        }

        return feeForFirstArtWorkChangeRequest;
    }

    /// @notice it allows token owner to create art work change request
    /// first user upload 2 images
    /// then do call this function
    /// admin can reject or approve it
    function artWorkChangeRequest(uint256 _tokenId, string _meta, uint8 _v, bytes32 _r, bytes32 _s)
        public payable returns (uint256)
    {

        address recoveredSigner = verify(keccak256(_meta), _v, _r, _s);

        require(signers[recoveredSigner] == true);

        require(msg.sender == token.getOwner(_tokenId));

        uint256 fee = getArtWorkChangeFee(_tokenId);

        require(msg.value >= fee);

        uint256 changeRequestCounter = artWorkChangeRequests.length;

        artWorkChangeRequests.push(
            ArtWorkChangeRequest(msg.sender, _tokenId, changeRequestCounter, _meta, now, false)
        );

        token.increaseUpdateMetadataCounter(_tokenId);

        transferEthers(platformWallet, msg.value);

        emit ArtWorkChangeRequestMade(msg.sender, _tokenId, changeRequestCounter, _meta, msg.value, now);

        return changeRequestCounter;
    }

    function artWorkChangeApprove(uint256 _index, uint256 _tokenId, bool approve) public onlyAdmin {
        ArtWorkChangeRequest storage request = artWorkChangeRequests[_index];
        require(false == request.isReviewed);

        require(_tokenId == request.tokenId);
        request.isReviewed = true;
        if (approve) {
            token.setTokenMetadata(_tokenId, request.meta);
            emit ArtWorkChangeRequestApproved(
                request.fromUser,
                request.tokenId,
                request.changeId,
                request.meta,
                now
            );
        } else {
            emit ArtWorkChangeRequestDeclined(
                request.fromUser,
                request.tokenId,
                request.changeId,
                request.meta,
                now
            );
        }
    }

    function artWorkChangeByAdmin(uint256 _tokenId, string _meta, uint256 _changeId) public onlyAdmin {
        token.setTokenMetadata(_tokenId, _meta);
        emit ArtWorkChangeRequestApproved(
            msg.sender,
            _tokenId,
            _changeId,
            _meta,
            now
        );
    }

    function changeTokenOwnerByAdmin(uint256 _tokenId, address _newOwner) public onlyAdmin {
        address prevOwner = token.getOwner(_tokenId);
        token.updateOwner(_tokenId, _newOwner, prevOwner);
        emit ChangedOwnership(_tokenId, prevOwner, _newOwner, now);
        string memory meta = token.getMetadata(_tokenId);
        token.removeTokenMetadata(_tokenId);
        emit RemovedMetaData(_tokenId, msg.sender, meta, now);
    }

    /// @return tokenId, x, y, sizeA, sizeB, price
    function getTokenData(uint256 _tokenId) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return token.getTokenData(_tokenId);
    }

    function getMetaData(uint256 _tokenId) public view returns(string) {
        return token.getMetadata(_tokenId);
    }

    /// @notice Withdraw a bid that was overbid and platform owner share
    function claim() public returns (bool) {
        return claimInternal(msg.sender);
    }

    /// @notice Withdraw (for cold storage wallet) a bid that was overbid and platform owner share
    function claimByAddress(address _address) public returns (bool) {
        return claimInternal(_address);
    }

    function claimInternal(address _address) internal returns (bool) {
        require(_address != address(0));

        uint256 amount = pendingReturns[_address];

        if (amount == 0) {
            return;
        }

        pendingReturns[_address] = 0;

        _address.transfer(amount);

        return true;
    }

    /// @return index of current tiers, if 100000(cannot use -1) then round 0  finished
    /// and we need to move to re-sale
    function getCurrentTierIndex() public view returns (uint256, uint256) {
        // cannot use -1
        // so use not possible value for tiers.length
        uint256 indexInner = 100000;
        uint256 indexOuter = 100000;

        for (uint256 i = 0; i < tiers.length; i++) {
            if (!tiers[i].filledInCenter) {
                indexInner = i;
                break;
            }
        }

        for (uint256 k = 0; k < tiers.length; k++) {
            if (!tiers[k].filledInOuter) {
                indexOuter = k;
                break;
            }
        }

        return (indexInner, indexOuter);
    }

    /// @return current tier stats
    /// index of current tiers, if 100000(cannot use -1) then initial sale is  finished
    /// works only during the initial phase
    function getCurrentTierStats() public view returns (uint256 indexInner, uint256 indexOuter, uint256 availableInner, uint256 availableInOuter, uint256 priceInCenter, uint256 priceInOuter, uint256 nextPriceInCenter, uint256 nextPriceInOuter) {

        indexInner = 100000;
        indexOuter = 100000;

        for (uint256 i = 0; i < tiers.length; i++) {
            if (!tiers[i].filledInCenter) {
                indexInner = i;
                break;
            }
        }

        for (uint256 k = 0; k < tiers.length; k++) {
            if (!tiers[k].filledInOuter) {
                indexOuter = k;
                break;
            }
        }

        Tier storage tier;

        if (indexInner != 100000) {
            tier = tiers[indexInner];

            availableInner = tier.amountInCenter.sub(tier.soldInCenter);

            priceInCenter = tier.priceInCenter;

            if (indexInner < 3) {
                nextPriceInCenter = tiers[indexInner + 1].priceInCenter;
            }
        }

        if (indexOuter != 100000) {
            tier = tiers[indexOuter];

            availableInOuter = tier.amountInOuter.sub(tier.soldInOuter);

            priceInOuter = tier.priceInOuter;

            if (indexOuter < 3) {
                nextPriceInOuter = tiers[indexOuter + 1].priceInOuter;
            }
        }
    }

    function calculateAmountOfUnits(uint256 sizeA, uint256 sizeB) public pure returns (uint256) {
        return sizeA.mul(sizeB);
    }

    /// @notice approve the offer
    function approve(uint256 _index, uint256 _tokenId) internal {
        Offer memory localOffer = offers[_index];

        address newOwner = localOffer.from;
        address prevOwner = token.getOwner(_tokenId);

        uint256 platformShare;
        uint256 forPrevOwner;

        uint256 soldPrice = token.getTokenSoldPrice(_tokenId);

        (platformShare, forPrevOwner) = pricingStrategy.calculateSharesInTheRevenue(
            soldPrice, localOffer.offeredPrice);

        //update token&#39;s state
        token.updateTokensState(_tokenId, localOffer.offeredPrice);

        // update owner
        token.updateOwner(_tokenId, newOwner, prevOwner);
        localOffer.accepted = true;

        transferEthers(platformWallet, platformShare);
        transferEthers(prevOwner, forPrevOwner.add(soldPrice));

        emit OfferApproved(newOwner, _tokenId, localOffer.offerId, localOffer.offeredPrice, now);
        emit Purchased(prevOwner, newOwner, _tokenId, localOffer.offeredPrice, soldPrice, forPrevOwner.add(soldPrice), platformShare, now);

        afterApproveAction(_tokenId);
    }

    function transferEthers(address _address, uint256 _wei) internal {
        if (isContract(_address)) {
            pendingReturns[_address] = pendingReturns[_address].add(_wei);
        }
        else {
            _address.transfer(_wei);
        }
    }

    function preMinting(uint256 x, uint256 y, uint256 sizeA, uint256 sizeB) internal view returns (uint256, uint256) {
        //  calculate units for token
        uint256 total = 0;
        uint256 inner = 0;
        uint256 outer = 0;


        (total, inner) = token.calculateCounters(x, y, sizeA, sizeB);
        outer = total.sub(inner);

        require(total <= 100);

        return (inner, outer);
    }

    function updateTierStatus(uint256 inner, uint256 outer) internal {
        uint256 leftInner = inner;
        uint256 leftOuter = outer;

        for (uint256 i = 0; i < 4; i++) {
            Tier storage tier = tiers[i];

            if (leftInner > 0 && tier.filledInCenter == false) {
                uint256 availableInner = tier.amountInCenter.sub(tier.soldInCenter);

                if (availableInner > leftInner) {
                    tier.soldInCenter = tier.soldInCenter.add(leftInner);

                    leftInner = 0;
                } else {
                    tier.filledInCenter = true;
                    tier.soldInCenter = tier.amountInCenter;

                    leftInner = leftInner.sub(availableInner);
                }
            }

            if (leftOuter > 0 && tier.filledInOuter == false) {
                uint256 availableOuter = tier.amountInOuter.sub(tier.soldInOuter);

                if (availableOuter > leftOuter) {
                    tier.soldInOuter = tier.soldInOuter.add(leftOuter);

                    leftOuter = 0;
                } else {
                    tier.filledInOuter = true;
                    tier.soldInOuter = tier.amountInOuter;

                    leftOuter = leftOuter.sub(availableOuter);
                }
            }
        }

        require(leftInner == 0 && leftOuter == 0);
    }

    function calculateTokenPrice(uint256 inner, uint256 outer) public view returns (uint256 price) {
        uint256 leftInner = inner;
        uint256 leftOuter = outer;

        for (uint256 i = 0; i < 4; i++) {
            Tier storage tier = tiers[i];

            if (leftInner > 0 && tier.filledInCenter == false) {
                uint256 availableInner = tier.amountInCenter.sub(tier.soldInCenter);

                if (availableInner > leftInner) {
                    price = price.add(leftInner.mul(tier.priceInCenter));
                    leftInner = 0;
                } else {
                    price = price.add(availableInner.mul(tier.priceInCenter));
                    leftInner = leftInner.sub(availableInner);
                }
            }

            if (leftOuter > 0 && tier.filledInOuter == false) {
                uint256 availableOuter = tier.amountInOuter.sub(tier.soldInOuter);

                if (availableOuter > leftOuter) {
                    price = price.add(leftOuter.mul(tier.priceInOuter));
                    leftOuter = 0;
                } else {
                    price = price.add(availableOuter.mul(tier.priceInOuter));
                    leftOuter = leftOuter.sub(availableOuter);
                }
            }
        }

        require(leftInner == 0 && leftOuter == 0);
    }

    function minPriceForNextRound(uint256 _tokenId) public view returns (uint256) {
        if (_tokenId == logoId && token.getCurrentPriceForToken(_tokenId) == 0) {
            return logoPrice;
        } else {
            // @TODO: check if sold-out

            uint256 currentPrice = getTokenPrice(_tokenId);
            uint256 minPrice = pricingStrategy.calculateMinPriceForNextRound(currentPrice, minResalePercentage);
            return minPrice;
        }
    }

    function afterApproveAction(uint256 _tokenId) internal {

        uint256 indexInner = 100000;
        uint256 indexOuter = 100000;

        bool hasInner;
        bool hasOuter;

        (hasInner, hasOuter) = token.getTokenScope(_tokenId);
        (indexInner, indexOuter) = getCurrentTierIndex();

        if (hasInner && hasOuter && indexInner == 100000 && indexOuter == 100000) {
            token.increasePriceForNeighbours(_tokenId);
        } else if (!hasInner && hasOuter && indexOuter == 100000) {
            token.increasePriceForNeighbours(_tokenId);
        } else if (!hasOuter && hasInner && indexInner == 100000) {
            token.increasePriceForNeighbours(_tokenId);
        }
    }

    function canBuyExistentToken(uint256 _tokenId) public view returns (uint256 _allowed) {
        uint256 indexInner = 0;
        uint256 indexOuter = 0;

        bool hasInner;
        bool hasOuter;

        (hasInner, hasOuter) = token.getTokenScope(_tokenId);
        (indexInner, indexOuter) = getCurrentTierIndex();

        if (token.getCurrentPriceForToken(_tokenId) == 0 && logoPrice == 0) {
            return 4;
        }

        if (_tokenId != logoId && hasInner && indexInner != 100000) {
            return 2;
        }

        if (hasOuter && indexOuter != 100000) {
            return 3;
        }

        return 1;
    }
}