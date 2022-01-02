/**
 *Submitted for verification at polygonscan.com on 2021-12-31
*/

// File: contracts/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
// File: contracts/interface/IERC20.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 is IERC20Metadata {
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
     * @dev Mints `amount` tokens to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function mint(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Burns `amount` tokens from `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function burn(address recipient, uint256 amount) external returns (bool);

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
// File: contracts/utils/Context.sol


// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/utils/Ownable.sol

//SPDX-License-Identifier:None
pragma solidity 0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address payable private _owner;
    address private _nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipNominated(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address multisig) {
        _owner = payable(multisig);
        emit OwnershipTransferred(address(0), multisig);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
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
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    /**
     * @dev Nominate new Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function nominateNewOwner(address newOwner) external onlyOwner {
        _nominatedOwner = newOwner;
        emit OwnershipNominated(_owner,newOwner);
    }

    /**
     * @dev Nominated Owner can accept the Ownership of the contract.
     * Can only be called by the nominated owner.
     */
    function acceptOwnership() external {
        require(msg.sender == _nominatedOwner, "Ownable: You must be nominated before you can accept ownership");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = payable(_nominatedOwner);
        _nominatedOwner = address(0);
    }
}
// File: contracts/TokenSale.sol


pragma solidity 0.8.0;



contract TokenSale is Ownable {

    /// @dev Instance for the xWife Token
    IERC20 private xWifeToken;

    uint256 public saleStartTimestamp = block.timestamp;

    uint256 public initialPhaseDuration;

    uint256 public rate = 5000;
    
    mapping(address => uint256) public lockedWives;

    event Purchased(address indexed user, uint256 paid, uint256 received);

    event TokenContractUpdated(address xWifeAddress);

    /**
     * @dev initialize the token address
     *
     * @param xWifeAddress Address of xWifeToken contract
     * @param ownerAddress Admin access of this contract
     * @param initialPhaseLength Duration of initial phase in seconds
     *
     */
    constructor (IERC20  xWifeAddress, address ownerAddress, uint256 initialPhaseLength) Ownable(ownerAddress) {

        require(address(xWifeAddress) != address(0), "Invalid Token address.");
        require(ownerAddress != address(0), "Invalid Owner address.");

        xWifeToken = xWifeAddress;
        initialPhaseDuration = initialPhaseLength; //5184000 sec = 2 months
    }

    /**
    * @dev Returns xWife tokens `receivedAmount` to be returned by paying PLS `purchaseAmount` amount.
    *
    */
    function getReturnAmount(uint256 purchaseAmount) public view returns(uint256) {
        uint256 receivedAmount = purchaseAmount*rate;
        return receivedAmount;
    }

    /**
    * @dev Sets the return amount of tokens `rate` in return of 1 wei PLS.
    *
    */
    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function isInitialPhase() public view returns(bool) {
        if(block.timestamp > (saleStartTimestamp + initialPhaseDuration)) {
            return false;
        }
        return true;
    }

    /**
    * @dev User buys some xWife tokens by paying PLS.
    *
    */
    function buy() public payable {
        uint256 purchaseAmount = msg.value;
        uint256 receivedAmount = getReturnAmount(purchaseAmount);

        if(isInitialPhase())  lockedWives[_msgSender()] += receivedAmount;
        else                  xWifeToken.mint(_msgSender(), receivedAmount);

        (bool sent, bytes memory data) = owner().call{value: purchaseAmount}("");
        require(sent, "Failed to send PLS");
        emit Purchased(_msgSender(), purchaseAmount, receivedAmount);
    }

    /**
    * @dev Unlock locked xWifeTokens after initial phase ends.
    *
    */
    function unlockWives(uint256 amount) external returns(bool) {
        require(!isInitialPhase(), "Initial Phase active");
        require(amount >= lockedWives[_msgSender()], "Not enough locked balance");

        lockedWives[_msgSender()] -= amount;
        xWifeToken.mint(_msgSender(), amount);

        return true;
    }

    /**
    * @dev Fallback function if ether is sent to address insted of buyTokens function
    **/
    receive () external payable {
        buy();
    }

    /**
    * @dev Update xWifeToken Contract address.
    */
    function updateTokenAddress(IERC20 tokenAddress) external onlyOwner {
        require(address(tokenAddress) != address(0), "Invalid address.");
        xWifeToken = tokenAddress;
        emit TokenContractUpdated(address(tokenAddress));
    }

}