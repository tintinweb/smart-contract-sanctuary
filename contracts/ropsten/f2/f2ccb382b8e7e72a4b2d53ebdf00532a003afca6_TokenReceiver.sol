/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity ^0.8.10;

/*import "@openzeppelin/contracts/token/ERC20/IERC20.sol";*/
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title TokenReceiver
 * @dev Very simple example of a contract receiving ERC20 tokens.
 */
contract TokenReceiver {

    IERC20 private _token;

    event DoneStuff(address from);

    /**
     * @dev Constructor sets token that can be received
     */
    constructor (IERC20 token) public {
        _token = token;
    }

    /**
     * @dev Do stuff, requires tokens
     */
    function doStuff() external payable{
        address from = msg.sender;
        _token.approve(address(this), 1000);
        //_token.transferFrom(from, address(this), 1000);
        _token.transferFrom(from,address(this), 1000);
        emit DoneStuff(from);
    }
}