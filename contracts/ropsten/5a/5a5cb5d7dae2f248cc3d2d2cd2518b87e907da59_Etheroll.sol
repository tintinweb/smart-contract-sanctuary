pragma solidity ^0.4.0;

/**
 * “随机”赌博
 * 用户有 n% 的机会获得不超过 (100/n) * 0.99 倍的下注金额返款
 * 警告！该代码没有经过审计，可能存在严重漏洞，不应用于生产环境。
 * 警告！该代码使用了可预测的随机数发生机制，所产生的随机数是可以提前预测的，攻击者可以构造对自己有利的数据，将奖池中的资金全数盗走。
 */

contract Etheroll {
    address owner = 0x0;
    uint funds;             /// 奖池金额
    
    
    event RollResult(uint256 n, bytes32 gasLeft, bytes32 hashResult, uint rolled, uint currentFunds);
    event RefundAmount(uint refund, uint fundsRemains);
    

    constructor() public payable {
        owner = msg.sender;
        funds = 0x0;
    }


    function playerRollDice(uint256 n) public payable {
        require(n >= 2);
        require(n <= 98);
        require(msg.value > 0x100);
        
        bytes32[2] memory data;
        data[0] = bytes32(block.number);
        data[1] = bytes32(gasleft());
        
        bytes32 hash = sha256(abi.encodePacked(data));
        
        uint rolled = uint(hash) % 100;
        
        uint refund = 0x1;
        
        emit RollResult(n, data[1], hash, rolled, funds);
        
        if (rolled < n) {
            /// 返还 150% 的以太
            /// 下面表达式等价于 (100 / n) * 0.99 * msg.value
            refund = 99 * msg.value / n;
            if (refund <= 0) {
                refund = 0x1;
            }
            
            if (refund > funds + msg.value) {
                refund = funds + msg.value;
            }
            
            require(refund <= 99 * msg.value / n);
        }
        else {
            /// 只返还 1 wei
            refund = 0x1;
        }
        
        /// 计算我们自己的积累下来的基金
        funds = funds + msg.value - refund;
        
        emit RefundAmount(refund, funds);
        
        msg.sender.transfer(refund);
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(funds);
    }
}