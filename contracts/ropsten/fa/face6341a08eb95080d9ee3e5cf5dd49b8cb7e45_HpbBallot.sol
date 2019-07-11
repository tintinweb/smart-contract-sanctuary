/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.4.26;
contract AdminInterface {

    function addCandidate(address _candidateAddr, bytes32 _name) public;

    function deleteCandidate(address _candidateAddr) public;

    function updateCandidateAddr(address _oldCandidateAddr, address _newCandidateAddr) public;

    function setCapacity(uint _capacity) public;

    function calVoteResult() public;

}
contract VoteInterface {

    /**
     * 投票  
     */
    function  vote(address voterAddr,address candidateAddr, uint num) public ;

    /**
     * 用于批量投票  For non locked voting
     */
    function  batchVote(address voterAddr,address[] candidateAddrs, uint[] nums) public;

    /**
     * 撤回对某个候选人的投票 Withdraw a vote on a candidate.
     */
    function cancelVoteForCandidate(address voterAddr,address candidateAddr, uint num) public ;

	function refreshVoteForAll() public;
}
contract FetchVoteInterface {

    /**
     * 获取所有候选人的详细信息
     * Get detailed information about all candidates.
     */
    function fetchAllCandidates() public view returns (address[] addrs, bytes32[] names);

    /**
     * 获取所有投票人的详细信息
     */
    function fetchAllVoters() public view returns (address[] voterAddrs, uint[] voteNumbers);

    /**
     * 获取所有投票人的投票情况
     */
    function fetchVoteInfoForVoter(address voterAddr) public view returns (address[] addrs, uint[] nums);

    /**
     * 获取某个候选人的总得票数
     * Total number of votes obtained from candidates
     */
    function fetchVoteNumForCandidate(address candidateAddr) public view returns (uint num);

    /**
     * 获取某个投票人已投票数
     * Total number of votes obtained from voterAddr
     */
    function fetchVoteNumForVoter(address voterAddr) public view returns (uint num);

    /**
     * 获取某个候选人被投票详细情况
     */
    function fetchVoteInfoForCandidate(address candidateAddr) public view returns (address[] addrs, uint[] nums);

    /**
     * 获取所有候选人的得票情况
     */
    function fetchAllResult() public view returns (address[] addrs, uint[] nums);

    /**
     * 返回给节点的投票数据
     */
    function fetchAllVoteResultForNodes(uint _block) public view returns (uint fromBlock, uint toBlock,
       address[] addrs,
       uint[] nums);
}
contract Ownable {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        // Do not forget the "_;"! It will be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
    // 合约管理员，可以添加和删除候选人
    mapping (address => address) public adminMap;

    modifier onlyAdmin {
        require(adminMap[msg.sender] != 0);
        _;
    }

    function addAdmin(address addr) onlyOwner public {
        require(adminMap[addr] == 0);
        adminMap[addr] = addr;
    }

    function deleteAdmin(address addr) onlyOwner public {
        require(adminMap[addr] != 0);
        adminMap[addr] = 0;
    }

}
library SafeMath {

    /**
	 * @dev Multiplies two numbers, throws on overflow.
	 */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero,
		// but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
	 * @dev Integer division of two numbers, truncating the quotient.
	 */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t
		// hold
        return a / b;
    }

    /**
	 * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is
	 *      greater than minuend).
	 */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
	 * @dev Adds two numbers, throws on overflow.
	 */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
