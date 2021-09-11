// V1:
// Contract ADDRESS Goerli :  0x742411Df38B834fbEc20AA2930Dc7ef4FC31b631
// Deployer :   0x1aA2Df70fBa9dE5882dCa7391B6Cb754B328C795

// V2:
// address contract: 0x0071682c1018073cc594b9B978794aa66d620157
//







/*
 * I would like to ensure that this code is correct.
 * I explain above each function what I would like it to do.
 * Anyone familiar with RocketPool please help :)
 */

pragma solidity ^0.8.0;

/* import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; */
import "./SafeMath.sol";
import "./Ownable.sol";


import "./RocketStorageInterface.sol";
import "./RocketDepositPoolInterface.sol";
import "./RocketTokenRETHInterface.sol";


contract RocketPool_TEST is Ownable {

  using SafeMath for uint;
  RocketStorageInterface rocketStorage = RocketStorageInterface(address(0x0));

  uint public totalEthStaked = 0;
  uint public ethToStake = 0;

  constructor(address _rocketStorageAddress) {
    rocketStorage = RocketStorageInterface(_rocketStorageAddress);
  }



  /*
   * When someone calls this function I want the msg.value to be deposited (staked) into RocketPool.
   * And I want the rETH minted to belong to this contract address.
   */
  function depositToPool() external {
    require(ethToStake >= 0.01 ether, "Invalid deposit amount");

    // Load Rocket contracts
    address rocketDepositPoolAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketDepositPool")));
    RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(rocketDepositPoolAddress);
    address rocketTokenRETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
    RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);

    // Forward deposit to RocketPool & get amount of rETH minted
    uint256 rethBalance1 = rocketTokenRETH.balanceOf(address(this));
    rocketDepositPool.deposit{value: ethToStake}();
    uint256 rethBalance2 = rocketTokenRETH.balanceOf(address(this));
    require(rethBalance2 > rethBalance1, "No rETH was minted");

    //uint256 rethMinted = rethBalance2 - rethBalance1;
    //require(rocketTokenRETH.transfer(msg.sender, rethMinted), "rETH was not transferred to caller");

    // Now we keep track of the total ETH that has been staked.
    totalEthStaked = totalEthStaked.add(ethToStake);
    ethToStake = 0;
  }



  /*
   * I want this function to tell me how much rewards are claimable without withdrawing the totalEthStaked deposits.
   * This should return the rewards amounts in terms of rETH and ETH eqivalent
   */
  function checkRewards() view external onlyOwner returns (uint, uint) {
    // Load Rocket contracts
    address rocketTokenRETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
    RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);

    // Get rewards amounts
    uint rEthBalance = rocketTokenRETH.balanceOf(address(this));
    uint rEthRewards = rEthBalance.sub(rocketTokenRETH.getRethValue(totalEthStaked));
    uint ethRewards = rocketTokenRETH.getEthValue(rEthRewards);

    return (rEthRewards, ethRewards);
  }


  function checkRewardsPercentage(uint percent) view external onlyOwner returns (uint, uint) {
    // Load Rocket contracts
    address rocketTokenRETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
    RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);

    // Get rewards amounts
    uint rEthBalance = rocketTokenRETH.balanceOf(address(this));
    uint rEthRewards = rEthBalance.mul(percent).div(100);
    uint ethRewards = rocketTokenRETH.getEthValue(rEthRewards);

    return (rEthRewards, ethRewards);
  }



  /*
   * I want this function to send to the owner() of this contract the rewards claimable in ETH
   * without withdrawing the totalEthStaked deposits.
   */
  function claimRewardsETH() external onlyOwner {
    // Load Rocket contracts
    address rocketTokenRETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
    RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);

    // Get rewards amounts
    uint rEthBalance = rocketTokenRETH.balanceOf(address(this));
    uint rEthRewards = rEthBalance.sub(rocketTokenRETH.getRethValue(totalEthStaked));

    // Burn rETH to ETH
    uint ethBalanceBefore = address(this).balance;
    rocketTokenRETH.burn(rEthRewards);

    // Send ETH to msg.sender
    //payable(msg.sender).send{value: address(this).balance.sub(ethBalanceBefore)};
    (bool success, ) = msg.sender.call{value: address(this).balance.sub(ethBalanceBefore)}("");
    require(success);
  }



  /*
   * I want this function to send to the owner() of this contract the rewards claimable in ETH
   * without withdrawing the totalEthStaked deposits.
   */
  function claimRewardsETHPercentage(uint percent) external onlyOwner {
    // Load Rocket contracts
    address rocketTokenRETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
    RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);

    // Get rewards amounts
    uint rEthBalance = rocketTokenRETH.balanceOf(address(this));
    uint rEthRewards = rEthBalance.mul(percent).div(100);

    // Burn rETH to ETH
    uint ethBalanceBefore = address(this).balance;
    rocketTokenRETH.burn(rEthRewards);

    // Send ETH to msg.sender
    //payable(msg.sender).send{value: (address(this).balance - ethBalanceBefore)}();
    (bool success, ) = msg.sender.call{value: address(this).balance.sub(ethBalanceBefore)}("");
    require(success);
  }



  /*
   * I want this function to send to the owner() of this contract the rewards claimable in rETH
   * without withdrawing the totalEthStaked deposits.
   * This is in case the RocketPool does not have enough liquidity to do the conversion from rETH to ETH.
   */
  function claimRewardsRETH() external onlyOwner {
    // Load Rocket contracts
    address rocketTokenRETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
    RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);

    // Get rewards amounts
    uint rEthBalance = rocketTokenRETH.balanceOf(address(this));
    uint rEthRewards = rEthBalance.sub(rocketTokenRETH.getRethValue(totalEthStaked));

    // Transfer rETH to msg.sender
    require(rocketTokenRETH.transfer(msg.sender, rEthRewards), "rETH rewards was not claimed");
  }




  /*
   * I want this function to send to the owner() of this contract the rewards claimable in rETH
   * without withdrawing the totalEthStaked deposits.
   * This is in case the RocketPool does not have enough liquidity to do the conversion from rETH to ETH.
   */
  function claimRewardsRETHPercentage(uint percent) external onlyOwner {
    // Load Rocket contracts
    address rocketTokenRETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
    RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);

    // Get rewards amounts
    uint rEthBalance = rocketTokenRETH.balanceOf(address(this));
    uint rEthRewards = rEthBalance.mul(percent).div(100);

    // Transfer rETH to msg.sender
    require(rocketTokenRETH.transfer(msg.sender, rEthRewards), "rETH rewards was not claimed");
  }



  function doSomethingPayable() payable external {
    ethToStake += msg.value;
  }

  function withdraw() onlyOwner external {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success);
  }


}