// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Roles.sol";
import "./ProjectToken_interface.sol";
import "./TetherToken_interface.sol";


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
        _qty_admins = _qty_admins.add(1);
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
      uint256 all_signatures = _qty_admins.add(1); // 1 for owner
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
      require(isOwner() || checkValidMultiSignatures(), "There is no required number of signatures");
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


contract DinoX is AdminRole, VerifySignature{
  using SafeMath for uint256;

  event TokensaleInfo(address indexed signer, uint256 coinsvalue, uint256 tokensvalue, uint256 holder_max_project_tokens, uint256 allowed_coinsvalue, uint256 allowed_tokensvalue);

  // sales status id
  uint8 private _tokensale_status;

  address public currency_token_address;
  TetherToken_interface private _currency_token;

  address public project_token_address;
  ProjectToken_interface private _project_token;

  uint256 private _token_price;

  address private _signer_address;

  mapping(address => uint256) private _sold_amounts;
  uint256 private _totalsold = 0;
  address[] private _participants;

  constructor () public {

    // set the sales status id as: "disabled
    _tokensale_status = 2;

    //set the sale price for 1 token
    _token_price = 25000;

    // set the address that stores Tokens and signs data from the white list
    _signer_address = address(0xEe3EA17E0Ed56a794e9bAE6F7A6c6b43b93333F5);

    // set the address of a currency smart contract
    // e.g. Token Tether (USDT) address is 0xdAC17F958D2ee523a2206206994597C13D831ec7
    currency_token_address = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    _currency_token = TetherToken_interface(currency_token_address);

    // set the address of the smart contract of the project token
    project_token_address = address(0xF7a8b369697EA3d3505092c3a95daF3e8BB72e4C);
    _project_token = ProjectToken_interface(project_token_address);

    // set administrators
    _addAdmin(address(0x92C3b65677700eD595DA15A402f5d7C9A10a4e49));
    _addAdmin(address(0x1489a398BeB2171D48C458CfbA9Cf1Bd739C0438));
    _addAdmin(address(0xd0cF831E3a2E171220094C066Ec4263d24c0C715));

    // transfer ownership from a deployer to 0x0000000000000000000000000000000000000000
    transferOwnership(address(0));
  }

  // returns the current sales status
  function saleStatus() public view returns(string memory){
    if(_tokensale_status == 0){
      return "Closed";
    }else if(_tokensale_status == 1){
      return "Active";
    }else if(_tokensale_status == 2){
      return "Disabled";
    }
    return "Unknown"; //impossible
  }

  // blocking the reception of a standard coin of network
  receive() external payable {
    require(false, "The contract does not accept the base coin of network.");
  }

  // this method allows admin of the smart contract to withdraw tokens
  // from smart contract. This can be done before or after stopTokensale()
  function tokenWithdrawal(address token_address, address recipient, uint256 value) public onlyOwnerOrAdmin {
    require(checkValidMultiSignatures(), "There is no required number of signatures");

    TetherToken_interface ct = TetherToken_interface(token_address);

    /////
    ///// Tether Token does not return bool when calling transfer
    /////
    // // withdraw USDT from the customer
    // require(ct.transfer(recipient, value), "USDT withdrawal error");
    /////
    ///// without call require
    /////
    ct.transfer(recipient, value);

    cancelAllMultiSignatures();
  }

  // this method allows admin of the smart contract to withdraw USDT
  // from smart contract. This can be done before or after stopTokensale()
  function USDTWithdrawal(address recipient, uint256 value) public onlyOwnerOrAdmin {
    tokenWithdrawal(currency_token_address, recipient, value);
  }

  // get price of 1 token in USDT
  function getTokenPrice() public view returns(uint256){
    return _token_price;
  }

  // Total tokens sold to specified address.
  function totalTokensSoldByAddress(address holder) public view returns(uint256){
    return _sold_amounts[holder];
  }

  // The amount of tokens sold so far.
  function totalTokensSold() public view returns (uint256) {
      return _totalsold;
  }

  // get the participant address by her index starting from 0.
  function getParticipantAddressByIndex(uint256 index) public view returns(address){
    return _participants[index];
  }

  // Get the number of participants that have purchased more than 0 tokens.
  function getNumberOfParticipants() public view returns(uint256){
    return _participants.length;
  }


  function setWhitelistAuthorityAddress(address signer) public onlyOwnerOrAdmin {
      // Set a different address of whitelist authority. This address will be used to sign "Purchase Certificates".
      // Purchase certificates are items of the white list indicatoing that the client has the right
      // to buy stated amount of tokens.
    require(checkValidMultiSignatures(), "There is no required number of signatures");

    require(_tokensale_status > 0, "Sales closed");

    _signer_address = signer;

    cancelAllMultiSignatures();
  }


  //function get_holder_available_token_value(address _holder, uint256 _maxProjectTokens, bytes memory _signedData) public view returns (uint256) {
  function getRemainingBalance(address holder, uint256 holder_max_project_tokens, bytes memory signature) public view returns (uint256) {
    // The remaining amount of tokens msg.sender has the right to purchase. This takes into account the
    // previously purchased tokens.
    require(verify(_signer_address, holder, holder_max_project_tokens, signature), "Incoming data have incorrectly signed");
    uint256 c = totalTokensSoldByAddress(holder);
    return holder_max_project_tokens.sub(c);
  }

  // function is_holder_available_token_value(address _holder, uint256 _needed_project_token_value, uint256 _maxProjectTokens, bytes memory _signedData) public view returns (bool){
  function checkEligibility(address holder, uint256 require_token_value, uint256 holder_max_project_tokens, bytes memory signature) public view returns (bool){
    // Check if msg.sender is eligible to buy the stated amount of tokens.
    uint256 v = getRemainingBalance(holder, holder_max_project_tokens, signature);
    if(v == 0 || require_token_value == 0){ return false; }
    return v >= require_token_value;
  }

  // function burn_allowanced_value(uint256 _projectTokens, uint256 _maxProjectTokens, bytes memory _signedData) public{
  // the main method of the smart contract that allows to purchase the project tokens
  // for USDT.
  function tokenPurchase(uint256 require_token_value, uint256 holder_max_project_tokens, bytes memory signature) public{

    // check that sales are open
    require(_tokensale_status==1, "Sales are not allowed");
    require(require_token_value > 0, "The requested amount of tokens for purchase must be greater than 0 (zero)");

    address sender = _msgSender();

    // check the permitted limits for purchase tokens for the customer
    require(checkEligibility(sender, require_token_value, holder_max_project_tokens, signature), "Customer limited by max value");

    // calculate the price for the specified purchase tokens value
    uint256 topay_value = require_token_value.mul(_token_price).div(10**_project_token.decimals());

    // check customer USDT balance
    uint256 c_value = _currency_token.balanceOf(sender);
    require(c_value >= topay_value, "The customer does not have enough USDT balance");

    // check allowed USDT value for transfer from the customer
    c_value = _currency_token.allowance(sender, address(this));
    require(c_value >= topay_value, "Smart contact is not entitled to such an USDT amount");

    // check the balance of project tokens for sale
    uint256 p_value = _project_token.balanceOf(_signer_address);
    require(p_value >= require_token_value, "The holder does not have enough project token balance");

    // check allowed project tokens value for transfer to the customer
    p_value = _project_token.allowance(_signer_address, address(this));
    require(p_value >= require_token_value, "Smart contact is not entitled to such a project token amount");

    // write information about purchase to events
    emit TokensaleInfo(_signer_address, topay_value, require_token_value, holder_max_project_tokens, c_value, p_value);

    /*
    //
    // Warning:
       USDT transferFrom has not return the result bool value
       and has not perform the necessary checks.
       !!! Do not remove all of the above checks, as this may damage the smart contract.!!!
    //
    */

    /////
    ///// Tether Token does not return bool when calling transferFrom
    /////
    // // withdraw USDT from the customer
    // require(_currency_token.transferFrom(sender, address(this), topay_value), "USDT withdrawal error");
    // // transfer project tokens to the customer
    // require(_project_token.transferFrom(_signer_address, sender, require_token_value), "Project Token transfer error");
    /////
    ///// without call require
    /////
    // withdraw USDT from the customer
    _currency_token.transferFrom(sender, address(this), topay_value);
    // transfer project tokens to the customer
    _project_token.transferFrom(_signer_address, sender, require_token_value);
    /////
    /////

    // add the customer's address to the list of participants
    if(_sold_amounts[sender] == 0){
      _participants.push(sender);
    }

    // calculate the total amount of purchased tokens by the customer
    _sold_amounts[sender] = _sold_amounts[sender].add(require_token_value);
    // calculate the total amount of purchased tokens by smart contact
    _totalsold = _totalsold.add(require_token_value);
  }

  // Stops the sales. After this method is called, no further purchases may take place.
  // This can be reverted. If there are unsold tokens, they can to sell later.
  function stopSales() public onlyOwnerOrAdmin{

    require(checkValidMultiSignatures(), "There is no required number of signatures");

    require(_tokensale_status > 0, "Sales is close");

    _tokensale_status = 2;

    cancelAllMultiSignatures();
  }

  // Start the sales. After this method is called, smart contract will opened selles.
  // This can be reverted.
  function startSales() public onlyOwnerOrAdmin{

    require(checkValidMultiSignatures(), "There is no required number of signatures");

    require(_tokensale_status > 0, "Sales is close");

    _tokensale_status = 1;

    cancelAllMultiSignatures();
  }


  // Close the sales. After this method is called, no further purchases may take place.
  // This can not be reverted. If there are unsold tokens they will remain with the
  // original holder of the tokens that issued allowence for this contract to
  // sell them.
  function stopTokensale() public onlyOwnerOrAdmin{
    require(checkValidMultiSignatures(), "There is no required number of signatures");

    // reset the address of the signature and the holder of the tokens for sale
    _signer_address = address(0);

    // set the sales status index to "Closed"
    _tokensale_status = 0;

    cancelAllMultiSignatures();
  }

}