/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity 0.8.0;

//SPDX-License-Identifier: UNLICENSED

interface mentormlm {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Mentor {
    
    using SafeMath for uint256;
    
    address public owner;
    address public productWallet;
    address public netWallet;
    bool public lockStatus;
    mentormlm public token;
    uint public depAmount = 28e18;
    uint public currentId = 1;
    
    struct user {
        uint id;
        address[] referals;
        address referer;
        uint depositAmt;
        uint level;
        bool active;
        address[] firstLineRef;
        address[] secondLinRef;
        address[] thirdLineRef;
        address[] fourthLineRef;
        address[] fifthLineRef;
        address[] sixthLineRef;
        mapping(uint => bool)levelStatus;
    }
    
    mapping (address => user) public users;
    
    constructor (address _owner,address _token,address _productwaller,address _netwallet)  {
        token = mentormlm(_token);
        owner = _owner;
        productWallet = _productwaller;
        netWallet = _netwallet;
        
        users[_owner].id = currentId;
        users[_owner].active = true;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "Witty: Contract Locked");
        _;
    }

    /**
     * @dev Throws if called by other contract
     */
    modifier isContractCheck(address _user) {
        require(!isContract(_user), "Witty: Invalid address");
        _;
    }
    
    // User can register with depositAmount
    function register(
        uint _amount,
        address _ref
    ) public isLock isContractCheck(msg.sender) {
        require(depAmount == _amount && _amount > 0,"Incorrect amount");
        require(_ref != address(0) && users[_ref].active == true,"Invalid referer");
        currentId++;
        token.transferFrom(msg.sender,address(this),_amount);
        users[msg.sender].depositAmt = _amount.sub(8e18);
        users[msg.sender].id = currentId;
        users[msg.sender].referer = _ref;
        users[msg.sender].active = true;
        updateReferer(msg.sender,_ref);
    }
    
    function updateReferer(
        address _user,
        address _ref
    ) internal {
        address firstRef = _ref;
        address secondRef = users[firstRef].referer;
        address thirdRef = users[secondRef].referer;
        address fourthRef = users[thirdRef].referer;
        address fifthRef = users[fourthRef].referer;
        address sixthRef = users[fifthRef].referer;
        
        if (firstRef != address(0)) {
            users[firstRef].firstLineRef.push(_user);
        }
        if (secondRef != address(0)) {
            users[secondRef].secondLinRef.push(_user);
        }
        if (thirdRef != address(0)) {
            users[thirdRef].thirdLineRef.push(_user);
        }
        if (fourthRef != address(0)) {
            users[fourthRef].fourthLineRef.push(_user);
        }
        if (fifthRef != address(0)) {
            users[fifthRef].fifthLineRef.push(_user);
        }
        if (sixthRef != address(0)) {
            users[sixthRef].sixthLineRef.push(_user);
        }
        updateLevels(firstRef,secondRef,thirdRef,fourthRef,
        fifthRef,sixthRef);
    }
    
    function updateLevels(
        address _firstref,
        address _secondref,
        address _thirdref,
        address _fourthref,
        address _fifthref,
        address _sixthref
    ) internal {
       
         if (_firstref != address(0) && users[_firstref].firstLineRef.length >= 3 
           && users[_firstref].levelStatus[1] == false ) {
              users[_firstref].level = 1;
              users[_firstref].levelStatus[1] = true;
              token.transfer(productWallet,8e18);
              token.transfer(netWallet,2e18);
         }
         
         if (_secondref != address(0) && users[_secondref].secondLinRef.length >= 9
           && users[_secondref].levelStatus[2] == false ) {
              users[_secondref].level = 2;
              users[_secondref].levelStatus[2] = true;
              token.transfer(productWallet,50e18);
              token.transfer(netWallet,100e18);
         }
         
         if (_thirdref != address(0) && users[_thirdref].thirdLineRef.length >= 27 
           && users[_thirdref].levelStatus[3] == false ) {
              users[_thirdref].level = 3;
              users[_thirdref].levelStatus[3] = true;
              token.transfer(productWallet,300e18);
              token.transfer(netWallet,3800e18);
         }
         
         if (_fourthref != address(0) && users[_fourthref].fourthLineRef.length >= 81 
           && users[_fourthref].levelStatus[4] == false ) {
              users[_fourthref].level = 4;
              users[_fourthref].levelStatus[4] = true;
              token.transfer(productWallet,8e18);
              token.transfer(netWallet,2e18);
         }
         
         if (_fifthref != address(0) && users[_fifthref].fifthLineRef.length >= 243 
           && users[_fifthref].levelStatus[5] == false ) {
              users[_fifthref].level = 5;
              users[_fifthref].levelStatus[5] = true;
              token.transfer(productWallet,50000e18);
              token.transfer(netWallet,270000e18);
         }
         
         if (_sixthref != address(0) && users[_sixthref].sixthLineRef.length >= 729 
           && users[_sixthref].levelStatus[6] == false ) {
              users[_sixthref].level = 6;
              users[_sixthref].levelStatus[6] = true;
              token.transfer(productWallet,8e18);
              token.transfer(netWallet,2e18);
         }
        
    }
    
    // User can view their referals upto 6 Levels
    function viewUserDetails(address _user
    )  public view returns(
        address[] memory,
        address[] memory,
        address[] memory,
        address[] memory,
        address[] memory,
        address[] memory
        ) {
        return (
        users[_user].firstLineRef,
        users[_user].secondLinRef,
        users[_user].thirdLineRef,
        users[_user].fourthLineRef,
        users[_user].fifthLineRef,
        users[_user].sixthLineRef);
    }
    
    // User can check the status of level
    function viewLevelActive(address _user,uint _level)public view returns(bool) {
        return users[_user].levelStatus[_level];
    }
    
    // Admin can update the wallet address
    function updateAddress(address _netwallet,address _productwallet,address _owner) public onlyOwner {
        netWallet = _netwallet;
        productWallet = _productwallet;
        owner = _owner;
    }
    
    /**
     * @dev failSafe: Returns transfer token
     */
    function failSafe(address  _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "Mentor: Invalid Address");
        require(token.balanceOf(address(this)) >= _amount, "Mentor: Insufficient balance");
        token.transfer(_toUser,_amount);
        //emit FailSafe(_toUser, _amount, block.timestamp);
        return true;
    }

    /**
     * @dev contractLock: For contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * @dev isContract: Returns true if account is a contract
     */
    function isContract(address _account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0)
            return true;
        return false;
    }
}