/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity >=0.6.0 <=0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract LuckyPool{
    address public admin;
    address public cafe;
    
    mapping(address => uint256) private _balances;
    
    constructor (address _token) {
        cafe = _token;
        admin = msg.sender;
    }
    
    function deposit(uint256 amount) public {
        uint256 balance = IERC20(cafe).balanceOf(address(msg.sender));
        require(balance >= amount, "Pool: INSUFFICIENT_INPUT_AMOUNT");

        IERC20(cafe).transferFrom(msg.sender, address(this), amount);
        _balances[msg.sender] += amount;
    }
    
    function withdraw(uint256 amount) public {
        uint256 balance = _balances[msg.sender];
        require(balance >= amount, "Pool: INSUFFICIENT_OUTPUT_AMOUNT");
         
        IERC20(cafe).transfer(msg.sender, amount);
        _balances[msg.sender] -= amount;
    }
    
    function balanceOfPool(address user) public view returns (uint256 amount) {
        return _balances[user];
    }
    

}