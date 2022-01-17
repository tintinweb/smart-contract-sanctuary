// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {IUserCowsBoy} from './IUserCowsBoy.sol';
import {SafeMath} from './SafeMath.sol';
import './ReentrancyGuard.sol';


contract COWS_Claim_Token_Test is ReentrancyGuard {
  using SafeMath for uint256;
  // Todo : Update when deploy to production

  address public operator;
  address public USER_COWSBOY;
  address public COWS_TOKEN;
  address public RIM_TOKEN;
  uint256 public constant DECIMAL_18 = 10**18;

  mapping(address => uint256) public claimRIMAmount;
  mapping(address => uint256) public claimCOWSAmount;

  uint256 public totalUser=0;
  uint256 public amountCOWS=10000 * DECIMAL_18;
  uint256 public amountRIM=100000 * DECIMAL_18;


  bool public _paused = false;
  
  
  event ClaimTokenAt(address indexed token, address indexed user, uint256 indexed claimAmount);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyAdmin() {
    require(msg.sender == operator, 'INVALID ADMIN');
    _;
  }

    

  constructor() public {
    USER_COWSBOY = 0x009fbfe571f29c3b994a0cd84B2f47b7e7D73CDC;
    COWS_TOKEN = 0xB084b320Da2a9AC57E06e143109cD69d495275e8;
    RIM_TOKEN = 0x7949636e8a517c48569872213723994443ACc00E; 
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
   * @dev Update amount
   */
  function updateAmountClaim(uint256 _amountCOWS,uint256 _amountRIM) public onlyAdmin {
        amountCOWS = _amountCOWS;
        amountRIM = _amountRIM;
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

   
   function ClaimToken() public ifNotPaused returns (uint256) {
       address recipient = msg.sender;
       require(IUserCowsBoy(USER_COWSBOY).isRegister(recipient) == true , "Address not whitelist registed system");
       require(claimRIMAmount[recipient] == 0 && claimCOWSAmount[recipient] == 0, "Sorry: only claimed onetime ");
       require(IERC20(COWS_TOKEN).balanceOf(address(this)) >= amountCOWS, "Sorry: not enough COWS tokens to release");
       require(IERC20(RIM_TOKEN).balanceOf(address(this)) >= amountRIM, "Sorry: not enough RIM tokens to release");
       IERC20(COWS_TOKEN).transfer(recipient, amountCOWS);   
       claimCOWSAmount[recipient] +=  amountCOWS;
       emit ClaimTokenAt(COWS_TOKEN, recipient, amountCOWS);
       IERC20(RIM_TOKEN).transfer(recipient, amountRIM);   
       claimRIMAmount[recipient] +=  amountRIM;
       emit ClaimTokenAt(RIM_TOKEN, recipient, amountRIM);
       totalUser += 1;
       return 1;
   }

  
}