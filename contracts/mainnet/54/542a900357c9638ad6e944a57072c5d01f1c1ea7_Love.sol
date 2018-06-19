pragma solidity ^0.4.19;

contract Love {

  mapping (address => address) private propose;
  mapping (address => address) private partner;
  mapping (uint256 => string[]) private partnerMessages;
  mapping (uint256 => bool) private isHiddenMessages;
  uint public proposeCount;
  uint public partnerCount;

  event Propose(address indexed from, address indexed to);
  event CancelPropose(address indexed from, address indexed to);
  event Partner(address indexed from, address indexed to);
  event Farewell(address indexed from, address indexed to);
  event Message(address indexed addressOne, address indexed addressTwo, string message, uint index);
  event HiddenMessages(address indexed addressOne, address indexed addressTwo, bool flag);

  function proposeTo(address to) public {
    require(to != address(0));
    require(msg.sender != to);
    require(partner[msg.sender] != to);

    address alreadyPropose = propose[to];
    if (alreadyPropose == msg.sender) {
      propose[to] = address(0);
      if (propose[msg.sender] != address(0)) {
        propose[msg.sender] = address(0);
        proposeCount -= 2;

      } else {
        proposeCount--;
      }

      address selfPartner = partner[msg.sender];
      if (selfPartner != address(0)) {
        if (partner[selfPartner] == msg.sender) {
          partner[selfPartner] = address(0);
          partnerCount--;
          Farewell(msg.sender, selfPartner);
        }
      }
      partner[msg.sender] = to;

      address targetPartner = partner[to];
      if (targetPartner != address(0)) {
        if (partner[targetPartner] == to) {
          partner[targetPartner] = address(0);
          partnerCount--;
          Farewell(to, targetPartner);
        }
      }
      partner[to] = msg.sender;

      partnerCount++;
      Partner(msg.sender, to);

    } else {
      if (propose[msg.sender] == address(0)) {
        proposeCount++;
      }
      propose[msg.sender] = to;
      Propose(msg.sender, to);
    }
  }

  function cancelProposeTo() public {
    address proposingTo = propose[msg.sender];
    require(proposingTo != address(0));
    propose[msg.sender] = address(0);
    proposeCount--;
    CancelPropose(msg.sender, proposingTo);
  }

  function addMessage(string message) public {
    address target = partner[msg.sender];
    require(isPartner(msg.sender, target) == true);
    uint index = partnerMessages[uint256(keccak256(craetePartnerBytes(msg.sender, target)))].push(message) - 1;
    Message(msg.sender, target, message, index);
  }

  function farewellTo(address to) public {
    require(partner[msg.sender] == to);
    require(partner[to] == msg.sender);
    partner[msg.sender] = address(0);
    partner[to] = address(0);
    partnerCount--;
    Farewell(msg.sender, to);
  }

  function isPartner(address a, address b) public view returns (bool) {
    require(a != address(0));
    require(b != address(0));
    return (a == partner[b]) && (b == partner[a]);
  }

  function getPropose(address a) public view returns (address) {
    return propose[a];
  }

  function getPartner(address a) public view returns (address) {
    return partner[a];
  }

  function getPartnerMessage(address a, address b, uint index) public view returns (string) {
    require(isPartner(a, b) == true);
    uint256 key = uint256(keccak256(craetePartnerBytes(a, b)));
    if (isHiddenMessages[key] == true) {
      require((msg.sender == a) || (msg.sender == b));
    }
    uint count = partnerMessages[key].length;
    require(index < count);
    return partnerMessages[key][index];
  }

  function partnerMessagesCount(address a, address b) public view returns (uint) {
    require(isPartner(a, b) == true);
    uint256 key = uint256(keccak256(craetePartnerBytes(a, b)));
    if (isHiddenMessages[key] == true) {
      require((msg.sender == a) || (msg.sender == b));
    }
    return partnerMessages[key].length;
  }

  function getOwnPartnerMessage(uint index) public view returns (string) {
    return getPartnerMessage(msg.sender, partner[msg.sender], index);
  }

  function craetePartnerBytes(address a, address b) private pure returns(bytes) {
    bytes memory arr = new bytes(64);
    bytes32 first;
    bytes32 second;
    if (uint160(a) < uint160(b)) {
      first = keccak256(a);
      second = keccak256(b);
    } else {
      first = keccak256(b);
      second = keccak256(a);
    }

    for (uint i = 0; i < 32; i++) {
      arr[i] = first[i];
      arr[i + 32] = second[i];
    }
    return arr;
  }

  function setIsHiddenMessages(bool flag) public {
    require(isPartner(msg.sender, partner[msg.sender]) == true);
    uint256 key = uint256(keccak256(craetePartnerBytes(msg.sender, partner[msg.sender])));
    isHiddenMessages[key] = flag;
    HiddenMessages(msg.sender, partner[msg.sender], flag);
  }
}