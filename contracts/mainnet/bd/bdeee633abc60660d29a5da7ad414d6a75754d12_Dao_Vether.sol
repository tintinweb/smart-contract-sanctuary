// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

interface iERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}
interface iROUTER {
    function isPool(address) external view returns(bool);
}
interface iPOOL {
    function TOKEN() external view returns(address);
    function transferTo(address, uint) external returns (bool);
}
interface iUTILS {
    function calcShare(uint part, uint total, uint amount) external pure returns (uint share);
    function getPoolShare(address token, uint units) external view returns(uint baseAmt);
}
interface iBASE {
    function changeIncentiveAddress(address) external returns(bool);
    function changeDAO(address) external returns(bool);
}

// SafeMath
library SafeMath {

    function add(uint a, uint b) internal pure returns (uint)   {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


contract Dao_Vether {

    using SafeMath for uint;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    address public DEPLOYER;

    address public BASE;

    uint256 public totalWeight;
    uint public one = 10**18;
    uint public coolOffPeriod = 1 * 2;
    uint public blocksPerDay = 5760;
    uint public daysToEarnFactor = 10;
    uint public FUNDS_CAP = one * 50000;

    address public proposedDao;
    bool public proposedDaoChange;
    uint public daoChangeStart;
    bool public daoHasMoved;
    address public DAO;

    address public proposedRouter;
    bool public proposedRouterChange;
    uint public routerChangeStart;
    bool public routerHasMoved;
    iROUTER private _ROUTER;

    address public proposedUtils;
    bool public proposedUtilsChange;
    uint public utilsChangeStart;
    bool public utilsHasMoved;
    iUTILS private _UTILS;

    address[] public arrayMembers;
    mapping(address => bool) public isMember; // Is Member
    mapping(address => mapping(address => uint256)) public mapMemberPool_Balance; // Member's balance in pool
    mapping(address => uint256) public mapMember_Weight; // Value of weight
    mapping(address => mapping(address => uint256)) public mapMemberPool_Weight; // Value of weight for pool
    mapping(address => uint256) public mapMember_Block;

    mapping(address => uint256) public mapAddress_Votes; 
    mapping(address => mapping(address => uint256)) public mapAddressMember_Votes; 

    uint public ID;
    mapping(uint256 => string) public mapID_Type;
    mapping(uint256 => uint256) public mapID_Value;
    mapping(uint256 => uint256) public mapID_Votes; 
    mapping(uint256 => uint256) public mapID_Start; 
    mapping(uint256 => mapping(address => uint256)) public mapIDMember_Votes; 

    event MemberLocks(address indexed member,address indexed pool,uint256 amount);
    event MemberUnlocks(address indexed member,address indexed pool,uint256 balance);
    event MemberRegisters(address indexed member,address indexed pool,uint256 amount);

    event NewVote(address indexed member,address indexed proposedAddress, uint voteWeight, uint totalVotes, string proposalType);
    event ProposalFinalising(address indexed member,address indexed proposedAddress, uint timeFinalised, string proposalType);
    event NewAddress(address indexed member,address indexed newAddress, uint votesCast, uint totalWeight, string proposalType);

    event NewVoteParam(address indexed member,uint indexed ID, uint voteWeight, uint totalVotes, string proposalType);
    event ParamProposalFinalising(address indexed member,uint indexed ID, uint timeFinalised, string proposalType);
    event NewParam(address indexed member,uint indexed ID, uint votesCast, uint totalWeight, string proposalType);

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    // Only Deployer can execute
    modifier onlyDeployer() {
        require(msg.sender == DEPLOYER, "DeployerErr");
        _;
    }

    constructor () public payable {
        BASE = 0x4Ba6dDd7b89ed838FEd25d208D4f644106E34279;
        DEPLOYER = msg.sender;
        _status = _NOT_ENTERED;
    }
    function setGenesisAddresses(address _router, address _utils) public onlyDeployer {
        _ROUTER = iROUTER(_router);
        _UTILS = iUTILS(_utils);
    }
    function setGenesisFactors(uint _coolOff, uint _blocksPerDay, uint _daysToEarn) public onlyDeployer {
        coolOffPeriod = _coolOff;
        blocksPerDay = _blocksPerDay;
        daysToEarnFactor = _daysToEarn;
    }
    function setCap(uint _fundsCap) public onlyDeployer {
        FUNDS_CAP = _fundsCap;
    }

    function purgeDeployer() public onlyDeployer {
        DEPLOYER = address(0);
    }

    //============================== USER - LOCK/UNLOCK ================================//
    // Member locks some LP tokens
    function lock(address pool, uint256 amount) public nonReentrant {
        require(_ROUTER.isPool(pool) == true, "Must be listed");
        require(amount > 0, "Must get some");
        if (!isMember[msg.sender]) {
            mapMember_Block[msg.sender] = block.number;
            arrayMembers.push(msg.sender);
            isMember[msg.sender] = true;
        }
        require(iPOOL(pool).transferTo(address(this), amount),"Must transfer"); // Uni/Bal LP tokens return bool
        mapMemberPool_Balance[msg.sender][pool] = mapMemberPool_Balance[msg.sender][pool].add(amount); // Record total pool balance for member
        registerWeight(msg.sender, pool); // Register weight
        emit MemberLocks(msg.sender, pool, amount);
    }

    // Member unlocks all from a pool
    function unlock(address pool) public nonReentrant {
        uint256 balance = mapMemberPool_Balance[msg.sender][pool];
        require(balance > 0, "Must have a balance to weight");
        reduceWeight(pool, msg.sender);
        if(mapMember_Weight[msg.sender] == 0 && iERC20(BASE).balanceOf(address(this)) > 0){
            harvest();
        }
        require(iERC20(pool).transfer(msg.sender, balance), "Must transfer"); // Then transfer
        emit MemberUnlocks(msg.sender, pool, balance);
    }

    // Member registers weight in a single pool
    function registerWeight(address member, address pool) internal {
        uint weight = updateWeight(pool, member);
        emit MemberRegisters(member, pool, weight);
    }

    function updateWeight(address pool, address member) public returns(uint){
        if(mapMemberPool_Weight[member][pool] > 0){
            totalWeight = totalWeight.sub(mapMemberPool_Weight[member][pool]); // Remove previous weights
            mapMember_Weight[member] = mapMember_Weight[member].sub(mapMemberPool_Weight[member][pool]);
            mapMemberPool_Weight[member][pool] = 0;
        }
        uint weight = _UTILS.getPoolShare(iPOOL(pool).TOKEN(), mapMemberPool_Balance[msg.sender][pool] );
        mapMemberPool_Weight[member][pool] = weight;
        mapMember_Weight[member] += weight;
        totalWeight += weight;
        return weight;
    }
    function reduceWeight(address pool, address member) internal {
        uint weight = mapMemberPool_Weight[member][pool];
        mapMemberPool_Balance[member][pool] = 0; // Zero out balance
        mapMemberPool_Weight[member][pool] = 0; // Zero out weight
        totalWeight = totalWeight.sub(weight); // Remove that weight
        mapMember_Weight[member] = mapMember_Weight[member].sub(weight); // Reduce weight
    }

    //============================== GOVERNANCE ================================//


    // Member votes new Router
    function voteAddressChange(address newAddress, string memory typeStr) public nonReentrant returns (uint voteWeight) {
        bytes memory _type = bytes(typeStr);
        require(sha256(_type) == sha256('DAO') || sha256(_type) == sha256('ROUTER') || sha256(_type) == sha256('UTILS'));
        voteWeight = countVotes(newAddress);
        updateAddressChange(newAddress, _type);
        emit NewVote(msg.sender, newAddress, voteWeight, mapAddress_Votes[newAddress], string(_type));
    }

    function updateAddressChange(address _newAddress, bytes memory _type) internal {
        if(hasQuorum(_newAddress)){
            if(sha256(_type) == sha256('DAO')){
                updateDao(_newAddress);
            } else if (sha256(_type) == sha256('ROUTER')) {
                updateRouter(_newAddress);
            } else if (sha256(_type) == sha256('UTILS')){
                updateUtils(_newAddress);
            }
            emit ProposalFinalising(msg.sender, _newAddress, now+coolOffPeriod, string(_type));
        }
    }

    function moveAddress(string memory _typeStr) public nonReentrant {
        bytes memory _type = bytes(_typeStr);
        if(sha256(_type) == sha256('DAO')){
            moveDao();
        } else if (sha256(_type) == sha256('ROUTER')) {
            moveRouter();
        } else if (sha256(_type) == sha256('UTILS')){
            moveUtils();
        }
    }

    function updateDao(address _address) internal {
        proposedDao = _address;
        proposedDaoChange = true;
        daoChangeStart = now;
    }
    function moveDao() internal {
        require(proposedDao != address(0), "No DAO proposed");
        require((now - daoChangeStart) > coolOffPeriod, "Must be pass cool off");
        if(!hasQuorum(proposedDao)){
            proposedDaoChange = false;
        }
        if(proposedDaoChange){
            uint reserve = iERC20(BASE).balanceOf(address(this));
            iERC20(BASE).transfer(proposedDao, reserve);
            daoHasMoved = true;
            DAO = proposedDao;
            emit NewAddress(msg.sender, proposedDao, mapAddress_Votes[proposedDao], totalWeight, 'DAO');
            mapAddress_Votes[proposedDao] = 0;
            proposedDao = address(0);
            proposedDaoChange = false;
        }
    }

    function updateRouter(address _address) internal {
        proposedRouter = _address;
        proposedRouterChange = true;
        routerChangeStart = now;
        routerHasMoved = false;
    }
    function moveRouter() internal {
        require(proposedRouter != address(0), "No router proposed");
        require((now - routerChangeStart) > coolOffPeriod, "Must be pass cool off");
        if(!hasQuorum(proposedRouter)){
            proposedRouterChange = false;
        }
        if(proposedRouterChange){
            _ROUTER = iROUTER(proposedRouter);
            routerHasMoved = true;
            emit NewAddress(msg.sender, proposedRouter, mapAddress_Votes[proposedRouter], totalWeight, 'ROUTER');
            mapAddress_Votes[proposedRouter] = 0;
            proposedRouter = address(0);
            proposedRouterChange = false;
        }
    }

    function updateUtils(address _address) internal {
        proposedUtils = _address;
        proposedUtilsChange = true;
        utilsChangeStart = now;
        utilsHasMoved = false;
    }
    function moveUtils() internal {
        require(proposedUtils != address(0), "No utils proposed");
        require((now - routerChangeStart) > coolOffPeriod, "Must be pass cool off");
        if(!hasQuorum(proposedUtils)){
            proposedUtilsChange = false;
        }
        if(proposedUtilsChange){
            _UTILS = iUTILS(proposedUtils);
            utilsHasMoved = true;
            emit NewAddress(msg.sender, proposedUtils, mapAddress_Votes[proposedUtils], totalWeight, 'UTILS');
            mapAddress_Votes[proposedUtils] = 0;
            proposedUtils = address(0);
            proposedUtilsChange = false;
        }
    }

    //============================== GOVERNANCE ================================//

    function newProposal(uint value, string memory typeStr) public {
        bytes memory _type = bytes(typeStr);
        require(sha256(_type) == sha256('FUNDS') || sha256(_type) == sha256('DAYS') || sha256(_type) == sha256('COOL'));
        mapID_Type[ID] = typeStr;
        mapID_Value[ID] = value;
        voteIDChange(ID);
        ID +=1;
    }

    function voteIDChange(uint _ID) public nonReentrant returns (uint voteWeight) {
        voteWeight = countVotesID(_ID);
        updateIDChange(_ID);
        emit NewVoteParam(msg.sender, _ID, voteWeight, mapID_Votes[_ID], mapID_Type[_ID]);
    }

    function updateIDChange(uint _ID) internal {
        if(hasQuorumID(_ID)){
            mapID_Start[_ID] = now;
            emit ParamProposalFinalising(msg.sender, ID, now+coolOffPeriod, mapID_Type[ID]);
        }
    }

    function executeID(uint _ID) public nonReentrant {
        bytes memory _type = bytes(mapID_Type[_ID]);
        if(sha256(_type) == sha256('FUNDS')){
            FUNDS_CAP = mapID_Value[_ID];
        } else if (sha256(_type) == sha256('DAYS')) {
            daysToEarnFactor = mapID_Value[_ID];
        } else if (sha256(_type) == sha256('COOL')){
            coolOffPeriod = mapID_Value[_ID];
        }
        emit NewParam(msg.sender, ID, mapID_Votes[_ID], totalWeight, mapID_Type[_ID]);
    }

    //============================== CONSENSUS ================================//

    function countVotes(address _address) internal returns (uint voteWeight){
        mapAddress_Votes[_address] = mapAddress_Votes[_address].sub(mapAddressMember_Votes[_address][msg.sender]);
        voteWeight = mapMember_Weight[msg.sender];
        mapAddress_Votes[_address] += voteWeight;
        mapAddressMember_Votes[_address][msg.sender] = voteWeight;
        return voteWeight;
    }

    function hasQuorum(address _address) public view returns(bool){
        uint votes = mapAddress_Votes[_address];
        uint consensus = totalWeight.div(2);
        if(votes > consensus){
            return true;
        } else {
            return false;
        }
    }

    function countVotesID(uint _ID) internal returns (uint voteWeight){
        mapID_Votes[_ID] = mapID_Votes[_ID].sub(mapIDMember_Votes[_ID][msg.sender]);
        voteWeight = mapMember_Weight[msg.sender];
        mapID_Votes[_ID] += voteWeight;
        mapIDMember_Votes[_ID][msg.sender] = voteWeight;
        return voteWeight;
    }

    function hasQuorumID(uint _ID) public view returns(bool){
        uint votes = mapID_Votes[_ID];
        uint consensus = totalWeight.div(2);
        if(votes > consensus){
            return true;
        } else {
            return false;
        }
    }

    // //============================== _ROUTER ================================//

    function ROUTER() public view returns(iROUTER){
        if(daoHasMoved){
            return Dao_Vether(DAO).ROUTER();
        } else {
            return _ROUTER;
        }
    }

    function UTILS() public view returns(iUTILS){
        if(daoHasMoved){
            return Dao_Vether(DAO).UTILS();
        } else {
            return _UTILS;
        }
    }

    //============================== REWARDS ================================//
    // Rewards
    function harvest() public nonReentrant {
        uint reward = calcCurrentReward(msg.sender);
        mapMember_Block[msg.sender] = block.number;
        iERC20(BASE).transfer(msg.sender, reward);
    }

    function calcCurrentReward(address member) public view returns(uint){
        uint blocksSinceClaim = block.number.sub(mapMember_Block[member]);
        uint share = calcReward(member);
        uint reward = share.mul(blocksSinceClaim).div(blocksPerDay);
        uint reserve = iERC20(BASE).balanceOf(address(this));
        if(reward >= reserve) {
            reward = reserve;
        }
        return reward;
    }

    function calcReward(address member) public view returns(uint){
        uint weight = mapMember_Weight[member];
        uint reserve = iERC20(BASE).balanceOf(address(this)).div(daysToEarnFactor);
        return _UTILS.calcShare(weight, totalWeight, reserve);
    }

}