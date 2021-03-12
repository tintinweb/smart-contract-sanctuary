/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity 0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract NEST35Staking {
    
    mapping(address=>mapping(address=>uint256)) _staked_balances;
    mapping(address=>mapping(address=>uint256)) _balance;
    
    
    constructor () public {}
    
    function addETH(address ntoken, address account) public payable {
        _balance[ntoken][account] = _balance[ntoken][account] + msg.value;
    }
    
    function addNToken(address ntoken, address account, uint256 amount) public {
        IERC20(ntoken).transferFrom(address(msg.sender), address(this), amount);
        _staked_balances[ntoken][account] = _staked_balances[ntoken][account] + amount;
    }
    
    // 查询ETH
    function stakedBalanceOf(address ntoken, address account) 
        public view returns (uint256) 
    {
        return _staked_balances[ntoken][account];
    }
    
    // 查询NToken
    function earned(address ntoken, address account) 
        public 
        view 
        returns (uint256) 
    {
        return _balance[ntoken][account];
    }
    
    function unstake(address ntoken, uint256 amount) 
        public 
    {
        require(amount > 0, "Nest:Stak:!amount");
        _staked_balances[ntoken][address(msg.sender)] = _staked_balances[ntoken][address(msg.sender)] - amount;
        IERC20(ntoken).transfer(address(msg.sender), amount);
    }
    
    function claim(address ntoken) 
        public 
    {
        uint256 eth = _balance[ntoken][address(msg.sender)];
        payable(address(uint160(msg.sender))).transfer(eth);
    }
}