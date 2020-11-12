pragma solidity >=0.5.0 <0.6.0;

library DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
    function div(uint x, uint y) internal pure returns (uint z) {
        // assert(y > 0); // Solidity automatically throws when dividing by 0
        z = x / y;
        // assert(x == y * z + x % y); // There is no case in which this doesn't hold
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

/**
 * @title Staking and delegation contract
 * @author DOS Network
 */

contract ERC20I {
    function balanceOf(address who) public view returns (uint);
    function decimals() public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
}

contract DOSAddressBridgeInterface {
    function getProxyAddress() public view returns(address);
}

contract Staking {
    using DSMath for *;

    uint public constant ONEYEAR = 365 days;
    uint public constant DOSDECIMAL = 18;
    uint public constant DBDECIMAL = 0;
    uint public constant LISTHEAD = 0x1;
    uint public initBlkN;
    address public admin;
    address public DOSTOKEN;
    address public DBTOKEN ;
    address public stakingRewardsVault;
    address public bridgeAddr;  // DOS address bridge
    uint public minStakePerNode;
    uint public dropburnMaxQuota;
    uint public totalStakedTokens;
    uint public circulatingSupply;
    uint public unbondDuration;
    uint public lastRateUpdatedTime;    // in seconds
    uint public accumulatedRewardIndex; // Multiplied by 1e10

    struct Node {
        address ownerAddr;
        uint rewardCut;  // %, [0, 100).
        uint stakedDB;   // [0, dropburnMaxQuota]
        uint selfStakedAmount;
        uint totalOtherDelegatedAmount;
        uint accumulatedRewards;
        uint accumulatedRewardIndex;
        uint pendingWithdrawToken;
        uint pendingWithdrawDB;
        uint lastStartTime;
        bool running;
        string description;
        address[] nodeDelegators;
        // release time => UnbondRequest metadata
        mapping (uint => UnbondRequest) unbondRequests;
        // LISTHEAD => release time 1 => ... => release time m => LISTHEAD
        mapping (uint => uint) releaseTime;
        string logoUrl;
    }

    struct UnbondRequest {
        uint dosAmount;
        uint dbAmount;
    }

    struct Delegation {
        address delegatedNode;
        uint delegatedAmount;
        uint accumulatedRewards; // in tokens
        uint accumulatedRewardIndex;
        uint pendingWithdraw;

        // release time => UnbondRequest metadata
        mapping (uint => UnbondRequest) unbondRequests;
        // LISTHEAD => release time 1 => ... => release time m => LISTHEAD
        mapping (uint => uint) releaseTime;
    }

    // 1:1 node address => Node metadata
    mapping (address => Node) public nodes;
    address[] public nodeAddrs;

    // node runner's main address => {node addresses}
    mapping (address => mapping(address => bool)) public nodeRunners;
    // 1:n token holder address => {delegated node 1 : Delegation, ..., delegated node n : Delegation}
    mapping (address => mapping(address => Delegation)) public delegators;

    event UpdateStakingAdmin(address oldAdmin, address newAdmin);
    event UpdateDropBurnMaxQuota(uint oldQuota, uint newQuota);
    event UpdateUnbondDuration(uint oldDuration, uint newDuration);
    event UpdateCirculatingSupply(uint oldCirculatingSupply, uint newCirculatingSupply);
    event UpdateMinStakePerNode(uint oldMinStakePerNode, uint newMinStakePerNode);
    event NewNode(address indexed owner, address indexed nodeAddress, uint selfStakedAmount, uint stakedDB, uint rewardCut);
    event Delegate(address indexed from, address indexed to, uint amount);
    event Withdraw(address indexed from, address indexed to, bool nodeRunner, uint tokenAmount, uint dbAmount);
    event Unbond(address indexed from, address indexed to, bool nodeRunner, uint tokenAmount, uint dropburnAmount);
    event ClaimReward(address indexed to, bool nodeRunner, uint amount);

    constructor(address _dostoken, address _dbtoken, address _vault, address _bridgeAddr) public {
        initialize(_dostoken, _dbtoken, _vault, _bridgeAddr);
    }

    function initialize(address _dostoken, address _dbtoken, address _vault, address _bridgeAddr) public {
        require(initBlkN == 0, "already-initialized");

        initBlkN = block.number;
        admin = msg.sender;
        DOSTOKEN = _dostoken;
        DBTOKEN = _dbtoken;
        stakingRewardsVault = _vault;
        bridgeAddr = _bridgeAddr;
        minStakePerNode = 800000 * (10 ** DOSDECIMAL);
        dropburnMaxQuota = 3;
        circulatingSupply = 160000000 * (10 ** DOSDECIMAL);
        unbondDuration = 7 days;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "onlyAdmin");
        _;
    }

    function setAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit UpdateStakingAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    /// @dev used when drop burn max quota duration is changed
    function setDropBurnMaxQuota(uint _quota) public onlyAdmin {
        require(_quota != dropburnMaxQuota && _quota < 10, "valid-dropburnMaxQuota-0-to-9");
        emit UpdateDropBurnMaxQuota(dropburnMaxQuota, _quota);
        dropburnMaxQuota = _quota;
    }

    /// @dev used when withdraw duration is changed
    function setUnbondDuration(uint _duration) public onlyAdmin {
        emit UpdateUnbondDuration(unbondDuration, _duration);
        unbondDuration = _duration;
    }

    /// @dev used when locked token is unlocked
    function setCirculatingSupply(uint _newSupply) public onlyAdmin {
        require(circulatingSupply >= totalStakedTokens,"CirculatingSupply < totalStakedTokens");

        updateGlobalRewardIndex();
        emit UpdateCirculatingSupply(circulatingSupply, _newSupply);
        circulatingSupply = _newSupply;
    }

    /// @dev used when minStakePerNode is updated
    function setMinStakePerNode(uint _minStake) public onlyAdmin {
        emit UpdateMinStakePerNode(minStakePerNode, _minStake);
        minStakePerNode = _minStake;
    }

    function getNodeAddrs() public view returns(address[] memory) {
        return nodeAddrs;
    }

    modifier checkStakingValidity(uint _tokenAmount, uint _dropburnAmount, uint _rewardCut) {
        require(0 <= _rewardCut && _rewardCut < 100, "not-valid-rewardCut-in-0-to-99");
        require(_tokenAmount >= minStakePerNode.mul(10.sub(DSMath.min(_dropburnAmount, dropburnMaxQuota))).div(10),
                "not-enough-dos-token-to-start-node");
        _;
    }

    modifier onlyFromProxy() {
        require(msg.sender == DOSAddressBridgeInterface(bridgeAddr).getProxyAddress(), "not-from-dos-proxy");
        _;
    }

    function isValidStakingNode(address nodeAddr) public view returns(bool) {
        Node storage node = nodes[nodeAddr];
        uint _tokenAmount = node.selfStakedAmount;
        uint _dropburnAmount = node.stakedDB;
        if (_tokenAmount >= minStakePerNode.mul(10.sub(DSMath.min(_dropburnAmount, dropburnMaxQuota))).div(10)) {
            return true;
        }
        return false;
    }

    function newNode(
        address _nodeAddr,
        uint _tokenAmount,
        uint _dropburnAmount,
        uint _rewardCut,
        string memory _desc,
        string memory _logoUrl)
        public checkStakingValidity(_tokenAmount, _dropburnAmount, _rewardCut)
    {
        require(!nodeRunners[msg.sender][_nodeAddr], "node-already-registered");
        require(nodes[_nodeAddr].ownerAddr == address(0), "node-already-registered");

        nodeRunners[msg.sender][_nodeAddr] = true;
        address[] memory nodeDelegators;
        nodes[_nodeAddr] = Node(msg.sender, _rewardCut, _dropburnAmount, _tokenAmount, 0, 0, 0, 0, 0, 0, false, _desc, nodeDelegators, _logoUrl);
        nodes[_nodeAddr].releaseTime[LISTHEAD] = LISTHEAD;
        nodeAddrs.push(_nodeAddr);
        // This would change interest rate
        totalStakedTokens = totalStakedTokens.add(_tokenAmount);
        // Deposit tokens.
        ERC20I(DOSTOKEN).transferFrom(msg.sender, address(this), _tokenAmount);
        if (_dropburnAmount > 0) {
            ERC20I(DBTOKEN).transferFrom(msg.sender, address(this), _dropburnAmount);
        }
        emit NewNode(msg.sender, _nodeAddr, _tokenAmount, _dropburnAmount, _rewardCut);
    }

    function nodeStart(address _nodeAddr) public onlyFromProxy {
        require(nodes[_nodeAddr].ownerAddr != address(0), "node-not-registered");
        Node storage node = nodes[_nodeAddr];
        if (!node.running) {
            node.running = true;
            node.lastStartTime = now;
            updateGlobalRewardIndex();
            node.accumulatedRewardIndex = accumulatedRewardIndex;
            for (uint i = 0; i < node.nodeDelegators.length; i++) {
                Delegation storage delegator = delegators[node.nodeDelegators[i]][_nodeAddr];
                delegator.accumulatedRewardIndex = accumulatedRewardIndex;
            }
        }
    }

    function nodeStop(address _nodeAddr) public onlyFromProxy {
        require(nodes[_nodeAddr].ownerAddr != address(0), "node-not-registered");
        nodeStopInternal(_nodeAddr);
    }

    function nodeStopInternal(address _nodeAddr) internal {
        Node storage node = nodes[_nodeAddr];
        if (node.running) {
            updateGlobalRewardIndex();
            node.accumulatedRewards = getNodeRewardTokens(_nodeAddr);
            node.accumulatedRewardIndex = accumulatedRewardIndex;
            for (uint i = 0; i < node.nodeDelegators.length; i++) {
                Delegation storage delegator = delegators[node.nodeDelegators[i]][_nodeAddr];
                delegator.accumulatedRewards = getDelegatorRewardTokens(node.nodeDelegators[i], _nodeAddr);
                delegator.accumulatedRewardIndex = accumulatedRewardIndex;
            }
            node.running = false;
        }
    }

    // For node runners to configure new staking settings.
    function updateNodeStaking(
        address _nodeAddr,
        uint _newTokenAmount,
        uint _newDropburnAmount,
        uint _newCut,
        string memory _newDesc,
        string memory _newLogoUrl)
        public
    {
        require(nodeRunners[msg.sender][_nodeAddr], "node-not-owned-by-msgSender");

        Node storage node = nodes[_nodeAddr];
        // _newCut with value uint(-1) means skipping this config.
        if (_newCut != uint(-1)) {
            require(_newCut >= 0 && _newCut < 100, "not-valid-rewardCut-in-0-to-99");
            // TODO: Update rewardCut affects delegators' reward calculation.
            node.rewardCut = _newCut;
        }
        if (_newDropburnAmount != 0) {
            node.stakedDB = node.stakedDB.add(_newDropburnAmount);
            ERC20I(DBTOKEN).transferFrom(msg.sender, address(this), _newDropburnAmount);
        }
        if (_newTokenAmount != 0) {
            node.selfStakedAmount = node.selfStakedAmount.add(_newTokenAmount);
            if (node.running) {
                // Update global accumulated interest index.
                updateGlobalRewardIndex();
                node.accumulatedRewards = getNodeRewardTokens(_nodeAddr);
                node.accumulatedRewardIndex = accumulatedRewardIndex;
            }
            // This would change interest rate
            totalStakedTokens = totalStakedTokens.add(_newTokenAmount);
            ERC20I(DOSTOKEN).transferFrom(msg.sender, address(this), _newTokenAmount);
        }
        if (bytes(_newDesc).length > 0 && bytes(_newDesc).length <= 32) {
            node.description = _newDesc;
        }
        if (bytes(_newLogoUrl).length > 0) {
            node.logoUrl = _newLogoUrl;
        }
    }

    // Token holders (delegators) call this function. It's allowed to delegate to the same node multiple times if possible.
    // Note: Re-delegate is not supported.
    function delegate(uint _tokenAmount, address _nodeAddr) public {
        Node storage node = nodes[_nodeAddr];
        require(node.ownerAddr != address(0), "node-not-exist");
        require(msg.sender != node.ownerAddr, "node-owner-cannot-self-delegate");

        Delegation storage delegator = delegators[msg.sender][_nodeAddr];
        require(delegator.delegatedNode == address(0) || delegator.delegatedNode == _nodeAddr, "invalid-delegated-node-addr");

        node.nodeDelegators.push(msg.sender);
        node.totalOtherDelegatedAmount = node.totalOtherDelegatedAmount.add(_tokenAmount);
        if (node.running) {
            // Update global accumulated interest index.
            updateGlobalRewardIndex();
            node.accumulatedRewards = getNodeRewardTokens(_nodeAddr);
            node.accumulatedRewardIndex = accumulatedRewardIndex;
            delegator.accumulatedRewards = getDelegatorRewardTokens(msg.sender, _nodeAddr);
            delegator.accumulatedRewardIndex = accumulatedRewardIndex;
        }
        delegator.delegatedAmount = delegator.delegatedAmount.add(_tokenAmount);
        if (delegator.delegatedNode == address(0)) {
            // New delegation
            delegator.delegatedNode = _nodeAddr;
            delegator.releaseTime[LISTHEAD] = LISTHEAD;
        }
        // This would change interest rate
        totalStakedTokens = totalStakedTokens.add(_tokenAmount);
        ERC20I(DOSTOKEN).transferFrom(msg.sender, address(this), _tokenAmount);
        emit Delegate(msg.sender, _nodeAddr, _tokenAmount);
    }

    function nodeUnregister(address _nodeAddr) public {
        require(nodeRunners[msg.sender][_nodeAddr], "node-not-owned-by-msgSender");
        Node storage node = nodes[_nodeAddr];
        nodeStopInternal(_nodeAddr);
        nodeUnbondInternal(node.selfStakedAmount, node.stakedDB, _nodeAddr);
    }

    function nodeTryDelete(address _nodeAddr) internal {
        if (!nodes[_nodeAddr].running &&
            nodes[_nodeAddr].selfStakedAmount == 0 &&
            nodes[_nodeAddr].stakedDB == 0 &&
            nodes[_nodeAddr].totalOtherDelegatedAmount == 0 &&
            nodes[_nodeAddr].accumulatedRewards == 0 &&
            nodes[_nodeAddr].nodeDelegators.length == 0 &&
            nodes[_nodeAddr].pendingWithdrawToken == 0 &&
            nodes[_nodeAddr].pendingWithdrawDB == 0
        ) {
            delete nodeRunners[nodes[_nodeAddr].ownerAddr][_nodeAddr];
            delete nodes[_nodeAddr];
            for (uint idx = 0; idx < nodeAddrs.length; idx++) {
                if (nodeAddrs[idx] == _nodeAddr) {
                    nodeAddrs[idx] = nodeAddrs[nodeAddrs.length - 1];
                    nodeAddrs.length--;
                    return;
                }
            }
        }
    }
    // Used by node runners to unbond their stakes.
    // Unbonded tokens are locked for 7 days, during the unbonding period they're not eligible for staking rewards.
    function nodeUnbond(uint _tokenAmount, uint _dropburnAmount, address _nodeAddr) public {
        require(nodeRunners[msg.sender][_nodeAddr], "node-not-owned-by-msgSender");
        Node storage node = nodes[_nodeAddr];

        require(_tokenAmount <= node.selfStakedAmount, "invalid-to-unbond-more-than-staked-amount");
        require(_dropburnAmount <= node.stakedDB, "invalid-to-unbond-more-than-staked-DropBurn-amount");
        require(node.selfStakedAmount.sub(_tokenAmount) >=
                minStakePerNode.mul(10.sub(DSMath.min(node.stakedDB.sub(_dropburnAmount), dropburnMaxQuota))).div(10),
                "invalid-unbond-to-maintain-staking-requirement");
        nodeUnbondInternal(_tokenAmount, _dropburnAmount, _nodeAddr);
    }
    // Used by node runners to unbond their stakes.
    // Unbonded tokens are locked for 7 days, during the unbonding period they're not eligible for staking rewards.
    function nodeUnbondInternal(uint _tokenAmount, uint _dropburnAmount, address _nodeAddr) internal {
        require(nodeRunners[msg.sender][_nodeAddr], "node-not-owned-by-msgSender");
        Node storage node = nodes[_nodeAddr];
        if (node.running) {
            updateGlobalRewardIndex();
            node.accumulatedRewards = getNodeRewardTokens(_nodeAddr);
            node.accumulatedRewardIndex = accumulatedRewardIndex;
        }
        // This would change interest rate
        totalStakedTokens = totalStakedTokens.sub(_tokenAmount);
        node.selfStakedAmount = node.selfStakedAmount.sub(_tokenAmount);
        node.pendingWithdrawToken = node.pendingWithdrawToken.add(_tokenAmount);
        node.stakedDB = node.stakedDB.sub(_dropburnAmount);
        node.pendingWithdrawDB = node.pendingWithdrawDB.add(_dropburnAmount);

        if (_tokenAmount > 0 || _dropburnAmount > 0) {
            // create an UnbondRequest
            uint releaseTime = now.add(unbondDuration);
            node.unbondRequests[releaseTime] = UnbondRequest(_tokenAmount, _dropburnAmount);
            node.releaseTime[releaseTime] = node.releaseTime[LISTHEAD];
            node.releaseTime[LISTHEAD] = releaseTime;
        }

        emit Unbond(msg.sender, _nodeAddr, true, _tokenAmount, _dropburnAmount);
    }

    // Used by token holders (delegators) to unbond their delegations.
    function delegatorUnbond(uint _tokenAmount, address _nodeAddr) public {
        Delegation storage delegator = delegators[msg.sender][_nodeAddr];
        require(nodes[_nodeAddr].ownerAddr != address(0), "node-not-exist");
        require(delegator.delegatedNode == _nodeAddr, "invalid-unbond-from-non-delegated-node");
        require(_tokenAmount <= delegator.delegatedAmount, "invalid-unbond-more-than-delegated-amount");
        if (nodes[_nodeAddr].running) {
            updateGlobalRewardIndex();
            delegator.accumulatedRewards = getDelegatorRewardTokens(msg.sender, _nodeAddr);
            delegator.accumulatedRewardIndex = accumulatedRewardIndex;
            nodes[_nodeAddr].accumulatedRewards = getNodeRewardTokens(_nodeAddr);
            nodes[_nodeAddr].accumulatedRewardIndex = accumulatedRewardIndex;
        }
        // This would change interest rate
        totalStakedTokens = totalStakedTokens.sub(_tokenAmount);
        delegator.delegatedAmount = delegator.delegatedAmount.sub(_tokenAmount);
        delegator.pendingWithdraw = delegator.pendingWithdraw.add(_tokenAmount);
        nodes[_nodeAddr].totalOtherDelegatedAmount = nodes[_nodeAddr].totalOtherDelegatedAmount.sub(_tokenAmount);

        if (_tokenAmount > 0) {
            // create a UnbondRequest
            uint releaseTime = now.add(unbondDuration);
            delegator.unbondRequests[releaseTime] = UnbondRequest(_tokenAmount, 0);
            delegator.releaseTime[releaseTime] = delegator.releaseTime[LISTHEAD];
            delegator.releaseTime[LISTHEAD] = releaseTime;
        }

        emit Unbond(msg.sender, _nodeAddr, false, _tokenAmount, 0);
    }

    function withdrawAll(mapping(uint => uint) storage releaseTimeList, mapping(uint => UnbondRequest) storage requestList)
        internal
        returns(uint, uint)
    {
        uint accumulatedDos = 0;
        uint accumulatedDropburn = 0;
        uint prev = LISTHEAD;
        uint curr = releaseTimeList[prev];
        while (curr != LISTHEAD && curr > now) {
            prev = curr;
            curr = releaseTimeList[prev];
        }
        if (releaseTimeList[prev] != LISTHEAD) {
            releaseTimeList[prev] = LISTHEAD;
        }
        // All next items are withdrawable.
        while (curr != LISTHEAD) {
            accumulatedDos = accumulatedDos.add(requestList[curr].dosAmount);
            accumulatedDropburn = accumulatedDropburn.add(requestList[curr].dbAmount);
            prev = curr;
            curr = releaseTimeList[prev];
            delete releaseTimeList[prev];
            delete requestList[prev];
        }
        return (accumulatedDos, accumulatedDropburn);
    }

    /// @dev A view version of above call with equivalent functionality, used by other view functions.
    function withdrawable(mapping(uint => uint) storage releaseTimeList, mapping(uint => UnbondRequest) storage requestList)
        internal
        view
        returns(uint, uint)
    {
        uint accumulatedDos = 0;
        uint accumulatedDropburn = 0;
        uint prev = LISTHEAD;
        uint curr = releaseTimeList[prev];
        while (curr != LISTHEAD && curr > now) {
            prev = curr;
            curr = releaseTimeList[prev];
        }
        // All next items are withdrawable.
        while (curr != LISTHEAD) {
            accumulatedDos = accumulatedDos.add(requestList[curr].dosAmount);
            accumulatedDropburn = accumulatedDropburn.add(requestList[curr].dbAmount);
            prev = curr;
            curr = releaseTimeList[prev];

        }
        return (accumulatedDos, accumulatedDropburn);
    }

    // Node runners call this function to withdraw available unbonded tokens after unbond period.
    function nodeWithdraw(address _nodeAddr) public {
        Node storage node = nodes[_nodeAddr];
        require(node.ownerAddr == msg.sender, "non-owner-not-authorized-to-withdraw");

        (uint tokenAmount, uint dropburnAmount) = withdrawAll(node.releaseTime, node.unbondRequests);
        node.pendingWithdrawToken = node.pendingWithdrawToken.sub(tokenAmount);
        node.pendingWithdrawDB = node.pendingWithdrawDB.sub(dropburnAmount);

        nodeTryDelete(_nodeAddr);

        if (tokenAmount > 0) {
            ERC20I(DOSTOKEN).transfer(msg.sender, tokenAmount);
        }
        if (dropburnAmount > 0) {
            ERC20I(DBTOKEN).transfer(msg.sender, dropburnAmount);
        }
        emit Withdraw(_nodeAddr, msg.sender, true, tokenAmount, dropburnAmount);
    }

    // Delegators call this function to withdraw available unbonded tokens from a specific node after unbond period.
    function delegatorWithdraw(address _nodeAddr) public {
        Delegation storage delegator = delegators[msg.sender][_nodeAddr];
        require(nodes[_nodeAddr].ownerAddr != address(0), "node-not-exist");
        require(delegator.delegatedNode == _nodeAddr, "cannot-withdraw-from-non-delegated-node");

        (uint tokenAmount, ) = withdrawAll(delegator.releaseTime, delegator.unbondRequests);
        if (tokenAmount > 0) {
            delegator.pendingWithdraw = delegator.pendingWithdraw.sub(tokenAmount);
            if (delegator.delegatedAmount == 0 && delegator.pendingWithdraw == 0 && delegator.accumulatedRewards == 0) {
                delete delegators[msg.sender][_nodeAddr];
                uint idx = 0;
                for (; idx < nodes[_nodeAddr].nodeDelegators.length; idx++) {
                    if (nodes[_nodeAddr].nodeDelegators[idx] == msg.sender) {
                        break;
                    }
                }
                if (idx < nodes[_nodeAddr].nodeDelegators.length) {
                    nodes[_nodeAddr].nodeDelegators[idx] = nodes[_nodeAddr].nodeDelegators[nodes[_nodeAddr].nodeDelegators.length - 1];
                    nodes[_nodeAddr].nodeDelegators.length--;
                }
                nodeTryDelete(_nodeAddr);
            }

            ERC20I(DOSTOKEN).transfer(msg.sender, tokenAmount);
        }
        emit Withdraw(_nodeAddr, msg.sender, false, tokenAmount, 0);
    }

    function nodeWithdrawable(address _owner, address _nodeAddr) public view returns(uint, uint) {
        Node storage node = nodes[_nodeAddr];
        if (node.ownerAddr != _owner) return (0, 0);
        return withdrawable(node.releaseTime, node.unbondRequests);
    }

    function delegatorWithdrawable(address _owner, address _nodeAddr) public view returns(uint) {
        Delegation storage delegator = delegators[_owner][_nodeAddr];
        if (delegator.delegatedNode != _nodeAddr) return 0;
        uint tokenAmount = 0;
        (tokenAmount, ) = withdrawable(delegator.releaseTime, delegator.unbondRequests);
        return tokenAmount;
    }

    function nodeClaimReward(address _nodeAddr) public {
        Node storage node = nodes[_nodeAddr];
        require(node.ownerAddr == msg.sender, "non-owner-not-authorized-to-claim");
        updateGlobalRewardIndex();
        uint claimedReward = getNodeRewardTokens(_nodeAddr);
        node.accumulatedRewards = 0;
        node.accumulatedRewardIndex = accumulatedRewardIndex;
        // This would change interest rate
        circulatingSupply = circulatingSupply.add(claimedReward);
        ERC20I(DOSTOKEN).transferFrom(stakingRewardsVault, msg.sender, claimedReward);
        emit ClaimReward(msg.sender, true, claimedReward);
    }

    function delegatorClaimReward(address _nodeAddr) public {
        Delegation storage delegator = delegators[msg.sender][_nodeAddr];
        require(nodes[_nodeAddr].ownerAddr != address(0), "node-not-exist");
        require(delegator.delegatedNode == _nodeAddr, "cannot-claim-from-non-delegated-node");
        updateGlobalRewardIndex();
        uint claimedReward = getDelegatorRewardTokens(msg.sender, _nodeAddr);

        if (delegator.delegatedAmount == 0 && delegator.pendingWithdraw == 0) {
            delete delegators[msg.sender][_nodeAddr];
        } else {
            delegator.accumulatedRewards = 0;
            delegator.accumulatedRewardIndex = accumulatedRewardIndex;
        }
        // This would change interest rate
        circulatingSupply = circulatingSupply.add(claimedReward);
        ERC20I(DOSTOKEN).transferFrom(stakingRewardsVault, msg.sender, claimedReward);
        emit ClaimReward(msg.sender, false, claimedReward);
    }

    function getNodeUptime(address nodeAddr) public view returns(uint) {
        Node storage node = nodes[nodeAddr];
        if (node.running) {
            return now.sub(node.lastStartTime);
        } else {
            return 0;
        }
    }

    // return a percentage in [4.00, 80.00] (400, 8000)
    function getCurrentAPR() public view returns (uint) {
        if (totalStakedTokens == 0) {
            return 8000;
        }
        uint localinverseStakeRatio = circulatingSupply.mul(1e4).div(totalStakedTokens);
        if (localinverseStakeRatio > 20 * 1e4) {
            // staking rate <= 5%, APR 80%
            return 8000;
        } else {
            return localinverseStakeRatio.div(25);
        }
    }

    function rewardRateDelta() internal view returns (uint) {
        return now.sub(lastRateUpdatedTime).mul(getCurrentAPR()).mul(1e6).div(ONEYEAR);
    }

    function updateGlobalRewardIndex() internal {
        accumulatedRewardIndex = accumulatedRewardIndex.add(rewardRateDelta());
        lastRateUpdatedTime = now;
    }

    function getNodeRewardsCore(Node storage _n, uint _indexRT) internal view returns(uint) {
        if (!_n.running) return _n.accumulatedRewards;
        return
            _n.accumulatedRewards.add(
                _n.selfStakedAmount.add(_n.totalOtherDelegatedAmount.mul(_n.rewardCut).div(100)).mul(
                    _indexRT.sub(_n.accumulatedRewardIndex)
                ).div(1e10)
            );
    }

    function getDelegatorRewardsCore(Node storage _n, Delegation storage _d, uint _indexRT) internal view returns(uint) {
        if (!_n.running) return _d.accumulatedRewards;
        return
            _d.accumulatedRewards.add(
                _d.delegatedAmount.mul(100.sub(_n.rewardCut)).div(100).mul(
                    _indexRT.sub(_d.accumulatedRewardIndex)
                ).div(1e10)
            );
    }

    function getNodeRewardTokens(address _nodeAddr) internal view returns(uint) {
        return getNodeRewardsCore(nodes[_nodeAddr], accumulatedRewardIndex);
    }

    /// @dev returns realtime node staking rewards without any state change (specifically the global accumulatedRewardIndex)
    function getNodeRewardTokensRT(address _nodeAddr) public view returns(uint) {
        uint indexRT = accumulatedRewardIndex.add(rewardRateDelta());
        return getNodeRewardsCore(nodes[_nodeAddr], indexRT);
    }

    function getDelegatorRewardTokens(address _delegator, address _nodeAddr) internal view returns(uint) {
        return getDelegatorRewardsCore(nodes[_nodeAddr], delegators[_delegator][_nodeAddr], accumulatedRewardIndex);
    }

    /// @dev returns realtime delegator's staking rewards without any state change (specifically the global accumulatedRewardIndex)
    function getDelegatorRewardTokensRT(address _delegator, address _nodeAddr) public view returns(uint) {
        uint indexRT = accumulatedRewardIndex.add(rewardRateDelta());
        return getDelegatorRewardsCore(nodes[_nodeAddr], delegators[_delegator][_nodeAddr], indexRT);
    }
}