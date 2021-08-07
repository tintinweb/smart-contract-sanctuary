//오픈체플린에서 가져온 예제코드 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./TokenTimelock.sol";

contract YaOng is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable {
    
    uint256 public  INITIAL_SUPPLY = 1000 * (10 ** uint256(decimals()));
    uint256 public  MAX_SUPPLY = 50000 * (10 ** uint256(decimals()));


    constructor() ERC20("YaOng", "YO")  {
        // _mint(msg.sender, 10000 * 10 ** decimals());
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function mint(address to, uint256 amount  ) public onlyOwner {
        require(totalSupply() <= MAX_SUPPLY );
        _mint(to, amount);
    }
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from,amount);
    }

      //에어드랍 
    mapping (address => uint256) public airDropHistory;
    event AirDrop(address _receiver, uint256 _amount);
    function dropToken(address[] memory receivers, uint256[] memory values) public onlyOwner{
    require(receivers.length != 0);
    require(receivers.length == values.length);
    for (uint256 i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      uint256 amount = values[i];
      transfer(receiver, amount);
      airDropHistory[receiver] += amount;
      emit AirDrop(receiver, amount);
    }
    }
       //락
    mapping (address => address) public lockStatus;
    event Lock(address _to, uint256 _amount);
    function lockToken(address _to, uint256 _amount, uint256 _releaseTime) public onlyOwner  {
    TokenTimelock lockContract = new TokenTimelock(this,  _to , _releaseTime);
    transfer(address(lockContract), _amount);
    lockStatus[_to] = address(lockContract);
    emit Lock(_to, _amount);
    }


    
}