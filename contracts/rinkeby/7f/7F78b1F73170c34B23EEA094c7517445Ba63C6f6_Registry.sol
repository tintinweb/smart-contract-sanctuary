// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Registry is Ownable {
    struct Package {
        bool exists;
        uint256 createdAt;
        uint256 destoryedAt;
        address nftContractAddress;
        uint256 nftID;
        address aiPodContractAddress;
        uint256 aiPodID;
        uint256 iNFTID;
    }

    address public canDestroyAddress;
    address public canRegisterAddress;
    mapping(uint256 => Package) public packages;

    event Register(
        address _nftContractAddress,
        uint256 _nftID,
        address _aiPodContractAddress,
        uint256 _aiPodID,
        uint256 _iNFTID
    );

    event Destroy(uint256 _inftID);

    //_canRegister must be set to the iNFT address
    constructor(address _canRegister, address _canDestroy) {
        canRegisterAddress = _canRegister;
        canDestroyAddress = _canDestroy;
    }

    function register(
        address _nftContractAddress,
        uint256 _nftID,
        address _aiPodContractAddress,
        uint256 _aiPodID,
        uint256 _iNFTID
    ) public {
        require(
            msg.sender == address(canRegisterAddress),
            "register can only be called by the canRegisterAddress"
        );
        //you can't register the same iNFT twice
        Package storage packageTest = packages[_iNFTID];
        require(
            packageTest.exists == false,
            "you can't register the same iNFT twice"
        );

        Package memory package =
            Package({
                exists: true,
                createdAt: block.timestamp,
                destoryedAt: 0,
                nftContractAddress: _nftContractAddress,
                nftID: _nftID,
                aiPodContractAddress: _aiPodContractAddress,
                aiPodID: _aiPodID,
                iNFTID: _iNFTID
            });
        packages[_iNFTID] = package;
        emit Register(
            _nftContractAddress,
            _nftID,
            _aiPodContractAddress,
            _aiPodID,
            _iNFTID
        );
    }

    //retrieves the registry.
    //Returns:
    //exists, createdAt, destoryedAt, nftContractAddress, nftID, aiPodContractAddress, aiPodID, iNFTID
    function get(uint256 _iNFTID)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            address,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        Package storage package = packages[_iNFTID];
        return (
            package.exists,
            package.createdAt,
            package.destoryedAt,
            package.nftContractAddress,
            package.nftID,
            package.aiPodContractAddress,
            package.aiPodID,
            package.iNFTID
        );
    }

    //set destroyed on an index.
    function destroy(uint256 _iNFTID) public returns (bool) {
        require(
            msg.sender == address(canDestroyAddress),
            "destroy can only be called by the canDestroyAddress"
        );
        Package storage package = packages[_iNFTID];
        package.destoryedAt = block.timestamp;
        emit Destroy(_iNFTID);
        return true;
    }

    // sets the address of the canRegister
    function setCanRegisterAddress(address _canRegister) public onlyOwner {
        canRegisterAddress = _canRegister;
    }

    // sets the address of the canDestroy
    function setCanDestroyAddress(address _canDestroy) public onlyOwner {
        canDestroyAddress = _canDestroy;
    }

    // withdraw currency accidentally sent to the smart contract
    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // reclaim accidentally sent tokens
    function reclaimToken(IERC20 token) public onlyOwner {
        require(address(token) != address(0));
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
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

