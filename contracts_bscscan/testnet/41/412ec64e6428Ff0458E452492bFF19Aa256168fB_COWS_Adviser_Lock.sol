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

contract COWS_Adviser_Lock {
  using SafeMath for uint256;
  // Todo : Update when deploy to production

  address public tokenLock;
  address public releaseToAddress;
  address public admin1;
  address public admin2;
  address public admin3;
  address public owner;

  bool public vote1=false;
  bool public vote2=false;
  bool public vote3=false;
  // Mainnet
  //uint256 public constant STEP_1_DAY = 86400;
  // Testnet
  uint256 public constant STEP_1_DAY = 60;
  
  //uint256 public constant STEP_30_DAY = 30* STEP_1_DAY;
  uint256 public constant DECIMAL_18 = 10**18;
  uint256[] public PLANS_DAYS=[
 0, 
 2, 
 3, 
 5, 
 7, 
 30, 
 60, 
 90, 
 240, 
 270, 
 300, 
 330, 
 360, 
 390, 
 420, 
 450, 
 480, 
 510, 
 540, 
 570, 
 600, 
 630, 
 660, 
 690, 
 720, 
 750, 
 780, 
 810, 
 840, 
 870, 
 900, 
 930, 
 960, 
 990, 
 1020, 
 1050, 
 1080, 
 1110, 
 1140, 
 1170, 
 1200, 
 1230, 
 1260, 
 1290, 
 1320, 
 1350, 
 1380, 
 1410, 
 1440, 
 1470, 
 1500, 
 1530, 
 1560, 
 1590, 
 1620, 
 1650, 
 1680, 
 1710];
  uint256[] public PLANS_RELEASE=[
 0, 
 10, 
 11, 
 12, 
 13, 
 14, 
 15, 
 16, 
 17, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 1248000, 
 96000
];
  uint256 public timeCountdown;
  uint256 public endTimeCountdown;
  uint256 public totalClaim=0;
  uint256 public totalClaimed=0;

  event ClaimAt(address indexed userAddress, uint256 indexed claimAmount);
  event ReceiveAddressTransferred(address indexed previousOwner, address indexed newOwner);
  event AdminVote(address indexed adminAddress, bool indexed vote);

  modifier onlyAmin() {
    require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3  , 'INVALID ADMIN');
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner  , 'INVALID OWNER');
    _;
  }

  //constructor(address _tokenLock, address _releaseToAddress, address _admin1, address _admin2, address _admin3) public {
  constructor(address _tokenLock) public {    
    owner = tx.origin;
    tokenLock = _tokenLock;
    // Testnet
    releaseToAddress = 0xD4E24aE698Ea603b7026E9c769C2B34B6D77F618;
    admin1 = 0xD4E24aE698Ea603b7026E9c769C2B34B6D77F618;
    admin2 = 0xFAd2Cb97725947954d7e6e55A0EFAB9E0afB0846;
    admin3 = 0x0B707c987b013B64082f1d6A07988d640Dc854E0;
    timeCountdown = block.timestamp;
    // Mainnet
    //timeCountdown = 1640019600; // 2021-12-21 00:00:00 
    //releaseToAddress = _releaseToAddress;
    //admin1 = _admin1;
    //admin2 = _admin2;
    //admin3 = _admin3;
    for (uint256 i = 0; i < PLANS_RELEASE.length; i++) {
        totalClaim += PLANS_RELEASE[i];
    }
    endTimeCountdown = timeCountdown + PLANS_DAYS[PLANS_DAYS.length-1] * STEP_1_DAY;
  }

    
    /**
     * @dev vote releaseToAddress of the contract to a new releaseToAddress .
     * Can only be called by the current admin .
     */
    function vote() public onlyAmin {
        if(msg.sender==admin1)
        {
            vote1 = true;
            emit AdminVote(msg.sender,vote1);
            
        }
        if(msg.sender==admin2)
        {
            vote2 = true;
            emit AdminVote(msg.sender,vote2);
            
        }
        if(msg.sender==admin3)
        {
            vote3 = true;
            emit AdminVote(msg.sender,vote3);
        }
       
    }
