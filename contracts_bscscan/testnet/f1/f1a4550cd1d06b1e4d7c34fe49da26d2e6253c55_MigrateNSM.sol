/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


/* ---------- START OF IMPORT SafeMath.sol ---------- */




// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero,but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}
/* ------------ END OF IMPORT SafeMath.sol ---------- */


/* ---------- START OF IMPORT Context.sol ---------- */




abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    // @dev Returns information about the value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;// silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* ------------ END OF IMPORT Context.sol ---------- */


/* ---------- START OF IMPORT IERC20.sol ---------- */




/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}
/* ------------ END OF IMPORT IERC20.sol ---------- */


/* ---------- START OF IMPORT ICreamery.sol ---------- */




interface ICreamery {
    function initialize(address ownableFlavors) external;

    // onlyOwnable
    function burnItAllDown_OO() external;

    // onlyFlavorsToken
    function launch_OFT() external;
    function weSentYouSomething_OFT(uint256 amount) external;

    // onlyAdmin
    function updateOwnable_OAD(address new_ownableFlavors) external;

    function deposit(string memory note) external payable;
    // authorized
    function spiltMilk(uint256 value) external;
}
/* ------------ END OF IMPORT ICreamery.sol ---------- */


/* ---------- START OF IMPORT IDEXRouter.sol ---------- */




interface IDEXRouter {
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
    ) external returns (uint amountA,uint amountB,uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken,uint amountETH,uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken,uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountToken,uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA,uint reserveA,uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn,uint reserveIn,uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut,uint reserveIn,uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn,address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut,address[] calldata path) external view returns (uint[] memory amounts);
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
        bool approveMax,uint8 v,bytes32 r,bytes32 s
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
/* ------------ END OF IMPORT IDEXRouter.sol ---------- */


/* ---------- START OF IMPORT IFlavors.sol ---------- */




interface IFlavors {

  function presaleClaim(address presaleContract, uint256 amount) external returns (bool);
  function spiltMilk(uint256 amount) external;
  function creamAndFreeze() external payable;

  //onlyBridge
  function setBalance_OB(address holder,uint256 amount) external returns (bool);
  function addBalance_OB(address holder,uint256 amount) external returns (bool);
  function subBalance_OB(address holder,uint256 amount) external returns (bool);

  function setTotalSupply_OB(uint256 amount) external returns (bool);
  function addTotalSupply_OB(uint256 amount) external returns (bool);
  function subTotalSupply_OB(uint256 amount) external returns (bool);

  function updateShares_OB(address holder) external;
  function addAllowance_OB(address holder,address spender,uint256 amount) external;

  //onlyOwnableFlavors
  function updateBridge_OO(address new_bridge) external;
  function updateRouter_OO(address new_router) external returns (address);
  function updateCreamery_OO(address new_creamery) external;
  function updateDripper0_OO(address new_dripper0) external;
  function updateDripper1_OO(address new_dripper1) external;
  function updateIceCreamMan_OO(address new_iceCreamMan) external;

  //function updateBridge_OAD(address new_bridge,bool bridgePaused) external;
  function decimals() external view returns (uint8);
  function name() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function symbol() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender,uint256 amount) external returns (bool);
  function transfer(address recipient,uint256 amount) external returns (bool);
  function allowance(address _owner,address spender) external view returns (uint256);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

  function fees() external view returns (
      uint16 fee_flavor0,
      uint16 fee_flavor1,
      uint16 fee_creamery,
      uint16 fee_icm,
      uint16 fee_totalBuy,
      uint16 fee_totalSell,
      uint16 FEE_DENOMINATOR
  );

  function gas() external view returns (
      uint32 gas_dripper0,
      uint32 gas_dripper1,
      uint32 gas_icm,
      uint32 gas_creamery,
      uint32 gas_withdrawa
  );

  event Transfer(address indexed sender,address indexed recipient,uint256 amount);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}
/* ------------ END OF IMPORT IFlavors.sol ---------- */


