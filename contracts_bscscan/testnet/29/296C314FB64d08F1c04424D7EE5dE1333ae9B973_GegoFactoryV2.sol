pragma solidity ^0.5.5;
pragma experimental ABIEncoderV2;

import "../interface/IERC20.sol";
import "../library/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interface/IGegoToken.sol";
import "../interface/IGegoFactoryV2.sol";
import "../interface/IGegoRuleProxy.sol";
import "../library/Governance.sol";

contract GegoFactoryV2 is Governance, IGegoFactoryV2 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;


    event GegoAdded(
        uint256 indexed id,
        uint256 grade,
        uint256 quality,
        uint256 amount,
        uint256 resBaseId,
        uint256 tLevel,
        uint256 ruleId,
        uint256 nftType,
        address author,
        address erc20,
        uint256 createdTime,
        uint256 blockNum
    );

    event GegoBurn(
        uint256 indexed id,
        uint256 amount,
        address erc20
    );

    struct MintData{
        uint256 amount;
        uint256 resBaseId;
        uint256 nftType;
        uint256 ruleId;
        uint256 tLevel;
    }

    struct MintExtraData {
        uint256 gego_id;
        uint256 grade;
        uint256 quality;
        address author;
    }

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);

    // for minters
    mapping(address => bool) public _minters;

    mapping(uint256 => IGegoToken.Gego) public _gegoes;

    mapping(uint256 => IGegoRuleProxy) public _ruleProxys;

    mapping(address => bool) public _ruleProxyFlags;

    uint256 public _maxGegoV1Id = 1000000;
    uint256 public _gegoId = _maxGegoV1Id;


    IGegoToken public _gegoToken = IGegoToken(0x0);

    bool public _isUserStart = false;

    constructor(address gegoToken) public {
        _gegoToken = IGegoToken(gegoToken);
    }

    function setUserStart(bool start) public onlyGovernance {
        _isUserStart = start;
    }

    function addMinter(address minter) public onlyGovernance {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyGovernance {
        _minters[minter] = false;
    }


    // only function for creating additional rewards from dust
    function seize(IERC20 asset, address teamWallet) public onlyGovernance {
        uint256 balance = asset.balanceOf(address(this));
        asset.safeTransfer(teamWallet, balance);
    }
    

    /**
     * @dev add gego mint strategy address
     * can't remove
     */
    function addGegoRuleProxy(uint256 nftType, address ruleProxy)  public  
    onlyGovernance{
        require(_ruleProxys[nftType] == IGegoRuleProxy(0x0), "must null");

        _ruleProxys[nftType] = IGegoRuleProxy(ruleProxy);

        _ruleProxyFlags[ruleProxy] = true;
    }

    function isRulerProxyContract(address proxy) external view returns ( bool ){
        return _ruleProxyFlags[proxy];
    }

    /*
     * @dev set gego contract address
     */
    function setGegoContract(address gego)  public  
        onlyGovernance{
        _gegoToken = IGegoToken(gego);
    }

    function setCurrentGegoId(uint256 id)  public  
        onlyGovernance{
        _gegoId = id;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'GegoFactoryV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getGego(uint256 tokenId)
        external view
        returns (
            uint256 grade,
            uint256 quality,
            uint256 amount,
            uint256 resBaseId,
            uint256 tLevel,
            uint256 ruleId,
            uint256 nftType,
            address author,
            address erc20,
            uint256 createdTime,
            uint256 blockNum
        )
    {
        IGegoToken.Gego storage gego = _gegoes[tokenId];
        require(gego.id > 0, "gego not exist");
        grade = gego.grade;
        quality = gego.quality;
        amount = gego.amount;
        resBaseId = gego.resBaseId;
        tLevel = gego.tLevel;
        ruleId = gego.ruleId;
        nftType = gego.nftType;
        author = gego.author;
        erc20 = gego.erc20;
        createdTime = gego.createdTime;
        blockNum = gego.blockNum;
    }

    function getGegoStruct(uint256 tokenId)
        external view
        returns (IGegoToken.Gego memory gego){
            require(_gegoes[tokenId].id > 0, "gego  not exist");
            gego=_gegoes[tokenId];
        }


    function setBaseResId(uint256 tokenId, uint256 resBaseId) external onlyGovernance {
        require( _gegoes[tokenId].id > 0, "gego not exist");
        _gegoes[tokenId].resBaseId = resBaseId;
    }

    function mint(MintData memory mintData, IGegoRuleProxy.Cost721Asset memory costSet1, IGegoRuleProxy.Cost721Asset memory costSet2 ) public 
        lock
    {

        address origin = msg.sender;

        if(_minters[msg.sender] == false){
            require(!origin.isContract(), "call to non-contract");
        }

        require(_isUserStart || _minters[msg.sender]  , "can't mint" );

        require( _ruleProxys[mintData.nftType] != IGegoRuleProxy(0x0), " invalid mint nftType !" );

        uint256 mintAmount;
        address mintErc20;

        IGegoRuleProxy.MintParams memory params;
        params.user = msg.sender;
        params.amount = mintData.amount;
        params.ruleId = mintData.ruleId;

        (mintAmount,mintErc20) = _ruleProxys[mintData.nftType].cost( params,costSet1,costSet2 );

        IGegoToken.Gego memory gego = _ruleProxys[mintData.nftType].generate( msg.sender, mintData.ruleId );

        uint256 gegoId = gego.id;
        if(gegoId  == 0){
            _gegoId++ ;
            gegoId = _gegoId;
        }
        gego.id = gegoId;
        gego.blockNum = gego.blockNum > 0 ? gego.blockNum:block.number;
        gego.createdTime =  gego.createdTime > 0?gego.createdTime:block.timestamp ;

        gego.amount = gego.amount>0?gego.amount:mintAmount;
        gego.resBaseId = gego.resBaseId>0?gego.resBaseId:mintData.resBaseId;
        gego.tLevel = gego.tLevel>0?gego.tLevel:mintData.tLevel;
        gego.erc20 = gego.erc20==address(0x0)?mintErc20:gego.erc20;

        gego.ruleId = mintData.ruleId;
        gego.nftType = mintData.nftType;
        gego.author = gego.author==address(0x0)?msg.sender:gego.author;

        _gegoes[gegoId] = gego;

        _gegoToken.mint(msg.sender, gegoId);

        emit GegoAdded(
            gego.id,
            gego.grade,
            gego.quality,
            gego.amount,
            gego.resBaseId,
            gego.tLevel,
            gego.ruleId,
            gego.nftType,
            gego.author,
            gego.erc20,
            gego.createdTime,
            gego.blockNum
        );

    } 


    function gmMint(MintData memory mintData, MintExtraData memory extraData) public {
        require(_minters[msg.sender]  , "can't mint");

        IGegoRuleProxy.Cost721Asset memory costSet1;
        IGegoRuleProxy.Cost721Asset memory costSet2;

        IGegoRuleProxy.MintParams memory params;
        params.user = msg.sender;
        params.amount = mintData.amount;
        params.ruleId = mintData.ruleId;

        uint256 mintAmount;
        address mintErc20;

        (mintAmount,mintErc20) = _ruleProxys[mintData.nftType].cost( params,costSet1,costSet2 );
      
        uint256 gegoId = extraData.gego_id;
        if(extraData.gego_id == 0){
            _gegoId++ ;
            gegoId = _gegoId;
        }else{
            if(gegoId > _gegoId){
                _gegoId =  gegoId;
            }
        }

        IGegoToken.Gego memory gego;
        gego.id = gegoId;
        gego.blockNum = block.number;
        gego.createdTime =  block.timestamp ;
        gego.grade = extraData.grade;
        gego.quality = extraData.quality;
        gego.amount = mintAmount;
        gego.resBaseId = mintData.resBaseId;
        gego.tLevel = mintData.tLevel;
        gego.ruleId = mintData.ruleId;
        gego.nftType = mintData.nftType;
        gego.author = extraData.author;
        gego.erc20 = mintErc20;

        _gegoes[gegoId] = gego;

        _gegoToken.mint(extraData.author, gegoId);

        emit GegoAdded(
            gego.id,
            gego.grade,
            gego.quality,
            gego.amount,
            gego.resBaseId,
            gego.tLevel,
            gego.ruleId,
            gego.nftType,
            gego.author,
            gego.erc20,
            gego.createdTime,
            gego.blockNum
        );
    } 


    function burn(uint256 tokenId) external returns ( bool ) {
      
        IGegoToken.Gego memory gego = _gegoes[tokenId];
        require(gego.id > 0, "not exist");

        _gegoToken.safeTransferFrom(msg.sender, address(this), tokenId);
        _gegoToken.burn(tokenId);

        emit GegoBurn(gego.id, gego.amount, gego.erc20);

        _ruleProxys[gego.nftType].destroy( msg.sender, gego );

        _gegoes[tokenId].id = 0;

        return true;
    }

    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        //only receive the _nft staff
        if(address(this) != operator) {
            //invalid from nft
            return 0;
        }
        //success
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function mint(address account, uint amount) external;
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

pragma solidity ^0.5.0;

import "../interface/IERC20.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract IGegoToken is IERC721 {

    struct GegoV1 {
        uint256 id;
        uint256 grade;
        uint256 quality;
        uint256 amount;
        uint256 resId;
        address author;
        uint256 createdTime;
        uint256 blockNum;
    }


    struct Gego {
        uint256 id;
        uint256 grade;
        uint256 quality;
        uint256 amount;
        uint256 resBaseId;
        uint256 tLevel;
        uint256 ruleId;
        uint256 nftType;
        address author;
        address erc20;
        uint256 createdTime;
        uint256 blockNum;
    }
    
    function mint(address to, uint256 tokenId) external returns (bool) ;
    function burn(uint256 tokenId) external;
}

pragma solidity ^0.5.0;

pragma experimental ABIEncoderV2;


import "../interface/IGegoToken.sol";

interface IGegoFactoryV2 {


    function getGego(uint256 tokenId)
        external view
        returns (
            uint256 grade,
            uint256 quality,
            uint256 amount,
            uint256 resBaseId,
            uint256 tLevel,
            uint256 ruleId,
            uint256 nftType,
            address author,
            address erc20,
            uint256 createdTime,
            uint256 blockNum
        );


    function getGegoStruct(uint256 tokenId)
        external view
        returns (IGegoToken.Gego memory gego);

    function burn(uint256 tokenId) external returns ( bool );
    
    function isRulerProxyContract(address proxy) external view returns ( bool );
}

pragma solidity ^0.5.0;

pragma experimental ABIEncoderV2;

import "../interface/IGegoToken.sol";


interface IGegoRuleProxy  {

    struct Cost721Asset{
        uint256 costErc721Id1;
        uint256 costErc721Id2;
        uint256 costErc721Id3;

        address costErc721Origin;
    }

    struct MintParams{
        address user;
        uint256 amount;
        uint256 ruleId;
    }

    function cost( MintParams calldata params, Cost721Asset calldata costSet1, Cost721Asset calldata costSet2 ) external returns (
        uint256 mintAmount,
        address mintErc20
    ) ;

    function destroy( address owner, IGegoToken.Gego calldata gego ) external ;

    function generate( address user,uint256 ruleId ) external view returns ( IGegoToken.Gego memory gego );

}

pragma solidity ^0.5.0;

contract Governance {

    address public _governance;

    constructor() public {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}