/***
 *    ██╗      █████╗ ██╗██████╗     ██████╗  █████╗  ██████╗██╗  ██╗
 *    ██║     ██╔══██╗██║██╔══██╗    ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝
 *    ██║     ███████║██║██║  ██║    ██████╔╝███████║██║     █████╔╝ 
 *    ██║     ██╔══██║██║██║  ██║    ██╔══██╗██╔══██║██║     ██╔═██╗ 
 *    ███████╗██║  ██║██║██████╔╝    ██████╔╝██║  ██║╚██████╗██║  ██╗
 *    ╚══════╝╚═╝  ╚═╝╚═╝╚═════╝     ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
 *                                                                   
 *        ██╗     ██╗      █████╗ ███╗   ███╗ █████╗ ███████╗        
 *        ██║     ██║     ██╔══██╗████╗ ████║██╔══██╗██╔════╝        
 *        ██║     ██║     ███████║██╔████╔██║███████║███████╗        
 *        ██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║╚════██║        
 *        ███████╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║███████║        
 *        ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝        
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC165Storage.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Developer.sol";
import "./Counters.sol";
import "./IMAX721.sol";
import "./Whitelist.sol";
import "./IMAX721Whitelist.sol";
import "./PaymentSplitter.sol";
import "./BAYC.sol";
import "./ContractURI.sol";

contract LaidBackLlamas is ERC721, BAYC, ContractURI, IMAX721, IMAX721Whitelist, Whitelist, ERC165Storage, ReentrancyGuard, PaymentSplitter, Developer, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;
  Counters.Counter private _teamMintCounter;
  uint private mintStartID;
  uint private constant MINT_FEES = 0.1 ether;
  uint private constant PRESALE_MINT_FEES = 0.07 ether;
  uint private endOfPresale;
  uint private constant MINT_SIZE = 7000;
  uint private teamMintSize;
  string private base;
  bool private enableMinter;
  bool private enableWhiteList;
  bool private lockedProvenance;
  bool private lockedPayees;

  event UpdatedBaseURI(string _old, string _new);
  event UpdatedMintSize(uint _old, uint _new);
  event UpdatedMintStatus(bool _old, bool _new);
  event UpdatedTeamMintSize(uint _old, uint _new);
  event UpdatedWhitelistStatus(bool _old, bool _new);
  event UpdatedPresaleEnd(uint _old, uint _new);
  event ProvenanceLocked(bool _status);
  event PayeesLocked(bool _status);

  // bytes4 constants for ERC165
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_IBAYC = 0xdee68dd1;
  bytes4 private constant _INTERFACE_ID_IContractURI = 0xe8a3d485;
  bytes4 private constant _INTERFACE_ID_IMAX721 = 0x29499a25;
  bytes4 private constant _INTERFACE_ID_IMAX721Whitelist = 0x22699a34;
  bytes4 private constant _INTERFACE_ID_Whitelist = 0xc683630d;
  bytes4 private constant _INTERFACE_ID_Developer = 0x18f19aba;
  bytes4 private constant _INTERFACE_ID_PaymentSplitter = 0x4a7f18f2;

  constructor() ERC721("Laid Back Llamas", "LBL") {

    // ECR165 Interfaces Supported
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_IBAYC);
    _registerInterface(_INTERFACE_ID_IContractURI);
    _registerInterface(_INTERFACE_ID_IMAX721);
    _registerInterface(_INTERFACE_ID_IMAX721Whitelist);
    _registerInterface(_INTERFACE_ID_Whitelist);
    _registerInterface(_INTERFACE_ID_Developer);
    _registerInterface(_INTERFACE_ID_PaymentSplitter);
  }

/***
 *    ███╗   ███╗██╗███╗   ██╗████████╗
 *    ████╗ ████║██║████╗  ██║╚══██╔══╝
 *    ██╔████╔██║██║██╔██╗ ██║   ██║   
 *    ██║╚██╔╝██║██║██║╚██╗██║   ██║   
 *    ██║ ╚═╝ ██║██║██║ ╚████║   ██║   
 *    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   
 */

  function publicMint(uint amount) public payable nonReentrant(){
    require(lockedProvenance, "Set Providence hashes");
    require(enableMinter, "Minter not active");
    require(_tokenIdCounter.current() + amount <= MINT_SIZE, "Can not mint that many");
    uint yourBalance = IERC721(address(this)).balanceOf(msg.sender);
    if(enableWhiteList) {
      require(msg.value == PRESALE_MINT_FEES * amount, "Wrong amount of Native Token");
      require(isWhitelist[msg.sender], "You are not Whitelisted");
      require(yourBalance < 3 && amount + yourBalance <= 3, "You can not get that many!");
      checkTime();
      // locks them out of whitelist, soft reentrancy guard
      _removeWhitelist(msg.sender);
      for (uint i = 0; i < amount; i++) {
        _safeMint(msg.sender, mintID());
        _tokenIdCounter.increment();
      }
    } else {
      require(msg.value == MINT_FEES * amount, "Wrong amount of Native Token");
      require(yourBalance < 5 && amount + yourBalance <= 5, "You can not get that many!");
      for (uint i = 0; i < amount; i++) {
        _safeMint(msg.sender, mintID());
        _tokenIdCounter.increment();
      }
    }
  }


  function teamMint(address _address) public onlyOwner {
    require(lockedProvenance, "Set Providence hashes");
    require(teamMintSize != 0, "Team minting not enabled");
    require(_tokenIdCounter.current() < MINT_SIZE, "Can not mint that many");
    require(_teamMintCounter.current() < teamMintSize, "Can not team mint anymore");
    _safeMint(_address, mintID());
    _tokenIdCounter.increment();
    _teamMintCounter.increment();
  }

  // @notice this shifts the _tokenIdCounter to proper mint number
  function mintID() internal view returns (uint) {
    return (mintStartID + _tokenIdCounter.current()) % MINT_SIZE;
  }

  // @notice this will check time and set whitelist to disabled
  function checkTime() private {
    if(endOfPresale <= block.timestamp) {
      enableWhiteList = !enableWhiteList;
    }
  } 

  // Function to receive ether, msg.data must be empty
  receive() external payable {
    // From PaymentSplitter.sol, 99% of the time won't register
    emit PaymentReceived(msg.sender, msg.value);
  }

  // Function to receive ether, msg.data is not empty
  fallback() external payable {
    // From PaymentSplitter.sol, 99% of the time won't register
    emit PaymentReceived(msg.sender, msg.value);
  }

  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

