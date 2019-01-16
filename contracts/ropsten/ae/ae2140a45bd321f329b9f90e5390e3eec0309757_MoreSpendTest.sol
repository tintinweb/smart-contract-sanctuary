pragma solidity >=0.4.22 <0.6.0;

contract MoreSpendTest{
   uint public lastMint;
   address[] public listUsers;
   address public contractOwner;
   address public lastWinner; // almacenado para efectos de test ver que va bien la funcion

   mapping(address => uint) spendQty;
   
   constructor() public {
        lastMint = now;
        contractOwner = msg.sender;
    }

    /* Funcion que agrega un usuario al listado de usuarios del contrato */
    function addUser(address user) public returns (bool success) {
        require(msg.sender == contractOwner);
        uint arrayLength = listUsers.length;

        // Verificar si el usuario ya esta registrado en el sistema para evitar duplicados
        for (uint i=0; i<arrayLength; i++) {
            if (listUsers[i] == user) {
                return false; //Ya existe el usuario
            }
        }

        listUsers.push(user);
        spendQty[user] = 0;

        return true;
    }

    /* Funcion que borra un usuario al listado de usuarios del contrato */
    function removeUser(address user) public returns (bool success) {
        require(msg.sender == contractOwner);
        uint arrayLength = listUsers.length;

        spendQty[user] = 0; // Aunque no haria falta ponerlo a 0 ya que al buscar el mejor no va a analizar este gasto al no estar array, pero asi &#39;limpiamos&#39; su rastro
        
        // Obtener el indice del usuario ya que es necesario para hacer sustitucion y borrado
        for (uint i=0; i<arrayLength; i++) {
            if (listUsers[i] == user) { // ya tenemos el indice del usuario
                // Se hace swap con el ultimo elemento y se elimina el ultimo, ya que no hay opcion pop en Solidity
                listUsers[i] = listUsers[arrayLength-1];
                delete listUsers[arrayLength-1];
                listUsers.length--; // Importante para no dejar una direccion 0x00000000..... que lo detecta sino como usuario
                return true;
            }
        }

        return false;
    }

   /* Funcion test para establecer cantidad de gasto a un usuario, en proyecto real la idea es que
   al hacer la llamada a una funcion de compra, se encargue de hacer el set*/ 
   function setSpend(address user, uint qty) public returns (bool success) {
        spendQty[user] = qty;
        return true;
   }

   /* Funcion que analiza en base a la lista de usuarios quien es el que mas gasto ha hecho, siendo el ganador
   desde el ultimo minado */
   function bestUser() private view returns (address winner) {
        require(listUsers.length > 0);
        uint max = spendQty[listUsers[0]];
        address userTop = listUsers[0];
        uint arrayLength = listUsers.length;

        // Se busca quien ha hecho el mayor gasto
        for (uint i = 1; i<arrayLength; i++) {
            if(spendQty[listUsers[i]] > max) {
                max = spendQty[listUsers[i]];
                userTop = listUsers[i];
            }
        }
        return userTop;
   }

   /* Funcion de minado que se ejecuta si se cumple el plazo de tiempo previsto para poder hacerse (aqui 5 minutos)*/
   function mint() public returns (bool success) {
    if (now >= lastMint + 5 minutes) {
        uint arrayLength = listUsers.length;
        address winnerUser = bestUser();
        
        // Aqui se har&#237;a la suma de balance a winnerUser, al no ser un contrato de moneda la unica accion que realiza en el test es la de cambiar los last
        lastWinner = winnerUser;

        for (uint i = 0; i<arrayLength; i++) {
            spendQty[listUsers[i]] = 0;
        }

        lastMint = now;

        return true;
      }

      return false;
    
   }
   
}

/* Contrato de pruebas que consta de una base de datos de usuarios que participan en el juego, una funci&#243;n de minado y 
una funci&#243;n que decide qui&#233;n es el ganador. Cuando alguien entra o sale del juego de recompensas, se pone a 0 su marcador
ya que pueden hacer operaciones perfectamente de transferencia, pero solo se llevan recompensa quienes est&#233;n dentro de los
proveedores Walidean. En el ejemplo est&#225; puesto que cada 5 minutos se pueda minar, pero ese plazo se cambia facilmente a 
por ejemplo, una semana. Agregar o quitar usuarios del juego solo lo puede hacer el creador del contrato. Un array asociativo
de una direcci&#243;n Ethereum y un valor entero es donde se almacenan las operaciones que hacen los usuarios y que al final son las 
determinantes de cara a ver qui&#233;n es el ganador. La idea es que en las operaciones de intercambio donde hay env&#237;o de monedas,
adem&#225;s de hacer la transferencia se haga la correspondiente actualizaci&#243;n del valor del array asociativo. Una vez hecho el minado
en el periodo estipulado, se resetean todos los contadores a 0 para empezar el nuevo ciclo de juego */