pragma solidity >=0.6.0 <0.7.0;

import "./ERC721.sol";
import "./DSAuth.sol";
import "./Counters.sol";

interface ITKRegistry {
    function tkMain() external view returns (address);
    function tkfrToken() external view returns (address);
    function tkToken() external view returns (address);
}

interface ITKMain {
    function tktrInfoById(uint256) external view returns (uint256, address payable, string memory, bytes memory, uint256, uint256, string memory);
    function tktrInfoByTKTRUrl(string calldata) external view returns (uint256, address payable, string memory, bytes memory, uint256, uint256, string memory);
    function tktrIdByTKTRUrl(string calldata) external view returns (uint256);
}

contract TKFRToken is ERC721, DSAuth {

    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    mapping (uint256 => string) public tokenTKFR;
    mapping (string => EnumerableSet.UintSet) private _tkfrTokens;

    mapping (string => uint256) public tkfrIdByTKFRUrl;
    mapping (uint256 => TKFR) private _tkfrById;
    mapping (address => EnumerableSet.UintSet) private _artistTKFRs;

    ITKRegistry public tkRegistry;
    Counters.Counter private _tokenIds;
    Counters.Counter public totalTKFRs;

    event mintedTKFR(uint256 id, string tkfrUrl, address to);

    struct TKFR {
      uint256 id;
      address artist;
      string jsonUrl;
      string tkfrUrl;
      uint256 limit;
      uint256 level;
    }

    constructor(address _registry) ERC721("TKFR", "TKFR") public {
      tkRegistry = ITKRegistry(_registry);
      _setBaseURI('https://juinc.github.io/tokenURI_sandbox/');
    }

    // onlyOwner
    function setTKRegistry(address _address) public onlyOwner {
      tkRegistry = ITKRegistry(_address);
    }

    function setBaseURI(string memory baseURI_) public auth {
      _setBaseURI(baseURI_);
    }

    function createTKFR(
      string memory tkfrUrl,
      string memory jsonUrl,
      uint256 limit,
      uint256 level,
      address artist) 
    auth public returns (uint256) {
      require(!(tkfrIdByTKFRUrl[tkfrUrl] > 0), "this tkfr already exists!");
      totalTKFRs.increment();
      uint256 _tkfrId = totalTKFRs.current();

      TKFR storage _tkfr = _tkfrById[_tkfrId];

      _tkfr.id = _tkfrId;
      _tkfr.artist = artist;
      _tkfr.tkfrUrl = tkfrUrl;
      _tkfr.jsonUrl = jsonUrl;
      _tkfr.limit = limit;
      _tkfr.level = level;

      tkfrIdByTKFRUrl[tkfrUrl] = _tkfrId;
      _artistTKFRs[artist].add(_tkfrId);

      //emit newLFTR(_lftr.id, _lftr.artist, _lftr.lftrUrl, _lftr.jsonUrl, _lftr.limit);

      return _tkfr.id;
    }

    function mintTKFR(address to, string memory tkfrUrl) auth public returns (uint256) {
      uint256 _tkfrId = tkfrIdByTKFRUrl[tkfrUrl];
      require(_tkfrId > 0, "this tkfr does not exist!");
      (, , string memory _jsonUrl, , uint256 _limit,) = tkfrInfoById(_tkfrId);
      require(tkfrTokenCount(tkfrUrl) < _limit || _limit == 0, "this lffr is over the limit!");

      // mint token
      _tokenIds.increment();
      uint256 id = _tokenIds.current();
      _tkfrTokens[tkfrUrl].add(id);
      tokenTKFR[id] = tkfrUrl;

      _mint(to, id);
      _setTokenURI(id, _jsonUrl);

      emit mintedTKFR(id, tkfrUrl, to);

      return id;      
    }

    // getter function
    function tkMain() public view returns (ITKMain) {
      return ITKMain(tkRegistry.tkMain());
    }

    function tkfrTokenCount(string memory _tkfrUrl) public view returns(uint256) {
      uint256 _tkfrTokenCount = _tkfrTokens[_tkfrUrl].length();
      return _tkfrTokenCount;
    }

    function tkfrTokenByIndex(string memory tkfrUrl, uint256 index) public view returns (uint256) {
      return _tkfrTokens[tkfrUrl].at(index);
    }

    function tkfrInfoById(uint256 id) public view returns (uint256, address, string memory, uint256, uint256, string memory) {
      require(id > 0 && id <= totalTKFRs.current(), "this tkfr does not exist!");
      TKFR storage _tkfr = _tkfrById[id];

      return (id, _tkfr.artist, _tkfr.jsonUrl,  _tkfr.level, _tkfr.limit, _tkfr.tkfrUrl);
    }

    function tkfrInfoByTKFRUrl(string memory tkfrUrl) public view returns (uint256, address, string memory, uint256, uint256, string memory) {
      uint256 _tkfrId = tkfrIdByTKFRUrl[tkfrUrl];

      return tkfrInfoById(_tkfrId);
    }

    function tkfrsCreatedBy(address artist) public view returns (uint256) {
      return _artistTKFRs[artist].length();
    }

    function tkfrOfArtistByIndex(address artist, uint256 index) public view returns (uint256) {
      return _artistTKFRs[artist].at(index);
    }

    function versionRecipient() external virtual pure returns (string memory) {
      return "1.0";
    }
}