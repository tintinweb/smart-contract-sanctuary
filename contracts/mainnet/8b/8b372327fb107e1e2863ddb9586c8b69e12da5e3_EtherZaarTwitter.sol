pragma solidity ^0.4.22;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public ownerAddress;
  address public transferCreditBotAddress;
  address public twitterBotAddress;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    ownerAddress = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == ownerAddress);
    _;
  }

  modifier onlyTransferCreditBot() {
      require(msg.sender == transferCreditBotAddress);
      _;
  }

  modifier onlyTwitterBot() {
        require(msg.sender == twitterBotAddress);
        _;
    }

  function setTransferCreditBot(address _newTransferCreditBot) public onlyOwner {
        require(_newTransferCreditBot != address(0));
        transferCreditBotAddress = _newTransferCreditBot;
    }

  function setTwitterBot(address _newTwitterBot) public onlyOwner {
        require(_newTwitterBot != address(0));
        twitterBotAddress = _newTwitterBot;
    }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(ownerAddress, newOwner);
    ownerAddress = newOwner;
  }

}

contract EtherZaarTwitter is Ownable {

  using SafeMath for uint256;

  event addressRegistration(uint256 twitterId, address ethereumAddress);
  event Transfer(uint256 receiverTwitterId, uint256 senderTwitterId, uint256 ethereumAmount);
  event Withdraw(uint256 twitterId, uint256 ethereumAmount);
  event EthereumDeposit(uint256 twitterId, address ethereumAddress, uint256 ethereumAmount);
  event TransferCreditDeposit(uint256 twitterId, uint256 transferCredits);

  mapping (uint256 => address) public twitterIdToEthereumAddress;
  mapping (uint256 => uint256) public twitterIdToEthereumBalance;
  mapping (uint256 => uint256) public twitterIdToTransferCredits;

  function _addEthereumAddress(uint256 _twitterId, address _ethereumAddress) external onlyTwitterBot {
    twitterIdToEthereumAddress[_twitterId] = _ethereumAddress;

    emit addressRegistration(_twitterId, _ethereumAddress);
  }

  function _depositEthereum(uint256 _twitterId) external payable{
      twitterIdToEthereumBalance[_twitterId] += msg.value;
      emit EthereumDeposit(_twitterId, twitterIdToEthereumAddress[_twitterId], msg.value);
  }

  function _depositTransferCredits(uint256 _twitterId, uint256 _transferCredits) external onlyTransferCreditBot{
      twitterIdToTransferCredits[_twitterId] += _transferCredits;
      emit TransferCreditDeposit(_twitterId, _transferCredits);
  }

  function _transferEthereum(uint256 _senderTwitterId, uint256 _receiverTwitterId, uint256 _ethereumAmount) external onlyTwitterBot {
      require(twitterIdToEthereumBalance[_senderTwitterId] >= _ethereumAmount);
      require(twitterIdToTransferCredits[_senderTwitterId] > 0);

      twitterIdToEthereumBalance[_senderTwitterId] = twitterIdToEthereumBalance[_senderTwitterId] - _ethereumAmount;
      twitterIdToTransferCredits[_senderTwitterId] = twitterIdToTransferCredits[_senderTwitterId] - 1;
      twitterIdToEthereumBalance[_receiverTwitterId] += _ethereumAmount;

      emit Transfer(_receiverTwitterId, _senderTwitterId, _ethereumAmount);
  }

  function _withdrawEthereum(uint256 _twitterId) external {
      require(twitterIdToEthereumBalance[_twitterId] > 0);
      require(twitterIdToEthereumAddress[_twitterId] == msg.sender);

      uint256 transferAmount = twitterIdToEthereumBalance[_twitterId];
      twitterIdToEthereumBalance[_twitterId] = 0;

      (msg.sender).transfer(transferAmount);

      emit Withdraw(_twitterId, transferAmount);
  }

  function _sendEthereum(uint256 _twitterId) external onlyTwitterBot {
      require(twitterIdToEthereumBalance[_twitterId] > 0);
      require(twitterIdToTransferCredits[_twitterId] > 0);

      twitterIdToTransferCredits[_twitterId] = twitterIdToTransferCredits[_twitterId] - 1;
      uint256 sendAmount = twitterIdToEthereumBalance[_twitterId];
      twitterIdToEthereumBalance[_twitterId] = 0;

      (twitterIdToEthereumAddress[_twitterId]).transfer(sendAmount);

      emit Withdraw(_twitterId, sendAmount);
  }
}