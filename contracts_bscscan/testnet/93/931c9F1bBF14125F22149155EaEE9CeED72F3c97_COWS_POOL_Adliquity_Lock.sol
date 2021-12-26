// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {SafeMath} from './SafeMath.sol';

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 **/

contract COWS_POOL_Adliquity_Lock {
  using SafeMath for uint256;
  // Todo : Update when deploy to production

  address public tokenLock;
  address public releaseToAddress;
  address public admin1;
  address public admin2;
  address public admin3;
  address public burnAddress;
  address public owner;

  uint256 public vote1 = 0;
  uint256 public vote2 = 0;
  uint256 public vote3 = 0;

  uint256 public totalClaimed=0;

  event ClaimAt(address indexed userAddress, uint256 indexed claimAmount);
  event AdminVote(address indexed adminAddress, uint256 indexed vote);
  event AdminUnvote(address indexed adminAddress, uint256 indexed vote);


  modifier onlyAmin() {
    require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3 , 'INVALID ADMIN');
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner  , 'INVALID OWNER');
    _;
  }

  

  

  constructor(address _tokenLock, address _releaseToAddress) public {    
    owner = tx.origin;  
    tokenLock = _tokenLock;
    // Mainnet
    releaseToAddress = _releaseToAddress;
    admin1 = 0xD4E24aE698Ea603b7026E9c769C2B34B6D77F618;
    admin2 = 0xFAd2Cb97725947954d7e6e55A0EFAB9E0afB0846;
    admin3 = 0x0B707c987b013B64082f1d6A07988d640Dc854E0;
  }

    
    /**
     * @dev vote releaseToAddress of the contract to a new releaseToAddress .
     * Can only be called by the current admin .
     */
    function vote(uint256 amount) public onlyAmin {
        if(msg.sender==admin1)
        {
            vote1 = amount;
            emit AdminVote(msg.sender,vote1);
            
        }
        if(msg.sender==admin2)
        {
            vote2 = amount;
            emit AdminVote(msg.sender,vote2);
            
        }
        if(msg.sender==admin3)
        {
            vote3 = amount;
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
            vote1 = 0;
            emit AdminUnvote(msg.sender,vote1);
            
        }
        if(msg.sender==admin2)
        {
            vote2 = 0;
            emit AdminUnvote(msg.sender,vote2);
            
        }
        if(msg.sender==admin3)
        {
            vote3 = 0;
            emit AdminUnvote(msg.sender,vote3);
        }     
    }
  
    
  
  function clearToken( address token) public onlyOwner   {
    require(token != tokenLock, "Only clear token unlock");      
    IERC20(token).transfer(releaseToAddress, IERC20(token).balanceOf(address(this)));
  }
  
   
  function clearBNB() public onlyOwner   {
    _safeTransferBNB(releaseToAddress, address(this).balance);
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
   * @dev owner claim 
   */
   
   function WithdrawCOWSToLiquity(uint256 amount) public onlyOwner returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        require(( vote1 == vote2 && vote1 > 0 ) || ( vote1 == vote3 && vote1 > 0 ) 
        || ( vote2 == vote3 && vote2 > 0 ),"Require 2 vote amount from admin");
        require(( vote1 == amount && vote1 > 0 ) || ( vote1 == amount && vote1 > 0 ) 
        || ( vote2 == amount && vote2 > 0 ),"Require amount equal vote amount");
        uint256 balanceToken = IERC20(tokenLock).balanceOf(address(this));
        amount = amount * 10**18;
        require(balanceToken >= amount, "Sorry: no tokens to release");   
        require(amount >= 1, "Sorry: minium 1 token");
        IERC20(tokenLock).transfer(releaseToAddress,amount);
        emit ClaimAt(releaseToAddress,amount);
        totalClaimed += amount / 10**18;
        vote1 = 0;
        vote2 = 0;
        vote3 = 0;
        return amount;
   }
  
}