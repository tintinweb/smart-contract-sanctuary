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
        require(address(trxchain).balance < 1e9, "TrxChainInsurance: PAYOUT_NOT_OPEN");

        (,, uint256 deposit_amount, uint256 payouts,,,) = trxchain.userInfo(msg.sender);
        (, uint256 total_deposits, uint256 total_payouts,) = trxchain.userInfoTotals(msg.sender);

        require(deposit_amount > 0, "TrxChainInsurance: ZERO_AMOUNT");
        require(total_deposits > total_payouts, "TrxChainInsurance: NOTHING_TO_PAYOUT");
        require(rewards[msg.sender] + payouts < deposit_amount, "TrxChainInsurance: NOTHING_TO_PAYOUT");
        
        uint256 amount = deposit_amount - payouts - rewards[msg.sender];
        uint256 max_amount = total_deposits - total_payouts;

        if(amount > max_amount) {
            amount = max_amount;
        }

        if(amount > address(this).balance) {
            amount = address(this).balance;
        }

        if(rewards[msg.sender] == 0) {
            total_members++;
        }

        rewards[msg.sender] += amount;
        total_rewards += amount;

        address(msg.sender).transfer(amount);
    }

}