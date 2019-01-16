pragma solidity ^0.4.25;


/***
 * HPB节点信息
 *  */
contract HpbNodes {
    string public name = "HPB Nodes Service";
    
    address public owner;
    /**
     * Only the HPB foundation account (administrator) can call.
     */
    modifier onlyOwner{
        require(msg.sender == owner);
        // Do not forget the "_;"! It will be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    event TransferOwnership(address indexed from,address indexed to);

    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
        emit TransferOwnership(msg.sender,newOwner);
    }

    struct HpbNode{
        address coinbase;
        bytes32 cid;
        bytes32 hid;
    }
    
    struct NodeStage{
        uint blockNumber;
        HpbNode[] hpbNodes;
        mapping (address => uint) hpbNodesIndexMap;
    }
    
    NodeStage[] public nodeStages;
    uint currentStageNum = 0;
    
    constructor() payable public{
        owner = msg.sender;
        changeStage(0);
    }

    event ChangeStage(uint indexed stageNum);
    function changeStage(
        uint stageNum
    ) internal{
        currentStageNum=stageNum;
        nodeStages.length++;
        nodeStages[currentStageNum].hpbNodesIndexMap[msg.sender]=0;
        nodeStages[currentStageNum].hpbNodes.push(HpbNode(msg.sender,0,0));
        nodeStages[currentStageNum].blockNumber=block.number;
        emit ChangeStage(stageNum);
    }
    
	function addStage(
    ) onlyOwner public{
        changeStage(currentStageNum+1);
    }
    /**
     * string类型转换成bytes32类型
      */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
       assembly {
        result := mload(add(source, 32))
      }
    }
    
	event AddHpbNode(address indexed coinbase,bytes32 indexed cid,bytes32 indexed hid);
	/**
	 * 添加节点信息
	 */
    function addHpbNode(
        address coinbase,
        bytes32 cid,
        bytes32 hid
    ) onlyOwner public{
        uint index = nodeStages[currentStageNum].hpbNodesIndexMap[coinbase];
        // 必须地址还未使用
        require(index == 0);
        index = nodeStages[currentStageNum].hpbNodes.length;
        nodeStages[currentStageNum].hpbNodesIndexMap[coinbase]=index;
        nodeStages[currentStageNum].hpbNodes.push(HpbNode(coinbase,cid,hid));
        emit AddHpbNode(coinbase,cid,hid);
    }
    
    function addHpbNodeWithString(
        address coinbase,
        string cid,
        string hid
    ) onlyOwner public{
        addHpbNode(coinbase,stringToBytes32(cid),stringToBytes32(hid));
    }

    function addHpbNodeBatch(
        address[] coinbases,
        bytes32[] cids,
        bytes32[] hids
    ) onlyOwner public{
        for(uint i = 0;i<coinbases.length;i++){
            addHpbNode(coinbases[i],cids[i],hids[i]);
        }
    }
	event UpdateHpbNode(address indexed coinbase,bytes32 indexed cid,bytes32 indexed hid);
    function updateHpbNode(
        address coinbase,
        bytes32 cid,
        bytes32 hid
    ) onlyOwner public{
        uint index = nodeStages[currentStageNum].hpbNodesIndexMap[coinbase];
        // 必须地址存在
        require(index != 0);
        nodeStages[currentStageNum].hpbNodes[index].coinbase=coinbase;
        nodeStages[currentStageNum].hpbNodes[index].cid=cid;
        nodeStages[currentStageNum].hpbNodes[index].hid=hid;
        emit UpdateHpbNode(coinbase,cid,hid);
    }
    
	function updateHpbNodeWithString(
        address coinbase,
        string cid,
        string hid
    ) onlyOwner public{
        updateHpbNode(coinbase,stringToBytes32(cid),stringToBytes32(hid));
    }
    
    function updateHpbNodeBatch(
        address[] coinbases,
        bytes32[] cids,
        bytes32[] hids
    ) onlyOwner public{
        for(uint i = 0;i<coinbases.length;i++){
            updateHpbNode(coinbases[i],cids[i],hids[i]);
        }
    }
    
	event DeleteHpbNode(address indexed coinbase);
    function deleteHpbNode(
        address coinbase
    ) onlyOwner public{
        uint index = nodeStages[currentStageNum].hpbNodesIndexMap[coinbase];
        // 必须地址存在
        require(index != 0);
        for (uint i = index;i<nodeStages[currentStageNum].hpbNodes.length-1;i++){
            nodeStages[currentStageNum].hpbNodes[i] = nodeStages[currentStageNum].hpbNodes[i+1];
        }
        delete nodeStages[currentStageNum].hpbNodes[index];
        nodeStages[currentStageNum].hpbNodes.length--;
        nodeStages[currentStageNum].hpbNodesIndexMap[coinbase]=0;
        emit DeleteHpbNode(coinbase);
    }
    function deleteHpbNodeBatch(
        address[] coinbases
    ) onlyOwner public{
        for(uint i = 0;i<coinbases.length;i++){
            deleteHpbNode(coinbases[i]);
        }
    }
    
    function copyAllHpbNodesByStageNum(
        uint stageNum
    )onlyOwner public{
        require(stageNum != 0);
        require(stageNum<currentStageNum);
        for (uint i = 0;i<nodeStages[stageNum].hpbNodes.length;i++){
            address coinbase=nodeStages[stageNum].hpbNodes[i].coinbase;
            bytes32 cid=nodeStages[stageNum].hpbNodes[i].cid;
            bytes32 hid=nodeStages[stageNum].hpbNodes[i].hid;
            addHpbNode(coinbase,cid,hid);
        }
    }
    function getAllHpbNodesByStageNum(
        uint stageNum
    ) onlyOwner public constant returns (
        address[] coinbases,
        bytes32[] cids,
        bytes32[] hids
    ){
        require(stageNum != 0);
        require(stageNum<=currentStageNum);
        uint cl=nodeStages[stageNum].hpbNodes.length;
        address[] memory _coinbases=new address[](cl);
        bytes32[] memory _cids=new bytes32[](cl);
        bytes32[] memory _hids=new bytes32[](cl);
        for (uint i = 0;i<nodeStages[stageNum].hpbNodes.length;i++){
            _coinbases[i]=nodeStages[stageNum].hpbNodes[i].coinbase;
            _cids[i]=nodeStages[stageNum].hpbNodes[i].cid;
            _hids[i]=nodeStages[stageNum].hpbNodes[i].hid;
        }
        return (_coinbases,_cids,hids);
    }
    
    function getAllHpbNodes(
    ) onlyOwner public constant returns (
        address[] coinbases,
        bytes32[] cids,
        bytes32[] hids
    ){
        return getAllHpbNodesByStageNum(currentStageNum);
    }
}