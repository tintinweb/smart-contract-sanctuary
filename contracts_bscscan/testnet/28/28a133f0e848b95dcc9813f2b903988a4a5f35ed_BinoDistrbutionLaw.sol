// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IMaterials.sol";
import "./ReentrancyGuard.sol";


contract BinoDistrbutionLaw is Context, Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardsToken;
    IMaterials public materials;
    uint256 public constant CONTEST_DURATION = 14 days;
    uint256 public constant CLAIM_DURATION = 4 days;
    // 152 + 69 + 25 = 246
    uint256 public constant TOTAL_ALLO_POINTS = 246;
    uint256[] public rankForThisRound;
    bool public isBurnTime;
    bool public isInjectTime;
    bool public isClaimTime;
    // record each round's total Bino reward balance; reset when the next round burn time starts
    uint256 private _totalRewardBalance;

    // material Id => points
    mapping(uint256 => uint256) private _materialPoints;
    // user => landId(lid) => stored points of this user in this land
    mapping(address => mapping (uint256 => uint256)) private _storedPointsOf;
    // landId(lid) => total burned mateials&bino points in this period for this land; from 1 to 7
    mapping(uint256 => uint256) private _totalPointsOf;
    // user => landId(lid) => injected points of this user in this land for this period
    mapping(address => mapping (uint256 => uint256)) private _injectedPointsOf;
    // landId(lid) => total injected points in this land for this period
    mapping(uint256 => uint256) private _totalInjectedPointsOf;
    // user => landId(lid) => time stamp of last time points injection
    mapping(address => mapping(uint256 => uint256)) private _lastTimeInject;

    event OpenBurnTime(uint256 indexed currentTime);
    event CloseBurnTime(uint256 indexed currentTime);
    event OpenInjectTime(uint256 indexed currentTime);
    event CloseInjectTime(uint256 indexed currentTime);
    event AddPoints(address indexed account, uint256 indexed amount);
    event InjectPoints(address indexed account, uint256 indexed lid, uint256 indexed amount);
    event ClaimBinoRewards(address indexed account, uint256 indexed lid, uint256 indexed rewards);


    constructor (address _rewardsToken, address _materials) public {
        rewardsToken = IERC20(_rewardsToken);
        materials = IMaterials(_materials);

        _setMaterialPoints();
        isBurnTime = false;
        isInjectTime = false;
        isClaimTime = false;
    }

    function openBurnTime() public onlyOwner {
        require(!isBurnTime, "Burn Time has opened");
        // reset the stored points & injected points for all lands
        for (uint256 i = 1; i <= 7; ++i) {
            _totalPointsOf[i] = 0;
            _totalInjectedPointsOf[i] = 0;
        }
        delete rankForThisRound;

        isBurnTime = true;
        // once BurnTime starts, the next round starts, and ClaimTime closed
        isClaimTime = false;
        _totalRewardBalance = 0;

        emit OpenBurnTime(block.timestamp);
    }

    function closeBurnTime() public onlyOwner {
        require(isBurnTime, "Burn Time has NOT opened");
        isBurnTime = false;

        emit CloseBurnTime(block.timestamp);
    }

    function openInjectTime() public onlyOwner {
        require(!isBurnTime, "can NOT inject points within Burn Time");
        require(!isInjectTime, "Inject Time has opened");

        isInjectTime = true;

        emit OpenInjectTime(block.timestamp);
    }

    // rank is a list of lids; e.g. [3,1,5] means the 1st is lid=3, 2nd is lid=1, 3rd is lid=5
    function closeInjectTime(uint256[] memory rank) public onlyOwner {
        require(isInjectTime, "Inject Time has NOT opened");

        isInjectTime = false;
        // once injectTime closed, the claim time starts
        isClaimTime = true;

        _setRankForThisRound(rank);
        _totalRewardBalance = rewardsToken.balanceOf(address(this));    // decimal: 1e18

        emit CloseInjectTime(block.timestamp);
    }

    function recoverRemaining(address to) public onlyOwner {
        require(!isClaimTime, "admin can not recover reward tokens within claimTime");
        uint256 remaining = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransfer(to, remaining);
    }

    function setMaterialPoints(uint256 materialId, uint256 newPoints) external onlyOwner {
        require(materialId > 0 && materialId <=10, "material id is out of range of [1, 10]");
        _materialPoints[materialId] = newPoints;
    }

    function materialPoints(uint256 materialId) public view returns (uint256) {
        require(materialId > 0 && materialId <=10, "material id is out of range of [1, 10]");
        return _materialPoints[materialId];
    }

    function storedPointsOf(address account, uint256 lid) public view returns (uint256) {
        require(lid > 0 && lid <=7, "land id is out of range of [1, 7]");
        return _storedPointsOf[account][lid];
    }

    function totalPointsOf(uint256 lid) public view returns (uint256) {
        require(lid > 0 && lid <=7, "land id is out of range of [1, 7]");
        return _totalPointsOf[lid];
    }

    function injectedPointsOf(address account, uint256 lid) public view returns (uint256) {
        require(lid > 0 && lid <=7, "land id is out of range of [1, 7]");
        // reset user's inject point to 0 for the new round
        if(block.timestamp > _lastTimeInject[account][lid].add(CONTEST_DURATION).add(CLAIM_DURATION)) {
            return 0;
        }
        return _injectedPointsOf[account][lid];
    }

    // in Bino decimal, 1e18
    function pendingRewards(address account, uint256 lid) public view returns (uint256) {
        require(lid > 0 && lid <=7, "land id is out of range of [1, 7]");
        if(!isClaimTime) {
            return 0;
        }
        if(block.timestamp > _lastTimeInject[account][lid].add(CONTEST_DURATION).add(CLAIM_DURATION)) {
            return 0;
        }

        uint256 thisRank = 0;
        for (uint256 i = 0; i < rankForThisRound.length; ++i) {
            if (lid == rankForThisRound[i]) {
                thisRank = i.add(1);    // from 1 to 3
                break;
            }
        }
        if (thisRank == 0) {
            return 0;
        }

        uint256 rankShare;
        if (thisRank == 1) {
            rankShare = _totalRewardBalance.mul(152).div(TOTAL_ALLO_POINTS);  // 1e18
        } else if (thisRank == 2) {
            rankShare = _totalRewardBalance.mul(69).div(TOTAL_ALLO_POINTS);  // 1e18
        } else {
            rankShare = _totalRewardBalance.mul(25).div(TOTAL_ALLO_POINTS);  // 1e18
        }

        return _injectedPointsOf[account][lid].mul(rankShare).div(_totalInjectedPointsOf[lid]);
    }

    function totalInjectedPointsOf(uint256 lid) public view returns (uint256) {
        require(lid > 0 && lid <=7, "land id is out of range of [1, 7]");
        return _totalInjectedPointsOf[lid];
    }

    // user MUST approve before use this function
    function burnMaterialsForLand(uint256 lid, uint256[] memory materialIds, uint256[] memory materialAmounts) public {
        require(isBurnTime, "Burn Time has NOT arrived!");
        require(lid > 0 && lid <=7, "land id is out of range of [1, 7]");
        require(materialIds.length == materialAmounts.length, "ids and amounts length mismatch");

        // burn selected materials
        materials.burnBatch(_msgSender(), materialIds, materialAmounts);
        // accumulate points for user and land
        uint256 addPoints = _computeTotalPoints(materialIds, materialAmounts);                   // decimal: 1e0
        _storedPointsOf[_msgSender()][lid] = _storedPointsOf[_msgSender()][lid].add(addPoints);  // decimal: 1e0
        _totalPointsOf[lid] = _totalPointsOf[lid].add(addPoints);                                // decimal: 1e0

        emit AddPoints(_msgSender(), addPoints);
    }

    // user MUST approve before use this function
    function burnBinoForLand(uint256 lid, uint256 amount) public {
        require(isBurnTime, "Burn Time has NOT arrived!");
        require(lid > 0 && lid <=7, "land id is out of range of [1, 7]");

        rewardsToken.burnFrom(_msgSender(), amount);
        // accumulate points for user and land
        uint256 addPoints = amount.mul(40).div(1e18);                                           // decimal: 1e0
        _storedPointsOf[_msgSender()][lid] = _storedPointsOf[_msgSender()][lid].add(addPoints); // decimal: 1e0
        _totalPointsOf[lid] = _totalPointsOf[lid].add(addPoints);                               // decimal: 1e0

        emit AddPoints(_msgSender(), addPoints);
    }

    function injectPoints(uint256 lid, uint256 amount) public {
        require(isInjectTime, "Can NOT inject points now");
        require(lid > 0 && lid <=7, "land id is out of range of [1, 7]");
        require(amount <= _storedPointsOf[_msgSender()][lid], "stored points are not enough");

        // reset user's inject point to 0 for the new round
        if(block.timestamp > _lastTimeInject[_msgSender()][lid].add(CONTEST_DURATION).add(CLAIM_DURATION)) {
            _injectedPointsOf[_msgSender()][lid] = 0;
        }

        _storedPointsOf[_msgSender()][lid] = _storedPointsOf[_msgSender()][lid].sub(amount);
        _injectedPointsOf[_msgSender()][lid] = _injectedPointsOf[_msgSender()][lid].add(amount);
        _totalInjectedPointsOf[lid] = _totalInjectedPointsOf[lid].add(amount);

        _lastTimeInject[_msgSender()][lid] = block.timestamp;

        emit InjectPoints(_msgSender(), lid, amount);
    }

    function claimBinoRewards(uint256 lid) public nonReentrant {
        require(isClaimTime, "Can NOT claim rewards now");
        require(lid > 0 && lid <=7, "land id is out of range of [1, 7]");
        // reset user's inject point to 0 for the new round
        if(block.timestamp > _lastTimeInject[_msgSender()][lid].add(CONTEST_DURATION).add(CLAIM_DURATION)) {
            _injectedPointsOf[_msgSender()][lid] = 0;
            return;
        }

        uint256 thisRank = 0;
        for (uint256 i = 0; i < rankForThisRound.length; ++i) {
            if (lid == rankForThisRound[i]) {
                thisRank = i.add(1);    // from 1 to 3
                break;
            }
        }
        require(thisRank == 1 || thisRank == 2 || thisRank == 3, "only the top 3 ranked land has extra rewards");

        uint256 rankShare;
        if (thisRank == 1) {
            rankShare = _totalRewardBalance.mul(152).div(TOTAL_ALLO_POINTS);  // 1e18
        } else if (thisRank == 2) {
            rankShare = _totalRewardBalance.mul(69).div(TOTAL_ALLO_POINTS);  // 1e18
        } else {
            rankShare = _totalRewardBalance.mul(25).div(TOTAL_ALLO_POINTS);  // 1e18
        }

        uint256 rewards = _injectedPointsOf[_msgSender()][lid].mul(rankShare).div(_totalInjectedPointsOf[lid]);
        _injectedPointsOf[_msgSender()][lid] = 0;
        rewardsToken.safeTransfer(_msgSender(), rewards);

        emit ClaimBinoRewards(_msgSender(), lid, rewards);
    }

    function _computeTotalPoints(uint256[] memory materialIds, uint256[] memory materialAmounts) private view returns (uint256) {
        uint256 result = 0;
        for(uint256 i = 0; i < materialIds.length; ++i) {
            uint256 points = _materialPoints[materialIds[i]];
            uint256 amount = materialAmounts[i];
            result = result.add(points.mul(amount));
        }
        return result;
    }

    function _setMaterialPoints() private {
        _materialPoints[1] = 1;    // id=1 clay
        _materialPoints[2] = 2;    // id=2 wood
        _materialPoints[3] = 9;    // id=3 stone
        _materialPoints[4] = 15;   // id=4 glass
        _materialPoints[5] = 25;   // id=5 iron
        _materialPoints[6] = 2;    // id=6 brick
        _materialPoints[7] = 5;    // id=7 woodAdvanced
        _materialPoints[8] = 30;   // id=8 stoneAdvanced
        _materialPoints[9] = 75;   // id=9 glassAdvanced
        _materialPoints[10] = 125;  // id=10 steel
    }

    function _setRankForThisRound(uint256[] memory _newRank) private {
        rankForThisRound = _newRank;
    }

}