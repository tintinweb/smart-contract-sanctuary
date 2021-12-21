// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {ISellToken} from './ISellToken.sol';
import {SafeMath} from './SafeMath.sol';

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 * @author Bitcoinnami
 **/

contract PreSaleContract {
  using SafeMath for uint256;
  // Todo : Update when deploy to production

  address public IDOAdmin;
  address public IDO_TOKEN;
  address public BUY_TOKEN;
  address public OLD_SELL_CONTRACT;
  uint256 public constant RATE_DIVIDER = 1000000000;
  uint256 public constant STEP_1_DAY = 86400;

  uint256[] public PLANS_PERCENTS = [10, 11, 12, 15, 15, 15 , 15, 7];
  uint256[] public PLANS_DAYS     = [70, 77, 84, 91, 98, 105, 112, 119];

  uint256 public tokenRate;
  uint256 public f1_rate;

  mapping(address => address) public referrers;
  mapping(address => uint256) public buyerAmount;
  mapping(address => uint256) public claimedAmount;
  mapping(address => uint256) public refAmount;
  uint256 public unlockPercent = 0;
  uint256 public totalBuyIDO=0;
  uint256 public totalRewardIDO=0;
  uint256 public timeStart=0;
  uint256 public totalUser=0;
  uint256 public minimumBuy=10*10**18;

  bool public _paused = false;
  
  event NewReferral(address indexed user, address indexed ref, uint8 indexed level);
  event SellIDO(address indexed user, uint256 indexed sell_amount, uint256 indexed buy_amount);
  event RefReward(address indexed user, uint256 indexed reward_amount, uint8 indexed level);
  event claimAt(address indexed user, uint256 indexed claimAmount);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyIDOAdmin() {
    require(msg.sender == IDOAdmin, 'INVALID IDO ADMIN');
    _;
  }

    

  constructor(address _idoAdmin, address _buyToken, address _idoToken) public {
    IDOAdmin = _idoAdmin;
    IDO_TOKEN = _idoToken;
    BUY_TOKEN = _buyToken;
    timeStart = block.timestamp;
  }

    function pause() public onlyIDOAdmin {
      _paused=true;
    }

    function unpause() public onlyIDOAdmin {
      _paused=false;
    }

    
    modifier ifPaused(){
      require(_paused,"");
      _;
    }

    modifier ifNotPaused(){
      require(!_paused,"");
      _;
    }  
  
  /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyIDOAdmin {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal onlyIDOAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(IDOAdmin, newOwner);
        IDOAdmin = newOwner;
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
    if ( buyerAmount[recipient] == 0){
      return 0;
    }  
    return _receivedAmount(recipient);
  }

  function userInfo (address account) public view returns(
        uint256 amount,
        uint256 amountClaimed,
        uint256 amountBonus,
        uint256 claimAble,
        address reff
        ) {
        return (buyerAmount[account],claimedAmount[account],refAmount[account],_receivedAmount(account),referrers[account]);
  }

  function planInfo (address account, uint256 plan) public view returns(
        uint256 amount,
        uint256 time,
        uint256 percent,
        bool claimAble
        ) {
        if(plan < PLANS_DAYS.length){
          uint256 amountPlan = buyerAmount[account] * PLANS_PERCENTS[plan] / 100 ;
          uint256 timePlan = timeStart + PLANS_DAYS[plan] * STEP_1_DAY ;
          bool isClaim = false;
          if( timePlan < block.timestamp )
          {
              isClaim = true;
          }
          return (amountPlan,timePlan,PLANS_PERCENTS[plan],isClaim);
        }
        else{
            return (0,0,0,false);
        }    
  }

  function _receivedAmount(address recipient) internal view returns (uint256){
    uint256 totalAmount=0;
    for (uint256 i = 0; i < PLANS_DAYS.length; i++) {
        if( timeStart + PLANS_DAYS[i] * STEP_1_DAY < block.timestamp ){
            totalAmount += buyerAmount[recipient] * PLANS_PERCENTS[i] / 100;
        }
    }
    return totalAmount - claimedAmount[recipient];
  }

  /**
   * @dev Update rate for refferal
   */
  function updateRateRef(uint256 _f1_rate) public onlyIDOAdmin {
    f1_rate = _f1_rate;
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
   * @dev Update minimumBuy
   */
  function updateMinBuy(uint256 _minimumBuy) public onlyIDOAdmin {
    minimumBuy = _minimumBuy;
  }

  


  /**
   * @dev Withdraw IDO BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawBNB(address recipient) public onlyIDOAdmin {
    _safeTransferBNB(recipient, address(this).balance);
  }

  /**
   * @dev 
   * @param recipient recipient of the transfer
   */
  function updateAddLock(address recipient, uint256 _lockAmount) public onlyIDOAdmin {
    buyerAmount[recipient] += _lockAmount;
  }

  function updateRefUser(address recipient, uint256 _lockAmount) public onlyIDOAdmin {
    buyerAmount[recipient] += _lockAmount;
  }

  /**
   * @dev 
   * @param recipient recipient of the transfer
   */
  function updateSubLock(address recipient, uint256 _lockAmount) public onlyIDOAdmin {
    require(buyerAmount[recipient] >= _lockAmount , "Sorry: input data");
    buyerAmount[recipient] -= _lockAmount;
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
   * @dev claim aridrop
   */
   
   function ClaimDES() public returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        require(buyerAmount[msg.sender] >0 , "Sorry: no token to claim ");
        uint256 balanceToken = IERC20(IDO_TOKEN).balanceOf(address(this));
        uint256 amountClaim= _receivedAmount(msg.sender);
        require(balanceToken >= amountClaim, "Sorry: no tokens to release");    
        IERC20(IDO_TOKEN).transfer(msg.sender,amountClaim);
        claimedAmount[msg.sender] += amountClaim;
        emit claimAt(msg.sender,amountClaim);
        return amountClaim;
   }


  /**
   * @dev execute buy Token
   **/
  function buyIDO(uint256 buy_amount, address _referrer) public ifNotPaused returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    require(buy_amount >= minimumBuy, "Minium buy IDO ");
    uint256 allowance = IERC20(BUY_TOKEN).allowance(msg.sender, address(this));
    address recipient = msg.sender;
    require(allowance >= buy_amount, "Check the token allowance ");
    require(IERC20(BUY_TOKEN).balanceOf(recipient) >= buy_amount, "Check the token balance ");
    require(tokenRate >0 , "Check the rate ");
    uint256 sold_amount = buy_amount * RATE_DIVIDER / tokenRate;
    require(IERC20(IDO_TOKEN).balanceOf(address(this)) >= sold_amount, "Check the token sell balance ");

    
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

    IERC20(BUY_TOKEN).transferFrom(msg.sender, address(this), buy_amount);
    if(buyerAmount[recipient] == 0){
      totalUser += 1;
    }

    buyerAmount[recipient] += sold_amount;
    //Lock Coin in Contract 70 days 
    //IERC20(IDO_TOKEN).transfer(recipient, sold_amount);
    totalBuyIDO += sold_amount;
    emit SellIDO(msg.sender, sold_amount, buy_amount);
    // send ref reward
    if (referrers[msg.sender] != address(0) && f1_rate > 0 ){
      uint256 f1_reward = buy_amount * f1_rate / RATE_DIVIDER;
      if(IERC20(BUY_TOKEN).balanceOf(address(this)) >= f1_reward)
      {
          IERC20(BUY_TOKEN).transfer(referrers[msg.sender], f1_reward);
          refAmount[referrers[msg.sender]] += f1_reward;
          totalRewardIDO += f1_reward;
          emit RefReward(referrers[msg.sender] , f1_reward, 1);
      }
    }
    return sold_amount;
  }
}