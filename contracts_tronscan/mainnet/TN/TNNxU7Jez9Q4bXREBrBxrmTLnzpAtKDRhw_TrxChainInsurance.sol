//SourceUnit: insurance20.sol

pragma solidity 0.5.12;

interface ITrxChain {
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus);
    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
}

interface ITrxChainInsurance {
    function rewards(address _addr) view external returns(uint256);
}

contract TrxChainInsurance {
    ITrxChainInsurance public oldinsurance = ITrxChainInsurance(0xECc05e03f5042B8b36EaA1dBac11F875B455C678);
    ITrxChain public trxchain = ITrxChain(0x55b776da4f19D5d476669B27F94923eF33f63208);

    address public regulator;

    uint32 public fee = 100; // 100 => 1%

    uint256 public total_rewards;
    uint256 public total_members;

    mapping(address => uint256) public rewards;
    mapping(address => uint40) public last_reward;

    modifier onlyRegulator() {
        require(msg.sender == regulator, "TrxChainInsurance: ACCESS_DENIED");
        _;
    }

    constructor() public {
        regulator = msg.sender;
    }

    function() payable external {}

    function payout() external {
        require(address(this).balance > 0, "TrxChainInsurance: ZERO_BALANCE");
        require(address(trxchain).balance < 1e8, "TrxChainInsurance: PAYOUT_NOT_OPEN");

        uint256 amount = this.toPayout(msg.sender);

        require(amount > 0, "TrxChainInsurance: ZERO_AMOUNT");

        if(rewards[msg.sender] == 0) {
            total_members++;
        }

        rewards[msg.sender] += amount;
        last_reward[msg.sender] = uint40(block.timestamp);

        total_rewards += amount;

        address(msg.sender).transfer(amount);
    }

    function setFee(uint32 _fee) external onlyRegulator {
        require(_fee > 0 && _fee <= 10000, "TrxChainInsurance: BAD_FEE");

        fee = _fee;
    }

    function toPayout(address member) external view returns(uint256 amount) {
        (,, uint256 deposit_amount,,,,) = trxchain.userInfo(member);
        (, uint256 total_deposits, uint256 total_payouts,) = trxchain.userInfoTotals(member);
            
        uint256 days_left = last_reward[member] > 0 ? ((block.timestamp - last_reward[member]) / 1 days) : 1;
        uint256 insurance = oldinsurance.rewards(member);

        if(days_left > 0 && total_deposits > total_payouts + rewards[member] + insurance) {
            amount = total_deposits - total_payouts - rewards[member] - insurance;
            
            uint256 days_amount = deposit_amount * fee * days_left / 10000;

            if(amount > days_amount) amount = days_amount;
            if(amount > address(this).balance) amount = address(this).balance;
        }
    }
}