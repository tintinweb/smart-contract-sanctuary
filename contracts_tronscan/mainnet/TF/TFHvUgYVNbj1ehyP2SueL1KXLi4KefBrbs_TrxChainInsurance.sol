//SourceUnit: trxchain.insurance.sol

pragma solidity 0.5.12;

interface ITrxChain {
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus);
    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
}

contract TrxChainInsurance {
    ITrxChain public trxchain = ITrxChain(0x55b776da4f19D5d476669B27F94923eF33f63208);

    uint256 public total_rewards;
    uint256 public total_members;

    mapping(address => uint256) public rewards;

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
        total_rewards += amount;

        address(msg.sender).transfer(amount);
    }

    function toPayout(address member) external view returns(uint256 amount) {
        (,, uint256 deposit_amount, uint256 payouts,,,) = trxchain.userInfo(member);
        (, uint256 total_deposits, uint256 total_payouts,) = trxchain.userInfoTotals(member);

        if(deposit_amount > 0 && total_deposits > total_payouts && rewards[member] + payouts < deposit_amount) {
            amount = deposit_amount - payouts - rewards[member];
            uint256 max_amount = total_deposits - total_payouts;

            if(amount > max_amount) amount = max_amount;
            if(amount > address(this).balance) amount = address(this).balance;
        }
    }
}