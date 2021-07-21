/**
 *Submitted for verification at polygonscan.com on 2021-07-21
*/

// File: contracts/interfaces/IVaultChef.sol

pragma solidity 0.6.12;


interface IVaultChef {

    function deposit(uint256 _pid, uint256 _wantAmt, address _to) external;

    function withdraw(uint256 _pid, uint256 _wantAmt, address _to) external;
}

// File: contracts/VaultChefWrapper.sol

pragma solidity 0.6.12;


contract VaultChefWrapper {
        
    IVaultChef public vaultChef;
        
    constructor(IVaultChef _vaultChef) public {
        vaultChef = _vaultChef;
    }
    
    function deposit(uint256 _pid, uint256 _wantAmt) external {
        vaultChef.deposit(_pid, _wantAmt, msg.sender);
    }

    function withdraw(uint256 _pid, uint256 _wantAmt) external {
        vaultChef.withdraw(_pid, _wantAmt, msg.sender);
    }
}