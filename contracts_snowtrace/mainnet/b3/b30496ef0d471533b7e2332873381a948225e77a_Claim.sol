/**
 *Submitted for verification at snowtrace.io on 2022-01-02
*/

pragma solidity ^0.8.0;

interface HasNodeEntity {
    struct NodeEntity {
        uint256 creationTime;
        uint256 lastClaimTime;
		uint256 dividendsPaid;
		uint256 expireTime;
    }
}

interface INodeRewardManagment is HasNodeEntity {
    function _cashoutNodeReward(address account, uint256 index) external returns (uint256);
    function createNode(address account, string memory name, uint256 expireTime) external;
    function _cashoutAllNodesReward(address account) external returns (uint256);
    function _getNodeNumberOf(address account) external view returns (uint256);
    function getNodes(address user) external view returns (NodeEntity[] memory nodes);
    function nodePrice() external returns (uint256);
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Claim is HasNodeEntity {
	
	mapping(address => bool) public userClaimed;
	address[] public usersClaimed;
	
	uint256 private maxCreationTime;
	uint256 public amountPerNode;
	uint256 private maxPayout;
	
	
	INodeRewardManagment private manager;
	IERC20 private WAVAX;
	
	address private recoveryWallet;
	address private owner;
	
	bool internal locked;
	modifier reentrancyGuard() {
		require(!locked);
		locked = true;
		_;
		locked = false;
	}
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	constructor(uint256 _amountPerNode, uint256 _maxCreationTime, address _recoveryWallet) {
		manager = INodeRewardManagment(0xFAcF8166D2d8F9A16ca2966F1b407564947F778d);
		WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
		
		maxCreationTime = _maxCreationTime;
		amountPerNode = _amountPerNode;
		
		recoveryWallet = _recoveryWallet;
		owner = msg.sender;
	}
	
	function changeAmountPerNode(uint256 _amountPerNode) external onlyOwner {
		amountPerNode = _amountPerNode;
	}
	
	function changeMaxCreationTime(uint256 _maxCreationTime) external onlyOwner {
		maxCreationTime = _maxCreationTime;
	}
	
	function changeRecoveryWallet(address _recoveryWallet) external onlyOwner {
		recoveryWallet = _recoveryWallet;
	}
	
	function claim() external reentrancyGuard {
		require(!userClaimed[msg.sender], "You have already claimed this");
		NodeEntity[] memory nodes = manager.getNodes(msg.sender);
		uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "You must have nodes to claim this");
		NodeEntity memory _node;
        uint256 rewardsTotal = 0;
		uint256 validNodes = 0;
		
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];

			if (_node.creationTime < maxCreationTime) {
				rewardsTotal += amountPerNode;
				validNodes++;
			}
        }
		userClaimed[msg.sender] = true;
		usersClaimed.push(msg.sender);
		WAVAX.transferFrom(recoveryWallet, msg.sender, rewardsTotal);
	}
}