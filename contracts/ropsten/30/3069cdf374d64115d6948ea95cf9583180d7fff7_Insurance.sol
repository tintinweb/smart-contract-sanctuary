pragma solidity ^0.4.4;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Insurance {
    mapping (address => uint256) insured;
    
    /*
    Per risparmiare Gas, il proprietario dell&#39;assicurazione &#232; identificato dal server con
    thisContract.events.watchNew({fromBlock: lastBlock}, function (error, event) {
        if(!error) {
            web3.eth.getTransaction(event.transactionHash, function (error, tx) {
                if(!error) {
                    var owner = tx.from;
                }
            }
        }
    });
    */
    
    event watchNew(uint256 start, uint256 stop);
    event refunded(address id);
    
    modifier onlyServer() {
        require(msg.sender == 0x8649c813334c0Fb7c7aDF916B18ABbe20D48e813);
        _;
    }
    
    constructor() public {
        
    }
    
    /*
    Assicura una settimana a partire dal momento in cui l&#39;assicurazione viene stipulata
    */
    function insure() public payable {
        insured[msg.sender] += msg.value;
        emit watchNew(now,now+604800);
    }
    
    function refund(address id) public onlyServer {
        id.transfer(insured[id]*10); //Restituisci dieci volte quello che &#232; stato versato
        emit refunded(id);
    }
    
    function balanceOf(address id) public view returns (uint256) {
        return insured[id];
    }
}