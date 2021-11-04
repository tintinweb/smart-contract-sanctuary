/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

interface IFaucet{
    function mint(address to, uint256 id, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}
contract Faucet{
    address public kwtCore;
    address public kwtErc20;
    constructor(address _core,address _kwterc20) public {
        kwtErc20 = _kwterc20;
        kwtCore = _core;
    }
    
    function faucet(address to, uint256[] memory id,uint256[] memory balance,uint256 kwtAmount) public{
        for(uint256 i = 0; i< id.length;i++){
            IFaucet(kwtCore).mint(to, id[i], balance[i]);
        }
        IFaucet(kwtErc20).mint(to,kwtAmount);
    }
}