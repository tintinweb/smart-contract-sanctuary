pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Sales{

	enum ICOSaleState{
	    PrivateSale,
	    PreSale,
	    PreICO,
	    PublicICO
	}
}

contract Utils{

	//verifies the amount greater than zero

	modifier greaterThanZero(uint256 _value){
		require(_value>0);
		_;
	}

	///verifies an address

	modifier validAddress(address _add){
		require(_add!=0x0);
		_;
	}
}


    








contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract SMTToken is Token,Ownable,Sales {
    string public constant name = "Sun Money Token";
    string public constant symbol = "SMT";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    ///The value to be sent to our BTC address
    uint public valueToBeSent = 1;
    ///The ethereum address of the person manking the transaction
    address personMakingTx;
    //uint private output1,output2,output3,output4;
    ///to return the address just for the testing purposes
    address public addr1;
    ///to return the tx origin just for the testing purposes
    address public txorigin;

    //function for testing only btc address
    bool isTesting;
    ///testing the name remove while deploying
    bytes32 testname;
    address finalOwner;
    bool public finalizedPublicICO = false;
    bool public finalizedPreICO = false;

    uint256 public SMTfundAfterPreICO;
    uint256 public ethraised;
    uint256 public btcraised;

    bool public istransferAllowed;

    uint256 public constant SMTfund = 10 * (10**6) * 10**decimals; 
    uint256 public fundingStartBlock; // crowdsale start block
    uint256 public fundingEndBlock; // crowdsale end block
    uint256 public  tokensPerEther = 150; //TODO
    uint256 public  tokensPerBTC = 22*150*(10**10);
    uint256 public tokenCreationMax= 72* (10**5) * 10**decimals; //TODO
    mapping (address => bool) ownership;


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
      if(!istransferAllowed) throw;
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    //this is the default constructor
    function SMTToken(uint256 _fundingStartBlock, uint256 _fundingEndBlock){
        totalSupply = SMTfund;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }


    ICOSaleState public salestate = ICOSaleState.PrivateSale;

    ///**To be replaced  the following by the following*///
    /**

    **/

    /***Event to be fired when the state of the sale of the ICO is changes**/
    event stateChange(ICOSaleState state);

    /**

    **/
    function setState(ICOSaleState state)  returns (bool){
    if(!ownership[msg.sender]) throw;
    salestate = state;
    stateChange(salestate);
    return true;
    }

    /**

    **/
    function getState() returns (ICOSaleState) {
    return salestate;

    }



    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
        if(!istransferAllowed) throw;
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function addToBalances(address _person,uint256 value) {
        if(!ownership[msg.sender]) throw;
        balances[_person] = SafeMath.add(balances[_person],value);

    }

    function addToOwnership(address owners) onlyOwner{
        ownership[owners] = true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if(!istransferAllowed) throw;
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      if(!istransferAllowed) throw;
      return allowed[_owner][_spender];
    }

    function increaseEthRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        ethraised+=value;
    }

    function increaseBTCRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        btcraised+=value;
    }




    function finalizePreICO(uint256 value) returns(bool){
        if(!ownership[msg.sender]) throw;
        finalizedPreICO = true;
        SMTfundAfterPreICO =value;
        return true;
    }


    function finalizePublicICO() returns(bool) {
        if(!ownership[msg.sender]) throw;
        finalizedPublicICO = true;
        istransferAllowed = true;
        return true;
    }


    function isValid() returns(bool){
        if(block.number>=fundingStartBlock && block.number<fundingEndBlock ){
            return true;
        }else{
            return false;
        }
    }

    ///do not allow payments on this address

    function() payable{
        throw;
    }
}








