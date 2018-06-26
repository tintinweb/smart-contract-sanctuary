pragma solidity ^0.4.24;

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

    /**
     * Returns whether there is code in the target address
     * @dev This function will return false if invoked during the constructor of a contract,
     *  as the code is not actually created until after the constructor finishes.
     * @param addr address address to check
     * @return whether there is code in the target address
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract Owned {
    address public owner;
    
    constructor () public { 
        owner = msg.sender; 
    }

    // This contract only defines a modifier but does not use
    // it: it will be used in derived contracts.
    // The function body is inserted where the special symbol
    // `_;` in the definition of a modifier appears.
    // This means that if the owner calls this function, the
    // function is executed and otherwise, an exception is
    // thrown.
    modifier onlyOwner {
        require(
            msg.sender == owner,
            &quot;Only owner can call this function.&quot;
        );
        _;
    }
}

contract LikeLike is Owned {
    using AddressUtils for address;

    // 内容（Token）
    struct Item {
        uint256 value; // 价值：收到的总赞赏金额
        uint256 head;
        uint8 ponzi;
        address[] sponsors;
        mapping (address => uint256) remain;
        mapping (address => uint256) total;
    }

    // 用户
    struct User {
        mapping (uint256 => Item) itemMap; // 该用户关联的所有原创内容（Token）
    }

    mapping (address => User) userMap;

    constructor() public {}

    /**
    * 打赏
    *
    * @param from - 打赏者
    * @param to - 被打赏者
    * @param item_id - 被打赏者的某项内容编号
    * @param message - 打赏附言
    * @param referrer - 推荐者 （TODO：推荐者可能是多个，应该是个array）
    *
    * msg.sender - 代理商（打赏者可以授权给代理商，让代理商发出打赏，每个代理商是应该是一个合约，合约里可以自定义玩法，比如：打赏抽奖，打赏分红等）
    */
    function like(address from, address to, uint256 item_id, string message, address referrer) public payable {
        address sender = msg.sender;

        require(msg.value > 0); // 打赏金额大于0
        require(item_id >= 0);
        require(referrer != from);
        require(referrer != to);
        require(referrer != sender);
        require(!referrer.isContract());
        // TODO: 如果 msg.sender != from(非本人直接打赏), 需要检查msg.sender是否是白名单里的代理商

        User storage user = userMap[to]; // 被打赏者
        Item storage item = user.itemMap[item_id]; // 被打赏的内容

        item.sponsors.push(from);
        item.value += msg.value;

        // 存入尚未兑现的返利
        item.total[from] += msg.value * item.ponzi / 100;
        item.remain[from] += msg.value * item.ponzi / 100;

        uint256 msgValue = msg.value * 97 / 100; // 3% cut off for contract

        while(msgValue > 0) {
            // 除了自己之外，没有站岗的人了，把钱分给被打赏者（to）
            if (item.head + 1 == item.sponsors.length) {
                to.transfer(msgValue);
                // TODO: emit 事件
                break;
            }

            //  把钱分给站岗者们
            address _sponsor = item.sponsors[item.head];
            if (msgValue <= item.remain[_sponsor]) {
                item.remain[_sponsor] -= msgValue;
                _sponsor.transfer(msgValue);
                // TODO: emit 事件
                break;
            } else {
                msgValue -= item.remain[_sponsor];
                _sponsor.transfer(item.remain[_sponsor]);
                // TODO: emit 事件
                item.remain[_sponsor] = 0;
                item.head++;
            }
        }
        // TODO: call 代理商msg.sender，告知打赏结果
    }

    function setPonzi(uint8 _ponzi, uint256 item_id) public  {
        require(_ponzi > 0);
        Item storage item = userMap[msg.sender].itemMap[item_id];
        item.ponzi = _ponzi;
    }
}