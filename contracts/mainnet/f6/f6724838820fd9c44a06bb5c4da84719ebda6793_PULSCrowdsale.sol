pragma solidity ^0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;

	/**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
	function Ownable() public {
		owner = tx.origin;
	}


	/**
     * @dev Throws if called by any account other than the owner.
     */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     *
     * @param _newOwner The address to transfer ownership to.
     */
	function transferOwnership(address _newOwner) onlyOwner public {
		require(_newOwner != address(0));
		owner = _newOwner;
	}
}








/**
 * @title BasicERC20 token.
 * @dev Basic version of ERC20 token with allowances.
 */
contract BasicERC20Token is Ownable {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);


    /**
     * @dev Function to check the amount of tokens for address.
     *
     * @param _owner Address which owns the tokens.
     * 
     * @return A uint256 specifing the amount of tokens still available to the owner.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    /**
     * @dev Function to check the total supply of tokens.
     *
     * @return The uint256 specifing the amount of tokens which are held by the contract.
     */
    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }


    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     *
     * @param _owner Address which owns the funds.
     * @param _spender Address which will spend the funds.
     *
     * @return The uint256 specifing the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    /**
     * @dev Internal function to transfer tokens.
     *
     * @param _from Address of the sender.
     * @param _to Address of the recipient.
     * @param _amount Amount to send.
     *
     * @return True if the operation was successful.
     */
    function _transfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        require (_from != 0x0);                               // Prevent transfer to 0x0 address
        require (_to != 0x0);                               // Prevent transfer to 0x0 address
        require (balances[_from] >= _amount);          // Check if the sender has enough tokens
        require (balances[_to] + _amount > balances[_to]);  // Check for overflows

        uint256 length;
        assembly {
            length := extcodesize(_to)
        }
        require (length == 0);

        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
        
        return true;
    }


    /**
     * @dev Function to transfer tokens.
     *
     * @param _to Address of the recipient.
     * @param _amount Amount to send.
     *
     * @return True if the operation was successful.
     */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _to, _amount);

        return true;
    }


    /**
     * @dev Transfer tokens from other address.
     *
     * @param _from Address of the sender.
     * @param _to Address of the recipient.
     * @param _amount Amount to send.
     *
     * @return True if the operation was successful.
     */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require (allowed[_from][msg.sender] >= _amount);          // Check if the sender has enough

        _transfer(_from, _to, _amount);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        return true;
    }


    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * 
     * @param _spender Address which will spend the funds.
     * @param _amount Amount of tokens to be spent.
     *
     * @return True if the operation was successful.
     */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        require (_spender != 0x0);                       // Prevent transfer to 0x0 address
        require (_amount >= 0);
        require (balances[msg.sender] >= _amount);       // Check if the msg.sender has enough to allow 

        if (_amount == 0) allowed[msg.sender][_spender] = _amount;
        else allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_amount);

        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
}

/**
 * @title PULS token
 * @dev Extends ERC20 token.
 */
