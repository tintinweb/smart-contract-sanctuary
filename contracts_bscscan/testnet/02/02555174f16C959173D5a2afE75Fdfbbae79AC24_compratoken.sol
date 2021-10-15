/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

    interface Cryptofitness{
        function decimals()external view returns (uint8);
        function balanceOf (address _address) external view returns (uint256);
        function transfer(address _to, uint256 _value) external returns (bool success);
    }
    
contract compratoken {
    
    address owner;
    uint256 precio;
    Cryptofitness Mytokencontract;
    uint256 ventatokens;

    event venta(address buyer, uint256 cantidad);
    
    constructor(uint256 _precio, address payable _addresscontract) {
        
        owner = msg.sender;
        precio = _precio;
        Mytokencontract = Cryptofitness(_addresscontract);
}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require (c / a == b);
            return c;
    }
    
    function comprar(uint256 _numerotokens) public payable {
        require (msg.value == mul(precio, _numerotokens));
        uint256 cantidadescalada = mul( _numerotokens, uint256(10) ** Mytokencontract.decimals());
        require (Mytokencontract.balanceOf(address(this)) >= cantidadescalada );
        ventatokens += _numerotokens;
        require (Mytokencontract.transfer (msg.sender, cantidadescalada));
        emit venta(msg.sender, _numerotokens);
    }
    
    function liquidacioncontrato() public {
        require (msg.sender == owner);
        require (Mytokencontract.transfer(owner, Mytokencontract.balanceOf(address(this))));
        payable (msg.sender).transfer(address(this).balance);
        
    }

}