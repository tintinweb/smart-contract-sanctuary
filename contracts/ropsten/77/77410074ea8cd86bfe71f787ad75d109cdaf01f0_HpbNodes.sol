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
        bytes32 hid;
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
        nodeStages[currentStageNum].hpbNodes.push(HpbNode(msg.sender,0,0,0));
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
        bytes32 cid1,
        bytes32 cid2,
        bytes32 indexed hid
	);

    /**
	 * 添加节点信息
	 */
    function addHpbNode(
        address coinbase,
        bytes32 cid1,
        bytes32 cid2,
        bytes32 hid
    ) onlyOwner public{
        uint index = nodeStages[currentStageNum].hpbNodesIndexMap[coinbase];
        // 必须地址还未使用
        require(index == 0);
        index = nodeStages[currentStageNum].hpbNodes.length;
        nodeStages[currentStageNum].hpbNodesIndexMap[coinbase]=index;
        nodeStages[currentStageNum].hpbNodes.push(HpbNode(
            coinbase,
            cid1,
            cid2,
            hid
        ));
        
        emit AddHpbNode(currentStageNum,coinbase,cid1,cid2,hid);
    }
    
    function addHpbNodeBatch(
        address[] coinbases,
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids
    ) onlyOwner public{
        for(uint i = 0;i<coinbases.length;i++){
            addHpbNode(coinbases[i],cid1s[i],cid2s[i],hids[i]);
        }
    }
	event UpdateHpbNode(
	    uint indexed stageNum,
        address indexed coinbase,
        bytes32 cid1,
        bytes32 cid2,
        bytes32 indexed hid
	);
	
    function updateHpbNode(
        address coinbase,
        bytes32 cid1,
        bytes32 cid2,
        bytes32 hid
    ) onlyOwner public{
        uint index = nodeStages[currentStageNum].hpbNodesIndexMap[coinbase];
        // 必须地址存在
        require(index != 0);
        nodeStages[currentStageNum].hpbNodes[index].coinbase=coinbase;
        nodeStages[currentStageNum].hpbNodes[index].cid1=cid1;
        nodeStages[currentStageNum].hpbNodes[index].cid2=cid2;
        nodeStages[currentStageNum].hpbNodes[index].hid=hid;
        emit UpdateHpbNode(currentStageNum,coinbase,cid1,cid2,hid);
    }
    
    function updateHpbNodeBatch(
        address[] coinbases,
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids
    ) onlyOwner public{
        for(uint i = 0;i<coinbases.length;i++){
            updateHpbNode(coinbases[i],cid1s[i],cid2s[i],hids[i]);
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
    
    /**
     * bytes32类型转换成string类型
     */
    function bytes32ToString(bytes32 x) internal pure returns (string) {
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
   
    function getAllHpbNodesByStageNum(
        uint _stageNum
    )  public constant returns (
        address[] coinbases,
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids
    ){
        require(_stageNum<=currentStageNum);
        NodeStage memory nodeStage=nodeStages[_stageNum];
        uint cl=nodeStage.hpbNodes.length;
        address[] memory _coinbases=new address[](cl);
        bytes32[] memory _cid1s=new bytes32[](cl);
        bytes32[] memory _cid2s=new bytes32[](cl);
        bytes32[] memory _hids=new bytes32[](cl);
        require(nodeStage.hpbNodes.length>1);
        for (uint i = 1;i<nodeStage.hpbNodes.length;i++){
            _coinbases[i]=nodeStage.hpbNodes[i].coinbase;
            _cid1s[i]=nodeStage.hpbNodes[i].cid1;
            _cid2s[i]=nodeStage.hpbNodes[i].cid2;
            _hids[i]=nodeStage.hpbNodes[i].hid;
        }
        return (_coinbases,_cid1s,_cid2s,_hids);
    }
    
    function getAllHpbNodes(
    )  public constant returns (
        address[] coinbases,
        bytes32[] cid1s,
        bytes32[] cid2s,
        bytes32[] hids
    ){
        return getAllHpbNodesByStageNum(currentStageNum);
    }
}