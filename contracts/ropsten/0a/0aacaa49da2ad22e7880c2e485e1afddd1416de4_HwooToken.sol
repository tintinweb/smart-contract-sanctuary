// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;




import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./TokenTimelock.sol";

contract HwooToken is ERC20, AccessControl, Ownable{

    // uint public INITIAL_SUPPLY = 21000000;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    address minter = msg.sender;
    address burner = msg.sender;

    constructor() ERC20("HwooToken", "Hwoo"){
        // _mint(msg.sender, INITIAL_SUPPLY * 10 ** (uint(decimals())));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
     function changename(string memory nname) public onlyRole(DEFAULT_ADMIN_ROLE){
        _changename(nname);
    }
      function changesymbol(string memory nsymbol) public onlyRole(DEFAULT_ADMIN_ROLE){
        _changesymbol(nsymbol);
    }
    
    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        _mint(to, amount);
    } //mint는 발행하는거니까 to 
    //public이지만 MINTER_ROLE권한있는 사람만 할 수있게 onlyRole사용. 

        function onequarterburn(address from) public onlyRole(DEFAULT_ADMIN_ROLE){
        _onequarterburn(from);
    } //burn는 빼는거니까 from
        function onethirdburn(address from) public onlyRole(DEFAULT_ADMIN_ROLE){
        _onethirdburn(from);
    } 
        function onehalfburn(address from) public onlyRole(DEFAULT_ADMIN_ROLE){
        _onehalfburn(from);
    }
         function entireburn(address from) public onlyRole(DEFAULT_ADMIN_ROLE){
        _entireburn(from);
    }
    function burn(address from, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        _burn(from,amount);
    } 
    

    function mintTimeLocked(address _to, uint256 _amount, uint256 _releaseTime) public onlyOwner returns(TokenTimelock) {
        TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
        mint(address(timelock), _amount);
        return timelock;
    }
}