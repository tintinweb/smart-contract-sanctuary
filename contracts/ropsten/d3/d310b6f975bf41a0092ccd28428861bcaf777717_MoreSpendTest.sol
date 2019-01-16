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
    
    function getUsers() public view returns (address[] memory) {
        return listUsers;
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