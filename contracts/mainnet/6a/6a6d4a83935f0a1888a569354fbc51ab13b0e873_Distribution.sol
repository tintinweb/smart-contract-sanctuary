/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

pragma solidity 0.5.12;

contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function _isOwner(address account) internal view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Distribution is Ownable {

    function transferETH(address payable[] memory recipients, uint256[] memory values) public payable onlyOwner {
        uint256 i;
        for (i; i < recipients.length; i++) {
            recipients[i].transfer(values[i]);
        }
    }

    function transferToken(IERC20 token, address[] memory recipients, uint256[] memory values) public onlyOwner {
        uint256 i;
        for (i; i < recipients.length; i++) {
            token.transfer(recipients[i], values[i]);
        }
    }

    function getContractBalanceOf(address tokenAddr) public view returns(uint256) {
        return IERC20(tokenAddr).balanceOf(address(this));
    }

    function getBalanceOf(address tokenAddr, address account) public view returns(uint256) {
        return IERC20(tokenAddr).balanceOf(account);
    }

}