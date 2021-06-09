/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT
// File: openzeppelin-solidity/contracts/utils/Context.sol



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

// File: openzeppelin-solidity/contracts/access/Ownable.sol




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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



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

// File: contracts/EthWalletFeeIncluded.sol



pragma solidity 0.8.4;



contract EthWalletFeeIncluded is Ownable {

    struct depSettings {
        uint128 size;
        uint128 fee;
    }

    //depSettings private _depositSettings;
    //mapping(address => depSettings) private _tokenDepositAmounts;

    mapping(uint8 => depSettings) private _depositSettings;
    mapping(uint8 => mapping (address => depSettings)) private _tokenDepositAmounts;
    mapping(uint256 => bool) private _networksAvailable;

    event DepositEthMade(
        address sender,
        uint128 amount,
        uint8 network
    );

    event DepositTokenMade(
        address tokenAddress,
        address sender,
        uint256 amount,
        uint8 network
    );

    constructor(uint8[] memory _networks, uint128[] memory _depositSize, uint128[] memory _depositFee) {
        //_depositSettings = depSettings(_depositSize, _depositFee);
        require(_networks.length == _depositSize.length, "Invalid array size");
        require(_depositSize.length == _depositFee.length, "Invalid array size");
        for(uint8 i=0; i < _networks.length; i++){
            _networksAvailable[_networks[i]] = true;
            _depositSettings[_networks[i]] = depSettings(_depositSize[i], _depositFee[i]);
        }
    }

    function deposit(uint8 network) external payable {
        require(_networksAvailable[network], "Network is not available");
        depSettings memory ds = _depositSettings[network];
        require(msg.value == ds.size, 'EthWallet: invalid eth amount');
        emit DepositEthMade(_msgSender(), ds.size - (ds.size*ds.fee)/100, network);
    }

    function depositToken(address tokenAddress, uint8 network) external {
        require(_networksAvailable[network], "Network is not available");
        depSettings memory tokenDepositSize = _tokenDepositAmounts[network][tokenAddress];
        require(tokenDepositSize.size != 0, 'EthWallet: token not allowed');

        require(IERC20(tokenAddress).transferFrom(_msgSender(), address(this),
        tokenDepositSize.size ), "Can not get tokens");

        emit DepositTokenMade(tokenAddress, _msgSender(), tokenDepositSize.size - (tokenDepositSize.size*tokenDepositSize.fee)/100, network);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount != 0, 'EthWallet: 0 transfer');
        payable(owner()).transfer(amount);
    }

    function withdrawToken(address tokenAddress, uint256 amount) external onlyOwner {
        require(amount != 0, 'EthWallet: 0 transfer');
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function setDepositSize(uint8 network, uint128 newSize) external onlyOwner {
        _depositSettings[network].size = newSize;
    }

    function setDepositFee(uint8 network, uint128 newFee) external onlyOwner {
        _depositSettings[network].fee = newFee;
    }

    function setDepositSettings(uint8 network, uint128 _depositSize, uint128 _depositFee) external onlyOwner {
        _depositSettings[network] = depSettings(_depositSize, _depositFee);
    }

    function setTokenDepositSettings(address tokenAddress, uint8 network, uint128 _depositSize, uint128 _depositFee) external onlyOwner {
        depSettings memory tokenDepositSettings = _tokenDepositAmounts[network][tokenAddress];
        tokenDepositSettings.size = _depositSize;
        tokenDepositSettings.fee = _depositFee;

        _tokenDepositAmounts[network][tokenAddress] = tokenDepositSettings;
    }

    function forbidTokenDeposits(uint8 network, address tokenAddress) external onlyOwner {
        _tokenDepositAmounts[network][tokenAddress].size = 0;
        _tokenDepositAmounts[network][tokenAddress].fee = 0;
    }

    function addNetwork(uint8 network, uint128 _depositSizeEth, uint128 _depositFeeEth) external onlyOwner {
        require(!_networksAvailable[network], "This network number exist");
        _networksAvailable[network] = true;
        _depositSettings[network] = depSettings(_depositSizeEth, _depositFeeEth);
    }

    function removeNetwork(uint8 network) external onlyOwner {
        require(_networksAvailable[network], "Network is not available");
        _networksAvailable[network] = false;
        _depositSettings[network].size = 0;
        _depositSettings[network].fee = 0;
    }

    function depositFee(uint8 network) external view returns(uint128) {
        return _depositSettings[network].fee;
    }

    function depositSize(uint8 network) external view returns(uint128) {
        return _depositSettings[network].size;
    }

    function depositTokenSize(uint8 network, address tokenAddress) external view returns(uint128) {
        return _tokenDepositAmounts[network][tokenAddress].size;
    }

    function depositTokenFee(uint8 network, address tokenAddress) external view returns(uint128) {
        return _tokenDepositAmounts[network][tokenAddress].fee;
    }
}