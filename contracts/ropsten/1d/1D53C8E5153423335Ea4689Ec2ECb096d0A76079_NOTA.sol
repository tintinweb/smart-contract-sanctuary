// xx-License-Identifier: MIT
pragma solidity ^0.8.10;
//import 'openzeppelin-solidity/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';
//import 'openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol';

//is equivalent to
import './imports.sol';

contract NOTA is ERC20Burnable, ERC20PresetMinterPauser {

    //uint256 MAXSUPPLY = 1000 * 10**6 * 10**18; // 1 thousand of millions
    uint256 MAXSUPPLY = 1000000000 ether; // 1 thousand of millions, 24 ceros
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    constructor () ERC20PresetMinterPauser("NOTARIOCOIN", "NOTA") {
        _grantRole(TRANSFER_ROLE, _msgSender());

        //Minting and main distribution at a time
        _mint(0xde0f5E8d1ce4F14D859014E8725111eC30AC0E15 , 300000000 ether); //__privatesale
        _mint(0xbd2CE8e89dae92F5bf2eB8BD8f0B61884437746B ,  50000000 ether); //__privatesale2
        _mint(0xeE8B1244259D2AF4Ad76D1804b09eEd7fc027b1A , 150000000 ether); //__publicsale
        _mint(0x44ad24238e2d1DC9ECFaF24e79f69825D23c83a2 ,  50000000 ether); //__team
        _mint(0x33b8bD3F7Fb16bf04DeDFdCD0eA2BB54F121775D ,  60000000 ether); //__techpartners
        _mint(0xA8bd4e956A53c9E38FeE4C16026Cf519FcBC1dFa ,  40000000 ether); //__idi
        _mint(0xaeA3F2cD39aE072b312D6006ba8a1828c8429dA0 ,  50000000 ether); //__advisors
        _mint(0xa2acDFcbeC6A098c9f452DF3Aa94E5E106aA925a , 280000000 ether); //__reserved
        _mint(0x24fEDee95aa8B27a82D34e4867565Ee7Dd508818 ,  20000000 ether); //__airdrops

        _pause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20PresetMinterPauser) {
        if (paused() && !hasRole(TRANSFER_ROLE, _msgSender())) {
            super._beforeTokenTransfer(from, to, amount);
        }
    }

    //Unpaused cannot be reverted
    function pause() public virtual override(ERC20PresetMinterPauser){
        require(false, "ERC20 Unpaused cannot be reverted");        
    }

    //Capped Mint function
    function mint(address to, uint256 amount) public virtual override(ERC20PresetMinterPauser){
        require(totalSupply() + amount <= MAXSUPPLY, "MAXSUPPLY cannot be exceded");
        super._mint(to, amount);
    }

    //A MINTER_ROLE account can burnFrom
    function burnFrom(address from, uint256 amount) public virtual override(ERC20Burnable){
        if (paused() && hasRole(MINTER_ROLE, _msgSender())) {
            _approve(from, _msgSender(), amount);
        }
        super.burnFrom(from, amount);
    }
}