pragma solidity ^0.4.24;



library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
  internal {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage _role, address _addr)
  internal {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
  internal
  view {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
  internal
  view
  returns(bool) {
    return _role.bearer[_addr];
  }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}





/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles
  for Roles.Role;

  mapping(string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
  public
  view {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
  public
  view
  returns(bool) {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
  internal {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
  internal {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role) {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}











contract LotteryData is Ownable {
    using SafeMath for uint;

    address public lotteryCore;

    enum LotteryStatus { Default, Going, Finshed }

    struct Prize {
        string name;            
        uint amount;         
        uint remainAmount;     
        uint probability;      
        address[] winners;      
        mapping(address => bytes32) winRecords; 
        uint[] winProbArray;  
    }

    struct Lottery {
        string name;           
        LotteryStatus status;  
        uint totalPrizeAmount;  
        uint totalDrawCnt;     
        uint LCM;             
        Prize[] prizes;       
    }

    Lottery[] public lotteries;

    event NewLotteryCore(address _lotteryCore);
    event UserDrawInfo(bytes32 indexed hash, uint indexed random, uint indexed res);
    event UserDrawPrize(address indexed sender, uint indexed lotteryId, uint indexed prizeId);
    event CloseLottery(uint _lotteryId, string reason);

    constructor() public {}

    /*
     * 
     */
    modifier onlyCore() {
        require(msg.sender == lotteryCore, "Only Core contract modifier");
        _;
    }

    /*
     * 
     */
    function setLotteryCore(address _lotteryCore) public onlyOwner {
        lotteryCore = _lotteryCore;
        emit NewLotteryCore(_lotteryCore);
    }

    /*
     * 
     */
    function createLottery(string _name) external onlyCore returns(uint) {
        lotteries.length ++;
        Lottery storage lottery = lotteries[lotteries.length - 1];
        lottery.name = _name;
        lottery.status = LotteryStatus.Default;
        return lotteries.length-1;
    }

    /*
     * 
     */
    function addLotteryPrize(uint lotteryId, string _name, uint _amount, uint _probability) external onlyCore {
        Lottery storage lottery = lotteries[lotteryId];
        require(lottery.status == LotteryStatus.Default, "lottery status not Default");
        Prize memory prize;
        prize.name = _name;
        prize.amount = _amount;
        prize.remainAmount = _amount;
        prize.probability = _probability;
        lottery.prizes.push(prize);
        lottery.totalPrizeAmount += _amount;
    }

    /*
     * 
     */
    function getLotteriesLength() public view returns(uint) {
        return lotteries.length;
    }

    /*
     * 
     */
    function getLotteryPrizesLength(uint _lotteryId) public view returns(uint) {
        return lotteries[_lotteryId].prizes.length;
    }

    /*
     * 
     */
    function startLottery(uint lotteryId) external onlyCore {
        Lottery storage lottery = lotteries[lotteryId];
        require(lottery.status == LotteryStatus.Default, "lottery status not Defalut");
        require(lottery.prizes.length > 0, "lottery prizes is null");
        lottery.LCM = getLestCommonMulArray(lotteryId);
        uint winProbBegin = 0;
        for (uint i = 0; i < lottery.prizes.length; i++) {
            Prize storage prize = lottery.prizes[i];
            for (uint j = 0; j < lottery.LCM.div(prize.probability); j++) {
                prize.winProbArray.push(winProbBegin);
                winProbBegin ++;
            }
        }

        lottery.status = LotteryStatus.Going;
    }

    /*
     *
     */
    function closeLottery(uint lotteryId, string reason) public onlyCore {
        Lottery storage lottery = lotteries[lotteryId];
        lottery.status = LotteryStatus.Finshed;
        emit CloseLottery(lotteryId, reason);
    }

    /*
     *
     */
    function draw(uint lotteryId, address sender) external onlyCore returns(bool) {
        Lottery storage lottery = lotteries[lotteryId];
        require(lottery.status == LotteryStatus.Going, "lottery status is not Going");
        lottery.totalDrawCnt ++;
        uint random = getRandomNum(sender, lottery.totalDrawCnt);

        uint drawRes = random % lottery.LCM;
        emit UserDrawInfo(blockhash(block.number - 1), random, drawRes);
        for (uint i = 0; i < lottery.prizes.length; i++) {
            Prize storage prize = lottery.prizes[i];
            if (prize.remainAmount > 0) {
                for (uint j = 0; j < prize.winProbArray.length; j++) {
                    if (drawRes == prize.winProbArray[j]) {
                        prize.winners.push(sender);
                        prize.winRecords[sender] = blockhash(block.number - 1);
                        prize.remainAmount --;
                        lottery.totalPrizeAmount --;
                        emit UserDrawPrize(sender, lotteryId, i);

                        if (lottery.totalPrizeAmount == 0) {
                            closeLottery(lotteryId, "run out of prizes");
                        }
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /*
     * 
     * 
     */
    function getRandomNum(address sender, uint lotteryCnt) internal view returns(uint) {
        bytes32 blockhashBytes = blockhash(block.number - 1);
        bytes4 lotteryBytes = bytes4(lotteryCnt);
        uint joinLength = blockhashBytes.length + 20 + lotteryBytes.length;
        bytes memory hashJoin = new bytes(joinLength);
        uint k = 0;
        for (uint i = 0; i < blockhashBytes.length; i++) {
            hashJoin[k++] = blockhashBytes[i];
        }
        // bytes 
        for (i = 0; i < 20; i++) {
            hashJoin[k++] = byte(uint8(uint(sender) / (2 ** (8 * (19 - i)))));
        }
        for (i = 0; i < lotteryBytes.length; i++) {
            hashJoin[k++] = lotteryBytes[i];
        }
        return uint(keccak256(hashJoin));
    }

    /*
     * 
     */
    function getLotteryInfo(uint _lotteryId) public view returns(string, uint, uint, uint, uint) {
        Lottery storage lottery = lotteries[_lotteryId];
        return (
            lottery.name,
            uint(lottery.status),
            lottery.totalPrizeAmount,
            lottery.LCM,
            lottery.prizes.length
        );
    }

    /*
     * 
     */
    function getLotteryPrizeInfo(uint _lotteryId, uint prizeIndex) public view returns(string, uint, uint, uint, address[], uint[]) {
        Lottery storage lottery = lotteries[_lotteryId];
        Prize storage prize = lottery.prizes[prizeIndex];

        return (
            prize.name,
            prize.amount,
            prize.remainAmount,
            prize.probability,
            prize.winners,
            prize.winProbArray
        );
    }

    /*
     * 
     */
    function getLotteryStatus(uint _lotteryId) public view returns(uint) {
        Lottery storage lottery = lotteries[_lotteryId];
        return uint(lottery.status);
    }

    /*
     * 
     */
    function getLestCommonMulArray(uint lotteryId) internal view returns(uint) {
        Lottery storage lottery = lotteries[lotteryId];
        uint prizesLength = lottery.prizes.length;
        uint[] memory probArray = new uint[](prizesLength);
        for (uint i = 0; i < prizesLength; i++) {
            probArray[i] = lottery.prizes[i].probability;
        }
        uint tempLCM = probArray[0];
        for (uint j = 0; j < probArray.length - 1; j ++) {
            tempLCM = getLestCommonMul(tempLCM, probArray[j+1]);
        }
        return tempLCM;
    }

    function getLestCommonMul(uint a, uint b) internal pure returns(uint) {
        uint min = a > b ? b : a;
        uint max = a > b ? a : b;

        for (uint i = 1; i <= max; i++) {
            uint temp = min.mul(i);
            if (temp % max == 0) {
                return temp;
            }
        }
    }

}



contract LotteryCore is Ownable, RBAC {

    LotteryData internal lotteryData;

    /*
     * 
     * params: owner,
     */
    constructor(address _owner, address _lotteryDataAddress)  public {
        require(_owner != address(0x0), "error: owner address is 0x00");
        require(_lotteryDataAddress != address(0x0), "error: _lotteryDataAddress address is 0x00");
        lotteryData = LotteryData(_lotteryDataAddress);
        addRole(_owner, "admin");
    }

    /*
     * 
     */
    function addAdmin(address _admin) public onlyOwner {
        addRole(_admin, "admin");
    }

    /*
     * 
     */
    function removeAdmin(address _admin) public onlyOwner {
        removeRole(_admin, "admin");
    }

    /*
     *
     */
    function updateLotteryData(address _lotteryDataAddress) public onlyOwner {
        require(_lotteryDataAddress != address(0x0), "error: _lotteryDataAddress is 0x00");
        lotteryData = LotteryData(_lotteryDataAddress);
    }

    /*
     * 
     */
    function createLottery(string _lotteryName) public onlyRole("admin") returns(uint) {
        return lotteryData.createLottery(_lotteryName);
    }

    /*
     *
     */
    function addLotteryPrize(uint _lotteryId, string _prizeName, uint _amount, uint _probability) public onlyRole("admin") {
        lotteryData.addLotteryPrize(_lotteryId, _prizeName, _amount, _probability);
    }

    /*
     *
     */
    function startLottery(uint _lotteryId) public onlyRole("admin") {
        lotteryData.startLottery(_lotteryId);
    }

    /*
     * 
     */
    function closeLottery(uint _lotteryId) public onlyRole("admin") {
        lotteryData.closeLottery(_lotteryId, "admin close lottery");
    }

    /*
     * 
     */
    function userDraw(uint _lotteryId) public {
        lotteryData.draw(_lotteryId, msg.sender);
    }

}


contract LotteryCoreWithRules is LotteryCore {

    struct LotteryRule {
        uint startTime;      
        uint endTime;         
        uint daysStartTime;   
        uint daysEndTime;      
        uint participateCnt;    
        uint perAddressPartCnt; 
    }

    mapping(uint => mapping(address => uint)) public participants;
    mapping(uint => uint) public participateCnts; // 
    mapping(uint => LotteryRule) public lotteryRules;

    constructor(address _owner, address _lotteryDataAddress) LotteryCore(_owner, _lotteryDataAddress) public {}

    /* 
     * 
     */
    function createLottery(
        string _lotteryName,
        uint _startTime,
        uint _endTime,
        uint _daysStartTime,
        uint _daysEndTime,
        uint _participateCnt,
        uint _perAddressPartCnt
    ) public onlyRole("admin") returns(uint) {
        uint _lotteryId = lotteryData.createLottery(_lotteryName);
        LotteryRule memory lotteryRule = LotteryRule(_startTime, _endTime, _daysStartTime, _daysEndTime, _participateCnt, _perAddressPartCnt);
        lotteryRules[_lotteryId] = lotteryRule;
        return _lotteryId;
    }

    /*
     * 
     */
    function userDraw(uint _lotteryId) public {
        // 
        uint status = lotteryData.getLotteryStatus(_lotteryId);
        if (status == 2) {
            revert("lottery is finshed");
        }

        //
        LotteryRule storage lotteryRule = lotteryRules[_lotteryId];
        require(lotteryRule.startTime < now, "lottery is not start");
        if (lotteryRule.endTime < now) {
            lotteryData.closeLottery(_lotteryId, "lottery end time");
            require(lotteryRule.endTime > now, "lottery is finshed");
        }

        // 
        if (lotteryRule.daysStartTime != 0 && lotteryRule.daysEndTime != 0) {
            uint hourNow = now % 1 days / 1 hours + 8; // UTC(+8)
            require(hourNow > lotteryRule.daysStartTime && hourNow < lotteryRule.daysEndTime, "not in lottery time");
        }

        // 
        if (lotteryRule.participateCnt > 0) {
            if (participateCnts[_lotteryId] >= lotteryRule.participateCnt) {
                lotteryData.closeLottery(_lotteryId, "participateCnt exceed the limit");
                require(participateCnts[_lotteryId] <= lotteryRule.participateCnt, "participateCnt exceed the limit");
            }
        }

        // 
        if (lotteryRule.perAddressPartCnt > 0) {
            require(participants[_lotteryId][msg.sender] < lotteryRule.perAddressPartCnt, "perAddressPartCnt exceed the limit");
        }

        //
        if (lotteryData.draw(_lotteryId, msg.sender)) {
            participateCnts[_lotteryId] ++;
            participants[_lotteryId][msg.sender] ++;
        }

    }

}