contract PULSToken is BasicERC20Token {
	// Public variables of the token
	string public constant name = &#39;PULS Token&#39;;
	string public constant symbol = &#39;PULS&#39;;
	uint256 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 88888888000000000000000000;

	address public crowdsaleAddress;

	// Public structure to support token reservation.
	struct Reserve {
        uint256 pulsAmount;
        uint256 collectedEther;
    }

	mapping (address => Reserve) reserved;

	// Public structure to record locked tokens for a specific lock.
	struct Lock {
		uint256 amount;
		uint256 startTime;	// in seconds since 01.01.1970
		uint256 timeToLock; // in seconds
		bytes32 pulseLockHash;
	}
	
	// Public list of locked tokens for a specific address.
	struct lockList{
		Lock[] lockedTokens;
	}
	
	// Public list of lockLists.
	mapping (address => lockList) addressLocks;

	/**
     * @dev Throws if called by any account other than the crowdsale address.
     */
	modifier onlyCrowdsaleAddress() {
		require(msg.sender == crowdsaleAddress);
		_;
	}

	event TokenReservation(address indexed beneficiary, uint256 sendEther, uint256 indexed pulsAmount, uint256 reserveTypeId);
	event RevertingReservation(address indexed addressToRevert);
	event TokenLocking(address indexed addressToLock, uint256 indexed amount, uint256 timeToLock);
	event TokenUnlocking(address indexed addressToUnlock, uint256 indexed amount);


	/**
     * @dev The PULS token constructor sets the initial supply of tokens to the crowdsale address
     * account.
     */
	function PULSToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		
		crowdsaleAddress = msg.sender;

		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}


	/**
     * @dev Payable function.
     */
	function () external payable {
	}


	/**
     * @dev Function to check reserved amount of tokens for address.
     *
     * @param _owner Address of owner of the tokens.
     *
     * @return The uint256 specifing the amount of tokens which are held in reserve for this address.
     */
	function reserveOf(address _owner) public view returns (uint256) {
		return reserved[_owner].pulsAmount;
	}


	/**
     * @dev Function to check reserved amount of tokens for address.
     *
     * @param _buyer Address of buyer of the tokens.
     *
     * @return The uint256 specifing the amount of tokens which are held in reserve for this address.
     */
	function collectedEtherFrom(address _buyer) public view returns (uint256) {
		return reserved[_buyer].collectedEther;
	}


	/**
     * @dev Function to get number of locks for an address.
     *
     * @param _address Address who owns locked tokens.
     *
     * @return The uint256 length of array.
     */
	function getAddressLockedLength(address _address) public view returns(uint256 length) {
	    return addressLocks[_address].lockedTokens.length;
	}


	/**
     * @dev Function to get locked tokens amount for specific address for specific lock.
     *
     * @param _address Address of owner of locked tokens.
     * @param _index Index of specific lock.
     *
     * @return The uint256 specifing the amount of locked tokens.
     */
	function getLockedStructAmount(address _address, uint256 _index) public view returns(uint256 amount) {
	    return addressLocks[_address].lockedTokens[_index].amount;
	}


	/**
     * @dev Function to get start time of lock for specific address.
     *
     * @param _address Address of owner of locked tokens.
     * @param _index Index of specific lock.
     *
     * @return The uint256 specifing the start time of lock in seconds.
     */
	function getLockedStructStartTime(address _address, uint256 _index) public view returns(uint256 startTime) {
	    return addressLocks[_address].lockedTokens[_index].startTime;
	}


	/**
     * @dev Function to get duration time of lock for specific address.
     *
     * @param _address Address of owner of locked tokens.
     * @param _index Index of specific lock.
     *
     * @return The uint256 specifing the duration time of lock in seconds.
     */
	function getLockedStructTimeToLock(address _address, uint256 _index) public view returns(uint256 timeToLock) {
	    return addressLocks[_address].lockedTokens[_index].timeToLock;
	}

	
	/**
     * @dev Function to get pulse hash for specific address for specific lock.
     *
     * @param _address Address of owner of locked tokens.
     * @param _index Index of specific lock.
     *
     * @return The bytes32 specifing the pulse hash.
     */
	function getLockedStructPulseLockHash(address _address, uint256 _index) public view returns(bytes32 pulseLockHash) {
	    return addressLocks[_address].lockedTokens[_index].pulseLockHash;
	}


	/**
     * @dev Function to send tokens after verifing KYC form.
     *
     * @param _beneficiary Address of receiver of tokens.
     *
     * @return True if the operation was successful.
     */
	function sendTokens(address _beneficiary) onlyOwner public returns (bool) {
		require (reserved[_beneficiary].pulsAmount > 0);		 // Check if reserved tokens for _beneficiary address is greater then 0

		_transfer(crowdsaleAddress, _beneficiary, reserved[_beneficiary].pulsAmount);

		reserved[_beneficiary].pulsAmount = 0;

		return true;
	}


	/**
     * @dev Function to reserve tokens for buyer after sending ETH to crowdsale address.
     *
     * @param _beneficiary Address of reserver of tokens.
     * @param _pulsAmount Amount of tokens to reserve.
     * @param _eth Amount of eth sent in transaction.
     *
     * @return True if the operation was successful.
     */
	function reserveTokens(address _beneficiary, uint256 _pulsAmount, uint256 _eth, uint256 _reserveTypeId) onlyCrowdsaleAddress public returns (bool) {
		require (_beneficiary != 0x0);					// Prevent transfer to 0x0 address
		require (totalSupply >= _pulsAmount);           // Check if such tokens amount left

		totalSupply = totalSupply.sub(_pulsAmount);
		reserved[_beneficiary].pulsAmount = reserved[_beneficiary].pulsAmount.add(_pulsAmount);
		reserved[_beneficiary].collectedEther = reserved[_beneficiary].collectedEther.add(_eth);

		emit TokenReservation(_beneficiary, _eth, _pulsAmount, _reserveTypeId);
		return true;
	}


	/**
     * @dev Function to revert reservation for some address.
     *
     * @param _addressToRevert Address to which collected ETH will be returned.
     *
     * @return True if the operation was successful.
     */
	function revertReservation(address _addressToRevert) onlyOwner public returns (bool) {
		require (reserved[_addressToRevert].pulsAmount > 0);	

		totalSupply = totalSupply.add(reserved[_addressToRevert].pulsAmount);
		reserved[_addressToRevert].pulsAmount = 0;

		_addressToRevert.transfer(reserved[_addressToRevert].collectedEther - (20000000000 * 21000));
		reserved[_addressToRevert].collectedEther = 0;

		emit RevertingReservation(_addressToRevert);
		return true;
	}


	/**
     * @dev Function to lock tokens for some period of time.
     *
     * @param _amount Amount of locked tokens.
     * @param _minutesToLock Days tokens will be locked.
     * @param _pulseLockHash Hash of locked pulse.
     *
     * @return True if the operation was successful.
     */
	function lockTokens(uint256 _amount, uint256 _minutesToLock, bytes32 _pulseLockHash) public returns (bool){
		require(balances[msg.sender] >= _amount);

		Lock memory lockStruct;
        lockStruct.amount = _amount;
        lockStruct.startTime = now;
        lockStruct.timeToLock = _minutesToLock * 1 minutes;
        lockStruct.pulseLockHash = _pulseLockHash;

        addressLocks[msg.sender].lockedTokens.push(lockStruct);
        balances[msg.sender] = balances[msg.sender].sub(_amount);

        emit TokenLocking(msg.sender, _amount, _minutesToLock);
        return true;
	}


	/**
     * @dev Function to unlock tokens for some period of time.
     *
     * @param _addressToUnlock Addrerss of person with locked tokens.
     *
     * @return True if the operation was successful.
     */
	function unlockTokens(address _addressToUnlock) public returns (bool){
		uint256 i = 0;
		while(i < addressLocks[_addressToUnlock].lockedTokens.length) {
			if (now > addressLocks[_addressToUnlock].lockedTokens[i].startTime + addressLocks[_addressToUnlock].lockedTokens[i].timeToLock) {

				balances[_addressToUnlock] = balances[_addressToUnlock].add(addressLocks[_addressToUnlock].lockedTokens[i].amount);
				emit TokenUnlocking(_addressToUnlock, addressLocks[_addressToUnlock].lockedTokens[i].amount);

				if (i < addressLocks[_addressToUnlock].lockedTokens.length) {
					for (uint256 j = i; j < addressLocks[_addressToUnlock].lockedTokens.length - 1; j++){
			            addressLocks[_addressToUnlock].lockedTokens[j] = addressLocks[_addressToUnlock].lockedTokens[j + 1];
			        }
				}
		        delete addressLocks[_addressToUnlock].lockedTokens[addressLocks[_addressToUnlock].lockedTokens.length - 1];
				
				addressLocks[_addressToUnlock].lockedTokens.length = addressLocks[_addressToUnlock].lockedTokens.length.sub(1);
			}
			else {
				i = i.add(1);
			}
		}

        return true;
	}
}





