// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20.sol";

/*
        @@@@@@           @@@@@@
      @@@@@@@@@@       @@@@@@@@@@
    @@@@@@@@@@@@@@   @@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@
          @@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@
              @@@@@@@@@@@
                @@@@@@@
                  @@@
*/
contract Loveswap is BEP20 {
    uint8 private constant DECIMALS = 8;
    uint public constant _totalSupply = 1_000_000_000_000 * 10**uint(DECIMALS);

    address private _admin;
    address private _newAdmin;
    uint private _maxAirdrop = 10_000_000 * 10**DECIMALS; //The maximum amount an admin can airdrop at a single time. Used to prevent mistyping amounts.
    uint private _airdropSupply = _totalSupply;

    constructor() BEP20("Loveswap DEX", "Loveswap") {
        _admin = msg.sender;
        _newAdmin = msg.sender;
        _mint(address(this), _totalSupply);
    }

    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    function editMaxAirdrop(uint newMax) public {
        require(msg.sender == _admin, "Admin address required.");
        _maxAirdrop = newMax * 10**DECIMALS;
    }

    //Allows the newAdmin address to claim the admin position. Two-step process to prevent mistyping the address.
    function editAdmin(address newAdmin) public {
        require(msg.sender == _admin, "Admin address required.");
        _newAdmin = newAdmin;
    }

    //If the calling address has been designated in the above editAdmin function, it will become the admin.
    //The old admin address will no longer have any admin priveleges.
    function claimAdmin() public {
        require(msg.sender == _newAdmin, "This address does not have the rights to claim the Admin position.");
        _admin = _newAdmin;
    }

    //Airdrops all given address the amount specified by the same index in the amounts array.
    //EX: addresses[4] receives amounts[4].
    function airdrop(address[] memory addresses, uint[] memory amounts) public {
        require(msg.sender == _admin, "Admin address required.");
        require(
            addresses.length == amounts.length,
            "Addresses and amounts arrays do not match in length."
        );
        for (uint i = 0; i < addresses.length; i++) {
            _airdrop(addresses[i], amounts[i] * 10**DECIMALS);
        }
    }

    function _airdrop(address recipient, uint amount) internal returns (bool) {
        require(amount <= _maxAirdrop, "Amount exceeds airdrop limit.");
        require(amount <= _airdropSupply, "Amount exceeds airdrop limit.");
        _transfer(address(this), recipient, amount);
        _airdropSupply -= amount;
        return true;
    }
}