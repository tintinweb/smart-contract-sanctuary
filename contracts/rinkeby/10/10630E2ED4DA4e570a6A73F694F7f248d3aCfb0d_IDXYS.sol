// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

 import "./interface/IDXVault.sol";
 

 import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";

contract IDXYS is Ownable{
    using SafeMath for uint;

    address constant ETHER = address(0);
    //address payable owner;                                                      // the owner is the deployer iDX

    // iDX Vault Contract records
    
   // mapping(address => uint256) public tier;                                    // user => tier
    uint256 public vaultCount;                                                         // a counter for the vaults
    mapping(uint256 => _Vaults) public idxVault;                                // vaultID => vaultStruct
    mapping(uint256 => mapping(address => bool)) assetInVault;                  // VaultID => asset => true

    struct _Vaults{ 
        uint256 id;                                                             // ID of the Vault mostly for UI
        uint256 tier;                                                           // Vault tier acess
        address addr;                                                           // the contract adresses
    }

    // iDX Vault Contract records

    uint256 public assetCount;                                                  // asset counter
    mapping(uint256 => _Assets) public assets;                                  // asset map to struct                       
    mapping(address => bool) public assetRegistered;                            // check if an asset is registered
  
    event Assets(
        uint256 id,                    
        address addr,            
        bool active 
    );

    struct _Assets{
        uint256 id;
        address addr;                                                
        bool active;                                                         
    }

    mapping(address => bool) public userRegistered;                                    // when set to true the user is allowed to use the contract
    mapping(address => uint256) public userTier;                                       // the user tier

    event Deposit(uint256 assetId, uint256 amount,uint256 vault,address user);   
    event WithdrawPosition(uint256 assetId,uint256 vault,address user);
     
    constructor(){
       // owner = payable(msg.sender);                // on deployment, the deployer own the contract. It couls be transfered to another controller when implementing V2  
    }

    /// @notice iDX Deposit 
    /// @dev Deposit an amount of an asset to a vault
    /// @param assetId the id based on the asset struct
    /// @param assetAmount the amount deposited
    /// @param vaultId the id of the vault

    function deposit(uint256 assetId, uint256 assetAmount, uint256 vaultId) public payable {
        _Assets memory asset = assets[assetId]; 
        _Vaults memory vault = idxVault[vaultId];
        IERC20 token = IERC20(asset.addr);
        IDXVault Currentvault = IDXVault(vault.addr);  
        require(asset.active, "Pool disabled!");                                                                    // require that the pool is active
        require(assetInVault[vaultId][asset.addr], "Wrong Vault!");                                                 // require that the asset is in the vault
        require(userTier[msg.sender] >= vault.tier, "Wrong Tier!");                                                     // require that this user have acces to this vault
        
     

        if(asset.addr == ETHER){
          payable(vault.addr).transfer(address(this).balance); 
        }
        else{
          require(token.transferFrom(msg.sender, vault.addr, assetAmount),'Available Funds?'); 
        }
      
        Currentvault.deposit{value:msg.value}(asset.addr, assetAmount);

        emit Deposit(assetId, assetAmount, vaultId,msg.sender);
    }

    /// @notice iDX withdrawPosition
    /// @dev Deposit an amount of an asset to a vault
    /// @param assetId the id based on the asset struct
    /// @param vaultId the id of the vault

    function withdrawPosition(uint256 assetId, uint256 vaultId) public payable {
        _Assets memory asset = assets[assetId]; 
        _Vaults memory vault = idxVault[vaultId];
        IDXVault Currentvault = IDXVault(vault.addr);  
        require(asset.active, "Pool disabled!");                                                                    // require that the pool is active
        require(assetInVault[vaultId][asset.addr], "Wrong Vault!");                                                 // require that the asset is in the vault
        require(userTier[msg.sender] >= vault.tier, "Wrong Tier!");                                                     // require that this user have acces to this vault
        Currentvault.withdrawPosition(asset.addr);
        emit WithdrawPosition(assetId, vaultId,msg.sender);
    }

    /// @notice Register and unregister Assets
    /// @dev We check if true on deposit

    function registerAsset(address _asset) public onlyOwner{
      require(!assetRegistered[_asset],'Asset Present ?');
         assetRegistered[_asset] = true;
        _Assets storage _newAsset = assets[assetCount];
        _newAsset.id = assetCount;
        _newAsset.addr = _asset;
        _newAsset.active = true;                
        assetCount = assetCount.add(1);
      
    }

    /// @notice Register and unregister Assets
    /// @dev We check if true on deposit
    /// @param _assetId the asset to remove from the protocol
    function unRegisterAsset(uint256 _assetId) public onlyOwner{
        _Assets storage asset = assets[_assetId]; 
        assetRegistered[asset.addr] = false;
        asset.active = false;
    }

    /// @notice Register a user
    /// @dev also asign a tier to that user on registration

    function registerUser(address _address, uint256 _tier) public onlyOwner{
        userRegistered[_address] = true;
        userTier[_address] = _tier; 
    }

    /// @notice UnRegister a user
    /// @dev will revoke access to the vaults.

    function unRegisterUser(address _address) public onlyOwner{
        userRegistered[_address] = false;
    }

    /// @notice Set protocol Fees 
    /// @dev Can be called on each vault.
    /// @param _protocolFees in base 002 

    function setProtocolFees(uint256 vaultId,uint256 _protocolFees) public onlyOwner{
        _Vaults memory vault = idxVault[vaultId];
        IDXVault Currentvault = IDXVault(vault.addr); 
        Currentvault.setFees(_protocolFees);
    }

    /// @notice Set protocol Fees 
    /// @dev Can be called on each vault.
    /// @param vaultContract the address of the vault contract
    /// @param vaultTier the address of the vault contract



    function addVault(address vaultContract, uint256 vaultTier) public onlyOwner{
        _Vaults storage vault = idxVault[vaultCount];
        vault.addr = vaultContract;
        vault.id = vaultCount;
        vault.tier = vaultTier;
        vaultCount = vaultCount.add(1);
    }

    function addAssetToVault(uint256 _vaultId,address _asset)public onlyOwner{
     assetInVault[_vaultId][_asset] = true;

    }
  


    function balance(uint256 vaultID, uint256 assetId) public view returns(uint256){
         _Vaults memory vault = idxVault[vaultID];
        _Assets memory asset = assets[assetId];
        IDXVault Currentvault = IDXVault(vault.addr); 
        return Currentvault.balance(asset.addr);
    }

    function balanceOf(uint256 vaultID, uint256 assetId, address user)public view returns(uint256){
        _Vaults memory vault = idxVault[vaultID];
        _Assets memory asset = assets[assetId];
        IDXVault Currentvault = IDXVault(vault.addr); 
        return Currentvault.balanceOf(user, asset.addr);

    }







}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


interface IDXVault {

      function deposit(address asset,uint256 amount) external payable;
      function balance(address asset) external view returns(uint256);
      function balanceOf(address user,address asset)external view returns(uint256);
      function withdrawPosition(address asset) external;
      function setFees(uint256 fees) external;
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