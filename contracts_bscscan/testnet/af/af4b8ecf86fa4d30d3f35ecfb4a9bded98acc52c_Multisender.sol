/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

pragma solidity ^0.6.2;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external payable returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Multisender is Ownable {
    event Tokensended(address toAddress, uint256 amount);

    uint256 arrayLimit = 500;

    constructor() public {}

    function getContractAddress() public view returns (address) {
        return address(this);
    }
    
    function getContractOwner() public view returns (address) {
        return owner;
    }

    function getBalanceOfToken(address _token, address _address) public view returns (uint256) {
        return ERC20(_token).balanceOf(_address);
    }

    function sendToken(address _token, address _receiver, uint _amount) public onlyOwner {        
        ERC20(_token).transfer(_receiver, _amount);
    }
    
    function bulkSendTokens(address _token, address[] memory _receivers, uint256[] memory _amounts) public payable {
        require(_receivers.length <= arrayLimit, "Array length should not exceed limit 500");
        require(
            _receivers.length == _amounts.length,
            "Addresses must equal amounts size."
        );

        ERC20 token = ERC20(_token);
        for (uint i = 0; i < _receivers.length; i++) {
            token.transferFrom(msg.sender, _receivers[i], _amounts[i]);
        }

        (bool success, ) = msg.sender.call.value(msg.value)("");
        require(success, "Fee transfer to owner failed.");
    }
    

    function bulkSendBNB(address payable[] memory _receivers, uint256[] memory _amounts) public payable {
        require(_receivers.length <= arrayLimit, "Array length should not exceed limit 500");
        require(
            _receivers.length == _amounts.length,
            "Addresses must equal amounts size."
        );

        uint256 total;
        for(uint i; i < _amounts.length; i++) {
            total += _amounts[i];
        }
        
        require(total <= msg.value, "Insufficient balance");

        for (uint i; i < _receivers.length; i++) {
            _receivers[i].transfer(_amounts[i]);
        }

        owner.transfer(msg.value - total);
    }

    function getTotalSupply(address _token) public view returns (uint256) {
        return ERC20(_token).totalSupply();
    }
}