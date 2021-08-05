pragma solidity ^0.6.12;


import "ERC20.sol";
import "Ownable.sol";


contract DXMRToken is ERC20("Decentralized XMR", "DXMR"), Ownable {
    event Burn(address _to, uint256 _amount, string _destination);
    event Mint(address _to,uint256 _amount);
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        emit Mint(_to,_amount);
    }
    function burn(uint256 _amount, string calldata _destination) public {
        _burn(msg.sender, _amount);
        emit Burn(msg.sender,_amount,_destination);
    }
}
