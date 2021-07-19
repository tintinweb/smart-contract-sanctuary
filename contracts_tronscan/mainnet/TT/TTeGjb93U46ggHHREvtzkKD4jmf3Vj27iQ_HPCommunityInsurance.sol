//SourceUnit: HPCommunityInsurance.sol

pragma solidity 0.5.8;

interface IHPCommunity {
    function userInfo(address _addr)
        external
        view
        returns (
            address upline,
            uint40 deposit_time,
            uint256 deposit_amount,
            uint256 payouts,
            uint256 pool_bonus,
            uint256 match_bonus
        );

    function userInfoTotals(address _addr)
        external
        view
        returns (
            uint256 referrals,
            uint256 total_deposits,
            uint256 total_payouts
        );
}

interface IHPCommunityInsurance {
    function rewards(address _addr) external view returns (uint256);
}

contract Pausable {
    bool public _paused;

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    constructor() public {
        _paused = false;
    }
}

contract HPCommunityInsurance is Pausable {
    IHPCommunity public hpcommunity =
        IHPCommunity(0x55b776da4f19D5d476669B27F94923eF33f63208);

    address public regulator;
    address payable deployer;

    uint32 public fee = 100; // 100 => 1%

    uint256 public total_rewards;
    uint256 public total_members;

    mapping(address => uint256) public rewards;
    mapping(address => uint40) public last_reward;

    modifier onlyRegulator() {
        require(msg.sender == regulator, "hpcommunityInsurance: ACCESS_DENIED");
        _;
    }

    constructor(address payable owner) public {
        regulator = owner;
        deployer = msg.sender;
    }

    function() external payable {}

    function setChainAddress(address chainAddress) external {
        require(
            msg.sender == regulator || msg.sender == deployer,
            "hpcommunityInsurance: ACCESS_DENIED"
        );

        hpcommunity = IHPCommunity(chainAddress);
    }

    function closeContract() external {
        if (msg.sender == regulator)
            return msg.sender.transfer(address(this).balance);
    }

    function payout() external whenNotPaused {
        require(
            address(this).balance > 0,
            "hpcommunityInsurance: ZERO_BALANCE"
        );
        require(
            address(hpcommunity).balance < 1e8,
            "hpcommunityInsurance: PAYOUT_NOT_OPEN"
        );

        uint256 amount = this.toPayout(msg.sender);

        require(amount > 0, "hpcommunityInsurance: ZERO_AMOUNT");

        if (rewards[msg.sender] == 0) {
            total_members++;
        }

        rewards[msg.sender] += amount;
        last_reward[msg.sender] = uint40(block.timestamp);

        total_rewards += amount;

        address(msg.sender).transfer(amount);
    }

    function setFee(uint32 _fee) external onlyRegulator {
        require(_fee > 0 && _fee <= 10000, "hpcommunityInsurance: BAD_FEE");

        fee = _fee;
    }

    function toPayout(address member) external view returns (uint256 amount) {
        (, , uint256 deposit_amount, , , ) = hpcommunity.userInfo(member);
        (, uint256 total_deposits, uint256 total_payouts) =
            hpcommunity.userInfoTotals(member);

        uint256 days_left =
            last_reward[member] > 0
                ? ((block.timestamp - last_reward[member]) / 1 days)
                : 1;
        // uint256 insurance = oldinsurance.rewards(member);

        if (days_left > 0 && total_deposits > total_payouts + rewards[member]) {
            amount = total_deposits - total_payouts - rewards[member];

            uint256 days_amount = (deposit_amount * fee * days_left) / 100000;

            if (amount < days_amount) amount = days_amount;
            if (amount > address(this).balance) amount = address(this).balance;
        }
    }

    function _pause() external whenNotPaused onlyRegulator {
        _paused = true;
    }

    function _unpause() external whenNotPaused onlyRegulator {
        _paused = false;
    }
}