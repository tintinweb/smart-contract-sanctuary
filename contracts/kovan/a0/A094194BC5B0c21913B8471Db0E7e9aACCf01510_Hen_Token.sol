//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./Ownable.sol";
import "./ERC20.sol";
contract Hen_Token is ERC20,Ownable{
    mapping(address=>bool)public Minter;
    constructor(address Owner) public ERC20("HEN Finance","HNF"){
        _mint(Owner,10e24);

        
    }
    function AddMinter(address _minter)public onlyOwner{
        Minter[_minter]=true;
    }
    function RemoveMinter(address _minter)public onlyOwner{
        Minter[_minter]=false;
    }
    modifier onlyMinter{
        require(Minter[msg.sender]);
        _;
    }
 function mint(address account,uint256 amount) public onlyMinter{
     _mint(account,amount);
 }
 function burn(address account,uint256 amount) public onlyMinter{
     _burn(account,amount);
 }
}