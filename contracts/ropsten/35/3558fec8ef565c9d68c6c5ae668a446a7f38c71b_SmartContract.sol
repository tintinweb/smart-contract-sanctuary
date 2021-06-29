// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Roles.sol";
import "./Token_interface.sol";


contract AdminRole is Context, Ownable {
    using Roles for Roles.Role;
    using SafeMath for uint256;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    uint256 private _qty_admins = 0;
    Roles.Role private _admins;
    address[] private _signatures;

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "AdminRole: caller does not have the Admin role");
        _;
    }

    modifier onlyOwnerOrAdmin() {
      require(isAdminOrOwner(_msgSender()), "Can call only owner or admin");
      _;
    }

    function isAdminOrOwner(address account) public view returns (bool) {
        return isAdmin(account) || isOwner();
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function _addAdmin(address account) internal {

        require(!isAdmin(account) && account != owner(), "already exist");

        _admins.add(account);
        _qty_admins++;
        emit AdminAdded(account);
    }

    function addSignature4NextOperation() public onlyOwnerOrAdmin {
      bool exist = false;
      for(uint256 i=0; i<_signatures.length; i++){
        if(_signatures[i] == _msgSender()){
          exist = true;
          break;
        }
      }
      require(!exist, "already exist");
      _signatures.push(_msgSender());
    }

    function cancelSignature4NextOperation() public onlyOwnerOrAdmin {
      for(uint256 i=0; i<_signatures.length; i++){
        if(_signatures[i] == _msgSender()){
          _remove_signatures(i);
          return;
        }
      }
      require(false, "not found");
      
    }

    function checkValidMultiSignatures() public view returns(bool){
      uint256 all_signatures = _qty_admins + 1; // 1 for owner
      if(all_signatures <= 2){
        return all_signatures == _signatures.length;
      }
      uint256 approved_signatures = all_signatures.mul(2).div(3);
      return _signatures.length >= approved_signatures;
    }

    function cancelAllMultiSignatures() public onlyOwnerOrAdmin{
      uint256 l = _signatures.length;
      for(uint256 i=0; i<l; i++){
        _signatures.pop();
      }
    }

    function checkExistSignature(address account) public view returns(bool){
      bool exist = false;
      for(uint256 i=0; i<_signatures.length; i++){
        if(_signatures[i] == account){
          exist = true;
          break;
        }
      }
      return exist;
    }

    function m_signaturesTransferOwnership(address newOwner) public onlyOwnerOrAdmin {
      require(isOwner() || checkValidMultiSignatures(), "Has not all needed signatures");
      transferOwnership(newOwner);
      cancelAllMultiSignatures();
    }

    function _remove_signatures(uint index) private {
      if (index >= _signatures.length) return;
      for (uint i = index; i<_signatures.length-1; i++){
        _signatures[i] = _signatures[i+1];
      }
      _signatures.pop();
    }

}

// https://solidity-by-example.org/signature/

