// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./teste_2.sol";
import "./teste_1.sol";

contract teste_3 is ERC20{
    teste_2 teste_2Contract;
    teste_1 teste_1Contract;

    constructor (
        string memory _name,
        string memory _symbol,
        address _teste_2ContractAddress,
        address _teste_1ContractAddress
    )ERC20(_name,_symbol){
        teste_2Contract = teste_2(_teste_2ContractAddress);
        teste_1Contract = teste_1(_teste_1ContractAddress);
    }
    function mint(address to, uint256 amount) external {
        require(msg.sender == address(teste_2Contract) || msg.sender == address(teste_1Contract), "Not accessible");
        _mint(to, amount);
    }
    function burn(address to, uint256 amount) external {
        require(msg.sender == address(teste_2Contract) || msg.sender == address(teste_1Contract), "Not accessible");
        _burn(to, amount);
    }
}