/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  modifier stopInEmergency {
    if (paused) {
      throw;
    }
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
// Bitcoin transaction parsing library

// Copyright 2016 rain <https://keybase.io/rain>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// https://en.bitcoin.it/wiki/Protocol_documentation#tx
//
// Raw Bitcoin transaction structure:
//
// field     | size | type     | description
// version   | 4    | int32    | transaction version number
// n_tx_in   | 1-9  | var_int  | number of transaction inputs
// tx_in     | 41+  | tx_in[]  | list of transaction inputs
// n_tx_out  | 1-9  | var_int  | number of transaction outputs
// tx_out    | 9+   | tx_out[] | list of transaction outputs
// lock_time | 4    | uint32   | block number / timestamp at which tx locked
//
// Transaction input (tx_in) structure:
//
// field      | size | type     | description
// previous   | 36   | outpoint | Previous output transaction reference
// script_len | 1-9  | var_int  | Length of the signature script
// sig_script | ?    | uchar[]  | Script for confirming transaction authorization
// sequence   | 4    | uint32   | Sender transaction version
//
// OutPoint structure:
//
// field      | size | type     | description
// hash       | 32   | char[32] | The hash of the referenced transaction
// index      | 4    | uint32   | The index of this output in the referenced transaction
//
// Transaction output (tx_out) structure:
//
// field         | size | type     | description
// value         | 8    | int64    | Transaction value (Satoshis)
// pk_script_len | 1-9  | var_int  | Length of the public key script
// pk_script     | ?    | uchar[]  | Public key as a Bitcoin script.
//
// Variable integers (var_int) can be encoded differently depending
// on the represented value, to save space. Variable integers always
// precede an array of a variable length data type (e.g. tx_in).
//
// Variable integer encodings as a function of represented value:
//
// value           | bytes  | format
// <0xFD (253)     | 1      | uint8
// <=0xFFFF (65535)| 3      | 0xFD followed by length as uint16
// <=0xFFFF FFFF   | 5      | 0xFE followed by length as uint32
// -               | 9      | 0xFF followed by length as uint64
//
// Public key scripts `pk_script` are set on the output and can
// take a number of forms. The regular transaction script is
// called &#39;pay-to-pubkey-hash&#39; (P2PKH):
//
// OP_DUP OP_HASH160 <pubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
//
// OP_x are Bitcoin script opcodes. The bytes representation (including
// the 0x14 20-byte stack push) is:
//
// 0x76 0xA9 0x14 <pubKeyHash> 0x88 0xAC
//
// The <pubKeyHash> is the ripemd160 hash of the sha256 hash of
// the public key, preceded by a network version byte. (21 bytes total)
//
// Network version bytes: 0x00 (mainnet); 0x6f (testnet); 0x34 (namecoin)
//
// The Bitcoin address is derived from the pubKeyHash. The binary form is the
// pubKeyHash, plus a checksum at the end.  The checksum is the first 4 bytes
// of the (32 byte) double sha256 of the pubKeyHash. (25 bytes total)
// This is converted to base58 to form the publicly used Bitcoin address.
// Mainnet P2PKH transaction scripts are to addresses beginning with &#39;1&#39;.
//
// P2SH (&#39;pay to script hash&#39;) scripts only supply a script hash. The spender
// must then provide the script that would allow them to redeem this output.
// This allows for arbitrarily complex scripts to be funded using only a
// hash of the script, and moves the onus on providing the script from
// the spender to the redeemer.
//
// The P2SH script format is simple:
//
// OP_HASH160 <scriptHash> OP_EQUAL
//
// 0xA9 0x14 <scriptHash> 0x87
//
// The <scriptHash> is the ripemd160 hash of the sha256 hash of the
// redeem script. The P2SH address is derived from the scriptHash.
// Addresses are the scriptHash with a version prefix of 5, encoded as
// Base58check. These addresses begin with a &#39;3&#39;.



// parse a raw bitcoin transaction byte array
library BTC {
    // Convert a variable integer into something useful and return it and
    // the index to after it.
    function parseVarInt(bytes txBytes, uint pos) returns (uint, uint) {
        // the first byte tells us how big the integer is
        var ibit = uint8(txBytes[pos]);
        pos += 1;  // skip ibit

        if (ibit < 0xfd) {
            return (ibit, pos);
        } else if (ibit == 0xfd) {
            return (getBytesLE(txBytes, pos, 16), pos + 2);
        } else if (ibit == 0xfe) {
            return (getBytesLE(txBytes, pos, 32), pos + 4);
        } else if (ibit == 0xff) {
            return (getBytesLE(txBytes, pos, 64), pos + 8);
        }
    }
    // convert little endian bytes to uint
    function getBytesLE(bytes data, uint pos, uint bits) returns (uint) {
        if (bits == 8) {
            return uint8(data[pos]);
        } else if (bits == 16) {
            return uint16(data[pos])
                 + uint16(data[pos + 1]) * 2 ** 8;
        } else if (bits == 32) {
            return uint32(data[pos])
                 + uint32(data[pos + 1]) * 2 ** 8
                 + uint32(data[pos + 2]) * 2 ** 16
                 + uint32(data[pos + 3]) * 2 ** 24;
        } else if (bits == 64) {
            return uint64(data[pos])
                 + uint64(data[pos + 1]) * 2 ** 8
                 + uint64(data[pos + 2]) * 2 ** 16
                 + uint64(data[pos + 3]) * 2 ** 24
                 + uint64(data[pos + 4]) * 2 ** 32
                 + uint64(data[pos + 5]) * 2 ** 40
                 + uint64(data[pos + 6]) * 2 ** 48
                 + uint64(data[pos + 7]) * 2 ** 56;
        }
    }
    // scan the full transaction bytes and return the first two output
    // values (in satoshis) and addresses (in binary)
    function getFirstTwoOutputs(bytes txBytes)
             returns (uint, bytes20, uint, bytes20)
    {
        uint pos;
        uint[] memory input_script_lens = new uint[](2);
        uint[] memory output_script_lens = new uint[](2);
        uint[] memory script_starts = new uint[](2);
        uint[] memory output_values = new uint[](2);
        bytes20[] memory output_addresses = new bytes20[](2);

        pos = 4;  // skip version

        (input_script_lens, pos) = scanInputs(txBytes, pos, 0);

        (output_values, script_starts, output_script_lens, pos) = scanOutputs(txBytes, pos, 2);

        for (uint i = 0; i < 2; i++) {
            var pkhash = parseOutputScript(txBytes, script_starts[i], output_script_lens[i]);
            output_addresses[i] = pkhash;
        }

        return (output_values[0], output_addresses[0],
                output_values[1], output_addresses[1]);
    }
    // Check whether `btcAddress` is in the transaction outputs *and*
    // whether *at least* `value` has been sent to it.
        // Check whether `btcAddress` is in the transaction outputs *and*
    // whether *at least* `value` has been sent to it.
    function checkValueSent(bytes txBytes, bytes20 btcAddress, uint value)
             returns (bool,uint)
    {
        uint pos = 4;  // skip version
        (, pos) = scanInputs(txBytes, pos, 0);  // find end of inputs

        // scan *all* the outputs and find where they are
        var (output_values, script_starts, output_script_lens,) = scanOutputs(txBytes, pos, 0);

        // look at each output and check whether it at least value to btcAddress
        for (uint i = 0; i < output_values.length; i++) {
            var pkhash = parseOutputScript(txBytes, script_starts[i], output_script_lens[i]);
            if (pkhash == btcAddress && output_values[i] >= value) {
                return (true,output_values[i]);
            }
        }
    }
    // scan the inputs and find the script lengths.
    // return an array of script lengths and the end position
    // of the inputs.
    // takes a &#39;stop&#39; argument which sets the maximum number of
    // outputs to scan through. stop=0 => scan all.
    function scanInputs(bytes txBytes, uint pos, uint stop)
             returns (uint[], uint)
    {
        uint n_inputs;
        uint halt;
        uint script_len;

        (n_inputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_inputs) {
            halt = n_inputs;
        } else {
            halt = stop;
        }

        uint[] memory script_lens = new uint[](halt);

        for (var i = 0; i < halt; i++) {
            pos += 36;  // skip outpoint
            (script_len, pos) = parseVarInt(txBytes, pos);
            script_lens[i] = script_len;
            pos += script_len + 4;  // skip sig_script, seq
        }

        return (script_lens, pos);
    }
    // scan the outputs and find the values and script lengths.
    // return array of values, array of script lengths and the
    // end position of the outputs.
    // takes a &#39;stop&#39; argument which sets the maximum number of
    // outputs to scan through. stop=0 => scan all.
    function scanOutputs(bytes txBytes, uint pos, uint stop)
             returns (uint[], uint[], uint[], uint)
    {
        uint n_outputs;
        uint halt;
        uint script_len;

        (n_outputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_outputs) {
            halt = n_outputs;
        } else {
            halt = stop;
        }

        uint[] memory script_starts = new uint[](halt);
        uint[] memory script_lens = new uint[](halt);
        uint[] memory output_values = new uint[](halt);

        for (var i = 0; i < halt; i++) {
            output_values[i] = getBytesLE(txBytes, pos, 64);
            pos += 8;

            (script_len, pos) = parseVarInt(txBytes, pos);
            script_starts[i] = pos;
            script_lens[i] = script_len;
            pos += script_len;
        }

        return (output_values, script_starts, script_lens, pos);
    }
    // Slice 20 contiguous bytes from bytes `data`, starting at `start`
    function sliceBytes20(bytes data, uint start) returns (bytes20) {
        uint160 slice = 0;
        for (uint160 i = 0; i < 20; i++) {
            slice += uint160(data[i + start]) << (8 * (19 - i));
        }
        return bytes20(slice);
    }
    // returns true if the bytes located in txBytes by pos and
    // script_len represent a P2PKH script
    function isP2PKH(bytes txBytes, uint pos, uint script_len) returns (bool) {
        return (script_len == 25)           // 20 byte pubkeyhash + 5 bytes of script
            && (txBytes[pos] == 0x76)       // OP_DUP
            && (txBytes[pos + 1] == 0xa9)   // OP_HASH160
            && (txBytes[pos + 2] == 0x14)   // bytes to push
            && (txBytes[pos + 23] == 0x88)  // OP_EQUALVERIFY
            && (txBytes[pos + 24] == 0xac); // OP_CHECKSIG
    }
    // returns true if the bytes located in txBytes by pos and
    // script_len represent a P2SH script
    function isP2SH(bytes txBytes, uint pos, uint script_len) returns (bool) {
        return (script_len == 23)           // 20 byte scripthash + 3 bytes of script
            && (txBytes[pos + 0] == 0xa9)   // OP_HASH160
            && (txBytes[pos + 1] == 0x14)   // bytes to push
            && (txBytes[pos + 22] == 0x87); // OP_EQUAL
    }
    // Get the pubkeyhash / scripthash from an output script. Assumes
    // pay-to-pubkey-hash (P2PKH) or pay-to-script-hash (P2SH) outputs.
    // Returns the pubkeyhash/ scripthash, or zero if unknown output.
    function parseOutputScript(bytes txBytes, uint pos, uint script_len)
             returns (bytes20)
    {
        if (isP2PKH(txBytes, pos, script_len)) {
            return sliceBytes20(txBytes, pos + 3);
        } else if (isP2SH(txBytes, pos, script_len)) {
            return sliceBytes20(txBytes, pos + 2);
        } else {
            return;
        }
    }
}





/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract PricingStrategy{

	/**
	returns the base discount value
	@param  currentsupply is a &#39;current supply&#39; value
	@param  contribution  is &#39;sent by the contributor&#39;
	@return   an integer for getting the discount value of the base discounts
	**/
	function baseDiscounts(uint256 currentsupply,uint256 contribution,string types) returns (uint256){
		if(contribution==0) throw;
		if(keccak256("ethereum")==keccak256(types)){
			if(currentsupply>=0 && currentsupply<= 15*(10**5) * (10**18) && contribution>=1*10**18){
			 return 40;
			}else if(currentsupply> 15*(10**5) * (10**18) && currentsupply< 30*(10**5) * (10**18) && contribution>=5*10**17){
				return 30;
			}else{
				return 0;
			}
			}else if(keccak256("bitcoin")==keccak256(types)){
				if(currentsupply>=0 && currentsupply<= 15*(10**5) * (10**18) && contribution>=45*10**5){
				 return 40;
				}else if(currentsupply> 15*(10**5) * (10**18) && currentsupply< 30*(10**5) * (10**18) && contribution>=225*10**4){
					return 30;
				}else{
					return 0;
				}
			}	
	}

	/**
	
	These are the base discounts offered by the sunMOneyToken
	These are valid ffor every value sent to the contract
	@param   contribution is a &#39;the value sent in wei by the contributor in ethereum&#39;
	@return  the discount
	**/
	function volumeDiscounts(uint256 contribution,string types) returns (uint256){
		///do not allow the zero contrbution 
		//its unsigned negative checking not required
		if(contribution==0) throw;
		if(keccak256("ethereum")==keccak256(types)){
			if(contribution>=3*10**18 && contribution<10*10**18){
				return 0;
			}else if(contribution>=10*10**18 && contribution<20*10**18){
				return 5;
			}else if(contribution>=20*10**18){
				return 10;
			}else{
				return 0;
			}
			}else if(keccak256("bitcoin")==keccak256(types)){
				if(contribution>=3*45*10**5 && contribution<10*45*10**5){
					return 0;
				}else if(contribution>=10*45*10**5 && contribution<20*45*10**5){
					return 5;
				}else if(contribution>=20*45*10**5){
					return 10;
				}else{
					return 0;
				}
			}

	}

	/**returns the total discount value**/
	/**
	@param  currentsupply is a &#39;current supply&#39;
	@param  contribution is a &#39;sent by the contributor&#39;
	@return   an integer for getting the total discounts
	**/
	function totalDiscount(uint256 currentsupply,uint256 contribution,string types) returns (uint256){
		uint256 basediscount = baseDiscounts(currentsupply,contribution,types);
		uint256 volumediscount = volumeDiscounts(contribution,types);
		uint256 totaldiscount = basediscount+volumediscount;
		return totaldiscount;
	}
}



contract PreICO is Ownable,Pausable, Utils,PricingStrategy,Sales{

	SMTToken token;
	uint256 public tokensPerBTC;
	uint public tokensPerEther;
	uint256 public initialSupplyPrivateSale;
	uint256 public initialSupplyPreSale;
	uint256 public SMTfundAfterPreICO;
	uint256 public initialSupplyPublicPreICO;
	uint256 public currentSupply;
	uint256 public fundingStartBlock;
	uint256 public fundingEndBlock;
	uint256 public SMTfund;
	uint256 public tokenCreationMaxPreICO = 15* (10**5) * 10**18;
	uint256 public tokenCreationMaxPrivateSale = 15*(10**5) * (10**18);
	///tokens for the team
	uint256 public team = 1*(10**6)*(10**18);
	///tokens for reserve
	uint256 public reserve = 1*(10**6)*(10**18);
	///tokens for the mentors
	uint256 public mentors = 5*(10**5)*10**18;
	///tokkens for the bounty
	uint256 public bounty = 3*(10**5)*10**18;
	///address for the teeam,investores,etc

	uint256 totalsend = team+reserve+bounty+mentors;
	address public addressPeople = 0xea0f17CA7C3e371af30EFE8CbA0e646374552e8B;

	address public ownerAddr = 0x4cA09B312F23b390450D902B21c7869AA64877E3;
	///array of addresses for the ethereum relateed back funding  contract
	uint256 public numberOfBackers;
	///the txorigin is the web3.eth.coinbase account
	//record Transactions that have claimed ether to prevent the replay attacks
	//to-do
	mapping(uint256 => bool) transactionsClaimed;
	uint256 public valueToBeSent;

	//the constructor function
   function PreICO(address tokenAddress){
		//require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input
		token = SMTToken(tokenAddress);
		tokensPerEther = token.tokensPerEther();
		tokensPerBTC = token.tokensPerBTC();
		valueToBeSent = token.valueToBeSent();
		SMTfund = token.SMTfund();
	}
	
	////function to send initialFUnd
    function sendFunds() onlyOwner{
        token.addToBalances(addressPeople,totalsend);
    }

	///a function using safemath to work with
	///the new function
	function calNewTokens(uint256 contribution,string types) returns (uint256){
		uint256 disc = totalDiscount(currentSupply,contribution,types);
		uint256 CreatedTokens;
		if(keccak256(types)==keccak256("ethereum")) CreatedTokens = SafeMath.mul(contribution,tokensPerEther);
		else if(keccak256(types)==keccak256("bitcoin"))  CreatedTokens = SafeMath.mul(contribution,tokensPerBTC);
		uint256 tokens = SafeMath.add(CreatedTokens,SafeMath.div(SafeMath.mul(CreatedTokens,disc),100));
		return tokens;
	}
	/**
		Payable function to send the ether funds
	**/
	function() external payable stopInEmergency{
        if(token.getState()==ICOSaleState.PublicICO) throw;
        bool isfinalized = token.finalizedPreICO();
        bool isValid = token.isValid();
        if(isfinalized) throw;
        if(!isValid) throw;
        if (msg.value == 0) throw;
        uint256 newCreatedTokens;
        ///since we are creating tokens we need to increase the total supply
        if(token.getState()==ICOSaleState.PrivateSale||token.getState()==ICOSaleState.PreSale) {
        	if((msg.value) < 1*10**18) throw;
        	newCreatedTokens =calNewTokens(msg.value,"ethereum");
        	uint256 temp = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
        	if(temp>tokenCreationMaxPrivateSale){
        		uint256 consumed = SafeMath.sub(tokenCreationMaxPrivateSale,initialSupplyPrivateSale);
        		initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,consumed);
        		currentSupply = SafeMath.add(currentSupply,consumed);
        		uint256 nonConsumed = SafeMath.sub(newCreatedTokens,consumed);
        		uint256 finalTokens = SafeMath.sub(nonConsumed,SafeMath.div(nonConsumed,10));
        		switchState();
        		initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,finalTokens);
        		currentSupply = SafeMath.add(currentSupply,finalTokens);
        		if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        		numberOfBackers++;
               token.addToBalances(msg.sender,SafeMath.add(finalTokens,consumed));
        	 if(!ownerAddr.send(msg.value))throw;
        	  token.increaseEthRaised(msg.value);
        	}else{
    			initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
    			currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
    			if(initialSupplyPrivateSale>tokenCreationMaxPrivateSale) throw;
    			numberOfBackers++;
                token.addToBalances(msg.sender,newCreatedTokens);
            	if(!ownerAddr.send(msg.value))throw;
            	token.increaseEthRaised(msg.value);
    		}
        }
        else if(token.getState()==ICOSaleState.PreICO){
        	if(msg.value < 5*10**17) throw;
        	newCreatedTokens =calNewTokens(msg.value,"ethereum");
        	initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,newCreatedTokens);
        	currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
        	if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        	numberOfBackers++;
             token.addToBalances(msg.sender,newCreatedTokens);
        	if(!ownerAddr.send(msg.value))throw;
        	token.increaseEthRaised(msg.value);
        }

	}

	///token distribution initial function for the one in the exchanges
	///to be done only the owner can run this function
	function tokenAssignExchange(address addr,uint256 val,uint256 txnHash) public onlyOwner {
	   // if(msg.sender!=owner) throw;
	  if (val == 0) throw;
	  if(token.getState()==ICOSaleState.PublicICO) throw;
	  if(transactionsClaimed[txnHash]) throw;
	  bool isfinalized = token.finalizedPreICO();
	  if(isfinalized) throw;
	  bool isValid = token.isValid();
	  if(!isValid) throw;
	  uint256 newCreatedTokens;
        if(token.getState()==ICOSaleState.PrivateSale||token.getState()==ICOSaleState.PreSale) {
        	if(val < 1*10**18) throw;
        	newCreatedTokens =calNewTokens(val,"ethereum");
        	uint256 temp = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
        	if(temp>tokenCreationMaxPrivateSale){
        		uint256 consumed = SafeMath.sub(tokenCreationMaxPrivateSale,initialSupplyPrivateSale);
        		initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,consumed);
        		currentSupply = SafeMath.add(currentSupply,consumed);
        		uint256 nonConsumed = SafeMath.sub(newCreatedTokens,consumed);
        		uint256 finalTokens = SafeMath.sub(nonConsumed,SafeMath.div(nonConsumed,10));
        		switchState();
        		initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,finalTokens);
        		currentSupply = SafeMath.add(currentSupply,finalTokens);
        		if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        		numberOfBackers++;
               token.addToBalances(addr,SafeMath.add(finalTokens,consumed));
        	   token.increaseEthRaised(val);
        	}else{
    			initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
    			currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
    			if(initialSupplyPrivateSale>tokenCreationMaxPrivateSale) throw;
    			numberOfBackers++;
                token.addToBalances(addr,newCreatedTokens);
            	token.increaseEthRaised(val);
    		}
        }
        else if(token.getState()==ICOSaleState.PreICO){
        	if(msg.value < 5*10**17) throw;
        	newCreatedTokens =calNewTokens(val,"ethereum");
        	initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,newCreatedTokens);
        	currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
        	if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        	numberOfBackers++;
             token.addToBalances(addr,newCreatedTokens);
        	token.increaseEthRaised(val);
        }
	}

	//Token distribution for the case of the ICO
	///function to run when the transaction has been veified
	function processTransaction(bytes txn, uint256 txHash,address addr,bytes20 btcaddr) onlyOwner returns (uint)
	{
		bool valueSent;
		bool isValid = token.isValid();
		if(!isValid) throw;
		//txorigin = tx.origin;
		//	if(token.getState()!=State.Funding) throw;
		if(!transactionsClaimed[txHash]){
			var (a,b) = BTC.checkValueSent(txn,btcaddr,valueToBeSent);
			if(a){
				valueSent = true;
				transactionsClaimed[txHash] = true;
				uint256 newCreatedTokens;
				 ///since we are creating tokens we need to increase the total supply
            if(token.getState()==ICOSaleState.PrivateSale||token.getState()==ICOSaleState.PreSale) {
        	if(b < 45*10**5) throw;
        	newCreatedTokens =calNewTokens(b,"bitcoin");
        	uint256 temp = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
        	if(temp>tokenCreationMaxPrivateSale){
        		uint256 consumed = SafeMath.sub(tokenCreationMaxPrivateSale,initialSupplyPrivateSale);
        		initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,consumed);
        		currentSupply = SafeMath.add(currentSupply,consumed);
        		uint256 nonConsumed = SafeMath.sub(newCreatedTokens,consumed);
        		uint256 finalTokens = SafeMath.sub(nonConsumed,SafeMath.div(nonConsumed,10));
        		switchState();
        		initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,finalTokens);
        		currentSupply = SafeMath.add(currentSupply,finalTokens);
        		if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        		numberOfBackers++;
               token.addToBalances(addr,SafeMath.add(finalTokens,consumed));
        	   token.increaseBTCRaised(b);
        	}else{
    			initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
    			currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
    			if(initialSupplyPrivateSale>tokenCreationMaxPrivateSale) throw;
    			numberOfBackers++;
                token.addToBalances(addr,newCreatedTokens);
            	token.increaseBTCRaised(b);
    		}
        }
        else if(token.getState()==ICOSaleState.PreICO){
        	if(msg.value < 225*10**4) throw;
        	newCreatedTokens =calNewTokens(b,"bitcoin");
        	initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,newCreatedTokens);
        	currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
        	if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        	numberOfBackers++;
             token.addToBalances(addr,newCreatedTokens);
        	token.increaseBTCRaised(b);
         }
		return 1;
			}
		}
		else{
		    throw;
		}
	}

	function finalizePreICO() public onlyOwner{
		uint256 val = currentSupply;
		token.finalizePreICO(val);
	}

	function switchState() internal  {
		 token.setState(ICOSaleState.PreICO);
		
	}
	

	

}