pragma solidity ^0.4.18;
interface ERC20_Interface {
	function balanceOf(address _owner) external constant returns (uint balance) ;
	function transfer(address _to, uint _value) external;
}
contract GamePay {
	address private admin_;
	constructor() public {
		admin_ = msg.sender;
	}
	modifier olnyAdmin() {
        require(msg.sender == admin_, "only for admin"); 
        _;
    }
	function transferToken(address _erc20, address _to) olnyAdmin() public {
		ERC20_Interface it = ERC20_Interface(_erc20);
		uint value = it.balanceOf(address(this));
		if (value > 0)
		    it.transfer(_to, value);
	}
}