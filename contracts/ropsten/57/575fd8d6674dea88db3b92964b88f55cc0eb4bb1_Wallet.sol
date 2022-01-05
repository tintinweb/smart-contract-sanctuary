/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

pragma solidity ^0.6.2;
interface  ERC20 {
    function balanceOf(address _owner) external view returns (uint256);
}
contract Account {
    address payable public reciever;
    address public from;
    address public owner;
    event Withdraw(address indexed from,uint256 value);
    event WithdrawToken(address indexed token,address indexed from,uint256 value);
    constructor(address token,address _from,address payable _reciever) public {
        reciever = _reciever;
        from = _from;
        owner = msg.sender;
        withdraw();
        if(token != address(0)){
            withdrawToken(token);
        }
        destory();
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        if (balance == 0){
            return;
        }
        reciever.transfer(balance);
        emit Withdraw(from, balance);
    }
    function withdrawToken(address token) public{
         uint256 balance = ERC20(token).balanceOf(address(this));
         if (balance == 0){
            return;
        }
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, reciever,balance));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Failed");
        emit WithdrawToken(token,from, balance);
    }

    function destory() public{
        require(msg.sender == owner, "403");
        selfdestruct(msg.sender);
    }
}

contract Wallet {
    address payable public admin;
    address payable public reciever;
    mapping(address => bool) public accounts;

    event Create(address);

    constructor(address payable _reciever) public {
        admin = msg.sender;
        reciever = _reciever;
    }
    modifier OnlyAdmin {
        require(msg.sender == admin, "403");
        _;
    }

    function withdraw(address token,address from,bytes32 _salt) public  OnlyAdmin{
        Account a = new Account{salt: _salt}(token,from,reciever);
        emit Create(address(a));
    }
}