// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MainPool is Ownable {
    constructor(
        address _IDOLAddress,
        address _PEACHAddress,
        address _feeAddress,
        uint256 _fee,
        uint256 _subscribeFee,
        uint256 _IDOLFee,
        uint256 _PEACHFee,
        uint256 _claimPeriod
    ) {
        IDOLAddress = _IDOLAddress;
        PEACHAddress = _PEACHAddress;
        feeAddress = _feeAddress;
        subscribeFee = _subscribeFee;
        fee = _fee;
        IDOLFee = _IDOLFee;
        PEACHFee = _PEACHFee;
        claimPeriod = _claimPeriod;
    }

    using SafeMath for uint256;
    
    struct tokenClaim {
        address tokenAddress;
        uint256 amount;
        uint256 lastClaimBlock;
    }
    
    struct tokenTipClaim {
        address tokenAddress;
        uint256 amount;
    }

    address private IDOLAddress;
    address private PEACHAddress;
    mapping(address => tokenClaim[]) private creatorBal;
    mapping(address => tokenTipClaim[]) private creatorTipBal;
    
    address private feeAddress;
    uint256 private claimPeriod;
    uint256 private IDOLFee;
    uint256 private PEACHFee;
    uint256 private fee;
    uint256 private subscribeFee;

    event Claim(
        address creator,
        address feeAddress,
        address token,
        uint256 amount,
        uint256 fee,
        uint256 feeAmount,
        uint256 finalAmount
    );
    
    event ClaimAll(
        address creator
    );
    
    event ClaimTipAll(
        address creator
    );
    
    event ClaimTip(
        address creator,
        address feeAddress,
        address token,
        uint256 amount,
        uint256 fee,
        uint256 feeAmount,
        uint256 finalAmount
    );
    
    event TransferToPool(
        address user,
        address creator,
        address token,
        uint256 conversionRate,
        uint256 amount,
        uint256 feeAmount
    );
    
    event TransferTipToPool(
        address user,
        address creator,
        address token,
        uint256 amount
    );

    function setClaimPeriod(uint256 _claimPeriod) public onlyOwner {
        claimPeriod = _claimPeriod;
    }

    function setIDOLFee(uint256 _IDOLFee) public onlyOwner {
        IDOLFee = _IDOLFee;
    }

    function setPEACHFee(uint256 _PEACHFee) public onlyOwner {
        PEACHFee = _PEACHFee;
    }

    function setIDOLAddress(address _idolAddress) external onlyOwner {
        IDOLAddress = _idolAddress;
    }

    function setPEACHAddress(address _peachAddress) external onlyOwner {
        PEACHAddress = _peachAddress;
    }
    
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function transferToPool(
        address _userAddress,
        address _creatorAddress,
        address _tokenAddress,
        uint256 _conversionRate,
        uint256 _amount
    ) external {
 
        IERC20 token = IERC20(_tokenAddress);
        uint256 userBalance = token.balanceOf(_userAddress);
        require(userBalance != 0, "insufficient amount");
        require(userBalance > _amount, "insufficient amount to transfer");
       
        // transfer plan amount
        token.transferFrom(_userAddress, address(this), _amount);
        
        uint256 feeAmount = 0;
        // pay with other token than IDOLAddress
        // take % fee
        if (_tokenAddress != IDOLAddress) {
            // take fee
            uint256 rate = _amount.mul(_conversionRate).div(10 ** 18);
            feeAmount = rate.mul(subscribeFee).div(100); 
            IERC20 IDOLToken = IERC20(IDOLAddress); 
            IDOLToken.transferFrom(_userAddress, feeAddress, feeAmount);
        }
        
        emit TransferToPool(_userAddress, _creatorAddress, _tokenAddress, _conversionRate, _amount, feeAmount);
        
        tokenClaim[] storage tcArr = creatorBal[_creatorAddress];
        bool tokenExist = false;
        for(uint256 i = 0; i < tcArr.length; i++ ) {
            tokenClaim storage tc = tcArr[i];
            if (_tokenAddress == tc.tokenAddress) {
                tc.amount = tc.amount.add(_amount);
                tokenExist = true;
            }
        }
        
        if (!tokenExist) {
            creatorBal[_creatorAddress].push(tokenClaim(_tokenAddress, _amount, block.number));
        }
    }

    function transferTipToPool(
        address _userAddress,
        address _creatorAddress,
        address _tokenAddress,
        uint256 _amount
    ) external {
        IERC20 token = IERC20(_tokenAddress);
        uint256 userBalance = token.balanceOf(_userAddress);
        require(userBalance != 0, "insufficient amount");
        require(userBalance > _amount, "insufficient amount to transfer");
    
        token.transferFrom(_userAddress, address(this), _amount);
        emit TransferTipToPool(_userAddress, _creatorAddress,_tokenAddress, _amount);
        
        
        // add balance to creator for future creator withdraw
        tokenTipClaim[] storage ttcArr = creatorTipBal[_creatorAddress];
        bool tokenExist = false;
        for(uint256 i = 0; i < ttcArr.length; i++ ) {
            tokenTipClaim storage ttc = ttcArr[i];
            if (_tokenAddress == ttc.tokenAddress) {
                ttc.amount = ttc.amount.add(_amount);
                tokenExist = true;
            }
        }
        
        if (!tokenExist) {
            creatorTipBal[_creatorAddress].push(tokenTipClaim(_tokenAddress, _amount));
        }
    
    }

    function checkBalance(address _address, address _tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        IERC20 token = IERC20(_tokenAddress);
        return token.balanceOf(_address);
    }

    function checkCreatorLastClaim(address _creatorAddress, address _tokenAddress)
        public
        view
        returns (uint256 lastClaimBlock)
    {
       tokenClaim[] memory tcArr = creatorBal[_creatorAddress];
       
        for (uint256 i = 0; i < tcArr.length; i++ ) {
            tokenClaim memory tc = tcArr[i];
            if (_tokenAddress == tc.tokenAddress) {
                return tc.lastClaimBlock;
            }
        }
        return 0;
    }
    
    function checkClaim(address _creatorAddress, address _tokenAddress)
        public
        view
        returns (
            uint256 balance,
            uint256 withdrawAmount,
            uint256 actualFee,
            uint256 actualWithdrawAmount
        )
    {
        tokenClaim[] memory tcArr = creatorBal[_creatorAddress];
        for (uint256 i = 0; i < tcArr.length; i++ ) {
            tokenClaim memory tc = tcArr[i];
            if (_tokenAddress == tc.tokenAddress) {
                // slow release        
                uint256 blockPassed = block.number.sub(tc.lastClaimBlock);
                uint256 claimAmount;
                if (blockPassed / claimPeriod >= 1) {
                    claimAmount = tc.amount;
                } else {
                    claimAmount = (tc.amount.mul(blockPassed)).div(claimPeriod);
                }
                
                // find fee
                uint256 fa = fee;
                if (_tokenAddress == IDOLAddress) {
                    fa = IDOLFee;
                }
                
                // calculate fee
                uint256 feeAmount = (claimAmount.mul(fa)).div(100);
                uint256 finalClaimAmount = claimAmount.sub(feeAmount);
                return (tc.amount, claimAmount, feeAmount, finalClaimAmount);
            }
        }
        return (0, 0, 0, 0);
    }

    function checkTipClaim(address _creatorAddress, address _tokenAddress)
        public
        view
        returns (
            uint256 balance,
            uint256 withdrawAmount,
            uint256 actualFee,
            uint256 actualWithdrawAmount
        )
    {
       tokenTipClaim[] memory ttcArr = creatorTipBal[_creatorAddress];
        for (uint256 i = 0; i < ttcArr.length; i++ ) {
            tokenTipClaim memory ttc = ttcArr[i];
            // if have token in bal
            if (_tokenAddress == ttc.tokenAddress) {
                uint256 claimAmount = ttc.amount;
                
                // find fee
                uint256 fa = fee;
                if (_tokenAddress == PEACHAddress) {
                    fa = PEACHFee;
                }
                
                // calculate fee
                uint256 feeAmount = (claimAmount.mul(fa)).div(100);
                uint256 finalClaimAmount = claimAmount.sub(feeAmount);
                return (ttc.amount, claimAmount, feeAmount, finalClaimAmount);
            }
        }
        return (0, 0, 0, 0);
    }
    
    function viewFee() public view returns (uint256 feeAmount) {
        return fee;
    }
    
    function viewIDOLFee() public view returns (uint256 feeAmount) {
        return IDOLFee;
    }
   
    function viewPEACHFee() public view returns (uint256 feeAmount) {
        return PEACHFee;
    }

    function viewClaimPeriod() public view returns (uint256 period) {
        return claimPeriod;
    }
    
    function viewCreatorBalance(address _creatorAddress, address _tokenAddress) public view returns (uint256 balance) {
        tokenClaim[] memory tcArr = creatorBal[_creatorAddress];
       
        for (uint256 i = 0; i < tcArr.length; i++ ) {
            tokenClaim memory tc = tcArr[i];
            if (_tokenAddress == tc.tokenAddress) {
                return tc.amount;
            }
        }
        return 0;
    }
    
    function viewCreatorTipBalance(address _creatorAddress, address _tokenAddress) public view returns (uint256 balance) {
        tokenTipClaim[] memory tccArr = creatorTipBal[_creatorAddress];
       
        for (uint256 i = 0; i < tccArr.length; i++ ) {
            tokenTipClaim memory tcc = tccArr[i];
            if (_tokenAddress == tcc.tokenAddress) {
                return tcc.amount;
            }
        }
        return 0;
    }

    function claim(address _tokenAddress) external {
        tokenClaim[] storage tcArr = creatorBal[msg.sender];
        for (uint256 i = 0; i < tcArr.length; i++ ) {
            tokenClaim storage tc = tcArr[i];
            
            if (_tokenAddress == tc.tokenAddress) {
                require(tc.amount != 0, "insufficient amount to claim");  
                uint256 blockPassed = block.number.sub(tc.lastClaimBlock);
                uint256 claimAmount;
        
                // slow released
                if (blockPassed / claimPeriod >= 1) {
                    claimAmount = tc.amount;
                } else {
                    claimAmount = (tc.amount.mul(blockPassed)).div(claimPeriod);
                }
                
                // determine fee
                uint256 fa = fee;
                if (_tokenAddress == IDOLAddress) {
                    fa = IDOLFee;
                }
                
                // calculate fee
                uint256 feeAmount = (claimAmount.mul(fa)).div(100);
                uint256 finalClaimAmount = claimAmount.sub(feeAmount);
                

                // transfer
                IERC20 token = IERC20(_tokenAddress);
                uint256 bal = token.balanceOf(address(this));
                require(bal != 0, "pool has insufficient amount");
                require(
                    bal >= finalClaimAmount,
                    "pool has insufficient amount to transfer"
                );
                token.transfer(msg.sender, finalClaimAmount);
                token.transfer(feeAddress, feeAmount);
                
                emit Claim(msg.sender, feeAddress, _tokenAddress, claimAmount, fa, feeAmount, finalClaimAmount);
                // new balance and lastClaim
                tc.amount = tc.amount.sub(claimAmount);
                tc.lastClaimBlock = block.number;
            }
        }

    }
    
    function claimAll() external {
        tokenClaim[] storage tcArr = creatorBal[msg.sender];
        emit ClaimAll(msg.sender);
        for (uint256 i = 0; i < tcArr.length; i++ ) {
            tokenClaim storage tc = tcArr[i];
            
            if (tc.amount != 0) {
                // slow release
                uint256 blockPassed = block.number.sub(tc.lastClaimBlock);
                uint256 claimAmount;
        
                if (blockPassed / claimPeriod >= 1) {
                    claimAmount = tc.amount;
                } else {
                    claimAmount = (tc.amount.mul(blockPassed)).div(claimPeriod);
                }
                
                // find fee
                uint256 fa = fee;
                if (tc.tokenAddress == IDOLAddress) {
                    fa = IDOLFee;
                }
                
                // calculate fee
                uint256 feeAmount = (claimAmount.mul(fa)).div(100);
                uint256 finalClaimAmount = claimAmount.sub(feeAmount);
            
                // transfer
                IERC20 token = IERC20(tc.tokenAddress);
                uint256 bal = token.balanceOf(address(this));
                require(bal != 0, "pool has insufficient amount");
                require(
                    bal >= finalClaimAmount,
                    "pool has insufficient amount to transfer"
                );
                
                token.transfer(msg.sender, finalClaimAmount);
                token.transfer(feeAddress, feeAmount);
                
                emit Claim(msg.sender, feeAddress, tc.tokenAddress, claimAmount, fa, feeAmount, finalClaimAmount);
                
                // new bal and lastcliam
                tc.amount = tc.amount.sub(claimAmount);
                tc.lastClaimBlock = block.number;
            }
        }

    }
    
    function claimTip(address _tokenAddress) external {
        tokenTipClaim[] storage tccArr = creatorTipBal[msg.sender];
        for (uint256 i = 0; i < tccArr.length; i++ ) {
            tokenTipClaim storage tcc = tccArr[i];
            
            if (_tokenAddress == tcc.tokenAddress) {
                require(tcc.amount != 0, "insufficient amount to claim");  
                uint256 claimAmount = tcc.amount;
                
                // find fee
                uint256 fa = fee;
                if (_tokenAddress == PEACHAddress) {
                    fa = PEACHFee;
                }
                
                // caculate fee
                uint256 feeAmount = (claimAmount.mul(fa)).div(100);
                uint256 finalClaimAmount = claimAmount.sub(feeAmount);
                

                // transfer
                IERC20 token = IERC20(_tokenAddress);
                uint256 bal = token.balanceOf(address(this));
                require(bal != 0, "pool has insufficient amount");
                require(
                    bal >= finalClaimAmount,
                    "pool has insufficient amount to transfer"
                );
                token.transfer(msg.sender, finalClaimAmount);
                token.transfer(feeAddress, feeAmount);
                
                // new balance
                emit ClaimTip(msg.sender, feeAddress, _tokenAddress, claimAmount, fa, feeAmount, finalClaimAmount);
                tcc.amount = tcc.amount.sub(claimAmount);
            }
        }
    }
    
    function claimTipAll() external {
        tokenTipClaim[] storage tccArr = creatorTipBal[msg.sender];
        emit ClaimTipAll(msg.sender);
        for (uint256 i = 0; i < tccArr.length; i++ ) {
            tokenTipClaim storage tcc = tccArr[i];
            
            if (tcc.amount != 0) {
                require(tcc.amount != 0, "insufficient amount to claim");  
                uint256 claimAmount = tcc.amount;
                
                // find fee
                uint256 fa = fee;
                if (tcc.tokenAddress == PEACHAddress) {
                    fa = PEACHFee;
                }
                
                // calculate fee
                uint256 feeAmount = (claimAmount.mul(fa)).div(100);
                uint256 finalClaimAmount = claimAmount.sub(feeAmount);
                
                // transfer
                IERC20 token = IERC20(tcc.tokenAddress);
                uint256 bal = token.balanceOf(address(this));
                require(bal != 0, "pool has insufficient amount");
                require(
                    bal >= finalClaimAmount,
                    "pool has insufficient amount to transfer"
                );
                token.transfer(msg.sender, finalClaimAmount);
                token.transfer(feeAddress, feeAmount);
                
                emit ClaimTip(msg.sender, feeAddress, tcc.tokenAddress, claimAmount, fa , feeAmount, finalClaimAmount);
                tcc.amount = tcc.amount.sub(claimAmount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

