// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/*
           ████████   ████████████████                 █████                     ███████
           ████████   ███████████████████          ███████████████████           ████████
          ████████   ██████████████████████      █████      ██  █████████       ████████
          ████████   ████████     ██████████    ████      █   █   ████████      ████████
          ███████   ████████        ████████   ███       █  █    █████████     ████████
         ████████   ████████        ████████  ████         ████████████████    ████████
         ████████   ███████         ████████  ████████████████████████   ██    ████████
        ████████   ████████        ████████   █████████████████████     ██    ████████
        ████████   ████████       █████████    █████████████████        ██    ████████
        ███████   █████████     ██████████      █  █████████████      ███        ████
       ████████   ██████████████████████      ████ ████████████      ██      ██████████████████
       ████████  ██████████████████████      █ ██  ███████████    ███       ████ ██████████████
      ████████   ██████████████████         █ ██      █████████████        ██ █ ███████████████
                                           █ █            ████            ██ █ ███████████████
                                          ███                   ██      █████
                                         ███       ██     █   ████    ██  █
                                        ██      ██ ██    █   ██ █   ███ ███
                                      ███     ██ ████  ███ ██   ████  █  █  ██
                                    ████    ██ ██   ██  ███              ███
                                     ██   ██ █
                                     ██ ██
                                      ██
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        //unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        //}
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract IDOLMaster is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public idol;
    IERC20 public busd;
    IERC20 public usdt;
    IERC20 public idolD;
    IERC20 public idolP;

    bool public isPreSale = false;
    bool public isClaimPreSale = false;
    bool public isClaimPrivateSale = false;

    uint256 public idolDPerUsd = 20;

    event Stake(address indexed user, uint256 amount);

    event Redeem(address indexed user, uint256 amount);

    event BUSDWithdrawn(uint256 amount);

    event IDOLWithdrawn(uint256 amount);

    event IDOLDWithdrawn(uint256 amount);

    event MaxStakeAmountChanged(uint256 maxStakeAmount);

    event EnablePreSale(bool ststus);
    event EnableClaimPreSale(bool ststus);
    event EnableClaimPrivateSale(bool ststus);

    event BalanceOfIdolP(uint256 amount);
    event BalanceOfIdol(uint256 amount);

    constructor(IERC20 _idol, IERC20 _busd, IERC20 _usdt, IERC20 _idolD, IERC20 _idolP) public {
        require(
            address(_idol) != address(0) &&
            address(_busd) != address(0) &&
            address(_usdt) != address(0) &&
            address(_idolD) != address(0) &&
            address(_idolP) != address(0),
            "zero address in constructor"
        );
        idol = _idol;
        busd = _busd;
        usdt = _usdt;
        idolD = _idolD;
        idolP = _idolP;
    }

    function stakeBUSD(uint256 amount) external nonReentrant {

        require(isPreSale, "Not Open Pre Sale");

        require(amount <= busd.balanceOf(msg.sender), "BUSD is not enough");

        uint256 idolPAmount = amount.mul(idolDPerUsd);
        require(idolPAmount <= idolP.balanceOf(address(this)), "IDOL-P is not enough");

        busd.safeTransferFrom(msg.sender, address(this), amount);
        idolP.safeTransfer(msg.sender, idolPAmount);
        emit Stake(msg.sender, amount);
        emit BalanceOfIdolP(idolP.balanceOf(address(this)));
    }

    function stakeUSDT(uint256 amount) external nonReentrant {

        require(isPreSale, "Not Open Pre Sale");

        require(amount <= usdt.balanceOf(msg.sender), "USDT is not enough");

        uint256 idolPAmount = amount.mul(idolDPerUsd);
        require(idolPAmount <= idolP.balanceOf(address(this)), "IDOL-P is not enough");

        usdt.safeTransferFrom(msg.sender, address(this), amount);
        idolP.safeTransfer(msg.sender, idolPAmount);
        emit Stake(msg.sender, amount);
        emit BalanceOfIdolP(idolP.balanceOf(address(this)));
    }

    function redeemIdolD() external nonReentrant {

        require(isPreSale, "Not Open Claim");

        uint256 amountIdolD = idolD.balanceOf(msg.sender);

        require(amountIdolD <= idol.balanceOf(address(this)), "IDOL is not enough");

        idolD.safeTransferFrom(msg.sender, address(this), amountIdolD);
        idol.safeTransfer(msg.sender, amountIdolD);
        emit Redeem(msg.sender, amountIdolD);
        emit BalanceOfIdol(idol.balanceOf(address(this)));

    }

    function redeemIdolP() external nonReentrant {

        require(isPreSale, "Not Open Claim");

        uint256 amountIdolP = idolP.balanceOf(msg.sender);
        
        require(amountIdolP <= idol.balanceOf(address(this)), "IDOL is not enough");

        idolP.safeTransferFrom(msg.sender, address(this), amountIdolP);
        idol.safeTransfer(msg.sender, amountIdolP);
        emit Redeem(msg.sender, amountIdolP);
        emit BalanceOfIdol(idol.balanceOf(address(this)));

    }

    function withdrawBUSD(uint256 amount) external onlyOwner {
        busd.safeTransfer(msg.sender, amount);
    }

    function withdrawUSDT(uint256 amount) external onlyOwner {
        usdt.safeTransfer(msg.sender, amount);
    }

    function withdrawIDOL(uint256 amount) external onlyOwner {
        idol.safeTransfer(msg.sender, amount);
    }

    function withdrawIDOLD(uint256 amount) external onlyOwner {
        idolD.safeTransfer(msg.sender, amount);
    }

    function withdrawIDOLP(uint256 amount) external onlyOwner {
        idolP.safeTransfer(msg.sender, amount);
    }

    function setEnablePreSale(bool state)  external onlyOwner {
        isPreSale = state;
        emit EnablePreSale(isPreSale);
    }

    function setEnableClaimPreSale(bool state)  external onlyOwner {
        isClaimPreSale = state;
        emit EnableClaimPreSale(isClaimPreSale);
    }

    function setEnableClaimPrivateSale(bool state)  external onlyOwner {
        isClaimPrivateSale = state;
        emit EnableClaimPrivateSale(isClaimPrivateSale);
    }

    function balanceOfIdolP() external view returns (uint256) {
        return idolP.balanceOf(address(this));
    }

    function balanceOfIdolD() external view returns (uint256) {
        return idolD.balanceOf(address(this));
    }

    function balanceOfIdol() external view returns (uint256) {
        return idol.balanceOf(address(this));
    }

    function balanceOfUsdt() external view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    function balanceOfBusd() external view returns (uint256) {
        return busd.balanceOf(address(this));
    }

}

