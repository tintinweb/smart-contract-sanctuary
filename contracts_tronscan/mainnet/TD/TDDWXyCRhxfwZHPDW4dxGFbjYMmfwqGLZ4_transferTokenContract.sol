//SourceUnit: mlm.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

contract Context {
  constructor() internal {}
  // solhint-disable-previous-line no-empty-blocks
  function _msgSender() internal view returns(address payable) {
    return msg.sender;
  }
}

library SafeMath {
  function add(uint a, uint b) internal pure returns(uint) {
    uint c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint a, uint b) internal pure returns(uint) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    require(b <= a, errorMessage);
    uint c = a - b;

    return c;
  }

  function mul(uint a, uint b) internal pure returns(uint) {
    if (a == 0) {
        return 0;
    }

    uint c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint a, uint b) internal pure returns(uint) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint c = a / b;

    return c;
  }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    // /**
    //  * @dev Transfers ownership of the contract to a new account (`newOwner`).
    //  * Can only be called by the current owner.
    //  */
    // function transferOwnership(address newOwner) public virtual onlyOwner {
    //     require(newOwner != address(0), "Ownable: new owner is the zero address");
    //     emit OwnershipTransferred(_owner, newOwner);
    //     _owner = newOwner;
    // }
}

contract transferTokenContract is Ownable {
    using SafeMath for uint256;

    struct Investment {
        uint256[] amount;
        uint256[] purchaseTime;
        uint256[] referralId;
    }
    // mapping(uint256 => uint256) private _prices;
    uint256[9] _prices = [1000,2000,4000,8000,16000,32000,64000,128000,256000];
    
    
    mapping(address => Investment) private _investments;
    mapping(address => uint256) private _amountWithrawed;
    mapping(address => address) private _parents;
    mapping(address => uint256) private _referralId;
    mapping(uint256 => address) private _userAddress;
    mapping(address => uint256[10]) private _levelReawrd;
    mapping(address => bool) private _isDirected;
    
    // mapping(uint256 => address) private _autoPool;
    address[] _autoPool;
    
    mapping(address => uint256) private _autoPoolReward;
    
    // mapping(uint256 => uint256) private _levelReawrdPercentage;
    uint256[10] _levelReawrdPercentage = [20,15,15,10,10,10,5,5,5,5];
    uint256 private _tokenSold = 0;
    // uint256 private _currentPhase;
    uint256 private _phaseLength = 20 days;
    uint256 private _maxPhase = 8; // starting from 0
    uint256 private _startTime;
    uint256 private _investorsCount = 0;
    // uint256 private _autoPoolCount = 0;
    trcToken private tokenId;
    
    
    constructor(trcToken _tokenId) public {
        tokenId = _tokenId;
        _startTime = block.timestamp;
        _parents[msg.sender] == address(0);
        
    }
    function getStartTime() public view returns (uint256) {
        return _startTime;
    }
    function getCurrentPhase() public view returns (uint256) {
        uint256 currentPhase = (block.timestamp.sub(_startTime)).div(_phaseLength).add(1);
        if(_tokenSold >= currentPhase.mul(1000000000)) {
            return _tokenSold.div(1000000000);
         }
         return currentPhase;
    }
    
    function getCurrentPrice() public view returns(uint256){
        uint256 currentPhase = getCurrentPhase().sub(1);
        if(currentPhase > _maxPhase) {
            return uint256(-1);
        }
        return _prices[currentPhase];
    }
    
    // function setLevelRewardPercentage(uint256[] memory percentages) external onlyOwner {
    //     for(uint256 i=0; i< percentages.length; i++) {
    //         _levelReawrdPercentage[i] = percentages[i];
    //     }
    // }
    function getLevelRewardPercentage() external view returns (uint256[10] memory) {
        return _levelReawrdPercentage;
    }
    
    function getLevelReward(address account) external view returns (uint256[10] memory) {
        return _levelReawrd[account];
    }
    
    function getAutoPoolReward(address account) external view returns (uint256) {
        return _autoPoolReward[account];
    }
    
    function getParent(address account) external view returns (address) {
        _parents[account];
    }
    
    
    function getTokenSold() external view returns(uint256){
        return _tokenSold;
    }
    
    function getReferralIdByAddress(address account) external view returns (uint256) {
        return _referralId[account];
    }
    
    function getAddressByReferralId(uint256 referralId) external view returns (address) {
        return _userAddress[referralId];
    }
    
    function getInvestmentCount(address account) external view returns (uint256) {
        return _investments[account].amount.length;
    }
    
    function getPhaseTimeLeft() external view returns (uint256) {
        uint256 currentPhase = getCurrentPhase();
        return (currentPhase.mul(_phaseLength)).add(_startTime).sub(block.timestamp);
    }
    
    function getAllInvestmentAmount(address account) external view returns(uint256[] memory) {
        return _investments[account].amount;
    }
    
    function getAllInvestmentPurchaseTime(address account) external view returns(uint256[] memory) {
        return _investments[account].purchaseTime;
    }
    
    function getAllInvestmentReferralId(address account) external view returns(uint256[] memory) {
        return _investments[account].referralId;
    }
      
    function inAutoPool(address account) external view returns (bool) {
        return _isDirected[account];
    } 
    
    function getInvestorsCount() external view returns (uint256) {
        return _investorsCount;
    }
    
    function getAutoPoolList() external view returns (address[] memory){
        return _autoPool;
    }
    
    function getAutoPoolCount() external view returns (uint256) {
        return _autoPool.length;
    }
    
    // no needs to give extra 6 zeroes in amount
    function buyToken(uint256 amount, uint256 referralId) external payable {
        require(_msgSender()!= owner(), "Owner can't invest");
        require(referralId <= _investorsCount, "Invalid Id");
        uint256 currentPrice = getCurrentPrice();
        require(currentPrice != uint256(-1), "All the phases are completed");
        require(amount % 10000 ==0, "token amount is not multiple of 10000");
        require(msg.value >= amount.mul(currentPrice),"insufficient Tron paid");
        
        require(_tokenSold.add(amount) <= getCurrentPhase().mul(1000000000), "buying more tokens than phase limit");
        _tokenSold = _tokenSold.add(amount);
        // uint256 value = amount.mul(75).div(100);
        
        
        _investments[_msgSender()].amount.push(amount);
        _investments[_msgSender()].purchaseTime.push(block.timestamp);
        _investments[_msgSender()].referralId.push(referralId);
        
        uint256 value = amount.mul(125).div(1000);
        address parent;
        address poolRewardUser;
        if(referralId == 0) {
            parent = owner();
            
        } else {
            parent = _userAddress[referralId];
            if(!_isDirected[parent]) {
                // _autoPoolCount = _autoPoolCount.add(1);
                // _autoPool[_autoPoolCount] = parent;
                _autoPool.push(parent);
                _isDirected[parent] = true;
                uint256 autoPoolLength = _autoPool.length;
                
                if(autoPoolLength > 10) {
                    poolRewardUser = _autoPool[autoPoolLength.sub(11)];
                    _autoPoolReward[poolRewardUser] = _investments[poolRewardUser].amount[0].mul(250000); // mul by 1e6 and div by 100
                }
            }
        }
        
        if(_referralId[_msgSender()] == 0) {
            
            _investorsCount = _investorsCount.add(1);

            _referralId[_msgSender()] = _investorsCount;
            _userAddress[_investorsCount] = _msgSender();
            _parents[_msgSender()] = parent;

        }

        
        
        for(uint256 i=0; i<10; i++){
            _levelReawrd[parent][i] = _levelReawrd[parent][i].add(value.mul(_levelReawrdPercentage[i]).mul(10000)); //mul by 10^6 and div by 10^2
            
            parent = _parents[parent];
            if(parent == address(0)){
                break;
            }
            
        }
        
        
    }
    
    function getTotalInvestment(address account) external view returns (uint256) {
        uint256 amount;
        uint256 count = _investments[account].amount.length;
        
        for(uint256 i=0; i<count ;i= i+1){
            amount = amount.add(_investments[account].amount[i]);
        }
        
        return amount;
        
    }
    
    function getWithdrawlAmount(address account) public view returns (uint256) {
        uint256 withdrawlAmount = 0; 
        uint256 purchaseTime;
        uint256 amount;
        uint256 i;
        for(  i=0; i<_investments[account].amount.length; i= i+1) {
            purchaseTime = _investments[account].purchaseTime[i];
            amount = _investments[account].amount[i];
            
            if(block.timestamp.sub(purchaseTime) <= 300 days) {
                withdrawlAmount = withdrawlAmount.add(amount.mul(block.timestamp - purchaseTime).mul(25).div(864));
            }
        }
        
        for(i=0;i<10; i=i+1) {
            withdrawlAmount = withdrawlAmount.add(_levelReawrd[account][i]);
        }
        
        withdrawlAmount = withdrawlAmount.add(_autoPoolReward[account]);
        
        return withdrawlAmount.sub(_amountWithrawed[account]);
    }
    
    function getWithdrawedAmount(address account) external view returns (uint256){
        return _amountWithrawed[account];
    }
    
    function withdraw() external {
        uint256 withdrawlAmount = getWithdrawlAmount(_msgSender());
        _amountWithrawed[_msgSender()] = _amountWithrawed[_msgSender()].add(withdrawlAmount);
        _msgSender().transferToken(withdrawlAmount, tokenId);
    }
    
    // function getContractBalance() external view onlyOwner returns(uint256){
    //     return address(this).tokenBalance(tokenId);
    // }
    
    // no needs to give extra 6 zeroes in amount
    // function withdrawLevelReward(uint256 amount) external {
    //     require(amount <= _levelReawrd[_msgSender()], "amount is larger than Level reward");
    //     require(address(this).tokenBalance(tokenId) >= amount,"not enough balance in contract");
    //     _msgSender().transferToken(amount, tokenId);
    // }
    
    // function withdrawCashBack() external {
    //     uint256 withdrawlAmount = getWithdrawlAmount(_msgSender());
    //         _amountWithrawed[_msgSender()] = _amountWithrawed[_msgSender()].add(withdrawlAmount);
    //     _msgSender().transferToken(withdrawlAmount, tokenId);
        
    // }
    
    function withdrawTron(uint256 amount, address receiver) external onlyOwner {
        payable(receiver).transfer(amount);
    }
    
    
    function withdrawToken(uint256 amount) external onlyOwner {
        // TODO: onwer can't withdraw sold tokens
        // require()
        _msgSender().transferToken(amount,tokenId);
    }

    
    
}