pragma solidity ^0.4.18 ;

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

contract ContractiumInterface {
    function balanceOf(address who) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function contractSpend(address _from, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function owner() public view returns (address);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract AirdropContractium is Ownable {
    
    
    using SafeMath for uint256;
    
    //Contractium contract interface
    ContractiumInterface ctuContract;

    //Store addresses submitted
    mapping(address => bool) submitted;
    
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_AIRDROP = 20000000 * (10 ** uint256(decimals));
    address public constant CTU_ADDRESS = 0x943ACa8ed65FBf188A7D369Cfc2BeE0aE435ee1B;
    address public ctu_owner = 0x69f4965e77dFF568cF2f8877F2B39d636D581ae8;
    
    uint256 public reward = 200 * (10 ** uint256(decimals));
    uint256 public remainAirdrop;
   
    event Submit(address _addr, bool _isSuccess);
   
    constructor() public {
        owner = msg.sender;
        remainAirdrop = INITIAL_AIRDROP;
        ctuContract = ContractiumInterface(CTU_ADDRESS);
    }
    
    function getAirdrop() public isNotSubmitted isRemain returns (bool) {
        return submit(msg.sender);
    }
    
    function batchSubmit(address[] _addresses) public onlyOwner {
        for(uint i; i < _addresses.length; i++) {
            if (!submitted[_addresses[i]]) {
                submit(_addresses[i]);
            }
        }
    }
    
    
    function submit(address _addr) private returns (bool) {
        address _from = ctu_owner;
        address _to = _addr;
        uint256 _value = uint256(reward);
        bool isSuccess = ctuContract.transferFrom(_from, _to, _value);
        
        if (isSuccess) {
            submitted[_to] = true;
            remainAirdrop = remainAirdrop.sub(_value);
        }
        
        emit Submit(_addr, isSuccess);
        
        closeAirdrop();
        return isSuccess;
    }
    
    
    modifier isNotSubmitted() {
        require(!submitted[msg.sender]);
        _;
    }
    
    modifier isRemain() {
        require(remainAirdrop > 0);
        require(reward > 0);
        _;
    }
    
    function closeAirdrop() private {
        address _owner = ctu_owner;
        address _spender = address(this);
        uint256 _remain = ctuContract.allowance(_owner, _spender);
        
        if (_remain < reward) {
            reward = 0;
            remainAirdrop = 0;
        }
    }
  
    function setCtuContract(address _ctuAddress) public onlyOwner  returns (bool) {
        require(_ctuAddress != address(0x0));
        ctuContract = ContractiumInterface(_ctuAddress);
        ctu_owner = ctuContract.owner();
        return true;
    }
    
    function setRemainAirdrop(uint256 _remain) public onlyOwner  returns (bool) {
        remainAirdrop = _remain;
        return true;
    }
    
    function setReward(uint256 _reward) public onlyOwner  returns (bool) {
        reward = _reward;
        return true;
    }

    function transferOwnership(address _addr) public onlyOwner {
        super.transferOwnership(_addr);
    }

}