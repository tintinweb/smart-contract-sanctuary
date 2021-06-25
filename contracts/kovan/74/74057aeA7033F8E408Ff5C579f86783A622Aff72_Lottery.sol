pragma solidity >0.6.0;

import './Owned.sol';
import './interfaces/IERC20.sol';
import './interfaces/IPrice.sol';
import './interfaces/IRandom.sol';

import './libraries/SafeMath.sol';

contract Lottery is Owned {
    using SafeMath for uint256;
    
    enum Status {
        Open,
        Expired,
        Closed,
        Completed
    }
    
    uint256 private oneRatio = 1e6;
    
    struct PoolInfo {
        address priceServiceAddress; //Address of chain link price
        
        string description;
        
        uint256 priceDecimals;
        uint256 startPrice;
        uint256 endPrice;
        
        uint256 startTime;
        uint256 endTime;
        
        Status status;
        
        uint256 lotteryRatio; // *1e6
        uint256 feeRatio;  // *1e6
        
        bytes32 lotteryWinningRequestId;
        uint256 lotteryWinningNumber;
        
        address creator;
    }
    
    struct PoolSpecification {
        uint256 redTicketPrice;
        uint256 blueTicketPrice;
        uint256 gained;
        
        uint256 redPool;
        uint256 bluePool;
        
        uint256 redCurrentReward;
        uint256 blueCurrentReward;
        
        uint256 redTicketNumber;
        uint256 blueTicketNumber;
    }
    
    struct Ticket {
        uint256 pid;
        uint256 index_by_label;
        address owner;
        bool lable; //RED=0 or BULE=1
        uint256 price;
        bool close;
    }
    
    mapping(uint256 => PoolInfo) public poolInfos;
    mapping(uint256 => PoolSpecification) public poolSpecifications;
    uint256 public poolLength;
    
    mapping(uint256 => Ticket[]) public tickets;
    IERC20 public token;
    IPrice public priceService;
    IRandom public randomService;
    
    event NewTicket(uint256 indexed _pid, address indexed _buyer, bool indexed _lable, uint256 _price);
    event RequestRandomLottery(uint256 indexed _pid, bytes32 _requestId);
    event Reward(uint256 indexed _pid, uint256 indexed _tid, address indexed _owner, address _to, uint256 _value);
    event LotteryReward(uint256 indexed _pid, uint256 indexed _tid, address indexed _owner, address _to, uint256 _value);
    
    modifier notExpired(uint256 _pid) {
        require(poolInfos[_pid].endTime >= block.timestamp, "LOTTERY: Pool is expired");
        _;
    }
    
    modifier expired(uint256 _pid) {
        require(poolInfos[_pid].endTime < block.timestamp, "LOTTERY: Pool is not expired");
        _;
    }
    
    modifier poolExisted(uint256 _pid) {
        require(_pid < poolLength, "LOTTERY: Pool not existed");
        _;
    }
    
    modifier onlyRandomService() {
        require(
            msg.sender == address(randomService),
            "LOTTERY: Only called by Random Service"
        );
        _;
    }
    
    constructor(address _token) public {
        token = IERC20(_token);
        poolLength = 0;
    }
    
    function setRandomService(address _random) public onlyOwner {
        randomService = IRandom(_random);
    }
    
    function setPriceService(address _price) public onlyOwner {
        priceService = IPrice(_price);
    }
    
    function createPool(
        address _priceServiceAddress,
        uint256 _deadline,
        uint256 _tiketPrice,
        uint256 _gained,
        uint256 _lotteryRatio,
        uint256 _feeRatio,
        uint8 _initTicketNumber
    ) public onlyOwner {
        require(_deadline > block.timestamp, "LOTTERY: Deadline too low");
        require(_initTicketNumber > 0, "LOTTERY: Requires initialization of at least 1 pair of tickets");
        require(_gained > 0, "LOTTERY: Requires gained > 0");
        
        (int price, uint8 decimals ,uint startedAt, ,string memory description) = priceService.getLastPrice(_priceServiceAddress);
        PoolInfo memory newPool = PoolInfo(_priceServiceAddress, description, decimals, uint256(price), 0, startedAt, _deadline, Status.Open, _lotteryRatio, _feeRatio, bytes32(""), 0, msg.sender);
        PoolSpecification memory newSpecification = PoolSpecification(_tiketPrice, _tiketPrice, _gained, 0, 0, 0, 0, 0, 0);
        poolInfos[poolLength] = newPool;
        poolSpecifications[poolLength] = newSpecification;
        poolLength++;
        
        for (uint8 i = 0; i < _initTicketNumber; i++) {
            buyTicket(poolLength - 1, true);
            buyTicket(poolLength - 1, false);
        }
    }
    
    function numbersDrawn(uint256 _pid, bytes32 _requestId, uint256 _randomNumber) external onlyRandomService() {
        require(
            poolInfos[_pid].status == Status.Closed,
            "LOTTERY: Required close pool first"
        );
        if(poolInfos[_pid].lotteryWinningRequestId == _requestId) {
            poolInfos[_pid].status = Status.Completed;
            poolInfos[_pid].lotteryWinningNumber = _split(_randomNumber, _pid);
        }

    }
    
    function closePool(uint256 _pid) external onlyOwner expired(_pid) {
        require(poolInfos[_pid].status == Status.Open, "LOTTERY: Pool status incorrect");
        (int price, uint8 decimals ,uint startedAt, ,) = priceService.getLastPrice(poolInfos[_pid].priceServiceAddress);
        poolInfos[_pid].endPrice = uint256(price);
        poolInfos[_pid].status = Status.Closed;
        poolInfos[_pid].lotteryWinningRequestId = randomService.getRandomNumber(_pid);
        _burnFee(_pid);
        emit RequestRandomLottery(_pid, poolInfos[_pid].lotteryWinningRequestId);
    }
    
    function buyTicket(uint256 _pid, bool _lable) public poolExisted(_pid) notExpired(_pid) {
        PoolInfo storage poolInfo = poolInfos[_pid];
        PoolSpecification storage specification = poolSpecifications[_pid];
        uint256 price = 0;
        
        if (specification.bluePool == 0 && _lable == true) {
            price = specification.blueTicketPrice;
            specification.bluePool = price;
            specification.blueTicketNumber++;
        } else if (specification.redPool == 0 && _lable == false) {
            price = specification.redTicketPrice;
            specification.redPool = price;
            specification.redTicketNumber++;
        } else {
            uint256 previousBluePool = specification.bluePool;
            uint256 previousRedPool = specification.redPool;
            uint256 avg = (previousBluePool.add(previousRedPool)).div(specification.blueTicketNumber.add(specification.redTicketNumber));
            uint256 bluePool = avg.mul(specification.blueTicketNumber);
            uint256 redPool = avg.mul(specification.redTicketNumber);
            
            uint256 newBluePool = 0;
            uint256 newRedPool = 0;
             if (_lable) {
                newBluePool = (bluePool.div(specification.blueTicketNumber).add(specification.gained)).mul(specification.blueTicketNumber.add(1));
                newRedPool = redPool;
                specification.blueTicketNumber++;
                price = newBluePool - bluePool;
                specification.blueTicketPrice = price;
            } else {
                newBluePool = bluePool;
                newRedPool = (redPool.div(specification.redTicketNumber).add(specification.gained)).mul(specification.redTicketNumber.add(1));
                specification.redTicketNumber++;
                price = newRedPool - redPool;
                specification.redTicketPrice = price;
            }
            specification.bluePool = newBluePool;
            specification.redPool = newRedPool;
        }
        token.transferFrom(msg.sender, address(this), price);
        if (specification.blueTicketNumber > 0) {
            specification.blueCurrentReward = 
                (specification.bluePool.add(specification.redPool))
                .mul(oneRatio.sub(poolInfo.lotteryRatio).sub(poolInfo.feeRatio)).div(oneRatio)
                .div(specification.blueTicketNumber);   
        }
        if (specification.redTicketNumber > 0) {
            specification.redCurrentReward = 
                (specification.bluePool.add(specification.redPool))
                .mul(oneRatio.sub(poolInfo.lotteryRatio).sub(poolInfo.feeRatio)).div(oneRatio)
                .div(specification.redTicketNumber);   
        }
        uint256 index = (_lable ? specification.blueTicketNumber : specification.redTicketNumber) - 1;
        Ticket memory ticket = Ticket(_pid,index ,msg.sender,_lable, price, false);
        tickets[_pid].push(ticket);
        emit NewTicket(_pid, msg.sender, _lable, price);
    }
    
    function getNextTicketPrice(uint256 _pid, bool _lable) public view poolExisted(_pid) notExpired(_pid) returns(uint256) {
        PoolSpecification memory specification = poolSpecifications[_pid];
        uint256 price = 0;
        
        if (specification.bluePool == 0 && _lable == true) {
            price = specification.blueTicketPrice;
        } else if (specification.redPool == 0 && _lable == false) {
            price = specification.redTicketPrice;
        } else {
            uint256 previousBluePool = specification.bluePool;
            uint256 previousRedPool = specification.redPool;
            uint256 avg = (previousBluePool.add(previousRedPool)).div(specification.blueTicketNumber.add(specification.redTicketNumber));
            uint256 bluePool = avg.mul(specification.blueTicketNumber);
            uint256 redPool = avg.mul(specification.redTicketNumber);
            
            uint256 newBluePool = 0;
            uint256 newRedPool = 0;
             if (_lable) {
                newBluePool = (bluePool.div(specification.blueTicketNumber).add(specification.gained)).mul(specification.blueTicketNumber.add(1));
                newRedPool = redPool;
                price = newBluePool - bluePool;
            } else {
                newBluePool = bluePool;
                newRedPool = (redPool.div(specification.redTicketNumber).add(specification.gained)).mul(specification.redTicketNumber.add(1));
                price = newRedPool - redPool;
            }
        }
        return price;
    }
    
    function getNextReward(uint256 _pid, bool _lable) public view poolExisted(_pid) notExpired(_pid) returns(uint256 _blueReward, uint256 _redReward) {
        PoolInfo memory poolInfo = poolInfos[_pid];
        PoolSpecification memory specification = poolSpecifications[_pid];
        
        if (specification.bluePool == 0 && _lable == true) {
            specification.bluePool = specification.blueTicketPrice;
        } else if (specification.redPool == 0 && _lable == false) {
            specification.redPool = specification.redTicketPrice;
        } else {
            uint256 previousBluePool = specification.bluePool;
            uint256 previousRedPool = specification.redPool;
            uint256 avg = (previousBluePool.add(previousRedPool)).div(specification.blueTicketNumber.add(specification.redTicketNumber));
            uint256 bluePool = avg.mul(specification.blueTicketNumber);
            uint256 redPool = avg.mul(specification.redTicketNumber);
            
            uint256 newBluePool = 0;
            uint256 newRedPool = 0;
             if (_lable) {
                newBluePool = (bluePool.div(specification.blueTicketNumber).add(specification.gained)).mul(specification.blueTicketNumber.add(1));
                newRedPool = redPool;
            } else {
                newBluePool = bluePool;
                newRedPool = (redPool.div(specification.redTicketNumber).add(specification.gained)).mul(specification.redTicketNumber.add(1));
            }
            specification.bluePool = newBluePool;
            specification.redPool = newRedPool;
        }
        if (specification.blueTicketNumber > 0) {
            specification.blueCurrentReward = 
                (specification.bluePool.add(specification.redPool))
                .mul(oneRatio.sub(poolInfo.lotteryRatio).sub(poolInfo.feeRatio)).div(oneRatio)
                .div(specification.blueTicketNumber);   
        }
        if (specification.redTicketNumber > 0) {
            specification.redCurrentReward = 
                (specification.bluePool.add(specification.redPool))
                .mul(oneRatio.sub(poolInfo.lotteryRatio).sub(poolInfo.feeRatio)).div(oneRatio)
                .div(specification.redTicketNumber);   
        }
        return (specification.blueCurrentReward, specification.redCurrentReward);
    }
    
    function clamReward(uint256 _pid, uint256[] memory _tids, address _to) public poolExisted(_pid) expired(_pid) {
        require(_to != address(0), "LOTTERY: Receiver must be different address 0x0");
        PoolInfo memory poolInfo = poolInfos[_pid];
        Ticket[] storage lotteryTickets = tickets[_pid];
        require(poolInfo.status == Status.Completed, "LOTTERY: Pool is not completed yet");
        
        PoolSpecification memory specification = poolSpecifications[_pid];
        
        bool result = poolInfo.startPrice < poolInfo.endPrice;
        uint256 value = result ? specification.blueCurrentReward : specification.redCurrentReward;
        
        for (uint256 i = 0; i < _tids.length; i++) {
            require(lotteryTickets[_tids[i]].owner == msg.sender, "LOTTERY: Only ticket owner can clam reward");
            require(lotteryTickets[_tids[i]].lable == result, "LOTTERY: List ticket contain lost ticket");
            require(lotteryTickets[_tids[i]].close == false, "LOTTERY: List ticket contain closed ticket");
            token.transfer(_to, value);
            emit Reward(_pid, _tids[i], msg.sender, _to, value);
            if (lotteryTickets[_tids[i]].index_by_label == poolInfo.lotteryWinningNumber) {
                uint256 lotteryReward = (specification.bluePool.add(specification.redPool)).mul(poolInfo.lotteryRatio).div(oneRatio);
                token.transfer(_to, lotteryReward);
                emit LotteryReward(_pid, _tids[i], msg.sender, _to, lotteryReward);
            }
            lotteryTickets[_tids[i]].close = true;
        }
    }
    
    function _split(uint256 _randomNumber, uint256 _pid) internal view returns(uint16) {
        PoolInfo memory poolInfo = poolInfos[_pid];
        PoolSpecification memory specification = poolSpecifications[_pid];
        // Encodes the random number with its position in loop
        bytes32 hashOfRandom = keccak256(abi.encodePacked(_randomNumber, _pid));
        // Casts random number hash into uint256
        uint256 numberRepresentation = uint256(hashOfRandom);
        
        bool result = poolInfo.endPrice > poolInfo.startPrice;
        // Calculation range
        uint256 range = result ? specification.blueTicketNumber : specification.redTicketNumber;
        uint256 position = numberRepresentation % range;
        return uint16(position);
    }
    
    function _burnFee(uint256 _pid) internal {
        PoolInfo memory poolInfo = poolInfos[_pid];
        PoolSpecification memory specification = poolSpecifications[_pid];
        uint256 fee = (specification.bluePool.add(specification.redPool)).mul(poolInfo.feeRatio).div(oneRatio);
        IERC20(token).burn(fee);
    }
}

pragma solidity >0.6.0;

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only available for owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function burn(uint256 amount) external returns(bool success);

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

// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

interface IPrice {
     function getLastPrice(address _address) external view returns (int _price, uint8 _decimals ,uint _startedAt, uint _timeStamp, string memory _description);
}

//SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

interface IRandom {

    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(
        uint256 lotteryId
    ) 
        external 
        returns (bytes32 requestId);
}

pragma solidity >0.6.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}