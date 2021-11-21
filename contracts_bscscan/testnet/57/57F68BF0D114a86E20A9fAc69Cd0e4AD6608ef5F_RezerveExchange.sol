/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


abstract contract Ownable is Context {
    address private _owner;

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
     * @dev Throws if called by any account other than the owner.
     */
    

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
} 



interface Reserve {
    function totalSupply() external ;
}



/**
 * @title VaultStaking
 * @dev Stake VLT/BNB LP Tokens
 */
contract RezerveExchange  is Ownable {
    
    using SafeMath for uint256;

    IERC20  public token;
    IERC20  public dai;
   
    address public EmergencyAddress;
    address public ReserveAddress;
    address public DaiAddress;
    address public burnAddress;
    
    uint256 public foreclosureReward;
    
    uint256 public BorrowsCount;
    mapping ( uint256 => Borrow ) public Borrows;
    mapping ( uint256 => forecloseInfo ) public forecloseInfos;
    
    mapping ( address => uint256[] ) public userBorrowings;
    mapping ( uint256 => ApprovedDay ) public ApprovedDays;
    
    uint256 public Collateral;
    
    
    struct ApprovedDay {
        bool approved;
        uint256 maxborrow;
        uint256 returnamount;
        
    }
    
    struct Borrow {
         
         address _user;
         uint256 _collateralamount;
         uint256 _amount;
         uint256 _borrowdate;
         uint256 _duedate;
         uint256 _paybackamount;
         uint256 _balance;
         uint256 _borrowdays;
         uint8   _status;
         uint256 _floorprice;
         
         uint256 _maxborrowpercent;
         uint256 _returnamountpercent;
     }
     
     struct forecloseInfo {
         
         address _forecloser;
         uint256 _forecloserreward;
         uint256 _paidtoforecloser;
     }
  
    constructor () {
       
        ReserveAddress = 0x23b8b512175590a76FFf32C6F06a7Ef1ce4724C7;
        DaiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        setTestnet(); // remove for mainnet
        
        
        token = IERC20 ( ReserveAddress ); 
        
        dai = IERC20 ( DaiAddress );
        
        
        EmergencyAddress = msg.sender;
        foreclosureReward = 8;
        
        burnAddress = 0x000000000000000000000000000000000000dEaD;   
        
        setApprovedDay ( 30,  80, 90 ); 
        setApprovedDay ( 90,  65, 80 );
        setApprovedDay ( 180, 60, 85 );
    }
    
    function setTestnet() internal {
        DaiAddress = 0x6BbC1F3190f82c0057847F75FA849566F85D9984;
        ReserveAddress = 0xE075766c90a5977b456F963Be3ADedE77611f366;
    }
    
   
   function exchangeReserve ( uint256 _amount ) public {
       
       token.transferFrom ( msg.sender, burnAddress, _amount );
       dai.transfer ( msg.sender, exchangeAmount ( _amount ));
   }
  
   function exchangeAmount ( uint256 _amount ) public view returns(uint256) {
       return _amount * floorPrice();
   }
   
   function EmergencyWithdrawal() public onlyOwner {
       if ( token.balanceOf ( address(this)) > 0 )    token.transfer ( msg.sender, token.balanceOf ( address(this) ));
       if ( dai.balanceOf   ( address(this)) > 0 )    dai.transfer ( msg.sender, dai.balanceOf ( address(this) ));
   }
   
   function EmergencyRZRVWithdrawal() public onlyOwner {
        token.transfer ( msg.sender, token.balanceOf ( address(this) ));
   }
   
   function EmergencyDAIWithdrawal() public onlyOwner {
        dai.transfer ( msg.sender, dai.balanceOf ( address(this) ));
   }
    
   function currentSupply() public view returns(uint256){
       return token.totalSupply().sub( token.balanceOf(burnAddress));
   } 
   
   
   
   function daiBalance() public view returns(uint256) {
       return dai.balanceOf(address(this));
   }
   
   function floorPrice() public view returns ( uint256 ){
       
       return  (daiBalance().div(currentSupply())) * 10 ** 9;
       
   }
   
   function flush() public {
        token.transfer ( burnAddress, token.balanceOf(address(this)) - Collateral );
       
   }
   
   
    function setApprovedDay ( uint256 _days,  uint256 _maxborrowpercent, uint256 _returnamountpercent ) public onlyOwner {
        require ( _days <= 365 && _days >= 30 , "Invalid range");
        ApprovedDays[_days].approved = true;
        ApprovedDays[_days].maxborrow = _maxborrowpercent;
        ApprovedDays[_days].returnamount = _returnamountpercent;
    }
    
    function unsetApprovedDay ( uint256 _days ) public onlyOwner {
        ApprovedDays[_days].approved = false;
         ApprovedDays[_days].maxborrow = 0;
        ApprovedDays[_days].returnamount = 0;
    }
    
    
   function setReserve ( address _address ) public OnlyEmergency {
       require(_address != address(0), "ERC20: transfer from the zero address");
       ReserveAddress = _address;
       token = IERC20 ( ReserveAddress ); 
   }
   
   function setForeclosureReward ( uint256 _amount ) public onlyOwner{
       require ( _amount >0 && _amount <= 20, "Out of Range" ); 
       foreclosureReward = _amount;
   }
  
   function borrowDAI ( uint256 _amount, uint256 _days  ) public returns ( uint256) {
       require ( ApprovedDays[_days].approved, "Time Period not approved" );
       require ( ApprovedDays[_days].returnamount > ApprovedDays[_days].maxborrow , "Configuration Error" );
       
       BorrowsCount++;
       ( uint256 _borrowAmount,  uint256 _paybackamount, uint256 _forecloserreward ) = borrowAmount ( _amount , _days );
       
       Borrows[BorrowsCount]._user = msg.sender;
       Borrows[BorrowsCount]._collateralamount = _amount;
       Borrows[BorrowsCount]._amount = _borrowAmount;
       Borrows[BorrowsCount]._borrowdate = block.timestamp;
       Borrows[BorrowsCount]._duedate = block.timestamp + ( _days * 10 seconds); // change to  1 days for mainnet
       Borrows[BorrowsCount]._paybackamount = _paybackamount;
       Borrows[BorrowsCount]._balance = _paybackamount;
       Borrows[BorrowsCount]._floorprice = floorPrice();
       Borrows[BorrowsCount]._borrowdays = _days;
       forecloseInfos[BorrowsCount]._forecloserreward = _forecloserreward;
       Borrows[BorrowsCount]._status = 1;
        
       Borrows[BorrowsCount]._maxborrowpercent = ApprovedDays[_days].maxborrow;     
       Borrows[BorrowsCount]._returnamountpercent = ApprovedDays[_days].returnamount;
       
       userBorrowings[msg.sender].push ( BorrowsCount);
       
       token.transferFrom ( msg.sender, address(this), _amount );
       Collateral += _amount;
       
       dai.transfer ( msg.sender, _borrowAmount );
       
       return ( BorrowsCount);
       
   }
   
   function paybackDAI ( uint256 _borrownumber , uint256 _amount ) public {
       
       require ( Borrows[_borrownumber]._user == msg.sender, "Not owner");
       require ( _amount <=  Borrows[_borrownumber]._balance ,  "Amount must be non-zero");
       require ( Borrows[_borrownumber]._status == 1, "Payback closed" );
       require ( Borrows[_borrownumber]._duedate >= block.timestamp, "Loan is in Default/ Payback no longer possible"  );
       
       dai.transferFrom ( msg.sender, address(this), _amount );
       
       (uint256 _tobereleased, uint256 _newcollateralamount,) = getToBeReleased (  _amount, _borrownumber );
       Borrows[_borrownumber]._collateralamount = _newcollateralamount;
       
       (,,uint256 _forecloserreward ) = borrowAmount ( _newcollateralamount , Borrows[_borrownumber]._borrowdays );
       forecloseInfos[_borrownumber]._forecloserreward = _forecloserreward;
       
       
       Borrows[_borrownumber]._balance -= _amount;
       token.transfer ( msg.sender, _tobereleased );
       
       if ( balanceLeft(  _borrownumber ) == 0 ) Borrows[_borrownumber]._status = 2;
   }
   
   function balanceLeft( uint256 _borrownumber ) public view returns ( uint256) {
       
       return Borrows[_borrownumber]._balance;
   }
   
   function foreclose( uint256 _borrownumber  ) public {
       require ( block.timestamp > Borrows[_borrownumber]._duedate, "Borrower is not in default" );
       require ( Borrows[_borrownumber]._status == 1, "Not Available" );
       Borrows[_borrownumber]._status = 3;
       forecloseInfos[_borrownumber]._forecloser = msg.sender;
       forecloseInfos[_borrownumber]._paidtoforecloser = forecloseInfos[_borrownumber]._forecloserreward;
       token.transfer ( msg.sender, forecloseInfos[_borrownumber]._forecloserreward );
       token.transfer ( burnAddress, Borrows[_borrownumber]._collateralamount - forecloseInfos[_borrownumber]._forecloserreward );
       
   }
   

   uint256 public AMOUNT;
   uint256 public BORROWNUMBER;
   
   function getToBeReleased ( uint256 _amount, uint256 _borrownumber ) public  view returns ( uint256, uint256, uint256) {
       
       
       uint256 newoutstandingbalance = Borrows[_borrownumber]._balance - _amount;
       
       uint256 newcollateralamount = ((newoutstandingbalance /  floorPrice()) / (Borrows[_borrownumber]._maxborrowpercent) * 100) * 10 ** 9 ;
       
       uint256 _releaseamount = Borrows[_borrownumber]._collateralamount - newcollateralamount;
       
       return ( _releaseamount, newcollateralamount, newoutstandingbalance );
   }
   
   function toggleApprovedDays ( uint256 _days ) public onlyOwner{
       ApprovedDays[_days].approved = !ApprovedDays[_days].approved;
   }
   
   function borrowAmount ( uint256 _amount, uint256 _days ) public view returns (uint256, uint256, uint256 ){
       if ( !ApprovedDays[_days].approved ) return (0,0,0);
       
       uint256 _floorvalue = (_amount * floorPrice())/10**9;
       return ((_floorvalue * ApprovedDays[_days].maxborrow)/100, (_floorvalue * ApprovedDays[_days].returnamount)/100, (_amount * foreclosureReward / 100) ) ;
   }
  
   
   
  
  
    modifier OnlyEmergency() {
        require( msg.sender == EmergencyAddress, "SSVault: Emergetcy Only");
        _;
    }
    
  
  
}