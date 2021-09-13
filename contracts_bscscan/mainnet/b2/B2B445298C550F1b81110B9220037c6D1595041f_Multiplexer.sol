/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity ^0.4.15;
contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
contract Feeable is Ownable {

   
}

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom( address from, address to, uint value) returns (bool ok);
}

contract Multiplexer is Feeable {
	function sendEth(address[] _to) public payable returns (bool _success) {
	    require(_to.length<256);
		 uint256 vv = msg.value/_to.length;
		for (uint8 i = 0; i < _to.length; i++) {
			_to[i].transfer(vv);
		}
		return true;
	}
	function sendErc20( address[] _to, uint256 _value,address _tokenAddress)public  returns (bool _success) {
	    require(_to.length<256);
		// input validation
		// use the erc20 abi
		ERC20 token = ERC20(_tokenAddress);
		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
			assert(token.transferFrom(msg.sender, _to[i], _value) == true);
		}
		return true;
	}
    function claim(address _token) public onlyOwner {
        if (_token == msg.sender) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(this);
        erc20token.transfer(owner, balance);
    }
    function ThisAddress( ) public view returns (address) {
        return address(this);
    }
    
}