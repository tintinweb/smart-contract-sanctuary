pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract MANToken {
    string public name; // MAN
    string public symbol; // MAN
    uint256 public decimals = 18;
    uint256 DECIMALSFACTOR = 10**decimals;
    uint256 constant weiDECIMALS = 18; 
    uint256 weiFACTOR =  10 ** weiDECIMALS; 
    
    address ethFundAddress  = 0xdF039a39899eC1Bc571eBcb7944B3b3A0A30C36d; 

    address address1 = 0x75C6CBe2cd50932D1E565A9B1Aea9F7671c7fEbc; 
    address address2 = 0xD94D499685bDdC28477f394bf3d7e4Ba729077f6; 
    address address3 = 0x11786422E7dF7A88Ea47C2dA76EE0a94aD2c5c64; 
    address address4 = 0xb1Df8C1a78582Db6CeEbFe6aAE3E01617198322e; 
    address address5 = 0x7eCc05F2da74036a9152dB3a4891f0AFDBB4eCc2; 
    address address6 = 0x39aC1d06EA941E2A41113F54737D49d9dD2c5022; 
    address address7 = 0x371895F2000053a61216011Aa43542cdd0dEb750; 
    address address8 = 0xf6a5F686bAd809b2Eb163fBE7Df646c472458852; 
    address address9 = 0xD21eF6388b232E5ceb6c2a43F93D7337dEb63274; 
    address address10 = 0xE92fFe240773E1F60fe17db7fAF8a3CdCD7bC6EC;

    uint256 public startTime; 
    uint256 public endTime; 
    uint256 lockedDuration = 3 * 24 * 60 * 60; 
    uint256 tokenPerETH = 3780; 

    address contractOwner; 
    uint256 ethRaised; 
    uint256 tokenDistributed; 
    uint256 donationCount; 
    uint256 public currentTokenPerETH = tokenPerETH;     

    uint256 public totalSupply = 250 * (10**6) * DECIMALSFACTOR;
    uint256 softCap = 20 * (10**6) * DECIMALSFACTOR; 
    uint256 reservedAmountPerAddress = 20 * (10**6) * DECIMALSFACTOR;
    uint256 minimumDonation = 5 * 10 ** (weiDECIMALS - 1); 
    
    uint256 public availableSupply = totalSupply; 
    uint8 public currentStage = 0;
    bool public isInLockStage = true;
    bool public finalised = false;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    function MANToken(
        string tokenName,
        string tokenSymbol,
        uint256 _startTimestamp,
        uint256 _endTimestamp) 
    public {
        contractOwner = msg.sender;

        name = tokenName; 
        symbol = tokenSymbol; 
        startTime = _startTimestamp;
        endTime = _endTimestamp; 

        balanceOf[address1] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[address2] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[address3] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[address4] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[address5] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[address6] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[address7] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[address8] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[address9] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[address10] += reservedAmountPerAddress;
        availableSupply -= reservedAmountPerAddress;

        balanceOf[contractOwner] = availableSupply;
    }


    function () payable public {
        require(!finalised);

        require(block.timestamp >= startTime);
        require(block.timestamp <= endTime);

        require(availableSupply > 0);

        mintMAN(); 
    }

    function mintMAN() payable public {
        require(msg.value >= minimumDonation); 

        uint256 preLockedTime = startTime + lockedDuration;
        
        if (block.timestamp <= preLockedTime) { 
            currentStage = 0;
            isInLockStage = true;
        }else if (block.timestamp > preLockedTime && tokenDistributed <= softCap) { 
            currentStage = 1;
            isInLockStage = true;
        }else if (block.timestamp > preLockedTime && tokenDistributed <= 35 * (10**6) * DECIMALSFACTOR) { 
            currentTokenPerETH = 3430;
            currentStage = 2;
            isInLockStage = false;
        }else if (block.timestamp > preLockedTime && tokenDistributed >= 35 * (10**6) * DECIMALSFACTOR) { 
            currentTokenPerETH = 3150;
            currentStage = 3;
            isInLockStage = false;
        }

        uint256 tokenValue = currentTokenPerETH * msg.value / 10 ** (weiDECIMALS - decimals);
        uint256 etherValue = msg.value;

        if (tokenValue > availableSupply) {
            tokenValue = availableSupply;
            
            etherValue = weiFACTOR * availableSupply / currentTokenPerETH / DECIMALSFACTOR;

            require(msg.sender.send(msg.value - etherValue));
        }

        ethRaised += etherValue;
        donationCount += 1;
        availableSupply -= tokenValue;

        _transfer(contractOwner, msg.sender, tokenValue);
        tokenDistributed += tokenValue;

        require(ethFundAddress.send(etherValue));
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        require(!isInLockStage);
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }

    function finalise() public {
        require( msg.sender == contractOwner );
        require(!finalised);

        finalised = true;
    } 

	function unlockTokens() public {
        require(msg.sender == contractOwner);
        isInLockStage = false;
    }

    function tokenHasDistributed() public constant returns (uint256) {
        return tokenDistributed;
    }
}