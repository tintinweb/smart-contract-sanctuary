pragma solidity ^0.4.24;

// Fabrica pre-ICO stage
//      see proposal at fabrica.io

contract Ownable {
    address public owner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract myPreICO is Ownable {
    uint public ETHRaised;
    uint public soft_cap = 1 ether; // once we raise min 1 ETH, we can get them and start the ICO preparation
    uint public hard_cap = 10 ether;// once we&#39;ve raised 10 ETH, you can&#39;t withdraw them back, project will run to the ICO stage
    address public owner = 0x0;
    uint public end_date;
    address[] public holders;
    mapping (address => uint) public holder_balance;
    
    function myICO() public {
        owner = msg.sender;
        end_date = now + 90 days; // holders can take their money back some time later if pre-ICO failed
    }

    function sendFunds(address _addr) public onlyOwner {
        require (ETHRaised >= soft_cap); // can get $ETH only if soft_cap reached
        _addr.transfer(address(this).balance);
    }

    function withdraw() public {
        uint amount;
        require(now > end_date);// holders can take their money back if pre-ICO failed ...
        require(ETHRaised < hard_cap);// ... and hard_cap has&#39;t been reached
        amount = holder_balance[msg.sender];
        holder_balance[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function () public payable {
        require(msg.value > 0);
        holders.push(msg.sender);
        holder_balance[msg.sender] += msg.value;
        ETHRaised += msg.value;
    }

    function getFunds() public view returns (uint){
        return address(this).balance;
    }
}