/***
 *     ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗ 
 *    ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗
 *    ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
 *    ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
 *    ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║
 *     ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
 * This section will have all the internals set to onlyOwner
 */

  // @notice click this to start it up initally, for ease by onlyOwner
  function startMinting() public onlyOwner {
    require(lockedProvenance && lockedPayees, "Prerequisites not met");
    // This is the initial setting
    // Set Presale end time and emit
    uint prevEndOfPresale = endOfPresale;
    endOfPresale = block.timestamp + 1 days;
    emit UpdatedPresaleEnd(prevEndOfPresale, endOfPresale);
    // Set Whitelist status and emit
    bool prevWhitelist = enableWhiteList;
    enableWhiteList = true;
    emit UpdatedWhitelistStatus(prevWhitelist, enableWhiteList);
    // Set Minter Status and emit
    bool prevMintStatus = enableMinter;
    enableMinter = true;
    emit UpdatedMintStatus(prevMintStatus, enableMinter);
  }


  // @notice this will enable publicMint()
  function enableMinting() public onlyOwner {
    bool old = enableMinter;
    enableMinter = true;
    emit UpdatedMintStatus(old, enableMinter);
  }

  // @notice this will disable publicMint()
  function disableMinting() public onlyOwner {
    bool old = enableMinter;
    enableMinter = false;
    emit UpdatedMintStatus(old, enableMinter);
  }

  // @notice this will enable whitelist or "if" in publicMint()
  function enableWhitelist() public onlyOwner {
    // Set Presale end time and emit
    uint prevEndOfPresale = endOfPresale;
    endOfPresale = block.timestamp + 1 days;
    emit UpdatedPresaleEnd(prevEndOfPresale, endOfPresale);
    // Set Whitelist status and emit
    bool prevWhitelist = enableWhiteList;
    enableWhiteList = true;
    emit UpdatedWhitelistStatus(prevWhitelist, enableWhiteList);
  }

  // @notice this will disable whitelist or "else" in publicMint()
  function disableWhitelist() public onlyOwner {
    bool old = enableWhiteList;
    enableWhiteList = false;
    emit UpdatedWhitelistStatus(old, enableWhiteList);
  }
  
  // @notice adding functions to mapping
  function addWhitelistBatch(address [] memory _addresses) public onlyOwner {
    _addWhitelistBatch(_addresses);
  }

  // @notice adding functions to mapping
  function addWhitelist(address _address) public onlyOwner {
    _addWhitelist(_address);
  }

  // @notice removing functions to mapping
  function removeWhitelistBatch(address [] memory _addresses) public onlyOwner {
    _removeWhitelistBatch(_addresses);
  }

  // @notice removing functions to mapping
  function removeWhitelist(address _address) public onlyOwner {
    _removeWhitelist(_address);
  }

