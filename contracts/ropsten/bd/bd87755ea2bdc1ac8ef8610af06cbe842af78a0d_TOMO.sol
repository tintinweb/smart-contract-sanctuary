pragma solidity ^0.4.25;

library SafeMath {
  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) 
      internal 
      pure 
      returns (uint256 c) 
  {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "SafeMath mul failed");
    return c;
  }

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
  
  /**
    * @dev gives square root of given x.
    */
  function sqrt(uint256 x)
      internal
      pure
      returns (uint256 y) 
  {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y) 
    {
      y = z;
      z = ((add((x / z),z)) / 2);
    }
  }
  
  /**
    * @dev gives square. batchplies x by x
    */
  function sq(uint256 x)
      internal
      pure
      returns (uint256)
  {
    return (mul(x,x));
  }
  
  /**
    * @dev x to the power of y 
    */
  function pwr(uint256 x, uint256 y)
      internal 
      pure 
      returns (uint256)
  {
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else 
    {
      uint256 z = x;
      for (uint256 i=1; i < y; i++)
        z = mul(z,x);
      return (z);
    }
  }
}

contract TOMO{
    address public admin;
    address[] public players;
    uint8[] public luckynumbers;
    uint256 sizebet;
    uint256 win;
    uint256 _seed = now;
    event BetResult(
    address from,
    uint256 betvalue,
    uint256 prediction,
    uint8 luckynumber,
    bool win,
    uint256 wonamount
    );
    
    event LuckyDrop(
    address from,
    uint256 betvalue,
    uint256 prediction,
    uint8 luckynumber,
    string congratulation
    );
    
    event Shake(
    address from,
    bytes32 make_chaos
    );
    
    constructor() public{
        admin = 0x1E1C1Fa8Ee39151ba082daE2F24E906882F4681C;
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty, _seed))%100); // random 0-99
    }

    function bet(uint8 under) public payable{
        require(msg.value >= .001 ether);
        require(under > 0 && under < 96);
        sizebet = msg.value;
        win = uint256 (sizebet*98/under);
        uint8 _random = random();
        luckynumbers.push(_random);
        
        if (_random < under) {
            if (msg.value*98/under < address(this).balance) {
                msg.sender.transfer(win);
                emit BetResult(msg.sender, msg.value, under, _random, true, win);
            }
            else {
                msg.sender.transfer(address(this).balance);
                emit BetResult(msg.sender, msg.value, under, _random, true, address(this).balance);
            }
        } else {
            emit BetResult(msg.sender, msg.value, under, _random, false, 0x0);
        }
    }
    

    modifier onlyAdmin() {
        // Ensure the participant awarding the ether is the admin
        require(msg.sender == admin);
        _;
    }
    
    function withdrawEth(address to, uint256 balance) onlyAdmin {
        if (balance == uint256(0x0)) {
            to.transfer(address(this).balance);
        } else {
        to.transfer(balance);
    }
  }

    function getLuckynumber() public view returns(uint8[]) {
        // Return list of luckynumbers
        return luckynumbers;
    }
    function shake(uint256 choose_a_number_to_chaos_the_algo) public {
        _seed = uint256(keccak256(choose_a_number_to_chaos_the_algo));
        emit Shake(msg.sender, "You changed the algo");
    }
    
}