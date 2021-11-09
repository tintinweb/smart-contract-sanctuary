// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ILO is Ownable { 
    IERC20 public MUFT;
    IERC20 public MUFTSWAP;

    uint256 public bnb_muftswap_rate = 54;
    uint256 public muft_muftswap_rate = 12218;
    // Because rate would be float, so need to use Decimal
    uint256 public rate_decimal = 10 ** 6;
    uint256 public bnb_hardcap = 10 * 10 ** 6 * 10 ** 8;
    uint256 public muft_hardcap = 10 * 10 ** 6 * 10 ** 8;

    uint256 public bnb_total = 0;
    uint256 public muft_total = 0;

    uint256 public bnb_limit_peruser = 2 * 10 ** 18;
    uint256 public muft_limit_peruser = 250 * 10 ** 6 * 10 ** 18;
    struct UserInfo {
        uint256 bnb;
        uint256 muft;
        uint256 muft_swap;
    }

    mapping(address => UserInfo) private userInfos;
    // Security purpose
    mapping(address => bool) private isBeingCommit;
    mapping(address => bool) private isBeingWithdraw;

    event CommitBNB(address indexed, uint256 amount);
    event CommitMUFT(address indexed, uint256 amount);
    event WithdrawMuftSwap(address indexed, uint256 amount);

    constructor (
        address _MUFT, address _MUFTSWAP
    ) {
        MUFT = IERC20(_MUFT);
        MUFTSWAP = IERC20(_MUFTSWAP);
    }

    modifier isNotBeingCommit() {
        require(isBeingCommit[msg.sender] == false, "Not able to this action before another progress");
        _;
    }
    modifier isNotBeingWithdraw() {
        require(isBeingWithdraw[msg.sender] == false, "Not able to this action before another progress");
        _;
    }

    modifier BNBCommitable() {
        require(bnb_hardcap >= bnb_total, "BNB: Overpass hardcap");
        _;
    }

    modifier MuftCommitable() {
        require(muft_hardcap >= muft_total, "Muft: Overpass hardcap");
        _;
    }

    // Convert BNB to MUFT_SWAP
    function commitBNB() BNBCommitable isNotBeingCommit isNotBeingWithdraw external payable{
        require(msg.value > 0, "BNB: not enough");
        require(userInfos[msg.sender].bnb + msg.value <= bnb_limit_peruser, "BNB Limit per user");
        isBeingCommit[msg.sender] = true;
        

        UserInfo storage user = userInfos[msg.sender];
        user.bnb = user.bnb + msg.value;

        bnb_total = bnb_total + msg.value;

        uint256 muft_swap_amount = msg.value * rate_decimal / bnb_muftswap_rate;

        user.muft_swap = user.muft_swap + muft_swap_amount;

        emit CommitBNB(msg.sender, msg.value);

        isBeingCommit[msg.sender] = false;
    }

    // Convert MUFT to MUFT_SWAP
    function commitMuft(uint256 _amount) MuftCommitable isNotBeingCommit isNotBeingWithdraw external payable{
        require(_amount > 0, "BNB: not enough");
        require(userInfos[msg.sender].muft + _amount <= muft_limit_peruser, "MUFT Limit per user");
        isBeingCommit[msg.sender] = true;
        
        MUFT.transferFrom(msg.sender, address(this), _amount);

        UserInfo storage user = userInfos[msg.sender];
        user.muft = user.muft + _amount;

        muft_total = muft_total + _amount;

        uint256 muft_swap_amount = msg.value / muft_muftswap_rate;
        user.muft_swap = user.muft_swap + muft_swap_amount;

        emit CommitMUFT(msg.sender, msg.value);

        isBeingCommit[msg.sender] = false;
    }

    // Withdraw MUFT_SWAP
    function withdrawMuftSwap(uint256 _amount) isNotBeingCommit isNotBeingWithdraw external {
        require(userInfos[msg.sender].muft_swap >= _amount, "Withdraw MUFT_SWAP: overpass the amount");
        isBeingWithdraw[msg.sender] = true;

        UserInfo storage user = userInfos[msg.sender];
        user.muft_swap = user.muft_swap - _amount;
        MUFTSWAP.transfer(msg.sender, _amount);

        emit WithdrawMuftSwap(msg.sender, _amount);
        isBeingWithdraw[msg.sender] = false;
    }

    // Withdraw BNB from pool
    function withdrawBNB() external onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(msg.sender, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // Set the rate for muft to muft_swap
    function setMuftToMuftSwap (uint256 _rate) external onlyOwner{
        require(muft_muftswap_rate != _rate, "Set Rate: already set");
        muft_muftswap_rate = _rate;
    }

    // Set the rate for bnb to muft_swap
    function setBnbToMuftSwap (uint256 _rate) external onlyOwner{
        require(bnb_muftswap_rate != _rate, "Set Rate: already set");
        bnb_muftswap_rate = _rate;
    }

    
    // Set the rate decimal
    function setRateDecimal (uint256 _decimal) external onlyOwner{
        require(rate_decimal != _decimal, "Set Rate: already set");
        rate_decimal = _decimal;
    }
    
    // Get user's tokens info
    function getUserInfo(address sender) external view returns(UserInfo memory) {
        return userInfos[sender];
    }

}

// SPDX-License-Identifier: MIT

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