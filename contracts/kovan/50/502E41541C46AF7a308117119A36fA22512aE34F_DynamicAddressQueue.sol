// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DynamicAddressQueue {
	
	struct Node {
		address value;
		address nextNodeAddress;
	}
	
	address private _headAddress = address(0);
	mapping(address => Node) private _getNodeFromAddress;
	
	function enqueue(address addr) external {
		// TODO isEmpty() function?
		if(isEmpty())
			_caseBaseEnqueue(addr);
		else
			_genericEnqueue(addr);
	}

	function isEmpty() public view returns(bool) {
		return _headAddress == address(0);
	}

	function _caseBaseEnqueue(address addr) private {
		Node memory firstNode = Node(addr, addr);
		_getNodeFromAddress[addr] = firstNode;
		_headAddress = addr;
	}

	function _genericEnqueue(address addr) private {
		Node memory headNode = _getHeadNode();
		_getNodeFromAddress[addr] = Node(addr, headNode.nextNodeAddress);
		headNode.nextNodeAddress = addr;
		_headAddress = addr;

	}
	
	function dequeue() external returns (address toReturn) {
		if (_theresOnlyOneNode())
			_caseBaseDequeue();
		else
			_genericDequeue();
	}

	function _theresOnlyOneNode() private returns (bool) {
		return _getHeadNode().nextNodeAddress == _headAddress;
	}


	function _caseBaseDequeue() private returns (address toReturn) {
		toReturn = _getHeadNode().value;
		delete _getNodeFromAddress[_headAddress];
		_headAddress = address(0);
	}

	function _genericDequeue() private returns (address toReturn) {
		Node memory headNode = _getHeadNode();
		toReturn = headNode.nextNodeAddress;
		Node memory nextNodeToHead = _getNodeFromAddress[
			headNode.nextNodeAddress
		];
		headNode.nextNodeAddress = nextNodeToHead.nextNodeAddress;
		delete _getNodeFromAddress[toReturn];
	}

	function _getHeadNode() private returns (Node memory) {
		return _getNodeFromAddress[_headAddress];
	}
	
	// NOTE Only for testing purpose
	function printQueue() public returns (string memory) {
		return "test";
	}

}