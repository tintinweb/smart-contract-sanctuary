/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

//SPDX-License-Identifier: MIT

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

interface IERC1155 {
	event TransferSingle(
		address indexed _operator,
		address indexed _from,
		address indexed _to,
		uint256 _id,
		uint256 _amount
	);

	event TransferBatch(
		address indexed _operator,
		address indexed _from,
		address indexed _to,
		uint256[] _ids,
		uint256[] _amounts
	);

	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	event URI(string _amount, uint256 indexed _id);

	function mint(
		address _to,
		uint256 _id,
		uint256 _quantity,
		bytes calldata _data
	) external;

	function create(
		uint256 _maxSupply,
		uint256 _initialSupply,
		string calldata _uri,
		bytes calldata _data
	) external returns (uint256 tokenId);

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _id,
		uint256 _amount,
		bytes calldata _data
	) external;

	function safeBatchTransferFrom(
		address _from,
		address _to,
		uint256[] calldata _ids,
		uint256[] calldata _amounts,
		bytes calldata _data
	) external;

	function balanceOf(address _owner, uint256 _id) external view returns (uint256);

	function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
		external
		view
		returns (uint256[] memory);

	function setApprovalForAll(address _operator, bool _approved) external;

	function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

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

contract EggPurchase is Ownable, IERC1155Receiver {
    using SafeMath for uint256;
    
    uint256 public nftid;
    // address => purchaseId => timestamp
    mapping(address => mapping(uint256 => uint256)) private userPurchased;
    mapping(address => uint256) private userNextPurchasedId;
    address public eggAddress;
    bool public active = false;
    uint256 public startTimestamp;
    address payable private devWallet;
    
    struct SalePeriod {
        uint256 duration;
        uint256 price;
        uint256 eggAmount;
        uint256 eggsSoldThisRound;
    }
    
    SalePeriod[] public salePeriods;
    
    constructor(address _eggAddress, uint256 _nftid, address payable _devWallet) public {
        eggAddress = _eggAddress;
        nftid = _nftid;
        devWallet = _devWallet;
    }
    
    function setActive(bool isActive) public onlyOwner {
        active = isActive;
    }
    
    function setDevWallet(address payable dev) public onlyOwner {
        devWallet = dev;
    }
    
    function initiateSale(uint256 _startTimestamp) public onlyOwner {
        
        if(_startTimestamp == 0) {
            startTimestamp = now;
        } else {
            startTimestamp = _startTimestamp;
        }
        
        active = true;
    }
    
    
    /*
        24h = 86400, 0.111 ether = 111*10**15
        
        Planned sale setup:
        [86400,86400,86400,86400,86400,86400,86400,86400,86400,86400,86400,86400,86400,86400]
        [111,111,222,222,333,333,444,444,555,555,444,333,222,111]
        [15,15,15,15,15,15,15,15,15,15,15,15,15,15]
        [111,111,111,111,111,111,111,111,111,111,0,0,0,0]
    */
    
    function setSalePeriods(uint256[] memory _duration, uint256[] memory _priceBase, uint256[] memory additionalDecimals, uint256[] memory _eggAmount) public onlyOwner {
        
        delete salePeriods;
        
        for (uint256 i = 0; i < _duration.length; i++) {
            salePeriods.push(SalePeriod(_duration[i], _priceBase[i].mul(10**additionalDecimals[i]), _eggAmount[i], 0));
        }
        
    }
    
    // returns: id, current price, total amount of eggs sold, total eggs available (until now)
    function getSaleRoundInfo() public view returns (uint256, uint256, uint256, uint256) {
        
        uint256 lastTimestamp = startTimestamp;
        uint256 totalEggsSold = 0;
        uint256 totalEggsAvailable = 0;
        
        for (uint256 i = 0; i < salePeriods.length; i++) {     
            SalePeriod storage salePeriod = salePeriods[i];
            lastTimestamp = lastTimestamp.add(salePeriod.duration);
            totalEggsSold = totalEggsSold.add(salePeriod.eggsSoldThisRound);
            totalEggsAvailable = totalEggsAvailable.add(salePeriod.eggAmount);
            
            if(now <= lastTimestamp) {
                return (i, salePeriod.price, totalEggsSold, totalEggsAvailable);
            }
        }
        
        return (0,0,totalEggsSold,0);
        
    }
    
    function getUserPurchased(address buyer, uint256 id) public view returns (uint256) {
        return userPurchased[buyer][id];
    }
    
    function getUserNextPurchasedId(address buyer) public view returns (uint256) {
        return userNextPurchasedId[buyer];
    }
    
    function userBought24h(address buyer) public view returns (uint256) {
        
        uint256 maxRange = 0;
        uint256 bought24h = 0;
        
        if(userNextPurchasedId[buyer] >= 5) {
            maxRange = 5;
        } else {
            maxRange = userNextPurchasedId[buyer];
        }
        
        
        for(uint256 i=1; i<=maxRange; i++) {
            if(userPurchased[buyer][userNextPurchasedId[buyer].sub(i)].add(24*60*60) >= now) {
                bought24h++;
            }
        }
        
        return bought24h;
    }

    function purchase() public payable {
        purchase(1);
    }

    function purchase(uint256 amount) public payable {
        
        require(active == true && startTimestamp > 0, "Cannot buy: Sale not active yet");
        
        (uint256 currentRoundId, uint256 currentPrice, uint256 totalEggsSold, uint256 totalEggsAvailable) = getSaleRoundInfo();
        
        require(totalEggsAvailable > totalEggsSold, "Eggs sold out. Try again during the next round.");
        uint256 eggsAvailableNow = totalEggsAvailable.sub(totalEggsSold);
        
        require(msg.value == currentPrice * amount, "You need to send the exact NFT price");
        require(amount > 0, "Why would you want zero eggs");
        require(amount <= 5, "You cannot buy more than 5 Eggs at once");
        require(amount <= eggsAvailableNow, "You cannot buy more than the available amount");
        require(userBought24h(msg.sender).add(amount) <= 5, "You cannot purchase more than 5 NFTs in 24h");
        require(IERC1155(eggAddress).balanceOf(address(this), nftid) > amount, "Cannot buy: not enough Eggs!");
        
        salePeriods[currentRoundId].eggsSoldThisRound = salePeriods[currentRoundId].eggsSoldThisRound.add(amount);
        
        IERC1155(eggAddress).safeTransferFrom(address(this), msg.sender, nftid, amount, "");
        if(devWallet != address(0)) {
            devWallet.transfer(msg.value);
        }
        
        for(uint256 i = 0; i < amount; i++) {
            userPurchased[msg.sender][userNextPurchasedId[msg.sender]] = now;
            userNextPurchasedId[msg.sender] = userNextPurchasedId[msg.sender] + 1;
        }
    }
    
    function withdrawEggs(address _to) public onlyOwner {
        uint256 amount = IERC1155(eggAddress).balanceOf(address(this), nftid);
        IERC1155(eggAddress).safeTransferFrom(address(this), _to, nftid, amount, "");
    }
    
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner {
        _to.transfer(_amount);
    }

    function withdrawTokens(address _token, address _to, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(_to, _amount);
    }
    
    
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    
    
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
    
}