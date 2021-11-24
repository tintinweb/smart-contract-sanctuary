/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    constructor()  {
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

contract LaunchPad is Ownable,ReentrancyGuard{
    
    IBEP20 public Busd;
    IBEP20 public Usdt;
    IBEP20 public token;
    uint public startTime;
    uint public endTime;
    uint public busdToJade;
    uint public usdtToJade;
    bool public lockStatus;
        
    struct userDetails {
        uint busdDepositAmount;
        uint usdTDepositAmount;
        bool status;
        uint busdReward;
        uint usdtReward;
    }
    
    mapping(address => userDetails)public users;
    
    modifier isLock() {
        require(lockStatus == false, "Witty: Contract Locked");
        _;
    }
    
    function initialize(
        IBEP20 _busd,
        IBEP20 _usdt,
        IBEP20 _token,
        uint _start,
        uint _end,
        uint _busdToJade, // Wei format
        uint _usdtToJade  // Wei format
        ) public onlyOwner {
        require(address(_busd) != address(0) && address(_usdt) != address(0) &&
        address(_token) != address(0),"Invalid address");
        Busd = _busd;
        Usdt = _usdt;
        token = _token;
        startTime = _start;
        endTime = _end;
        busdToJade = _busdToJade;
        usdtToJade = _usdtToJade;
    }
    
    function deposit(uint8 _type,uint _amount) public isLock {
        require(_type == 1 || _type == 2,"Incorrect type");
        require(_amount > 0,"Incorrect amount");
        require(block.timestamp > startTime && block.timestamp < endTime,"Invalid time");
        userDetails storage user = users[msg.sender];
        if (_type == 1) {
            IBEP20(Busd).transferFrom(msg.sender,address(this),_amount);
            user.busdDepositAmount += _amount;
            user.status = true;
        }
        else {
            IBEP20(Usdt).transferFrom(msg.sender,address(this),_amount);
            user.usdTDepositAmount += _amount;
            user.status = true;
        }
    }
    
    function claim()public nonReentrant isLock{
        require(block.timestamp > endTime,"Not a claim time");
        userDetails storage user = users[msg.sender];
        require(user.status,"Not yet deposit");
        uint amount;
        if (user.busdDepositAmount > 0) {
            amount = user.busdDepositAmount*busdToJade/1e18;
            IBEP20(token).transfer(msg.sender,amount);
            user.busdReward += amount;
        }
        if (user.usdTDepositAmount > 0) {
            amount = user.usdTDepositAmount*usdtToJade/1e18;
            IBEP20(token).transfer(msg.sender,amount);
            user.usdtReward += amount;
        }
        user.status = false;
        
    }
    
    function updatePercent(uint _busdToJade,uint _usdtToJade)public onlyOwner {
        busdToJade = _busdToJade;
        usdtToJade = _usdtToJade;
    }
    
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    function emergencyExit(IBEP20 _token,address _user,uint _amount)public onlyOwner {
        require(address(_token) != address(0) && _user != address(0),"Invalid address");
        require(_amount > 0,"Invalid amount");
        IBEP20(_token).transfer(_user,_amount);
    }
    
    
}