pragma solidity ^0.4.11;

/// @title STABLE Project ICO
/// @author Konrad Szałapak <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d9b2b6b7abb8bdf7aaa3b8b5b8a9b8b299beb4b8b0b5f7bab6b4">[email&#160;protected]</a>>

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
}
  
/* New ERC23 contract interface */
contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
  
    function name() constant returns (string _name);
    function symbol() constant returns (string _symbol);
    function decimals() constant returns (uint8 _decimals);
    function totalSupply() constant returns (uint256 _supply);

    function transfer(address to, uint value) returns (bool ok);
    function transfer(address to, uint value, bytes data) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

/*
* Contract that is working with ERC223 tokens
*/
contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data);
}

/**
* ERC23 token by Dexaran
*
* https://github.com/Dexaran/ERC23-tokens
*/
 
 
/* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) throw;
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) throw;
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) throw;
        return x * y;
    }
}

/**
* Stable Awareness Token - STA
*/
contract ERC223Token_STA is ERC223, SafeMath, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint) balances;
    
    // stable:
    uint256 public icoEndBlock;                              // last block number of ICO 
    uint256 public maxSupply;                                // maximum token supply
    uint256 public minedTokenCount;                          // counter of mined tokens
    address public icoAddress;                               // address of ICO contract    
    uint256 private multiplier;                              // for managing token fractionals
    struct Miner {                                           // struct for mined tokens data
        uint256 block;
        address minerAddress;
    }
    mapping (uint256 => Miner) public minedTokens;           // mined tokens data
    event MessageClaimMiningReward(address indexed miner, uint256 block, uint256 sta);  // notifies clients about sta winning miner
    event Burn(address indexed from, uint256 value);         // notifies clients about the amount burnt
    
    function ERC223Token_STA() {
        decimals = 8;
        multiplier = 10**uint256(decimals);
        maxSupply = 10000000000;                             // Maximum possible supply == 100 STA
        name = "STABLE STA Token";                           // Set the name for display purposes
        symbol = "STA";                                      // Set the symbol for display purposes
        icoEndBlock = 4230150;  // INIT                      // last block number for ICO
        totalSupply = 0;                                     // Update total supply
        // balances[msg.sender] = totalSupply;               // Give the creator all initial tokens
    }
 
    // trigger rewarding a miner with STA token:
    function claimMiningReward() {  
        if (icoAddress == address(0)) throw;                         // ICO address must be set up first
        if (msg.sender != icoAddress && msg.sender != owner) throw;  // triggering enabled only for ICO or owner
        if (block.number > icoEndBlock) throw;                       // rewarding enabled only before the end of ICO
        if (minedTokenCount * multiplier >= maxSupply) throw; 
        if (minedTokenCount > 0) {
            for (uint256 i = 0; i < minedTokenCount; i++) {
                if (minedTokens[i].block == block.number) throw; 
            }
        }
        totalSupply += 1 * multiplier;
        balances[block.coinbase] += 1 * multiplier;                  // reward miner with one STA token
        minedTokens[minedTokenCount] = Miner(block.number, block.coinbase);
        minedTokenCount += 1;
        MessageClaimMiningReward(block.coinbase, block.number, 1 * multiplier);
    } 
    
    function selfDestroy() onlyOwner {
        if (block.number <= icoEndBlock+14*3456) throw;           // allow to suicide STA token after around 2 weeks (25s/block) from the end of ICO
        suicide(this); 
    }
    // /stable
   
    // Function to access name of token .
    function name() constant returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() constant returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    function minedTokenCount() constant returns (uint256 _minedTokenCount) {
        return minedTokenCount;
    }
    function icoAddress() constant returns (address _icoAddress) {
        return icoAddress;
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }
  
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) returns (bool success) {
        bytes memory empty;
        if(isContract(_to)) {
            transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
        return true;
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        _addr = _addr;  // workaround for Mist&#39;s inability to compile
        is_contract = is_contract;  // workaround for Mist&#39;s inability to compile
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

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
  
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
	
    function burn(address _address, uint256 _value) returns (bool success) {
        if (icoAddress == address(0)) throw;
        if (msg.sender != owner && msg.sender != icoAddress) throw; // only owner and ico contract are allowed
        if (balances[_address] < _value) throw;                     // Check if the sender has enough tokens
        balances[_address] -= _value;                               // Subtract from the sender
        totalSupply -= _value;                               
        Burn(_address, _value);
        return true;
    }
	
    /* setting ICO address for allowing execution from the ICO contract */
    function setIcoAddress(address _address) onlyOwner {
        if (icoAddress == address(0)) {
            icoAddress = _address;
        }    
        else throw;
    }
}

/**
* Stable Token - STB
*/
contract ERC223Token_STB is ERC223, SafeMath, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint) balances;
    
    // stable:
    uint256 public maxSupply;
    uint256 public icoEndBlock;
    address public icoAddress;
	
    function ERC223Token_STB() {
        totalSupply = 0;                                     // Update total supply
        maxSupply = 1000000000000;                           // Maximum possible supply of STB == 100M STB
        name = "STABLE STB Token";                           // Set the name for display purposes
        decimals = 4;                                        // Amount of decimals for display purposes
        symbol = "STB";                                      // Set the symbol for display purposes
        icoEndBlock = 4230150;  // INIT                      // last block number of ICO  // INIT PARAM             
        //balances[msg.sender] = totalSupply;                // Give the creator all initial tokens       
    }
    
    // Function to access max supply of tokens .
    function maxSupply() constant returns (uint256 _maxSupply) {
        return maxSupply;
    }
    // /stable
  
    // Function to access name of token .
    function name() constant returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() constant returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    function icoAddress() constant returns (address _icoAddress) {
        return icoAddress;
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }
  
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) returns (bool success) {
        bytes memory empty;
        if(isContract(_to)) {
            transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
        return true;
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        _addr = _addr;  // workaround for Mist&#39;s inability to compile
        is_contract = is_contract;  // workaround for Mist&#39;s inability to compile
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

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
  
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    /* setting ICO address for allowing execution from the ICO contract */
    function setIcoAddress(address _address) onlyOwner {
        if (icoAddress == address(0)) {
            icoAddress = _address;
        }    
        else throw;
    }

    /* mint new tokens */
    function mint(address _receiver, uint256 _amount) {
        if (icoAddress == address(0)) throw;
        if (msg.sender != icoAddress && msg.sender != owner) throw;     // mint allowed only for ICO contract and owner
        // if (block.number <= icoEndBlock) throw;                      // mint allowed only after ICO
        if (safeAdd(totalSupply, _amount) > maxSupply) throw;
        totalSupply = safeAdd(totalSupply, _amount); 
        balances[_receiver] = safeAdd(balances[_receiver], _amount);
        Transfer(0, _receiver, _amount, new bytes(0)); 
    }
    
    function selfDestroy() onlyOwner { // TEST ONLY
        suicide(this); 
    }
}

/* main contract - ICO */
contract StableICO is Ownable, SafeMath {
    uint256 public crowdfundingTarget;         // ICO target, in wei
    ERC223Token_STA public sta;                // address of STA token
    ERC223Token_STB public stb;                // address of STB token
    address public beneficiary;                // where the donation is transferred after successful ICO
    uint256 public icoStartBlock;              // number of start block of ICO
    uint256 public icoEndBlock;                // number of end block of ICO
    bool public isIcoFinished;                 // boolean for ICO status - is ICO finished?
    bool public isIcoSucceeded;                // boolean for ICO status - is crowdfunding target reached?
    bool public isDonatedEthTransferred;       // boolean for ICO status - is donation transferred to the secure account?
    bool public isStbMintedForStaEx;           // boolean for ICO status - is extra STB tokens minted for covering exchange of STA token?
    uint256 public receivedStaAmount;          // amount of received STA tokens from rewarded miners
    uint256 public totalFunded;                // amount of ETH donations
    uint256 public ownersEth;                  // amount of ETH transferred to ICO contract by the owner
    uint256 public oneStaIsStb;                // one STA value in STB
    
    struct Donor {                                                      // struct for ETH donations
        address donorAddress;
        uint256 ethAmount;
        uint256 block;
        bool exchangedOrRefunded;
        uint256 stbAmount;
    }
    mapping (uint256 => Donor) public donations;                        // storage for ETH donations
    uint256 public donationNum;                                         // counter of ETH donations
	
    struct Miner {                                                      // struct for received STA tokens
        address minerAddress;
        uint256 staAmount;
        uint256 block;
        bool exchanged;
        uint256 stbAmount;
    }
    mapping (uint256 => Miner) public receivedSta;                      // storage for received STA tokens
    uint256 public minerNum;                                            // counter of STA receives

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value); 
    
    event MessageExchangeEthStb(address from, uint256 eth, uint256 stb);
    event MessageExchangeStaStb(address from, uint256 sta, uint256 stb);
    event MessageReceiveEth(address from, uint256 eth, uint256 block);
    event MessageReceiveSta(address from, uint256 sta, uint256 block);
    event MessageReceiveStb(address from, uint256 stb, uint256 block, bytes data);  // it should never happen
    event MessageRefundEth(address donor_address, uint256 eth);
  
    /* constructor */
    function StableICO() {
        crowdfundingTarget = 200000000000000000; // INIT (test: 0.2 ETH)
        sta = ERC223Token_STA(0xe1e8f9bd535384a345c2a7a29a15df8fc345ad9c);  // INIT
        stb = ERC223Token_STB(0x1e46a3f0552c5acf8ced4fe21a789b412f0e792a);  // INIT
        beneficiary = 0x29ef9329bc15b7c11d047217618186b52bb4c8ff;  // INIT
        icoStartBlock = 4230000;  // INIT
        icoEndBlock = 4230150;  // INIT
    }		
    
    /* trigger rewarding the miner with STA token */
    function claimMiningReward() public onlyOwner {
        sta.claimMiningReward();
    }
	
    /* Receiving STA from miners - during and after ICO */
    function tokenFallback(address _from, uint256 _value, bytes _data) {
        if (block.number < icoStartBlock) throw;
        if (msg.sender == address(sta)) {
            if (_value < 50000000) throw; // minimum 0.5 STA
            if (block.number < icoEndBlock+14*3456) {  // allow STA tokens exchange for around 14 days (25s/block) after ICO
                receivedSta[minerNum] = Miner(_from, _value, block.number, false, 0);
                minerNum += 1;
                receivedStaAmount = safeAdd(receivedStaAmount, _value);
                MessageReceiveSta(_from, _value, block.number);
            } else throw;	
        } else if(msg.sender == address(stb)) {
            MessageReceiveStb(_from, _value, block.number, _data);
        } else {
            throw; // other tokens
        }
    }

    /* Receiving ETH */
    function () payable {

        if (msg.value < 10000000000000000) throw;  // minimum 0.1 ETH  TEST: 0.01ETH
		
        // before ICO (pre-ico)
        if (block.number < icoStartBlock) {
            if (msg.sender == owner) {
                ownersEth = safeAdd(ownersEth, msg.value);
            } else {
                totalFunded = safeAdd(totalFunded, msg.value);
                donations[donationNum] = Donor(msg.sender, msg.value, block.number, false, 0);
                donationNum += 1;
                MessageReceiveEth(msg.sender, msg.value, block.number);
            }    
        } 
        // during ICO
        else if (block.number >= icoStartBlock && block.number <= icoEndBlock) {
            if (msg.sender != owner) {
                totalFunded = safeAdd(totalFunded, msg.value);
                donations[donationNum] = Donor(msg.sender, msg.value, block.number, false, 0);
                donationNum += 1;
                MessageReceiveEth(msg.sender, msg.value, block.number);
            } else ownersEth = safeAdd(ownersEth, msg.value);
        }
        // after ICO - first ETH transfer is returned to the sender
        else if (block.number > icoEndBlock) {
            if (!isIcoFinished) {
                isIcoFinished = true;
                msg.sender.transfer(msg.value);  // return ETH to the sender
                if (totalFunded >= crowdfundingTarget) {
                    isIcoSucceeded = true;
                    exchangeStaStb(0, minerNum);
                    exchangeEthStb(0, donationNum);
                    drawdown();
                } else {
                    refund(0, donationNum);
                }	
            } else {
                if (msg.sender != owner) throw;  // WARNING: senders ETH may be lost (if transferred after finished ICO)
                ownersEth = safeAdd(ownersEth, msg.value);
            }    
        } else {
            throw;  // WARNING: senders ETH may be lost (if transferred after finished ICO)
        }
    }

    /* send STB to the miners who returned STA tokens - after successful ICO */
    function exchangeStaStb(uint256 _from, uint256 _to) private {  
        if (!isIcoSucceeded) throw;
        if (_from >= _to) return;  // skip the function if there is invalid range given for loop
        uint256 _sta2stb = 10**4; 
        uint256 _wei2stb = 10**14; 

        if (!isStbMintedForStaEx) {
            uint256 _mintAmount = (10*totalFunded)*5/1000 / _wei2stb;  // 0.5% extra STB minting for STA covering
            oneStaIsStb = _mintAmount / 100;
            stb.mint(address(this), _mintAmount);
            isStbMintedForStaEx = true;
        }	
			
        /* exchange */
        uint256 _toBurn = 0;
        for (uint256 i = _from; i < _to; i++) {
            if (receivedSta[i].exchanged) continue;  // skip already exchanged STA
            stb.transfer(receivedSta[i].minerAddress, receivedSta[i].staAmount/_sta2stb * oneStaIsStb / 10**4);
            receivedSta[i].exchanged = true;
            receivedSta[i].stbAmount = receivedSta[i].staAmount/_sta2stb * oneStaIsStb / 10**4;
            _toBurn += receivedSta[i].staAmount;
            MessageExchangeStaStb(receivedSta[i].minerAddress, receivedSta[i].staAmount, 
              receivedSta[i].staAmount/_sta2stb * oneStaIsStb / 10**4);
        }
        sta.burn(address(this), _toBurn);  // burn received and processed STA tokens
    }
	
    /* send STB to the donors - after successful ICO */
    function exchangeEthStb(uint256 _from, uint256 _to) private { 
        if (!isIcoSucceeded) throw;
        if (_from >= _to) return;  // skip the function if there is invalid range given for loop
        uint256 _wei2stb = 10**14; // calculate eth to stb exchange
        uint _pb = (icoEndBlock - icoStartBlock)/4; 
        uint _bonus;

        /* mint */
        uint256 _mintAmount = 0;
        for (uint256 i = _from; i < _to; i++) {
            if (donations[i].exchangedOrRefunded) continue;  // skip already minted STB
            if (donations[i].block < icoStartBlock + _pb) _bonus = 6;  // first period; bonus in %
            else if (donations[i].block >= icoStartBlock + _pb && donations[i].block < icoStartBlock + 2*_pb) _bonus = 4;  // 2nd
            else if (donations[i].block >= icoStartBlock + 2*_pb && donations[i].block < icoStartBlock + 3*_pb) _bonus = 2;  // 3rd
            else _bonus = 0;  // 4th
            _mintAmount += 10 * ( (100 + _bonus) * (donations[i].ethAmount / _wei2stb) / 100);
        }
        stb.mint(address(this), _mintAmount);

        /* exchange */
        for (i = _from; i < _to; i++) {
            if (donations[i].exchangedOrRefunded) continue;  // skip already exchanged ETH
            if (donations[i].block < icoStartBlock + _pb) _bonus = 6;  // first period; bonus in %
            else if (donations[i].block >= icoStartBlock + _pb && donations[i].block < icoStartBlock + 2*_pb) _bonus = 4;  // 2nd
            else if (donations[i].block >= icoStartBlock + 2*_pb && donations[i].block < icoStartBlock + 3*_pb) _bonus = 2;  // 3rd
            else _bonus = 0;  // 4th
            stb.transfer(donations[i].donorAddress, 10 * ( (100 + _bonus) * (donations[i].ethAmount / _wei2stb) / 100) );
            donations[i].exchangedOrRefunded = true;
            donations[i].stbAmount = 10 * ( (100 + _bonus) * (donations[i].ethAmount / _wei2stb) / 100);
            MessageExchangeEthStb(donations[i].donorAddress, donations[i].ethAmount, 
              10 * ( (100 + _bonus) * (donations[i].ethAmount / _wei2stb) / 100));
        }
    }
  
    // send funds to the ICO beneficiary account - after successful ICO
    function drawdown() private {
        if (!isIcoSucceeded || isDonatedEthTransferred) throw;
        beneficiary.transfer(totalFunded);  
        isDonatedEthTransferred = true;
    }
  
    /* refund ETH - after unsuccessful ICO */
    function refund(uint256 _from, uint256 _to) private {
        if (!isIcoFinished || isIcoSucceeded) throw;
        if (_from >= _to) return;
        for (uint256 i = _from; i < _to; i++) {
            if (donations[i].exchangedOrRefunded) continue;
            donations[i].donorAddress.transfer(donations[i].ethAmount);
            donations[i].exchangedOrRefunded = true;
            MessageRefundEth(donations[i].donorAddress, donations[i].ethAmount);
        }
    }
    
    // send owner&#39;s funds to the ICO owner - after ICO
    function transferEthToOwner(uint256 _amount) public onlyOwner { 
        if (!isIcoFinished || _amount <= 0 || _amount > ownersEth) throw;
        owner.transfer(_amount); 
        ownersEth -= _amount;
    }    

    // send STB to the ICO owner - after ICO
    function transferStbToOwner(uint256 _amount) public onlyOwner { 
        if (!isIcoFinished || _amount <= 0) throw;
        stb.transfer(owner, _amount); 
    }    
    
    
    /* backup functions to be executed "manually" - in case of a critical ethereum platform failure 
      during automatic function execution */
    function backup_finishIcoVars() public onlyOwner {
        if (block.number <= icoEndBlock || isIcoFinished) throw;
        isIcoFinished = true;
        if (totalFunded >= crowdfundingTarget) isIcoSucceeded = true;
    }
    function backup_exchangeStaStb(uint256 _from, uint256 _to) public onlyOwner { 
        exchangeStaStb(_from, _to);
    }
    function backup_exchangeEthStb(uint256 _from, uint256 _to) public onlyOwner { 
        exchangeEthStb(_from, _to);
    }
    function backup_drawdown() public onlyOwner { 
        drawdown();
    }
    function backup_drawdown_amount(uint256 _amount) public onlyOwner {
        if (!isIcoSucceeded) throw;
        beneficiary.transfer(_amount);  
    }
    function backup_refund(uint256 _from, uint256 _to) public onlyOwner { 
        refund(_from, _to);
    }
    /* /backup */

    function selfDestroy() onlyOwner { // TEST ONLY
        suicide(this); 
    }
}