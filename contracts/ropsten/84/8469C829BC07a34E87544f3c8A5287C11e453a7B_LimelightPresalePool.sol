/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity 0.4.23;



interface ERC20 {
    function transfer(address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint balance);
}
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract LimelightPresalePool {

  using SafeMath for uint;

  enum PresaleState { Opened, Closed, Paid, Transfered}

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAdmin()
  {
    require(participantsInfo[msg.sender].admin);
    _;
  }

  modifier onlyWhitelisted()
  {
    require(participantsInfo[msg.sender].isWhitelisted);
    _;
  }

  modifier onlyInDate()
  {
    if (presaleInfo.startDate!=0 && presaleInfo.endDate!=0)
    {
      require(now >= presaleInfo.startDate && now <= presaleInfo.endDate);
    }
    _;
  }

  modifier whenClosed()
  {
    require(presaleInfo.state == PresaleState.Closed);
    _;
  }

  modifier whenOpened()
  {
    require(presaleInfo.state == PresaleState.Opened);
    _;
  }

  modifier whenTransfered()
  {
    require(presaleInfo.state == PresaleState.Transfered);
    _;
  }

  modifier whenExchangeRateSetted()
  {
    require(exchangeRate > 0);
    _;
  }

  struct PresaleInfo
  {
    PresaleState state;
    uint minContribution;
    uint maxContribution;
    uint maxAllocation;
    uint startDate;
    uint endDate;
  }

  struct Participant
  {
    bool admin;
    bool isWhitelisted;
    uint sum;
    bool gotTokens;
    uint realValue;
  }

  event AddedToWhiteList(address participant);
  event Closed();
  event Transfered();
  event Paid(uint balance);
  event GotTokens(address participant, uint tokens);
  event TeamFeeSetted(uint feePerEther);
  event PoolFeeSetted(uint feePerEther);
  event ParticipateContributed(address participant);
  event ParticipantWithdrawed(address participant, uint amount);

  mapping (address=> Participant) participantsInfo;
  PresaleInfo private presaleInfo;
  address public owner;
  address public distributionWallet;
  address public poolDistributionWallet;
  address[] participants;
  address[] admins;

  uint public exchangeRate;
  uint private tokenDecimals;
  uint public contributionBalance;
  uint feePerEtherTeam;
  uint feePerEtherPool;
  uint totalTeamFee;
  uint totalPoolFee;
  bool teamGotFee;
  bool adminGotFee;

  constructor() public
  {
    owner = msg.sender;
  }

  function init(address[] _admins, address _distributionWallet, address _poolDistributionWallet) external onlyOwner
  {
    presaleInfo.state = PresaleState.Opened;
    distributionWallet = _distributionWallet;
    poolDistributionWallet = _poolDistributionWallet;

    admins = _admins;
    for (uint i = 0; i < _admins.length; i++) {
        addAdmin(_admins[i]);
    }
  }

  function setMainValues(uint _startDate, uint _endDate, uint _minContribution, uint _maxContribution, uint _maxAllocation, uint _poolFee, address[] _participants, uint _tokenRate, uint _decimals) external onlyAdmin
  {
    setPresaleSettings(_startDate, _endDate, _minContribution, _maxContribution, _maxAllocation);
    setPoolFeePerEther(_poolFee);
    addAddressesToWhitelist(_participants);
    setTokenRate(_tokenRate, _decimals);

  }

  function setNewOwner(address _owner) external onlyOwner
  {
    owner = _owner;
  }

  function addAdmin(address admin) internal
  {
    participantsInfo[admin].admin = true;
    participantsInfo[admin].isWhitelisted = true;
  }

  function getAdmins() external view returns(address[])
  {
    return admins;
  }

  function contribute() onlyWhitelisted whenOpened payable onlyInDate external
  {
    Participant storage participant = participantsInfo[msg.sender];
    require(participant.realValue.add(msg.value) <= presaleInfo.maxContribution);

    participant.realValue = participant.realValue.add(msg.value);
    if (participant.realValue >= presaleInfo.minContribution)
    {
      contributionBalance = contributionBalance.sub(participant.sum);
      participant.sum = participant.realValue;
      contributionBalance = contributionBalance.add(participant.sum);
      require(contributionBalance <= presaleInfo.maxAllocation);
    }

    emit ParticipateContributed(msg.sender);
  }

  function withdrawContribution() whenOpened external
  {
    Participant storage participant = participantsInfo[msg.sender];
    uint transferSum =  participant.realValue;
    participant.realValue = 0;
    if (participant.sum != 0)
    {
      contributionBalance = contributionBalance.sub(participant.sum);
      participant.sum = 0;
    }

    msg.sender.transfer(transferSum);

    emit ParticipantWithdrawed(msg.sender, participant.sum);

  }

  function getPoolValue() external view returns(uint)
  {
    return contributionBalance;
  }

  function sendContribution(address token, uint gasLimit, bytes data) external onlyAdmin whenClosed
  {
    require (presaleInfo.state != PresaleState.Paid);
    presaleInfo.state = PresaleState.Paid;
    uint fee = calculateTotalValueFee(contributionBalance);
    uint gas = (gasLimit > 0) ? gasLimit : gasleft();
    require(
        token.call.gas(gas).value(contributionBalance - fee)(data)
    );

    emit Paid(contributionBalance.sub(fee));
  }

  function getTokens(address tokenAddress) whenTransfered external
  {
    require (!participantsInfo[msg.sender].gotTokens);
    participantsInfo[msg.sender].gotTokens = true;

    uint reward = calculateParticipantTokens(msg.sender);
    ERC20 token = ERC20(tokenAddress);

    require(token.transfer(msg.sender, reward));
    emit GotTokens(msg.sender, reward);
  }

  function calculateParticipantTokens(address participant) internal view  returns(uint)
  {
    uint sum = participantsInfo[participant].sum;
    uint fee = calculateTotalValueFee(sum);
    sum = sum.sub(fee);

    uint tokens = (10 ** tokenDecimals).mul(sum).div(exchangeRate);

    return tokens;
  }

  function calculateTotalValueFee(uint value) internal view returns(uint)
  {
    uint fee = value.mul(feePerEtherPool.add(feePerEtherTeam)).div(1 ether);
    return fee;
  }

  function calculateTeamValueFee(uint value) internal view returns(uint)
  {
    uint fee = value.mul(feePerEtherTeam).div(1 ether);
    return fee;
  }

  function calculatePoolValueFee(uint value) internal view returns(uint)
  {
    uint fee = value.mul(feePerEtherPool).div(1 ether);
    return fee;
  }

  function setPresaleSettings(uint _startDate, uint _endDate, uint _minContribution, uint _maxContribution, uint _maxAllocation) public onlyAdmin
  {
    require(_minContribution < _maxContribution);
    require(_startDate <= _endDate);

    presaleInfo.startDate = _startDate;
    presaleInfo.endDate = _endDate;

    if( _minContribution < presaleInfo.minContribution)
    {
      presaleInfo.minContribution = _minContribution;
      rebalanceContributionsDecreaseMin();
    }
    else if (_minContribution > presaleInfo.minContribution)
    {
      presaleInfo.minContribution = _minContribution;
      rebalanceContributionsIncreaseMin();
    }
    presaleInfo.maxContribution = _maxContribution;
    rebalanceContributionsDecreaseMax();
    presaleInfo.maxAllocation = _maxAllocation;
  }

  function rebalanceContributionsIncreaseMin() internal
  {
    for (uint i=0;i<participants.length;i++)
    {
      Participant storage participant = participantsInfo[participants[i]];
      if(participant.realValue < presaleInfo.minContribution)
      {
        contributionBalance = contributionBalance.sub(participant.sum);
        participant.sum = 0;
      }
    }
  }

  function rebalanceContributionsDecreaseMin() internal
  {
    for (uint i=0;i<participants.length;i++)
    {
      Participant storage participant = participantsInfo[participants[i]];
      if(participant.realValue > presaleInfo.minContribution)
      {
        if (participant.sum == 0)
        {
          participant.sum = participant.realValue;
          contributionBalance = contributionBalance.add(participant.sum);
        }
      }
    }
  }

  function rebalanceContributionsDecreaseMax() internal
  {
    for (uint i=0;i<participants.length;i++)
    {
      Participant storage participant = participantsInfo[participants[i]];
      if(participant.sum > presaleInfo.maxContribution)
      {
        uint transferSum = participant.realValue;
        contributionBalance = contributionBalance.sub(participant.sum);
        participant.realValue = 0;
        participant.sum = 0;

        participants[i].transfer(transferSum);
      }
    }
  }

  function getPresaleSettings() external view returns(uint, uint, uint)
  {
    return (presaleInfo.minContribution, presaleInfo.maxContribution, presaleInfo.maxAllocation);
  }

  function setTokenRate(uint rate, uint decimals) public onlyAdmin
  {
    exchangeRate = rate;
    tokenDecimals = decimals;
  }

  function getTokenRate() external returns(uint, uint)
  {
    return (exchangeRate, tokenDecimals);
  }

  function setTeamFeePerEther(uint fee) external onlyOwner whenOpened
  {
    feePerEtherTeam = fee;
    emit TeamFeeSetted(fee);
  }

  function setPoolFeePerEther(uint fee) public onlyAdmin whenOpened
  {
    feePerEtherPool = fee;
    emit PoolFeeSetted(fee);
  }

  function getPoolFeePerEther() external view returns(uint)
  {
    return feePerEtherPool;
  }

  function sendFeeToTeam() external onlyOwner whenTransfered
  {
    require(!teamGotFee);

    teamGotFee = true;
    distributionWallet.transfer(calculateTeamValueFee(contributionBalance));
  }

  function sendFeeToPoolAdmin() external onlyAdmin whenTransfered
  {
    require(!adminGotFee);

    adminGotFee = true;
    poolDistributionWallet.transfer(calculatePoolValueFee(contributionBalance));
  }

  function addAddressesToWhitelist(address[] _participants) public onlyAdmin
  {
    for (uint i=0;i<participants.length;i++)
    {
      Participant storage participantInfo = participantsInfo[_participants[i]];
      participantInfo.isWhitelisted = false;
    }

    for (i=0;i<_participants.length;i++)
    {
      participantInfo = participantsInfo[_participants[i]];
      participantInfo.isWhitelisted = true;
    }

    participants = _participants;
  }

  function addToWhitelist(address participant) external onlyAdmin
  {
    Participant storage participantInfo = participantsInfo[participant];
    participantInfo.isWhitelisted = true;
    participants.push(participant);

    emit AddedToWhiteList(participant);
  }

  function removeFromWhitelist(address participant) external onlyAdmin
  {
    Participant storage participantInfo = participantsInfo[participant];
    participantInfo.isWhitelisted = false;
  }

  function getWhitelist() external view returns(address[])
  {
    return participants;
  }

  function getContributedSum() external view returns(uint)
  {
    return participantsInfo[msg.sender].sum;
  }

  function getContributedSumAfterFees() external view returns(uint)
  {
    return participantsInfo[msg.sender].sum.sub(calculateTotalValueFee(participantsInfo[msg.sender].sum));
  }

  function getRealSum() external view returns(uint)
  {
    return participantsInfo[msg.sender].realValue;
  }

  function setTransferedState() external onlyAdmin
  {
    require (presaleInfo.state == PresaleState.Paid);
    presaleInfo.state = PresaleState.Transfered;

    emit Transfered();
  }

  function close() public onlyAdmin whenOpened
  {
    presaleInfo.state = PresaleState.Closed;

    emit Closed();
  }

  function getCurrentState() public returns(uint)
  {
    return uint(presaleInfo.state);
  }
}