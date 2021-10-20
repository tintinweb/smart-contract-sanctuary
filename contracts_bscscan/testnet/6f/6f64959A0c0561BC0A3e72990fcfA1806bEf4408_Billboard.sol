// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./utils/stringUnpacker.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Billboard is Ownable {
    struct Advertisement {
        string messageData;
        address op;
        uint256 value;
        uint256 inst_value;
        uint64 timestamp;
        bool exists;
        bool display;
    }

    // messageData is a single string composed of multiple fields that can be dissected to create a listing card.
    // the library stringUnpacker exposes these fields on-chain, but it's recommended that card generation be done
    // on the frontend to avoid excessive calls to the chain.

    // Global Variabes

    uint postCreationMin = 1000000;
    uint bumpValueMin = 1000000;
    bool pauseBillboard = false;
    address charityWallet;

    // Structural variables
    mapping (uint => Advertisement) public advertisements;
    uint public numAdvertisements;
    string public separator = '`';

    event NewAdvertisementAdded(uint advertisementID, string _messageData, address _op, uint value, uint inst_value, uint timestamp, bool display);
    event ValueToAdvertisementAdded(uint advertisementID, string _messageData, address _op, uint value, uint inst_value, uint timestamp, bool display);

    function addNewAdvertisement(string memory _messageData) external payable returns (uint advertisementID) {
        require(pauseBillboard == false, "Billboard is paused");
        require(msg.value > postCreationMin, "Post value below minimum");

        advertisementID = numAdvertisements++;

        advertisements[advertisementID] = Advertisement({
            messageData: _messageData,
            op: tx.origin,
            value: msg.value,
            inst_value: msg.value,
            timestamp: uint64(block.timestamp),
            exists: true,
            display: true
        });
        emit NewAdvertisementAdded(advertisementID, _messageData, tx.origin, msg.value, msg.value, block.timestamp, true);
    }

    function addValueToAdvertisement(uint advertisementID) external payable {
        require(pauseBillboard == false, "Billboard is paused");
        require(msg.value > postCreationMin, "Bump below minimum");
        Advertisement storage advertisement = advertisements[advertisementID];
        require(advertisement.exists == true, "No post at this index");
        advertisement.value += msg.value;
        advertisement.inst_value = msg.value;
        advertisement.timestamp = uint64(block.timestamp);

        emit ValueToAdvertisementAdded(
          advertisementID,
          advertisement.messageData,
          advertisement.op,
          advertisement.value,
          advertisement.inst_value,
          advertisement.timestamp,
          advertisement.display);
    }

    function deleteAdvertisement(uint advertisementID) external onlyOwner {       //Look into rulesets to tie into (country/platform) Terroristic threats, hate speech, calls for violent action
      delete advertisements[advertisementID];                                     //add display flag, allow setting to false
    }

    function update_post_fees(uint _postCreationMin, uint _bumpValueMin) external onlyOwner {
      postCreationMin = _postCreationMin;
      bumpValueMin = _bumpValueMin;
    }

    function getBalance() internal view returns(uint) {
        return address(this).balance;
    }

    //Make onlyOwner
    function withdrawMoney() external { //Implment 3 account system + charity wallet 10%
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function withdrawMoney_charity() external onlyOwner {
        require(charityWallet != address(0), "Charity wallet at 0 address");
        uint total = getBalance();
        uint devPay = (total * 9000 / 10000);
        payable(msg.sender).transfer(devPay);
        payable(charityWallet).transfer(total - devPay);
    }

    function setBillboardPause(bool _pauseBillboard) external onlyOwner {
        pauseBillboard = _pauseBillboard;
    }

    function setDisplay(uint advertisementID, bool _display) external onlyOwner {
        Advertisement storage advertisement = advertisements[advertisementID];
        advertisement.display = _display;
    }

    function setCharityWallet(address _charityWallet) external onlyOwner {
        charityWallet = _charityWallet;
    }

    function boom() external onlyOwner { // Remove for final version
        selfdestruct(payable(msg.sender));
    }

    //string unpackers

    function getEntryName(uint adID) public view returns(string memory) {
      string memory searchString = advertisements[adID].messageData;
      string memory startKey = string(abi.encodePacked(separator, "0"));
      string memory endKey = string(abi.encodePacked(separator, "1"));
      return stringUnpacker.findInString(startKey, endKey, searchString);
    }

    function getEntrySymbol(uint adID) public view returns(string memory) {
      string memory searchString = advertisements[adID].messageData;
      string memory startKey = string(abi.encodePacked(separator, "1"));
      string memory endKey = string(abi.encodePacked(separator, "2"));
      return stringUnpacker.findInString(startKey, endKey, searchString);
    }

    function getEntryChat(uint adID) public view returns(string memory) {
      string memory searchString = advertisements[adID].messageData;
      string memory startKey = string(abi.encodePacked(separator, "2"));
      string memory endKey = string(abi.encodePacked(separator, "3"));
      return stringUnpacker.findInString(startKey, endKey, searchString);
    }

    function getEntryWebsite(uint adID) public view returns(string memory) {
      string memory searchString = advertisements[adID].messageData;
      string memory startKey = string(abi.encodePacked(separator, "3"));
      string memory endKey = string(abi.encodePacked(separator, "4"));
      return stringUnpacker.findInString(startKey, endKey, searchString);
    }

    function getEntryUsername(uint adID) public view returns(string memory) {
      string memory searchString = advertisements[adID].messageData;
      string memory startKey = string(abi.encodePacked(separator, "4"));
      string memory endKey = string(abi.encodePacked(separator, "5"));
      return stringUnpacker.findInString(startKey, endKey, searchString);
    }

    function getEntryMessage(uint adID) public view returns(string memory) {
      string memory searchString = advertisements[adID].messageData;
      string memory startKey = string(abi.encodePacked(separator, "5"));
      string memory endKey = string(abi.encodePacked(separator, "6"));
      return stringUnpacker.findInString(startKey, endKey, searchString);
    }
    // important to receive ETH
    receive() payable external {}
}

