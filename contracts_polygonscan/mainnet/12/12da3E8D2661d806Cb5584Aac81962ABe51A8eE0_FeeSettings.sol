/**
 *Submitted for verification at polygonscan.com on 2021-10-21
*/

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

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

// File: original_contracts/interfaces/IFeeSettings.sol

pragma solidity 0.5.17;


interface IFeeSettings {

    function getFeeWallet() external view returns(address);

    function getFeePercentage() external view returns(uint256);

    function getMinimumFee() external view returns(uint256);

    function changeFeeWallet(address feeWallet) external;

    function changeFeePercentage(uint256 feePercentage) external;

    function changeMinimuFee(uint256 minimumFee) external;
}

// File: original_contracts/FeeSettings.sol

pragma solidity 0.5.17;




contract FeeSettings is Ownable, IFeeSettings {

    address private _feeWallet;

    //100 for 1%
    uint256 private _feePercentage;

    uint256 private _minimumFee;

    constructor(
        address feeWallet,
        uint256 feePercentage,
        uint256 minimumFee
    )
        public
    {
        _feeWallet = feeWallet;
        _feePercentage = feePercentage;
        _minimumFee = minimumFee;
    }

    event FeeWalletChanged(address feeWallet);
    event FeePercentageChanged(uint256 feePercentage);
    event MinimumFeeChanged(uint256 minFee);

    function getFeeWallet() external view returns(address) {
        return _feeWallet;
    }

    function getFeePercentage() external view returns(uint256) {
        return _feePercentage;
    }

    function getMinimumFee() external view returns(uint256) {
        return _minimumFee;
    }

    function changeFeeWallet(address feeWallet) external onlyOwner {
        require(feeWallet != address(0), "Invalid Fee Wallet");
        _feeWallet = feeWallet;
        emit FeeWalletChanged(feeWallet);
    }

    function changeFeePercentage(uint256 feePercentage) external onlyOwner {
        _feePercentage = feePercentage;
        emit FeePercentageChanged(feePercentage);
    }

    function changeMinimuFee(uint256 minimumFee) external onlyOwner {
        _minimumFee = minimumFee;
        emit MinimumFeeChanged(minimumFee);
    }
}