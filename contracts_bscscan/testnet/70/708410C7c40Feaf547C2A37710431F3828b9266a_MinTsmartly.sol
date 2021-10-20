/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.4;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor()  {}

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
    constructor() {
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
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
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

interface IBEP20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract MinTsmartly is Ownable,ReentrancyGuard {
    
    uint public poolId;
    bool public lockStatus;
    
    struct pools {
        address token;
        uint id;
        uint startTime;
        uint endTime;
        uint amount;
        bool status;
        uint8 perBnbToken;
    }
    
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }
    
    modifier isContractCheck(address _user) {
        require(!isContract(_user), "Invalid address");
        _;
    }
    
    event AddSale(address Token,uint Startime,uint EndTime,uint amount,uint8 PerBnb,uint time);
    event Claim(address indexed user,uint Pid,uint depositAmount,uint tokenAmount,uint time);
    
    mapping(uint => pools)public poolList;
    
    receive()external payable{
         revert("No acces");
    }
    
    function addSale(
        address token,
        uint _starttime,
        uint _endtime,
        uint _amount,
        uint8 _bnbPerTpoken
    ) public onlyOwner {
        poolId++;
        pools storage pid = poolList[poolId];
        require(token != address(0),"Invalid token address");
        require(_starttime > 0 && _endtime > 0,"Invalid time");
        require(_amount > 0,"Invalid Amount");
        require(!pid.status,"Already added");
        
        IBEP20(token).transferFrom(msg.sender,address(this),_amount);
        pid.token = token;
        pid.id = poolId;
        pid.startTime = _starttime;
        pid.endTime = _endtime;
        pid.amount = _amount;
        pid.perBnbToken = _bnbPerTpoken;
        pid.status = true;
        emit AddSale(token,_starttime,_endtime,_amount,_bnbPerTpoken,block.timestamp);
    }
    
    function claim(
        uint _pid
    ) public payable nonReentrant isLock isContractCheck(msg.sender){
      pools storage pid = poolList[_pid];
      require(_pid > 0 && pid.status,"Incorrct pool id");
      require(block.timestamp <= pid.endTime,"Sale finsihed");
      uint amt = (pid.perBnbToken*msg.value/1e18)*1e18;
      IBEP20(pid.token).transfer(msg.sender,amt);
      emit Claim(msg.sender,_pid,msg.value,amt,block.timestamp);
    }
    
    function failSafe(address _token,address _toUser,uint _amount,uint8 _flag) public onlyOwner {
        require(_toUser != address(0) && _amount > 0,"Invalid argument");
        if (_flag == 1) {
        require(_token != address(0),"Token must be 0");
        require(IBEP20(_token).balanceOf(address(this)) >= _amount,"Insufficent amount");
        IBEP20(_token).transfer(_toUser,_amount);
        }
        else {
        require(_token == address(0),"Token must be 0");
        require(address(this).balance >= _amount,"Insufficent amount");
        require(payable(_toUser).send(_amount),"send failed");
        }
    }
    
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
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