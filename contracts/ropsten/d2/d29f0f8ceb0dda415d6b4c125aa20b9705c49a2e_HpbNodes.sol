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
        bytes32 cid1;
        bytes32 cid2;
        bytes32 cid3;
        bytes32 cid4;
        bytes32 hid1;
        bytes32 hid2;
    }
    
    struct NodeStage{
        uint blockNumber;
        HpbNode[] hpbNodes;
        mapping (address => uint) hpbNodesIndexMap;
    }
    
    NodeStage[] public nodeStages;
    uint public currentStageNum = 0;
    
    constructor() public{
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
        nodeStages[currentStageNum].hpbNodes.push(HpbNode(msg.sender,0,0,0,0,0,0));
        nodeStages[currentStageNum].blockNumber=block.number;
        emit ChangeStage(stageNum);
    }
    
	function addStage(
    ) onlyOwner public{
        changeStage(currentStageNum+1);
    }
  
	event AddHpbNode(
	    uint indexed stageNum,
	    address indexed coinbase,
	    bytes32 indexed cid1,
	    bytes32 hid1,
	    bytes32 cid2,
	    bytes32 cid3,
	    bytes32 cid4,
	    bytes32 hid2
	);
	/**
	 * 添加节点信息
	 */
    function addHpbNode(
        address coinbase,
        bytes32 cid1,
        bytes32 cid2,
        bytes32 cid3,
        bytes32 cid4,
        bytes32 hid1,
        bytes32 hid2
    ) onlyOwner public{
        uint index = nodeStages[currentStageNum].hpbNodesIndexMap[coinbase];
        // 必须地址还未使用
        require(index == 0);
        index = nodeStages[currentStageNum].hpbNodes.length;
        nodeStages[currentStageNum].hpbNodesIndexMap[coinbase]=index;
        nodeStages[currentStageNum].hpbNodes.push(HpbNode(coinbase,cid1,cid2,cid3,cid4,hid1,hid2));
        emit AddHpbNode(currentStageNum,coinbase,cid1,hid1,cid2,cid3,cid4,hid2);
    }
    
    function addHpbNodeBatch(
        address[] coinbases,
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] cid3s,
        bytes32[] cid4s,
        bytes32[] hid1s,
        bytes32[] hid2s
    ) onlyOwner public{
        for(uint i = 0;i<coinbases.length;i++){
            addHpbNode(coinbases[i],cid1s[i],cid2s[i],cid3s[i],cid4s[i],hid1s[i],hid2s[i]);
        }
    }
    
	event UpdateHpbNode(
	    uint indexed stageNum,
	    address indexed coinbase,
	    bytes32 indexed cid1,
	    bytes32 hid1,
	    bytes32 cid2,
	    bytes32 cid3,
	    bytes32 cid4,
	    bytes32 hid2
	);
	
    function updateHpbNode(
        address coinbase,
        bytes32 cid1,
        bytes32 cid2,
        bytes32 cid3,
        bytes32 cid4,
        bytes32 hid1,
        bytes32 hid2
    ) onlyOwner public{
        uint index = nodeStages[currentStageNum].hpbNodesIndexMap[coinbase];
        // 必须地址存在
        require(index != 0);
        nodeStages[currentStageNum].hpbNodes[index].coinbase=coinbase;
        nodeStages[currentStageNum].hpbNodes[index].cid1=cid1;
        nodeStages[currentStageNum].hpbNodes[index].cid2=cid2;
        nodeStages[currentStageNum].hpbNodes[index].cid3=cid3;
        nodeStages[currentStageNum].hpbNodes[index].cid4=cid4;
        nodeStages[currentStageNum].hpbNodes[index].hid1=hid1;
        nodeStages[currentStageNum].hpbNodes[index].hid2=hid2;
        emit UpdateHpbNode(currentStageNum,coinbase,cid1,hid1,cid2,cid3,cid4,hid2);
    }
	
    function updateHpbNodeBatch(
        address[] coinbases,
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] cid3s,
        bytes32[] cid4s,
        bytes32[] hid1s,
        bytes32[] hid2s
    ) onlyOwner public{
        for(uint i = 0;i<coinbases.length;i++){
            updateHpbNode(coinbases[i],cid1s[i],cid2s[i],cid3s[i],cid4s[i],hid1s[i],hid2s[i]);
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
    
    event CopyAllHpbNodesByStageNum(uint indexed stageNum);
    function copyAllHpbNodesByStageNum(
        uint stageNum
    )onlyOwner public{
        require(stageNum != 0);
        require(stageNum<currentStageNum);
        nodeStages[currentStageNum].hpbNodes=nodeStages[stageNum].hpbNodes;
        emit CopyAllHpbNodesByStageNum(stageNum);
    }
    
    function getAllHpbNodesByStageNum(
        uint _stageNum
    ) onlyOwner public constant returns (
        address[] coinbases,
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] cid3s,
        bytes32[] cid4s
    ){
        require(_stageNum<=currentStageNum);
        NodeStage memory nodeStage=nodeStages[_stageNum];
        uint cl=nodeStage.hpbNodes.length;
        address[] memory _coinbases=new address[](cl);
        bytes32[] memory _cid1s=new bytes32[](cl);
        bytes32[] memory _cid2s=new bytes32[](cl);
        bytes32[] memory _cid3s=new bytes32[](cl);
        bytes32[] memory _cid4s=new bytes32[](cl);
   
        for (uint i = 0;i<nodeStage.hpbNodes.length;i++){
            _coinbases[i]=nodeStage.hpbNodes[i].coinbase;
            _cid1s[i]=nodeStage.hpbNodes[i].cid1;
            _cid2s[i]=nodeStage.hpbNodes[i].cid2;
            _cid3s[i]=nodeStage.hpbNodes[i].cid3;
            _cid4s[i]=nodeStage.hpbNodes[i].cid4;
        }
        return (_coinbases,_cid1s,_cid2s,_cid3s,_cid3s);
    }
    
    function getAllHpbNodes(
    ) onlyOwner public constant returns (
        address[] coinbases,
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] cid3s,
        bytes32[] cid4s
    ){
        return getAllHpbNodesByStageNum(currentStageNum);
    }
    function getAllHpbNodesExtByStageNum(
        uint _stageNum
    ) onlyOwner public constant returns (
        address[] coinbases,
        bytes32[] hid1s,
        bytes32[] hid2s
    ){
        require(_stageNum<=currentStageNum);
        NodeStage memory nodeStage=nodeStages[_stageNum];
        uint cl=nodeStage.hpbNodes.length;
        address[] memory _coinbases=new address[](cl);
        bytes32[] memory _hid1s=new bytes32[](cl);
        bytes32[] memory _hid2s=new bytes32[](cl);
   
        for (uint i = 0;i<nodeStage.hpbNodes.length;i++){
            _coinbases[i]=nodeStage.hpbNodes[i].coinbase;
            _hid1s[i]=nodeStage.hpbNodes[i].hid1;
            _hid2s[i]=nodeStage.hpbNodes[i].hid2;
        }
        return (_coinbases,_hid1s,_hid2s);
    }
    
    function getAllHpbNodesExt(
    ) onlyOwner public constant returns (
        address[] coinbases,
        bytes32[] hid1s,
        bytes32[] hid2s
    ){
        return getAllHpbNodesExtByStageNum(currentStageNum);
    }
}