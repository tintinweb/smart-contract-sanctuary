// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {ISellToken} from './ISellToken.sol';
import {SafeMath} from './SafeMath.sol';
import {IERC721} from './IERC721.sol';
import './ReentrancyGuard.sol';

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 **/
contract SellTokenBNB is ReentrancyGuard {
  using SafeMath for uint256;
  // Todo : Update when deploy to production
  uint256 public constant DECIMAL_18 = 10**18;
  uint256 public constant PERCENTS_DIVIDER = 1000000000;
  address public IDOAdmin;
  address public ContractNFTOwner;
  address public IDO_TOKEN;
  address public IDO_NFT_TOKEN;
  address public OLD_SELL_CONTRACT;

  uint256 public tokenRate;
  uint256 public f1_rate;
  uint256 public f2_rate;
  mapping(address => uint256) public buyerAmount;
  mapping(address => address) public referrers;
  mapping(address => uint256) public refAmount;
  bool public is_enable = false;
  uint256 public totalBuyIDO=0;
  uint256 public totalRewardIDO=0;
  uint256 public unlockPercent = 0;
  
  uint256 public minimumBuyAmount = DECIMAL_18 / 10; //0.1 BNB
  uint256 public maximumBuyAmount = 50 ether; //50 BNB


  mapping(address => uint256) public airDropAmount;
  mapping(address => uint256) public refAirDrop;
  mapping(address => bool) public airDroper;

  //mapping(uint256 => uint8) public NFTHolds;
  struct NFTInfo {
        uint256 tokenID;
        address user;
        uint256 claimAt;
        bool isEnable;
    }
  mapping(uint256 => NFTInfo) public NFTHolds;
  uint256[] public NFTList;
  uint256 public totalNFT=0;
  uint256 public totalNFTClaimed=0;

  uint256 public unlockPercentAirDrop = 0;
  uint256 public amountClaimAirDrop=0;
  uint256 public amountClaimFee= 0;
  uint256 public totalAirDrops=0;
  uint256 public totalRefAirDrops=0;

  bool public _paused = false;
  bool public _pausedNFT = false;

  event NewReferral(address indexed user, address indexed ref, uint8 indexed level);
  event SellIDO(address indexed user, uint256 indexed sell_amount, uint256 indexed buy_amount);
  event RefReward(address indexed user, uint256 indexed reward_amount, uint8 indexed level);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event UpdateRefUser(address indexed account, address indexed newRefaccount);
  event ClaimToken(address indexed user, uint256 indexed claimAmount);
  event ClaimNFT(address indexed user, uint256 indexed tokenid);

  modifier onlyIDOAdmin() {
    require(msg.sender == IDOAdmin, 'INVALID IDO ADMIN');
    _;
  }

  constructor(address _idoToken,address _NFTToken) public {
    IDOAdmin  = tx.origin;
    IDO_TOKEN = _idoToken;
    IDO_NFT_TOKEN = _NFTToken;
    tokenRate = 7500000000; 
    f1_rate   = 100000000;
    f2_rate   = 50000000;
    amountClaimAirDrop = 2564102 * DECIMAL_18;
    amountClaimFee = 19000000000000000;
  }

    fallback() external {
    }

    receive() payable external {
        
    }


    function pause() public onlyIDOAdmin {
      _paused=true;
    }

    function unpause() public onlyIDOAdmin {
      _paused=false;
    }

    function pauseNFT() public onlyIDOAdmin {
      _pausedNFT=true;
    }

    function unpauseNFT() public onlyIDOAdmin {
      _pausedNFT=false;
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
    if (is_enable){
      return 0;
    }
    uint256 totalAmountBuy = buyerAmount[recipient];
    uint256 totalAmountAirDrop = airDropAmount[recipient].add(refAirDrop[recipient]);
    totalAmountBuy = totalAmountBuy - totalAmountBuy * unlockPercent / PERCENTS_DIVIDER;
    totalAmountAirDrop = totalAmountAirDrop - totalAmountAirDrop * unlockPercentAirDrop / PERCENTS_DIVIDER;
    if (OLD_SELL_CONTRACT != address(0)) {
      uint256 receiedAmount = ISellToken(OLD_SELL_CONTRACT).receivedAmount(recipient);
      return totalAmountBuy + totalAmountAirDrop + receiedAmount ;
    }
    else 
    {
      return totalAmountBuy + totalAmountAirDrop;
    }
  }

  /**
   * @dev Update rate for refferal
   */
  function updateRateRef(uint256 _f1_rate, uint256 _f2_rate) public onlyIDOAdmin {
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
   * @dev 
   * @param recipient recipient of the transfer
   */
  function updateLock(address recipient, uint256 _lockAmount) public onlyIDOAdmin {
    buyerAmount[recipient] += _lockAmount;
  }
  /** 
   * @dev 
   */
  function updateSubLock(address recipient, uint256 _lockAmount) public onlyIDOAdmin {
    require(buyerAmount[recipient] >= _lockAmount , "Sorry: input data");
    buyerAmount[recipient] -= _lockAmount;
  }

  /**
   * @dev 
   */
  function updateRefUser(address account, address newRefAccount) public onlyIDOAdmin {
     referrers[account] = newRefAccount;
     emit UpdateRefUser(account, newRefAccount);
  }

  /**
   * @dev Update unlockPercentAirDrop
   */
  function updateUnlockPercentAirDrop(uint256 _unlockPercentAirDrop) public onlyIDOAdmin {
    unlockPercentAirDrop = _unlockPercentAirDrop;
  }

  /**
   * @dev Update unlockPercent
   */
  function updateUnlockPercent(uint256 _unlockPercent) public onlyIDOAdmin {
    unlockPercent = _unlockPercent;
  }

  /**
   * @dev Update ContractOwner
   */
  function updateContractNFTOwner(address _ContractNFTOwner) public onlyIDOAdmin {
    ContractNFTOwner = _ContractNFTOwner;
  }

  /**
   * @dev Update amountClaimFee
   */
   
  function updateAmountClaimFee(uint256 _amountClaimFee) public onlyIDOAdmin {
    amountClaimFee = _amountClaimFee;
  }

  function updateAmountClaimAirDrop(uint256 _amountClaimAirDrop) public onlyIDOAdmin {
    amountClaimAirDrop = _amountClaimAirDrop;
  }
  
  function updateMinimumBuyAmount(uint256 _minimumBuyAmount) public onlyIDOAdmin {
    minimumBuyAmount = _minimumBuyAmount;
  }

  function updateMaximumBuyAmount(uint256 _maximumBuyAmount) public onlyIDOAdmin {
    maximumBuyAmount = _maximumBuyAmount;
  }

  function addNFTReceiver(
        uint256[] calldata idTokens
    ) public onlyIDOAdmin {

        for (uint256 index; index < idTokens.length; index++) {
                if(ownerOfNFT(idTokens[index]) == ContractNFTOwner)
                if(NFTHolds[idTokens[index]].tokenID == 0)
                {
                    NFTHolds[idTokens[index]].tokenID = idTokens[index];
                    NFTList.push(idTokens[index]);
                    totalNFT += 1;
                }

        }       
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
    
    function getApproved(uint256 tokenId) external view returns (address){
        return IERC721(IDO_NFT_TOKEN).getApproved(tokenId);
    }

    function ownerOfNFT(uint256 tokenId) public view returns (address){
        return IERC721(IDO_NFT_TOKEN).ownerOf(tokenId);
    }

    

  /**
   * @dev 
   * @param recipients recipients of the transfer
   */
  function sendFTLNFTList(address[] calldata recipients) public onlyIDOAdmin {
  
    require(totalNFT - totalNFTClaimed > recipients.length, "Sorry: not enought NFT");
    for (uint256 i = 0; i < recipients.length; i++) {
       //IERC721(IDO_NFT_TOKEN).transferFrom(address(this),recipients[i], idTokens[i]);
       _sendNFT(recipients[i]);
    }
  }

  function _sendNFT(address recipient) internal {
       if(totalNFTClaimed < totalNFT && _pausedNFT == false)
       {
           if(ownerOfNFT(NFTList[totalNFTClaimed]) == ContractNFTOwner)
            {
               IERC721(IDO_NFT_TOKEN).transferFrom(address(this), recipient, NFTList[totalNFTClaimed]);
               NFTHolds[NFTList[totalNFTClaimed]].isEnable = false;
               NFTHolds[NFTList[totalNFTClaimed]].claimAt = block.timestamp;
               NFTHolds[NFTList[totalNFTClaimed]].user = recipient;
               emit ClaimNFT(recipient,NFTList[totalNFTClaimed]);
            }      
           totalNFTClaimed += 1;
       }
       
  }

  /**
   * @dev Withdraw IDO BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawBNB(address payable recipient) public onlyIDOAdmin {
    _safeTransferBNB(recipient, address(this).balance);
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
   
   function AirDrop(address _referrer) public ifNotPaused payable returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        uint256 fee_amount = msg.value;
        require(fee_amount>=amountClaimFee , "Sorry: your address enought fee");
        require(airDroper[msg.sender] != true , "Sorry: your address was claimed");
        uint256 balance = IERC20(IDO_TOKEN).balanceOf(address(this));
        require(balance >= amountClaimAirDrop, "Sorry: no tokens to release");

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
        airDropAmount[msg.sender] += amountClaimAirDrop;
        totalAirDrops += amountClaimAirDrop;
        emit ClaimToken(msg.sender,amountClaimAirDrop);
        _sendNFT(msg.sender);
        return amountClaimAirDrop;
   }


  /**
   * @dev execute buy Token external payable 
   **/
  function buy(address _referrer)  public  ifNotPaused  payable returns (uint256) {
    uint256 buy_amount = msg.value;
    address recipient =  msg.sender;
    require( buy_amount >= minimumBuyAmount && buy_amount<= maximumBuyAmount , "Minimum amount is 0.05 BNB and Maximum amount is 10 BNB"); 
    //require((buy_amount > 0), "Minimum amount is 0.05 BNB and Maximum amount is 10 BNB"); 
      
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
  
    uint256 sold_amount = buy_amount * DECIMAL_18 / tokenRate;
    buyerAmount[recipient] += sold_amount;
    IERC20(IDO_TOKEN).transfer(recipient, sold_amount);
    emit SellIDO(msg.sender, sold_amount, buy_amount);
    // send ref reward

    if (referrers[msg.sender] != address(0) && f1_rate > 0){
      uint256 f1_reward = buy_amount * f1_rate / PERCENTS_DIVIDER;
      
      if(address(this).balance >= f1_reward){
        //IERC20(IDO_TOKEN).transfer(referrers[msg.sender], f1_reward);
        _safeTransferBNB(referrers[msg.sender], f1_reward);
        refAmount[referrers[msg.sender]] += f1_reward;
        emit RefReward(referrers[msg.sender] , f1_reward, 1);
      }
    }
    if (referrers[referrers[msg.sender]] != address(0)  && f2_rate > 0){
      uint256 f2_reward = buy_amount * f2_rate / PERCENTS_DIVIDER;
      if(address(this).balance >= f2_reward){
        //IERC20(IDO_TOKEN).transfer(referrers[referrers[msg.sender]], f2_reward);
        _safeTransferBNB(referrers[referrers[msg.sender]], f2_reward);
        refAmount[referrers[referrers[msg.sender]]] += f2_reward;
        emit RefReward(referrers[referrers[msg.sender]], f2_reward, 2);
      }
    }
    return sold_amount;

  }
}