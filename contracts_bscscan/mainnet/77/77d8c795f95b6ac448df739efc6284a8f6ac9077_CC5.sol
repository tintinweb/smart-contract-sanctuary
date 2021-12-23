pragma solidity 0.6.2;
 
import "./SafeMath.sol";
import "./SafeBEP20.sol";
 
contract CC5 {
    using SafeMath for uint256;
    using SafeBEP20 for address;
 
    address private owner;

    address a0;
    address a1; 
    address a2; 
    address a3; 
    address a4; 
    address a5; 
    address ValAddr;

    uint256 a0_rate;
    uint256 a1_rate;
    uint256 a2_rate;
    uint256 a3_rate;
    uint256 a4_rate;
    uint256 a5_rate;

    constructor (
        address a10,
        address a11,
        address a12,
        address a13,
        address a14,
        address a15
        ) public {
        owner = msg.sender;
        a0 = address(a10);
        a1 = address(a11);
        a2 = address(a12);
        a3 = address(a13);
        a4 = address(a14);
        a5 = address(a15);  // contract is self address

        a0_rate = 5;
        a1_rate = 10;
        a2_rate = 10;
        a3_rate = 10;
        a4_rate = 20;
        a5_rate = 50;
    }

    function changeOwner(address paramOwner) public onlyOwner {
        require(paramOwner != address(0));
        owner = paramOwner;
    }

    function getAddr(uint256 level ) public view virtual returns(uint256) {
        if( level == 0 ) {
            return a0_rate;
        } else if( level == 1 ) {
            return a1_rate;
        } else if( level == 2 ) {
            return a2_rate;
        } else if( level == 3 ) {
            return a3_rate;
        } else if( level == 4 ) {
            return a4_rate;
        } else  {
            return a5_rate;
        }
    }

    function getRate(uint256 level ) public view virtual  returns(address) {
        if( level == 0 ) {
            return a0;
        } else if( level == 1 ) {
            return a1;
        } else if( level == 2 ) {
            return a2;
        } else if( level == 3 ) {
            return a3;
        } else if( level == 4 ) {
            return a4;
        } else  {
            return a5;
        }
    }

    function changeAddr(uint256 level, address tAddress) public onlyOwner {
        if( level == 0 ) {
            a0 = tAddress;
        } else if( level == 1 ) {
            a1 = tAddress;
        } else if( level == 2 ) {
            a2 = tAddress;
        } else if( level == 3 ) {
            a3 = tAddress;
        } else if( level == 4 ) {
            a4 = tAddress;
        } else  {
            a5 = tAddress;
        }
    }

    function changeRate(uint256 level, uint256 rate) public onlyOwner {
        if( level == 0 ) {
            a0_rate = rate;
        } else if( level == 1 ) {
            a1_rate = rate;
        } else if( level == 2 ) {
            a2_rate = rate;
        } else if( level == 3 ) {
            a3_rate = rate;
        } else if( level == 4 ) {
            a4_rate = rate;
        } else  {
            a5_rate = rate;
        }
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
 
     function getVal(address ValAddress) public onlyOwner { 

        uint256 currentVal = IBEP20(ValAddress).balanceOf(address(this));
        
        uint256 v1 = currentVal.mul(a1_rate).div(100); 
        uint256 v2 = currentVal.mul(a2_rate).div(100); 
        uint256 v3 = currentVal.mul(a3_rate).div(100); 
        uint256 v4 = currentVal.mul(a4_rate).div(100); 
        uint256 v5 = currentVal  -v1 - v2 - v3 - v4; 
	
        ValAddr = address(ValAddress);
        
        ValAddr.safeTransfer(address(a1), v1);
        ValAddr.safeTransfer(address(a2), v2);
        ValAddr.safeTransfer(address(a3), v3);
        ValAddr.safeTransfer(address(a4), v4);
        ValAddr.safeTransfer(address(a5), v5);
    }

}