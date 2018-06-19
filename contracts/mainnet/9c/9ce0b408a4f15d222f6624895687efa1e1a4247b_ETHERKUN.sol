pragma solidity ^0.4.20;

library SafeMath {

  /**0
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ETHERKUN {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
 function ETHERKUN() public {
    owner = msg.sender;
 }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
    
    using SafeMath for uint256;
    uint cooldownTime = 10 minutes;
    
    struct kun {
        uint price;
        uint atk;
        uint readyTime;
    }
    
    kun[] public kuns;
    
    mapping (uint => address) public kunToOwner;
    
    function getKun() external {
        uint id = kuns.push(kun(0, 0, now)) - 1;
        kunToOwner[id] = msg.sender;
    }
    
    //查询拥有的kun
  function getKunsByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](kuns.length);
    uint counter = 0;
    for (uint i = 0; i < kuns.length; i++) {
      if (kunToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
  
  function getKunsNum() external view returns(uint) {
    return kuns.length;
  }
  
  //
  function getBattleKuns(uint _price) external view returns(uint[]) {
    uint[] memory result = new uint[](kuns.length);
    uint counter = 0;
    for (uint i = 0; i < kuns.length; i++) {
      if (kuns[i].price > _price && kunToOwner[i] != msg.sender) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
  
  uint randNonce = 0;
    //Evolution price
    uint public testFee = 0.001 ether;
  
  event Evolution(address indexed owner, uint kunId,uint newAtk, uint oldAtk);
  event KunSell(address indexed owner, uint kunId,uint price);
  
  function randMod() internal returns(uint) {
    randNonce = randNonce.add(1);
    return uint(keccak256(now, randNonce, block.blockhash(block.number - 1), block.coinbase)) % 100;
  }
  
  //owner可以调整费率
  function setTestFee(uint _fee) external onlyOwner {
    testFee = _fee;
  }
  //检查必须是拥有者
  modifier onlyOwnerOf(uint _kunId) {
    require(msg.sender == kunToOwner[_kunId]);
    _;
  }
  
    //进入冷却 change to uint
  function _triggerCooldown(kun storage _kun) internal {
    _kun.readyTime = uint(now + cooldownTime);
  }

  //test逻辑
  function feed1(uint _kunId) external onlyOwnerOf(_kunId) payable {
    require(msg.value == testFee);
    kun storage mykun = kuns[_kunId];
    uint oldAtk = mykun.atk;
    uint random = randMod();
    if (random < 20) {
        mykun.atk = mykun.atk.add(50);
    } else if (random < 70) {
        mykun.atk = mykun.atk.add(100);
    } else if (random < 90) {
        mykun.atk = mykun.atk.add(200);
    } else {
         mykun.atk = mykun.atk.add(500);
    }
    mykun.price = mykun.price.add(msg.value);
    _triggerCooldown(mykun);
    Evolution(msg.sender, _kunId, mykun.atk, oldAtk);
  }
  
  function feed10(uint _kunId) external onlyOwnerOf(_kunId) payable {
    require(msg.value == testFee * 10);
    kun storage mykun = kuns[_kunId];
    uint oldAtk = mykun.atk;
    uint random = randMod();
    if (random < 20) {
        mykun.atk = mykun.atk.add(550);
    } else if (random < 70) {
        mykun.atk = mykun.atk.add(1100);
    } else if (random < 90) {
        mykun.atk = mykun.atk.add(2200);
    } else {
         mykun.atk = mykun.atk.add(5500);
    }
    mykun.price = mykun.price.add(msg.value);
    _triggerCooldown(mykun);
    Evolution(msg.sender, _kunId, mykun.atk, oldAtk);
  }
  
  function feed50(uint _kunId) external onlyOwnerOf(_kunId) payable {
    require(msg.value == testFee * 50);
    kun storage mykun = kuns[_kunId];
    uint oldAtk = mykun.atk;
    uint random = randMod();
    if (random < 20) {
        mykun.atk = mykun.atk.add(2750);
    } else if (random < 70) {
        mykun.atk = mykun.atk.add(5500);
    } else if (random < 90) {
        mykun.atk = mykun.atk.add(11000);
    } else {
         mykun.atk = mykun.atk.add(27500);
    }
    mykun.price = mykun.price.add(msg.value);
    _triggerCooldown(mykun);
    Evolution(msg.sender, _kunId, mykun.atk, oldAtk);
  }
  
  function feed100(uint _kunId) external onlyOwnerOf(_kunId) payable {
    require(msg.value == testFee * 100);
    kun storage mykun = kuns[_kunId];
    uint oldAtk = mykun.atk;
    uint random = randMod();
    if (random < 20) {
        mykun.atk = mykun.atk.add(6000);
    } else if (random < 70) {
        mykun.atk = mykun.atk.add(12000);
    } else if (random < 90) {
        mykun.atk = mykun.atk.add(24000);
    } else {
         mykun.atk = mykun.atk.add(60000);
    }
    mykun.price = mykun.price.add(msg.value);
    _triggerCooldown(mykun);
    Evolution(msg.sender, _kunId, mykun.atk, oldAtk);
  }
  
  function feed100AndPay(uint _kunId) external onlyOwnerOf(_kunId) payable {
    require(msg.value == testFee * 110);
    kun storage mykun = kuns[_kunId];
    uint oldAtk = mykun.atk;
    mykun.atk = mykun.atk.add(60000);
    mykun.price = mykun.price.add(testFee * 100);
    owner.transfer(testFee * 10);
    _triggerCooldown(mykun);
    Evolution(msg.sender, _kunId, mykun.atk, oldAtk);
  }
    
    //sellKun
    function sellKun(uint _kunId) external onlyOwnerOf(_kunId) {
        kun storage mykun = kuns[_kunId];
        if(now > mykun.readyTime) {
            msg.sender.transfer(mykun.price);
             KunSell( msg.sender, _kunId, mykun.price);
        } else{
            uint award = mykun.price * 19 / 20;
            msg.sender.transfer(award);
            owner.transfer(mykun.price - award);
             KunSell( msg.sender, _kunId, mykun.price * 19 / 20);
        }
        mykun.price = 0;
        mykun.atk = 0;
        kunToOwner[_kunId] = 0;
    }
    
    event kunAttackResult(address indexed _from,uint atk1, address _to, uint atk2, uint random, uint price);
  
  //判断是否ready
  function _isReady(kun storage _kun) internal view returns (bool) {
      return (_kun.readyTime <= now);
  }
  
  //attack
  function attack(uint _kunId, uint _targetId) external onlyOwnerOf(_kunId) {
    kun storage mykun = kuns[_kunId];
    kun storage enemykun = kuns[_targetId]; 
    require(_isReady(enemykun));
    require(enemykun.atk > 299 && mykun.atk > 0);
    uint rand = randMod();
    uint probability = mykun.atk * 100 /(mykun.atk + enemykun.atk) ;
    
    if (rand < probability) {
        //win
        msg.sender.transfer(enemykun.price);
        kunAttackResult(msg.sender, mykun.atk, kunToOwner[_targetId], enemykun.atk, rand, enemykun.price);
        enemykun.price = 0;
        enemykun.atk = 0;
        mykun.readyTime = now;
    } else {
        //loss
        uint award1 = mykun.price*9/10;
        kunToOwner[_targetId].transfer(award1);
        owner.transfer(mykun.price - award1);
        kunAttackResult(msg.sender, mykun.atk, kunToOwner[_targetId], enemykun.atk, rand, mykun.price*9/10);
        mykun.price = 0;
        mykun.atk = 0;
    }
  }
}