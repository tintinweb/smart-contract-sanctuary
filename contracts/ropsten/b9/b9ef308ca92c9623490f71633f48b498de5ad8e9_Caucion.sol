pragma solidity ^0.5.1;
// ----------------------------------------------------------------------------
// Cauci&#243;n Contract
// Este contrato permite realizar compraventa de productos y servicios
// con una garantia sin intermediarios.
// (c) by DFE.
// ----------------------------------------------------------------------------


contract Caucion{
    int estado; /*0: en blanco - 1: generado x vendedor - 2: rembolsado a vendedor - 3 cerrado - 4: pago liberado - 5: finalizado*/
    address vendedor;
    address comprador;
    uint fGeneracionContrato;
    uint fCierreContrato;
    uint fFinalizadoContrato;
    uint256 mtoVta;
    uint256 mtoCompra;
    uint256 mtoCaucionVta;
    uint256 mtoCaucionCompra;
    
    
    constructor() public {
        estado=0;
    }
    
    function getBalance() public view returns (uint256) {
        require((msg.sender==vendedor) || (msg.sender==comprador),"No autorizado");
        return (address(this).balance);
    }
    
    function getEstado() public view returns (int) {
        require((msg.sender==vendedor) || (msg.sender==comprador),"No autorizado");
        return (estado);
    }
    
    function getMtoCompraVta() public view returns (uint256) {
        return (mtoVta);
    }
    
    function getCaucionVta() public view returns (uint256) {
        require((msg.sender==vendedor) || (msg.sender==comprador),"No autorizado");
        return (mtoCaucionVta);
    }
    
    function getCaucionCompra() public view returns (uint256) {
        require((msg.sender==vendedor) || (msg.sender==comprador),"No autorizado");
        return (mtoCaucionCompra);
    }
    
    function getComprador() public view returns (address) {
        require((msg.sender==vendedor) || (msg.sender==comprador),"No autorizado");
        return (comprador);
    }
    
    function getVendedor() public view returns (address) {
        require((msg.sender==vendedor) || (msg.sender==comprador),"No autorizado");
        return (vendedor);
    }
    
    function setPublicacionVendedor(address _comprador)public payable{
        require(estado==0,"No se puede publicar el contrato");
        require((msg.value > 0 ether),"El monto para generar el contrato debe ser >0");
        fGeneracionContrato=now;
        vendedor=msg.sender;
        comprador=_comprador;
        mtoVta=msg.value;
        mtoCaucionVta=msg.value;
        mtoCompra=msg.value;
        mtoCaucionCompra=msg.value*2;
        estado=1;
        //address(this).balance
    }
    
    function setSuscripcionComprador()public payable{
        require(estado==1,"No se puede suscribir el contrato");
        require((msg.value==(mtoCompra+mtoCaucionCompra)) && (msg.sender==comprador),"Usted no es el comprador &#243; el monto del contrato pactado no coincide");
        fCierreContrato=now;
        estado=3;
        //address(this).balance
    }
    
    function onDeshacerPublicacion() public payable {
        require(estado==1,"No se puede reembolsar la Cauci&#243;n");
        require((msg.sender==vendedor),"Vendedor incorrecto");
        msg.sender.transfer(address(this).balance);
        estado=2;
    }
    
    function onLiberarPago() public payable {
        require(estado==3,"No se puede liberar pago");
        require((msg.sender==comprador),"Error");
        msg.sender.transfer(mtoCaucionCompra);
        estado=4;
    }
    
    function onCobrarVenta() public payable {
        require(estado==4,"No se puede liberar pago");
        require((msg.sender==vendedor),"Error");
        msg.sender.transfer(mtoCaucionVta+mtoVta);
        estado=5;
    }
    
}