/**
 * @title SafeMath.
 * @dev Math operations with safety checks that throw on error.
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

/**
 * @title Staged crowdsale.
 * @dev Functionality of staged crowdsale.
 */
contract StagedCrowdsale is Ownable {

    using SafeMath for uint256;

    // Public structure of crowdsale&#39;s stages.
    struct Stage {
        uint256 hardcap;
        uint256 price;
        uint256 minInvestment;
        uint256 invested;
        uint256 closed;
    }

    Stage[] public stages;


    /**
     * @dev Function to get the current stage number.
     * 
     * @return A uint256 specifing the current stage number.
     */
    function getCurrentStage() public view returns(uint256) {
        for(uint256 i=0; i < stages.length; i++) {
            if(stages[i].closed == 0) {
                return i;
            }
        }
        revert();
    }


    /**
     * @dev Function to add the stage to the crowdsale.
     *
     * @param _hardcap The hardcap of the stage.
     * @param _price The amount of tokens you will receive per 1 ETH for this stage.
     */
    function addStage(uint256 _hardcap, uint256 _price, uint256 _minInvestment, uint _invested) onlyOwner public {
        require(_hardcap > 0 && _price > 0);
        Stage memory stage = Stage(_hardcap.mul(1 ether), _price, _minInvestment.mul(1 ether).div(10), _invested.mul(1 ether), 0);
        stages.push(stage);
    }


    /**
     * @dev Function to close the stage manually.
     *
     * @param _stageNumber Stage number to close.
     */
    function closeStage(uint256 _stageNumber) onlyOwner public {
        require(stages[_stageNumber].closed == 0);
        if (_stageNumber != 0) require(stages[_stageNumber - 1].closed != 0);

        stages[_stageNumber].closed = now;
        stages[_stageNumber].invested = stages[_stageNumber].hardcap;

        if (_stageNumber + 1 <= stages.length - 1) {
            stages[_stageNumber + 1].invested = stages[_stageNumber].hardcap;
        }
    }


    /**
     * @dev Function to remove all stages.
     *
     * @return True if the operation was successful.
    */
    function removeStages() onlyOwner public returns (bool) {
        require(stages.length > 0);

        stages.length = 0;

        return true;
    }
}

