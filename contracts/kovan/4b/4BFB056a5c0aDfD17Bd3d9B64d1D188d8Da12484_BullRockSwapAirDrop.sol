/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

pragma solidity ^0.7.6;

interface IBEP20 {
    function balanceOf(address _owner) view external  returns (uint256 balance);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}



contract BullRockSwapAirDrop {

	using SafeMath for uint256;
    IBEP20 public token;
	address payable public owner;
	mapping(address=>bool) public taken;
	uint256 public claimamount= 5000e7;
	uint256 public refamount = 2000e7;
    constructor()  {
       owner = payable(0x03AA1cf0097041Df7Ee901518697bEDde21CCaB5);
       token = IBEP20(0xc302B4202828F95AaEE1094FA9cEbD16dDDC6807);

    }
    
	modifier onlyOwner() {
        require(msg.sender == owner,"bep20: Not an owner");
        _;
    }
    
    function claim(address refferer)public returns(bool){
        require(!taken[msg.sender],"already taken");
        token.transferFrom(owner,msg.sender,claimamount);
        token.transferFrom(owner,refferer,refamount);
        taken[msg.sender]=true;
        return true;
    }
    
    function changeClaimamount(uint256 _amount)public onlyOwner returns(bool){
        claimamount=_amount;
        return true;
    }
	
}

   library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    
    }