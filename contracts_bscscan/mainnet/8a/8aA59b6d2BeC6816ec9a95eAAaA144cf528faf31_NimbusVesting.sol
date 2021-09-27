/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

pragma solidity =0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library SafeBEP20 {
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

interface INimbusVesting {
    function vest(address user, uint amount, uint vestingFirstPeriod, uint vestingSecondPeriod) external;
    function vestWithVestType(address user, uint amount, uint vestingFirstPeriodDuration, uint vestingSecondPeriodDuration, uint vestType) external;
    function unvest() external returns (uint unvested);
    function unvestFor(address user) external returns (uint unvested);
}

contract NimbusVesting is Ownable, Pausable, INimbusVesting { 
    using SafeBEP20 for IBEP20;
    
    IBEP20 public immutable vestingToken;

    struct VestingInfo {
        uint vestingAmount;
        uint unvestedAmount;
        uint vestingType; //for information purposes and future use in other contracts
        uint vestingStart;
        uint vestingReleaseStartDate;
        uint vestingEnd;
        uint vestingSecondPeriod;
    }

    mapping (address => uint) public vestingNonces;
    mapping (address => mapping (uint => VestingInfo)) public vestingInfos;
    mapping (address => bool) public vesters;

    bool public canAnyoneUnvest;

    event UpdateVesters(address vester, bool isActive);
    event Vest(address indexed user, uint vestNonece, uint amount, uint indexed vestingFirstPeriod, uint vestingSecondPeriod, uint vestingReleaseStartDate, uint vestingEnd, uint indexed vestType);
    event Unvest(address indexed user, uint amount);
    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed to, address indexed token, uint amount);
    event ToggleCanAnyoneUnvest(bool indexed canAnyoneUnvest);

    constructor(address vestingTokenAddress) {
        require(Address.isContract(vestingTokenAddress), "NimbusVesting: Not a contract");
        vestingToken = IBEP20(vestingTokenAddress);
    }
    
    function vest(address user, uint amount, uint vestingFirstPeriod, uint vestingSecondPeriod) override external whenNotPaused { 
        vestWithVestType(user, amount, vestingFirstPeriod, vestingSecondPeriod, 0);
    }

    function vestWithVestType(address user, uint amount, uint vestingFirstPeriodDuration, uint vestingSecondPeriodDuration, uint vestType) override public whenNotPaused {
        require (msg.sender == owner || vesters[msg.sender], "NimbusVesting::vest: Not allowed");
        require(user != address(0), "NimbusVesting::vest: Vest to the zero address");
        uint nonce = ++vestingNonces[user];

        vestingInfos[user][nonce].vestingAmount = amount;
        vestingInfos[user][nonce].vestingType = vestType;
        vestingInfos[user][nonce].vestingStart = block.timestamp;
        vestingInfos[user][nonce].vestingSecondPeriod = vestingSecondPeriodDuration;
        uint vestingReleaseStartDate = block.timestamp + vestingFirstPeriodDuration;
        uint vestingEnd = vestingReleaseStartDate + vestingSecondPeriodDuration;
        vestingInfos[user][nonce].vestingReleaseStartDate = vestingReleaseStartDate;
        vestingInfos[user][nonce].vestingEnd = vestingEnd;
        emit Vest(user, nonce, amount, vestingFirstPeriodDuration, vestingSecondPeriodDuration, vestingReleaseStartDate, vestingEnd, vestType);
    }

    function unvest() external override whenNotPaused returns (uint unvested) {
        return _unvest(msg.sender);
    }

    function unvestFor(address user) external override whenNotPaused returns (uint unvested) {
        require(canAnyoneUnvest || vesters[msg.sender], "NimbusVesting: Not allowed");
        return _unvest(user);
    }

    function unvestForBatch(address[] memory users) external whenNotPaused returns (uint unvested) {
        require(canAnyoneUnvest || vesters[msg.sender], "NimbusVesting: Not allowed");
        uint length = users.length;
        for (uint i = 0; i < length; i++) {
            unvested += _unvest(users[i]);
        }
    }

    function _unvest(address user) internal returns (uint unvested) {
        uint nonce = vestingNonces[user]; 
        require (nonce > 0, "NimbusVesting: No vested amount");
        for (uint i = 1; i <= nonce; i++) {
            VestingInfo memory vestingInfo = vestingInfos[user][i];
            if (vestingInfo.vestingAmount == vestingInfo.unvestedAmount) continue;
            if (vestingInfo.vestingReleaseStartDate > block.timestamp) continue;
            uint toUnvest;
            if (vestingInfo.vestingSecondPeriod != 0) {
                toUnvest = (block.timestamp - vestingInfo.vestingReleaseStartDate) * vestingInfo.vestingAmount / vestingInfo.vestingSecondPeriod;
                if (toUnvest > vestingInfo.vestingAmount) {
                    toUnvest = vestingInfo.vestingAmount;
                } 
            } else {
                toUnvest = vestingInfo.vestingAmount;
            }
            uint totalUnvestedForNonce = toUnvest;
            toUnvest -= vestingInfo.unvestedAmount;
            unvested += toUnvest;
            vestingInfos[user][i].unvestedAmount = totalUnvestedForNonce;
        }
        require(unvested > 0, "NimbusVesting: Unvest amount is zero");
        vestingToken.safeTransfer(user, unvested);
        emit Unvest(user, unvested);
    }

    function availableForUnvesting(address user) external view returns (uint unvestAmount) {
        uint nonce = vestingNonces[user];
        if (nonce == 0) return 0;
        for (uint i = 1; i <= nonce; i++) {
            VestingInfo memory vestingInfo = vestingInfos[user][i];
            if (vestingInfo.vestingAmount == vestingInfo.unvestedAmount) continue;
            if (vestingInfo.vestingReleaseStartDate > block.timestamp) continue;
            uint toUnvest;
            if (vestingInfo.vestingSecondPeriod != 0) {
                toUnvest = (block.timestamp - vestingInfo.vestingReleaseStartDate) * vestingInfo.vestingAmount / vestingInfo.vestingSecondPeriod;
                if (toUnvest > vestingInfo.vestingAmount) {
                    toUnvest = vestingInfo.vestingAmount;
                } 
            } else {
                toUnvest = vestingInfo.vestingAmount;
            }
            toUnvest -= vestingInfo.unvestedAmount;
            unvestAmount += toUnvest;
        }
    }

    function userUnvested(address user) external view returns (uint totalUnvested) {
        uint nonce = vestingNonces[user];
        if (nonce == 0) return 0;
        for (uint i = 1; i <= nonce; i++) {
            VestingInfo memory vestingInfo = vestingInfos[user][i];
            if (vestingInfo.vestingReleaseStartDate > block.timestamp) continue;
            totalUnvested += vestingInfo.unvestedAmount;
        }
    }


    function userVestedUnclaimed(address user) external view returns (uint unclaimed) {
        uint nonce = vestingNonces[user];
        if (nonce == 0) return 0;
        for (uint i = 1; i <= nonce; i++) {
            VestingInfo memory vestingInfo = vestingInfos[user][i];
            if (vestingInfo.vestingAmount == vestingInfo.unvestedAmount) continue;
            unclaimed += (vestingInfo.vestingAmount - vestingInfo.unvestedAmount);
        }
    }

    function userTotalVested(address user) external view returns (uint totalVested) {
        uint nonce = vestingNonces[user];
        if (nonce == 0) return 0;
        for (uint i = 1; i <= nonce; i++) {
            totalVested += vestingInfos[user][i].vestingAmount;
        }
    }

    function updateVesters(address vester, bool isActive) external onlyOwner { 
        require(vester != address(0), "NimbusVesting::updateVesters: Zero address");
        vesters[vester] = isActive;
        emit UpdateVesters(vester, isActive);
    }

    function toggleCanAnyoneUnvest() external onlyOwner { 
        canAnyoneUnvest = !canAnyoneUnvest;
        emit ToggleCanAnyoneUnvest(canAnyoneUnvest);
    }

    function rescue(address to, address tokenAddress, uint256 amount) external onlyOwner {
        require(to != address(0), "NimbusVesting::rescue: Cannot rescue to the zero address");
        require(amount > 0, "NimbusVesting::rescue: Cannot rescue 0");

        IBEP20(tokenAddress).safeTransfer(to, amount);
        emit RescueToken(to, address(tokenAddress), amount);
    }

    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "NimbusVesting::rescue: Cannot rescue to the zero address");
        require(amount > 0, "NimbusVesting::rescue Cannot rescue 0");

        to.transfer(amount);
        emit Rescue(to, amount);
    }
}