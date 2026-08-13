/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-04-07
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
      if (a == 0) {
        return 0;
      }
      c = a * b;
      assert(c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface TOKEN {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PartnerFarm is Ownable {
    using SafeMath for uint256;

   modifier hasDripped {
        if (farmPool > 0 && sharesSupply > 0) {
          uint256 secondsPassed = SafeMath.sub(block.timestamp, lastDripTime);
          uint256 rewards = secondsPassed.mul(farmPool).div(dailyRate);

          if (rewards > farmPool) {
            rewards = farmPool;
          }

          profitPerShare = SafeMath.add(profitPerShare, (rewards * magnitude) / sharesSupply);
          farmPool = farmPool.sub(rewards);
          lastDripTime = block.timestamp;
        }
        _;
    }
    
    modifier onlyFarmers {
        require(myShares() > 0);
        _;
    }

    modifier hasRewards {
        require(myRewards() > 0);
        _;
    }
    
    event onDonation(
        address indexed userAddress,
        uint256 tokens
    );
    
    event onNewStake(
        address indexed farmerAddress,
        uint256 stakedTokens,
        uint256 timestamp
    );

    event onRemoveStake(
        address indexed farmerAddress,
        uint256 tokensRemoved,
        uint256 timestamp
    );

    event onHarvest(
        address indexed farmerAddress,
        uint256 tokensWithdrawn
    );

    event feeReceiverChanged(
        address indexed previousFeeReceiver,
        address indexed newFeeReceiver
    );
    
    uint256 constant private magnitude = 2 ** 64;
    uint32 constant private dailyRate = 11520000; //0.75% a day
    uint8 constant private vaultFee = 1;

    mapping(address => uint256) private sharesBalanceLedger;
    mapping(address => int256) private payoutsTo;
    
    mapping(address => uint256) public farmedTokens;

    uint256 public farmPool = 0;
    uint256 public lastDripTime = block.timestamp;
    
    uint256 public totalVaultFundReceived = 0;
    uint256 public totalVaultFundCollected = 0;

    uint256 private sharesSupply = 0;
    uint256 private profitPerShare = 0;

    address public feeReceiver;

    TOKEN rewardsToken;
    TOKEN acceptedToken;

    constructor(address _feeReceiver, address _rewardsToken, address _acceptedToken) {
        rewardsToken = TOKEN(_rewardsToken);
        acceptedToken = TOKEN(_acceptedToken);
        feeReceiver = _feeReceiver;
    }


    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    function checkAndTransfer(uint256 _amount, TOKEN _token) private {
        require(_token.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }
    
    function donateToPool(uint256 _amount) public {
        require(_amount > 0 && sharesSupply > 0, "must be a positive value and have supply");
        checkAndTransfer(_amount, rewardsToken);
        farmPool = farmPool.add(_amount);
        emit onDonation(msg.sender, _amount);
    }

    function payVault() public {
        uint256 _tokensToPay = tokensToPay();
        require(_tokensToPay > 0);
        acceptedToken.transfer(feeReceiver, _tokensToPay);
        totalVaultFundReceived = totalVaultFundReceived.add(_tokensToPay);
    }

    function harvest() hasDripped hasRewards public {
        address _farmerAddress = msg.sender;
        uint256 _rewards = myRewards();
        payoutsTo[_farmerAddress] += (int256) (_rewards.mul(magnitude));
        rewardsToken.transfer(_farmerAddress, _rewards);
        farmedTokens[_farmerAddress] += _rewards;
        emit onHarvest(_farmerAddress, _rewards);
    }

    function deposit(uint256 _amount) hasDripped public returns (uint256) {
        checkAndTransfer(_amount, acceptedToken);
        return addShares(msg.sender, _amount);
    }

    function _addShares(address _customerAddress, uint256 _incomingTokens) private returns(uint256) {
        uint256 _amountOfTokens = _incomingTokens;

        require(_amountOfTokens > 0 && _amountOfTokens.add(sharesSupply) > sharesSupply);

        sharesSupply = sharesSupply.add(_amountOfTokens);
        sharesBalanceLedger[_customerAddress] = sharesBalanceLedger[_customerAddress].add(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare.mul(_amountOfTokens));
        payoutsTo[_customerAddress] += _updatedPayouts;

        return _amountOfTokens;
    }
    
    function addShares(address _farmerAddress, uint256 _incomingTokens) private returns (uint256) {
        require(_incomingTokens > 0);

        uint256 _vaultFee = _incomingTokens.mul(vaultFee).div(100);

        uint256 _taxedTokens = _incomingTokens.sub(_vaultFee);

        uint256 _amountOfTokens = _addShares(_farmerAddress, _taxedTokens);

        totalVaultFundCollected = totalVaultFundCollected.add(_vaultFee);

        emit onNewStake(_farmerAddress, _amountOfTokens, block.timestamp);

        return _amountOfTokens;
    }
    
     function remove(uint256 _amountOfShares) hasDripped onlyFarmers public {
        address _farmerAddress = msg.sender;
        require(_amountOfShares > 0 && _amountOfShares <= sharesBalanceLedger[_farmerAddress]);
        
        uint256 _vaultFee = _amountOfShares.mul(vaultFee).div(100);
        
        uint256 _taxedTokens = _amountOfShares.sub(_vaultFee);

        sharesSupply = sharesSupply.sub(_amountOfShares);
        sharesBalanceLedger[_farmerAddress] = sharesBalanceLedger[_farmerAddress].sub(_amountOfShares);

        int256 _updatedPayouts = (int256) (profitPerShare.mul(_amountOfShares));
        payoutsTo[_farmerAddress] -= _updatedPayouts;
        
        totalVaultFundCollected = totalVaultFundCollected.add(_vaultFee);
        
        acceptedToken.transfer(_farmerAddress, _taxedTokens);
        
        emit onRemoveStake(_farmerAddress, _taxedTokens, block.timestamp);
    }
    
    function totalTokenBalance() public view returns (uint256) {
        return acceptedToken.balanceOf(address(this));
    }

    function totalSupply() public view returns(uint256) {
        return sharesSupply;
    }

    function myShares() public view returns (uint256) {
        address _farmerAddress = msg.sender;
        return sharesOf(_farmerAddress);
    }

    function myEstimateRewards() public view returns (uint256) {
        address _farmerAddress = msg.sender;
        return estimateRewardsOf(_farmerAddress) ;
    }

    function estimateRewardsOf(address _farmerAddress) public view returns (uint256) {
        uint256 _profitPerShare = profitPerShare;

        if (farmPool > 0) {
          uint256 secondsPassed = SafeMath.sub(block.timestamp, lastDripTime);
          
          uint256 dividends = secondsPassed.mul(farmPool).div(dailyRate);

          if (dividends > farmPool) {
            dividends = farmPool;
          }

          _profitPerShare = SafeMath.add(_profitPerShare, (dividends * magnitude) / sharesSupply);
        }

        return (uint256) ((int256) (_profitPerShare * sharesBalanceLedger[_farmerAddress]) - payoutsTo[_farmerAddress]) / magnitude;
    }

    function myRewards() public view returns (uint256) {
        address _farmerAddress = msg.sender;
        return rewardsOf(_farmerAddress) ;
    }

    function rewardsOf(address _farmerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare * sharesBalanceLedger[_farmerAddress]) - payoutsTo[_farmerAddress]) / magnitude;
    }

    function sharesOf(address _farmerAddress) public view returns (uint256) {
        return sharesBalanceLedger[_farmerAddress];
    }
    
    function tokensToPay() public view returns(uint256) {
        return totalVaultFundCollected.sub(totalVaultFundReceived);
    }
    
    function changeFeeReceiver(address _newFeeReceiver) onlyOwner public {
        address _oldFeeReceiver = _newFeeReceiver;
        feeReceiver = _newFeeReceiver;
        emit feeReceiverChanged(_oldFeeReceiver, _newFeeReceiver);
    }
}