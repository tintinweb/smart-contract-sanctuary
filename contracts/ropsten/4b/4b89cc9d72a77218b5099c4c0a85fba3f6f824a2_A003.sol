/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity ^0.4.25;



/**
 * @title SafeMath for uint256
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath256 {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
}


/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract A003{


 using SafeMath256 for uint256;
address[] public myAddresses = [

0xcD2CAaae37354B7549aC7C526eDC432681821bbb,

0x8948e4b00deb0a5adb909f4dc5789d20d0851d71,

0xce82cf84558add0eff5ecfb3de63ff75df59ace0,

0xa732e7665ff54ba63ae40e67fac9f23ecd0b1223,

0x445b660236c39f5bc98bc49dddc7cf1f246a40ab,

0x60e31b8b79bd92302fe452242ea6f7672a77a80f

];
    /*
function () public payable {
require(myAddresses.length>0);

uint256 distr = msg.value/myAddresses.length;

for(uint256 i=0;i<myAddresses.length;i++)

{

myAddresses[i].transfer(distr);

}

}*/

function batchTtransferEther(address[] _to,uint256[] _value) public payable {
    require(_to.length>0);
    //uint256 distr = msg.value/myAddresses.length;
    for(uint256 i=0;i<_to.length;i++)
    {
        _to[i].transfer(_value[i]);
    }
}


  /**
     * @dev Batch transfer Ether.
     
    function batchTtransferEther(address payable[] memory accounts, uint256 etherValue) public payable {
        uint256 __etherBalance = address(this).balance;

        require(__etherBalance >= etherValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            accounts[i].transfer(etherValue);
        }
    }*/

/**
     * @dev Batch transfer Ether.
     
    function batchTtransferEther1(address payable[] memory accounts, uint256[] memory etherValue) public payable {
       // uint256 __etherBalance = address(this).balance;

       // require(__etherBalance >= etherValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            accounts[i].transfer(etherValue[i]);
        }
    }*/

    /**
     * @dev Batch  Token. years
     
    function batchTransferAgileToken(address[] memory accounts,uint256[] _value,address caddress) public {
        IERC20 VOKEN = IERC20(caddress);
       // uint256 __vokenAllowance = VOKEN.allowance(msg.sender, address(this));
        //require(__vokenAllowance >= vokenValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            VOKEN.transferFrom(msg.sender, accounts[i], _value[i]);
        }
    }*/


 /**
     * @dev Batch transfer Voken.
   
    function batchTransferVoken(address[] memory accounts, uint256 vokenValue) public {
        uint256 __vokenAllowance = VOKEN.allowance(msg.sender, address(this));

        require(__vokenAllowance >= vokenValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            assert(VOKEN.transferFrom(msg.sender, accounts[i], vokenValue));
        }
    }
  */
    
}