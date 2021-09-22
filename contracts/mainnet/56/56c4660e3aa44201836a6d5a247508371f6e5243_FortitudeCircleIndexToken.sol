pragma solidity ^0.8.7;

import "./ERC20.sol";

contract FortitudeCircleIndexToken is ERC20 {
    address public admin;
    constructor() ERC20('Fortitude Circle Index Token', 'FCIT') {
        _mint(msg.sender, 1000000000 * 10 ** 18);
        admin = msg.sender;
    }
    
    function mint(address to, uint amount) external {
        require(msg.sender == admin, 'only admin');
        _mint(to, amount);
    }
    
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
    
}