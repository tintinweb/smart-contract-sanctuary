// SPDX-License-Identifier: MIT

pragma solidity = 0.7 .0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b *c + a % b);	// There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns(uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns(address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns(bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

abstract contract Token {

  function balanceOf(address account) external view virtual returns(uint256 data);

}

abstract contract Router {

  function extrenalRouterCall(string memory route, address[2] memory addressArr, uint[2] memory uintArr) external virtual returns(bool success);

  function updateCurrentSupply(uint[2] memory uintArr) external virtual returns(bool success);
}

//===============================================================
//MAIN CONTRACT
//===============================================================
contract SoloMiner is Ownable {
  using SafeMath
  for uint;

  address private tokenContract;
  address private routerContract;
  uint private totalBurned;
  uint private totalMinted;
  bool private active = true;

  Token private token;
  Router private router;
  mapping(address => uint) private numerator;
  mapping(address => uint) private denominator;
  mapping(address => uint) private minimumReturn;
  mapping(address => uint) private userBlocks;
  mapping(address => uint) private miners;
  mapping(uint => address) private addressFromId;
  mapping(address => bool) private mutex;

  uint private pivot = 0;
  uint private rewardConstant = 100000000000000000000;
  uint private totalConstant = 21000000000000000000000000; //we assume that there is a 21 million as a total supply
  uint private currentConstant = 1050000000000000000000000; //we assume that the current supply is 10.5 million tokens
  uint private inflationBuffer = 100000000000000000000; //we are allowing the automated inflation with this

  address private contractAddress;

  constructor() {
    contractAddress = address(this);
    setNewTokenContract(address(0x7C131Ab459b874b82f19cdc1254fB66840D021B6));
    setNewRouterContract(address(0x1f773c9344E3caE0AA6fA3c89Ac90701fEa364Fe));
  }

  modifier isActive() {
    require(active, "Miner is not active.");
    _;
  }

  //+++++++++++VIEWS++++++++++++++++
  //----------GETTERS---------------
  
  function getPivot() external view virtual returns(uint lastPivot) {
    return pivot;
  }

  function getAddressFromId(uint id) external view virtual returns(address minerAddress) {
    return addressFromId[id];
  }

  function getUserNumerator(address minerAddress) external view virtual returns(uint minerNumerator) {
    return numerator[minerAddress];
  }

  function getUserDenominator(address minerAddress) external view virtual returns(uint minerDenominator) {
    return denominator[minerAddress];
  }

  function getUserBlocks(address minerAddress) external view virtual returns(uint minerBlocks) {
    return userBlocks[minerAddress];
  }

  function getContractAddress() external view virtual returns(address tokenAddress) {
    return contractAddress;
  }

  function getTokenContract() external view virtual returns(address tokenAddress) {
    return tokenContract;
  }

  function getTotalBurned() external view virtual returns(uint burned) {
    return totalBurned;
  }

  function getTotalMinted() external view virtual returns(uint burned) {
    return totalMinted;
  }

  function getLastBlockNumber(address minerAddress) public view virtual returns(uint lastBlock) {
    return userBlocks[minerAddress];
  }

  function getRouterContract() external view virtual returns(address routerAddress) {
    return routerContract;
  }

  function getCurrentBlockNumber() public view returns(uint256 blockNumber) {
    return block.number;
  }

  function getGapSize() public view virtual returns(uint gapSize) {
    return totalConstant.sub(currentConstant);
  }

  function getRewardConstant() external view virtual returns(uint routerAddress) {
    return rewardConstant;
  }

  function getTotalConstant() external view virtual returns(uint routerAddress) {
    return totalConstant;
  }

  function getCurrentConstant() external view virtual returns(uint routerAddress) {
    return currentConstant;
  }

  function getinflationBuffer() external view virtual returns(uint routerAddress) {
    return inflationBuffer;
  }

  //----------OTHER VIEWS---------------
  function showReward(address minerAddress) public view virtual returns(uint reward) {
    if (denominator[minerAddress] == 0) {
      return 0;
    } else if (!active) {
      return 0;
    }

    uint previousBlock = getLastBlockNumber(minerAddress);
    uint currentBlock = getCurrentBlockNumber();
    uint diff = currentBlock.sub(previousBlock);
    uint additionalReward = diff.mul(rewardConstant);
    additionalReward = (numerator[minerAddress].mul(additionalReward)).div(denominator[minerAddress]);
    uint rewardSize = (numerator[minerAddress].mul(getGapSize())).div(denominator[minerAddress]);

    if (rewardSize.add(currentConstant) > totalConstant) {
      rewardSize = totalConstant.sub(currentConstant);
    }
    if (rewardSize < showMyCurrentRewardTotal()) {
      rewardSize = showMyCurrentRewardTotal();
    }
    rewardSize = rewardSize + additionalReward;

    return rewardSize;
  }

  //+++++++++++EXTERNAL++++++++++++++++
  function mine(uint depositAmount) isActive external virtual returns(bool success) {
    require(!mutex[msg.sender]);
    mutex[msg.sender] = true;

    require(depositAmount > 0,
      "at: solo_miner.sol | contract: SoloMiner | function: mine | message: No zero deposits allowed");

    uint reward = showReward(msg.sender);
    reward = reward.add(depositAmount);

    uint gapSize = getGapSize().add(depositAmount);

    numerator[msg.sender] = reward;
    denominator[msg.sender] = gapSize;
    minimumReturn[msg.sender] = minimumReturn[msg.sender].add(depositAmount);
    userBlocks[msg.sender] = getCurrentBlockNumber();

    registerMiner();

    burn(depositAmount);

    mutex[msg.sender] = false;

    return true;
  }

  function getReward(uint tokenAmount) isActive public virtual returns(bool success) {

    require(!mutex[msg.sender]);
    mutex[msg.sender] = true;

    uint reward = showReward(msg.sender);

    require(tokenAmount <= reward,
      "at: solo_miner.sol | contract: SoloMiner | function: getReward | message: Amount too big");

    reward = reward.sub(tokenAmount);

    uint gapSize = getGapSize().sub(tokenAmount);

    numerator[msg.sender] = reward;
    denominator[msg.sender] = gapSize;
    if (minimumReturn[msg.sender] >= tokenAmount) {
      minimumReturn[msg.sender] = minimumReturn[msg.sender].sub(tokenAmount);
    } else {
      minimumReturn[msg.sender] = 0;
    }
    userBlocks[msg.sender] = getCurrentBlockNumber();

    registerMiner();

    mint(tokenAmount);

    mutex[msg.sender] = false;

    return true;
  }

  function getFullReward() isActive public virtual returns(bool success) {

    require(!mutex[msg.sender]);
    mutex[msg.sender] = true;

    uint amt = showReward(msg.sender);

    require(amt > 0,
      "at: solo_miner.sol | contract: SoloMiner | function: getFullReward | message: No rewards to give");

    require(getLastBlockNumber(msg.sender) > 0,
      "at: solo_miner.sol | contract: SoloMiner | function: getFullReward | message: Must mine first");

    numerator[msg.sender] = 0;
    denominator[msg.sender] = 0;
    minimumReturn[msg.sender] = 0;
    userBlocks[msg.sender] = 0;

    mint(amt);

    mutex[msg.sender] = false;

    return true;
  }

  //should miner become inactive, we can still get our tokens back
  function recoverOnly() external virtual returns(bool success) {

    require(!mutex[msg.sender]);
    mutex[msg.sender] = true;

    require(!active,
      "at: solo_miner.sol | contract: SoloMiner | function: recoverOnly | message: Contract must be deactivated");
    require(minimumReturn[msg.sender] > 0,
      "at: solo_miner.sol | contract: SoloMiner | function: recoverOnly | message: You cannot recover a zero amount");

    uint amt = minimumReturn[msg.sender];
    minimumReturn[msg.sender] = 0;
    mint(amt);

    mutex[msg.sender] = false;

    return true;
  }

  //in case you want to burn tokens and increase miner rewards
  function burnMyTokens(uint tokenAmount) isActive public virtual returns(bool success) {

    require(!mutex[msg.sender]);
    mutex[msg.sender] = true;

    currentConstant = currentConstant.sub(tokenAmount);
    burn(tokenAmount);

    mutex[msg.sender] = false;

    return true;
  }

  //+++++++++++ONLY OWNER++++++++++++++++
  //----------SETTERS--------------------
  function setNewTokenContract(address newTokenAddress) onlyOwner public virtual returns(bool success) {
    tokenContract = newTokenAddress;
    token = Token(newTokenAddress);
    return true;
  }
  
  function setNewRouterContract(address newRouterAddress) onlyOwner public virtual returns(bool success) {
    routerContract = newRouterAddress;
    router = Router(newRouterAddress);
    return true;
  }

  function setRewardConstant(uint newConstant) onlyOwner public virtual returns(bool success) {
    rewardConstant = newConstant;
    return true;
  }

  function setInflationBuffer(uint newConstant) onlyOwner public virtual returns(bool success) {
    inflationBuffer = newConstant;
    return true;
  }

  function setCurrentConstant(uint newConstant) onlyOwner public virtual returns(bool success) {
    currentConstant = newConstant;
    return true;
  }

  function setTotalConstant(uint newConstant) onlyOwner public virtual returns(bool success) {
    totalConstant = newConstant;
    return true;
  }

  //----------OTHER--------------------
  function flipSwitch() external onlyOwner returns(bool success) {
    active = !active;
    return true;
  }

  //+++++++++++PRIVATE++++++++++++++++++++   
  function registerMiner() private {
    if (miners[msg.sender] == 0) {
      pivot = pivot.add(1);
      miners[msg.sender] = pivot;
      addressFromId[pivot] = msg.sender;
    }
  }

  function showMyCurrentRewardTotal() private view returns(uint reward) {

    if (denominator[msg.sender] == 0) {
      return 0;
    } else if (!active) {
      return 0;
    }

    uint gapSize = getGapSize();
    uint rewardSize = (numerator[msg.sender].mul(gapSize)).div(denominator[msg.sender]);

    if (rewardSize < minimumReturn[msg.sender]) {
      rewardSize = minimumReturn[msg.sender];
    }
    if (rewardSize > getGapSize()) {
      rewardSize = getGapSize();
    }

    return rewardSize;
  }

  function burn(uint burnAmount) isActive private returns(bool success) {
    require(burnAmount <= currentConstant,
      "at: solo_miner.sol | contract: SoloMiner | function: burn | message: You cannot burn more tokens than the existing current supply");
    require(burnAmount <= token.balanceOf(msg.sender),
      "at: solo_miner.sol | contract: SoloMiner | function: burn | message: You are trying to burn more than you own");

    address toAddress = address(0);
    address[2] memory addresseArr = [msg.sender, toAddress];
    uint[2] memory uintArr = [burnAmount, 0];

    totalBurned = totalBurned.add(burnAmount);
    currentConstant = currentConstant.sub(burnAmount);

    router.extrenalRouterCall("burn", addresseArr, uintArr);

    return true;
  }

  function mint(uint mintAmount) isActive private returns(bool success) {
    address fromAddress = address(0);
    address[2] memory addresseArr = [fromAddress, msg.sender];
    uint[2] memory uintArr = [mintAmount, 0];

    if (inflationBuffer >= mintAmount && currentConstant >= mintAmount) {
      inflationBuffer = inflationBuffer.sub(mintAmount);
    } else {
      currentConstant = currentConstant.add(mintAmount);
    }

    totalMinted = totalMinted.add(mintAmount);

    router.extrenalRouterCall("mint", addresseArr, uintArr);

    return true;
  }
}