// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "ERC20.sol";
import "Ownable.sol";


contract AnimeToken is ERC20, Ownable {
    
    address public stakingContract;

    constructor() ERC20('AnimeToken', 'ANI')
    {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
    
    function setStakingContract(address _stakingContract) public onlyOwner {
        stakingContract = _stakingContract;
    }
    
    function mint(address _address, uint256 _amount) external {
        require(msg.sender == stakingContract, "Invalid caller");
        
        _mint(_address, _amount);
    }
}