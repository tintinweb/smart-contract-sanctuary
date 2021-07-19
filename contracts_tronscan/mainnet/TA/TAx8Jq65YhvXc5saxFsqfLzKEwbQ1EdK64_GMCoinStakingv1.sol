//SourceUnit: GMCoinStaking_v1.sol

pragma solidity >=0.5.4 <0.6.0;

contract GMCoinStakingv1 { 

    event Deposit(address indexed dst, uint256 sadd);
    event Withdrawal(address indexed src, uint256 sadw);
    event GetRewards(address indexed srcgr, uint256 sadwgr);

    uint256 internal totalSupply_;
    uint256 internal rewardFactor_ = 1902;

    mapping(address => uint256) internal balanceOf_;
    mapping(address => uint256) internal startTimeOf_;
    mapping(address => uint256) internal rewardsOf_;

    mapping(address => uint256) internal claimOf_;
    mapping(address => uint256) internal claimTimeOf_;

    function() external payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.tokenid == 1002357, "Only GMC Token allowed to transact ");
        rewards(msg.sender);
        balanceOf_[msg.sender] += msg.tokenvalue;   
        totalSupply_ += msg.tokenvalue;
        emit Deposit(msg.sender, msg.tokenvalue);
    }

    function withdraw(uint256 trnsmnt) public payable {
        require(
            balanceOf_[msg.sender] >= trnsmnt,
            "Balance must greater requested amount"
        );
        rewards(msg.sender);
        balanceOf_[msg.sender] -= trnsmnt;
        totalSupply_ -= trnsmnt;
        claimOf_[msg.sender] = trnsmnt;
        claimTimeOf_[msg.sender] = block.timestamp;
        emit Withdrawal(msg.sender, trnsmnt);
    }

    function claim() public payable {
        require(claimOf_[msg.sender] > 0, "No funds to claim");
        require(
            block.timestamp > claimTimeOf_[msg.sender] + 96 hours ,
            "Please wait till the holding period ends."
        );
        msg.sender.transferToken(claimOf_[msg.sender], 1002357);
        claimOf_[msg.sender] = 0 ;
    }

    function checkClaim() public view returns (uint256) {
        return claimOf_[msg.sender];
    } 

    function checkTimeOf() public view returns (uint256){
        return claimTimeOf_[msg.sender] ; 
    }

    function rewards(address _address) internal {
        rewardsOf_[_address] =
            rewardsOf_[_address] +
            (((block.timestamp - startTimeOf_[_address]) *
                ((rewardFactor_) * balanceOf_[_address])) / 1000000000000);
        startTimeOf_[_address] = block.timestamp;
    }

    function rewardscheck(address _address) public view returns (uint256) {
        return
            rewardsOf_[_address] +
            (((block.timestamp - startTimeOf_[_address]) *
                ((rewardFactor_) * balanceOf_[_address])) / 1000000000000);
    }

    function getRewards() public payable {
        rewards(msg.sender);
        require(rewardsOf_[msg.sender] > 0, "rewards must gt 0");
        msg.sender.transferToken(rewardsOf_[msg.sender], 1002357);
        emit GetRewards(msg.sender, rewardsOf_[msg.sender]);
        rewardsOf_[msg.sender] = 0;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address guy) public view returns (uint256) {
        return balanceOf_[guy];
    }
}