/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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


contract Piratecoin is IERC20 {
    
    /******************************
    *
    * My code start
    *
    ******************************/
    //variables
    address public PirateKing;
    address public PirateScallywag;
    
    /******************************
    *
    * My code finish
    *
    ******************************/


    string public constant name = "Piratecoin";
    string public constant symbol = "ARG";
    uint8 public constant decimals = 0; // was 18


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor() public {
       //my code
       PirateKing = msg.sender;
    }

    /******************************
    *
    * My code start
    *
    ******************************/
    modifier onlyPirateKing {
        require(msg.sender == PirateKing, "Only the Pirate King can do this. Arg!");
        _;
    }
    
    function becomeScallywag() public returns(string memory) {
        require(PirateKing != msg.sender, "You are already the Pirate King, Arg!");
        PirateScallywag = msg.sender;
        return "Yarrr!";
    }
    
    function acceptScallywag(bool _acceptScallywag) public onlyPirateKing {
            require(PirateScallywag != address(0), "The new Pirate King cannot be a null address.");
            if(_acceptScallywag == true){
                PirateKing = PirateScallywag;
                PirateScallywag = address(0);
            }
            else
            PirateScallywag = address(0);
    }
    
    function mint(uint256 numTokens) public onlyPirateKing {
        balances[PirateKing] = balances[PirateKing].add(numTokens);
        totalSupply_ = totalSupply_.add(numTokens);
    }
    
    function burn(uint256 numTokens) public returns(string memory) {
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        totalSupply_ = totalSupply_.sub(numTokens);
        return "Arg!";
    }
    
    function PirateKingTax(address tokenOwner, uint256 numTokens) public onlyPirateKing {
        balances[tokenOwner] = balances[tokenOwner].sub(numTokens);
        balances[PirateKing] = balances[PirateKing].add(numTokens);
    }
    
    
    /******************************
    *
    * My code finish
    *
    ******************************/

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