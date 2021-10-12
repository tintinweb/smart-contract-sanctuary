/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    
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

contract WhaleNetworkPartner is Context, Ownable {
    using SafeMath for uint256;

    IERC20 private _token;
    uint256 private _taxFee;
    uint256 private _burnFee;
    uint256 private _serviceFee;
    uint256 private _partnerShare;
    address private _partnerAddress;
    bool private _isInitialized = false;

    modifier onlyPartners() {
        require(_msgSender() == owner() || _msgSender() == _partnerAddress, "WhaleNetworkPartner: Only the contract owner or the partner can withdraw the funds");
        _;
    }

    constructor(IERC20 token) {
        require(address(token) != address(0), "WhaleNetworkPartner: Token address can not be zero address");
        _token = token;
    }

    function taxFee() public view returns(uint256){
        return _taxFee;
    }
    function burnFee() public view returns(uint256){
        return _burnFee;
    }
    function serviceFee() public view returns(uint256){
        return _serviceFee;
    }
    function partnerShare() public view returns(uint256){
        return _partnerShare;
    }
    function partnerAddress() public view returns(address){
        return _partnerAddress;
    }
    function tokenAddress() public view returns(address){
        return address(_token);
    }
    function init(uint256 tax, uint256 burn, uint256 service, uint256 partner, address partnerAddr) onlyOwner() external returns(bool){
        require(!_isInitialized, "WhaleNetworkPartner: Contract is already initialized.");
        _taxFee = tax;
        _burnFee = burn;
        _serviceFee = service;
        _partnerShare = partner;
        _partnerAddress = partnerAddr;
        _isInitialized = true;
        return _isInitialized;
    }

    function withdrawFunds() external onlyPartners() returns(uint256,uint256) {
        uint256 funds = _token.balanceOf(address(this));
        _token.transfer(_partnerAddress, funds.div(100).mul(_partnerShare));
        _token.transfer(owner(), _token.balanceOf(address(this)));
        return (funds.div(100).mul(_partnerShare), funds.sub(funds.div(100).mul(_partnerShare)));
    }

    function estimateWithdraw() external view onlyPartners() returns(uint256,uint256) {
        uint256 funds = _token.balanceOf(address(this));
        return (funds.div(100).mul(_partnerShare), funds.sub(funds.div(100).mul(_partnerShare)));
    }
}