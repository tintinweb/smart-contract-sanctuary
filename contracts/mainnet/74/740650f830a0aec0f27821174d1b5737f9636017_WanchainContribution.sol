pragma solidity ^0.4.11;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


pragma solidity ^0.4.11;


/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.11;

contract ERC20Protocol {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint supply);
    is replaced with:
    uint public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


pragma solidity ^0.4.11;

//import "./ERC20Protocol.sol";
//import "./SafeMath.sol";

contract StandardToken is ERC20Protocol {
    using SafeMath for uint;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
}




pragma solidity ^0.4.11;


/*

  Copyright 2017 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | &#39;_ \ / __| &#39;_ \ / _` | | &#39;_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//  Code style according to: https://github.com/wanchain/wanchain-token/blob/master/style-guide.rst



//import "./StandardToken.sol";
//import "./SafeMath.sol";


/// @title Wanchain Token Contract
/// For more information about this token sale, please visit https://wanchain.org
/// @author Cathy - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="177476637f6e57607679747f767e7939786570">[email&#160;protected]</a>>
contract WanToken is StandardToken {
    using SafeMath for uint;

    /// Constant token specific fields
    string public constant name = "WanCoin";
    string public constant symbol = "WAN";
    uint public constant decimals = 18;

    /// Wanchain total tokens supply
    uint public constant MAX_TOTAL_TOKEN_AMOUNT = 210000000 ether;

    /// Fields that are only changed in constructor
    /// Wanchain contribution contract
    address public minter;
    /// ICO start time
    uint public startTime;
    /// ICO end time
    uint public endTime;

    /// Fields that can be changed by functions
    mapping (address => uint) public lockedBalances;
    /*
     * MODIFIERS
     */

    modifier onlyMinter {
    	  assert(msg.sender == minter);
    	  _;
    }

    modifier isLaterThan (uint x){
    	  assert(now > x);
    	  _;
    }

    modifier maxWanTokenAmountNotReached (uint amount){
    	  assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
    	  _;
    }

    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the Wanchain Token
     * @param _minter The Wanchain Contribution Contract
     * @param _startTime ICO start time
     * @param _endTime ICO End Time
     */
    function WanToken(address _minter, uint _startTime, uint _endTime){
    	  minter = _minter;
    	  startTime = _startTime;
    	  endTime = _endTime;
    }

    /**
     * EXTERNAL FUNCTION
     *
     * @dev Contribution contract instance mint token
     * @param receipent The destination account owned mint tokens
     * @param amount The amount of mint token
     * be sent to this address.
     */
    function mintToken(address receipent, uint amount)
        external
        onlyMinter
        maxWanTokenAmountNotReached(amount)
        returns (bool)
    {
      	lockedBalances[receipent] = lockedBalances[receipent].add(amount);
      	totalSupply = totalSupply.add(amount);
      	return true;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// @dev Locking period has passed - Locked tokens have turned into tradeable
    ///      All tokens owned by receipent will be tradeable
    function claimTokens(address receipent)
        public
        onlyMinter
    {
      	balances[receipent] = balances[receipent].add(lockedBalances[receipent]);
      	lockedBalances[receipent] = 0;
    }

    /*
     * CONSTANT METHODS
     */
    function lockedBalanceOf(address _owner) constant returns (uint balance) {
        return lockedBalances[_owner];
    }
}


pragma solidity ^0.4.11;

