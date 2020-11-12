pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract GATORDrop {

    using SafeMath for uint256;
    address owner;
    address gatotoken;
    address[] public hugeetherinvest;

    mapping (address => bool) public blacklist;

    uint256 public rate = 0;
    uint256 public totalRemaining;
    uint256 public gatovalue;

    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event crowdsaleFinishedd();

    bool public distributionFinished;
    bool public crowdsaleFinished;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    modifier canDistrCS() {
        require(!crowdsaleFinished);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlynotblacklist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    function setgatotoken(address _gatotoken) public onlyOwner {
        require (_gatotoken != address(0));
        gatotoken = _gatotoken;
        totalRemaining = ERC20(gatotoken).balanceOf(address(this));
    } 
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    function startgato() onlyOwner public returns (bool) {
        distributionFinished = false;
        return true;
    }
    function startcrowdsale() onlyOwner public returns (bool) {
        crowdsaleFinished = false;
        return true;
    }
    function finishgato() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    function finishcrowdsale() onlyOwner canDistrCS public returns (bool) {
        crowdsaleFinished = true;
        emit crowdsaleFinishedd();
        return true;
    }
    
    function distr(address _to, uint256 _amount) private returns (bool) {

        totalRemaining = totalRemaining.sub(_amount);
        ERC20(gatotoken).transfer(_to,_amount);
        emit Distr(_to, _amount);
        return true;
        
        if (totalRemaining == 0) {
            distributionFinished = true;
            crowdsaleFinished = true;
        }
    }
    function setgatovalue(uint256 _value) public onlyOwner {
        gatovalue = _value.mul(1e18);
    }
    function () external payable{
        if(msg.value == 0){getTokenss();}else{getTokens();}         
    }
    function getTokenss() canDistr onlynotblacklist internal {
        
        require (gatovalue != 0);
        
        if (gatovalue > totalRemaining) {
            gatovalue = totalRemaining;
        }
        
        require(gatovalue <= totalRemaining);
        
        address investor = msg.sender;
        uint256 toGive = gatovalue;
        
        distr(investor, toGive);
        
        if (toGive > 0) {
            blacklist[investor] = true;
        }
    }
    
    function setethrate(uint _rate) onlyOwner public {
        rate = _rate;
    }
    function getTokens() canDistrCS public payable {
        
        require(msg.value >= 0.001 ether);
        require(rate > 0);
        
        uint256 value = msg.value.mul(rate);
        
        require(totalRemaining >= value);
        
        address investor = msg.sender;
        uint256 toGive = value;
        
        distr(investor, toGive);
        
        if(msg.value >= 0.1 ether){
            hugeetherinvest.push(msg.sender);
        }
    }
    function withdrawGATOfromcontract() public onlyOwner {
        ERC20(gatotoken).transfer(owner,ERC20(gatotoken).balanceOf(address(this)));
    }
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}