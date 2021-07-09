/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.8;

library SafeMath {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
    * - Subtraction cannot overflow.
    */
  function sub(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b <= a, "SafeMath: subtraction overflow");
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
    * - Multiplication cannot overflow.
    */
  function mul(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    * - The divisor cannot be zero.
    */
  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    * - The divisor cannot be zero.
    */
  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

contract Aggreator {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct RoundId {
        uint256 roundId;
        uint256 timeStamp;
    }

    // mapping (string => mapping(address => bool)) public pairNode;
    mapping (address => bool) public approveList;
    mapping (address => bool) public nodes;
    mapping (address => uint256) public depoistFeeBalance;
    mapping (address => uint256) public nodeFeedPriceTimes;
    mapping (string => int256[]) public pairPrice;
    mapping (string => RoundId) public roundIds;
    mapping (uint256 => mapping(address => bool)) public roundIdPrice;
    mapping (string => int256) public latestPrice;

    address public immutable teamAddress;
    address public immutable token;
    address public immutable blackHole = 0x000000000000000000000000000000000000dEaD;
    uint256 public decimals = 18;
    uint256 public destroyFee;
    uint256 private totalTimes;
    uint256 private reward;
    uint256 public registerFee = 1000 * 10 ** decimals;
    uint256 public depositFee = 100 * 10 ** decimals;
    uint256 public priceRequestFee = 10 * 10 ** decimals;
    uint256 public priceRequestDestroy = 50;
    uint256 public minResponses;

    event transfer(address from, address to, uint256 value);
    event request(uint256 roundId, bytes pair);
    event priceUpdated(bytes _pair,uint256 _roundId,int256 _price);
    
    constructor(
        address _teamAddress,
        address _token
    )
    {
        teamAddress = _teamAddress;
        token = _token;
    }

    function init(string memory _pair) external {
        require(msg.sender == teamAddress,"no admin");
        roundIds[_pair].roundId = 1;
        roundIds[_pair].timeStamp = block.timestamp;
        emit request(roundIds[_pair].roundId, bytes(_pair));
    }

    function setMinResponses(uint256 _minResponses) public {
        require(msg.sender == teamAddress,"no admin");
        minResponses = _minResponses;
    }

    function setRequest(uint256 _roundId,string memory _pair) public {
        require(msg.sender == teamAddress,"no admin");
        require(_roundId == roundIds[_pair].roundId,"roundId is wrong");
        require(block.timestamp - roundIds[_pair].timeStamp > 180,"roundId invalid");
        safeTransferFrom(token, msg.sender, address(this), priceRequestFee);
        delete pairPrice[_pair];
        uint256 temp = priceRequestFee.mul(priceRequestDestroy).div(100);
        destroyFee += temp;
        reward += priceRequestFee - temp;
        roundIds[_pair].roundId += 1;
        emit request(roundIds[_pair].roundId, bytes(_pair));
    }

    function receiveData(string memory _pair, uint256 _roundId, int256 _price) external {
        require(nodes[msg.sender],"no node");
        require(roundIds[_pair].roundId == _roundId,"roundId is wrong");
        require(block.timestamp - roundIds[_pair].timeStamp < 180,"roundId invalid");
        require(!roundIdPrice[_roundId][msg.sender],"send price multy times");
        pairPrice[_pair].push(_price);
        nodeFeedPriceTimes[msg.sender] += 1;
        totalTimes += 1;
        updatePrice(_pair,pairPrice[_pair],_roundId);
    }

    function updatePrice(string memory _pair, int256[] memory _pairPrice, uint256 _roundId)
        private
        ensureMinResponsesReceived(_pairPrice)
        // ensureLatestResponsesReceived(_priceId)
    {
        uint256 responseLength = _pairPrice.length;
        uint256 middleIndex = responseLength.div(2);
        int256 currentPriceTemp = 1;
        if (responseLength % 2 == 0) {
            int256 median1 = quickselect(
                _pairPrice,
                middleIndex
            );
            int256 median2 = quickselect(
                _pairPrice,
                middleIndex.add(1)
            ); // quickselect is 1 indexed
            currentPriceTemp = median1.add(median2) / 2; // signed integers are not supported by SafeMath
        } else {
            currentPriceTemp = quickselect(
                _pairPrice,
                middleIndex.add(1)
            ); // quickselect is 1 indexed
        }
        latestPrice[_pair] = currentPriceTemp;
        emit priceUpdated(bytes(_pair),_roundId,currentPriceTemp);
    }

//设置保证金
    function setDepoistFee(uint256 _depoistFee) external {
        require(msg.sender == teamAddress,"no admin");
        depositFee = _depoistFee *10**decimals;
    }

//设置注册费用
    function setRegisterFee(uint256 _registerFee) external {
        require(msg.sender == teamAddress,"no admin");
        registerFee = _registerFee *10**decimals;
    }

//设置喂价更新请求时的费用
    function setPriceRequestFee(uint256 _priceRequestFee) external {
        require(msg.sender == teamAddress,"no admin");
        priceRequestFee = _priceRequestFee *10**decimals;
    }

//设置喂价更新请求时销毁的比例，50%为50，
    function setPriceRequestDestroy(uint256 _priceRequestDestroy) external {
        require(msg.sender == teamAddress,"no admin");
        priceRequestDestroy = _priceRequestDestroy *10**decimals;
    }

//追加保证金
    function addDepoistFee(uint256 _depoistFee) external {
        require(nodes[msg.sender],"no node");
        safeTransferFrom(token, msg.sender, address(this), _depoistFee);
        depoistFeeBalance[msg.sender] += _depoistFee;
    }

//添加节点注册白名单
    function addApproveList (address _nodeAddress) external {
        require(msg.sender == teamAddress,"no admin");
        approveList[_nodeAddress] = true;
    }

//将节点移除注册白名单
    function removeApproveList(address _nodeAddress) external{
        require(msg.sender == teamAddress, "no admin");
        approveList[_nodeAddress] = false;
    }

// //注册节点
//     function registered(string memory pairName) external {
//         require(approveList[msg.sender],"no permission");
//         pairNode[pairName][msg.sender] = true;
//     }

//注册节点，与上面方法二选一，待定
    function registered() external {
        require(approveList[msg.sender],"no permission");
        safeTransferFrom(token, msg.sender, blackHole, registerFee);
        safeTransferFrom(token, msg.sender, address(this), depositFee);
        nodes[msg.sender] = true;
        depoistFeeBalance[msg.sender] = depositFee;
    }

    function unregistered() external {
        require(nodes[msg.sender],"no permission");
        nodes[msg.sender] = false;
        approveList[msg.sender] = false;
    }

//吊销节点后，是否需要将它从已批准列表中删除
    function revoke(address _nodeAddress) external {
        if(!approveList[_nodeAddress]) {
            nodes[_nodeAddress] = false;
        }
        if(depoistFeeBalance[_nodeAddress]>depositFee.mul(5).div(10)){
            nodes[_nodeAddress] = false;
            approveList[_nodeAddress] = false;
        }
    }

//赎回担保金
    function withdraw() external {
        require(nodes[msg.sender] == false,"node is registered");
        require(depoistFeeBalance[msg.sender] != 0, "depoist is Empty");
        safeTransfer(token, msg.sender, depoistFeeBalance[msg.sender]);
    }

    function claim() external {
        require(nodes[msg.sender],"no permission");
        uint256 temp = reward.mul(nodeFeedPriceTimes[msg.sender]).div(totalTimes);
        safeTransfer(token, msg.sender, temp);
        reward -= temp;
        totalTimes -= nodeFeedPriceTimes[msg.sender];
        nodeFeedPriceTimes[msg.sender] = 0;
    }

    function quickselect(int256[] memory _a, uint256 _k)
        private
        pure
        returns (int256)
    {
        int256[] memory a = _a;
        uint256 k = _k;
        uint256 aLen = a.length;
        int256[] memory a1 = new int256[](aLen);
        int256[] memory a2 = new int256[](aLen);
        uint256 a1Len;
        uint256 a2Len;
        int256 pivot;
        uint256 i;

        while (true) {
            pivot = a[aLen.div(2)];
            a1Len = 0;
            a2Len = 0;
            for (i = 0; i < aLen; i++) {
                if (a[i] < pivot) {
                    a1[a1Len] = a[i];
                    a1Len++;
                } else if (a[i] > pivot) {
                    a2[a2Len] = a[i];
                    a2Len++;
                }
            }
            if (k <= a1Len) {
                aLen = a1Len;
                (a, a1) = swap(a, a1);
            } else if (k > (aLen.sub(a2Len))) {
                k = k.sub(aLen.sub(a2Len));
                aLen = a2Len;
                (a, a2) = swap(a, a2);
            } else {
                return pivot;
            }
        }
    }

    function swap(int256[] memory _a, int256[] memory _b)
        private
        pure
        returns (int256[] memory, int256[] memory)
    {
        return (_b, _a);
    }

//转账操作，必须让msg.sender先approve
    function safeTransfer(
        address _token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
        emit transfer(address(this), to, value);
    }

    function safeTransferFrom(
        address _token,
        address from,
        address to,
        uint256 value
    ) public {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
        emit transfer(from, to, value);
    }

    modifier ensureMinResponsesReceived(int256[] memory _pairPrice) {
        if (_pairPrice.length >= minResponses) {
            _;
        }
    }

}