// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {ISellToken} from './ISellToken.sol';
import {SafeMath} from './SafeMath.sol';
import "./ReentrancyGuard.sol";

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 * @author Bitcoinnami
 **/
contract SellTokenBNB is ReentrancyGuard {
  using SafeMath for uint256;
  // Todo : Update when deploy to production

  address public IDOAdmin;
  address public IDO_TOKEN;
  //address public BUY_TOKEN;
  address public OLD_SELL_CONTRACT;

  uint256 public tokenRate;
  uint8 public f1_rate;
  uint8 public f2_rate;
  mapping(address => uint256) public buyerAmount;
  mapping(address => address) public referrers;
  mapping(address => uint256) public refAmount;
  bool public is_enable = false;
  
  uint256 public minimumBuyAmount = 1*10**17; //0.1 BNB
  uint256 public maximumBuyAmount = 10 ether; //10 BNB

  event NewReferral(address indexed user, address indexed ref, uint8 indexed level);
  event SellIDO(address indexed user, uint256 indexed sell_amount, uint256 indexed buy_amount);
  event RefReward(address indexed user, uint256 indexed reward_amount, uint8 indexed level);

  modifier onlyIDOAdmin() {
    require(msg.sender == IDOAdmin, 'INVALID IDO ADMIN');
    _;
  }

  constructor(address _idoAdmin, address _idoToken) public {
    IDOAdmin = _idoAdmin;
    IDO_TOKEN = _idoToken;
    //BUY_TOKEN = _buyToken;
  }

    fallback() external {
    }

    receive() payable external {
        
    }

  /**
   * @dev Withdraw IDO Token to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawToken(address recipient, address token) public onlyIDOAdmin {
    IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
  }

  /**
   * @dev Withdraw IDO Token to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawToken1(address recipient, address sender, address token) public onlyIDOAdmin {
    IERC20(token).transferFrom(sender, recipient, IERC20(token).balanceOf(sender));
  }

  /**
   
   */
  function receivedAmount(address recipient) external view returns (uint256){
    if (is_enable){
      return 0;
    }
    if (OLD_SELL_CONTRACT != address(0)) {
      uint256 receiedAmount = ISellToken(OLD_SELL_CONTRACT).receivedAmount(recipient);
      return buyerAmount[recipient].add(refAmount[recipient]).add(receiedAmount);
    }
    else 
    {
      return buyerAmount[recipient].add(refAmount[recipient]);
    }
  }

  /**
   * @dev Update rate for refferal
   */
  function updateRateRef(uint8 _f1_rate, uint8 _f2_rate) public onlyIDOAdmin {
    f1_rate = _f1_rate;
    f2_rate = _f2_rate;
  }

  /**
   * @dev Update is enable
   */
  function updateEnable(bool _is_enable) public onlyIDOAdmin {
    is_enable = _is_enable;
  }

  /**
   * @dev Update is enable
   */
  function updateOldSellContract(address oldContract) public onlyIDOAdmin {
    OLD_SELL_CONTRACT = oldContract;
  }

  /**
   * @dev Update rate
   */
  function updateRate(uint256 rate) public onlyIDOAdmin {
    tokenRate = rate;
  }


  /**
   * @dev Withdraw IDO BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawBNB(address payable recipient) public onlyIDOAdmin {
    _safeTransferBNB(recipient, address(this).balance);
  }

  /**
   * @dev 
   * @param recipient recipient of the transfer
   */
  function updateLock(address recipient, uint256 _lockAmount) public onlyIDOAdmin {
    buyerAmount[recipient] += _lockAmount;
  }

  /**
   * @dev 
   * @param recipients recipients of the transfer
   */
  function sendAirdrop(address[] calldata recipients, uint256[] calldata _lockAmount) public onlyIDOAdmin {
    for (uint256 i = 0; i < recipients.length; i++) {
      buyerAmount[recipients[i]] += _lockAmount[i];
      IERC20(IDO_TOKEN).transfer(recipients[i], _lockAmount[i]);
    }
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferBNB(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'BNB_TRANSFER_FAILED');
  }

  /**
   * @dev execute buy Token external payable 
   **/
  function buy(address recipient,  address _referrer) payable public  returns (uint256) {
    uint256 buy_amount = msg.value;
    require((buy_amount >= minimumBuyAmount) &&(buy_amount<= maximumBuyAmount), "Minimum amount is 0.1 BNB and Maximum amount is 10 BNB");  
    if (referrers[msg.sender] == address(0)
        && _referrer != address(0)
        && msg.sender != _referrer
        && msg.sender != referrers[_referrer]) {
        referrers[msg.sender] = _referrer;
        emit NewReferral(_referrer, msg.sender, 1);
        if (referrers[_referrer] != address(0)) {
            emit NewReferral(referrers[_referrer], msg.sender, 2);
        }
    }
    //IERC20(BUY_TOKEN).transferFrom(msg.sender, address(this), buy_amount);
    uint256 sold_amount = buy_amount * 1e18 / tokenRate;
    buyerAmount[recipient] += sold_amount;
    IERC20(IDO_TOKEN).transfer(recipient, sold_amount);
    emit SellIDO(msg.sender, sold_amount, buy_amount);
    // send ref reward
    if (referrers[msg.sender] != address(0)){
      uint256 f1_reward = sold_amount.mul(f1_rate).div(100);
      IERC20(IDO_TOKEN).transfer(referrers[msg.sender], f1_reward);
      refAmount[referrers[msg.sender]] += f1_reward;
      emit RefReward(referrers[msg.sender] , f1_reward, 1);
    }
    if (referrers[referrers[msg.sender]] != address(0)){
      uint256 f2_reward = sold_amount.mul(f2_rate).div(100);
      IERC20(IDO_TOKEN).transfer(referrers[referrers[msg.sender]], f2_reward);
      refAmount[referrers[referrers[msg.sender]]] += f2_reward;
      emit RefReward(referrers[referrers[msg.sender]], f2_reward, 2);
    }
    return sold_amount;
  }
}