/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity 0.8.2;

abstract contract PS520Coin {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool supptess);
    function approve(address spender, uint256 tokens) public virtual returns (bool supptess);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool supptess);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract sunafeMath {
    function sunafeAdd(uint256 ppt, uint256 PS5) public pure returns (uint256 c1) {
        c1 = ppt + PS5;
        require(c1 >= ppt);
    }
    function sunafeSub(uint256 ppt, uint256 PS5) public pure returns (uint256 c1) {
        require(PS5 <= ppt);
        c1 = ppt - PS5;
    }
    function sunafeMul(uint256 ppt, uint256 PS5) public pure returns (uint256 c1) {
        c1 = ppt * PS5;
        require(c1 == 0 || c1 / ppt == PS5);
    }
    function sunafeDiv(uint256 ppt, uint256 PS5) public pure returns (uint256 c1) {
        require(PS5 > 0);
        c1 = ppt / PS5;
    }
}

contract ToinPS520 is  PS520Coin, sunafeMath {
    string public name =  "Download Pump";
    string public symbol =   "DPUMP";
    uint8 public decimals = 9;
    uint256 public _totalSupply = 10000000000000000000000; // 2000 billion SIM in supply

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address from, address to, uint256 tokens) private returns (bool supptess) {
        uint256 amountToBurn = sunafeDiv(tokens, 17); // 5% of the transaction shall be burned
        uint256 amountToTransfer = sunafeSub(tokens, amountToBurn);
        
        balances[from] = sunafeSub(balances[from], tokens);
        balances[0x0000000000000000000000000000000000000004] = sunafeAdd(balances[0x0000000000000000000000000000000000000004], amountToBurn);
        balances[to] = sunafeAdd(balances[to], amountToTransfer);
        return true;
    }

    function transfer(address to, uint256 tokens) public override returns (bool supptess) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint256 tokens) public override returns (bool supptess) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool supptess) {
        allowed[from][msg.sender] = sunafeSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}