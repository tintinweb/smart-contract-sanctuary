// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

 import "./interface/compound/Comptroller.sol";
 import "./interface/compound/CErc20.sol";
 import "./interface/compound/CEther.sol";
 import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";
 
contract IDXCompVault is Ownable{

    /**
       this contract is owned my IDXYS 
       The function to interface

       deposit(asset,amount)
       withdraw(asset,amount)

       Borow
       Repay
     */

    using SafeMath for uint;

    //address payable owner;                // owned by IDXYS contract
    address admin;                        // the admistrator is the deployer
    address constant ETHER = address(0);
    uint256  protocolFees;
 
    // COMPOUND COMPTROLLER
    // mainnet 0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b
    // kovan 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
    // Rinkeby 0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb

    address comptrollerAddress = 0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb;
    Comptroller comptroller = Comptroller(comptrollerAddress);
    
    // maping the asset to it's collateral
    mapping(address => address) public collaterals;
    mapping(address => mapping(address => uint256)) public collateralBalances;                               // user => cAsset => balance in collateral
    mapping(address => mapping(address => uint256)) public underlyingBalances;                               // user => asset => balance in Underlying


       /// @notice Modifier Basic security
    /// @dev  
    modifier onlyAdmin() {
        require(msg.sender == admin, "Owner?");
        _;
    }
                                      
    /// @notice CONSTRUCTOR
    /// @dev 
    /// @param _protocolFees uint the protocol fees
   
   
    constructor(uint256 _protocolFees) {
    
        admin = msg.sender;                                 
        protocolFees = _protocolFees;  

    }
                                                
    /// @notice COMPOUND DEPOSIT.
    /// @dev Called by IDXYS
    /// @param _asset adresse of ERC20 asset
    /// @param _amount The amount to deposit

    function deposit(address _asset, uint256 _amount) external payable onlyOwner {
        uint256 balanceB;                                                                                    // the balance of underlying before
        uint256 balanceA;                                                                                    // the balance of underlying after
        address _cToken = collaterals[_asset];                                                               // return the collateral asset address        DAI => cDai                                                                     
        if(_asset == ETHER){
            CEther cToken = CEther(_cToken);
            balanceB = cToken.balanceOf(address(this));
            cToken.mint{value : msg.value }(); 
            balanceA = cToken.balanceOf(address(this));
        }else {
            IERC20 underlying = IERC20(_asset);                                                              // get a handle for the underlying asset contract
            CErc20 cToken = CErc20(_cToken);                                                                 // get a handle for the corresponding cToken contract
            balanceB = cToken.balanceOf(address(this));                                                      // the balance of collateral before
            underlying.approve(address(cToken), _amount);                                                    // approve the transfer
                                                              
            assert(cToken.mint(_amount) == 0);                                                               // mint the cTokens and assert there is no error
            balanceA = cToken.balanceOf(address(this));                                                      // the balance of collateral before
        }
        uint256 userAmount = balanceA.sub(balanceB);                                                         // the balance of the user in collaterall                                                      
        underlyingBalances[tx.origin][_asset] = collateralBalances[tx.origin][_asset].add(_amount);          // ajust balance in underlying token
        collateralBalances[tx.origin][_cToken] = collateralBalances[tx.origin][_cToken].add(userAmount);     // ajust balance in collateral token  
    }
    
    /// @notice COMPOUND WITHDRAW 
    /// @dev Will withdraw what ever balance the user have
    /// @param _asset CToken address

    function withdrawPosition(address _asset) external onlyOwner {
        uint256 balanceB;                                                                                    
        uint256 balanceA;  
        address _cToken = collaterals[_asset];                                                                                                                                                         
      //  uint256 pTokenAmount = pBalances[msg.sender][_cToken];                                                                                                                                                                                                                     
        if(_asset == ETHER){    
            balanceB = address(this).balance;                                                                
            CEther cToken = CEther(_cToken);
            uint256[] memory TX = _Computation(_asset);
            cToken.approve(address(cToken), TX[0]);                        
            require(cToken.redeem(TX[4]) == 0, "CEther Withdraw?");                             
            balanceA = address(this).balance;  
            require(balanceA.sub(balanceB) == TX[1]);
            underlyingBalances[tx.origin][_asset] = 0;                                                           
            collateralBalances[tx.origin][_cToken] = 0; 
            collateralBalances[address(this)][_cToken].add(TX[2]);                                                           
            payable(tx.origin).transfer(TX[1]);
       
        }else {                                                                                 
                                                               
            CErc20 cToken = CErc20(_cToken);
            IERC20 asset = IERC20(_asset);
            balanceB = asset.balanceOf(address(this)); 
            uint256[] memory TX = _Computation(_asset);
            cToken.approve(address(cToken),TX[0]);                                    
            require(cToken.redeem(TX[4]) == 0, "CToken Withdraw?");
            balanceA = asset.balanceOf(address(this)); 
            require(balanceA.sub(balanceB) == TX[1]);                  
            underlyingBalances[tx.origin][_asset] = 0;               
            collateralBalances[tx.origin][_cToken] = 0; 
            collateralBalances[address(this)][_cToken].add(TX[2]);     
            asset.transfer(tx.origin, TX[1]);
            
        }
            // need safety for eventual rounding error    
    }

    
    /// @notice Compute the transaction on the full position based on the user balance.
    /// @dev This function is for the full position withdrawmax

    function _Computation(address _asset) internal view returns (uint256[] memory ){
       
        address _cToken = collaterals[_asset]; 
        CErc20 token = CErc20(_cToken);
        uint256 rate = token.exchangeRateStored();                                          // rate from Compound
        //get the rate for this amount of underlying asset
        //uint256 collateralAmount =  underlyingBalances[tx.origin][_asset].mul(1e18).div(rate);    // is in collaterall
        uint256 underlyingAmount = rate.mul(collateralBalances[tx.origin][_asset]).div(1e18);     // the total position value  
        uint256 profit = underlyingAmount.sub(underlyingBalances[tx.origin][_asset]); 
        // the profit expressed in collaterall but this amount also have gained so we need to decreasse it by the gain quotien
        uint256 collateralProfit = profit.mul(1e18).div(rate); 
        // we apply fees on the profit and leave them on the protocol.  
        uint256 fees = (collateralProfit.div(10000)).mul(protocolFees);    
        uint256 gainQuotient = quotient(underlyingBalances[tx.origin][_asset],underlyingAmount,18);
        uint256 feesAdjusted = fees.mul(gainQuotient).div(1e18);
        uint256 withdrawn = collateralBalances[tx.origin][_asset].sub(feesAdjusted);
        // fees recorded                      
       // collateralBalances[address(this)][_asset] = collateralBalances[address(this)][_asset].add(feesAdjusted);
        //The amount of dai we will sent back is what we ge from  the pamount after fees

        
        // returned data
        uint256[] memory txData  = new uint256[](4);
        txData[0] =  collateralBalances[tx.origin][_asset];   // the balance                                 
        txData[1] =  underlyingAmount;                        // the underlying asset with interest                                       
        txData[2] =  feesAdjusted; 
        txData[3] =  withdrawn; 
        return txData;   
    }

    /// @notice WITHDRAW ERC AMOUNT.
    /// @dev To be used to withdraw an amount lower than the balance 
    /// @param _asset CToken address
    /// @param _amount Must be Ctoken amount with 8 decimals

    function _withdrawUnderlying(address _asset,uint256 _amount) internal  {
        address _cToken = collaterals[_asset]; 
        CErc20 cToken = CErc20(_cToken);

        /// same check the fees.
        require(cToken.redeemUnderlying(_amount) == 0, "ERC Withdraw?");
    }

    /// @notice Borrowing.
    /// @param _asset the asset to borrow
    /// @param _amount the asset to borrow

         function borrow(address _asset, uint256 _amount) public onlyOwner{
           
    }

    /// @notice RepayBorrow.
    /// @param _asset the asset to borrow
    /// @param _amount the asset to borrow

         function repayBorrow(address _asset, uint256 _amount) public onlyOwner{
           
    }


    /// @notice CLAIM COMP TOKEN.
    /// @param _holder Must be Ctoken amount with 8 decimals

    function _claimComp(address _holder) public onlyOwner{
       
        comptroller.claimComp(_holder);
    }

    /// @notice ENTER COMPOUND MARKET.
    /// @param _asset The collatereral token address

    function _enterCompMarket(address _asset) public onlyAdmin {
        address _cToken = collaterals[_asset];
        address[] memory cTokens = new address[](1);                                                                                 
        //  entering MArket with ctoken
        cTokens[0] = _cToken;
        uint[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0);
    }

    /// @notice EXIT COMPOUND MARKET.
    /// @param _cToken Exiting market for unused asset will lower the TX cost with Compound

    function _exitCompMarket(address _cToken) public onlyAdmin {                                                                             
        uint256 errors = comptroller.exitMarket(_cToken);
        require(errors == 0,"Exit CMarket?");
    }

    /// @notice SET VAULT FEES.
    /// @param fees the fees in %  

    function setFees(uint256 fees) public onlyOwner {                                                                             
       protocolFees = fees;
    }

    /// @notice SET VAULT COLLATERALS
    /// @param _asset the underlying address  
    /// @param _collateral the collateral asset address 

    function setCollaterals(address _asset, address _collateral) public onlyAdmin {                                                                             
      collaterals[_asset] = _collateral;
    }

    /// @notice returns a quotient
    /// @dev this function assumed you checked the values already 
    /// @param numerator the amount filled
    /// @param denominator the amount in order 
    /// @param precision the decimal places we keep
    /// @return _quotient

    function quotient(uint256 numerator, uint256 denominator, uint256 precision) pure public  returns(uint256 _quotient) {
        uint256 _numerator  = numerator * 10 ** (precision+1);
        _quotient =  ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    /// @notice returns the balance of the pool
    /// @dev
    /// @param asset the asset address

    function balance(address _asset) public view returns(uint256){
        address _cToken = collaterals[_asset];
        CErc20 cToken = CErc20(_cToken);
        return  cToken.balanceOfUnderlying(address(this));
    }

    /// @notice returns the balance of the user
    /// @dev
    /// @param _user the user address
    /// @param _asset the asset address

    function balanceOf(address _user,address _asset) public view returns(uint256){
        address _cToken = collaterals[_asset];
        CErc20 cToken = CErc20(_cToken);
        uint256 rate = cToken.exchangeRateStored();                                          // rate from Compound
        //get the rate for this amount of underlying asset
        //uint256 collateralAmount =  underlyingBalances[tx.origin][_asset].mul(1e18).div(rate);    // is in collaterall
        return rate.mul(collateralBalances[_user][_cToken]).div(1e18);     // the total position value  
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface CErc20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function underlying() external view returns (address);

    function getCash() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external view returns (uint);

    function totalSupply() external view returns (uint);

    function totalReserves() external view returns (uint);

    function exchangeRateCurrent() external view returns (uint);

    function balanceOfUnderlying(address account) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface CEther {
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint() external payable;

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow() external payable;

    function getCash() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external view returns (uint);

    function totalSupply() external view returns (uint);

    function totalReserves() external view returns (uint);

    function exchangeRateCurrent() external view returns (uint);

    function balanceOfUnderlying(address account) external view returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Comptroller {

    function enterMarkets(address[] calldata) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint);

    function claimComp(address holder) external;

    function getAssetsIn(address account) external view returns (address[] memory);

    function markets(address cTokenAddress) external view returns (bool, uint, bool);

    function getAccountLiquidity(address account) external view returns (uint, uint, uint);

    function liquidationIncentiveMantissa() external view returns (uint);

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
    constructor () {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

