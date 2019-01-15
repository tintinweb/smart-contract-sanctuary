pragma solidity ^0.5.2;

interface ERC223Handler { 
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

interface ICOStickers {
    function giveSticker(address _to, uint256 _property) external;
}


contract ICOToken{
    using SafeMath for uint256;
    using SafeMath for uint;
    
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
    
    constructor(address _s) public{
        stickers = ICOStickers(_s);
        totalSupply = 0;
        owner = msg.sender;
    }
	address owner;
	address newOwner;
    
    uint256 constant internal MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant internal TOKEN_PRICE = 0.0001 ether;
    uint256 constant public fundingCap = 2000 ether;

    uint256 constant public IcoStartTime = 1546628400; // Jan 04 2019 20:00:00 GMT+0100
    uint256 constant public IcoEndTime = 1550084400; // Feb 13 2019 20:00:00 GMT+0100


    ICOStickers internal stickers;
    mapping(address => uint256) internal beneficiaryWithdrawAmount;
    mapping(address => uint256) public beneficiaryShares;
    uint256 public beneficiaryTotalShares;
    uint256 public beneficiaryPayoutPerShare;
    uint256 public icoFunding;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public etherSpent;
    mapping(address => mapping (address => uint256)) internal allowances;
    string constant public name = "0xchan ICO";
    string constant public symbol = "ZCI";
    uint8 constant public decimals = 18;
    uint256 public totalSupply;
    
    // --Events
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint value);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    
    event onICOBuy(address indexed from, uint256 tokens, uint256 bonusTokens);
    // --Events--
    
    // --Owner only functions
    function setNewOwner(address o) public onlyOwner {
		newOwner = o;
	}

	function acceptNewOwner() public {
		require(msg.sender == newOwner);
		owner = msg.sender;
	}
	
    // For the 0xchan ICO, the following beneficieries will be added.
    // 3 - Aritz
    // 3 - Sumpunk
    // 2 - Multisig wallet for bounties/audit payments
	function addBeneficiary(address b, uint256 shares) public onlyOwner {
	   require(block.timestamp < IcoStartTime, "ICO has started");
	   require(beneficiaryWithdrawAmount[b] == 0, "Already a beneficiary");
	   beneficiaryWithdrawAmount[b] = MAX_UINT256;
	   beneficiaryShares[b] = shares;
	   beneficiaryTotalShares += shares;
	}
	
	function removeBeneficiary(address b, uint256 shares) public onlyOwner {
	   require(block.timestamp < IcoStartTime, "ICO has started");
	   require(beneficiaryWithdrawAmount[b] != 0, "Not a beneficiary");
	   delete beneficiaryWithdrawAmount[b];
	   delete beneficiaryShares[b];
	   beneficiaryTotalShares -= shares;
	}
	
	// --Owner only functions--
    
    // --Public write functions
    function withdrawFunding(uint256 _amount) public {
        if (icoFunding == 0){
            require(address(this).balance >= fundingCap || block.timestamp >= IcoEndTime, "ICO hasn&#39;t ended");
            icoFunding = address(this).balance;
        }
        require(beneficiaryWithdrawAmount[msg.sender] > 0, "You&#39;re not a beneficiary");
        uint256 stash = beneficiaryStash(msg.sender);
        if (_amount >= stash){
            beneficiaryWithdrawAmount[msg.sender] = beneficiaryPayoutPerShare * beneficiaryShares[msg.sender];
            msg.sender.transfer(stash);
        }else{
            if (beneficiaryWithdrawAmount[msg.sender] == MAX_UINT256){
                beneficiaryWithdrawAmount[msg.sender] = _amount;
            }else{
                beneficiaryWithdrawAmount[msg.sender] += _amount;
            }
            msg.sender.transfer(_amount);
        }
    }
    
