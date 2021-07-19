//SourceUnit: TokenHelper.sol

pragma solidity 0.5.8;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function burnTokens(address _burnee, uint256 _amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenHelper {
    ITRC20 token;
    
    function lpBalanceOf(address _lpToken, address _user) public view returns (uint) {
        token == ITRC20(_lpToken);
        return (token.balanceOf(_user));
    }
}