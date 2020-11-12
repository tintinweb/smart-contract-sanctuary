pragma solidity 0.6.5;

import "./ERC20.sol";
import "./Pausable.sol";

abstract contract ERC20Mintable is ERC20, Pausable {
    event Mint(address indexed receiver, uint256 amount);
    event MintFinished();
    uint256 internal _cap;
    bool internal _mintingFinished;
    ///@notice mint token
    ///@dev only owner can call this function
    function mint(address receiver, uint256 amount)
        external
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        require(
            receiver != address(0),
            "ERC20Mintable/mint : Should not mint to zero address"
        );
        require(
            _totalSupply.add(amount) <= _cap,
            "ERC20Mintable/mint : Cannot mint over cap"
        );
        require(
            !_mintingFinished,
            "ERC20Mintable/mint : Cannot mint after finished"
        );
        _mint(receiver, amount);
        emit Mint(receiver, amount);
        success = true;
    }

    ///@notice finish minting, cannot mint after calling this function
    ///@dev only owner can call this function
    function finishMint()
        external
        onlyOwner
        returns (bool success)
    {
        require(
            !_mintingFinished,
            "ERC20Mintable/finishMinting : Already finished"
        );
        _mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function cap()
        external
        view
        returns (uint256)
    {
        return _cap;
    }

    function isFinished() external view returns(bool finished) {
        finished = _mintingFinished;
    }
}
