/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function lucaToFragment(uint256 value) external view returns (uint256);
    function fragmentToLuca(uint256 value) external view returns (uint256);
}

interface IPledge {
    function  modifierLUCAToken(address _lucaToken) external;
    function  addNodeAddr(address[] calldata _nodeAddrs) external;
    function  deleteNodeAddr(address[] calldata _nodeAddrs) external;
    function  modifierLucaFactory(address _lucaFactory) external;
    function  updateExecutor(address _admin) external;
    function  stakeLuca(address _nodeAddr, uint256 _amount) external;
    function  stakeWLuca(address _nodeAddr, uint256 _amount, address _sender) external returns(bool);
    function  cancleStakeLuca(uint256[] calldata _indexs) external;
    function  cancleStakeWLuca(address _sender) external returns(bool);
    function  nodeRank(uint256 start, uint256 end) external;

    event StakeLuca(uint256 indexed _stakeNum, address _userAddr, address _nodeAddr, uint256 _amount, uint256 _time);
    event EndStakeLuca(uint256 indexed _stakeNum, address indexed _userAddr, address _nodeAddr, uint256 _time);
    event StakeWLuca(uint256 indexed _stakeNum, address indexed _userAddr, address _nodeAddr, address _linkAddr, uint256 _amount, uint256 _time);
    event EndStakeWLuca(uint256 indexed _stakeNum, address indexed _userAddr, address _nodeAddr, address _linkAddr, uint256 _time);
}


