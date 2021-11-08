/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder/SafeKeep/contracts/SafeKeep.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder/SafeKeep/contracts/SafeKeep.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder/SafeKeep/contracts/SafeKeep.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT


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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder/SafeKeep/contracts/SafeKeep.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder/SafeKeep/contracts/SafeKeep.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT


////import "../utils/Context.sol";

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


/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder/SafeKeep/contracts/SafeKeep.sol
*/

//SPDX-License-Identifier: Unlicense
//2021 Safekeep Finance v1


//////import "hardhat/console.sol";
//////import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/utils/math/SafeMath.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SafeKeep is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    //using SafeERC20 for IERC20;

    //safekeepV1 Vaults will only support eth and erc20 tokens for now

    struct Vault {
        address _owner;
        uint256 _VAULT_WEI_BALANCE;
        uint256 _lastPing;
        uint256 _id;
        address backup;
        address[] _inheritors;
        address[] tokensDeposited;
        mapping(address => uint256) _VAULT_TOKEN_BALANCES;
        mapping(address => uint256) _inheritorWeishares;
        mapping(address => mapping(address => uint256)) _inheritorTokenShares;
        mapping(address => mapping(address => bool)) _inheritorActiveTokens;
        mapping(address => bool) activeInheritors;
        mapping(address => bool) activeTokens;
        mapping(address => address[]) inheritorAllocatedTokens;
        //strictly for returning values
        mapping(address=>mapping(address=>uint)) inheritorTokenAllocations;
        //mapping(uint=>address) aaveToks;
    }

    struct tokenAllocs {
        address token;
        uint256 amount;
    }
    struct allInheritorTokenAllocs {
        address inheritor_;
        address token_;
        uint256 amount_;
    }

    struct allInheritorEtherAllocs {
        address inheritor_;
        uint256 weiAlloc_;
    }

    struct tokenBal {
        address token_;
        uint256 bal_;
    }

    struct vaultDeets{
address _owner;
uint256 _VAULT_WEI_BALANCE;
        uint256 _lastPing;
        uint256 _id;
        address backup;
        address[] _inheritors;
        address[] tokensDeposited;

    }

   

    //using a central struct
    struct SFStorage {
        //Vault[] vaults;
        uint256 VAULT_ID;
        address _mediator;
        mapping(address => bool) hasVault;
    }

    bytes32 private _contractIdentifier =
        keccak256(abi.encodePacked("SAFEKEEPV1"));

    mapping(address => bool) public _whitelistedAssets;
    mapping(uint256 => Vault) public vaultDefaultIndex;
    mapping(bytes32 => SFStorage) private contractStore;
    mapping(address=>mapping(uint=>bool)) inheritorActiveVaults;
    mapping(address=>uint[]) userVaults;
    mapping(address=>uint) ownerVault;

    modifier vaultOwner(uint256 vaultID) {
        require(
            msg.sender == vaultDefaultIndex[vaultID]._owner,
            "vaultOwner: you are not the vault owner"
        );
        _;
    }

    modifier vaultExists(uint256 vaultId) {
        require(
            vaultDefaultIndex[vaultId]._owner != address(0),
            "vault does not exist"
        );
        _;
    }

    modifier vaultBackup(uint256 vaultID) {
        require(
            vaultDefaultIndex[vaultID].backup == msg.sender,
            "vaultBackup: you are not the vault backup address"
        );
        _;
    }

    modifier notExpired(uint256 vaultID) {
        require(
            block.timestamp.sub(vaultDefaultIndex[vaultID]._lastPing) <=
                24 weeks,
            "Has expired"
        );
        _;
    }

    receive() external payable {}

    /////////////
    ///EVENTS///
    ////////////
    event vaultCreated(
        address indexed owner,
        address indexed backup,
        uint256 indexed startingBalance,
        address[] inheritors_
    );
    event inheritorsAdded(address[] indexed newInheritors);
    event inheritorsRemoved(address[] indexed inheritors);
    event EthAllocated(address[] indexed inheritors, uint256[] amounts);
    event tokenAllocated(
        address indexed token,
        address[] indexed inheritors,
        uint256[] amounts
    );
    event EthDeposited(uint256 _amount);
    event tokensDeposited(address[] indexed tokens, uint256[] amounts);
    event claimedTokens(
        address indexed inheritor,
        address indexed token,
        uint256 amount
    );
    event ClaimedEth(address indexed inheritor, uint256 _amount);

    ///////////////////
    //VIEW FUNCTIONS//
    /////////////////



