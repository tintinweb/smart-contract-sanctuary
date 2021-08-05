/**
 *Submitted for verification at Etherscan.io on 2020-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}(new bytes(0));
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IUniswapV2Pair token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IUniswapV2Pair token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IUniswapV2Pair token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IUniswapV2Pair token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IUniswapV2Pair token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IUniswapV2Pair token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IERC20Custom {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function farmMint(address user, uint256 amount) external;
    function burn(uint256 amount) external;
}


contract MoonStake {
  using SafeMath for uint256;
  using SafeERC20 for IUniswapV2Pair;

  IUniswapV2Pair public lpToken = IUniswapV2Pair(address(0)); //Moonday-Mooncrops LP Token
  IUniswapV2Pair public moonETHToken = IUniswapV2Pair(address(0)); //Moonday-WETH LP Token

  address weth;
  address crops;
  address moonday;

  address owner;
  address dev1;
  address dev2;
  address dev3;
  address controller;

  modifier onlyDev() {
        require(msg.sender == controller, "Not Dev");
        _;
    }

  mapping(address => UserData) public userList;

  mapping(address => mapping(uint256 => StakeData)) public stakeList;
  mapping(address => uint256) public stakeCount;

  uint256 public burnCount;
  mapping(uint256 => BurnData) public burnList;
  bool burnLock;

  struct BurnData{
    uint256 burnStart;
    uint256 reserveSnapshot0;
    uint256 reserveSnapshot1;
    uint256 percentageSnapshot;

    uint256 finalReserveSnapshot0;
    uint256 finalReserveSnapshot1;
    uint256 finalPercentageSnapshot;

    uint256 totalFees;
    uint256 totalBurn;
  }

  struct UserData{
    uint256 moondayEthStaked;
    uint256 percentage;
    uint256 reserveConstant;
    uint256 percentageSnapshot;
    mapping(uint256 => uint256) burnStake;
  }

  struct StakeData{
    uint256 stakeTime;
    uint256 amount;
  }

  event Staked(address indexed user, uint256 amount, uint256 stakeIndex);
  event RewardPaid(address indexed user, uint256 reward);

  constructor(address _weth, address _owner, address _dev1, address _dev2, address _dev3) public {
    require(_owner != address(0) && _dev1 != address(0) && _dev2 != address(0) && _dev3 != address(0), "Invalid User Address");
    weth = _weth;
    owner = _owner;
    dev1 = _dev1;
    dev2 = _dev2;
    dev3 = _dev3;
    controller = msg.sender;
  }


  function getBurnStake(address _user, uint256 _week) public view returns(uint256){
    return(userList[_user].burnStake[_week]);
  }

  function setBurnLock() public onlyDev{
    burnLock = !burnLock;
  }

  function setLPTokens(address _lpToken, address _moonEthToken, address _crops, address _moonday) public onlyDev{
    lpToken = IUniswapV2Pair(_lpToken);
    moonETHToken = IUniswapV2Pair(_moonEthToken);
    crops = _crops;
    moonday = _moonday;
  }

  /// Get current reward for stake
  /// @dev calculates returnable stake amount
  /// @param _user the user to query
  /// @param _index the stake index to query
  /// @return total stake reward
  function currentReward(address _user, uint256 _index) public view returns (uint256) {
    if(stakeList[msg.sender][_index].amount == 0){
      return 0;
    }

    uint256 secondsPercent = (20 + userList[msg.sender].percentage).mul(1 ether).div(864000);
    uint256 secPayout = secondsPercent.mul(block.timestamp - stakeList[msg.sender][_index].stakeTime);

    uint cropReserves;
    uint moonReserves;

    if(crops > moonday){
      (moonReserves, cropReserves,) = lpToken.getReserves();
    }
    else{
      (cropReserves, moonReserves,) = lpToken.getReserves();
    }

    uint256 cropsAmount = stakeList[_user][_index].amount.mul(cropReserves).div(lpToken.totalSupply());
    if(secPayout > 185 ether){
      return cropsAmount.mul(185 ether).div(50 ether);
    }
    else{
      return cropsAmount.mul(secPayout).div(50 ether);
    }
  }

  /// Stake LP token
  /// @dev stakes users LP tokens
  /// @param _amount the amount to stake
  function stake(uint256 _amount) public {
      require(_amount >= (1 ether), "Cannot stake less than 1 LP token");

      lpToken.safeTransferFrom(msg.sender, address(this), _amount);
      lpToken.transfer(owner, _amount.mul(23).div(100));
      lpToken.transfer(dev1, _amount.div(20));
      lpToken.transfer(dev2, _amount.div(100));
      lpToken.transfer(dev3, _amount.div(100));

      stakeList[msg.sender][stakeCount[msg.sender]].amount = _amount;
      stakeList[msg.sender][stakeCount[msg.sender]].stakeTime = block.timestamp;
      stakeCount[msg.sender]++;

      emit Staked(msg.sender, _amount, stakeCount[msg.sender] - 1);
  }

  /// Deposit Moonday/ETH LP in exchange for a higher percentage
  /// @dev stakes users Moonday/ETH LP tokens
  /// @param _amount the amount to stake
  function depositMoondayETH(uint256 _amount) public{
    require(userList[msg.sender].percentage + _amount <= 50, "You have deposited the maximum amount");

    uint wethReserves;
    uint moonReserves;

    if(weth > moonday){
      (moonReserves, wethReserves,) = moonETHToken.getReserves();
    }
    else{
      (wethReserves, moonReserves,) = moonETHToken.getReserves();
    }

    uint256 lpRequired = uint256(1 ether).mul(moonETHToken.totalSupply()).div(moonReserves).div(10);

    moonETHToken.safeTransferFrom(msg.sender, address(this), lpRequired.mul(_amount));
    moonETHToken.transfer(owner, lpRequired.mul(_amount).div(20));
    moonETHToken.transfer(dev1, lpRequired.mul(_amount).div(20));
    moonETHToken.transfer(dev2, lpRequired.mul(_amount).div(100));
    moonETHToken.transfer(dev3, lpRequired.mul(_amount).div(100));

    (uint256 reserveSnapshot0, uint256 reserveSnapshot1,) = moonETHToken.getReserves();
    uint256 finalPercentageSnapshot = userList[msg.sender].moondayEthStaked.mul(1 ether).div(moonETHToken.totalSupply());

    uint256 constantFirst = userList[msg.sender].reserveConstant.mul(userList[msg.sender].percentageSnapshot);
    uint256 constantSecond = reserveSnapshot0.mul(reserveSnapshot1).mul(finalPercentageSnapshot);

    uint256 totalFees = 0;

    if(userList[msg.sender].percentage != 0){
      uint256 deltaPercentage = constantSecond.mul(1 ether).div(constantFirst);
      if(deltaPercentage.mul(userList[msg.sender].moondayEthStaked).div(1 ether) > userList[msg.sender].moondayEthStaked){
        totalFees = deltaPercentage.mul(userList[msg.sender].moondayEthStaked).div(1 ether).sub(userList[msg.sender].moondayEthStaked);
      }
    }

    userList[msg.sender].moondayEthStaked += lpRequired.mul(_amount).mul(88).div(100);
    userList[msg.sender].moondayEthStaked = userList[msg.sender].moondayEthStaked.sub(totalFees);
    userList[msg.sender].percentage += _amount;

    userList[msg.sender].percentageSnapshot = userList[msg.sender].moondayEthStaked.mul(1 ether).div(moonETHToken.totalSupply());
    userList[msg.sender].reserveConstant = reserveSnapshot0.mul(reserveSnapshot1);
  }

  /// Withdraws Moonday/ETH LP in exchange for a lower percentage
  /// @dev withdraws users Moonday/ETH LP tokens
  /// @param _amount the amount to stake
  function withdrawMoondayETH(uint256 _amount) public{
    require(userList[msg.sender].percentage >= _amount, "You cannot withdraw this amount");

    uint256 balance = userList[msg.sender].moondayEthStaked.mul(_amount).div(userList[msg.sender].percentage);

    (uint256 finalReserveSnapshot0, uint256 finalReserveSnapshot1,) = moonETHToken.getReserves();
    uint256 finalPercentageSnapshot = balance.mul(1 ether).div(moonETHToken.totalSupply());


    uint256 constantFirst = userList[msg.sender].reserveConstant.mul(userList[msg.sender].percentageSnapshot.mul(_amount).div(userList[msg.sender].percentage));
    uint256 constantSecond = finalReserveSnapshot0.mul(finalReserveSnapshot1).mul(finalPercentageSnapshot);

    uint256 deltaPercentage = constantSecond.mul(1 ether).div(constantFirst);
    uint256 totalFees = 0;

    if(deltaPercentage.mul(balance).div(1 ether) > balance){
      totalFees = deltaPercentage.mul(balance).div(1 ether).sub(balance);
    }

    uint256 lpReturn = balance.sub(totalFees);
    burnList[burnCount].totalFees += totalFees;
    moonETHToken.transfer(msg.sender, lpReturn);
    userList[msg.sender].moondayEthStaked -= userList[msg.sender].moondayEthStaked.mul(_amount).div(userList[msg.sender].percentage);
    userList[msg.sender].percentage -= _amount;
    userList[msg.sender].percentageSnapshot = userList[msg.sender].moondayEthStaked.mul(1 ether).div(moonETHToken.totalSupply());
    //userList[msg.sender].reserveConstant = finalReserveSnapshot0.mul(finalReserveSnapshot1);
  }

  /// Give staker their mooncrop reward
  /// @dev calculates claim and pays user
  /// @param _index the stake to query
  /// @return dividend claimed by user
  function claim(uint256 _index) public returns(uint256){
      require(stakeList[msg.sender][_index].amount > 0, "Stake Doesnt Exist");

      uint256 reward = currentReward(msg.sender, _index);
      IERC20Custom(crops).farmMint(msg.sender, reward);
      stakeList[msg.sender][_index].amount = 0;
      emit RewardPaid(msg.sender, reward);
      return reward;
  }

  function burnMining(uint256 _amount) public{
    require(!burnLock, "Function Locked");
    IERC20Custom(crops).transferFrom(msg.sender, address(this), _amount.mul(1 ether));
    IERC20Custom(crops).burn(_amount.mul(1 ether));
    burnList[burnCount].totalBurn += _amount.mul(1 ether);
    userList[msg.sender].burnStake[burnCount] += _amount.mul(1 ether);
  }

  function payoutBurns() public onlyDev{
    uint256 balance = moonETHToken.balanceOf(address(this));

    (burnList[burnCount].finalReserveSnapshot0, burnList[burnCount].finalReserveSnapshot1,) = moonETHToken.getReserves();
    burnList[burnCount].finalPercentageSnapshot = moonETHToken.balanceOf(address(this)).mul(1 ether).div(moonETHToken.totalSupply());

    uint256 constantFirst = burnList[burnCount].reserveSnapshot0.mul(burnList[burnCount].reserveSnapshot1).mul(burnList[burnCount].percentageSnapshot);
    uint256 constantSecond = burnList[burnCount].finalReserveSnapshot0.mul(burnList[burnCount].finalReserveSnapshot1).mul(burnList[burnCount].finalPercentageSnapshot);

    if(constantFirst != 0 && constantSecond != 0){
      uint256 deltaPercentage = constantSecond.mul(1 ether).div(constantFirst);
      if(deltaPercentage.mul(balance).div(1 ether) > balance){
        burnList[burnCount].totalFees += deltaPercentage.mul(balance).div(1 ether).sub(balance);
      }
    }

    burnCount++;
    burnList[burnCount].burnStart = block.timestamp;
    (burnList[burnCount].reserveSnapshot0, burnList[burnCount].reserveSnapshot1,) = moonETHToken.getReserves();
    burnList[burnCount].percentageSnapshot = moonETHToken.balanceOf(address(this)).mul(1 ether).div(moonETHToken.totalSupply());
  }

  function claimBurns(uint256 _week) public{
    require(burnList[_week].finalPercentageSnapshot != 0, "Burn Not Finished Yet");
    require(!burnLock, "Function Locked");
    uint256 divs = userList[msg.sender].burnStake[_week].mul(burnList[_week].totalFees).div(burnList[_week].totalBurn);

    moonETHToken.transfer(msg.sender, divs);
    userList[msg.sender].burnStake[_week] = 0;
  }

}