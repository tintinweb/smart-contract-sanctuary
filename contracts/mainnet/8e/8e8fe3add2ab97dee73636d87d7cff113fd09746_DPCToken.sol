pragma solidity ^0.6.12;


import "ERC20.sol";
import "Ownable.sol";


contract DPCToken is ERC20("Decentralized Privacy", "DPC"), Ownable {
    event Mint(address _to,uint256 _amount);
    function mint(address _to, uint256 _amount) public onlyOwner {
        emit Mint(_to,_amount);
        _mint(_to, _amount);
    }
}