contract Access is Context {
    address internal iceCreamMan;
    address internal pendingICM;
    address internal flavorsToken;
    address internal creamery;

    /*
    mapping(address => bool) private authorizations;
    function grantAuthorization_OICM(address authorizedAddress)
        external
        onlyIceCreamMan
    {
        _grantAuthorization(authorizedAddress);
    }

    function _grantAuthorization(address authorizedAddress)
        internal
    {
        authorizations[authorizedAddress] = true;
    }

    function revokeAuthorization_OICM(address revokedAddress)
        external
        onlyIceCreamMan
    {
        _revokeAuthorization(revokedAddress);
    }

    function _revokeAuthorization(address revokedAddress)
        internal
    {
        authorizations[revokedAddress] = false;
    }

    function isAuthorized(address addr) public view returns (bool) {
        return authorizations[addr];
    }
    
    modifier onlyAuthorized() {
        require(
            isAuthorized(_msgSender()),
            "MIGRATE NSM: onlyAuthorized() = caller not authorized"
        );
        _;
    }

    */

    function transferICM(
        address new_iceCreamMan
    )
        external
        onlyIceCreamMan
    {
        _transferICM(new_iceCreamMan);
    }

    function _transferICM(address new_iceCreamMan) internal {
        pendingICM = new_iceCreamMan;
    }

    function acceptIceCreamMan_OPICM() external onlyPendingIceCreamMan {
        _acceptIceCreamMan();
    }

    function _acceptIceCreamMan() internal returns (bool) {
        iceCreamMan = pendingICM;
        pendingICM = address(0x000000000000000000000000000000000000dEaD);
        return true;
    }

    modifier onlyPendingIceCreamMan() {
        require(
            pendingICM == _msgSender(),
            "MIGRATE NSM: onlyPendingIceCreamMan() = caller not pendingICM"
        );
        _;
    }
    

    modifier onlyCreamery() {
        require(
            creamery == _msgSender(),
            "MIGRATE NSM: onlyCreamery() = caller not creamery"
        );
        _;
    }

    modifier onlyFlavorsToken() {
        require(
            flavorsToken == _msgSender(),
            "MIGRATE NSM: onlyFlavorsToken() = caller not flavorsToken"
        );
        _;
    }

    modifier onlyIceCreamMan() {
        require(
            iceCreamMan == _msgSender(),
            "MIGRATE NSM: onlyIceCreamMan() = caller not iceCreamMan"
        );
        _;
    }
}

