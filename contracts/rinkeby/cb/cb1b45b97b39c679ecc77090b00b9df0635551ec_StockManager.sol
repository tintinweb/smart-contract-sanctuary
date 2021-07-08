/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity 0.8.4;
//"SPDX-License-Identifier: UNLICENSED"

//import "@openzeppelin/contracts/access/Ownable.sol";

contract StockManager {
    address owner;
    struct Item {
        address payable owner;
        //uint id; //No hace falta no? El id es el índice en products
        uint originalStock;
        uint remaining;
        uint maxUnitsPerPerson;
        uint price;
        mapping(address => uint) buyerList;
        mapping(address => bool) payedFor;
        //uint initialTime;
        bool active;
    }
    uint private nProducts;
    mapping(uint => Item) products;

    constructor(){
        owner = msg.sender;
    }

   /*
   *@dev Sólo el dueño del contrato puede llamar
   */    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
   
   /*
   *@dev Verifica que el número de unidades no sea mayor al límite y que queden suficientes unidades disponibles
   */
    modifier checkStock(uint _productId, uint _units) {
        require(_units <= products[_productId].maxUnitsPerPerson, "This exceeds the maximum number of units per person");
        require(products[_productId].remaining >= _units, "Not enough units available");
        _;
    }
   
   /*
   *@dev Verifica que la address que lo llama no haya hecho una reserva de ese producto previamente
   */   
    modifier neverPurchased(uint _productId, address _client) {
        require(products[_productId].buyerList[_client] == 0, "Only one purchase is allowed per customer");
        //Acá podría validar también que la dirección sea real/única para esa persona
        _;
    }
   
    /*
   *@dev Verifica que el producto se encuentre activo
   */ 
    modifier isActiveProduct(uint _productId) {
        require(products[_productId].active == true, "Product is no longer available");
        //require(block.timestamp >= products[_productId].initialTime, "Product is not available yet");
        _;
    }

   /*
   *@dev Requiere que sea el dueño del producto el que llama la función
   */
    modifier onlyProductOwner(uint _productId) {
        //Solo el owner del product, overrideo el onlyOwner de Ownable
        require(products[_productId].owner == msg.sender, "Only the product owner can edit the product details");
        _;
    }
    
    /*
   *@dev Sólo el dueño del producto o del contrato pueden acceder a la función
   */
    modifier onlyOwnerOrProductOwner(uint _productId) {
        require(products[_productId].owner == msg.sender || owner == msg.sender, "Not authorized");
        _;
    }

    /*
   *@dev Sólo compradores
   */
    modifier onlyBuyer(uint _productId) {
        require(products[_productId].buyerList[msg.sender] > 0, "You don't have a reservation");
        _;
    }
    
   /*
   *@dev Verifica que la dirección haya reservado el producto y que el valor enviado coincida con lo que se debe pagar por la cantidad de unidades del producto a comprar
   */    
    modifier canBuy(uint _productId) {
        require(products[_productId].buyerList[msg.sender] > 0, "You don't have a reservation for this product");
        require(products[_productId].buyerList[msg.sender] * products[_productId].price == msg.value, "Incorrect amount, please transfer the payment for the whole order");
        _; 
    }

   /*
   *@dev Consulta la cantidad que queda disponible de un producto
   *@param _productId es el ID del producto que se quiere consultar
   *@return la cantidad de producto que queda disponible
   */   
    function getRemainingStock(uint _productId) external view returns(uint){
        return products[_productId].remaining;
    }

   /*
   *@dev Verifica la cantidad de unidades vendidas
   *@param _productId es el ID del producto que se quiere consultar
   *@return la cantidad de producto que ya está reservado
   */
    function getSoldUnits(uint _productId) external view returns(uint){
        return products[_productId].originalStock - products[_productId].remaining ;
    }
    
   /*
   *@dev Devuelve la dirección del owner de un producto
   *@param _productId es el ID del producto que se quiere consultar
   *@return la dirección asignada como dueña del producto
   */   
    function getProductOwner(uint _productId) external view returns(address){
        return products[_productId].owner;
    }
    
   /*
   *@dev Devuelve si un producto está activo
   *@param _productId es el ID del producto que se quiere consultar
   *@return True o false
   */     
    function checkIfProductActive(uint _productId) external view returns(bool){
        return products[_productId].active;
    }

   /*
   *@dev Agrega un producto con unos valores default, pero no lo activa aún
   *@param _productId es el ID del producto que se quiere consultar
   *@return la cantidad de producto que queda disponible
   */   
    function addItem(address payable _productOwner) public onlyOwner{
        //asigna el owner del producto y el ID igual a nProducts
        nProducts++;
        
        products[nProducts].owner = _productOwner;
        products[nProducts].active = false; //Hasta que el owner del Producto no lo valide y corrija
        
        //Defaults, el owner lo tiene que actualizar
        products[nProducts].maxUnitsPerPerson = 1;
        products[nProducts].originalStock = 1;
        products[nProducts].remaining = products[nProducts].originalStock;
        //products[nProducts].initialTime = block.timestamp;
        //emita un mensaje a la _owner address para que sepa que tiene cargado un nuevo producto
    }
    
   /*
   *@dev El owner del producto carga los detalles y habilita el producto
   *@param _productId es el ID del producto que se quiere consultar
   *@param _initialStock es la cantidad disponible inicialmente
   *@param _maxPerBuyer unidades máximas permitidas por dirección
   *@param _price precio del producto
   */  
    function updateProduct(uint _productId, uint _initialStock, uint _maxPerBuyer, uint _price) external onlyProductOwner(_productId) {
        require(products[_productId].active == false); //Para que no se pueda editar un producto manualmente una vez activado.
        
        products[_productId].originalStock = _initialStock;
        products[_productId].remaining = _initialStock;
        products[_productId].active = true;
        products[_productId].maxUnitsPerPerson = _maxPerBuyer;
        products[_productId].price = _price;
        //products[_productId].initialTime = _releaseTime;
    }

   /*
   *@dev El owner del contrato o el del producto pueden remover el listado de un producto.
   *@param _productId es el ID del producto que se quiere consultar
   */         
    function removeProduct(uint _productId) external onlyOwnerOrProductOwner(_productId) {
        //en ambos lados porque lo puede hacer el owner o el product owner?
        products[_productId].owner = payable(address(0));
        products[_productId].active = false;
    }

   /*
   *@dev Función para que el comprador que hubiera pagado un producto que fue cancelado pueda recuperar sus fondos.
   *@param _productId es el ID del producto que se quiere consultar
   */  
    function askRefund(uint _productId) external onlyBuyer(_productId) {
        require (products[_productId].payedFor[msg.sender], "This reserve hasn't been payed for yet");
        require (products[_productId].active == false, "Sale is still active, cancel the sale for a refund");
        
        payable(msg.sender).transfer(products[_productId].buyerList[msg.sender] * products[_productId].price);
        products[_productId].buyerList[msg.sender] = 0;
        products[_productId].payedFor[msg.sender] = false;
    }
    
   /*
   *@dev Permite a un comprador reservar el producto, chequeando que haya stock, no haya comprado antes y no pase el límite de unidades por cuenta. Si no quedan más unidades, desactiva la publicación.
   *@param _productId es el ID del producto que se quiere consultar
   *@param _units es la cantidad de unidades que se quiere comprar
   */  
    function reserveProduct(uint _productId, uint _units) external isActiveProduct(_productId) neverPurchased(_productId, msg.sender) checkStock(_productId, _units) {
        products[_productId].remaining = products[_productId].remaining - _units;
        if (products[_productId].remaining == 0) {
            products[_productId].active = false;
        }
        products[_productId].buyerList[msg.sender] = _units;
    }

   /*
   *@dev Permite cancelar la reserva de un producto activo. Si ya se había pagado se devuelve el monto. Se resetean los mappings
   *@param _productId es el ID del producto que se quiere consultar
   */     
    function cancelSale(uint _productId) external isActiveProduct(_productId) {
        //Para que la llame el comprador y cancele la reserva
        if (products[_productId].payedFor[msg.sender]) {
            payable(msg.sender).transfer(products[_productId].buyerList[msg.sender] * products[_productId].price);
        }
        products[_productId].remaining = products[_productId].remaining + products[_productId].buyerList[msg.sender];
        products[_productId].buyerList[msg.sender] = 0;
        products[_productId].payedFor[msg.sender] = false;
    }

   /*
   *@dev Permite al dueño de un producto cancelar la reserva de un producto activo a una address. Si ya se había pagado se devuelve el monto. Se resetean los mappings
   *@param _productId es el ID del producto que se quiere consultar
   *@param _buyer es la dirección a la que se le va a cancelar la reserva
   */  
    function cancelSale(uint _productId, address payable _buyer) external onlyProductOwner(_productId) {
        if (products[_productId].payedFor[_buyer]) {
            _buyer.transfer(products[_productId].buyerList[_buyer] * products[_productId].price);
        }
        
        products[_productId].remaining = products[_productId].remaining + products[_productId].buyerList[_buyer];
        products[_productId].buyerList[_buyer] = 0;
        products[_productId].payedFor[_buyer] = false;
    }
    
   /*
   *@dev Permite comprar un producto activo que fue reservado. Se asigna el payedFor a true. Paga la plata al contrato, después al acusar recibo del producto se envía al owner del producto.
   *@param _productId es el ID del producto que se quiere consultar
   */     
    function purchaseProduct(uint _productId) external payable canBuy(_productId) {
        products[_productId].payedFor[msg.sender] = true;
    }

   /*
   *@dev El comprador declara haber recibido el producto y libera los fondos que se envían al owner del producto.
   *@param _productId es el ID del producto que se quiere consultar
   */     
    function productReceived(uint _productId) external onlyBuyer(_productId) {
        require(products[_productId].payedFor[msg.sender] = true);
        releaseFunds(_productId, msg.sender);
    }
   
   /*
   *@dev Se llama cuando el comprador avisa tener el producto. Libera los fondos al owner del producto y actualiza los mappings para que no se pueda hacer otra compra desde esa dirección.
   *@param _productId es el ID del producto que se quiere consultar
   */     
    function releaseFunds(uint _productId, address _buyer) private {
        require(products[_productId].payedFor[_buyer] = true);
        
        products[_productId].owner.transfer(products[_productId].buyerList[_buyer] * products[_productId].price);
        products[_productId].buyerList[_buyer] = 9999999;
        products[_productId].payedFor[_buyer] = false;
    }
    
    receive() external payable{
        
    }
    
    fallback() external payable{
        
    }
}