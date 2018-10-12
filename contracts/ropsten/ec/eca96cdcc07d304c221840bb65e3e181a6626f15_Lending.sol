pragma solidity ^0.4.25;

/**
 * Definition of contract accepting THC tokens
 * Games, casinos, anything can reuse this contract to support AcceptsTHC tokens
 * ...
 * M3Divval
 * ...
 */
contract AcceptsTHC {
    Prosperity public tokenContract;

    constructor(address _tokenContract) public {
        tokenContract = Prosperity(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    /**
    * @dev Standard ERC677 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}


contract Lending {
	
	/*==============================
    =            EVENTS            =
    ==============================*/    
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
	
	
	/*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    /*modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }*/
	
	
	/*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    uint256 internal tokenSupply_ = 0;
	
	// administrator (see above on what they can do)
    address public administrator_;
    
	
	/*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    constructor()
        public
    {
        administrator_ = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
    }
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there&#39;s 0% fee here.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        //onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // withdraw all outstanding dividends first
        //if(myDividends(true) > 0) withdraw();

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        
        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        
        // ERC20
        return true;
    }
	
	/**
    * Transfer token to a specified address and forward the data to recipient
    * ERC-677 standard
    * https://github.com/ethereum/EIPs/issues/677
    * @param _to    Receiver address.
    * @param _value Amount of tokens that will be transferred.
    * @param _data  Transaction metadata.
    */
    function transferAndCall(address _to, uint256 _value, bytes _data) 
		external 
		returns (bool) 
	{
		require(_to != address(0));
		require(transfer(_to, _value)); 			// do a normal token transfer to the contract

		if (isContract(_to)) {
			AcceptsTHC receiver = AcceptsTHC(_to);
			require(receiver.tokenFallback(msg.sender, _value, _data));
		}

		return true;
    }

    /**
     * Additional check that the game address we are sending tokens to is a contract
     * assemble the given address bytecode. If bytecode exists then the _addr is a contract.
     */
     function isContract(address _addr) 
		private 
		constant 
		returns (bool is_contract) 
	{
		// retrieve the size of the code on target address, this needs assembly
		uint length;
		assembly { length := extcodesize(_addr) }
		return length > 0;
    }
}


contract Prosperity {}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}