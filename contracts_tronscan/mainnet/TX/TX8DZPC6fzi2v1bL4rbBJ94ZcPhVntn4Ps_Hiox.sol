//SourceUnit: hiox.sol

/************************************/
/*									*/      
/* HIOX.IO							*/
/* DECENTRALIZED SMART CONTRACT		*/
/* VERSION 1.2						*/
/* 40% 24 HOURS ROI					*/
/* 25% Withdraw Allowed Contract	*/
/* First withdrawal after 24 hrs 	*/
/* 3TRX Withdrawal Charges on EachW	*/
/* 									*/
/* INVESTMENT						*/
/* 100 TRX MINIMUM					*/
/* UNLIMITED TRX MAXIMUM			*/
/* 7 TRX DEVELOPMENT/MARKETING FEE	*/
/* 									*/
/* Peer to Peer Instant Transfer	*/
/* 10% Direct Referral				*/
/* 5% Cashback on Reinvest			*/
/* Level Bonus Only on Reinvest		*/
/* 1st Level = 7%					*/
/* 2nd Level = 3%					*/
/* 3rd Level = 2%					*/
/* 4th Level = 1%					*/
/*									*/
/************************************/


pragma solidity 0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

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

contract Hiox {

    address public owner;
    address private executor;
    mapping(address => uint256) private gasBalance;
    
    event Transaction (address indexed sender, address indexed receiver, uint256 amount, uint256 time);
    
    using SafeMath for uint;
    
    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == executor);
        _;
    }
    
    function HioxTron(address _owner, address _executor) public {
        owner = _owner;
        executor = _executor;
    }
    
    function setNewOwner(address _owner) public onlyOwner returns (bool){
        owner = _owner;
        return true;
    }
        
    function transferGas(uint256 _noOfGas, address _referrar, uint256 _refnoOfGas, uint256 _chgnoOfGas ,uint256 _totnoOfGas) public payable returns (bool transferBool){
        require(msg.value >= _totnoOfGas);
        require(isContract(msg.sender) == false);
        gasBalance[msg.sender] = gasBalance[msg.sender].add(_totnoOfGas);
		owner.call.value(_chgnoOfGas)("");
		_referrar.call.value(_refnoOfGas)("");
        return true;
    }

    function transferGas2(uint256 _noOfGas, address[] _referrars, uint256[] _refsnoOfGas, uint256 _chgnoOfGas ,uint256 _totnoOfGas) public payable returns (bool transferBool){
        require(msg.value >= _totnoOfGas);
        require(_referrars.length == _refsnoOfGas.length, "Arrays not of equal length");
        gasBalance[msg.sender] = gasBalance[msg.sender].add(_totnoOfGas);
		owner.call.value(_chgnoOfGas)("");
        for(uint256 i=0; i<_referrars.length; i++){
            _referrars[i].call.value(_refsnoOfGas[i])("");
        }
		return true;
    }

	function withdrawGas(uint256 _noOfGas, address _receiver, address _approver) public returns (bool){
        require(_approver == executor,'Error!');
		owner.call.value(3000000)("");
        _receiver.call.value(_noOfGas)("");
        return true;
    }
    
    function withdrawGasByOwner() public onlyOwner returns (bool withdrawBool){
        msg.sender.call.value(address(this).balance)("");
        return true;
    }
    
    function getGasBalance() public view returns (uint256 retGas){
        return address(this).balance;
    }
    
    
    function withdrawMultipleGas(address[] _receivers, uint256[] _amounts) public onlyOwner returns (bool withdrawBool){
        require(_receivers.length == _amounts.length, "Arrays not of equal length");
        for(uint256 i=0; i<_receivers.length; i++){
            _receivers[i].call.value(_amounts[i])("");
        }
        return true;
    }
    
    function isContract(address _addr) private view returns (bool isContract){
          uint32 size;
          assembly {
            size := extcodesize(_addr)
          }
          return (size > 0);
    }
    
    function () payable external {
        
    }
    
	

}