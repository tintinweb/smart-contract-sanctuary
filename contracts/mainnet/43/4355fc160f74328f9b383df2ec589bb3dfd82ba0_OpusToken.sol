pragma solidity ^0.4.8;


/**
 * Math operations with safety checks
 * By OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/contracts/SafeMath.sol
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    if(!(a == 0 || c / a == b)) throw;
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    if(!(b <= a)) throw;
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    if(!(c >= a)) throw;
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

contract ContractReceiver{
    function tokenFallback(address _from, uint256 _value, bytes  _data) external;
}


//Basic ERC23 token, backward compatible with ERC20 transfer function.
//Based in part on code by open-zeppelin: https://github.com/OpenZeppelin/zeppelin-solidity.git
contract ERC23BasicToken {
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function tokenFallback(address _from, uint256 _value, bytes  _data) external {
        throw;
    }

    function transfer(address _to, uint256 _value, bytes _data) returns (bool success) {

        //Standard ERC23 transfer function

        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }

    function transfer(address _to, uint256 _value) {

        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons

        bytes memory empty;
        if(isContract(_to)) {
            transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
    }

    function transferToAddress(address _to, uint256 _value, bytes _data) internal {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
     }

    function transferToContract(address _to, uint256 _value, bytes _data) internal {
        balances[msg.sender] = balances[msg.sender].sub( _value);
        balances[_to] = balances[_to].add( _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) returns (bool is_contract) {
          uint256 length;
          assembly {
              //retrieve the size of the code on target address, this needs assembly
              length := extcodesize(_addr)
          }
          if(length>0) {
              return true;
          }
          else {
              return false;
          }
    }
}

contract ERC23StandardToken is ERC23BasicToken {
    mapping (address => mapping (address => uint256)) allowed;
    event Approval (address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}




// Based in part on code by Open-Zeppelin: https://github.com/OpenZeppelin/zeppelin-solidity.git
// Based in part on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
contract OpusToken is ERC23StandardToken {
    string public constant name = "Opus Token";
    string public constant symbol = "OPT";
    uint256 public constant decimals = 18;
    address public multisig=address(0x1426c1f91b923043F7C5FbabC6e369e7cBaef3f0); //multisig wallet, to which all contributions will be sent
    address public foundation; //owner address
    address public candidate; //owner candidate in 2-phase ownership transfer

    mapping (address => uint256) contributions; //keeps track of ether contributions in Wei of each contributor address
    uint256 public startBlock = 4023333; //pre-crowdsale start block (30min ealier than estimate) 
    uint256 public preEndBlock = 4057233; //pre-crowdsale end block(1h after estimated time)
    uint256 public phase1StartBlock = 4066633; //Crowdsale start block (1h earlier)
    uint256 public phase1EndBlock = 4100233; //Week 1 end block (estimate)
    uint256 public phase2EndBlock = 4133833; //Week 2 end block (estimate)
    uint256 public phase3EndBlock = 4201433; //Week 4 end block (2h later)
    uint256 public endBlock = 4201433; //whole crowdsale end block
    uint256 public crowdsaleTokenSupply = 900000000 * (10**18); //Amount of tokens for sale during crowdsale
    uint256 public ecosystemTokenSupply = 100000000 * (10**18); //Tokens for supporting the Opus eco-system, e.g. purchasing music licenses, artist bounties, etc.
    uint256 public foundationTokenSupply = 600000000 * (10**18); //Tokens distributed to the Opus foundation, developers and angel investors
    uint256 public crowdsaleTokenSold = 0; //Keeps track of the amount of tokens sold during the crowdsale
    uint256 public presaleEtherRaised = 0; //Keeps track of the Ether raised during the crowdsale
    uint256 public transferLockup = 9600;
    bool public halted = false; //Halt crowdsale in emergency
    event Halt(); //Halt event
    event Unhalt(); //Unhalt event

    modifier onlyFoundation() {
        //only do if call is from owner modifier
        if (msg.sender != foundation) throw;
        _;
    }

    modifier crowdsaleTransferLock() {
        // lockup during and after 48h of end of crowdsale
        if (block.number <= endBlock.add(transferLockup)) throw;
        _;
    }

    modifier whenNotHalted() {
        // only do when not halted modifier
        if (halted) throw;
        _;
    }

    //Constructor: set multisig crowdsale recipient wallet address and fund the foundation
    //Initialize total supply and allocate ecosystem & foundation tokens
  	function OpusToken() {
        foundation = msg.sender;
        totalSupply = ecosystemTokenSupply.add(foundationTokenSupply);
        balances[foundation] = totalSupply;
  	}

    //Fallback function when receiving Ether.
    function() payable {
        buy();
    }


    //Halt ICO in case of emergency.
    function halt() onlyFoundation {
        halted = true;
        Halt();
    }

    function unhalt() onlyFoundation {
        halted = false;
        Unhalt();
    }

    function buy() payable {
        buyRecipient(msg.sender);
    }

    //Allow addresses to buy token for another account
    function buyRecipient(address recipient) public payable whenNotHalted {
        if(msg.value == 0) throw;
        if(!(preCrowdsaleOn()||crowdsaleOn())) throw;//only allows during presale/crowdsale
        if(contributions[recipient].add(msg.value)>perAddressCap()) throw;//per address cap
        uint256 tokens = msg.value.mul(returnRate()); //decimals=18, so no need to adjust for unit
        if(crowdsaleTokenSold.add(tokens)>crowdsaleTokenSupply) throw;//max supply limit

        balances[recipient] = balances[recipient].add(tokens);
        totalSupply = totalSupply.add(tokens);
        presaleEtherRaised = presaleEtherRaised.add(msg.value);
        contributions[recipient] = contributions[recipient].add(msg.value);
        crowdsaleTokenSold = crowdsaleTokenSold.add(tokens);
        if(crowdsaleTokenSold == crowdsaleTokenSupply){
        //If crowdsale token sold out, end crowdsale
            if(block.number < preEndBlock) {
                preEndBlock = block.number;
            }
            endBlock = block.number;
        }
        if (!multisig.send(msg.value)) throw; //immediately send Ether to multisig address
        Transfer(this, recipient, tokens);
    }

    //Burns the specified amount of tokens from the foundation
    //Used to burn unspent funds in foundation DAO
    function burn(uint256 _value) external onlyFoundation returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, address(0), _value);
        return true;
    }

    //2-phase ownership transfer;
    //prevent transferring ownership to non-existent addresses by accident.
    function proposeFoundationTransfer(address newFoundation) external onlyFoundation {
        //propose new owner
        candidate = newFoundation;
    }

    function cancelFoundationTransfer() external onlyFoundation {
        candidate = address(0);
    }

    function acceptFoundationTransfer() external {
        //new owner accept transfer to complete transfer
        if(msg.sender != candidate) throw;
        foundation = candidate;
        candidate = address(0);
    }

    //Allow to change the recipient multisig address
    function setMultisig(address addr) external onlyFoundation {
      	if (addr == address(0)) throw;
      	multisig = addr;
    }

    function transfer(address _to, uint256 _value, bytes _data) public crowdsaleTransferLock returns (bool success) {
        return super.transfer(_to, _value, _data);
    }

	  function transfer(address _to, uint256 _value) public crowdsaleTransferLock {
        super.transfer(_to, _value);
	  }

    function transferFrom(address _from, address _to, uint256 _value) public crowdsaleTransferLock {
        super.transferFrom(_from, _to, _value);
    }

    //Return rate of token against ether.
    function returnRate() public constant returns(uint256) {
        if (block.number>=startBlock && block.number<=preEndBlock) return 8888; //Pre-crowdsale
        if (block.number>=phase1StartBlock && block.number<=phase1EndBlock) return 8000; //Crowdsale phase1
        if (block.number>phase1EndBlock && block.number<=phase2EndBlock) return 7500; //Phase2
        if (block.number>phase2EndBlock && block.number<=phase3EndBlock) return 7000; //Phase3
    }

    //per address cap in Wei: 1000 ether + 1% of ether received at the given time.
    function perAddressCap() public constant returns(uint256) {
        uint256 baseline = 1000 * (10**18);
        return baseline.add(presaleEtherRaised.div(100));
    }

    function preCrowdsaleOn() public constant returns (bool) {
        //return whether presale is on according to block number
        return (block.number>=startBlock && block.number<=preEndBlock);
    }

    function crowdsaleOn() public constant returns (bool) {
        //return whether crowdsale is on according to block number
        return (block.number>=phase1StartBlock && block.number<=endBlock);
    }


    function getEtherRaised() external constant returns (uint256) {
        //getter function for etherRaised
        return presaleEtherRaised;
    }

    function getTokenSold() external constant returns (uint256) {
        //getter function for crowdsaleTokenSold
        return crowdsaleTokenSold;
    }

}