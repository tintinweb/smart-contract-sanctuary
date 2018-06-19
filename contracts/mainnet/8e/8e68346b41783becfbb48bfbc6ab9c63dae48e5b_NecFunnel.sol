pragma solidity 0.4.21;

contract ERC20Interface {
    function transfer(address _to, uint _value) public returns (bool) {}
}

contract WhitelistInterface {

    modifier onlyAdmins() {
        require(isAdmin(msg.sender));
        _;
    }

    function register(address[] newUsers) public onlyAdmins {}
  
    function isAdmin(address _admin) public view returns(bool) {}

}

contract NecFunnel {
    
    ERC20Interface token = ERC20Interface(0xCc80C051057B774cD75067Dc48f8987C4Eb97A5e);
    WhitelistInterface list = WhitelistInterface(0x0E55c54249F25f70D519b7Fb1c20e3331e7Ba76d);

    modifier onlyAdmins() {
        require(list.isAdmin(msg.sender));
        _;
    }
  
	event PaymentFailure(
		address payee,
		uint value
	);

	function dropNectar(address[] receivers, uint[] values) public onlyAdmins {
	    list.register(receivers);
	    for (uint i = 0; i < receivers.length; i++){
	        if (!token.transfer(receivers[i],values[i])) {
	            emit PaymentFailure(receivers[i], values[i]);
	        }
	    }
	}
}