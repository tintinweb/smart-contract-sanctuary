pragma solidity 0.4.16;


library CommonLibrary {
	struct Data {
		mapping (uint => Node) nodes; 
		mapping (string => uint) nodesID;
		mapping (string => uint16) nodeGroups;
		uint16 nodeGroupID;
		uint nodeID;
		uint ownerNotationId;
		uint addNodeAddressId;
	}
	
	struct Node {
		string nodeName;
		address producer;
		address node;
		uint256 date;
		bool starmidConfirmed;
		address[] outsourceConfirmed;
		uint16[] nodeGroup;
		uint8 producersPercent;
		uint16 nodeSocialMedia;
	}
	
	function addNodeGroup(Data storage self, string _newNodeGroup) returns(bool _result, uint16 _id) {
		if (self.nodeGroups[_newNodeGroup] == 0) {
			_id = self.nodeGroupID += 1;
			self.nodeGroups[_newNodeGroup] = self.nodeGroupID;
			_result = true;
		}
	}
	
	function addNode(
		Data storage self, 
		string _newNode, 
		uint8 _producersPercent
		) returns (bool _result, uint _id) {
		if (self.nodesID[_newNode] < 1 && _producersPercent < 100) {
			_id = self.nodeID += 1;
			require(self.nodeID < 1000000000000);
			self.nodes[self.nodeID].nodeName = _newNode;
			self.nodes[self.nodeID].producer = msg.sender;
			self.nodes[self.nodeID].date = block.timestamp;
			self.nodes[self.nodeID].starmidConfirmed = false;
			self.nodes[self.nodeID].producersPercent = _producersPercent;
			self.nodesID[_newNode] = self.nodeID;
			_result = true;
		}
		else _result = false;
	}
	
	function editNode(
	    Data storage self, 
		uint _nodeID, 
		address _nodeAddress, 
		bool _isNewProducer, 
		address _newProducer, 
		uint8 _newProducersPercent,
		bool _starmidConfirmed
		) returns (bool) {
		if (_isNewProducer == true) {
			self.nodes[_nodeID].node = _nodeAddress;
			self.nodes[_nodeID].producer = _newProducer;
			self.nodes[_nodeID].producersPercent = _newProducersPercent;
			self.nodes[_nodeID].starmidConfirmed = _starmidConfirmed;
			return true;
		}
		else {
			self.nodes[_nodeID].node = _nodeAddress;
			self.nodes[_nodeID].starmidConfirmed = _starmidConfirmed;
			return true;
		}
	}
	
	function addNodeAddress(Data storage self, uint _nodeID, address _nodeAddress) returns(bool _result, uint _id) {
		if (msg.sender == self.nodes[_nodeID].producer) {
			if (self.nodes[_nodeID].node == 0) {
				self.nodes[_nodeID].node = _nodeAddress;
				_id = self.addNodeAddressId += 1;//for event count
				_result = true;
			}
			else _result = false;
		}
		else _result = false;
	}
	
	//-----------------------------------------Starmid Exchange functions
	function stockMinSellPrice(StarCoinLibrary.Data storage self, uint _buyPrice, uint _node) constant returns (uint _minSellPrice) {
		_minSellPrice = _buyPrice + 1;
		for (uint i = 0; i < self.stockSellOrderPrices[_node].length; i++) {
			if(self.stockSellOrderPrices[_node][i] < _minSellPrice) _minSellPrice = self.stockSellOrderPrices[_node][i];
		}
	}
	
	function stockMaxBuyPrice (StarCoinLibrary.Data storage self, uint _sellPrice, uint _node) constant returns (uint _maxBuyPrice) {
		_maxBuyPrice = _sellPrice - 1;
		for (uint i = 0; i < self.stockBuyOrderPrices[_node].length; i++) {
			if(self.stockBuyOrderPrices[_node][i] > _maxBuyPrice) _maxBuyPrice = self.stockBuyOrderPrices[_node][i];
		}
	}
	
	function stockDeleteFirstOrder(StarCoinLibrary.Data storage self, uint _node, uint _price, bool _isStockSellOrders) {
		if (_isStockSellOrders == true) uint _length = self.stockSellOrders[_node][_price].length;
		else _length = self.stockBuyOrders[_node][_price].length;
		for (uint ii = 0; ii < _length - 1; ii++) {
			if (_isStockSellOrders == true) self.stockSellOrders[_node][_price][ii] = self.stockSellOrders[_node][_price][ii + 1];
			else self.stockBuyOrders[_node][_price][ii] = self.stockBuyOrders[_node][_price][ii + 1];
		}
		if (_isStockSellOrders == true) {
			delete self.stockSellOrders[_node][_price][self.stockSellOrders[_node][_price].length - 1];
			self.stockSellOrders[_node][_price].length--;
			//Delete _price from stockSellOrderPrices[_node][] if it&#39;s the last order
			if (self.stockSellOrders[_node][_price].length == 0) {
				uint fromArg = 99999;
				for (uint8 iii = 0; iii < self.stockSellOrderPrices[_node].length - 1; iii++) {
					if (self.stockSellOrderPrices[_node][iii] == _price) {
						fromArg = iii;
					}
					if (fromArg != 99999 && iii >= fromArg) self.stockSellOrderPrices[_node][iii] = self.stockSellOrderPrices[_node][iii + 1];
				}
				delete self.stockSellOrderPrices[_node][self.stockSellOrderPrices[_node].length-1];
				self.stockSellOrderPrices[_node].length--;
			}
		}
		else {
			delete self.stockBuyOrders[_node][_price][self.stockBuyOrders[_node][_price].length - 1];
			self.stockBuyOrders[_node][_price].length--;
			//Delete _price from stockBuyOrderPrices[_node][] if it&#39;s the last order
			if (self.stockBuyOrders[_node][_price].length == 0) {
				fromArg = 99999;
				for (iii = 0; iii < self.stockBuyOrderPrices[_node].length - 1; iii++) {
					if (self.stockBuyOrderPrices[_node][iii] == _price) {
						fromArg = iii;
					}
					if (fromArg != 99999 && iii >= fromArg) self.stockBuyOrderPrices[_node][iii] = self.stockBuyOrderPrices[_node][iii + 1];
				}
				delete self.stockBuyOrderPrices[_node][self.stockBuyOrderPrices[_node].length-1];
				self.stockBuyOrderPrices[_node].length--;
			}
		}
	}
	
	function stockSaveOwnerInfo(StarCoinLibrary.Data storage self, uint _node, uint _amount, address _buyer, address _seller, uint _price) {
		//--------------------------------------_buyer
		self.StockOwnersBuyPrice[_buyer][_node].sumPriceAmount += _amount*_price;
		self.StockOwnersBuyPrice[_buyer][_node].sumDateAmount += _amount*block.timestamp;
		self.StockOwnersBuyPrice[_buyer][_node].sumAmount += _amount;
		uint16 _thisNode = 0;
			for (uint16 i6 = 0; i6 < self.stockOwnerInfo[_buyer].nodes.length; i6++) {
				if (self.stockOwnerInfo[_buyer].nodes[i6] == _node) _thisNode = 1;
			}
			if (_thisNode == 0) self.stockOwnerInfo[_buyer].nodes.push(_node);
		//--------------------------------------_seller
		if(self.StockOwnersBuyPrice[_seller][_node].sumPriceAmount > 0) {
			self.StockOwnersBuyPrice[_seller][_node].sumPriceAmount -= _amount*_price;
			self.StockOwnersBuyPrice[_buyer][_node].sumDateAmount -= _amount*block.timestamp;
			self.StockOwnersBuyPrice[_buyer][_node].sumAmount -= _amount;
		}
		_thisNode = 0;
		for (i6 = 0; i6 < self.stockOwnerInfo[_seller].nodes.length; i6++) {
			if (self.stockOwnerInfo[_seller].nodes[i6] == _node) _thisNode = i6;
		}
		if (_thisNode > 0) {
			for (uint ii = _thisNode; ii < self.stockOwnerInfo[msg.sender].nodes.length - 1; ii++) {
				self.stockOwnerInfo[msg.sender].nodes[ii] = self.stockOwnerInfo[msg.sender].nodes[ii + 1];
			}
			delete self.stockOwnerInfo[msg.sender].nodes[self.stockOwnerInfo[msg.sender].nodes.length - 1];
		}
	}
	
	function deleteStockBuyOrder(StarCoinLibrary.Data storage self, uint _iii, uint _node, uint _price) {
		for (uint ii = _iii; ii < self.stockBuyOrders[_node][_price].length - 1; ii++) {
			self.stockBuyOrders[_node][_price][ii] = self.stockBuyOrders[_node][_price][ii + 1];
		}
		delete self.stockBuyOrders[_node][_price][self.stockBuyOrders[_node][_price].length - 1];
		self.stockBuyOrders[_node][_price].length--;
		//Delete _price from stockBuyOrderPrices[_node][] if it&#39;s the last order
		if (self.stockBuyOrders[_node][_price].length == 0) {
			uint _fromArg = 99999;
			for (_iii = 0; _iii < self.stockBuyOrderPrices[_node].length - 1; _iii++) {
				if (self.stockBuyOrderPrices[_node][_iii] == _price) {
					_fromArg = _iii;
				}
				if (_fromArg != 99999 && _iii >= _fromArg) self.stockBuyOrderPrices[_node][_iii] = self.stockBuyOrderPrices[_node][_iii + 1];
			}
			delete self.stockBuyOrderPrices[_node][self.stockBuyOrderPrices[_node].length-1];
			self.stockBuyOrderPrices[_node].length--;
		}
	}
	
	function deleteStockSellOrder(StarCoinLibrary.Data storage self, uint _iii, uint _node, uint _price) {
		for (uint ii = _iii; ii < self.stockSellOrders[_node][_price].length - 1; ii++) {
			self.stockSellOrders[_node][_price][ii] = self.stockSellOrders[_node][_price][ii + 1];
		}
		delete self.stockSellOrders[_node][_price][self.stockSellOrders[_node][_price].length - 1];
		self.stockSellOrders[_node][_price].length--;
		//Delete _price from stockSellOrderPrices[_node][] if it&#39;s the last order
		if (self.stockSellOrders[_node][_price].length == 0) {
			uint _fromArg = 99999;
			for (_iii = 0; _iii < self.stockSellOrderPrices[_node].length - 1; _iii++) {
				if (self.stockSellOrderPrices[_node][_iii] == _price) {
					_fromArg = _iii;
				}
				if (_fromArg != 99999 && _iii >= _fromArg) self.stockSellOrderPrices[_node][_iii] = self.stockSellOrderPrices[_node][_iii + 1];
			}
			delete self.stockSellOrderPrices[_node][self.stockSellOrderPrices[_node].length-1];
			self.stockSellOrderPrices[_node].length--;
		}
	}
}


