/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

interface IERC20Test {
    function mint(address account,uint256 amount) external;
}


contract Test{


    function callContractFn() public {
        IERC20Test _ERC20Test = IERC20Test(0x12765763DB974a8613E18fC2519219Eb9c4F9B49);
        _ERC20Test.mint(msg.sender,200);
    }
    // function callContractFn2() public {
    //     IERC20Test _ERC20Test = IERC20Test(0x12765763DB974a8613E18fC2519219Eb9c4F9B49);
    //     _ERC20Test.mint.value(msg.value)(msg.sender,200);
    // }

}