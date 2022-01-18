/**
 *Submitted for verification at FtmScan.com on 2022-01-18
*/

pragma solidity ^0.8.11;
// SPDX-License-Identifier: GPL-3.0-or-later


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
interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public address_owner;
    constructor() { 
        address_owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(
            msg.sender == address_owner,
            "Only owner can call this function."
        );
        _;
    }
    function transferOwnership(address _address_owner) public onlyOwner {
        address_owner = _address_owner;
    }
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract MultiSender is Ownable {
    using SafeMath for uint256;
    address public receiverAddress;
    
    function allowance(address _token, address _owner, address _spender) public view returns (uint256) {
        ERC20 token = ERC20(_token);
        uint256 balance = token.allowance(_owner, _spender);
        return balance;
    }
    
    function amountToken(address _token, address _address) public view returns(uint256) {
        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(_address);
        return balance;
    }
          
 
    function amountEth(address _address) public view returns(uint256) {
        return _address.balance;
    }

    /*
     *  get balance
     */
    function getBalance(address _tokenAddress) public payable {
        address _receiverAddress = getReceiverAddress();
        if (_tokenAddress == address(0)) {
            payable(_receiverAddress).transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_receiverAddress, balance);
    }

    /*
     * set receiver address
     */
    function setReceiverAddress(address _addr) public onlyOwner {
        require(_addr != address(0));
        receiverAddress = _addr;
    }

    /*
     * get receiver address
     */
    function getReceiverAddress() public view returns (address) {
        if (receiverAddress == address(0)) {
            return owner;
        }

        return receiverAddress;
    }
    
    function multiSend(address[] memory tokens, address[] memory addresses, uint256[] memory values) public payable  {
        for(uint256 index = 0; index < addresses.length; index++) {
            address _address =  addresses[index];
            address _token =  tokens[index];
            uint256 value = values[index];
            if (_token == address(0))
            {
                payable(_address).transfer(value);
            }
            else {
                ERC20 tokenAddress = ERC20(_token);
                tokenAddress.transferFrom(msg.sender, _address, value);
            }
        }
        getBalance(address(0));
    }
    
    function multiSendToken(address _token, address[] memory addresses, uint256[] memory values) public payable {
        ERC20 tokenAddress = ERC20(_token);
        for(uint256 index = 0; index < addresses.length; index++) {
            address _address =  addresses[index];
            uint256 value = values[index];
            tokenAddress.transferFrom(msg.sender, _address, value);
        }
        getBalance(address(0));
    }

    function multiSendEth(address[] memory addresses, uint256[] memory values) public payable {
        for(uint256 index = 0; index < addresses.length; index++) {
            address _address =  addresses[index];
            uint256 value = values[index];
            payable(_address).transfer(value);
        }
        getBalance(address(0));
    }
  
    
    function multiSendTokenSameValue(address _token, address[] memory addresses, uint256 value) public payable {
        uint256[] memory values;
        for(uint256 index = 0; index < addresses.length; index++) {
            values[index] = value;
        }
        multiSendToken(_token, addresses, values);
    }

    function multiSendEthSameValue(address[] memory addresses,  uint256 value) public payable {
        uint256[] memory values;
        for(uint256 index = 0; index < addresses.length; index++) {
            values[index] = value;
        }
        multiSendEth(addresses, values);
    }
}