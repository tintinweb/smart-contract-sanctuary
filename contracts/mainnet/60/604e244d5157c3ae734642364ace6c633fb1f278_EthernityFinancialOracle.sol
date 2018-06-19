pragma solidity ^0.4.18;


// EthernityFinancialOracle v0.2
// @ethernity.live


contract Caller {
    function EFOcallBack(string _response);
}


contract EthernityFinancialOracle{
    
    address public owner;
    address public oracleAddress;
    uint public collectedFee; 
    uint public feePrice = 0.0005 ether;
    uint public gasLimit = 50000;
    uint public gasPrice = 40000000000 wei;
    
    struct User {
    	string response;
    	bool callBack;
    	bool asked;
    	uint balance;
    	bool banned;
    }

    mapping(address => User) public users;

    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    modifier onlyOracle{
        require(msg.sender == oracleAddress);
        _;
    }

    modifier onlyOwnerOrOracle {
    	require(msg.sender == owner || msg.sender == oracleAddress);
    	_;
    }

    modifier notBanned {
        require( users[msg.sender].banned == false );
        _;
    }

    modifier receivePayment {
        users[msg.sender].balance = users[msg.sender].balance + msg.value;
        _;
    }

    event Request (string _coin , string _againstCoin , address _address , uint _gasPrice , uint _gasLimit );
    event Response (address _address , string _response);
    event Error (string _error);
    

    // Main constructor
    function EthernityFinancialOracle() {
        owner = msg.sender;
        oracleAddress = msg.sender; // 0xfb509f6900d0326520c8f88e8f12c83459a199ec;
    }   

    // Payable to receive payments and stores into the mapping through modifier
    function () payable receivePayment {
    }

    // REQUESTS
    
    function requestEtherToUSD(bool _callBack , uint _gasPrice , uint _gasLimit) payable receivePayment notBanned {
        (_gasPrice , _gasLimit) = payToOracle (_gasPrice , _gasLimit);
        users[msg.sender].callBack = _callBack;
        users[msg.sender].asked = true;
        Request (&#39;ETH&#39;, &#39;USD&#39;, msg.sender , _gasPrice , _gasLimit );
    }
    
    function requestCoinToUSD(string _coin , bool _callBack , uint _gasPrice , uint _gasLimit) payable receivePayment notBanned {
    	(_gasPrice , _gasLimit) = payToOracle (_gasPrice , _gasLimit);
        users[msg.sender].callBack = _callBack;
        users[msg.sender].asked = true;
        Request (_coin, &#39;USD&#39;, msg.sender , _gasPrice , _gasLimit );
    }
    
    function requestRate(string _coin, string _againstCoin , bool _callBack , uint _gasPrice , uint _gasLimit) payable receivePayment notBanned {
    	(_gasPrice , _gasLimit) = payToOracle (_gasPrice , _gasLimit);
        users[msg.sender].callBack = _callBack;
        users[msg.sender].asked = true;
        Request (_coin, _againstCoin, msg.sender , _gasPrice , _gasLimit );
    }


    function getRefund() {
        if (msg.sender == owner) {
            uint a = collectedFee;
            collectedFee = 0; 
            require(owner.send(a));
        } else {
	        uint b = users[msg.sender].balance;
	        users[msg.sender].balance = 0;
	        require(msg.sender.send(b));
	    	}
    }


    // GETTERS

    function getResponse() public constant returns(string _response){
        return users[msg.sender].response;
    }

    function getPrice(uint _gasPrice , uint _gasLimit) public constant returns(uint _price) {
        if (_gasPrice == 0) _gasPrice = gasPrice;
        if (_gasLimit == 0) _gasLimit = gasLimit;
    	assert(_gasLimit * _gasPrice / _gasLimit == _gasPrice); // To avoid overflow exploitation
    	return feePrice + _gasLimit * _gasPrice;
    }

    function getBalance() public constant returns(uint _balance) {
    	return users[msg.sender].balance;
    }

    function getBalance(address _address) public constant returns(uint _balance) {
		return users[_address].balance;
    }



    // SET RESPONSE FROM ORACLE
    function setResponse (address _user, string _result) onlyOracle {

		require( users[_user].asked );
		users[_user].asked = false;

    	if ( users[_user].callBack ) {
    		// Callback function: passive, expensive, somewhat private
        	Caller _caller = Caller(_user);
        	_caller.EFOcallBack(_result);
    		} else {
    	// Mapping: active, cheap, public
        users[_user].response = _result;
        Response( _user , _result );
    	}

    }


    // INTERNAL FUNCTIONS

    function payToOracle (uint _gasPrice , uint _gasLimit) internal returns(uint _price , uint _limit) {
        if (_gasPrice == 0) _gasPrice = gasPrice;
        if (_gasLimit == 0) _gasLimit = gasLimit;

        uint gp = getPrice(_gasPrice,_gasLimit);

        require (users[msg.sender].balance >= gp );

        collectedFee += feePrice;
        users[msg.sender].balance -= gp;

        require(oracleAddress.send(gp - feePrice));
        return(_gasPrice,_gasLimit);
    }


    // ADMIN FUNCTIONS
    
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }

    function changeOracleAdd(address _newOracleAdd) onlyOwner {
        oracleAddress = _newOracleAdd;
    }

    function setFeePrice(uint _feePrice) onlyOwner {
        feePrice = _feePrice;
    }

    function setGasPrice(uint _gasPrice) onlyOwnerOrOracle {
    	gasPrice = _gasPrice;
    }

    function setGasLimit(uint _gasLimit) onlyOwnerOrOracle {
    	gasLimit = _gasLimit;
    }

    function emergencyFlush() onlyOwner {
        require(owner.send(this.balance));
    }

    function ban(address _user) onlyOwner{
        users[_user].banned = true;
    }
    
    function desBan(address _user) onlyOwner{
        users[_user].banned = false;
    }
}