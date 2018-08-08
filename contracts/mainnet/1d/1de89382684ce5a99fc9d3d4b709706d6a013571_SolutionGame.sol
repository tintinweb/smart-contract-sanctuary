pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public admin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner);
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

    function setAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0));
        admin = newAdmin;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    bool public paused = true;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}

contract BrokenContract is Pausable {
    /// Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    ///@dev only for serious breaking bug
    function setNewAddress(address _v2Address) external onlyOwner whenPaused {
        //withdraw all balance when contract update
        owner.transfer(address(this).balance);

        newContractAddress = _v2Address;
    }
}


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    //event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    //function approve(address _to, uint256 _tokenId) public;
    //function getApproved(uint256 _tokenId) public view returns (address _operator);
    //function transferFrom(address _from, address _to, uint256 _tokenId) public;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is BrokenContract, ERC721Basic {
    using SafeMath for uint256;
    using AddressUtils for address;

    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

    // Mapping from token ID to approved address
    //mapping (uint256 => address) internal tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;

    /**
     * @dev Guarantees msg.sender is owner of the given token
     * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
     */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
     * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
     * @param _tokenId uint256 ID of the token to validate
     */
    /*modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }*/

    /**
     * @dev Gets the balance of the specified address
     * @param _owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param _tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Returns whether the specified token exists
     * @param _tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * @dev The zero address indicates there is no approved address.
     * @dev There can only be one approved address per token at a given time.
     * @dev Can only be called by the token owner or an approved operator.
     * @param _to address to be approved for the given token ID
     * @param _tokenId uint256 ID of the token to be approved
     */
    /*function approve(address _to, uint256 _tokenId) public whenNotPaused {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner);

        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }*/

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * @param _tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    /*function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }*/

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
    */
    /*function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }*/

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param _spender address of the spender to query
     * @param _tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *  is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner/* || getApproved(_tokenId) == _spender*/;
    }

    /**
     * @dev Internal function to mint a new token
     * @dev Reverts if the given token ID already exists
     * @param _to The address that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    /**
     * @dev Internal function to clear current approval of a given token ID
     * @dev Reverts if the given address is not indeed the owner of the token
     * @param _owner owner of the token
     * @param _tokenId uint256 ID of the token to be transferred
     */
    /*function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }*/

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }
}


