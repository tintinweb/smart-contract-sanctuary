// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.2;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

// contract vivek is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, ERC20Permit, ERC20Votes {
//     constructor() ERC20("vivek", "vivek") ERC20Permit("vivek") {
//         _mint(msg.sender, 50000000 * 10 ** decimals());
//     }

//     function snapshot() public onlyOwner {
//         _snapshot();
//     }

//     function pause() public onlyOwner {
//         _pause();
//     }

//     function unpause() public onlyOwner {
//         _unpause();
//     }

//     function mint(address to, uint256 amount) public onlyOwner {
//         _mint(to, amount);
//     }

//     function _beforeTokenTransfer(address from, address to, uint256 amount)
//         internal
//         whenNotPaused
//         override(ERC20, ERC20Snapshot)
//     {
//         super._beforeTokenTransfer(from, to, amount);
//     }

//     function _afterTokenTransfer(address from, address to, uint256 amount)
//         internal
//         override(ERC20, ERC20Votes)
//     {
//         super._afterTokenTransfer(from, to, amount);
//     }

//     function _mint(address to, uint256 amount)
//         internal
//         override(ERC20, ERC20Votes)
//     {
//         super._mint(to, amount);
//     }

//     function _burn(address account, uint256 amount)
//         internal
//         override(ERC20, ERC20Votes)
//     {
//         super._burn(account, amount);
//     }
// }
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}

