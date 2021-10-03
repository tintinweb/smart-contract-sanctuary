/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

pragma solidity >=0.7.0 <0.9.0;

interface IERC20{
    function balanceOf(address) external returns(uint);
    function transfer(address dst, uint wad) external returns (bool);
}
interface IStrategy {
    function harvest() external;
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


contract VAULT{
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function harvest() public{
        require(!isContract(msg.sender), "!contract");
        require(tx.origin == msg.sender, "!origin");
        
        IERC20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd).transfer( msg.sender, 1 );
    }
}