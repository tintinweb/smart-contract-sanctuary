//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


interface MyContract {

/// @dev Deposit ERC20 tokens on behalf of msg.sender to Aave Protocol
/// @param _erc20Contract The address fo the underlying asset to deposit to Aave Protocol v2
/// @param _amount The amount of the underlying asset to deposit
/// @return success Whether the deposit operation was successful or not
function deposit(address _erc20Contract, uint256 _amount) external returns (bool success);

/// @dev Withdraw ERC20 tokens on behalf of msg.sender from Aave Protocol
/// @param _erc20Contract The address of the underlyng asset being withdrawn
/// @param _amount The amount to be withdrawn
/// @return amountWithdrawn The actual amount withdrawn from Aave
function withdraw(address _erc20Contract, uint256 _amount) external returns (uint256 amountWithdrawn);

/// @dev Read only function
/// @return amountInEth Returns the value locked as collateral posted by msg.sender
function checkCollateralValueInEth(address _erc20Contract) external view returns (uint256 amountInEth);
}


contract CodingTest is MyContract {
    //priceFeed for only eth/usdt
    AggregatorV3Interface internal priceFeed;
    mapping(IERC20=>mapping(address=>uint256)) public userDepositedAmount;
    event depositingToken(address indexed erc20Contract,address indexed user,uint256 amount,uint256 date);
    event withdrawingToken(address indexed erc20Contract,address indexed user,uint256 amount,uint256 date);
    bool private _initialized = false;
    function initialize()public  {
        require(!_initialized," intialized already ");
        _initialized=true;
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

    }
    //User must approve 1st token for this contract 
    function deposit(address _erc20Contract, uint256 _amount) external  override returns (bool success){
            IERC20 erc20=IERC20(_erc20Contract);
            success=erc20.transferFrom(msg.sender,address(this),_amount);
            userDepositedAmount[erc20][msg.sender]+=_amount;
            require(success,"Error in depositing tokens");
            emit depositingToken(_erc20Contract,msg.sender,_amount,block.timestamp);
    }
    function withdraw(address _erc20Contract,uint256 _amount) external  override returns (uint256 amountWithdrawn){
            IERC20 erc20=IERC20(_erc20Contract);
            uint256 userAmount=userDepositedAmount[erc20][msg.sender];
            require(userAmount>0,"User must have deposited amount greater than 0");
            amountWithdrawn=_amount>=userAmount?_amount:userAmount;
            require(erc20.balanceOf(address(this))>=amountWithdrawn,"contract have not enough ammount of token");
            userDepositedAmount[erc20][msg.sender]-=amountWithdrawn;
            erc20.transfer(msg.sender,amountWithdrawn);
            emit withdrawingToken(_erc20Contract,msg.sender,amountWithdrawn,block.timestamp);
    }
    //Originally dive it by 1e28 then exact answer in float you will getThePrice
    function checkCollateralValueInEth(address _erc20Contract) external override view  returns (uint256 amountInEth){
               uint256 ethAmmounInUSDT=uint256(getThePrice());
               amountInEth=(userDepositedAmount[IERC20(_erc20Contract)][msg.sender])*10**18/ethAmmounInUSDT;
    }
     function getThePrice() public view returns (int) {
         (
             uint80 roundID, 
             int price,
             uint startedAt,
             uint timeStamp,
             uint80 answeredInRound
         ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}