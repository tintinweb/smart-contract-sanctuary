pragma solidity >=0.4.23 <0.9.0;

import "./TRC20Detailed.sol";
import "./TRC20.sol";
import "./MinterRole.sol";

contract PiToken is TRC20, TRC20Detailed, MinterRole {
    uint8 private constant _decimals = 8;
    uint256 private constant _maxMint = 1368678999 * (10 ** uint256(_decimals)); // 100 millions
    uint256 private constant _cap = _maxMint * 1; // 12 billions cap, 10 years minting in estimate
    uint private constant _mintInterval = 60 * 60 * 24 * 25; // 25 days minimum interval between mintings - sec * min * h * day
    uint private _lastMint = 0;

    constructor ()
        TRC20Detailed("Pi Token", "PI", _decimals)
        TRC20()
        public
    {}

    function cap() public pure returns (uint256) {
        return _cap;
    }

    function lastMintTime() public view returns (uint) {
        return _lastMint;
    }

    function mintCooldownMinutes() public view returns (uint) {
        require(now - _mintInterval < _lastMint, "MINT: READY");
        return ((_mintInterval - (now - _lastMint)) / 60 + 1);
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        uint256 _value = value * (10 ** uint256(_decimals));
        require(_value <= _maxMint, "MINT: AMOUNT NOT ALLOWED");
		require(now - _mintInterval > _lastMint, "MINT: TIME RANGE LOW");
        require(totalSupply().add(_value) <= _cap, "MINT: TOTAL SUPPLY LIMIT HIT");
        _mint(to, _value);
        _lastMint = now;
        return true;
    }
}