/*

  Copyright 2017 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | &#39;_ \ / __| &#39;_ \ / _` | | &#39;_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//  Code style according to: https://github.com/wanchain/wanchain-token/blob/master/style-guide.rst

/// @title Wanchain Contribution Contract
/// ICO Rules according: https://www.wanchain.org/crowdsale
/// For more information about this token sale, please visit https://wanchain.org
/// @author Zane Liang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2f554e414a43464e41486f584e414c474e464101405d48">[email&#160;protected]</a>>
contract WanchainContribution is Owned {
    using SafeMath for uint;

    /// Constant fields
    /// Wanchain total tokens supply
    uint public constant WAN_TOTAL_SUPPLY = 210000000 ether;
    uint public constant MAX_CONTRIBUTION_DURATION = 3 days;

    /// Exchange rates for first phase
    uint public constant PRICE_RATE_FIRST = 880;
    /// Exchange rates for second phase
    uint public constant PRICE_RATE_SECOND = 790;
    /// Exchange rates for last phase
    uint public constant PRICE_RATE_LAST = 750;

    /// ----------------------------------------------------------------------------------------------------
    /// |                                                  |                    |                 |        |
    /// |        PUBLIC SALE (PRESALE + OPEN SALE)         |      DEV TEAM      |    FOUNDATION   |  MINER |
    /// |                       51%                        |         20%        |       19%       |   10%  |
    /// ----------------------------------------------------------------------------------------------------
      /// OPEN_SALE_STAKE + PRESALE_STAKE = 51; 51% sale for public
      uint public constant OPEN_SALE_STAKE = 459;  // 45.9% for open sale
      uint public constant PRESALE_STAKE = 51;     // 5.1%  for presale

      // Reserved stakes
      uint public constant DEV_TEAM_STAKE = 200;   // 20%
      uint public constant FOUNDATION_STAKE = 190; // 19%
      uint public constant MINERS_STAKE = 100;     // 10%

      uint public constant DIVISOR_STAKE = 1000;

      /// Holder address for presale and reserved tokens
      /// TODO: change addressed before deployed to main net
      address public constant PRESALE_HOLDER = 0xca8f76fd9597e5c0ea5ef0f83381c0635271cd5d;

      // Addresses of Patrons
      address public constant DEV_TEAM_HOLDER = 0x1631447d041f929595a9c7b0c9c0047de2e76186;
      address public constant FOUNDATION_HOLDER = 0xe442408a5f2e224c92b34e251de48f5266fc38de;
      address public constant MINERS_HOLDER = 0x38b195d2a18a4e60292868fa74fae619d566111e;

      uint public MAX_OPEN_SOLD = WAN_TOTAL_SUPPLY * OPEN_SALE_STAKE / DIVISOR_STAKE;

    /// Fields that are only changed in constructor
    /// All deposited ETH will be instantly forwarded to this address.
    address public wanport;
    /// Contribution start time
    uint public startTime;
    /// Contribution end time
    uint public endTime;

    /// Fields that can be changed by functions
    /// Accumulator for open sold tokens
    uint openSoldTokens;
    /// Normal sold tokens
    uint normalSoldTokens;
    /// The sum of reserved tokens for ICO stage 1
    uint public partnerReservedSum;
    /// Due to an emergency, set this to true to halt the contribution
    bool public halted;
    /// ERC20 compilant wanchain token contact instance
    WanToken public wanToken;

    /// Quota for partners
    mapping (address => uint256) public partnersLimit;
    /// Accumulator for partner sold
    mapping (address => uint256) public partnersBought;

    uint256 public normalBuyLimit = 65 ether;

    /*
     * EVENTS
     */

    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);
    event PartnerAddressQuota(address indexed partnerAddress, uint quota);

    /*
     * MODIFIERS
     */

    modifier onlyWallet {
        require(msg.sender == wanport);
        _;
    }

    modifier notHalted() {
        require(!halted);
        _;
    }

    modifier initialized() {
        require(address(wanport) != 0x0);
        _;
    }

    modifier notEarlierThan(uint x) {
        require(now >= x);
        _;
    }

    modifier earlierThan(uint x) {
        require(now < x);
        _;
    }

    modifier ceilingNotReached() {
        require(openSoldTokens < MAX_OPEN_SOLD);
        _;
    }

    modifier isSaleEnded() {
        require(now > endTime || openSoldTokens >= MAX_OPEN_SOLD);
        _;
    }


    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the Wanchain contribution contract
     * @param _wanport The escrow account address, all ethers will be sent to this address.
     * @param _startTime ICO start time
     */
    function WanchainContribution(address _wanport, uint _startTime){
    	require(_wanport != 0x0);

        halted = false;
    	wanport = _wanport;
    	startTime = _startTime;
    	endTime = startTime + MAX_CONTRIBUTION_DURATION;
        openSoldTokens = 0;
        partnerReservedSum = 0;
        normalSoldTokens = 0;
        /// Create wanchain token contract instance
    	wanToken = new WanToken(this,startTime, endTime);

        /// Reserve tokens according wanchain ICO rules
    	uint stakeMultiplier = WAN_TOTAL_SUPPLY / DIVISOR_STAKE;

    	wanToken.mintToken(PRESALE_HOLDER, PRESALE_STAKE * stakeMultiplier);
        wanToken.mintToken(DEV_TEAM_HOLDER, DEV_TEAM_STAKE * stakeMultiplier);
        wanToken.mintToken(FOUNDATION_HOLDER, FOUNDATION_STAKE * stakeMultiplier);
        wanToken.mintToken(MINERS_HOLDER, MINERS_STAKE * stakeMultiplier);
    }

    /**
     * Fallback function
     *
     * @dev If anybody sends Ether directly to this  contract, consider he is getting wan token
     */
    function () public payable notHalted ceilingNotReached{
    	buyWanCoin(msg.sender);
    }

    /*
     * PUBLIC FUNCTIONS
     */

   function setNormalBuyLimit(uint256 limit)
        public
        initialized
        onlyOwner
        earlierThan(endTime)
    {
        normalBuyLimit = limit;
    }

    /// @dev Sets the limit for a partner address. All the partner addresses
    /// will be able to get wan token during the contribution period with his own
    /// specific limit.
    /// This method should be called by the owner after the initialization
    /// and before the contribution end.
    /// @param setPartnerAddress Partner address
    /// @param limit Limit for the partner address,the limit is WANTOKEN, not ETHER
    function setPartnerQuota(address setPartnerAddress, uint256 limit)
        public
        initialized
        onlyOwner
        earlierThan(endTime)
    {
        require(limit > 0 && limit <= MAX_OPEN_SOLD);
        partnersLimit[setPartnerAddress] = limit;
        partnerReservedSum += limit;
        PartnerAddressQuota(setPartnerAddress, limit);
    }

    /// @dev Exchange msg.value ether to WAN for account recepient
    /// @param receipient WAN tokens receiver
    function buyWanCoin(address receipient)
        public
        payable
        notHalted
        initialized
        ceilingNotReached
        notEarlierThan(startTime)
        earlierThan(endTime)
        returns (bool)
    {
    	require(receipient != 0x0);
    	require(msg.value >= 0.1 ether);

    	if (partnersLimit[receipient] > 0)
    		buyFromPartner(receipient);
    	else {
    		require(msg.value <= normalBuyLimit);
    		buyNormal(receipient);
    	}

    	return true;
    }

    /// @dev Emergency situation that requires contribution period to stop.
    /// Contributing not possible anymore.
    function halt() public onlyWallet{
        halted = true;
    }

    /// @dev Emergency situation resolved.
    /// Contributing becomes possible again withing the outlined restrictions.
    function unHalt() public onlyWallet{
        halted = false;
    }

    /// @dev Emergency situation
    function changeWalletAddress(address newAddress) onlyWallet {
        wanport = newAddress;
    }

    /// @return true if sale has started, false otherwise.
    function saleStarted() constant returns (bool) {
        return now >= startTime;
    }

    /// @return true if sale has ended, false otherwise.
    function saleEnded() constant returns (bool) {
        return now > endTime || openSoldTokens >= MAX_OPEN_SOLD;
    }

    /// CONSTANT METHODS
    /// @dev Get current exchange rate
    function priceRate() public constant returns (uint) {
        // Three price tiers
        if (startTime <= now && now < startTime + 1 days)
            return PRICE_RATE_FIRST;
        if (startTime + 1 days <= now && now < startTime + 2 days)
            return PRICE_RATE_SECOND;
        if (startTime + 2 days <= now && now < endTime)
            return PRICE_RATE_LAST;
        // Should not be called before or after contribution period
        assert(false);
    }


    function claimTokens(address receipent)
      public
      isSaleEnded
    {

      wanToken.claimTokens(receipent);

    }

    /*
     * INTERNAL FUNCTIONS
     */

    /// @dev Buy wanchain tokens by partners
    function buyFromPartner(address receipient) internal {
    	uint partnerAvailable = partnersLimit[receipient].sub(partnersBought[receipient]);
	    uint allAvailable = MAX_OPEN_SOLD.sub(openSoldTokens);
      partnerAvailable = partnerAvailable.min256(allAvailable);

    	require(partnerAvailable > 0);

    	uint toFund;
    	uint toCollect;
    	(toFund,  toCollect)= costAndBuyTokens(partnerAvailable);

    	partnersBought[receipient] = partnersBought[receipient].add(toCollect);

    	buyCommon(receipient, toFund, toCollect);

    }

    /// @dev Buy wanchain token normally
    function buyNormal(address receipient) internal {
        // Do not allow contracts to game the system
        require(!isContract(msg.sender));

        // protect partner quota in stage one
        uint tokenAvailable;
        if(startTime <= now && now < startTime + 1 days) {
            uint totalNormalAvailable = MAX_OPEN_SOLD.sub(partnerReservedSum);
            tokenAvailable = totalNormalAvailable.sub(normalSoldTokens);
        } else {
            tokenAvailable = MAX_OPEN_SOLD.sub(openSoldTokens);
        }

        require(tokenAvailable > 0);

    	uint toFund;
    	uint toCollect;
    	(toFund, toCollect) = costAndBuyTokens(tokenAvailable);
        buyCommon(receipient, toFund, toCollect);
        normalSoldTokens += toCollect;
    }

    /// @dev Utility function for bug wanchain token
    function buyCommon(address receipient, uint toFund, uint wanTokenCollect) internal {
        require(msg.value >= toFund); // double check

        if(toFund > 0) {
            require(wanToken.mintToken(receipient, wanTokenCollect));
            wanport.transfer(toFund);
            openSoldTokens = openSoldTokens.add(wanTokenCollect);
            NewSale(receipient, toFund, wanTokenCollect);
        }

        uint toReturn = msg.value.sub(toFund);
        if(toReturn > 0) {
            msg.sender.transfer(toReturn);
        }
    }

    /// @dev Utility function for calculate available tokens and cost ethers
    function costAndBuyTokens(uint availableToken) constant internal returns (uint costValue, uint getTokens){
    	// all conditions has checked in the caller functions
    	uint exchangeRate = priceRate();
    	getTokens = exchangeRate * msg.value;

    	if(availableToken >= getTokens){
    		costValue = msg.value;
    	} else {
    		costValue = availableToken / exchangeRate;
    		getTokens = availableToken;
    	}

    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}