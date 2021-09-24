/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

pragma solidity ^0.8.0;

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

interface TOKEN {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface MINTER {
    function mint() external returns (uint256);
}

contract PadFarmsV2 {
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
        uint256 RewardsWithdrawn
    );
    
    event onDonation(
        address indexed farmerAddress,
        uint256 amount
    );


    uint256 constant private magnitude = 2 ** 64;
    uint32 constant private dailyRate = 8640000; //1% a day
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

    address public vaultAddress;
    
    uint256 public totalDonation = 0;
    
    uint256 public deflationaryTax = 5;
    
    TOKEN rewardToken;
    TOKEN acceptedToken;

    constructor(address _vaultAddress, address _rewardToken, address _acceptedToken) {
        rewardToken = TOKEN(_rewardToken);
        acceptedToken = TOKEN(_acceptedToken);
        vaultAddress = _vaultAddress;
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
        checkAndTransfer(_amount, rewardToken);
        uint256 _deflationTax = _amount.mul(deflationaryTax).div(100);
        uint256 _taxedTokens = _amount.sub(_deflationTax);
        totalDonation += _amount;
        farmPool = farmPool.add(_taxedTokens);
        emit onDonation(msg.sender, _amount);
    }
    
    function payVault() public {
        uint256 _tokensToPay = tokensToPay();
        require(_tokensToPay > 0);
        acceptedToken.transfer(vaultAddress, _tokensToPay);
        totalVaultFundReceived = totalVaultFundReceived.add(_tokensToPay);
    }

    function harvest() hasDripped hasRewards public {
        address _farmerAddress = msg.sender;
        uint256 _rewards = myRewards();
        payoutsTo[_farmerAddress] += (int256) (_rewards.mul(magnitude));
        rewardToken.transfer(_farmerAddress, _rewards);
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
}