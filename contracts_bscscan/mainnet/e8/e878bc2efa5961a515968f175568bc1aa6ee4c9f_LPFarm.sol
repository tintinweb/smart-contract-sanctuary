/**
 *Submitted for verification at BscScan.com on 2021-08-17
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

contract LPFarm {
    using SafeMath for uint256;

    modifier hasDripped {
        if (dividendPool > 0) {
          uint256 secondsPassed = SafeMath.sub(block.timestamp, lastDripTime);
          uint256 dividends = secondsPassed.mul(dividendPool).div(dailyRate);

          if (dividends > dividendPool) {
            dividends = dividendPool;
          }

          profitPerShare = SafeMath.add(profitPerShare, (dividends * magnitude) / tokenSupply);
          dividendPool = dividendPool.sub(dividends);
          lastDripTime = block.timestamp;
        }
        _;
    }

    modifier onlyTokenHolders {
        require(myShares() > 0);
        _;
    }

    modifier onlyDivis {
        require(myRewards() > 0);
        _;
    }

    event onDonation(
        address indexed userAddress,
        uint256 tokens
    );

    event onStake(
        address indexed userAddress,
        uint256 incomingTokens,
        uint256 timestamp
    );

    event onUnstake(
        address indexed customerAddress,
        uint256 tokenRemoved,
        uint256 timestamp
    );

    event onReinvest(
        address indexed customerAddress,
        uint256 tokensReinvested
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 tokensWithdrawn
    );


    uint256 constant private magnitude = 2 ** 64;
    uint32 constant private dailyRate = 11520000; //0.75% a day
    uint8 constant private buyInFee = 75;
    uint8 constant private sellOutFee = 75;
    uint8 constant private vaultFee = 25;

    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => int256) private payoutsTo;

    uint256 public dividendPool = 0;
    uint256 public lastDripTime = block.timestamp;
    uint256 public totalDonation = 0;
    uint256 public totalVaultFundReceived = 0;
    uint256 public totalVaultFundCollected = 0;

    uint256 private tokenSupply = 0;
    uint256 private profitPerShare = 0;

    address public vaultAddress;
    TOKEN bep20;

    constructor() {
        vaultAddress = address(0x6bEee53eFa847ec426707693c83836E359E92609); //vault address
        bep20 = TOKEN(address(0x6F547381e6594C177A4C56Bc818b599cc78A8c16)); //pair token
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    function checkAndTransfer(uint256 _amount) private {
        require(bep20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function donateToPool(uint256 _amount) public {
        require(_amount > 0 && tokenSupply > 0, "must be a positive value and have supply");
        checkAndTransfer(_amount);
        totalDonation += _amount;
        dividendPool = dividendPool.add(_amount);
        emit onDonation(msg.sender, _amount);
    }

    function payVault() public {
        uint256 _tokensToPay = tokensToPay();
        require(_tokensToPay > 0);
        bep20.transfer(vaultAddress, _tokensToPay);
        totalVaultFundReceived = totalVaultFundReceived.add(_tokensToPay);
    }

    function reinvest() hasDripped onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myRewards();
        payoutsTo[_customerAddress] +=  (int256) (_dividends.mul(magnitude));
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends);
        emit onReinvest(_customerAddress, _tokens);
    }

    function withdraw() hasDripped onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myRewards();
        payoutsTo[_customerAddress] += (int256) (_dividends.mul(magnitude));
        bep20.transfer(_customerAddress, _dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }

    function deposit(uint256 _amount) hasDripped public returns (uint256) {
        checkAndTransfer(_amount);
        return purchaseTokens(msg.sender, _amount);
    }

    function _purchaseTokens(address _customerAddress, uint256 _incomingTokens) private returns(uint256) {
        uint256 _amountOfTokens = _incomingTokens;

        require(_amountOfTokens > 0 && _amountOfTokens.add(tokenSupply) > tokenSupply);

        tokenSupply = tokenSupply.add(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] =  tokenBalanceLedger[_customerAddress].add(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare.mul(_amountOfTokens));
        payoutsTo[_customerAddress] += _updatedPayouts;

        return _amountOfTokens;
    }

    function purchaseTokens(address _customerAddress, uint256 _incomingTokens) private returns (uint256) {
        require(_incomingTokens > 0);

        uint256 _dividendFee = _incomingTokens.mul(buyInFee).div(1000);

        uint256 _vaultFee = _incomingTokens.mul(vaultFee).div(1000);

        uint256 _entryFee = _incomingTokens.mul(100).div(1000);
        uint256 _taxedTokens = _incomingTokens.sub(_entryFee);

        uint256 _amountOfTokens = _purchaseTokens(_customerAddress, _taxedTokens);

        dividendPool = dividendPool.add(_dividendFee);
        totalVaultFundCollected = totalVaultFundCollected.add(_vaultFee);

        emit onStake(_customerAddress, _amountOfTokens, block.timestamp);

        return _amountOfTokens;
    }

    function remove(uint256 _amountOfTokens) hasDripped onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens > 0 && _amountOfTokens <= tokenBalanceLedger[_customerAddress]);

        uint256 _dividendFee = _amountOfTokens.mul(sellOutFee).div(1000);
        uint256 _vaultFee = _amountOfTokens.mul(vaultFee).div(1000);
        uint256 _taxedTokens = _amountOfTokens.sub(_dividendFee).sub(_vaultFee);

        tokenSupply = tokenSupply.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);

        int256 _updatedPayouts = (int256) ((profitPerShare.mul(_amountOfTokens)).add(_taxedTokens.mul(magnitude)));
        payoutsTo[_customerAddress] -= _updatedPayouts;

        dividendPool = dividendPool.add(_dividendFee);
        totalVaultFundCollected = totalVaultFundCollected.add(_vaultFee);
          
        emit onUnstake(_customerAddress, _taxedTokens, block.timestamp);
    }

    function totalTokenBalance() public view returns (uint256) {
        return bep20.balanceOf(address(this));
    }

    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }

    function myShares() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return sharesOf(_customerAddress);
    }

    function myEstimateRewards() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return estimateRewardsOf(_customerAddress);
    }

    function estimateRewardsOf(address _customerAddress) public view returns (uint256) {
        uint256 _profitPerShare = profitPerShare;

        if (dividendPool > 0) {
          uint256 secondsPassed = 0;
       
          secondsPassed = SafeMath.sub(block.timestamp, lastDripTime);

          uint256 dividends = secondsPassed.mul(dividendPool).div(dailyRate);

          if (dividends > dividendPool) {
            dividends = dividendPool;
          }

          _profitPerShare = SafeMath.add(_profitPerShare, (dividends * magnitude) / tokenSupply);
        }

        return (uint256) ((int256) (_profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / magnitude;
    }

    function myRewards() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return rewardsOf(_customerAddress) ;
    }

    function rewardsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / magnitude;
    }

    function sharesOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger[_customerAddress];
    }

    function tokensToPay() public view returns(uint256) {
        return totalVaultFundCollected.sub(totalVaultFundReceived);
    }
}