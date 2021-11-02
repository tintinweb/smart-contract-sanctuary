// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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

contract MainPool is OwnableUpgradeable {
    using SafeMath for uint256;

    struct TokenClaim {
        address tokenAddress;
        uint256 amount;
        uint256 lastClaimBlock;
    }

    struct TokenTipClaim {
        address tokenAddress;
        uint256 amount;
    }

    struct PoolType {
        string name;
        bool isIDOL;
        uint256 claimPeriod;
        uint256 startFee;
        uint256 endFee;
    }
    
    struct Coupon {
        uint256 discount;
        uint256 expired;
        uint256 reserve;
    }

    mapping(address => TokenClaim[]) public creatorBal;
    mapping(address => TokenTipClaim[]) public creatorTipBal;
    mapping(uint256 => PoolType) public poolTypes;
    mapping(address => uint256) public pools;
    mapping(string => Coupon) public coupons;
    
    address public IDOLAddress;
    address public PEACHAddress;
    address public BUSDAddress;
    address public feeAddress;
    uint256 public subscribeFee;
    uint256 public subscribeIDOLFee;
    uint256 public nextPoolTypeId;

    event Claim(
        address creator,
        address feeAddress,
        address token,
        uint256 amount,
        uint256 fee,
        uint256 feeAmount,
        uint256 finalAmount
    );

    event ClaimAll(address creator);

    event ClaimTipAll(address creator);

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

    event PoolTypeCreated(
        string name,
        bool isIDOL,
        uint256 poolTypeId,
        uint256 claimPeriod,
        uint256 startFee,
        uint256 endFee
    );

    event PoolTypeUpdated(
        string name,
        bool isIDOL,
        uint256 poolTypeId,
        uint256 claimPeriod,
        uint256 startFee,
        uint256 endFee
    );
    
    event NewCoupon(string code, uint256 discount, uint256 expired);
    
    event DeleteCoupon(string code);
    
    function initialize(
        address[] memory addresses,
        uint256[] memory numbers
    ) external {
        IDOLAddress = addresses[0];
        PEACHAddress = addresses[1];
        BUSDAddress = addresses[2];
        feeAddress = addresses[3];

        subscribeFee = numbers[0];
        subscribeIDOLFee = numbers[1];
        nextPoolTypeId = 1;
        OwnableUpgradeable.__Ownable_init();
    }

    function addPool(address _tokenAddress, uint256 poolId) public onlyOwner {
        require(pools[_tokenAddress] == 0, "pool address already exists");
        pools[_tokenAddress] = poolId;
    }

    function removePool(address _tokenAddress) public onlyOwner {
        require(pools[_tokenAddress] != 0, "pool address not exists");
        delete pools[_tokenAddress];
    }
    
    function setCoupons(string[] calldata _codes, uint256[] calldata _discounts, uint256[] calldata _expireds) public onlyOwner {
        for (uint256 i = 0; i < _codes.length; i ++ ) {
            coupons[_codes[i]] = Coupon(_discounts[i], _expireds[i], 0);
            emit NewCoupon(_codes[i], _discounts[i], _expireds[i]);
        }
    }
    
    function removeCoupons(string[] calldata _codes) public onlyOwner {
        for (uint256 i = 0; i < _codes.length; i ++ ) {
            delete coupons[_codes[i]];
            emit DeleteCoupon(_codes[i]);
        }
    }

    function addReserveCoupon(string calldata _code, address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);
        Coupon memory c = coupons[_code];
        c.reserve = c.reserve.add(_amount);
    }
    
    function removeReserveCoupon(string calldata _code, address _tokenAddress) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        Coupon memory c = coupons[_code];
        token.transfer(msg.sender, c.reserve);
        c.reserve = 0;
    }
 
    function createPoolType(
        string memory name,
        bool isIDOL,
        uint256 period,
        uint256 startFee,
        uint256 endFee
    ) public onlyOwner returns (uint256 id) {
        poolTypes[nextPoolTypeId] = PoolType(name, isIDOL, period, startFee, endFee);
        emit PoolTypeCreated(name, isIDOL, nextPoolTypeId, period, startFee, endFee);
        id = nextPoolTypeId;
        nextPoolTypeId = nextPoolTypeId.add(1);
    }

    function updatePoolType(
        string memory name,
        bool isIDOL,
        uint256 poolTypeId,
        uint256 period,
        uint256 startFee,
        uint256 endFee
    ) public onlyOwner {
        poolTypes[poolTypeId] = PoolType(name, isIDOL, period, startFee, endFee);
        emit PoolTypeUpdated(name, isIDOL, poolTypeId, period, startFee, endFee);
    }
    
    function setSusbscribeFee(uint256 _subscribeFee) external onlyOwner {
        subscribeFee = _subscribeFee;
    }
    
     function setSusbscribeIDOLFFee(uint256 _subscribeIDOLFFee) external onlyOwner {
        subscribeIDOLFee = _subscribeIDOLFFee;
    }

    function setIDOLAddress(address _idolAddress) external onlyOwner {
        IDOLAddress = _idolAddress;
    }

    function setPEACHAddress(address _peachAddress) external onlyOwner {
        PEACHAddress = _peachAddress;
    }

    function setBUSDAddress(address _BUSDAddress) external onlyOwner {
        BUSDAddress = _BUSDAddress;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function transferToPool(
        address _userAddress,
        address _creatorAddress,
        address _tokenAddress,
        uint256 _conversionRate,
        uint256 _amount,
        uint256 _USDAmount,
        string calldata _code
    ) external {
        // take % fee
        uint256 percentFee = 0;
        (_tokenAddress == IDOLAddress) ? percentFee = subscribeIDOLFee : percentFee = subscribeFee;
        uint256 percentAmount = (_USDAmount.mul(percentFee)).div(10 ** 18);
        uint256 feeAmount = (percentAmount.mul(_conversionRate)).div(10 ** 18);

        // check if have fee
        if (feeAmount > 0) {
            IERC20 IDOLToken = IERC20(IDOLAddress);
            IDOLToken.transferFrom(_userAddress, feeAddress, feeAmount);
        }

        // check if coupon exist
        if (coupons[_code].discount != 0) {
            // have discount, pool paid for discount
            uint256 discountAmount = (_amount.mul(coupons[_code].discount)).div(10 ** 18);
            uint256 leftoverAmount = _amount.sub(discountAmount);
  
            // transfer leftover token from user to pool
            IERC20 token = IERC20(_tokenAddress);
            token.transferFrom(_userAddress, address(this), leftoverAmount);
            
            // add amount to pool, add idol to pool
            _addAmountToPool(_creatorAddress, _tokenAddress, discountAmount);
            _addAmountToPool(_creatorAddress, IDOLAddress, leftoverAmount);
        } else {
            // no discount, transfer token to pool
            IERC20 token = IERC20(_tokenAddress);
            token.transferFrom(_userAddress, address(this), _amount);
            
            // add amount to pool
            _addAmountToPool(_creatorAddress, _tokenAddress, _amount);
        }
        
        emit TransferToPool(
            _userAddress,
            _creatorAddress,
            _tokenAddress,
            _conversionRate,
            _amount,
            feeAmount
        );
    }
    
    function transferTipToPool(
        address _userAddress,
        address _creatorAddress,
        address _tokenAddress,
        uint256 _amount
    ) external {
        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(_userAddress, address(this), _amount);
        emit TransferTipToPool(
            _userAddress,
            _creatorAddress,
            _tokenAddress,
            _amount
        );

        // add balance to creator for future creator withdraw
        TokenTipClaim[] storage ttcArr = creatorTipBal[_creatorAddress];
        bool tokenExist = false;
        for (uint256 i = 0; i < ttcArr.length; i++) {
            TokenTipClaim storage ttc = ttcArr[i];
            if (_tokenAddress == ttc.tokenAddress) {
                ttc.amount = ttc.amount.add(_amount);
                tokenExist = true;
            }
        }

        if (!tokenExist) {
            creatorTipBal[_creatorAddress].push(
                TokenTipClaim(_tokenAddress, _amount)
            );
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

    function checkCreatorLastClaim(
        address _creatorAddress,
        address _tokenAddress
    ) public view returns (uint256 lastClaimBlock) {
        TokenClaim[] memory tokenClaims = creatorBal[_creatorAddress];

        for (uint256 i = 0; i < tokenClaims.length; i++) {
            TokenClaim memory tokenClaim = tokenClaims[i];
            if (_tokenAddress == tokenClaim.tokenAddress) {
                return tokenClaim.lastClaimBlock;
            }
        }
        return 0;
    }

    // check type of pool (A IDOL pool, B non-IDOL pool, tip Pool ??)
    // idol pool (same slow release)
    // non idol, check fee and range
    function checkClaim(address _creatorAddress, address _tokenAddress)
        public
        view
        returns (
            uint256 balance,
            uint256 withdrawAmount,
            uint256 feePercentage,
            uint256 actualFee,
            uint256 actualWithdrawAmount
        )
    {
        PoolType memory poolType = poolTypes[pools[_tokenAddress]];
        TokenClaim[] memory tokenClaims = creatorBal[_creatorAddress];
        
        for (uint256 i = 0; i < tokenClaims.length; i++) {
            TokenClaim memory tokenClaim = tokenClaims[i];
            uint256 feeRate = 0;
            uint256 feeAmount = 0;
            uint256 claimAmount = 0;
            uint256 finalClaimAmount = 0;
            uint256 blockPassed = 0;
            if (_tokenAddress == tokenClaim.tokenAddress) {
                // IDOL slow release
                if (poolType.isIDOL) {
                    // slow release
                    blockPassed = block.number.sub(tokenClaim.lastClaimBlock);
                    if (blockPassed / poolType.claimPeriod >= 1) {
                        claimAmount = tokenClaim.amount;
                    } else {
                        claimAmount = (tokenClaim.amount.mul(blockPassed)).div(
                            poolType.claimPeriod
                        );
                    }
                    
                    if (poolType.endFee == 0) {
                        feeAmount = 0;
                        finalClaimAmount = claimAmount;
                        feeRate = poolType.endFee;
                    } else {
                        // calculate fee
                        feeAmount = (claimAmount.mul(poolType.endFee)).div(10 ** 18);
                        finalClaimAmount = claimAmount.sub(feeAmount);
                        feeRate = poolType.endFee;
                    }
                    return (
                        tokenClaim.amount,
                        claimAmount,
                        feeRate,
                        feeAmount,
                        finalClaimAmount
                    );
                } else {
                    // calculate range fee
                    if (poolType.endFee == 0) {
                        feeAmount = 0;
                        claimAmount = tokenClaim.amount;
                        finalClaimAmount = claimAmount;
                        feeRate = poolType.endFee;
                    } else {
                        // calculate range fee
                        blockPassed = block.number.sub(tokenClaim.lastClaimBlock);
                        if (blockPassed.div(poolType.claimPeriod) >= 1) {
                            feeRate = poolType.startFee;
                        } else {
                            uint256 diffFee = poolType.endFee.sub(poolType.startFee);
                            uint256 reduceFee = (blockPassed.mul(diffFee)).div(
                                poolType.claimPeriod
                            );
                            feeRate = poolType.endFee.sub(reduceFee);
                        }
    
                        // calculate final amount
                        claimAmount = tokenClaim.amount;
                        feeAmount = (claimAmount.mul(feeRate)).div(10 ** 18);
                        finalClaimAmount = claimAmount.sub(feeAmount);

                    }

                    return (
                            tokenClaim.amount,
                            claimAmount,
                            feeRate,
                            feeAmount,
                            finalClaimAmount
                    );
                }
            }
        }
        return (0, 0, 0, 0, 0);
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
        PoolType memory poolType = poolTypes[pools[_tokenAddress]];
        uint256 feeRate = poolType.endFee;
    
        TokenTipClaim[] memory tokenTipClaims = creatorTipBal[_creatorAddress];
        for (uint256 i = 0; i < tokenTipClaims.length; i++ ) {
            TokenTipClaim memory tokenTipClaim = tokenTipClaims[i];
            // if have token in balance
            if (_tokenAddress == tokenTipClaim.tokenAddress) {
                uint256 claimAmount = tokenTipClaim.amount;
                uint256 feeAmount = 0;
                uint256 finalClaimAmount = 0;

                // calculate fee
                if (feeRate == 0) {
                    finalClaimAmount = claimAmount;
                } else {
                    feeAmount = (claimAmount.mul(feeRate)).div(10 ** 18);
                    finalClaimAmount = claimAmount.sub(feeAmount);
                }
                return (tokenTipClaim.amount, claimAmount, feeAmount, finalClaimAmount);
            }
        }
        return (0, 0, 0, 0);
    }

    function viewCreatorBalance(address _creatorAddress, address _tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        TokenClaim[] memory tokenClaims = creatorBal[_creatorAddress];

        for (uint256 i = 0; i < tokenClaims.length; i++) {
            TokenClaim memory tokenClaim = tokenClaims[i];
            if (_tokenAddress == tokenClaim.tokenAddress) {
                return tokenClaim.amount;
            }
        }
        return 0;
    }

    function viewCreatorTipBalance(
        address _creatorAddress,
        address _tokenAddress
    ) public view returns (uint256 balance) {
        TokenTipClaim[] memory tokenTipCliams = creatorTipBal[_creatorAddress];

        for (uint256 i = 0; i < tokenTipCliams.length; i++) {
            TokenTipClaim memory tokenTipClaim = tokenTipCliams[i];
            if (_tokenAddress == tokenTipClaim.tokenAddress) {
                return tokenTipClaim.amount;
            }
        }
        return 0;
    }
    
    function checkCoupon(string calldata _code) 
        public 
        view 
        returns (
            uint256 discount,
            uint256 expired,
            uint256 reserve
        ) 
    {
        Coupon memory c = coupons[_code];
        return (c.discount, c.expired, c.reserve);
    }
    
    // check type of pool (A IDOL pool, B non-IDOL pool, tip Pool)
    // idol pool (slow release)
    // non idol, check fee and range
    function claim(address _tokenAddress, uint256 _amount) external {
        require(pools[_tokenAddress] != 0, "Pool not exists");
        require(
            poolTypes[pools[_tokenAddress]].claimPeriod != 0,
            "Pool Type not exists"
        );
        PoolType memory poolType = poolTypes[pools[_tokenAddress]];
        TokenClaim[] storage tokenClaims = creatorBal[msg.sender];
        
        for (uint256 i = 0; i < tokenClaims.length; i++ ) {
            TokenClaim storage tokenClaim = tokenClaims[i];
            uint256 feeRate = 0;
            uint256 feeAmount = 0;
            uint256 claimAmount = 0;
            uint256 finalClaimAmount = 0;
            uint256 blockPassed = 0;
            
            if (_tokenAddress == tokenClaim.tokenAddress) {
                require(tokenClaim.amount >= _amount, "insufficient amount to claim");
                // IDOL slow release
                if (poolType.isIDOL) {
                    // slow release
                    blockPassed = block.number.sub(tokenClaim.lastClaimBlock);
                    if (blockPassed / poolType.claimPeriod >= 1) {
                        claimAmount = _amount;
                    } else {
                        claimAmount = (tokenClaim.amount.mul(blockPassed)).div(poolType.claimPeriod);
                        require(_amount <= claimAmount);
                        claimAmount = _amount;
                    }

                     // calculate fee
                     if (poolType.endFee == 0) {
                        feeAmount = 0;
                        finalClaimAmount = claimAmount;
                        feeRate = poolType.endFee;
                     } else {
                         // calculate fee
                        feeAmount = (claimAmount.mul(poolType.endFee)).div(10 ** 18);
                        finalClaimAmount = claimAmount.sub(feeAmount);
                        feeRate = poolType.endFee;
                     }
            
                } else {
                    // calculate range fee
                    if (poolType.endFee == 0) {
                        claimAmount = _amount;
                        finalClaimAmount = claimAmount;
                        feeAmount = 0;
                        feeRate = poolType.endFee;
                    } else {
                        blockPassed = block.number.sub(tokenClaim.lastClaimBlock);
                        if (blockPassed.div(poolType.claimPeriod) >= 1) {
                            feeRate = poolType.startFee;
                        } else {
                            uint256 diffFee = poolType.endFee.sub(poolType.startFee);
                            uint256 reduceFee = (blockPassed.mul(diffFee)).div(
                                poolType.claimPeriod
                            );
                            feeRate = poolType.endFee.sub(reduceFee);
                        }
                        // calculate final amount
                        claimAmount = _amount;
                        feeAmount = (claimAmount.mul(feeRate)).div(10 ** 18);
                        finalClaimAmount = claimAmount.sub(feeAmount);
                    }
                }

                // transfer
                IERC20 token = IERC20(_tokenAddress);
                token.transfer(msg.sender, finalClaimAmount);
                
                // check if have fee
                if (feeAmount > 0) {
                    token.transfer(feeAddress, feeAmount);
                }

                emit Claim(msg.sender, feeAddress, _tokenAddress, claimAmount, feeRate, feeAmount, finalClaimAmount);
                // new balance and lastClaim
                tokenClaim.amount = tokenClaim.amount.sub(claimAmount);
                tokenClaim.lastClaimBlock = block.number;
            }
        }

    }

    function claimTip(address _tokenAddress, uint256 _amount) external {
        require(pools[_tokenAddress] != 0, "Pool not exists");
        require(
            poolTypes[pools[_tokenAddress]].claimPeriod != 0,
            "Pool Type not exists"
        );
        PoolType memory poolType = poolTypes[pools[_tokenAddress]];
        uint256 feeRate = poolType.endFee;
        
        TokenTipClaim[] storage tokenTipCliams = creatorTipBal[msg.sender];
        for (uint256 i = 0; i < tokenTipCliams.length; i++ ) {
            TokenTipClaim storage tokenTipClaim = tokenTipCliams[i];

            if (_tokenAddress == tokenTipClaim.tokenAddress) {
                require(tokenTipClaim.amount >= _amount, "insufficient amount to claim");
                uint256 claimAmount = _amount;

                uint256 feeAmount = 0;
                uint256 finalClaimAmount = 0;
                // caculate fee
                if (feeRate == 0) {
                    finalClaimAmount = claimAmount;
                }
                else {
                    feeAmount = (claimAmount.mul(feeRate)).div(10 ** 18);
                    finalClaimAmount = claimAmount.sub(feeAmount);
                }

                // transfer
                IERC20 token = IERC20(_tokenAddress);
                token.transfer(msg.sender, finalClaimAmount);
                if (feeAmount > 0) {
                    token.transfer(feeAddress, feeAmount);
                }

                // new balance
                emit ClaimTip(msg.sender, feeAddress, _tokenAddress, claimAmount, feeRate, feeAmount, finalClaimAmount);
                tokenTipClaim.amount = tokenTipClaim.amount.sub(claimAmount);
            }
        }
    }
    
    function _addAmountToPool(address _creatorAddress, address _tokenAddress, uint256 _amount) internal {
        TokenClaim[] storage tokenClaims = creatorBal[_creatorAddress];
        bool tokenExist = false;
        for (uint256 i = 0; i < tokenClaims.length; i++) {
            TokenClaim storage tokenClaim = tokenClaims[i];
            if (_tokenAddress == tokenClaim.tokenAddress) {
                tokenClaim.amount = tokenClaim.amount.add(_amount);
                tokenExist = true;
            }
        }

        if (!tokenExist) {
            creatorBal[_creatorAddress].push(
                TokenClaim(_tokenAddress, _amount, block.number)
            );
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}