library StarCoinLibrary {
	struct Data {
		uint256 lastMint;
		mapping (address => uint256) balanceOf;
		mapping (address => uint256) frozen;
		uint32 ordersId;
		mapping (uint256 => orderInfo[]) buyOrders;
		mapping (uint256 => orderInfo[]) sellOrders;
		mapping (address => mapping (uint => uint)) stockBalanceOf;
		mapping (address => mapping (uint => uint)) stockFrozen;
		mapping (uint => uint)  emissionLimits;
		uint32 stockOrdersId;
		mapping (uint => emissionNodeInfo) emissions;
		mapping (uint => mapping (uint256 => stockOrderInfo[])) stockBuyOrders;
		mapping (uint => mapping (uint256 => stockOrderInfo[])) stockSellOrders;
		mapping (address => mapping (uint => uint)) lastDividends;
		mapping (address => mapping (uint => averageBuyPrice)) StockOwnersBuyPrice;
		mapping (address => ownerInfo) stockOwnerInfo;
		uint[] buyOrderPrices;
		uint[] sellOrderPrices;
		mapping (uint => uint[]) stockBuyOrderPrices;
		mapping (uint => uint[]) stockSellOrderPrices;
		mapping (address => uint) pendingWithdrawals;
	}
	struct orderInfo {
		uint date;
		address client;
		uint256 amount;
		uint256 price;
		bool isBuyer;
		uint orderId;
    }
	struct emissionNodeInfo {
		uint emissionNumber;
		uint date;
	}
	struct stockOrderInfo {
		uint date;
		address client;
		uint256 amount;
		uint256 price;
		bool isBuyer;
		uint orderId;
		uint node;
    }
	struct averageBuyPrice {
        uint sumPriceAmount;
		uint sumDateAmount;
		uint sumAmount;
    }
	struct ownerInfo {
		uint index;
		uint[] nodes;
    }
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	event TradeHistory(uint date, address buyer, address seller, uint price, uint amount, uint orderId);
    
    function buyOrder(Data storage self, uint256 _buyPrice) returns (uint[4] _results) {
		uint _remainingValue = msg.value;
		uint256[4] memory it;
		if (minSellPrice(self, _buyPrice) != _buyPrice + 1) {
			it[3] = self.sellOrderPrices.length;
			for (it[1] = 0; it[1] < it[3]; it[1]++) {
				uint _minPrice = minSellPrice(self, _buyPrice);
				it[2] = self.sellOrders[_minPrice].length;
				for (it[0] = 0; it[0] < it[2]; it[0]++) {
					uint _amount = _remainingValue/_minPrice;
					if (_amount >= self.sellOrders[_minPrice][0].amount) {
						//buy starcoins for ether
						self.balanceOf[msg.sender] += self.sellOrders[_minPrice][0].amount;// adds the amount to buyer&#39;s balance
						self.frozen[self.sellOrders[_minPrice][0].client] -= self.sellOrders[_minPrice][0].amount;// subtracts the amount from seller&#39;s frozen balance
						Transfer(self.sellOrders[_minPrice][0].client, msg.sender, self.sellOrders[_minPrice][0].amount);
						//transfer ether to seller
						uint256 amountTransfer = _minPrice*self.sellOrders[_minPrice][0].amount;
						self.pendingWithdrawals[self.sellOrders[_minPrice][0].client] += amountTransfer;
						//save the transaction
						TradeHistory(block.timestamp, msg.sender, self.sellOrders[_minPrice][0].client, _minPrice, self.sellOrders[_minPrice][0].amount, 
						self.sellOrders[_minPrice][0].orderId);
						_remainingValue -= amountTransfer;
						_results[0] += self.sellOrders[_minPrice][0].amount;
						//delete sellOrders[_minPrice][0] and move each element
						deleteFirstOrder(self, _minPrice, true);
						if (_remainingValue/_minPrice < 1) break;
					}
					else {
						//edit sellOrders[_minPrice][0]
						self.sellOrders[_minPrice][0].amount = self.sellOrders[_minPrice][0].amount - _amount;
						//buy starcoins for ether
						self.balanceOf[msg.sender] += _amount;// adds the _amount to buyer&#39;s balance
						self.frozen[self.sellOrders[_minPrice][0].client] -= _amount;// subtracts the _amount from seller&#39;s frozen balance
						Transfer(self.sellOrders[_minPrice][0].client, msg.sender, _amount);
						//save the transaction
						TradeHistory(block.timestamp, msg.sender, self.sellOrders[_minPrice][0].client, _minPrice, _amount, self.sellOrders[_minPrice][0].orderId);
						//transfer ether to seller
						uint256 amountTransfer1 = _amount*_minPrice;
						self.pendingWithdrawals[self.sellOrders[_minPrice][0].client] += amountTransfer1;
						_remainingValue -= amountTransfer1;
						_results[0] += _amount;
						if(_remainingValue/_minPrice < 1) {
							_results[3] = 1;
							break;
						}
					}
				}
				if (_remainingValue/_minPrice < 1) {
					_results[3] = 1;
					break;
				}
			}
			if(_remainingValue/_buyPrice < 1) 
				self.pendingWithdrawals[msg.sender] += _remainingValue;//returns change to buyer
		}
		if (minSellPrice(self, _buyPrice) == _buyPrice + 1 && _remainingValue/_buyPrice >= 1) {
			//save new order
			_results[1] =  _remainingValue/_buyPrice;
			if (_remainingValue - _results[1]*_buyPrice > 0) 
				self.pendingWithdrawals[msg.sender] += _remainingValue - _results[1]*_buyPrice;//returns change to buyer
			self.ordersId += 1;
			_results[2] = self.ordersId;
			self.buyOrders[_buyPrice].push(orderInfo( block.timestamp, msg.sender, _results[1], _buyPrice, true, self.ordersId));
		    _results[3] = 1;
			//Add _buyPrice to buyOrderPrices[]
			it[0] = 99999;
			for (it[1] = 0; it[1] < self.buyOrderPrices.length; it[1]++) {
				if (self.buyOrderPrices[it[1]] == _buyPrice) 
					it[0] = it[1];
			}
			if (it[0] == 99999) 
				self.buyOrderPrices.push(_buyPrice);
		}
	}
	
	function minSellPrice(Data storage self, uint _buyPrice) constant returns (uint _minSellPrice) {
		_minSellPrice = _buyPrice + 1;
		for (uint i = 0; i < self.sellOrderPrices.length; i++) {
			if(self.sellOrderPrices[i] < _minSellPrice) _minSellPrice = self.sellOrderPrices[i];
		}
	}
	
	function sellOrder(Data storage self, uint256 _sellPrice, uint _amount) returns (uint[4] _results) {
		uint _remainingAmount = _amount;
		require(self.balanceOf[msg.sender] >= _amount);
		uint256[4] memory it;
		if (maxBuyPrice(self, _sellPrice) != _sellPrice - 1) {
			it[3] = self.buyOrderPrices.length;
			for (it[1] = 0; it[1] < it[3]; it[1]++) {
				uint _maxPrice = maxBuyPrice(self, _sellPrice);
				it[2] = self.buyOrders[_maxPrice].length;
				for (it[0] = 0; it[0] < it[2]; it[0]++) {
					if (_remainingAmount >= self.buyOrders[_maxPrice][0].amount) {
						//sell starcoins for ether
						self.balanceOf[msg.sender] -= self.buyOrders[_maxPrice][0].amount;// subtracts amount from seller&#39;s balance
						self.balanceOf[self.buyOrders[_maxPrice][0].client] += self.buyOrders[_maxPrice][0].amount;// adds the amount to buyer&#39;s balance
						Transfer(msg.sender, self.buyOrders[_maxPrice][0].client, self.buyOrders[_maxPrice][0].amount);
						//transfer ether to seller
						uint _amountTransfer = _maxPrice*self.buyOrders[_maxPrice][0].amount;
						self.pendingWithdrawals[msg.sender] += _amountTransfer;
						//save the transaction
						TradeHistory(block.timestamp, self.buyOrders[_maxPrice][0].client, msg.sender, _maxPrice, self.buyOrders[_maxPrice][0].amount, 
						self.buyOrders[_maxPrice][0].orderId);
						_remainingAmount -= self.buyOrders[_maxPrice][0].amount;
						_results[0] += self.buyOrders[_maxPrice][0].amount;
						//delete buyOrders[_maxPrice][0] and move each element
						deleteFirstOrder(self, _maxPrice, false);
						if(_remainingAmount < 1) break;
					}
					else {
						//edit buyOrders[_maxPrice][0]
						self.buyOrders[_maxPrice][0].amount = self.buyOrders[_maxPrice][0].amount-_remainingAmount;
						//buy starcoins for ether
						self.balanceOf[msg.sender] -= _remainingAmount;// subtracts amount from seller&#39;s balance
						self.balanceOf[self.buyOrders[_maxPrice][0].client] += _remainingAmount;// adds the amount to buyer&#39;s balance 
						Transfer(msg.sender, self.buyOrders[_maxPrice][0].client, _remainingAmount);
						//save the transaction
						TradeHistory(block.timestamp, self.buyOrders[_maxPrice][0].client, msg.sender, _maxPrice, _remainingAmount, self.buyOrders[_maxPrice][0].orderId);
						//transfer ether to seller
						uint256 amountTransfer1 = _maxPrice*_remainingAmount;
						self.pendingWithdrawals[msg.sender] += amountTransfer1;
						_results[0] += _remainingAmount;
						_remainingAmount = 0;
						break;
					}
				}
				if (_remainingAmount<1) {
					_results[3] = 1;
					break;
				}
			}
		}
		if (maxBuyPrice(self, _sellPrice) == _sellPrice - 1 && _remainingAmount >= 1) {
			//save new order
			_results[1] =  _remainingAmount;
			self.ordersId += 1;
			_results[2] = self.ordersId;
			self.sellOrders[_sellPrice].push(orderInfo( block.timestamp, msg.sender, _results[1], _sellPrice, false, _results[2]));
		    _results[3] = 1;
			//transfer starcoins to the frozen balance
			self.frozen[msg.sender] += _remainingAmount;
			self.balanceOf[msg.sender] -= _remainingAmount;
			//Add _sellPrice to sellOrderPrices[]
			it[0] = 99999;
			for (it[1] = 0; it[1] < self.sellOrderPrices.length; it[1]++) {
				if (self.sellOrderPrices[it[1]] == _sellPrice) 
					it[0] = it[1];
			}
			if (it[0] == 99999) 
				self.sellOrderPrices.push(_sellPrice);
		}
	}
	
	function maxBuyPrice (Data storage self, uint _sellPrice) constant returns (uint _maxBuyPrice) {
		_maxBuyPrice = _sellPrice - 1;
		for (uint i = 0; i < self.buyOrderPrices.length; i++) {
			if(self.buyOrderPrices[i] > _maxBuyPrice) _maxBuyPrice = self.buyOrderPrices[i];
		}
	}
	
	function deleteFirstOrder(Data storage self, uint _price, bool _isSellOrders) {
		if (_isSellOrders == true) uint _length = self.sellOrders[_price].length;
		else _length = self.buyOrders[_price].length;
		for (uint ii = 0; ii < _length - 1; ii++) {
			if (_isSellOrders == true) self.sellOrders[_price][ii] = self.sellOrders[_price][ii + 1];
			else self.buyOrders[_price][ii] = self.buyOrders[_price][ii+1];
		}
		if (_isSellOrders == true) {
			delete self.sellOrders[_price][self.sellOrders[_price].length - 1];
			self.sellOrders[_price].length--;
			//Delete _price from sellOrderPrices[] if it&#39;s the last order
			if (_length == 1) {
				uint _fromArg = 99999;
				for (uint8 iii = 0; iii < self.sellOrderPrices.length - 1; iii++) {
					if (self.sellOrderPrices[iii] == _price) {
						_fromArg = iii;
					}
					if (_fromArg != 99999 && iii >= _fromArg) self.sellOrderPrices[iii] = self.sellOrderPrices[iii + 1];
				}
				delete self.sellOrderPrices[self.sellOrderPrices.length-1];
				self.sellOrderPrices.length--;
			}
		}
		else {
			delete self.buyOrders[_price][self.buyOrders[_price].length - 1];
			self.buyOrders[_price].length--;
			//Delete _price from buyOrderPrices[] if it&#39;s the last order
			if (_length == 1) {
				_fromArg = 99999;
				for (iii = 0; iii < self.buyOrderPrices.length - 1; iii++) {
					if (self.buyOrderPrices[iii] == _price) {
						_fromArg = iii;
					}
					if (_fromArg != 99999 && iii >= _fromArg) self.buyOrderPrices[iii] = self.buyOrderPrices[iii + 1];
				}
				delete self.buyOrderPrices[self.buyOrderPrices.length-1];
				self.buyOrderPrices.length--;
			}
		}
	}
	
	function cancelBuyOrder(Data storage self, uint _thisOrderID, uint _price) public returns(bool) {
		for (uint8 iii = 0; iii < self.buyOrders[_price].length; iii++) {
			if (self.buyOrders[_price][iii].orderId == _thisOrderID) {
				//delete buyOrders[_price][iii] and move each element
				require(msg.sender == self.buyOrders[_price][iii].client);
				uint _remainingValue = self.buyOrders[_price][iii].price*self.buyOrders[_price][iii].amount;
				for (uint ii = iii; ii < self.buyOrders[_price].length - 1; ii++) {
					self.buyOrders[_price][ii] = self.buyOrders[_price][ii + 1];
				}
				delete self.buyOrders[_price][self.buyOrders[_price].length - 1];
				self.buyOrders[_price].length--;
				self.pendingWithdrawals[msg.sender] += _remainingValue;//returns ether to buyer
				break;
			}
		}
		//Delete _price from buyOrderPrices[] if it&#39;s the last order
		if (self.buyOrders[_price].length == 0) {
				uint _fromArg = 99999;
				for (uint8 iiii = 0; iiii < self.buyOrderPrices.length - 1; iiii++) {
					if (self.buyOrderPrices[iiii] == _price) {
						_fromArg = iiii;
					}
					if (_fromArg != 99999 && iiii >= _fromArg) self.buyOrderPrices[iiii] = self.buyOrderPrices[iiii + 1];
				}
				delete self.buyOrderPrices[self.buyOrderPrices.length-1];
				self.buyOrderPrices.length--;
		}
		return true;
	}
	
	function cancelSellOrder(Data storage self, uint _thisOrderID, uint _price) public returns(bool) {
		for (uint8 iii = 0; iii < self.sellOrders[_price].length; iii++) {
			if (self.sellOrders[_price][iii].orderId == _thisOrderID) {
				require(msg.sender == self.sellOrders[_price][iii].client);
				//return starcoins from the frozen balance to seller
				self.frozen[msg.sender] -= self.sellOrders[_price][iii].amount;
				self.balanceOf[msg.sender] += self.sellOrders[_price][iii].amount;
				//delete sellOrders[_price][iii] and move each element
				for (uint ii = iii; ii < self.sellOrders[_price].length - 1; ii++) {
					self.sellOrders[_price][ii] = self.sellOrders[_price][ii + 1];
				}
				delete self.sellOrders[_price][self.sellOrders[_price].length - 1];
				self.sellOrders[_price].length--;
				break;
			}
		}
		//Delete _price from sellOrderPrices[] if it&#39;s the last order
		if (self.sellOrders[_price].length == 0) {
				uint _fromArg = 99999;
				for (uint8 iiii = 0; iiii < self.sellOrderPrices.length - 1; iiii++) {
					if (self.sellOrderPrices[iiii] == _price) {
						_fromArg = iiii;
					}
					if (_fromArg != 99999 && iiii >= _fromArg) 
						self.sellOrderPrices[iiii] = self.sellOrderPrices[iiii + 1];
				}
				delete self.sellOrderPrices[self.sellOrderPrices.length-1];
				self.sellOrderPrices.length--;
		}
		return true;
	}
}


