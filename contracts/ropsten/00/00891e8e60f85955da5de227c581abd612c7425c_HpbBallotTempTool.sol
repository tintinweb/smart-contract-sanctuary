/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.4.26;
contract VoteInterface {
    function addCandidate(address _candidateAddr,string _facilityId,string _name)public;
}

contract HpbNodesInterface {

    function addStage() public;
    
    function transferOwnership(address newOwner) public;

    function addHpbNode(address coinbase, bytes32 cid1,
        bytes32 cid2,
        bytes32 hid) public;

    function updateHpbNode(address coinbase, bytes32 cid1,
        bytes32 cid2,
        bytes32 hid) public;

    function getAllHpbNodes() public view returns (address[] coinbases, bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids);
}
contract FechHpbBallotAddrInterface {

    function setContractAddr(address _contractAddr) public;
    /**
     * 得到最获取智能合约地址
     */
    function getContractAddr() public view returns(address _contractAddr);

    function setFunStr(string _funStr) public;

    /**
     * 得到最获取智能合约调用方法
     */
    function getFunStr() public view returns(string _funStr);
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
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
contract HpbBallotTempTool is Ownable {
    using SafeMath for uint256;
    address hpbNodeAddress;
    address fechHpbBallotAddrAddress;
    address[] hpbBallots;
    mapping (address => uint) hpbBallotIndex;
    event ReceivedHpb(address indexed sender, uint amount);
    event RewardVoteResultForCandidate(address indexed from,address indexed to,uint indexed value);

    // 接受HPB转账
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

    constructor () payable public {
        owner = msg.sender;
        adminMap[msg.sender] = msg.sender;
        hpbBallots.push(0);
    }

    function setHpbNodeAddress(address _hpbNodeAddress) onlyAdmin public {
        hpbNodeAddress = _hpbNodeAddress;
    }

    function setFechHpbBallotAddrAddresss(address _fechHpbBallotAddrAddress) onlyAdmin public {
        fechHpbBallotAddrAddress = _fechHpbBallotAddrAddress;
    }

    function addHpbBallotAddress(address _hpbBallotAddress) onlyAdmin public {
        require(hpbBallotIndex[_hpbBallotAddress] == 0);
        uint index=hpbBallots.push(_hpbBallotAddress) - 1;
        hpbBallotIndex[_hpbBallotAddress] = index;
    }

    function updateHpbBallotAddress(address _hpbBallotAddress, address _newHpbBallotAddress) onlyAdmin public {
        uint index=hpbBallotIndex[_newHpbBallotAddress];
        require(index != 0);
        hpbBallots[index] = _newHpbBallotAddress;
        hpbBallotIndex[_hpbBallotAddress] = 0;
        hpbBallotIndex[_newHpbBallotAddress] = index;
    }

    function _getVoteInterface(uint _index) internal view returns (VoteInterface voteInterface) {
        require(_index != 0);
        return VoteInterface(hpbBallots[_index]);
    }

    function _getHpbNodesInterface() internal view returns  (HpbNodesInterface hpbNodesInterface) {
        require(hpbNodeAddress != 0);
        return HpbNodesInterface(hpbNodeAddress);
    }

    function _getFechHpbBallotAddrInterface() internal view returns (FechHpbBallotAddrInterface fechHpbBallotAddrInterface) {
        require(fechHpbBallotAddrAddress != 0);
        return FechHpbBallotAddrInterface(fechHpbBallotAddrAddress);
    }


    function addCandidate(address _candidateAddr,string _facilityId,string _name) public {
        addCandidateByIndex(hpbBallots.length - 1,_candidateAddr,_facilityId,_name);
    }
    
    function addCandidateByIndex(uint index,address _candidateAddr,string _facilityId,string _name) public {
        _getVoteInterface(index).addCandidate(_candidateAddr,_facilityId, _name);
    }

    function batchAddCandidate(address[] _candidateAddrs, bytes32[] _facilityIds,bytes32[] _names) public {
        batchAddCandidateByIndex(hpbBallots.length - 1,_candidateAddrs,_facilityIds,_names);
    }
    function batchAddCandidateByIndex(uint index,address[] _candidateAddrs, bytes32[] _facilityIds,bytes32[] _names) public {
        for (uint i=0;i < _candidateAddrs.length;i++) {
            addCandidateByIndex(index,_candidateAddrs[i],bytes32ToString(_facilityIds[i]),bytes32ToString(_names[i]));
        }
    }
	function bytes32ToString(bytes32 x)  public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    function addStage() public {
        _getHpbNodesInterface().addStage();
    }

    function addHpbNode(
        address coinbase, 
        bytes32 cid1,
        bytes32 cid2,
        bytes32 hid
    ) public {
        _getHpbNodesInterface().addHpbNode(coinbase, cid1, cid2, hid);
    }

    function addHpbNodeBatch(
        address[] coinbases, 
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids
    ) public {
       for(uint i = 0;i<coinbases.length;i++){
           addHpbNode(coinbases[i],cid1s[i],cid2s[i],hids[i]);
       }
    }

    function updateHpbNode(
        address coinbase, 
        bytes32 cid1,
        bytes32 cid2,
        bytes32 hid
    ) public {
        _getHpbNodesInterface().updateHpbNode(coinbase, cid1, cid2, hid);
    }

    function updateHpbNodeBatch(
        address[] coinbases, 
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids
    ) public {
        for(uint i = 0;i<coinbases.length;i++){
            updateHpbNode(coinbases[i],cid1s[i],cid2s[i],hids[i]);
        }
    }

    function getAllHpbNodes() public view returns (
        address[] coinbases, 
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids
    ) {
        return _getHpbNodesInterface().getAllHpbNodes();
    }

    function setContractAddr(address _contractAddr) public {
        _getFechHpbBallotAddrInterface().setContractAddr(_contractAddr);
    }

    /**
     * 得到最获取智能合约地址
     */
    function getContractAddr() public view returns(address _contractAddr) {
        return _getFechHpbBallotAddrInterface().getContractAddr();
    }

    function setFunStr(string _funStr) public {
        _getFechHpbBallotAddrInterface().setFunStr(_funStr);
    }

    /**
     * 得到最获取智能合约调用方法
     */
    function getFunStr() public view returns(string _funStr) {
        return _getFechHpbBallotAddrInterface().getFunStr();
    }
    
    function transferNodeContractOwnership(address newOwner) onlyOwner public{
        _getHpbNodesInterface().transferOwnership(newOwner);
    }
    
    struct Candidate {
        address candidateAddr;
        bytes32 name;
    }
    Candidate[] candidateArray;
    mapping (address => uint) candidateIndexMap;
    function addCandidateCache(address[] _candidateAddrs, bytes32[] _names) onlyAdmin public {
        require(_candidateAddrs.length==_names.length);
        for(uint i = 0;i<_candidateAddrs.length;i++){
	        uint index = candidateIndexMap[_candidateAddrs[i]];
	        // 必须地址还未使用
	        require(index == 0);
	        candidateIndexMap[_candidateAddrs[i]]=candidateArray.push(Candidate(
	            _candidateAddrs[i],_names[i]))-1;
        }
    }
     function deleteCandidateCache(
        address _candidateAddr
    ) onlyAdmin public{
        uint index = candidateIndexMap[_candidateAddr];
        // 必须地址存在
        require(index != 0);
        for (uint i = index;i<candidateArray.length-1;i++){
            candidateArray[i] = candidateArray[i+1];
            candidateIndexMap[candidateArray[i].candidateAddr]=i;
        }
        delete candidateArray[index];
        candidateArray.length--;
        candidateIndexMap[_candidateAddr]=0;
    }
    function batchDeleteCandidateCache(
        address[] _candidateAddrs
    ) onlyAdmin public{
        for(uint i = 0;i<_candidateAddrs.length;i++){
            deleteCandidateCache(_candidateAddrs[i]);
        }
    }
    function clearCandidateCache(
    ) onlyAdmin public{
        for(uint i = 1;i<candidateArray.length;i++){
            deleteCandidateCache(candidateArray[i].candidateAddr);
        }
    }
    function addAllCandidates(
    )onlyAdmin public{
        require(candidateArray.length > 1);
        uint cl=candidateArray.length - 1;
        address[] memory _addrs=new address[](cl);
        bytes32[] memory _facilityIds=new bytes32[](cl);
        bytes32[] memory _names=new bytes32[](cl);
        for (uint i=1;i <= cl;i++) {
            _addrs[i-1] = candidateArray[i].candidateAddr;
            _names[i-1] = candidateArray[i].name;
            _facilityIds[i-1] =bytes32(i);
        }
        batchAddCandidate(_addrs,_facilityIds,_names);
    }
	struct HpbNode{
        address coinbase;
        bytes32 cid1;
        bytes32 cid2;
        bytes32 hid;
    }
    HpbNode[] hpbNodes;
    mapping (address => uint) hpbNodesIndexMap;
    function addNodesCache(
        address[] coinbases, 
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids
    ) onlyAdmin public {
        require(coinbases.length==cid1s.length);
        require(coinbases.length==cid2s.length);
        require(coinbases.length==hids.length);
        for(uint i = 0;i<coinbases.length;i++){
	        uint index = hpbNodesIndexMap[coinbases[i]];
	        // 必须地址还未使用
	        require(index == 0);
	        hpbNodesIndexMap[coinbases[i]]=hpbNodes.push(HpbNode(
	            coinbases[i],cid1s[i],cid2s[i],hids[i]))-1;
        }
    }
    function deleteHpbNodeCache(
        address coinbase
    ) onlyAdmin public{
        uint index = hpbNodesIndexMap[coinbase];
        // 必须地址存在
        require(index != 0);
        for (uint i = index;i<hpbNodes.length-1;i++){
            hpbNodes[i] = hpbNodes[i+1];
            hpbNodesIndexMap[hpbNodes[i].coinbase]=i;
        }
        delete hpbNodes[index];
        hpbNodes.length--;
        hpbNodesIndexMap[coinbase]=0;
    }
    function batchDeleteHpbNodeCache(
        address[] coinbases
    ) onlyAdmin public{
        for(uint i = 0;i<coinbases.length;i++){
            deleteHpbNodeCache(coinbases[i]);
        }
    }
    function clearHpbNodeCache(
    ) onlyAdmin public{
        for(uint i = 1;i<hpbNodes.length;i++){
            deleteHpbNodeCache(hpbNodes[i].coinbase);
        }
    }
    function getAllHpbNodesCache(
    )  public view returns (
        address[] coinbases,
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids
    ){
        require(hpbNodes.length>1);
        uint cl=hpbNodes.length-1;
        address[] memory _coinbases=new address[](cl);
        bytes32[] memory _cid1s=new bytes32[](cl);
        bytes32[] memory _cid2s=new bytes32[](cl);
        bytes32[] memory _hids=new bytes32[](cl);
        for (uint i = 1;i<hpbNodes.length;i++){
            _coinbases[i-1]=hpbNodes[i].coinbase;
            _cid1s[i-1]=hpbNodes[i].cid1;
            _cid2s[i-1]=hpbNodes[i].cid2;
            _hids[i-1]=hpbNodes[i].hid;
        }
        return (_coinbases,_cid1s,_cid2s,_hids);
    }
    function switchNodes(
    )onlyAdmin public {
        require(hpbNodes.length>1);
        uint cl=hpbNodes.length-1;
        address[] memory _coinbases=new address[](cl);
        bytes32[] memory _cid1s=new bytes32[](cl);
        bytes32[] memory _cid2s=new bytes32[](cl);
        bytes32[] memory _hids=new bytes32[](cl);
        for (uint i = 1;i<hpbNodes.length;i++){
            _coinbases[i-1]=hpbNodes[i].coinbase;
            _cid1s[i-1]=hpbNodes[i].cid1;
            _cid2s[i-1]=hpbNodes[i].cid2;
            _hids[i-1]=hpbNodes[i].hid;
        }
        addStage();
        addHpbNodeBatch(_coinbases,_cid1s,_cid2s,_hids);
        _getFechHpbBallotAddrInterface().setContractAddr(address(this));
        _getFechHpbBallotAddrInterface().setFunStr(bytes32ToString(keccak256("fechAllVoteResultPreStageByBlock(uint)")));
    }
}