/**
 * @title PULS crowdsale
 * @dev PULS crowdsale functionality.
 */
contract PULSCrowdsale is StagedCrowdsale {
	using SafeMath for uint256;

	PULSToken public token;

	// Public variables of the crowdsale
	address public multiSigWallet; 	// address where funds are collected
	bool public hasEnded;
	bool public isPaused;	


	event TokenReservation(address purchaser, address indexed beneficiary, uint256 indexed sendEther, uint256 indexed pulsAmount);
	event ForwardingFunds(uint256 indexed value);


	/**
     * @dev Throws if crowdsale has ended.
     */
	modifier notEnded() {
		require(!hasEnded);
		_;
	}


	/**
     * @dev Throws if crowdsale has not ended.
     */
	modifier notPaused() {
		require(!isPaused);
		_;
	}


	/**
     * @dev The Crowdsale constructor sets the multisig wallet for forwanding funds.
     * Adds stages to the crowdsale. Initialize PULS tokens.
     */
	function PULSCrowdsale() public {
		token = createTokenContract();

		multiSigWallet = 0x00955149d0f425179000e914F0DFC2eBD96d6f43;
		hasEnded = false;
		isPaused = false;

		addStage(3000, 1600, 1, 0);   //3rd value is actually div 10
		addStage(3500, 1550, 1, 0);   //3rd value is actually div 10
		addStage(4000, 1500, 1, 0);   //3rd value is actually div 10
		addStage(4500, 1450, 1, 0);   //3rd value is actually div 10
		addStage(42500, 1400, 1, 0);  //3rd value is actually div 10
	}


	/**
     * @dev Function to create PULS tokens contract.
     *
     * @return PULSToken The instance of PULS token contract.
     */
	function createTokenContract() internal returns (PULSToken) {
		return new PULSToken();
	}


	/**
     * @dev Payable function.
     */
	function () external payable {
		buyTokens(msg.sender);
	}


	/**
     * @dev Function to buy tokens - reserve calculated amount of tokens.
     *
     * @param _beneficiary The address of the buyer.
     */
	function buyTokens(address _beneficiary) payable notEnded notPaused public {
		require(msg.value >= 0);
		
		uint256 stageIndex = getCurrentStage();
		Stage storage stageCurrent = stages[stageIndex];

		require(msg.value >= stageCurrent.minInvestment);

		uint256 tokens;

		// if puts us in new stage - receives with next stage price
		if (stageCurrent.invested.add(msg.value) >= stageCurrent.hardcap){
			stageCurrent.closed = now;

			if (stageIndex + 1 <= stages.length - 1) {
				Stage storage stageNext = stages[stageIndex + 1];

				tokens = msg.value.mul(stageCurrent.price);
				token.reserveTokens(_beneficiary, tokens, msg.value, 0);

				stageNext.invested = stageCurrent.invested.add(msg.value);

				stageCurrent.invested = stageCurrent.hardcap;
			}
			else {
				tokens = msg.value.mul(stageCurrent.price);
				token.reserveTokens(_beneficiary, tokens, msg.value, 0);

				stageCurrent.invested = stageCurrent.invested.add(msg.value);

				hasEnded = true;
			}
		}
		else {
			tokens = msg.value.mul(stageCurrent.price);
			token.reserveTokens(_beneficiary, tokens, msg.value, 0);

			stageCurrent.invested = stageCurrent.invested.add(msg.value);
		}

		emit TokenReservation(msg.sender, _beneficiary, msg.value, tokens);
		forwardFunds();
	}


	/**
     * @dev Function to buy tokens - reserve calculated amount of tokens.
     *
     * @param _beneficiary The address of the buyer.
     */
	function privatePresaleTokenReservation(address _beneficiary, uint256 _amount, uint256 _reserveTypeId) onlyOwner public {
		require (_reserveTypeId > 0);
		token.reserveTokens(_beneficiary, _amount, 0, _reserveTypeId);
		emit TokenReservation(msg.sender, _beneficiary, 0, _amount);
	}


	/**
     * @dev Internal function to forward funds to multisig wallet.
     */
	function forwardFunds() internal {
		multiSigWallet.transfer(msg.value);
		emit ForwardingFunds(msg.value);
	}


	/**
     * @dev Function to finish the crowdsale.
     *
     * @return True if the operation was successful.
     */ 
	function finishCrowdsale() onlyOwner notEnded public returns (bool) {
		hasEnded = true;
		return true;
	}


	/**
     * @dev Function to pause the crowdsale.
     *
     * @return True if the operation was successful.
     */ 
	function pauseCrowdsale() onlyOwner notEnded notPaused public returns (bool) {
		isPaused = true;
		return true;
	}


	/**
     * @dev Function to unpause the crowdsale.
     *
     * @return True if the operation was successful.
     */ 
	function unpauseCrowdsale() onlyOwner notEnded public returns (bool) {
		isPaused = false;
		return true;
	}


	/**
     * @dev Function to change multisgwallet.
     *
     * @return True if the operation was successful.
     */ 
	function changeMultiSigWallet(address _newMultiSigWallet) onlyOwner public returns (bool) {
		multiSigWallet = _newMultiSigWallet;
		return true;
	}
}