library StarmidLibrary {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event StockTransfer(address indexed from, address indexed to, uint indexed node, uint256 value);
	event StockTradeHistory(uint node, uint date, address buyer, address seller, uint price, uint amount, uint orderId);
    
	function stockBuyOrder(StarCoinLibrary.Data storage self, uint _node, uint256 _buyPrice, uint _amount) public returns (uint[4] _results) {
		require(self.balanceOf[msg.sender] >= _buyPrice*_amount);
		uint256[4] memory it;
		if (CommonLibrary.stockMinSellPrice(self, _buyPrice, _node) != _buyPrice + 1) {
			it[3] = self.stockSellOrderPrices[_node].length;
			for (it[1] = 0; it[1] < it[3]; it[1]++) {
				uint minPrice = CommonLibrary.stockMinSellPrice(self, _buyPrice, _node);
				it[2] = self.stockSellOrders[_node][minPrice].length;
				for (it[0] = 0; it[0] < it[2]; it[0]++) {
					if (_amount >= self.stockSellOrders[_node][minPrice][0].amount) {
						//buy stocks for starcoins
						self.stockBalanceOf[msg.sender][_node] += self.stockSellOrders[_node][minPrice][0].amount;// add the amount to buyer&#39;s balance
						self.stockFrozen[self.stockSellOrders[_node][minPrice][0].client][_node] -= self.stockSellOrders[_node][minPrice][0].amount;// subtracts amount from seller&#39;s frozen stock balance
						//write stockOwnerInfo and stockOwners for dividends
						CommonLibrary.stockSaveOwnerInfo(self, _node, self.stockSellOrders[_node][minPrice][0].amount, msg.sender, self.stockSellOrders[_node][minPrice][0].client, minPrice);
						//transfer starcoins to seller
						self.balanceOf[msg.sender] -= self.stockSellOrders[_node][minPrice][0].amount*minPrice;// subtracts amount from buyer&#39;s balance
						self.balanceOf[self.stockSellOrders[_node][minPrice][0].client] += self.stockSellOrders[_node][minPrice][0].amount*minPrice;// adds the amount to seller&#39;s balance
						Transfer(self.stockSellOrders[_node][minPrice][0].client, msg.sender, self.stockSellOrders[_node][minPrice][0].amount*minPrice);
						//save the transaction into event StocksTradeHistory;
						StockTradeHistory(_node, block.timestamp, msg.sender, self.stockSellOrders[_node][minPrice][0].client, minPrice, 
						self.stockSellOrders[_node][minPrice][0].amount, self.stockSellOrders[_node][minPrice][0].orderId);
						_amount -= self.stockSellOrders[_node][minPrice][0].amount;
						_results[0] += self.stockSellOrders[_node][minPrice][0].amount;
						//delete stockSellOrders[_node][minPrice][0] and move each element
						CommonLibrary.stockDeleteFirstOrder(self, _node, minPrice, true);
						if (_amount<1) break;
					}
					else {
						//edit stockSellOrders[_node][minPrice][0]
						self.stockSellOrders[_node][minPrice][0].amount -= _amount;
						//buy stocks for starcoins
						self.stockBalanceOf[msg.sender][_node] += _amount;// adds the _amount to buyer&#39;s balance
						self.stockFrozen[self.stockSellOrders[_node][minPrice][0].client][_node] -= _amount;// subtracts _amount from seller&#39;s frozen stock balance
						//write stockOwnerInfo and stockOwners for dividends
					    CommonLibrary.stockSaveOwnerInfo(self, _node, _amount, msg.sender, self.stockSellOrders[_node][minPrice][0].client, minPrice);
						//transfer starcoins to seller
						self.balanceOf[msg.sender] -= _amount*minPrice;// subtracts _amount from buyer&#39;s balance
						self.balanceOf[self.stockSellOrders[_node][minPrice][0].client] += _amount*minPrice;// adds the amount to seller&#39;s balance
						Transfer(self.stockSellOrders[_node][minPrice][0].client, msg.sender, _amount*minPrice);
						//save the transaction  into event StocksTradeHistory;
						StockTradeHistory(_node, block.timestamp, msg.sender, self.stockSellOrders[_node][minPrice][0].client, minPrice, 
						_amount, self.stockSellOrders[_node][minPrice][0].orderId);
						_results[0] += _amount;
						_amount = 0;
						break;
					}
				}
				if(_amount < 1) {
					_results[3] = 1;
					break;
				}
		   	}
		}
		if (CommonLibrary.stockMinSellPrice(self, _buyPrice, _node) == _buyPrice + 1 && _amount >= 1) {
			//save new order
			_results[1] =  _amount;
			self.stockOrdersId += 1;
			_results[2] = self.stockOrdersId;
			self.stockBuyOrders[_node][_buyPrice].push(StarCoinLibrary.stockOrderInfo(block.timestamp, msg.sender, _results[1], _buyPrice, true, self.stockOrdersId, _node));
		    _results[3] = 1;
			//transfer starcoins to the frozen balance
			self.frozen[msg.sender] += _amount*_buyPrice;
			self.balanceOf[msg.sender] -= _amount*_buyPrice;
			//Add _buyPrice to stockBuyOrderPrices[_node][]
			it[0] = 99999;
			for (it[1] = 0; it[1] < self.stockBuyOrderPrices[_node].length; it[1]++) {
				if (self.stockBuyOrderPrices[_node][it[1]] == _buyPrice) 
					it[0] = it[1];
			}
			if (it[0] == 99999) self.stockBuyOrderPrices[_node].push(_buyPrice);
		}
	}
	
	function stockSellOrder(StarCoinLibrary.Data storage self, uint _node, uint _sellPrice, uint _amount) returns (uint[4] _results) {
		require(self.stockBalanceOf[msg.sender][_node] >= _amount);
		uint[4] memory it;
		if (CommonLibrary.stockMaxBuyPrice(self, _sellPrice, _node) != _sellPrice - 1) {
			it[3] = self.stockBuyOrderPrices[_node].length;
			for (it[1] = 0; it[1] < it[3]; it[1]++) {
				uint _maxPrice = CommonLibrary.stockMaxBuyPrice(self, _sellPrice, _node);
				it[2] = self.stockBuyOrders[_node][_maxPrice].length;
				for (it[0] = 0; it[0] < it[2]; it[0]++) {
					if (_amount >= self.stockBuyOrders[_node][_maxPrice][0].amount) {
						//sell stocks for starcoins
						self.stockBalanceOf[msg.sender][_node] -= self.stockBuyOrders[_node][_maxPrice][0].amount;// subtracts the _amount from seller&#39;s balance 
						self.stockBalanceOf[self.stockBuyOrders[_node][_maxPrice][0].client][_node] += self.stockBuyOrders[_node][_maxPrice][0].amount;// adds the _amount to buyer&#39;s balance
						//write stockOwnerInfo and stockOwners for dividends
						CommonLibrary.stockSaveOwnerInfo(self, _node, self.stockBuyOrders[_node][_maxPrice][0].amount, self.stockBuyOrders[_node][_maxPrice][0].client, msg.sender, _maxPrice);
						//transfer starcoins to seller
						self.balanceOf[msg.sender] += self.stockBuyOrders[_node][_maxPrice][0].amount*_maxPrice;// adds the amount to buyer&#39;s balance 
						self.frozen[self.stockBuyOrders[_node][_maxPrice][0].client] -= self.stockBuyOrders[_node][_maxPrice][0].amount*_maxPrice;// subtracts amount from seller&#39;s frozen balance
						Transfer(self.stockBuyOrders[_node][_maxPrice][0].client, msg.sender, self.stockBuyOrders[_node][_maxPrice][0].amount*_maxPrice);
						//save the transaction
						StockTradeHistory(_node, block.timestamp, self.stockBuyOrders[_node][_maxPrice][0].client, msg.sender, 
						_maxPrice, self.stockBuyOrders[_node][_maxPrice][0].amount, self.stockBuyOrders[_node][_maxPrice][0].orderId);
						_amount -= self.stockBuyOrders[_node][_maxPrice][0].amount;
						_results[0] += self.stockBuyOrders[_node][_maxPrice][0].amount;
						//delete stockBuyOrders[_node][_maxPrice][0] and move each element
						CommonLibrary.stockDeleteFirstOrder(self, _node, _maxPrice, false);
						if(_amount < 1) break;
					}
					else {
						//edit stockBuyOrders[_node][_maxPrice][0]
						self.stockBuyOrders[_node][_maxPrice][0].amount -= _amount;
						//sell stocks for starcoins
						self.stockBalanceOf[msg.sender][_node] -= _amount;// subtracts _amount from seller&#39;s balance 
						self.stockBalanceOf[self.stockBuyOrders[_node][_maxPrice][0].client][_node] += _amount;// adds the _amount to buyer&#39;s balance
						//write stockOwnerInfo and stockOwners for dividends
						CommonLibrary.stockSaveOwnerInfo(self, _node, _amount, self.stockBuyOrders[_node][_maxPrice][0].client, msg.sender, _maxPrice);
						//transfer starcoins to seller
						self.balanceOf[msg.sender] += _amount*_maxPrice;// adds the _amount to buyer&#39;s balance 
						self.frozen[self.stockBuyOrders[_node][_maxPrice][0].client] -= _amount*_maxPrice;// subtracts _amount from seller&#39;s frozen balance
						Transfer(self.stockBuyOrders[_node][_maxPrice][0].client, msg.sender, _amount*_maxPrice);
						//save the transaction
						StockTradeHistory(_node, block.timestamp, self.stockBuyOrders[_node][_maxPrice][0].client, msg.sender, 
						_maxPrice, _amount, self.stockBuyOrders[_node][_maxPrice][0].orderId);
						_results[0] += _amount;
						_amount = 0;
						break;
					}
				}
				if (_amount < 1) {
					_results[3] = 1;
					break;
				}
			}
		}
		if (CommonLibrary.stockMaxBuyPrice(self, _sellPrice, _node) == _sellPrice - 1 && _amount >= 1) {
			//save new order
			_results[1] =  _amount;
			self.stockOrdersId += 1;
			_results[2] = self.stockOrdersId;
			self.stockSellOrders[_node][_sellPrice].push(StarCoinLibrary.stockOrderInfo(block.timestamp, msg.sender, _results[1], _sellPrice, false, self.stockOrdersId, _node));
		    _results[3] = 1;
			//transfer stocks to the frozen stock balance
			self.stockFrozen[msg.sender][_node] += _amount;
			self.stockBalanceOf[msg.sender][_node] -= _amount;
			//Add _sellPrice to stockSellOrderPrices[_node][]
			it[0] = 99999;
			for (it[1] = 0; it[1] < self.stockSellOrderPrices[_node].length; it[1]++) {
				if (self.stockSellOrderPrices[_node][it[1]] == _sellPrice) 
					it[0] = it[1];
			}
			if (it[0] == 99999) 
				self.stockSellOrderPrices[_node].push(_sellPrice);
		}
	}
	
	function stockCancelBuyOrder(StarCoinLibrary.Data storage self, uint _node, uint _thisOrderID, uint _price) public returns(bool) {
		for (uint iii = 0; iii < self.stockBuyOrders[_node][_price].length; iii++) {
			if (self.stockBuyOrders[_node][_price][iii].orderId == _thisOrderID) {
				require(msg.sender == self.stockBuyOrders[_node][_price][iii].client);
				//return starcoins from the buyer`s frozen balance
				self.frozen[msg.sender] -= self.stockBuyOrders[_node][_price][iii].amount*_price;
				self.balanceOf[msg.sender] += self.stockBuyOrders[_node][_price][iii].amount*_price;
				//delete stockBuyOrders[_node][_price][iii] and move each element
				for (uint ii = iii; ii < self.stockBuyOrders[_node][_price].length - 1; ii++) {
					self.stockBuyOrders[_node][_price][ii] = self.stockBuyOrders[_node][_price][ii + 1];
				}
				delete self.stockBuyOrders[_node][_price][self.stockBuyOrders[_node][_price].length - 1];
				self.stockBuyOrders[_node][_price].length--;
				break;
			}
		}
		//Delete _price from stockBuyOrderPrices[_node][] if it&#39;s the last order
		if (self.stockBuyOrders[_node][_price].length == 0) {
			uint _fromArg = 99999;
			for (iii = 0; iii < self.stockBuyOrderPrices[_node].length - 1; iii++) {
				if (self.stockBuyOrderPrices[_node][iii] == _price) {
					_fromArg = iii;
				}
				if (_fromArg != 99999 && iii >= _fromArg) self.stockBuyOrderPrices[_node][iii] = self.stockBuyOrderPrices[_node][iii + 1];
			}
			delete self.stockBuyOrderPrices[_node][self.stockBuyOrderPrices[_node].length-1];
			self.stockBuyOrderPrices[_node].length--;
		}
		return true;
	}
	
	function stockCancelSellOrder(StarCoinLibrary.Data storage self, uint _node, uint _thisOrderID, uint _price) public returns(bool) {
		for (uint iii = 0; iii < self.stockSellOrders[_node][_price].length; iii++) {
			if (self.stockSellOrders[_node][_price][iii].orderId == _thisOrderID) {
				require(msg.sender == self.stockSellOrders[_node][_price][iii].client);
				//return stocks from the seller`s frozen stock balance
				self.stockFrozen[msg.sender][_node] -= self.stockSellOrders[_node][_price][iii].amount;
				self.stockBalanceOf[msg.sender][_node] += self.stockSellOrders[_node][_price][iii].amount;
				//delete stockSellOrders[_node][_price][iii] and move each element
				for (uint ii = iii; ii < self.stockSellOrders[_node][_price].length - 1; ii++) {
					self.stockSellOrders[_node][_price][ii] = self.stockSellOrders[_node][_price][ii + 1];
				}
				delete self.stockSellOrders[_node][_price][self.stockSellOrders[_node][_price].length - 1];
				self.stockSellOrders[_node][_price].length--;
				break;
			}
		}
		//Delete _price from stockSellOrderPrices[_node][] if it&#39;s the last order
		if (self.stockSellOrders[_node][_price].length == 0) {
			uint _fromArg = 99999;
			for (iii = 0; iii < self.stockSellOrderPrices[_node].length - 1; iii++) {
				if (self.stockSellOrderPrices[_node][iii] == _price) {
					_fromArg = iii;
				}
				if (_fromArg != 99999 && iii >= _fromArg) self.stockSellOrderPrices[_node][iii] = self.stockSellOrderPrices[_node][iii + 1];
			}
			delete self.stockSellOrderPrices[_node][self.stockSellOrderPrices[_node].length-1];
			self.stockSellOrderPrices[_node].length--;
		}
		return true;
	}
}


