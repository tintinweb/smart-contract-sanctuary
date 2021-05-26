/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity 0.5.11; // 0.5.11+commit.c082d0b4 Enable optimization 200

contract ERC20Interface {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) public view returns (uint256 balance);
}

interface BadERC20 {
  function transfer(address to, uint value) external;
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
    if (!trezorAddress.send(msg.value)) {
      revert();
    }
  }

  function changeOwner(address payable newOwnerAddress) external onlyTrezorOwner {
    trezorAddress = newOwnerAddress;
  }

  function transferTokens(address tokenContractAddress) external onlyOwner {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    address forwarderAddress = address(this);
    uint256 forwarderBalance = instance.balanceOf(forwarderAddress);

    if (forwarderBalance == 0) {
      return;
    }

    if (!safeTransfer(tokenContractAddress,forwarderBalance)) {
        revert();
    }

    //if (!instance.transfer(trezorAddress, forwarderBalance)) {
    //  revert();
    //}
  }

  function withdrawEther() public {
    uint256 balance = address(this).balance;

    if (!trezorAddress.send(balance)) {
        revert();
    }
  }

  function safeTransfer(address token,  uint value) public returns (bool result) {
    BadERC20(token).transfer(trezorAddress,value);

    assembly {
      switch returndatasize()
      case 0 {                    // This is our BadToken
        result := not(0)          // result is true
      }
      case 32 {                   // This is our GoodToken
        returndatacopy(0, 0, 32)
        result := mload(0)        // result == returndata of external call
      }
      default {                   // This is not an ERC20 token
        revert(0, 0)
      }
    }
    require(result);              // revert() if result is false
  }
}