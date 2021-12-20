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
contract IDOCGOLDContract {
  using SafeMath for uint256;
  // Todo : Update when deploy to production

  address public IDOAdmin;
  address public IDO_TOKEN;
  address public BUY_TOKEN;
  address public OLD_SELL_CONTRACT;
  uint256 public constant PERCENTS_DIVIDER = 1000000000;

  uint256 public tokenRate;
  uint8 public f1_rate;
  uint8 public f1_rate_airdrop;
  
  mapping(address => address) public referrers;
  mapping(address => uint256) public buyerAmount;
  mapping(address => uint256) public refAmount;
  uint8 public unlockPercent = 0;
  uint256 public totalBuyIDO=0;
  uint256 public totalRewardIDO=0;


  mapping(address => uint256) public airDropAmount;
  mapping(address => uint256) public refAirDrop;
  mapping(address => bool) public airDroper;
  uint8 public unlockPercentAirDrop = 0;
  uint256 public amountClaimAirDrop=0;
  uint256 public totalAirDrops=0;
  uint256 public totalRefAirDrops=0;

  
  
  bool public is_enable = false;
  bool public _paused = false;
  

  event NewReferral(address indexed user, address indexed ref, uint8 indexed level);
  event SellIDO(address indexed user, uint256 indexed sell_amount, uint256 indexed buy_amount);
  event RefReward(address indexed user, uint256 indexed reward_amount, uint8 indexed level);
  event AirDropAt(address indexed user, uint256 indexed claimAmount);
  event RefAirDropAt(address indexed user, uint256 indexed reward_amount, uint8 indexed level);

  modifier onlyIDOAdmin() {
    require(msg.sender == IDOAdmin, 'INVALID IDO ADMIN');
    _;
  }

    

  constructor(address _idoAdmin, address _buyToken, address _idoToken) public {
    IDOAdmin = _idoAdmin;
    IDO_TOKEN = _idoToken;
    BUY_TOKEN = _buyToken;
    amountClaimAirDrop=10000*10**18;
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
      uint256 totalAmountBuy = buyerAmount[recipient].add(refAmount[recipient]);
      uint256 totalAmountAirDrop = airDropAmount[recipient].add(refAirDrop[recipient]);
      uint256 totalLock = totalAmountBuy.sub(totalAmountBuy.mul(unlockPercent).div(PERCENTS_DIVIDER)) +
        totalAmountAirDrop.sub(totalAmountAirDrop.mul(unlockPercentAirDrop).div(PERCENTS_DIVIDER))
      ;
      return totalLock.add(receiedAmount);
    }
    else 
    {
      uint256 totalAmountBuy = buyerAmount[recipient].add(refAmount[recipient]);
      uint256 totalAmountAirDrop = airDropAmount[recipient].add(refAirDrop[recipient]);
      return  totalAmountBuy.sub(totalAmountBuy.mul(unlockPercent).div(PERCENTS_DIVIDER)) +
        totalAmountAirDrop.sub(totalAmountAirDrop.mul(unlockPercentAirDrop).div(PERCENTS_DIVIDER))
      ;
    }

  }

  /**
   * @dev Update rate for refferal
   */
  function updateRateRef(uint8 _f1_rate,uint8 _f1_rate_airdrop) public onlyIDOAdmin {
    f1_rate = _f1_rate;
    f1_rate_airdrop = _f1_rate_airdrop;
  }

  /**
   * @dev Update rate for amount claim airdrop
   */
  function updateRateRef(uint8 _amountClaimAirDrop) public onlyIDOAdmin {
    amountClaimAirDrop = _amountClaimAirDrop;
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

  /**
   * @dev 
   * @param recipient recipient of the transfer
   */
  function updateSubLock(address recipient, uint256 _lockAmount) public onlyIDOAdmin {
    require(buyerAmount[recipient] >= _lockAmount , "Sorry: input data");
    buyerAmount[recipient] -= _lockAmount;
  }

  /**
   * @dev 
   * @param recipients recipients of the transfer
   */

  function sendAirdrop(address[] calldata recipients, uint256[] calldata _lockAmount) public onlyIDOAdmin {
    for (uint256 i = 0; i < recipients.length; i++) {
      buyerAmount[recipients[i]] += _lockAmount[i];
      IERC20(IDO_TOKEN).transfer(recipients[i], _lockAmount[i]);
      totalAirDrops.add(_lockAmount[i]);
      emit AirDropAt(msg.sender,_lockAmount[i]);
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
   * @dev claim aridrop
   */
   
   function AirDrop(address _referrer) public ifNotPaused returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        require(airDroper[msg.sender] != true , "Sorry: your address was claimed");
        uint256 amount = IERC20(IDO_TOKEN).balanceOf(address(this));
        require(amount >= amountClaimAirDrop, "Sorry: no tokens to release");

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

        airDroper[msg.sender] = true;
        
        IERC20(IDO_TOKEN).transfer(msg.sender,amountClaimAirDrop);
        airDropAmount[msg.sender].add(amountClaimAirDrop);
        totalAirDrops.add(amountClaimAirDrop);

        emit AirDropAt(msg.sender,amountClaimAirDrop);

        // send ref token reward
        if (referrers[msg.sender] != address(0)){
          uint256 f1_reward = f1_rate_airdrop;
          
          IERC20(IDO_TOKEN).transfer(referrers[msg.sender], f1_reward);
          refAirDrop[referrers[msg.sender]] += f1_reward;
          totalRefAirDrops.add(f1_reward);

          emit RefAirDropAt(referrers[msg.sender] , f1_reward, 1);
        }
        return amountClaimAirDrop;
   }


  /**
   * @dev execute buy Token
   **/
  function buyIDO(address recipient, uint256 buy_amount, address _referrer) public ifNotPaused returns (uint256) {
    require(50*10*18 <= buy_amount, "Minium buy IDO");
    uint256 allowance = IERC20(BUY_TOKEN).allowance(msg.sender, address(this));
    require(allowance >= buy_amount, "Check the token allowance");
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
    uint256 sold_amount = buy_amount.mul(PERCENTS_DIVIDER).div(tokenRate);
    buyerAmount[recipient] += sold_amount;
    IERC20(IDO_TOKEN).transfer(recipient, sold_amount);
    totalBuyIDO.add(sold_amount);
    emit SellIDO(msg.sender, sold_amount, buy_amount);
    // send ref reward
    if (referrers[msg.sender] != address(0)){
      uint256 f1_reward = sold_amount.mul(f1_rate).div(PERCENTS_DIVIDER);
      IERC20(BUY_TOKEN).transfer(referrers[msg.sender], f1_reward);
      refAmount[referrers[msg.sender]] += f1_reward;
      totalRewardIDO.add(f1_reward);
      emit RefReward(referrers[msg.sender] , f1_reward, 1);
    }
    return sold_amount;
  }
}