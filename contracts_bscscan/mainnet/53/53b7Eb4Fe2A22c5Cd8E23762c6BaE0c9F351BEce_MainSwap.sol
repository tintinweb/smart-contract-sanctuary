/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

contract Ownable is OwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    
    function mint(address to, uint256 amount) external returns(bool);

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

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface CustomExchange{
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}
    function getBestQuotation(uint orderType, address[] memory path, uint256 amountIn) external view returns (uint256);
    function executeSwapping(uint orderType, address[] memory path, uint256 assetInOffered, uint256 assetOutExpected, address to, uint256 deadline) external payable returns(uint[] memory);
}




contract MainSwap is Ownable {
    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}
    using SafeMath for uint256;
    uint256 public fees = 1000000;            // 6 decimal places added
    mapping (uint=>address) public exchangeList;
    mapping (address=>bool) public whitelistedToken;
    uint public totalExchanges = 0;
    
    constructor() {
    }
    
    
    function addExchange(address _exchangeAddress) external onlyOwner {
        exchangeList[totalExchanges] = _exchangeAddress;
        totalExchanges = totalExchanges + 1;
    }
    
    function updateExchange(address _exchangeAddress, uint _dexId) external onlyOwner {
        exchangeList[_dexId] = _exchangeAddress;
    }
    
    function setWhiteListToken(address _tokenAddress, bool _flag) external onlyOwner {
        whitelistedToken[_tokenAddress] = _flag;
    }
    
    function updateFees(uint256 _newFees) external onlyOwner {
        fees = _newFees;
    }
    
    function getFeesAmount(uint256 temp) internal view returns (uint256){
        return (temp.mul(fees).div(100000000));
    }
    
    function getBestQuote(uint orderType, address[] memory path, uint256 amountIn) public view returns (uint, uint256) {
        require((orderType==0)||(orderType==1)||(orderType==2),"Invalid orderType");
        uint256 bestAmountOut = 0;
        uint dexId = 0;
        uint256 amountInFin = amountIn;
        bool feeAfterSwap;
        if(OrderType(orderType) == OrderType.EthForTokens){
            amountInFin = amountIn.sub(getFeesAmount(amountIn));
        }
        if (OrderType(orderType) == OrderType.TokensForEth){
            feeAfterSwap = true;
        }
        if (OrderType(orderType) == OrderType.TokensForTokens){
            if(whitelistedToken[path[path.length-1]]){
                feeAfterSwap = true;
            }else{
                amountInFin = amountIn.sub(getFeesAmount(amountIn));
            }
        }
        for(uint i=0;i<totalExchanges;i++){
            CustomExchange ExInstance = CustomExchange(exchangeList[i]);
            uint256 amountOut;
            try
                ExInstance.getBestQuotation(orderType, path,amountInFin) returns(uint256 _amountOut){
                    if(feeAfterSwap){
                        amountOut = _amountOut.sub(getFeesAmount(_amountOut));
                    }else{
                        amountOut = _amountOut; 
                    }
                    
                if(bestAmountOut<amountOut){
                bestAmountOut = amountOut;
                dexId = i;
                }
            }catch{}
            
        }
        return (dexId, bestAmountOut);
    }
    
    function executeSwap(uint dexId, uint orderType, address[] memory path, uint256 assetInOffered, uint256 assetOutExpected, uint256 deadline) external payable{
        uint[] memory swapResult;
        uint256 amountInFees;
        CustomExchange ExInstance = CustomExchange(exchangeList[dexId]);
        if(OrderType(orderType) == OrderType.EthForTokens){
            require(msg.value >= assetInOffered, "amount send is less than mentioned");
            amountInFees = getFeesAmount(assetInOffered);
            TransferHelper.safeTransferETH(owner, amountInFees);
            ExInstance.executeSwapping{value:assetInOffered.sub(amountInFees)}(orderType, path, assetInOffered.sub(amountInFees), assetOutExpected, msg.sender, deadline);
        } else if(OrderType(orderType) == OrderType.TokensForEth) {
            TransferHelper.safeTransferFrom(path[0], msg.sender, exchangeList[dexId], assetInOffered);
            swapResult = ExInstance.executeSwapping(orderType, path, assetInOffered, assetOutExpected, address(this), deadline);
            amountInFees = getFeesAmount(uint256(swapResult[1]));
            TransferHelper.safeTransferETH(owner, amountInFees);
            TransferHelper.safeTransferETH(msg.sender, swapResult[1].sub(amountInFees));
        }else if (OrderType(orderType) == OrderType.TokensForTokens){
            if(whitelistedToken[path[path.length-1]]){
                TransferHelper.safeTransferFrom(path[0], msg.sender, exchangeList[dexId], assetInOffered);
                swapResult = ExInstance.executeSwapping(orderType, path, assetInOffered, assetOutExpected, address(this), deadline);
                amountInFees = getFeesAmount(swapResult[1]);
                TransferHelper.safeTransfer(path[path.length-1], owner, amountInFees);
                TransferHelper.safeTransfer(path[path.length-1], msg.sender, swapResult[1].sub(amountInFees));
            }else{
                amountInFees = getFeesAmount(assetInOffered);
                TransferHelper.safeTransferFrom(path[0], msg.sender, owner, amountInFees);
                TransferHelper.safeTransferFrom(path[0], msg.sender, exchangeList[dexId], assetInOffered.sub(amountInFees));
                swapResult = ExInstance.executeSwapping(orderType, path, assetInOffered.sub(amountInFees), assetOutExpected, msg.sender, deadline);
            }
        } else {
            revert("Invalid order type");
        }
    }
    
    function feesWithdraw(address payable _to) external onlyOwner{
        uint256 amount = (address(this)).balance;
        require(_to.send(amount), 'Fee Transfer to Owner failed.');
    }

}