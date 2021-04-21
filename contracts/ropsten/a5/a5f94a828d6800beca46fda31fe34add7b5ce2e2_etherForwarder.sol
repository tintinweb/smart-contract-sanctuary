/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity 0.5.11;
contract ERC20Interface {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) public view returns (uint256 balance);
}

contract etherForwarder {
  address payable public ownerAddress;
  address payable public trezorAddress;

  constructor(address payable _trezorAddress) public {
    ownerAddress = msg.sender;
    trezorAddress = _trezorAddress;
  }

  modifier onlyOwner {
    if (msg.sender != ownerAddress) {
      revert();
    }
    _;
  }
  
  modifier onlyTrezorOwner {
    if (msg.sender != trezorAddress) {
      revert();
    }
    _;
  }

  function() external payable {
    if (!trezorAddress.send(msg.value)){
      revert();
    }
  }

  function changeOwner(address payable newOwnerAddress) public onlyTrezorOwner {
      trezorAddress = newOwnerAddress;
  }

  function transferTokens(address tokenContractAddress) public onlyOwner {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    address forwarderAddress = address(this);
    uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(trezorAddress, forwarderBalance)) {
      revert();
    }
  }

  function withdrawEther() public {
    uint256 balance = address(this).balance;
    if (!trezorAddress.send(balance)){
        revert();
    }
  }
}