/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

pragma solidity ^0.4.19;

contract SteakV2 {
    SteakV1 steak_1;

    string public constant name = "Steak";
    string public constant symbol = "STEAK";
    uint8 public constant decimals = 18;

    uint public newSteak;
    uint public claimBlock;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Claimed(address staker);
    event Burned(address staker);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    address[] private addresses;

    using SafeMath for uint256;

    constructor(uint256 _startSupply) public {
        steak_1 = SteakV1(0xEe80b739b1d2ADec66AB567D53Cf10eB1985bE81);
	    balances[msg.sender] = _startSupply;
	    newSteak = 1000000000000000000;
        claimBlock = block.number;
        addresses.push(msg.sender)-1;
    }  

    function totalSupply() public view returns (uint256) {
	    return totalStakingSupply();
    }
    
    function totalStakingSupply() public view returns (uint256) {
        uint supply = 0;
        for (uint j = 0; j < addresses.length; j++) {
            address y = addresses[j];
            supply = supply + balances[y];
        }
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        claim();
        
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        
        stake(receiver);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
        claim();
        
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        
        stake(receiver);
        emit Transfer(owner, receiver, numTokens);
        return true;
    }
    
    function stake(address steaker) private {
        for (uint i = 0; i < addresses.length; i++) {
            address x = addresses[i];
            if (x == steaker) {
                return;
            }
        }
        
        addresses.push(steaker)-1;
    }
    
    function claim() public {
        uint256 _totalSupply = totalSupply();
        uint token = (block.number - claimBlock) * newSteak;
        for (uint i = 0; i < addresses.length; i++) {
            address x = addresses[i];
            balances[x] += (token * balances[x] / _totalSupply);
        }

        claimBlock = block.number;
        emit Claimed(msg.sender);
    }
    
    function burn(uint256 numTokens) public {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        emit Burned(msg.sender);
    }
    
    function convert(uint256 numTokens) public {
        require(numTokens <= steak_1.balanceOf(msg.sender));
        steak_1.transferFrom(msg.sender, address(this), numTokens);
        balances[msg.sender] += numTokens;
        steak_1.stake();
    }
    
}

contract SteakV1 {
    function balanceOf(address) public pure returns (uint) {}
    function transferFrom(address, address, uint) public pure returns (bool) {}
    function stake() public pure {}
}

library SafeMath { 
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