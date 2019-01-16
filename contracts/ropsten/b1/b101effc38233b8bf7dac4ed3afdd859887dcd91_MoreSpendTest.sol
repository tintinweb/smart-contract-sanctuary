pragma solidity >=0.4.22 <0.6.0;

contract MoreSpendTest{
   uint public lastMint;
   address[] public listUsers;
   address contractOwner;
   address lastWinner; // almacenado para efectos de test ver que va bien la funcion

   mapping(address => uint) spendQty;
   
   constructor() public {
        lastMint = now;
        contractOwner = msg.sender;
    }

    /* Funcion que agrega un usuario al listado de usuarios del contrato */
    function addUser(address user) public returns (bool success) {
        require(msg.sender == contractOwner);
        listUsers.push(user);
        return true;
    }

    /* Funcion que norra un usuario al listado de usuarios del contrato */
    function removeUser(address user) public returns (bool success) {
        require(msg.sender == contractOwner);
        uint arrayLength = listUsers.length;
        uint i = 0;

        spendQty[user] = 0; // Aunque no haria falta ponerlo a 0 ya que al buscar el mejor no va a analizar este gasto al no estar array, asi &#39;limpiamos&#39; su rastro
        
        for (i=0; i<arrayLength; i++) {
            if (listUsers[i] == user) {
                break; // ya tenemos el indice del usuario
            }
        }

        // Se hace swap con el ultimo elemento y se elimina el ultimo, ya que no hay opcion pop en Solidity
        listUsers[i] = listUsers[arrayLength-1];
        delete listUsers[arrayLength-1];
        return true;
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
        uint max = spendQty[listUsers[0]];
        address userTop;
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