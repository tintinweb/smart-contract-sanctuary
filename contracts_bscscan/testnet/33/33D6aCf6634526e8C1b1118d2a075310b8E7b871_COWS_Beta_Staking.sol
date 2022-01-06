// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {IUserCowsBoy} from './IUserCowsBoy.sol';
import {SafeMath} from './SafeMath.sol';
import './ReentrancyGuard.sol';


contract COWS_Beta_Staking is ReentrancyGuard {
  using SafeMath for uint256;
  // Todo : Update when deploy to production

  address public operator;
  address public USER_COWSBOY;
  address public BUY_TOKEN;
  
  mapping(address => uint256) public buyerAmount;
  mapping(address => uint256) public claimAmount;
  
  uint256 public totalStaking=0;
  uint256 public totalClaimed=0;
  uint256 public totalUser=0;
  uint256 public releaseTime=1641421597;

  uint256 public constant DECIMAL_18 = 10**18;
  uint256 public minimumStaking=500*DECIMAL_18;

  bool public _paused = false;
  
  event Staking(address indexed user, uint256 indexed sell_amount);
  event ClaimAt(address indexed user, uint256 indexed claimAmount);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyAdmin() {
    require(msg.sender == operator, 'INVALID ADMIN');
    _;
  }

    

  constructor(address _userCowBoy, address _lockToken) public {
    USER_COWSBOY = _userCowBoy;
    BUY_TOKEN = _lockToken;
    operator  = tx.origin;
  }

    function pause() public onlyAdmin {
      _paused=true;
    }

    function unpause() public onlyAdmin {
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
    function transferOwnership(address newOwner) public onlyAdmin {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal onlyAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(operator, newOwner);
        operator = newOwner;
    }
  

  /**
   * @dev Withdraw IDO Token to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawToken(address recipient, address token) public onlyAdmin {
    IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
  }


  /**
   * @dev Update is enable
   */
  function updateUserContract(address _userCowBoy) public onlyAdmin {
    USER_COWSBOY = _userCowBoy;
  }

  

  /**
   * @dev Update minimumBuy
   */
  function updateMinBuy(uint256 _minimumStaking) public onlyAdmin {
    minimumStaking = _minimumStaking;
  }

  


  /**
   * @dev Withdraw IDO BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawBNB(address recipient) public onlyAdmin {
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

   
   function releaseCOWS() public returns (uint256) {
       address recipient = msg.sender;
       require(block.timestamp > releaseTime, "Sorry: it's not time yet to  release");
       require(buyerAmount[recipient] == 0, "Sorry: no tokens to release");
       require(claimAmount[recipient] > 0, "Sorry: your tokens was release ");
       uint256 claim_amount = buyerAmount[recipient];
       require(IERC20(BUY_TOKEN).balanceOf(address(this)) >= claim_amount, "Sorry: not enough tokens to release");
       IERC20(BUY_TOKEN).transferFrom(address(this), recipient, claim_amount);   
       claimAmount[recipient]=  claim_amount;
       totalClaimed += claim_amount;
       emit ClaimAt(recipient, claim_amount);
       return 1;
   }

  function StakingCOWS() public ifNotPaused returns (uint256) {
   // solhint-disable-next-line not-rely-on-time
    uint256 buy_amount = minimumStaking;
    address recipient = msg.sender;
    require(IUserCowsBoy(USER_COWSBOY).isRegister(recipient) == true , "Address not exist registed system");
    require(buyerAmount[recipient] == 0, "Only lock onetime ");
    uint256 allowance = IERC20(BUY_TOKEN).allowance(msg.sender, address(this));
    require(allowance >= buy_amount, "Check the token allowance");
    IERC20(BUY_TOKEN).transferFrom(recipient, address(this), buy_amount);   
    totalUser += 1;
    buyerAmount[recipient] += minimumStaking;
    totalStaking += buy_amount;
    emit Staking(recipient, buy_amount);
    return buy_amount;
  }
}