contract HpbBallot is Ownable ,AdminInterface,VoteInterface,FetchVoteInterface {
    using SafeMath for uint256;

    // 候选者的结构体
    // Candidate struct
    struct Candidate {
        // 候选人账户地址
        // Candidate account address
        address candidateAddr;
        // 候选人名称
        // Name of candidate
        bytes32 name;
        // 得票数
        // Number of votes
        uint voteNumber;
        // 对候选者投票的投票者数组，用于遍历用途
        // An array of voters for the candidates to be used for traversal.
        address[] voterMapAddrs;
        // 已经投票了投票人账户地址-》下标
        mapping (address => uint) voterMapAddrsIndex;

        // 已经投票了投票人账户地址-》投票数
        // The voting address of voters has been voted
        mapping (address => uint) voterMap;

    }

    // 投票结构体
    // Voting structure
    struct Voter {
        // 投票人的账户地址
        // Address of voters
        address voterAddr;
        // 投票人已经投票数(实际投票数)
        // Voters have voted number.
        uint voteNumber;

        // 用于遍历投票了的候选者用途
        // Candidate use for traversing voting
        address[] candidateMapAddrs;
        // 已经投票了的候选者账户地址-》下标
        mapping (address => uint) candidateMapAddrsIndex;
        // 已经投票了的候选者账户地址-》投票数
        // The candidate&#39;s account address has been voted
        mapping (address => uint) candidateMap;

    }

    // 候选者的数组
    // An array of candidates
    Candidate[] candidateArray;

    /*
	 * 候选者的地址与以上变量候选者数组（candidateArray）索引(数组下标)对应关系,用于查询候选者用途
	 * 这样可以降低每次遍历对象对gas的消耗，存储空间申请和申请次数远远小于查询次数，并且计票步骤更加复杂，相比较消耗gas更多 The address
	 * of the candidate corresponds to the index (array subscript) of the
	 * candidate array of variables above for the purpose of querying candidates
	 * This reduces the consumption of gas for each traversal object, reduces
	 * the number of requests and requests for storage space far less than the
	 * number of queries,and makes the counting step more complex than consuming
	 * gas.
	 */
    mapping (address => uint) candidateIndexMap;

    // 投票者数组
    // An array of voters
    Voter[] voterArray;

    // 投票者的地址与投票者序号（voterArray下标）对应关系，便于查询和减少gas消耗
    // The voter&#39;s address corresponds to the voter&#39;s ordinal number (voter Array subscript),
    // making it easy to query and reduce gas consumption
    mapping (address => uint) voterIndexMap;

    // 最终获选者总数（容量，获选者数量上限）
    // the total number of final winners (capacity, the upper limit of the number of candidates selected)
    uint public capacity=105;

    // 竞选准备阶段
    bool public isRunUp=true;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    mapping (address => bool) private _useCustomOperator;
    
    address private _defaultOperator;
    
    // 最小投票额：0.1票,可外部设置
    uint public minLimit=100 finney;

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    // 增加候选者
    // add candidate
    event CandidateAdded(address indexed candidateAddr,bytes32 name);

    // 更新候选者名称
    // update candidate
    event UpdateCandidateName(address indexed candidateAddr,bytes32 name);

    // 删除候选者
    // delete candidate
    event CandidateDeleted(address indexed candidateAddr);

    event UpdateCandidateAddr(address indexed _oldCandidateAddr,address indexed _newCandidateAddr);
    // 投票
    // vote flag=1为投票,flag=0为撤票
    event DoVoted(address indexed voteAddr,address indexed candidateAddr,uint indexed flag,uint num);

    // 记录发送HPB的发送者地址和发送的金额
    // Record the sender address and the amount sent to send HPB.
    event ReceivedHpb(address indexed sender, uint amount);

    // 接受HPB转账
    // Accept HPB transfer
    function () payable external {
        emit ReceivedHpb(msg.sender, msg.value);
    }

    // 销毁合约，并把合约余额返回给合约拥有者
    function kill() onlyOwner public {
        selfdestruct(owner);
    }

    function withdraw(uint _value) onlyOwner payable public {
        require(address(this).balance >= _value);
        owner.transfer(_value);
    }

    /**
	 * @dev Tells whether an operator is approved by a given voter address
	 * @param voterAddr voter address which you want to query the approval of
	 * @param operator operator address which you want to query the approval of
	 * @return bool whether the given operator is approved by the given voter address
	 */
    function isApproved(address voterAddr, address operator) public view returns (bool) {
        if (voterAddr == operator) {
            return true;
        } else if (_useCustomOperator[voterAddr]) {
            return _operatorApprovals[voterAddr][operator];
        } else {
            return operator == _defaultOperator;
        }
    }

    modifier onlyApproved(address voterAddr) {
        require(isApproved(voterAddr, msg.sender));
        _;
    }

    /**
	 * @dev Sets or unsets the approval of a given operator An operator is
	 *      allowed to transfer all tokens of the sender on their behalf
	 * @param to operator address to set the approval
	 * @param approved representing the status of the approval to be set
	 */
    function setApproval(address to, bool approved) public {
        require(to != msg.sender);
        _useCustomOperator[msg.sender] = true;
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function setMinLimit(uint _minLimit) onlyAdmin public {
        minLimit = _minLimit;
    }

    function setDefaultOperator(address defaultOperator) onlyAdmin public {
        require(_defaultOperator != msg.sender);
        _defaultOperator = defaultOperator;
        adminMap[_defaultOperator] = _defaultOperator;
    }

    /**
	 * Constructor function 构造函数 初始化投票智能合约的部分依赖参数
	 */
    constructor () payable public {
        owner = msg.sender;
        // 设置默认管理员
        adminMap[owner] = owner;
        // 设置第一位置
        // Set the first position.
        voterArray.push(Voter(msg.sender, 0, new address[](0)));

        // 设置第一位置
        // Set the first position.
        candidateArray.push(Candidate(msg.sender, 0, 0, new address[](0)));
    }

    function setCapacity(uint _capacity) onlyAdmin public {
        capacity = _capacity;
    }

    /**
	 * 增加候选者 add Candidate
	 * 
	 * @param _candidateAddr Candidate account address for return bond (HPB)
	 * @param _name 候选者名称 Candidate name
	 * 
	 */
    function addCandidate(address _candidateAddr, bytes32 _name) onlyAdmin public {
        require(isRunUp); // 必须是竞选准备阶段
        uint index =candidateIndexMap[_candidateAddr];
        // 必须候选人地址还未使用
        require(index == 0);
        // 添加候选人
        index =candidateArray.push(Candidate(_candidateAddr, _name, 0, new address[](0)))-1;
        candidateIndexMap[_candidateAddr] = index;
        //占用第一个位置
        candidateArray[index].voterMapAddrs.push(msg.sender);
        emit CandidateAdded(_candidateAddr, _name);
    }

    /**
	 * 删除候选者
	 * 
	 * @param _candidateAddr 候选者账户地址 Candidate account address
	 */
    function deleteCandidate(address _candidateAddr) onlyAdmin public {
        require(isRunUp); // 必须是竞选准备阶段
        uint index=candidateIndexMap[_candidateAddr];
        require(index != 0);
        // 删除该候选者对应的投票者关联的候选者信息
        for (uint n=1;n<candidateArray[index].voterMapAddrs.length;n++) {
            // 得到投票者 get voter
            uint voterIndex = voterIndexMap[candidateArray[index].voterMapAddrs[n]];
            uint cIndex=voterArray[voterIndex].candidateMapAddrsIndex[_candidateAddr];
            // 遍历对应投票者里面的候选者信息，并删除其中对应的该候选者
            for (uint k=cIndex;k < voterArray[voterIndex].candidateMapAddrs.length - 1;k++) {
                voterArray[voterIndex].candidateMapAddrs[k] = voterArray[voterIndex].candidateMapAddrs[k+1];
                voterArray[voterIndex].candidateMapAddrsIndex[voterArray[voterIndex].candidateMapAddrs[k]]=k;
            }
            // 撤回已经投的票
            voterArray[voterIndex].voteNumber = voterArray[voterIndex].voteNumber.
            	sub(voterArray[voterIndex].candidateMap[_candidateAddr]);
            voterArray[voterIndex].candidateMap[_candidateAddr] = 0;
            voterArray[voterIndex].candidateMapAddrsIndex[_candidateAddr] = 0;

            delete voterArray[voterIndex].candidateMapAddrs[voterArray[voterIndex].candidateMapAddrs.length - 1];
            voterArray[voterIndex].candidateMapAddrs.length--;
        }

        for (uint i = index;i < candidateArray.length - 1;i++) {
            candidateArray[i] = candidateArray[i+1];
            candidateIndexMap[candidateArray[i].candidateAddr]=i;
        }
        candidateIndexMap[_candidateAddr] = 0;
        delete candidateArray[candidateArray.length - 1];
        candidateArray.length--;
        emit CandidateDeleted(_candidateAddr);
    }

    function updateCandidateAddr(address _oldCandidateAddr, address _newCandidateAddr) onlyAdmin public {
        // 判断候选人是否已经存在 Judge whether candidates exist.
        uint index =candidateIndexMap[_oldCandidateAddr];
        require(index != 0);
        candidateArray[index].candidateAddr = _newCandidateAddr;
        candidateIndexMap[_newCandidateAddr] = index;
        candidateIndexMap[_oldCandidateAddr] = 0;
        // 该候选者对应的投票者信息
        for (uint n=1;n < candidateArray[index].voterMapAddrs.length;n++) {
            // 得到投票者 get voter
            uint voterIndex = voterIndexMap[candidateArray[index].voterMapAddrs[n]];
            uint voterNum =voterArray[voterIndex].candidateMap[_oldCandidateAddr];
            voterArray[voterIndex].candidateMap[_newCandidateAddr] = voterNum;
            voterArray[voterIndex].candidateMap[_oldCandidateAddr] = 0;
            uint cIndex=voterArray[voterIndex].candidateMapAddrsIndex[_oldCandidateAddr];
            voterArray[voterIndex].candidateMapAddrs[cIndex] = _newCandidateAddr;
            voterArray[voterIndex].candidateMapAddrsIndex[_newCandidateAddr] = cIndex;
            voterArray[voterIndex].candidateMapAddrsIndex[_oldCandidateAddr] = 0;
        }
        emit UpdateCandidateAddr(_oldCandidateAddr, _newCandidateAddr);
    }

    /**
	 * 投票
	 */
    function  vote(
        address voterAddr, 
        address candidateAddr,
        uint num
    ) onlyApproved(voterAddr) public {
        _internalVote(voterAddr, candidateAddr, num);
        // 刷新所有的投票结果
        refreshVoteForAll();
    }

    function  _internalVote(address voterAddr, address candidateAddr, 
        uint num) internal {
        // 防止投票短地址攻击
        require(voterAddr != 0);
        require(candidateAddr != 0);

        uint voterAddrSize;
        assembly {voterAddrSize := extcodesize(voterAddr)}
        require(voterAddrSize == 0);

        uint candidateAddrSize;
        assembly {candidateAddrSize := extcodesize(candidateAddr)}
        require(candidateAddrSize == 0);

        uint index=voterIndexMap[voterAddr];
        //如果从没投过票，就添加投票人
        if (index == 0) {
            index =voterArray.push(Voter(voterAddr,0,new address[](0)))-1;
            voterIndexMap[voterAddr]=index;
            voterArray[index].candidateMapAddrs.push(msg.sender);
        }
        //账户余额必须大于已投票数
        require(voterAddr.balance > voterArray[index].voteNumber);
        require(voterAddr.balance.sub(voterArray[index].voteNumber) >= num);
        _doVote(candidateAddr, index, num);
    }

    /**
	 * 用于批量投票 For non locked voting
	 */
    function  batchVote(
        address voterAddr, 
        address[] candidateAddrs,
        uint[] nums
    ) onlyApproved(voterAddr) public {
        for (uint i=0;i < candidateAddrs.length;i++) {
            _internalVote(voterAddr, candidateAddrs[i], nums[i]);
        }
        // 刷新所有的投票结果
        refreshVoteForAll();
    }

    function refreshVoteForAll() public {
        for (uint i = 1;i < voterArray.length;i++) {
            _refreshVoteForVoter(i);
        }
    }

    function _refreshVoteForVoter(uint index) internal {
        uint vvcl=voterArray[index].candidateMapAddrs.length;
        uint balance=voterArray[index].voterAddr.balance;
        uint voteNumber=voterArray[index].voteNumber;
        if (balance < minLimit || balance < voteNumber) {
            for (uint i = 1;i < vvcl;i++) {
                uint _num= voterArray[index].candidateMap[voterArray[index].candidateMapAddrs[i]];
                address _addr= voterArray[index].candidateMapAddrs[i];
                if (_num < minLimit) {
                    _cancelVote(voterArray[index].voterAddr, _addr, _num);
                } else {
                    uint  n_num=balance.mul(1 finney).div(voteNumber).mul(_num).div(1 finney);
                    if (n_num < minLimit) {
                        _cancelVote(voterArray[index].voterAddr, _addr, _num);
                    } else {
                        _cancelVote(voterArray[index].voterAddr, _addr, _num.sub(n_num));
                    }
                }
            }
        }
        if (voterArray[index].voteNumber < minLimit) {
            for (uint k = index;k < voterArray.length - 1;k++) {
                voterArray[k] = voterArray[k+1];
            }
            delete voterArray[voterArray.length - 1];
            voterArray.length--;
            voterIndexMap[voterArray[index].voterAddr] = 0;
        }

    }

    /**
	 * 撤回对某个候选人的投票 Withdraw a vote on a candidate.
	 */
    function cancelVoteForCandidate(
        address voterAddr, 
        address candidateAddr,
        uint num
    ) onlyApproved(voterAddr) public {
        _cancelVote(voterAddr, candidateAddr, num);
    }

    function _cancelVote(
        address voterAddr, 
        address candidateAddr,
        uint num
    ) internal {
        uint index=voterIndexMap[voterAddr];
        // 必须投过票 Tickets must be cast.
        require(index != 0);
        uint candidateIndex=candidateIndexMap[candidateAddr];
        // 候选人必须存在 Candidates must exist
        require(candidateIndex != 0);
        // 必须已投候选者票数不少于取消数量
        uint cnum=voterArray[index].candidateMap[candidateAddr];
        require(cnum >= num);

        // 处理候选者中的投票信息
        candidateArray[candidateIndex].voterMap[voterAddr] = cnum.sub(num);
        if (candidateArray[candidateIndex].voterMap[voterAddr] == 0) {
            // 如果投票数为0，那么删除该候选人中的投票者
            uint vIndex=candidateArray[candidateIndex].voterMapAddrsIndex[voterAddr];
            for (uint k=vIndex;k<candidateArray[candidateIndex].voterMapAddrs.length-1;k++) {
                candidateArray[candidateIndex].voterMapAddrs[k] = 
                	candidateArray[candidateIndex].voterMapAddrs[k+1];
            }
            delete candidateArray[candidateIndex].voterMapAddrs[
                candidateArray[candidateIndex].voterMapAddrs.length - 1
            ];
            candidateArray[candidateIndex].voterMapAddrs.length--;
            candidateArray[candidateIndex].voterMapAddrsIndex[voterAddr] = 0;
        }
        candidateArray[candidateIndex].voteNumber = candidateArray[candidateIndex].voteNumber.sub(num);

        // 处理投票者里面的投票信息
        voterArray[index].candidateMap[candidateAddr] = candidateArray[candidateIndex].voterMap[voterAddr];
        if (voterArray[index].candidateMap[candidateAddr] == 0) {
            // 如果投票数为0，删除投票者对应候选者的信息
            uint cIndex=voterArray[index].candidateMapAddrsIndex[candidateAddr];
            // 遍历对应投票者里面的候选者信息，并删除其中对应的该候选者
            for (uint j=cIndex;j < voterArray[index].candidateMapAddrs.length - 1;j++) {
                voterArray[index].candidateMapAddrs[j] = voterArray[index].candidateMapAddrs[j+1];
            }
            delete voterArray[index].candidateMapAddrs[voterArray[index].candidateMapAddrs.length - 1];
            voterArray[index].candidateMapAddrs.length--;
            voterArray[index].candidateMapAddrsIndex[candidateAddr] = 0;
        }

        voterArray[index].voteNumber = voterArray[index].voteNumber.sub(num);
        // 该操作后，下一轮就不能自动投票
        emit DoVoted(voterAddr, candidateAddr,0,num);
    }

    /**
	 * 执行投票 do vote
	 */
    function _doVote(address candidateAddr, uint index,uint num) internal {
        //不少于允许的最小投票数
        require(num > minLimit);
        uint candidateIndex=candidateIndexMap[candidateAddr];
        // 候选人必须存在 Candidates must exist
        require(candidateIndex != 0);
        
        //尚未投该候选人的票
        if (candidateArray[candidateIndex].voterMapAddrsIndex[voterArray[index].voterAddr] == 0) {
            uint voterIndex=candidateArray[candidateIndex].voterMapAddrs.push(voterArray[index].voterAddr) - 1;
            candidateArray[candidateIndex].voterMapAddrsIndex[voterArray[index].voterAddr] = voterIndex;
            candidateArray[candidateIndex].voterMap[voterArray[index].voterAddr] = num;

            uint cIndex=voterArray[index].candidateMapAddrs.push(candidateAddr) - 1;
            voterArray[index].candidateMapAddrsIndex[candidateAddr] = cIndex;
            voterArray[index].candidateMap[candidateAddr] = num;
        } else {//已经投了该候选人的票
            candidateArray[candidateIndex].voterMap[voterArray[index].voterAddr] = 
            	candidateArray[candidateIndex].voterMap[voterArray[index].voterAddr].add(num);
            voterArray[index].candidateMap[candidateAddr] = voterArray[index].
	        	candidateMap[candidateAddr].add(num);
        }

        // 投票人已投总数累加
        voterArray[index].voteNumber = voterArray[index].voteNumber.add(num);
        // 候选者得票数累加
        candidateArray[candidateIndex].voteNumber = candidateArray[candidateIndex].voteNumber.add(num);

        emit DoVoted(voterArray[index].voterAddr, candidateAddr,1,num);
    }

    /**
	 * 获取所有候选人的详细信息
	 */
    function fetchAllCandidates() public view returns (address[] addrs, bytes32[] names) {
        require(candidateArray.length > 1);
        uint cl=candidateArray.length - 1;
        address[] memory _addrs=new address[](cl);
        bytes32[] memory _names=new bytes32[](cl);
        for (uint i=1;i <= cl;i++) {
            _addrs[i-1] = candidateArray[i].candidateAddr;
            _names[i-1] = candidateArray[i].name;
        }
        return (_addrs, _names);
    }

    /**
	 * 获取所有投票人的详细信息
	 */
    function fetchAllVoters() public view returns (address[] voterAddrs, uint[] voteNumbers) {
        require(voterArray.length > 1);

        uint cl=voterArray.length - 1;
        address[] memory _addrs=new address[](cl);
        uint[] memory _voteNumbers=new uint[](cl);
        for (uint i=1;i <= cl;i++) {
            _addrs[i-1] = voterArray[i].voterAddr;
            _voteNumbers[i-1] = voterArray[i].voteNumber;

        }
        return (_addrs, _voteNumbers);
    }

    /**
	 * 计算选举结果
	 */
    function calVoteResult() onlyAdmin public {
        require(isRunUp); // 必须是竞选准备阶段
        uint candidateLength=candidateArray.length;
        if (candidateLength <= capacity.add(1)) {
            isRunUp = false;
        } else {
            address[] memory _inAddrs=new address[](capacity);
            address[] memory _outAddrs=new address[](candidateLength.sub(1).sub(capacity));
            uint[] memory _nums=new uint[](capacity);
            uint min=candidateArray[1].voteNumber;
            uint minIndex=1;
            for (uint p = 1;p < candidateArray.length;p++) {
                uint outIndex=0;
                if (p <= capacity) {
                    // 先初始化获选者数量池 Initialize the number of pools selected first.
                    _inAddrs[p] = candidateArray[p].candidateAddr;
                    _nums[p] = candidateArray[p].voteNumber;
                    // 先记录获选者数量池中得票最少的记录 Record the number of votes selected in
					// the pool.
                    if (_nums[p] < min) {
                        min = _nums[p];
                        minIndex = p;
                    }
                } else {
                    if (candidateArray[p].voteNumber == min) {
                        // 对于得票相同的，取持币数量多的为当选 For the same votes,
                        // the number of holding currencies is high.
                        if (candidateArray[p].candidateAddr.balance > _inAddrs[minIndex].balance) {
                            _outAddrs[outIndex] = _inAddrs[minIndex];
                            _inAddrs[minIndex] = candidateArray[p].candidateAddr;
                            _nums[minIndex] = candidateArray[p].voteNumber;
                        } else {
                            _outAddrs[outIndex] = candidateArray[p].candidateAddr;
                        }
                    } else if (candidateArray[p].voteNumber > min) {
                        _outAddrs[outIndex] = _inAddrs[minIndex];
                        _inAddrs[minIndex] = candidateArray[p].candidateAddr;
                        _nums[minIndex] = candidateArray[p].voteNumber;
                        // 重新记下最小得票者 Recount the smallest ticket winner
                        min = _nums[0];
                        minIndex = 0;
                        for (uint j=0;j < _inAddrs.length;j++) {
                            if (_nums[j] < min) {
                                min = _nums[j];
                                minIndex = j;
                            }
                        }
                        min = _nums[minIndex];
                    } else {
                        _outAddrs[outIndex] = candidateArray[p].candidateAddr;
                    }
                    outIndex = outIndex.add(1);
                }
            }
            // 删除落选的候选人
            for (uint n=0;n < _outAddrs.length;n++) {
                deleteCandidate(_outAddrs[n]);
            }
            isRunUp = false;
        }
    }


    /**
	 * 获取投票人的投票情况
	 */
    function fetchVoteInfoForVoter(address voterAddr) public view returns (address[] addrs, uint[] nums) {
        uint index = voterIndexMap[voterAddr];
        if (index == 0) { // 没投过票 No vote
            return (new address[](0), new uint[](0));
        }

        uint vvcl=voterArray[index].candidateMapAddrs.length - 1;
        address[] memory _addrs=new address[](vvcl);
        uint[] memory _nums=new uint[](vvcl);
        for (uint i = 1;i <= vvcl;i++) {
            _nums[i-1] = voterArray[index].candidateMap[voterArray[index].candidateMapAddrs[i]];
            _addrs[i-1] = voterArray[index].candidateMapAddrs[i];
        }
        return (_addrs, _nums);
    }

    /**
	 * 获取某个候选人的总得票数 Total number of votes obtained from candidates
	 */
    function fetchVoteNumForCandidate(address candidateAddr) public view returns (uint num) {
        uint index = candidateIndexMap[candidateAddr];
        if (index == 0) { // 没票 No vote
            return 0;
        }
        return candidateArray[index].voteNumber;
    }

    /**
	 * 获取某个投票人已投票数 Total number of votes obtained from voterAddr
	 */
    function fetchVoteNumForVoter(address voterAddr) public view returns (uint num) {
        uint index = voterIndexMap[voterAddr];
        if (index == 0) { // 没投过票 No vote
            return 0;
        }
        return voterArray[index].voteNumber;
    }

    /**
	 * 获取某个候选人被投票详细情况
	 */
    function fetchVoteInfoForCandidate(address candidateAddr) public view returns (address[] addrs, uint[] nums) {
        uint index = candidateIndexMap[candidateAddr];
        require(index > 0);
        // 如果候选人存在,即时更新竞选情况 If candidates exist, update the campaign
		// immediately.
        uint vcvl=candidateArray[index].voterMapAddrs.length - 1;
        address[] memory _addrs=new address[](vcvl);
        uint[] memory _nums=new uint[](vcvl);
        for (uint i=1;i <= vcvl;i++) {
            _nums[i-1] = candidateArray[index].voterMap[candidateArray[index].voterMapAddrs[i]];
            _addrs[i-1] = candidateArray[index].voterMapAddrs[i];
        }
        return (_addrs, _nums);
    }

    /**
	 * 获取所有候选人的得票情况
	 */
    function fetchAllResult() public view returns (address[] addrs, uint[] nums) {
        require(candidateArray.length > 1);
        uint vcl=candidateArray.length - 1;
        address[] memory _addrs=new address[](vcl);
        uint[] memory _nums=new uint[](vcl);
        for (uint i = 1;i <= vcl;i++) {
            _addrs[i-1] = candidateArray[i].candidateAddr;
            _nums[i-1] = candidateArray[i].voteNumber;
        }
        return (_addrs, _nums);
    }

    /**
	 * 返回给节点的投票数据
	 */
    function fetchAllVoteResultForNodes(uint _block) public view returns (
    		uint fromBlock, uint toBlock,address[] addrs,uint[] nums) {
        if (isRunUp) {
            return (0, 0,new address[](0),new uint[](0));
        }
        uint vcl=candidateArray.length - 1;
        address[] memory _addrs=new address[](vcl);
        uint[] memory _nums=new uint[](vcl);
        for (uint i = 1;i <= vcl;i++) {
            _addrs[i-1] = candidateArray[i].candidateAddr;
            _nums[i-1] = candidateArray[i].voteNumber;
        }
        return (_block.sub(200), _block,_addrs,_nums);
    }
}