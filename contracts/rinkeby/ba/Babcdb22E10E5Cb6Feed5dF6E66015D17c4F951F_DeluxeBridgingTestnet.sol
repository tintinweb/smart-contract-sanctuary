//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/BearsDeluxeI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// @dev DeluxeBridge is bridging a 1155 BearsDeluxe into a 721 and viceversa
contract DeluxeBridgingTestnet is ERC721Holder, ERC1155Holder, Ownable, ReentrancyGuard {
  uint32 private totalBridged = 0;
  address[] private senders;
  uint256[] idsBridged;

  uint256[] private whitelisted;
  string ids;
  // ids that can be minted
  uint16[] private newTokenIds;
  // 1155 tokens mapped to 721 tokens
  mapping(uint256 => uint16) private oldNewIds;
  // 721 tokens mapped to 1155 tokens
  mapping(uint16 => uint256) private newOldIds;

  address private immutable osContract;
  address private bdContract = 0x0000000000000000000000000000000000000000;

  event ReceivedFromOS(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId, uint256 _amount);

  event ReceivedFrom721(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId);

  event Minted721(address indexed _sender, uint256 indexed _tokenId);

  constructor(address _osContract) onlyOwner {
    osContract = _osContract;
    init();
  }

  /**
   * @dev when receive a deluxe from OS, it mints a 721
   */
  function mintOnReceiving(address _sender, uint256 _tokenId) internal isWhitelisted(_tokenId) returns (bool) {
    require(_sender != address(0), "can not mint to address 0");

    uint256 newTokenId = oldNewIds[_tokenId];

    if (BearsDeluxeI(bdContract).exists(newTokenId) && BearsDeluxeI(bdContract).ownerOf(newTokenId) == address(this)) {
      BearsDeluxeI(bdContract).safeTransferFrom(address(this), _sender, newTokenId);
      return true;
    }

    require(!BearsDeluxeI(bdContract).exists(newTokenId), "token minted");
    require(newTokenId != 0, "new token id !exists");

    BearsDeluxeI(bdContract).mint(_sender, newTokenId);
    return true;
  }

  /**
   * @dev check a OS token balance
   */
  function checkBalance(address _account, uint256 _tokenId) public view returns (uint256) {
    require(_account != address(0), "to is address 0");
    return IERC1155(osContract).balanceOf(_account, _tokenId);
  }

  /**
   * @dev sets Bears Deluxe 721 token
   */
  function setBDContract(address _contract) public onlyOwner {
    require(_contract != address(0), "_contract !address 0");
    bdContract = _contract;
  }

  /**
   * @dev check owner of a token on OpenSea token
   */
  function ownerOf1155(uint256 _tokenId) public view returns (bool) {
    return IERC1155(osContract).balanceOf(msg.sender, _tokenId) != 0;
  }

  /**
   * @dev owner minting 721
   */
  function mint721(uint16 _tokenId, address _to) external onlyOwner {
    require(_to != address(0), "mint to address 0");
    require(!BearsDeluxeI(bdContract).exists(_tokenId), "token exists");

    if (BearsDeluxeI(bdContract).exists(_tokenId) && BearsDeluxeI(bdContract).ownerOf(_tokenId) == address(this)) {
      BearsDeluxeI(bdContract).safeTransferFrom(address(this), _to, _tokenId);
      return;
    }
    _mint721(_tokenId, _to);
  }

  /**
   * @dev get os contract address
   */
  function getOSContract() public view returns (address) {
    return osContract;
  }

  /**
   * @dev get 721 contract address
   */
  function getBDContract() public view returns (address) {
    return bdContract;
  }

  /**
   * @dev triggered by 1155 transfer
   */
  function onERC1155Received(
    address _sender,
    address _receiver,
    uint256 _tokenId,
    uint256 _amount,
    bytes memory _data
  ) public override nonReentrant returns (bytes4) {
    triggerReceived1155(_sender, _tokenId);
    mintOnReceiving(_sender, _tokenId);
    emit ReceivedFromOS(_sender, _receiver, _tokenId, _amount);
    return super.onERC1155Received(_sender, _receiver, _tokenId, _amount, _data);
  }

  /**
   * @dev triggered by 721 transfer
   */
  function onERC721Received(
    address _sender,
    address _receiver,
    uint256 _tokenId,
    bytes memory _data
  ) public override nonReentrant returns (bytes4) {
    require(_sender != address(0), "update from address 0");
    if (_sender == address(this)) return super.onERC721Received(_sender, _receiver, _tokenId, _data);

    require(_tokenId <= type(uint16).max, "ids overflow");
    if (_sender != address(this)) onReceiveTransfer721(_sender, _tokenId);

    emit ReceivedFrom721(_sender, _receiver, _tokenId);
    return super.onERC721Received(_sender, _receiver, _tokenId, _data);
  }

  /**
   * @dev update params once we receive a transfer from 1155
   * the sender can not be address(0) and tokenId needs to be allowed
   */
  function triggerReceived1155(address _sender, uint256 _tokenId) internal isWhitelisted(_tokenId) returns (uint32 count) {
    require(_sender != address(0), "update from address 0");
    require(IERC1155(osContract).balanceOf(address(this), _tokenId) > 0, "not os");

    senders.push(_sender);
    idsBridged.push(_tokenId);
    totalBridged++;
    return totalBridged;
  }

  /**
   * @dev update params once we receive a transfer 721
   * the sender can not be address(0) and tokenId needs to be allowed
   */
  function onReceiveTransfer721(address _sender, uint256 _tokenId) internal isNewTokenWhitelisted(_tokenId) {
    for (uint120 i; i < idsBridged.length; i++) {
      if (idsBridged[i] == _tokenId) delete idsBridged[i];
    }

    for (uint120 i; i < senders.length; i++) {
      if (senders[i] == _sender) delete senders[i];
    }

    IERC1155(osContract).safeTransferFrom(address(this), _sender, newOldIds[uint16(_tokenId)], 1, "");
  }

  /**
   * @dev only the owner can add whitelisted ids
   */
  function addToWhitelist(uint256 _tokenId, uint16 _newTokenId) public onlyOwner {
    whitelisted.push(_tokenId);
    newTokenIds.push(_newTokenId);
    // oldNewIds[_tokenId] = _newTokenId;
    // newOldIds[_newTokenId] = _tokenId;
  }

  /**
   * @dev transfers the ownership of 721
   */
  function transferOwnershipOf721(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "owner != address 0");
    BearsDeluxeI(bdContract).transferOwnership(_newOwner);
  }

  /**
   * @dev minting 721 to the owner
   */
  function _mint721(uint256 _tokenId, address _owner) private {
    BearsDeluxeI(bdContract).mint(_owner, _tokenId);
    emit Minted721(_owner, _tokenId);
  }

  /**
   * @dev transfer BD 721 from bridge
   */
  function transfer721(uint256 _tokenId, address _owner) external onlyOwner nonReentrant isNewTokenWhitelisted(_tokenId) {
    require(_owner != address(0), "can not send to address 0");
    BearsDeluxeI(bdContract).safeTransferFrom(address(this), _owner, _tokenId);
  }

  /**
   * @dev transfer BD 1155 from bridge
   */
  function transfer1155(uint256 _tokenId, address _owner) external onlyOwner nonReentrant isWhitelisted(_tokenId) {
    require(_owner != address(0), "can not send to address 0");
    IERC1155(osContract).safeTransferFrom(address(this), _owner, _tokenId, 1, "");
  }

  /**
   * @dev get total transfer count
   */
  function getTokenBridgedCount() public view returns (uint128) {
    return totalBridged;
  }

  function getOwnersWhoBridged() public view returns (address[] memory) {
    return senders;
  }

  /**
   * @dev get ids of tokens that were transfered
   */
  function getIdsTransfered() public view returns (uint256[] memory) {
    return idsBridged;
  }

  /**
   * @dev check if it's whitelisted id
   */
  modifier isWhitelisted(uint256 _tokenId) {
    bool inWhitelisted = false;
    for (uint128 i = 0; i < whitelisted.length; i++) {
      if (whitelisted[i] == _tokenId) {
        inWhitelisted = true;
        break;
      }
    }
    require(inWhitelisted, "tokenId !whitelisted");
    _;
  }

  /**
   * @dev checks if it's part of the new whitelisted ids
   */
  modifier isNewTokenWhitelisted(uint256 _tokenId) {
    bool inWhitelisted = false;

    for (uint128 i = 0; i < newTokenIds.length; i++) {
      if (newTokenIds[i] == _tokenId) {
        inWhitelisted = true;
        break;
      }
    }
    require(inWhitelisted, "newTokenId !whitelisted");
    _;
  }

  function init() private {
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009812667154563073, 1);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009813766666190849, 2);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009814866177818625, 3);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009815965689446401, 4);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009817065201074177, 5);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009818164712701953, 6);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009819264224329729, 7);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009820363735957505, 8);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009821463247585281, 9);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009822562759213057, 10);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009823662270840833, 11);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009824761782468609, 12);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009825861294096385, 13);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009826960805724161, 14);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009828060317351937, 15);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009829159828979713, 16);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009830259340607489, 17);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009831358852235265, 18);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009832458363863041, 19);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009833557875490817, 20);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009834657387118593, 21);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009835756898746369, 22);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009836856410374145, 23);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009837955922001921, 24);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009839055433629697, 25);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009840154945257473, 26);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009841254456885249, 27);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009842353968513025, 28);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009843453480140801, 29);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009844552991768577, 30);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009845652503396353, 31);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009846752015024129, 32);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009847851526651905, 33);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009848951038279681, 34);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009850050549907457, 35);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009851150061535233, 36);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009852249573163009, 37);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009853349084790785, 38);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009854448596418561, 39);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009855548108046337, 40);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009856647619674113, 41);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009857747131301889, 42);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009858846642929665, 43);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009859946154557441, 44);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009861045666185217, 45);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009862145177812993, 46);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009863244689440769, 47);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009864344201068545, 48);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009865443712696321, 49);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009866543224324097, 50);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009867642735951873, 51);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009868742247579649, 52);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009869841759207425, 53);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009870941270835201, 54);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009872040782462977, 55);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009873140294090753, 56);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009874239805718529, 57);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009875339317346305, 58);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009876438828974081, 59);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009877538340601857, 60);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009878637852229633, 61);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009879737363857409, 62);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009880836875485185, 63);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009881936387112961, 64);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009883035898740737, 65);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009884135410368513, 66);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009885234921996289, 67);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009886334433624065, 68);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009887433945251841, 69);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009888533456879617, 70);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009889632968507393, 71);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009890732480135169, 72);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009891831991762945, 73);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009892931503390721, 74);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009894031015018497, 75);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009895130526646273, 76);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009896230038274049, 77);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009897329549901825, 78);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009898429061529601, 79);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009899528573157377, 80);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009900628084785153, 81);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009901727596412929, 82);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009902827108040705, 83);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009903926619668481, 84);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009905026131296257, 85);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009906125642924033, 86);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009907225154551809, 87);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009908324666179585, 88);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009909424177807361, 89);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009910523689435137, 90);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009911623201062913, 91);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009913822224318465, 92);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009914921735946241, 93);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009916021247574017, 94);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009917120759201793, 95);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009918220270829569, 96);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009919319782457345, 97);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009920419294085121, 98);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009921518805712897, 99);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009922618317340673, 100);
  }

  function addAnother() external onlyOwner {
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009923717828968449, 101);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009924817340596225, 102);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009925916852224001, 103);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009927016363851777, 104);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009928115875479553, 105);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009929215387107329, 106);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009930314898735105, 107);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009931414410362881, 108);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009932513921990657, 109);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009933613433618433, 110);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009934712945246209, 111);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009935812456873985, 112);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009936911968501761, 113);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009938011480129537, 114);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009939110991757313, 115);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009940210503385089, 116);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009941310015012865, 117);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009942409526640641, 118);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009943509038268417, 119);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009944608549896193, 120);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009945708061523969, 121);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009946807573151745, 122);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009947907084779521, 123);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009949006596407297, 124);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009950106108035073, 125);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009951205619662849, 126);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009952305131290625, 127);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009953404642918401, 128);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009954504154546177, 129);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009955603666173953, 130);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009956703177801729, 131);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009957802689429505, 132);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009958902201057281, 133);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009960001712685057, 134);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009961101224312833, 135);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009962200735940609, 136);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009963300247568385, 137);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009964399759196161, 138);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009965499270823937, 139);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009966598782451713, 140);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009967698294079489, 141);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009968797805707265, 142);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009969897317335041, 143);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009970996828962817, 144);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009972096340590593, 145);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009973195852218369, 146);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009974295363846145, 147);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009975394875473921, 148);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009976494387101697, 149);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009977593898729473, 150);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009978693410357249, 151);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009979792921985025, 152);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009980892433612801, 153);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009981991945240577, 154);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009983091456868353, 155);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009984190968496129, 156);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009985290480123905, 157);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009986389991751681, 158);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009987489503379457, 159);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009988589015007233, 160);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009989688526635009, 161);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009990788038262785, 162);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009991887549890561, 163);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009992987061518337, 164);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009994086573146113, 165);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009995186084773889, 166);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009996285596401665, 167);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009997385108029441, 168);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009998484619657217, 169);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045009999584131284993, 170);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010000683642912769, 171);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010001783154540545, 172);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010002882666168321, 173);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010003982177796097, 174);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010005081689423873, 175);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010006181201051649, 176);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010007280712679425, 177);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010008380224307201, 178);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010009479735934977, 179);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010010579247562753, 180);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010011678759190529, 181);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010012778270818305, 182);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010013877782446081, 183);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010014977294073857, 184);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010016076805701633, 185);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010017176317329409, 186);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010018275828957185, 187);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010019375340584961, 188);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010020474852212737, 189);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010021574363840513, 190);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010022673875468289, 191);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010023773387096065, 192);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010024872898723841, 193);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010025972410351617, 194);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010027071921979393, 195);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010028171433607169, 196);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010029270945234945, 197);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010030370456862721, 198);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010031469968490497, 199);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010032569480118273, 200);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010033668991746049, 201);
    addToWhitelist(63389814796431140271882538879984655106744147143831287279045010034768503373825, 202);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract BearsDeluxeI is Ownable, IERC721 {
  function mint(address _owner, uint256 _tokenId) public virtual;

  function exists(uint256 _tokenId) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}