library StarmidLibraryExtra {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event StockTransfer(address indexed from, address indexed to, uint indexed node, uint256 value);
	event StockTradeHistory(uint node, uint date, address buyer, address seller, uint price, uint amount, uint orderId);
	event TradeHistory(uint date, address buyer, address seller, uint price, uint amount, uint orderId);
	
	function buyCertainOrder(StarCoinLibrary.Data storage self, uint _price, uint _thisOrderID) returns (bool) {
		uint _remainingValue = msg.value;
		for (uint8 iii = 0; iii < self.sellOrders[_price].length; iii++) {
			if (self.sellOrders[_price][iii].orderId == _thisOrderID) {
				uint _amount = _remainingValue/_price;
				require(_amount <= self.sellOrders[_price][iii].amount);
				if (_amount == self.sellOrders[_price][iii].amount) {
					//buy starcoins for ether
					self.balanceOf[msg.sender] += self.sellOrders[_price][iii].amount;// adds the amount to buyer&#39;s balance
					self.frozen[self.sellOrders[_price][iii].client] -= self.sellOrders[_price][iii].amount;// subtracts the amount from seller&#39;s frozen balance
					Transfer(self.sellOrders[_price][iii].client, msg.sender, self.sellOrders[_price][iii].amount);
					//transfer ether to seller
					self.pendingWithdrawals[self.sellOrders[_price][iii].client] += _price*self.sellOrders[_price][iii].amount;
					//save the transaction
					TradeHistory(block.timestamp, msg.sender, self.sellOrders[_price][iii].client, _price, self.sellOrders[_price][iii].amount, 
					self.sellOrders[_price][iii].orderId);
					_remainingValue -= _price*self.sellOrders[_price][iii].amount;
					//delete sellOrders[_price][iii] and move each element
					for (uint ii = iii; ii < self.sellOrders[_price].length - 1; ii++) {
						self.sellOrders[_price][ii] = self.sellOrders[_price][ii + 1];
					}
					delete self.sellOrders[_price][self.sellOrders[_price].length - 1];
					self.sellOrders[_price].length--;
					//Delete _price from sellOrderPrices[] if it&#39;s the last order
					if (self.sellOrders[_price].length == 0) {
						uint fromArg = 99999;
						for (ii = 0; ii < self.sellOrderPrices.length - 1; ii++) {
							if (self.sellOrderPrices[ii] == _price) {
								fromArg = ii;
							}
							if (fromArg != 99999 && ii >= fromArg) 
								self.sellOrderPrices[ii] = self.sellOrderPrices[ii + 1];
						}
						delete self.sellOrderPrices[self.sellOrderPrices.length-1];
						self.sellOrderPrices.length--;
					}
					return true;
					break;
				}
				else {
					//edit sellOrders[_price][iii]
					self.sellOrders[_price][iii].amount = self.sellOrders[_price][iii].amount - _amount;
					//buy starcoins for ether
					self.balanceOf[msg.sender] += _amount;// adds the _amount to buyer&#39;s balance
					self.frozen[self.sellOrders[_price][iii].client] -= _amount;// subtracts the _amount from seller&#39;s frozen balance
					Transfer(self.sellOrders[_price][iii].client, msg.sender, _amount);
					//save the transaction
					TradeHistory(block.timestamp, msg.sender, self.sellOrders[_price][iii].client, _price, _amount, self.sellOrders[_price][iii].orderId);
					//transfer ether to seller
					self.pendingWithdrawals[self.sellOrders[_price][iii].client] += _amount*_price;
					_remainingValue -= _amount*_price;
					return true;
					break;
				}
			}
		}
		self.pendingWithdrawals[msg.sender] += _remainingValue;//returns change to buyer				
	}
	
	function sellCertainOrder(StarCoinLibrary.Data storage self, uint _amount, uint _price, uint _thisOrderID) returns (bool) {
		for (uint8 iii = 0; iii < self.buyOrders[_price].length; iii++) {
			if (self.buyOrders[_price][iii].orderId == _thisOrderID) {
				require(_amount <= self.buyOrders[_price][iii].amount && self.balanceOf[msg.sender] >= _amount);
				if (_amount == self.buyOrders[_price][iii].amount) {
					//sell starcoins for ether
					self.balanceOf[msg.sender] -= self.buyOrders[_price][iii].amount;// subtracts amount from seller&#39;s balance
					self.balanceOf[self.buyOrders[_price][iii].client] += self.buyOrders[_price][iii].amount;// adds the amount to buyer&#39;s balance
					Transfer(msg.sender, self.buyOrders[_price][iii].client, self.buyOrders[_price][iii].amount);
					//transfer ether to seller
					uint _amountTransfer = _price*self.buyOrders[_price][iii].amount;
					self.pendingWithdrawals[msg.sender] += _amountTransfer;
					//save the transaction
					TradeHistory(block.timestamp, self.buyOrders[_price][iii].client, msg.sender, _price, self.buyOrders[_price][iii].amount, 
					self.buyOrders[_price][iii].orderId);
					_amount -= self.buyOrders[_price][iii].amount;
					//delete buyOrders[_price][iii] and move each element
					for (uint ii = iii; ii < self.buyOrders[_price].length - 1; ii++) {
						self.buyOrders[_price][ii] = self.buyOrders[_price][ii + 1];
					}
					delete self.buyOrders[_price][self.buyOrders[_price].length - 1];
					self.buyOrders[_price].length--;
					//Delete _price from buyOrderPrices[] if it&#39;s the last order
					if (self.buyOrders[_price].length == 0) {
						uint _fromArg = 99999;
						for (uint8 iiii = 0; iiii < self.buyOrderPrices.length - 1; iiii++) {
							if (self.buyOrderPrices[iiii] == _price) {
								_fromArg = iiii;
							}
							if (_fromArg != 99999 && iiii >= _fromArg) self.buyOrderPrices[iiii] = self.buyOrderPrices[iiii + 1];
						}
						delete self.buyOrderPrices[self.buyOrderPrices.length-1];
						self.buyOrderPrices.length--;
					}
					return true;
					break;
				}
				else {
					//edit buyOrders[_price][iii]
					self.buyOrders[_price][iii].amount = self.buyOrders[_price][iii].amount - _amount;
					//buy starcoins for ether
					self.balanceOf[msg.sender] -= _amount;// subtracts amount from seller&#39;s balance
					self.balanceOf[self.buyOrders[_price][iii].client] += _amount;// adds the amount to buyer&#39;s balance 
					Transfer(msg.sender, self.buyOrders[_price][iii].client, _amount);
					//save the transaction
					TradeHistory(block.timestamp, self.buyOrders[_price][iii].client, msg.sender, _price, _amount, self.buyOrders[_price][iii].orderId);
					//transfer ether to seller
					self.pendingWithdrawals[msg.sender] += _price*_amount;
					return true;
					break;
				}
			}	
		}
	}
	
	function stockBuyCertainOrder(StarCoinLibrary.Data storage self, uint _node, uint _price, uint _amount, uint _thisOrderID) returns (bool) {
		require(self.balanceOf[msg.sender] >= _price*_amount);
		for (uint8 iii = 0; iii < self.stockSellOrders[_node][_price].length; iii++) {
			if (self.stockSellOrders[_node][_price][iii].orderId == _thisOrderID) {
				require(_amount <= self.stockSellOrders[_node][_price][iii].amount);
				if (_amount == self.stockSellOrders[_node][_price][iii].amount) {
					//buy stocks for starcoins
					self.stockBalanceOf[msg.sender][_node] += self.stockSellOrders[_node][_price][iii].amount;// add the amount to buyer&#39;s balance
					self.stockFrozen[self.stockSellOrders[_node][_price][iii].client][_node] -= self.stockSellOrders[_node][_price][iii].amount;// subtracts amount from seller&#39;s frozen stock balance
					//write stockOwnerInfo and stockOwners for dividends
					CommonLibrary.stockSaveOwnerInfo(self, _node, self.stockSellOrders[_node][_price][iii].amount, msg.sender, self.stockSellOrders[_node][_price][iii].client, _price);
					//transfer starcoins to seller
					self.balanceOf[msg.sender] -= self.stockSellOrders[_node][_price][iii].amount*_price;// subtracts amount from buyer&#39;s balance
					self.balanceOf[self.stockSellOrders[_node][_price][iii].client] += self.stockSellOrders[_node][_price][iii].amount*_price;// adds the amount to seller&#39;s balance
					Transfer(self.stockSellOrders[_node][_price][iii].client, msg.sender, self.stockSellOrders[_node][_price][iii].amount*_price);
					//save the transaction into event StocksTradeHistory;
					StockTradeHistory(_node, block.timestamp, msg.sender, self.stockSellOrders[_node][_price][iii].client, _price, 
					self.stockSellOrders[_node][_price][iii].amount, self.stockSellOrders[_node][_price][iii].orderId);
					_amount -= self.stockSellOrders[_node][_price][iii].amount;
					//delete stockSellOrders[_node][_price][iii] and move each element
					CommonLibrary.deleteStockSellOrder(self, iii, _node, _price);
					return true;
					break;
				}
				else {
					//edit stockSellOrders[_node][_price][iii]
					self.stockSellOrders[_node][_price][iii].amount -= _amount;
					//buy stocks for starcoins
					self.stockBalanceOf[msg.sender][_node] += _amount;// adds the amount to buyer&#39;s balance
					self.stockFrozen[self.stockSellOrders[_node][_price][iii].client][_node] -= _amount;// subtracts amount from seller&#39;s frozen stock balance
					//write stockOwnerInfo and stockOwners for dividends
					CommonLibrary.stockSaveOwnerInfo(self, _node, _amount, msg.sender, self.stockSellOrders[_node][_price][iii].client, _price);
					//transfer starcoins to seller
					self.balanceOf[msg.sender] -= _amount*_price;// subtracts amount from buyer&#39;s balance
					self.balanceOf[self.stockSellOrders[_node][_price][iii].client] += _amount*_price;// adds the amount to seller&#39;s balance
					Transfer(self.stockSellOrders[_node][_price][iii].client, msg.sender, _amount*_price);
					//save the transaction  into event StocksTradeHistory;
					StockTradeHistory(_node, block.timestamp, msg.sender, self.stockSellOrders[_node][_price][iii].client, _price, 
					_amount, self.stockSellOrders[_node][_price][iii].orderId);
					_amount = 0;
					return true;
					break;
				}
			}
		}
	}
	
	function stockSellCertainOrder(StarCoinLibrary.Data storage self, uint _node, uint _price, uint _amount, uint _thisOrderID) returns (bool results) {
		uint _remainingAmount = _amount;
		for (uint8 iii = 0; iii < self.stockBuyOrders[_node][_price].length; iii++) {
			if (self.stockBuyOrders[_node][_price][iii].orderId == _thisOrderID) {
				require(_amount <= self.stockBuyOrders[_node][_price][iii].amount && self.stockBalanceOf[msg.sender][_node] >= _amount);
				if (_remainingAmount == self.stockBuyOrders[_node][_price][iii].amount) {
					//sell stocks for starcoins
					self.stockBalanceOf[msg.sender][_node] -= self.stockBuyOrders[_node][_price][iii].amount;// subtracts amount from seller&#39;s balance 
					self.stockBalanceOf[self.stockBuyOrders[_node][_price][iii].client][_node] += self.stockBuyOrders[_node][_price][iii].amount;// adds the amount to buyer&#39;s balance
					//write stockOwnerInfo and stockOwners for dividends
					CommonLibrary.stockSaveOwnerInfo(self, _node, self.stockBuyOrders[_node][_price][iii].amount, self.stockBuyOrders[_node][_price][iii].client, msg.sender, _price);
					//transfer starcoins to seller
					self.balanceOf[msg.sender] += self.stockBuyOrders[_node][_price][iii].amount*_price;// adds the amount to buyer&#39;s balance 
					self.frozen[self.stockBuyOrders[_node][_price][iii].client] -= self.stockBuyOrders[_node][_price][iii].amount*_price;// subtracts amount from seller&#39;s frozen balance
					Transfer(self.stockBuyOrders[_node][_price][iii].client, msg.sender, self.stockBuyOrders[_node][_price][iii].amount*_price);
					//save the transaction
					StockTradeHistory(_node, block.timestamp, self.stockBuyOrders[_node][_price][iii].client, msg.sender, 
					_price, self.stockBuyOrders[_node][_price][iii].amount, self.stockBuyOrders[_node][_price][iii].orderId);
					_amount -= self.stockBuyOrders[_node][_price][iii].amount;
					//delete stockBuyOrders[_node][_price][iii] and move each element
					CommonLibrary.deleteStockBuyOrder(self, iii, _node, _price);
					results = true;
					break;
				}
				else {
					//edit stockBuyOrders[_node][_price][0]
					self.stockBuyOrders[_node][_price][iii].amount -= _amount;
					//sell stocks for starcoins
					self.stockBalanceOf[msg.sender][_node] -= _amount;// subtracts amount from seller&#39;s balance 
					self.stockBalanceOf[self.stockBuyOrders[_node][_price][iii].client][_node] += _amount;// adds the amount to buyer&#39;s balance
					//write stockOwnerInfo and stockOwners for dividends
					CommonLibrary.stockSaveOwnerInfo(self, _node, _amount, self.stockBuyOrders[_node][_price][iii].client, msg.sender, _price);
					//transfer starcoins to seller
					self.balanceOf[msg.sender] += _amount*_price;// adds the amount to buyer&#39;s balance 
					self.frozen[self.stockBuyOrders[_node][_price][iii].client] -= _amount*_price;// subtracts amount from seller&#39;s frozen balance
					Transfer(self.stockBuyOrders[_node][_price][iii].client, msg.sender, _amount*_price);
					//save the transaction
					StockTradeHistory(_node, block.timestamp, self.stockBuyOrders[_node][_price][iii].client, msg.sender, 
					_price, _amount, self.stockBuyOrders[_node][_price][iii].orderId);
					_amount = 0;
					results = true;
					break;
				}
			}	
		}
	}	
}


