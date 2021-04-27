/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
  uint256 public feePercentage;
  uint256 public feesCollected;
  address public admin;
  address payable public wallet;
  
  mapping(address => uint256) public balances;
  
  event Sweeped(address wallet, uint256 value);
  event Deposited(address from, uint256 value, uint256 fee);
  event FeeChanged(uint256 newFee);
  
  modifier onlyAdmin() {
    require(msg.sender == admin, "Unauthorized");
    _;
  }

  function initialize(uint256 _fee, address _admin, address payable _wallet) public {
    require(admin == address(0), "Already initialized");
    wallet = _wallet;
    admin = _admin;
    feePercentage = _fee;
  }

  function version() public virtual pure returns (string memory) {
    return "v1";
  }

  function deposit() public virtual payable {
    uint256 fee = msg.value * feePercentage / 100;
    balances[msg.sender] += (msg.value - fee);
    feesCollected += fee;
    emit Deposited(msg.sender, msg.value, fee);
  }

  function withdraw() public virtual {
    uint256 funds = balances[msg.sender];
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(funds);
  }
  
  function setFee(uint256 _fee) onlyAdmin public {
    feePercentage = _fee;
    emit FeeChanged(_fee);
  }

  function sweep() public {
    wallet.transfer(feesCollected);
    emit Sweeped(wallet, feesCollected);
    feesCollected = 0;
  }
}

contract VaultV2 is Vault {
  bool public paused;

  event Paused();
  event Unpaused();

  modifier whenNotPaused() {
    require(!paused, "Contract is paused");
    _;
  }

  function version() public override virtual pure returns (string memory) {
    return "v2";
  }

  function pause() public  onlyAdmin {
    require(!paused, "Contract already paused");
    paused = true;
    emit Paused();
  }

  function unpause() public onlyAdmin {
    require(paused, "Contract not paused");
    paused = false;
    emit Unpaused();
  }

  function withdraw() public override whenNotPaused {
    super.withdraw();
  }

  function deposit() public payable override whenNotPaused {
    super.deposit();
  }
}

contract VaultV3 is VaultV2 {
  function version() public override pure returns (string memory) {
    return "v3.5";
  }
}