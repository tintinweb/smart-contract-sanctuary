pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract BSPMintable is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Mint(uint256 amount);
  event DistributorChanged(address indexed previousDistributor, address indexed newDistributor);

  address public distributor = 0x4F91C1f068E0dED2B7fF823289Add800E1c26Fc3;

  // BSP contract address
  ERC20Basic public BSPToken = ERC20Basic(0x5d551fA77ec2C7dd1387B626c4f33235c3885199);
  // lock 30% total supply of BSP for mining
  uint256 constant public rewardAmount = 630000000 * (10 ** 18);
  // mining duration
  uint256 constant public duration = 4 years;
  // adjust mining rate every 1 year
  uint256[4] public miningRate = [40,20,20,20];

  bool public started = false;

  uint256 public startTime;

  uint256 public minted;

  modifier whenStarted() {
    require(started == true && startTime <= block.timestamp);
    _;
  }

  function startMining(uint256 _startTime) public onlyOwner {

      require(started == false && BSPToken.balanceOf(this) >= rewardAmount);

      // cannot start from a historical time
      require(_startTime >= block.timestamp);
      // prevent input error
      require(_startTime <= block.timestamp + 60 days);

      startTime = _startTime;
      started = true;
  }

  function changeDistributor(address _newDistributor) public onlyOwner {
    emit DistributorChanged(distributor, _newDistributor);
    distributor = _newDistributor;

  }

  function mint() public whenStarted {
    uint256 unminted = mintableAmount();
    require(unminted > 0);

    minted = minted.add(unminted);
    BSPToken.safeTransfer(distributor, unminted);

    emit Mint(unminted);
  }

  function mintableAmount() public view returns (uint256) {

    if(started == false || startTime >= block.timestamp){
        return 0;
    }

    if (block.timestamp >= startTime.add(duration)){
        return BSPToken.balanceOf(this);
    }

    uint currentYear = block.timestamp.sub(startTime).div(1 years);
    uint currentDay = (block.timestamp.sub(startTime) % (1 years)).div(1 days);
    uint currentMintable = 0;

    for (uint i = 0; i < currentYear; i++){
        currentMintable = currentMintable.add(rewardAmount.mul(miningRate[i]).div(100));
    }
    currentMintable = currentMintable.add(rewardAmount.mul(miningRate[currentYear]).div(36500).mul(currentDay));

    return currentMintable.sub(minted);
  }

  function totalBspAmount() public view returns (uint256) {
      return BSPToken.balanceOf(this).add(minted);
  }

  function () public payable {
    revert ();
  }

}