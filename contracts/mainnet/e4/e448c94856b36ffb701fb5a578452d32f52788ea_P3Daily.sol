pragma solidity ^0.4.25;

contract P3Daily {
    
    using SafeMath for uint256;
    
    struct Round {
        uint256 pot;
        uint256 ticketsSold;
        uint256 blockNumber;
        uint256 startTime;
        mapping(uint256 => address) tickets;
        mapping(address => uint256) ticketsPerAddress;
    }
    
    HourglassInterface constant p3dContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    address constant sacMasternode = address(0x4fac33dAbFd83d160717dFee4175d9cAaA249CA5);
    address constant dev = address(0xF0EA6CE7d210Ee58e83a463Af13989B5c2DbE108);
    
    uint256 constant public PRICE_PER_TICKET = 0.01 ether;
    uint256 constant public ROUND_LENGTH = 24 hours;
    
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256) private vault;
    
    uint256 public currentRoundNumber;
    
    event TicketsPurchased(address indexed player, uint256 indexed amount);
    event LotteryWinner(address indexed winner, uint256 indexed winnings, uint256 indexed ticket);
    event WithdrawVault(address indexed player, uint256 indexed amaount);
    event Validator(address indexed validator, uint256 indexed reward);
    
    modifier isValidPurchase(uint256 _howMany)
    {
        require(_howMany > 0);
        require(msg.value == _howMany.mul(PRICE_PER_TICKET));
        _;
    }
    
    modifier canPayFromVault(uint256 _howMany)
    {
        require(_howMany > 0);
        require(vault[msg.sender] >= _howMany.mul(PRICE_PER_TICKET));
        _;
    }
    
    modifier positiveVaultBalance()
    {
        require(vault[msg.sender] > 0);
        _;
    }
    
    constructor()
        public
    {
        currentRoundNumber = 0;
        rounds[currentRoundNumber] = Round(0, 0, 0, now);
    }
    
    function() external payable {}
       
    function isRoundOver()
        public
        view
        returns(bool)
    {
        return now >= rounds[currentRoundNumber].startTime.add(ROUND_LENGTH);
    }
    
    function potentialWinner()
        external
        view
        returns(address)
    {
        if(isRoundOver() &&
        rounds[currentRoundNumber].blockNumber != 0 &&
        block.number - 256 <= rounds[currentRoundNumber].blockNumber &&
        rounds[currentRoundNumber].blockNumber != block.number) {
            uint256 potentialwinningTicket = uint256(blockhash(rounds[currentRoundNumber].blockNumber)) % rounds[currentRoundNumber].ticketsSold;
            return rounds[currentRoundNumber].tickets[potentialwinningTicket];
        }
        
        return address(0);
    }
    
    function blocksUntilNewPotentialWinner()
        external
        view
        returns (uint256)
    {
        if(isRoundOver() &&
        rounds[currentRoundNumber].blockNumber != 0 &&
        block.number - 256 <= rounds[currentRoundNumber].blockNumber &&
        rounds[currentRoundNumber].blockNumber != block.number) {
           return 256 - (block.number - rounds[currentRoundNumber].blockNumber);
        }
        
        return 0;
    }
    
    function getTicketOwner(uint256 _number)
        external
        view
        returns(address)
    {
        return rounds[currentRoundNumber].tickets[_number];
    }
    
     function ticketsPurchased()
        external
        view
        returns(uint256)
    {
        return rounds[currentRoundNumber].ticketsSold;
    }
    
    function timeLeft()
        external
        view
        returns(uint256)
    {
        if(isRoundOver()) {
            return 0;
        }
        
        return ROUND_LENGTH.sub(now.sub(rounds[currentRoundNumber].startTime));
    }
    
    function jackpotSize()
        external
        view
        returns(uint256)
    {
        return rounds[currentRoundNumber].pot.add(p3dContract.myDividends(true)).mul(97) / 100;
    }
    
    function validatorReward()
        external
        view
        returns(uint256)
    {
        return rounds[currentRoundNumber].pot.add(p3dContract.myDividends(true)) / 100;
    }
    
    function myVault()
        external
        view
        returns(uint256)
    {
        return vault[msg.sender];
    }
    
    function myTickets()
        external
        view
        returns(uint256)
    {
        return rounds[currentRoundNumber].ticketsPerAddress[msg.sender];
    }
    
    function purchaseTicket(uint256 _howMany)
        external
        payable
        isValidPurchase(_howMany)
    {
        if(!isRoundOver() || onRoundEnd()) {
            acceptPurchase(_howMany, msg.value);
        } else {
            vault[msg.sender] = vault[msg.sender].add(msg.value);
        }
    }
    
    function purchaseFromVault(uint256 _howMany)
        external
        canPayFromVault(_howMany)
    {
        if(!isRoundOver() || onRoundEnd()) {
            uint256 value = _howMany.mul(PRICE_PER_TICKET);
            vault[msg.sender] -= value;
            acceptPurchase(_howMany, value);
        }
    }
    
    function validate()
        external
    {
        require(isRoundOver());
        
        onRoundEnd();
    }
    
    function withdrawFromVault()
        external
        positiveVaultBalance
    {
        uint256 amount = vault[msg.sender];
        vault[msg.sender] = 0;
        
        emit WithdrawVault(msg.sender, amount);
        
        msg.sender.transfer(amount);
    }
    
    function onRoundEnd()
        private
        returns(bool newRound)
    {
        //no tickets sold => create new round
        if(rounds[currentRoundNumber].ticketsSold == 0) {
            currentRoundNumber++;
            rounds[currentRoundNumber] = Round(0, 0, 0, now);
            return true;
        }
        
        //blocknumber has not been chosen or is too old => set new one
        if(rounds[currentRoundNumber].blockNumber == 0 || block.number - 256 > rounds[currentRoundNumber].blockNumber) {
            rounds[currentRoundNumber].blockNumber = block.number;
            return false;
        }
        
        //can&#39;t determine hash of current block
        if(block.number == rounds[currentRoundNumber].blockNumber) {return false;}
        
        //determine winner
        uint256 winningTicket = uint256(blockhash(rounds[currentRoundNumber].blockNumber)) % rounds[currentRoundNumber].ticketsSold;
        address winner = rounds[currentRoundNumber].tickets[winningTicket];
        
        uint256 totalWinnings = rounds[currentRoundNumber].pot;
        
        uint256 dividends = p3dContract.myDividends(true);
        if(dividends > 0) {
            p3dContract.withdraw();
            totalWinnings = totalWinnings.add(dividends);
        }
        
        //winner reward
        uint256 winnings = totalWinnings.mul(97) / 100;
        vault[winner] = vault[winner].add(winnings);
        emit LotteryWinner(winner, winnings, winningTicket);
        
        //validator reward
        vault[msg.sender] = vault[msg.sender].add(totalWinnings / 100);
        emit Validator(msg.sender, totalWinnings / 100);
        
        //dev fee
        vault[dev] = vault[dev].add(totalWinnings.mul(2) / 100);
        
        currentRoundNumber++;
        rounds[currentRoundNumber] = Round(0, 0, 0, now);
        return true;
    }
    
    function acceptPurchase(uint256 _howMany, uint256 value)
        private
    {
        uint256 ticketsSold = rounds[currentRoundNumber].ticketsSold;
        uint256 boundary = _howMany.add(ticketsSold);
        
        for(uint256 i = ticketsSold; i < boundary; i++) {
            rounds[currentRoundNumber].tickets[i] = msg.sender;
        }
        
        rounds[currentRoundNumber].ticketsSold = boundary;
        rounds[currentRoundNumber].pot = rounds[currentRoundNumber].pot.add(value.mul(60) / 100);
        rounds[currentRoundNumber].ticketsPerAddress[msg.sender] = rounds[currentRoundNumber].ticketsPerAddress[msg.sender].add(_howMany);
        
        emit TicketsPurchased(msg.sender, _howMany);
        
        p3dContract.buy.value(value.mul(40) / 100)(sacMasternode);
    }
}

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function withdraw() external;
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
}