pragma solidity ^0.8.4;

library stringUnpacker {

  // String slicer/unpacker library by Mr. Idiot.
  // These functions are intended to be used by front-end calls, NOT
  // smart contract calls. Integrating any of these functions into a
  // write is likely to be extremely gas-expensive.

  function _getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
      bytes memory a = new bytes(end-begin+1);
      for(uint i=0;i<=end-begin;i++){
          if (i>4){ //drop leading filter
            a[i] = bytes(text)[i+begin-1];
          }
      }
      return string(a);
  }

  function _find (string memory startKey, string memory endKey, string memory searchString) internal pure returns (uint, uint) {
    bytes memory startBytes = bytes (startKey);
    bytes memory endBytes = bytes (endKey);
    bytes memory searchStringBytes = bytes (searchString);
    uint posStart;
    uint posEnd;

    for (uint i = 0; i <= searchStringBytes.length - startBytes.length; i++) {
      bool startFlag = true;
      for (uint j = 0; j < startBytes.length; j++)
        if (searchStringBytes [i + j] != startBytes [j]) {
          startFlag = false;
          break;
        }
        if (startFlag) {
          posStart = i;
          break;
        }
    }

    for (uint i = posStart+1; i <= searchStringBytes.length - endBytes.length; i++) {
      bool endFlag = true;
      for (uint j = 0; j < endBytes.length; j++)
        if (searchStringBytes [i + j] != endBytes [j]) {
          endFlag = false;
          break;
        }
        if (endFlag) {
          posEnd = i;
          break;
        }
    }
    return (posStart, posEnd);

  }

  function findInString(string memory startKey, string memory endKey, string memory searchString) internal pure returns (string memory) {
    uint posStart;
    uint posEnd;
    string memory slice;
    (posStart, posEnd) = _find(startKey, endKey, searchString);
    slice = _getSlice(posStart, posEnd, searchString);
    return slice;
  }
}