//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;
import "./Ownable.sol";

contract FastLocker is Ownable {
    uint public locked_until;
    
    // constructor(uint _locked_until) {
    //     locked_until = _locked_until;
    // }
    struct dossier{
        address contr_own;
        address lp_adrs;
        uint quantity;
        uint locked_until;
    }

    //mapping(address => dossier) Archive;
    mapping(address => mapping(address => dossier)) Archive;
    
    modifier controlla_tempo(address contract_adrss) {
        require(block.timestamp > Archive[msg.sender][contract_adrss].locked_until,"You cannot withdraw yet. (Time)");
        _;
    }
    modifier onlyUser(address contract_adrss) {
        require (alreadyDeposited(msg.sender,contract_adrss), "You do not exist");
        _;
    }

    function updateLock(uint _newTime, address contract_adrss) external onlyUser(contract_adrss) {
        require(Archive[msg.sender][contract_adrss].locked_until <= _newTime, "The past is past");
        Archive[msg.sender][contract_adrss].locked_until = _newTime;
    } 
    
    function addToken(address contract_adrss) external onlyUser(contract_adrss) {
        BEP20 tok = BEP20(contract_adrss);
        uint quant = tok.balanceOf(msg.sender);
        require(tok.transferFrom(msg.sender, address(this), quant));
        Archive[msg.sender][contract_adrss].quantity = Archive[msg.sender][contract_adrss].quantity + quant;
    }
    
    function Withdraw(address contract_adrss) external controlla_tempo(contract_adrss) onlyUser(contract_adrss) {
    uint256 balance = Archive[msg.sender][contract_adrss].quantity;
        require(balance > 0, "balance 0");
		require(BEP20(Archive[msg.sender][contract_adrss].lp_adrs).transfer(msg.sender, balance));
		Archive[msg.sender][contract_adrss].quantity = 0;
		
    }
    
    function alreadyDeposited(address _addrss, address contract_adrss) public view returns(bool) {
        return Archive[_addrss][contract_adrss].contr_own == _addrss;
    }
    
    function createLock(address lp_adrss, uint until, address contract_adrss) external {
        require(alreadyDeposited(msg.sender,contract_adrss) == false);
        BEP20 tok = BEP20(lp_adrss);
        uint quant = tok.balanceOf(msg.sender);
        require(tok.transferFrom(msg.sender, address(this), quant));
        
        Archive[msg.sender][contract_adrss].contr_own = msg.sender;
        Archive[msg.sender][contract_adrss].lp_adrs = lp_adrss;
        Archive[msg.sender][contract_adrss].quantity = quant;
        Archive[msg.sender][contract_adrss].locked_until = until;
    }
    
    //INFO
    function all_info(address contract_adrss) public view returns(address,address,uint,uint){
        address a = Archive[msg.sender][contract_adrss].contr_own;
        address b = Archive[msg.sender][contract_adrss].lp_adrs;
        uint c = Archive[msg.sender][contract_adrss].quantity;
        uint d = Archive[msg.sender][contract_adrss].locked_until;
        return (a,b,c,d);
    }
    
    function deleteAll_token(address contract_adrss) public onlyUser(contract_adrss) {
        delete Archive[msg.sender][contract_adrss];
    }
    
}
abstract contract BEP20 {
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);
}