/***
 *    ██████╗ ███████╗██╗   ██╗
 *    ██╔══██╗██╔════╝██║   ██║
 *    ██║  ██║█████╗  ██║   ██║
 *    ██║  ██║██╔══╝  ╚██╗ ██╔╝
 *    ██████╔╝███████╗ ╚████╔╝ 
 *    ╚═════╝ ╚══════╝  ╚═══╝  
 * This section will have all the internals set to onlyDev
 * also contains all overrides required for funtionality
 */

  // @notice will add an address to PaymentSplitter by onlyDev role
  function addPayee(address newAddy, uint newShares) public onlyDev {
    require(!lockedPayees, "Can not set, payees locked");
    _addPayee(newAddy, newShares);
  }

  // @notice will lock payees on PaymentSplitter.sol
  function lockPayees() public onlyDev {
    require(!lockedPayees, "Can not set, payees locked");
    lockedPayees = true;
    emit PayeesLocked(lockedPayees);
  }

  // @notice will update _baseURI() by onlyDev role
  function setBaseURI(string memory _base) public onlyDev {
    string memory old = base;
    base = _base;
    emit UpdatedBaseURI(old, base);
  }

  // @notice will set the ContractURI for OpenSea
  function setContractURI(string memory _contractURI) public onlyDev {
    _setContractURI(_contractURI);
  }

  // @notice will set "team minting" by onlyDev role
  function setTeamMinting(uint _amount) public onlyDev {
    uint old = teamMintSize;
    teamMintSize = _amount;
    emit UpdatedTeamMintSize(old, teamMintSize);
  }

  // @notice this will set the Provenance Hashes
  // This will also set the starting order as well!
  // Only one shot to do this, otherwise it shows as invalid
  function setProvenance(string memory _images, string memory _json) public onlyDev {
    require(lockedPayees, "Can not set, payees unlocked");
    require(!lockedProvenance, "Already Set!");
    // This is the initial setting
    _setProvenanceImages(_images);
    _setProvenanceJSON(_json);
    // Now to psuedo-random the starting number
    // Your API should be a random before this step!
    mintStartID = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _images, _json, block.difficulty))) % MINT_SIZE;
    _setStartNumber(mintStartID);
    // @notice Locks sequence
    lockedProvenance = true;
    emit ProvenanceLocked(lockedProvenance);
  }

  // @notice this will set the reveal timestamp
  // This is more for your API and not on chain...
  function setRevealTimestamp(uint _time) public onlyDev {
    _setRevealTimestamp(_time);
  }

  // @notice function useful for accidental ETH transfers to contract (to user address)
  // wraps _user in payable to fix address -> address payable
  // Set to onlyOwner, this is case of a foulup on PaymentSplitter or minting
  function sweepEthToAddress(address _user, uint _amount) public onlyOwner {
    payable(_user).transfer(_amount);
  }

  ///
  /// Developer, these are the overrides
  ///

  // @notice solidity required override for _baseURI()
  function _baseURI() internal view override returns (string memory) {
    return base;
  }

  // @notice solidity required override for supportsInterface(bytes4)
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165Storage, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // @notice will return status of Minter
  function minterStatus() external view override(IMAX721) returns (bool) {
    return enableMinter;
  }

  // @notice will return minting fees
  function minterFees() external pure override(IMAX721) returns (uint) {
    return MINT_FEES;
  }

  // @notice will return presale minting fees
  function presaleMinterFees() external pure returns (uint) {
    return PRESALE_MINT_FEES;
  }

  // @notice will return maximum mint capacity
  function minterMaximumCapacity() external pure override(IMAX721) returns (uint) {
    return MINT_SIZE;
  }

  // @notice will return maximum "team minting" capacity
  function minterMaximumTeamMints() external view override(IMAX721) returns (uint) {
    return teamMintSize;
  }
  // @notice will return "team mints" left
  function minterTeamMintsRemaining() external view override(IMAX721) returns (uint) {
    return teamMintSize - _teamMintCounter.current();
  }

  // @notice will return "team mints" count
  function minterTeamMintsCount() external view override(IMAX721) returns (uint) {
    return _teamMintCounter.current();
  }

  // @notice will return current token count
  function totalSupply() external view override(IMAX721) returns (uint) {
    return _tokenIdCounter.current();
  }

  // @notice will return whitelist end timestamp
  function whitelistEnd() external view override(IMAX721Whitelist) returns (uint256) {
    return endOfPresale;
  }

  // @notice will return whitelist status of Minter
  function whitelistStatus() external view override(IMAX721Whitelist) returns (bool) {
    return enableWhiteList;
  }
}