// SPDX-License-Identifier: MIT LICENSE  

pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./Strings.sol";
import "./WOOL.sol";
import "./IDateTime.sol";

contract WoolPouch is ERC721Upgradeable, OwnableUpgradeable, PausableUpgradeable {
  
  /*

  Security notes
  ==============

  - Claiming can lead to a tiny round down. This can result in negligible, but real losses in dust. This is a tradeoff made to save gas by not requiring storage of already claimed balances.
  - Frontrunning protection: Transfers will revert if WOOL was claimed in the same block.
    We specifically do not show currently claimable balance as part of the metadata to reduce user confusion.
    A longer cooldown on transfers was considered, but ultimately not implemented as it introduces UX issues and additional complexity.
  
  */

  using Strings for uint256;
  using Strings for uint16;

  uint256 constant SECONDS_PER_DAY = 1 days;
  string gif;

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) public controllers;

  uint256 public minted;
  mapping(uint256 => Pouch) public pouches;

  uint256 public constant START_VALUE = 10000 ether;

  struct Pouch {
    bool initialClaimed; // whether or not first 10,000 WOOL has been claimed
    uint16 duration; // stored in days, maxed at 2^16 days
    uint56 lastClaimTimestamp; // stored in seconds, uint56 can store 2 billion years 
    uint56 startTimestamp; // stored in seconds, uint56 can store 2 billion years 
    uint120 amount; // max value, 120 bits is far beyond 5 billion wool supply
  }

  event WoolClaimed(
    address recipient,
    uint256 tokenId,
    uint256 amount
  );

  WOOL public wool;
  IDateTime dateTime;

  function initialize(address _wool, address _dateTime) external initializer {
    __Ownable_init();
    __Pausable_init();
    __ERC721_init("Wool Pouch", "WPOUCH");

    wool = WOOL(_wool);
    dateTime = IDateTime(_dateTime);

    _pause();
  }

  /** EXTERNAL */

  /**
   * claim WOOL tokens from a pouch
   * @param tokenId the token to claim WOOL from
   */
  function claim(uint256 tokenId) external whenNotPaused {
    require(ownerOf(tokenId) == _msgSender(), "SWIPER NO SWIPING");
    uint256 available = amountAvailable(tokenId);
    require(available > 0, "NO MORE EARNINGS AVAILABLE");
    Pouch storage pouch = pouches[tokenId];
    pouch.lastClaimTimestamp = uint56(block.timestamp);
    if (!pouch.initialClaimed) pouch.initialClaimed = true;
    wool.mint(_msgSender(), available);
    emit WoolClaimed(_msgSender(), tokenId, available);
  }

  function claimMany(uint256[] calldata tokenIds) external whenNotPaused {
    uint256 available;
    uint256 totalAvailable;
    for (uint i = 0; i < tokenIds.length; i++) {
      require(ownerOf(tokenIds[i]) == _msgSender(), "SWIPER NO SWIPING");
      available = amountAvailable(tokenIds[i]);
      Pouch storage pouch = pouches[tokenIds[i]];
      pouch.lastClaimTimestamp = uint56(block.timestamp);
      if (!pouch.initialClaimed) pouch.initialClaimed = true;
      emit WoolClaimed(_msgSender(), tokenIds[i], available);
      
      totalAvailable += available;
    }
    require(totalAvailable > 0, "NO MORE EARNINGS AVAILABLE");
    wool.mint(_msgSender(), totalAvailable);
  }

  /**
   * the amount of WOOL currently available to claim in a WOOL pouch
   * @param tokenId the token to check the WOOL for
   */
  function amountAvailable(uint256 tokenId) public view returns (uint256) {
    Pouch memory pouch = pouches[tokenId];
    uint256 currentTimestamp = block.timestamp;
    if (currentTimestamp > uint256(pouch.startTimestamp) + uint256(pouch.duration) * SECONDS_PER_DAY)
      currentTimestamp = uint256(pouch.startTimestamp) + uint256(pouch.duration) * SECONDS_PER_DAY;
    if (pouch.lastClaimTimestamp > currentTimestamp) return 0;
    uint256 elapsed = currentTimestamp - pouch.lastClaimTimestamp;
    return elapsed * uint256(pouch.amount) / (uint256(pouch.duration) * SECONDS_PER_DAY) + 
      (pouch.initialClaimed ? 0 : START_VALUE);
  }

  /** CONTROLLER */

  /**
   * mints $WOOL to a recipient
   * @param to the recipient of the $WOOL
   * @param amount the amount of $WOOL to mint
   */
  function mint(address to, uint128 amount, uint16 duration) external {
    require(controllers[msg.sender], "Only controllers can mint");
    require(amount >= START_VALUE, "Insufficient pouch");
    pouches[++minted] = Pouch({
      initialClaimed: false,
      duration: duration,
      lastClaimTimestamp: uint56(block.timestamp),
      startTimestamp: uint56(block.timestamp),
      amount: uint120(amount - START_VALUE)
    });
    _mint(to, minted);
  }

  function mintWithoutClaimable(address to, uint128 amount, uint16 duration) external {
    require(controllers[msg.sender], "Only controllers can mint");
    pouches[++minted] = Pouch({
      initialClaimed: true,
      duration: duration,
      lastClaimTimestamp: uint56(block.timestamp),
      startTimestamp: uint56(block.timestamp),
      amount: uint120(amount)
    });
    _mint(to, minted);
  }

  /** 
   Override to make sure that transfers can't be frontrun
   */
  function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(pouches[tokenId].lastClaimTimestamp < block.timestamp, "Cannot claim immediately before a transfer");
        _transfer(from, to, tokenId);
    }

  /** 
   Override to make sure that transfers can't be frontrun
   */
  function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(pouches[tokenId].lastClaimTimestamp < block.timestamp, "Cannot claim immediately before a transfer");
        _safeTransfer(from, to, tokenId, _data);
    }

  /** ADMIN */

  /**
   * enables an address to mint
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * uploads a gif for the background of the NFT
   * @param _gif the base64 encoded GIF
   */
  function uploadGIF(string calldata _gif) external onlyOwner {
    gif = _gif;
  }

  function generateSVG(uint256 tokenId) internal view returns (string memory) {
    Pouch memory pouch = pouches[tokenId];
    uint256 duration = uint256(pouch.duration) * SECONDS_PER_DAY;
    uint256 endTime = uint256(pouch.startTimestamp) + duration;
    uint256 locked;
    uint256 daysRemaining;
    if (endTime > block.timestamp) {
      locked = (endTime - block.timestamp) * uint256(pouch.amount) / duration;
      daysRemaining = (endTime - block.timestamp) / SECONDS_PER_DAY;
    }
    return string(abi.encodePacked(
      '<svg id="woolpouch" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
      '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/gif;base64,',gif,
      '"/><text font-family="monospace"><tspan x="13" y="4" font-size="0.25em">Locked WOOL:</tspan><tspan id="g" x="38" y="4" font-size="0.25em">',
      (locked / 1 ether).toString(),
      '</tspan></text><text font-family="monospace"><tspan x="9" y="9" font-size="0.25em">Unlock Period:</tspan><tspan id="b" x="38" y="9" font-size="0.25em">',
      (daysRemaining).toString(),
      ' Days</tspan></text><text font-family="monospace"><tspan x="4" y="13" font-size="0.15em">Before transfer, remember to claim unlocked WOOL</tspan></text>',
      '</svg>'
    ));
  }

  /**
   * generates an attribute for the attributes array in the ERC721 metadata standard
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function attributeForTypeAndValue(string memory traitType, string memory value, bool isNumber) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":',
      isNumber ? '' : '"',
      value,
      isNumber ? '' : '"',
      '}'
    ));
  }

  /**
   * sets the attributes of the NFTs, mainly based on current WOOL state
   * @param tokenId the token to get the attributes for
   */
  function compileAttributes(uint256 tokenId) internal view returns (string memory) {
    Pouch memory pouch = pouches[tokenId];
    uint256 duration = uint256(pouch.duration) * SECONDS_PER_DAY;
    uint256 endTime = uint256(pouch.startTimestamp) + duration;
    uint256 locked;
    uint256 daysRemaining;
    if (endTime > block.timestamp) {
      locked = (endTime - block.timestamp) * uint256(pouch.amount) / duration;
      daysRemaining = (endTime - block.timestamp) / SECONDS_PER_DAY;
    }
    string memory attributes = string(abi.encodePacked(
      attributeForTypeAndValue("Locked WOOL", 
        uint256(locked / 1 ether).toString(),
      false),',',
      attributeForTypeAndValue("Time Remaining", 
        string(abi.encodePacked(
          daysRemaining.toString(),
          " Days"
        )),
      false),','
    ));
    attributes = string(abi.encodePacked(
      attributes,
      '{"trait_type":"Last Refreshed","display_type":"date","value":',
      block.timestamp.toString(),
      '},',
      attributeForTypeAndValue("Last Refreshed Time",
        string(abi.encodePacked(
          padNumber(uint256(dateTime.getHour(block.timestamp))),':',
          padNumber(uint256(dateTime.getMinute(block.timestamp))),':',
          padNumber(uint256(dateTime.getSecond(block.timestamp))),' UTC'
        )),
      false),',',
      attributeForTypeAndValue("Last Refreshed Date",
        string(abi.encodePacked(
          padNumber(uint256(dateTime.getMonth(block.timestamp))),'/',
          padNumber(uint256(dateTime.getDay(block.timestamp))),'/',
          uint256(dateTime.getYear(block.timestamp)).toString()
        )),
      false)   
    ));
    return string(abi.encodePacked(
      '[',
      attributes,
      ']'
    ));
  }

  function padNumber(uint256 number) internal pure returns (string memory padded) {
    padded = number.toString();
    return number < 10 ? string(abi.encodePacked('0', padded)) : padded;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory metadata = string(abi.encodePacked(
      '{"name": "WOOL Pouch #',
      tokenId.toString(),
      '","description": "Sellers: before listing, claim any unlocked WOOL in your Pouch on the Wolf Game site.<br /><br />Buyers: When you purchase a WOOL Pouch, assume the previous owner has already claimed its unlocked WOOL. Locked WOOL, which unlocks over time, will be displayed on the image. Refresh the metadata to see the most up to date values.",',
      '"image": "data:image/svg+xml;base64,',
      base64(bytes(generateSVG(tokenId))),
      '", "attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
  }

  /** BASE 64 - Written by Brech Devos */
  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';
    
    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)
      
      // prepare the lookup table
      let tablePtr := add(table, 1)
      
      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      
      // result ptr, jump over length
      let resultPtr := add(result, 32)
      
      // run over the input, 3 bytes at a time
      for {} lt(dataPtr, endPtr) {}
      {
          dataPtr := add(dataPtr, 3)
          
          // read 3 bytes
          let input := mload(dataPtr)
          
          // write 4 characters
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
          resultPtr := add(resultPtr, 1)
      }
      
      // padding with '='
      switch mod(mload(data), 3)
      case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
      case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
    }
    
    return result;
  }
}