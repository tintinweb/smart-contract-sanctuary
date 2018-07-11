pragma solidity ^0.4.24;

// File: contracts/utils/ExtendsOwnable.sol

contract ExtendsOwnable {

    mapping(address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/contents/Content.sol

//import &quot;contracts/contents/Episode.sol&quot;;
//import &quot;contracts/supporter/Fundraising.sol&quot;;
//import &quot;contracts/supporter/Supporters.sol&quot;;

contract Content is ExtendsOwnable {
    using SafeMath for uint256;

    string public name;
    address public writer;
    string public synopsis;
    string public genres;
    string public titleImage;
//    Fundraising public fundraising;
//    Supporters public supporters;
    uint256 public marketerRate;
    uint256 public translatorRate;
//    Episode[] public episodes;
//    TranslatorContent[] public translators;

    modifier contentOwner() {
        require(writer == msg.sender || owners[msg.sender]);
        _;
    }

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    modifier validString(string _str) {
        require(bytes(_str).length > 0);
        _;
    }

    constructor(
        string _name,
        address _writer,
        string _synopsis,
        string _genres,
        string _titleImage,
        uint256 _marketerRate,
        uint256 _translatorRate
    ) public {
        require(bytes(_name).length > 0 && bytes(_titleImage).length > 0 && bytes(_genres).length > 0);
        require(_writer != address(0) && _writer != address(this));

        name = _name;
        writer = _writer;
        synopsis = _synopsis;
        genres = _genres;
        titleImage = _titleImage;
        marketerRate = _marketerRate;
        translatorRate = _translatorRate;

        emit RegisterContents(msg.sender, &quot;initializing content&quot;);
    }

    function resetContent(
        string _name,
        address _writer,
        string _synopsis,
        string _genres,
        string _titleImage,
        uint256 _marketerRate,
        uint256 _translatorRate
    ) external contentOwner validAddress(_writer) {
        require(bytes(_name).length > 0 && bytes(_titleImage).length > 0 && bytes(_genres).length > 0);

        name = _name;
        writer = _writer;
        synopsis = _synopsis;
        genres = _genres;
        titleImage = _titleImage;
        marketerRate = _marketerRate;
        translatorRate = _translatorRate;

        emit RegisterContents(msg.sender, &quot;reset content&quot;);
    }
/*
    function addSupporter(address _supporterAddr) external contentOwner validAddress(_supporterAddr) {
        supporters.push(Supporters(_supporterAddr));
        emit ChangeExternalAddress(_supporterAddr, &quot;add supporter address&quot;);
    } */

    function setWriter(address _writerAddr) external contentOwner validAddress(_writerAddr) {
        writer = _writerAddr;
        emit ChangeExternalAddress(writer, &quot;writer&quot;);
    }

    /* function setFundraising(address _funraisingAddr) external contentOwner validAddress(_writerAddr) {
        fundraising = Fundraising(_funraisingAddr);
        emit ChangeExternalAddress(_funraisingAddr, &quot;fundraising&quot;);
    } */

    function setContentName(string _name) external contentOwner validString(_name) {
        name = _name;
        emit ChangeContentDescription(msg.sender, &quot;content name&quot;);
    }

    function setSynopsis(string _synopsis) external contentOwner validString(_synopsis) {
        synopsis = _synopsis;
        emit ChangeContentDescription(msg.sender, &quot;synopsis&quot;);
    }

    function setGenres(string _genres) external contentOwner validString(_genres) {
        genres = _genres;
        emit ChangeContentDescription(msg.sender, &quot;genres&quot;);
    }

    function setTitleImage(string _imagePath) external contentOwner validString(_imagePath) {
        titleImage = _imagePath;
        emit ChangeContentDescription(msg.sender, &quot;title image&quot;);
    }

    function setMarketerRate(uint256 _marketerRate) external contentOwner {
        marketerRate = _marketerRate;
        emit ChangeDistributionRate(msg.sender, &quot;marketer rate&quot;);
    }

    function setTranslatorRate(uint256 _translatorRate) external contentOwner {
        translatorRate = _translatorRate;
        emit ChangeDistributionRate(msg.sender, &quot;translator rate&quot;);
    }

    /* function addEpisode(address _episodeAddr) external contentOwner {
        episodes.push(Episode(_episodeAddr));
        emit RegisterContents(msg.sender, &quot;episode&quot;);
    }

    function addTranslatorContent(address _translatorAddr) external contentOwner {
        translators.push(TranslatorContent(_translatorAddr));
        emit RegisterContents(msg.sender, &quot;translator contents&quot;);
    }

    function getSupportersAddress() public view return (address) {
        return address(supporters);
    }

    function getEpisodeList() public view return (address[], string[], string[], uint256[]) {
        uint256 arrayLength = episodes.length;
        address[] memory episodeAddress = new address[](arrayLength);
        string[] memory episodeNames = new string[](arrayLength);
        string[] memory episodeTitleImages = new string[](arrayLength);
        uint256[] memory episodePrices = new uint256[](arrayLength);

        for(uint256 i = 0 ; i < arrayLength ; i++) {
            episodeAddress[i] = address(episodes[i]);
            episodeNames[i] = episodes[i].name();
            episodeTitleImages[i] = episode[i].titleImage();
            episodePrices[i] = episode[i].price();
        }

        return (episodeAddress, episodeNames, episodeTitleImages, episodePrices);
    }

    function getTranslationLanguageList() public view return (string[]) {
        string[] memory translationLanguages = new string[](translators.length);

        for(uint256 i = 0 ; i < translators.length ; i++) {
            translationLanguages[i] = translators[i].language;
        }

        return translationLanguages;
    } */

    event ChangeExternalAddress(address _addr, string _name);
    event ChangeDistributionRate(address _addr, string _name);
    event ChangeContentDescription(address _addr, string _name);
    event RegisterContents(address _addr, string _name);
}