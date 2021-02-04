// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./ERC721.sol";
import "./DSAuth.sol";
import "./Counters.sol";

contract DuelMonsters is ERC721, DSAuth {

    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    mapping (uint256 => string) public tokenDLMR;
    mapping (string => EnumerableSet.UintSet) private _dlmrTokens;

    mapping (string => uint256) public dlmrIdByDLMRName;
    mapping (uint256 => DLMR) private _dlmrById;

    Counters.Counter private _tokenIds;
    Counters.Counter public totalDLMRs;

    event mintedDLMR(uint256 id, string dlmrName, address to);

    struct DLMR {
      uint256 id;
      string name;
      string url;
      uint256 limit;
    }

    constructor () ERC721("DuelMonsters", "DLMR") public {
    }

    function setBaseURI(string memory baseURI_) public auth {
      _setBaseURI(baseURI_);
    }

    function createDLMR(
      string memory name,
      string memory url,
      uint256 limit) auth public returns (uint256) {
      require(!(dlmrIdByDLMRName[name] > 0), "this dlmr already exists!");
      totalDLMRs.increment();
      uint256 _id = totalDLMRs.current();

      DLMR storage _dlmr = _dlmrById[_id];

      _dlmr.id = _id;
      _dlmr.name = name;
      _dlmr.url = url;
      _dlmr.limit = limit;

      dlmrIdByDLMRName[name] = _id;

      return _dlmr.id;
    }

    function mintDLMR(address to, string memory name) auth public returns (uint256) {
      uint256 _dlmrId = dlmrIdByDLMRName[name];
      require(_dlmrId > 0, "this dlmr does not exist!");
      (, , string memory _url, uint256 _limit) = dlmrInfoById(_dlmrId);
      require(dlmrTokenCount(name) < _limit || _limit == 0, "this uri is over the limit!");

      // mint token
      _tokenIds.increment();
      uint256 id = _tokenIds.current();
      _dlmrTokens[name].add(id);
      tokenDLMR[id] = name;

      _safeMint(to, id);
      _setTokenURI(id, _url);

      emit mintedDLMR(id, name, to);

      return id;
    }

    function dlmrTokenCount(string memory name) public view returns(uint256) {
      uint256 _dlmrTokenCount = _dlmrTokens[name].length();
      return _dlmrTokenCount;
    }

    function dlmrInfoById(uint256 id) public view returns (uint256, string memory, string memory, uint256) {
      require(id > 0 && id <= totalDLMRs.current(), "this dlmr does not exist!");
      DLMR storage _dlmr = _dlmrById[id];

      return (id, _dlmr.name, _dlmr.url, _dlmr.limit);
    }

    function dlmrInfoByDLMRName(string memory name) public view returns (uint256, string memory, string memory, uint256) {
      uint256 _dlmrId = dlmrIdByDLMRName[name];

      return dlmrInfoById(_dlmrId);
    }
}