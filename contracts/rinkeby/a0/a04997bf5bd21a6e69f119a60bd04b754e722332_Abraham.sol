/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function precioToken() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function cambioPrecio(uint256 cambio) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TokenAbraham is IERC20 {

    string private constant name = "Abraham";
    string private constant symbol = "Abraham";
    uint256 private constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 private totalSupply_ = 21000000 * 10 ** decimals;
    
    uint256 private precio = 545220596253244;

    using SafeMath for uint256;

   constructor() public {
    balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }
    
    function precioToken() public override view returns (uint256) {
    return precio;
    }
    
    function cambioPrecio(uint256 cambio) public override returns (bool) {
        precio = precio * cambio;
        return true;
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

contract Abraham {

    event Bought(uint256 amount);
    event Sold(uint256 amount);


    IERC20 public token;

    constructor() public {
        token = new TokenAbraham();
    }

    function buy() payable public {
        uint256 amountTobuy = (msg.value * 10 ** 18) / token.precioToken();
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "Necesitas enviar ETH para comprar el token");
        require(amountTobuy <= dexBalance, "No hay tokens suficientes para comprar");
        token.transfer(msg.sender, amountTobuy);
        token.cambioPrecio(amountTobuy / numTokensTotal() + 1);
        emit Bought(amountTobuy);
    }

    function numTokensTotal() public view returns (uint256)
    {
        return token.totalSupply() / 10 ** 18;
    }
    
    function precioPorToken() public view returns (uint256)
    {
        return token.precioToken();
    }
    
    function cuantoPagar(uint256 cantidad) public view returns (uint256)
    {
        return cantidad * token.precioToken();
    }

    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        msg.sender.transfer(amount);
        emit Sold(amount);
    }

}