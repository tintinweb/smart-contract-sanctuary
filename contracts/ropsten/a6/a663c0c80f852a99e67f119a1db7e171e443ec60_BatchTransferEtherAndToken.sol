/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.5.7;



library SafeMath256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
    }


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        address __previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(__previousOwner, newOwner);
    }


    function rescueTokens(address tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20 __token = IERC20(tokenAddr);
        require(receiver != address(0));
        uint256 __balance = __token.balanceOf(address(this));
        
        require(__balance >= amount);
        assert(__token.transfer(receiver, amount));
    }
}


interface IERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}


contract BatchTransferEtherAndToken is Ownable {
    using SafeMath256 for uint256;
    
    IERC20 TOKEN = IERC20(0x0eACD9F66941D7d1885d5854F5b92575CE9eD5fd);


    function batchTransfer(address payable[] memory accounts, uint256 etherValue, uint256 tokenValue) public payable {
        uint256 __etherBalance = address(this).balance;
        uint256 __tokenAllowance = TOKEN.allowance(msg.sender, address(this));

        require(__etherBalance >= etherValue.mul(accounts.length));
        require(__tokenAllowance >= tokenValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            accounts[i].transfer(etherValue);
            assert(TOKEN.transferFrom(msg.sender, accounts[i], tokenValue));
        }
    }


    function batchTtransferEther(address payable[] memory accounts, uint256 etherValue) public payable {
        uint256 __etherBalance = address(this).balance;

        require(__etherBalance >= etherValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            accounts[i].transfer(etherValue);
        }
    }


    function batchTransferToken(address[] memory accounts, uint256 tokenValue) public {
        uint256 __tokenAllowance = TOKEN.allowance(msg.sender, address(this));

        require(__tokenAllowance >= tokenValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            assert(TOKEN.transferFrom(msg.sender, accounts[i], tokenValue));
        }
    }

    function batchTransferToken2(address[] memory accounts, uint256 tokenValue) public {

        for (uint256 i = 0; i < accounts.length; i++) {
            assert(TOKEN.transferFrom(address(this), accounts[i], tokenValue));
        }
    }
}