/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function decimals() external view returns (uint8);
}

interface UNIPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast); 
}

contract GuarateeContract {
    // SafeMath library
    using SafeMath for uint256;
    
    // manager address
    address public owner;
    
    // ether/usdt pair address
    UNIPair public pair;
    
    // usdt address
    IERC20 public usdt;
    
    // contract start id
    uint256 public contractID;
    
    // owner totalBalance
    uint256 public ownerTotalBalance;
    
    // owner currentBalance
    uint256 public ownerCurrentBalance;
    
    struct singleContract {
        uint256 id;
        address from;
        address to;
        uint256 value;
        uint8   prAcc;
        uint8   cfAcc;
        uint8   ctState;
        uint256 stateTime;
    }
    mapping(uint256 => singleContract) singleContracts;
    
    event SignSingleContract(
        uint256 id, address from, address to, address manager, uint256 value,
        uint8 prAcc, uint8 cfAcc, uint8 ctState, uint256 stateTime
    );

    event ApplyTerminateSingleContract(
        address applyer, uint256 id, uint8 prAcc, uint8 ctState, uint256 stateTime
    );
    
    event ConfirmTerminateSingleContract(
        address confirmer, uint256 id, uint8 cfAcc, uint8 ctState, bool isAccept, uint256 stateTime
    );
    
    struct doubleContract {
        uint256 id;
        address from;
        address to;
        uint256 fvalue;
        uint256 tvalue;
        uint8   prAcc;
        uint8   cfAcc;
        uint8   ctState;
        uint8   withdrawType;
        uint256 stateTime;
    }
    mapping(uint256 => doubleContract) doubleContracts;
    
    event SignDoubleContract(
        uint256 id, address from, address to, address manager, uint256 fvalue, uint256 tvalue,
        uint8 prAcc, uint8 cfAcc, uint8 ctState, uint8 withdrawType, uint256 stateTime
    );
    
    event ConfirmSignDoubleContract(
        address confirmer, uint256 id, uint256 tvalue, uint8 cfAcc, uint8 ctState, uint256 stateTime
    );
    
    event CancleDoubleContract(
        address opter, uint256 id, uint8 ctState, uint256 stateTime
    );

    event ApplyTerminateDoubleContract(
        address applyer, uint256 id, uint8 prAcc, uint8 ctState, uint8 withdrawType, uint256 stateTime
    );
    
    event ConfirmTerminateDoubleContract(
        address confirmer, uint256 id, uint8 cfAcc, uint8 ctState, bool isAccept, uint256 stateTime
    );
    
    event UpdateOwnerAddress(address newOner);
    
    modifier scExists(uint256 _id) {
        require(_id < contractID, "Contract does not exist");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
    
    constructor(IERC20 _usdt, UNIPair _pair, address _owner, uint256 _contractID) {
        owner = _owner;
        contractID = _contractID;
        usdt = _usdt;
        pair = _pair;
    }
    
    function signSingleContract(address _to, uint256 _value) public {
        require(usdt.balanceOf(msg.sender) >= _value && _value > 0, "value error");
        singleContract storage sc = singleContracts[contractID++];
        sc.id = contractID.sub(1);
        sc.from = msg.sender;
        sc.to = _to;
        sc.value = _value;
        sc.prAcc = 0;
        sc.cfAcc = 0;
        sc.ctState = 1;
        sc.stateTime = block.timestamp;
        
        usdt.transferFrom(msg.sender, address(this), _value);
        
        emit SignSingleContract(sc.id, sc.from, sc.to, owner, sc.value, sc.prAcc, sc.cfAcc, sc.ctState, sc.stateTime);
    }
    
    function applyTerminateSingleContract(uint256 _id) public scExists(_id) {
        singleContract storage sc = singleContracts[_id];
        require((msg.sender == sc.from && sc.prAcc != 1) || (msg.sender == sc.to && sc.prAcc != 2), "illegal address or not permission");
        require(sc.ctState == 1, "terminate contract in progress or finished");
        
        if(msg.sender == sc.from) {
            sc.prAcc = 1;
            sc.ctState = 2;
            sc.stateTime = block.timestamp;
        }else {
            sc.prAcc = 2;
            sc.ctState = 2;
            sc.stateTime = block.timestamp;
        }
        
        emit ApplyTerminateSingleContract(msg.sender, _id, sc.prAcc, sc.ctState, sc.stateTime);
    }
    
    function confirmTerminateSingleContract(uint256 _id, bool _isAccept) public scExists(_id) {
        uint256 gasAtStart = gasleft();

        singleContract storage sc = singleContracts[_id];
        require((msg.sender == sc.from && sc.prAcc != 1) || (msg.sender == sc.to && sc.prAcc != 2) || msg.sender == owner, "illegal address");
        require(sc.ctState == 2, "terminate contract finished or not start");
        address to = sc.prAcc == 1 ? sc.from : sc.to;
        require(usdt.balanceOf(address(this)) >= sc.value, "value error");

        if(_isAccept){
            if(msg.sender == owner) {
                sc.cfAcc = 3;
                sc.ctState = 3;
                sc.stateTime = block.timestamp;
                
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                uint256 feeSpent = gasAtStart.sub(gasleft()).add(63109).mul(tx.gasprice);
                uint256 usdtSpent = reserve1.mul(10**12).mul(feeSpent).div(reserve0).div(10**12);
                if(usdtSpent >= sc.value){
                    ownerTotalBalance = ownerTotalBalance.add(sc.value);
                    ownerCurrentBalance = ownerCurrentBalance.add(sc.value);
                }else{
                    uint256 amount = sc.value.sub(usdtSpent);
                
                    usdt.transfer(to, amount);
                    ownerTotalBalance = ownerTotalBalance.add(usdtSpent);
                    ownerCurrentBalance = ownerCurrentBalance.add(usdtSpent);
                }

                emit ConfirmTerminateSingleContract(msg.sender, _id, sc.cfAcc, sc.ctState, _isAccept, sc.stateTime);

                return;

            }

            require(3 days < block.timestamp - sc.stateTime, "have to wait 72 hours");

            if(msg.sender == sc.from) {
                
                sc.cfAcc = 1;
                sc.ctState = 3;
                sc.stateTime = block.timestamp;
                
            }else {
                sc.cfAcc = 2;
                sc.ctState = 3;
                sc.stateTime = block.timestamp;
            }

            uint256 amount1 = sc.value.mul(17).div(20);
            usdt.transfer(to, amount1);
            ownerTotalBalance = ownerTotalBalance.add(sc.value.sub(amount1));
            ownerCurrentBalance = ownerCurrentBalance.add(sc.value.sub(amount1));
            
            emit ConfirmTerminateSingleContract(msg.sender, _id, sc.cfAcc, sc.ctState, _isAccept, sc.stateTime);

        }else {
            sc.ctState = 1;
            sc.stateTime = block.timestamp;
                
            emit ConfirmTerminateSingleContract(msg.sender, _id, sc.cfAcc, sc.ctState, _isAccept, sc.stateTime);
        }
    }
    
    function signDoubleContract(address _to, uint256 _value) public {
        require(usdt.balanceOf(msg.sender) >= _value && _value > 0, "value error");
        doubleContract storage sc = doubleContracts[contractID++];
        sc.id = contractID.sub(1);
        sc.from = msg.sender;
        sc.to = _to;
        sc.fvalue = _value;
        sc.tvalue = 0;
        sc.prAcc = 0;
        sc.cfAcc = 0;
        sc.ctState = 0;
        sc.withdrawType = 0;
        sc.stateTime = block.timestamp;
        
        usdt.transferFrom(msg.sender, address(this), _value);
        
        emit SignDoubleContract(sc.id, sc.from, sc.to, owner, sc.fvalue, sc.tvalue, sc.prAcc, sc.cfAcc, sc.ctState, sc.withdrawType, sc.stateTime);
    }
    
    function confirmSignDoubleContract(uint256 _id, uint256 _value) public scExists(_id) {
        require(usdt.balanceOf(msg.sender) >= _value && _value > 0, "value error");
        doubleContract storage sc = doubleContracts[_id];
        require(msg.sender == sc.to, "you have not permission to confirm");
        require(sc.ctState == 0, "contract state wrong");
        require(3 days > block.timestamp - sc.stateTime, "the contract has expired");
        
        sc.tvalue = _value;
        sc.ctState = 1;
        sc.stateTime = block.timestamp;
        
        usdt.transferFrom(msg.sender, address(this), _value);
        
        emit ConfirmSignDoubleContract(msg.sender, _id, sc.tvalue, sc.cfAcc, sc.ctState, sc.stateTime);
    }
    
    function cancleDoubleContract(uint256 _id) public scExists(_id) {
        doubleContract storage sc = doubleContracts[_id];
        require(3 days < block.timestamp - sc.stateTime, "have to wait 72 hours");
        require(msg.sender == sc.from, "you have not permission to confirm");
        require(sc.ctState == 0, "contract state wrong");
        
        sc.ctState = 5;

        require(usdt.balanceOf(address(this)) >= sc.fvalue, "value error");
        usdt.transfer(msg.sender, sc.fvalue);
        
        emit CancleDoubleContract(msg.sender, _id, sc.ctState, sc.stateTime);
    }
    
    function applyTerminateDoubleContract(uint256 _id, uint8 _withdrawType) public scExists(_id) {
        doubleContract storage sc = doubleContracts[_id];
        require((msg.sender == sc.from && sc.prAcc != 1) || (msg.sender == sc.to && sc.prAcc != 2), "illegal address or not permission");
        require(sc.ctState == 1, "terminate contract is not confirm sign or in progress or finished");
        require(_withdrawType == 1 || _withdrawType == 2, "illegal withdrawType");
        
        if(msg.sender == sc.from) {
            sc.prAcc = 1;
            sc.ctState = 2;
            sc.withdrawType = _withdrawType;
            sc.stateTime = block.timestamp;
        }else {
            sc.prAcc = 2;
            sc.ctState = 2;
            sc.withdrawType = _withdrawType;
            sc.stateTime = block.timestamp;
        }
        
        emit ApplyTerminateDoubleContract(msg.sender, _id, sc.prAcc, sc.ctState, sc.withdrawType, sc.stateTime);
    }
    
    function confirmTerminateDoubleContract(uint256 _id, bool _isAccept) public scExists(_id) {
        uint256 gasAtStart = gasleft();
        doubleContract storage sc = doubleContracts[_id];
        require((msg.sender == sc.from && sc.prAcc != 1) || (msg.sender == sc.to && sc.prAcc != 2) || msg.sender == owner, "illegal address");
        require(sc.ctState == 2, "terminate contract finished or not start");
        address to = sc.prAcc == 1 ? sc.from : sc.to;
        require(usdt.balanceOf(address(this)) >= sc.fvalue.add(sc.tvalue), "value error");
        
        if(_isAccept){
            if(msg.sender == owner) {
                sc.cfAcc = 3;
                sc.ctState = 3;
                sc.stateTime = block.timestamp;
                
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                uint256 feeSpent = gasAtStart.sub(gasleft()).add(63109).mul(tx.gasprice);
                uint256 usdtSpent = reserve1.mul(10**12).mul(feeSpent).div(reserve0).div(10**12);
                
                if(sc.withdrawType == 1) {
                    uint256 usdtSpent1 = usdtSpent >= sc.fvalue ? sc.fvalue : usdtSpent;
                    uint256 usdtSpent2 = usdtSpent >= sc.tvalue ? sc.tvalue : usdtSpent;
                    uint256 amountOfWithdraw1 = sc.fvalue.sub(usdtSpent1);
                    uint256 amountOfWithdraw2 = sc.tvalue.sub(usdtSpent2);
                    
                    usdt.transfer(sc.from, amountOfWithdraw1);
                    usdt.transfer(sc.to, amountOfWithdraw2);
                    ownerTotalBalance = ownerTotalBalance.add(usdtSpent1.add(usdtSpent2));
                    ownerCurrentBalance = ownerCurrentBalance.add(usdtSpent1.add(usdtSpent2));
                }else {
                    usdtSpent = usdtSpent > sc.fvalue.add(sc.tvalue) ? sc.fvalue.add(sc.tvalue) : usdtSpent;
                    uint256 amountOfWithdraw = sc.fvalue.add(sc.tvalue).sub(usdtSpent);
                    
                    usdt.transfer(to, amountOfWithdraw);
                    ownerTotalBalance = ownerTotalBalance.add(usdtSpent);
                    ownerCurrentBalance = ownerCurrentBalance.add(usdtSpent);
                }

                emit ConfirmTerminateDoubleContract(msg.sender, _id, sc.cfAcc, sc.ctState, _isAccept, sc.stateTime);
                
                return;
            }
            
            require(3 days < block.timestamp - sc.stateTime, "have to wait 72 hours");
            
            if(msg.sender == sc.from) {
                sc.cfAcc = 1;
                sc.ctState = 3;
                sc.stateTime = block.timestamp;
            }
            
            if(msg.sender == sc.to) {
                sc.cfAcc = 2;
                sc.ctState = 3;
                sc.stateTime = block.timestamp;
            }
            
            uint256 amount1 = sc.fvalue.mul(17).div(20);
            uint256 amount2 = sc.tvalue.mul(17).div(20);
            uint256 amount3 = amount1.add(amount2);
            
            if(sc.withdrawType == 1) {
                usdt.transfer(sc.from, amount1);
                usdt.transfer(sc.to, amount2);
            }
            if(sc.withdrawType == 2) {
                usdt.transfer(to, amount3);
            }

            ownerTotalBalance = ownerTotalBalance.add(sc.fvalue.add(sc.tvalue).sub(amount3));
            ownerCurrentBalance = ownerCurrentBalance.add(sc.fvalue.add(sc.tvalue).sub(amount3));
                
            emit ConfirmTerminateDoubleContract(msg.sender, _id, sc.cfAcc, sc.ctState, _isAccept, sc.stateTime);
        }else {
            sc.ctState = 1;
            sc.stateTime = block.timestamp;
                
            emit ConfirmTerminateDoubleContract(msg.sender, _id, sc.cfAcc, sc.ctState, _isAccept, sc.stateTime);
        }
    }
    
    function withdraw(uint256 amount) public onlyOwner {
        require(ownerCurrentBalance >= amount, "amount exceeds balance");
        require(usdt.balanceOf(address(this)) >= amount, "amount exceeds balance");
        ownerCurrentBalance = ownerCurrentBalance.sub(amount);
        usdt.transfer(msg.sender, amount);
    }
    
    function updateOwnerAddress(address _newOwnerAddress) public onlyOwner {
        owner = _newOwnerAddress;
        
        emit UpdateOwnerAddress(owner);
    }
    
    function getSingleContract(uint256 _id) public view 
        returns (uint256 id, address from, address to, address manager, 
                 uint256 value, uint8 prAcc, uint8 cfAcc, uint8 ctState, uint256 stateTime)
    {
        singleContract storage sc = singleContracts[_id];
        return (sc.id, sc.from, sc.to, owner, sc.value, sc.prAcc, sc.cfAcc, sc.ctState, sc.stateTime);
    }
    
    function getDoubleContract(uint256 _id) public view 
        returns (uint256 id, address from, address to, address manager, 
                 uint256 fvalue, uint256 tvalue, uint8 prAcc, uint8 cfAcc, uint8 ctState, uint8   withdrawType, uint256 stateTime)
    {
        doubleContract storage sc = doubleContracts[_id];
        return (sc.id, sc.from, sc.to, owner, sc.fvalue, sc.tvalue, sc.prAcc, sc.cfAcc, sc.ctState, sc.withdrawType, sc.stateTime);
    }
}