/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: f.sol


pragma solidity ^0.8.0;



interface SafeGuardWhiteList {
    function isWhiteListed(address callee) external view returns (bool);
}

contract CallAgent is Ownable {
    address constant NULL = 0x0000000000000000000000000000000000000000;
    address private _admin;
    // If white list contract is null. local whitelist filter will be used.
    address public whiteListContract = NULL;
    mapping(address => bool) filter;
    // todo add method to modify signaturedb
    mapping(bytes4 => uint256) signatures;

    // When operator changed.
    event adminChanged(address newAdmin);
    //  When operator triggered emergency
    event paused();
    // When switched to white list contract.
    event whiteListChanged(address newWhiteList);

    modifier requireAdmin() {
        require(owner() == msg.sender || admin() == msg.sender, "denied");
        _;
    }

    function ChangeAdmin(address newAdmin) public onlyOwner {
        _admin = newAdmin;
        emit adminChanged(newAdmin);
    }

    function ChangeWhiteList(address newWhiteList) public onlyOwner {
        // todo: check if the external contract is legal whitelist.
        whiteListContract = newWhiteList;
        emit whiteListChanged(newWhiteList);
    }

    // Add local target address.
    // Available when whitelist contract is null
    function addLocalWhiteList(address[] memory callee) public onlyOwner {
        for (uint256 i = 0; i < callee.length; i++) {
            filter[callee[i]] = true;
        }
    }

    function removeLocalWhiteList(address[] memory callee) public onlyOwner {
        for (uint256 i = 0; i < callee.length; i++) {
            filter[callee[i]] = false;
        }
    }

    function checkWhiteList(address callee) public view returns (bool) {
        if(whiteListContract == NULL) {
            return filter[callee];
        } 
        return SafeGuardWhiteList(whiteListContract).isWhiteListed(callee);
    }

    constructor(address owner, address adm) {
        transferOwnership(owner);
        _admin = adm;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    // Owner withdrawal ethereum.
    function withdrawEth(uint256 amount, address payable out) public onlyOwner {
        out.transfer(amount);
    }

    function withdrawErc20(uint256 amount, address erc20, address out) public onlyOwner {
        IERC20(erc20).transfer(out, amount);
    }

    function emergencyPause() public requireAdmin {
        _admin = 0x0000000000000000000000000000000000000000;
        emit paused();
    }

    // Add filtered signatures
    // src: function signature
    // address_filter: where address begins
    // Example:
    //        src: 0xa9059cbb(Transfer)
    //        address_filter: 4 (in ABI Encode of transfer(address, uint256), address begins at hex 0x4 location)
    function addSignature(bytes4[] memory src, uint256[] memory address_filter) public onlyOwner {
        for (uint256 i = 0; i < src.length; i++) {
            signatures[src[i]] = address_filter[i];
        }
    }

    function removeSignature(bytes4[] memory src) public onlyOwner {
        for (uint256 i = 0; i < src.length; i++) {
            signatures[src[i]] = 0;
        }
    }

    function toBytes4(bytes memory payload) internal pure returns (bytes4 b) {
        assembly {
            b := mload(add(payload, 0x20))
        }
    }

    function toAddress(bytes memory payload) internal pure returns (address b) {
        assembly {
            b := mload(add(payload, 0x20))
        }
    }

    function callAgent(address callee, uint256 ethAmount, bytes calldata payload) public requireAdmin returns (bool, bytes memory) {
        if(ethAmount != 0) {
            if(!checkWhiteList(callee)) {
                revert("no whitelist");
            }
        } else {
            bytes4 signature = toBytes4(payload[:4]);
            uint256 p = signatures[signature];
            if(p > 0) {
                address addr = toAddress(payload[p:p + 32]);
                if(!checkWhiteList(addr)) {
                    revert("no whitelist");
                }
            }
        }
        return callee.call{value: ethAmount}(payload);
    }

    receive() external payable {}
    fallback() external payable {}

}