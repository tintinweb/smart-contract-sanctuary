pragma solidity ^0.4.16;


/**
 * @title WeBetCrypto
 * @author AL_X
 * @dev The WBC ERC-223 Token Contract
 */
contract WeBetCrypto {
    string public name = "We Bet Crypto";
    string public symbol = "WBC";
	
    address public selfAddress;
    address public admin;
    address[] private users;
	
    uint8 public decimals = 7;
    uint256 public relativeDateSave;
    uint256 public totalFunds;
    uint256 public totalSupply = 300000000000000;
    uint256 public pricePerEther;
    uint256 private amountInCirculation;
    uint256 private currentProfits;
    uint256 private currentIteration;
	uint256 private actualProfitSplit;
	
    bool public DAppReady;
    bool public isFrozen;
	bool public splitInService = true;
	bool private hasICORun;
    bool private running;
	bool[4] private devApprovals;
	
    mapping(address => uint256) balances;
    mapping(address => uint256) monthlyLimit;
	
    mapping(address => bool) isAdded;
    mapping(address => bool) freezeUser;
	
    mapping (address => mapping (address => uint256)) allowed;
	mapping (address => mapping (address => uint256)) cooldown;
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event CurrentTLSNProof(address indexed _from, string _proof);
    
	/**
	 * @notice Ensures admin is caller
	 */
    modifier isAdmin() {
        require(msg.sender == admin);
        //Continue executing rest of method body
        _;
    }
    
    /**
	 * @notice Re-entry protection
	 */
    modifier isRunning() {
        require(!running);
        running = true;
        _;
        running = false;
    }
    
	/**
	 * @notice Ensures system isn&#39;t frozen
	 */
    modifier requireThaw() {
        require(!isFrozen);
        _;
    }
    
	/**
	 * @notice Ensures player isn&#39;t logged in on platform
	 */
    modifier userNotPlaying(address _user) {
        require(!freezeUser[_user]);
        _;
    }
	
	/**
	 * @notice Ensures function runs only once
	 */
	modifier oneTime() {
		require(!hasICORun);
		_;
	}
    
	/**
	 * @notice Ensures WBC DApp is online
	 */
    modifier DAppOnline() {
        require(DAppReady);
        _;
    }
    
    /**
	 * @notice SafeMath Library safeSub Import
	 * @dev 
	        Since we are dealing with a limited currency
	        circulation of 30 million tokens and values
	        that will not surpass the uint256 limit, only
	        safeSub is required to prevent underflows.
	 */
    function safeSub(uint256 a, uint256 b) internal constant returns (uint256 z) {
        assert((z = a - b) <= a);
    }
	
	/**
	 * @notice WBC Constructor
	 * @dev 
	        Constructor function containing proper initializations such as 
	        token distribution to the team members and pushing the first 
	        profit split to 6 months when the DApp will already be live.
	 */
    function WeBetCrypto() {
        admin = msg.sender;
        selfAddress = this;
        balances[0x166Cb48973C2447dafFA8EFd3526da18076088de] = 22500000000000;
        addUser(0x166Cb48973C2447dafFA8EFd3526da18076088de);
        Transfer(selfAddress, 0x166Cb48973C2447dafFA8EFd3526da18076088de, 22500000000000);
        balances[0xE59CbD028f71447B804F31Cf0fC41F0e5E13f4bF] = 15000000000000;
        addUser(0xE59CbD028f71447B804F31Cf0fC41F0e5E13f4bF);
        Transfer(selfAddress, 0xE59CbD028f71447B804F31Cf0fC41F0e5E13f4bF, 15000000000000);
        balances[0x1ab13D2C1AC4303737981Ce8B8bD5116C84c744d] = 5000000000000;
        addUser(0x1ab13D2C1AC4303737981Ce8B8bD5116C84c744d);
        Transfer(selfAddress, 0x1ab13D2C1AC4303737981Ce8B8bD5116C84c744d, 5000000000000);
        balances[0x06908Df389Cf2589375b6908D0b1c8FcC34721B5] = 2500000000000;
        addUser(0x06908Df389Cf2589375b6908D0b1c8FcC34721B5);
        Transfer(selfAddress, 0x06908Df389Cf2589375b6908D0b1c8FcC34721B5, 2500000000000);
        balances[0xEdBd4c6757DC425321584a91bDB355Ce65c42b13] = 2500000000000;
        addUser(0xEdBd4c6757DC425321584a91bDB355Ce65c42b13);
        Transfer(selfAddress, 0xEdBd4c6757DC425321584a91bDB355Ce65c42b13, 2500000000000);
        balances[0x4309Fb4B31aA667673d69db1072E6dcD50Fd8858] = 2500000000000;
        addUser(0x4309Fb4B31aA667673d69db1072E6dcD50Fd8858);
        Transfer(selfAddress, 0x4309Fb4B31aA667673d69db1072E6dcD50Fd8858, 2500000000000);
        relativeDateSave = now + 180 days;
        pricePerEther = 33209;
        balances[selfAddress] = 250000000000000;
    }
    
    /**
     * @notice Check the name of the token ~ ERC-20 Standard
     * @return {
					"_name": "The token name"
				}
     */
    function name() external constant returns (string _name) {
        return name;
    }
    
	/**
     * @notice Check the symbol of the token ~ ERC-20 Standard
     * @return {
					"_symbol": "The token symbol"
				}
     */
    function symbol() external constant returns (string _symbol) {
        return symbol;
    }
    
    /**
     * @notice Check the decimals of the token ~ ERC-20 Standard
     * @return {
					"_decimals": "The token decimals"
				}
     */
    function decimals() external constant returns (uint8 _decimals) {
        return decimals;
    }
    
    /**
     * @notice Check the total supply of the token ~ ERC-20 Standard
     * @return {
					"_totalSupply": "Total supply of tokens"
				}
     */
    function totalSupply() external constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    
    /**
     * @notice Query the available balance of an address ~ ERC-20 Standard
	 * @param _owner The address whose balance we wish to retrieve
     * @return {
					"balance": "Balance of the address"
				}
     */
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }
	
	/**
	 * @notice Query the amount of tokens the spender address can withdraw from the owner address ~ ERC-20 Standard
	 * @param _owner The address who owns the tokens
	 * @param _spender The address who can withdraw the tokens
	 * @return {
					"remaining": "Remaining withdrawal amount"
				}
     */
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    /**
     * @notice Transfer tokens from an address to another ~ ERC-20 Standard
	 * @dev 
	        Adjusts the monthly limit in case the _from address is the Casino
	        and ensures that the user isn&#39;t logged in when retrieving funds
	        so as to prevent against a race attack with the Casino.
     * @param _from The address whose balance we will transfer
     * @param _to The recipient address
	 * @param _value The amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) external requireThaw userNotPlaying(_to) {
		require(cooldown[_from][_to] <= now);
        var _allowance = allowed[_from][_to];
        if (_from == selfAddress) {
            monthlyLimit[_to] = safeSub(monthlyLimit[_to], _value);
        }
        balances[_to] = balances[_to]+_value;
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][_to] = safeSub(_allowance, _value);
        addUser(_to);
        Transfer(_from, _to, _value);
    }
    
    /**
	 * @notice Authorize an address to retrieve funds from you ~ ERC-20 Standard
	 * @dev 
	        Each approval comes with a default cooldown of 30 minutes
	        to prevent against the ERC-20 race attack.
	 * @param _spender The address you wish to authorize
	 * @param _value The amount of tokens you wish to authorize
	 */
    function approve(address _spender, uint256 _value) external {
        allowed[msg.sender][_spender] = _value;
		cooldown[msg.sender][_spender] = now + 30 minutes;
        Approval(msg.sender, _spender, _value);
    }
	
	/**
	 * @notice Authorize an address to retrieve funds from you with a custom cooldown ~ ERC-20 Standard
	 * @dev Allowing custom cooldown for the ERC-20 race attack prevention.
	 * @param _spender The address you wish to authorize
	 * @param _value The amount of tokens you wish to authorize
	 * @param _cooldown The amount of seconds the recipient needs to wait before withdrawing the balance
	 */
    function approve(address _spender, uint256 _value, uint256 _cooldown) external {
        allowed[msg.sender][_spender] = _value;
		cooldown[msg.sender][_spender] = now + _cooldown;
        Approval(msg.sender, _spender, _value);
    }
    
    /**
	 * @notice Transfer the specified amount to the target address ~ ERC-20 Standard
	 * @dev 
	        A boolean is returned so that callers of the function 
	        will know if their transaction went through.
	 * @param _to The address you wish to send the tokens to
	 * @param _value The amount of tokens you wish to send
	 * @return {
					"success": "Transaction success"
				}
     */
    function transfer(address _to, uint256 _value) external isRunning requireThaw returns (bool success){
        bytes memory empty;
        if (_to == selfAddress) {
            return transferToSelf(_value, empty);
        } else if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }
    
    /**
	 * @notice Check whether address is a contract ~ ERC-223 Proposed Standard
	 * @param _address The address to check
	 * @return {
					"is_contract": "Result of query"
				}
     */
    function isContract(address _address) internal returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_address)
        }
        return length > 0;
    }
    
    /**
	 * @notice Transfer the specified amount to the target address with embedded bytes data ~ ERC-223 Proposed Standard
	 * @dev Includes an extra transferToSelf function to handle Casino deposits
	 * @param _to The address to transfer to
	 * @param _value The amount of tokens to transfer
	 * @param _data Any extra embedded data of the transaction
	 * @return {
					"success": "Transaction success"
				}
     */
    function transfer(address _to, uint256 _value, bytes _data) external isRunning requireThaw returns (bool success){
        if (_to == selfAddress) {
            return transferToSelf(_value, _data);
        } else if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }
    
    /**
	 * @notice Handles transfer to an ECA (Externally Controlled Account), a normal account ~ ERC-223 Proposed Standard
	 * @param _to The address to transfer to
	 * @param _value The amount of tokens to transfer
	 * @param _data Any extra embedded data of the transaction
	 * @return {
					"success": "Transaction success"
				}
     */
    function transferToAddress(address _to, uint256 _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        addUser(_to);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
	 * @notice Handles transfer to a contract ~ ERC-223 Proposed Standard
	 * @param _to The address to transfer to
	 * @param _value The amount of tokens to transfer
	 * @param _data Any extra embedded data of the transaction
	 * @return {
					"success": "Transaction success"
				}
     */
    function transferToContract(address _to, uint256 _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        WeBetCrypto rec = WeBetCrypto(_to);
        rec.tokenFallback(msg.sender, _value, _data);
        addUser(_to);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
	 * @notice Handles Casino deposits ~ Custom ERC-223 Proposed Standard Addition
	 * @param _value The amount of tokens to transfer
	 * @param _data Any extra embedded data of the transaction
	 * @return {
					"success": "Transaction success"
				}
     */
    function transferToSelf(uint256 _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[selfAddress] = balances[selfAddress]+_value;
        Transfer(msg.sender, selfAddress, _value);
		allowed[selfAddress][msg.sender] = _value + allowed[selfAddress][msg.sender];
		Approval(selfAddress, msg.sender, allowed[selfAddress][msg.sender]);
        return true;
    }
	
	/**
	 * @notice Empty tokenFallback method to ensure ERC-223 compatibility
	 * @param _sender The address who sent the ERC-223 tokens
	 * @param _value The amount of tokens the address sent to this contract
	 * @param _data Any embedded data of the transaction
	 */
	function tokenFallback(address _sender, uint256 _value, bytes _data) {}
	
	/**
	 * @notice Check the cooldown remaining until the allowee can withdraw the balance
	 * @param _allower The holder of the balance
	 * @param _allowee The recipient of the balance
	 * @return {
					"remaining": "Cooldown remaining in seconds"
				}
     */
	function checkCooldown(address _allower, address _allowee) external constant returns (uint256 remaining) {
		if (cooldown[_allower][_allowee] > now) {
			return (cooldown[_allower][_allowee] - now);
		} else {
			return 0;
		}
	}
	
	/**
	 * @notice Check how much Casino withdrawal balance remains for address
	 * @param _owner The address to check
	 * @return {
					"remaining": "Withdrawal balance remaining"
				}
     */
    function checkMonthlyLimit(address _owner) external constant returns (uint256 remaining) {
        return monthlyLimit[_owner];
    }
	
	/**
	 * @notice Retrieve ERC Tokens sent to contract
	 * @dev Feel free to contact us and retrieve your ERC tokens should you wish so.
	 * @param _token The token contract address
	 */
    function claimTokens(address _token) isAdmin external { 
		require(_token != selfAddress);
        WeBetCrypto token = WeBetCrypto(_token); 
        uint balance = token.balanceOf(selfAddress); 
        token.transfer(admin, balance); 
    }
    
	/**
	 * @notice Freeze token circulation - splitProfits internal
	 * @dev 
	        Ensures that one doesn&#39;t transfer his total balance mid-split to 
	        an account later in the split queue in order to receive twice the
	        monthly profits
	 */
    function assetFreeze() internal {
        isFrozen = true;
    }
    
	/**
	 * @notice Re-enable token circulation - splitProfits internal
	 */
    function assetThaw() internal {
        isFrozen = false;
    }
    
	/**
	 * @notice Freeze token circulation
	 * @dev To be used only in extreme circumstances.
	 */
    function emergencyFreeze() isAdmin external {
        isFrozen = true;
    }
    
	/**
	 * @notice Re-enable token circulation
	 * @dev To be used only in extreme circumstances
	 */
    function emergencyThaw() isAdmin external {
        isFrozen = false;
    }
	
	/**
	 * @notice Disable the splitting function
	 * @dev 
	        To be used in case the system is upgraded to a 
	        node.js operated profit reward system via the 
			alterBankBalance function. Ensures scalability 
			in case userbase gets too big.
	 */
	function emergencySplitToggle() isAdmin external {
		splitInService = !splitInService;
	}
    
	/**
	 * @notice Adjust the price of Ether according to Coin Market Cap&#39;s API
	 * @dev 
	        The subfolder is public domain so anyone can verify that we indeed got the price
	        from a trusted source at the time we updated it. 2 decimal precision is achieved
	        by multiplying the price of Ether by 100 and then offsetting the multiplication
	        in the calculation the price is used in. The TLSNotaryProof string can be added
	        to the end of https://webetcrypto.io/TLSNotary/ to get the perspective TLS proof.
	 * @param newPrice The new Ethereum price with 2 decimal precision
	 * @param TLSNotaryProof The webetcrypto.io subfolder the TLSNotary proof is stored
	 */
    function setPriceOfEther(uint256 newPrice, string TLSNotaryProof) external isAdmin {
        pricePerEther = newPrice;
        CurrentTLSNProof(selfAddress, TLSNotaryProof);
    }
	
	/**
	 * @notice Get the current 2-decimal precision price per token
	 * @dev 
	        The price retains the 2 decimal precision by multiplying it with
	        100 and offsetting that in the calculations the price is used in.
	        For example 50 means each token costs 0.50$.
	 * @return {
					"price": "Price of a single WBC Token"
				}
     */
	function getPricePerToken() public constant returns (uint256 price) {
        if (balances[selfAddress] > 200000000000000) {
            return 50;
        } else if (balances[selfAddress] > 150000000000000) {
			return 200;
		} else if (balances[selfAddress] > 100000000000000) {
			return 400;
		} else {
			return 550;
        }
    }
	
	/**
	 * @notice Convert Wei to WBC tokens
	 * @dev 
		    The _value is multiplied by 10^7 because of the 7 decimal precision
			of WBC and to ensure that a user can invest less than 1 ether and 
			still get his WBC tokens, preventing rounding errors. A hard cap
			of 500k WBC tokens per purchase is enforced so as to prevent users
			from buying large amounts at a higher or lower Ether price due to 
			hourly price updates.
	 * @param _value The amount of Wei to convert
	 * @return {
					"tokenAmount": "Amount of WBC Tokens input is worth"
				}
     */
	function calculateTokenAmount(uint256 _value) internal returns (uint256 tokenAmount) {
		tokenAmount = ((_value*(10**7)/1 ether)*pricePerEther)/getPricePerToken();
		assert(tokenAmount <= 5000000000000);
	}
	
	/**
	 * @notice Add the address to the user list 
	 * @dev Used for the splitting function to take it into account
	 * @param _user User to add to database
	 */
	function addUser(address _user) internal {
		if (!isAdded[_user]) {
            users.push(_user);
            monthlyLimit[_user] = 5000000000000;
            isAdded[_user] = true;
        }
	}
    
	/**
	 * @notice Split the monthly profits of the Casino to the users
	 * @dev 
			The formula that calculates the profit a user is owed can be seen on 
			the white paper. The actualProfitSplit variable stores the actual values
	   		that are distributed to the users to prevent rounding errors from burning 
			tokens. Since gas requirements will spike the more users use our platform,
			a loop-state-save is implemented to ensure scalability.
	 */
    function splitProfits() external {
		require(splitInService);
        uint i;
        if (!isFrozen) {
            require(now >= relativeDateSave);
            assetFreeze();
            require(balances[selfAddress] > 30000000000000);
            relativeDateSave = now + 30 days;
            currentProfits = ((balances[selfAddress]-30000000000000)/10)*7; 
            amountInCirculation = safeSub(300000000000000, balances[selfAddress]);
            currentIteration = 0;
			actualProfitSplit = 0;
        } else {
            for (i = currentIteration; i < users.length; i++) {
                monthlyLimit[users[i]] = 5000000000000;
                if (msg.gas < 240000) {
                    currentIteration = i;
                    break;
                }
				if (allowed[selfAddress][users[i]] == 0) {
					checkSplitEnd(i);
					continue;
				} else if ((balances[users[i]]/allowed[selfAddress][users[i]]) < 19) {
					checkSplitEnd(i);
                    continue;
                }
				actualProfitSplit += (balances[users[i]]*currentProfits)/amountInCirculation;
                balances[users[i]] += (balances[users[i]]*currentProfits)/amountInCirculation;
				checkSplitEnd(i);
                Transfer(selfAddress, users[i], (balances[users[i]]/amountInCirculation)*currentProfits);
            }
        }
    }
	
	/**
	 * @notice Change variables on split end
	 * @param i The current index of the split loop
	 */
	function checkSplitEnd(uint256 i) internal {
		if (i == users.length-1) {
			assetThaw();
			balances[0x166Cb48973C2447dafFA8EFd3526da18076088de] = balances[0x166Cb48973C2447dafFA8EFd3526da18076088de] + currentProfits/22;
			balances[selfAddress] = balances[selfAddress] - actualProfitSplit - currentProfits/22;
		}
	}
	
	/**
	 * @notice Split the unsold WBC of the ICO
	 * @dev 
			One time function to distribute the unsold tokens.
	 */
    function ICOSplit() external isAdmin oneTime {
        uint i;
        if (!isFrozen) {
            require((relativeDateSave - now) >= (relativeDateSave - 150 days));
            assetFreeze();
            require(balances[selfAddress] > 50000000000000);
            currentProfits = ((balances[selfAddress] - 50000000000000) / 10) * 7; 
            amountInCirculation = safeSub(300000000000000, balances[selfAddress]);
            currentIteration = 0;
			actualProfitSplit = 0;
        } else {
            for (i = currentIteration; i < users.length; i++) {
                if (msg.gas < 240000) {
                    currentIteration = i;
                    break;
                }
				actualProfitSplit += (balances[users[i]]*currentProfits)/amountInCirculation;
                balances[users[i]] += (balances[users[i]]*currentProfits)/amountInCirculation;
                if (i == users.length-1) {
                    assetThaw();
                    balances[selfAddress] = balances[selfAddress] - actualProfitSplit;
					hasICORun = true;
                }
                Transfer(selfAddress, users[i], (balances[users[i]]/amountInCirculation)*currentProfits);
            }
        }
    }
	
	/**
	 * @notice Sign that the DApp is ready
	 * @dev 
	        Only the core team members have access to this function. This is 
	        created as an extra layer of security for investors and users of 
			the coin, since a multi-signature approval is required before the 
			function that alters the Casino balance is used.
	 */
    function assureDAppIsReady() external {
        if (msg.sender == 0x166Cb48973C2447dafFA8EFd3526da18076088de) {
            devApprovals[0] = true;
        } else if (msg.sender == 0x1ab13D2C1AC4303737981Ce8B8bD5116C84c744d) {
            devApprovals[1] = true;
        } else if (msg.sender == 0xEC5a48d6F11F8a981aa3D913DA0A69194280cDBc) {
            devApprovals[2] = true;
        } else if (msg.sender == 0xE59CbD028f71447B804F31Cf0fC41F0e5E13f4bF) {
            devApprovals[3] = true;
        } else {
			revert();
		}
    }
	
	/**
     * @notice Verify that the DApp is ready
	 * @dev 
			Since iterating through the devApprovals array costs gas
			and the functions with the DAppOnline modifier are going
			to be repetitively used, it is better to store the DApp
			state in a variable that needs to be altered once.
	 */
    function isDAppReady() external isAdmin {
        uint8 numOfApprovals = 0;
        for (uint i = 0; i < devApprovals.length; i++) {
            if (devApprovals[i]) {
                numOfApprovals++;
            }
        }
        DAppReady = (numOfApprovals>=2);
    }
    
	/**
	 * @notice Rise or lower user bank balance - Backend Function
	 * @dev 
	        This allows real-time adjustment of the balance a user has within the Casino to
			represent earnings and losses. Underflow impossible since only bets can lower the
			balance.
	 * @param _toAlter The address whose Casino balance to alter
	 * @param _amount The amount to alter it by
	 */
    function alterBankBalance(address _toAlter, uint256 _amount, bool sign) external DAppOnline isAdmin {
        if (sign && (_amount+allowed[selfAddress][_toAlter]) > allowed[selfAddress][_toAlter]) {
			allowed[selfAddress][_toAlter] = _amount + allowed[selfAddress][_toAlter];
			Approval(selfAddress, _toAlter, allowed[selfAddress][_toAlter]);
        } else {
            allowed[selfAddress][_toAlter] = safeSub(allowed[selfAddress][_toAlter], _amount);
			Approval(selfAddress, _toAlter, allowed[selfAddress][_toAlter]);
        }
    }
    
	/**
	 * @notice Freeze user during platform use - Backend Function
	 * @dev Prevents against the ERC-20 race attack on the Casino
	 * @param _user The user to freeze
	 */
    function loginUser(address _user) external DAppOnline isAdmin {
        freezeUser[_user] = true;
    }
	
	/**
	 * @notice De-Freeze user - Backend Function
     * @dev Used when a user logs out or loses connection with the DApp
	 * @param _user The user to de-freeze
	 */
	function logoutUser(address _user) external DAppOnline isAdmin {
		freezeUser[_user] = false;
	}
    
    /**
	 * @notice Fallback function 
	 * @dev Triggered when Ether is sent to the contract. Throws intentionally to refund the sender.
	 */
    function() payable {
		revert();
    }
	
	/**
	 * @notice Purchase WBC Tokens for Address - ICO
	 * @param _recipient The recipient of the WBC tokens
	 */
	function buyTokensForAddress(address _recipient) external payable {
        totalFunds = totalFunds + msg.value;
        require(msg.value > 0);
		require(_recipient != admin);
		require((totalFunds/1 ether)*pricePerEther < 6000000000);
        addUser(_recipient);
		uint tokenAmount = calculateTokenAmount(msg.value);
		balances[selfAddress] = balances[selfAddress] - tokenAmount;
		assert(balances[selfAddress] >= 50000000000000);
        balances[_recipient] = balances[_recipient] + tokenAmount;
        Transfer(selfAddress, _recipient, tokenAmount);
        address etherTransfer = 0x166Cb48973C2447dafFA8EFd3526da18076088de;
        etherTransfer.transfer(msg.value);
    }
	
	/**
	 * @notice Purchase WBC Tokens for Self - ICO
	 */
	function buyTokensForSelf() external payable {
        totalFunds = totalFunds + msg.value;
		address etherTransfer = 0x166Cb48973C2447dafFA8EFd3526da18076088de;
        require(msg.value > 0);
		require(msg.sender != etherTransfer);
		require((totalFunds/1 ether)*pricePerEther < 6000000000);
        addUser(msg.sender);
		uint tokenAmount = calculateTokenAmount(msg.value);
		balances[selfAddress] = balances[selfAddress] - tokenAmount;
		assert(balances[selfAddress] >= 50000000000000);
        balances[msg.sender] = balances[msg.sender] + tokenAmount;
        Transfer(selfAddress, msg.sender, tokenAmount);
        etherTransfer.transfer(msg.value);
    }
}