pragma solidity ^0.4.25;

contract items {

    address admin = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;

    struct producto {
        uint no_qr;
        uint lote;
        string description;
        string fecha_fab;
        string modelo;
        string marca;
        string test_qa;
        address owner;
    }
    mapping (uint => producto) private PRODUCTOS;
    mapping (address => uint) private PRODUCTO_OWNER;

    uint[] public productosList;


     constructor () payable{
     }

     function add_product (uint _qr,uint _lote,string _description,string
_fecha_fab,string _modelo,string _marca,string _test_qa)  returns
(string,uint){
        require (msg.sender == admin, "No esta autorizado");
        var PRODUCTO = PRODUCTOS[_qr];
        PRODUCTO.no_qr = _qr;
        PRODUCTO.lote = _lote;
        PRODUCTO.description = _description;
        PRODUCTO.fecha_fab = _fecha_fab;
        PRODUCTO.modelo = _modelo;
        PRODUCTO.marca = _marca;
        PRODUCTO.test_qa = _test_qa;
        productosList.push(_qr) -1;

        return ("Producto agregado ok QR_ID:",_qr);
    }
    function del_product (uint _qr) public returns (string,uint) {
        require (msg.sender == admin, "No esta autorizado");
        delete(PRODUCTOS[_qr]);
        return ("PRODUCTO BORRADO:",_qr);
    }
    function mod_product (uint _qr,uint _lote,string _description,string
_fecha_fab,string _modelo,string _marca,string _test_qa) public returns
(string,uint) {
        require (msg.sender == admin|| msg.sender == PRODUCTOS[_qr].owner,
"No esta autorizado");
        var PRODUCTO = PRODUCTOS[_qr];
        PRODUCTO.no_qr = _qr;
        PRODUCTO.lote = _lote;
        PRODUCTO.description = _description;
        PRODUCTO.fecha_fab = _fecha_fab;
        PRODUCTO.modelo = _modelo;
        PRODUCTO.marca = _marca;
        PRODUCTO.test_qa = _test_qa;
        return ("PRODUCTO MODIFICADO:",_qr);

    }
    function view_product (uint _qr) view public returns
(string,uint,uint,string,string,string,address) {
        return ("INFO DEL PRODUCTO:", PRODUCTOS[_qr].no_qr,
PRODUCTOS[_qr].lote,PRODUCTOS[_qr].description, PRODUCTOS[_qr].fecha_fab,
PRODUCTOS[_qr].modelo, PRODUCTOS[_qr].owner);
    }
    function transferir (uint _qr,address _new_owner) returns
(string,uint,address){
     require (msg.sender == admin || msg.sender == PRODUCTOS[_qr].owner,
"No esta autorizado");
        var PRODUCTO = PRODUCTOS[_qr];
        PRODUCTO.owner = _new_owner;
     return ("New owner de:",_qr,_new_owner);
    }
    function list_products () view public returns (uint[]) {
        require (msg.sender == admin, "No esta autorizado");
        return (productosList);
    }
    function count_products() view public returns (uint) {
        return productosList.length;
    }

}