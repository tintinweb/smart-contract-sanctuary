/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

pragma solidity ^0.4.16;


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

    uint8 public feePercent;

    function Feeable() public {
        feePercent = 80;
    }

    function setFeePercent(uint8 _feePercent) public onlyOwner {
        feePercent = _feePercent;
    }

    function minFee() public view returns(uint256) {
        return tx.gasprice * msg.gas * feePercent / 100;
    }
}


contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom( address from, address to, uint value) returns (bool ok);
}


contract Multiplexer is Feeable {

	function sendEth(address[] _to, uint256[] _value) payable returns (bool _success) {
		// input validation
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
        uint256 fee = minFee();
        require(msg.value > fee);

        uint256 remain_value = msg.value - fee;

		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
            require(remain_value >= _value[i]);
            remain_value = remain_value - _value[i];

			_to[i].transfer(_value[i]);
		}

		return true;
	}

	function sendErc20(address _tokenAddress, address[] _to, uint256[] _value) payable returns (bool _success) {
		// input validation
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
        require(msg.value >= minFee());

		// use the erc20 abi
		ERC20 token = ERC20(_tokenAddress);
		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
			assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
		}
		return true;
	}

    function claim(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(this);
        erc20token.transfer(owner, balance);
    }
}