function checkVault(uint256 _vaultId) public view returns(vaultDeets memory deets){
 Vault storage v = vaultDefaultIndex[_vaultId];
 deets._owner=v._owner;
 deets._VAULT_WEI_BALANCE=v._VAULT_WEI_BALANCE;
 deets._lastPing=v._lastPing;
 deets._id=v._id;
 deets.backup=v.backup;
 deets._inheritors=v._inheritors;
 deets.tokensDeposited=v.tokensDeposited;

}
    function checkAddressTokenAllocations(uint256 _vaultId,address _inheritor)
        public
        view
        returns (tokenAllocs[] memory tAllocs)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(
            anInheritor(_vaultId, _inheritor) == true,
            "Check: you are not an inheritor in this vault"
        );
        require(
            v.inheritorAllocatedTokens[_inheritor].length > 0,
            "ClaimTokens: you do not have any allocated tokens in this vault"
        );
        require(_inheritor != v._owner, "address is the owner");
        uint256 count = v.inheritorAllocatedTokens[msg.sender].length;
        tAllocs = new tokenAllocs[](count);
        for (uint256 i; i < count; i++) {
            address _t = v.inheritorAllocatedTokens[msg.sender][i];
            tAllocs[i].amount = v._inheritorTokenShares[msg.sender][_t];
            tAllocs[i].token = _t;
        }
    }
    
    //returns the vaultID of an address(if he has any)
    function checkOwnerVault(address _vaultOwner) public view returns(uint256 _ID){
        SFStorage storage s=contractStore[_contractIdentifier];
        if(s.hasVault[_vaultOwner]){
_ID=ownerVault[_vaultOwner];
        }
        
    }

    function checkAllEtherAllocations(uint256 _vaultId)
        public
        view
        returns (allInheritorEtherAllocs[] memory eAllocs)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(v._owner != address(0), "Vault has not been created yet");
        uint256 inheritorCount = v._inheritors.length;
        eAllocs = new allInheritorEtherAllocs[](inheritorCount);
        for (uint256 i; i < inheritorCount; i++) {
            eAllocs[i].inheritor_ = v._inheritors[i];
            eAllocs[i].weiAlloc_ = v._inheritorWeishares[v._inheritors[i]];
        }
    }

    function checkBackupAddressAndPing(uint _vaultId) public view vaultExists(_vaultId) returns(address _backup,uint _p){
        Vault storage v=vaultDefaultIndex[_vaultId];
        _backup=v.backup;
        _p=v._lastPing;
    }

    function checkAddressEtherAllocation(uint256 _vaultId,address _inheritor)
        public
        view
        vaultExists(_vaultId)
        returns (uint256 _allocated)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(_inheritor != v._owner, "address is the owner");
        require(
            v._inheritorWeishares[_inheritor] > 0,
            "ClaimTokens: address does not have any allocated ether in this vault"
        );
        require(
            anInheritor(_vaultId, _inheritor) == true,
            "Check: address is not an inheritor"
        );
        _allocated = v._inheritorWeishares[msg.sender];
    }
    
    function checkAllAddressVaults(address _inheritor) public view returns(uint[] memory){
        return userVaults[_inheritor];
    }

    function checkVaultEtherBalance(uint256 _vaultId)
        public
        view
        vaultExists(_vaultId)
        returns (uint256 etherBalance)
    {
        etherBalance = vaultDefaultIndex[_vaultId]._VAULT_WEI_BALANCE;
    }

