/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IErc20Fee {
    function fee(uint amount, uint blockNumber) external view returns(uint);
}




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


contract UserBalanceQueueContract {
    
    mapping(address => uint[]) public amountM;
    mapping(address => uint[]) public blockNumberM;
    
    function length(address addr) public view returns(uint,uint){
        return (amountM[addr].length,blockNumberM[addr].length);
    }
    
    function add(address addr,uint amount,uint blockNumber) internal {
        amountM[addr].push(amount);
        blockNumberM[addr].push(blockNumber);
    }
    
    function frontAmount(address addr,uint amount) internal {
        require(blockNumberM[addr].length>0,'user must have balance record');
        uint blockNumber=blockNumberM[addr][0];
        if(blockNumberM[addr].length>1 && blockNumber==0){
            amountM[addr][1]=amount;
        } else {
            amountM[addr][0]=amount;
        }
    }
    
    function front(address addr) internal view returns(uint amount,uint blockNumber){
        require(blockNumberM[addr].length>0,'user must have balance record');
        blockNumber=blockNumberM[addr][0];
        if(blockNumberM[addr].length>1 && blockNumber==0){
            blockNumber= blockNumberM[addr][1];
            amount=amountM[addr][1];
        }
        else{
            amount=amountM[addr][0];
        }
    }
    
    function pop(address addr) internal returns(uint amount,uint blockNumber){
        uint n=blockNumberM[addr].length;
        require(n>0,'user must have balance record');
        blockNumber=blockNumberM[addr][0];
        if(blockNumber!=0){
            amount=amountM[addr][0];
            if(n>1){
                blockNumberM[addr][0]=0;
                return (amount,blockNumber);
            } else {
                popM(addr);
                return (amount,blockNumber);
            }
        }
        assert(n>1);
        blockNumber=blockNumberM[addr][1];
        amount=amountM[addr][1];
        swap(addr,1,n-1);
        sedimentation(addr,1,n-1);
        popM(addr);
        if(blockNumberM[addr].length==1){
            popM(addr);
        }
        return (amount,blockNumber);
    }
    
    function sedimentation(address addr,uint dq,uint n) private {
        uint next=dq;
        uint nextBlock=blockNumberM[addr][dq];
        uint temp=(dq<<1);
        if(temp<n){
            uint left=blockNumberM[addr][temp];
            if(left<nextBlock){
                next=temp;
                nextBlock=left;
            }
        }
        temp=(dq<<1)+1;
        if(temp<n){
            uint right=blockNumberM[addr][temp];
            if(right<nextBlock){
                next=temp;
                nextBlock=right;
            }
        }
        if(next!=dq){
            swap(addr,dq,next);
            sedimentation(addr,next,n);
        }
    }
    
    function popM(address addr) private {
        blockNumberM[addr].pop();
        amountM[addr].pop();
    }
    
    function swap(address addr,uint left,uint right) private {
        (amountM[addr][left],amountM[addr][right])=(amountM[addr][right],amountM[addr][left]);
        (blockNumberM[addr][left],blockNumberM[addr][right])=(blockNumberM[addr][right],blockNumberM[addr][left]);
    }
    
}

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

contract Erc20WithFee is Ownable,IERC20,UserBalanceQueueContract {
    string public constant name = 'twallet';
    string public constant symbol = 'twallet';
    uint8 public constant decimals = 18;
    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
    IErc20Fee public feeAddress;
    
    using SafeMath for uint;

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] >=value) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function burn(address from, uint value) external onlyOwner {
        _burn(from, value);
    }

    function mint(address to, uint value) external onlyOwner {
        _mint(to, value);
    }
    
    function setFeeAddress(IErc20Fee erc20Fee) external onlyOwner {
        feeAddress=erc20Fee;
    }
    
    function _fee(uint amount, uint blockNumber) public view returns(uint){
        if(feeAddress==IErc20Fee(address(0))){
            return 0;
        }
        uint feeNumber=feeAddress.fee(amount,blockNumber);
        require(amount>=feeNumber,'fee must less than amount');
        return feeNumber;
    }
    
    function _mint(address to, uint value) internal {
        require(value>0,'value must greater than 0');
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        _add(to,value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        require(value>0,'value must greater than 0');
        _reduce(from,value);
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(value>0,'value must greater than 0');
        uint fee=_reduce(from,value);
        balanceOf[from] = balanceOf[from].sub(value);
        value-=fee;
        require(value>0,'value must greater than fee');
        balanceOf[to] = balanceOf[to].add(value);
        _add(to,value);
        if (fee>0) {
            totalSupply = totalSupply.sub(fee);
            emit Transfer(from, address(0), fee);
        }
        emit Transfer(from, to, value);
    }
    
    
    function _add(address addr,uint value) private {
        UserBalanceQueueContract.add(addr,value,block.number);
    }
    
    function _reduce(address addr,uint value) private returns(uint) {
        require(balanceOf[addr]>=value,'user must have balance');
        uint fee=0;uint amount;uint blockNumber;
        do{
            (amount,blockNumber)=UserBalanceQueueContract.front(addr);
            if(value>=amount){
                fee+=_fee(amount,blockNumber);
                UserBalanceQueueContract.pop(addr);
                value-=amount;
            } else {
                fee+=_fee(value,blockNumber);
                UserBalanceQueueContract.frontAmount(addr,amount-value);
                value=0;
            }
        } while(value>0);
        return fee;
    }

}