contract VerifySignature{
    
    function getMessageHash(address holder, uint _maxvalue) public pure returns (bytes32){
        return keccak256(abi.encodePacked(holder, _maxvalue));
    }

    function getSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, address holder, uint _maxvalue, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(holder, _maxvalue);
        bytes32 signedMessageHash = getSignedMessageHash(messageHash);
        return recoverSigner(signedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _signedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_signedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
}


contract SmartContract is AdminRole, VerifySignature{
  using SafeMath for uint256;

  event SaleInfo(address indexed to, uint256 coinsvalue, uint256 tokensvalue, uint256 allowed_coinsvalue, uint256 allowed_tokensvalue);

  Token_interface public coinToken;
  Token_interface public projectToken;

  uint256 private _token_exchange_rate = 273789679021000; //0.000273789679021 USDT per 1 project token

  address signer_address;

  mapping(address => uint256) private _sold_amounts;
  uint256 private _totalsold = 0;
  address[] private _participants;

  struct PhaseParams{
    string NAME;
    bool IS_STARTED;
    bool IS_FINISHED;
  }

  PhaseParams[] public phases;
  uint256 constant PHASES_COUNT = 3;

  constructor () public {

    signer_address = address(0x1234567890123456789012345678901234567890);

    coinToken = Token_interface(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // Token Tether USD 0xdAC17F958D2ee523a2206206994597C13D831ec7 https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7
    projectToken = Token_interface(address(0x2234567890123456789012345678901234567890));

    _addAdmin(address(0x1234567890123456789012345678901234567890));
    _addAdmin(address(0x2234567890123456789012345678901234567890));
    _addAdmin(address(0x3234567890123456789012345678901234567890));

    // 0 - first
    PhaseParams memory phaseFirst;
    phaseFirst.NAME = "Initialize";
    phaseFirst.IS_STARTED = false;
    phaseFirst.IS_FINISHED = false;
    phases.push(phaseFirst);

    // 1 - second
    PhaseParams memory phaseSecond;
    phaseSecond.NAME = "Sales";
    phaseSecond.IS_STARTED = false;
    phaseSecond.IS_FINISHED = false;
    phases.push(phaseSecond);

    // 2 - last - last
    PhaseParams memory phaseThird;
    phaseThird.NAME = "Finalize";
    phaseThird.IS_STARTED = false;
    phaseThird.IS_FINISHED = false;
    phases.push(phaseThird);
    
    assert(PHASES_COUNT == phases.length);

    phases[0].IS_STARTED = true;
  }

  //
  // ####################################
  //

  receive() external payable {
    require( false, "Contract cannot to receive standard network value.");
  }

  function coinout(address payable recipient, uint256 value) public onlyOwnerOrAdmin{
    require(checkValidMultiSignatures(), "Has not all needed signatures");

    Token_interface ct = Token_interface(address(this));
    ct.transfer(recipient, value);

    cancelAllMultiSignatures();
  }

  function getRate() public view returns(uint256){
    return _token_exchange_rate;
  }

  function getSoldAmount(address holder) public view returns(uint256){
    return _sold_amounts[holder];
  }

  function totalsold() public view returns (uint256) {
      return _totalsold;
  }

  function getParticipantAddressByIndex(uint256 index) public view returns(address){
    return _participants[index];
  }

  function participants_qty() public view returns(uint256){
    return _participants.length;
  }

  //
  // ####################################
  //


  function setDataSignerAddress(address _signer) public onlyOwnerOrAdmin{
    uint256 i = getCurrentPhaseIndex();
    require((i == 0 || i == 1) && !phases[i].IS_FINISHED, "Not Allowed phase"); // Not Finalize
    
    require(checkValidMultiSignatures(), "Has not all needed signatures");

    signer_address = _signer;
    
    cancelAllMultiSignatures();
  }


  function get_holder_available_token_value(address _holder, uint256 _maxProjectTokens, bytes memory _signedData) public view returns (uint256){
    require(verify(signer_address, _holder, _maxProjectTokens, _signedData), "Incoming data have incorrectly signed");
    uint256 c = getSoldAmount(_holder);
    return _maxProjectTokens - c;
  }

  function is_holder_available_token_value(address _holder, uint256 _needed_project_token_value, uint256 _maxProjectTokens, bytes memory _signedData) public view returns (bool){
    uint256 v = get_holder_available_token_value(_holder, _maxProjectTokens, _signedData);
    if(v == 0 || _needed_project_token_value == 0){ return false; }
    return v >= _needed_project_token_value;
  }


  function burn_allowanced_value(uint256 _projectTokens, uint256 _maxProjectTokens, bytes memory _signedData) public{
    uint256 i = getCurrentPhaseIndex();
    require(i == 1, "Not Allowed phase"); // First phase

    address sender = _msgSender();

    require(is_holder_available_token_value(sender, _projectTokens, _maxProjectTokens, _signedData), "Client limited by max value");
    
    uint256 topay_value = (_projectTokens * _token_exchange_rate).div(10**coinToken.decimals());
    uint256 c_value = coinToken.allowance(sender, address(this));
    require(c_value >= topay_value, "Client hasn't Allowed value");

    uint256 p_toke_value = projectToken.allowance(signer_address, address(this));
    require(p_toke_value >= _projectTokens, "Project Tokens Not Allowed value");

    emit SaleInfo(sender, topay_value, _projectTokens, c_value, p_toke_value);

    require(coinToken.transferFrom(sender, address(this), topay_value), "Error with incoming transferFrom");
    require(coinToken.transferFrom(signer_address, sender, _projectTokens), "Error with outgoing transferFrom");

    if(_sold_amounts[sender] == 0){
      _participants.push(sender);
    }

    _sold_amounts[sender] = _sold_amounts[sender].add(_projectTokens);
    _totalsold = _totalsold.add(_projectTokens);
  }

  

  function finize() public onlyOwnerOrAdmin{
    uint256 i = getCurrentPhaseIndex();
    require(i == 2 && !phases[i].IS_FINISHED, "Not Allowed phase"); // Finalize

    require(checkValidMultiSignatures(), "Has not all needed signatures");

    signer_address = address(0x00); // set as unavailable

    cancelAllMultiSignatures();
  }

  //
  // ####################################
  //

  function startNextPhase() public onlyOwnerOrAdmin{
    uint256 i = getCurrentPhaseIndex();
    require((i+1) < PHASES_COUNT);
    require(phases[i].IS_FINISHED);
    phases[i+1].IS_STARTED = true;
  }

  function finishCurrentPhase() public onlyOwnerOrAdmin{
    uint256 i = getCurrentPhaseIndex();
    phases[i].IS_FINISHED = true;

    if ((i+1) == PHASES_COUNT){ // is Finalize and Close
      // pass
    }
  }

  function revertAbovePhase() public onlyOwnerOrAdmin{
    uint256 i = getCurrentPhaseIndex();

    require(i > 0, "Initialize phase has already active");

    phases[i].IS_STARTED = false;
    phases[i].IS_FINISHED = false;

    phases[i-1].IS_STARTED = true;
    phases[i-1].IS_FINISHED = false;    
  }

  function PHASE() public view returns(string memory){
    uint256 i = getCurrentPhaseIndex();
    return phases[i].NAME;
  }

  function getCurrentPhaseIndex() public view returns (uint256){
    uint256 current_phase = 0;
    for (uint256 i = 0; i < PHASES_COUNT; i++)
    {
      if (phases[i].IS_STARTED) {
        current_phase = i;
      }

    }
    return current_phase;
  }

}