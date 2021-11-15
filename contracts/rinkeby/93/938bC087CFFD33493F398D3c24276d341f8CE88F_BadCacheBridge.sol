//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../opensea/OpenSeaIERC1155.sol";
import "../core/BadCacheI.sol";

/**
 * @dev This contracts bridges an OpenSea ERC1155 into the new Badcache ERC721.
 *      Only owners of BadCache from OpenSea can mint new tokens once they transfer their NFT ownership to the BadcacheBridge.
 *      An ERC721 will be minted once transfer is received
 */

contract BadCacheBridge is ReentrancyGuard, Ownable, ERC1155Holder, ERC721Holder {
  // OpenSea token that can be proxied to check for balance
  address internal openseaToken = 0x495f947276749Ce646f68AC8c248420045cb7b5e;

  // Total transfered tokens to our bridge
  uint32 internal totalTransfers = 0;

  // A list of senders, that sent tokens to our bridge
  address[] internal senders;

  // Storing a transfer count -> sender -> tokenId
  mapping(uint32 => mapping(address => uint256)) internal transfers;

  // BadCache721 token that it will be minted based on receiving
  address internal badCache721 = 0x0000000000000000000000000000000000000000;

  // Storing token URIs base
  string private baseUri = "https://ipfs.io/ipfs/QmYSUKeq5Dt8M2RBt7u9f63QwWvdPNawr6Gjc47jdaUr5C/";

  // Allowed tokens ids (from OpenSea)
  uint256[] internal allowedTokens;

  // Maps an old token id with a new token id oldTokenId=>newTokenId
  mapping(uint256 => uint16) internal oldNewTokenIdPairs;

  // Maps an old token id with a new token id oldTokenId=>newTokenId
  mapping(uint16 => uint256) internal newOldTokenIdPairs;

  // Keeps an array of new token ids that are allowed to be minted
  uint16[] internal newTokenIds;

  // Keeps an array of custom 721 tokens
  uint16[] internal custom721Ids;

  event ReceivedTransferFromOpenSea(
    address indexed _sender,
    address indexed _receiver,
    uint256 indexed _tokenId,
    uint256 _amount
  );

  event ReceivedTransferFromBadCache721(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId);

  event MintedBadCache721(address indexed _sender, uint256 indexed _tokenId);

  /**
   * @dev Initiating the tokens allowed to be received
   */
  constructor() onlyOwner {
    initAllowedTokens();
  }

  /**
   * @dev Mint a ERC721 token based on the receiving of the OpenSea token.
   *
   * Requirements:
   *
   * - `_sender` cannot be the zero address.
   * - `_tokenId` needs to be part of our allowedIds.
   * - `_tokenId` must not be minted before.
   *
   * Emits a {Transfer} event.
   */
  function mintBasedOnReceiving(address _sender, uint256 _tokenId) internal isTokenAllowed(_tokenId) returns (bool) {
    require(_sender != address(0), "BadCacheBridge: can not mint a new token to the zero address");

    uint256 newTokenId = oldNewTokenIdPairs[_tokenId];
    if (BadCacheI(badCache721).exists(newTokenId) && BadCacheI(badCache721).ownerOf(newTokenId) == address(this)) {
      BadCacheI(badCache721).safeTransferFrom(address(this), _sender, newTokenId);
      return true;
    }
    require(!BadCacheI(badCache721).exists(newTokenId), "BadCacheBridge: token already minted");
    require(newTokenId != 0, "BadCacheBridge: new token id does not exists");

    string memory uri = getURIById(newTokenId);
    _mint721(newTokenId, _sender, uri);

    return true;
  }

  /**
   * @dev check balance of an account and an id for the OpenSea ERC1155
   */
  function checkBalance(address _account, uint256 _tokenId) public view isTokenAllowed(_tokenId) returns (uint256) {
    require(_account != address(0), "BadCacheBridge: can not check balance for address zero");
    return OpenSeaIERC1155(openseaToken).balanceOf(_account, _tokenId);
  }

  /**
   * @dev sets proxied token for OpenSea. You need to get it from the mainnet https://etherscan.io/address/0x495f947276749ce646f68ac8c248420045cb7b5e
   * Requirements:
   *
   * - `_token` must not be address zero
   */
  function setOpenSeaProxiedToken(address _token) public onlyOwner {
    require(_token != address(0), "BadCacheBridge: can not set as proxy the address zero");
    openseaToken = _token;
  }

  /**
   * @dev sets proxied token for BadCache721. You need to transfer the ownership of the 721 to the Bridge so the bridge can mint and transfer
   * Requirements:
   *
   * - `_token` must not be address zero
   */
  function setBadCache721ProxiedToken(address _token) public onlyOwner {
    require(_token != address(0), "BadCacheBridge: can not set as BadCache721 the address zero");
    badCache721 = _token;
  }

  /**
   * @dev sets base uri
   * Requirements:
   */
  function setBaseUri(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }

  /**
   * @dev get base uri
   * Requirements:
   */
  function getBaseUri() public view returns (string memory) {
    return baseUri;
  }

  /**
   * @dev transfers a BadCache721 Owned by the bridge to another owner
   * Requirements:
   *
   * - `_token` must not be address zero
   */
  function transferBadCache721(uint256 _tokenId, address _owner) public onlyOwner isNewTokenAllowed(_tokenId) {
    require(_owner != address(0), "BadCacheBridge: can not send a BadCache721 to the address zero");

    BadCacheI(badCache721).safeTransferFrom(address(this), _owner, _tokenId);
  }

  /**
   * @dev transfers a BadCache1155 Owned by the bridge to another owner
   * Requirements:
   *
   * - `_token` must not be address zero
   */
  function transferBadCache1155(uint256 _tokenId, address _owner) public onlyOwner isTokenAllowed(_tokenId) {
    require(_owner != address(0), "BadCacheBridge: can not send a BadCache1155 to the address zero");

    OpenSeaIERC1155(openseaToken).safeTransferFrom(address(this), _owner, _tokenId, 1, "");
  }

  /**
   * @dev check owner of a token on OpenSea token
   */
  function ownerOf1155(uint256 _tokenId) public view returns (bool) {
    return OpenSeaIERC1155(openseaToken).balanceOf(msg.sender, _tokenId) != 0;
  }

  /**
   * @dev Triggered when we receive an ERC1155 from OpenSea and calls {mintBasedOnReceiving}
   *
   * Requirements:
   *
   * - `_sender` cannot be the zero address.
   * - `_tokenId` needs to be part of our allowedIds.
   * - `_tokenId` must not be minted before.
   *
   * Emits a {Transfer} event.
   */
  function onERC1155Received(
    address _sender,
    address _receiver,
    uint256 _tokenId,
    uint256 _amount,
    bytes memory _data
  ) public override returns (bytes4) {
    onReceiveTransfer1155(_sender, _tokenId);
    mintBasedOnReceiving(_sender, _tokenId);
    emit ReceivedTransferFromOpenSea(_sender, _receiver, _tokenId, _amount);
    return super.onERC1155Received(_sender, _receiver, _tokenId, _amount, _data);
  }

  /**
   * @dev Triggered when we receive an ERC1155 from OpenSea and calls {mintBasedOnReceiving}
   *
   * Requirements:
   *
   * - `_sender` cannot be the zero address.
   * - `_tokenId` needs to be part of our allowedIds.
   * - `_tokenId` must not be minted before.
   *
   * Emits a {Transfer} event.
   */
  function onERC721Received(
    address _sender,
    address _receiver,
    uint256 _tokenId,
    bytes memory _data
  ) public override returns (bytes4) {
    require(_sender != address(0), "BadCacheBridge: can not update from the zero address");
    if (_sender == address(this)) return super.onERC721Received(_sender, _receiver, _tokenId, _data);
    require(_tokenId <= type(uint16).max, "BadCacheBridge: Token id overflows");
    if (_sender != address(this)) onReceiveTransfer721(_sender, _tokenId);
    emit ReceivedTransferFromBadCache721(_sender, _receiver, _tokenId);
    return super.onERC721Received(_sender, _receiver, _tokenId, _data);
  }

  /**
   * @dev get total transfer count
   */
  function getTransferCount() public view returns (uint128) {
    return totalTransfers;
  }

  /**
   * @dev get addreses that already sent a token to us
   */
  function getAddressesThatTransferedIds() public view returns (address[] memory) {
    return senders;
  }

  /**
   * @dev get ids of tokens that were transfered
   */
  function getIds() public view returns (uint256[] memory) {
    uint256[] memory ids = new uint256[](totalTransfers);
    for (uint32 i = 0; i < totalTransfers; i++) {
      ids[i] = transfers[i][senders[i]];
    }
    return ids;
  }

  /**
   * @dev get ids of custom 721 tokens that were minted
   */
  function getCustomIds() public view returns (uint256[] memory) {
    uint256[] memory ids = new uint256[](custom721Ids.length);
    for (uint128 i = 0; i < custom721Ids.length; i++) {
      ids[i] = custom721Ids[i];
    }
    return ids;
  }

  /**
   * @dev get opensea proxied token
   */
  function getOpenSeaProxiedtoken() public view returns (address) {
    return openseaToken;
  }

  /**
   * @dev get BadCache721 proxied token
   */
  function getBadCache721ProxiedToken() public view returns (address) {
    return badCache721;
  }

  /**
   * @dev update params once we receive a transfer from 1155
   *
   * Requirements:
   *
   * - `_sender` cannot be the zero address.
   * - `_tokenId` needs to be part of our allowedIds.
   */
  function onReceiveTransfer1155(address _sender, uint256 _tokenId) internal isTokenAllowed(_tokenId) returns (uint32 count) {
    require(_sender != address(0), "BadCacheBridge: can not update from the zero address");
    require(OpenSeaIERC1155(openseaToken).balanceOf(address(this), _tokenId) > 0, "BadCacheBridge: This is not an OpenSea token");

    senders.push(_sender);
    transfers[totalTransfers][_sender] = _tokenId;
    totalTransfers++;
    return totalTransfers;
  }

  /**
   * @dev update params once we receive a transfer 721
   *
   * Requirements:
   *
   * - `_sender` cannot be the zero address.
   * - `_tokenId` needs to be part of our allowedIds.
   */
  function onReceiveTransfer721(address _sender, uint256 _tokenId) internal isNewTokenAllowed(_tokenId) {
    for (uint120 i; i < senders.length; i++) {
      if (senders[i] == _sender) delete senders[i];
    }

    OpenSeaIERC1155(openseaToken).safeTransferFrom(address(this), _sender, newOldTokenIdPairs[uint16(_tokenId)], 1, "");
  }

  /**
   * @dev the owner can add new tokens into the allowed tokens list
   */
  function addAllowedToken(uint256 _tokenId, uint16 _newTokenId) public onlyOwner {
    allowedTokens.push(_tokenId);
    oldNewTokenIdPairs[_tokenId] = _newTokenId;
    newTokenIds.push(_newTokenId);
    newOldTokenIdPairs[_newTokenId] = _tokenId;
  }

  /**
   * @dev mint a custom 721 token by the owner
   */
  function mintBadCache721(
    uint16 _tokenId,
    string memory _uri,
    address _owner
  ) public onlyOwner {
    require(_owner != address(0), "BadCacheBridge: can not mint a new token to the zero address");

    //means we want to transfer an existing BadCache721
    if (BadCacheI(badCache721).exists(_tokenId) && BadCacheI(badCache721).ownerOf(_tokenId) == address(this)) {
      BadCacheI(badCache721).safeTransferFrom(address(this), _owner, _tokenId);
      return;
    }
    require(!BadCacheI(badCache721).exists(_tokenId), "BadCacheBridge: token already minted");
    _mint721(_tokenId, _owner, _uri);
    custom721Ids.push(_tokenId);
  }

  /**
   * @dev transfers the ownership of BadCache721 token
   */
  function transferOwnershipOf721(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "BadCacheBridge: new owner can not be the zero address");
    BadCacheI(badCache721).transferOwnership(_newOwner);
  }

  /**
   * @dev get URI by token id from allowed tokens
   *
   * Requirements:
   *
   * - `_tokenId` needs to be part of our allowedIds.
   */
  function getURIById(uint256 _tokenId) private view isNewTokenAllowed(_tokenId) returns (string memory) {
    return string(abi.encodePacked(baseUri, uint2str(_tokenId), ".json"));
  }

  /**
   * @dev minting BadCache721 function and transfer to the owner
   */
  function _mint721(
    uint256 _tokenId,
    address _owner,
    string memory _tokenURI
  ) private {
    BadCacheI(badCache721).mint(address(this), _tokenId);

    BadCacheI(badCache721).setTokenUri(_tokenId, _tokenURI);
    BadCacheI(badCache721).safeTransferFrom(address(this), _owner, _tokenId);
    emit MintedBadCache721(_owner, _tokenId);
  }

  /**
   * @dev initiation of the allowed tokens
   */
  function initAllowedTokens() private {
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680203063263232001, 1);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680204162774859777, 2);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680205262286487553, 3);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680206361798115329, 4);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680207461309743105, 5);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680208560821370881, 6);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680209660332998657, 7);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680210759844626433, 8);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680211859356254209, 9);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680212958867881985, 10);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680214058379509761, 11);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680215157891137537, 12);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680216257402765313, 13);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680217356914393089, 14);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680218456426020865, 15);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680219555937648641, 16);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680220655449276417, 17);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680221754960904193, 18);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680222854472531969, 19);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680223953984159745, 20);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680225053495787521, 21);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680226153007415297, 22);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680227252519043073, 23);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680228352030670849, 24);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680229451542298625, 25);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680230551053926401, 26);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680231650565554177, 27);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680232750077181953, 28);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680233849588809729, 29);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680234949100437505, 30);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680236048612065281, 31);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680237148123693057, 32);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680238247635320833, 33);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680239347146948609, 34);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680240446658576385, 35);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680241546170204161, 36);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680242645681831937, 37);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680243745193459713, 38);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680244844705087489, 39);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680245944216715265, 40);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680247043728343041, 41);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680248143239970817, 42);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680249242751598593, 43);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680250342263226369, 44);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680251441774854145, 45);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680252541286481921, 46);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680253640798109697, 47);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680254740309737473, 48);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680255839821365249, 49);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680256939332993025, 50);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680258038844620801, 51);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680259138356248577, 52);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680260237867876353, 53);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680261337379504129, 54);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680262436891131905, 55);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680263536402759681, 56);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680264635914387457, 57);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680265735426015233, 58);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680266834937643009, 59);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680267934449270785, 60);
  }

  function initTheRestOfTheTokens() public onlyOwner {
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680269033960898561, 61);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680270133472526337, 62);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680271232984154113, 63);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680272332495781889, 64);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680273432007409665, 65);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680274531519037441, 66);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680275631030665217, 67);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680276730542292993, 68);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680277830053920769, 69);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680278929565548545, 70);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680280029077176321, 71);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680281128588804097, 72);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680282228100431873, 73);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680283327612059649, 74);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680284427123687425, 75);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680285526635315201, 76);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680286626146942977, 77);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680287725658570753, 78);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680288825170198529, 79);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680289924681826305, 80);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680291024193454081, 81);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680292123705081857, 82);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680293223216709633, 83);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680294322728337409, 84);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680295422239965185, 85);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680296521751592961, 86);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680297621263220737, 87);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680298720774848513, 88);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680299820286476289, 89);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680300919798104065, 90);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680302019309731841, 91);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680303118821359617, 92);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680304218332987393, 93);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680305317844615169, 94);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680306417356242945, 95);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680307516867870721, 96);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680308616379498497, 97);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680309715891126273, 98);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680310815402754049, 99);
    addAllowedToken(85601406272210854214775655996269203562327957411057160318308680311914914381825, 100);
  }

  /**
   * @dev checks if it's part of the allowed tokens
   */
  modifier isTokenAllowed(uint256 _tokenId) {
    bool found = false;
    for (uint128 i = 0; i < allowedTokens.length; i++) {
      if (allowedTokens[i] == _tokenId) found = true;
    }
    require(found, "BadCacheBridge: token id does not exists");
    _;
  }

  /**
   * @dev checks if it's part of the new allowed tokens
   */
  modifier isNewTokenAllowed(uint256 _tokenId) {
    bool found = false;

    for (uint128 i = 0; i < newTokenIds.length; i++) {
      if (newTokenIds[i] == _tokenId) found = true;
    }
    require(found, "BadCacheBridge: new token id does not exists");
    _;
  }

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract OpenSeaIERC1155 is IERC1155 {}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BadCacheI is IERC721, Ownable {
  function setTokenUri(uint256 _tokenId, string memory _tokenURI) public virtual;

  function mint(address _owner, uint256 _tokenId) public virtual;

  function exists(uint256 _tokenId) public view virtual returns (bool);

  function getMaxId() public view virtual returns (uint256);

  function setMaxId(uint256 _newMaxId) public virtual;
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

