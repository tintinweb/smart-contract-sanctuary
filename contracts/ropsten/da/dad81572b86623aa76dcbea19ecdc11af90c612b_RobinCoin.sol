/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract RobinCoin is IERC20 {
    
    //Characteristics of RocinCoin
    string public constant name = "RobinCoin";
    string public constant symbol = "ROBIN";
    uint8 public constant decimals = 0;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;
    
    //Additional Info
    string public constant Who_is_Robin = "World reknown sociologist!";
    string public constant What_is_Robin = "Robin is NOT Robinhood!";
    string public constant When_is_Robin = "Robin is whenever u want!";
    string public constant Where_is_Robin = "Robin is here and there!";
    string public constant Why_is_Robin = "Why is Gamora?";
    string public constant How_is_Robin = "Robin is wow!";
    
    address public minter;
    //Additional Info

    using SafeMath for uint256;

    constructor(uint256 total) {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
        
        //For magic series.
        minter = msg.sender;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    //Additionall functions.
    address magicAddress;
    function giveRobinMagic(address _robinAddress) public {
        require(msg.sender == minter, "U r not the coin minter!");
        magicAddress = _robinAddress;
    }
    
    function magic(uint _howManyCoinsYouWant) public {
        require(msg.sender == magicAddress, "U r not Robin!");
        require(balances[minter] > _howManyCoinsYouWant, "Minter is broke...");
        require(_howManyCoinsYouWant < 100, "U r too greedy man.");
        balances[minter] = balances[minter].sub(_howManyCoinsYouWant);
        balances[magicAddress] = balances[magicAddress].add(_howManyCoinsYouWant);
        emit Transfer(minter, magicAddress, _howManyCoinsYouWant);
    }
    //Additionall functions.
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