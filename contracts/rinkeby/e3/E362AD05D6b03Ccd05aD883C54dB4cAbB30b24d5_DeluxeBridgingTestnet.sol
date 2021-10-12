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

  uint56[] private whitelisted;

  // ids that can be minted
  uint16[] private newTokenIds;
  // 1155 tokens mapped to 721 tokens
  mapping(uint56 => uint16) private oldNewIds;
  // 721 tokens mapped to 1155 tokens
  mapping(uint16 => uint56) private newOldIds;

  address private immutable osContract;
  address private bdContract = 0x0000000000000000000000000000000000000000;

  event ReceivedFromOS(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId, uint256 _amount);

  event ReceivedFrom721(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId);

  event Minted721(address indexed _sender, uint256 indexed _tokenId);

  constructor(address _osContract) onlyOwner {
    osContract = _osContract;
  }

  /**
   * @dev when receive a deluxe from OS, it mints a 721
   */
  function mintOnReceiving(address _sender, uint256 _tokenId) internal isWhitelisted(_tokenId) returns (bool) {
    require(_sender != address(0), "can not mint to address 0");

    uint256 newTokenId = oldNewIds[transformOldId(_tokenId)];

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
    uint56 oldId = transformOldId(_tokenId);

    whitelisted.push(oldId);
    newTokenIds.push(_newTokenId);
    oldNewIds[oldId] = _newTokenId;
    newOldIds[_newTokenId] = oldId;
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

  function transformOldId(uint256 _oldId) private pure returns (uint56) {
    return uint56(_oldId / 1e14);
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

  function init() private{
    addToWhitelist(5009812667154563073,1);
addToWhitelist(5009813766666190849,2);
addToWhitelist(5009814866177818625,3);
addToWhitelist(5009815965689446401,4);
addToWhitelist(5009817065201074177,5);
addToWhitelist(5009818164712701953,6);
addToWhitelist(5009819264224329729,7);
addToWhitelist(5009820363735957505,8);
addToWhitelist(5009821463247585281,9);
addToWhitelist(5009822562759213057,10);
addToWhitelist(5009823662270840833,11);
addToWhitelist(5009824761782468609,12);
addToWhitelist(5009825861294096385,13);
addToWhitelist(5009826960805724161,14);
addToWhitelist(5009828060317351937,15);
addToWhitelist(5009829159828979713,16);
addToWhitelist(5009830259340607489,17);
addToWhitelist(5009831358852235265,18);
addToWhitelist(5009832458363863041,19);
addToWhitelist(5009833557875490817,20);
addToWhitelist(5009834657387118593,21);
addToWhitelist(5009835756898746369,22);
addToWhitelist(5009836856410374145,23);
addToWhitelist(5009837955922001921,24);
addToWhitelist(5009839055433629697,25);
addToWhitelist(5009840154945257473,26);
addToWhitelist(5009841254456885249,27);
addToWhitelist(5009842353968513025,28);
addToWhitelist(5009843453480140801,29);
addToWhitelist(5009844552991768577,30);
addToWhitelist(5009845652503396353,31);
addToWhitelist(5009846752015024129,32);
addToWhitelist(5009847851526651905,33);
addToWhitelist(5009848951038279681,34);
addToWhitelist(5009850050549907457,35);
addToWhitelist(5009851150061535233,36);
addToWhitelist(5009852249573163009,37);
addToWhitelist(5009853349084790785,38);
addToWhitelist(5009854448596418561,39);
addToWhitelist(5009855548108046337,40);
addToWhitelist(5009856647619674113,41);
addToWhitelist(5009857747131301889,42);
addToWhitelist(5009858846642929665,43);
addToWhitelist(5009859946154557441,44);
addToWhitelist(5009861045666185217,45);
addToWhitelist(5009862145177812993,46);
addToWhitelist(5009863244689440769,47);
addToWhitelist(5009864344201068545,48);
addToWhitelist(5009865443712696321,49);
addToWhitelist(5009866543224324097,50);
addToWhitelist(5009867642735951873,51);
addToWhitelist(5009868742247579649,52);
addToWhitelist(5009869841759207425,53);
addToWhitelist(5009870941270835201,54);
addToWhitelist(5009872040782462977,55);
addToWhitelist(5009873140294090753,56);
addToWhitelist(5009874239805718529,57);
addToWhitelist(5009875339317346305,58);
addToWhitelist(5009876438828974081,59);
addToWhitelist(5009877538340601857,60);
addToWhitelist(5009878637852229633,61);
addToWhitelist(5009879737363857409,62);
addToWhitelist(5009880836875485185,63);
addToWhitelist(5009881936387112961,64);
addToWhitelist(5009883035898740737,65);
addToWhitelist(5009884135410368513,66);
addToWhitelist(5009885234921996289,67);
addToWhitelist(5009886334433624065,68);
addToWhitelist(5009887433945251841,69);
addToWhitelist(5009888533456879617,70);
addToWhitelist(5009889632968507393,71);
addToWhitelist(5009890732480135169,72);
addToWhitelist(5009891831991762945,73);
addToWhitelist(5009892931503390721,74);
addToWhitelist(5009894031015018497,75);
addToWhitelist(5009895130526646273,76);
addToWhitelist(5009896230038274049,77);
addToWhitelist(5009897329549901825,78);
addToWhitelist(5009898429061529601,79);
addToWhitelist(5009899528573157377,80);
addToWhitelist(5009900628084785153,81);
addToWhitelist(5009901727596412929,82);
addToWhitelist(5009902827108040705,83);
addToWhitelist(5009903926619668481,84);
addToWhitelist(5009905026131296257,85);
addToWhitelist(5009906125642924033,86);
addToWhitelist(5009907225154551809,87);
addToWhitelist(5009908324666179585,88);
addToWhitelist(5009909424177807361,89);
addToWhitelist(5009910523689435137,90);
addToWhitelist(5009911623201062913,91);
addToWhitelist(5009913822224318465,92);
addToWhitelist(5009914921735946241,93);
addToWhitelist(5009916021247574017,94);
addToWhitelist(5009917120759201793,95);
addToWhitelist(5009918220270829569,96);
addToWhitelist(5009919319782457345,97);
addToWhitelist(5009920419294085121,98);
addToWhitelist(5009921518805712897,99);
addToWhitelist(5009922618317340673,100);
addToWhitelist(5009923717828968449,101);
addToWhitelist(5009924817340596225,102);
addToWhitelist(5009925916852224001,103);
addToWhitelist(5009927016363851777,104);
addToWhitelist(5009928115875479553,105);
addToWhitelist(5009929215387107329,106);
addToWhitelist(5009930314898735105,107);
addToWhitelist(5009931414410362881,108);
addToWhitelist(5009932513921990657,109);
addToWhitelist(5009933613433618433,110);
addToWhitelist(5009934712945246209,111);
addToWhitelist(5009935812456873985,112);
addToWhitelist(5009936911968501761,113);
addToWhitelist(5009938011480129537,114);
addToWhitelist(5009939110991757313,115);
addToWhitelist(5009940210503385089,116);
addToWhitelist(5009941310015012865,117);
addToWhitelist(5009942409526640641,118);
addToWhitelist(5009943509038268417,119);
addToWhitelist(5009944608549896193,120);
addToWhitelist(5009945708061523969,121);
addToWhitelist(5009946807573151745,122);
addToWhitelist(5009947907084779521,123);
addToWhitelist(5009949006596407297,124);
addToWhitelist(5009950106108035073,125);
addToWhitelist(5009951205619662849,126);
addToWhitelist(5009952305131290625,127);
addToWhitelist(5009953404642918401,128);
addToWhitelist(5009954504154546177,129);
addToWhitelist(5009955603666173953,130);
addToWhitelist(5009956703177801729,131);
addToWhitelist(5009957802689429505,132);
addToWhitelist(5009958902201057281,133);
addToWhitelist(5009960001712685057,134);
addToWhitelist(5009961101224312833,135);
addToWhitelist(5009962200735940609,136);
addToWhitelist(5009963300247568385,137);
addToWhitelist(5009964399759196161,138);
addToWhitelist(5009965499270823937,139);
addToWhitelist(5009966598782451713,140);
addToWhitelist(5009967698294079489,141);
addToWhitelist(5009968797805707265,142);
addToWhitelist(5009969897317335041,143);
addToWhitelist(5009970996828962817,144);
addToWhitelist(5009972096340590593,145);
addToWhitelist(5009973195852218369,146);
addToWhitelist(5009974295363846145,147);
addToWhitelist(5009975394875473921,148);
addToWhitelist(5009976494387101697,149);
addToWhitelist(5009977593898729473,150);
addToWhitelist(5009978693410357249,151);
addToWhitelist(5009979792921985025,152);
addToWhitelist(5009980892433612801,153);
addToWhitelist(5009981991945240577,154);
addToWhitelist(5009983091456868353,155);
addToWhitelist(5009984190968496129,156);
addToWhitelist(5009985290480123905,157);
addToWhitelist(5009986389991751681,158);
addToWhitelist(5009987489503379457,159);
addToWhitelist(5009988589015007233,160);
addToWhitelist(5009989688526635009,161);
addToWhitelist(5009990788038262785,162);
addToWhitelist(5009991887549890561,163);
addToWhitelist(5009992987061518337,164);
addToWhitelist(5009994086573146113,165);
addToWhitelist(5009995186084773889,166);
addToWhitelist(5009996285596401665,167);
addToWhitelist(5009997385108029441,168);
addToWhitelist(5009998484619657217,169);
addToWhitelist(5009999584131284993,170);
addToWhitelist(5010000683642912769,171);
addToWhitelist(5010001783154540545,172);
addToWhitelist(5010002882666168321,173);
addToWhitelist(5010003982177796097,174);
addToWhitelist(5010005081689423873,175);
addToWhitelist(5010006181201051649,176);
addToWhitelist(5010007280712679425,177);
addToWhitelist(5010008380224307201,178);
addToWhitelist(5010009479735934977,179);
addToWhitelist(5010010579247562753,180);
addToWhitelist(5010011678759190529,181);
addToWhitelist(5010012778270818305,182);
addToWhitelist(5010013877782446081,183);
addToWhitelist(5010014977294073857,184);
addToWhitelist(5010016076805701633,185);
addToWhitelist(5010017176317329409,186);
addToWhitelist(5010018275828957185,187);
addToWhitelist(5010019375340584961,188);
addToWhitelist(5010020474852212737,189);
addToWhitelist(5010021574363840513,190);
addToWhitelist(5010022673875468289,191);
addToWhitelist(5010023773387096065,192);
addToWhitelist(5010024872898723841,193);
addToWhitelist(5010025972410351617,194);
addToWhitelist(5010027071921979393,195);
addToWhitelist(5010028171433607169,196);
addToWhitelist(5010029270945234945,197);
addToWhitelist(5010030370456862721,198);
addToWhitelist(5010031469968490497,199);
addToWhitelist(5010032569480118273,200);
addToWhitelist(5010033668991746049,201);
addToWhitelist(5010034768503373825,202);
addToWhitelist(5010035868015001601,203);
addToWhitelist(5010036967526629377,204);
addToWhitelist(5010038067038257153,205);
addToWhitelist(5010039166549884929,206);
addToWhitelist(5010040266061512705,207);
addToWhitelist(5010041365573140481,208);
addToWhitelist(5010042465084768257,209);
addToWhitelist(5010043564596396033,210);
addToWhitelist(5010044664108023809,211);
addToWhitelist(5010045763619651585,212);
addToWhitelist(5010046863131279361,213);
addToWhitelist(5010047962642907137,214);
addToWhitelist(5010049062154534913,215);
addToWhitelist(5010050161666162689,216);
addToWhitelist(5010051261177790465,217);
addToWhitelist(5010052360689418241,218);
addToWhitelist(5010053460201046017,219);
addToWhitelist(5010054559712673793,220);
addToWhitelist(5010055659224301569,221);
addToWhitelist(5010056758735929345,222);
addToWhitelist(5010057858247557121,223);
addToWhitelist(5010058957759184897,224);
addToWhitelist(5010060057270812673,225);
addToWhitelist(5010061156782440449,226);
addToWhitelist(5010062256294068225,227);
addToWhitelist(5010063355805696001,228);
addToWhitelist(5010064455317323777,229);
addToWhitelist(5010065554828951553,230);
addToWhitelist(5010066654340579329,231);
addToWhitelist(5010067753852207105,232);
addToWhitelist(5010068853363834881,233);
addToWhitelist(5010069952875462657,234);
addToWhitelist(5010071052387090433,235);
addToWhitelist(5010072151898718209,236);
addToWhitelist(5010073251410345985,237);
addToWhitelist(5010074350921973761,238);
addToWhitelist(5010075450433601537,239);
addToWhitelist(5010076549945229313,240);
addToWhitelist(5010077649456857089,241);
addToWhitelist(5010078748968484865,242);
addToWhitelist(5010079848480112641,243);
addToWhitelist(5010080947991740417,244);
addToWhitelist(5010082047503368193,245);
addToWhitelist(5010083147014995969,246);
addToWhitelist(5010084246526623745,247);
addToWhitelist(5010085346038251521,248);
addToWhitelist(5010086445549879297,249);
addToWhitelist(5010087545061507073,250);
addToWhitelist(5010088644573134849,251);
addToWhitelist(5010089744084762625,252);
addToWhitelist(5010090843596390401,253);
addToWhitelist(5010091943108018177,254);
addToWhitelist(5010093042619645953,255);
addToWhitelist(5010094142131273729,256);
addToWhitelist(5010095241642901505,257);
addToWhitelist(5010096341154529281,258);
addToWhitelist(5010097440666157057,259);
addToWhitelist(5010098540177784833,260);
addToWhitelist(5010099639689412609,261);
addToWhitelist(5010100739201040385,262);
addToWhitelist(5010101838712668161,263);
addToWhitelist(5010102938224295937,264);
addToWhitelist(5010104037735923713,265);
addToWhitelist(5010105137247551489,266);
addToWhitelist(5010106236759179265,267);
addToWhitelist(5010107336270807041,268);
addToWhitelist(5010108435782434817,269);
addToWhitelist(5010109535294062593,270);
addToWhitelist(5010110634805690369,271);
addToWhitelist(5010111734317318145,272);
addToWhitelist(5010112833828945921,273);
addToWhitelist(5010113933340573697,274);
addToWhitelist(5010115032852201473,275);
addToWhitelist(5010116132363829249,276);
addToWhitelist(5010117231875457025,277);
addToWhitelist(5010118331387084801,278);
addToWhitelist(5010119430898712577,279);
addToWhitelist(5010120530410340353,280);
addToWhitelist(5010121629921968129,281);
addToWhitelist(5010122729433595905,282);
addToWhitelist(5010123828945223681,283);
addToWhitelist(5010124928456851457,284);
addToWhitelist(5010126027968479233,285);
addToWhitelist(5010127127480107009,286);
addToWhitelist(5010128226991734785,287);
addToWhitelist(5010129326503362561,288);
addToWhitelist(5010130426014990337,289);
addToWhitelist(5010131525526618113,290);
addToWhitelist(5010132625038245889,291);
addToWhitelist(5010133724549873665,292);
addToWhitelist(5010134824061501441,293);
addToWhitelist(5010135923573129217,294);
addToWhitelist(5010137023084756993,295);
addToWhitelist(5010138122596384769,296);
addToWhitelist(5010139222108012545,297);
addToWhitelist(5010140321619640321,298);
addToWhitelist(5010141421131268097,299);
addToWhitelist(5010142520642895873,300);
addToWhitelist(5010143620154523649,301);
addToWhitelist(5010144719666151425,302);
addToWhitelist(5010145819177779201,303);
addToWhitelist(5010146918689406977,304);
addToWhitelist(5010148018201034753,305);
addToWhitelist(5010149117712662529,306);
addToWhitelist(5010150217224290305,307);
addToWhitelist(5010151316735918081,308);
addToWhitelist(5010152416247545857,309);
addToWhitelist(5010153515759173633,310);
addToWhitelist(5010154615270801409,311);
addToWhitelist(5010155714782429185,312);
addToWhitelist(5010156814294056961,313);
addToWhitelist(5010157913805684737,314);
addToWhitelist(5010159013317312513,315);
addToWhitelist(5010160112828940289,316);
addToWhitelist(5010161212340568065,317);
addToWhitelist(5010162311852195841,318);
addToWhitelist(5010163411363823617,319);
addToWhitelist(5010164510875451393,320);
addToWhitelist(5010165610387079169,321);
addToWhitelist(5010166709898706945,322);
addToWhitelist(5010167809410334721,323);
addToWhitelist(5010168908921962497,324);
addToWhitelist(5010170008433590273,325);
addToWhitelist(5010171107945218049,326);
addToWhitelist(5010172207456845825,327);
addToWhitelist(5010173306968473601,328);
addToWhitelist(5010174406480101377,329);
addToWhitelist(5010175505991729153,330);
addToWhitelist(5010176605503356929,331);
addToWhitelist(5010177705014984705,332);
addToWhitelist(5010178804526612481,333);
addToWhitelist(5010179904038240257,334);
addToWhitelist(5010181003549868033,335);
addToWhitelist(5010182103061495809,336);
addToWhitelist(5010183202573123585,337);
addToWhitelist(5010184302084751361,338);
addToWhitelist(5010185401596379137,339);
addToWhitelist(5010186501108006913,340);
addToWhitelist(5010187600619634689,341);
addToWhitelist(5010188700131262465,342);
addToWhitelist(5010189799642890241,343);
addToWhitelist(5010190899154518017,344);
addToWhitelist(5010191998666145793,345);
addToWhitelist(5010193098177773569,346);
addToWhitelist(5010194197689401345,347);
addToWhitelist(5010195297201029121,348);
addToWhitelist(5010196396712656897,349);
addToWhitelist(5010197496224284673,350);
addToWhitelist(5010198595735912449,351);
addToWhitelist(5010199695247540225,352);
addToWhitelist(5010200794759168001,353);
addToWhitelist(5010201894270795777,354);
addToWhitelist(5010202993782423553,355);
addToWhitelist(5010204093294051329,356);
addToWhitelist(5010205192805679105,357);
addToWhitelist(5010206292317306881,358);
addToWhitelist(5010207391828934657,359);
addToWhitelist(5010208491340562433,360);
addToWhitelist(5010209590852190209,361);
addToWhitelist(5010210690363817985,362);
addToWhitelist(5010211789875445761,363);
addToWhitelist(5010212889387073537,364);
addToWhitelist(5010213988898701313,365);
addToWhitelist(5010215088410329089,366);
addToWhitelist(5010216187921956865,367);
addToWhitelist(5010217287433584641,368);
addToWhitelist(5010218386945212417,369);
addToWhitelist(5010219486456840193,370);
addToWhitelist(5010220585968467969,371);
addToWhitelist(5010221685480095745,372);
addToWhitelist(5010222784991723521,373);
addToWhitelist(5010223884503351297,374);
addToWhitelist(5010224984014979073,375);
addToWhitelist(5010226083526606849,376);
addToWhitelist(5010227183038234625,377);
addToWhitelist(5010228282549862401,378);
addToWhitelist(5010229382061490177,379);
addToWhitelist(5010230481573117953,380);
addToWhitelist(5010231581084745729,381);
addToWhitelist(5010232680596373505,382);
addToWhitelist(5010233780108001281,383);
addToWhitelist(5010234879619629057,384);
addToWhitelist(5010235979131256833,385);
addToWhitelist(5010237078642884609,386);
addToWhitelist(5010238178154512385,387);
addToWhitelist(5010239277666140161,388);
addToWhitelist(5010240377177767937,389);
addToWhitelist(5010241476689395713,390);
addToWhitelist(5010242576201023489,391);
addToWhitelist(5010243675712651265,392);
addToWhitelist(5010244775224279041,393);
addToWhitelist(5010245874735906817,394);
addToWhitelist(5010246974247534593,395);
addToWhitelist(5010248073759162369,396);
addToWhitelist(5010249173270790145,397);
addToWhitelist(5010250272782417921,398);
addToWhitelist(5010251372294045697,399);
addToWhitelist(5010252471805673473,400);
addToWhitelist(5010253571317301249,401);
addToWhitelist(5010254670828929025,402);
addToWhitelist(5010255770340556801,403);
addToWhitelist(5010256869852184577,404);
addToWhitelist(5010257969363812353,405);
addToWhitelist(5010259068875440129,406);
addToWhitelist(5010260168387067905,407);
addToWhitelist(5010261267898695681,408);
addToWhitelist(5010262367410323457,409);
addToWhitelist(5010263466921951233,410);
addToWhitelist(5010264566433579009,411);
addToWhitelist(5010265665945206785,412);
addToWhitelist(5010266765456834561,413);
addToWhitelist(5010267864968462337,414);
addToWhitelist(5010268964480090113,415);
addToWhitelist(5010270063991717889,416);
addToWhitelist(5010271163503345665,417);
addToWhitelist(5010272263014973441,418);
addToWhitelist(5010273362526601217,419);
addToWhitelist(5010274462038228993,420);
addToWhitelist(5010275561549856769,421);
addToWhitelist(5010276661061484545,422);
addToWhitelist(5010277760573112321,423);
addToWhitelist(5010278860084740097,424);
addToWhitelist(5010279959596367873,425);
addToWhitelist(5010281059107995649,426);
addToWhitelist(5010282158619623425,427);
addToWhitelist(5010283258131251201,428);
addToWhitelist(5010284357642878977,429);
addToWhitelist(5010285457154506753,430);
addToWhitelist(5010286556666134529,431);
addToWhitelist(5010287656177762305,432);
addToWhitelist(5010288755689390081,433);
addToWhitelist(5010289855201017857,434);
addToWhitelist(5010290954712645633,435);
addToWhitelist(5010292054224273409,436);
addToWhitelist(5010293153735901185,437);
addToWhitelist(5010294253247528961,438);
addToWhitelist(5010295352759156737,439);
addToWhitelist(5010296452270784513,440);
addToWhitelist(5010297551782412289,441);
addToWhitelist(5010298651294040065,442);
addToWhitelist(5010299750805667841,443);
addToWhitelist(5010300850317295617,444);
addToWhitelist(5010301949828923393,445);
addToWhitelist(5010303049340551169,446);
addToWhitelist(5010304148852178945,447);
addToWhitelist(5010305248363806721,448);
addToWhitelist(5010306347875434497,449);
addToWhitelist(5010307447387062273,450);
addToWhitelist(5010308546898690049,451);
addToWhitelist(5010309646410317825,452);
addToWhitelist(5010310745921945601,453);
addToWhitelist(5010311845433573377,454);
addToWhitelist(5010312944945201153,455);
addToWhitelist(5010314044456828929,456);
addToWhitelist(5010315143968456705,457);
addToWhitelist(5010316243480084481,458);
addToWhitelist(5010317342991712257,459);
addToWhitelist(5010318442503340033,460);
addToWhitelist(5010319542014967809,461);
addToWhitelist(5010320641526595585,462);
addToWhitelist(5010321741038223361,463);
addToWhitelist(5010322840549851137,464);
addToWhitelist(5010323940061478913,465);
addToWhitelist(5010325039573106689,466);
addToWhitelist(5010326139084734465,467);
addToWhitelist(5010327238596362241,468);
addToWhitelist(5010328338107990017,469);
addToWhitelist(5010329437619617793,470);
addToWhitelist(5010330537131245569,471);
addToWhitelist(5010331636642873345,472);
addToWhitelist(5010332736154501121,473);
addToWhitelist(5010333835666128897,474);
addToWhitelist(5010334935177756673,475);
addToWhitelist(5010336034689384449,476);
addToWhitelist(5010337134201012225,477);
addToWhitelist(5010338233712640001,478);
addToWhitelist(5010339333224267777,479);
addToWhitelist(5010340432735895553,480);
addToWhitelist(5010341532247523329,481);
addToWhitelist(5010342631759151105,482);
addToWhitelist(5010343731270778881,483);
addToWhitelist(5010344830782406657,484);
addToWhitelist(5010345930294034433,485);
addToWhitelist(5010347029805662209,486);
addToWhitelist(5010348129317289985,487);
addToWhitelist(5010349228828917761,488);
addToWhitelist(5010350328340545537,489);
addToWhitelist(5010351427852173313,490);
addToWhitelist(5010352527363801089,491);
addToWhitelist(5010353626875428865,492);
addToWhitelist(5010354726387056641,493);
addToWhitelist(5010355825898684417,494);
addToWhitelist(5010356925410312193,495);
addToWhitelist(5010358024921939969,496);
addToWhitelist(5010359124433567745,497);
addToWhitelist(5010360223945195521,498);
addToWhitelist(5010361323456823297,499);
addToWhitelist(5010362422968451073,500);
addToWhitelist(5010363522480078849,501);
addToWhitelist(5010364621991706625,502);
addToWhitelist(5010365721503334401,503);
addToWhitelist(5010366821014962177,504);
addToWhitelist(5010367920526589953,505);
addToWhitelist(5010369020038217729,506);
addToWhitelist(5010370119549845505,507);
addToWhitelist(5010371219061473281,508);
addToWhitelist(5010372318573101057,509);
addToWhitelist(5010373418084728833,510);
addToWhitelist(5010374517596356609,511);
addToWhitelist(5010375617107984385,512);
addToWhitelist(5010376716619612161,513);
addToWhitelist(5010377816131239937,514);
addToWhitelist(5010378915642867713,515);
addToWhitelist(5010380015154495489,516);
addToWhitelist(5010381114666123265,517);
addToWhitelist(5010382214177751041,518);
addToWhitelist(5010383313689378817,519);
addToWhitelist(5010384413201006593,520);
addToWhitelist(5010385512712634369,521);
addToWhitelist(5010386612224262145,522);
addToWhitelist(5010387711735889921,523);
addToWhitelist(5010388811247517697,524);
addToWhitelist(5010389910759145473,525);
addToWhitelist(5010391010270773249,526);
addToWhitelist(5010392109782401025,527);
addToWhitelist(5010393209294028801,528);
addToWhitelist(5010394308805656577,529);
addToWhitelist(5010395408317284353,530);
addToWhitelist(5010396507828912129,531);
addToWhitelist(5010397607340539905,532);
addToWhitelist(5010398706852167681,533);
addToWhitelist(5010399806363795457,534);
addToWhitelist(5010400905875423233,535);
addToWhitelist(5010402005387051009,536);
addToWhitelist(5010403104898678785,537);
addToWhitelist(5010404204410306561,538);
addToWhitelist(5010405303921934337,539);
addToWhitelist(5010406403433562113,540);
addToWhitelist(5010407502945189889,541);
addToWhitelist(5010408602456817665,542);
addToWhitelist(5010409701968445441,543);
addToWhitelist(5010410801480073217,544);
addToWhitelist(5010411900991700993,545);
addToWhitelist(5010413000503328769,546);
addToWhitelist(5010414100014956545,547);
addToWhitelist(5010415199526584321,548);
addToWhitelist(5010416299038212097,549);
addToWhitelist(5010417398549839873,550);
addToWhitelist(5010418498061467649,551);
addToWhitelist(5010419597573095425,552);
addToWhitelist(5010420697084723201,553);
addToWhitelist(5010421796596350977,554);
addToWhitelist(5010422896107978753,555);
addToWhitelist(5010423995619606529,556);
addToWhitelist(5010425095131234305,557);
addToWhitelist(5010426194642862081,558);
addToWhitelist(5010427294154489857,559);
addToWhitelist(5010428393666117633,560);
addToWhitelist(5010429493177745409,561);
addToWhitelist(5010430592689373185,562);
addToWhitelist(5010431692201000961,563);
addToWhitelist(5010432791712628737,564);
addToWhitelist(5010433891224256513,565);
addToWhitelist(5010434990735884289,566);
addToWhitelist(5010436090247512065,567);
addToWhitelist(5010437189759139841,568);
addToWhitelist(5010438289270767617,569);
addToWhitelist(5010439388782395393,570);
addToWhitelist(5010440488294023169,571);
addToWhitelist(5010441587805650945,572);
addToWhitelist(5010442687317278721,573);
addToWhitelist(5010443786828906497,574);
addToWhitelist(5010444886340534273,575);
addToWhitelist(5010445985852162049,576);
addToWhitelist(5010447085363789825,577);
addToWhitelist(5010448184875417601,578);
addToWhitelist(5010449284387045377,579);
addToWhitelist(5010450383898673153,580);
addToWhitelist(5010451483410300929,581);
addToWhitelist(5010452582921928705,582);
addToWhitelist(5010453682433556481,583);
addToWhitelist(5010454781945184257,584);
addToWhitelist(5010455881456812033,585);
addToWhitelist(5010456980968439809,586);
addToWhitelist(5010458080480067585,587);
addToWhitelist(5010459179991695361,588);
addToWhitelist(5010460279503323137,589);
addToWhitelist(5010461379014950913,590);
addToWhitelist(5010462478526578689,591);
addToWhitelist(5010463578038206465,592);
addToWhitelist(5010464677549834241,593);
addToWhitelist(5010465777061462017,594);
addToWhitelist(5010466876573089793,595);
addToWhitelist(5010467976084717569,596);
addToWhitelist(5010469075596345345,597);
addToWhitelist(5010470175107973121,598);
addToWhitelist(5010471274619600897,599);
addToWhitelist(5010472374131228673,600);
addToWhitelist(5010473473642856449,601);
addToWhitelist(5010474573154484225,602);
addToWhitelist(5010475672666112001,603);
addToWhitelist(5010476772177739777,604);
addToWhitelist(5010477871689367553,605);
addToWhitelist(5010478971200995329,606);
addToWhitelist(5010480070712623105,607);
addToWhitelist(5010481170224250881,608);
addToWhitelist(5010482269735878657,609);
addToWhitelist(5010483369247506433,610);
addToWhitelist(5010484468759134209,611);
addToWhitelist(5010485568270761985,612);
addToWhitelist(5010486667782389761,613);
addToWhitelist(5010487767294017537,614);
addToWhitelist(5010488866805645313,615);
addToWhitelist(5010489966317273089,616);
addToWhitelist(5010491065828900865,617);
addToWhitelist(5010492165340528641,618);
addToWhitelist(5010493264852156417,619);
addToWhitelist(5010494364363784193,620);
addToWhitelist(5010495463875411969,621);
addToWhitelist(5010496563387039745,622);
addToWhitelist(5010497662898667521,623);
addToWhitelist(5010498762410295297,624);
addToWhitelist(5010499861921923073,625);
addToWhitelist(5010500961433550849,626);
addToWhitelist(5010502060945178625,627);
addToWhitelist(5010503160456806401,628);
addToWhitelist(5010504259968434177,629);
addToWhitelist(5010505359480061953,630);
addToWhitelist(5010506458991689729,631);
addToWhitelist(5010507558503317505,632);
addToWhitelist(5010508658014945281,633);
addToWhitelist(5010509757526573057,634);
addToWhitelist(5010510857038200833,635);
addToWhitelist(5010511956549828609,636);
addToWhitelist(5010513056061456385,637);
addToWhitelist(5010514155573084161,638);
addToWhitelist(5010515255084711937,639);
addToWhitelist(5010516354596339713,640);
addToWhitelist(5010517454107967489,641);
addToWhitelist(5010518553619595265,642);
addToWhitelist(5010519653131223041,643);
addToWhitelist(5010520752642850817,644);
addToWhitelist(5010521852154478593,645);
addToWhitelist(5010522951666106369,646);
addToWhitelist(5010524051177734145,647);
addToWhitelist(5010525150689361921,648);
addToWhitelist(5010526250200989697,649);
addToWhitelist(5010527349712617473,650);
addToWhitelist(5010528449224245249,651);
addToWhitelist(5010529548735873025,652);
addToWhitelist(5010530648247500801,653);
addToWhitelist(5010531747759128577,654);
addToWhitelist(5010532847270756353,655);
addToWhitelist(5010533946782384129,656);
addToWhitelist(5010535046294011905,657);
addToWhitelist(5010536145805639681,658);
addToWhitelist(5010537245317267457,659);
addToWhitelist(5010538344828895233,660);
addToWhitelist(5010539444340523009,661);
addToWhitelist(5010540543852150785,662);
addToWhitelist(5010541643363778561,663);
addToWhitelist(5010542742875406337,664);
addToWhitelist(5010543842387034113,665);
addToWhitelist(5010544941898661889,666);
addToWhitelist(5010546041410289665,667);
addToWhitelist(5010547140921917441,668);
addToWhitelist(5010548240433545217,669);
addToWhitelist(5010549339945172993,670);
addToWhitelist(5010550439456800769,671);
addToWhitelist(5010551538968428545,672);
addToWhitelist(5010552638480056321,673);
addToWhitelist(5010553737991684097,674);
addToWhitelist(5010554837503311873,675);
addToWhitelist(5010555937014939649,676);
addToWhitelist(5010557036526567425,677);
addToWhitelist(5010558136038195201,678);
addToWhitelist(5010559235549822977,679);
addToWhitelist(5010560335061450753,680);
addToWhitelist(5010561434573078529,681);
addToWhitelist(5010562534084706305,682);
addToWhitelist(5010563633596334081,683);
addToWhitelist(5010564733107961857,684);
addToWhitelist(5010565832619589633,685);
addToWhitelist(5010566932131217409,686);
addToWhitelist(5010568031642845185,687);
addToWhitelist(5010569131154472961,688);
addToWhitelist(5010570230666100737,689);
addToWhitelist(5010571330177728513,690);
addToWhitelist(5010572429689356289,691);
addToWhitelist(5010573529200984065,692);
addToWhitelist(5010574628712611841,693);
addToWhitelist(5010575728224239617,694);
addToWhitelist(5010576827735867393,695);
addToWhitelist(5010577927247495169,696);
addToWhitelist(5010579026759122945,697);
addToWhitelist(5010580126270750721,698);
addToWhitelist(5010581225782378497,699);
addToWhitelist(5010582325294006273,700);
addToWhitelist(5010583424805634049,701);
addToWhitelist(5010584524317261825,702);
addToWhitelist(5010585623828889601,703);
addToWhitelist(5010586723340517377,704);
addToWhitelist(5010587822852145153,705);
addToWhitelist(5010588922363772929,706);
addToWhitelist(5010590021875400705,707);
addToWhitelist(5010591121387028481,708);
addToWhitelist(5010592220898656257,709);
addToWhitelist(5010593320410284033,710);
addToWhitelist(5010594419921911809,711);
addToWhitelist(5010595519433539585,712);
addToWhitelist(5010596618945167361,713);
addToWhitelist(5010597718456795137,714);
addToWhitelist(5010598817968422913,715);
addToWhitelist(5010599917480050689,716);
addToWhitelist(5010601016991678465,717);
addToWhitelist(5010602116503306241,718);
addToWhitelist(5010603216014934017,719);
addToWhitelist(5010604315526561793,720);
addToWhitelist(5010605415038189569,721);
addToWhitelist(5010606514549817345,722);
addToWhitelist(5010607614061445121,723);
addToWhitelist(5010608713573072897,724);
addToWhitelist(5010609813084700673,725);
addToWhitelist(5010610912596328449,726);
addToWhitelist(5010612012107956225,727);
addToWhitelist(5010613111619584001,728);
addToWhitelist(5010614211131211777,729);
addToWhitelist(5010615310642839553,730);
addToWhitelist(5010616410154467329,731);
addToWhitelist(5010617509666095105,732);
addToWhitelist(5010618609177722881,733);
addToWhitelist(5010619708689350657,734);
addToWhitelist(5010620808200978433,735);
addToWhitelist(5010621907712606209,736);
addToWhitelist(5010623007224233985,737);
addToWhitelist(5010624106735861761,738);
addToWhitelist(5010625206247489537,739);
addToWhitelist(5010626305759117313,740);
addToWhitelist(5010627405270745089,741);
addToWhitelist(5010628504782372865,742);
addToWhitelist(5010629604294000641,743);
addToWhitelist(5010630703805628417,744);
addToWhitelist(5010631803317256193,745);
addToWhitelist(5010632902828883969,746);
addToWhitelist(5010634002340511745,747);
addToWhitelist(5010635101852139521,748);
addToWhitelist(5010636201363767297,749);
addToWhitelist(5010637300875395073,750);
addToWhitelist(5010638400387022849,751);
addToWhitelist(5010639499898650625,752);
addToWhitelist(5010640599410278401,753);
addToWhitelist(5010641698921906177,754);
addToWhitelist(5010642798433533953,755);
addToWhitelist(5010643897945161729,756);
addToWhitelist(5010644997456789505,757);
addToWhitelist(5010646096968417281,758);
addToWhitelist(5010647196480045057,759);
addToWhitelist(5010648295991672833,760);
addToWhitelist(5010649395503300609,761);
addToWhitelist(5010650495014928385,762);
addToWhitelist(5010651594526556161,763);
addToWhitelist(5010652694038183937,764);
addToWhitelist(5010653793549811713,765);
addToWhitelist(5010654893061439489,766);
addToWhitelist(5010655992573067265,767);
addToWhitelist(5010657092084695041,768);
addToWhitelist(5010658191596322817,769);
addToWhitelist(5010659291107950593,770);
addToWhitelist(5010660390619578369,771);
addToWhitelist(5010661490131206145,772);
addToWhitelist(5010662589642833921,773);
addToWhitelist(5010663689154461697,774);
addToWhitelist(5010664788666089473,775);
addToWhitelist(5010665888177717249,776);
addToWhitelist(5010666987689345025,777);
addToWhitelist(5010668087200972801,778);
addToWhitelist(5010669186712600577,779);
addToWhitelist(5010670286224228353,780);
addToWhitelist(5010671385735856129,781);
addToWhitelist(5010672485247483905,782);
addToWhitelist(5010673584759111681,783);
addToWhitelist(5010674684270739457,784);
addToWhitelist(5010675783782367233,785);
addToWhitelist(5010676883293995009,786);
addToWhitelist(5010677982805622785,787);
addToWhitelist(5010679082317250561,788);
addToWhitelist(5010680181828878337,789);
addToWhitelist(5010681281340506113,790);
addToWhitelist(5010682380852133889,791);
addToWhitelist(5010683480363761665,792);
addToWhitelist(5010684579875389441,793);
addToWhitelist(5010685679387017217,794);
addToWhitelist(5010686778898644993,795);
addToWhitelist(5010687878410272769,796);
addToWhitelist(5010688977921900545,797);
addToWhitelist(5010690077433528321,798);
addToWhitelist(5010691176945156097,799);
addToWhitelist(5010692276456783873,800);
addToWhitelist(5010693375968411649,801);
addToWhitelist(5010694475480039425,802);
addToWhitelist(5010695574991667201,803);
addToWhitelist(5010696674503294977,804);
addToWhitelist(5010697774014922753,805);
addToWhitelist(5010698873526550529,806);
addToWhitelist(5010699973038178305,807);
addToWhitelist(5010701072549806081,808);
addToWhitelist(5010702172061433857,809);
addToWhitelist(5010703271573061633,810);
addToWhitelist(5010704371084689409,811);
addToWhitelist(5010705470596317185,812);
addToWhitelist(5010706570107944961,813);
addToWhitelist(5010707669619572737,814);
addToWhitelist(5010708769131200513,815);
addToWhitelist(5010709868642828289,816);
addToWhitelist(5010710968154456065,817);
addToWhitelist(5010712067666083841,818);
addToWhitelist(5010713167177711617,819);
addToWhitelist(5010714266689339393,820);
addToWhitelist(5010715366200967169,821);
addToWhitelist(5010716465712594945,822);
addToWhitelist(5010717565224222721,823);
addToWhitelist(5010718664735850497,824);
addToWhitelist(5010719764247478273,825);
addToWhitelist(5010720863759106049,826);
addToWhitelist(5010721963270733825,827);
addToWhitelist(5010723062782361601,828);
addToWhitelist(5010724162293989377,829);
addToWhitelist(5010725261805617153,830);
addToWhitelist(5010726361317244929,831);
addToWhitelist(5010727460828872705,832);
addToWhitelist(5010728560340500481,833);
addToWhitelist(5010729659852128257,834);
addToWhitelist(5010730759363756033,835);
addToWhitelist(5010731858875383809,836);
addToWhitelist(5010732958387011585,837);
addToWhitelist(5010734057898639361,838);
addToWhitelist(5010735157410267137,839);
addToWhitelist(5010736256921894913,840);
addToWhitelist(5010737356433522689,841);
addToWhitelist(5010738455945150465,842);
addToWhitelist(5010739555456778241,843);
addToWhitelist(5010740654968406017,844);
addToWhitelist(5010741754480033793,845);
addToWhitelist(5010742853991661569,846);
addToWhitelist(5010743953503289345,847);
addToWhitelist(5010745053014917121,848);
addToWhitelist(5010746152526544897,849);
addToWhitelist(5010747252038172673,850);
addToWhitelist(5010748351549800449,851);
addToWhitelist(5010749451061428225,852);
addToWhitelist(5010750550573056001,853);
addToWhitelist(5010751650084683777,854);
addToWhitelist(5010752749596311553,855);
addToWhitelist(5010753849107939329,856);
addToWhitelist(5010754948619567105,857);
addToWhitelist(5010756048131194881,858);
addToWhitelist(5010757147642822657,859);
addToWhitelist(5010758247154450433,860);
addToWhitelist(5010759346666078209,861);
addToWhitelist(5010760446177705985,862);
addToWhitelist(5010761545689333761,863);
addToWhitelist(5010762645200961537,864);
addToWhitelist(5010763744712589313,865);
addToWhitelist(5010764844224217089,866);
addToWhitelist(5010765943735844865,867);
addToWhitelist(5010767043247472641,868);
addToWhitelist(5010768142759100417,869);
addToWhitelist(5010769242270728193,870);
addToWhitelist(5010770341782355969,871);
addToWhitelist(5010771441293983745,872);
addToWhitelist(5010772540805611521,873);
addToWhitelist(5010773640317239297,874);
addToWhitelist(5010774739828867073,875);
addToWhitelist(5010775839340494849,876);
addToWhitelist(5010776938852122625,877);
addToWhitelist(5010778038363750401,878);
addToWhitelist(5010779137875378177,879);
addToWhitelist(5010780237387005953,880);
addToWhitelist(5010781336898633729,881);
addToWhitelist(5010782436410261505,882);
addToWhitelist(5010783535921889281,883);
addToWhitelist(5010784635433517057,884);
addToWhitelist(5010785734945144833,885);
addToWhitelist(5010786834456772609,886);
addToWhitelist(5010787933968400385,887);
addToWhitelist(5010789033480028161,888);
addToWhitelist(5010790132991655937,889);
addToWhitelist(5010791232503283713,890);
addToWhitelist(5010792332014911489,891);
addToWhitelist(5010793431526539265,892);
addToWhitelist(5010794531038167041,893);
addToWhitelist(5010795630549794817,894);
addToWhitelist(5010796730061422593,895);
addToWhitelist(5010797829573050369,896);
addToWhitelist(5010798929084678145,897);
addToWhitelist(5010800028596305921,898);
addToWhitelist(5010801128107933697,899);
addToWhitelist(5010802227619561473,900);
addToWhitelist(5010803327131189249,901);
addToWhitelist(5010804426642817025,902);
addToWhitelist(5010805526154444801,903);
addToWhitelist(5010806625666072577,904);
addToWhitelist(5010807725177700353,905);
addToWhitelist(5010808824689328129,906);
addToWhitelist(5010809924200955905,907);
addToWhitelist(5010811023712583681,908);
addToWhitelist(5010812123224211457,909);
addToWhitelist(5010813222735839233,910);
addToWhitelist(5010814322247467009,911);
addToWhitelist(5010815421759094785,912);
addToWhitelist(5010816521270722561,913);
addToWhitelist(5010817620782350337,914);
addToWhitelist(5010818720293978113,915);
addToWhitelist(5010819819805605889,916);
addToWhitelist(5010820919317233665,917);
addToWhitelist(5010822018828861441,918);
addToWhitelist(5010823118340489217,919);
addToWhitelist(5010824217852116993,920);
addToWhitelist(5010825317363744769,921);
addToWhitelist(5010826416875372545,922);
addToWhitelist(5010827516387000321,923);
addToWhitelist(5010828615898628097,924);
addToWhitelist(5010829715410255873,925);
addToWhitelist(5010830814921883649,926);
addToWhitelist(5010831914433511425,927);
addToWhitelist(5010833013945139201,928);
addToWhitelist(5010834113456766977,929);
addToWhitelist(5010835212968394753,930);
addToWhitelist(5010836312480022529,931);
addToWhitelist(5010837411991650305,932);
addToWhitelist(5010838511503278081,933);
addToWhitelist(5010839611014905857,934);
addToWhitelist(5010840710526533633,935);
addToWhitelist(5010841810038161409,936);
addToWhitelist(5010842909549789185,937);
addToWhitelist(5010844009061416961,938);
addToWhitelist(5010845108573044737,939);
addToWhitelist(5010846208084672513,940);
addToWhitelist(5010847307596300289,941);
addToWhitelist(5010848407107928065,942);
addToWhitelist(5010849506619555841,943);
addToWhitelist(5010850606131183617,944);
addToWhitelist(5010851705642811393,945);
addToWhitelist(5010852805154439169,946);
addToWhitelist(5010853904666066945,947);
addToWhitelist(5010855004177694721,948);
addToWhitelist(5010856103689322497,949);
addToWhitelist(5010857203200950273,950);
addToWhitelist(5010858302712578049,951);
addToWhitelist(5010859402224205825,952);
addToWhitelist(5010860501735833601,953);
addToWhitelist(5010861601247461377,954);
addToWhitelist(5010862700759089153,955);
addToWhitelist(5010863800270716929,956);
addToWhitelist(5010864899782344705,957);
addToWhitelist(5010865999293972481,958);
addToWhitelist(5010867098805600257,959);
addToWhitelist(5010868198317228033,960);
addToWhitelist(5010869297828855809,961);
addToWhitelist(5010870397340483585,962);
addToWhitelist(5010871496852111361,963);
addToWhitelist(5010872596363739137,964);
addToWhitelist(5010873695875366913,965);
addToWhitelist(5010874795386994689,966);
addToWhitelist(5010875894898622465,967);
addToWhitelist(5010876994410250241,968);
addToWhitelist(5010878093921878017,969);
addToWhitelist(5010879193433505793,970);
addToWhitelist(5010880292945133569,971);
addToWhitelist(5010881392456761345,972);
addToWhitelist(5010882491968389121,973);
addToWhitelist(5010883591480016897,974);
addToWhitelist(5010884690991644673,975);
addToWhitelist(5010885790503272449,976);
addToWhitelist(5010886890014900225,977);
addToWhitelist(5010887989526528001,978);
addToWhitelist(5010889089038155777,979);
addToWhitelist(5010890188549783553,980);
addToWhitelist(5010891288061411329,981);
addToWhitelist(5010892387573039105,982);
addToWhitelist(5010893487084666881,983);
addToWhitelist(5010894586596294657,984);
addToWhitelist(5010895686107922433,985);
addToWhitelist(5010896785619550209,986);
addToWhitelist(5010897885131177985,987);
addToWhitelist(5010898984642805761,988);
addToWhitelist(5010900084154433537,989);
addToWhitelist(5010901183666061313,990);
addToWhitelist(5010902283177689089,991);
addToWhitelist(5010903382689316865,992);
addToWhitelist(5010904482200944641,993);
addToWhitelist(5010905581712572417,994);
addToWhitelist(5010906681224200193,995);
addToWhitelist(5010907780735827969,996);
addToWhitelist(5010908880247455745,997);
addToWhitelist(5010909979759083521,998);
addToWhitelist(5010911079270711297,999);
addToWhitelist(5010912178782339073,1000);
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