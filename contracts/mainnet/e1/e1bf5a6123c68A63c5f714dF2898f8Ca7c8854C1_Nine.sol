pragma solidity ^0.4.20;

contract Nine {
  address public God;

  function Nine() public {
    God = msg.sender;
  }

  modifier onlyGod() {
    require(msg.sender == God);
    _;
  }

  function destroyTheUniverse () private {
    selfdestruct(God);
  }

  address public agentAddress;
  uint256 public nameValue = 10 finney;

  function setAgent(address _newAgent) external onlyGod {
    require(_newAgent != address(0));
    agentAddress = _newAgent;
  }

  modifier onlyAgent() {
    require(msg.sender == agentAddress);
    _;
  }

  function withdrawBalance(uint256 amount) external onlyAgent {
    msg.sender.transfer(amount <= 0 ? address(this).balance : amount);
  }

  function setNameValue(uint256 val) external onlyAgent {
    nameValue = val;
  }


  string public constant name = "TheNineBillionNamesOfGod";
  string public constant symbol = "NOG";
  uint256 public constant totalSupply = 9000000000;

  struct Name {
    uint64 recordTime;
  }


  Name[] names;

  mapping (uint256 => address) public nameIndexToOwner;

  mapping (address => uint256) ownershipTokenCount;

  event Transfer(address from, address to, uint256 tokenId);
  event Record(address owner, uint256 nameId);

  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    ownershipTokenCount[_to]++;

    nameIndexToOwner[_tokenId] = _to;

    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
    }

    emit Transfer(_from, _to, _tokenId);
  }

  function _recordName(address _owner)
    internal
    returns (uint)
  {
    Name memory _name = Name({recordTime: uint64(now)});
    uint256 newNameId = names.push(_name) - 1;

    require(newNameId == uint256(uint32(newNameId)));

    emit Record(_owner,newNameId);

    _transfer(0, _owner, newNameId);

    if (names.length == totalSupply) {
      destroyTheUniverse();
    }

    return newNameId;
  }

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return nameIndexToOwner[_tokenId] == _claimant;
  }

  function balanceOf(address _owner) public view returns (uint256 count) {
    return ownershipTokenCount[_owner];
  }


  function transfer(
                    address _to,
                    uint256 _tokenId
                    )
    external
  {
    require(_to != address(0));

    require(_to != address(this));

    require(_owns(msg.sender, _tokenId));

    _transfer(msg.sender, _to, _tokenId);
  }


  function recordNameCount() public view returns (uint) {
    return names.length;
  }

  function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
  {
    owner = nameIndexToOwner[_tokenId];

    require(owner != address(0));
  }

  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalRecord = recordNameCount();
      uint256 resultIndex = 0;

      uint256 nId;

      for (nId = 1; nId < totalRecord; nId++) {
        if (nameIndexToOwner[nId] == _owner) {
          result[resultIndex] = nId;
          resultIndex++;
        }
      }

      return result;
    }
  }


  function getName(uint256 _id)
    external
    view
    returns (uint256 recordTime) {
    recordTime = uint256(names[_id].recordTime);
  }

  function tryToRecord(address _sender, uint256 _value) internal {
    uint times = _value / nameValue;
    for (uint i = 0; i < times; i++) {
      _recordName(_sender);
    }
  }

  function recordName() external payable {
    tryToRecord(msg.sender, msg.value);
  }

  function() external payable {
    tryToRecord(msg.sender, msg.value);
  }
}