interface ILucaFactory {
    function isLink(address _link) external view returns(bool);
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Ownable is Initializable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init_unchained() internal initializer {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract  Pledge is Initializable,Ownable,IPledge{
    using SafeMath for uint256;
    address public executor;
    IERC20 public  lucaToken;
    ILucaFactory public lucaFactory;
    uint256 public  mainNodeNum = 11;                     
    uint256 public exchangeRate;
    uint256 public  nodeNum;                           
    mapping(address => uint256) nodeAddrIndex;  
    mapping(uint256 => address) public nodeIndexAddr;  
    mapping(address => uint256) nodeFragmentAmount;     
    mapping(address => uint256) public nodeWLucaAmount;     
    mapping(address => bool) public nodeAddrSta;
    uint256 public  stakeLucaNum;         
    mapping(uint256 => StakeLucaMsg) public stakeLucaMsg;  
    mapping(address => uint256) public userStakeLucaNum;  
    mapping(address => mapping(uint256 => uint256)) public userStakeLucaIndex;
    uint256 public  stakeWLucaNum;          
    mapping(uint256 => StakeWLucaMsg) public stakeWLucaMsg;  
    mapping(address => uint256) public userStakeWLucaNum;  
    mapping(address => mapping(uint256 => uint256)) public userStakeWLucaIndex; 
    mapping(address => mapping(address => uint256)) public userLinkIndex; 
    event UpdateExecutor(address _executor);
    event AddNodeAddr(address _nodeAddr);
    event DeleteNodeAddr(address _nodeAddr);

    struct StakeNodeMsg {
        uint256 fragment;  
        uint256 wLucaAmount;
    }

    struct StakeLucaMsg {
        address userAddr;    
        address nodeAddr;   
        uint256 start;  
        uint256 end;  
        uint256 fragment;  
    }

    struct StakeWLucaMsg {
        address userAddr;    
        address linkAddr;
        address nodeAddr;   
        uint256 start;  
        uint256 end;  
        uint256 wLucaAmount;  
    }

    modifier onlyNodeAddr(address _nodeAddr) {
        require(nodeAddrSta[_nodeAddr], "PledgeContract: The pledge address is not a node address");
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "PledgeContract: caller is not the admin");
        _;
    }

    modifier onlyLinkContract(address _addr) {
        require( lucaFactory.isLink(_addr), "PledgeContract: This method can only be called by the link contract");
        _;
    }

    function init(address _lucaToken, address _lucaFactory, address _executor) external initializer{
        __Ownable_init_unchained();
        __Pledge_init_unchained(_lucaToken, _lucaFactory, _executor);
    }

    function __Pledge_init_unchained(address _lucaToken, address _lucaFactory, address _executor) internal initializer{
        lucaToken = IERC20(_lucaToken);
        lucaFactory = ILucaFactory(_lucaFactory);
        executor = _executor;
        exchangeRate = lucaToken.fragmentToLuca(10**30);
    }
    
    receive() payable external{

    }
    
    fallback() payable external{

    }
    
    function  modifierLUCAToken(address _lucaToken) external override onlyExecutor{
        lucaToken = IERC20(_lucaToken);
    }
    
    /**
    * @notice A method to add a list of trusted nodes
    * @param _nodeAddrs a list of trusted nodes
    */
    function  addNodeAddr(address[] calldata _nodeAddrs) override external onlyExecutor{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(!nodeAddrSta[_nodeAddr], "This node is already a pledged node");
            nodeAddrSta[_nodeAddr] = true;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex == 0){
                _nodeAddrIndex = ++nodeNum;
                nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
                addNodeStake(_nodeAddrIndex);
            }
            emit AddNodeAddr(_nodeAddrs[i]);
        }
    }
    
    /**
    * @notice A method to cancel the list of untrusted nodes
    * @param _nodeAddrs the list of untrusted nodes
    */
    function  deleteNodeAddr(address[] calldata _nodeAddrs) override external onlyExecutor{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(nodeAddrSta[_nodeAddr], "This node is not a pledge node");
            nodeAddrSta[_nodeAddr] = false;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex > 0){
                uint256 _nodeNum = nodeNum;
                address _lastNodeAddr = nodeIndexAddr[_nodeNum];
                nodeAddrIndex[_lastNodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _lastNodeAddr;
                nodeAddrIndex[_nodeAddr] = 0;
                nodeIndexAddr[_nodeNum] = address(0x0);
                nodeNum--;
                cancelNodeStake(_lastNodeAddr);
            }
            emit DeleteNodeAddr(_nodeAddrs[i]);
        }
    }
    
    function  modifierLucaFactory(address _lucaFactory) override external onlyExecutor{
        lucaFactory = ILucaFactory(_lucaFactory);
    }

    function  updateExecutor(address _executor) override external onlyOwner{
        executor = _executor;
        emit UpdateExecutor(_executor);
    }
    
    /**
    * @notice A method in which users pledge LUCA to trusted nodes. 
    * The nodes must be in the top 11 of the pledge, 
    * and the user's pledge can obtain the pledge income
    * @param _nodeAddr trusted node
    * @param _amount the pledge number
    */
    function  stakeLuca(address _nodeAddr, uint256 _amount) override external onlyNodeAddr(_nodeAddr){
        address _sender = msg.sender;
        require(lucaToken.transferFrom(_sender,address(this),_amount), "Token transfer failed");
        uint256 fragment = lucaToken.lucaToFragment(_amount);
        require(fragment > 0, "Share calculation anomaly");
        _stake(_nodeAddr, fragment, _sender, address(0x0), true);
    }
    
    /**
    * @notice A method in which the user pledges trusted nodes in the link contract. 
    * The nodes must be in the top 11 of the pledge, 
    * and the user's pledge can obtain the pledge income
    * @param _nodeAddr trusted node
    * @param _amount the pledge number
    * @param _sender the pledge user
    */
    function  stakeWLuca(
        address _nodeAddr, 
        uint256 _amount, 
        address _sender
    ) 
        override 
        external 
        onlyNodeAddr(_nodeAddr) 
        onlyLinkContract(msg.sender) 
        returns(bool)
    {
        return  _stake(_nodeAddr, _amount, _sender, msg.sender, false);
    }
    
    /**
    * @notice A method to the user cancels the pledges
    * @param _indexs the user pledges a collection of ids
    */
    function  cancleStakeLuca(uint256[] calldata _indexs) override external {
        address _sender = msg.sender;
        uint256 _amount;
        for (uint256 i = 0; i < _indexs.length; i++) {
            uint256 _stakeLucaMark = _indexs[i];
            if (_stakeLucaMark > 0){
                StakeLucaMsg storage _stakeMsg = stakeLucaMsg[_stakeLucaMark];
                require(_stakeMsg.userAddr == _sender, "Has no authority to remove the pledge not his own");
                require(_stakeMsg.end == 0, "The pledge has been redeemed");
                _stakeMsg.end = block.timestamp;
                _amount += _stakeMsg.fragment;
                nodeFragmentAmount[_stakeMsg.nodeAddr] = nodeFragmentAmount[_stakeMsg.nodeAddr].sub(_stakeMsg.fragment);
                if (nodeAddrSta[_stakeMsg.nodeAddr]){           
                    cancelNodeStake(_stakeMsg.nodeAddr);
                }
                emit EndStakeLuca(_stakeLucaMark, _sender, _stakeMsg.nodeAddr, block.timestamp);
            }
        }
        _amount = lucaToken.fragmentToLuca(_amount);
        require(lucaToken.transfer(_sender,_amount), "Token transfer failed");
    }
    
    /**
    * @notice A method to the user cancels the pledge of the link contract
    * @param _user user address
    */
    function  cancleStakeWLuca(address _user) override external  onlyLinkContract(msg.sender) returns(bool){
        address _sender = msg.sender;
        uint256 _index = userLinkIndex[_sender][_user];
        require(_index > 0, "The corresponding pledge information does not exist");
        userLinkIndex[_sender][_user] = 0;
        StakeWLucaMsg  memory _stakeMsg = stakeWLucaMsg[_index];
        stakeWLucaMsg[_index].end = block.timestamp;
        nodeWLucaAmount[_stakeMsg.nodeAddr] = nodeWLucaAmount[_stakeMsg.nodeAddr].sub(_stakeMsg.wLucaAmount);
        if (nodeAddrSta[_stakeMsg.nodeAddr]){          
            cancelNodeStake(_stakeMsg.nodeAddr);
        }
        emit EndStakeWLuca(_index, _user, _stakeMsg.nodeAddr, _stakeMsg.linkAddr, block.timestamp);
        return true;
    }
        
    function  queryStakeLuca(
        address _userAddr,
        uint256 _page,
        uint256 _limit
    )
        external
        view
        returns(
            address[] memory nodeAddrs,
            uint256[] memory stakeMsgData,
            uint256 _num
        )
    {
        _num = userStakeLucaNum[_userAddr];

        if (_limit > _num){
            _limit = _num;
        }
        if (_page<2){
            _page = 1;
        }
        _page--;
        uint256 start = _page.mul(_limit);
        uint256 end = start.add(_limit);
        if (end > _num){
            end = _num;
            _limit = end.sub(start);
        }
        nodeAddrs = new address[](_limit);
        stakeMsgData = new uint256[](_limit*4);
        if (_num > 0){
            require(end > start, "Query index range out of limit");
            uint256 j;
            for (uint256 i = start; i < end; i++) {
                uint256 _index;
                _index = userStakeLucaIndex[_userAddr][i.add(1)];
                StakeLucaMsg memory _stakeMsg = stakeLucaMsg[_index];
                nodeAddrs[j] = _stakeMsg.nodeAddr;
                stakeMsgData[j*4] = _stakeMsg.start;
                stakeMsgData[j*4+1] = _stakeMsg.end;
                stakeMsgData[j*4+2] = lucaToken.fragmentToLuca(_stakeMsg.fragment);
                stakeMsgData[j*4+3] = _index;
                j++;
            }
        }
    }

    function  queryStakeWLuca(
        address _userAddr,
        uint256 _page,
        uint256 _limit
    )
        external
        view
        returns(
            address[] memory linkAddrs,
            address[] memory nodeAddrs,
            uint256[] memory stakeMsgData,
            uint256 _num
        )
    {
        _num = userStakeWLucaNum[_userAddr];
        if (_limit > _num){
            _limit = _num;
        }
        if (_page<2){
            _page = 1;
        }
        _page--;
        uint256 start = _page.mul(_limit);
        uint256 end = start.add(_limit);
        if (end > _num){
            end = _num;
            _limit = end.sub(start);
        }
        linkAddrs = new address[](_limit);
        nodeAddrs = new address[](_limit);
        stakeMsgData = new uint256[](_limit*4);
        if (_num > 0){
            require(end > start, "Query index range out of limit");
            uint256 j;
            for (uint256 i = start; i < end; i++) {
                uint256 _index;
                _index = userStakeWLucaIndex[_userAddr][i.add(1)];
                StakeWLucaMsg memory _stakeMsg = stakeWLucaMsg[_index];
                linkAddrs[j] = _stakeMsg.linkAddr;
                nodeAddrs[j] = _stakeMsg.nodeAddr;
                stakeMsgData[j*4] = _stakeMsg.start;
                stakeMsgData[j*4+1] = _stakeMsg.end;
                stakeMsgData[j*4+2] = _stakeMsg.wLucaAmount;
                stakeMsgData[j*4+3] = _index;
                j++;
            }
        }
    }

    function queryNodeRank(uint256 start, uint256 end) external view returns (address[] memory, uint256[] memory) {
        if (end > nodeNum){
            end = nodeNum;
        }
        address[] memory _addrArray = new address[](1) ;
        uint256[] memory _stakeAmount = new uint256[](1) ;
        uint256 j;
        if (end >= start){
            uint256 len = end.sub(start).add(1);
            _addrArray = new address[](len) ;
            _stakeAmount = new uint256[](len) ;
            for (uint256 i = start; i <= end; i++) {
                address _nodeAddr = nodeIndexAddr[i];
                _addrArray[j] = _nodeAddr;
                _stakeAmount[j] = lucaToken.fragmentToLuca(nodeFragmentAmount[_nodeAddr]).add(nodeWLucaAmount[_nodeAddr]);
                j++;
            }
        }
        return (_addrArray, _stakeAmount);
    }
    
    function  queryNodeIndex(address _nodeAddr) external view returns(uint256){
        return nodeAddrIndex[_nodeAddr];
    }

    function  queryNodeStakeAmount(address _nodeAddr) external view returns(uint256){
        uint256 lucaStakeAmount = lucaToken.fragmentToLuca(nodeFragmentAmount[_nodeAddr]).add(nodeWLucaAmount[_nodeAddr]);
        return lucaStakeAmount;
    }

    function  nodeRank(uint256 start, uint256 end) override public {
        uint256 _exchangeRate= lucaToken.fragmentToLuca(10**30);
        exchangeRate = _exchangeRate;
        uint256 _nodeNum = nodeNum;
        if (_nodeNum > end){
            _nodeNum = end;
        }
        for (uint256 i=start; i <= _nodeNum; i++){
            for (uint256 j=i+start ; j <= _nodeNum; j++){
                address nextAddr = nodeIndexAddr[j];
                address prefixAddr = nodeIndexAddr[i];
                uint256 _nextSum = nodeFragmentAmount[nextAddr].mul(_exchangeRate).div(10**30).add(nodeWLucaAmount[nextAddr]);
                uint256 _prefixSum = nodeFragmentAmount[prefixAddr].mul(_exchangeRate).div(10**30).add(nodeWLucaAmount[prefixAddr]);
                if (_prefixSum < _nextSum){
                    nodeAddrIndex[prefixAddr] = j;
                    nodeAddrIndex[nextAddr] = i;
                    nodeIndexAddr[i] = nextAddr;
                    nodeIndexAddr[j] = prefixAddr;
                }
            }
        }
    }

    function  _stake(address _nodeAddr, uint256 _amount, address _sender, address _linkAddr, bool _sta) internal  returns(bool){
        uint256 _nodeNum = nodeNum;
        uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
        if (_nodeAddrIndex == 0){
            _nodeAddrIndex = ++nodeNum;
            _nodeNum = _nodeAddrIndex;
            nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
            nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
        }
        if (_sta){
            uint256 _stakeLucaNum = ++stakeLucaNum;
            uint256 _userStakeLucaNum = ++userStakeLucaNum[_sender];
            userStakeLucaIndex[_sender][_userStakeLucaNum] = _stakeLucaNum;
            nodeFragmentAmount[_nodeAddr] += _amount;
            stakeLucaMsg[_stakeLucaNum] = StakeLucaMsg(_sender, _nodeAddr, block.timestamp, 0, _amount);
            emit StakeLuca(_stakeLucaNum, _sender, _nodeAddr, _amount, block.timestamp);
        }else{
            uint256 _stakeWLucaNum = ++stakeWLucaNum;
            uint256 _userStakeWLucaNum = ++userStakeWLucaNum[_sender];
            userStakeWLucaIndex[_sender][_userStakeWLucaNum] = _stakeWLucaNum;
            nodeWLucaAmount[_nodeAddr] += _amount;
            stakeWLucaMsg[_stakeWLucaNum] = StakeWLucaMsg(_sender, _linkAddr, _nodeAddr, block.timestamp, 0, _amount);
            require(userLinkIndex[_linkAddr][_sender] == 0, "The corresponding pledge information already exists");
            userLinkIndex[_linkAddr][_sender] = _stakeWLucaNum;
            emit StakeWLuca(_stakeWLucaNum, _sender, _nodeAddr, _linkAddr, _amount, block.timestamp);
        }
        addNodeStake(_nodeAddrIndex);
        return true;
    }

    function  addNodeStake(uint256 _nodeAddrIndex) internal {
        uint256 _exchangeRate = exchangeRate;
        for (uint256 i = _nodeAddrIndex; i > 1; i--) {
            address _nodeAddr = nodeIndexAddr[i];
            uint256 _prefixIndex = i.sub(1);
            address prefixAddr = nodeIndexAddr[_prefixIndex];
            uint256 _nodeSum = nodeFragmentAmount[_nodeAddr].mul(_exchangeRate).div(10**30).add(nodeWLucaAmount[_nodeAddr]);
            uint256 _prefixSum = nodeFragmentAmount[prefixAddr].mul(_exchangeRate).div(10**30).add(nodeWLucaAmount[prefixAddr]);
            if (_prefixSum < _nodeSum){
                nodeAddrIndex[prefixAddr] = i;
                nodeAddrIndex[_nodeAddr] = _prefixIndex;
                nodeIndexAddr[i] = prefixAddr;
                nodeIndexAddr[_prefixIndex] = _nodeAddr;
            }else{
                break;
            }
        }
    }

    function  cancelNodeStake(address _addr) internal {
        uint256 _nodeNum = nodeNum;
        uint256 _exchangeRate = exchangeRate;
        uint256 _nodeAddrIndex = nodeAddrIndex[_addr];
        for (uint256 i = _nodeAddrIndex; i < _nodeNum; i++) {
            address _nodeAddr = nodeIndexAddr[i];
            uint256 _lastIndex = i.add(1);
            address lastAddr = nodeIndexAddr[_lastIndex];
            uint256 _nodeSum = nodeFragmentAmount[_nodeAddr].mul(_exchangeRate).div(10**30).add(nodeWLucaAmount[_nodeAddr]);
            uint256 _lastSum = nodeFragmentAmount[lastAddr].mul(_exchangeRate).div(10**30).add(nodeWLucaAmount[lastAddr]);
            if (_lastSum > _nodeSum){
                nodeAddrIndex[lastAddr] = i;
                nodeAddrIndex[_nodeAddr] = _lastIndex;
                nodeIndexAddr[i] = lastAddr;
                nodeIndexAddr[_lastIndex] = _nodeAddr;
            }else{
                break;
            }
        }
    }

}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}