contract Nodes {
	address public owner;
	CommonLibrary.Data public vars;
	mapping (address => string) public confirmationNodes;
	uint confirmNodeId;
	uint40 changePercentId;
	uint40 pushNodeGroupId;
	uint40 deleteNodeGroupId;
	event NewNode(
		uint256 id, 
		string nodeName, 
		uint8 producersPercent, 
		address producer, 
		uint date
		);
	event OwnerNotation(uint256 id, uint date, string newNotation);
	event NewNodeGroup(uint16 id, string newNodeGroup);
	event AddNodeAddress(uint id, uint nodeID, address nodeAdress);
	event EditNode(
		uint nodeID,
		address nodeAdress, 
		address newProducer, 
		uint8 newProducersPercent,
		bool starmidConfirmed
		);
	event ConfirmNode(uint id, uint nodeID);
	event OutsourceConfirmNode(uint nodeID, address confirmationNode);
	event ChangePercent(uint id, uint nodeId, uint producersPercent);
	event PushNodeGroup(uint id, uint nodeId, uint newNodeGroup);
	event DeleteNodeGroup(uint id, uint nodeId, uint deleteNodeGroup);
	
	function Nodes() public {
		owner = msg.sender;
	}
	
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	
	//-----------------------------------------------------Nodes---------------------------------------------------------------
	function changeOwner(string _changeOwnerPassword, address _newOwnerAddress) onlyOwner returns(bool) {
		//One-time tool for emergency owner change
		if (keccak256(_changeOwnerPassword) == 0xe17a112b6fc12fc80c9b241de72da0d27ce7e244100f3c4e9358162a11bed629) {
			owner = _newOwnerAddress;
			return true;
		}
		else 
			return false;
	}
	
	function addOwnerNotations(string _newNotation) onlyOwner {
		uint date = block.timestamp;
		vars.ownerNotationId += 1;
		OwnerNotation(vars.ownerNotationId, date, _newNotation);
	}
	
	function addConfirmationNode(string _newConfirmationNode) public returns(bool) {
		confirmationNodes[msg.sender] = _newConfirmationNode;
		return true;
	}
	
	function addNodeGroup(string _newNodeGroup) onlyOwner returns(uint16 _id) {
		bool result;
		(result, _id) = CommonLibrary.addNodeGroup(vars, _newNodeGroup);
		require(result);
		NewNodeGroup(_id, _newNodeGroup);
	}
	
	function addNode(string _newNode, uint8 _producersPercent) returns(bool) {
		bool result;
		uint _id;
		(result, _id) = CommonLibrary.addNode(vars, _newNode, _producersPercent);
		require(result);
		NewNode(_id, _newNode, _producersPercent, msg.sender, block.timestamp);
		return true;
	}
	
	function editNode(
		uint _nodeID, 
		address _nodeAddress, 
		bool _isNewProducer, 
		address _newProducer, 
		uint8 _newProducersPercent,
		bool _starmidConfirmed
		) onlyOwner returns(bool) {
		bool x = CommonLibrary.editNode(vars, _nodeID, _nodeAddress,_isNewProducer, _newProducer, _newProducersPercent, _starmidConfirmed);
		require(x);
		EditNode(_nodeID, _nodeAddress, _newProducer, _newProducersPercent, _starmidConfirmed);
		return true;
	}
	
	
	function addNodeAddress(uint _nodeID, address _nodeAddress) public returns(bool) {
		bool _result;
		uint _id;
		(_result, _id) = CommonLibrary.addNodeAddress(vars, _nodeID, _nodeAddress);
		require(_result);
		AddNodeAddress(_id, _nodeID, _nodeAddress);
		return true; 
	}
	
	function pushNodeGroup(uint _nodeID, uint16 _newNodeGroup) public returns(bool) {
		require(msg.sender == vars.nodes[_nodeID].node);
		vars.nodes[_nodeID].nodeGroup.push(_newNodeGroup);
		pushNodeGroupId += 1;
		PushNodeGroup(pushNodeGroupId, _nodeID, _newNodeGroup);
		return true;
	}
	
	function deleteNodeGroup(uint _nodeID, uint16 _deleteNodeGroup) public returns(bool) {
		require(msg.sender == vars.nodes[_nodeID].node);
		for(uint16 i = 0; i < vars.nodes[_nodeID].nodeGroup.length; i++) {
			if(_deleteNodeGroup == vars.nodes[_nodeID].nodeGroup[i]) {
				for(uint16 ii = i; ii < vars.nodes[_nodeID].nodeGroup.length - 1; ii++) 
					vars.nodes[_nodeID].nodeGroup[ii] = vars.nodes[_nodeID].nodeGroup[ii + 1];
		    	delete vars.nodes[_nodeID].nodeGroup[vars.nodes[_nodeID].nodeGroup.length - 1];
				vars.nodes[_nodeID].nodeGroup.length--;
				break;
		    }
	    }
		deleteNodeGroupId += 1;
		DeleteNodeGroup(deleteNodeGroupId, _nodeID, _deleteNodeGroup);
		return true;
    }
	
	function confirmNode(uint _nodeID) onlyOwner returns(bool) {
		vars.nodes[_nodeID].starmidConfirmed = true;
		confirmNodeId += 1;
		ConfirmNode(confirmNodeId, _nodeID);
		return true;
	}
	
	function outsourceConfirmNode(uint _nodeID) public returns(bool) {
		vars.nodes[_nodeID].outsourceConfirmed.push(msg.sender);
		OutsourceConfirmNode(_nodeID, msg.sender);
		return true;
	}
	
	function changePercent(uint _nodeId, uint8 _producersPercent) public returns(bool){
		if(msg.sender == vars.nodes[_nodeId].producer && vars.nodes[_nodeId].node == 0x0000000000000000000000000000000000000000) {
			vars.nodes[_nodeId].producersPercent = _producersPercent;
			changePercentId += 1;
			ChangePercent(changePercentId, _nodeId, _producersPercent);
			return true;
		}
	}
	
	function getNodeInfo(uint _nodeID) constant public returns(
		address _producer, 
		address _node, 
		uint _date, 
		bool _starmidConfirmed, 
		string _nodeName, 
		address[] _outsourceConfirmed, 
		uint16[] _nodeGroup, 
		uint _producersPercent
		) {
		_producer = vars.nodes[_nodeID].producer;
		_node = vars.nodes[_nodeID].node;
		_date = vars.nodes[_nodeID].date;
		_starmidConfirmed = vars.nodes[_nodeID].starmidConfirmed;
		_nodeName = vars.nodes[_nodeID].nodeName;
		_outsourceConfirmed = vars.nodes[_nodeID].outsourceConfirmed;
		_nodeGroup = vars.nodes[_nodeID].nodeGroup;
		_producersPercent = vars.nodes[_nodeID].producersPercent;
	}
}	


