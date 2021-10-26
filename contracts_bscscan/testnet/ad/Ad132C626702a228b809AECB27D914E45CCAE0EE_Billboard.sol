// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

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
    }

    // messageData is a single string composed of multiple fields that can be dissected to create a listing card.
    // the library stringUnpacker exposes these fields on-chain, but it's recommended that card generation be done
    // on the frontend to avoid excessive calls to the chain.

    // Global Variabes

    uint postCreationMin = 1000000;
    uint bumpValueMin = 1000000;
    bool pauseBillboard = false;
    address treasury;
    address paymentAdd;
    uint treasuryRate;

    // Structural variables
    mapping (uint => Advertisement) public advertisements;
    uint public numAdvertisements;

    event NewAdvertisementAdded(uint advertisementID, string _messageData, address _op, uint value, uint inst_value, uint timestamp);
    event ValueToAdvertisementAdded(uint advertisementID, string _messageData, address _op, uint value, uint inst_value, uint timestamp);

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
            exists: true
        });
        emit NewAdvertisementAdded(
          advertisementID,
          _messageData,
          tx.origin,
          msg.value,
          msg.value,
          block.timestamp);
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
          advertisement.timestamp);
    }

    function updatePostFees(uint _postCreationMin, uint _bumpValueMin) external onlyOwner {
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

    function withdrawMoneyTreasury() external onlyOwner {
        require(treasury != address(0), "Charity wallet at 0 address");
        uint total = getBalance();
        uint toTreasury = (total * treasuryRate / 10000);
        payable(treasury).transfer(toTreasury);
        payable(paymentAdd).transfer(total - toTreasury); //update 'trasfer' to 'call';
    }

    function setBillboardPause(bool _pauseBillboard) external onlyOwner { //Maybe remove?
        pauseBillboard = _pauseBillboard;
    }

    function setPaymentAdd(address _paymentAdd) external onlyOwner {
        paymentAdd = _paymentAdd;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setTreasuryRate(uint _treasuryRate) external onlyOwner {
        treasuryRate = _treasuryRate;
    }
    // important to receive ETH
    receive() payable external {}
}