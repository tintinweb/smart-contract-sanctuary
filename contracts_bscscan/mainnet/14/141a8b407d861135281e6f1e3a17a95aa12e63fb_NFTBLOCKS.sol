/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity ^0.6.0;

/**
 * NFTblocks.net
 * Your own piece of crypto history
*/

/**
 * Each of us wants to stand out and leave our own mark in history.
 * Unfortunately, not everyone has an opportunity to do so.
 * You can draw graffiti on the wall but anyone else can remove it.
 * You can start your own business and make it into a global company.
 * But will it still be around in 100 years? 
 * There are hundreds of examples in real life where you can try to leave your mark only for it to be erased.
 * But what if you have the desire to leave something lasting after you?
 * We have an answer. Go to the digital world!
 * Our solution is «NFTblocks», an online game with a whole crypto city, 
 * which will expand into the whole crypto world in the near future.
*/

contract NFTBLOCKS {

    string public constant name = "NFTBLOCKSV3";
    string public constant symbol = "NFTBLOCKSV3";
    uint8 public constant decimals = 2;
    uint256 public constant _totalSupply = 10000000000;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;

    constructor() public {
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public pure returns (uint256) {
	    return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
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

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
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