contract Starmid {
	address public owner;
	Nodes public nodesVars;
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	StarCoinLibrary.Data public sCVars;
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	event BuyOrder(address indexed from, uint orderId, uint buyPrice);
	event SellOrder(address indexed from, uint orderId, uint sellPrice);
	event CancelBuyOrder(address indexed from, uint indexed orderId, uint price);
	event CancelSellOrder(address indexed from, uint indexed orderId, uint price);
	event TradeHistory(uint date, address buyer, address seller, uint price, uint amount, uint orderId);
    //----------------------------------------------------Starmid exchange
	event StockTransfer(address indexed from, address indexed to, uint indexed node, uint256 value);
	event StockBuyOrder(uint node, uint buyPrice);
	event StockSellOrder(uint node, uint sellPrice);
	event StockCancelBuyOrder(uint node, uint price);
	event StockCancelSellOrder(uint node, uint price);
	event StockTradeHistory(uint node, uint date, address buyer, address seller, uint price, uint amount, uint orderId);
	
	function Starmid(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) public {
		owner = 0x378B9eea7ab9C15d9818EAdDe1156A079Cd02ba8;
		totalSupply = initialSupply;  
		sCVars.balanceOf[msg.sender] = 5000000000;
		sCVars.balanceOf[0x378B9eea7ab9C15d9818EAdDe1156A079Cd02ba8] = initialSupply - 5000000000;                
		name = tokenName;                                   
		symbol = tokenSymbol;                               
		decimals = decimalUnits; 
		sCVars.lastMint = block.timestamp;
		sCVars.emissionLimits[1] = 500000; sCVars.emissionLimits[2] = 500000; sCVars.emissionLimits[3] = 500000;
		sCVars.emissionLimits[4] = 500000; sCVars.emissionLimits[5] = 500000; sCVars.emissionLimits[6] = 500000;
	}
	
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	//-----------------------------------------------------StarCoin Exchange------------------------------------------------------
	function getWithdrawal() constant public returns(uint _amount) {
        _amount = sCVars.pendingWithdrawals[msg.sender];
    }
	
	function withdraw() public returns(bool _result, uint _amount) {
        _amount = sCVars.pendingWithdrawals[msg.sender];
        sCVars.pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(_amount);
		_result = true;
    }
	
	function changeOwner(string _changeOwnerPassword, address _newOwnerAddress) onlyOwner returns(bool) {
		//One-time tool for emergency owner change
		if (keccak256(_changeOwnerPassword) == 0xe17a112b6fc12fc80c9b241de72da0d27ce7e244100f3c4e9358162a11bed629) {
			owner = _newOwnerAddress;
			return true;
		}
		else 
			return false;
	}
	
	function setNodesVars(address _addr) public {
	    require(msg.sender == 0xfCbA69eF1D63b0A4CcD9ceCeA429157bA48d6a9c);
		nodesVars = Nodes(_addr);
	}
	
	function getBalance(address _address) constant public returns(uint _balance) {
		_balance = sCVars.balanceOf[_address];
	}
	
	function getBuyOrderPrices() constant public returns(uint[] _prices) {
		_prices = sCVars.buyOrderPrices;
	}
	
	function getSellOrderPrices() constant public returns(uint[] _prices) {
		_prices = sCVars.sellOrderPrices;
	}
	
	function getOrderInfo(bool _isBuyOrder, uint _price, uint _number) constant public returns(address _address, uint _amount, uint _orderId) {
		if(_isBuyOrder == true) {
			_address = sCVars.buyOrders[_price][_number].client;
			_amount = sCVars.buyOrders[_price][_number].amount;
			_orderId = sCVars.buyOrders[_price][_number].orderId;
		}
		else {
			_address = sCVars.sellOrders[_price][_number].client;
			_amount = sCVars.sellOrders[_price][_number].amount;
			_orderId = sCVars.sellOrders[_price][_number].orderId;
		}
	}
	
	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	}
	
	function mint() public onlyOwner returns(uint _mintedAmount) {
		//Minted amount does not exceed 8,5% per annum. Thus, minting does not greatly increase the total supply 
		//and does not cause significant inflation and depreciation of the starcoin.
		_mintedAmount = (block.timestamp - sCVars.lastMint)*totalSupply/(12*31536000);//31536000 seconds in year
		sCVars.balanceOf[msg.sender] += _mintedAmount;
		totalSupply += _mintedAmount;
		sCVars.lastMint = block.timestamp;
		Transfer(0, this, _mintedAmount);
		Transfer(this, msg.sender, _mintedAmount);
	}
	
	function buyOrder(uint256 _buyPrice) payable public returns (uint[4] _results) {
		require(_buyPrice > 0 && msg.value > 0);
		_results = StarCoinLibrary.buyOrder(sCVars, _buyPrice);
		require(_results[3] == 1);
		BuyOrder(msg.sender, _results[2], _buyPrice);
	}
	
	function sellOrder(uint256 _sellPrice, uint _amount) public returns (uint[4] _results) {
		require(_sellPrice > 0 && _amount > 0);
		_results = StarCoinLibrary.sellOrder(sCVars, _sellPrice, _amount);
		require(_results[3] == 1);
		SellOrder(msg.sender, _results[2], _sellPrice);
	}
	
	function cancelBuyOrder(uint _thisOrderID, uint _price) public {
		require(StarCoinLibrary.cancelBuyOrder(sCVars, _thisOrderID, _price));
		CancelBuyOrder(msg.sender, _thisOrderID, _price);
	}
	
	function cancelSellOrder(uint _thisOrderID, uint _price) public {
		require(StarCoinLibrary.cancelSellOrder(sCVars, _thisOrderID, _price));
		CancelSellOrder(msg.sender, _thisOrderID, _price);
	}
	
	function _transfer(address _from, address _to, uint _value) internal {
		require(_to != 0x0);
        require(sCVars.balanceOf[_from] >= _value && sCVars.balanceOf[_to] + _value > sCVars.balanceOf[_to]);
        sCVars.balanceOf[_from] -= _value;
        sCVars.balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
	}
	
	function buyCertainOrder(uint _price, uint _thisOrderID) payable public returns (bool _results) {
		_results = StarmidLibraryExtra.buyCertainOrder(sCVars, _price, _thisOrderID);
		require(_results && msg.value > 0);
		BuyOrder(msg.sender, _thisOrderID, _price);
	}
	
	function sellCertainOrder(uint _amount, uint _price, uint _thisOrderID) public returns (bool _results) {
		_results = StarmidLibraryExtra.sellCertainOrder(sCVars, _amount, _price, _thisOrderID);
		require(_results && _amount > 0);
		SellOrder(msg.sender, _thisOrderID, _price);
	}
	//------------------------------------------------------Starmid exchange----------------------------------------------------------
	function stockTransfer(address _to, uint _node, uint _value) public {
		require(_to != 0x0);
        require(sCVars.stockBalanceOf[msg.sender][_node] >= _value && sCVars.stockBalanceOf[_to][_node] + _value > sCVars.stockBalanceOf[_to][_node]);
		var (x,y,) = nodesVars.getNodeInfo(_node);
		require(msg.sender != y);//nodeOwner cannot transfer his stocks, only sell
		sCVars.stockBalanceOf[msg.sender][_node] -= _value;
        sCVars.stockBalanceOf[_to][_node] += _value;
        StockTransfer(msg.sender, _to, _node, _value);
	}
	
	function getEmission(uint _node) constant public returns(uint _emissionNumber, uint _emissionDate, uint _emissionAmount) {
		_emissionNumber = sCVars.emissions[_node].emissionNumber;
		_emissionDate = sCVars.emissions[_node].date;
		_emissionAmount = sCVars.emissionLimits[_emissionNumber];
	}
	
	function emission(uint _node) public returns(bool _result, uint _emissionNumber, uint _emissionAmount, uint _producersPercent) {
		var (x,y,,,,,,z,) = nodesVars.getNodeInfo(_node);
		address _nodeOwner = y;
		address _nodeProducer = x;
		_producersPercent = z;
		require(msg.sender == _nodeOwner || msg.sender == _nodeProducer);
		uint allStocks;
		for (uint i = 1; i <= sCVars.emissions[_node].emissionNumber; i++) {
			allStocks += sCVars.emissionLimits[i];
		}
		if (_nodeOwner !=0x0000000000000000000000000000000000000000 && block.timestamp > sCVars.emissions[_node].date + 5184000 && 
		sCVars.stockBalanceOf[_nodeOwner][_node] <= allStocks/2 ) {
			_emissionNumber = sCVars.emissions[_node].emissionNumber + 1;
			sCVars.stockBalanceOf[_nodeOwner][_node] += sCVars.emissionLimits[_emissionNumber]*(100 - _producersPercent)/100;
			//save stockOwnerInfo for _nodeOwner
			uint thisNode = 0;
			for (i = 0; i < sCVars.stockOwnerInfo[_nodeOwner].nodes.length; i++) {
				if (sCVars.stockOwnerInfo[_nodeOwner].nodes[i] == _node) thisNode = 1;
			}
			if (thisNode == 0) sCVars.stockOwnerInfo[_nodeOwner].nodes.push(_node);
			sCVars.stockBalanceOf[_nodeProducer][_node] += sCVars.emissionLimits[_emissionNumber]*_producersPercent/100;
			//save stockOwnerInfo for _nodeProducer
			thisNode = 0;
			for (i = 0; i < sCVars.stockOwnerInfo[_nodeProducer].nodes.length; i++) {
				if (sCVars.stockOwnerInfo[_nodeProducer].nodes[i] == _node) thisNode = 1;
			}
			if (thisNode == 0) sCVars.stockOwnerInfo[_nodeProducer].nodes.push(_node);
			sCVars.emissions[_node].date = block.timestamp;
			sCVars.emissions[_node].emissionNumber = _emissionNumber;
			_emissionAmount = sCVars.emissionLimits[_emissionNumber];
			_result = true;
		}
		else _result = false;
	}
	
	function getStockOwnerInfo(address _address) constant public returns(uint[] _nodes) {
		_nodes = sCVars.stockOwnerInfo[_address].nodes;
	}
	
	function getStockBalance(address _address, uint _node) constant public returns(uint _balance) {
		_balance = sCVars.stockBalanceOf[_address][_node];
	}
	
	function getWithFrozenStockBalance(address _address, uint _node) constant public returns(uint _balance) {
		_balance = sCVars.stockBalanceOf[_address][_node] + sCVars.stockFrozen[_address][_node];
	}
	
	function getStockOrderInfo(bool _isBuyOrder, uint _node, uint _price, uint _number) constant public returns(address _address, uint _amount, uint _orderId) {
		if(_isBuyOrder == true) {
			_address = sCVars.stockBuyOrders[_node][_price][_number].client;
			_amount = sCVars.stockBuyOrders[_node][_price][_number].amount;
			_orderId = sCVars.stockBuyOrders[_node][_price][_number].orderId;
		}
		else {
			_address = sCVars.stockSellOrders[_node][_price][_number].client;
			_amount = sCVars.stockSellOrders[_node][_price][_number].amount;
			_orderId = sCVars.stockSellOrders[_node][_price][_number].orderId;
		}
	}
	
	function getStockBuyOrderPrices(uint _node) constant public returns(uint[] _prices) {
		_prices = sCVars.stockBuyOrderPrices[_node];
	}
	
	function getStockSellOrderPrices(uint _node) constant public returns(uint[] _prices) {
		_prices = sCVars.stockSellOrderPrices[_node];
	}
	
	function stockBuyOrder(uint _node, uint256 _buyPrice, uint _amount) public returns (uint[4] _results) {
		require(_node > 0 && _buyPrice > 0 && _amount > 0);
		_results = StarmidLibrary.stockBuyOrder(sCVars, _node, _buyPrice, _amount);
		require(_results[3] == 1);
		StockBuyOrder(_node, _buyPrice);
	}
	
	function stockSellOrder(uint _node, uint256 _sellPrice, uint _amount) public returns (uint[4] _results) {
		require(_node > 0 && _sellPrice > 0 && _amount > 0);
		_results = StarmidLibrary.stockSellOrder(sCVars, _node, _sellPrice, _amount);
		require(_results[3] == 1);
		StockSellOrder(_node, _sellPrice);
	}
	
	function stockCancelBuyOrder(uint _node, uint _thisOrderID, uint _price) public {
		require(StarmidLibrary.stockCancelBuyOrder(sCVars, _node, _thisOrderID, _price));
		StockCancelBuyOrder(_node, _price);
	}
	
	function stockCancelSellOrder(uint _node, uint _thisOrderID, uint _price) public {
		require(StarmidLibrary.stockCancelSellOrder(sCVars, _node, _thisOrderID, _price));
		StockCancelSellOrder(_node, _price);
	}
	
	function getLastDividends(uint _node) public constant returns (uint _lastDividents, uint _dividends) {
		uint stockAmount = sCVars.StockOwnersBuyPrice[msg.sender][_node].sumAmount;
		uint sumAmount = sCVars.StockOwnersBuyPrice[msg.sender][_node].sumAmount;
		if(sumAmount > 0) {
			uint stockAverageBuyPrice = sCVars.StockOwnersBuyPrice[msg.sender][_node].sumPriceAmount/sumAmount;
			uint dividendsBase = stockAmount*stockAverageBuyPrice;
			_lastDividents = sCVars.StockOwnersBuyPrice[msg.sender][_node].sumDateAmount/sumAmount;
			if(_lastDividents > 0)_dividends = (block.timestamp - _lastDividents)*dividendsBase/(10*31536000);
			else _dividends = 0;
		}
	}
	
	//--------------------------------Dividends (10% to stock owner, 2,5% to node owner per annum)------------------------------------
	function dividends(uint _node) public returns (bool _result, uint _dividends) {
		var (x,y,) = nodesVars.getNodeInfo(_node);
		uint _stockAmount = sCVars.StockOwnersBuyPrice[msg.sender][_node].sumAmount;
		uint _sumAmount = sCVars.StockOwnersBuyPrice[msg.sender][_node].sumAmount;
		if(_sumAmount > 0) {
			uint _stockAverageBuyPrice = sCVars.StockOwnersBuyPrice[msg.sender][_node].sumPriceAmount/_sumAmount;
			uint _dividendsBase = _stockAmount*_stockAverageBuyPrice;
			uint _averageDate = sCVars.StockOwnersBuyPrice[msg.sender][_node].sumDateAmount/_sumAmount;
			//Stock owner`s dividends
			uint _div = (block.timestamp - _averageDate)*_dividendsBase/(10*31536000);//31536000 seconds in year
			sCVars.balanceOf[msg.sender] += _div;
			//Node owner`s dividends
			uint _nodeDividends = (block.timestamp - _averageDate)*_dividendsBase/(40*31536000);//31536000 seconds in year
			sCVars.balanceOf[y] += _nodeDividends;
			sCVars.StockOwnersBuyPrice[msg.sender][_node].sumDateAmount = block.timestamp*_stockAmount;//set new average dividends date
			totalSupply += _div + _div/4;
			_dividends =  _div + _div/4;
			Transfer(this, msg.sender, _div);	
			Transfer(this, y, _div/4);	
			_result = true;
		}
	}
	
	function stockBuyCertainOrder(uint _node, uint _price, uint _amount, uint _thisOrderID) payable public returns (bool _results) {
		_results = StarmidLibraryExtra.stockBuyCertainOrder(sCVars, _node, _price, _amount, _thisOrderID);
		require(_results && _node > 0 && _amount > 0);
		StockBuyOrder(_node, _price);
	}
	
	function stockSellCertainOrder(uint _node, uint _price, uint _amount, uint _thisOrderID) public returns (bool _results) {
		_results = StarmidLibraryExtra.stockSellCertainOrder(sCVars, _node, _price, _amount, _thisOrderID);
		require(_results && _node > 0 && _amount > 0);
		StockSellOrder(_node, _price);
	}
}