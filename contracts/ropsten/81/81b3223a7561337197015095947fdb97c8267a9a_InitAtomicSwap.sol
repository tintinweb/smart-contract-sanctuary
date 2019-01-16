pragma solidity 0.4.25;



contract	InitAtomicSwap  {
    struct Initiations {
        address addressFrom;
        address addressTo;
        bool isShow;
        bool isRedeem;
        bool isInit;
        uint blockTimestamp;
        uint amount;
        bytes32 hashSecret;
    }
    
    //ConfirmedInitiations - struct for storing information about order that was already paid 
    struct ConfirmedInitiations {
        address addressFrom;
        address addressTo;
        bool isShow;
        bool isRedeem;
        bool isInit;
        uint blockTimestamp;
        uint amount;
        bytes32 hashSecret;
    }

    mapping(address=>Initiations) public inits;
    
    mapping(address=>mapping(bytes32=>ConfirmedInitiations)) public confirmedInits;
    
    modifier isInitCreated(address _addressOfInitiator) {
	    require(inits[_addressOfInitiator].isInit == false);
	    _;
	}
	
	modifier isValidHashsecret(string _password, address _addressOfInitiator) {
	    require(inits[_addressOfInitiator].hashSecret == keccak256(abi.encodePacked(
	        inits[_addressOfInitiator].addressFrom,
	        inits[_addressOfInitiator].addressTo,
	        inits[_addressOfInitiator].amount,
	        inits[_addressOfInitiator].blockTimestamp,
	        _password)));
	    _;
	}
	
	modifier isTxValid(address _addressOfInitiator, uint _blockTimestamp) {
	    require(inits[_addressOfInitiator].blockTimestamp >= _blockTimestamp);
	    _;
	}
    
    //addInit - this function will write data of order to mapping inits in Initiations struct with address of the sender key 
    function addInit(address _addressFrom, address _addressTo, uint _amount, string _password) public 
    isInitCreated(_addressFrom) 
    returns(bytes32) {
        inits[_addressFrom].addressFrom = _addressFrom;
        inits[_addressFrom].addressTo = _addressTo;
        inits[_addressFrom].isShow = false;
        inits[_addressFrom].isRedeem = false;
        inits[_addressFrom].isInit = true;
        inits[_addressFrom].blockTimestamp = now;
        inits[_addressFrom].amount = _amount;
        inits[_addressFrom].hashSecret = keccak256(abi.encodePacked(_addressFrom, _addressTo, _amount, inits[_addressFrom].blockTimestamp, _password));
        
        return inits[_addressFrom].hashSecret;
	}
	
	//getInit - this function returns data about order of the special address
	function getInit(address _addressOfInitiator) public view returns(address, address, uint, uint, bytes32) {
	    return (
	        inits[_addressOfInitiator].addressFrom, 
	        inits[_addressOfInitiator].addressTo, 
	       // inits[_addressOfInitiator].isShow, 
	       // inits[_addressOfInitiator].isRedeem, 
	       // inits[_addressOfInitiator].isInit,
	        inits[_addressOfInitiator].amount,
	        inits[_addressOfInitiator].blockTimestamp,
	        inits[_addressOfInitiator].hashSecret
	        );
	}
	
	//confirmInit function that write information about already sended tx
	function confirmInit(address _addressOfInitiator, string _password, bytes32 _txHash, uint _blockTimestamp) public 
	isValidHashsecret(_password, _addressOfInitiator) 
	isTxValid(_addressOfInitiator, _blockTimestamp) 
	returns(bool) {
	    confirmedInits[_addressOfInitiator][_txHash].addressFrom = inits[_addressOfInitiator].addressFrom;
	    confirmedInits[_addressOfInitiator][_txHash].addressTo = inits[_addressOfInitiator].addressTo;
	    confirmedInits[_addressOfInitiator][_txHash].isShow = inits[_addressOfInitiator].isShow;
	    confirmedInits[_addressOfInitiator][_txHash].isRedeem = inits[_addressOfInitiator].isRedeem;
	    confirmedInits[_addressOfInitiator][_txHash].isInit = inits[_addressOfInitiator].isInit;
	    confirmedInits[_addressOfInitiator][_txHash].amount = inits[_addressOfInitiator].amount;
	    confirmedInits[_addressOfInitiator][_txHash].blockTimestamp = inits[_addressOfInitiator].blockTimestamp;
	    confirmedInits[_addressOfInitiator][_txHash].hashSecret = inits[_addressOfInitiator].hashSecret;
	}
}