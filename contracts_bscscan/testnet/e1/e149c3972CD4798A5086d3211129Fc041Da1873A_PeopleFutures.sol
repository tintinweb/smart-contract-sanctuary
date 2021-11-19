//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract PeopleFutures {
    // total Contract Generated
    // Contract Admin Address
    address public prompti = 0x196B6c2cF3578f3b42ce4DEe65B4a5365e7A58d7;
    address public admin;
    // ------------------------------------------------------------------------
    // Mapping of Escrows
    // ------------------------------------------------------------------------
    event Withdraw(address owner, uint256 amount);
    event Deposit(address indexed owner, uint256 amount);
    mapping (address => uint256) public balances;

    constructor() {
        admin = msg.sender;
    }

    function getPrompti() public view returns(address){
        return prompti;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function deposit(address _owner, uint _amount) public {
        balances[_owner] += _amount;
        emit Deposit(_owner, _amount);
    }

    function withdraw(address _owner, uint _amount) external onlyAdmin() {
        require(balances[_owner] > _amount, "the amount is bigger than balance");
        balances[_owner] -= _amount;
        emit Withdraw(_owner, _amount);
    }
}