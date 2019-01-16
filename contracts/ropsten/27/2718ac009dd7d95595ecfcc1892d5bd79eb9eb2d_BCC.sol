pragma solidity ^0.4.23;

/**
* Symbol      : BCC
* Name        : Bitcoin Cash Classic Token
* Total supply: 21,000,000.00
* Decimals    : 8
*/

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }

  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

library ExtendedMath {
  // return the smaller of the two inputs (a or b)
  function limitLessThan(uint a, uint b) internal pure returns (uint c) {
    if (a > b) return b;
    return a;
  }
}

contract ERC223 {
  uint public totalSupply;

  function balanceOf(address who) public constant returns (uint);
  function name() public constant returns (string _name);
  function symbol() public constant returns (string _symbol);
  function decimals() public constant returns (uint8 _decimals);
  function totalSupply() public constant returns (uint256 _supply);
  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract BCC is ERC223 {
  using SafeMath for uint;
  using ExtendedMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint public totalSupply;
  mapping(address => uint) balances;

  uint private startBlock;
  uint public latestDifficultyPeriodStarted;
  uint public epochCount; // number of &#39;blocks&#39; mined
  uint public _BLOCKS_PER_READJUSTMENT = 2016;
  uint public  _MINIMUM_TARGET = 2**16;
  uint public  _MAXIMUM_TARGET = 2**224;
  uint public miningTarget;
  bytes32 public challengeNumber;
  uint public rewardEra;
  uint public maxSupplyForEra;
  address public lastRewardTo;
  uint public lastRewardAmount;
  uint public lastRewardEthBlockNumber;
  mapping(bytes32 => bytes32) solutionForChallenge;
  uint public tokensMinted;

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

  constructor(uint _startBlock) public {
    symbol      = "BCC";
    name        = "Bitcoin Cash Classic Token";
    decimals    = 8;
    totalSupply = 21000000 * 10**uint(decimals);

    maxSupplyForEra = totalSupply.div(2);
    miningTarget    = _MAXIMUM_TARGET;
    startBlock      = _startBlock;

    latestDifficultyPeriodStarted = block.number;
    _startNewMiningEpoch();
  }

  function () public payable {
    revert();
  }

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
    // in order to ensure fair launch revert all mining transactions
    // that happen before startBlock
    if (block.number < startBlock) revert();
    // the PoW must contain work that includes a recent ETC block hash (challenge number) and the msg.sender&#39;s address to prevent MITM attacks
    bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));
    // the challenge digest must match the expected
    if (digest != challenge_digest) revert();
    // the digest must be smaller than the target
    if (uint256(digest) > miningTarget) revert();
    // only allow one reward for each challenge
    bytes32 solution = solutionForChallenge[challengeNumber];
    solutionForChallenge[challengeNumber] = digest;
    if (solution != 0x0) revert();  // prevent the same answer from awarding twice

    uint reward_amount = getMiningReward();
    balances[msg.sender] = balances[msg.sender].add(reward_amount);
    tokensMinted = tokensMinted.add(reward_amount);
    // Cannot mint more tokens than there are
    assert(tokensMinted <= maxSupplyForEra);

    // set readonly diagnostics data
    lastRewardTo = msg.sender;
    lastRewardAmount = reward_amount;
    lastRewardEthBlockNumber = block.number;

    _startNewMiningEpoch();
    emit Mint(msg.sender, reward_amount, epochCount, challengeNumber);
    return true;
  }

  // a new &#39;block&#39; to be mined
  function _startNewMiningEpoch() internal {
    // if max supply for the era will be exceeded next reward round then
    // enter the new era before that happens

    // 40 is the final reward era, almost all tokens minted
    // once the final era is reached, more tokens will not be given out
    // because of the assertion
    if (tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 39) {
      rewardEra++;
    }

    // set the next minted supply at which the era will change
    // total supply is 2100000000000000  because of 8 decimal places
    maxSupplyForEra = totalSupply.sub(totalSupply.div(2**(rewardEra + 1)));
    epochCount++;

    // every so often, readjust difficulty. Dont readjust when deploying
    if (epochCount % _BLOCKS_PER_READJUSTMENT == 0) {
      _reAdjustDifficulty();
    }

    // make the latest ETC block hash a part of the next challenge for PoW
    // to prevent pre-mining future blocks
    // do this last since this is a protection mechanism in the mint() function
    challengeNumber = blockhash(block.number - 1);
  }

  // https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
  // as of 2017 the bitcoin difficulty was up to 17 zeroes
  // it was only 8 in the early days
  // readjust the target by 5 percent
  function _reAdjustDifficulty() internal {
    uint blocksSinceLastDifficultyPeriod = block.number.sub(latestDifficultyPeriodStarted);
    // assume 360 ETC blocks per hour
    // we want miners to spend 10 minutes to mine each &#39;block&#39;
    // about 60 ethereum blocks = one BCC epoch
    uint epochsMined = _BLOCKS_PER_READJUSTMENT;
    // should be 60 times slower than ETC
    uint targetBlocksPerDiffPeriod = epochsMined * 60;

    if (blocksSinceLastDifficultyPeriod < targetBlocksPerDiffPeriod) {
      // make it harder
      uint excess_block_pct = targetBlocksPerDiffPeriod.mul(100).div(blocksSinceLastDifficultyPeriod);
      uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
      miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));
    } else {
      // make it easier
      uint shortage_block_pct = blocksSinceLastDifficultyPeriod.mul(100).div(targetBlocksPerDiffPeriod);
      uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000);
      miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));
    }

    latestDifficultyPeriodStarted = block.number;

    if (miningTarget < _MINIMUM_TARGET) {
      miningTarget = _MINIMUM_TARGET;
    }

    if (miningTarget > _MAXIMUM_TARGET) {
      miningTarget = _MAXIMUM_TARGET;
    }
  }

  function getChallengeNumber() public constant returns (bytes32) {
    return challengeNumber;
  }

  function getMiningDifficulty() public constant returns (uint) {
    return _MAXIMUM_TARGET.div(miningTarget);
  }

  function getMiningTarget() public constant returns (uint) {
    return miningTarget;
  }

  // 21m coins total
  // reward begins at 50 and is cut in half every reward era (as tokens are mined)
  function getMiningReward() public constant returns (uint) {
    return (50 * 10**uint(decimals)).div(2**rewardEra);
  }

  // ERC223 functionality
  function name() public constant returns (string) {
    return name;
  }

  function symbol() public constant returns (string) {
    return symbol;
  }

  function decimals() public constant returns (uint8) {
    return decimals;
  }

  function totalSupply() public constant returns (uint256 _supply) {
    return totalSupply;
  }

  function balanceOf(address who) public constant returns (uint) {
    return balances[who];
  }

  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    if (isContract(_to)) {
      return transferToContract(_to, _value, _data);
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    bytes memory empty;
    if (isContract(_to)) {
      return transferToContract(_to, _value, empty);
    } else {
      return transferToAddress(_to, _value, empty);
    }
  }

  function isContract(address _addr) private view returns (bool) {
    uint length;
    assembly {
      length := extcodesize(_addr)
    }
    if (length > 0) {
      return true;
    } else {
      return false;
    }
  }

  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    emit Transfer(msg.sender, _to, _value);
    emit ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value);
    emit ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }
}