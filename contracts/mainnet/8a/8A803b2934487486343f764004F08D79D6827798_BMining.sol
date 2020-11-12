// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.5.1;
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

interface IBSpare {
    function requestSpare(uint amount) external;
}

interface IERC20 {
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

contract BMining {
    using SafeMath for uint;
    
    uint public constant CONTRACT_DURATION = 6500 * 365;
    uint public constant INCOME_NUMERATOR  = 136;
    uint public constant INCOME_DENOMINATOR  = 100;
    
    uint public startBlock;
    uint public endBlock;
    address public BETH;
    address public owner;
    address public admin;
    address public BSpare;

    struct Data {
        uint stakes;
        uint lastAuditBlock;
        uint rewards;
        bool used;
    }
    
    mapping (address => Data) users;
    Data public global;
    uint public sparedReward;
    uint public mintedReward;
    uint public totalIncome;
    uint public userCount;
    
    receive() external payable {
        if(msg.sender != BSpare) {
            totalIncome += msg.value;
        }
    }
    
    constructor(address _BETH) public {
        BETH = _BETH;
        owner = msg.sender;
        admin = msg.sender;
    }
    
    function setupAdmin(address _admin) public {
        require(msg.sender == owner, "REQUIRE OWNER");
        admin = _admin;
    }
    
    function setupSpare(address _spare) public {
        require(msg.sender == owner, "REQUIRE OWNER");
        BSpare = _spare;
    }
    
    function turnOn() public returns (bool) {
        require(BSpare != address(0), "SETUP Spare FIRST");
        require(msg.sender == admin, "REQUIRE ADMIN");
        require(startBlock == 0, "ALREADY TURN ON");
        startBlock = block.number;
        endBlock = startBlock.add(CONTRACT_DURATION);
        
        return true;
    }
    
    function isOn() view public returns (bool) {
        return endBlock > 0;
    }
    
    function stake(uint amount) external {
        require(endBlock == 0 || block.number < endBlock, "ALREADY END");
        Data storage data = users[msg.sender];
        _audit(msg.sender);
        TransferHelper.safeTransferFrom(BETH, msg.sender, address(this), amount);
        data.stakes = data.stakes.add(amount);
        global.stakes = global.stakes.add(amount);
        if(!data.used) {
            userCount = userCount.add(1);
            data.used = true;
        }
    }
    
    function withdraw(uint amount) external {
        require(users[msg.sender].stakes >= amount, "INSUFFCIENT WITHDRAW AMOUNT");
        _audit(msg.sender);
        
        TransferHelper.safeTransfer(BETH, msg.sender, amount);
        users[msg.sender].stakes = users[msg.sender].stakes.sub(amount);
        global.stakes = global.stakes.sub(amount);
    }
    
    function mintReward() public returns(uint) {
        _audit(msg.sender);
        return _transferReward();
    }
    
    function queryStakeInfo() public view returns(uint stakeAmount, uint lastAuditBlock, uint rewards, uint blockNumber) {
        Data memory data = users[msg.sender];
        stakeAmount = data.stakes;
        lastAuditBlock = data.lastAuditBlock;
        rewards = data.rewards.add(_getReward(data));
        blockNumber = block.number;
    }
    
    function queryGlobalInfo() public view returns (uint, uint, uint, uint, uint, uint) {
        return (totalIncome, global.rewards.add(_getReward(global)), global.stakes, userCount, endBlock, INCOME_NUMERATOR);
    }
    
    function queryAmountToExtract() view public returns (uint){
        uint globalReward = _getReward(global) + global.rewards;
        require(globalReward >= mintedReward, "UNKNOWN ERROR");
        if(address(this).balance > sparedReward.add(globalReward).sub(mintedReward)) {
            return address(this).balance.sub(sparedReward.add(globalReward).sub(mintedReward));
        }
        
        return 0;
    }
    
    function extractToSpare() public {
        require(msg.sender == admin, "REQUIRE ADMIN");
        uint amount = queryAmountToExtract();
        if(amount > 0) {
            TransferHelper.safeTransferETH(BSpare, amount);
            sparedReward = 0;
        }
    }
    
    // private method
    function _audit(address user) private {
        Data storage data = users[user];
        data.rewards = data.rewards.add(_getReward(data));
        data.lastAuditBlock = Math.min(block.number, endBlock);
        
        _auditGlobal();
    }
    
    function _auditGlobal() private {
        global.rewards = global.rewards.add(_getReward(global));
        global.lastAuditBlock = Math.min(block.number, endBlock);
    }
    
    function _transferReward() private returns(uint rewards){
        Data storage data = users[msg.sender];
        require(data.rewards > 0, "INSUFFCIENT STAKE REWARDS");
        if(address(this).balance < data.rewards) {
            sparedReward = sparedReward.add(data.rewards.sub(address(this).balance));
            IBSpare(BSpare).requestSpare(data.rewards.sub(address(this).balance));
        }
        
        mintedReward = mintedReward.add(data.rewards);
        require(address(this).balance >= data.rewards, "NOT ENOUGH BALANCE NOW");
        
        TransferHelper.safeTransferETH(msg.sender, data.rewards);
        rewards = data.rewards;
        data.rewards = 0;
    }
    
    function _getReward (Data memory data) private view returns(uint reward) {
        if(!isOn()) {
            return 0;
        } 
        uint auditBlock = Math.min(block.number, endBlock);
        uint stakeDuration = data.lastAuditBlock > startBlock ? auditBlock.sub(data.lastAuditBlock) : auditBlock.sub(startBlock);
        reward = data.stakes.mul(stakeDuration).mul(INCOME_NUMERATOR) / INCOME_DENOMINATOR / CONTRACT_DURATION;
    }
}