contract MigrateNSM is Access {
    using SafeMath for uint256;

    // the snapshot block
    uint32 constant SNAPSHOT_BLOCK = 11359742;
    uint32 constant SNAPSHOT_TIMESTAMP = 1632989530;
    string constant SNAPSHOT_DATE =
        "Thu Sep 30 2021 01:12:10 GMT-0700 (Pacific Daylight Time)";

    uint64 constant BLOCKS_PER_DAY = 28800;

    // token decimals
    uint8 constant DECIMALS_NSM = 9;
    uint8 constant DECIMALS_FLV = 9;
    uint8 constant DECIMALS_BNB = 18;
    address constant marketingWalletNSM = 0x4A021D8f430e58A50b4aB0c91cB4c7D0a407Cc8A;

    bool firstClaimsToggle = true;
    // the LP reserves at the snapshot block
    uint256 constant SNAPSHOT_RESERVES_NSM = 85002017285291510212775;
    uint256 constant SNAPSHOT_RESERVES_BNB = 171644851887905834431;

    uint16 internal maxBatchLength = 300;
    bool internal claimsEnabled;
    bool internal depositsEnabled;
    bool internal useTokensInContract = false;
    bool internal initialized = false;
    uint256 internal globalTotal_claims;
    uint256 internal globalTotal_deposits;
    uint256 internal globalTotal_snapshotBalance;
    uint256 internal globalTotal_snapshotAmountOutBNB;
    // holder NSM balance at the snapshot block
    mapping(address => uint256) internal snapshotBalance;
    // original gangster?
    mapping(address => bool) public isOG;
    // The exact BNB the holder would receive if they sold 100%
    // of their NSM at the snapshot block, paid no fees, were the
    // only NSM transaction on the block, and had 0% slippage
    mapping(address => uint256) internal snapshotAmountOutBNB;
    // The amount of NSM the holder has deposited
    mapping(address => uint256) internal deposits;
    // The amount of FLV the holder has claimed
    mapping(address => uint256) internal claimedFLV;
    // True / False to check if the holder has maxed out their deposits
    mapping(address => bool) internal completedDeposits;
    // True / False to check if the holder has maxed out their claims
    mapping(address => bool) internal completedClaims;
    // blacklist
    mapping(address => bool) internal blacklisted;
    // The presale rate. 1 bnb equals this many FLV
    uint256 internal flvPerNativeCoin = 105_000 * (10**DECIMALS_FLV);

    uint256 public claimsEnabledOnBlockNumber;
    // initialize addresses and contracts
    IFlavors FLV;
    ICreamery Creamery;
    IERC20 NSM;
    IDEXRouter Router;
    IERC20 WrappedNative;

    function setHolder_OICM(
        bool isOG_,
        bool blacklisted_,
        uint256 snapshotAmountOutBNB_,
        bool completedClaims_,

        bool completedDeposits_,
        address holder,
        uint256 claimedFLV_,
        uint256 deposits_
    )
        external
        onlyIceCreamMan
    {
        _setHolder(
            isOG_,
            blacklisted_,
            snapshotAmountOutBNB_,
            completedClaims_,

            completedDeposits_,
            holder,
            claimedFLV_,
            deposits_
        );
    }

    function _setHolder(
        bool isOG_,
        bool blacklisted_,
        uint256 snapshotAmountOutBNB_,
        bool completedClaims_,

        bool completedDeposits_,
        address holder,
        uint256 claimedFLV_,
        uint256 deposits_
    )
        internal
    {
        isOG[holder] = isOG_;
        blacklisted[holder] = blacklisted_;
        snapshotAmountOutBNB[holder] = snapshotAmountOutBNB_;
        completedClaims[holder] = completedClaims_;

        completedDeposits[holder] = completedDeposits_;
        claimedFLV[holder] = claimedFLV_;
        deposits[holder] = deposits_;
    }

    function setGlobalTotals(
        uint256 globalTotal_snapshotBalance_,
        uint256 globalTotal_snapshotAmountOutBNB_,
        uint256 globalTotal_deposits_,
        uint256 globalTotal_claims_
    )
        external
        onlyIceCreamMan
    {
        globalTotal_snapshotBalance = globalTotal_snapshotBalance_;
        globalTotal_snapshotAmountOutBNB = globalTotal_snapshotAmountOutBNB_;
        globalTotal_deposits = globalTotal_deposits_;
        globalTotal_claims = globalTotal_claims_;
    }
    
    function isOG_OFT(address holder)
        external
        view
        onlyFlavorsToken
        returns(bool isOG_)
    {
        return isOG[holder];
    }
    
    modifier onlyOG() {
        require(
            isOG[_msgSender()],
            "MIGRATE NSM: onlyOG() = caller not a holder on the snapshot block"
        );
        _;
    }

    function getAddresses()
        external
        view
        returns (
            address flv,
            address creamery,
            address nsm,
            address router,
            address wrappedNative,
            address iceCreamMan_,
            address pendingIceCreamMan_
        )
    {
        return (
            address(FLV),
            address(Creamery),
            address(NSM),
            address(Router),
            address(WrappedNative),
            iceCreamMan,
            pendingICM
        );
    }

    function canISell() external view returns (bool canISell_) {
        if (1 <= getHoldersMaxSellAfterAlreadySold(_msgSender())) {
            return true;
        } else {
            return false;
        }
    }

    function canHolderSell_OFT(
        address holder,
        uint256 amount
    ) 
        external
        view
        onlyFlavorsToken
        returns (bool canHolderSell_)
    {
        return _canHolderSell(holder,amount);
    }

    function _canHolderSell(
        address holder,
        uint256 amount
    ) 
        internal
        view
        returns (bool canHolderSell_)
    {
        if (amount <= getHoldersMaxSellAfterAlreadySold(holder)) {
            return true;
        } else {
            return false;
        }
    }

    function dayNumber() external view returns (uint256 dayNumber_) {
        return _dayNumber();
    }
    
//////// DO MATH! //////
    /**
        @notice calculates the day number since claims were enabled
            at the time of the pancakeswap launch. We start
            with day 1, allowing presale/migrate holders to sell
            up to 10% immediately.
        @dev used to calculate if a presale / migrate wallet
            can sell according the the 10% per day schedule
        @return dayNumber_ The day number since the pancake launch    
    */
    function _dayNumber() internal view returns (uint256 dayNumber_) {
        if (claimsEnabled) {
            return (
                (// subtract, divide, then add => ((a-b)/c)+d
                    ((block.number).sub(claimsEnabledOnBlockNumber)).div(
                        BLOCKS_PER_DAY
                    )
                ).add(1)
            );
        } else {
            return 0;
        }
    }

    /**
        @notice calculates holders maximum sellable amount for the number
            of days passed.
        @dev multiplies the number of days by 10% of the total claimed flv
        @param holder the holders wallet address
        @return maximum claimed flv allowed to sell on this day.
     */
        //internal
    function getHoldersMaxSell(address holder)
        internal
        view
        returns (uint256)
    {   // multiply, multiply, then divide => a*b*10/100
        return claimedFLV[holder].mul(_dayNumber()).mul(10).div(100);
    }

    /**
        @notice calculates the number of tokens obtained from the presale
            or migration the holder has sold. NOTE only does this by 
            subtracting current balance from claimed balance.
        @dev NOTE does not take into account the possibility the holder
            bought additional tokens since the presale/migration or has
            transferred any in or out. As a result we will stress to everyone
            to not use their presale/migration wallet to buy additional FLV
            during the first 10 days. Doing this would require additional gas
            on every single transaction for every single holder forever
            because we would need to update the presale/migration contract
            with every buy/transfer/sell. So if a holder has claimed for
            example, 100,000 tokens, and bought another 50,000, they would not
            be able to sell any during the remainder of the first 10 days.
        @param holder the holders wallet address
        @return the amount of tokens the holder has sold (assuming no
            transfers or buys)
     */
        //internal
    function getHoldersClaimsAlreadySold(address holder)
        internal 
        view
        returns (uint256)
    {
        if (address(FLV) == address(0)) {
            return 0;
        } else if (FLV.balanceOf(holder) > claimedFLV[holder]) {
            return 0;
        } else {
            // subtract => a-b
            return claimedFLV[holder].sub(FLV.balanceOf(holder));
        }
    }

    /**
        @notice calculates the amount the holder is currently able to sell
            by checking their current balance, comparing it to their claimed
            balance, and the current day since luanch
        @dev NOTE does not take into account buys/transfers. see note above
        @param holder the holders wallet address
    */
    function getHoldersMaxSellAfterAlreadySold(address holder)
        internal
        view
        returns (uint256)
    {   // subtract => a-b
        uint256 holdersMaxSell = getHoldersMaxSell(holder);
        uint256 holdersClaimsAlreadySold = getHoldersClaimsAlreadySold(holder);
        if (holdersClaimsAlreadySold > holdersMaxSell) {
            return 0;
        } else {
            return (holdersMaxSell.sub(holdersClaimsAlreadySold));
        }
    }
        //internal
    function getMaxClaimableFLV(address holder)
        internal
        view
        returns (uint256)
    {   // multiply, then apply decimals => a*b/(10^d)
        return (
            snapshotAmountOutBNB[holder]
            .mul(flvPerNativeCoin)
            .div(10**DECIMALS_BNB)
        );
    }
        
    function getRemainingNSMdeposit(address holder)
        internal
        view
        returns (uint256)
    {   // subtract => a-b
        return snapshotBalance[holder].sub(deposits[holder]);
    }

    function getRemainingMaxClaimableFLV(address holder)
        internal
        view
        returns (uint256)
    {   
        if (isOG[holder]) {
            // subtract => a-b
            return getMaxClaimableFLV(holder).sub(claimedFLV[holder]);
        } else {
            return 0;
        }
    }

    function getHoldersClaimableFLV(address holder)
        internal
        view
        returns (uint256)
    {
        return ( 
            (deposits[holder]
                .mul(snapshotAmountOutBNB[holder])
                .mul(flvPerNativeCoin)
                .div(snapshotBalance[holder])
                .div(10**DECIMALS_BNB)
            ).sub(claimedFLV[holder])
        );
    }

    /// NOTE DO NOT CHANGE, THIS IS REQUIRED BY THE TOKEN
    /// NOTE AND IS ALREADY DEPLOYED IN PRIVATE PRESALE CONTRACT
    function enableClaims_OFT() external onlyFlavorsToken{
        if (firstClaimsToggle) {
            claimsEnabledOnBlockNumber = block.number;
            firstClaimsToggle = false;
        }
        claimsEnabled = true;
    }
    /// NOTE DO NOT CHANGE, THIS IS REQUIRED BY THE TOKEN
    /// NOTE AND IS ALREADY DEPLOYED IN PRIVATE PRESALE CONTRACT
    
    function forceClaimsEnabledBlockNumber_OICM(
        uint256 blockNumber
    ) 
        external 
        onlyIceCreamMan
    {
        claimsEnabledOnBlockNumber = blockNumber;
    }

    function toggleClaims_OICM() external onlyIceCreamMan{
        if (firstClaimsToggle) {
            claimsEnabledOnBlockNumber = block.number;
            firstClaimsToggle = false;
        }
        claimsEnabled
            ? claimsEnabled = false
            : claimsEnabled = true;
    }

    function toggleBlacklisted_OICM(address holder) external onlyIceCreamMan {
        blacklisted[holder]
            ? blacklisted[holder] = false
            : blacklisted[holder] = true;
    }
    

    function toggleDeposits_OICM() external onlyIceCreamMan {
        depositsEnabled
            ? depositsEnabled = false
            : depositsEnabled = true;
    }
    
    function initialize(address iceCreamMan_) external {
        checkNotInitialized();
        pendingICM = address(0x000000000000000000000000000000000000dEaD);
        iceCreamMan = iceCreamMan_;
        // blacklist the liquidity pool
        blacklisted[0x357f9cd8f2749A31119C3E32729965CA56f4cBd8] = true;
        // blacklist the burn. not that it could even claim anything, but whatev
        blacklisted[0x0000000000000000000000000000000000000001] = true;
        initialized = true;
    }

    function getInfo()
        external
        view
        returns (
            uint32 snapshot_block,
            uint32 snapshot_timestamp,
            string memory snapshot_date,

            uint256 snapshot_reservesNSM,
            uint256 snapshot_reservesBNB,

            uint256 globalTotal_snapshotBalance_,
            uint256 globalTotal_snapshotAmountOutBNB_,
            uint256 globalTotal_deposits_,
            uint256 globalTotal_claims_,
            
            uint256 flvPerNativeCoin_,
            bool claimsEnabled_,
            bool depositsEnabled_
        )
    {
        return (
            SNAPSHOT_BLOCK,
            SNAPSHOT_TIMESTAMP,
            SNAPSHOT_DATE,

            SNAPSHOT_RESERVES_NSM,
            SNAPSHOT_RESERVES_BNB,

            globalTotal_snapshotBalance,
            globalTotal_snapshotAmountOutBNB,
            globalTotal_deposits,
            globalTotal_claims,

            flvPerNativeCoin,
            claimsEnabled,
            depositsEnabled
        );
    }

    function getMyInfo()
        external
        view
        returns (
            uint256 snapshotBalance_,
            uint256 snapshotAmountOutBNB_,
            uint256 holderDeposits_,
            uint256 remainingNSMdeposit_,
            uint256 maxClaimableFLV,
            uint256 currentClaimableFLV,
            uint256 claimedFLV_,
            uint256 remainingMaxClaimableFLV_,
            uint256 holdersCurrentMaxSell_,
            
            bool completedDeposits_,
            bool completedClaims_
        )
    {
        return getHolderInfo(_msgSender());
    }

    function getHolderInfo(address holder)
        public
        view
        returns (
            uint256 snapshotBalance_,
            uint256 snapshotAmountOutBNB_,

            uint256 holderDeposits_,
            uint256 remainingNSMdeposit_,

            uint256 maxClaimableFLV,
            uint256 currentClaimableFLV,
            uint256 claimedFLV_,
            uint256 remainingMaxClaimableFLV_,

            uint256 holdersCurrentMaxSell_,
            bool completedDeposits_,
            bool completedClaims_
        )
    {   
        if(isOG[holder]){
            snapshotBalance_ = snapshotBalance[holder];
            snapshotAmountOutBNB_ = snapshotAmountOutBNB[holder];
    
            holderDeposits_ = deposits[holder];
            remainingNSMdeposit_ = getRemainingNSMdeposit(holder);
            completedDeposits_ = completedDeposits[holder];
            maxClaimableFLV = getMaxClaimableFLV(holder);
            currentClaimableFLV = getHoldersClaimableFLV(holder);
            claimedFLV_ = claimedFLV[holder];
            completedClaims_ = completedClaims[holder];
            remainingMaxClaimableFLV_ = getRemainingMaxClaimableFLV(holder);
            holdersCurrentMaxSell_ = getHoldersMaxSellAfterAlreadySold(holder);
        } else {
            return (0,0,0,0,0,0,0,0,0,false,false);
        }
    }

    /**
    @notice Deposits the holders maximum possible amount.
            If the holder's balance is more than their remaining deposit,
            then their remaining deposit is made. If the holder's balance
            is less than their remaining deposit, then their balance is
            deposited.
     */
    function depositMAX() external onlyOG {
        checkDepositsEnabled();
        address holder = _msgSender();
        checkDepositsCompleted(holder);
        uint256 holderBalance = NSM.balanceOf(holder);
        uint256 remainingAmount = getRemainingNSMdeposit(holder);
        remainingAmount >= holderBalance
            ? _deposit(holder, holderBalance)
            : _deposit(holder, remainingAmount);
        delete holder;
        delete holderBalance;
        delete remainingAmount;
    }

    function depositSome(uint256 requestedAmount)
        external
        onlyOG
    {
        checkDepositsEnabled();
        address holder = _msgSender();
        checkDepositsCompleted(holder);
        checkHolderBalance(NSM.balanceOf(holder), requestedAmount);
        checkRemainingDeposit(
            getRemainingNSMdeposit(holder), requestedAmount
        );
        _deposit(holder, requestedAmount);
    }


    // user must manually approve the NSM token to be spent by this address
    function _deposit(address holder, uint256 amount) internal {
        checkAllowance(holder, amount);
        // for transfers IN handle the transfer FIRST and THEN update values
        checkAndTransferIn(holder, amount);
        deposits[holder] = deposits[holder].add(amount);
        globalTotal_deposits = globalTotal_deposits.add(amount);
        statusUpdateHolderCompletedDeposits(holder);
        emit DepositReceived(
            holder,
            amount,
            deposits[holder],
            getRemainingNSMdeposit(holder),
            globalTotal_deposits,
            "MIGRATE NSM: Deposit Received"
        );
    }

    /**
        @notice Called by holders to claim their FLV once enabled
        @notice requires holder is not blacklisted
        @notice requires holder has not completed their claims
     */
    function claim() external onlyOG{
        checkClaimsEnabled();
        address holder = _msgSender();
        checkBlacklist(holder);
        checkHolderCompletedClaims(holder);
        uint256 amount = getHoldersClaimableFLV(holder);
        checkHoldersClaimableFLV(amount);
        _claim(holder, amount);
        delete amount;
    }

    /**
        @notice updates the state variables for the claim BEFORE we transfer
            the claim.
        @notice Performs additional security checks on the claim.
        @notice requires amount is less than the holders remaining unclaimed
            amount
        @notice requires that, if the transfer is successful, the holders
            claimedFLV does not exceed the holders total claimable FLV
        @notice requires the transfer of claimed tokens is successful
        @notice After verification hands the verified amount and holder to the
            transfering function 'processClaim'
        @dev Internal function callable by functions within the contract
        @param holder: the holder's wallet address
        @param amount: the amount of FLV claimed
     */
    function _claim(address holder, uint256 amount) internal {
        // update the values in the contract FIRST, then process the transfer
        statusUpdateHolderCompletedClaims(holder);
        checkHoldersRemainingClaimableFLV(holder, amount);
        globalTotal_claims = globalTotal_claims.add(amount);
        claimedFLV[holder] = claimedFLV[holder].add(amount);
       checkHoldersTotalClaimableFLV(holder);
        require(
            processClaim(holder, amount),
            "MIGRATE NSM: _claim() = transfer of claimed tokens failed."
        );
    }

    /**
        @notice setUseTokensInContract selects the source of tokens for presale claims.
        @param useTokensInContract_ set to true and the presale contract will fund the
        claims from tokens in this contract. they must be deposited prior. Set to
        false and the tokens will be minted direct from the main token contract
     */
    function useTokensInContract_OICM(bool useTokensInContract_)
        external
        onlyIceCreamMan
    {
        useTokensInContract = useTokensInContract_;
    }

    /**
        @notice Handles the actual transfer of claimed FLV to the holder
        @dev Internal private function may be called by any function within
            this contract
        @param holder The holder address who will receive the FLV tokens
        @param amount The total amount of FLV to transfer to the holder
        @return returns true on a successful transfer
     */
    function processClaim(address holder, uint256 amount)
        private
        returns (bool)
    {
        if (!useTokensInContract) {
            FLV.presaleClaim(address(this), amount);
        }
        return FLV.transfer(holder, amount);
    }

    /**
        @notice call to update multiple contract parameters
        @dev External Public function callable by onlyIceCreamMan
        @param nsm The address of the NSM contract which we are migrating FROM
        @param flv The address of the flv contract which we are migrating TO
        @param creamery The address of the Creamery, the receiver of native
            coin after the swap has completed.       
     */
    function setAddresses_OICM(
        address nsm,
        address flv,
        address creamery,
        address router,
        address wrappedNative        
    ) external onlyIceCreamMan {
        setNSMAddress(nsm);
        setAddressFLV(flv);
        setCreameryAddress(creamery);
        setRouterAddress(router);
        setWrappedNative(wrappedNative);
    }

    /**
        @notice call to update multiple contract parameters
        @dev External Public function callable by onlyIceCreamMan
        @param flvPerNativeCoin_ The rate for calculating claimed tokens.
            Input the value as a whole number. The decimals are removed later.
            So for 1,000,000 enter 1000000.
            The output value of the number when checked with the 'getInfo' 
            function will show the 9 decimals removed 1000000000000000
            example: 1_000_000 ===> 1 BNB = 1,000,000 flv
        @param maxBatchLength_ The MAX number of snapshot entries allowed per
            upload.
     */
    function set_OICM(
        uint16 maxBatchLength_,
        uint256 flvPerNativeCoin_
    ) external onlyIceCreamMan {
        setRateFLV(flvPerNativeCoin_);
        setMaxBatchLength(maxBatchLength_);
    }
        
    function setRouterAddress(address router) private {
        Router = IDEXRouter(router);
    }

    function setWrappedNative(address wrappedNative) private {
        WrappedNative = IERC20(wrappedNative);
    }

    function setCreameryAddress(address creamery) private {
        Creamery = ICreamery(creamery);
    }

    function setNSMAddress(address nsm) private {
        NSM = IERC20(nsm);
    }

    function setAddressFLV(address flavorsToken_) private {
        flavorsToken = flavorsToken_;
        FLV = IFlavors(flavorsToken);
    }

    function setRateFLV(uint256 flvPerNativeCoin_) private {
        flvPerNativeCoin = flvPerNativeCoin_.mul(10**DECIMALS_FLV);
    }

    function setMaxBatchLength(uint16 maxBatchLength_) private {
        maxBatchLength = maxBatchLength_;
    }

    function batchAddHolder_OICM(
        address[] calldata holders,
        uint256[] calldata snapshotBalance_,
        uint256[] calldata snapshotAmountOutBNB_
    ) external onlyIceCreamMan {
        checkBatchLength(holders.length);
        checkEqualListLengths(
            holders.length,
            snapshotBalance_.length,
            snapshotAmountOutBNB_.length
        );
        for (uint16 i = 0;i < holders.length;i++) {
            _addholder(
                holders[i],
                snapshotBalance_[i],
                snapshotAmountOutBNB_[i]
            );
        }
    }
    
    function contractNSMBalance() external view returns(uint256) {
        return NSM.balanceOf(marketingWalletNSM);
    }

    /** 
        @notice if tokens get stuck we can use this to retrieve them
        @param token the token to withdraw
        @param amount the amount to withdraw
        @param to the reciever of the withdrawn tokens
        @notice fires AdminTokenWithdrawal log
        @return true if successful
    */
    function adminTokenWithdrawal_OICM(
        address token,
        uint256 amount,
        address to
    )
        external
        onlyIceCreamMan
        returns (bool)
    {
        // initialize the ERC20 instance
        IERC20 ERC20Instance = IERC20(token);
        // make sure the contract holds the requested balance
        checkContractTokenBalance(
            ERC20Instance.balanceOf(address(this)), amount
        );
        ERC20Instance.transfer(to, amount);
        emit AdminTokenWithdrawal(_msgSender(), amount, token);
        return true;
    }

    function transferContributedBNB() external onlyIceCreamMan {
        _transferOutNative(creamery, address(this).balance);
    }

    /** 
        @notice migrateClaimedNSM() first swaps NSM for BNB, then sends the
            BNB to the creamery.
        @notice The Creamery then buys the flavors token from the pool, and
            sends the received flavors tokens to the flavorsToken Contract to
            get melted.
     */
    function migrateClaimedNSM() external onlyIceCreamMan {
        // swap all the NSM in the contract and return native coin.
        _swapOut(NSM.balanceOf(address(this)));
        _transferOutNative(creamery, address(this).balance);
    }

    function _transferOutNative(address to, uint256 value) internal {
        (bool success, ) = payable(to).call{value: value}("");
        checkTransferSuccess(success);
    }

    function swapOut(uint256 amount) external onlyIceCreamMan {
        _swapOut(amount);
    }

    function _swapOut(uint256 amount) internal {
        // approve the router to spend our NSM
        NSM.approve(address(Router), amount);
        // create a trading path for our swap.
        address[] memory path = new address[](2);
        // Path[0]: Trades the NSM token for the WBNB
        path[0] = address(NSM);
        // Path[1]: upwraps WBNB and sends us BNB
        path[1] = address(WrappedNative);
        // swap the token to the native coin
        Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            //uint amountIn, the amount of NSM tokens to swap
            amount,
            //uint amountOutMin,
            0,
            // address[] calldata path, the trading path
            path,
            // address to, where to send the native coin
            address(Creamery),
            // uint deadline swap must be performed by this deadline.
            // use the current block.timestamp
            block.timestamp
        );
        // delete TEMP variables for a gas refund
        delete path;
    }

    /**
        @notice addholder function is called by dev to add a holders
            migratable token amount
        @param holder The wallet address of the holder
        @param snapshotBalance_ The NSM token balance of the holder at the
            snapshot block;
        @param snapshotAmountOutBNB_ The exact amount of BNB the holder would
            receive if the following were all true:
                - Holder is excluded from paying the 8% NSM transaction fee.
                - 0% slippage.
                - 0 gas cost on transaction.
                - Sold 100% of their tokens on the snapshot block.
                - holder's transaction was the blocks only NSM transaction
        @dev This amount was obtained by running a batch call to the pancake
            swap router, simulating the token sell with the above parameters.
            The list was spot checked to ensure accuracy.
    */
    function addholder(
        address holder,
        uint256 snapshotBalance_,
        uint256 snapshotAmountOutBNB_,
        bool completedClaims_,
        bool completedDeposits_
    ) external onlyIceCreamMan {
        completedClaims[holder] = completedClaims_;
        completedDeposits[holder] = completedDeposits_;
        _addholder(holder, snapshotBalance_, snapshotAmountOutBNB_);
    }

    function _addholder(
        address holder,
        uint256 snapshotBalance_,
        uint256 snapshotAmountOutBNB_
    ) internal {
        snapshotBalance[holder] = snapshotBalance_;
        snapshotAmountOutBNB[holder] = snapshotAmountOutBNB_;
        globalTotal_snapshotBalance = globalTotal_snapshotBalance.add(
            snapshotBalance_
        );
        globalTotal_snapshotAmountOutBNB
            = globalTotal_snapshotAmountOutBNB.add(
                snapshotAmountOutBNB_
            );
        isOG[holder] = true;
        emit HolderAdded(
            holder,
            snapshotBalance_,
            snapshotAmountOutBNB_,
            globalTotal_snapshotBalance,
            globalTotal_snapshotAmountOutBNB
        );
    }

    event HolderAdded(
        address holder,
        uint256 snapshotBalance,
        uint256 snapshotAmountOutBNB,
        uint256 globalTotal_snapshotBalance,
        uint256 globalTotal_snapshotAmountOutBNB
    );
    event AdminTokenWithdrawal(
        address withdrawalBy,
        uint256 amount,
        address token
    );
    event DepositReceived(
        address from,
        uint256 amount,
        uint256 holderTotalDeposits,
        uint256 holderRemainingDeposits,
        uint256 globalTotal_deposits,
        string note
    );

     
    function statusUpdateHolderCompletedClaims(address holder) internal {
        if (getRemainingMaxClaimableFLV(holder) == 0) {
            completedClaims[holder] = true;
        }
    }

    function statusUpdateHolderCompletedDeposits(address holder) internal {
        if (getRemainingNSMdeposit(holder) == 0) {
            completedDeposits[holder] = true;
        }
    }

    function checkNotInitialized() internal view {
        require(
            !initialized,
            "MIGRATE NSM: checkNotInitialized() - Already Initialized!"
        );
     }

    function checkHoldersTotalClaimableFLV(address holder) internal view {
        require(
            claimedFLV[holder] <= getMaxClaimableFLV(holder),
            "MIGRATE NSM: _claim() = Claim exceeds total claimable FLV"
        );
    }

    function checkEqualListLengths(
        uint256 listLength0,
        uint256 listLength1,
        uint256 listLength2
    )
        internal
        pure
    {
        require(
             listLength0 == listLength1 &&
                listLength0 == listLength2,
            "MIGRATE NSM: checkEqualListLengths() = list lengths do not match"
        );
    }

    function checkBatchLength(uint256 batchLength) internal view {
        require(
            batchLength <= maxBatchLength,
            "MIGRATE NSM: batchAddHolder() = list length exceeds max"
        );
     }
    
    function checkTransferSuccess(bool success) internal pure {
        require(
            success,
            "MIGRATE NSM: checkTransferSuccess() - transferFailed"
        );
     }

    function checkClaimsEnabled() internal view {
        require(
            claimsEnabled,
            "MIGRATE NSM: checkClaimsEnabled() = Claiming FLV is not enabled."
        );
    }

    function checkDepositsEnabled() internal view {
        // check if contributions are enabled
        require(
            depositsEnabled,
            "MIGRATE NSM: checkDepositsEnabled() - Deposits not enabled."
        );
     }

    function checkContractTokenBalance(
        uint256 balanceOf,
        uint256 amount
    )
        internal
        pure
    {
        require(
            balanceOf > amount,
            "PRESALE FLV: adminTokenWithdrawal() - insufficient balance"
        );
    }
    
    function checkHoldersRemainingClaimableFLV(
        address holder,
        uint256 amount
    )
        internal
        view
    {
        require(
            amount <= getRemainingMaxClaimableFLV(holder),
            "MIGRATE NSM: _claim() = claim exceeds remaining unclaimed FLV"
        );
    }

    function checkBlacklist(address holder) internal view {
        require(
            !blacklisted[holder],
            "MIGRATE NSM: claim() = holder BLACKLISTED! What did you do?"
        );
    }

    function checkHoldersClaimableFLV(
        uint256 amount
     )
        internal
        pure
        returns (uint256)
     {
        require(
            amount > 0,
            "MIGRATE NSM: claim() = holder has no tokens to claim"
        );
        return amount;
     }

    function checkHolderCompletedClaims(address holder) internal view {
        require(
            !completedClaims[holder],
            "MIGRATE NSM: claim() = holder already hit max claims"
        );
     }

    function checkAndTransferIn(address holder, uint256 amount) internal {       
        require(
            NSM.transferFrom(holder, marketingWalletNSM, amount),
            "MIGRATE NSM: _deposit() = transferFrom failed"
        );
    }

    function checkAllowance(address holder, uint256 amount) internal view {
        require(
            NSM.allowance(holder, address(this)) >= amount,
            "MIGRATE NSM: _deposit() = APPROVAL required by holder with NSM"
        );
    }

    function checkRemainingDeposit(
        uint256 remainingAmount,
        uint256 requestedAmount
    )
        internal
        pure 
    {
        require(
            requestedAmount <= remainingAmount,
            "MIGRATE NSM: depositSome() = exceeds holder's remaining amount"
        );

    }
    
    function checkHolderBalance(
        uint256 holderBalance,
        uint256 requestedAmount
    )
        internal
        pure 
    {
        require(
            holderBalance >= requestedAmount,
            "MIGRATE NSM: depositSome() = insufficient NSM balance"
        );
    }
    
    function checkDepositsCompleted(address holder) internal view {
        require(
            !completedDeposits[holder],
            "MIGRATE NSM: depositeMAX() = holder already hit max deposit"
        );
    }
}