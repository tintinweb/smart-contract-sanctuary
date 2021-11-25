//SourceUnit: paytc.sol

pragma solidity 0.5.10;
/**
* 
* A FINANCIAL SYSTEM BUILT ON TRON SMART CONTRACT TECHNOLOGY
* https://paytc.biz/
*
**/
contract PayTC {
	address payable public owner;
	address payable public platform_fee;
	event NewDeposit(address indexed addr,address indexed upline, uint256 amount);
	constructor() public {
        owner=msg.sender; 
        platform_fee = 0xA6c7652E10446eA338e0ce26DF3Ef3811530EDB2;
    }
	function deposit(address _upline) payable external {
		uint256 _amount=msg.value;
		require(_amount >= 1e8);
		platform_fee.transfer(_amount);
		emit NewDeposit(msg.sender,_upline, _amount);
    }
    function multisendTron(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total-_balances[i];
            _contributors[i].transfer(_balances[i]);
        }
    }
    function withdraw(address payable _receiver, uint256 _amount) public {
		if (msg.sender != owner) {revert("Access Denied");}
		_receiver.transfer(_amount);  
    }
    function setPayoutAccount(address payable _platform_fee) public {
        if (msg.sender != owner) {revert("Access Denied");}
		platform_fee=_platform_fee;
    }
}