/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {
    // Token name
    string internal name_;

    // Token symbol
    string internal symbol_;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;

    /**
     * @dev Constructor function
     */
    constructor(string _name, string _symbol) public {
        name_ = _name;
        symbol_ = _symbol;
    }

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() public view returns (string) {
        return name_;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() public view returns (string) {
        return symbol_;
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param _owner address owning the tokens list to be accessed
     * @param _index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * @dev Reverts if the index is greater or equal to the total number of tokens
     * @param _index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return allTokens[_index];
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

    /**
     * @dev Internal function to mint a new token
     * @dev Reverts if the given token ID already exists
     * @param _to address the beneficiary that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

}


///@dev Base game contract. Holds all common structs, events and base variables.
contract BaseGame is ERC721Token {
    /// EVENTS
    ///@dev the Created event is fired whenever create or clone new fan token
    event NewAccount(address owner, uint tokenId, uint parentTokenId, uint blockNumber);

    ///@dev the NewForecast event is fired whenever any user create new forecast for game
    event NewForecast(address owner, uint tokenId, uint forecastId, uint _gameId,
        uint _forecastData);

    /// STRUCTS
    ///@dev Token - main token struct
    struct Token {
        // create block number, for tournament round, and date
        uint createBlockNumber;

        // parent
        uint parentId;
    }

    enum Teams { DEF,
        RUS, SAU, EGY, URY,     // group A
        PRT, ESP, MAR, IRN,     // group B
        FRA, AUS, PER, DNK,     // group C
        ARG, ISL, HRV, NGA,     // D
        BRA, CHE, CRI, SRB,     // E
        DEU, MEX, SWE, KOR,     // F
        BEL, PAN, TUN, GBR,     // G
        POL, SEN, COL, JPN      // H
    }

    ///#dev game changed event
    event GameChanged(uint _gameId, uint64 gameDate, Teams teamA, Teams teamB,
        uint goalA, uint goalB, bool odds, uint shotA, uint shotB);


    ///@dev Game info with result, index = official game id
    struct Game {
        // timestamp game date
        uint64 gameDate;

        // id teamA and teamB
        Teams teamA;
        Teams teamB;

        // count of total goal
        uint goalA;
        uint goalB;

        // game overweight / true - A / false - B
        bool odds;

        // total blows on target
        uint shotA;
        uint shotB;

        // list of ID forecast&#39;s
        uint[] forecasts;
    }

    ///@dev Forecast - fan forecast to game
    struct Forecast {
        // bits forecast for game from fan
        uint gameId;
        uint forecastBlockNumber;

        uint forecastData;
    }

    /// STORAGE
    ///@dev array of token fans
    Token[] tokens;

    ///@dev array of game from, 0 - invalid, index - official ID of game
    // http://welcome2018.com/matches/#
    //Game[65] games;
    mapping (uint => Game) games;

    ///@dev array of forecast for game from fans
    Forecast[] forecasts;

    ///@dev forecast -> token
    mapping (uint => uint) internal forecastToToken;

    ///@dev token -> forecast&#39;s
    mapping (uint => uint[]) internal tokenForecasts;

    /**
    * @dev Constructor function
    */
    constructor(string _name, string _symbol) ERC721Token(_name, _symbol) public {}

    /// METHOD&#39;s
    ///@dev create new token
    function _createToken(uint _parentId, address _owner) internal whenNotPaused
    returns (uint) {
        Token memory _token = Token({
            createBlockNumber: block.number,
            parentId: _parentId
            });
        uint newTokenId = tokens.push(_token) - 1;

        emit NewAccount(_owner, newTokenId, uint(_token.parentId), uint(_token.createBlockNumber));
        _mint(_owner, newTokenId);
        return newTokenId;
    }

    ///@dev Create new forecast
    function _createForecast(uint _tokenId, uint _gameId, uint _forecastData) internal whenNotPaused returns (uint) {
        require(_tokenId < tokens.length);

        Forecast memory newForecast = Forecast({
            gameId: _gameId,
            forecastBlockNumber: block.number,
            forecastData: _forecastData
            });

        uint newForecastId = forecasts.push(newForecast) - 1;

        forecastToToken[newForecastId] = _tokenId;
        tokenForecasts[_tokenId].push(newForecastId);
        games[_gameId].forecasts.push(newForecastId);

        //fire forecast!
        emit NewForecast(tokenOwner[_tokenId], _tokenId, newForecastId, _gameId, _forecastData);
        return newForecastId;
    }    
}


contract BaseGameLogic is BaseGame {

    ///@dev prize fund count
    uint public prizeFund = 0;
    ///@dev payment for create new Token
    uint public basePrice = 21 finney;
    ///@dev cut game on each clone operation, measured in basis points (1/100 of a percent).

    /// values 0 - 10 000 -> 0 - 100%
    uint public gameCloneFee = 7000;         /// % game fee (contract + prizeFund)
    uint public priceFactor = 10000;         /// %% calculate price (increase/decrease)
    uint public prizeFundFactor = 5000;      /// %% prizeFund

    /**
    * @dev Constructor function
    */
    constructor(string _name, string _symbol) BaseGame(_name, _symbol) public {}

    ///@dev increase prize fund
    function _addToFund(uint _val, bool isAll) internal whenNotPaused {
        if(isAll) {
            prizeFund = prizeFund.add(_val);
        } else {
            prizeFund = prizeFund.add(_val.mul(prizeFundFactor).div(10000));
        }
    }

    ///@dev create new Token
    function createAccount() external payable whenNotPaused returns (uint) {
        require(msg.value >= basePrice);

        ///todo: return excess funds
        _addToFund(msg.value, false);
        return _createToken(0, msg.sender);
    }

    ///@dev buy clone of token
    function cloneAccount(uint _tokenId) external payable whenNotPaused returns (uint) {
        require(exists(_tokenId));

        uint tokenPrice = calculateTokenPrice(_tokenId);
        require(msg.value >= tokenPrice);

        /// create clone
        uint newToken = _createToken( _tokenId, msg.sender);

        /// calculate game fee
        //uint gameFee = _calculateGameFee(tokenPrice);
        uint gameFee = tokenPrice.mul(gameCloneFee).div(10000);
        /// increase prizeFund
        _addToFund(gameFee, false);
        /// send income to token owner
        uint ownerProceed = tokenPrice.sub(gameFee);
        address tokenOwnerAddress = tokenOwner[_tokenId];
        tokenOwnerAddress.transfer(ownerProceed);

        return newToken;
    }


    ///@dev create forecast, check game stop
    function createForecast(uint _tokenId, uint _gameId,
        uint8 _goalA, uint8 _goalB, bool _odds, uint8 _shotA, uint8 _shotB)
    external whenNotPaused onlyOwnerOf(_tokenId) returns (uint){
        require(exists(_tokenId));
        require(block.timestamp < games[_gameId].gameDate);

        uint _forecastData = toForecastData(_goalA, _goalB, _odds, _shotA, _shotB);
        return _createForecast(_tokenId, _gameId, _forecastData);

        //check exist forecast from this token/account
        /* uint forecastId = 0;
        uint _forecastCount = tokenForecasts[_tokenId].length;
        uint _testForecastId;
        for (uint _forecastIndex = 0; _forecastIndex < _forecastCount; _forecastIndex++) {
            _testForecastId = tokenForecasts[_tokenId][_forecastIndex];
            if(forecasts[_testForecastId].gameId == _gameId) {
                forecastId = _testForecastId;
                break;
            }
        }

        uint _forecastData = toForecastData(_goalA, _goalB, _odds, _shotA, _shotB);

        if(forecastId > 0) {
            return _editForecast(forecastId, _forecastData);
        } else {
            return _createForecast(_tokenId, _gameId, _forecastData);
        } */
    }

    ///@dev get list of token
    function tokensOfOwner(address _owner) public view returns(uint[] ownerTokens) {
        uint tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint totalToken = totalSupply();
            uint resultIndex = 0;

            uint _tokenId;
            for (_tokenId = 1; _tokenId <= totalToken; _tokenId++) {
                if (tokenOwner[_tokenId] == _owner) {
                    result[resultIndex] = _tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    ///@dev get list of forecast by token
    function forecastOfToken(uint _tokenId) public view returns(uint[]) {
        uint forecastCount = tokenForecasts[_tokenId].length;

        if (forecastCount == 0) {
            // Return an empty array
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](forecastCount);
            uint resultIndex;
            for (resultIndex = 0; resultIndex < forecastCount; resultIndex++) {
                result[resultIndex] = tokenForecasts[_tokenId][resultIndex];
            }

            return result;
        }
    }

    ///@dev get info by game
    function gameInfo(uint _gameId) external view returns(
        uint64 gameDate, Teams teamA, Teams teamB, uint goalA, uint gaolB,
        bool odds, uint shotA, uint shotB, uint forecastCount
    ){
        gameDate = games[_gameId].gameDate;
        teamA = games[_gameId].teamA;
        teamB = games[_gameId].teamB;
        goalA = games[_gameId].goalA;
        gaolB = games[_gameId].goalB;
        odds = games[_gameId].odds;
        shotA = games[_gameId].shotA;
        shotB = games[_gameId].shotB;
        forecastCount = games[_gameId].forecasts.length;
    }

    ///@dev get info by forecast
    function forecastInfo(uint _fId) external view
        returns(uint gameId, uint f) {
        gameId = forecasts[_fId].gameId;
        f = forecasts[_fId].forecastData;
    }

    function tokenInfo(uint _tokenId) external view
        returns(uint createBlockNumber, uint parentId, uint forecast, uint score, uint price) {

        createBlockNumber = tokens[_tokenId].createBlockNumber;
        parentId = tokens[_tokenId].parentId;
        price = calculateTokenPrice(_tokenId);
        forecast = getForecastCount(_tokenId, block.number, false);
        score = getScore(_tokenId);
    }

    ///@dev calculate token price
    function calculateTokenPrice(uint _tokenId) public view returns(uint) {
        require(exists(_tokenId));
        /// token price = (forecast count + 1) * basePrice * priceFactor / 10000
        uint forecastCount = getForecastCount(_tokenId, block.number, true);
        return (forecastCount.add(1)).mul(basePrice).mul(priceFactor).div(10000);
    }

    ///@dev get forecast count by tokenID
    function getForecastCount(uint _tokenId, uint _blockNumber, bool isReleased) public view returns(uint) {
        require(exists(_tokenId));

        uint forecastCount = 0 ;

        uint index = 0;
        uint count = tokenForecasts[_tokenId].length;
        for (index = 0; index < count; index++) {
            //game&#39;s ended
            if(forecasts[tokenForecasts[_tokenId][index]].forecastBlockNumber < _blockNumber){
                if(isReleased) {
                    if (games[forecasts[tokenForecasts[_tokenId][index]].gameId].gameDate < block.timestamp) {
                        forecastCount = forecastCount + 1;
                    }
                } else {
                    forecastCount = forecastCount + 1;
                }
            }
        }

        /// if token are cloned, calculate parent forecast score
        if(tokens[_tokenId].parentId != 0){
            forecastCount = forecastCount.add(getForecastCount(tokens[_tokenId].parentId,
                tokens[_tokenId].createBlockNumber, isReleased));
        }
        return forecastCount;
    }

    ///@dev calculate score by fan&#39;s forecasts
    function getScore(uint _tokenId) public view returns (uint){
        uint[] memory _gameForecast = new uint[](65);
        return getScore(_tokenId, block.number, _gameForecast);
    }

    ///@dev calculate score by fan&#39;s forecast to a specific block number
    function getScore(uint _tokenId, uint _blockNumber, uint[] _gameForecast) public view returns (uint){
        uint score = 0;

        /// find all forecasts and calculate forecast score
        uint[] memory _forecasts = forecastOfToken(_tokenId);
        if (_forecasts.length > 0){
            uint256 _index;
            for(_index = _forecasts.length - 1; _index >= 0 && _index < _forecasts.length ; _index--){
                /// check:
                ///     forecastBlockNumber < current block number
                ///     one forecast for one game (last)
                if(forecasts[_forecasts[_index]].forecastBlockNumber < _blockNumber &&
                    _gameForecast[forecasts[_forecasts[_index]].gameId] == 0 &&
                    block.timestamp > games[forecasts[_forecasts[_index]].gameId].gameDate
                ){
                    score = score.add(calculateScore(
                            forecasts[_forecasts[_index]].gameId,
                            forecasts[_forecasts[_index]].forecastData
                        ));
                    _gameForecast[forecasts[_forecasts[_index]].gameId] = forecasts[_forecasts[_index]].forecastBlockNumber;
                }
            }
        }

        /// if token are cloned, calculate parent forecast score
        if(tokens[_tokenId].parentId != 0){
            score = score.add(getScore(tokens[_tokenId].parentId, tokens[_tokenId].createBlockNumber, _gameForecast));
        }
        return score;
    }

    /// get forecast score
    function getForecastScore(uint256 _forecastId) external view returns (uint256) {
        require(_forecastId < forecasts.length);

        return calculateScore(
            forecasts[_forecastId].gameId,
            forecasts[_forecastId].forecastData
        );
    }

    ///@dev calculate score by game forecast (only for games that have ended)
    function calculateScore(uint256 _gameId, uint d)
    public view returns (uint256){
        require(block.timestamp > games[_gameId].gameDate);

        uint256 _shotB = (d & 0xff);
        d = d >> 8;
        uint256 _shotA = (d & 0xff);
        d = d >> 8;
        uint odds8 = (d & 0xff);
        bool _odds = odds8 == 1 ? true: false;
        d = d >> 8;
        uint256 _goalB = (d & 0xff);
        d = d >> 8;
        uint256 _goalA = (d & 0xff);
        d = d >> 8;

        Game memory cGame = games[_gameId];

        uint256 _score = 0;
        bool isDoubleScore = true;
        if(cGame.shotA == _shotA) {
            _score = _score.add(1);
        } else {
            isDoubleScore = false;
        }
        if(cGame.shotB == _shotB) {
            _score = _score.add(1);
        } else {
            isDoubleScore = false;
        }
        if(cGame.odds == _odds) {
            _score = _score.add(1);
        } else {
            isDoubleScore = false;
        }

        /// total goal count&#39;s
        if((cGame.goalA + cGame.goalB) == (_goalA + _goalB)) {
            _score = _score.add(2);
        } else {
            isDoubleScore = false;
        }

        /// exact match score
        if(cGame.goalA == _goalA && cGame.goalB == _goalB) {
            _score = _score.add(3);
        } else {
            isDoubleScore = false;
        }

        if( ((cGame.goalA > cGame.goalB) && (_goalA > _goalB)) ||
            ((cGame.goalA < cGame.goalB) && (_goalA < _goalB)) ||
            ((cGame.goalA == cGame.goalB) && (_goalA == _goalB))) {
            _score = _score.add(1);
        } else {
            isDoubleScore = false;
        }

        /// double if all win
        if(isDoubleScore) {
            _score = _score.mul(2);
        }
        return _score;
    }

    /// admin logic
    ///@dev set new base Price for create token
    function setBasePrice(uint256 _val) external onlyAdmin {
        require(_val > 0);
        basePrice = _val;
    }

    ///@dev change fee for clone token
    function setGameCloneFee(uint256 _val) external onlyAdmin {
        require(_val <= 10000);
        gameCloneFee = _val;
    }

    ///@dev change fee for clone token
    function setPrizeFundFactor(uint256 _val) external onlyAdmin {
        require(_val <= 10000);
        prizeFundFactor = _val;
    }

    ///@dev change fee for clone token
    function setPriceFactor(uint256 _val) external onlyAdmin {
        priceFactor = _val;
    }

    ///@dev game info edit
    function gameEdit(uint256 _gameId, uint64 gameDate,
        Teams teamA, Teams teamB)
    external onlyAdmin {
        games[_gameId].gameDate = gameDate;
        games[_gameId].teamA = teamA;
        games[_gameId].teamB = teamB;

        emit GameChanged(_gameId, games[_gameId].gameDate, games[_gameId].teamA, games[_gameId].teamB,
            0, 0, true, 0, 0);
    }

    function gameResult(uint256 _gameId, uint256 goalA, uint256 goalB, bool odds, uint256 shotA, uint256 shotB)
    external onlyAdmin {
        games[_gameId].goalA = goalA;
        games[_gameId].goalB = goalB;
        games[_gameId].odds = odds;
        games[_gameId].shotA = shotA;
        games[_gameId].shotB = shotB;

        emit GameChanged(_gameId, games[_gameId].gameDate, games[_gameId].teamA, games[_gameId].teamB,
            goalA, goalB, odds, shotA, shotB);
    }

    function toForecastData(uint8 _goalA, uint8 _goalB, bool _odds, uint8 _shotA, uint8 _shotB)
    pure internal returns (uint) {
        uint forecastData;
        forecastData = forecastData << 8 | _goalA;
        forecastData = forecastData << 8 | _goalB;
        uint8 odds8 = _odds ? 1 : 0;
        forecastData = forecastData << 8 | odds8;
        forecastData = forecastData << 8 | _shotA;
        forecastData = forecastData << 8 | _shotB;

        return forecastData;
    }
}


contract HWCIntegration is BaseGameLogic {

    event NewHWCRegister(address owner, string aD, string aW);

    constructor(string _name, string _symbol) BaseGameLogic(_name, _symbol) public {}

    struct HWCInfo {
        string aDeposit;
        string aWithdraw;
        uint deposit;
        uint index1;        // index + 1
    }

    uint public cHWCtoEth = 0;
    uint256 public prizeFundHWC = 0;

    // address => hwc address
    mapping (address => HWCInfo) hwcAddress;
    address[] hwcAddressList;

    function _addToFundHWC(uint256 _val) internal whenNotPaused {
        prizeFundHWC = prizeFundHWC.add(_val.mul(prizeFundFactor).div(10000));
    }

    function registerHWCDep(string _a) public {
        require(bytes(_a).length == 34);
        hwcAddress[msg.sender].aDeposit = _a;

        if(hwcAddress[msg.sender].index1 == 0){
            hwcAddress[msg.sender].index1 = hwcAddressList.push(msg.sender);
        }

        emit NewHWCRegister(msg.sender, _a, &#39;&#39;);
    }

    function registerHWCWit(string _a) public {
        require(bytes(_a).length == 34);
        hwcAddress[msg.sender].aWithdraw = _a;

        if(hwcAddress[msg.sender].index1 == 0){
            hwcAddress[msg.sender].index1 = hwcAddressList.push(msg.sender);
        }

        emit NewHWCRegister(msg.sender, &#39;&#39;, _a);
    }

    function getHWCAddressCount() public view returns (uint){
        return hwcAddressList.length;
    }

    function getHWCAddressByIndex(uint _index) public view returns (string aDeposit, string aWithdraw, uint d) {
        require(_index < hwcAddressList.length);
        return getHWCAddress(hwcAddressList[_index]);
    }

    function getHWCAddress(address _val) public view returns (string aDeposit, string aWithdraw, uint d) {
        aDeposit = hwcAddress[_val].aDeposit;
        aWithdraw = hwcAddress[_val].aWithdraw;
        d = hwcAddress[_val].deposit;
    }

    function setHWCDeposit(address _user, uint _val) external onlyAdmin {
        hwcAddress[_user].deposit = _val;
    }

    function createTokenByHWC(address _userTo, uint256 _parentId) external onlyAdmin whenNotPaused returns (uint) {
        //convert eth to hwc
        uint256 tokenPrice = basePrice.div(1e10).mul(cHWCtoEth);
        if(_parentId > 0) {
            tokenPrice = calculateTokenPrice(_parentId);
            tokenPrice = tokenPrice.div(1e10).mul(cHWCtoEth);
            //uint256 gameFee = _calculateGameFee(tokenPrice);
            uint gameFee = tokenPrice.mul(gameCloneFee).div(10000);
            _addToFundHWC(gameFee);

            uint256 ownerProceed = tokenPrice.sub(gameFee);
            address tokenOwnerAddress = tokenOwner[_parentId];

            hwcAddress[tokenOwnerAddress].deposit = hwcAddress[tokenOwnerAddress].deposit + ownerProceed;
        } else {
            _addToFundHWC(tokenPrice);
        }

        return _createToken(_parentId, _userTo);
    }

    function setCourse(uint _val) external onlyAdmin {
        cHWCtoEth = _val;
    }
}


contract SolutionGame is HWCIntegration {

    ///@dev winner token list
    uint256 countWinnerPlace;
    //place -> %%% ( 100% - 10000)
    mapping (uint256 => uint256) internal prizeDistribution;
    //place -> prize
    mapping (uint256 => uint256) internal prizesByPlace;
    mapping (uint256 => uint256) internal scoreByPlace;
    //token -> prize
    mapping (uint => uint) winnerMap;
    uint[] winnerList;

    mapping (uint256 => uint256) internal prizesByPlaceHWC;

    bool isWinnerTime = false;

    modifier whenWinnerTime() {
        require(isWinnerTime);
        _;
    }

    constructor(string _name, string _symbol) HWCIntegration(_name, _symbol) public {
        countWinnerPlace = 0;      //top 10!
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it&#39;s from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        _addToFund(msg.value, true);
    }

    function setWinnerTimeStatus(bool _status) external onlyOwner {
        isWinnerTime = _status;
    }

    // @dev withdraw balance without prizeFund
    function withdrawBalance() external onlyOwner {
        owner.transfer(address(this).balance.sub(prizeFund));
    }

    /// @dev set count winner place / top1/top5/top10 etc
    function setCountWinnerPlace(uint256 _val) external onlyOwner {
        countWinnerPlace = _val;
    }

    /// @dev set the distribution of the prize by place
    function setWinnerPlaceDistribution(uint256 place, uint256 _val) external onlyOwner {
        require(place <= countWinnerPlace);
        require(_val <= 10000);

        uint256 testVal = 0;
        uint256 index;
        for (index = 1; index <= countWinnerPlace; index ++) {
            if(index != place) {
                testVal = testVal + prizeDistribution[index];
            }
        }

        testVal = testVal + _val;
        require(testVal <= 10000);
        prizeDistribution[place] = _val;
    }

    ///@dev method for manual add/edit winner list and winner count
    /// only after final
    function setCountWinnerByPlace(uint256 place, uint256 _winnerCount, uint256 _winnerScore) public onlyOwner whenPaused {
        require(_winnerCount > 0);
        require(place <= countWinnerPlace);
        prizesByPlace[place] = prizeFund.mul(prizeDistribution[place]).div(10000).div(_winnerCount);
        prizesByPlaceHWC[place] = prizeFundHWC.mul(prizeDistribution[place]).div(10000).div(_winnerCount);
        scoreByPlace[place] = _winnerScore;
    }

    function checkIsWinner(uint _tokenId) public view whenPaused onlyOwnerOf(_tokenId)
    returns (uint place) {
        place = 0;
        uint score = getScore(_tokenId);
        for(uint index = 1; index <= countWinnerPlace; index ++) {
            if (score == scoreByPlace[index]) {
                // token - winner
                place = index;
                break;
            }
        }
    }

    function getMyPrize() external whenWinnerTime {
        uint[] memory tokenList = tokensOfOwner(msg.sender);

        for(uint index = 0; index < tokenList.length; index ++) {
            getPrizeByToken(tokenList[index]);
        }
    }

    function getPrizeByToken(uint _tokenId) public whenWinnerTime onlyOwnerOf(_tokenId) {
        uint place = checkIsWinner(_tokenId);
        require (place > 0);

        uint prize = prizesByPlace[place];
        if(prize > 0) {
            if(winnerMap[_tokenId] == 0) {
                winnerMap[_tokenId] = prize;
                winnerList.push(_tokenId);

                address _owner = tokenOwner[_tokenId];
                if(_owner != address(0)){
                    //for hwc integration
                    uint hwcPrize = prizesByPlaceHWC[place];
                    hwcAddress[_owner].deposit = hwcAddress[_owner].deposit + hwcPrize;

                    _owner.transfer(prize);
                }
            }
        }
    }

    function getWinnerList() external view onlyAdmin returns (uint[]) {
        return winnerList;
    }

    function getWinnerInfo(uint _tokenId) external view onlyAdmin returns (uint){
        return winnerMap[_tokenId];
    }

    function getResultTable(uint _start, uint _count) external view returns (uint[]) {
        uint[] memory results = new uint[](_count);
        for(uint index = _start; index < tokens.length && index < (_start + _count); index++) {
            results[(index - _start)] = getScore(index);
        }
        return results;
    }
}