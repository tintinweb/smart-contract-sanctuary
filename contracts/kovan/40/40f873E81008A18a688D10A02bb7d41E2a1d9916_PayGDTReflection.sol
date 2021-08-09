/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;


//import the ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}



//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}



interface IGorillaDiamond {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}



contract PayGDTReflection is Context, Ownable{
    using SafeMath for uint256;

    IGorillaDiamond gorillaDiamondInstance = IGorillaDiamond(0x754D73CbB65B0287884E39a510F77805f5D634e1);

    
    // add mapping updates to any functions needed; not done
    
    // tracks reflections individually earned/not withdrawn and withdrawn
    mapping (address => uint256) public reflectionsToPay;  
    mapping (address => uint256) public reflectionsWithdrawn;
    mapping (address => uint256) public totalReflectionsEarnedBalance;
    
    uint256 public totalReflectionsWithdrawnRT;
    address public _holderAccount= 0x5CE28EeAD9F46Ae6AA389dd088Faf047A40432F7; 
    uint256 public totalReflectionsEarnedRT;
    uint256 public reflectionsPaidToHolderAccount;
    
    


    // can control send average account balance to contract as soon as wallet connects???
    mapping (address => uint256) public accountAverageBalance;
    // uint256 accountBalanceMUL = accountAverageBalance[_msgSender()].mul(1000000000000000);

    
    

    // *****************write so no decimals/fractions are used!!!!!!!!!!!!!!!!!!!!
    // need to multiply GDTAccountsBalance by huge number then divide rewardToPay by same number
    // 1,000,000,000,000,000

    // uint256 ratio = (GDTAccountsBalance / _totalGDTAccountsBalances);
    // uint256 rewardToPay = (reflectionReward * ratio);
            
        
    // calculates totalReflectionsEarnedBalance for msg.sender
    // totalGDT is inputted by control   
    // will probably need control to enter an averaged account balance instead of calling it
    function calculateTotalReflectionsEarnedBalance(uint256 _totalGDT) private returns(bool) {
        uint256 accountBalance = getMyAccountBalance();                     // replace with control average
        uint256 accountBalanceMUL = accountBalance.mul(1000000000000000);
        uint256 ratio = accountBalanceMUL.div(_totalGDT);

        calculateReflectionsPaidToHolderAccount();
        uint256 _totalReflections = reflectionsPaidToHolderAccount.add(totalReflectionsEarnedRT);
        uint256 _reflectionsEarned = _totalReflections.mul(ratio);
        totalReflectionsEarnedBalance[_msgSender()] = _reflectionsEarned.div(1000000000000000);
        return true;
    } 

    // determines amount for rewardToPay available to withdraw
    function calculateReflectionsToPay(uint256 _totalGDT) public returns(bool) {
        calculateTotalReflectionsEarnedBalance(_totalGDT);
        uint256 _reflectionsToPay = totalReflectionsEarnedBalance[_msgSender()].sub(reflectionsWithdrawn[_msgSender()]);
        reflectionsToPay[_msgSender()] = _reflectionsToPay;
        return true;
    }
        
    

    // add to total of reflections earned by RT
    // called by control once amount of GDT has been swapped for and transferred into holder account
    function addTotalReflectionsEarnedRT(uint256 amountDeposited) public onlyOwner returns(bool) {
       uint _totalReflections = totalReflectionsEarnedRT.add(amountDeposited);
       totalReflectionsEarnedRT = _totalReflections;
       return true;
    }

    // add to total reflections withdrawn
    // called whenever reflections are transferred to a GDT account
    function addTotalReflectionsWithdrawnRT(uint256 amountWithdrawn) internal returns(bool) {
       uint _totalReflections = totalReflectionsWithdrawnRT.add(amountWithdrawn);
       totalReflectionsWithdrawnRT = _totalReflections;
       return true;
    }

    // get total amount of reflections earned by RT from service fees
    function getReflectionsEarnedRT() public view onlyOwner returns(uint256) {
        return totalReflectionsEarnedRT;
    }

    // get total amount of RT reflections withdrawn
    function getReflectionsWithdrawnRT() public view onlyOwner returns(uint256) {
        return totalReflectionsWithdrawnRT;
    }

    // balance of holder account + totalReflectionsWithdrawnRT - totalReflectionsEarnedRT = reflections paid into account from sales
    //get amount of reflections paid to holder account by GDT sales
    function calculateReflectionsPaidToHolderAccount() public onlyOwner returns(bool) {
        uint256 holderBalance = gorillaDiamondInstance.balanceOf(_holderAccount);
        uint256 reflectionsPaid = (holderBalance + totalReflectionsWithdrawnRT) - totalReflectionsEarnedRT;
        reflectionsPaidToHolderAccount = reflectionsPaid;
        return true;
    }

    // get total amount of reflections paid to holder acount by GDT sales
    function getReflectionsPaidToHolderAccount() public view onlyOwner returns(uint256) {
        return reflectionsPaidToHolderAccount;
    }

    // get RT holder account
    function getHolderAccount() public view onlyOwner returns (address) {
        return _holderAccount;
    }

    // change the holder account address used
    function changeHolderAccount(address _newHolderAccount) public onlyOwner returns(bool) {
        _holderAccount = _newHolderAccount;
        return true;
    }

    // get balance of RT holder account
    function getHolderAccountBalance() public onlyOwner view returns(uint256) {
        uint256 holderAccountBalance = gorillaDiamondInstance.balanceOf(_holderAccount);
        return holderAccountBalance;
    }

    // get balance of any account holding GDT
    function getAccountBalance(address _GDTholder) public onlyOwner view returns(uint256) {
        uint256 GDTAccountBalance = gorillaDiamondInstance.balanceOf(_GDTholder);
        return GDTAccountBalance;
    }

    // get balance of msg.sender
    function getMyAccountBalance() private view returns(uint256) {
        uint256 myAccountBalance = gorillaDiamondInstance.balanceOf(_msgSender());
        return myAccountBalance;
    }

    // transfer reflections from holder account to msgSender; called by control
    // need to set minimum value of rewardToPay before allowing transfer
    function payReflection(address recipient) public onlyOwner returns(bool) {
        gorillaDiamondInstance.transfer(recipient, reflectionsToPay[recipient]);
        addTotalReflectionsWithdrawnRT(reflectionsToPay[recipient]);
        return true;
    }

    // control inputs spender address, captures it when connecting
    // approves msgSender to transfer their reflection GDT to their account from holder account
    // must be called by control before withdraw()
    function approveWithdraw(address spender) public onlyOwner returns(bool) {
        gorillaDiamondInstance.approve(spender, reflectionsToPay[spender]);
        return true;
    }

    // transfer reflections from holder account to msgSender; called by msgSender
    // control must call approveWithdraw() first
    function withdraw() public returns(bool) {
        reflectionsWithdrawn[_msgSender()].add(reflectionsToPay[_msgSender()]);
        addTotalReflectionsWithdrawnRT(reflectionsToPay[_msgSender()]);
        
        gorillaDiamondInstance.transferFrom(_holderAccount, _msgSender(), reflectionsToPay[_msgSender()]);
        return true;
    }

    function getMyAddress() public view returns(address) {
        address _spender = _msgSender();
        return _spender;
    }

    function transfer(address recipient, uint256 rewardToPay) private returns (bool) {
        gorillaDiamondInstance.transfer(recipient, rewardToPay);
        return true;
    }



    
}