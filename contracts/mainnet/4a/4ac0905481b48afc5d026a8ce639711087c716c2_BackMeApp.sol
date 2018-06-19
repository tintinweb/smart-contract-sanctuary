pragma solidity ^0.4.22;

contract BackMeApp {
  address public owner;
  bool public isShutDown;
  uint256 public minEsteemAmount;

  struct EtherBox {
    bytes32 label;
    address owner;
    string ownerUrl;
    uint256 expiration;
  }

  mapping (address => bytes32) public nicknames;
  mapping (address => address[]) public ownerToEtherBoxes;
  mapping (address => EtherBox) public etherBoxes;

  event NewEsteem(address indexed senderAddress, bytes32 senderNickname, address indexed etherBoxAddress, bytes32 etherBoxLabel, string message, uint amount, uint256 timestamp);
  event EtherBoxPublished(address indexed senderAddress, bytes32 senderNickname, address indexed etherBoxAddress, bytes32 etherBoxLabel, uint256 timestamp);
  event EtherBoxDeleted(address indexed senderAddress, bytes32 senderNickname, address indexed etherBoxAddress, uint256 timestamp);
  modifier onlyOwner() { require(msg.sender == owner); _; }
  modifier onlyWhenRunning() { require(isShutDown == false); _; }

  constructor() public { owner = msg.sender; minEsteemAmount = 1 finney; }
  function() public payable {}

  function getEtherBoxes(address _owner) external view returns (address[]) { return ownerToEtherBoxes[_owner]; }
  function isExpired(address _etherBoxAddress) external view returns(bool) { return etherBoxes[_etherBoxAddress].expiration <= now ? true : false; }

  function esteem(bytes32 _nickname, string _message, address _to) external payable {
    assert(bytes(_message).length <= 300);
    EtherBox storage etherBox = etherBoxes[_to];
    require(etherBox.expiration > now);
    assert(etherBox.owner != address(0));
    nicknames[msg.sender] = _nickname;
    emit NewEsteem(msg.sender, _nickname, _to, etherBox.label, _message, msg.value, now);
    etherBox.owner.transfer(msg.value);
  }

  function publishEtherBox (bytes32 _label, string _ownerUrl, uint _lifespan) external onlyWhenRunning() payable {
      require(ownerToEtherBoxes[msg.sender].length < 10);
      assert(bytes(_ownerUrl).length <= 200);
      address etherBoxAddress = address(keccak256(msg.sender, now));
      ownerToEtherBoxes[msg.sender].push(etherBoxAddress);
      etherBoxes[etherBoxAddress] = EtherBox({
        label: _label,
        owner: msg.sender,
        ownerUrl: _ownerUrl,
        expiration: now + _lifespan
      });
      emit EtherBoxPublished(msg.sender, nicknames[msg.sender], etherBoxAddress, _label, now);
      if(msg.value > 0){ owner.transfer(msg.value); }
  }

  function deleteEtherBox(address _etherBoxAddress) external {
    require(etherBoxes[_etherBoxAddress].owner == msg.sender);
    require(etherBoxes[_etherBoxAddress].expiration <= now);
    address[] storage ownedEtherBoxes = ownerToEtherBoxes[msg.sender];
    address[] memory tempEtherBoxes = ownedEtherBoxes;
    uint newLength = 0;
    for(uint i = 0; i < tempEtherBoxes.length; i++){
      if(tempEtherBoxes[i] != _etherBoxAddress){
        ownedEtherBoxes[newLength] = tempEtherBoxes[i];
        newLength++;
      }
    }
    ownedEtherBoxes.length = newLength;
    delete etherBoxes[_etherBoxAddress];
    emit EtherBoxDeleted(msg.sender, nicknames[msg.sender], _etherBoxAddress, now);
  }

  function getBalance() external view returns(uint) { return address(this).balance; }
  function withdrawBalance() external onlyOwner() { owner.transfer(address(this).balance); }
  function toggleFactoryPower() external onlyOwner() { isShutDown = isShutDown == false ? true : false; }
  function destroyFactory() external onlyOwner() { selfdestruct(owner); }
}