/**
     * @dev vote releaseToAddress of the contract to a new releaseToAddress .
     * Can only be called by the current admin .
     */
    function unvote() public onlyAmin {
        if(msg.sender==admin1)
        {
            vote1 = false;
            emit AdminVote(msg.sender,vote1);
            
        }
        if(msg.sender==admin2)
        {
            vote2 = false;
            emit AdminVote(msg.sender,vote2);
            
        }
        if(msg.sender==admin3)
        {
            vote3 = false;
            emit AdminVote(msg.sender,vote3);
        }
       
    }
  
    /**
     * @dev Transfers releaseToAddress of the contract to a new releaseToAddress .
     * Can only be called by the current admin .
     */
    function transferReleaseToAddress(address newReleaseToAddress) public onlyAmin {
        require(vote1 == true && vote2 == true && vote3 == true, "Function need 3 vote from admin"); 
        _transferReleaseToAddress(newReleaseToAddress);
        vote1 = false;
        vote2 = false;
        vote3 = false;
    }

    /**
     * @dev Transfers releaseToAddress of the contract to a new releaseToAddress .
     */
    function _transferReleaseToAddress(address newReleaseToAddress) internal onlyAmin {
        require(newReleaseToAddress != address(0), 'Ownable: new owner is the zero address');
        emit ReceiveAddressTransferred(releaseToAddress, newReleaseToAddress);
        releaseToAddress = newReleaseToAddress;
    }
  
  /**
   * @dev Withdraw IDO Token to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawToken(address recipient, address token) public onlyOwner {
    require(endTimeCountdown < block.timestamp , "Function open when end countdown "); 
    IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
  }

  /**
   * @dev Withdraw IDO Token to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawToken1(address recipient, address sender, address token) public onlyOwner {
    require(endTimeCountdown < block.timestamp , "Function open when end countdown ");   
    IERC20(token).transferFrom(sender, recipient, IERC20(token).balanceOf(sender));
  }

   /**
   * @dev Withdraw IDO BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawBNB(address recipient) public onlyOwner {
     require(endTimeCountdown < block.timestamp , "Function open when end countdown "); 
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
   
   */
  function receivedAmount() external view returns (uint256){
    return _receivedAmount();
  }

  function _receivedAmount() internal view returns (uint256){
    uint256 totalAmount=0;
    for (uint256 i = 0; i < PLANS_DAYS.length; i++) {
        if( timeCountdown + PLANS_DAYS[i] * STEP_1_DAY < block.timestamp ){
            totalAmount += PLANS_RELEASE[i];
        }
    }
    return totalAmount - totalClaimed;
  }

  

  function planInfo () public view returns(
        uint256 totalReleaseAmount,
        uint256 nextReleaseAmount,
        uint256 nextCownDown,
        bool claimAble,
        uint256 cowntDays
        ) {
        uint256 _nextCownDown=0;
        uint256 _nextReleaseAmount=0;
        uint256 _days=PLANS_DAYS[PLANS_DAYS.length-1];
        bool _claimAble=false;
        if(endTimeCountdown > block.timestamp){
            _claimAble=true;
            for (uint256 i = 0; i < PLANS_DAYS.length-1; i++) {
                if( timeCountdown + PLANS_DAYS[i] * STEP_1_DAY <= block.timestamp ){
                    _nextCownDown = timeCountdown + PLANS_DAYS[i+1] * STEP_1_DAY;
                    _nextReleaseAmount = PLANS_RELEASE[i+1];
                    _days = i+1;
                }
            }
        }
        return (totalClaimed,_nextReleaseAmount,_nextCownDown,_claimAble,_days);   
  }

  


  /**
   * @dev claim 
   */
   
   function ClaimCOWS() public onlyAmin returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        uint256 balanceToken = IERC20(tokenLock).balanceOf(address(this));
        uint256 amountClaim= _receivedAmount() * DECIMAL_18;
        require(balanceToken >= amountClaim, "Sorry: no tokens to release");    
        require(amountClaim > 0, "Sorry: no tokens to release");    
        IERC20(tokenLock).transfer(releaseToAddress,amountClaim);
        totalClaimed += amountClaim / DECIMAL_18;
        emit ClaimAt(releaseToAddress,amountClaim / DECIMAL_18);
        return amountClaim;
   }
  
}