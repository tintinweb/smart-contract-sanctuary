/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {return 0;} else {return a - b;}
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IMintable is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function destroy(uint256 amount) external returns (bool);
}

interface ITreasury {
    function mint(uint256 _amount) external returns (uint256 mintAmount);
    function borrow(uint256 cashAmount) external returns (bool);
    function settle(uint256 settleAmount) external returns (bool);
    function income(uint256 cashAmount) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Treasury is Ownable, ITreasury, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IMintable public cash; // The CASH token
    IMintable public bond; // The BOND token

    IERC20 public Collateral;    // The Collateral token

    uint256 public totalCollateral; // Collateral in the Treasury

    mapping(address => bool) public authorizedBorrowers;
    mapping(address => bool) public authorizedMinters;

    mapping(address => uint256) public borrowedOf;
    mapping(address => uint256) public borrowDateOf;

    // Bond Buy/Sell Settings
    uint256 public borrowedCollateral;
    uint256 public borrowableCollateral;

    event onSetMinter(address indexed user, address indexed minter, bool authorized);
    event onSetBorrower(address indexed user, address indexed borrower, bool authorized);

    event onBorrowCollateral(address indexed user, uint256 amount, uint256 timestamp);
    event onRepayCollateral(address indexed user, uint256 amountRepaid, uint256 amountOwing, uint256 timestamp);

    event onUpdateBondToken(address indexed user, address indexed oldToken, address indexed newToken, uint256 timestamp);
    event onUpdateCashToken(address indexed user, address indexed oldToken, address indexed newToken, uint256 timestamp);

    constructor(address _cash, address _bond, address _base) Ownable() public {
        
        cash = IMintable(_cash);
        bond = IMintable(_bond);

        Collateral = IERC20(_base);
    }

    modifier isBorrower() {
        require(authorizedBorrowers[msg.sender], "UNAUTHORIZED");
        _;
    }

    modifier isMinter() {
        require(authorizedMinters[msg.sender], "UNAUTHORIZED");
        _;
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    // Display amount of unused Collateral tokens
    function surplus() public view returns (uint256){
        return totalCollateral.sub(cash.totalSupply());
    }

    // Display amount of Collateral tokens withdrawable
    function withdrawable() public view returns (uint256){

        // Unused collateral tokens
        uint256 _unusedCollateral = surplus();

        // Minimum tokens to be left behind
        uint256 _minimum = 1e18;
        
        // If there's more than the minimum available...
        if (_unusedCollateral > _minimum) {

            // Show how much
            return _unusedCollateral.sub(_minimum);

        // Otherwise...
        } else {

            // Show none
            return 0;
        }
    }

    ///////////////////////////
    // NORMAL USER FUNCTIONS //
    ///////////////////////////

    // Deposit Collateral, receive BOND
    function invest(uint256 dollarAmount) external nonReentrant {
        Collateral.safeTransferFrom(msg.sender, address(this), dollarAmount);
        totalCollateral = totalCollateral.add(dollarAmount);

        uint256 bondsAmount = dollarAmount.mul(10000).div(10000);
        bool success = bond.mint(msg.sender, bondsAmount);

        borrowableCollateral += dollarAmount;
        
        require(success, "MINTING FAILED");
    }

    // Liquidate BOND tokens, receive Collateral
    function withdraw(uint256 bondsAmount) external nonReentrant {
        uint256 dollarAmount = bondsAmount.mul(9000).div(10000);
        require(withdrawable() >= dollarAmount, "INSUFFICIENT FUNDS");

        Collateral.safeTransfer(msg.sender, dollarAmount);
        totalCollateral = totalCollateral.sub(dollarAmount);
        IERC20(bond).safeTransferFrom(msg.sender, address(this), bondsAmount);

        borrowableCollateral -= dollarAmount;
        
        bool success = bond.destroy(bondsAmount);
        require(success, "BURNING FAILED"); //insufficient bonds balance
    }

    // Deposit tokens to contribute to mintable / surplus
    function income(uint256 dollarAmount) external override nonReentrant {
        Collateral.safeTransferFrom(msg.sender, address(this), dollarAmount);
        totalCollateral = totalCollateral.add(dollarAmount);
    }

    ////////////////////////
    // BORROWER FUNCTIONS //
    ////////////////////////

    // Borrow Collateral from the Treasury
    function borrow(uint256 dollarAmount) external override isBorrower returns (bool) {
        require(borrowDateOf[msg.sender] == 0, "ALREADY_BORROWING");
        require(dollarAmount < borrowableCollateral, "INSUFFICIENT_COLLATERAL");
        
        IERC20(cash).safeTransferFrom(msg.sender, address(this), dollarAmount);
        Collateral.safeTransfer(msg.sender, dollarAmount);

        borrowedOf[msg.sender] += dollarAmount;
        borrowedCollateral += dollarAmount;
        borrowableCollateral -= dollarAmount;
        
        borrowDateOf[msg.sender] = block.timestamp;

        emit onBorrowCollateral(msg.sender, dollarAmount, block.timestamp);
        return true;
    }

    // Return Collateral to the Treasury
    function settle(uint256 settleAmount) external override isBorrower returns (bool) {
        uint256 owedByUser = borrowedOf[msg.sender];
        require(owedByUser >= settleAmount, "CANNOT_SETTLE_MORE_THAN_OWED");

        Collateral.safeTransferFrom(msg.sender, address(this), settleAmount);
        IERC20(cash).safeTransfer(msg.sender, settleAmount);

        borrowedOf[msg.sender] -= settleAmount;
        borrowedCollateral -= settleAmount;
        borrowableCollateral += settleAmount;

        uint256 owedRemaining = borrowedOf[msg.sender];
        
        emit onRepayCollateral(msg.sender, settleAmount, owedRemaining, block.timestamp);
        return true;
    }

    ///////////////////////////
    // MINTER-ONLY FUNCTIONS //
    ///////////////////////////

    // Mint CASH tokens backed by Collateral tokens
    function mint(uint256 _amount) external override isMinter returns (uint256 mintAmount){
        uint256 _unusedCollateral = surplus();

        // If there's less collateral unused than asked for...
        if (_unusedCollateral < _amount) {

            // Figure out what can be had
            mintAmount = Math.min(_unusedCollateral, _amount);
        } else {
            mintAmount = _amount;
        }

        // If the amount is more than 0, mint CASH
        if(mintAmount > 0) {
            bool success = cash.mint(msg.sender, mintAmount);
            require(success, "MINTING FAILED");
        }

        // Return CASH amount minted
        return mintAmount;
    }

    //////////////////////////
    // OWNER-ONLY FUNCTIONS //
    //////////////////////////

    // Set borrower permissions
    function setBorrower(address borrower, bool authorized) external onlyOwner returns (bool _success) {
        authorizedBorrowers[borrower] = authorized;

        emit onSetBorrower(msg.sender, borrower, authorized);
        return true;
    }

    // Set borrower permissions
    function setMinter(address minter, bool authorized) external onlyOwner returns (bool _success) {
        authorizedMinters[minter] = authorized;

        emit onSetMinter(msg.sender, minter, authorized);
        return true;
    }
}