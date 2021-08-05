/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}




library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}






contract ERC20 is IERC20, Context{
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 5;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract ATAToken is ERC20, Ownable {
   using SafeMath for uint256;

    enum VestingCategory {
        EARLY_CONTRIBUTORS,
        NETWORK_FEES,
        PROTOCOL_RESERVE,
        PARTNER_ADVISORS,
        TEAM,
        ECOSYSTEM_COMMUNITY
    }

    enum VestingType {TIME, BLOCK}

    uint256 private constant TOTAL_QUOTA = 100;

    uint256 private EARLY_CONTRIBUTORS_QUOTA = 15;
    uint256 private NETWORK_FEES_QUOTA = 0;
    uint256 private PROTOCOL_RESERVE_QUOTA = 35;
    uint256 private PARTNER_ADVISORS_QUOTA = 5;
    uint256 private TEAM_QUOTA = 15;
    uint256 private ECOSYSTEM_COMMUNITY_QUOTA = 30;

    event VestingPlanAdded(uint256 uniqueId);
    event VestingPlanRevoked(uint256 uniqueId);
    event QuotaAdjusted(
        uint256 earlyContributors,
        uint256 networkFees,
        uint256 protocolReserve,
        uint256 parternerAndAdvisor,
        uint256 team,
        uint256 ecosystemAndCommunity
    );
    event Withdraw(address beneficiary, uint256 amount);

    struct VestingPlan {
        uint256 uniqueId; //each vesting plan has a unique id
        bool isRevocable; //true if the vesting plan is revocable
        bool isRevoked; //true if the vesting plan is revoked
        bool accumulateDuringCliff; //true if the token amount is accumulated during cliff
        uint256 startTime; //grant start date, in seconds(VestingType.TIME) or block nums(VestingType.BLOCK)
        uint256 cliffDuration; //duration of cliff, in seconds(VestingType.TIME) or block nums(VestingType.BLOCK)
        uint256 duration; //duration of vesting plan, in seconds(VestingType.TIME) or block nums(VestingType.BLOCK), exclude cliff
        uint256 interval; //release interval, in seconds, useless if vestingType is VestingType.BLOCK
        uint256 initialAmount; //amount of tokens which will be released at startTime
        uint256 totalAmount; //total amount of vesting plan
        address beneficiary; //address that benefit from the vesting plan
        VestingCategory category; //vesting plan category -e.g. for backers, for team members...
        VestingType vestingType; //vesting type, vestingType==VestingType.BLOCK indicates that use block num as timing unit
    }

    mapping(uint256 => VestingPlan) private _vestingPlans;
    mapping(address => uint256[]) private _vestingPlanIds;
    mapping(uint256 => uint256) private _released;
    mapping(uint32 => uint256) private _categoryVestedAmount;

    constructor(uint256 initialSupply) public ERC20('Tushar', 'T1') {
        _mint(msg.sender, initialSupply);
    }

    function addVestingPlan(
        address beneficiary,
        uint256 totalAmount,
        uint256 initialAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 duration,
        uint256 interval,
        bool accumulateDuringCliff,
        bool isRevocable,
        VestingCategory category,
        VestingType vestingType
    ) public onlyOwner {
        uint256 currentTime = (vestingType == VestingType.TIME ? now : block.number);
        //check the startTime
        require(startTime > currentTime, 'The start time can not be earlier than the current time');
        require(initialAmount <= totalAmount, 'Initial amount can not be greater than the total amount');
        //check whether owner's balance is enough
        require(balanceOf(owner()) >= totalAmount, "Exceed owner's balance");
        //check whether category's balance is enough
        require(
            (_categoryVestedAmount[uint32(category)] + totalAmount) <=
                totalSupply().mul(_getCategoryPercentage(category)).div(TOTAL_QUOTA),
            "Exceed category's balance"
        );

        //generate unique id for vesting plan
        uint256 uniqueId = _getUniqueId(beneficiary);
        _vestingPlanIds[beneficiary].push(uniqueId);
        _vestingPlans[uniqueId] = VestingPlan(
            uniqueId,
            isRevocable,
            false,
            accumulateDuringCliff,
            startTime,
            cliffDuration,
            duration,
            interval,
            initialAmount,
            totalAmount,
            beneficiary,
            category,
            vestingType
        );
        _categoryVestedAmount[uint32(category)] = _categoryVestedAmount[uint32(category)] + totalAmount;
        //deposit funds in address(this)
        transfer(address(this), totalAmount);
        emit VestingPlanAdded(uniqueId);
    }

    function revokeVestingPlan(uint256 uniqueId) public onlyOwner {
        VestingPlan storage plan = _vestingPlans[uniqueId];
        require(plan.uniqueId == uniqueId, 'Vesting plan not exist');

        require(plan.isRevoked == false, "Vesting plan is already revoked");
        require(plan.isRevocable, 'Vesting plan is not revocable');

        plan.isRevoked = true;

        uint256 unreleasedAmount = _getUnreleasedAmount(uniqueId);
        //refund the unreleased tokens to owner
        this.transfer(owner(), unreleasedAmount);
        emit VestingPlanRevoked(uniqueId);
    }

    function getVestingPlan(uint256 planUniqueId)
        public
        view
        onlyOwner
        returns (
            bool isRevocable,
            bool isRevoked,
            bool accumulateDuringCliff,
            uint256 startTime,
            uint256 cliffDuration,
            uint256 duration,
            uint256 interval,
            uint256 initialAmount,
            uint256 totalAmount,
            address beneficiary,
            VestingCategory category,
            VestingType vestingType
        )
    {
        VestingPlan memory vestingPlan = _vestingPlans[planUniqueId];
        return (
            vestingPlan.isRevocable,
            vestingPlan.isRevoked,
            vestingPlan.accumulateDuringCliff,
            vestingPlan.startTime,
            vestingPlan.cliffDuration,
            vestingPlan.duration,
            vestingPlan.interval,
            vestingPlan.initialAmount,
            vestingPlan.totalAmount,
            vestingPlan.beneficiary,
            vestingPlan.category,
            vestingPlan.vestingType
        );
    }

    function adjustQuota(
        uint256 earlyContributors,
        uint256 networkFees,
        uint256 protocolReserve,
        uint256 parternerAndAdvisor,
        uint256 team,
        uint256 ecosystemAndCommunity
    ) public onlyOwner {
        require(
            earlyContributors + networkFees + protocolReserve + parternerAndAdvisor + team + ecosystemAndCommunity ==
                100,
            'Invalid quota'
        );

        uint256 totalSupply = totalSupply();

        require(
            _categoryVestedAmount[uint32(VestingCategory.EARLY_CONTRIBUTORS)] <=
                totalSupply.mul(earlyContributors).div(TOTAL_QUOTA),
            'Exceed allocated quota, EARLY_CONTRIBUTORS'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.NETWORK_FEES)] <=
                totalSupply.mul(networkFees).div(TOTAL_QUOTA),
            'Exceed allocated quota, NETWORK_FEES'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.PROTOCOL_RESERVE)] <=
                totalSupply.mul(protocolReserve).div(TOTAL_QUOTA),
            'Exceed allocated quota, PROTOCOL_RESERVE'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.PARTNER_ADVISORS)] <=
                totalSupply.mul(parternerAndAdvisor).div(TOTAL_QUOTA),
            'Exceed allocated quota, PARTNER_ADVISORS'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.TEAM)] <= totalSupply.mul(team).div(TOTAL_QUOTA),
            'Exceed allocated quota, TEAM'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.ECOSYSTEM_COMMUNITY)] <=
                totalSupply.mul(ecosystemAndCommunity).div(TOTAL_QUOTA),
            'Exceed allocated quota, ECOSYSTEM_COMMUNITY'
        );

        EARLY_CONTRIBUTORS_QUOTA = earlyContributors;
        NETWORK_FEES_QUOTA = networkFees;
        PROTOCOL_RESERVE_QUOTA = protocolReserve;
        PARTNER_ADVISORS_QUOTA = parternerAndAdvisor;
        TEAM_QUOTA = team;
        ECOSYSTEM_COMMUNITY_QUOTA = ecosystemAndCommunity;

        emit QuotaAdjusted(
            earlyContributors,
            networkFees,
            protocolReserve,
            parternerAndAdvisor,
            team,
            ecosystemAndCommunity
        );
    }

    function withdraw() public {
        uint256[] memory vestingPlanIds = _vestingPlanIds[msg.sender];
        require(vestingPlanIds.length != 0, 'No vesting plans exist');

        uint256 totalWithdrawableAmount = 0;
        for (uint32 i = 0; i < vestingPlanIds.length; i++) {
            uint256 vestingPlanId = vestingPlanIds[i];
            uint256 planWithdrawableAmount = _calculateWithdrawableAmount(_vestingPlans[vestingPlanId]);
            _released[vestingPlanId] = _released[vestingPlanId] + planWithdrawableAmount;
            totalWithdrawableAmount += planWithdrawableAmount;
        }

        //transfer withdrawable tokens to beneficiary
        this.transfer(msg.sender, totalWithdrawableAmount);
        emit Withdraw(msg.sender, totalWithdrawableAmount);
    }

    function getTotalVestedAmount() public view returns (uint256) {
        uint256[] memory vestingPlanIds = _vestingPlanIds[msg.sender];
        require(vestingPlanIds.length != 0, 'No vesting plans exist');

        uint256 totalVestedAmount = 0;
        for (uint32 i = 0; i < vestingPlanIds.length; i++) {
            VestingPlan memory vestingPlan = _vestingPlans[vestingPlanIds[i]];
            if (!vestingPlan.isRevoked) {
                totalVestedAmount += vestingPlan.totalAmount;
            }
        }

        return totalVestedAmount;
    }

    function getWithdrawableAmount() public view returns (uint256) {
        uint256[] memory vestingPlanIds = _vestingPlanIds[msg.sender];
        require(vestingPlanIds.length != 0, 'No vesting plans exist');

        uint256 totalWithdrawableAmount = 0;
        for (uint32 i = 0; i < vestingPlanIds.length; i++) {
            uint256 planWithdrawableAmount = _calculateWithdrawableAmount(_vestingPlans[vestingPlanIds[i]]);
            totalWithdrawableAmount += planWithdrawableAmount;
        }

        return totalWithdrawableAmount;
    }

    function _getCategoryPercentage(VestingCategory category) private view returns (uint256) {
        if (category == VestingCategory.EARLY_CONTRIBUTORS) {
            return EARLY_CONTRIBUTORS_QUOTA;
        } else if (category == VestingCategory.NETWORK_FEES) {
            return NETWORK_FEES_QUOTA;
        } else if (category == VestingCategory.PROTOCOL_RESERVE) {
            return PROTOCOL_RESERVE_QUOTA;
        } else if (category == VestingCategory.PARTNER_ADVISORS) {
            return PARTNER_ADVISORS_QUOTA;
        } else if (category == VestingCategory.TEAM) {
            return TEAM_QUOTA;
        } else if (category == VestingCategory.ECOSYSTEM_COMMUNITY) {
            return ECOSYSTEM_COMMUNITY_QUOTA;
        } else {
            revert('Invalid vesting category');
        }
    }

    function _getUniqueId(address beneficiary) private view returns (uint256) {
        uint256 uniqueId =
            uint256(
                keccak256(
                    abi.encodePacked(string(abi.encodePacked(beneficiary)), block.number, now)
                )
            );
        return uniqueId;
    }

    function _getUnreleasedAmount(uint256 uniqueId) private view returns (uint256) {
        VestingPlan memory plan = _vestingPlans[uniqueId];
        uint256 unreleasedAmount = plan.totalAmount - _released[uniqueId];
        return unreleasedAmount;
    }

    function _calculateWithdrawableAmount(VestingPlan memory plan) private view returns (uint256) {
        //revoked vesting plan
        if (plan.isRevoked) {
            return uint256(0);
        }

        uint256 currentTime = (plan.vestingType == VestingType.TIME ? now : block.number);

        if (currentTime < plan.startTime) {
            return uint256(0);
        }

        //during cliff
        uint256 releasedAmount = _released[plan.uniqueId];
        if (currentTime <= plan.startTime.add(plan.cliffDuration)) {
            if (plan.initialAmount > releasedAmount) {
                return plan.initialAmount.sub(releasedAmount);
            } else {
                return uint256(0);
            }
            //vesting finished
        } else if (currentTime > plan.startTime.add(plan.cliffDuration).add(plan.duration)) {
            if (plan.totalAmount > releasedAmount) {
                return plan.totalAmount.sub(releasedAmount);
            } else {
                return uint256(0);
            }
            // during the vesting duration, exclude cliff
        } else {
            uint256 accumulatstartTime =
                (plan.accumulateDuringCliff ? plan.startTime : plan.startTime + plan.cliffDuration);
            uint256 totalDuration =
                (plan.accumulateDuringCliff ? plan.duration.add(plan.cliffDuration) : plan.duration);

            uint256 intervalCounts;
            if (plan.vestingType == VestingType.TIME) {
                intervalCounts = (
                    totalDuration.mod(plan.interval) == 0
                        ? totalDuration.div(plan.interval)
                        : totalDuration.div(plan.interval).add(1)
                );
            } else {
                intervalCounts = totalDuration;
            }

            uint256 planInterval = (plan.vestingType == VestingType.TIME ? plan.interval : 1);

            uint256 accumulatedAmount =
                plan.totalAmount.sub(plan.initialAmount).mul(currentTime.sub(accumulatstartTime).div(planInterval)).div(
                    intervalCounts
                );

            return accumulatedAmount.add(plan.initialAmount).sub(releasedAmount);
        }
    }
}