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

contract DynamicSKx2 {

        uint private multiplier;
        uint private payoutOrder = 0;

        address private owner;

        function DynamicSKx2(uint multiplierPercent) public {
            owner = msg.sender;
            multiplier = multiplierPercent;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        modifier onlyPositiveSend {
            require(msg.value > 0);
            _;
        }
        struct Participant {
            address etherAddress;
            uint payout;
        }

        Participant[] private participants;


        function() public payable onlyPositiveSend {
            participants.push(Participant(msg.sender, (msg.value * multiplier) / 100));
            uint balance = msg.value;
            while (balance > 0) {
                uint payoutToSend = balance < participants[payoutOrder].payout ? balance : participants[payoutOrder].payout;
                participants[payoutOrder].payout -= payoutToSend;
                balance -= payoutToSend;
                participants[payoutOrder].etherAddress.transfer(payoutToSend);
                if(balance > 0){
                    payoutOrder += 1;
                }
            }
        }


        function currentMultiplier() view public returns(uint) {
            return multiplier;
        }

        function totalParticipants() view public returns(uint count) {
                count = participants.length;
        }

        function numberOfParticipantsWaitingForPayout() view public returns(uint ) {
                return participants.length - payoutOrder;
        }

        function participantDetails(uint orderInPyramid) view public returns(address Address, uint Payout) {
                if (orderInPyramid <= participants.length) {
                        Address = participants[orderInPyramid].etherAddress;
                        Payout = participants[orderInPyramid].payout;
                }
        }
        
        function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
            return ERC20Interface(tokenAddress).transfer(owner, tokens);
        }
}