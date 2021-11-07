// 20190401 Robert Martin-Legene <[email protected]>
// 20190507 Andres Blanco <[email protected]>
// Stamper
// vim:filetype=javascript
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Stamper {
    struct Stamp {
        bytes32 object;
        address stamper;
        uint256 blockNo;
    }
    // Lista de stamps (cada entrada tiene el hash del object, la cuenta que lo envio
    //                  y el numero de bloque en que se guardo)
    Stamp[] stampList;

    // Mapping de objects stampeados a la stampList
    mapping(bytes32 => uint256[]) hashObjects;

    // Mapping de cuentas que stampean (stampers) a la stampList
    mapping(address => uint256[]) hashStampers;

    // Evento que se dispara al agregar un stamp
    event Stamped(
        uint256 id,
        address indexed from,
        bytes32 indexed object,
        uint256 blockNo
    );

    address owner;

    constructor() {
        owner = msg.sender;

        // No queremos que haya stamps asociados a la posicion 0 (== false)
        // entonces guardamos ahi informacion de quien creo el SC y en que bloque
        stampList.push(Stamp(0, msg.sender, block.number));
    }

    // Stampear una lista de objects (hashes) recibido como array
    function put(bytes32[] memory objectList) public {
        uint256 i = 0;
        uint256 max = objectList.length;
        while (i < max) {
            // este object
            bytes32 object = objectList[i];
            // lo agregamos a la stampList
            // stampList.push devuelve la longitud, restamos 1 para usar como indice de la nueva entrada
            stampList.push(Stamp(object, msg.sender, block.number));
            uint256 newObjectIndex = stampList.length - 1;
            // lo mapeamos desde la lista de objects
            hashObjects[object].push(newObjectIndex);
            // lo mapeamos desde la lista de stampers
            hashStampers[msg.sender].push(newObjectIndex);

            emit Stamped(newObjectIndex,msg.sender, object, block.number);

            i++;
        }
    }

    // devuelve un stamp completo (object, stamper, blockno) de la lista
    function getStamplistPos(uint256 pos)
        public
        view
        returns (
            bytes32,
            address,
            uint256
        )
    {
        return (
            stampList[pos].object,
            stampList[pos].stamper,
            stampList[pos].blockNo
        );
    }

    // devuelve la cantidad de stamps que hay de este object
    function getObjectCount(bytes32 object) public view returns (uint256) {
        return hashObjects[object].length;
    }

    // devuelve la ubicacion en la stampList de un stamp especifico de este object
    function getObjectPos(bytes32 object, uint256 pos)
        public
        view
        returns (uint256)
    {
        return hashObjects[object][pos];
    }

    // devuelve el nro de bloque en el que este stamper registro este object por primera vez
    // Si no fue stampeado por este stamper devuelve 0
    function getBlockNo(bytes32 object, address stamper)
        public
        view
        returns (uint256)
    {
        uint256 length = hashObjects[object].length;
        for (uint256 i = 0; i < length; i++) {
            Stamp memory current = stampList[hashObjects[object][i]];
            if (current.stamper == stamper) {
                return current.blockNo;
            }
        }

        return 0;
    }

    // devuelve la cantidad de stamps que realizo este stamper
    function getStamperCount(address stamper) public view returns (uint256) {
        return hashStampers[stamper].length;
    }

    // devuelve la ubicacion en la stampList de un Stamp especifico de este stamper
    function getStamperPos(address stamper, uint256 pos)
        public
        view
        returns (uint256)
    {
        return hashStampers[stamper][pos];
    }
}