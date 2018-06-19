pragma solidity 0.4.21;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract FLMContract {
    function withdraw() public;
    function buy() public payable returns(uint256);
    function myTokens() public view returns(uint256);
}

contract Owned {
    address public owner;
    address public ownerCandidate;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
    }
    
}

contract BoomerangLiquidity is Owned {
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    uint public multiplier;
    uint public payoutOrder = 0;
    FLMContract flmContract;

    function BoomerangLiquidity(uint multiplierPercent, address aFlmContract) public {
        multiplier = multiplierPercent;
        flmContract = FLMContract(aFlmContract);
    }
    
    
    struct Participant {
        address etherAddress;
        uint payout;
    }

    Participant[] public participants;

    
    function() payable public {
        deposit();
    }
    
    function deposit() payable public {
        participants.push(Participant(msg.sender, (msg.value * multiplier) / 100));
    }
    
    function payout() public {
        uint balance = address(this).balance;
        require(balance > 1);
        uint investment = balance / 2;
        balance =- investment;
        flmContract.buy.value(investment)();
        while (balance > 0) {
            uint payoutToSend = balance < participants[payoutOrder].payout ? balance : participants[payoutOrder].payout;
            if(payoutToSend > 0){
                participants[payoutOrder].payout -= payoutToSend;
                balance -= payoutToSend;
                if(!participants[payoutOrder].etherAddress.send(payoutToSend)){
                    participants[payoutOrder].etherAddress.call.value(payoutToSend).gas(1000000)();
                }
            }
            if(balance > 0){
                payoutOrder += 1;
            }
        }
    }
    
    function myTokens()
        public
        view
        returns(uint256) {
        return flmContract.myTokens();    
    }
    
    function withdraw() public {
        flmContract.withdraw.gas(1000000)();
    }
    
    function donate() payable public {
    }
    
    //THIS CONTRACT IS FOR TESTING. IF THIS IS HERE, DO NOT INVEST REAL MONEY.
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    //THIS CONTRACT IS FOR TESTING. IF THIS IS HERE, DO NOT INVEST REAL MONEY.
    function exitScam() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }
    
}