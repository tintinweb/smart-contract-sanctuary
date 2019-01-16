pragma solidity ^0.4.24;

interface ERC20 {
  function totalSupply() external view returns (uint supply);
  function balanceOf(address _owner) external view returns (uint balance);
  function transfer(address _to, uint _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  function approve(address _spender, uint _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint remaining);
  function decimals() external view returns(uint digits);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract VotingModel {

  function weightOf(uint x) public pure returns (uint y) {
    // Currently using Quadratic voting (Square Root)
    // https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }
  }
}

// File: contracts/ReentrancyGuard.sol

/**
 * @title Helps contracts guard against reentrancy attacks.
 */
contract ReentrancyGuard {

    /// @dev lengther to allow mutex lock with only one SSTORE operation
    uint256 private guardCounter = 1;

    /**
     * @dev Prevents a function from calling itself, directly or indirectly.
     * Calling one `nonReentrant` function from
     * another is not supported. Instead, you can implement a
     * `private` function doing the actual work, and an `external`
     * wrapper marked as `nonReentrant`.
     */
    modifier nonReentrant() {
        guardCounter += 1;
        uint256 localCounter = guardCounter;
        _;
        require(localCounter == guardCounter);
    }

}

// File: contracts/KyberNetworkProxyInterface.sol

/// @title Kyber Network interface
interface KyberNetworkProxyInterface {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) external payable returns(uint);
}

contract Blarity is ReentrancyGuard, VotingModel {

  ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  // Withdraw funds
  event EtherWithdraw(uint amount, address sendTo);
  /**
   * @dev Withdraw Ethers
   */
  function withdrawEther(uint amount, address sendTo) public onlyOwner {
    require(amount <= address(this).balance);
    sendTo.transfer(amount);
    emit EtherWithdraw(amount, sendTo);
  }

  event TokenWithdraw(ERC20 token, uint amount, address sendTo);
  /**
   * @dev Withdraw all ERC20 compatible tokens
   * @param token ERC20 The address of the token contract
   */
  function withdrawToken(ERC20 token, uint amount, address sendTo) public onlyOwner {
    if (token != acceptedToken) {
      require(token.transfer(sendTo, amount));
      emit TokenWithdraw(token, amount, sendTo);
    } else {
      // withdraw accepted token, only can withdraw amount does not belong to campaign
      // contract could get some airdrop
      require(acceptedToken.balanceOf(address(this)) >= amount + currentBalance);
      require(acceptedToken.transfer(sendTo, amount));
      emit TokenWithdraw(token, amount, sendTo);
    }
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Transfer ownership
  event TransferOwner(address newOwner);
  function transferOwner(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit TransferOwner(newOwner);
  }

  // owner/creator address
  address public owner;
  // start and end time
  uint public endTime;
  // accepted token, e.g: DAI
  ERC20 public acceptedToken;
  // target money of this campaign, if target is not reached, money could be reverted back to contributors
  uint public targetedMoney;
  // current balance of this campaign
  uint public currentBalance;
  // if campaign is timed out and not got enough money,
  // contributors can submit a request to claim funds back (no need approve of Delegator)
  bool public isReverted = false;

  // a contributor will have:
  // - amount contributed
  // - delegator address, who will decide the vote
  struct Contributor {
    // address of the contributor
    address ownerAddress;
    // contributed amount
    uint amount;
    // delegator address
    address delegator;
  }
  // list of contributors
  Contributor[] contributors;

  // who will decide the vote based on their weight
  struct Delegator {
    // address of Delegator
    address ownerAddress;
    // weight for the vote from this Delegator
    uint weight;
  }
  Delegator[] delegators;

  struct RequestFund {
    // amount to request
    uint amount;
    // address to transfer funds to
    address toAddress;
    // is ended the request
    uint endTime;
    bool isEnded;
    // status of the request: 0: reject, 1: unknown, 2: approved
    uint status;
  }
  RequestFund[] requestFunds;

  struct Vote {
    address ownerVote;
    uint weight;
    bool isApproved;
  }
  mapping(uint => Vote[]) votings;

  constructor(
    uint _endTime,
    ERC20 _acceptedToken,
    uint _targetedMoney
  ) public {
    require(_targetedMoney > 0);
    require(_endTime > now);
    owner = msg.sender;
    endTime = _endTime;
    acceptedToken = _acceptedToken;
    targetedMoney = _targetedMoney;
    currentBalance = 0;
  }

  // Do we allow owner to change targeted money?
  function updateTargetedMoney(uint _money) public onlyOwner {
    require(now < endTime); // must not be ended
    targetedMoney = _money;
  }

  // Should be able to update end time
  function updateEndTime(uint _endTime) public onlyOwner {
    endTime = _endTime;
  }

  event UpdateIsReverted(bool isReverted);
  function updateIsRevertedEndTimeReached() public onlyOwner {
    require(now >= endTime);
    require(isReverted == false);
    if (acceptedToken.balanceOf(address(this)) < targetedMoney) {
      isReverted = true;
      emit UpdateIsReverted(true);
    }
  }

  event TargetedMoneyReached();
  function updateTargetedMoneyReached() public onlyOwner {
    require(currentBalance >= targetedMoney);
    endTime = now;
    emit TargetedMoneyReached();
  }

  // Creator requests a fund transfer with amount and to address
  event CreatorRequestFundTransfer(uint _amount, address _address, uint _endTime);
  function creatorRequestFundTransfer(uint _amount, address _to, uint _endTime) public onlyOwner {
    require(now >= endTime); // must be ended to start requesting funds
    require(_endTime > now); // end time must be greater than current time
    if (acceptedToken == ETH_TOKEN_ADDRESS) {
      require(address(this).balance >= _amount);
    } else {
      require(acceptedToken.balanceOf(address(this)) >= _amount);
    }
    // require all previous request funds must be Refunded
    for(uint i = 0; i < requestFunds.length; i++) {
      require(requestFunds[i].isEnded); // only 1 request at any time
    }
    // push new request fund with amount, to _to address, not ended and status is unknown (1)
    requestFunds.push(RequestFund({amount: _amount, toAddress: _to, isEnded: false, status: 1, endTime: endTime}));
    emit CreatorRequestFundTransfer(_amount, _to, _endTime);
  }

  // Creator Reject a request
  event CreatorRejectRequestFundTransfer(uint _amount, address _address);
  function creatorRejectRequestFundTransfer(uint id) public onlyOwner {
    require(now >= endTime); // must be ended
    require(requestFunds.length > id); // id must be in range of number request funds
    require(!requestFunds[id].isEnded); // must of be ended
    requestFunds[id].status = 0; // reject the request
    emit CreatorRejectRequestFundTransfer(requestFunds[id].amount, requestFunds[id].toAddress);
  }

  // Creator claim fund transfer
  event CreatorClaimedFundTransfer(uint _amount, address _address);
  function creatorClaimFundTransfer(uint id) public onlyOwner {
    require(now >= endTime); // must be ended
    require(requestFunds.length > id); // id must be in range of number request funds
    require(requestFunds[id].status == 1); // status of the request must be unknown
    require(currentBalance >= requestFunds[id].amount);
    // check if it is success or failed
    uint totalWeight = 0;
    uint i;
    for(i = 0; i < delegators.length; i++) {
      totalWeight += weightOf(delegators[i].weight);
    }
    Vote[] storage votes = votings[id];
    uint positive = 0;
    uint negavtive = 0;
    for(i = 0; i < votes.length; i++) {
      if (votes[i].isApproved) { positive += weightOf(votes[i].weight); }
      else { negavtive += weightOf(votes[i].weight); }
    }
    // positive or negative is more than 50%, immediate update the request
    if (positive > totalWeight / 2) {
      // more than 50% approved
      if (acceptedToken == ETH_TOKEN_ADDRESS) {
        requestFunds[id].toAddress.transfer(requestFunds[id].amount);
      } else {
        require(acceptedToken.transfer(requestFunds[id].toAddress, requestFunds[id].amount));
      }
      currentBalance -= requestFunds[id].amount;
      requestFunds[id].isEnded = true;
      requestFunds[id].status = 2; // approved
      emit CreatorClaimedFundTransfer(requestFunds[id].amount, requestFunds[id].toAddress);
      return;
    } else if (negavtive > totalWeight / 2) {
      requestFunds[id].isEnded = true;
      requestFunds[id].status = 1; // rejected
      return;
    }
    // End time reached
    if (now >= requestFunds[id].endTime) {
      // more approves and rejects
      if (positive > negavtive) {
        if (acceptedToken == ETH_TOKEN_ADDRESS) {
          requestFunds[id].toAddress.transfer(requestFunds[id].amount);
        } else {
          require(acceptedToken.transfer(requestFunds[id].toAddress, requestFunds[id].amount));
        }
        currentBalance -= requestFunds[id].amount;
        requestFunds[id].isEnded = true;
        requestFunds[id].status = 2; // approved
        emit CreatorClaimedFundTransfer(requestFunds[id].amount, requestFunds[id].toAddress);
      } else {
        requestFunds[id].isEnded = true;
        requestFunds[id].status = 1; // rejected
      }
    }
  }

  event Voted(uint _requestID, address _delegator, uint _weight, bool _isApproved);
  function vote(uint _requestID, bool isApproved) public {
    require(now >= endTime); // must be ended
    require(requestFunds.length > _requestID); // id must be in range of number request funds
    require(!requestFunds[_requestID].isEnded && requestFunds[_requestID].status == 1); // status of the request must be unknown, request must not be ended
    uint weight;
    for(uint i0 = 0; i0 < delegators.length; i0++) {
      if (delegators[i0].ownerAddress == msg.sender) {
        weight = delegators[i0].weight;
      }
    }
    require(weight > 0);
    Vote[] storage voters = votings[_requestID];
    for(uint i = 0; i < voters.length; i++) {
      if (voters[i].ownerVote == msg.sender) {
        // already vote
        return;
      }
    }
    voters.push(Vote({ownerVote: msg.sender, weight: weight, isApproved: isApproved}));
    emit Voted(_requestID, msg.sender, weight, isApproved);
  }

  event Contributed(address _address, uint _amount, address _delegator);
  function contribute(KyberNetworkProxyInterface network, ERC20 src, uint srcAmount, address _delegator) public payable {
    require(currentBalance < targetedMoney); // target money is not reached
    require(srcAmount > 0);
    require(now < endTime); // not ended yet
    if (src == ETH_TOKEN_ADDRESS) require(srcAmount == msg.value);
    uint paidAmount;
    bytes memory hint;
    if (src == acceptedToken) {
      // normal transfer, no need swap
      paidAmount = doContributeWithoutKyber(src, srcAmount);
    } else {
      // do swap with KyberNetwork protocol
      PayData memory payData = PayData({
        src: src,
        network: network,
        srcAmount: srcAmount,
        dest: acceptedToken,
        destAddress: address(this),
        minConversionRate: 0,
        walletId: address(0),
        maxDestAmount: targetedMoney - currentBalance,
        hint: hint});
      paidAmount = doContributeWithKyber(payData);
    }
    currentBalance += paidAmount;
    // add paid amount to Contributor
    bool contributorExist = false;
    uint i;
    for(i = 0; i < contributors.length; i++) {
      if (contributors[i].ownerAddress == msg.sender) {
        require(contributors[i].delegator == _delegator);
        contributors[i].amount += paidAmount;
        contributorExist = true;
      }
    }
    if (!contributorExist) {
      contributors.push(Contributor({ownerAddress: msg.sender, amount: paidAmount, delegator: _delegator}));
    }
    // add weight to delegator
    for(i = 0; i < delegators.length; i++) {
      if (delegators[i].ownerAddress == _delegator) {
        delegators[i].weight += paidAmount;
        emit Contributed(msg.sender, paidAmount, _delegator);
        return;
      }
    }
    delegators.push(Delegator({ownerAddress: _delegator, weight: paidAmount}));
    emit Contributed(msg.sender, paidAmount, _delegator);
  }

  // normal transfer token without Kyber Network
  function doContributeWithoutKyber(ERC20 src, uint srcAmount) internal returns (uint paidAmount) {
    uint returnAmount;
    if (srcAmount + currentBalance > targetedMoney) {
      returnAmount = srcAmount + currentBalance - targetedMoney;
      paidAmount = srcAmount - returnAmount;
    } else {
      returnAmount = 0;
      paidAmount = srcAmount;
    }
    if (src == ETH_TOKEN_ADDRESS) {
      address(this).transfer(paidAmount);
      if (returnAmount > 0) {
        msg.sender.transfer(returnAmount);
      }
    } else {
      require(src.transferFrom(msg.sender, address(this), paidAmount));
    }
  }

  struct PayData {
    KyberNetworkProxyInterface network;
    ERC20 src;
    uint srcAmount;
    ERC20 dest;
    address destAddress;
    uint maxDestAmount;
    uint minConversionRate;
    address walletId;
    bytes hint;
  }

  // Swap token using KyberNetwork protocol
  function doContributeWithKyber(PayData payData) internal returns (uint paidAmount) {
    if (payData.src != ETH_TOKEN_ADDRESS) {
      require(payData.src.transferFrom(msg.sender, address(this), payData.srcAmount));
      require(payData.src.approve(payData.network, 0));
      require(payData.src.approve(payData.network, payData.srcAmount));
    }
    uint wrapperSrcBalanceBefore;
    uint destAddressBalanceBefore;
    uint wrapperSrcBalanceAfter;
    uint destAddressBalanceAfter;
    uint srcAmountUsed;
    (wrapperSrcBalanceBefore, destAddressBalanceBefore) = getBalances(payData.src, payData.dest, payData.destAddress);

    paidAmount = doTradeWithHint(payData);
    if (payData.src != ETH_TOKEN_ADDRESS) {
      require(payData.src.approve(payData.network, 0));
    }
    (wrapperSrcBalanceAfter, destAddressBalanceAfter) = getBalances(payData.src, payData.dest, payData.destAddress);
    // verify the amount the user got is same as returned from Kyber Network
    require(destAddressBalanceAfter > destAddressBalanceBefore);
    require(paidAmount == (destAddressBalanceAfter - destAddressBalanceBefore));

    // calculate the returned change amount
    require(wrapperSrcBalanceBefore >= wrapperSrcBalanceAfter);
    srcAmountUsed = wrapperSrcBalanceBefore - wrapperSrcBalanceAfter;

    require(payData.srcAmount >= srcAmountUsed);

    if (payData.srcAmount - srcAmountUsed > 0) {
      if (payData.src == ETH_TOKEN_ADDRESS) {
        msg.sender.transfer(payData.srcAmount - srcAmountUsed);
      } else {
        require(payData.src.transfer(msg.sender, payData.srcAmount - srcAmountUsed));
      }
    }
    return paidAmount;
  }

  function doTradeWithHint(PayData memory payData) internal returns (uint paidAmount) {
    paidAmount = payData.network.tradeWithHint.value(msg.value)({
      src: payData.src,
      srcAmount: payData.srcAmount,
      dest: payData.dest,
      destAddress: payData.destAddress,
      maxDestAmount: payData.maxDestAmount,
      minConversionRate: payData.minConversionRate,
      walletId: payData.walletId,
      hint: payData.hint
    });
  }

  function getBalances(ERC20 src, ERC20 dest, address destAddress) internal view returns (uint wrapperSrcBalance, uint destAddressBalance) {
    if (src == ETH_TOKEN_ADDRESS) {
        wrapperSrcBalance = address(this).balance;
    } else {
        wrapperSrcBalance = src.balanceOf(address(this));
    }

    if (dest == ETH_TOKEN_ADDRESS) {
        destAddressBalance = destAddress.balance;
    } else {
        destAddressBalance = dest.balanceOf(destAddress);
    }
  }

  // transfer delegator
  event DelegatorTransferFrom(address _from, address _to, uint _weight);
  function transferDelegator(address _newDelegator) public {
    address oldDelegator;
    uint amount = 0;
    uint i;
    for(i = 0; i < contributors.length; i++) {
      if (contributors[i].ownerAddress == msg.sender) {
        oldDelegator = contributors[i].delegator;
        amount = contributors[i].amount;
        require(oldDelegator != _newDelegator);
        contributors[i].delegator = _newDelegator;
      }
    }
    require(amount > 0);
    for(i = 0; i < delegators.length; i++) {
      if (delegators[i].ownerAddress == oldDelegator) {
        require(delegators[i].weight >= amount);
        delegators[i].weight -= amount;
      }
    }
    for(i = 0; i < delegators.length; i++) {
      if (delegators[i].ownerAddress == _newDelegator) {
        delegators[i].weight += amount;
      }
    }
    emit DelegatorTransferFrom(oldDelegator, _newDelegator, amount);
  }

  event RefundedContributor(address _address, uint _amount);
  function requestRefundContributor() public {
    require(isReverted == true); // only refund if it is reverted
    uint refundAmount;
    address delegator;
    uint i;
    for(i = 0; i < contributors.length; i++) {
      if (contributors[i].ownerAddress == msg.sender) {
        refundAmount = contributors[i].amount;
        delegator = contributors[i].delegator;
        require(refundAmount > 0);
      }
    }
    if (acceptedToken == ETH_TOKEN_ADDRESS) {
      msg.sender.transfer(refundAmount);
    } else {
      require(acceptedToken.transferFrom(address(this), msg.sender, refundAmount));
    }
    for(i = 0; i < delegators.length; i++) {
      if (delegators[i].ownerAddress == delegator) {
        require(delegators[i].weight >= refundAmount);
        delegators[i].weight -= refundAmount;
      }
    }
    emit RefundedContributor(msg.sender, refundAmount);
  }

  function getVoteStatus(uint _requestID) public view returns (uint negative, uint unknown, uint positive) {
    require(now > endTime); // ended
    require(requestFunds.length > _requestID);
    negative = 0;
    unknown = 0;
    positive = 0;
    uint i;
    for(i = 0; i < delegators.length; i++) {
      unknown += delegators[i].weight;
    }
    Vote[] storage votes = votings[_requestID];
    for(i = 0; i < votes.length; i++) {
      require(unknown >= votes[i].weight);
      if (votes[i].isApproved) {
        positive += votes[i].weight;
        unknown -= votes[i].weight;
      } else {
        negative += votes[i].weight;
        unknown -= votes[i].weight;
      }
    }
    return (negative, unknown, positive);
  }

  function getRequestFundInfo(uint _requestID) public view returns (uint _amount, address _toAddress, uint _endTime, bool _isEnded, uint _status) {
    require(requestFunds.length > _requestID);
    _amount = requestFunds[_requestID].amount;
    _toAddress = requestFunds[_requestID].toAddress;
    _endTime = requestFunds[_requestID].endTime;
    _isEnded = requestFunds[_requestID].isEnded;
    _status = requestFunds[_requestID].status;
    return (_amount, _toAddress, _endTime, _isEnded, _status);
  }

  function getLastestRequestFundID() public view returns (uint requestID) {
    return requestFunds.length;
  }
}

// 999999999999
// 0xad6d458402f60fd3bd25163575031acdce07538d
// 0x8AC7230489E80000