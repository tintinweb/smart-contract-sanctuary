pragma solidity ^0.4.21;

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
contract POWH {
    
    function buy(address) public payable returns(uint256){}
    function withdraw() public {}
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
    
    modifier notPowh(address aContract){
        require(aContract != powh_address);
        _;
    }

    uint public multiplier;
    uint public payoutOrder = 0;
    address powh_address;
    POWH weak_hands;

    function BoomerangLiquidity(uint multiplierPercent, address powh) public {
        multiplier = multiplierPercent;
        powh_address = powh;
        weak_hands = POWH(powh_address);
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
        payout();
    }
    
    function payout() public {
        uint balance = address(this).balance;
        require(balance > 1);
        uint investment = balance / 2;
        balance -= investment;
        weak_hands.buy.value(investment).gas(1000000)(msg.sender);
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
            if(payoutOrder >= participants.length){
                return;
            }
        }
    }
    
    
    function withdraw() public {
        weak_hands.withdraw.gas(3000000)();
    }
    
    function donate() payable public {
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner notPowh(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    

    
}