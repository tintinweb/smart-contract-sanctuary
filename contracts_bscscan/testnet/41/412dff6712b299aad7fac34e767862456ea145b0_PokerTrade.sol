/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

library Bep20TransferHelper {


    function safeApprove(address token, address to, uint256 value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint256 value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    
    function power(uint256 a, uint256 b) internal pure returns (uint256){

        if(a == 0) return 0;
        if(b == 0) return 1;
        
        uint256 c = a ** b;
        require(c > 0, "SafeMathForUint256: modulo by zero");
        return c;
    }
}




contract PokerTrade {
    
    uint256 constant STATUS_AVAIL = 1;
    uint256 constant STATUS_SOLD = 2;
    uint256 constant STATUS_CANCEL = 3;
    
    address private HER_CONTRACT_ADDRESS;// 卡牌交易使用HER
    
    address private SERVICEE_ADDRESS;// 卡牌交易3%手续费收款地址
    
    mapping(uint256 => PublishModel) private pokerMap;// 卡牌id - 状态
    
    mapping(uint256 => address) private buyerMap;// 卡牌id - 买家
    
    mapping(uint256 => address) private pokerAddress;
    
    mapping(uint256 => bool) private opratingMap;
    
    address private owner;// 发行此合约地址
    
    struct PublishModel {
        uint256 price;// 发布价格
        uint256 status;// 状态
        address seller;// 卖方
        address buyer;// 买方
    }
    
    modifier onlyOperator(uint256 id) {
        require(opratingMap[id] == false, "poker is operating");
        opratingMap[id] = true;
        _;
        opratingMap[id] = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only publisher can operate");
        _;
    }
    
    constructor(address herContractAddress) {
        HER_CONTRACT_ADDRESS = herContractAddress;
        owner = msg.sender;
    }
    
    function setServiceAddress(address serviceAddress) public onlyOwner {
        SERVICEE_ADDRESS = serviceAddress;
    }
    
    function publish(uint256 id, uint256 p) public onlyOperator(id) {
        require(pokerMap[id].status == 0 || pokerMap[id].status == STATUS_CANCEL || pokerMap[id].status == STATUS_SOLD, "poker can not publish");
        pokerMap[id] = PublishModel({
            price: p,
            status: STATUS_AVAIL,
            seller: msg.sender,
            buyer: address(0)
        });
    }
    
    function cancel(uint256 id) public onlyOperator(id) {
        require(pokerMap[id].status == STATUS_AVAIL, "poker is not avail");
        pokerMap[id].status = STATUS_CANCEL;
    }
    
    function trade(uint256 id) public onlyOperator(id) {
        require(pokerMap[id].status == STATUS_AVAIL, "poker is not avail");
        
        uint256 p = SafeMath.mul(pokerMap[id].price, 3);
        uint256 service = SafeMath.div(p, 100);
        
        require(Bep20TransferHelper.safeTransferFrom(HER_CONTRACT_ADDRESS, msg.sender, SERVICEE_ADDRESS, service), "asset insufficient1");
        require(Bep20TransferHelper.safeTransferFrom(HER_CONTRACT_ADDRESS, msg.sender, pokerMap[id].seller, SafeMath.sub(pokerMap[id].price, service)), "asset insufficient2");

        pokerMap[id].status = STATUS_SOLD;
        pokerMap[id].buyer = msg.sender;
    }
    
    // 后台改卡牌状态
    function admin(uint256 id, uint256 status, address buyer) public onlyOperator(id) onlyOwner {
        pokerMap[id].status = status;
        pokerMap[id].buyer = buyer;
    }
    
    // 批量状态查询
    function getStatus(address[] memory ids) public view returns (address[] memory) {
        uint256 length = ids.length;
        uint256 d = SafeMath.div(length, 2);
        for (uint256 i = 0; i < d; i++) {
            uint160 pokerId = uint160(ids[SafeMath.mul(i, 2)]);
            uint256 pid = uint256(pokerId);
            ids[SafeMath.mul(i, 2)] = address(uint160(pokerMap[pid].status));
            ids[SafeMath.add(SafeMath.mul(i, 2), 1)] = pokerMap[pid].buyer;
        }
        return ids;
    }
    
}