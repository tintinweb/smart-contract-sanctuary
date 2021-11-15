// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITokenPresenter.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";
import "./utils/Maintainable.sol";

contract OROSPresenter is ITokenPresenter, Maintainable {

  struct Info {
    address addr;
    uint percentage;
    bool isEnabled;
    uint8 side; // 0 for buy, 1 for sell, 2 for both
    bool isRegistered;
  }

  uint internal constant RATE_NOMINATOR = 10000; // rate nominator

  address public token;
  address public router;
  
  mapping(address => uint) public rewardPool;
  mapping(address => mapping(address => uint)) userDebt;

  mapping(address => bool) public isExcludedFromFees;
  mapping(address => bool) public isExcludedTotalStaked;
  mapping(address => bool) public isExcludedTotalStakedRegistered; 

  mapping(address => Info) public tokenInfo;
  mapping(address => Info) public teamInfo;

  Info public lpInfo;
  uint public lpAmount;
  uint public burnAmount;
  // uint public totalStaked;

  mapping(address => uint) public teamAmount;
  uint public totalBuyBackAmount;

  address[] public tokens;
  address[] public team;
  address[] public totalStakedExcludedAccounts;

  bool public regularTransfersHasFee;
  uint public burnPercentage;
  bool public compound;
  bool private swapping;
  bool private claiming;

  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
  event ExcludeFromFees(address indexed account, bool isExcluded);
  event ExcludeTotalStaked(address indexed account, bool isExcluded);
  event Received(address sender, uint amount);
  
  address public zeroAddress = 0x0000000000000000000000000000000000000001;
  /**
  * @dev allow contract to receive ethers
  */
  receive() external payable {
      emit Received(msg.sender, msg.value);
  }

  constructor() {
    token = address(0);
  }

  /** 
  * @dev calculate total value staked
  */
  function totalStaked() public view returns (uint) {
    IERC20 mainToken = IERC20(token);
    uint totalSupply = mainToken.totalSupply();
    uint totalExcluded;
    for(uint i = 0; i < totalStakedExcludedAccounts.length; i++){
      if(isExcludedTotalStaked[totalStakedExcludedAccounts[i]])
        totalExcluded = totalExcluded + mainToken.balanceOf(totalStakedExcludedAccounts[i]);
    }
    return totalSupply - totalExcluded;
  }

  /**
  * @dev get the eth balance on the contract
  * @return eth balance
  */
  function getEthBalance() public view returns (uint) {
    return address(this).balance;
  }

  function getRewardPoolByToken(address _tokenAddress) external view returns (uint) {
    return rewardPool[_tokenAddress];
  }
  /**
  * @dev get the token balance
  * @param _tokenAddress token address
  */
  function getTokenBalance(address _tokenAddress) public view returns (uint) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
  * @dev get the tokens Length
  */
  function getTokensLength() external view returns (uint) {
    return tokens.length;
  }

  /**
  * @dev get the team Length
  */
  function getTeamLength() external view returns (uint) {
    return team.length;
  }

  /**
  * @dev get the reward token list
  */
  function getRewardTokenList() external view returns (Info[] memory){
    uint length = tokens.length;
    Info[] memory allTokens = new Info[](length);
    for (uint i = 0; i < length; i++) {
      allTokens[i] = tokenInfo[tokens[i]];
    }
    return allTokens;
  }

  /**
  * @dev initialize the contract, only call by owner
  * @param _token address of the main token
  * @param _router address of router exchange (Pancakeswap)
  * @param _burnPercentage burn percentage
  * @param _regularTransfersHasFee enable or disable regular transfer fee
  * @param _compound allow user to compund his reward fo main token
  * @param _lpInfo lp info
  * @param _tokens array of tokens to add
  * @param _team array of team to add
  * @param _excludedAccounts list of excluded accounts
  */
  function initialize(
    address _token,
    address _router,
    uint _burnPercentage,
    bool _regularTransfersHasFee,
    bool _compound,
    Info memory _lpInfo,
    Info[] memory _tokens,
    Info[] memory _team,
    address[] memory _excludedAccounts) onlyOwner public {
    ifNotMaintenance();
    token = _token;
    router =  _router;
    burnPercentage = _burnPercentage;
    regularTransfersHasFee = _regularTransfersHasFee;
    compound = _compound;

    IPancakeRouter02 pancakRouter = IPancakeRouter02(router);
    address lpAddress = IPancakeFactory(pancakRouter.factory()).createPair(token, pancakRouter.WETH());

    addOrUpdateLPInfo(
      lpAddress,
      _lpInfo.percentage,
      _lpInfo.isEnabled,
      _lpInfo.side
    );
    excludeFromTotalStaked(lpAddress, true);

    for (uint i; i < _tokens.length; i++) {
      Info memory info = _tokens[i];
      addOrUpdateRewardToken(
        info.addr,
        info.percentage,
        info.isEnabled,
        info.side
      );
    }

    for (uint i; i < _team.length; i++) {
      Info memory info = _team[i];
      addOrUpdateTeam(
        info.addr,
        info.percentage,
        info.isEnabled,
        info.side
      );
      excludeFromTotalStaked(info.addr, true);
    }

    for (uint i; i < _excludedAccounts.length; i++) {
      excludeFromFees(_excludedAccounts[i], true);
    }

    excludeFromTotalStaked(owner(), true);
    excludeFromTotalStaked(address(this), true);
    excludeFromTotalStaked(zeroAddress, true);
    //exclude addresses
    excludeFromFees(owner(), true);
  }

  /**
  * @dev set the main token
  * @param _token address of main token
  */
  function setToken(address _token) onlyOwner public {
    ifNotMaintenance();
    token = _token;
  }

  /**
  * @dev set exchange router
  * @param _router address of main token
  */
  function setRouter(address _router) onlyOwner public {
    ifNotMaintenance();
    router = _router;
  }

  /** 
  * @dev set the zero Address
  * @param _zeroAddress address of zero
  */
  function setZeroAddress(address _zeroAddress) onlyOwner external {
    ifNotMaintenance();
    zeroAddress = _zeroAddress;
  }
  /**
  * @dev set the burn percentage
  * @param _burnPercentage burn percentage
  */
  function setBurnPercentage(uint _burnPercentage) onlyOwner external {
    ifNotMaintenance();
    burnPercentage = _burnPercentage;
  }

  /**
  * @dev set regular transfer has fee
  * @param _regularTransfersHasFee enable or disable regular transfer fee
  */
  function setregularTransfersHasFee(bool _regularTransfersHasFee) onlyOwner external {
    ifNotMaintenance();
    regularTransfersHasFee = _regularTransfersHasFee;
  }

  /**
  * @dev set the compound Ability
  * @param _compound compound ability to true and false
  */
  function setCompound(bool _compound) onlyOwner external {
    ifNotMaintenance();
    compound = _compound;
  }

  /**
  * @dev add or update liquidity provider token
  * @param _addr address of token
  * @param _percentage tax percentage of token
  * @param _isEnabled enable the token
  * @param _side 0 for buy, 1 for sell, 2 for both
  */
  function addOrUpdateLPInfo(address _addr, uint _percentage, bool _isEnabled, uint8 _side) onlyOwner public {
    ifNotMaintenance();
    lpInfo.addr = _addr;
    lpInfo.percentage = _percentage;
    lpInfo.isEnabled = _isEnabled;
    lpInfo.side = _side;
  }

  /**
  * @dev add or update buy back/reward token
  * @param _addr address of token
  * @param _percentage tax percentage of token
  * @param _isEnabled enable the token
  * @param _side 0 for buy, 1 for sell, 2 for both
  */
  function addOrUpdateRewardToken(address _addr, uint _percentage, bool _isEnabled, uint8 _side) onlyOwner public {
    ifNotMaintenance();
    Info storage info = tokenInfo[_addr];

    info.percentage = _percentage;
    info.isEnabled = _isEnabled;
    info.addr = _addr;
    info.side = _side;
    if (info.isRegistered == false) {
      info.isRegistered = true;
      tokens.push(_addr);
    }
  }

  /**
  * @dev add or update buy back/reward token
  * @param _addr address of token
  * @param _percentage tax percentage of token
  * @param _isEnabled enable the token
  * @param _side 0 for buy, 1 for sell, 2 for both
  */
  function addOrUpdateTeam(address _addr, uint _percentage, bool _isEnabled, uint8 _side) onlyOwner public {
    ifNotMaintenance();
    Info storage info = teamInfo[_addr];

    info.percentage = _percentage;
    info.isEnabled = _isEnabled;
    info.addr = _addr;
    info.side = _side;
    if (info.isRegistered == false) {
      info.isRegistered = true;
      team.push(_addr);
    }
  }

  /**
  * @dev remove and delist token
  * @param _tokenAddress address of token
  */
  function delistToken(address _tokenAddress) onlyOwner public {
    ifNotMaintenance();
    Info storage info = tokenInfo[_tokenAddress];
    info.isEnabled = false;
  }

  /**
  * @dev remove and delist team member
  * @param _teamMemberAddress address of team member
  */
  function delistTeaMember(address _teamMemberAddress) onlyOwner public {
    ifNotMaintenance();
    Info storage info = teamInfo[_teamMemberAddress];
    info.isEnabled = false;
  }

  /**
  * @dev this is the main function to distribute the tokens call from only main token
  * @param _from from address
  * @param _to to address
  * @param _amount amount of tokens
  */
  function receiveTokens(address _from, address _to, uint256 _amount) public override returns (bool) {
    ifNotMaintenance();
    require(msg.sender == token, "PuffsPresenter::Only trigger from token");

    bool isLiquidityTransfer = ((_from == lpInfo.addr && _to == router) || (_to == lpInfo.addr && _from == router));
       
    bool isBuy = _from == lpInfo.addr || _from == router;
    bool isSell = _to == lpInfo.addr || _to == router;
    // bool isContractTransfer = _from == address(this) || _to == address(this) || _from == token || _to == token;
    bool isExcluded = isExcludedFromFees[_from] || isExcludedFromFees[_to];
    // if any account belongs to _isExcludedFromFee account then remove the fee and in case claiming is true
    // check if regular transfer has fee and no is buy or sell
    if (
      isExcluded ||
      isLiquidityTransfer ||
      // isContractTransfer ||
      claiming ||
      (regularTransfersHasFee == false && isSell == false && isBuy == false) ||
      swapping) {
      IERC20(token).transfer(_to, _amount);
      // if(!(_from != router && _to == lpInfo.addr)) {
      //   totalStaked = totalStaked + _amount;
      // }
    } else {
      _taxCollection(_from, _to, _amount, isBuy, isSell);
    }

    return true;
  }

  /** 
  * @dev get pending reward for 
  * @param _userAddress address of user
  */
  function pendingReward(address _userAddress) external view returns (uint[] memory) {
    IERC20 mainToken = IERC20(token);
    uint userBalance = mainToken.balanceOf(_userAddress);
    uint length = tokens.length;
    uint[] memory rewards = new uint[](length);
    
    if(userBalance > 0) {
      for(uint i; i < length; i++){
        address tokenAddress = tokens[i];
        uint share = (userBalance * 1e18)/totalStaked();
        uint userReward = ((share * rewardPool[tokenAddress])/1e18) - userDebt[tokenAddress][_userAddress];
        rewards[i] = userReward;
      }
    }
    return rewards;
  }
  /**
  * @dev anyone can claim all buy Back Amount
  */
  function claimAllReward() external {
    claiming = true;
    //claim all buy back Amount
    IERC20 mainToken = IERC20(token);
    uint userBalance = mainToken.balanceOf(msg.sender);
    
    if(userBalance > 0) {
      for(uint i; i < tokens.length; i++){
        address tokenAddress = tokens[i];
        uint share = (userBalance * 1e18)/totalStaked();
        uint userReward = ((share * rewardPool[tokenAddress])/1e18) - userDebt[tokenAddress][msg.sender];
        if(userReward > 0) {
          uint initialBalance = IERC20(tokenAddress).balanceOf(address(this));
          _swapTokens(token, tokenAddress, userReward);
          uint tokenToTransfer = IERC20(tokenAddress).balanceOf(address(this)) - initialBalance;
          IERC20(tokenAddress).transfer(msg.sender, tokenToTransfer);
          userDebt[tokenAddress][msg.sender] = userDebt[tokenAddress][msg.sender] + userReward;
        }
      }
    }
    //add liquidity
    _swapAndLiquify(token, lpAmount);
    lpAmount = 0;

    claiming = false;
  }

  /**
  * @dev add buy back token amount to contract
  * @param _tokenAddress address of token
  * @param _amount amount of tokens
  */
  function addTokenBalance(address _tokenAddress, uint256 _amount) external {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transferFrom(msg.sender, address(this), _amount);
  }

  /**
  * @dev withdraw eth balance
  */
  function withdrawEthBalance() external onlyOwner {
    payable(owner()).transfer(getEthBalance());
  }

  /**
  * @dev withdraw token balance
  * @param _tokenAddress token address
  */
  function withdrawTokenBalance(address _tokenAddress) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(
      owner(),
      getTokenBalance(_tokenAddress)
    );
  }

  /**
  * @dev function to exclude a account from tax
  * @param _account account to exclude
  * @param _excluded state of excluded account true or false
  */
  function excludeFromFees(address _account, bool _excluded) public onlyOwner {
    require(isExcludedFromFees[_account] != _excluded, "PuffsPresenter: Account is already the value of 'excluded'");
    isExcludedFromFees[_account] = _excluded;

    emit ExcludeFromFees(_account, _excluded);
  }

  /**
  * @dev function to exclude a account from tax
  * @param _account account to exclude
  * @param _excluded state of excluded account true or false
  */
  function excludeFromTotalStaked(address _account, bool _excluded) public onlyOwner {
    require(isExcludedTotalStaked[_account] != _excluded, "PuffsPresenter: Account is already the value of 'excluded'");
    isExcludedTotalStaked[_account] = _excluded;
    //ensure account will be added only one time
    if(isExcludedTotalStakedRegistered[_account] == false) {
      totalStakedExcludedAccounts.push(_account);
      isExcludedTotalStakedRegistered[_account] = true;
    }

    emit ExcludeTotalStaked(_account, _excluded);
  }

  /**
  * @dev swap tokens
  * @param _tokenAddressFrom address of from token
  * @param _tokenAddressTo address of to token
  * @param _amount amount of tokens
  */
  function _swapTokens(address _tokenAddressFrom, address _tokenAddressTo, uint256 _amount) internal {
    address[] memory path = new address[](3);
    path[0] = _tokenAddressFrom;
    path[1] = IPancakeRouter02(router).WETH();
    path[2] = _tokenAddressTo;

    IERC20(_tokenAddressFrom).approve(router, _amount);

    // make the swap
    IPancakeRouter02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
      _amount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  /**
  * @dev swap tokens and add liquidity
  * @param _tokenAddress address of token
  * @param _amount amount of tokens
  */
  function _swapAndLiquify(address _tokenAddress, uint256 _amount) internal {
    // split the contract balance into halves
    uint256 half = _amount / 2;
    uint256 otherHalf = _amount - half;

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    _swapTokensForEth(half);
    // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance - initialBalance;

    // add liquidity to pancakeswap
     _addLiquidity(_tokenAddress, otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  /**
  * @dev add liquidity in pair
  * @param _tokenAddress address of token
  * @param _tokenAmount amount of tokens
  * @param _ethAmount amount of eth tokens
  */
  function _addLiquidity(address _tokenAddress, uint256 _tokenAmount, uint256 _ethAmount) internal {
    // approve token transfer to cover all possible scenarios
    IERC20(_tokenAddress).approve(router, _tokenAmount);

    // add the liquidity
    IPancakeRouter02(router).addLiquidityETH{value : _ethAmount}(
      address(token),
      _tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(0),
      block.timestamp
    );
  }

  /**
  * @dev swap tokens and get ETH
  * @param _amount amount of tokens
  */
  function _swapTokensForEth(uint256 _amount) internal {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = IPancakeRouter02(router).WETH();

    IERC20(token).approve(router, _amount);

    // make the swap
    IPancakeRouter02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
      _amount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function _sendTaxToTeamInCaseOfSell(uint _taxAmount) internal {
    uint totalPercentage;
    //calculate total percentage
    for (uint i; i < team.length; i++) {
      totalPercentage = totalPercentage + teamInfo[team[i]].percentage;
    }

    for (uint i; i < team.length; i++) {
      Info memory info = tokenInfo[tokens[i]];
      teamAmount[team[i]] = teamAmount[team[i]] + ((_taxAmount * info.percentage)/totalPercentage);
    }

  }
  /**
  * @dev internal function to collect tax
  * @param _from from address
  * @param _to to address
  * @param _amount amount of tokens
  * @param _isBuy true if buy order
  * @param _isSell true if sell order
  */
  function _taxCollection(address _from, address _to, uint256 _amount, bool _isBuy, bool _isSell) internal {
    swapping = true;
    uint totalTax;
    address recipient = _from;
    // require(swapping == false, "jj");
    bool normalTransfer = _isBuy == false && _isSell == false;
    if(_isBuy || normalTransfer) {
      recipient = _to;
    }

    //direct transfer to team
    uint teamTaxAccumulated;
    uint teamTotalPercentage;
    for (uint i; i < team.length; i++) {
      Info memory info = teamInfo[team[i]];
      if ((info.isEnabled == true && _checkSide(_isBuy, _isSell, info.side)) ||
        (info.isEnabled == true && normalTransfer)) {
        uint teamTax = (_amount * info.percentage) / RATE_NOMINATOR;
        IERC20(token).transfer(team[i], teamTax);
        teamTaxAccumulated = teamTaxAccumulated + teamTax;
        teamTotalPercentage = teamTotalPercentage + info.percentage;
      }
    }
    //add lp in main token
    if ((lpInfo.isEnabled == true && _checkSide(_isBuy, _isSell, lpInfo.side)) ||
      (lpInfo.isEnabled == true && normalTransfer)) {
      uint lpTax = (_amount * lpInfo.percentage) / RATE_NOMINATOR;
      lpAmount = lpAmount + lpTax;
      totalTax = totalTax + lpTax;
    }
    //transfering tokens to buy back tokens
    for (uint i; i < tokens.length; i++) {
      Info memory info = tokenInfo[tokens[i]];
      // send all unclaimed buy back tax to team in case of user sell
      if(_isSell == true ) {
        uint userBalance = IERC20(token).balanceOf(recipient);
        uint share = (userBalance * 1e18)/totalStaked();
        uint userReward = ((share * rewardPool[info.addr])/1e18) - userDebt[info.addr][recipient];
        //share unclaimed reward with team 
        if(userReward > 0){
          for (uint j; j < team.length; j++) {
            Info memory tInfo = teamInfo[team[j]];
            if(tInfo.isEnabled) {
              uint tokenToTransfer = (userReward * tInfo.percentage)/teamTotalPercentage;
              IERC20(token).transfer(team[j], tokenToTransfer);
            }
          }
          userDebt[info.addr][recipient] = userDebt[info.addr][recipient] + userReward;
        }
      }
      if ((info.isEnabled == true && _checkSide(_isBuy, _isSell, info.side)) ||
        (info.isEnabled == true && normalTransfer)) {
        //store dividend
        uint buyBackTax = (_amount * info.percentage) / RATE_NOMINATOR;
        //track dividend
        rewardPool[info.addr] = rewardPool[info.addr] + buyBackTax;
        totalTax = totalTax + buyBackTax;
        totalBuyBackAmount = totalBuyBackAmount + buyBackTax;
      }
    }
    uint burnTax = (_amount * burnPercentage) / RATE_NOMINATOR;
    if (burnTax > 0) {
      IERC20(token).transfer(zeroAddress, burnTax);
    }
    //send total tax collected to contract
    IERC20(token).transfer(address(this), totalTax);
    //send remaining amount
    IERC20(token).transfer(_to, _amount - totalTax - teamTaxAccumulated - burnTax);

    swapping = false;
  }

  /**
  * @dev internal function to check side configuration
  * @param _isBuy see if buy is true
  * @param _isSell see if sell is true
  * @param _side see if side is true
  */
  function _checkSide(bool _isBuy, bool _isSell, uint8 _side) internal pure returns (bool) {
    if (_isBuy == true && _side == 0) return true;
    if (_isSell == true && _side == 1) return true;
    if ((_isBuy == true || _isSell == true) && _side == 2) return true;
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IPancakeFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IPancakeRouter01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);

  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface ITokenPresenter {
  function receiveTokens(address _from, address _to, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Maintainable is Ownable {

  bool public isMaintenance = false;
  bool public isOutdated = false;

  // Check if contract is not in maintenance
  function ifNotMaintenance() internal view {
    require(!isMaintenance, "Maintenance");
    require(!isOutdated, "Outdated");
  }

  // Check if contract on maintenance for restore
  function ifMaintenance() internal view {
    require(isMaintenance, "!Maintenance");
  }

  // Enable maintenance
  function enableMaintenance(bool status) onlyOwner public {
    isMaintenance = status;
  }

  // Enable outdated
  function enableOutdated(bool status) onlyOwner public {
    isOutdated = status;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

