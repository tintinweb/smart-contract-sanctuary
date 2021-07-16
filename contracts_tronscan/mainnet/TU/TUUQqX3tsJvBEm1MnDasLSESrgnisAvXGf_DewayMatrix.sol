//SourceUnit: deway.sol

/**
 * Created on 2021-01-01
 * @summary: 
 * @author: deway.io dev
 */
pragma solidity ^0.5.0;

contract TRC20 {


  string public name;

  string public symbol;

  uint8 public decimals;

  uint256 public totalSupply;

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract DewayMatrix {
	
	address payable owner;
	address payable devteam;
	address payable overflowPool;
	TRC20 DWB;
	struct User {
		bool exists;
		uint256 id;
		uint256 parentId;
		uint256 partners;
		uint256 totalIncome;
		uint256 tokenBouns;
	}

	struct Node {
		uint256 left;
		uint256 right;
		uint256 parent;
		bool next;
		uint256[] ancestors;
		uint256 totalRight;
		uint256 totalLeft;
		mapping (uint8 => bool) activeLevel;
		mapping (uint8 => Maxtrix) matrixData;
	}

	struct Maxtrix {
		uint256 incomes;
		uint256 DWReward;
		bool maxout;
		uint256 cyclePlace;
		uint256 totalIncome;
	}
	
	uint256 public totalNode = 1;
	uint256 public totalDeposit;
	uint256 public totalTokenBonus;
	mapping(address => User) public users;
	mapping(uint256 => address payable) public idToUsers;
	mapping(uint256 => Node) public nodes;
	mapping (uint8 => uint256) public matrixValue;
	mapping (uint256 => address[]) public partners;
	mapping (uint256 => uint256) public revenues;
	
	
	constructor(
		address payable _devteam,
		address payable _owner,
		address payable _overflowPool,
		address payable addr1,
	    address payable addr2,
	    address payable addr3,
	    address payable addr4,
		address payable addr5,
		address payable addr6,
		address payable tokenAddr
	) public {
		devteam = _devteam;
		overflowPool = _overflowPool;
		owner = _owner;
		DWB = TRC20(tokenAddr);
		User memory _newUser = User({
			exists: true,
			id : totalNode,
			parentId: 0,
			partners: 0,
			tokenBouns: 0,
			totalIncome: 0
		});
		users[owner] = _newUser;
		idToUsers[totalNode] = owner;

		matrixValue[1] = 1000 trx;
		matrixValue[2] = 5000 trx;
		matrixValue[3] = 10000 trx;
		matrixValue[4] = 30000 trx;
		matrixValue[5] = 50000 trx;
		matrixValue[6] = 100000 trx;
		matrixValue[7] = 200000 trx;
		matrixValue[8] = 500000 trx;
		matrixValue[9] = 1000000 trx;
		
		for(uint8 i=1; i<=9; i++){
			nodes[1].activeLevel[i] = true;
		}

		_leaderInit(addr1, 1);
		_leaderInit(addr2, 1);
		_leaderInit(addr3, 1);
		_leaderInit(addr4, 1);
		_leaderInit(addr5, 1);
		_leaderInit(addr6, 1);
	}

	function register(uint256 refId) public payable {
		require(msg.value == matrixValue[1], "Need 1000 TRX to Register");
		require(refId <= totalNode && refId > 0, "Reference Id not exists");
		require(!users[msg.sender].exists, "Node have been exists");
		users[idToUsers[refId]].partners += 1;
		partners[refId].push(msg.sender);
		hanldeDWReward(idToUsers[refId], 1);
		if(DWB.balanceOf(address(this)) > 10){
			users[idToUsers[refId]].tokenBouns += 10 trx;
			totalTokenBonus += 10 trx;
			DWB.transfer(idToUsers[refId], 10 trx);
		}
		totalDeposit += msg.value;
		_addNewUser(msg.sender, refId);
		devteam.transfer(msg.value * 7 / 100);
		_updateRevenue(msg.sender, msg.value);
		emit NewPlace(totalNode, refId, now);
	}

	function _leaderInit (address payable _add, uint256 refId) private {
		users[idToUsers[refId]].partners += 1;
		partners[refId].push(_add);
		totalNode++;
		User memory _newUser = User({
			exists: true,
			id : totalNode,
			parentId: refId,
			partners: 0,
			tokenBouns: 0,
			totalIncome:0
		});

		users[_add] = _newUser;
		idToUsers[totalNode] = _add;
		_addNewNode(totalNode, refId);
	}
	

	function rePlace(uint8 level) public payable {
		require(msg.value == matrixValue[level], "invalid value");
		require(users[msg.sender].exists, "User is not exists. Please register");
		require(level >= 1 && level <= 9, "invalid level");
		require(nodes[users[msg.sender].id].matrixData[level].maxout,"Level not maxout");
		
		nodes[users[msg.sender].id].matrixData[level].maxout = false;
		nodes[users[msg.sender].id].matrixData[level].incomes = 0;
		nodes[users[msg.sender].id].matrixData[level].cyclePlace += 1;
		nodes[users[msg.sender].id].matrixData[level].DWReward = 0;
		hanldeDWReward(idToUsers[users[msg.sender].parentId], level);
		address payable parentNode  = idToUsers[_findParentPaiddNode(users[msg.sender].parentId,nodes[users[msg.sender].parentId].ancestors, level)];
		address payable paidNode  = idToUsers[_findPaidNode(nodes[users[msg.sender].id].ancestors, level)];
		parentNode.transfer(msg.value * 45 / 100);
		_handleIncomes(users[parentNode].id, level, msg.value * 45 / 100);
		paidNode.transfer(msg.value * 45 / 100);
		_handleIncomes(users[paidNode].id, level, msg.value * 45 / 100);
		totalDeposit += msg.value;
		devteam.transfer(msg.value * 7 / 100);
		_updateRevenue(msg.sender, msg.value);
		emit DirectRewards(users[parentNode].id,matrixValue[1] * 45 / 100, now);
		emit Receive(users[paidNode].id,matrixValue[1] * 45 / 100, now);
		emit RePlace(users[msg.sender].id,level,now);
	}

	function buyLevel (uint8 level) public payable {
		require(msg.value == matrixValue[level], "invalid value");
		require(users[msg.sender].exists, "User is not exists. Please register");
		require(level > 1 && level <= 9, "invalid level");
		require (!nodes[users[msg.sender].id].activeLevel[level] && nodes[users[msg.sender].id].activeLevel[level-1],"Not enough requirment up level");
		hanldeDWReward(idToUsers[users[msg.sender].parentId], level);
		nodes[users[msg.sender].id].activeLevel[level] = true;
		address payable parentNode  = idToUsers[_findParentPaiddNode(users[msg.sender].parentId,nodes[users[msg.sender].parentId].ancestors, level)];
		address payable paidNode  = idToUsers[_findPaidNode(nodes[users[msg.sender].id].ancestors, level)];
		parentNode.transfer(msg.value * 45 / 100);
		_handleIncomes(users[parentNode].id, level, msg.value * 45 / 100);
		paidNode.transfer(msg.value * 45 / 100);
		_handleIncomes(users[paidNode].id, level, msg.value * 45 / 100);
		totalDeposit += msg.value;
		devteam.transfer(msg.value * 7 / 100);
		_updateRevenue(msg.sender, msg.value);
		emit DirectRewards(users[parentNode].id,matrixValue[1] * 45 / 100, now);
		emit Receive(users[paidNode].id,matrixValue[1] * 45 / 100, now);

		emit BuyLevel(users[msg.sender].id, level, now);
	}
	
	function hanldeDWReward (address payable _add, uint8 _level) public {
		if(nodes[users[_add].id].matrixData[_level].DWReward == matrixValue[_level] * 18 / 100){
			overflowPool.transfer(matrixValue[_level] * 3 / 100);
		} else {
			_add.transfer(matrixValue[_level] * 3 / 100);
			nodes[users[_add].id].matrixData[_level].DWReward += matrixValue[_level] * 3 / 100;
			emit DWRewards(_add);
		}
	}
	
	function changeAddress (address payable newAddr) public payable {
		require (users[msg.sender].exists,"User is not exists");
		uint256 userId = users[msg.sender].id;
		User memory _userData = users[msg.sender];
		users[newAddr] = _userData;
		idToUsers[userId] = newAddr;
		users[msg.sender].exists = false;
	}
	
	
	function _addNewUser(address payable  _add, uint256 _id) private {
		totalNode++;
		User memory _newUser = User({
			exists: true,
			id : totalNode,
			parentId: _id,
			partners: 0,
			tokenBouns: 0,
			totalIncome:0
		});

		users[_add] = _newUser;
		idToUsers[totalNode] = _add;
		_addNewNode(totalNode, _id);
		address payable parentNode  = idToUsers[_findParentPaiddNode(_id,nodes[_id].ancestors, 1)];
		address payable paidNode  = idToUsers[_findPaidNode(nodes[totalNode].ancestors, 1)];
		parentNode.transfer(matrixValue[1] * 45 / 100);
		_handleIncomes(users[parentNode].id, 1, matrixValue[1] * 45 / 100);
		paidNode.transfer(matrixValue[1] * 45 / 100);
		_handleIncomes(users[paidNode].id, 1, matrixValue[1] * 45 / 100);
		emit DirectRewards(users[parentNode].id,matrixValue[1] * 45 / 100, now);
		emit Receive(users[paidNode].id,matrixValue[1] * 45 / 100, now);
	}

	function _addNewNode(uint256 _id, uint256 _parentId) private {
		uint256 _parentNode = _findParentNode(_parentId);
		
		nodes[_id].parent = _parentNode;
        nodes[_id].ancestors = nodes[_parentNode].ancestors;
        nodes[_id].ancestors.push(_parentNode);
        nodes[_id].activeLevel[1] = true;
		if(nodes[_parentNode].left == 0){
			nodes[_parentNode].left = _id;
		} else {
			nodes[_parentNode].right = _id;                          
			nodes[_parentNode].next = true;
		}

		_hanldeTotalNode(_id, nodes[_id].ancestors);
	} 


	function _findPaidNode(uint256[] memory _ancestors, uint8 _level) private view returns(uint256){
		for(uint256 i= 1; i < _ancestors.length; i++){
			uint256 currentNode = _ancestors[_ancestors.length -i];
			if(!nodes[currentNode].matrixData[_level].maxout && nodes[currentNode].activeLevel[_level]){
				return currentNode;
			}
		}
		return 1;
	}

	function _findParentPaiddNode(uint256 _parentId, uint256[] memory _ancestors,uint8 _level) private view returns(uint256){
		if(!nodes[_parentId].matrixData[_level].maxout && nodes[_parentId].activeLevel[_level]){
			return _parentId;
		}
		for(uint256 i= 1; i < _ancestors.length; i++){
			uint256 currentNode = _ancestors[_ancestors.length -i];
			if(!nodes[currentNode].matrixData[_level].maxout && nodes[currentNode].activeLevel[_level]){
				return currentNode;
			}
		}
		return 1;
	}

	function _handleIncomes(uint256 _id,uint8 _level, uint256 _value) private {
// 		users[idToUsers[_id]].matrixData[_level].incomes += _value;
		users[idToUsers[_id]].totalIncome += _value;
		nodes[_id].matrixData[_level].totalIncome += _value;
		if(nodes[_id].matrixData[_level].incomes == matrixValue[_level] * 270 / 100){
			nodes[_id].matrixData[_level].incomes = _value;
		} else {
			nodes[_id].matrixData[_level].incomes += _value;
			if(nodes[_id].matrixData[_level].incomes ==  matrixValue[_level] * 270 / 100){
				nodes[_id].matrixData[_level].maxout = true;
				emit MaxOut(_id);
			}
		}
	}

	function _hanldeTotalNode(uint256 _id, uint256[] memory _ancestors) private {
		if(nodes[_ancestors[_ancestors.length -1]].right == _id){
			nodes[_ancestors[_ancestors.length -1]].totalRight +=1;
		} else {
			nodes[_ancestors[_ancestors.length -1]].totalLeft +=1;
		}
		for(uint256 i= 2; i <= _ancestors.length; i++){
			if(nodes[_ancestors[_ancestors.length -i]].right == _ancestors[_ancestors.length -i+1]){
				nodes[_ancestors[_ancestors.length -i]].totalRight +=1;
			} else {
				nodes[_ancestors[_ancestors.length -i]].totalLeft +=1;
			}
		}
	}


	function _findParentNode(uint256 _currentParentId) private view returns(uint256){
		if(nodes[_currentParentId].next){
			if(nodes[_currentParentId].totalRight >= nodes[_currentParentId].totalLeft){
				return _findParentNode(nodes[_currentParentId].left);
			} else {
				return _findParentNode(nodes[_currentParentId].right);
			}
		} else {
			return _currentParentId;
		}
	}

	function _updateRevenue(address _add, uint256 _value) private {
		address upline = idToUsers[users[_add].parentId];
		while(upline != owner){
			revenues[users[upline].id] += _value;
			upline = idToUsers[users[upline].parentId];
		}
	}

	function userMatrixData( address addr, uint8 matrix) public view returns(bool, uint256, bool, uint256, uint256) {
		if(!users[addr].exists || !nodes[users[addr].id].activeLevel[matrix]){
			return (false,0,false,0,0);
		}
		return (nodes[users[addr].id].activeLevel[matrix], nodes[users[addr].id].matrixData[matrix].incomes,nodes[users[addr].id].matrixData[matrix].maxout,nodes[users[addr].id].matrixData[matrix].cyclePlace,nodes[users[addr].id].matrixData[matrix].totalIncome);

	}
	
	function getDWreward (address addr) public view returns(uint256) {
		uint256 result = 0;
		for(uint8 i =1; i<=9; i++){
			result += nodes[users[addr].id].matrixData[i].DWReward;
		}

		return result;
	}
	
	event NewPlace(
		uint256 indexed members,
		uint256 parent,
		uint time
 	);

	event RePlace(
		uint256 indexed members,
		uint8 level,
		uint time
	);
	
 	event MaxOut(
		uint256 indexed user
	);

 	event DWRewards(
 		address indexed members
 	);

 	event Receive(
 		uint256 indexed members,
 		uint256 value,
 		uint time
 	);

 	event DirectRewards(
 		uint256 indexed members,
 		uint256 value,
 		uint time
 	);
 	
	event  BuyLevel(
		uint256 indexed victim,
		uint8 level,
		uint time
	);

	event TokenClaim(
		address indexed addr,
		uint256 value
	);
	
}