    function() payable external{
        require(block.timestamp >= IcoStartTime, "ICO hasn&#39;t started yet");
        require(icoFunding == 0 && block.timestamp < IcoEndTime, "ICO has ended");
        require(msg.value != 0 && ((msg.value % TOKEN_PRICE) == 0), "Must be a multiple of 0.0001 ETH");
        
        uint256 thisBalance = address(this).balance; 
        uint256 msgValue = msg.value;
        
        // While the extra ETH is appriciated, we set ourselves a hardcap and we&#39;re gonna stick to it!
        if (thisBalance > fundingCap){
            msgValue -= (thisBalance - fundingCap);
            require(msgValue != 0, "Funding cap has been reached");
            thisBalance = fundingCap;
        }
        
        uint256 oldBalance = thisBalance - msgValue;
        uint256 tokensToGive = (msgValue / TOKEN_PRICE) * 1e18;
        uint256 bonusTokens;
        
        uint256 difference;
        
        while (oldBalance < thisBalance){
            if (oldBalance < 500 ether){
                difference = min(500 ether, thisBalance) - oldBalance;
                bonusTokens += ((difference / TOKEN_PRICE) * 1e18) / 2;
                oldBalance += difference;
            }else if(oldBalance < 1250 ether){
                difference = min(1250 ether, thisBalance) - oldBalance;
                bonusTokens += ((difference / TOKEN_PRICE) * 1e18) / 5;
                oldBalance += difference;
            }else{
                difference = thisBalance - oldBalance;
                bonusTokens += ((difference / TOKEN_PRICE) * 1e18) / 10;
                oldBalance += difference;
            }
        }
        emit onICOBuy(msg.sender, tokensToGive, bonusTokens);
        
        tokensToGive += bonusTokens;
        balanceOf[msg.sender] += tokensToGive;
        totalSupply += tokensToGive;
        
        if (address(stickers) != address(0)){
            stickers.giveSticker(msg.sender, msgValue);
        }
        emit Transfer(address(this), msg.sender, tokensToGive, "");
        emit Transfer(address(this), msg.sender, tokensToGive);
        
        beneficiaryPayoutPerShare = thisBalance / beneficiaryTotalShares;
        etherSpent[msg.sender] += msgValue;
        if (msgValue != msg.value){
            // Finally return any extra ETH sent.
            msg.sender.transfer(msg.value - msgValue); 
        }
    }
    
    function transfer(address _to, uint _value, bytes memory _data, string memory _function) public returns(bool ok){
        actualTransfer(msg.sender, _to, _value, _data, _function, true);
        return true;
    }
    
    function transfer(address _to, uint _value, bytes memory _data) public returns(bool ok){
        actualTransfer(msg.sender, _to, _value, _data, "", true);
        return true;
    }
    function transfer(address _to, uint _value) public returns(bool ok){
        actualTransfer(msg.sender, _to, _value, "", "", true);
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        uint256 _allowance = allowances[_from][msg.sender];
        require(_allowance > 0, "Not approved");
        require(_allowance >= _value, "Over spending limit");
        allowances[_from][msg.sender] = _allowance.sub(_value);
        actualTransfer(_from, _to, _value, "", "", false);
        return true;
    }
    
    // --Public write functions--
     
    // --Public read-only functions
    function beneficiaryStash(address b) public view returns (uint256){
        uint256 withdrawAmount = beneficiaryWithdrawAmount[b];
        if (withdrawAmount == 0){
            return 0;
        }
        if (withdrawAmount == MAX_UINT256){
            return beneficiaryPayoutPerShare * beneficiaryShares[b];
        }
        return (beneficiaryPayoutPerShare * beneficiaryShares[b]) - withdrawAmount;
    }
    
    function allowance(address _sugardaddy, address _spender) public view returns (uint remaining) {
        return allowances[_sugardaddy][_spender];
    }
    
    // --Public read-only functions--
    
    
    
    // Internal functions
    
    function actualTransfer (address _from, address _to, uint _value, bytes memory _data, string memory _function, bool _careAboutHumanity) private {
        // You can only transfer this token after the ICO has ended.
        require(icoFunding != 0 || address(this).balance >= fundingCap || block.timestamp >= IcoEndTime, "ICO hasn&#39;t ended");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(_to != address(this), "You can&#39;t sell back your tokens");
        
        // Throwing an exception undos all changes. Otherwise changing the balance now would be a shitshow
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        if(_careAboutHumanity && isContract(_to)) {
            if (bytes(_function).length == 0){
                ERC223Handler receiver = ERC223Handler(_to);
                receiver.tokenFallback(_from, _value, _data);
            }else{
                bool success;
                bytes memory returnData;
                (success, returnData) = _to.call.value(0)(abi.encodeWithSignature(_function, _from, _value, _data));
                assert(success);
            }
        }
        emit Transfer(_from, _to, _value, _data);
        emit Transfer(_from, _to, _value);
    }
    
    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
    
    function min(uint256 i1, uint256 i2) private pure returns (uint256) {
        if (i1 < i2){
            return i1;
        }
        return i2;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0 || b == 0) {
           return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}