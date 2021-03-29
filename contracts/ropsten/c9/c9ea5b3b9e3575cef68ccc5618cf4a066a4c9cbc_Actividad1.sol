/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

contract Actividad1 {
    //string public message;
    mapping(address => string[]) private messages;
    uint256 constant coste_del_contrato = 10 wei;
    uint256 public fecha_del_ultimo_mensaje = block.timestamp;

   //constructor (string memory _message) public {
   //    message = _message;
   // }

    function setMessage(string memory _new_message) public payable {
    require(msg.value >= coste_del_contrato, "Por favor introduzca la cantidad minima de 10WEI para realizar la Tx, si no, no se va a completar" );
    messages[msg.sender].push(_new_message);
    fecha_del_ultimo_mensaje = block.timestamp;
        
    }

    function getMessages() public view returns (string[] memory) {
        return messages[msg.sender];
    }
    function remove(uint index, string[] storage array) private {
        if (index >= array.length) return;

        for (uint i = index; i<array.length-1; i++){
            array[i] = array[i+1];
        }
        delete array[array.length-1];
    }
    
    function deleteMessage(uint index, address el_baneado_al_sotano) public {
        require(msg.sender == address(0x954676A10617Cab2F13a953ca20E2d384ddAe966)); //ADMIN
        remove(index, messages[el_baneado_al_sotano]); 
    }
}