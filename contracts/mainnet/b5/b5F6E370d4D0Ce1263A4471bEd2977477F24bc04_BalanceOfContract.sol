/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-05
*/

pragma solidity =0.6.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}    

contract BalanceOfContract {
    
    function balanceOf(address _add,address[] memory _contractid) public view returns(uint256[] memory){
        uint256[] memory result = new uint256[](_contractid.length+1);
        result[0] = _add.balance;
        for(uint i=0;i<_contractid.length;i++){
            IERC20 erc20 = IERC20(_contractid[i]);
            result[i+1] = erc20.balanceOf(_add);
        }
        return result;
    }
    
}