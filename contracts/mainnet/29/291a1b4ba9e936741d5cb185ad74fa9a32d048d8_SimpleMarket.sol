pragma solidity ^0.4.19;

contract owned {
    address public owner;
    function owned() public {owner = msg.sender;}
    modifier onlyOwner {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) onlyOwner public {owner = newOwner;}
}

contract WithdrawalContract is owned {
    address public richest;
    uint public mostSent;
    mapping (address => uint) pendingWithdrawals;
    function WithdrawalContract() public payable {
        richest = msg.sender;
        mostSent = msg.value;
    }
    function becomeRichest() public payable returns (bool) {
        if (msg.value > mostSent) {
            pendingWithdrawals[richest] += msg.value;
            richest = msg.sender;
            mostSent = msg.value;
            return true;
        } else {
            return false;
        }
    }
    function withdraw() public onlyOwner {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    function setMostSent(uint _newMostSent) public onlyOwner {
        mostSent = _newMostSent;
    }
}

contract SimpleMarket is owned, WithdrawalContract {

    uint public    startPrice;
    uint public    fixPrice  = 0.1 ether;
    uint internal  decimals  = 0;
    bytes32 public productId = 0x0;

	struct UserStruct {
		uint userListPointer;
		bytes32[] productKeys;
		bytes32 userEmail;
		bytes32 userName;
		mapping(bytes32 => uint) productKeyPointers;
	}

	mapping(bytes32 => UserStruct) public userStructs;
	bytes32[] public userList;

	struct ProductStruct {
		uint productListPointer;
		bytes32 userKey;
		bytes32 size;
		uint productPrice;
		string delivery;
		bool inSale;
		address[] historyUser;
		uint[] historyDate;
		uint[] historyPrice;
	}

	mapping(bytes32 => ProductStruct) public productStructs;
	bytes32[] public productList;

	event LogNewUser(address sender, bytes32 userId);
	event LogNewProduct(address sender, bytes32 productId, bytes32 userId);
	event LogUserDeleted(address sender, bytes32 userId);
	event LogProductDeleted(address sender, bytes32 productId);

	function getUserCount() public constant returns(uint userCount) {
		return userList.length;
	}

	function getProductCount() public constant returns(uint productCount){
		return productList.length;
	}
	
	function getUserProductsKeys(bytes32 _userId) public view returns(bytes32[]){
	    require(isUser(_userId));
	    return userStructs[_userId].productKeys;
	}

	function getProductHistoryUser(bytes32 _productId) public view returns(address[]) {
	    return productStructs[_productId].historyUser;
	}

	function getProductHistoryDate(bytes32 _productId) public view returns(uint[]) {
	    return productStructs[_productId].historyDate;
	}

	function getProductHistoryPrice(bytes32 _productId) public view returns(uint[]) {
	    return productStructs[_productId].historyPrice;
	}

	function isUser(bytes32 userId) public constant returns(bool isIndeed) {
		if(userList.length==0) return false;
		return userList[userStructs[userId].userListPointer] == userId;
	}

	function isProduct(bytes32 _productId) public constant returns(bool isIndeed) {
		if(productList.length==0) return false;
		return productList[productStructs[_productId].productListPointer] == _productId;
	}

	function isUserProduct(bytes32 _productId, bytes32 _userId) public constant returns(bool isIndeed) {

		if(productList.length==0) return false;
		if(userList.length==0) return false;

		return productStructs[_productId].userKey == _userId;
	}

	function getUserProductCount(bytes32 userId) public constant returns(uint productCount) {
		require(isUser(userId));
		return userStructs[userId].productKeys.length;
	}

	function getUserProductAtIndex(bytes32 userId, uint row) public constant returns(bytes32 productKey) {
		require(isUser(userId));
		return userStructs[userId].productKeys[row];
	}

	function createUser(bytes32 _userName, bytes32 _userEmail) public {
	    require(msg.sender != 0);
        bytes32 userId = bytes32(msg.sender);
		require(!isUser(userId));

		userStructs[userId].userListPointer = userList.push(userId)-1;
		userStructs[userId].userEmail       = _userEmail;
		userStructs[userId].userName        = _userName;

		LogNewUser(msg.sender, userId);
	}

	function createProduct(bytes32 _size, string delivery, bytes32 _userName, bytes32 _userEmail) public payable returns(bool success) {
		
		require(msg.sender != 0);
        require(startPrice != 0);
        require(msg.value  >= startPrice);
        require(productList.length <= 100);
        
		bytes32 userId    = bytes32(msg.sender);
		uint productCount = productList.length + 1;
		productId         = bytes32(productCount);

        if(!isUser(userId)) {
            require(_userName !=0);
            require(_userEmail !=0);
            createUser(_userName, _userEmail);
        }

		require(isUser(userId));
		require(!isProduct(productId));

		productStructs[productId].productListPointer = productList.push(productId)-1;
		productStructs[productId].userKey            = userId;
		productStructs[productId].size               = _size;
		productStructs[productId].productPrice       = startPrice;
		productStructs[productId].delivery           = delivery;
		productStructs[productId].inSale             = false;

		productStructs[productId].historyUser.push(msg.sender);
		productStructs[productId].historyDate.push(now);
		productStructs[productId].historyPrice.push(startPrice);
		
		userStructs[userId].productKeyPointers[productId] = userStructs[userId].productKeys.push(productId) - 1;
		
		LogNewProduct(msg.sender, productId, userId);
		
		uint oddMoney = msg.value - startPrice;

        this.transfer(startPrice);
        uint countProduct = getProductCount();
        startPrice        = ((countProduct * fixPrice) + fixPrice) * 10 ** decimals;

        msg.sender.transfer(oddMoney);

		return true;
	}

	function deleteUser(bytes32 userId) public onlyOwner returns(bool succes) {

		require(isUser(userId));
		require(userStructs[userId].productKeys.length <= 0);

		uint rowToDelete  = userStructs[userId].userListPointer;
		bytes32 keyToMove = userList[userList.length-1];

		userList[rowToDelete]                  = keyToMove;
		userStructs[keyToMove].userListPointer = rowToDelete;
		userStructs[keyToMove].userEmail       = 0x0;
		userStructs[keyToMove].userName        = 0x0;

		userList.length--;

		LogUserDeleted(msg.sender, userId);

		return true;
	}

	function deleteProduct(bytes32 _productId) public onlyOwner returns(bool success) {
		
		require(isProduct(_productId));
		
		uint rowToDelete                              = productStructs[_productId].productListPointer;
		bytes32 keyToMove                             = productList[productList.length-1];

		productList[rowToDelete]                      = keyToMove;
		productStructs[_productId].productListPointer = rowToDelete;
		
		productList.length--;

		bytes32 userId = productStructs[_productId].userKey;
		rowToDelete    = userStructs[userId].productKeyPointers[_productId];
		keyToMove      = userStructs[userId].productKeys[userStructs[userId].productKeys.length-1];

		userStructs[userId].productKeys[rowToDelete]      = keyToMove;
		userStructs[userId].productKeyPointers[keyToMove] = rowToDelete;
		
		userStructs[userId].productKeys.length--;
		
		LogProductDeleted(msg.sender, _productId);
		uint countProduct = getProductCount();
		productId = bytes32(countProduct - 1);
		
		return true;
	}

	function changeOwner(
	    bytes32 _productId, 
	    bytes32 _oldOwner, 
	    bytes32 _newOwner, 
	    address oldOwner, 
	    string _newDelivery,
	    bytes32 _userName,
	    bytes32 _userEmail
	    ) public payable returns (bool success) {

	    require(isProduct(_productId));
	    require(isUser(_oldOwner));
	    require(msg.value >= productStructs[_productId].productPrice);

	    if(isUserProduct(_productId, _newOwner)) return false;

	    if(!isUser(_newOwner)) {
            require(_userName !=0);
            require(_userEmail !=0);
            createUser(_userName, _userEmail);
        }

	    productStructs[_productId].userKey  = _newOwner;
		productStructs[_productId].delivery = _newDelivery;
		productStructs[_productId].inSale   = false;

		productStructs[_productId].historyUser.push(msg.sender);
		productStructs[_productId].historyDate.push(now);
		productStructs[_productId].historyPrice.push(productStructs[_productId].productPrice);
		
    	userStructs[_newOwner].productKeyPointers[_productId] = userStructs[_newOwner].productKeys.push(_productId) - 1;

        bool start = false;

    	for(uint i=0;i<userStructs[_oldOwner].productKeys.length;i++) {
    	    if((i+1) == userStructs[_oldOwner].productKeys.length){
    	        userStructs[_oldOwner].productKeys[i] = 0x0;
    	    }else{
    	        if(userStructs[_oldOwner].productKeys[i] == _productId || start){
    	            userStructs[_oldOwner].productKeys[i] = userStructs[_oldOwner].productKeys[i+1];
    	            start = true;
    	        }
    	    }
		}
		
		delete userStructs[_oldOwner].productKeyPointers[_productId];
		delete userStructs[_oldOwner].productKeys[userStructs[_oldOwner].productKeys.length-1];
        userStructs[_oldOwner].productKeys.length--;
		
		this.transfer(msg.value);
		oldOwner.transfer(msg.value);

	    return true;
	}
	
	function changeInSale(bytes32 _productId, bytes32 _userId, uint _newPrice) public payable returns(bool success) {

	   require(isProduct(_productId));
	   require(isUser(_userId));

	   productStructs[_productId].productPrice = _newPrice;
	   productStructs[_productId].inSale       = true;

	   return true;
	}

    function setPrices(uint _newPrice) internal {
        require(_newPrice != 0);
        if(startPrice == 0) {
            startPrice = (1 ether / _newPrice) * 10 ** decimals;
        } else {
            uint countProduct = getProductCount();
            startPrice = (1 ether / (countProduct * _newPrice)) * 10 ** decimals;
        }
    }

    function setFixPrice(uint _newFixPrice) public payable onlyOwner returns(bool success) {
        require(msg.sender   != 0);
        require(_newFixPrice != 0);
        fixPrice = _newFixPrice;
        return true;
    }

    function setDecimals(uint _newDecimals) public payable onlyOwner returns(bool success) {
        require(msg.sender != 0);
        decimals = _newDecimals;
        return true;
    }

    function() public payable {}

    function SimpleMarket() public payable {
        startPrice = 0.1 ether;
    }
}