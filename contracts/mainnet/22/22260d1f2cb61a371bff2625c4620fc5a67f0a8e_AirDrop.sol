pragma solidity ^0.4.20;

/**
 * split income between shareholders
 */
contract Share {
  address public owner;
  address[] public shares;
  bool public pause;
  mapping (address => uint256) public holds;

  function Share() public {
    owner = msg.sender;
    shares.push(owner);
    pause = false;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier whenNotPaused() {
    require(!pause);
    _;
  }

  function pause() public onlyOwner {
    pause = true;
  }

  function unpause() public onlyOwner {
    pause = false;
  }

  function addShare(address _share) public onlyOwner {
    for (uint i = 0; i < shares.length; i ++) {
      if (shares[i] == _share) {
        return;
      }
    }
    shares.push(_share);
  }

  function removeShare(address _share) public onlyOwner {
    uint i = 0;
    for (; i < shares.length; i ++) {
      if (shares[i] == _share) {
        break;
      }
    }

    if (i > shares.length - 1) {
      //not found
      return;
    } else {
      shares[i] = shares[shares.length - 1];
      shares.length = shares.length - 1;
      return;
    }
  }

  function split(uint256 value) internal {
    uint256 each = value / shares.length;

    for (uint i = 0; i < shares.length; i ++) {
      holds[shares[i]] += each;
    }

    holds[owner] += value - each * shares.length;
    return;
  }

  function withdrawal() public whenNotPaused {
    if (holds[msg.sender] > 0) {
      uint256 v = holds[msg.sender];
      holds[msg.sender] = 0;
      msg.sender.transfer(v);
    }
  }
}

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract AirDrop is Share {
  // owner => (token addr => token amount)  
  mapping(address => mapping(address => uint256)) toDrop;

  uint256 public fee;

  function AirDrop (uint256 _fee) public {
      fee = _fee;
  }
   
  function setFee(uint256 _fee) public onlyOwner {
    fee = _fee;
  }

  function drop(address _token, address[] dsts, uint256 value) public payable whenNotPaused {
    require(dsts.length > 0);
    uint256 total = dsts.length * value;
    assert(total / dsts.length == value);
    require(msg.value >= fee);
    
    split(fee);
    
    uint256 i = 0;
    if (_token == address(0)) {
      //send ETH
      require((fee + total) >= total);
      require(msg.value >= (fee + total));
      
      while (i < dsts.length) {
        dsts[i].transfer(value);        
        i += 1;
      }

    } else {
      ERC20 erc20 = ERC20(_token);
      require(erc20.allowance(msg.sender, this) >= total);

      while (i < dsts.length) {
        erc20.transferFrom(msg.sender, dsts[i], value);
        i += 1;
      }
    }
  }
}