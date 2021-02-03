// SPDX-License-Identifier: UNLICENSED
// StakeOrderERC20 by Stakedex.io 2021

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./EnumerableAddressSet.sol";
import "./StakeOrderFactory.sol";
import "./StakeOrderLib.sol";

contract LPStakeOrderERC20
  {
   StakeOrderFactory _Factory;
   
   IERC20 public _LPToken;            // liquidity token required
   IERC20 public _rewardToken;        // reward token provided by posteBy
   IERC20 public _entranceFeeToken;   // token used for entrance fee
   IERC20 public _premiumToken;       // token required to be hodling to enter staking
  
   address private _postedBy;       // who posted the order
   address private _devWallet;
  
   uint public _premiumAmount;      // min amount hodling premium token to stake
   uint public _entranceFee;        // amount charged for staking entrance fee
   uint public _stakeFee;           // fee in LP % taken from stakers  
   uint public _numBlocks;          // end block for staking
   uint public _lastBlockCalc;      // last time balances were modified
   uint public _rewardsLeft;        // remaining reward balance for informational purposes
   uint public _rewardsPerBlock;    // total rewards per block (this is divided amongst participants)
   uint public _totalStake;         // total amount of LP being staked between all stakers
   uint public _minStake;           // minimum amount of stake
   uint public _rewardAmount;       // amount of reward when posted
   uint public _numBlocksLeft;      // amount of unrewarded blocks
  
   bool private _initialized;
   bool public _isActive;
  
   mapping(address => uint) public _stakeBalance;   // stake balances of stakers
   mapping(address => uint) public _rewardBalance;  // reward balances of stakers
   mapping(address => uint) public _enteredBlock;   // block at which this address entered. used to make sure nobody entered while going thrugh_Stakers list
  
   using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
   EnumerableAddressSet.AddressSet _Stakers;

   function initialize(StakeOrderLib.OrderVars calldata vars) external
   {
     require(!_initialized);
     _initialized = true;

     require(vars.rewardToken != address(0) && vars.LPToken != address(0));
      
     _rewardToken = IERC20(vars.rewardToken);
     _LPToken = IERC20(vars.LPToken);
     _entranceFeeToken = IERC20(vars.entranceFeeToken);
     _premiumToken = IERC20(vars.premiumToken);
     _premiumAmount = vars.premiumAmount;

     _stakeFee = vars.stakeFee;
     _postedBy = vars.postedBy;
     _numBlocks = vars.numBlocks;
     _numBlocksLeft = vars.numBlocks;
     _entranceFee = vars.entranceFee;
     _Factory = StakeOrderFactory(msg.sender);
     _devWallet = vars.devWallet;
     _minStake = vars.minStake;
     
     if(_minStake < 10000)
       _minStake = 10000;
     
     _rewardAmount = vars.rewardAmount;
   }

   function startOrder() public
   {
     // only factory can start this order
     require(msg.sender == address(_Factory));
     
     uint256 allowance = _rewardToken.allowance(msg.sender, address(this));
     require(allowance >= _rewardAmount);
    
     // factory should have paid us the reward purse
     require(_rewardToken.transferFrom(msg.sender, address(this), _rewardAmount));
    
     _rewardsLeft = _rewardAmount;
     _rewardsPerBlock = _rewardAmount / _numBlocks;
    
     _lastBlockCalc = block.number;
     _isActive = true; // order is ready to start as soon as we get our first staker    
   }
  
   // update all balances when a balance has been modified
   // this makes the user staking/withdrawing pay for the updates gas
   function updateBalances() public returns(bool)
   {
     // this is important because it is dealing with users funds
     // users can enter staking while we are iterating _Stakers list
     // we have keep track of when they entered so everyone gets paid correctly
    
     require(_isActive);
     require(_numBlocksLeft > 0);
     
     uint len = _Stakers.length();
    
     if(len > 0) // dont have to do any of this is there are no stakers
       {
	 uint blockNum = block.number;
	 uint pendingRewards = getPendingRewards();
	 uint pendingBlocks = getPendingBlocks();
	 bool calcs = false;
	 
	 // calculate and modify all balances
	 for(uint i=0;i<len;i++)
	   {
	     address staker = _Stakers.at(i);
	     if(_enteredBlock[staker] < blockNum) // prevent counting of stakers who just entered while we are iterating the list
	       {
		 /*
		 uint scale = 100000;
		 uint split = (_stakeBalance[staker] * scale) / _totalStake * pendingRewards / scale;
		 _rewardBalance[staker] = _rewardBalance[staker] + split;
		 calcs = true;
		 */
		 uint scale = 100000;
		 uint scaledbalance = (_stakeBalance[staker] * scale);
		      
		 if(scaledbalance > _totalStake) // avoid division error
		   {
		     uint num = scaledbalance / _totalStake * pendingRewards;
      
		     if(num > scale) // avoid division error
		       {
			 _rewardBalance[staker] = _rewardBalance[staker] + (num/scale);
			 calcs = true;
		       }
		   }
	       }
	   }
       
	 if(calcs) // only do this if we actually added to any balances
	   {
	     _rewardsLeft = _rewardsLeft - pendingRewards;
	     _numBlocksLeft = _numBlocksLeft - pendingBlocks;
	   }
       }

     bool closed = false;
     if( _numBlocksLeft == 0)
       {
	 _Factory.closeOrder(address(this));
	 iclose();
	 closed = true;
       }
     
     _lastBlockCalc = block.number;
     return(closed);
   }

   // stake
   function stake(uint amount) public
   {
     require(_isActive);
     require(amount >= _minStake);
     
     // premium orders are required to be holding a minimum amount of premium token
     if(address(_premiumToken) != address(0) && _premiumAmount > 0)
       require(_premiumToken.balanceOf(msg.sender) >= _premiumAmount);

     if(updateBalances())
       return;
   
     // entry fee orders require an antry fee to be paid 
     if(address(_entranceFeeToken) != address(0) && _entranceFee > 0)
       {
	 require(_entranceFeeToken.allowance(msg.sender, address(this)) >= amount);
	 require(_entranceFeeToken.transferFrom(msg.sender, _devWallet, _entranceFee));
       }
   
     require(_LPToken.allowance(msg.sender, address(this)) >= amount);

     uint fee = amount * _stakeFee / 10000; // 10 is .01%
     
     uint stakeAmount = amount - fee;
   
     // send fee to dev wallet
     require(_LPToken.transferFrom(msg.sender, address(this), amount));
     require(_LPToken.transfer(_devWallet, fee) == true);

     // always update balances before we change anything

     _stakeBalance[msg.sender] = _stakeBalance[msg.sender] + stakeAmount; // add just in case they have already staked before
     _totalStake = _totalStake + stakeAmount;
     
     if(!_Stakers.contains(msg.sender)) // new staker
       {
	 _Stakers.add(msg.sender);
	 _enteredBlock[msg.sender] = block.number;
       }
   }

   // collect uncollected rewards
   function collectRewards() public 
   {
     // always update balances before we change anything
     if(updateBalances())
       return;
   
     require(_rewardBalance[msg.sender] > 0);   
   
     require(_rewardToken.transfer(msg.sender, _rewardBalance[msg.sender]));
     _rewardBalance[msg.sender] = 0;
   }

   // withdraw all stakes and stop staking
   function withdraw() public
   {
     // always update balances before we change anything
     if(updateBalances())
       return;
   
     require(_stakeBalance[msg.sender] > 0);
   
     require(_LPToken.transfer(msg.sender, _stakeBalance[msg.sender]));
     require(_rewardToken.transfer(msg.sender, _rewardBalance[msg.sender]));
     _totalStake = _totalStake - _stakeBalance[msg.sender];
     _stakeBalance[msg.sender] = 0;
     _rewardBalance[msg.sender] = 0;
      
     _Stakers.remove(msg.sender);
   }
   
   function getMyRewardBalance() public view returns(uint)
   {
     return(getRewardBalance(msg.sender));
   }

   
   function isStaker(address addr) public view returns(bool)
   {
     return(_Stakers.contains(addr));
   }
   
   
   function getPendingRewards() public view returns (uint)
   {
     if(_Stakers.length() == 0) // all balances should already be correct
       return(0); 
     return(_rewardsPerBlock * getPendingBlocks());
   }

   function getRewardsLeft() public view returns(uint)
   {
     if(_Stakers.length() == 0)
       return(_rewardsLeft);
     
     return(_rewardsLeft - getPendingRewards());
   }

   function getPendingBlocks() public view returns(uint)
   {
     if(_Stakers.length() == 0 )
       return(0);
     if((block.number - _lastBlockCalc) >= _numBlocksLeft) // contract is done
       return _numBlocksLeft; // prevent neg number
     
     else return(block.number - _lastBlockCalc);
   }

   function getBlocksLeft() public view returns(uint)
   {
     return(_numBlocksLeft - getPendingBlocks());
   }

   // predict their current balance for informational purposes only
   function getRewardBalance(address addr) public view returns(uint)
   {
     // balances have not been updated so we must predict amount in balance
     uint bal = _rewardBalance[addr];
   
     if(_numBlocksLeft == 0 || !_Stakers.contains(addr)) 
       return(bal);
   
     uint pending = getPendingRewards();
     
     uint scale = 100000;
     uint scaledbalance = (_stakeBalance[addr] * scale);
     
     if(scaledbalance < _totalStake) // avoid division error
       return(bal);
     
      uint num = scaledbalance / _totalStake * pending;
      
      if(num < scale) // avoid division error
	return(bal);
      
     return( num / scale); 
   }
      
   function close() public
   {
     require(msg.sender == address(_Factory));
     updateBalances();
     iclose();
   }
 
   // close order
   function iclose() internal
   {
     _isActive = false;
     // return all LP tokens and rewards to stakera
     for(uint i=0;i<_Stakers.length();i++)
       {
	 if(_stakeBalance[_Stakers.at(i)] > 0)
	   _LPToken.transfer(_Stakers.at(i), _stakeBalance[_Stakers.at(i)]);
	 if(_rewardBalance[_Stakers.at(i)] > 0)
	   _rewardToken.transfer(_Stakers.at(i), _rewardBalance[_Stakers.at(i)]);
       }

     uint rewardAmount = _rewardToken.balanceOf(address(this));
   
     // send all unused reward tokens back to poster
     if(rewardAmount > 0)
       _rewardToken.transfer(_postedBy, rewardAmount);

     // if for some reason any lptoken left give it to devwallet
     uint amount = _LPToken.balanceOf(address(this));     
     if(amount > 0)
       _LPToken.transfer(_devWallet, amount);
   }

   function getContractBalances() public view returns(uint, uint)
   {
     return(_rewardToken.balanceOf(address(this)), _LPToken.balanceOf(address(this)));
   }
   
   function getStakers() public view returns(StakeOrderLib.stakeOut[] memory)
   {
     uint len = _Stakers.length();
     StakeOrderLib.stakeOut[] memory out = new StakeOrderLib.stakeOut[](len);
    
     for(uint i=0;i<len;i++)
       {
	 out[i].staker = _Stakers.at(i);
	 out[i].stake =  _stakeBalance[_Stakers.at(i)];
       }
     return out;
   }

   function getInfo() public view returns(StakeOrderLib.stakeInfo memory)
   {
     StakeOrderLib.stakeInfo memory out;
     out.LPToken = address(_LPToken);          
     out.rewardToken = address(_rewardToken);
     out.entranceFeeToken = address(_entranceFeeToken);
     out.premiumToken =  address(_premiumToken);
     out.postedBy =  address(_postedBy);
  
     out.premiumAmount =  _premiumAmount;    // min amount hodling premium token to stake
     out.entranceFee = _entranceFee;         // amount charged for staking entrance fee
     out.stakeFee =  _stakeFee;              // fee in LP % taken from stakers  
     out.numBlocks = _numBlocks;             // end block for staking
     out.rewardsPerBlock = _rewardsPerBlock; // total rewards per block (this is divided amongst participants)
     out.minStake = _minStake;               // minimum amount of stake
     out.rewardAmount = _rewardAmount;       // amount of reward when posted
     out.isActive = _isActive;
     return out;
   }
   
   function getUpdate() public view returns(StakeOrderLib.updateInfo memory)
   {
     StakeOrderLib.updateInfo memory out;
     out.rewardsLeft =  getRewardsLeft();        // remaining reward balance for informational purposes
     out.numBlocksLeft = getBlocksLeft();        // amount of blocks left in contract
     out.myStake = _stakeBalance[msg.sender];
     out.myUnclaimed = getRewardBalance(msg.sender);
     out.totalStake = _totalStake;               // total amount of LP being staked between all stakers
     return(out);
   }
  }