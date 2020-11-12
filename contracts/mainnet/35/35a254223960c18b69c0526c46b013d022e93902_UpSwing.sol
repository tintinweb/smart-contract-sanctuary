//SPDX-Licence-Identifier: 2guys

//======================================================================================================


pragma solidity ^0.6.0;

import "./Steam.sol";
import "./ERC20.sol";

interface IUNIv2 {
    function sync() external;
}

contract UpSwing is ERC20 {

    using SafeMath for uint256;

    address private UNIv2;
    
    mapping(address => bool) public allowed;
    mapping(address => bool) public pauser;
    modifier onlyAllowed() {
        require(allowed[_msgSender()], "onlyAllowed");
        _;
    }


    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _initialSupply;
    uint256 private _UPSBurned = 0;
    
    uint8 public leverage;
    bool public paused = true;
    mapping(address => uint256) sellPressure;
    mapping(address => uint256) steamToGenerate;
    mapping(address => uint256) txCount;
    
    address _STEAM;

    event BurnedFromLiquidityPool(address burnerAddress, uint amount);
    event SteamGenerated(address steamRecipientddress, uint amount);

    constructor(uint256 UPS_totalSupply) public {
        _name = "UpSwing"; 
        _symbol = "UPS";
        _decimals = 18;
        _initialSupply = UPS_totalSupply.mul(1e18);
        ERC20._mint(_msgSender(), UPS_totalSupply.mul(1e18)); //uses "normal" numbers

        leverage = 200;
        
        _STEAM = address(new Steam(UPS_totalSupply)); //creates steam token
        allowed[_msgSender()] = true;
        pauser[_msgSender()] = true;
    }
    
    modifier onlyPauser() {
        require(pauser[_msgSender()], "onlyPauser");
        _;
    }

    
    function setPauser(address _address, bool _bool) public onlyAllowed {
        pauser[_address] = _bool;
    }
    
    function togglePause(bool _bool) public onlyPauser {
        paused = _bool;
    }
    
    
    modifier canSteam(address _address){
        require(steamToGenerate[_address] > 0, "no Steam to generate");
        _;
    }
    
    /*  //STEAM function called below:
    
        function generateSteam(address account, uint256 amount) external onlyAllowed {
        require((_totalSupply + amount) < _maxSupply, "STEAM token: cannot generate more steam than the max supply");
        ERC20._mint(account, amount);
        _steamMinted = _steamMinted.add(amount);
    }
    */
    
    function _generateSteamFromUPSBurn(address _address) internal canSteam(_address){
        uint256 _steam = steamToGenerate[_address];
        steamToGenerate[_address] = 0;
        Steam(_STEAM).generateSteam(_address, _steam);
    }   
    
    function addToSteam(address _address, uint256 _amount) internal {
        steamToGenerate[_address] = steamToGenerate[_address].add(_amount);
    }  
    
    function amountPressure(uint256 amount) internal view returns(uint256){ 
        uint256 UNI_SupplyRatio = (getUNIV2Liq().mul(1e18)).div(totalSupply());
        UNI_SupplyRatio = UNI_SupplyRatio.mul(leverage).div(100);

        return amount.mul(UNI_SupplyRatio).div(1e18);
    }
    
    function setAllowed(address _address, bool _bool) public onlyAllowed {
        allowed[_address] = _bool;
    }

    function setUNIv2(address _address) public onlyAllowed {
        UNIv2 = _address;
    }

    function setLeverage(uint8 _leverage) public onlyAllowed {
        require(_leverage <= 1000 && _leverage >= 0);
        leverage = _leverage;
    }

    function myPressure(address _address) public view returns(uint256){
        return amountPressure(sellPressure[_address]);
    }
    
    function releasePressure(address _address) internal {
        uint256 amount = myPressure(_address);
        
        if(amount < balanceOf(UNIv2)) {
            require(_totalSupply.sub(amount) >= _initialSupply.div(1000), "There is less than 0.1% of the Maximum Supply remaining, unfortunately, kabooming is over");
            
            sellPressure[_address] = 0;
            addToSteam(_address, amount);
            
            ERC20._burn(UNIv2, amount);

            _UPSBurned = _UPSBurned.add(amount);
            emit BurnedFromLiquidityPool(_address, amount);
            
            _generateSteamFromUPSBurn(_address);
            emit SteamGenerated(_address, amount);
            
            txCount[_address] = 0;
        } else if (amount > 0) {
            sellPressure[_address] = sellPressure[_address].div(2);
        }
        
        
       IUNIv2(UNIv2).sync();
    }
    
    function UPSMath(uint256 n) internal pure returns(uint256){
        uint _t = n*n + 1;
        _t =  1e10/(_t);
        return (92*_t)/100;
        
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override{
        require(!paused || pauser[sender], "UPStkn: You must wait until UniSwap listing to transfer");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
    
        ERC20._balances[sender] = ERC20._balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        ERC20._balances[recipient] = ERC20._balances[recipient].add(amount);
    
            if(recipient == UNIv2){ 
                txCount[sender] = txCount[sender]+1;
                amount = amount.mul(UPSMath(txCount[sender])).div(1e10);
                sellPressure[sender] = sellPressure[sender].add(amount);
            }
    
            if(sender == recipient && amount == 0){releasePressure(sender);}
    
        emit Transfer(sender, recipient, amount);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    
    function mySteam(address _address) public view returns(uint256){
        return steamToGenerate[_address];
    }
    
    function getUNIV2Address() public view returns (address) {
        return UNIv2;
    }
    
    function getUNIV2Liq() public view returns (uint256) {
        return balanceOf(UNIv2);
    }
    
    function getUPSTotalSupply() public view returns(uint256){
        return _totalSupply;
    }
    
    function getUPSBurned() public view returns(uint256){
        return _UPSBurned;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return ERC20._totalSupply;
    }

}