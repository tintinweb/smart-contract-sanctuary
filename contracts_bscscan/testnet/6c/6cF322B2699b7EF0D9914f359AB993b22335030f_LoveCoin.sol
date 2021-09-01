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
contract LoveCoin is BEP20 {
    uint8 private constant DECIMALS = 8;
    uint public constant _totalSupply = 500000000000000 * 10**uint(DECIMALS);
    uint constant HALF_LIFE = 120 days;
    uint constant STARTING_SUPPLY = _totalSupply / 10;
    uint private _lockedCoins = _totalSupply - STARTING_SUPPLY;
    uint private _releasedCoins = STARTING_SUPPLY;
    uint private _releaseDate;
    uint private _lastReleasePeriod;

    address private _admin;
    address private _newAdmin;
    uint private _maxAirdrop = 10_000_000 * 10**DECIMALS;

    constructor() BEP20("Lovecoin Token", "Lovecoin") {
        _admin = msg.sender;
        _newAdmin = msg.sender;
        _releaseDate = block.timestamp;
    }

    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply - _lockedCoins;
    }

    function maxSupply() public pure returns (uint) {
        return _totalSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    function editMaxAirdrop(uint newMax) public {
        require(msg.sender == _admin, "Admin address required.");
        _maxAirdrop = newMax * 10**DECIMALS;
    }

    function editAdmin(address newAdmin) public {
        require(msg.sender == _admin, "Admin address required.");
        _newAdmin = newAdmin;
    }

    function claimAdmin() public {
        require(msg.sender == _newAdmin, "This address does not have the rights to claim the Admin position.");
        _admin = _newAdmin;
    }

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
        require(amount <= _releasedCoins, "Airdrop supply cannot cover the amount requested.");
        _releasedCoins -= amount;
        _mint(recipient, amount);
        return true;
    }

    //Tokens will be emitted at a rate of half the remaining supply every 4 months.
    function releaseCoins() public {
        require(msg.sender == _admin, "Admin address required.");
        uint currentPeriod = (block.timestamp - _releaseDate) / HALF_LIFE;
        require(currentPeriod > _lastReleasePeriod, "Already released coins this period.");

        uint toRelease;
        uint periodsToRelease = currentPeriod - _lastReleasePeriod;
        for (uint i = 0; i < periodsToRelease; i++) {
            toRelease += (_lockedCoins - toRelease) / 2;
        }

        _lockedCoins -= toRelease;
        _releasedCoins += toRelease;
        _lastReleasePeriod = currentPeriod;
    }
}