//removing this function as it is currently not feasible
    //because of multiple dimensions, only displays the first token
    /**
    function checkAllAllocatedTokens(uint256 _vaultId)
        public
        view
        returns (allInheritorTokenAllocs[] memory allTokenAllocs)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        uint256 inheritorCount = v._inheritors.length;
        allTokenAllocs = new allInheritorTokenAllocs[](inheritorCount);
        for (uint256 i; i < inheritorCount; i++) {
            allTokenAllocs[i].inheritor_ = v._inheritors[i];
            address currentInheritor = v._inheritors[i];
            for (
                uint256 j;
                j <
                v.inheritorAllocatedTokens[allTokenAllocs[i].inheritor_].length;
                j++
            ) {
                uint256 _bal = v.inheritorTokenAllocations[currentInheritor][v.inheritorAllocatedTokens[currentInheritor][j]];
                address _tok = v.inheritorAllocatedTokens[currentInheritor][j];
                allTokenAllocs[i].amount_ = _bal;
                allTokenAllocs[i].token_ = _tok;
            }
        }
    }
    **/

    function checkVaultTokenBalance(uint256 _vaultId, address token)
        public
        view
        returns (uint256 bal_)
    {
        bal_ = vaultDefaultIndex[_vaultId]._VAULT_TOKEN_BALANCES[token];
    }

   // function checkAllVaultDetails(uint256 _vaultId) public view returns(Vault memory v){
     //   v=vaultDefaultIndex[_vaultId];
    //}

    function checkMyVaultTokenBalance(uint256 _vaultId, address token)
        public
        view
        returns (uint256 bal_)
    {
        require(
            anInheritor(_vaultId, msg.sender) == true,
            "Check: you are not an inheritor in this vault"
        );
        bal_ = vaultDefaultIndex[_vaultId]._inheritorTokenShares[msg.sender][
            token
        ];
    }

    function checkAllVaultTokenBalances(uint256 _vaultId)
        public
        view
        returns (tokenBal[] memory _tBal)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(
            v.tokensDeposited.length > 0,
            "Vault does not contain any tokens"
        );
        uint256 tokenCount = v.tokensDeposited.length;
        _tBal = new tokenBal[](tokenCount);
        for (uint256 k; k < v.tokensDeposited.length; k++) {
            if (v.activeTokens[v.tokensDeposited[k]] == true) {
                address _addr = v.tokensDeposited[k];
                uint256 _balance = v._VAULT_TOKEN_BALANCES[_addr];
                _tBal[k].token_ = _addr;
                _tBal[k].bal_ = _balance;
            }
        }
    }

    function checkVaultDepositedTokens(uint256 _vaultId)
        public
        view
        returns (address[] memory _tok)
    {
        _tok = vaultDefaultIndex[_vaultId].tokensDeposited;
    }

    function getAllInheritors(uint256 _vaultId)
        public
        view
        returns (address[] memory inheritors_)
    {
        inheritors_ = vaultDefaultIndex[_vaultId]._inheritors;
    }


    //////////////////////
    ///WRITE FUNCTIONS///
    ////////////////////
    function createVault(
        address[] calldata inheritors,
        uint256 _startingBal,
        address _backupAddress
    ) public payable returns (uint256) {
        require(
            msg.value == _startingBal,
            "CreateVault: Sent ether does not match inputted ether"
        );
        require(
            _backupAddress != msg.sender,
            "you cannot be the backup address"
        );
        SFStorage storage s = contractStore[_contractIdentifier];
        require(s.hasVault[msg.sender] == false, "you already have a vault");
        vaultDefaultIndex[s.VAULT_ID]._id = s.VAULT_ID;
        vaultDefaultIndex[s.VAULT_ID]._owner = msg.sender;
        vaultDefaultIndex[s.VAULT_ID]._VAULT_WEI_BALANCE = _startingBal;
        // vaultDefaultIndex[s.VAULT_ID]._OWNER_WEI_SHARE=_startingBal; //allocate all ether to owner
        vaultDefaultIndex[s.VAULT_ID]._inheritors = inheritors;
        vaultDefaultIndex[s.VAULT_ID]._lastPing = block.timestamp;
        vaultDefaultIndex[s.VAULT_ID].backup = _backupAddress;
        s.hasVault[msg.sender] = true; //you now have a vault
        ownerVault[msg.sender]=s.VAULT_ID;
        for (uint256 k; k < inheritors.length; k++) {
            vaultDefaultIndex[s.VAULT_ID].activeInheritors[
                inheritors[k]
            ] = true; //all new inheritors are active by default
            inheritorActiveVaults[inheritors[k]][s.VAULT_ID]=true;
            //vaultId is unique so add to array
                userVaults[inheritors[k]].push(s.VAULT_ID);
        }
        s.VAULT_ID++;
        emit vaultCreated(msg.sender, _backupAddress, _startingBal, inheritors);
        emit inheritorsAdded(inheritors);
        return vaultDefaultIndex[s.VAULT_ID]._id;
    }

    function addInheritors(
        uint256 _vaultId,
        address[] calldata _newInheritors,
        uint256[] calldata _weiShare
    )
        external
        notExpired(_vaultId)
        returns (address[] memory, uint256[] memory)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(
            msg.sender == v._owner,
            "AddInheritors:you are not the vault owner"
        );
        require(
            _newInheritors.length == _weiShare.length,
            "AddInheritors: Length of arguments do not match"
        );
        uint256 _total;
        uint256 _existingallocated = getCurrentAllocatedEth(_vaultId);
        for (uint256 k; k < _newInheritors.length; k++) {
            _total += _weiShare[k];
            require(
                v.activeInheritors[_newInheritors[k]] == false,
                "AddInheritors: one or more of the addresses is already an active inheritor"
            );
            require(
                (_total.add(_existingallocated)) <= v._VAULT_WEI_BALANCE,
                "AddInheritors:you do not have that much ether to allocate,unallocate or deposit more ether"
            );
            v._inheritorWeishares[_newInheritors[k]] = _weiShare[k];
            //append the inheritors for a vault
            (v._inheritors).push(_newInheritors[k]);
            v.activeInheritors[_newInheritors[k]] = true;
            userVaults[_newInheritors[k]].push(_vaultId);
        }
        _ping(_vaultId);
        emit inheritorsAdded(_newInheritors);
        return (_newInheritors, _weiShare);
    }

    function removeInheritors(uint256 _vaultId, address[] calldata _inheritors)
        external
        notExpired(_vaultId)
        returns (address[] memory)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(
            msg.sender == v._owner,
            "activateInheritors:you are not the vault owner"
        );
        for (uint256 k; k < _inheritors.length; k++) {
            require(
                v.activeInheritors[_inheritors[k]] == true,
                "activateInheritors:one or more inheritor is already removed or does not exist"
            );
            v.activeInheritors[_inheritors[k]] = false;
            //pop out the address from the array
            removeAddress(v._inheritors, _inheritors[k]);
            removeUint(userVaults[_inheritors[k]],_vaultId);
            reset(_vaultId, _inheritors[k]);
        }
        _ping(_vaultId);
        emit inheritorsAdded(_inheritors);
        return _inheritors;
    }

    function depositEther(uint256 _vaultId, uint256 _amount)
        external
        payable
        vaultOwner(_vaultId)
        notExpired(_vaultId)
        nonReentrant
        returns (uint256 currentEtherBalance)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(
            _amount == msg.value,
            "DepositEther:Amount sent does not equal amount entered"
        );
        v._VAULT_WEI_BALANCE += _amount;
        _ping(_vaultId);
        emit EthDeposited(_amount);
        return v._VAULT_WEI_BALANCE;
    }

    function depositTokens(
        uint256 _id,
        address[] calldata tokenDeps,
        uint256[] calldata _amounts
    )
        external
        vaultOwner(_id)
        notExpired(_id)
        nonReentrant
        returns (address[] memory, uint256[] memory)
    {
        Vault storage v = vaultDefaultIndex[_id];
        require(
            tokenDeps.length == _amounts.length,
            "TokenDeposit: number of tokens does not match number of amounts"
        );
        for (uint256 j; j < tokenDeps.length; j++) {
            IERC20 _j = IERC20(tokenDeps[j]);
            require(
                _j.allowance(msg.sender, address(this)) >= _amounts[j],
                "TokenDeposit: you have not approved safekeep to spend one or more of your tokens"
            );
            uint256 tokenBalanceBefore= _j.balanceOf(address(this));
            require(_j.transferFrom(msg.sender, address(this), _amounts[j]));
            uint256 toAdd=_j.balanceOf(address(this))-tokenBalanceBefore;
            v._VAULT_TOKEN_BALANCES[tokenDeps[j]] += toAdd;
            if (v.activeTokens[tokenDeps[j]] == false) {
                v.tokensDeposited.push(tokenDeps[j]);
                v.activeTokens[tokenDeps[j]] = true;
                //require(v.activeTokens[tokenDeps[j]]==true,"didn't do it, sorry");
            }
        }
        emit tokensDeposited(tokenDeps, _amounts);
         _ping(_id);
        
        return (tokenDeps, _amounts);
       
    }

    function allocateTokens(
        uint256 _vaultId,
        address tokenAdd,
        address[] calldata _inheritors,
        uint256[] calldata _shares
    ) external nonReentrant returns (address[] memory, uint256[] memory) {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(
            msg.sender == v._owner,
            "AllocateTokens:you are not the vault owner"
        );
        require(
            _inheritors.length == _shares.length,
            "AllocateTokens: Length of arguments do not match"
        );
        uint256 _total = 0;
        uint256 existingAllocated;
        for (uint256 k; k < _inheritors.length; k++) {
            _total += _shares[k];
            existingAllocated = getCurrentAllocatedTokens(_vaultId, tokenAdd);
            require(
                _total <= v._VAULT_TOKEN_BALANCES[tokenAdd],
                "AllocateTokens: you do not have that much tokens to allocate,unallocate or deposit more tokens"
            );
            require(
                v.activeInheritors[_inheritors[k]] == true,
                "AllocateTokens: one of the addresses is not an active inheritor"
            );
            v._inheritorTokenShares[_inheritors[k]][tokenAdd] = _shares[k];
            if (v._inheritorActiveTokens[_inheritors[k]][tokenAdd] == false) {
                v.inheritorAllocatedTokens[_inheritors[k]].push(tokenAdd);
                v._inheritorActiveTokens[_inheritors[k]][tokenAdd] = true;
                v.inheritorTokenAllocations[_inheritors[k]][tokenAdd]=_shares[k];
            }
        }
        _ping(_vaultId);
        emit tokenAllocated(tokenAdd, _inheritors, _shares);
        return (_inheritors, _shares);
    }

    function allocateEther(
        uint256 _vaultId,
        address[] calldata _inheritors,
        uint256[] calldata _ethShares
    ) external nonReentrant returns (address[] memory, uint256[] memory) {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(
            msg.sender == v._owner,
            "AllocateEther:you are not the vault owner"
        );
        require(
            _inheritors.length == _ethShares.length,
            "AllocateEther: Length of arguments do not match"
        );
        uint256 _total = 0;
        //  uint256 _allocated=getCurrentAllocatedEth(_vaultId);
        for (uint256 k; k < _inheritors.length; k++) {
            _total += _ethShares[k];
            require(
                _total <= v._VAULT_WEI_BALANCE,
                "AllocateEther: you do not have that much Ether to allocate,unallocate or deposit more ether"
            );
            require(
                v.activeInheritors[_inheritors[k]] == true,
                "AllocateEther: one of the addresses is not an active inheritor"
            );
            v._inheritorWeishares[_inheritors[k]] = _ethShares[k];
            //   v._OWNER_WEI_SHARE-=_ethShares[k];
        }
        _ping(_vaultId);
        emit EthAllocated(_inheritors, _ethShares);
        return (_inheritors, _ethShares);
    }

    function checkEthLimit(uint256 _vaultId)
        internal
        view
        returns (uint256 _unallocated)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        uint256 totalEthAllocated;
        for (uint256 x; x < v._inheritors.length; x++) {
            totalEthAllocated += v._inheritorWeishares[v._inheritors[x]];
        }
        require(
            v._VAULT_WEI_BALANCE >= totalEthAllocated,
            "WEI:Overflow, unallocate some ether"
        );
        return v._VAULT_WEI_BALANCE.sub(totalEthAllocated);
    }

    function checkTokenLimit(uint256 _vaultId, address token)
        internal
        view
        returns (uint256 _unallocated)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        uint256 totalTokensAllocated;
        for (uint256 x; x < v._inheritors.length; x++) {
            totalTokensAllocated += v._inheritorTokenShares[v._inheritors[x]][
                token
            ];
        }
        require(
            v._VAULT_TOKEN_BALANCES[token] >= totalTokensAllocated,
            "TOKEN: Overflow, unallocate some tokens"
        );
        return v._VAULT_TOKEN_BALANCES[token].sub(totalTokensAllocated);
    }

    function findAddIndex(address _item, address[] memory addressArray)
        internal
        pure
        returns (uint256 i)
    {
        for (i; i < addressArray.length; i++) {
            //using the conventional method since we cannot have duplicate addresses
            if (addressArray[i] == _item) {
                return i;
            }
        }
    }
    
    function findUintIndex(uint _item,uint[] memory noArray) internal pure returns(uint256 i){
        for(i;i<noArray.length;i++){
            if(noArray[i]==_item){
                return i;
        }
    }
    }
    
    function removeUint(uint[] storage _noArray,uint to) internal{
        uint256 index=findUintIndex(to,_noArray);
        if(_noArray.length<=1){
            _noArray.pop();
        }
        if(_noArray.length>1){
        for(uint256 i=index;i<_noArray.length;i++){
            _noArray[i]=_noArray[i-1];
            
        }
        _noArray.pop();
        }
        
    }

    function removeAddress(address[] storage _array, address _add) internal {
        uint256 index = findAddIndex(_add, _array);
        if(_array.length<=1){
            _array.pop();
        }
        
        if(_array.length>1){
        for (uint256 i = index; i < _array.length; i++) {
            _array[i] = _array[i - 1];
        }
        _array.pop();
    }
    }
    
    

    //only used for multiple address elemented arrays
    function reset(uint256 _vaultId, address _inheritor)
        internal
        returns (uint256 unAllocatedWei)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        unAllocatedWei = v._inheritorWeishares[_inheritor];
        v._inheritorWeishares[_inheritor] = 0;
        //resetting all token allocations
        for (
            uint256 x;
            x < v.inheritorAllocatedTokens[_inheritor].length;
            x++
        ) {
            v._inheritorTokenShares[_inheritor][
                v.inheritorAllocatedTokens[_inheritor][x]
            ] = 0;
            v._inheritorActiveTokens[_inheritor][
                v.inheritorAllocatedTokens[_inheritor][x]
            ] = false;
        }
        //remove all token addresses
        delete v.inheritorAllocatedTokens[_inheritor];
    }

    function getCurrentAllocatedEth(uint256 _vaultId)
        internal
        view
        returns (uint256)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        uint256 totalEthAllocated;
        for (uint256 x; x < v._inheritors.length; x++) {
            totalEthAllocated += v._inheritorWeishares[v._inheritors[x]];
        }
        return totalEthAllocated;
    }

    function getCurrentAllocatedTokens(uint256 _vaultId, address _token)
        internal
        view
        returns (uint256)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        uint256 totalTokensAllocated;
        for (uint256 x; x < v._inheritors.length; x++) {
            totalTokensAllocated += v._inheritorTokenShares[v._inheritors[x]][
                _token
            ];
        }
        return totalTokensAllocated;
    }

    function withdrawEth(uint256 _vaultId, uint256 _amount)
        public
        vaultOwner(_vaultId)
        nonReentrant
        returns (uint256)
    {
        Vault storage v = vaultDefaultIndex[_vaultId];
        uint256 _avail = v._VAULT_WEI_BALANCE.sub(
            getCurrentAllocatedEth(_vaultId)
        );
        require(
            _amount <= _avail,
            "withdrawEth: Not enough eth, Unallocate from some inheritors or deposit more"
        );
        //reduce balance after checks
        (v._VAULT_WEI_BALANCE -= _amount);
        payable(v._owner).transfer(_amount);
        _ping(_vaultId);
        return (v._VAULT_WEI_BALANCE);
    }

    function withdrawTokens(
        uint256 _vaultId,
        address[] calldata tokenAdds,
        uint256[] calldata _amounts
    ) public vaultOwner(_vaultId) nonReentrant returns (bool) {
        Vault storage v = vaultDefaultIndex[_vaultId];
        for (uint256 x; x < tokenAdds.length; x++) {
            uint256 _availableTokens = v
            ._VAULT_TOKEN_BALANCES[tokenAdds[x]]
            .sub(getCurrentAllocatedTokens(_vaultId, tokenAdds[x]));
            require(
                _availableTokens >= _amounts[x],
                "withdrawToken:Not enough tokens, unallocate from some inheritors or deposit more"
            );
            //transfer tokens after checks then reduce balance
            IERC20 _j = IERC20(tokenAdds[x]);
            require(_j.transfer(v._owner, _amounts[x]));
            v._VAULT_TOKEN_BALANCES[tokenAdds[x]] -= (_amounts[x]);
            //if there is just a token and balance is 0
            if (
                v.tokensDeposited.length == 1 &&
                v._VAULT_TOKEN_BALANCES[v.tokensDeposited[0]] == 0
            ) {
                v.activeTokens[v.tokensDeposited[0]] = false;
                v.tokensDeposited.pop();
                continue;
            }
            //if no tokens remain,delete the array
            if (
                v._VAULT_TOKEN_BALANCES[tokenAdds[x]] == 0
            ) {
                v.activeTokens[tokenAdds[x]] = false;
                removeAddress(v.tokensDeposited, tokenAdds[x]);
            }
        }
        _ping(_vaultId);
        return true;
    }

    function _ping(uint256 _vaultId)
        private
        vaultOwner(_vaultId)
        returns (uint256)
    {
        vaultDefaultIndex[_vaultId]._lastPing = block.timestamp;
        return (vaultDefaultIndex[_vaultId]._lastPing);
    }

    function ping(uint256 _vaultId) external {
        _ping(_vaultId);
    }

    function anInheritor(uint256 vaultId, address inheritor_)
        internal
        view
        returns (bool inh)
    {
        Vault storage v = vaultDefaultIndex[vaultId];
        for (uint256 i; i < v._inheritors.length; i++) {
            if (inheritor_ == v._inheritors[i]) {
                inh= true;
            }
        }
    }

    //////////
    //DANGER//
    /////////
    function transferOwner(uint256 _vaultId, address _newOwner)
        public
        vaultOwner(_vaultId)
        returns (address)
    {
        vaultDefaultIndex[_vaultId]._owner = _newOwner;
        ownerVault[_newOwner]=_vaultId;
        //  _ping(_vaultId);
        return _newOwner;
    }

    function transferBackup(uint256 _vaultId, address _newBackup)
        public
        vaultBackup(_vaultId)
        returns (address)
    {
        vaultDefaultIndex[_vaultId].backup = _newBackup;
        return _newBackup;
    }

    function claimOwnership(uint256 _vaultId, address _backup)
        public
        vaultBackup(_vaultId)
        returns (address)
    {
        require(
            block.timestamp.sub(vaultDefaultIndex[_vaultId]._lastPing) >
                24 weeks,
            "Has not expired"
        );
        vaultDefaultIndex[_vaultId]._owner = msg.sender;
        vaultDefaultIndex[_vaultId].backup = _backup;
        ownerVault[msg.sender]=_vaultId;
        return msg.sender;
    }


    //////////
    //CLAIMS//
    //////////
    function claimAllTokens(uint256 _vaultId) internal {
        Vault storage v = vaultDefaultIndex[_vaultId];
        //this is used for testing
        require(
            block.timestamp.sub(v._lastPing) > 24 weeks,
            "Has not expired"
        );
        require(
            v.inheritorAllocatedTokens[msg.sender].length > 0,
            "ClaimTokens: you do not have any allocated tokens in this vault"
        );
        for (
            uint256 i;
            i < v.inheritorAllocatedTokens[msg.sender].length;
            i++
        ) {
            IERC20 _t = IERC20(v.inheritorAllocatedTokens[msg.sender][i]);
            require(
                _t.transfer(
                    msg.sender,
                    v._inheritorTokenShares[msg.sender][
                        v.inheritorAllocatedTokens[msg.sender][i]
                    ]
                )
            );
            v._inheritorActiveTokens[msg.sender][
                v.inheritorAllocatedTokens[msg.sender][i]
            ] = false;
            v._VAULT_TOKEN_BALANCES[
                v.inheritorAllocatedTokens[msg.sender][i]
            ] -= v._inheritorTokenShares[msg.sender][
                v.inheritorAllocatedTokens[msg.sender][i]
            ];
            v.inheritorTokenAllocations[msg.sender][v.inheritorAllocatedTokens[msg.sender][i]]=0;
           
            emit claimedTokens(
                msg.sender,
                v.inheritorAllocatedTokens[msg.sender][i],
                v._inheritorTokenShares[msg.sender][
                    v.inheritorAllocatedTokens[msg.sender][i]
                ]
            );
             delete v.inheritorAllocatedTokens[msg.sender];
        }
        
        reset(_vaultId, msg.sender);
    }

    function claim(uint256 _vaultId) external nonReentrant {
        Vault storage v = vaultDefaultIndex[_vaultId];
        require(
            block.timestamp.sub(v._lastPing) > 10 seconds,
            "Has not expired"
        );
        if (v._inheritorWeishares[msg.sender] > 0) {
            uint256 _toClaim = v._inheritorWeishares[msg.sender];
            v._VAULT_WEI_BALANCE -= _toClaim;
            //reset balance
            v._inheritorWeishares[msg.sender] = 0;
            //send out balance
            payable(msg.sender).transfer(_toClaim);
            emit ClaimedEth(msg.sender, _toClaim);
        }
        if (v.inheritorAllocatedTokens[msg.sender].length > 0) {
            claimAllTokens(_vaultId);
        }
        removeAddress(v._inheritors, msg.sender);
        removeUint(userVaults[msg.sender],_vaultId);
    }
}