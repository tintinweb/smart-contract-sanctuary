/**
 *Submitted for verification at FtmScan.com on 2021-12-19
*/

pragma solidity >= 0.8.0;


contract ValidatorFails{
    mapping(address=>mapping(address=>uint256)) public pending_to_claim; //user_address->validator_address->amount_available_to_calim
    uint256 public NumberClaims;
    

    mapping(address=>uint256) public rewards_remaining; //total amount deposited and available
    mapping(address=>uint256) public rewards_assigned; //rewards already assigned to delegators
    mapping(address=>uint256) public rewards_claimed; //rewards already claimed by delegators

    event Claim(address indexed _staker, uint256 _amount);
    event Distributed(address indexed _validator_address, address[] _addresses, uint256[] _amounts);


    
    function deposit_reward() external payable{
        uint256 current_rewards=rewards_remaining[msg.sender];
        rewards_remaining[msg.sender]=current_rewards+msg.value;
    }

    function claim_balance(address validator_address) external{
        uint256 amount_claimable=pending_to_claim[msg.sender][validator_address];
        require(amount_claimable>0, "NO PENDING REWARDS");
        rewards_remaining[validator_address]=rewards_remaining[validator_address]-amount_claimable;
        pending_to_claim[msg.sender][validator_address]=0;
        rewards_assigned[validator_address]=rewards_assigned[validator_address]-amount_claimable;
        rewards_claimed[validator_address]=rewards_claimed[validator_address]+amount_claimable;
        NumberClaims=NumberClaims+1;
        
        payable(msg.sender).transfer(amount_claimable);
        
        emit Claim(msg.sender, amount_claimable);
    }
    
    //anyone who deposited can withdraw at any time the unclaimed balance, this will lead to error from anyone trying to claim after this
    //withdraw if they already had balances assigned
    function withdraw_FTM(uint256 amount) external{
        uint256 max_available=rewards_remaining[msg.sender];
        rewards_remaining[msg.sender]=rewards_remaining[msg.sender]-amount;
        require(amount<=max_available, "NOT ENOUGH BALANCE");
        payable(msg.sender).transfer(amount);
    }

    //it's recommended to call this function to clear the pending rewards of delegators if you already distributed rewards
    function blacklist_addresses(address[] calldata _addresses_to_blacklist) external{
        for (uint256 i; i<_addresses_to_blacklist.length; i++){
            rewards_assigned[msg.sender]=rewards_assigned[msg.sender] - pending_to_claim[_addresses_to_blacklist[i]][msg.sender];
            pending_to_claim[_addresses_to_blacklist[i]][msg.sender]=0;
        }
    }

    function distribute_rewards(address payable[] calldata addreses_to_whitelist, uint256[] calldata amounts) external {
        require(addreses_to_whitelist.length==amounts.length, "NOT SAME LENGTH");
        uint256 num_addresses=amounts.length;
        address[] memory _addresses= new address[](num_addresses);
        uint256 pending_assign=rewards_remaining[msg.sender]-rewards_assigned[msg.sender];
        uint256 total_distributed=0;
        for(uint256 i; i<addreses_to_whitelist.length; i++){
            total_distributed=total_distributed+amounts[i];
            require(pending_assign>=total_distributed, "NOT ENOUGH FUNDS");
            pending_to_claim[addreses_to_whitelist[i]][msg.sender]=pending_to_claim[addreses_to_whitelist[i]][msg.sender]+amounts[i];
            _addresses[i]=addreses_to_whitelist[i];
        }
        rewards_assigned[msg.sender]=rewards_assigned[msg.sender]+total_distributed;
        emit Distributed(msg.sender, _addresses, amounts);
    }
    
}