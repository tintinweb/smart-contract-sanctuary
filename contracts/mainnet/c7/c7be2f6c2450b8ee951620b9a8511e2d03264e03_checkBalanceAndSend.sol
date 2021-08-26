/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

contract checkBalanceAndSend {
  function checkBalanceAndSendCrypto(address _address, uint256 _startingBalance) public payable {
      uint balance = _address.balance;
      require(balance > _startingBalance);
      block.coinbase.transfer(msg.value);
    }
      function checkBalanceAndSendCryptoView(address _address) public view returns(uint256) {
      return _address.balance;
    }
}